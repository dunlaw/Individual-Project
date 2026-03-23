extends RefCounted
class_name SettingsMenuLogActions
static func delete_logs(game_state: Node, notifier: Node, tr_callable: Callable) -> void:
	var success := false
	var files_removed := 0
	var metadata_removed := 0
	if game_state and game_state.has_method("delete_local_logs"):
		var result: Dictionary = game_state.delete_local_logs()
		success = true
		files_removed = int(result.get("files_deleted", 0))
		var removed_variant: Variant = result.get("metadata_keys_removed", [])
		if removed_variant is Array:
			var removed_array: Array = removed_variant
			metadata_removed = removed_array.size()
		game_state.set_metadata("prayer_notice_acknowledged", false)
	var message := ""
	if success:
		message = tr_callable.call("SETTINGS_LOGS_CLEARED") % [files_removed, metadata_removed]
	else:
		message = tr_callable.call("SETTINGS_LOGS_UNAVAILABLE")
	if notifier:
		if success:
			notifier.show_success(message)
		else:
			notifier.show_warning(message)
