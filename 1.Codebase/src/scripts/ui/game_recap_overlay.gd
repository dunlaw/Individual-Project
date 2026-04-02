extends Control
signal dismissed
const ERROR_CONTEXT := "GameRecapOverlay"
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const TYPEWRITER_INTERVAL: float = 0.028
const TYPEWRITER_CHARS_PER_TICK: int = 2
const FAILSAFE_TIMEOUT: float = 16.0
var _title_label: Label
var _recap_label: RichTextLabel
var _loading_label: Label
var _continue_btn: Button
var _skip_btn: Button
var _typewriter_timer: Timer
var _failsafe_timer: Timer
var _dots_timer: Timer
var _full_text: String = ""
var _content_received: bool = false
var _language: String = "en"
var _game_state: Node = null
var _ai_manager: Node = null
var _dots_index: int = 0
func _ready() -> void:
	for child in get_children():
		child.queue_free()
	_game_state = ServiceLocator.get_game_state() if ServiceLocator else GameState
	_ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else AIManager
	_language = _game_state.current_language if _game_state else "en"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_start_failsafe()
	modulate.a = 0.0
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(self, "modulate:a", 1.0, 0.75)
	t.tween_callback(_request_recap)
	t.tween_callback(_start_dots_animation)
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.05, 0.97)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.0, 0.0, 0.0, 0.85)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 8
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)
	var bot_bar := ColorRect.new()
	bot_bar.color = Color(0.0, 0.0, 0.0, 0.85)
	bot_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_bar.offset_top = -8
	bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot_bar)
	_skip_btn = Button.new()
	_skip_btn.text = _tr("RECAP_SKIP")
	_skip_btn.pressed.connect(_on_skip_pressed)
	add_child(_skip_btn)
	_skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_btn.anchor_left   = 1.0;  _skip_btn.anchor_right  = 1.0
	_skip_btn.offset_left   = -130; _skip_btn.offset_right  = -16
	_skip_btn.offset_top    =  16;  _skip_btn.offset_bottom =  54
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var page := MarginContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("margin_left",   72)
	page.add_theme_constant_override("margin_right",  72)
	page.add_theme_constant_override("margin_top",     0)
	page.add_theme_constant_override("margin_bottom", 100)
	scroll.add_child(page)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	page.add_child(vbox)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 72)
	vbox.add_child(top_spacer)
	_title_label = Label.new()
	_title_label.text = _tr("RECAP_TITLE")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 21)
	_title_label.add_theme_color_override("font_color", Color(0.52, 0.52, 0.62, 0.88))
	_title_label.uppercase = true
	vbox.add_child(_title_label)
	var mission_title := _get_mission_title()
	if not mission_title.is_empty():
		var subtitle := Label.new()
		subtitle.text = "— " + mission_title + " —"
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.add_theme_font_size_override("font_size", 13)
		subtitle.add_theme_color_override("font_color", Color(0.38, 0.38, 0.48, 0.62))
		vbox.add_child(subtitle)
	var sep := HSeparator.new()
	sep.modulate = Color(0.28, 0.28, 0.42, 0.55)
	vbox.add_child(sep)
	_loading_label = Label.new()
	_loading_label.text = _tr("RECAP_LOADING")
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 15)
	_loading_label.add_theme_color_override("font_color", Color(0.42, 0.42, 0.52, 0.72))
	vbox.add_child(_loading_label)
	_recap_label = RichTextLabel.new()
	_recap_label.fit_content        = true
	_recap_label.bbcode_enabled     = true
	_recap_label.scroll_active      = false
	_recap_label.autowrap_mode      = TextServer.AUTOWRAP_WORD
	_recap_label.add_theme_font_size_override("normal_font_size", 18)
	_recap_label.add_theme_color_override("default_color", Color(0.86, 0.85, 0.92))
	_recap_label.visible            = false
	vbox.add_child(_recap_label)
	var bot_spacer := Control.new()
	bot_spacer.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(bot_spacer)
	_continue_btn = Button.new()
	_continue_btn.text = _tr("RECAP_CONTINUE")
	_continue_btn.custom_minimum_size = Vector2(260, 56)
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue_pressed)
	if UIStyleManager:
		UIStyleManager.apply_button_style(_continue_btn, "accent", "large")
	var btn_center := CenterContainer.new()
	btn_center.add_child(_continue_btn)
	vbox.add_child(btn_center)
