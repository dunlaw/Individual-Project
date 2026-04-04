extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ICON_QUIT = preload("res://1.Codebase/src/assets/ui/icon_quit.svg")
const TURNAROUND_BACKGROUND_DIR = "res://1.Codebase/src/assets/backgrounds"
var current_language: String = "en"
var selected_character_id: String = ""
var character_data: Dictionary = {}
var _content_title: Label
var _content_scroll: ScrollContainer
var _content_text: RichTextLabel
var _character_list: VBoxContainer
var _character_portrait: TextureRect
var _graph_view_btn: Button
var _details_container: VBoxContainer
var _graph_container: Control
var _is_graph_mode: bool = false
var _graph_nodes: Dictionary = {}
var _turnaround_overlay: ColorRect
var _turnaround_background: TextureRect
var _turnaround_texture: TextureRect
var _show_turnaround_btn: Button
var _turnaround_background_paths: Array[String] = []
var _last_turnaround_background_path: String = ""
var _turnaround_rng := RandomNumberGenerator.new()
func _ready():
	_turnaround_rng.randomize()
	_load_turnaround_background_paths()
	var game_state = ServiceLocator.get_game_state() if ServiceLocator else null
	current_language = game_state.current_language if game_state else "en"
	_init_character_data()
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
		_rebuild_ui_layout(panel)
		UIStyleManager.fade_in(panel, 0.4)
		UIStyleManager.slide_in_from_bottom(panel, 0.5, 30.0)
	_select_character("protagonist")
func _init_character_data():
	character_data = {
		"protagonist": {
			"name_key": "CHAR_PROTAGONIST_NAME",
			"title_key": "CHAR_PROTAGONIST_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_protagonist.png",
			"desc_key": "CHAR_PROTAGONIST_DESC",
			"turnaround_path": "res://1.Codebase/src/assets/characters/turnaround_protagonist.png"
		},
		"gloria": {
			"name_key": "CHAR_GLORIA_NAME",
			"title_key": "CHAR_GLORIA_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_gloria.png",
			"desc_key": "CHAR_GLORIA_DESC",
			"turnaround_path": "res://1.Codebase/src/assets/characters/turnaround_gloria.png"
		},
		"donkey": {
			"name_key": "CHAR_DONKEY_NAME",
			"title_key": "CHAR_DONKEY_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_donkey.png",
			"desc_key": "CHAR_DONKEY_DESC",
			"turnaround_path": "res://1.Codebase/src/assets/characters/turnaround_donkey.png"
		},
		"ark": {
			"name_key": "CHAR_ARK_NAME",
			"title_key": "CHAR_ARK_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_ark.png",
			"desc_key": "CHAR_ARK_DESC",
			"turnaround_path": "res://1.Codebase/src/assets/characters/turnaround_ark.png"
		},
		"one": {
			"name_key": "CHAR_ONE_NAME",
			"title_key": "CHAR_ONE_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_one.png",
			"desc_key": "CHAR_ONE_DESC",
			"turnaround_path": "res://1.Codebase/src/assets/characters/turnaround_one.png"
		},
		"teacher_chan": {
			"name_key": "CHAR_TEACHER_NAME",
			"title_key": "CHAR_TEACHER_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_teacher_chan.png",
			"desc_key": "CHAR_TEACHER_DESC",
			"turnaround_path": "res://1.Codebase/src/assets/characters/turnaround_teacher_chan.png"
		},
		"fsm": {
			"name_key": "CHAR_FSM_NAME",
			"title_key": "CHAR_FSM_TITLE",
			"icon_path": "res://1.Codebase/src/assets/ui/pray_to_monster.png",
			"desc_key": "CHAR_FSM_DESC"
		}
	}
