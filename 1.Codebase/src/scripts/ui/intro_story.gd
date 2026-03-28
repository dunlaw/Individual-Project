extends Control
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "IntroStory"
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const GameGuidePage = preload("res://1.Codebase/src/scripts/ui/game_guide_page.gd")
const IntroStoryData = preload("res://1.Codebase/src/scripts/ui/intro_story_data.gd")
const ICON_NEXT = preload("res://1.Codebase/src/assets/ui/icon_next.svg")
const ICON_SKIP = preload("res://1.Codebase/src/assets/ui/icon_skip.svg")
const TOTAL_PAGES := 41
const STORY_CSV_PATH := "res://1.Codebase/localization/intro_story_pages.csv"
const SETTINGS_FILE := "user://settings.cfg"
const INTRO_MUSIC := "background_music"
const STORY_MUSIC_TRACK_0_10 := "story_bgm_0_10"
const STORY_MUSIC_TRACK_11_20 := "story_bgm_11_20"
const STORY_MUSIC_TRACK_20_30 := "story_bgm_20_30"
const STORY_MUSIC_TRACK_30_41 := "story_bgm_30_41"
const DEFAULT_BACKGROUND := "menu"
const STORY_IMAGE_HEIGHT_RATIO := 0.46
const STORY_IMAGE_MIN_HEIGHT := 420
const STORY_IMAGE_MAX_HEIGHT := 620
const COLOR_PAGE_LEFT := Color(0.96, 0.92, 0.82, 1.0)
const COLOR_PAGE_RIGHT := Color(0.98, 0.95, 0.88, 1.0)
const COLOR_SPINE := Color(0.55, 0.35, 0.12, 1.0)
const COLOR_BORDER := Color(0.62, 0.42, 0.18, 0.8)
const COLOR_INK := Color(0.13, 0.08, 0.03, 1.0)
const COLOR_TITLE_INK := Color(0.45, 0.25, 0.06, 1.0)
const COLOR_PAGE_NUM := Color(0.50, 0.32, 0.10, 1.0)
signal intro_completed
signal intro_skipped
var current_page: int = 0
var story_pages: Array[Dictionary] = []
var background_texture: TextureRect
var background_overlay: ColorRect
var main_panel: PanelContainer
var story_text_label: RichTextLabel
var story_image: TextureRect
var story_image_margin: MarginContainer
var page_indicator_label: Label
var left_page_num_label: Label
var chapter_label: Label
var skip_button: Button
var chapter_button: MenuButton
var quick_start_button: Button
var prev_button: Button
var next_button: Button
var audio_manager: Node = null
var current_language: String = "en"
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _ready() -> void:
	_refresh_services()
	_load_language_from_settings()
	_initialize_story_pages()
	_build_ui()
	_apply_styles()
	_update_display()
	_animate_entrance()
	_start_background_music()
	if not resized.is_connected(_on_intro_story_resized):
		resized.connect(_on_intro_story_resized)
func _refresh_services() -> void:
	if ServiceLocator:
		audio_manager = ServiceLocator.get_audio_manager()
	if GameState:
		current_language = GameState.current_language
func _load_language_from_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	if err == OK:
		current_language = config.get_value("game", "language", "en")
func _parse_csv_text(content: String) -> Array:
	var rows: Array = []
	var current_row: Array = []
	var current_field: String = ""
	var in_quotes: bool = false
	var i: int = 0
	var length: int = content.length()
	while i < length:
		var c: String = content[i]
		if in_quotes:
			if c == '"':
				if i + 1 < length and content[i + 1] == '"':
					current_field += '"'
					i += 2
					continue
				else:
					in_quotes = false
					i += 1
					continue
			else:
				current_field += c
		else:
			if c == '"':
				in_quotes = true
			elif c == ',':
				current_row.append(current_field)
				current_field = ""
			elif c == '\n':
				current_row.append(current_field)
				current_field = ""
				if not (current_row.size() == 1 and current_row[0] == ""):
					rows.append(current_row)
				current_row = []
			elif c == '\r':
				pass  
			else:
				current_field += c
		i += 1
	if current_field != "" or current_row.size() > 0:
		current_row.append(current_field)
		rows.append(current_row)
	return rows
