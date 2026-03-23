extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var current_language: String = "en"
var _audio_manager: Node = null
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready():
	current_language = GameState.current_language if GameState else "en"
	_apply_modern_styling()
	update_ui_text()
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
func _apply_modern_styling():
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	var close_button = $MenuContainer/Panel/VBoxContainer/CloseButton
	if close_button:
		UIStyleManager.apply_button_style(close_button, "accent", "large")
		UIStyleManager.add_hover_scale_effect(close_button, 1.06)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
func _on_close_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	var parent = get_parent()
	if parent and (parent.name == "StartMenu" or parent.get_script() and parent.get_script().get_path().contains("start_menu")):
		queue_free()
	else:
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/start_menu.tscn")
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func update_ui_text():
	$MenuContainer/Panel/VBoxContainer/TitleLabel.text = _tr("TERMS_TITLE")
	$MenuContainer/Panel/VBoxContainer/ScrollContainer/BodyLabel.text = _tr("TERMS_BODY")
	$MenuContainer/Panel/VBoxContainer/CloseButton.text = _tr("TERMS_ACCEPT_BUTTON")
