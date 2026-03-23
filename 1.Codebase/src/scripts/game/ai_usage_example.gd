extends Control
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "AIUsageExample"
@onready var ai_manager: Node = _resolve_ai_manager()
var reality_score: int = 50
var positive_energy: int = 50
func _ready() -> void:
	var manager := _get_ai_manager()
	if not manager:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager unavailable; skipping signal connections")
		return
	_connect_signals(manager)
func _connect_signals(manager: Node) -> void:
	if manager.has_signal("ai_response_received"):
		manager.ai_response_received.connect(_on_story_generated)
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager missing ai_response_received signal")
	if manager.has_signal("ai_error"):
		manager.ai_error.connect(_on_ai_error)
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager missing ai_error signal")
func generate_new_mission() -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := _tr("AI_EXAMPLE_MISSION_PROMPT")
	var context := {
		"purpose": "mission",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
	}
	manager.generate_story(prompt, context)
func generate_teammate_reaction(player_action: String) -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := _tr("AI_EXAMPLE_REACTION_PROMPT") % player_action
	var context := {
		"purpose": "interference",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"teammate": "donkey",
		"player_action": player_action,
	}
	manager.generate_story(prompt, context)
func generate_gloria_pua() -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := _tr("AI_EXAMPLE_GLORIA_PUA_PROMPT")
	var context := {
		"purpose": "interference",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"teammate": "gloria",
		"player_action": _tr("AI_EXAMPLE_GLORIA_PUA_ACTION"),
	}
	manager.generate_story(prompt, context)
func generate_prayer_consequence(prayer_text: String) -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := _tr("AI_EXAMPLE_PRAYER_PROMPT") % prayer_text
	var context := {
		"purpose": "prayer",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"prayer_text": prayer_text,
	}
	manager.generate_story(prompt, context)
func _on_story_generated(response: String) -> void:
	_report_info("AI Generated Story: %s\n%s" % [response, "=".repeat(50)])
	var manager := _get_ai_manager()
	if manager:
		manager.add_to_memory(response.substr(0, min(200, response.length())))
func _on_ai_error(error_message: String) -> void:
	_report_error("AI Error: %s" % error_message)
func example_gameplay_flow() -> void:
	generate_new_mission()
	pass
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _resolve_ai_manager() -> Node:
	if typeof(ServiceLocator) == TYPE_NIL or ServiceLocator == null:
		return null
	return ServiceLocator.get_ai_manager()
func _get_ai_manager() -> Node:
	if is_instance_valid(ai_manager):
		return ai_manager
	ai_manager = _resolve_ai_manager()
	if not ai_manager:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager not available via ServiceLocator")
	return ai_manager
