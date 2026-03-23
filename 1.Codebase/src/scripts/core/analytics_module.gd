extends RefCounted
class_name AnalyticsModule
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "AnalyticsModule"
signal analytics_updated()
var session_start_time: float = 0.0
var total_playtime: float = 0.0
var current_session_playtime: float = 0.0
var total_choices_made: int = 0
var choice_frequency: Dictionary = {}  
var decision_times: Array[float] = []  
var last_choice_timestamp: float = 0.0
var attribute_history: Array[Dictionary] = []  
var mission_completion_times: Array[float] = []  
var current_mission_start_time: float = 0.0
const MAX_DECISION_TIMES: int = 100
const MAX_ATTRIBUTE_HISTORY: int = 50
func _init() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	last_choice_timestamp = session_start_time
func start_session() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	current_session_playtime = 0.0
	last_choice_timestamp = session_start_time
func update_playtime() -> void:
	if session_start_time > 0:
		current_session_playtime = (Time.get_ticks_msec() / 1000.0) - session_start_time
func record_choice(choice_text: String, choice_index: int = -1) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var decision_time := current_time - last_choice_timestamp
	decision_times.append(decision_time)
	if decision_times.size() > MAX_DECISION_TIMES:
		decision_times.remove_at(0)
	if choice_text in choice_frequency:
		choice_frequency[choice_text] += 1
	else:
		choice_frequency[choice_text] = 1
	total_choices_made += 1
	last_choice_timestamp = current_time
	_report_info("Choice recorded #%d | decision time: %.1fs | average: %.1fs" % [
		total_choices_made, decision_time, get_average_decision_time()
	])
	analytics_updated.emit()
func record_attribute_snapshot(reality: int, positive: int, entropy: int) -> void:
	var snapshot := {
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"reality_score": reality,
		"positive_energy": positive,
		"entropy_level": entropy,
	}
	attribute_history.append(snapshot)
	if attribute_history.size() > MAX_ATTRIBUTE_HISTORY:
		attribute_history.remove_at(0)
	analytics_updated.emit()
func start_mission_tracking() -> void:
	current_mission_start_time = Time.get_ticks_msec() / 1000.0
func complete_mission_tracking() -> void:
	if current_mission_start_time > 0:
		var mission_time := (Time.get_ticks_msec() / 1000.0) - current_mission_start_time
		mission_completion_times.append(mission_time)
		current_mission_start_time = 0.0
		var avg_time := _get_average_mission_time()
		_report_info("Mission duration: %.1fs | average: %.1fs | completed: %d times" % [
			mission_time, avg_time, mission_completion_times.size()
		])
		analytics_updated.emit()
func get_average_decision_time() -> float:
	if decision_times.is_empty():
		return 0.0
	var sum := 0.0
	for time in decision_times:
		sum += time
	return sum / decision_times.size()
func get_most_common_choices(limit: int = 5) -> Array[Dictionary]:
	var sorted_choices: Array[Dictionary] = []
	for choice_text in choice_frequency:
		sorted_choices.append({
			"choice": choice_text,
			"count": choice_frequency[choice_text]
		})
	sorted_choices.sort_custom(func(a, b): return a["count"] > b["count"])
	if sorted_choices.size() > limit:
		sorted_choices.resize(limit)
	return sorted_choices
func get_least_common_choices(limit: int = 5) -> Array[Dictionary]:
	var sorted_choices: Array[Dictionary] = []
	for choice_text in choice_frequency:
		sorted_choices.append({
			"choice": choice_text,
			"count": choice_frequency[choice_text]
		})
	sorted_choices.sort_custom(func(a, b): return a["count"] < b["count"])
	if sorted_choices.size() > limit:
		sorted_choices.resize(limit)
	return sorted_choices
func get_attribute_trends(limit: int = 10) -> Array[Dictionary]:
	if attribute_history.is_empty():
		return []
	var start_idx: int = maxi(0, attribute_history.size() - limit)
	var result: Array[Dictionary] = []
	for i in range(start_idx, attribute_history.size()):
		result.append(attribute_history[i].duplicate())
	return result
func calculate_attribute_change_rates() -> Dictionary:
	if attribute_history.size() < 2:
		return {
			"reality_rate": 0.0,
			"positive_rate": 0.0,
			"entropy_rate": 0.0,
		}
	var first: Dictionary = attribute_history[0]
	var last: Dictionary = attribute_history[attribute_history.size() - 1]
	var first_timestamp: float = float(first.get("timestamp", 0.0))
	var last_timestamp: float = float(last.get("timestamp", 0.0))
	var time_diff: float = last_timestamp - first_timestamp
	if time_diff == 0:
		return {
			"reality_rate": 0.0,
			"positive_rate": 0.0,
			"entropy_rate": 0.0,
		}
	var first_reality: float = float(first.get("reality_score", 0))
	var last_reality: float = float(last.get("reality_score", 0))
	var first_positive: float = float(first.get("positive_energy", 0))
	var last_positive: float = float(last.get("positive_energy", 0))
	var first_entropy: float = float(first.get("entropy_level", 0))
	var last_entropy: float = float(last.get("entropy_level", 0))
	return {
		"reality_rate": (last_reality - first_reality) / time_diff,
		"positive_rate": (last_positive - first_positive) / time_diff,
		"entropy_rate": (last_entropy - first_entropy) / time_diff,
	}
func get_analytics_summary() -> Dictionary:
	update_playtime()
	return {
		"session_playtime": current_session_playtime,
		"total_playtime": total_playtime + current_session_playtime,
		"total_choices": total_choices_made,
		"average_decision_time": get_average_decision_time(),
		"most_common_choices": get_most_common_choices(3),
		"least_common_choices": get_least_common_choices(3),
		"missions_completed": mission_completion_times.size(),
		"average_mission_time": _get_average_mission_time(),
		"attribute_trends": get_attribute_trends(10),
		"attribute_change_rates": calculate_attribute_change_rates(),
	}
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _get_average_mission_time() -> float:
	if mission_completion_times.is_empty():
		return 0.0
	var sum := 0.0
	for time in mission_completion_times:
		sum += time
	return sum / mission_completion_times.size()
func get_save_data() -> Dictionary:
	update_playtime()
	return {
		"total_playtime": total_playtime + current_session_playtime,
		"total_choices_made": total_choices_made,
		"choice_frequency": choice_frequency.duplicate(),
		"decision_times": decision_times.duplicate(),
		"attribute_history": attribute_history.duplicate(true),
		"mission_completion_times": mission_completion_times.duplicate(),
	}
func load_save_data(data: Dictionary) -> void:
	total_playtime = data.get("total_playtime", 0.0)
	total_choices_made = data.get("total_choices_made", 0)
	var freq_data = data.get("choice_frequency", {})
	choice_frequency = freq_data.duplicate() if freq_data is Dictionary else {}
	var decision_data = data.get("decision_times", [])
	decision_times.clear()
	if decision_data is Array:
		for time in decision_data:
			decision_times.append(float(time))
	var history_data = data.get("attribute_history", [])
	attribute_history.clear()
	if history_data is Array:
		for snapshot in history_data:
			if snapshot is Dictionary:
				attribute_history.append(snapshot.duplicate())
	var mission_data = data.get("mission_completion_times", [])
	mission_completion_times.clear()
	if mission_data is Array:
		for time in mission_data:
			mission_completion_times.append(float(time))
	start_session()
func reset() -> void:
	total_playtime = 0.0
	current_session_playtime = 0.0
	total_choices_made = 0
	choice_frequency.clear()
	decision_times.clear()
	attribute_history.clear()
	mission_completion_times.clear()
	start_session()