func _initialize_story_pages() -> void:
	story_pages.clear()
	var bundled_pages := IntroStoryData.get_story_pages()
	var loaded_from_csv := false
	if not OS.has_feature("web"):
		loaded_from_csv = _try_load_story_pages_from_csv()
	if loaded_from_csv:
		if not _has_complete_story_pages(story_pages):
			if ErrorReporter:
				ErrorReporter.report_warning(
					"IntroStory",
					"CSV story data incomplete, using bundled fallback",
					{ "csv_path": STORY_CSV_PATH, "csv_count": story_pages.size(), "fallback_count": bundled_pages.size() },
				)
			story_pages = bundled_pages
	else:
		story_pages = bundled_pages
		if ErrorReporter and not OS.has_feature("web"):
			ErrorReporter.report_warning(
				"IntroStory",
				"Failed to load CSV story data or running on Web; using bundled fallback",
				{
					"csv_path": STORY_CSV_PATH,
					"fallback_count": story_pages.size(),
					"is_web": OS.has_feature("web"),
				},
			)
	if story_pages.is_empty():
		for i in range(TOTAL_PAGES):
			var page_num := i + 1
			story_pages.append({
				"title_en": "Page %d" % page_num,
				"title_zh": "INTRO_DATA_PLACEHOLDER_TITLE_%d" % page_num,
				"text_en": "Placeholder Story Page %d" % page_num,
				"text_zh": "INTRO_DATA_PLACEHOLDER_TEXT_%d" % page_num,
				"image_path": "",
			})
func _try_load_story_pages_from_csv() -> bool:
	var file := FileAccess.open(STORY_CSV_PATH, FileAccess.READ)
	if file == null:
		return false
	var content := file.get_as_text()
	file.close()
	if content.strip_edges().is_empty():
		return false
	var all_rows := _parse_csv_text(content)
	if all_rows.is_empty():
		return false
	var header_row: Array = all_rows[0]
	var column_indices := _build_story_csv_column_indices(header_row)
	for ri in range(1, all_rows.size()):
		var row: Array = all_rows[ri]
		if row.is_empty():
			continue
		story_pages.append({
			"title_zh": _decode_story_escape_sequences(_get_story_csv_value(row, column_indices, "title_zh")),
			"title_en": _decode_story_escape_sequences(_get_story_csv_value(row, column_indices, "title_en")),
			"title_de": _decode_story_escape_sequences(_get_story_csv_value(row, column_indices, "title_de")),
			"text_zh": _decode_story_escape_sequences(_get_story_csv_value(row, column_indices, "text_zh")),
			"text_en": _decode_story_escape_sequences(_get_story_csv_value(row, column_indices, "text_en")),
			"text_de": _decode_story_escape_sequences(_get_story_csv_value(row, column_indices, "text_de")),
			"image_path": _get_story_csv_value(row, column_indices, "image_path").strip_edges(),
		})
	return not story_pages.is_empty()
func _build_story_csv_column_indices(header_row: Array) -> Dictionary:
	var column_indices: Dictionary = {}
	for i in range(header_row.size()):
		var column_name := str(header_row[i]).strip_edges()
		if column_name.is_empty():
			continue
		column_indices[column_name] = i
	return column_indices
func _get_story_csv_value(row: Array, column_indices: Dictionary, column_name: String) -> String:
	if not column_indices.has(column_name):
		return ""
	var column_index := int(column_indices[column_name])
	if column_index < 0 or column_index >= row.size():
		return ""
	return str(row[column_index])
func _decode_story_escape_sequences(value: String) -> String:
	if value.find("\\") == -1:
		return value
	var decoded := value
	decoded = decoded.replace("\\r\\n", "\n")
	decoded = decoded.replace("\\n", "\n")
	decoded = decoded.replace("\\r", "\n")
	decoded = decoded.replace("\\t", "\t")
	decoded = decoded.replace("\\\"", "\"")
	decoded = decoded.replace("\\'", "'")
	return decoded
func _has_complete_story_pages(pages: Array[Dictionary]) -> bool:
	if pages.size() < TOTAL_PAGES:
		return false
	for i in range(TOTAL_PAGES):
		var page_data: Dictionary = pages[i]
		if page_data.get("title_en", "").strip_edges().is_empty():
			return false
		if page_data.get("title_zh", "").strip_edges().is_empty():
			return false
		if page_data.get("text_en", "").strip_edges().is_empty():
			return false
		if page_data.get("text_zh", "").strip_edges().is_empty():
			return false
	return true
