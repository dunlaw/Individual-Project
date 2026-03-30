extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const StoryExporterScript = preload("res://1.Codebase/src/scripts/core/story_exporter.gd")
const ICON_SAVE = preload("res://1.Codebase/src/assets/ui/icon_save.svg")
const ICON_CLOSE = preload("res://1.Codebase/src/assets/ui/icon_close.svg")
const ICON_CREATIVE = preload("res://1.Codebase/src/assets/ui/icon_creative.svg")
signal close_requested
@onready var backdrop: ColorRect = $Backdrop
@onready var panel: Panel = $ModalRoot/Panel
@onready var title_label: Label = $ModalRoot/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $ModalRoot/Panel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var info_box: VBoxContainer = $ModalRoot/Panel/MarginContainer/VBoxContainer/InfoBox
@onready var status_label: Label = $ModalRoot/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var export_button: Button = $ModalRoot/Panel/MarginContainer/VBoxContainer/ButtonRow/ExportButton
@onready var close_button: Button = $ModalRoot/Panel/MarginContainer/VBoxContainer/ButtonRow/CloseButton
var _file_dialog: FileDialog = null
var _exporter: StoryExporter = null
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_exporter = StoryExporterScript.new()
	_setup_file_dialog()
	_apply_styles()
	_apply_locale()
	_populate_info()
	_connect_signals()
	if panel:
		UIStyleManager.fade_in(panel, 0.25)
		UIStyleManager.slide_in_from_bottom(panel, 0.35, 20.0)
	if export_button:
		export_button.grab_focus()
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).keycode == KEY_ESCAPE:
		_on_close_pressed()
		get_viewport().set_input_as_handled()
func _apply_locale() -> void:
	if title_label:
		title_label.text = _tr("EXPORT_STORY_TITLE")
	if subtitle_label:
		subtitle_label.text = _tr("EXPORT_STORY_SUBTITLE")
	if export_button:
		export_button.text = _tr("EXPORT_STORY_BUTTON")
	if close_button:
		close_button.text = _tr("EXPORT_STORY_CANCEL")
func _apply_styles() -> void:
	if export_button:
		UIStyleManager.apply_button_style(export_button, "accent", "large")
		export_button.icon = ICON_SAVE
		export_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(export_button, 1.05)
		UIStyleManager.add_press_feedback(export_button)
		export_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if close_button:
		UIStyleManager.apply_button_style(close_button, "primary", "medium")
		close_button.icon = ICON_CLOSE
		close_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(close_button, 1.05)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _populate_info() -> void:
	if not info_box:
		return
	var game_state = GameState if GameState else null
	var butterfly = game_state.butterfly_tracker if game_state else null
	var choices_count := 0
	var missions_count := 0
	var scene_count := 0
	if butterfly:
		choices_count = butterfly.recorded_choices.size()
		scene_count = butterfly.current_scene_number
	if game_state:
		missions_count = game_state.missions_completed
	for child in info_box.get_children():
		child.queue_free()
	var rows := [
		[_tr("EXPORT_STORY_INFO_CHOICES"), str(choices_count)],
		[_tr("EXPORT_STORY_INFO_MISSIONS"), str(missions_count)],
		[_tr("EXPORT_STORY_INFO_SCENES"), str(scene_count)],
		[_tr("EXPORT_STORY_INFO_FORMAT"), "HTML (printable as PDF)"],
	]
	for row in rows:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		var lbl_key := Label.new()
		lbl_key.text = row[0]
		lbl_key.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
		lbl_key.add_theme_font_size_override("font_size", 18)
		lbl_key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lbl_val := Label.new()
		lbl_val.text = row[1]
		lbl_val.add_theme_font_size_override("font_size", 18)
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(lbl_key)
		hbox.add_child(lbl_val)
		info_box.add_child(hbox)
func _connect_signals() -> void:
	if export_button and not export_button.pressed.is_connected(_on_export_pressed):
		export_button.pressed.connect(_on_export_pressed)
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
func _setup_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.add_filter("*.html", "HTML Document")
	_file_dialog.title = _tr("EXPORT_STORY_FILEDLG_TITLE")
	add_child(_file_dialog)
	_file_dialog.file_selected.connect(_on_file_selected)
func _on_export_pressed() -> void:
	var game_state = GameState if GameState else null
	var butterfly = game_state.butterfly_tracker if game_state else null
	if butterfly == null or butterfly.recorded_choices.is_empty():
		_set_status(_tr("EXPORT_STORY_NO_DATA"), true)
		return
	var default_name := "GDA_Story.html"
	if game_state:
		default_name = _exporter.get_default_filename(game_state)
	_file_dialog.current_file = default_name
	_file_dialog.popup_centered_ratio(0.7)
func _on_file_selected(path: String) -> void:
	_set_status(_tr("EXPORT_STORY_GENERATING"), false)
	await get_tree().process_frame  
	var game_state = GameState if GameState else null
	var butterfly = game_state.butterfly_tracker if game_state else null
	var html_content := _exporter.generate_html(game_state, butterfly)
	var ok := _exporter.save_to_file(html_content, path)
	if ok:
		_set_status(_tr("EXPORT_STORY_SUCCESS") + "\n" + path.get_file(), false)
	else:
		_set_status(_tr("EXPORT_STORY_ERROR"), true)
func _set_status(message: String, is_error: bool) -> void:
	if status_label:
		status_label.text = message
		if is_error:
			status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
func _on_close_pressed() -> void:
	emit_signal("close_requested")
