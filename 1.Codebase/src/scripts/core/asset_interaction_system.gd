extends Node
const ERROR_CONTEXT := "AssetInteractionSystem"
const PUZZLE_PURPOSE := "asset_puzzle"
const MAX_PUZZLE_LOG_LENGTH := 180
signal interaction_completed(result: Dictionary)
signal interaction_failed(reason: String)
signal puzzle_generated(puzzle: Dictionary)
var current_asset_rules: Dictionary = { }
var available_actions: Array = []
var interaction_history: Array = []
const ACTION_TYPES = {
	"USE": { "name": "Use", "icon": "" },
	"SPEAK": { "name": "Speak To", "icon": "" },
	"EXAMINE": { "name": "Examine", "icon": "" },
	"GIVE": { "name": "Give Item", "icon": "" },
	"ACTIVATE": { "name": "Activate", "icon": "" },
	"PACIFY": { "name": "Pacify", "icon": "" },
	"CHALLENGE": { "name": "Challenge", "icon": "" },
	"EMPATHIZE": { "name": "Show Empathy", "icon": "" },
	"IGNORE": { "name": "Ignore", "icon": "" },
	"PRAY": { "name": "Pray", "icon": "" },
}
func _ready() -> void:
	_log_info("Asset interaction system ready")
func set_asset_context(asset_id: String, ai_defined_rules: Dictionary):
	current_asset_rules[asset_id] = {
		"id": asset_id,
		"description": ai_defined_rules.get("description", ""),
		"ai_lore": ai_defined_rules.get("ai_lore", ""),
		"available_actions": ai_defined_rules.get("available_actions", []),
		"success_conditions": ai_defined_rules.get("success_conditions", { }),
		"failure_outcomes": ai_defined_rules.get("failure_outcomes", { }),
		"required_assets": ai_defined_rules.get("required_assets", []),
		"puzzle_solution": ai_defined_rules.get("puzzle_solution", ""),
	}
	_log_info(
		"Asset rules updated",
		{
			"asset_id": asset_id,
			"actions": ai_defined_rules.get("available_actions", []),
		},
	)
func get_available_actions_for_asset(asset_id: String) -> Array:
	if not current_asset_rules.has(asset_id):
		return []
	var rules: Dictionary = current_asset_rules[asset_id]
	var actions: Array[Dictionary] = []
	for action_id in rules.get("available_actions", []):
		if ACTION_TYPES.has(action_id):
			actions.append(
				{
					"id": action_id,
					"name": ACTION_TYPES[action_id]["name"],
					"icon": ACTION_TYPES[action_id]["icon"],
					"asset_id": asset_id,
				},
			)
	return actions
func perform_action(asset_id: String, action_id: String, additional_params: Dictionary = { }) -> Dictionary:
	if not current_asset_rules.has(asset_id):
		interaction_failed.emit("Asset not found: %s" % asset_id)
		return { "success": false, "error": "Asset not found" }
	var rules: Dictionary = current_asset_rules[asset_id]
	var result: Dictionary = {
		"success": false,
		"outcome_text": "",
		"stat_changes": { },
		"new_assets_unlocked": [],
		"narrative_consequence": "",
	}
	if not action_id in rules.get("available_actions", []):
		result["outcome_text"] = "You cannot perform that action on this asset."
		interaction_failed.emit("Invalid action")
		return result
	var conditions = rules.get("success_conditions", { })
	if conditions.has(action_id):
		var condition: Dictionary = conditions[action_id]
		if _evaluate_condition(condition, additional_params):
			result["success"] = true
			result["outcome_text"] = condition.get("success_text", "The action succeeds!")
			result["stat_changes"] = condition.get("stat_changes", { })
			result["new_assets_unlocked"] = condition.get("unlocks", [])
			result["narrative_consequence"] = condition.get("narrative", "")
		else:
			var failure: Dictionary = rules.get("failure_outcomes", { }).get(action_id, { })
			result["outcome_text"] = failure.get("failure_text", "The action fails.")
			result["stat_changes"] = failure.get("stat_changes", { })
			result["narrative_consequence"] = failure.get("narrative", "")
	else:
		result["success"] = true
		result["outcome_text"] = "You perform the action. Something happens."
	interaction_history.append(
		{
			"timestamp": Time.get_datetime_string_from_system(),
			"asset_id": asset_id,
			"action_id": action_id,
			"success": result["success"],
		},
	)
	var game_state: Node = _get_game_state()
	if result.has("stat_changes") and game_state:
		var stat_changes: Dictionary = result["stat_changes"]
		for stat in stat_changes:
			var value: float = float(stat_changes[stat])
			match stat:
				"reality":
					if game_state.has_method("modify_reality_score"):
						game_state.modify_reality_score(value)
				"positive_energy":
					if game_state.has_method("modify_positive_energy"):
						game_state.modify_positive_energy(value)
				"entropy":
					if game_state.has_method("modify_entropy"):
						game_state.modify_entropy(value, "Asset interaction")
	interaction_completed.emit(result)
	return result