func _rebuild_ui_layout(panel: Control):
	var children = panel.get_children()
	for child in children:
		if child.get_parent() == panel:
			panel.remove_child(child)
			child.queue_free()
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainLayout"
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 30)
	margin_container.add_theme_constant_override("margin_right", 30)
	margin_container.add_theme_constant_override("margin_top", 30)
	margin_container.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin_container)
	margin_container.add_child(main_hbox)
	var sidebar = VBoxContainer.new()
	sidebar.name = "Sidebar"
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.size_flags_stretch_ratio = 0.3
	sidebar.add_theme_constant_override("separation", 15)
	main_hbox.add_child(sidebar)
	var sidebar_title = Label.new()
	sidebar_title.text = _tr("CHARACTERS_TITLE")
	sidebar_title.add_theme_font_size_override("font_size", 24)
	sidebar_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	sidebar.add_child(sidebar_title)
	_graph_view_btn = Button.new()
	_graph_view_btn.text = " " + _tr("GRAPH_VIEW_TITLE")
	_graph_view_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_graph_view_btn.connect("pressed", Callable(self, "_toggle_graph_view"))
	UIStyleManager.apply_button_style(_graph_view_btn, "secondary", "medium")
	sidebar.add_child(_graph_view_btn)
	var sep = HSeparator.new()
	sidebar.add_child(sep)
	var scroll_sidebar = ScrollContainer.new()
	scroll_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(scroll_sidebar)
	_character_list = VBoxContainer.new()
	_character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_list.add_theme_constant_override("separation", 10)
	scroll_sidebar.add_child(_character_list)
	for key in ["protagonist", "gloria", "donkey", "ark", "one", "teacher_chan", "fsm"]:
		if not character_data.has(key): continue
		var btn = Button.new()
		var char_name = _tr(character_data[key]["name_key"])
		btn.text = char_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.connect("pressed", Callable(self, "_select_character").bind(key))
		UIStyleManager.apply_button_style(btn, "secondary", "medium")
		_character_list.add_child(btn)
	var close_btn = Button.new()
	close_btn.text = _tr("CHAR_BUTTON_CLOSE")
	close_btn.icon = ICON_QUIT
	close_btn.expand_icon = true
	close_btn.connect("pressed", Callable(self, "_on_close_pressed"))
	UIStyleManager.apply_button_style(close_btn, "primary", "medium")
	sidebar.add_child(close_btn)
	var content_area = VBoxContainer.new()
	content_area.name = "ContentArea"
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.size_flags_stretch_ratio = 0.7
	main_hbox.add_child(content_area)
	var spacer = VSeparator.new()
	spacer.add_theme_constant_override("separation", 40)
	main_hbox.add_child(spacer)
	main_hbox.move_child(spacer, 1)
	_graph_container = Control.new()
	_graph_container.name = "GraphContainer"
	_graph_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_container.visible = false
	content_area.add_child(_graph_container)
	_details_container = VBoxContainer.new()
	_details_container.name = "DetailsContainer"
	_details_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_child(_details_container)
	_character_portrait = TextureRect.new()
	_character_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_character_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_character_portrait.custom_minimum_size = Vector2(320, 320)
	_character_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var portrait_row = HBoxContainer.new()
	portrait_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_row.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_row.add_theme_constant_override("separation", 24)
	_details_container.add_child(portrait_row)
	portrait_row.add_child(_character_portrait)
	var action_column = VBoxContainer.new()
	action_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_column.add_theme_constant_override("separation", 10)
	portrait_row.add_child(action_column)
	_show_turnaround_btn = Button.new()
	_show_turnaround_btn.text = _tr("CHAR_BUTTON_REFERENCE")
	_show_turnaround_btn.custom_minimum_size = Vector2(220, 72)
	_show_turnaround_btn.connect("pressed", Callable(self, "_on_show_turnaround_pressed"))
	UIStyleManager.apply_button_style(_show_turnaround_btn, "accent", "large")
	action_column.add_child(_show_turnaround_btn)
	var turnaround_hint = Label.new()
	turnaround_hint.text = "Front / Side / Back"
	turnaround_hint.add_theme_font_size_override("font_size", 14)
	turnaround_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	turnaround_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_column.add_child(turnaround_hint)
	_turnaround_overlay = ColorRect.new()
	_turnaround_overlay.color = Color(0, 0, 0, 0.88)
	_turnaround_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_turnaround_overlay.visible = false
	panel.add_child(_turnaround_overlay)
	var overlay_margin = MarginContainer.new()
	overlay_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_margin.add_theme_constant_override("margin_left", 48)
	overlay_margin.add_theme_constant_override("margin_right", 48)
	overlay_margin.add_theme_constant_override("margin_top", 36)
	overlay_margin.add_theme_constant_override("margin_bottom", 36)
	_turnaround_overlay.add_child(overlay_margin)
	var overlay_panel = PanelContainer.new()
	UIStyleManager.apply_panel_style(overlay_panel, 0.98, UIStyleManager.CORNER_RADIUS_LARGE)
	overlay_margin.add_child(overlay_panel)
	var overlay_vbox = VBoxContainer.new()
	overlay_vbox.add_theme_constant_override("separation", 16)
	overlay_panel.add_child(overlay_vbox)
	var overlay_header = HBoxContainer.new()
	overlay_header.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_vbox.add_child(overlay_header)
	var overlay_title = Label.new()
	overlay_title.text = _tr("CHAR_BUTTON_REFERENCE")
	overlay_title.add_theme_font_size_override("font_size", 26)
	overlay_title.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	overlay_header.add_child(overlay_title)
	var turnaround_preview = Control.new()
	turnaround_preview.custom_minimum_size = Vector2(960, 680)
	turnaround_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turnaround_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	turnaround_preview.clip_contents = true
	overlay_vbox.add_child(turnaround_preview)
	var turnaround_preview_frame = PanelContainer.new()
	turnaround_preview_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	turnaround_preview_frame.clip_contents = true
	var turnaround_preview_style = StyleBoxFlat.new()
	turnaround_preview_style.bg_color = Color(0.06, 0.08, 0.11, 0.96)
	turnaround_preview_style.corner_radius_top_left = 24
	turnaround_preview_style.corner_radius_top_right = 24
	turnaround_preview_style.corner_radius_bottom_right = 24
	turnaround_preview_style.corner_radius_bottom_left = 24
	turnaround_preview_style.border_width_left = 2
	turnaround_preview_style.border_width_top = 2
	turnaround_preview_style.border_width_right = 2
	turnaround_preview_style.border_width_bottom = 2
	turnaround_preview_style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	turnaround_preview_frame.add_theme_stylebox_override("panel", turnaround_preview_style)
	turnaround_preview.add_child(turnaround_preview_frame)
	_turnaround_background = TextureRect.new()
	_turnaround_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_turnaround_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_turnaround_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_turnaround_background.modulate = Color(1.0, 1.0, 1.0, 0.92)
	turnaround_preview_frame.add_child(_turnaround_background)
	var turnaround_shade = ColorRect.new()
	turnaround_shade.color = Color(0.04, 0.05, 0.08, 0.28)
	turnaround_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	turnaround_preview_frame.add_child(turnaround_shade)
	var turnaround_margin = MarginContainer.new()
	turnaround_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	turnaround_margin.add_theme_constant_override("margin_left", 24)
	turnaround_margin.add_theme_constant_override("margin_right", 24)
	turnaround_margin.add_theme_constant_override("margin_top", 24)
	turnaround_margin.add_theme_constant_override("margin_bottom", 24)
	turnaround_preview_frame.add_child(turnaround_margin)
	_turnaround_texture = TextureRect.new()
	_turnaround_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_turnaround_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_turnaround_texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turnaround_texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	turnaround_margin.add_child(_turnaround_texture)
	var close_turnaround_btn = Button.new()
	close_turnaround_btn.text = _tr("CHAR_BUTTON_CLOSE")
	close_turnaround_btn.icon = ICON_QUIT
	close_turnaround_btn.expand_icon = true
	close_turnaround_btn.custom_minimum_size = Vector2(220, 56)
	close_turnaround_btn.connect("pressed", Callable(self, "_on_close_turnaround_pressed"))
	UIStyleManager.apply_button_style(close_turnaround_btn, "primary", "medium")
	close_turnaround_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	overlay_vbox.add_child(close_turnaround_btn)
	_content_title = Label.new()
	_content_title.text = ""
	_content_title.add_theme_font_size_override("font_size", 32)
	_content_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	_content_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_container.add_child(_content_title)
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_container.add_child(_content_scroll)
	_content_text = RichTextLabel.new()
	_content_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_text.fit_content = true
	_content_text.bbcode_enabled = true
	_content_text.add_theme_font_size_override("normal_font_size", 18)
	_content_text.add_theme_constant_override("line_separation", 6)
	_content_scroll.add_child(_content_text)
