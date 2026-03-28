extends Control
signal prayer_completed(result: Dictionary)
signal prayer_cancelled
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const PRAYER_NOTICE_SCENE: PackedScene = preload("res://1.Codebase/src/scenes/ui/prayer_notice.tscn")
const PRAYER_ICON = preload("res://1.Codebase/src/assets/ui/prayer_icon.png")
const PRAYER_SCENE_BG = preload("res://1.Codebase/src/assets/ui/prayer_scene_background.png")
const CHAN_PLEADING = preload("res://1.Codebase/src/assets/characters/teacher_chan_pleading_hands.png")
const ERROR_CONTEXT := "PrayerSystem"
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
var _floating_particles: Array = []
var _mystical_glow_tween: Tween
var _wifi_symbols: Array = []
var _candle_flames: Array = []
var _pasta_tendrils: Array = []
var _ritual_circle: Control = null
var _typing_burst_tween: Tween = null
var _last_text_len: int = 0
var _typing_symbol_chars: Array[String] = ["✦", "✝", "♱", "☽", "✶", "★", "⊕", "⌘", "✺", "⋆"]
@onready var prayer_panel: Panel = $PrayerPanel
@onready var prayer_input: TextEdit = $PrayerPanel/MarginContainer/VBoxContainer/PrayerInput
@onready var submit_button: Button = $PrayerPanel/MarginContainer/VBoxContainer/ButtonsContainer/SubmitButton
@onready var cancel_button: Button = $PrayerPanel/MarginContainer/VBoxContainer/ButtonsContainer/CancelButton
@onready var home_button: Button = $PrayerPanel/MarginContainer/VBoxContainer/ButtonsContainer/HomeButton
@onready var warning_label: Label = $PrayerPanel/MarginContainer/VBoxContainer/WarningLabel
@onready var title_label: Label = $PrayerPanel/MarginContainer/VBoxContainer/Title
@onready var description_label: Label = $PrayerPanel/MarginContainer/VBoxContainer/Description
var _reality_bar: ProgressBar
var _entropy_bar: ProgressBar
var _positive_energy_bar: ProgressBar
var is_processing: bool = false
var _notice_overlay: Control = null
var _input_locked_by_notice: bool = false
var _context: String = "default"
var _connecting_tween: Tween
var _retry_button: Button = null
var _last_prayer_text: String = ""
var _previous_music: String = ""
var _playlist_was_active: bool = false
var _input_glow_style: StyleBoxFlat = null
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready():
	_debug_log("Prayer screen initialized")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_fullscreen_layout()
	_apply_modern_styling()
	_apply_localization()
	_update_stats_display()
	update_warning()
	_create_mystical_atmosphere()
	_enhance_input_field_sacred()
	_setup_button_focus()
	if prayer_panel:
		prayer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		prayer_panel.modulate.a = 0.0
		prayer_panel.scale = Vector2.ONE
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(prayer_panel, "modulate:a", 1.0, 0.5)
	_maybe_show_data_notice()
	_report_info("Ready complete. context=%s locked=%s processing=%s" % [_context, _input_locked_by_notice, is_processing])
	_deferred_focus.call_deferred()
func _deferred_focus() -> void:
	if submit_button and not submit_button.disabled:
		submit_button.grab_focus()
	elif cancel_button and cancel_button.visible and not cancel_button.disabled:
		cancel_button.grab_focus()
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _input_locked_by_notice:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _context != "night" and cancel_button and cancel_button.visible:
				_report_info("Escape key -> cancel")
				_on_cancel_pressed()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			if submit_button and not submit_button.disabled:
				_report_info("Key 1 -> submit")
				_on_submit_pressed()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			if cancel_button and cancel_button.visible and not cancel_button.disabled:
				_report_info("Key 2 -> cancel")
				_on_cancel_pressed()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			if home_button and home_button.visible and not home_button.disabled:
				_report_info("Key 3 -> home")
				_on_home_pressed()
				get_viewport().set_input_as_handled()
func _setup_button_focus() -> void:
	if submit_button:
		submit_button.focus_mode = Control.FOCUS_ALL
	if cancel_button:
		cancel_button.focus_mode = Control.FOCUS_ALL
	if home_button:
		home_button.focus_mode = Control.FOCUS_ALL
	if submit_button and cancel_button:
		submit_button.focus_neighbor_right = submit_button.get_path_to(cancel_button)
		cancel_button.focus_neighbor_left = cancel_button.get_path_to(submit_button)
	if cancel_button and home_button:
		cancel_button.focus_neighbor_right = cancel_button.get_path_to(home_button)
		home_button.focus_neighbor_left = home_button.get_path_to(cancel_button)
	if home_button and submit_button:
		home_button.focus_neighbor_right = home_button.get_path_to(submit_button)
		submit_button.focus_neighbor_left = submit_button.get_path_to(home_button)
func _exit_tree() -> void:
	for particle in _floating_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	_floating_particles.clear()
	for wifi in _wifi_symbols:
		if is_instance_valid(wifi):
			wifi.queue_free()
	_wifi_symbols.clear()
	for flame in _candle_flames:
		if is_instance_valid(flame):
			flame.queue_free()
	_candle_flames.clear()
	for tendril in _pasta_tendrils:
		if is_instance_valid(tendril):
			tendril.queue_free()
	_pasta_tendrils.clear()
	if is_instance_valid(_ritual_circle):
		_ritual_circle.queue_free()
	_ritual_circle = null
	_input_glow_style = null
	var audio_manager = get_audio_manager()
	if audio_manager:
		if audio_manager.has_method("stop_music"):
			audio_manager.stop_music(1.2)
		var tree = get_tree()
		if tree:
			await tree.create_timer(1.3).timeout
			if audio_manager and is_instance_valid(audio_manager):
				if _playlist_was_active and audio_manager.has_method("resume_gameplay_playlist"):
					audio_manager.resume_gameplay_playlist()
				elif not _previous_music.is_empty() and audio_manager.has_method("play_music"):
					audio_manager.play_music(_previous_music, true)
