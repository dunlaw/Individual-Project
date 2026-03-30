extends Node
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "MissionSummaryLogger"
var journal_system: Control = null
var _game_state: Node = null
var _ai_manager: Node = null
func _ready() -> void:
	_refresh_services()
	_connect_signals()
func _on_event_logged(event: Dictionary) -> void:
	var event_type = event.get("type", "")
	if event_type == "mission_complete":
		_generate_mission_summary(event)
func _generate_mission_summary(event_data: Dictionary) -> void:
	var ai_manager: Node = _get_ai_manager()
	if ai_manager == null:
		_report_warning("AIManager not available; skipping mission summary generation")
		return
	var game_state: Node = _get_game_state()
	var mission_number: int = game_state.current_mission if game_state else 0
	var latest_story := ""
	if game_state:
		var latest_story_value: Variant = game_state.get_latest_story_text("") if game_state.has_method("get_latest_story_text") else game_state.get_metadata("latest_story_text", "")
		latest_story = String(latest_story_value if latest_story_value != null else "")
	var last_choice = ""
	if game_state and game_state.butterfly_tracker:
		var recorded_choices = game_state.butterfly_tracker.recorded_choices
		if not recorded_choices.is_empty():
			var last_recorded: Variant = recorded_choices[-1]
			if last_recorded is Dictionary:
				var last_recorded_dict := last_recorded as Dictionary
				last_choice = String(last_recorded_dict.get("text", last_recorded_dict.get("choice_text", last_recorded_dict.get("description", "")))).strip_edges()
	var event_details: Dictionary = event_data.get("details", {}) if event_data.get("details", {}) is Dictionary else {}
	var template := _tr("AI_PROMPT_MISSION_SUMMARY")
	var summary_prompt := template % [
		latest_story.substr(0, 200) if latest_story else _tr("UI_UNKNOWN"),
		last_choice if last_choice else _tr("UI_UNKNOWN"),
		String(event_details.get("outcome", _tr("STATUS_SUCCESS"))),
	]
	_report_info("Generating mission summary for mission #%d" % mission_number)
	var context := {"purpose": "mission_summary"}
	var callback := func(resp: Dictionary):
		var ok := bool(resp.get("success", false))
		if ok:
			var text := String(resp.get("content", ""))
			_on_summary_generated(mission_number, text)
		else:
			var err := String(resp.get("error", "Unknown error"))
			_on_summary_failed(mission_number, err)
	ai_manager.request_ai(summary_prompt, callback, context)
func _on_summary_generated(mission_number: int, summary: String) -> void:
	_report_info("Summary generated for mission #%d: %s" % [mission_number, summary])
	_add_mission_summary_to_journal(mission_number, summary)
func _on_summary_failed(mission_number: int, error: String) -> void:
	_report_error("Failed to generate summary for mission #%d: %s" % [mission_number, error])
	_report_warning("Failed to generate AI mission summary", { "mission": mission_number, "error": error })
	var fallback_summary = _tr("MISSION_SUMMARY_FALLBACK")
	if fallback_summary == "MISSION_SUMMARY_FALLBACK":
		fallback_summary = "Mission #%d completed."
	fallback_summary = fallback_summary.replace("%d", str(mission_number))
	_add_mission_summary_to_journal(mission_number, fallback_summary)
func _add_mission_summary_to_journal(mission_number: int, summary: String) -> void:
	var game_state: Node = _get_game_state()
	if game_state:
		var all_summaries = game_state.get_metadata("mission_summaries")
		if not all_summaries:
			all_summaries = { }
		all_summaries[str(mission_number)] = {
			"summary": summary,
			"timestamp": Time.get_unix_time_from_system(),
		}
		game_state.set_metadata("mission_summaries", all_summaries)
	var ai_manager: Node = _get_ai_manager()
	if ai_manager and ai_manager.has_method("register_note"):
		var note_text = "Mission #%d Summary: %s" % [mission_number, summary]
		ai_manager.register_note(note_text, ["mission_summary"], 5)
func get_all_summaries() -> Dictionary:
	var game_state: Node = _get_game_state()
	if game_state:
		var summaries = game_state.get_metadata("mission_summaries")
		if summaries is Dictionary:
			return summaries
	return { }
func get_mission_summary(mission_number: int) -> String:
	var all_summaries = get_all_summaries()
	var summary_data = all_summaries.get(str(mission_number), { })
	return summary_data.get("summary", "")
func regenerate_mission_summary(mission_number: int) -> void:
	var fake_event = {
		"type": "mission_complete",
		"details": {
			"mission_number": mission_number,
			"outcome": "Regenerated",
		},
	}
	_generate_mission_summary(fake_event)
func _refresh_services() -> void:
	if typeof(ServiceLocator) == TYPE_NIL or ServiceLocator == null:
		_game_state = null
		_ai_manager = null
		return
	_game_state = ServiceLocator.get_game_state()
	_ai_manager = ServiceLocator.get_ai_manager()
func _connect_signals() -> void:
	var game_state: Node = _get_game_state()
	if game_state and game_state.has_signal("event_logged"):
		if not game_state.event_logged.is_connected(_on_event_logged):
			game_state.event_logged.connect(_on_event_logged)
	else:
		_report_warning("GameState unavailable; mission summaries will not auto-generate")
func _get_game_state() -> Node:
	if not is_instance_valid(_game_state):
		_refresh_services()
	return _game_state
func _get_ai_manager() -> Node:
	if not is_instance_valid(_ai_manager):
		_refresh_services()
	return _ai_manager
func _report_info(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, _get_game_state().current_language if _get_game_state() else "en")
	return key