func _build_ui() -> void:
	background_texture = TextureRect.new()
	background_texture.name = "BackgroundTexture"
	background_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_background_image()
	add_child(background_texture)
	background_overlay = ColorRect.new()
	background_overlay.name = "BackgroundOverlay"
	background_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_overlay.color = Color(0.07, 0.05, 0.02, 0.88)
	background_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background_overlay)
	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toolbar.anchor_bottom = 0.0
	toolbar.offset_top = 10
	toolbar.offset_bottom = 50
	toolbar.offset_left = 20
	toolbar.offset_right = -20
	toolbar.add_theme_constant_override("separation", 10)
	add_child(toolbar)
	var toolbar_title := Label.new()
	toolbar_title.name = "ToolbarTitle"
	toolbar_title.text = _tr("INTRO_NAV_TITLE")
	toolbar_title.add_theme_font_size_override("font_size", UIStyleManager.FONT_SIZE_LARGE)
	toolbar_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72))
	toolbar_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(toolbar_title)
	chapter_button = MenuButton.new()
	chapter_button.name = "ChapterButton"
	chapter_button.text = _tr("INTRO_NAV_CHAPTERS")
	chapter_button.get_popup().id_pressed.connect(_on_chapter_selected)
	toolbar.add_child(chapter_button)
	quick_start_button = Button.new()
	quick_start_button.name = "QuickStartButton"
	quick_start_button.text = _tr("INTRO_NAV_START_GAME")
	quick_start_button.pressed.connect(_complete_intro)
	toolbar.add_child(quick_start_button)
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = _tr("INTRO_NAV_SKIP")
	skip_button.icon = ICON_SKIP if ICON_SKIP else null
	skip_button.pressed.connect(_on_skip_pressed)
	toolbar.add_child(skip_button)
	var book_container := MarginContainer.new()
	book_container.name = "BookContainer"
	book_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	book_container.offset_top = 60
	book_container.offset_bottom = -10
	book_container.offset_left = 12
	book_container.offset_right = -12
	add_child(book_container)
	main_panel = PanelContainer.new()
	main_panel.name = "MainPanel"
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_container.add_child(main_panel)
	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 0)
	outer_margin.add_theme_constant_override("margin_right", 0)
	outer_margin.add_theme_constant_override("margin_top", 0)
	outer_margin.add_theme_constant_override("margin_bottom", 0)
	main_panel.add_child(outer_margin)
	var book_hbox := HBoxContainer.new()
	book_hbox.name = "BookSpread"
	book_hbox.add_theme_constant_override("separation", 0)
	outer_margin.add_child(book_hbox)
	var left_page := _build_left_page()
	book_hbox.add_child(left_page)
	var spine := _build_spine()
	book_hbox.add_child(spine)
	var right_page := _build_right_page()
	book_hbox.add_child(right_page)
