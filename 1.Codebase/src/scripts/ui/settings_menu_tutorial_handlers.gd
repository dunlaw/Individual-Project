extends RefCounted
class_name SettingsMenuTutorialHandlers
var _play_sfx_fn: Callable           
var _show_notification_fn: Callable  
var _tutorial_progress_label: Label = null
var _tutorial_list_container: VBoxContainer = null
func setup(play_sfx_fn: Callable, show_notification_fn: Callable) -> void:
	_play_sfx_fn          = play_sfx_fn
	_show_notification_fn = show_notification_fn
func set_node_refs(progress_label: Label, list_container: VBoxContainer) -> void:
	_tutorial_progress_label  = progress_label
	_tutorial_list_container  = list_container
func _on_tutorial_enabled_toggled(toggled: bool) -> void:
	_play_sfx_fn.call("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.set_tutorial_enabled(toggled)
		_show_notification_fn.call("Tutorials enabled" if toggled else "Tutorials disabled", true)
func _on_reset_tutorials_pressed() -> void:
	_play_sfx_fn.call("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.reset_tutorials()
		_show_notification_fn.call("All tutorials have been reset!", true)
		update_progress_display()
		update_status_labels()
func _on_trigger_tutorial(step_id: String) -> void:
	_play_sfx_fn.call("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.trigger_tutorial(step_id)
		_show_notification_fn.call("Triggered: " + step_id.replace("_", " ").capitalize(), true)
func update_progress_display() -> void:
	if not _tutorial_progress_label:
		return
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		var progress: float = tutorial_system.get_tutorial_progress()
		var completed_count: int = tutorial_system.get_completed_tutorials().size()
		var total_count: int = tutorial_system.get_all_tutorial_steps().size()
		_tutorial_progress_label.text = "Progress: %d/%d (%.1f%%)" % [completed_count, total_count, progress]
func update_status_labels() -> void:
	if not _tutorial_list_container:
		return
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if not tutorial_system:
		return
	for child in _tutorial_list_container.get_children():
		if child is PanelContainer:
			var status_label = child.find_child("Status_*", true, false)
			if status_label and status_label is Label:
				var step_id: String = status_label.name.replace("Status_", "")
				if tutorial_system.is_tutorial_completed(step_id):
					status_label.text = "✓ Completed"
					status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
				else:
					status_label.text = "Not Seen"
					status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
