extends "res://1.Codebase/src/scripts/ui/base_controller.gd"
class_name StoryFlowController
const ERROR_CONTEXT := "StoryFlowController"
var state_controller: StoryStateController
var narrative_controller: StoryNarrativeController
var ui_controller: StoryUIController
var choice_controller: StoryChoiceController
var overlay_controller: StoryOverlayController
var _debug_gloria_pending: bool = false
var night_overlay_scene := preload("res://1.Codebase/src/scenes/ui/night_cycle_overlay.tscn")
var transition_overlay_scene := preload("res://1.Codebase/src/scenes/ui/scene_transition_overlay.tscn")
const GLORIA_POSITIVE_THRESHOLD := 30
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _init(p_story_scene: Control) -> void:
	super(p_story_scene)
func set_controllers(
		p_state: StoryStateController,
		p_narrative: StoryNarrativeController,
		p_ui: StoryUIController,
		p_choice: StoryChoiceController,
		p_overlay: StoryOverlayController,
) -> void:
	state_controller = p_state
	narrative_controller = p_narrative
	ui_controller = p_ui
	choice_controller = p_choice
	overlay_controller = p_overlay
func start_new_mission() -> void:
	_log_info("Starting new mission")
	var _gs = get_game_state()
	var mission_num = _gs.missions_completed + 1 if _gs else 1
	_log_info("Starting Mission #%d" % mission_num)
	if story_scene.has_method("hide_mission_complete_countdown"):
		story_scene.hide_mission_complete_countdown()
	var game_state = get_game_state()
	var prev_turns = 0
	if game_state:
		prev_turns = game_state.mission_turn_count
		game_state.start_mission(game_state.missions_completed + 1)
		game_state.reset_complaint_counter()
	var overlay = null
	if transition_overlay_scene and story_scene:
		overlay = transition_overlay_scene.instantiate()
		story_scene.add_child(overlay)
		mission_num = game_state.current_mission if game_state else 1
		overlay.setup(mission_num, prev_turns)
		overlay.play_transition_in()
	state_controller.set_night_cycle(false)
	state_controller.set_force_prayer_only(false)
	state_controller.unregister_gloria_overlay()
	state_controller.set_prayer_context(state_controller.PRAYER_CONTEXT_MISSION)
	var audio_manager = get_audio_manager()
	if audio_manager and audio_manager.has_method("start_gameplay_playlist"):
		audio_manager.start_gameplay_playlist()
	var asset_payload: Dictionary = { }
	if story_scene.asset_controller:
		var payload_variant: Variant = story_scene.asset_controller.prepare_mission_assets()
		if payload_variant is Dictionary:
			asset_payload = payload_variant
	story_scene.update_asset_display()
	if story_scene.asset_controller:
		var asset_ids: Array = asset_payload.get("asset_ids", [])
		story_scene.asset_controller.setup_asset_interactions(asset_ids)
	if narrative_controller:
		if not narrative_controller.is_connected("mission_generation_complete", _on_mission_generation_ready):
			narrative_controller.connect("mission_generation_complete", _on_mission_generation_ready.bind(overlay), CONNECT_ONE_SHOT)
		narrative_controller.start_new_mission(asset_payload)
	else:
		if overlay:
			overlay.finish_transition()
func resume_current_mission() -> void:
	_log_info("Resuming mission from save")
	var game_state = get_game_state()
	var text = ""
	if game_state:
		text = game_state.get_latest_story_text()
	if text.strip_edges().is_empty():
		_log_info("No saved story text found, starting fresh mission generation")
		start_new_mission()
		return
	var audio_manager = get_audio_manager()
	if audio_manager and audio_manager.has_method("start_gameplay_playlist"):
		audio_manager.start_gameplay_playlist()
	if narrative_controller:
		narrative_controller._update_story_display(text)
	var saved_choices = []
	if game_state:
		saved_choices = game_state.get_metadata("current_choices", [])
	if choice_controller:
		if not saved_choices.is_empty():
			choice_controller.current_choices = saved_choices
			choice_controller._display_choices()
		else:
			choice_controller.generate_choices()
	var saved_asset_ids = []
	if game_state:
		saved_asset_ids = game_state.get_metadata("current_asset_ids", [])
	if story_scene.asset_controller:
		if not saved_asset_ids.is_empty():
			story_scene.asset_controller.setup_asset_interactions(saved_asset_ids)
		story_scene.asset_controller.update_asset_display()
	await story_scene.get_tree().create_timer(2.0).timeout
	_try_schedule_trolley_problem()
func _on_mission_generation_ready(overlay: Node) -> void:
	if overlay and is_instance_valid(overlay) and overlay.has_method("finish_transition"):
		overlay.finish_transition()
	_try_schedule_trolley_problem()