func _setup_fullscreen_layout():
	if not prayer_panel:
		return
	prayer_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin = 40
	prayer_panel.offset_left = margin
	prayer_panel.offset_top = margin
	prayer_panel.offset_right = -margin
	prayer_panel.offset_bottom = -margin
	var margin_container = prayer_panel.get_node("MarginContainer")
	var input_vbox = margin_container.get_node("VBoxContainer")
	var h_split = HBoxContainer.new()
	h_split.name = "MainSplit"
	h_split.mouse_filter = Control.MOUSE_FILTER_PASS
	h_split.add_theme_constant_override("separation", 40)
	h_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stats_vbox = VBoxContainer.new()
	stats_vbox.name = "StatsColumn"
	stats_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_vbox.size_flags_stretch_ratio = 0.4
	stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin_container.remove_child(input_vbox)
	margin_container.add_child(h_split)
	h_split.add_child(stats_vbox)
	h_split.add_child(input_vbox)
	input_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_vbox.size_flags_stretch_ratio = 0.6
	input_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_build_stats_column(stats_vbox)
func _build_stats_column(parent: Control):
	var chan_pleading_img = TextureRect.new()
	chan_pleading_img.texture = CHAN_PLEADING
	chan_pleading_img.custom_minimum_size = Vector2(160, 200)
	chan_pleading_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chan_pleading_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chan_pleading_img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chan_pleading_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(chan_pleading_img)
	var chan_caption = Label.new()
	chan_caption.text = "Miss Chan is praying too..."
	chan_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chan_caption.add_theme_font_size_override("font_size", 11)
	chan_caption.add_theme_color_override("font_color", Color(1.0, 0.7, 0.9, 0.75))
	chan_caption.autowrap_mode = TextServer.AUTOWRAP_WORD
	chan_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(chan_caption)
	var icon = TextureRect.new()
	icon.texture = PRAYER_ICON
	icon.custom_minimum_size = Vector2(400, 400)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 10)
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer_top)
	var header = Label.new()
	header.text = _tr("PRAYER_CURRENT_STATE")
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(header)
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sep)
	_reality_bar = _create_stat_row(parent, _tr("PRAYER_STAT_REALITY"), Color(0.2, 0.6, 1.0))
	_positive_energy_bar = _create_stat_row(parent, _tr("PRAYER_STAT_POSITIVE"), Color(1.0, 0.8, 0.2))
	_entropy_bar = _create_stat_row(parent, _tr("PRAYER_STAT_ENTROPY"), Color(0.8, 0.2, 0.2))
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)
	var lore_label = Label.new()
	lore_label.text = _tr("PRAYER_HIGH_ENTROPY_WARNING")
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lore_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lore_label)
func _create_stat_row(parent: Control, title: String, color: Color) -> ProgressBar:
	var container = VBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_theme_constant_override("separation", 5)
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 20)
	bar.show_percentage = true
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_color_override("font_color", Color.WHITE)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", style_box)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)
	container.add_child(bar)
	parent.add_child(container)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)
	return bar
func _update_stats_display():
	if not GameState:
		return
	if _reality_bar:
		_reality_bar.value = GameState.reality_score
	if _positive_energy_bar:
		_positive_energy_bar.value = GameState.positive_energy
	if _entropy_bar:
		_entropy_bar.value = GameState.entropy_level
func set_context(context: String) -> void:
	_report_info("set_context: %s" % context)
	_context = context
	if _context == "night":
		if cancel_button: cancel_button.visible = false
		if home_button: home_button.visible = false
	else:
		if cancel_button:
			cancel_button.visible = true
			cancel_button.disabled = false
		if home_button:
			home_button.visible = true
			home_button.disabled = false
	_report_info("After set_context: submit_disabled=%s cancel_visible=%s cancel_disabled=%s home_visible=%s home_disabled=%s" % [
		submit_button.disabled if submit_button else "N/A",
		cancel_button.visible if cancel_button else "N/A",
		cancel_button.disabled if cancel_button else "N/A",
		home_button.visible if home_button else "N/A",
		home_button.disabled if home_button else "N/A",
	])