func _select_character(char_key: String):
	if char_key not in character_data:
		return
	_is_graph_mode = false
	if _graph_container: _graph_container.visible = false
	if _details_container: _details_container.visible = true
	if _graph_view_btn: UIStyleManager.apply_button_style(_graph_view_btn, "secondary", "medium")
	selected_character_id = char_key
	var data = character_data[char_key]
	var name_text = _tr(data["name_key"])
	var title_text = _tr(data["title_key"])
	var icon_path = data.get("icon_path", "")
	var portrait_tex = null
	if icon_path != "":
		portrait_tex = _load_texture_safe(icon_path)
	if portrait_tex:
		_character_portrait.texture = portrait_tex
		_character_portrait.visible = true
	else:
		_character_portrait.texture = null
		_character_portrait.visible = false
	var turnaround_path = data.get("turnaround_path", "")
	if _show_turnaround_btn:
		_show_turnaround_btn.visible = turnaround_path != "" and ResourceLoader.exists(turnaround_path)
	_content_title.text = name_text + "\n" + title_text
	_content_title.add_theme_font_size_override("font_size", 32)
	var desc_text = _tr(data["desc_key"])
	_content_text.text = desc_text.replace("\\n", "\n")
	var child_idx = 0
	var keys = ["protagonist", "gloria", "donkey", "ark", "one", "teacher_chan", "fsm"]
	for btn in _character_list.get_children():
		if btn is Button:
			if child_idx < keys.size():
				if keys[child_idx] == char_key:
					UIStyleManager.apply_button_style(btn, "primary", "medium")
				else:
					UIStyleManager.apply_button_style(btn, "secondary", "medium")
			child_idx += 1