func enter_night_cycle(mission_payload: Dictionary) -> void:
	_log_info("Entering night cycle")
	var game_state = get_game_state()
	if game_state:
		_log_info("Entering night cycle after Mission #%d | Reality: %d | Positive Energy: %d | Entropy: %d" % [
			game_state.current_mission, game_state.reality_score,
			game_state.positive_energy, game_state.entropy_level
		])
	else:
		_log_info("Entering night cycle | Payload keys: %s" % [mission_payload.keys()])
	state_controller.set_night_cycle(true)
	state_controller.store_night_payload(mission_payload)
	choice_controller.hide_choice_buttons()
	story_scene.show_loading("Entering night cycle...")
	await story_scene.get_tree().create_timer(1.5).timeout
	var night_overlay: Control = night_overlay_scene.instantiate()
	night_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	story_scene.add_child(night_overlay)
	state_controller.register_night_overlay(night_overlay)
	_record_mission_completion(mission_payload)
	var paused_here: bool = state_controller.push_overlay_pause()
	if night_overlay.has_method("set_content"):
		night_overlay.set_content(mission_payload)
	else:
		if night_overlay.has_method("apply_content"):
			var reflection_text: String = mission_payload.get("reflection_text", "")
			var teacher_chan_text: String = mission_payload.get("teacher_chan_text", "")
			var honeymoon_text: String = mission_payload.get("honeymoon_text", "")
			var prayer_prompt: String = mission_payload.get("prayer_prompt", "")
			night_overlay.apply_content(reflection_text, teacher_chan_text, honeymoon_text, prayer_prompt)
	if night_overlay.has_signal("night_completed"):
		night_overlay.night_completed.connect(
			func():
				_on_night_cycle_completed(paused_here)
		)
	if night_overlay.has_signal("prayer_requested"):
		night_overlay.prayer_requested.connect(
			func():
				_on_night_overlay_prayer_requested(night_overlay, paused_here)
		)
	night_overlay.tree_exited.connect(
		func():
			state_controller.unregister_night_overlay()
			state_controller.pop_overlay_pause(paused_here)
	)
	story_scene.hide_loading()
	var audio_manager = get_audio_manager()
	if audio_manager:
		if audio_manager.has_method("stop_gameplay_playlist"):
			audio_manager.stop_gameplay_playlist()
		audio_manager.stop_music(1.0)
		audio_manager.play_sfx("night_start")
	var lang: String = "en"
	if game_state:
		lang = String(game_state.current_language)
	var mission_end_msg = _tr("STORY_FLOW_MISSION_CONCLUDED_ENTERING_NIGHT_CYCLE")
	if game_state:
		game_state.add_event(mission_end_msg, mission_end_msg)
func _on_night_cycle_completed(paused_here: bool) -> void:
	_log_info("Night cycle completed")
	_log_info("Night cycle complete, starting new mission")
	state_controller.set_night_cycle(false)
	state_controller.pop_overlay_pause(paused_here)
	await story_scene.get_tree().create_timer(0.5).timeout
	start_new_mission()
func _on_night_overlay_prayer_requested(night_overlay: Control, paused_here: bool) -> void:
	_log_info("Prayer requested from night overlay")
	if is_instance_valid(night_overlay):
		night_overlay.visible = false
	state_controller.set_prayer_context(state_controller.PRAYER_CONTEXT_NIGHT)
	if overlay_controller:
		overlay_controller.open_prayer_system()
func _try_schedule_trolley_problem() -> void:
	var trolley_gen = ServiceLocator.get_trolley_problem_generator() if ServiceLocator else null
	if not trolley_gen:
		return
	var game_state = get_game_state()
	var force_trigger = false
	if game_state and game_state.get("debug_force_trolley_next_turn"):
		force_trigger = true
		game_state.debug_force_trolley_next_turn = false
		_log_info("Debug: Forcing trolley problem trigger")
	if not force_trigger and game_state:
		var turn_count: int = game_state.mission_turn_count
		if turn_count < 3:
			_log_info("Trolley problem skipped: too early (turn %d < 3)" % turn_count)
			return
		var last_trolley_turn: int = game_state.get_metadata("last_trolley_turn", -999)
		var turns_since_last: int = turn_count - last_trolley_turn
		if turns_since_last < 5:
			_log_info("Trolley problem skipped: cooldown (only %d turns since last)" % turns_since_last)
			return
	var trigger_chance: float = _calculate_dilemma_trigger_chance()
	if force_trigger or randf() < trigger_chance:
		if game_state:
			game_state.set_metadata("last_trolley_turn", game_state.mission_turn_count)
		_schedule_trolley_problem()