func _apply_modern_styling():
	if prayer_panel:
		UIStyleManager.apply_panel_style(prayer_panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	if submit_button:
		UIStyleManager.apply_button_style(submit_button, "primary", "large")
		UIStyleManager.add_hover_scale_effect(submit_button, 1.05)
		UIStyleManager.add_press_feedback(submit_button)
		submit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if cancel_button:
		UIStyleManager.apply_button_style(cancel_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(cancel_button, 1.05)
		UIStyleManager.add_press_feedback(cancel_button)
		cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if home_button:
		UIStyleManager.apply_button_style(home_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(home_button, 1.05)
		UIStyleManager.add_press_feedback(home_button)
		home_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if prayer_input:
		prayer_input.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		prayer_input.add_theme_color_override("caret_color", Color(0.7, 0.85, 1.0))
		prayer_input.add_theme_color_override("selection_color", Color(0.3, 0.5, 0.8, 0.5))
		prayer_input.add_theme_font_size_override("font_size", 16)
	if title_label:
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	if description_label:
		description_label.add_theme_font_size_override("font_size", 14)
		description_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
func _apply_localization() -> void:
	if title_label:
		title_label.text = _tr("PRAYER_TITLE")
	if description_label:
		description_label.text = _tr("PRAYER_DESCRIPTION")
	if submit_button:
		submit_button.text = _tr("NIGHT_BUTTON_PRAY") + " [1]"
	if cancel_button:
		cancel_button.text = _tr("PRAYER_CANCEL") + " [2]"
	if home_button:
		home_button.text = _tr("PRAYER_MAIN_MENU") + " [3]"
	if prayer_input:
		prayer_input.placeholder_text = _tr("PRAYER_INPUT_PLACEHOLDER")
func _maybe_show_data_notice() -> void:
	if not GameState:
		_report_info("_maybe_show_data_notice: no GameState, skip notice")
		_input_locked_by_notice = false
		_set_input_enabled(true)
		return
	if _is_offline_or_mock_mode():
		_report_info("_maybe_show_data_notice: offline/mock mode, skip notice")
		_input_locked_by_notice = false
		_set_input_enabled(true)
		if is_instance_valid(_notice_overlay):
			_notice_overlay.queue_free()
		_notice_overlay = null
		GameState.set_metadata("prayer_notice_acknowledged", true)
		return
	var has_seen := bool(GameState.get_metadata("prayer_notice_acknowledged", false))
	if has_seen:
		_report_info("_maybe_show_data_notice: already acknowledged, skip notice")
		_input_locked_by_notice = false
		_set_input_enabled(true)
		return
	_report_info("_maybe_show_data_notice: showing notice, input LOCKED")
	_set_input_enabled(false)
	_input_locked_by_notice = true
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	var notice_instance: Node = PRAYER_NOTICE_SCENE.instantiate()
	var notice_control: Control = notice_instance as Control
	if notice_control == null:
		_input_locked_by_notice = false
		_set_input_enabled(true)
		_debug_log("Prayer notice instantiation failed, unlocking input")
		return
	notice_control.process_mode = Node.PROCESS_MODE_ALWAYS
	_notice_overlay = notice_control
	add_child(notice_control)
	notice_control.connect("accepted", Callable(self, "_on_prayer_notice_accepted"))
	notice_control.connect("cancelled", Callable(self, "_on_prayer_notice_cancelled"))
func _is_offline_or_mock_mode() -> bool:
	if not AIManager:
		return true
	if AIManager.current_provider == AIConfigManager.AIProvider.MOCK_MODE:
		return true
	if AIManager.has_method("is_mock_override_enabled") and AIManager.is_mock_override_enabled():
		return true
	return false
func _set_input_enabled(enabled: bool) -> void:
	_report_info("_set_input_enabled(%s) context=%s processing=%s" % [enabled, _context, is_processing])
	if prayer_input:
		prayer_input.editable = enabled
		prayer_input.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
		if enabled and not is_processing:
			prayer_input.grab_focus()
	if submit_button:
		submit_button.disabled = not enabled or is_processing
	if cancel_button and _context != "night":
		cancel_button.disabled = not enabled
	if home_button and _context != "night":
		home_button.disabled = not enabled
func update_warning():
	var gs = GameState
	if not warning_label:
		return
	if not gs:
		warning_label.text = _tr("PRAYER_DEFAULT_WARNING")
		warning_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		return
	var warning_text = ""
	var warning_color = Color.WHITE
	if gs.cognitive_dissonance_active:
		warning_text = _tr("PRAYER_COGNITIVE_DISSONANCE")
		warning_color = Color(1.0, 0.4, 1.0)
	elif gs.reality_score < GameConstants.Prayer.REALITY_CRITICAL_THRESHOLD:
		warning_text = _tr("PRAYER_DANGER_LOW_REALITY")
		warning_color = Color(1.0, 0.2, 0.2)
	elif gs.reality_score < GameConstants.Prayer.REALITY_WARNING_THRESHOLD:
		warning_text = _tr("PRAYER_WARNING_LOW_REALITY")
		warning_color = Color(1.0, 0.6, 0.2)
	else:
		warning_text = _tr("PRAYER_FSM_RESPONSE")
		warning_color = Color(0.8, 0.8, 0.9)
	warning_label.text = warning_text
	warning_label.add_theme_color_override("font_color", warning_color)
	warning_label.add_theme_font_size_override("font_size", 15)
	if gs.reality_score < GameConstants.Prayer.REALITY_CRITICAL_THRESHOLD or gs.cognitive_dissonance_active:
		_pulse_warning()
func _on_prayer_notice_accepted() -> void:
	_input_locked_by_notice = false
	if GameState:
		GameState.set_metadata("prayer_notice_acknowledged", true)
	_set_input_enabled(true)
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	_notice_overlay = null
func _on_prayer_notice_cancelled() -> void:
	_input_locked_by_notice = false
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	_notice_overlay = null
	_on_cancel_pressed()
func _on_submit_pressed():
	_report_info("_on_submit_pressed called! locked=%s processing=%s" % [_input_locked_by_notice, is_processing])
	_debug_log("Submit pressed")
	var lang = GameState.current_language if GameState else "en"
	if is_processing:
		return
	if _input_locked_by_notice:
		return
	var prayer_text = prayer_input.text.strip_edges()
	if prayer_text.is_empty():
		var msg = _tr("PRAYER_ERROR_EMPTY")
		show_error(msg)
		return
	if prayer_text.length() < GameConstants.Prayer.MIN_INPUT_LENGTH:
		var msg = _tr("PRAYER_ERROR_TOO_SHORT")
		show_error(msg)
		return
	var original_input = prayer_input.text.strip_edges()
	if GameState and GameState.cognitive_dissonance_active:
		prayer_text = _inject_positive_words(prayer_text, lang)
	var sanitized_prayer = _sanitize_prayer_text(prayer_text)
	if sanitized_prayer.is_empty():
		var blocked_msg = _tr("PRAYER_ERROR_UNSUPPORTED")
		show_error(blocked_msg)
		return
	if sanitized_prayer.length() < GameConstants.Prayer.MIN_INPUT_LENGTH:
		var trimmed_msg = _tr("PRAYER_ERROR_TOO_SHORT_FILTERED")
		show_error(trimmed_msg)
		return
	if sanitized_prayer != original_input:
		prayer_input.text = sanitized_prayer
	prayer_text = sanitized_prayer
	_last_prayer_text = prayer_text
	if _retry_button and is_instance_valid(_retry_button):
		_retry_button.visible = false
	is_processing = true
	submit_button.disabled = true
	_start_connecting_animation()
	_trigger_curse_flash()
	_debug_log("Calling process_prayer (len=%d)" % prayer_text.length())
	process_prayer(prayer_text)
	var failsafe_timer = get_tree().create_timer(GameConstants.Prayer.REQUEST_FAILSAFE_TIMEOUT_SECONDS)
	failsafe_timer.timeout.connect(func():
		if is_processing:
			_debug_log("Prayer request timed out (failsafe)")
			_on_disaster_generated({
				"success": false,
				"error": _tr("PRAYER_ERROR_TIMEOUT"),
			})
	)
func _start_connecting_animation() -> void:
	if _connecting_tween:
		_connecting_tween.kill()
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("countdown")
	var connecting_text_1 := _tr("PRAYER_CONNECTING_1")
	var connecting_text_2 := _tr("PRAYER_CONNECTING_2")
	var connecting_text_3 := _tr("PRAYER_CONNECTING_3")
	_connecting_tween = create_tween()
	_connecting_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_connecting_tween.set_loops()
	_connecting_tween.tween_callback(func(): submit_button.text = connecting_text_1).set_delay(0.5)
	_connecting_tween.tween_callback(func(): submit_button.text = connecting_text_2).set_delay(0.5)
	_connecting_tween.tween_callback(func(): submit_button.text = connecting_text_3).set_delay(0.5)
func _trigger_curse_flash() -> void:
	var flash = ColorRect.new()
	flash.color = Color(0.8, 0.1, 0.3, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween = flash.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(flash, "color:a", 0.4, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(flash.queue_free)
	if not GameState or GameState.settings.get("screen_shake_enabled", true):
		_shake_panel()
func process_prayer(prayer_text: String):
	var gs = GameState
	prayer_text = _sanitize_prayer_text(prayer_text)
	if prayer_text.is_empty():
		return
	if not AIManager:
		_debug_log("AIManager unavailable")
		var error_msg = _tr("PRAYER_ERROR_AI_UNAVAILABLE")
		_on_disaster_generated({"success": false, "error": error_msg})
		return
	var disaster_prompt = build_disaster_prompt(prayer_text)
	_debug_log("Sending prayer request through AIManager")
	var callback = Callable(self, "_on_disaster_generated")
	AIManager.generate_story(disaster_prompt, { "purpose": "prayer", "prayer_text": prayer_text, "reality_score": gs.reality_score, "positive_energy": gs.positive_energy, "asset_ids": GameState.get_metadata("current_asset_ids", []) }, callback)
	_safe_record_event(gs, prayer_text)
	var achievement_system = ServiceLocator.get_achievement_system() if ServiceLocator else null
	if achievement_system:
		achievement_system.check_prayer()
func _safe_record_event(gs, prayer_text):
	if gs and gs.has_method("record_event"):
		gs.record_event(
			"prayer_made",
			{
				"prayer": prayer_text,
				"reality_score": gs.reality_score,
				"positive_energy": gs.positive_energy,
			},
		)
func build_disaster_prompt(prayer_text: String) -> String:
	prayer_text = _sanitize_prayer_text(prayer_text)
	var gs = GameState
	if not gs:
		return ""
	var distortion_level = ""
	if gs.reality_score < GameConstants.Prayer.REALITY_CRITICAL_THRESHOLD:
		distortion_level = _tr("PRAYER_DISTORTION_EXTREME")
	elif gs.reality_score < GameConstants.Prayer.REALITY_WARNING_THRESHOLD:
		distortion_level = _tr("PRAYER_DISTORTION_SEVERE")
	elif gs.reality_score < GameConstants.Prayer.DISTORTION_MID_REALITY_THRESHOLD:
		distortion_level = _tr("PRAYER_DISTORTION_MODERATE")
	else:
		distortion_level = _tr("PRAYER_DISTORTION_SUBTLE")
	var prompt_template = _tr("PRAYER_AI_PROMPT")
	var prompt = prompt_template % [prayer_text, gs.reality_score, gs.positive_energy, distortion_level]
	return prompt
func _on_disaster_generated(response: Dictionary):
	_debug_log("_on_disaster_generated called; success=%s" % str(response.get("success", false)))
	if not response.get("success", false):
		_debug_log("Prayer error details: %s" % str(response.get("error", "Unknown error")))
	var lang = GameState.current_language if GameState else "en"
	if _connecting_tween:
		_connecting_tween.kill()
	is_processing = false
	submit_button.disabled = false
	submit_button.text = _tr("NIGHT_BUTTON_PRAY")
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("session_fail_sting")
	if response.get("success", false):
		if not GameState:
			ErrorReporterBridge.report_warning("PrayerSystem", "GameState unavailable while processing prayer result")
			show_error(_tr("PRAYER_ERROR_AI_UNAVAILABLE"))
			_show_retry_button(lang)
			return
		var disaster_text = String(response.get("content", ""))
		var reality_penalty = GameConstants.Prayer.BASE_REALITY_PENALTY
		var positive_increase = GameConstants.Prayer.BASE_POSITIVE_GAIN
		var entropy_increase = GameConstants.Prayer.BASE_ENTROPY_GAIN
		if GameState.reality_score < GameConstants.Prayer.REALITY_CRITICAL_THRESHOLD:
			reality_penalty = GameConstants.Prayer.CRITICAL_REALITY_PENALTY
			positive_increase = GameConstants.Prayer.CRITICAL_POSITIVE_GAIN
			entropy_increase = GameConstants.Prayer.CRITICAL_ENTROPY_GAIN
		elif GameState.reality_score < GameConstants.Prayer.REALITY_WARNING_THRESHOLD:
			reality_penalty = GameConstants.Prayer.WARNING_REALITY_PENALTY
			positive_increase = GameConstants.Prayer.WARNING_POSITIVE_GAIN
			entropy_increase = GameConstants.Prayer.WARNING_ENTROPY_GAIN
		GameState.modify_reality_score(reality_penalty)
		GameState.modify_positive_energy(positive_increase)
		var entropy_reason = _tr("REASON_PRAYER_AFTERSHOCK")
		GameState.modify_entropy(entropy_increase, entropy_reason)
		var result = {
			"prayer": prayer_input.text,
			"disaster": disaster_text,
			"reality_change": reality_penalty,
			"positive_change": positive_increase,
			"entropy_change": entropy_increase,
			"context": _context,
		}
		prayer_completed.emit(result)
		_debug_log("Prayer completed signal emitted")
		queue_free()
	else:
		var error_text = String(response.get("error", "Unknown error"))
		var display_error: String
		if "timed out" in error_text.to_lower() or "timeout" in error_text.to_lower():
			display_error = _tr("PRAYER_ERROR_TIMEOUT")
		elif "network" in error_text.to_lower() or "connection" in error_text.to_lower():
			display_error = _tr("PRAYER_ERROR_NETWORK")
		elif "api" in error_text.to_lower() or "key" in error_text.to_lower():
			display_error = _tr("PRAYER_ERROR_API")
		else:
			var error_msg = _tr("PRAYER_ERROR_PREFIX")
			display_error = error_msg + error_text
		show_error(display_error)
		_show_retry_button(lang)
func _on_cancel_pressed():
	_report_info("_on_cancel_pressed called!")
	prayer_cancelled.emit()
	queue_free()
func _on_home_pressed():
	_report_info("_on_home_pressed called!")
	if GameState:
		GameState.save_game()
	var tree = get_tree()
	if tree:
		tree.paused = false
		tree.change_scene_to_file("res://1.Codebase/menu_main.tscn")
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "SceneTree unavailable in _on_home_pressed")
func get_audio_manager():
	if ServiceLocator and ServiceLocator.has_service("AudioManager"):
		return ServiceLocator.get_service("AudioManager")
	return null
func show_error(message: String):
	if not warning_label:
		return
	warning_label.text = message
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	warning_label.add_theme_font_size_override("font_size", 15)
	if not GameState or GameState.settings.get("screen_shake_enabled", true):
		_shake_panel()
func _show_retry_button(lang: String) -> void:
	if not _retry_button or not is_instance_valid(_retry_button):
		_retry_button = Button.new()
		_retry_button.name = "RetryButton"
		_retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_retry_button.custom_minimum_size = Vector2(0, 45)
		_retry_button.pressed.connect(_on_retry_pressed)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.8, 0.3, 0.3, 1.0)
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_left = 8
		stylebox.corner_radius_bottom_right = 8
		_retry_button.add_theme_stylebox_override("normal", stylebox)
		var hover_style = stylebox.duplicate()
		hover_style.bg_color = Color(1.0, 0.4, 0.4, 1.0)
		_retry_button.add_theme_stylebox_override("hover", hover_style)
		_retry_button.add_theme_color_override("font_color", Color.WHITE)
		_retry_button.add_theme_font_size_override("font_size", 18)
		if warning_label and warning_label.get_parent():
			var parent = warning_label.get_parent()
			var warning_idx = warning_label.get_index()
			parent.add_child(_retry_button)
			parent.move_child(_retry_button, warning_idx + 1)
	_retry_button.text = _tr("PRAYER_RETRY")
	_retry_button.visible = true
func _on_retry_pressed() -> void:
	var lang = GameState.current_language if GameState else "en"
	update_warning()
	if _retry_button and is_instance_valid(_retry_button):
		_retry_button.visible = false
	var prayer_text = _last_prayer_text if not _last_prayer_text.is_empty() else prayer_input.text.strip_edges()
	if prayer_text.is_empty():
		show_error(_tr("PRAYER_ERROR_EMPTY"))
		return
	is_processing = true
	submit_button.disabled = true
	_start_connecting_animation()
	_trigger_curse_flash()
	_debug_log("Retrying prayer (len=%d)" % prayer_text.length())
	process_prayer(prayer_text)
	get_tree().create_timer(GameConstants.Prayer.REQUEST_FAILSAFE_TIMEOUT_SECONDS).timeout.connect(func():
		if is_processing:
			_debug_log("Retry prayer request timed out (failsafe)")
			_on_disaster_generated({
				"success": false,
				"error": _tr("PRAYER_ERROR_TIMEOUT"),
			})
	)
func _sanitize_prayer_text(prayer_text: String) -> String:
	var sanitized = prayer_text.strip_edges()
	if AIManager and AIManager.has_method("sanitize_user_text"):
		sanitized = AIManager.sanitize_user_text(sanitized, GameConstants.Prayer.MAX_SANITIZED_INPUT_LENGTH)
	else:
		sanitized = sanitized.replace("\r", " ")
		sanitized = sanitized.replace("\n", " ")
		sanitized = sanitized.replace("\t", " ")
		var blocked_tokens = ["```", ":::", "===", "[INST]", "[/INST]", "<s>", "</s>"]
		for token in blocked_tokens:
			sanitized = sanitized.replace(token, "")
		var regex = RegEx.new()
		regex.compile("\\s+")
		sanitized = regex.sub(sanitized, " ", true).strip_edges()
		if sanitized.length() > GameConstants.Prayer.MAX_SANITIZED_INPUT_LENGTH:
			sanitized = sanitized.substr(0, GameConstants.Prayer.MAX_SANITIZED_INPUT_LENGTH)
	return sanitized
func _tr_local(key: String, fallback_en: String, fallback_zh: String) -> String:
	var lang := GameState.current_language if GameState else "en"
	if LocalizationManager:
		var translated: String = LocalizationManager.get_translation(key, lang)
		if not translated.is_empty() and translated != key:
			return translated
	return fallback_zh if lang == "zh" else fallback_en
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
func _inject_positive_words(prayer_text: String, _lang: String) -> String:
	var positive_words = [
		_tr("PRAYER_POSITIVE_WORD_1"),
		_tr("PRAYER_POSITIVE_WORD_2"),
		_tr("PRAYER_POSITIVE_WORD_3"),
		_tr("PRAYER_POSITIVE_WORD_4"),
		_tr("PRAYER_POSITIVE_WORD_5"),
		_tr("PRAYER_POSITIVE_WORD_6"),
		_tr("PRAYER_POSITIVE_WORD_7"),
	]
	var injected_word = positive_words[randi() % positive_words.size()]
	var injection_template = _tr("PRAYER_POSITIVE_INJECTION")
	return prayer_text + injection_template % injected_word
func _pulse_warning():
	if not warning_label:
		return
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(warning_label, "modulate:a", 0.6, 0.8)
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.8)
func _shake_panel():
	if not prayer_panel:
		return
	var original_pos = prayer_panel.position
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
	for i in range(4):
		var offset_x = 10 if i % 2 == 0 else -10
		tween.tween_property(prayer_panel, "position", original_pos + Vector2(offset_x, 0), 0.05)
	tween.tween_property(prayer_panel, "position", original_pos, 0.1)
func _create_mystical_atmosphere() -> void:
	_create_floating_particles()
	_create_wifi_symbols()
	_create_candle_flames()
	_create_mysterious_background()
	_create_pasta_tendrils()
	_create_ritual_circle()
	_start_mystical_glow()
	_play_ambient_sound()
func _create_floating_particles() -> void:
	for i in range(20):
		var particle = ColorRect.new()
		particle.custom_minimum_size = Vector2(3, 3)
		particle.color = Color(0.9, 0.8, 0.3, randf_range(0.3, 0.7))
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var viewport_size = get_viewport_rect().size
		particle.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)
		add_child(particle)
		_floating_particles.append(particle)
		_animate_particle_float(particle, i)
func _animate_particle_float(particle: Control, index: int) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var viewport_size = get_viewport_rect().size
	var duration = randf_range(3.0, 6.0)
	var delay = index * 0.1
	tween.tween_property(
		particle,
		"position",
		Vector2(randf_range(0, viewport_size.x), randf_range(0, viewport_size.y)),
		duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(delay)
	var fade_tween = create_tween()
	fade_tween.set_loops()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(particle, "modulate:a", 0.2, 2.0).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(particle, "modulate:a", 0.8, 2.0).set_ease(Tween.EASE_IN_OUT)
func _create_wifi_symbols() -> void:
	for i in range(3):
		var wifi_container = Control.new()
		wifi_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(wifi_container)
		var wifi_symbol = _draw_wifi_symbol()
		wifi_container.add_child(wifi_symbol)
		var angle = (i * TAU / 3.0) + PI / 6.0
		var radius = 350
		var center = get_viewport_rect().size / 2.0
		wifi_container.position = center + Vector2(cos(angle), sin(angle)) * radius
		_wifi_symbols.append(wifi_container)
		_animate_wifi_pulse(wifi_container, i)
func _draw_wifi_symbol() -> Control:
	var wifi = Control.new()
	wifi.custom_minimum_size = Vector2(60, 60)
	wifi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for arc_index in range(3):
		var arc = ColorRect.new()
		var size = 20 + arc_index * 15
		arc.custom_minimum_size = Vector2(size, size)
		arc.size = Vector2(size, size)
		arc.color = Color(0.3, 0.8, 1.0, 0.6 - arc_index * 0.15)
		arc.position = Vector2(-size / 2, -size / 2) + Vector2(30, 30)
		arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wifi.add_child(arc)
	var dot = ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size = Vector2(8, 8)
	dot.color = Color(0.3, 0.8, 1.0, 0.9)
	dot.position = Vector2(26, 50)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wifi.add_child(dot)
	return wifi
func _animate_wifi_pulse(wifi: Control, index: int) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var delay = index * 0.5
	tween.tween_property(wifi, "modulate:a", 0.3, 1.5).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
	tween.tween_property(wifi, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_IN_OUT)
	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rotate_tween.tween_property(wifi, "rotation", TAU, 20.0).set_delay(delay)
func _create_candle_flames() -> void:
	var positions = [
		Vector2(0.15, 0.2),
		Vector2(0.85, 0.2),
		Vector2(0.15, 0.8),
		Vector2(0.85, 0.8),
	]
	var viewport_size = get_viewport_rect().size
	for pos_ratio in positions:
		var flame = _create_flame_effect()
		flame.position = Vector2(
			viewport_size.x * pos_ratio.x,
			viewport_size.y * pos_ratio.y
		)
		add_child(flame)
		_candle_flames.append(flame)
func _create_flame_effect() -> Control:
	var flame_container = Control.new()
	flame_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(3):
		var flame_part = ColorRect.new()
		var size = 15 - i * 3
		flame_part.custom_minimum_size = Vector2(size, size * 1.5)
		flame_part.size = Vector2(size, size * 1.5)
		var colors = [
			Color(1.0, 0.9, 0.3, 0.8),
			Color(1.0, 0.5, 0.1, 0.6),
			Color(0.8, 0.2, 0.0, 0.4)
		]
		flame_part.color = colors[i]
		flame_part.position = Vector2(-size / 2, -size * 1.5) + Vector2(0, i * 5)
		flame_part.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flame_container.add_child(flame_part)
		_animate_flame_flicker(flame_part, i)
	return flame_container
func _animate_flame_flicker(flame: ColorRect, index: int) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var delay = index * 0.1
	tween.tween_property(flame, "scale", Vector2(1.0, 1.2), 0.15).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
	tween.tween_property(flame, "scale", Vector2(0.9, 0.8), 0.15).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flame, "scale", Vector2(1.05, 1.1), 0.1).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flame, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN_OUT)
