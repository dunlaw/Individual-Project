extends PanelContainer
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
@onready var icon_label: Label = $MarginContainer/HBoxContainer/IconLabel
@onready var message_label: Label = $MarginContainer/HBoxContainer/MessageLabel
var lifetime: float = 3.0
var fade_duration: float = 0.3
func setup(title: String, description: String, color: Color, duration: float, icon_path: String = "", header: String = ""):
	lifetime = duration
	if not icon_path.is_empty():
		_setup_achievement_layout(title, description, icon_path, header)
	else:
		_setup_standard_layout(title, description, color)
	_animate_entrance()
	await get_tree().create_timer(lifetime).timeout
	_animate_exit()
func _setup_standard_layout(title: String, description: String, color: Color):
	icon_label.modulate = color
	var hbox = icon_label.get_parent()
	var content_vbox = hbox.get_node_or_null("ContentVBox")
	if not content_vbox:
		content_vbox = VBoxContainer.new()
		content_vbox.name = "ContentVBox"
		content_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		content_vbox.size_flags_vertical = SIZE_SHRINK_CENTER
		hbox.add_child(content_vbox)
		hbox.move_child(content_vbox, 1)
		message_label.visible = false
	for child in content_vbox.get_children():
		child.queue_free()
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.modulate = Color.WHITE
	content_vbox.add_child(lbl_title)
	if not description.is_empty():
		var lbl_desc = Label.new()
		lbl_desc.text = description
		lbl_desc.add_theme_font_size_override("font_size", 14)
		lbl_desc.modulate = Color(0.9, 0.9, 0.9, 0.9)
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_desc.size_flags_horizontal = SIZE_EXPAND_FILL
		content_vbox.add_child(lbl_desc)
	custom_minimum_size = Vector2(0, 0)
	size_flags_vertical = SIZE_SHRINK_CENTER
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.12, 0.16, 0.95)
	style_box.border_color = color
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_size = 8
	style_box.shadow_offset = Vector2(0, 4)
	style_box.content_margin_left = 12
	style_box.content_margin_top = 10
	style_box.content_margin_right = 12
	style_box.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style_box)
	if color.r > 0.8 and color.g < 0.5:
		icon_label.text = ""
	elif color.r > 0.8 and color.g > 0.6:
		icon_label.text = ""
	elif color.g > 0.8 and color.r < 0.5:
		icon_label.text = "✓"
	else:
		icon_label.text = ""
func _setup_achievement_layout(title: String, description: String, icon_path: String, header: String = ""):
	icon_label.visible = false
	message_label.visible = false
	var hbox = icon_label.get_parent()
	var existing_icon = hbox.get_node_or_null("AchievementIcon")
	if existing_icon:
		existing_icon.queue_free()
	var existing_vbox = hbox.get_node_or_null("ContentVBox")
	if existing_vbox:
		existing_vbox.queue_free()
	var texture_rect = TextureRect.new()
	texture_rect.name = "AchievementIcon"
	texture_rect.custom_minimum_size = Vector2(64, 64)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.size_flags_vertical = SIZE_SHRINK_CENTER
	var loaded_tex = load(icon_path)
	if loaded_tex:
		texture_rect.texture = loaded_tex
	hbox.add_child(texture_rect)
	hbox.move_child(texture_rect, 0)
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = SIZE_SHRINK_CENTER
	content_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(content_vbox)
	var lbl_header = Label.new()
	lbl_header.text = header if not header.is_empty() else "★  Achievement Unlocked"
	lbl_header.add_theme_font_size_override("font_size", 11)
	lbl_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	content_vbox.add_child(lbl_header)
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(lbl_title)
	if not description.is_empty():
		var lbl_desc = Label.new()
		lbl_desc.text = description
		lbl_desc.add_theme_font_size_override("font_size", 13)
		lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7, 0.9))
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_desc.size_flags_horizontal = SIZE_EXPAND_FILL
		content_vbox.add_child(lbl_desc)
	custom_minimum_size = Vector2(420, 0)
	size_flags_vertical = SIZE_SHRINK_CENTER
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.09, 0.05, 0.97)
	style_box.border_color = Color(0.2, 0.8, 0.2, 1.0)
	style_box.border_width_left = 4
	style_box.border_width_top = 4
	style_box.border_width_right = 4
	style_box.border_width_bottom = 4
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.shadow_color = Color(0.1, 0.7, 0.1, 0.7)
	style_box.shadow_size = 12
	style_box.shadow_offset = Vector2(0, 4)
	style_box.content_margin_left = 14
	style_box.content_margin_top = 12
	style_box.content_margin_right = 14
	style_box.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style_box)
	_animate_achievement_glow(style_box)
func _animate_achievement_glow(style_box: StyleBoxFlat):
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(
		func(v: float):
			style_box.shadow_size = v
			add_theme_stylebox_override("panel", style_box),
		10.0, 22.0, 1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(v: float):
			style_box.shadow_size = v
			add_theme_stylebox_override("panel", style_box),
		22.0, 10.0, 1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func _animate_entrance():
	position.y -= 30
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", position.y + 30, 0.4)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)
func _animate_exit():
	if not is_inside_tree(): return
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), fade_duration)
	await tween.finished
	queue_free()
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE:
			_animate_exit()
			get_viewport().set_input_as_handled()
func dismiss():
	_animate_exit()
