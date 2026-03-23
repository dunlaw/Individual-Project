extends Control
signal accepted
signal cancelled
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const NOTICE_TITLE_EN := "Data Use Notice"
const NOTICE_BODY_EN := "[b]Before you submit a prayer[/b]\n\n- Your text may be sent to a third-party AI service when a cloud model is enabled.\n- The full request is also stored in local logs for debugging and evaluation.\n- Please avoid entering personal, sensitive, or identifying information.\n\nYou can delete stored logs anytime from the Settings menu."
const NOTICE_TITLE_ZH := "Data Usage Notice"
const NOTICE_BODY_ZH := "[b]Before you begin praying, please understand:[/b]

- If you choose a cloud model, your input text will be sent to a third-party AI service.
- Complete request content will also be stored in local records for debugging and experience evaluation.
- Please do not enter any personal data, sensitive information, or identifiable content.

You can adjust these settings at any time in the Settings menu."
var current_language: String = "en"
var _is_closing: bool = false
@onready var panel: Panel = $MenuContainer/Panel
@onready var title_label: Label = $MenuContainer/Panel/VBoxContainer/TitleLabel
@onready var body_text: RichTextLabel = $MenuContainer/Panel/VBoxContainer/BodyText
@onready var cancel_button: Button = $MenuContainer/Panel/VBoxContainer/Buttons/CancelButton
@onready var accept_button: Button = $MenuContainer/Panel/VBoxContainer/Buttons/AcceptButton
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_language = GameState.current_language if GameState else "en"
	_apply_styles()
	_setup_keyboard_support()
	_update_text()
	if panel:
		panel.modulate.a = 0.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	_focus_default_button.call_deferred()
func _setup_keyboard_support() -> void:
	if accept_button:
		accept_button.focus_mode = Control.FOCUS_ALL
	if cancel_button:
		cancel_button.focus_mode = Control.FOCUS_ALL
	if accept_button and cancel_button:
		accept_button.focus_neighbor_left = accept_button.get_path_to(cancel_button)
		accept_button.focus_neighbor_right = accept_button.get_path_to(cancel_button)
		cancel_button.focus_neighbor_left = cancel_button.get_path_to(accept_button)
		cancel_button.focus_neighbor_right = cancel_button.get_path_to(accept_button)
		accept_button.focus_previous = accept_button.get_path_to(cancel_button)
		accept_button.focus_next = accept_button.get_path_to(cancel_button)
		cancel_button.focus_previous = cancel_button.get_path_to(accept_button)
		cancel_button.focus_next = cancel_button.get_path_to(accept_button)
func _focus_default_button() -> void:
	if accept_button and accept_button.visible and not accept_button.disabled:
		accept_button.grab_focus()
	elif cancel_button and cancel_button.visible and not cancel_button.disabled:
		cancel_button.grab_focus()
func _input(event: InputEvent) -> void:
	if _is_closing or not visible:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.is_action_pressed("ui_cancel"):
		_on_cancel_button_pressed()
		get_viewport().set_input_as_handled()
		return
	if key_event.is_action_pressed("ui_left"):
		_focus_cancel_button()
		get_viewport().set_input_as_handled()
		return
	if key_event.is_action_pressed("ui_right"):
		_focus_accept_button()
		get_viewport().set_input_as_handled()
		return
	if key_event.is_action_pressed("ui_accept") and not _has_notice_button_focus():
		_on_accept_button_pressed()
		get_viewport().set_input_as_handled()
func _focus_cancel_button() -> void:
	if cancel_button and cancel_button.visible and not cancel_button.disabled:
		cancel_button.grab_focus()
func _focus_accept_button() -> void:
	if accept_button and accept_button.visible and not accept_button.disabled:
		accept_button.grab_focus()
func _has_notice_button_focus() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner == accept_button or focus_owner == cancel_button
func _apply_styles() -> void:
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.96, UIStyleManager.CORNER_RADIUS_LARGE)
	if accept_button:
		UIStyleManager.apply_button_style(accept_button, "accent", "large")
		UIStyleManager.add_hover_scale_effect(accept_button, 1.05)
		UIStyleManager.add_press_feedback(accept_button)
		accept_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if cancel_button:
		UIStyleManager.apply_button_style(cancel_button, "secondary", "large")
		UIStyleManager.add_hover_scale_effect(cancel_button, 1.05)
		UIStyleManager.add_press_feedback(cancel_button)
		cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	if body_text:
		body_text.bbcode_enabled = true
		body_text.add_theme_color_override("default_color", Color(0.88, 0.9, 1.0))
func _update_text() -> void:
	if current_language.begins_with("zh"):
		title_label.text = NOTICE_TITLE_ZH
		body_text.text = NOTICE_BODY_ZH
		cancel_button.text = _tr("PRAYER_NOTICE_CANCEL")
		accept_button.text = _tr("PRAYER_NOTICE_ACCEPT")
	else:
		title_label.text = NOTICE_TITLE_EN
		body_text.text = NOTICE_BODY_EN
		cancel_button.text = "Cancel"
		accept_button.text = "I Understand"
func _on_cancel_button_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	cancelled.emit()
	queue_free()
func _on_accept_button_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	accepted.emit()
	queue_free()