func _on_show_turnaround_pressed():
	if selected_character_id == "" or not character_data.has(selected_character_id):
		return
	var data = character_data[selected_character_id]
	var turnaround_path = data.get("turnaround_path", "")
	if turnaround_path == "":
		return
	var tex = _load_texture_safe(turnaround_path)
	if tex and _turnaround_overlay and _turnaround_texture:
		_apply_random_turnaround_background()
		_turnaround_texture.texture = tex
		_turnaround_overlay.visible = true
		_turnaround_overlay.move_to_front()
func _on_close_turnaround_pressed():
	if _turnaround_overlay:
		_turnaround_overlay.visible = false
func _on_close_pressed():
	queue_free()
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE:
			if _turnaround_overlay and _turnaround_overlay.visible:
				_on_close_turnaround_pressed()
			else:
				_on_close_pressed()
			get_viewport().set_input_as_handled()
		KEY_G:
			_toggle_graph_view()
			get_viewport().set_input_as_handled()
func _toggle_graph_view():
	_is_graph_mode = true
	if _details_container: _details_container.visible = false
	if _graph_container: _graph_container.visible = true
	if _graph_view_btn: UIStyleManager.apply_button_style(_graph_view_btn, "primary", "medium")
	for btn in _character_list.get_children():
		if btn is Button:
			UIStyleManager.apply_button_style(btn, "secondary", "medium")
	_render_graph()
func _render_graph():
	if not _graph_container: return
	for child in _graph_container.get_children():
		child.queue_free()
	_graph_nodes.clear()
	var center = _graph_container.size / 2
	if center == Vector2.ZERO: center = Vector2(400, 300)
	_create_graph_node("protagonist", center)
	var teammates = ["gloria", "donkey", "ark", "one"]
	var radius = 200.0
	var angle_step = TAU / teammates.size()
	for i in range(teammates.size()):
		var angle = i * angle_step - PI/2
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		_create_graph_node(teammates[i], pos)
	_draw_relationship_lines()
	for node in _graph_nodes.values():
		node.move_to_front()
func _create_graph_node(char_key: String, position: Vector2):
	if not character_data.has(char_key): return
	var data = character_data[char_key]
	var node = VBoxContainer.new()
	node.position = position - Vector2(50, 50)
	node.custom_minimum_size = Vector2(100, 120)
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(80, 80)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var icon_path = data.get("icon_path", "")
	if icon_path != "":
		tex_rect.texture = _load_texture_safe(icon_path)
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 40
	style.corner_radius_top_right = 40
	style.corner_radius_bottom_right = 40
	style.corner_radius_bottom_left = 40
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(tex_rect)
	node.add_child(panel)
	var label = Label.new()
	label.text = _tr(data["name_key"]).split("|")[0]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(label)
	_graph_container.add_child(node)
	_graph_nodes[char_key] = node
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_character(char_key)
	)