func _build_left_page() -> Control:
	var page := PanelContainer.new()
	page.name = "LeftPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_style := StyleBoxFlat.new()
	left_style.bg_color = COLOR_PAGE_LEFT
	left_style.border_color = COLOR_BORDER
	left_style.set_border_width_all(1)
	left_style.corner_radius_top_left = 12
	left_style.corner_radius_bottom_left = 12
	left_style.set_content_margin_all(0)
	page.add_theme_stylebox_override("panel", left_style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	page.add_child(vbox)
	var chapter_margin := MarginContainer.new()
	chapter_margin.add_theme_constant_override("margin_left", 20)
	chapter_margin.add_theme_constant_override("margin_right", 20)
	chapter_margin.add_theme_constant_override("margin_top", 16)
	chapter_margin.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(chapter_margin)
	chapter_label = Label.new()
	chapter_label.name = "ChapterLabel"
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_label.add_theme_font_size_override("font_size", UIStyleManager.FONT_SIZE_SMALL)
	chapter_label.add_theme_color_override("font_color", COLOR_TITLE_INK)
	chapter_margin.add_child(chapter_label)
	var rule_top := ColorRect.new()
	rule_top.custom_minimum_size = Vector2(0, 1)
	rule_top.color = COLOR_BORDER
	vbox.add_child(rule_top)
	story_image_margin = MarginContainer.new()
	story_image_margin.add_theme_constant_override("margin_left", 24)
	story_image_margin.add_theme_constant_override("margin_right", 24)
	story_image_margin.add_theme_constant_override("margin_top", 12)
	story_image_margin.add_theme_constant_override("margin_bottom", 12)
	story_image_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_image_margin.custom_minimum_size = Vector2(0, STORY_IMAGE_MIN_HEIGHT)
	vbox.add_child(story_image_margin)
	story_image = TextureRect.new()
	story_image.name = "StoryImage"
	story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	story_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_image.custom_minimum_size = Vector2(0, STORY_IMAGE_MIN_HEIGHT)
	story_image_margin.add_child(story_image)
	var rule_bot := ColorRect.new()
	rule_bot.custom_minimum_size = Vector2(0, 1)
	rule_bot.color = COLOR_BORDER
	vbox.add_child(rule_bot)
	var left_footer := MarginContainer.new()
	left_footer.add_theme_constant_override("margin_left", 20)
	left_footer.add_theme_constant_override("margin_right", 20)
	left_footer.add_theme_constant_override("margin_top", 8)
	left_footer.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(left_footer)
	left_page_num_label = Label.new()
	left_page_num_label.name = "LeftPageNum"
	left_page_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left_page_num_label.add_theme_font_size_override("font_size", UIStyleManager.FONT_SIZE_SMALL)
	left_page_num_label.add_theme_color_override("font_color", COLOR_PAGE_NUM)
	left_footer.add_child(left_page_num_label)
	return page
func _build_spine() -> Control:
	var spine_vbox := VBoxContainer.new()
	spine_vbox.name = "Spine"
	spine_vbox.custom_minimum_size = Vector2(18, 0)
	spine_vbox.add_theme_constant_override("separation", 0)
	var spine_bg := ColorRect.new()
	spine_bg.color = COLOR_SPINE
	spine_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spine_vbox.add_child(spine_bg)
	return spine_vbox
func _build_right_page() -> Control:
	var page := PanelContainer.new()
	page.name = "RightPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right_style := StyleBoxFlat.new()
	right_style.bg_color = COLOR_PAGE_RIGHT
	right_style.border_color = COLOR_BORDER
	right_style.set_border_width_all(1)
	right_style.corner_radius_top_right = 12
	right_style.corner_radius_bottom_right = 12
	right_style.set_content_margin_all(0)
	page.add_theme_stylebox_override("panel", right_style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	page.add_child(vbox)
	var rule_top := ColorRect.new()
	rule_top.custom_minimum_size = Vector2(0, 1)
	rule_top.color = COLOR_BORDER
	vbox.add_child(rule_top)
	var text_margin := MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 36)
	text_margin.add_theme_constant_override("margin_right", 36)
	text_margin.add_theme_constant_override("margin_top", 24)
	text_margin.add_theme_constant_override("margin_bottom", 12)
	text_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(text_margin)
	var scroll := ScrollContainer.new()
	scroll.name = "TextScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	text_margin.add_child(scroll)
	story_text_label = RichTextLabel.new()
	story_text_label.name = "StoryTextLabel"
	story_text_label.bbcode_enabled = true
	story_text_label.fit_content = true
	story_text_label.scroll_active = false
	story_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_text_label.add_theme_font_size_override("normal_font_size", 17)
	story_text_label.add_theme_font_size_override("bold_font_size", 17)
	story_text_label.add_theme_color_override("default_color", COLOR_INK)
	scroll.add_child(story_text_label)
	var rule_bot := ColorRect.new()
	rule_bot.custom_minimum_size = Vector2(0, 1)
	rule_bot.color = COLOR_BORDER
	vbox.add_child(rule_bot)
	var footer_margin := MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_left", 20)
	footer_margin.add_theme_constant_override("margin_right", 20)
	footer_margin.add_theme_constant_override("margin_top", 8)
	footer_margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(footer_margin)
	var footer_hbox := HBoxContainer.new()
	footer_hbox.name = "FooterHBox"
	footer_hbox.add_theme_constant_override("separation", 12)
	footer_margin.add_child(footer_hbox)
	prev_button = Button.new()
	prev_button.name = "PrevButton"
	prev_button.text = _tr("INTRO_NAV_PREVIOUS")
	prev_button.custom_minimum_size = Vector2(120, 38)
	prev_button.pressed.connect(_on_prev_pressed)
	footer_hbox.add_child(prev_button)
	page_indicator_label = Label.new()
	page_indicator_label.name = "PageIndicator"
	page_indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_indicator_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_indicator_label.add_theme_font_size_override("font_size", UIStyleManager.FONT_SIZE_SMALL)
	page_indicator_label.add_theme_color_override("font_color", COLOR_PAGE_NUM)
	footer_hbox.add_child(page_indicator_label)
	next_button = Button.new()
	next_button.name = "NextButton"
	next_button.text = _tr("INTRO_NAV_NEXT")
	next_button.icon = ICON_NEXT if ICON_NEXT else null
	next_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next_button.custom_minimum_size = Vector2(120, 38)
	next_button.pressed.connect(_on_next_pressed)
	footer_hbox.add_child(next_button)
	return page
func _on_intro_story_resized() -> void:
	_update_story_image_size()
func _apply_styles() -> void:
	var book_outer := StyleBoxFlat.new()
	book_outer.bg_color = Color(0.88, 0.82, 0.68, 1.0)
	book_outer.corner_radius_top_left = 12
	book_outer.corner_radius_top_right = 12
	book_outer.corner_radius_bottom_left = 12
	book_outer.corner_radius_bottom_right = 12
	book_outer.shadow_size = 18
	book_outer.shadow_color = Color(0, 0, 0, 0.55)
	book_outer.shadow_offset = Vector2(4, 6)
	book_outer.set_content_margin_all(0)
	main_panel.add_theme_stylebox_override("panel", book_outer)
	UIStyleManager.apply_button_style(skip_button, "warning", "medium")
	UIStyleManager.apply_button_style(chapter_button, "primary", "medium")
	UIStyleManager.apply_button_style(quick_start_button, "accent", "medium")
	UIStyleManager.add_hover_scale_effect(skip_button, 1.05)
	UIStyleManager.add_hover_scale_effect(chapter_button, 1.05)
	UIStyleManager.add_hover_scale_effect(quick_start_button, 1.05)
	UIStyleManager.add_press_feedback(skip_button)
	UIStyleManager.add_press_feedback(chapter_button)
	UIStyleManager.add_press_feedback(quick_start_button)
	UIStyleManager.apply_button_style(prev_button, "primary", "medium")
	UIStyleManager.add_hover_scale_effect(prev_button, 1.05)
	UIStyleManager.add_press_feedback(prev_button)
	UIStyleManager.apply_button_style(next_button, "accent", "medium")
	UIStyleManager.add_hover_scale_effect(next_button, 1.08)
	UIStyleManager.add_press_feedback(next_button)
func _animate_entrance() -> void:
	main_panel.modulate.a = 0.0
	main_panel.scale = Vector2(0.93, 0.93)
	main_panel.pivot_offset = main_panel.size / 2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_panel, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
func _update_display() -> void:
	if current_page < 0 or current_page >= story_pages.size():
		return
	var page_data: Dictionary = story_pages[current_page]
	_play_story_music_for_current_page()
	var page_number := current_page + 1
	var title := _get_story_page_text(page_data, "title", page_number)
	var text := _get_story_page_text(page_data, "text", page_number)
	var safe_title := title.replace("[", "[lb]")
	var safe_text := text.replace("[", "[lb]")
	var color_title := COLOR_TITLE_INK.to_html(false)
	var color_body := COLOR_INK.to_html(false)
	var formatted := "[center][b][color=#%s]%s[/color][/b][/center]\n\n[color=#%s]%s[/color]" % [color_title, safe_title, color_body, safe_text]
	story_text_label.text = formatted
	_load_story_image(page_data.get("image_path", ""))
	_update_chapter_menu()
	var left_page_number := current_page * 2 + 1
	if left_page_num_label:
		left_page_num_label.text = "[ %d ]" % left_page_number
	var chapter_title := _get_chapter_title()
	if chapter_label:
		chapter_label.text = chapter_title
	var indicator_format := _tr("INTRO_NAV_PAGE_FORMAT")
	if indicator_format.find("%d") >= 0:
		page_indicator_label.text = indicator_format % [current_page + 1, TOTAL_PAGES]
	else:
		page_indicator_label.text = "%d / %d" % [current_page + 1, TOTAL_PAGES]
	prev_button.disabled = (current_page == 0)
	prev_button.visible = (current_page > 0)
	if current_page >= TOTAL_PAGES - 1:
		next_button.text = _tr("INTRO_NAV_START_GAME")
		next_button.icon = ICON_NEXT if ICON_NEXT else null
	else:
		next_button.text = _tr("INTRO_NAV_NEXT")
		next_button.icon = ICON_NEXT if ICON_NEXT else null
func _get_chapter_title() -> String:
	if current_page < 15:
		return _tr("INTRO_NAV_ACT_1")
	elif current_page < 20:
		return _tr("INTRO_NAV_ACT_2")
	elif current_page < 30:
		return _tr("INTRO_NAV_ACT_3")
	return _tr("INTRO_NAV_ACT_4")
func _on_prev_pressed() -> void:
	if current_page > 0:
		_play_sfx("menu_click")
		current_page -= 1
		_animate_page_transition(-1)
		_update_display()
func _on_next_pressed() -> void:
	_play_sfx("happy_click")
	if current_page >= TOTAL_PAGES - 1:
		_complete_intro()
	else:
		current_page += 1
		_animate_page_transition(1)
		_update_display()
func _on_skip_pressed() -> void:
	_play_sfx("menu_click")
	_mark_intro_seen()
	intro_skipped.emit()
	_transition_to_game()
func _on_chapter_selected(chapter_id: int) -> void:
	match chapter_id:
		0:
			current_page = 0
		1:
			current_page = 15
		2:
			current_page = 20
		3:
			current_page = 30
	_update_display()
func _complete_intro() -> void:
	_mark_intro_seen()
	intro_completed.emit()
	_transition_to_game()
func _animate_page_transition(_direction: int) -> void:
	var tween := create_tween()
	tween.tween_property(story_text_label, "modulate:a", 0.3, 0.1)
	tween.tween_property(story_text_label, "modulate:a", 1.0, 0.2)
func _transition_to_game() -> void:
	var tween := create_tween()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.3)
	tween.tween_property(background_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_show_game_guide)