func _evaluate_condition(condition: Dictionary, params: Dictionary) -> bool:
	var condition_type: String = condition.get("type", "always")
	match condition_type:
		"always":
			return true
		"has_item":
			var required_item: String = condition.get("item", "")
			return params.get("has_items", []).has(required_item)
		"stat_check":
			var stat: String = condition.get("stat", "reality")
			var threshold: float = float(condition.get("threshold", 50))
			var operator: String = condition.get("operator", ">=")
			var current_value: float = float(_get_stat_value(stat))
			return _compare_values(current_value, threshold, operator)
		"nearby_asset":
			var required_asset = condition.get("asset", "")
			return params.get("nearby_assets", []).has(required_asset)
		_:
			return false
func _get_stat_value(stat_name: String) -> int:
	var game_state = _get_game_state()
	if not game_state:
		return 50
	match stat_name:
		"reality":
			return int(game_state.get("reality_score") if game_state.has_method("get") else game_state.reality_score)
		"positive_energy":
			return int(game_state.get("positive_energy") if game_state.has_method("get") else game_state.positive_energy)
		"entropy":
			return int(game_state.get("entropy_level") if game_state.has_method("get") else game_state.entropy_level)
		_:
			return 0
func _compare_values(a: float, b: float, operator: String) -> bool:
	match operator:
		">=":
			return a >= b
		">":
			return a > b
		"<=":
			return a <= b
		"<":
			return a < b
		"==":
			return a == b
		"!=":
			return a != b
		_:
			return false
func generate_puzzle_from_assets(asset_ids: Array, difficulty: String = "medium") -> Dictionary:
	var normalized_ids: Array[String] = []
	for id in asset_ids:
		if typeof(id) == TYPE_STRING:
			var trimmed: String = String(id).strip_edges()
			if not trimmed.is_empty() and not normalized_ids.has(trimmed):
				normalized_ids.append(trimmed)
	var puzzle_data: Dictionary = {
		"assets": normalized_ids,
		"difficulty": difficulty,
		"generated": false,
	}
	if normalized_ids.is_empty():
		_report_warning("Puzzle generation requested without assets")
		return puzzle_data
	var ai_manager: Node = _get_ai_manager()
	if ai_manager == null:
		_report_warning("AIManager unavailable for puzzle generation", { "assets": normalized_ids })
		return puzzle_data
	var prompt: String = _build_puzzle_prompt(normalized_ids, difficulty)
	if prompt.is_empty():
		_report_warning("Puzzle prompt could not be constructed", { "assets": normalized_ids, "difficulty": difficulty })
		return puzzle_data
	var context: Dictionary = {
		"purpose": PUZZLE_PURPOSE,
		"assets": normalized_ids,
		"difficulty": difficulty,
	}
	ai_manager.generate_story(
		prompt,
		context,
		Callable(self, "_on_puzzle_generated").bind(normalized_ids, difficulty),
	)
	_log_info("Requested puzzle generation", { "assets": normalized_ids, "difficulty": difficulty })
	return puzzle_data
