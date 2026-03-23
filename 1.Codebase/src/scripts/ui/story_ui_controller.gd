extends "res://1.Codebase/src/scripts/ui/base_controller.gd"
class_name StoryUIController
var ui_bindings: StorySceneUIBindings
var story_text: RichTextLabel
var story_scroll: ScrollContainer
var reality_bar: ProgressBar
var reality_value: Label
var positive_bar: ProgressBar
var positive_value: Label
var entropy_value: Label
var loading_overlay: Control
var loading_label: Label
var loading_sublabel: Label
var loading_dots: Label
var loading_timer_label: Label
var loading_model_label: Label
var status_label: Label
var ai_error_overlay: Control
var ai_error_title_label: Label
var ai_error_message_label: Label
var ai_error_details_label: Label
var ai_error_retry_button: Button
var ai_error_offline_button: Button
var ai_error_home_button: Button
var loading_animation_time: float = 0.0
var loading_start_time: float = 0.0
var current_loading_context: String = "default"
var _story_typewriter_tween: Tween = null
var _current_story_index: int = -1  
var _is_viewing_history: bool = false
var prev_story_button: Button
var next_story_button: Button
var story_nav_label: Label
const MarkdownParser = preload("res://1.Codebase/src/scripts/ui/markdown_parser.gd")
const StoryUIHelper = preload("res://1.Codebase/src/scripts/ui/story_ui_helper.gd")
const LoadingDisplay = preload("res://1.Codebase/src/scripts/ui/loading_display.gd")
const GameConstants = preload("res://1.Codebase/src/scripts/core/game_constants.gd")
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _init(p_story_scene: Control) -> void:
	super(p_story_scene)
	_setup_ui_references()
func _setup_ui_references() -> void:
	ui_bindings = _resolve_ui_bindings()
	if not ui_bindings:
		_report_error("StorySceneUIBindings reference not available for StoryUIController")
		return
	story_text = ui_bindings.story_text
	story_scroll = ui_bindings.story_scroll
	reality_bar = ui_bindings.reality_bar
	reality_value = ui_bindings.reality_value
	positive_bar = ui_bindings.positive_bar
	positive_value = ui_bindings.positive_value
	entropy_value = ui_bindings.entropy_value
	loading_overlay = ui_bindings.loading_overlay
	loading_label = ui_bindings.loading_label
	loading_sublabel = ui_bindings.loading_sublabel
	loading_dots = ui_bindings.loading_dots
	loading_timer_label = ui_bindings.loading_timer_label
	loading_model_label = ui_bindings.loading_model_label
	status_label = ui_bindings.status_label
	ai_error_overlay = ui_bindings.ai_error_overlay
	ai_error_title_label = ui_bindings.ai_error_title_label
	ai_error_message_label = ui_bindings.ai_error_message_label
	ai_error_details_label = ui_bindings.ai_error_details_label
	ai_error_retry_button = ui_bindings.ai_error_retry_button
	ai_error_offline_button = ui_bindings.ai_error_offline_button
	ai_error_home_button = ui_bindings.ai_error_home_button
	var p_btn = ui_bindings.prev_story_button if ui_bindings else null
	var n_btn = ui_bindings.next_story_button if ui_bindings else null
	var n_lbl = ui_bindings.story_nav_label if ui_bindings else null
	if not p_btn and story_scene:
		p_btn = story_scene.get_node_or_null("NarratorBox/MarginContainer/VBoxContainer/StoryNavigation/PrevStoryButton") as Button
	if not n_btn and story_scene:
		n_btn = story_scene.get_node_or_null("NarratorBox/MarginContainer/VBoxContainer/StoryNavigation/NextStoryButton") as Button
	if not n_lbl and story_scene:
		n_lbl = story_scene.get_node_or_null("NarratorBox/MarginContainer/VBoxContainer/StoryNavigation/StoryNavLabel") as Label
	if p_btn and n_btn and n_lbl:
		setup_story_navigation_buttons(p_btn, n_btn, n_lbl)
	else:
		_report_warning("Story navigation buttons not found, nav bar will not be functional")
func _resolve_ui_bindings() -> StorySceneUIBindings:
	if not story_scene:
		return null
	var binding: Variant = null
	if story_scene.has_method("get_ui_bindings"):
		binding = story_scene.get_ui_bindings()
	if (binding == null or not is_instance_valid(binding)) and story_scene.has_method("get_ui"):
		binding = story_scene.get_ui()
	if binding is StorySceneUIBindings and is_instance_valid(binding):
		return binding
	return null
