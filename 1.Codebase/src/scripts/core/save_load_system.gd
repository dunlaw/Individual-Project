extends RefCounted
const ERROR_CONTEXT := "SaveLoadSystem"
const MAX_SAVE_SLOTS: int = 5
var _game_state = null
var current_save_slot: int = 1
var _migrator: SaveVersionMigrator = SaveVersionMigrator.new()
func set_game_state(game_state) -> void:
	_game_state = game_state
func _to_absolute_path(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
func _ensure_parent_directory(path: String) -> bool:
	var absolute_path := _to_absolute_path(path)
	var parent_dir := absolute_path.get_base_dir()
	if parent_dir.is_empty():
		return true
	var result := DirAccess.make_dir_recursive_absolute(parent_dir)
	return result == OK or result == ERR_ALREADY_EXISTS
func _open_file(path: String, mode: FileAccess.ModeFlags) -> FileAccess:
	var absolute_path := _to_absolute_path(path)
	if mode != FileAccess.READ and not _ensure_parent_directory(path):
		return null
	return FileAccess.open(absolute_path, mode)
func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(_to_absolute_path(path))
func _remove_file(path: String) -> bool:
	var absolute_path := _to_absolute_path(path)
	if not FileAccess.file_exists(absolute_path):
		return true
	return DirAccess.remove_absolute(absolute_path) == OK
func _copy_save_file(source_path: String, backup_path: String) -> bool:
	if not _file_exists(source_path):
		return false
	var source_file := _open_file(source_path, FileAccess.READ)
	if not source_file:
		return false
	var buffer := source_file.get_buffer(source_file.get_length())
	source_file.close()
	var backup_file := _open_file(backup_path, FileAccess.WRITE)
	if not backup_file:
		ErrorReporter.report_warning(
			ERROR_CONTEXT,
			"Failed to create save backup",
			{
				"source_path": source_path,
				"backup_path": backup_path,
				"source_absolute": _to_absolute_path(source_path),
				"backup_absolute": _to_absolute_path(backup_path),
				"error_code": FileAccess.get_open_error(),
			},
		)
		return false
	backup_file.store_buffer(buffer)
	backup_file.close()
	return true
func autosave() -> bool:
	if not _game_state:
		ErrorReporter.report_error(ERROR_CONTEXT, "Cannot autosave: GameState not set", -1)
		return false
	var autosave_path = "user://gda1_autosave.dat"
	var backup_path = "user://gda1_autosave_backup.dat"
	if _file_exists(autosave_path):
		_copy_save_file(autosave_path, backup_path)
	var save_file = _open_file(autosave_path, FileAccess.WRITE)
	if save_file:
		var save_data = _game_state.get_save_data()
		save_data["is_autosave"] = true
		save_data["save_timestamp"] = Time.get_unix_time_from_system()
		_migrator.stamp_version(save_data)
		save_file.store_var(save_data)
		save_file.close()
		ErrorReporter.report_info(ERROR_CONTEXT, "Autosave written to: %s" % autosave_path)
		ErrorReporter.report_info(ERROR_CONTEXT, "Auto-save completed successfully")
		return true
	else:
		var error = FileAccess.get_open_error()
		ErrorReporter.report_error(ERROR_CONTEXT, "Auto-save failed", error, false, { "path": autosave_path })
		return false
func save_to_slot(slot: int = -1) -> bool:
	if not _game_state:
		ErrorReporter.report_error(ERROR_CONTEXT, "Cannot save: GameState not set", -1)
		return false
	if slot == -1:
		slot = current_save_slot
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var save_path = "user://gda1_save_slot_%d.dat" % slot
	var backup_path = "user://gda1_save_slot_%d_backup.dat" % slot
	ErrorReporter.report_info(ERROR_CONTEXT, "Saving game to slot %d" % slot, { "path": save_path })
	if _file_exists(save_path):
		if _copy_save_file(save_path, backup_path):
			ErrorReporter.report_info(ERROR_CONTEXT, "Backed up existing save", { "backup_path": backup_path })
	var save_file = _open_file(save_path, FileAccess.WRITE)
	if save_file:
		var save_data = _game_state.get_save_data()
		save_data["save_slot"] = slot
		save_data["save_timestamp"] = Time.get_unix_time_from_system()
		save_data["is_autosave"] = false
		_migrator.stamp_version(save_data)
		save_file.store_var(save_data)
		save_file.close()
		current_save_slot = slot
		ErrorReporter.report_info(ERROR_CONTEXT, "Game saved to slot %d: %s" % [slot, save_path])
		ErrorReporter.report_info(ERROR_CONTEXT, "Game saved successfully to slot %d" % slot)
		return true
	else:
		var error = FileAccess.get_open_error()
		ErrorReporter.report_error(
			"SaveLoadSystem",
			"Failed to save game",
			error,
			true,
			{
				"slot": slot,
				"path": save_path,
			},
		)
		return false
func load_from_slot(slot: int = -1) -> bool:
	if not _game_state:
		ErrorReporter.report_error(ERROR_CONTEXT, "Cannot load: GameState not set", -1)
		return false
	if slot == -1:
		slot = current_save_slot
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var save_path = "user://gda1_save_slot_%d.dat" % slot
	var backup_path = "user://gda1_save_slot_%d_backup.dat" % slot
	ErrorReporter.report_info(ERROR_CONTEXT, "Loading game from slot %d" % slot)
	if _file_exists(save_path):
		var save_file = _open_file(save_path, FileAccess.READ)
		if save_file:
			var save_data = save_file.get_var()
			save_file.close()
			if save_data == null:
				ErrorReporter.report_error(ERROR_CONTEXT, "Save file returned null data in slot %d" % slot, -1)
				if _file_exists(backup_path):
					var restored_null := _load_from_backup(slot)
					if not restored_null:
						ErrorReporter.report_error(
							"SaveLoadSystem",
							"Failed to recover null save via backup for slot %d" % slot,
							-1,
							true,
							{ "backup_path": backup_path },
						)
					return restored_null
				return false
			if not save_data is Dictionary:
				ErrorReporter.report_error(ERROR_CONTEXT, "Save data is not a Dictionary in slot %d (type: %s)" % [slot, typeof(save_data)], -1)
				if _file_exists(backup_path):
					var restored_type := _load_from_backup(slot)
					if not restored_type:
						ErrorReporter.report_error(
							"SaveLoadSystem",
							"Failed to recover malformed save via backup for slot %d" % slot,
							-1,
							true,
							{ "backup_path": backup_path },
						)
					return restored_type
				return false
			if save_data.has("reality_score") or save_data.has("player_stats_data"):
				if _migrator.needs_migration(save_data):
					save_data = _migrator.migrate(save_data)
					_rewrite_save_file(save_path, save_data)
				_game_state.load_save_data(save_data)
				current_save_slot = slot
				ErrorReporter.report_info(ERROR_CONTEXT, "Game loaded from slot %d: reality=%s PE=%s" % [
					slot,
					str(save_data.get("reality_score", "?")),
					str(save_data.get("positive_energy", "?")),
				])
				return true
			else:
				ErrorReporter.report_warning(ERROR_CONTEXT, "Corrupted save in slot %d (missing required keys), attempting backup..." % slot)
				if _file_exists(backup_path):
					var restored_missing := _load_from_backup(slot)
					if not restored_missing:
						ErrorReporter.report_error(
							"SaveLoadSystem",
							"Failed to recover corrupted save via backup for slot %d" % slot,
							-1,
							true,
							{ "backup_path": backup_path },
						)
					return restored_missing
		else:
			var open_error := FileAccess.get_open_error()
			ErrorReporter.report_error(
				"SaveLoadSystem",
				"Failed to open save file for slot %d" % slot,
				open_error,
				true,
				{ "path": save_path },
			)
			if _file_exists(backup_path):
				var restored_open := _load_from_backup(slot)
				if not restored_open:
					ErrorReporter.report_error(
						"SaveLoadSystem",
						"Failed to recover from unreadable save via backup for slot %d" % slot,
						-1,
						true,
						{ "backup_path": backup_path },
					)
				return restored_open
	else:
		ErrorReporter.report_info(ERROR_CONTEXT, "Save file does not exist at slot %d" % slot)
	return false
func _load_from_backup(slot: int) -> bool:
	if not _game_state:
		return false
	var backup_path = "user://gda1_save_slot_%d_backup.dat" % slot
	if not _file_exists(backup_path):
		ErrorReporter.report_warning(ERROR_CONTEXT, "Backup file missing for slot %d" % slot, { "backup_path": backup_path })
		return false
	var save_file = _open_file(backup_path, FileAccess.READ)
	if not save_file:
		var open_error := FileAccess.get_open_error()
		ErrorReporter.report_error(
			"SaveLoadSystem",
			"Failed to open backup save for slot %d" % slot,
			open_error,
			false,
			{ "backup_path": backup_path },
		)
		return false
	var save_data = save_file.get_var()
	save_file.close()
	if not save_data is Dictionary or not (save_data.has("reality_score") or save_data.has("player_stats_data")):
		ErrorReporter.report_warning(
			"SaveLoadSystem",
			"Backup save invalid for slot %d" % slot,
			{ "backup_path": backup_path, "data_type": typeof(save_data) },
		)
		return false
	_game_state.load_save_data(save_data)
	current_save_slot = slot
	ErrorReporter.report_info(ERROR_CONTEXT, "Game loaded from backup slot %d" % slot, { "backup_path": backup_path })
	return true
func load_game() -> bool:
	if not _game_state:
		return false
	if _file_exists("user://gda1_autosave.dat"):
		var save_file = _open_file("user://gda1_autosave.dat", FileAccess.READ)
		if save_file:
			var save_data = save_file.get_var()
			save_file.close()
			if save_data is Dictionary and (save_data.has("reality_score") or save_data.has("player_stats_data")):
				if _migrator.needs_migration(save_data):
					save_data = _migrator.migrate(save_data)
					_rewrite_save_file("user://gda1_autosave.dat", save_data)
				_game_state.load_save_data(save_data)
				return true
	return load_from_slot(current_save_slot)
func load_from_autosave() -> bool:
	if not _game_state:
		ErrorReporter.report_error(ERROR_CONTEXT, "Cannot load autosave: GameState not set", -1)
		return false
	var autosave_path = "user://gda1_autosave.dat"
	if not _file_exists(autosave_path):
		ErrorReporter.report_info(ERROR_CONTEXT, "Autosave file does not exist")
		return false
	var save_file = _open_file(autosave_path, FileAccess.READ)
	if not save_file:
		var error = FileAccess.get_open_error()
		ErrorReporter.report_error(ERROR_CONTEXT, "Failed to open autosave file", error)
		return false
	var save_data = save_file.get_var()
	save_file.close()
	if not save_data is Dictionary or not (save_data.has("reality_score") or save_data.has("player_stats_data")):
		ErrorReporter.report_error(ERROR_CONTEXT, "Autosave data is invalid or corrupted", -1)
		return false
	if _migrator.needs_migration(save_data):
		save_data = _migrator.migrate(save_data)
		_rewrite_save_file(autosave_path, save_data)
	_game_state.load_save_data(save_data)
	ErrorReporter.report_info(ERROR_CONTEXT, "Game loaded from autosave")
	return true
func export_slot_to_path(slot: int, destination_path: String) -> bool:
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var save_path = "user://gda1_save_slot_%d.dat" % slot
	return _export_file(save_path, destination_path, { "slot": slot })
func export_autosave_to_path(destination_path: String) -> bool:
	var autosave_path = "user://gda1_autosave.dat"
	return _export_file(autosave_path, destination_path, {})
func import_slot_from_path(slot: int, source_path: String) -> bool:
	if not _game_state:
		ErrorReporter.report_error(ERROR_CONTEXT, "Cannot import save slot: GameState not set", -1)
		return false
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var target_path = "user://gda1_save_slot_%d.dat" % slot
	var backup_path = "user://gda1_save_slot_%d_backup.dat" % slot
	return _import_file(source_path, target_path, backup_path, false, slot)
func import_autosave_from_path(source_path: String) -> bool:
	if not _game_state:
		ErrorReporter.report_error(ERROR_CONTEXT, "Cannot import autosave: GameState not set", -1)
		return false
	var target_path = "user://gda1_autosave.dat"
	var backup_path = "user://gda1_autosave_backup.dat"
	return _import_file(source_path, target_path, backup_path, true, 0)
func _export_file(source_path: String, destination_path: String, details: Dictionary) -> bool:
	if destination_path.is_empty():
		ErrorReporter.report_warning(ERROR_CONTEXT, "Export destination path is empty", details)
		return false
	if not _file_exists(source_path):
		var missing_details := details.duplicate()
		missing_details["source_path"] = source_path
		ErrorReporter.report_warning(ERROR_CONTEXT, "Export source file does not exist", missing_details)
		return false
	var source_file = _open_file(source_path, FileAccess.READ)
	if not source_file:
		var source_error := FileAccess.get_open_error()
		var source_details := details.duplicate()
		source_details["source_path"] = source_path
		ErrorReporter.report_error(ERROR_CONTEXT, "Failed to open source file for export", source_error, false, source_details)
		return false
	var buffer = source_file.get_buffer(source_file.get_length())
	source_file.close()
	var destination_file = _open_file(destination_path, FileAccess.WRITE)
	if not destination_file:
		var destination_error := FileAccess.get_open_error()
		var destination_details := details.duplicate()
		destination_details["destination_path"] = destination_path
		ErrorReporter.report_error(ERROR_CONTEXT, "Failed to open destination file for export", destination_error, false, destination_details)
		return false
	destination_file.store_buffer(buffer)
	destination_file.close()
	var export_details := details.duplicate()
	export_details["source_path"] = source_path
	export_details["destination_path"] = destination_path
	export_details["bytes"] = buffer.size()
	ErrorReporter.report_info(ERROR_CONTEXT, "Save exported successfully", export_details)
	return true
func _import_file(source_path: String, target_path: String, backup_path: String, is_autosave: bool, slot: int) -> bool:
	if source_path.is_empty():
		ErrorReporter.report_warning(ERROR_CONTEXT, "Import source path is empty", {})
		return false
	if not _file_exists(source_path):
		ErrorReporter.report_warning(ERROR_CONTEXT, "Import source file does not exist", { "source_path": source_path })
		return false
	var source_file = _open_file(source_path, FileAccess.READ)
	if not source_file:
		var source_error := FileAccess.get_open_error()
		ErrorReporter.report_error(ERROR_CONTEXT, "Failed to open import source file", source_error, false, { "source_path": source_path })
		return false
	var imported_data = source_file.get_var()
	source_file.close()
	if not _is_valid_save_data(imported_data):
		ErrorReporter.report_warning(ERROR_CONTEXT, "Imported file is not a valid save file", { "source_path": source_path })
		return false
	if _file_exists(target_path):
		_copy_save_file(target_path, backup_path)
	var normalized_data: Dictionary = imported_data.duplicate(true)
	if _migrator.needs_migration(normalized_data):
		normalized_data = _migrator.migrate(normalized_data)
	normalized_data["save_timestamp"] = Time.get_unix_time_from_system()
	normalized_data["is_autosave"] = is_autosave
	if not is_autosave:
		normalized_data["save_slot"] = slot
	var target_file = _open_file(target_path, FileAccess.WRITE)
	if not target_file:
		var target_error := FileAccess.get_open_error()
		ErrorReporter.report_error(
			"SaveLoadSystem",
			"Failed to write imported save file",
			target_error,
			true,
			{
				"source_path": source_path,
				"target_path": target_path,
			},
		)
		return false
	target_file.store_var(normalized_data)
	target_file.close()
	ErrorReporter.report_info(
		"SaveLoadSystem",
		"Save imported successfully",
		{
			"source_path": source_path,
			"target_path": target_path,
			"is_autosave": is_autosave,
			"slot": slot,
		},
	)
	return true
func _rewrite_save_file(path: String, data: Dictionary) -> void:
	var save_file = _open_file(path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(data)
		save_file.close()
		ErrorReporter.report_info(ERROR_CONTEXT, "Rewrote migrated save", {"path": path, "version": data.get("save_version", 0)})
	else:
		ErrorReporter.report_warning(ERROR_CONTEXT, "Failed to rewrite migrated save", {"path": path})
func _is_valid_save_data(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	return data.has("reality_score") or data.has("player_stats_data")
func _extract_stat(save_data: Dictionary, stat_key: String, fallback: Variant = 0) -> Variant:
	if save_data.has("player_stats_data"):
		return save_data["player_stats_data"].get(stat_key, fallback)
	return save_data.get(stat_key, fallback)
func _build_save_info(save_data: Dictionary, overrides: Dictionary) -> Dictionary:
	var info := {
		"exists": true,
		"timestamp": save_data.get("save_timestamp", 0),
		"reality_score": _extract_stat(save_data, "reality_score"),
		"missions_completed": save_data.get("missions_completed", 0),
		"entropy_level": _extract_stat(save_data, "entropy_level"),
		"save_slot": overrides.get("save_slot", 0),
		"is_autosave": overrides.get("is_autosave", false),
		"save_version": save_data.get("save_version", 0),
		"needs_migration": _migrator.needs_migration(save_data),
	}
	return info
func get_autosave_info() -> Dictionary:
	var save_path = "user://gda1_autosave.dat"
	if not _file_exists(save_path):
		return { "exists": false }
	var save_file = _open_file(save_path, FileAccess.READ)
	if not save_file:
		return { "exists": false }
	var save_data = save_file.get_var()
	save_file.close()
	if not save_data is Dictionary:
		return { "exists": false }
	return _build_save_info(save_data, { "save_slot": save_data.get("save_slot", 0), "is_autosave": true })
func get_save_slot_info(slot: int) -> Dictionary:
	var save_path = "user://gda1_save_slot_%d.dat" % slot
	if not _file_exists(save_path):
		return { "exists": false }
	var save_file = _open_file(save_path, FileAccess.READ)
	if not save_file:
		return { "exists": false }
	var save_data = save_file.get_var()
	save_file.close()
	if not save_data is Dictionary:
		return { "exists": false }
	return _build_save_info(save_data, { "save_slot": slot, "is_autosave": save_data.get("is_autosave", false) })
func get_latest_save_info() -> Dictionary:
	var latest_timestamp: float = -1.0
	var latest_info: Dictionary = { "exists": false }
	var autosave_info := get_autosave_info()
	if autosave_info.get("exists", false):
		latest_timestamp = float(autosave_info.get("timestamp", 0))
		latest_info = autosave_info.duplicate()
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		var slot_info := get_save_slot_info(slot)
		if not slot_info.get("exists", false):
			continue
		var slot_timestamp := float(slot_info.get("timestamp", 0))
		if slot_timestamp > latest_timestamp:
			latest_timestamp = slot_timestamp
			latest_info = slot_info.duplicate()
	if latest_info.get("exists", false):
		return latest_info
	return { "exists": false }
func has_saved_game() -> bool:
	return get_latest_save_info().get("exists", false)
func delete_save_slot(slot: int) -> bool:
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var main_name = "user://gda1_save_slot_%d.dat" % slot
	var backup_name = "user://gda1_save_slot_%d_backup.dat" % slot
	var success = true
	if _file_exists(main_name):
		if not _remove_file(main_name):
			success = false
			ErrorReporter.report_error(ERROR_CONTEXT, "Failed to delete save slot %d" % slot, -1)
		else:
			ErrorReporter.report_info(ERROR_CONTEXT, "Deleted main save file " + main_name)
	if _file_exists(backup_name):
		if _remove_file(backup_name):
			ErrorReporter.report_info(ERROR_CONTEXT, "Deleted backup save file " + backup_name)
	if success:
		ErrorReporter.report_info(ERROR_CONTEXT, "Save slot %d and its backup have been removed." % slot)
	return success
func delete_autosave() -> bool:
	var main_name = "user://gda1_autosave.dat"
	var backup_name = "user://gda1_autosave_backup.dat"
	var success = true
	if _file_exists(main_name):
		if not _remove_file(main_name):
			success = false
			ErrorReporter.report_error(ERROR_CONTEXT, "Failed to delete autosave", -1)
		else:
			ErrorReporter.report_info(ERROR_CONTEXT, "Deleted autosave file")
	if _file_exists(backup_name):
		if _remove_file(backup_name):
			ErrorReporter.report_info(ERROR_CONTEXT, "Deleted autosave backup file")
	if success:
		ErrorReporter.report_info(ERROR_CONTEXT, "Autosave and its backup have been removed.")
	return success