func _request_recap() -> void:
	if not is_instance_valid(_ai_manager):
		_show_fallback()
		return
	var prompt := _build_recap_prompt()
	var context := { "purpose": "game_recap", "type": "game_recap" }
	_ai_manager.generate_story(prompt, context, Callable(self, "_on_recap_received"))
func _build_recap_prompt() -> String:
	var lines: Array[String] = []
	if _game_state:
		var mission_num     := int(_game_state.get("current_mission") if _game_state.get("current_mission") != null else 0)
		var missions_done   := int(_game_state.get("missions_completed") if _game_state.get("missions_completed") != null else 0)
		var reality         := int(_game_state.get("reality_score") if _game_state.get("reality_score") != null else 50)
		var entropy         := int(_game_state.get("entropy_level") if _game_state.get("entropy_level") != null else 0)
		var mission_title   := _get_mission_title()
		lines.append("Current state: Mission %d, %d missions completed, Reality Score %d, Entropy %d." % [
			mission_num, missions_done, reality, entropy
		])
		if not mission_title.is_empty():
			lines.append("Current mission: \"%s\"" % mission_title)
	var memory_store: Variant = _ai_manager.get("memory_store") if is_instance_valid(_ai_manager) else null
	if memory_store != null and memory_store.has_method("get_long_term_lines"):
		var summaries: Array = memory_store.get_long_term_lines(_language, 8)
		if not summaries.is_empty():
			lines.append("\nStory so far (condensed memory):")
			const MAX_SUMMARY_LINE_CHARS := 600
			for s in summaries:
				var summary_text := str(s)
				if summary_text.length() > MAX_SUMMARY_LINE_CHARS:
					summary_text = summary_text.left(MAX_SUMMARY_LINE_CHARS) + "..."
				lines.append("- " + summary_text)
	if _game_state != null and "recent_events" in _game_state:
		var events: Array = _game_state.recent_events
		if events.size() > 0:
			lines.append("\nMost recent events:")
			var start: int = max(0, events.size() - 5)
			for i in range(start, events.size()):
				var ev: Variant = events[i]
				var ev_text: String = ""
				if ev is Dictionary:
					if _language == "zh":
						ev_text = str(ev.get("text_zh", ev.get("text_en", ev.get("text", ""))))
					if ev_text.is_empty():
						ev_text = str(ev.get("text_en", ev.get("text", ev.get("description", ""))))
				elif ev is String:
					ev_text = ev
				if not ev_text.is_empty():
					lines.append("- " + ev_text)
	var context_block := "\n".join(lines)
	if _language == "zh":
		return (
			"請根據以下遊戲狀態與記憶，為玩家生成「上次在光榮拯救機構一號...」的旁白回顧。\n\n"
			+ context_block
			+ "\n\n請用繁體中文寫一段100-150字的戲劇性旁白，以「上次在光榮拯救機構一號...」開頭，"
			+ "用諷刺而帶有暗黑幽默的口吻總結玩家迄今的故事。只輸出旁白文字，不要任何JSON或選項。"
		)
	else:
		return (
			"Based on the following game context and story memory, generate a \"Previously on Glorious Deliverance Agency 1...\" narrative recap.\n\n"
			+ context_block
			+ "\n\nWrite a 120-180 word dramatic recap in English, opening with \"Previously on Glorious Deliverance Agency 1...\", "
			+ "in a sardonic, darkly humorous narrator voice. Output ONLY the recap text — no JSON, no choices, no headings."
		)
func _on_recap_received(response: Dictionary) -> void:
	if not is_instance_valid(self) or _content_received:
		return
	_content_received = true
	if is_instance_valid(_failsafe_timer):
		_failsafe_timer.stop()
	var text := str(response.get("content", "")).strip_edges() if response.get("success", false) else ""
	if text.is_empty():
		_show_fallback()
		return
	_show_recap_text(text)