func _show_game_guide() -> void:
	if not GameGuidePage.has_seen_guide():
		var guide: Control = GameGuidePage.new()
		add_child(guide)
		guide.guide_closed.connect(_go_to_story_scene)
	else:
		_go_to_story_scene()
func _go_to_story_scene() -> void:
	get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/story_scene.tscn")
func _mark_intro_seen() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err != OK:
		config = ConfigFile.new()
	config.set_value("game", "intro_story_seen", true)
	config.save(SETTINGS_FILE)
	_report_info("Marked intro as seen in settings")
func _play_sfx(sfx_name: String) -> void:
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_name)
func _update_chapter_menu() -> void:
	if not chapter_button:
		return
	var popup := chapter_button.get_popup()
	popup.clear()
	popup.add_check_item(_tr("INTRO_NAV_ACT_1"), 0)
	popup.add_check_item(_tr("INTRO_NAV_ACT_2"), 1)
	popup.add_check_item(_tr("INTRO_NAV_ACT_3"), 2)
	popup.add_check_item(_tr("INTRO_NAV_ACT_4"), 3)
	popup.set_item_checked(0, current_page < 15)
	popup.set_item_checked(1, current_page >= 15 and current_page < 20)
	popup.set_item_checked(2, current_page >= 20 and current_page < 30)
	popup.set_item_checked(3, current_page >= 30)