func _create_mysterious_background() -> void:
	var bg_img = TextureRect.new()
	bg_img.texture = PRAYER_SCENE_BG
	bg_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_img.modulate = Color(0.7, 0.65, 0.85, 1.0)
	add_child(bg_img)
	move_child(bg_img, 0)
	var vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0.02, 0.0, 0.08, 0.55)
	add_child(vignette)
	move_child(vignette, 1)
	var tween = create_tween()
	tween.set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(vignette, "color:a", 0.70, 3.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(vignette, "color:a", 0.40, 3.5).set_ease(Tween.EASE_IN_OUT)
func _start_mystical_glow() -> void:
	if not prayer_panel:
		return
	_mystical_glow_tween = create_tween()
	_mystical_glow_tween.set_loops()
	_mystical_glow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var glow_color_1 = Color(0.2, 0.15, 0.3, 1.0)
	var glow_color_2 = Color(0.15, 0.2, 0.35, 1.0)
	_mystical_glow_tween.tween_property(prayer_panel, "self_modulate", glow_color_1, 4.0).set_ease(Tween.EASE_IN_OUT)
	_mystical_glow_tween.tween_property(prayer_panel, "self_modulate", glow_color_2, 4.0).set_ease(Tween.EASE_IN_OUT)
func _enhance_input_field_sacred() -> void:
	if not prayer_input:
		return
	if not prayer_input.text_changed.is_connected(_on_prayer_text_changed):
		prayer_input.text_changed.connect(_on_prayer_text_changed)
	_input_glow_style = StyleBoxFlat.new()
	_input_glow_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	_input_glow_style.border_width_left = 2
	_input_glow_style.border_width_right = 2
	_input_glow_style.border_width_top = 2
	_input_glow_style.border_width_bottom = 2
	_input_glow_style.border_color = Color(0.3, 0.7, 1.0, 0.6)
	_input_glow_style.corner_radius_top_left = 8
	_input_glow_style.corner_radius_top_right = 8
	_input_glow_style.corner_radius_bottom_left = 8
	_input_glow_style.corner_radius_bottom_right = 8
	_input_glow_style.shadow_size = 10
	_input_glow_style.shadow_color = Color(0.3, 0.7, 1.0, 0.3)
	prayer_input.add_theme_stylebox_override("normal", _input_glow_style)
	prayer_input.add_theme_stylebox_override("focus", _input_glow_style)
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glow_tween.tween_method(_update_input_glow, 0.3, 1.0, 2.0).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_method(_update_input_glow, 1.0, 0.3, 2.0).set_ease(Tween.EASE_IN_OUT)
func _update_input_glow(intensity: float) -> void:
	if not prayer_input or not _input_glow_style:
		return
	_input_glow_style.border_color = Color(0.3, 0.7, 1.0, intensity * 0.8)
	_input_glow_style.shadow_size = int(10 * intensity)
	_input_glow_style.shadow_color = Color(0.3, 0.7, 1.0, intensity * 0.5)
func _create_pasta_tendrils() -> void:
	for i in range(6):
		var tendril = _create_single_tendril(i)
		add_child(tendril)
		_pasta_tendrils.append(tendril)
func _create_single_tendril(index: int) -> Control:
	var tendril_container = Control.new()
	tendril_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2.0
	var num_segments = 8
	var segment_size = Vector2(4, 25)
	for seg_idx in range(num_segments):
		var segment = ColorRect.new()
		segment.custom_minimum_size = segment_size
		segment.size = segment_size
		var alpha = 0.5 - (seg_idx * 0.05)
		segment.color = Color(0.9, 0.85, 0.5, alpha)
		segment.position = Vector2(0, seg_idx * segment_size.y * 0.8)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.pivot_offset = segment_size / 2.0
		tendril_container.add_child(segment)
		_animate_tendril_segment(segment, seg_idx, index)
	var angle = (index * TAU / 6.0)
	var radius = 250 + randf_range(-30, 30)
	tendril_container.position = center + Vector2(cos(angle), sin(angle)) * radius
	tendril_container.rotation = angle + PI / 2
	return tendril_container
func _animate_tendril_segment(segment: ColorRect, seg_idx: int, tendril_idx: int) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var delay = (tendril_idx * 0.2) + (seg_idx * 0.05)
	var base_rotation = segment.rotation
	tween.tween_property(segment, "rotation", base_rotation + deg_to_rad(15), 1.0 + randf_range(0, 0.5)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(delay)
	tween.tween_property(segment, "rotation", base_rotation - deg_to_rad(15), 1.0 + randf_range(0, 0.5)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(segment, "rotation", base_rotation, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
func _create_ritual_circle() -> void:
	_ritual_circle = Control.new()
	_ritual_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2.0
	_ritual_circle.position = center
	for circle_idx in range(3):
		var radius = 200 + (circle_idx * 60)
		_create_circle_ring(_ritual_circle, radius, circle_idx)
	add_child(_ritual_circle)
	move_child(_ritual_circle, 2)
	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rotate_tween.tween_property(_ritual_circle, "rotation", TAU, 30.0)
func _create_circle_ring(parent: Control, radius: float, circle_idx: int) -> void:
	var num_symbols = 12 + (circle_idx * 4)
	var symbol_colors = [
		Color(0.3, 0.7, 1.0, 0.4),
		Color(0.5, 0.8, 1.0, 0.3),
		Color(0.2, 0.6, 0.9, 0.2)
	]
	for i in range(num_symbols):
		var angle = (i * TAU / num_symbols)
		var symbol = ColorRect.new()
		if i % 3 == 0:
			symbol.custom_minimum_size = Vector2(6, 6)
			symbol.size = Vector2(6, 6)
		else:
			symbol.custom_minimum_size = Vector2(3, 8)
			symbol.size = Vector2(3, 8)
		symbol.color = symbol_colors[circle_idx]
		symbol.position = Vector2(cos(angle), sin(angle)) * radius - symbol.size / 2.0
		symbol.rotation = angle + PI / 2
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(symbol)
		_animate_circle_symbol(symbol, i, circle_idx)
func _animate_circle_symbol(symbol: Control, index: int, circle_idx: int) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var delay = (index * 0.05) + (circle_idx * 0.1)
	tween.tween_property(symbol, "modulate:a", 0.2, 1.5).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
	tween.tween_property(symbol, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_IN_OUT)
func _play_ambient_sound() -> void:
	var audio_manager = get_audio_manager()
	if not audio_manager:
		return
	if audio_manager.has_method("get_current_music"):
		_previous_music = audio_manager.get_current_music()
	_playlist_was_active = audio_manager.has_method("is_playlist_active") and audio_manager.is_playlist_active()
	if not audio_manager.has_method("play_music"):
		return
	if audio_manager.has_method("suspend_gameplay_playlist"):
		audio_manager.suspend_gameplay_playlist()
	if audio_manager.has_method("stop_music") and audio_manager.is_music_playing():
		audio_manager.stop_music(1.5)
	var tree = get_tree()
	if not tree:
		return
	await tree.create_timer(1.6).timeout
	if not is_instance_valid(self):
		return
	audio_manager.play_music("prayer_music", true)
	if audio_manager.music_player:
		audio_manager.music_player.volume_db = -40.0
		var fade_tw = create_tween()
		fade_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tw.tween_property(audio_manager.music_player, "volume_db", 0.0, 2.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
func _on_prayer_text_changed() -> void:
	var new_len: int = prayer_input.text.length()
	if new_len == _last_text_len:
		return
	_last_text_len = new_len
	_spawn_typing_symbol()
	_intensify_input_glow()
	if _ritual_circle and is_instance_valid(_ritual_circle):
		var tw = create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_ritual_circle, "rotation", _ritual_circle.rotation + TAU * 0.08, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if prayer_panel and is_instance_valid(prayer_panel):
		var flash_tw = create_tween()
		flash_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		flash_tw.tween_property(prayer_panel, "self_modulate", Color(1.12, 1.08, 1.18, 1.0), 0.06)
		flash_tw.tween_property(prayer_panel, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
func _spawn_typing_symbol() -> void:
	if not prayer_input or not is_instance_valid(prayer_input):
		return
	var sym_char: String = _typing_symbol_chars[randi() % _typing_symbol_chars.size()]
	var sym = Label.new()
	sym.text = sym_char
	sym.add_theme_font_size_override("font_size", randi_range(14, 28))
	var palette = [
		Color(1.0, 0.88, 0.28, 0.90),   
		Color(0.40, 0.85, 1.0,  0.90),  
		Color(0.82, 0.55, 1.0,  0.90),  
		Color(1.0, 0.55, 0.75,  0.85),  
	]
	sym.add_theme_color_override("font_color", palette[randi() % palette.size()])
	sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sym)
	var input_rect: Rect2 = prayer_input.get_global_rect()
	var start_x: float = randf_range(input_rect.position.x, input_rect.end.x - 10.0)
	var start_y: float = input_rect.position.y - 10.0
	sym.global_position = Vector2(start_x, start_y)
	var drift_x: float = randf_range(-40.0, 40.0)
	var drift_y: float = randf_range(-80.0, -140.0)
	var dur: float = randf_range(0.8, 1.5)
	var tw = sym.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(sym, "global_position",
		Vector2(start_x + drift_x, start_y + drift_y), dur) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sym, "modulate:a", 0.0, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(sym.queue_free)
func _intensify_input_glow() -> void:
	if not prayer_input or not is_instance_valid(prayer_input):
		return
	if _typing_burst_tween and _typing_burst_tween.is_valid():
		_typing_burst_tween.kill()
	_typing_burst_tween = create_tween()
	_typing_burst_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_typing_burst_tween.tween_method(
		func(v: float):
			if not _input_glow_style or not prayer_input or not is_instance_valid(prayer_input):
				return
			_input_glow_style.border_color = Color(0.60, 0.30, 1.0, v)
			_input_glow_style.shadow_size  = int(18.0 * v)
			_input_glow_style.shadow_color = Color(0.55, 0.20, 1.0, v * 0.65),
		0.45, 1.0, 0.08          
	)
	_typing_burst_tween.tween_method(
		func(v: float):
			if not _input_glow_style or not prayer_input or not is_instance_valid(prayer_input):
				return
			_input_glow_style.border_color = Color(0.30, 0.70, 1.0, v)
			_input_glow_style.shadow_size  = int(10.0 * v)
			_input_glow_style.shadow_color = Color(0.30, 0.70, 1.0, v * 0.5),
		1.0, 0.45, 0.60          
	)
