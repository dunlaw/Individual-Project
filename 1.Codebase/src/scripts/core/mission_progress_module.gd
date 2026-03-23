extends RefCounted
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "MissionProgressModule"
signal mission_started(mission_id: int)
signal mission_completed(mission_id: int, success: bool)
signal complaint_triggered()
var current_mission: int = 0
var current_mission_title: String = ""
var mission_turn_count: int = 0
var complaint_counter: int = 0
var missions_completed: int = 0
var _game_state: Variant = null
func set_game_state(gs: Variant) -> void:
	_game_state = gs
func start_mission(mission_id: int) -> void:
	current_mission = mission_id
	current_mission_title = "Mission %d" % mission_id
	mission_turn_count = 0
	mission_started.emit(mission_id)
	_report_info("Starting Mission #%d (Turn Count Reset)" % current_mission)
func complete_mission(success: bool) -> void:
	missions_completed += 1
	_report_info("Mission Completed! Success: %s, Total Completed: %d" % [success, missions_completed])
	mission_completed.emit(current_mission, success)
func increment_turn() -> void:
	mission_turn_count += 1
	_report_info("Turn %d (Mission #%d: %s)" % [mission_turn_count, current_mission, current_mission_title])
func add_complaint() -> bool:
	complaint_counter += 1
	_report_info("Complaint filed! Count: %d/%d" % [complaint_counter, GameConstants.Gloria.MIN_COMPLAINTS_FOR_TRIGGER])
	if complaint_counter >= GameConstants.Gloria.MIN_COMPLAINTS_FOR_TRIGGER:
		_report_info("Complaint threshold reached! Gloria intervention triggered.")
		complaint_counter = 0
		complaint_triggered.emit()
		return true
	return false
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func reset_complaint_counter() -> void:
	complaint_counter = 0
func reset() -> void:
	current_mission = 0
	current_mission_title = ""
	mission_turn_count = 0
	complaint_counter = 0
	missions_completed = 0
func get_save_data() -> Dictionary:
	return {
		"current_mission": current_mission,
		"current_mission_title": current_mission_title,
		"mission_turn_count": mission_turn_count,
		"complaint_counter": complaint_counter,
		"missions_completed": missions_completed,
	}
func load_save_data(data: Dictionary) -> void:
	current_mission = data.get("current_mission", 0)
	current_mission_title = data.get("current_mission_title", "Mission %d" % current_mission)
	mission_turn_count = data.get("mission_turn_count", 0)
	complaint_counter = data.get("complaint_counter", 0)
	missions_completed = data.get("missions_completed", 0)
