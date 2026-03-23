extends RefCounted
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "DebuffSystem"
var active_debuffs: Array = []
var cognitive_dissonance_active: bool = false
var cognitive_dissonance_choices_left: int = 0
func add_debuff(debuff_name: String, duration: int, effect: String) -> void:
	active_debuffs.append(
		{
			"name": debuff_name,
			"duration": duration,
			"effect": effect,
		},
	)
	_report_info("Applied: '%s' (Duration: %d turns): %s" % [debuff_name, duration, effect])
	if debuff_name == GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME:
		cognitive_dissonance_active = true
		cognitive_dissonance_choices_left = duration
		_report_info("Cognitive Dissonance ACTIVE! Logic checks penalized for %d choices." % duration)
func process_debuffs() -> void:
	var to_remove = []
	for i in range(active_debuffs.size()):
		active_debuffs[i]["duration"] -= 1
		if active_debuffs[i]["duration"] <= 0:
			to_remove.append(i)
		else:
			_report_info("'%s' ticking: %d turns remaining" % [active_debuffs[i]["name"], active_debuffs[i]["duration"]])
	for i in range(to_remove.size() - 1, -1, -1):
		var debuff = active_debuffs[to_remove[i]]
		_report_info("Expired: '%s'" % debuff["name"])
		if debuff["name"] == GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME:
			cognitive_dissonance_active = false
			_report_info("Cognitive Dissonance lifted. Logic checks restored.")
		active_debuffs.remove_at(to_remove[i])
func use_cognitive_dissonance_choice() -> void:
	if cognitive_dissonance_active:
		cognitive_dissonance_choices_left -= 1
		_report_info("Cognitive Dissonance: %d choices remaining" % cognitive_dissonance_choices_left)
		if cognitive_dissonance_choices_left <= 0:
			cognitive_dissonance_active = false
			var i = active_debuffs.size() - 1
			while i >= 0:
				if active_debuffs[i]["name"] == GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME:
					active_debuffs.remove_at(i)
				i -= 1
			_report_info("Cognitive Dissonance worn off naturally.")
func has_debuff(debuff_name: String) -> bool:
	for debuff in active_debuffs:
		if debuff["name"] == debuff_name:
			return true
	return false
func get_active_debuffs() -> Array:
	return active_debuffs.duplicate()
func get_debuff(debuff_name: String) -> Dictionary:
	for debuff in active_debuffs:
		if debuff["name"] == debuff_name:
			return debuff.duplicate()
	return { }
func clear_all() -> void:
	if not active_debuffs.is_empty():
		_report_info("Clearing all %d active debuffs" % active_debuffs.size())
	active_debuffs.clear()
	cognitive_dissonance_active = false
	cognitive_dissonance_choices_left = 0
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func get_save_data() -> Dictionary:
	return {
		"active_debuffs": active_debuffs.duplicate(true),
		"cognitive_dissonance_active": cognitive_dissonance_active,
		"cognitive_dissonance_choices_left": cognitive_dissonance_choices_left,
	}
func load_save_data(data: Dictionary) -> void:
	var debuffs_data = data.get("active_debuffs", [])
	active_debuffs = debuffs_data.duplicate(true) if debuffs_data is Array else []
	cognitive_dissonance_active = data.get("cognitive_dissonance_active", false)
	cognitive_dissonance_choices_left = data.get("cognitive_dissonance_choices_left", 0)
func reset() -> void:
	clear_all()