func update_stats_display() -> void:
	var game_state: Node = get_game_state()
	if not game_state:
		return
	_update_reality_display(game_state)
	_update_positive_energy_display(game_state)
	_update_entropy_display(game_state)
func _update_reality_display(game_state: Node) -> void:
	if reality_bar:
		reality_bar.value = game_state.reality_score
		_apply_stat_color_gradient(reality_bar, game_state.reality_score)
	if reality_value:
		reality_value.text = str(game_state.reality_score)
func _update_positive_energy_display(game_state: Node) -> void:
	if positive_bar:
		positive_bar.value = game_state.positive_energy
		_apply_stat_color_gradient(positive_bar, game_state.positive_energy)
	if positive_value:
		positive_value.text = str(game_state.positive_energy)
func _update_entropy_display(game_state: Node) -> void:
	if entropy_value:
		var entropy_level: float = game_state.entropy_level
		var entropy_text := str(entropy_level)
		if entropy_level > GameConstants.Stats.HIGH_ENTROPY_CRITICAL:
			entropy_text = "[color=red]%s ?[/color]" % entropy_text
		elif entropy_level > GameConstants.Stats.HIGH_ENTROPY_WARNING:
			entropy_text = "[color=yellow]%s[/color]" % entropy_text
		entropy_value.text = entropy_text
func _apply_stat_color_gradient(bar: ProgressBar, value: int) -> void:
	if not bar:
		return
	var style := bar.get_theme_stylebox("fill")
	if not style is StyleBoxFlat:
		return
	var color: Color = GameConstants.UI.COLOR_STAT_LOW
	if value >= GameConstants.UI.STAT_COLOR_HIGH_THRESHOLD:
		color = GameConstants.UI.COLOR_STAT_HIGH
	elif value >= GameConstants.UI.STAT_COLOR_MEDIUM_THRESHOLD:
		color = GameConstants.UI.COLOR_STAT_MEDIUM
	style.bg_color = color