func _load_story_image(image_path: String) -> void:
	if not story_image:
		return
	_update_story_image_size()
	var normalized_path := image_path.strip_edges()
	if normalized_path.is_empty():
		story_image.texture = null
		return
	var texture := IntroStoryData.get_texture_for_path(normalized_path)
	if texture == null:
		texture = load(normalized_path) as Texture2D
	if texture == null and ErrorReporter:
		ErrorReporter.report_warning(
			"IntroStory",
			"Story image load failed",
			{ "path": normalized_path, "page": current_page + 1 },
		)
	story_image.texture = texture
func _update_story_image_size() -> void:
	if not story_image or not story_image_margin:
		return
	var viewport_height := get_viewport_rect().size.y
	var target_height := clampi(int(viewport_height * STORY_IMAGE_HEIGHT_RATIO), STORY_IMAGE_MIN_HEIGHT, STORY_IMAGE_MAX_HEIGHT)
	story_image_margin.custom_minimum_size = Vector2(0, target_height)
	story_image.custom_minimum_size = Vector2(0, target_height)
func _get_story_page_text(page_data: Dictionary, field_name: String, page_number: int) -> String:
	var english_value := _decode_story_escape_sequences(str(page_data.get("%s_en" % field_name, "")))
	match current_language:
		"zh":
			return _resolve_story_translation(
				str(page_data.get("%s_zh" % field_name, "")),
				_get_story_translation_key(page_number, field_name),
				english_value,
			)
		"de":
			var german_value := _decode_story_escape_sequences(str(page_data.get("%s_de" % field_name, "")))
			if not german_value.strip_edges().is_empty():
				return german_value
			return _resolve_story_translation("", _get_story_translation_key(page_number, field_name), english_value)
		_:
			return english_value