func _start_dots_animation() -> void:
	_dots_timer = Timer.new()
	_dots_timer.wait_time = 0.55
	_dots_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_dots_timer.timeout.connect(_on_dots_tick)
	add_child(_dots_timer)
	_dots_timer.start()
func _on_dots_tick() -> void:
	if not is_instance_valid(_loading_label) or not _loading_label.visible:
		return
	_dots_index = (_dots_index + 1) % 4
	var dots := ".".repeat(_dots_index)
	_loading_label.text = _tr("RECAP_LOADING") + dots
func _stop_dots_animation() -> void:
	if is_instance_valid(_dots_timer):
		_dots_timer.stop()
		_dots_timer.queue_free()
		_dots_timer = null
func _show_recap_text(text: String) -> void:
	_stop_dots_animation()
	if not is_instance_valid(_loading_label) or not is_instance_valid(_recap_label):
		return
	_loading_label.visible = false
	_full_text             = text
	_recap_label.text      = text
	_recap_label.visible_characters = 0
	_recap_label.visible   = true
	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time   = TYPEWRITER_INTERVAL
	_typewriter_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)
	_typewriter_timer.start()
func _on_typewriter_tick() -> void:
	if not is_instance_valid(_recap_label):
		return
	var visible := _recap_label.visible_characters + TYPEWRITER_CHARS_PER_TICK
	var total   := _recap_label.get_total_character_count()
	if visible >= total:
		_recap_label.visible_characters = -1  
		if is_instance_valid(_typewriter_timer):
			_typewriter_timer.stop()
		_show_continue_button()
	else:
		_recap_label.visible_characters = visible
func _show_continue_button() -> void:
	if not is_instance_valid(_continue_btn):
		return
	_continue_btn.visible    = true
	_continue_btn.modulate.a = 0.0
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_continue_btn, "modulate:a", 1.0, 0.5)
func _show_fallback() -> void:
	if _content_received:
		return
	_content_received = true
	_show_recap_text(_tr("RECAP_FALLBACK"))
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			if is_instance_valid(_continue_btn) and _continue_btn.visible:
				_on_continue_pressed()
				get_viewport().set_input_as_handled()
			elif is_instance_valid(_recap_label) and _recap_label.visible:
				_finish_typewriter()
				get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()
func _finish_typewriter() -> void:
	if is_instance_valid(_typewriter_timer):
		_typewriter_timer.stop()
	if is_instance_valid(_recap_label):
		_recap_label.visible_characters = -1
	_show_continue_button()
func _on_skip_pressed() -> void:
	if not _content_received:
		if is_instance_valid(_failsafe_timer):
			_failsafe_timer.stop()
		_content_received = true
		_stop_dots_animation()
		_show_fallback()
		return
	if is_instance_valid(_typewriter_timer) and _typewriter_timer.is_stopped() == false:
		_finish_typewriter()
		return
	_dismiss()
func _on_continue_pressed() -> void:
	_dismiss()
func _dismiss() -> void:
	_stop_dots_animation()
	if is_instance_valid(_typewriter_timer):
		_typewriter_timer.stop()
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(self, "modulate:a", 0.0, 0.45)
	t.tween_callback(func() -> void:
		dismissed.emit()
		queue_free()
	)
func _get_mission_title() -> String:
	if not _game_state:
		return ""
	var title: Variant = _game_state.get("current_mission_title")
	return str(title) if title != null and str(title) != "" else ""
func _start_failsafe() -> void:
	_failsafe_timer = Timer.new()
	_failsafe_timer.wait_time    = FAILSAFE_TIMEOUT
	_failsafe_timer.one_shot     = true
	_failsafe_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_failsafe_timer.timeout.connect(_show_fallback)
	add_child(_failsafe_timer)
	_failsafe_timer.start()
func _exit_tree() -> void:
	if is_instance_valid(_typewriter_timer):
		_typewriter_timer.stop()
		_typewriter_timer.queue_free()
	if is_instance_valid(_failsafe_timer):
		_failsafe_timer.stop()
		_failsafe_timer.queue_free()
func _tr(key: String) -> String:
	var lm: Node = ServiceLocator.get_localization_manager() if ServiceLocator else null
	if lm:
		return lm.get_translation(key, _language)
	return key
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
