extends RefCounted
var metadata: Dictionary = {}
func _duplicate_variant(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
func set_value(key: String, value: Variant) -> void:
	metadata[key] = _duplicate_variant(value)
func get_value(key: String, default_value: Variant = null) -> Variant:
	if metadata.has(key):
		return metadata[key]
	return default_value
func has_key(key: String) -> bool:
	return metadata.has(key)
func erase_key(key: String) -> bool:
	return metadata.erase(key)
func clear() -> void:
	metadata.clear()
func duplicate_data() -> Dictionary:
	return metadata.duplicate(true)
func set_latest_story_text(text: String) -> void:
	metadata["latest_story_text"] = text
	metadata["latest_story_timestamp"] = Time.get_datetime_string_from_system()
	metadata["latest_story_summary"] = ""
	metadata["latest_story_summary_pending"] = true
	_add_to_story_history(text)
func get_latest_story_text(default_value: String = "") -> String:
	var text_value = get_value("latest_story_text", default_value)
	return str(text_value)
func set_latest_story_summary(summary: String) -> void:
	metadata["latest_story_summary"] = summary
	metadata["latest_story_summary_pending"] = false
func get_latest_story_summary(default_value: String = "") -> String:
	var summary_value = get_value("latest_story_summary", default_value)
	return str(summary_value)
func is_story_summary_pending() -> bool:
	return bool(get_value("latest_story_summary_pending", false))
func get_journal_entries() -> Array:
	var stored = get_value("journal_entries", [])
	if stored is Array:
		return (stored as Array).duplicate(false)
	return []
func set_journal_entries(entries: Array) -> void:
	metadata["journal_entries"] = entries.duplicate(true)
func append_journal_entry(entry: Dictionary) -> void:
	var entries = get_journal_entries()
	entries.append(entry.duplicate(true))
	set_journal_entries(entries)
func get_recent_journal_entries(limit: int = 3) -> Array:
	var entries = get_journal_entries()
	if entries.is_empty():
		return []
	var count: int = min(limit, entries.size())
	var start: int = max(0, entries.size() - count)
	return entries.slice(start, entries.size())
func delete_local_logs() -> Dictionary:
	var result := {
		"metadata_keys_removed": [],
		"files_deleted": 0,
	}
	var metadata_log_keys: Array[String] = [
		"latest_story_text",
		"latest_story_timestamp",
		"recent_assets_data",
		"recent_asset_icons",
		"current_asset_ids",
	]
	var metadata_keys_removed: Array[String] = []
	for key in metadata_log_keys:
		if metadata.has(key):
			metadata.erase(key)
			metadata_keys_removed.append(key)
	result["metadata_keys_removed"] = metadata_keys_removed
	result["files_deleted"] = _delete_log_files()
	return result
func _delete_log_files() -> int:
	var removed := 0
	var root := DirAccess.open("user://")
	if root == null:
		return removed
	var log_dirs: Array[String] = ["logs", "gda1_logs", "gda1_debug_logs", "gda1_prayer_logs"]
	for dir_name in log_dirs:
		if root.dir_exists(dir_name):
			removed += _delete_directory_contents("user://%s" % dir_name)
	var removable_files: Array[String] = []
	root.list_dir_begin()
	while true:
		var name := root.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		if root.current_is_dir():
			continue
		var lower := name.to_lower()
		if lower.ends_with(".log") or lower.ends_with(".jsonl") or (lower.ends_with(".txt") and lower.find("_log") != -1):
			removable_files.append(name)
	root.list_dir_end()
	var remover := DirAccess.open("user://")
	if remover:
		for file_name in removable_files:
			if remover.file_exists(file_name):
				if remover.remove(file_name) == OK:
					removed += 1
	return removed
func _delete_directory_contents(path: String) -> int:
	var removed := 0
	var dir := DirAccess.open(path)
	if dir == null:
		return removed
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		if dir.current_is_dir():
			removed += _delete_directory_contents("%s/%s" % [path, name])
		else:
			if dir.remove(name) == OK:
				removed += 1
	dir.list_dir_end()
	return removed
func _add_to_story_history(text: String) -> void:
	var history = get_value("story_history", [])
	if not (history is Array):
		history = []
	var entry = {
		"text": text,
		"timestamp": Time.get_datetime_string_from_system(),
		"mission": get_value("current_mission", 0),
	}
	history.append(entry)
	if history.size() > 20:
		history = history.slice(history.size() - 20, history.size())
	metadata["story_history"] = history
func get_story_history() -> Array:
	var history = get_value("story_history", [])
	if history is Array:
		return (history as Array).duplicate(false)
	return []
func get_story_history_count() -> int:
	var history = get_story_history()
	return history.size()
func get_story_at_index(index: int) -> String:
	var history = get_story_history()
	if index >= 0 and index < history.size():
		var entry = history[index]
		if entry is Dictionary:
			return str(entry.get("text", ""))
	return ""
func clear_story_history() -> void:
	metadata["story_history"] = []
func get_save_data() -> Dictionary:
	return metadata.duplicate(true)
func load_save_data(data: Dictionary) -> void:
	metadata = data.duplicate(true) if data is Dictionary else {}