func force_gloria_intervention() -> void:
	_log_info("Debug: Gloria intervention queued, will fire after next AI story response")
	_debug_gloria_pending = true
func check_and_fire_pending_gloria() -> void:
	if not _debug_gloria_pending:
		return
	_debug_gloria_pending = false
	_log_info("Debug: Firing pending Gloria intervention")
	if overlay_controller:
		overlay_controller.show_gloria_overlay("forced_debug")
func force_honeymoon_phase(enabled: bool) -> void:
	_log_info("Debug: Forcing honeymoon phase %s" % ["ON" if enabled else "OFF"])
	if enabled:
		enter_honeymoon_phase()
	else:
		exit_honeymoon_phase()
func _calculate_dilemma_trigger_chance() -> float:
	var game_state = get_game_state()
	if not game_state:
		return 0.0
	if game_state.current_mission < 1:
		return 0.0
	if game_state.mission_turn_count < 3:
		return 0.0
	var base_chance: float = 0.08
	var entropy_bonus: float = game_state.calculate_void_entropy() * 0.3
	var pe_bonus: float = 0.0
	if game_state.positive_energy >= 70:
		pe_bonus = 0.15
	var reality_bonus: float = 0.0
	if game_state.reality_score <= 30:
		reality_bonus = 0.20
	var total: float = base_chance + entropy_bonus + pe_bonus + reality_bonus
	return clamp(total, 0.0, 0.20)
func _schedule_trolley_problem() -> void:
	var trolley_gen = ServiceLocator.get_trolley_problem_generator() if ServiceLocator else null
	if not trolley_gen:
		return
	_log_info("Scheduling trolley problem")
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = randf_range(5.0, 10.0)
	story_scene.add_child(timer)
	timer.add_to_group("story_scene_timers")
	timer.start()
	await timer.timeout
	if is_instance_valid(timer):
		timer.queue_free()
	if not is_instance_valid(story_scene) or state_controller.is_in_night_cycle():
		return
	if narrative_controller and narrative_controller.is_generating():
		_log_info("Trolley problem cancelled: Player already made a choice")
		return
	var template_type: String = _select_dilemma_template()
	var game_state = get_game_state()
	var recent_events: Array = []
	var lang: String = "en"
	if game_state:
		lang = game_state.current_language
		recent_events = game_state.get_recent_event_notes(3, lang)
	var current_story = "Unknown mission"
	if game_state:
		current_story = game_state.get_latest_story_text("Unknown mission")
		if current_story.length() > 500:
			current_story = current_story.substr(0, 500) + "..."
	trolley_gen.generate_dilemma(
		template_type,
		{
			"mission_summary": current_story,
			"recent_events": recent_events,
		},
	)
func _select_dilemma_template() -> String:
	var game_state = get_game_state()
	if not game_state:
		return ""
	if game_state.positive_energy >= 70:
		return "positive_energy_trap"
	if game_state.calculate_void_entropy() >= 0.7:
		return "lesser_evil"
	if game_state.reality_score <= 30:
		return "complicity"
	if game_state.game_phase == GameConstants.GamePhase.CRISIS:
		return "sacrifice"
	if randf() < 0.5:
		return "classic"
	return ""
func open_prayer_system() -> void:
	if overlay_controller:
		overlay_controller.open_prayer_system()
func enter_honeymoon_phase() -> void:
	state_controller.set_honeymoon_phase(true)
	var game_state = get_game_state()
	if game_state:
		game_state.enter_honeymoon_phase()
func exit_honeymoon_phase() -> void:
	state_controller.set_honeymoon_phase(false)
	var game_state = get_game_state()
	if game_state:
		game_state.exit_honeymoon_phase()
func is_mission_in_progress() -> bool:
	return not state_controller.get_current_mission().is_empty()
func _record_mission_completion(payload: Dictionary) -> void:
	var game_state = get_game_state()
	if not game_state or not game_state.butterfly_tracker:
		return
	var mission_num = game_state.current_mission
	_log_info("Completed Mission #%d | reality=%d, positive_energy=%d, entropy=%d, turns=%d" % [
		mission_num, game_state.reality_score, game_state.positive_energy,
		game_state.entropy_level, game_state.mission_turn_count
	])
	var reflection = payload.get("reflection_text", "")
	var summary = "Mission #%d Concluded" % mission_num
	var details = reflection.substr(0, 100) + "..." if reflection.length() > 100 else reflection
	var event_data = {
		"type": "mission_end",
		"choice_type": "milestone",
		"text": summary,
		"description": details,
		"mission_number": mission_num,
		"tags": ["system", "milestone", "mission_end"]
	}
	game_state.butterfly_tracker.record_choice(event_data)
func _log_info(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