func _get_story_translation_key(page_number: int, field_name: String) -> String:
	return "INTRO_DATA_PAGE_%d_%s" % [page_number, field_name.to_upper()]
func _resolve_story_translation(raw_value: String, translation_key: String, fallback: String) -> String:
	var trimmed_raw := raw_value.strip_edges()
	if not trimmed_raw.is_empty():
		if trimmed_raw == translation_key or trimmed_raw.begins_with("INTRO_DATA_PAGE_"):
			var translated_from_raw := _tr(trimmed_raw)
			if translated_from_raw != trimmed_raw:
				return _decode_story_escape_sequences(translated_from_raw)
		return _decode_story_escape_sequences(raw_value)
	var translated := _tr(translation_key)
	if translated != translation_key:
		return _decode_story_escape_sequences(translated)
	return _decode_story_escape_sequences(fallback)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
static func has_seen_intro() -> bool:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err != OK:
		return false
	return config.get_value("game", "intro_story_seen", false)
static func reset_intro_seen() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err != OK:
		config = ConfigFile.new()
	config.set_value("game", "intro_story_seen", false)
	config.save(SETTINGS_FILE)
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Reset intro seen status")
func set_story_page(page_index: int, title_en: String, title_zh: String, text_en: String, text_zh: String) -> void:
	if page_index >= 0 and page_index < story_pages.size():
		story_pages[page_index] = {
			"title_en": title_en,
			"title_zh": title_zh,
			"title_de": story_pages[page_index].get("title_de", ""),
			"text_en": text_en,
			"text_zh": text_zh,
			"text_de": story_pages[page_index].get("text_de", ""),
			"image_path": story_pages[page_index].get("image_path", ""),
		}
		if page_index == current_page:
			_update_display()
func set_all_story_pages(pages: Array[Dictionary]) -> void:
	story_pages = pages
	_update_display()
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_UP:
				if current_page > 0:
					_on_prev_pressed()
			KEY_RIGHT, KEY_DOWN, KEY_SPACE, KEY_ENTER:
				_on_next_pressed()
			KEY_ESCAPE:
				_on_skip_pressed()
func _load_background_image() -> void:
	if not BackgroundLoader:
		return
	var texture: Texture2D = BackgroundLoader.get_background_texture(DEFAULT_BACKGROUND)
	if texture and background_texture:
		background_texture.texture = texture
func _start_background_music() -> void:
	if audio_manager and audio_manager.has_method("play_music"):
		_play_story_music_for_current_page()
func _get_story_music_for_page(page_index: int) -> String:
	if page_index >= 31:
		return STORY_MUSIC_TRACK_30_41
	if page_index >= 21:
		return STORY_MUSIC_TRACK_20_30
	if page_index >= 11:
		return STORY_MUSIC_TRACK_11_20
	return STORY_MUSIC_TRACK_0_10
func _play_story_music_for_current_page() -> void:
	if not audio_manager or not audio_manager.has_method("play_music"):
		return
	var music_name := _get_story_music_for_page(current_page)
	if audio_manager.has_method("has_sound") and not audio_manager.has_sound(music_name):
		if ErrorReporter:
			ErrorReporter.report_warning(
				"IntroStory",
				"Story music track missing; falling back to default intro track",
				{
					"music_name": music_name,
					"page_index": current_page,
				},
			)
		music_name = INTRO_MUSIC
	var current_music_name := ""
	if audio_manager.has_method("get_current_music"):
		current_music_name = String(audio_manager.get_current_music())
	if current_music_name == music_name and audio_manager.has_method("is_music_playing") and audio_manager.is_music_playing():
		return
	audio_manager.play_music(music_name, true)
func set_background(background_id: String) -> void:
	if not BackgroundLoader or not background_texture:
		return
	var texture: Texture2D = BackgroundLoader.get_background_texture(background_id)
	if texture:
		background_texture.texture = texture
func set_music(music_name: String) -> void:
	if audio_manager and audio_manager.has_method("play_music"):
		audio_manager.play_music(music_name, true)