func display_story(content: String) -> void:
	if not story_text:
		return
	if _is_viewing_history:
		reset_to_latest_story()
	var should_autoscroll := false
	if story_scroll:
		var prev_bar: ScrollBar = story_scroll.get_v_scroll_bar()
		if prev_bar:
			var distance_to_bottom := prev_bar.max_value - prev_bar.value
			should_autoscroll = distance_to_bottom <= 80.0
	var bbcode: String = MarkdownParser.parse_markdown(content)
	var current_text := story_text.get_parsed_text()
	if not current_text.is_empty():
		story_text.append_text("\n\n")
	var prev_char_count = story_text.get_parsed_text().length()
	story_text.append_text(bbcode)
	var game_state = get_game_state()
	var text_speed = 1.0
	if game_state and "settings" in game_state:
		text_speed = game_state.settings.get("text_speed", 1.0)
	if text_speed > 0.0:
		var new_char_count = story_text.get_parsed_text().length()
		var chars_to_add = new_char_count - prev_char_count
		if chars_to_add > 0:
			if _story_typewriter_tween and _story_typewriter_tween.is_valid():
				_story_typewriter_tween.kill()
			story_text.visible_characters = prev_char_count
			var chars_per_sec = 50.0 * text_speed
			var duration = float(chars_to_add) / max(chars_per_sec, 1.0)
			_story_typewriter_tween = story_scene.create_tween()
			_story_typewriter_tween.tween_property(story_text, "visible_characters", new_char_count, duration)
			_story_typewriter_tween.tween_callback(func(): story_text.visible_characters = -1)
	else:
		story_text.visible_characters = -1
	await story_scene.get_tree().process_frame
	if story_scroll:
		var scroll_bar = story_scroll.get_v_scroll_bar()
		if not scroll_bar:
			return
		if not should_autoscroll:
			if prev_char_count == 0:
				story_scroll.scroll_vertical = 0
			return
		var target_value = int(scroll_bar.max_value)
		var current_val = scroll_bar.value
		if abs(target_value - current_val) < 1000:
			var tween = story_scroll.create_tween()
			tween.tween_property(story_scroll, "scroll_vertical", target_value, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			story_scroll.scroll_vertical = target_value
	_update_nav_buttons()
func clear_story_text() -> void:
	if _story_typewriter_tween and _story_typewriter_tween.is_valid():
		_story_typewriter_tween.kill()
		_story_typewriter_tween = null
	if story_text:
		story_text.clear()
		story_text.visible_characters = -1
func show_loading(should_show: bool, context: String = "default") -> void:
	if not loading_overlay:
		return
	if should_show:
		_start_loading(context)
	else:
		_stop_loading()
func _start_loading(context: String) -> void:
	current_loading_context = context
	if not loading_overlay:
		_report_warning("Loading overlay not bound; cannot start loading UI")
		return
	loading_overlay.visible = true
	loading_start_time = Time.get_ticks_msec() / 1000.0
	loading_animation_time = 0.0
	var game_state: Node = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	if loading_label:
		loading_label.text = LoadingDisplay.get_random_loading_phrase(lang)
	if loading_sublabel:
		loading_sublabel.text = LoadingDisplay.get_loading_sublabel(context, lang)
	if loading_model_label:
		var ai_manager: Node = get_ai_manager()
		if ai_manager:
			var model := _get_current_model_name(ai_manager)
			loading_model_label.text = "Model: " + model
		else:
			loading_model_label.text = ""
	if loading_timer_label:
		loading_timer_label.text = "00:00"
func _stop_loading() -> void:
	if loading_overlay:
		loading_overlay.visible = false
func update_loading_progress(progress_info: Dictionary) -> void:
	if not loading_overlay or not loading_overlay.visible:
		return
	var game_state: Node = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var message := LoadingDisplay.get_progress_display_text(progress_info, lang)
	if loading_label:
		loading_label.text = message
func process_loading_animation(delta: float) -> void:
	if not loading_overlay or not loading_overlay.visible:
		return
	loading_animation_time += delta
	if loading_dots:
		loading_dots.text = LoadingDisplay.get_loading_dots_for_time(loading_animation_time)
	if loading_timer_label:
		var elapsed := (Time.get_ticks_msec() / 1000.0) - loading_start_time
		loading_timer_label.text = LoadingDisplay.format_elapsed_time(elapsed)
func show_ai_error_overlay(title: String, message: String, details: String = "", offline_enabled: bool = true) -> void:
	if not ai_error_overlay:
		return
	var resolved_title := title.strip_edges()
	if resolved_title.is_empty():
		resolved_title = "AI Error"
	var resolved_message := message.strip_edges()
	if resolved_message.is_empty():
		resolved_message = "The AI service did not respond."
	var resolved_details := details.strip_edges()
	ai_error_overlay.visible = true
	if ai_error_title_label:
		ai_error_title_label.text = resolved_title
	if ai_error_message_label:
		ai_error_message_label.text = resolved_message
	if ai_error_details_label:
		ai_error_details_label.text = resolved_details
		ai_error_details_label.visible = not resolved_details.is_empty()
	var lang := "en"
	var game_state = get_game_state()
	if game_state:
		lang = String(game_state.current_language)
	var retry_text: String = String(LocalizationManager.get_translation("STORY_RETRY_BUTTON", lang))
	var offline_text: String = String(LocalizationManager.get_translation("STORY_OFFLINE_BUTTON", lang))
	var home_text: String = String(LocalizationManager.get_translation("STORY_HOME_BUTTON", lang))
	if ai_error_retry_button:
		ai_error_retry_button.visible = true
		ai_error_retry_button.disabled = false
		ai_error_retry_button.text = retry_text
	if ai_error_offline_button:
		ai_error_offline_button.visible = offline_enabled
		ai_error_offline_button.disabled = not offline_enabled
		ai_error_offline_button.text = offline_text
	if ai_error_home_button:
		ai_error_home_button.visible = true
		ai_error_home_button.disabled = false
		ai_error_home_button.text = home_text
	if offline_enabled and ai_error_offline_button and ai_error_offline_button.is_inside_tree():
		ai_error_offline_button.grab_focus()
	elif ai_error_retry_button and ai_error_retry_button.is_inside_tree():
		ai_error_retry_button.grab_focus()
	elif ai_error_home_button and ai_error_home_button.is_inside_tree():
		ai_error_home_button.grab_focus()
func hide_ai_error_overlay() -> void:
	if not ai_error_overlay:
		return
	ai_error_overlay.visible = false
	if ai_error_message_label:
		ai_error_message_label.text = ""
	if ai_error_details_label:
		ai_error_details_label.text = ""
		ai_error_details_label.visible = false
	if ai_error_retry_button:
		ai_error_retry_button.visible = false
	if ai_error_offline_button:
		ai_error_offline_button.visible = false
	if ai_error_home_button:
		ai_error_home_button.visible = false
func _get_current_model_name(ai_manager: Node) -> String:
	if not ai_manager:
		return "Unknown"
	match ai_manager.current_provider:
		0:
			return ai_manager.gemini_model
		1:
			return ai_manager.openrouter_model
		2:
			return ai_manager.ollama_model
		_:
			return "Unknown"
func update_ui_labels() -> void:
	var game_state: Node = get_game_state()
	if not game_state:
		return
func apply_font_sizes() -> void:
	var font_manager = get_font_manager()
	if not font_manager:
		return
	if story_text:
		var font_size: int = font_manager.get_font_size("story_text")
		if font_size > 0:
			story_text.add_theme_font_size_override("normal_font_size", font_size)
func set_status_text(text: String) -> void:
	if status_label:
		status_label.text = text
func animate_ui_entrance() -> void:
	if story_text:
		story_text.modulate.a = 0.0
		var tween := story_scene.create_tween()
		tween.tween_property(story_text, "modulate:a", 1.0, 0.5)
func show_welcome_message() -> void:
	var welcome_text := _tr("STORY_WELCOME_TEXT")
	display_story(welcome_text)
func setup_story_navigation_buttons(prev_btn: Button, next_btn: Button, nav_label: Label) -> void:
	prev_story_button = prev_btn
	next_story_button = next_btn
	story_nav_label = nav_label
	if prev_story_button:
		prev_story_button.pressed.connect(_on_prev_story_pressed)
	if next_story_button:
		next_story_button.pressed.connect(_on_next_story_pressed)
	_update_nav_buttons()
func _on_prev_story_pressed() -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var history_count = game_state.get_story_history_count()
	if history_count == 0:
		return
	if _current_story_index == -1:
		_current_story_index = history_count - 2
	else:
		_current_story_index -= 1
	if _current_story_index < 0:
		_current_story_index = 0
	_show_story_at_current_index()
func _on_next_story_pressed() -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var history_count = game_state.get_story_history_count()
	if history_count == 0:
		return
	_current_story_index += 1
	if _current_story_index >= history_count - 1:
		_current_story_index = -1
		_show_latest_story()
		return
	_show_story_at_current_index()
func _show_story_at_current_index() -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var story_content = game_state.get_story_at_index(_current_story_index)
	if story_content.is_empty():
		return
	_is_viewing_history = true
	clear_story_text()
	if story_text:
		var bbcode: String = MarkdownParser.parse_markdown(story_content)
		story_text.text = bbcode
		story_text.visible_characters = -1
	_update_nav_buttons()
func _show_latest_story() -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var latest_text = game_state.get_latest_story_text("")
	if latest_text.is_empty():
		return
	_is_viewing_history = false
	_current_story_index = -1
	clear_story_text()
	var bbcode: String = MarkdownParser.parse_markdown(latest_text)
	story_text.text = bbcode
	story_text.visible_characters = -1
	_update_nav_buttons()
func _update_nav_buttons() -> void:
	var game_state = get_game_state()
	var history_count = 0
	var lang: String = "en"
	if game_state:
		history_count = game_state.get_story_history_count()
		lang = String(game_state.current_language) if game_state else "en"
	var prev_text: String = LocalizationManager.get_translation("STORY_NAV_PREV", lang)
	var next_text: String = LocalizationManager.get_translation("STORY_NAV_NEXT", lang)
	if prev_text.is_empty():
		prev_text = _tr("STORY_UI_PREV_ROUND")
	if next_text.is_empty():
		next_text = _tr("STORY_UI_NEXT_ROUND")
	if prev_story_button:
		prev_story_button.visible = true
		prev_story_button.text = prev_text
		var can_go_back = history_count > 1 and (_current_story_index == -1 or _current_story_index > 0)
		prev_story_button.disabled = not can_go_back
	if next_story_button:
		next_story_button.visible = true
		next_story_button.text = next_text
		var can_go_forward = _current_story_index != -1
		next_story_button.disabled = not can_go_forward
	if story_nav_label:
		story_nav_label.visible = true
		if history_count == 0:
			story_nav_label.text = ""
		elif _current_story_index == -1:
			var fmt: String = LocalizationManager.get_translation("STORY_NAV_CURRENT", lang)
			if fmt.is_empty():
				fmt = _tr("STORY_UI_CURRENT_ROUND_DD")
			story_nav_label.text = fmt % [history_count, history_count]
		else:
			var fmt: String = LocalizationManager.get_translation("STORY_NAV_HISTORY", lang)
			if fmt.is_empty():
				fmt = _tr("STORY_UI_HISTORY_DD")
			story_nav_label.text = fmt % [_current_story_index + 1, history_count]
func reset_to_latest_story() -> void:
	_current_story_index = -1
	_is_viewing_history = false
	_update_nav_buttons()
func refresh_nav_buttons() -> void:
	_update_nav_buttons()
func is_viewing_history() -> bool:
	return _is_viewing_history
