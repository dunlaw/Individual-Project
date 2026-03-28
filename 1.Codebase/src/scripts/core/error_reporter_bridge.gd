extends RefCounted
class_name ErrorReporterBridge
const DEFAULT_CONTEXT := "General"
static func report_error(
		context: String,
		message: String,
		error_code: int = -1,
		notify_user: bool = false,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_error(context, message, error_code, notify_user, details)
		return
	_push_error(context, message)
static func report_warning(
		context: String,
		message: String,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_warning(context, message, details)
		return
	_push_warning(context, message)
static func report_info(
		context: String,
		message: String,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_info(context, message, details)
		return
	print_rich("[color=cyan][%s][INFO][%s][/color] %s" % [_get_console_timestamp(), context, message])
static func report_critical(
		context: String,
		message: String,
		error_code: int = -1,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_critical(context, message, error_code, details)
		return
	_push_error(context, message)
static func report_raw_error(message: String) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_error(DEFAULT_CONTEXT, message)
		return
	push_error("[%s] %s" % [DEFAULT_CONTEXT, message])
static func _get_reporter() -> Variant:
	var main_loop = Engine.get_main_loop()
	if not main_loop:
		return null
	if main_loop is SceneTree:
		var root = main_loop.root
		var reporter = root.get_node_or_null("ErrorReporter")
		if reporter:
			return reporter
		var sl = root.get_node_or_null("ServiceLocator")
		if sl and sl.has_method("get_error_reporter"):
			return sl.call("get_error_reporter")
	return null
static func _push_error(context: String, message: String) -> void:
	push_error("[%s] [%s] %s" % [_get_console_timestamp(), context, message])
static func _push_warning(context: String, message: String) -> void:
	push_warning("[%s] [%s] %s" % [_get_console_timestamp(), context, message])
static func _get_console_timestamp() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d %02d:%02d:%02d" % [
		int(datetime.get("day", 0)),
		int(datetime.get("month", 0)),
		int(datetime.get("year", 0)),
		int(datetime.get("hour", 0)),
		int(datetime.get("minute", 0)),
		int(datetime.get("second", 0)),
	]