func _on_puzzle_generated(response: Variant, asset_ids: Array, difficulty: String) -> void:
	var response_dict: Dictionary = { }
	if response is Dictionary:
		response_dict = response
	else:
		response_dict = { "success": true, "content": str(response) }
	if not response_dict.get("success", true):
		var error_msg: String = String(response_dict.get("error", "unknown error"))
		_report_error("Puzzle generation failed", { "error": error_msg, "assets": asset_ids })
		return
	var content: String = String(response_dict.get("content", ""))
	if content.is_empty():
		content = String(response_dict.get("text", ""))
	if content.is_empty():
		_report_warning("Puzzle generation returned empty content", { "assets": asset_ids })
		return
	content = _strip_code_fence(content.strip_edges())
	var json := JSON.new()
	var parse_err := json.parse(content)
	if parse_err != OK or json.data == null:
		_report_warning(
			"Puzzle generation returned invalid JSON",
			{
				"error": json.get_error_message(),
				"line": json.get_error_line(),
				"snippet": content.substr(0, MAX_PUZZLE_LOG_LENGTH),
			},
		)
		return
	if not (json.data is Dictionary):
		_report_warning("Puzzle generation produced non-dictionary payload", { "payload_type": typeof(json.data) })
		return
	var rules: Dictionary = json.data as Dictionary
	if rules.is_empty():
		_report_warning("Puzzle generation returned empty rules", { "assets": asset_ids })
		return
	for asset_id in rules.keys():
		var rule_block: Dictionary = rules[asset_id] as Dictionary
		if rule_block is Dictionary:
			set_asset_context(String(asset_id), rule_block)
		else:
			_report_warning("Ignoring puzzle rule with invalid structure", { "asset_id": asset_id })
	var puzzle_payload := {
		"assets": asset_ids,
		"difficulty": difficulty,
		"rules": rules,
		"generated": true,
	}
	puzzle_generated.emit(puzzle_payload)
	_log_info("Puzzle rules generated", { "assets": asset_ids, "difficulty": difficulty })
func _build_puzzle_prompt(asset_ids: Array, difficulty: String) -> String:
	var asset_registry: Node = _get_asset_registry()
	var asset_names: Array[String] = []
	for asset_id in asset_ids:
		if asset_registry and asset_registry.assets.has(asset_id):
			asset_names.append(asset_registry.assets[asset_id].get("default_name", asset_id))
		else:
			asset_names.append(asset_id)
	var parts: Array[String] = []
	parts.append(_tr("ASSET_INTERACT_PUZZLE_HEADER") % ", ".join(asset_names))
	parts.append("")
	parts.append(_tr("ASSET_INTERACT_PUZZLE_RULES_INTRO"))
	parts.append(_tr("ASSET_INTERACT_PUZZLE_RULE1"))
	parts.append(_tr("ASSET_INTERACT_PUZZLE_RULE2"))
	parts.append(_tr("ASSET_INTERACT_PUZZLE_RULE3"))
	parts.append(_tr("ASSET_INTERACT_PUZZLE_RULE4"))
	parts.append("")
	parts.append(_tr("ASSET_INTERACT_PUZZLE_DIFFICULTY") % difficulty)
	parts.append(_tr("ASSET_INTERACT_PUZZLE_STYLE"))
	parts.append(_tr("ASSET_INTERACT_PUZZLE_OUTPUT"))
	parts.append("{")
	parts.append("\t\"%s\": {" % _tr("ASSET_INTERACT_PUZZLE_JSON_ASSET_ID"))
	parts.append("\t\t\"description\": \"...\",")
	parts.append("\t\t\"available_actions\": [\"%s\"]," % _tr("ASSET_INTERACT_PUZZLE_JSON_ACTION_ID"))
	parts.append("\t\t\"success_conditions\": {...},")
	parts.append("\t\t\"failure_outcomes\": {...}")
	parts.append("\t}")
	parts.append("}")
	return "\n".join(parts)
func clear_asset_rules():
	current_asset_rules.clear()
	available_actions.clear()
func get_interaction_history() -> Array:
	return interaction_history.duplicate()
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _strip_code_fence(text: String) -> String:
	var trimmed: String = text.strip_edges()
	if trimmed.begins_with("```"):
		var closing := trimmed.rfind("```")
		if closing > 0:
			trimmed = trimmed.substr(3, closing - 3)
	return trimmed.strip_edges()
func _get_game_state() -> Node:
	if ServiceLocator:
		var service: Variant = ServiceLocator.get_game_state()
		if service is Node:
			return service
	return null
func _get_asset_registry() -> Node:
	if ServiceLocator:
		var service: Variant = ServiceLocator.get_asset_registry()
		if service is Node:
			return service
	return null
func _get_ai_manager() -> Node:
	if ServiceLocator:
		var service: Variant = ServiceLocator.get_ai_manager()
		if service is Node:
			return service
	return null
func _log_info(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