func _draw_relationship_lines():
	var player_node = _graph_nodes.get("protagonist")
	if not player_node: return
	var player_center = player_node.position + Vector2(50, 50)
	for key in _graph_nodes:
		if key == "protagonist": continue
		var target_node = _graph_nodes[key]
		var target_center = target_node.position + Vector2(50, 50)
		var status = _get_relationship_status(key)
		var color = status.color
		var width = status.width
		var line = Line2D.new()
		line.add_point(player_center)
		line.add_point(target_center)
		line.width = width
		line.default_color = color
		line.antialiased = true
		_graph_container.add_child(line)
		var mid_point = (player_center + target_center) / 2
		var status_label = Label.new()
		status_label.text = status.text
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_color_override("font_color", color)
		status_label.add_theme_font_size_override("font_size", 14)
		var bg = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.7)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		bg.add_theme_stylebox_override("panel", style)
		bg.position = mid_point - Vector2(30, 10)
		bg.add_child(status_label)
		_graph_container.add_child(bg)
func _get_relationship_status(char_key: String) -> Dictionary:
	var game_state = ServiceLocator.get_game_state() if ServiceLocator else null
	if not game_state: return {"color": Color.GRAY, "width": 2, "text": "?"}
	var reality = game_state.reality_score
	var positive = game_state.positive_energy
	var result = {"color": Color.GRAY, "width": 2, "text": "RELATIONSHIP_NEUTRAL"}
	match char_key:
		"gloria":
			if positive > 60 and reality < 40:
				result = {"color": Color.GREEN, "width": 4, "text": "RELATIONSHIP_DEVOTED"}
			elif reality > 60:
				result = {"color": Color.RED, "width": 3, "text": "RELATIONSHIP_HOSTILE"}
			elif positive < 30:
				result = {"color": Color.ORANGE, "width": 2, "text": "RELATIONSHIP_SUSPICIOUS"}
		"donkey":
			if positive > 60:
				result = {"color": Color.GREEN, "width": 4, "text": "RELATIONSHIP_LOYAL"}
			elif positive < 40:
				result = {"color": Color.ORANGE, "width": 2, "text": "RELATIONSHIP_DISAPPOINTED"}
		"ark":
			if reality > 40:
				result = {"color": Color.CYAN, "width": 3, "text": "RELATIONSHIP_ALIGNED"}
			elif reality < 30:
				result = {"color": Color.RED, "width": 3, "text": "RELATIONSHIP_CRITICAL"}
		"one":
			if reality < 55 and positive < 45:
				result = {"color": Color.PURPLE, "width": 3, "text": "RELATIONSHIP_SYMPATHETIC"}
			elif positive > 70:
				result = {"color": Color.GRAY, "width": 1, "text": "RELATIONSHIP_DISTANT"}
	result.text = _tr(result.text)
	return result
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return tr(key)
func _load_turnaround_background_paths() -> void:
	_turnaround_background_paths.clear()
	var dir := DirAccess.open(TURNAROUND_BACKGROUND_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var extension := file_name.get_extension().to_lower()
			if extension in ["png", "jpg", "jpeg", "webp"]:
				var file_path := "%s/%s" % [TURNAROUND_BACKGROUND_DIR, file_name]
				if ResourceLoader.exists(file_path):
					_turnaround_background_paths.append(file_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	_turnaround_background_paths.sort()
func _apply_random_turnaround_background() -> void:
	if not _turnaround_background:
		return
	if _turnaround_background_paths.is_empty():
		_turnaround_background.texture = null
		return
	var candidate_paths: Array[String] = []
	for background_path in _turnaround_background_paths:
		if background_path != _last_turnaround_background_path:
			candidate_paths.append(background_path)
	if candidate_paths.is_empty():
		candidate_paths = _turnaround_background_paths.duplicate()
	var selected_index := _turnaround_rng.randi_range(0, candidate_paths.size() - 1)
	var selected_path := candidate_paths[selected_index]
	var background_texture := _load_texture_safe(selected_path)
	if background_texture:
		_turnaround_background.texture = background_texture
		_last_turnaround_background_path = selected_path
	else:
		_turnaround_background.texture = null
func _load_texture_safe(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
