extends RefCounted
signal challenge_started()
signal day_completed(day: int)
signal challenge_crash_triggered()
signal challenge_cancelled()
const ERROR_CONTEXT := "FSMChallengeModule"
var is_challenge_active: bool = false
var challenge_start_date: String = ""  
var last_login_date: String = ""  
var current_day: int = 0
var days_completed: Array = []  
var challenge_completed: bool = false
var challenge_crashed: bool = false
func start_challenge() -> void:
	if is_challenge_active:
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "Challenge already active")
		return
	is_challenge_active = true
	challenge_start_date = _get_current_date_string()
	last_login_date = _get_current_date_string()
	current_day = 1
	days_completed = []
	challenge_completed = false
	challenge_crashed = false
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "FSM Challenge started on %s" % challenge_start_date)
	challenge_started.emit()
func complete_day() -> void:
	if not is_challenge_active or challenge_crashed:
		return
	if current_day in days_completed:
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "Day %d already completed" % current_day)
		return
	days_completed.append(current_day)
	last_login_date = _get_current_date_string()  
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Day %d completed" % current_day)
	day_completed.emit(current_day)
	if current_day == GameConstants.FSMChallenge.DAYS_BEFORE_CRASH:
		_trigger_crash()
func _trigger_crash() -> void:
	challenge_crashed = true
	is_challenge_active = false
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "FSM Challenge crashed after day %d" % current_day)
	challenge_crash_triggered.emit()
func cancel_challenge() -> void:
	if not is_challenge_active:
		return
	is_challenge_active = false
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "FSM Challenge cancelled")
	challenge_cancelled.emit()
func can_advance_day() -> bool:
	if not is_challenge_active or challenge_crashed:
		return false
	if current_day >= GameConstants.FSMChallenge.DAYS_BEFORE_CRASH:
		return false
	var today = _get_current_date_string()
	var days_since_start = _calculate_days_between(challenge_start_date, today)
	return days_since_start > days_completed.size()
func check_and_reset_if_missed() -> bool:
	if not is_challenge_active or challenge_crashed:
		return false
	if last_login_date.is_empty():
		last_login_date = _get_current_date_string()
		return false
	var today = _get_current_date_string()
	var days_since_login = _calculate_days_between(last_login_date, today)
	if days_since_login > 1:
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "Challenge reset: player missed %d days" % (days_since_login - 1))
		reset()
		return true
	last_login_date = today
	return false
func get_time_until_next_day() -> int:
	if not is_challenge_active or challenge_crashed:
		return 0
	if not is_today_completed():
		return 0
	var now = Time.get_datetime_dict_from_system()
	var seconds_since_midnight = now.hour * 3600 + now.minute * 60 + now.second
	var seconds_until_midnight = 86400 - seconds_since_midnight  
	return seconds_until_midnight
func format_time_until_next_day() -> String:
	var seconds = get_time_until_next_day()
	if seconds <= 0:
		return _tr("FSM_MODULE_AVAILABLE_NOW")
	var hours = int(seconds / 3600)
	var minutes = int((seconds % 3600) / 60)
	var secs = seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]
func _tr(key: String) -> String:
	var localization_manager: Node = _get_localization_manager()
	if localization_manager:
		return localization_manager.get_translation(key)
	return key
func _get_localization_manager() -> Node:
	if ServiceLocator != null and ServiceLocator.has_method("get_localization_manager"):
		var located: Node = ServiceLocator.get_localization_manager()
		if located != null:
			return located
	return LocalizationManager if LocalizationManager != null else null
func advance_to_next_day() -> void:
	if can_advance_day():
		current_day += 1
		if ErrorReporter and ErrorReporter.has_method("report_info"):
			ErrorReporter.report_info(ERROR_CONTEXT, "Advanced to day %d" % current_day)
func _get_current_date_string() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [datetime.year, datetime.month, datetime.day]
func _calculate_days_between(start_date: String, end_date: String) -> int:
	var start_dict = _parse_date_string(start_date)
	var end_dict = _parse_date_string(end_date)
	if start_dict.is_empty() or end_dict.is_empty():
		return 0
	var start_unix = Time.get_unix_time_from_datetime_dict(start_dict)
	var end_unix = Time.get_unix_time_from_datetime_dict(end_dict)
	var seconds_diff = end_unix - start_unix
	var days_diff = int(seconds_diff / 86400.0)  
	return days_diff
func _parse_date_string(date_str: String) -> Dictionary:
	var parts = date_str.split("-")
	if parts.size() != 3:
		return {}
	return {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2]),
		"hour": 0,
		"minute": 0,
		"second": 0
	}
func is_today_completed() -> bool:
	return current_day in days_completed
func get_status_summary() -> Dictionary:
	return {
		"is_active": is_challenge_active,
		"start_date": challenge_start_date,
		"current_day": current_day,
		"days_completed": days_completed.duplicate(),
		"crashed": challenge_crashed,
		"can_advance": can_advance_day()
	}
func get_save_data() -> Dictionary:
	return {
		"is_challenge_active": is_challenge_active,
		"challenge_start_date": challenge_start_date,
		"last_login_date": last_login_date,
		"current_day": current_day,
		"days_completed": days_completed.duplicate(),
		"challenge_completed": challenge_completed,
		"challenge_crashed": challenge_crashed
	}
func load_save_data(data: Dictionary) -> void:
	is_challenge_active = data.get("is_challenge_active", false)
	challenge_start_date = data.get("challenge_start_date", "")
	last_login_date = data.get("last_login_date", "")
	current_day = data.get("current_day", 0)
	days_completed = data.get("days_completed", [])
	challenge_completed = data.get("challenge_completed", false)
	challenge_crashed = data.get("challenge_crashed", false)
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "FSM Challenge state loaded: day %d/%d" % [current_day, GameConstants.FSMChallenge.DAYS_BEFORE_CRASH])
func reset() -> void:
	is_challenge_active = false
	challenge_start_date = ""
	last_login_date = ""
	current_day = 0
	days_completed = []
	challenge_completed = false
	challenge_crashed = false
