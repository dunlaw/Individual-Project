extends Node
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "TeammateSystem"
var BEHAVIOR_LIBRARY: Dictionary = {}
var TEAMMATES: Dictionary = {}
signal relationship_updated(source_id: String, target_id: String)
var _team_relationships: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	_rng.randomize()
	_build_default_data()
	_report_info("System loaded | teammates: %d | behaviors: %d | relationships: %d" % [
		TEAMMATES.size(), BEHAVIOR_LIBRARY.size(), _team_relationships.size()
	])
func _build_default_data() -> void:
	BEHAVIOR_LIBRARY = {
		"moral_blackmail": {
			"label":   _tr("BEHAVIOR_MORAL_BLACKMAIL_LABEL"),
			"summary": _tr("BEHAVIOR_MORAL_BLACKMAIL_SUMMARY"),
			"style":   _tr("BEHAVIOR_MORAL_BLACKMAIL_STYLE"),
			"impact":  { "reality": -8, "positive": 12, "entropy": 4 },
		},
		"issue_replacement": {
			"label":   _tr("BEHAVIOR_ISSUE_REPLACEMENT_LABEL"),
			"summary": _tr("BEHAVIOR_ISSUE_REPLACEMENT_SUMMARY"),
			"style":   _tr("BEHAVIOR_ISSUE_REPLACEMENT_STYLE"),
			"impact":  { "reality": -6, "positive": 8, "entropy": 3 },
		},
		"divine_protection": {
			"label":   _tr("BEHAVIOR_DIVINE_PROTECTION_LABEL"),
			"summary": _tr("BEHAVIOR_DIVINE_PROTECTION_SUMMARY"),
			"style":   _tr("BEHAVIOR_DIVINE_PROTECTION_STYLE"),
			"impact":  { "reality": -4, "positive": 10, "entropy": 5 },
		},
		"heroic_nonsense": {
			"label":   _tr("BEHAVIOR_HEROIC_NONSENSE_LABEL"),
			"summary": _tr("BEHAVIOR_HEROIC_NONSENSE_SUMMARY"),
			"style":   _tr("BEHAVIOR_HEROIC_NONSENSE_STYLE"),
			"impact":  { "reality": -5, "positive": 6, "entropy": 4 },
		},
		"blame_shifting": {
			"label":   _tr("BEHAVIOR_BLAME_SHIFTING_LABEL"),
			"summary": _tr("BEHAVIOR_BLAME_SHIFTING_SUMMARY"),
			"style":   _tr("BEHAVIOR_BLAME_SHIFTING_STYLE"),
			"impact":  { "reality": -7, "positive": 5, "entropy": 2 },
		},
		"epic_planning": {
			"label":   _tr("BEHAVIOR_EPIC_PLANNING_LABEL"),
			"summary": _tr("BEHAVIOR_EPIC_PLANNING_SUMMARY"),
			"style":   _tr("BEHAVIOR_EPIC_PLANNING_STYLE"),
			"impact":  { "reality": -3, "positive": 7, "entropy": 3 },
		},
		"overcomplicate": {
			"label":   _tr("BEHAVIOR_OVERCOMPLICATE_LABEL"),
			"summary": _tr("BEHAVIOR_OVERCOMPLICATE_SUMMARY"),
			"style":   _tr("BEHAVIOR_OVERCOMPLICATE_STYLE"),
			"impact":  { "reality": -6, "positive": 4, "entropy": 5 },
		},
		"black_box_operation": {
			"label":   _tr("BEHAVIOR_BLACK_BOX_OPERATION_LABEL"),
			"summary": _tr("BEHAVIOR_BLACK_BOX_OPERATION_SUMMARY"),
			"style":   _tr("BEHAVIOR_BLACK_BOX_OPERATION_STYLE"),
			"impact":  { "reality": -5, "positive": 6, "entropy": 6 },
		},
		"absolute_plan": {
			"label":   _tr("BEHAVIOR_ABSOLUTE_PLAN_LABEL"),
			"summary": _tr("BEHAVIOR_ABSOLUTE_PLAN_SUMMARY"),
			"style":   _tr("BEHAVIOR_ABSOLUTE_PLAN_STYLE"),
			"impact":  { "reality": -4, "positive": 5, "entropy": 7 },
		},
		"silent_agreement": {
			"label":   _tr("BEHAVIOR_SILENT_AGREEMENT_LABEL"),
			"summary": _tr("BEHAVIOR_SILENT_AGREEMENT_SUMMARY"),
			"style":   _tr("BEHAVIOR_SILENT_AGREEMENT_STYLE"),
			"impact":  { "reality": -2, "positive": 3, "entropy": 1 },
		},
		"reliable_execution": {
			"label":   _tr("BEHAVIOR_RELIABLE_EXECUTION_LABEL"),
			"summary": _tr("BEHAVIOR_RELIABLE_EXECUTION_SUMMARY"),
			"style":   _tr("BEHAVIOR_RELIABLE_EXECUTION_STYLE"),
			"impact":  { "reality": -1, "positive": 4, "entropy": 2 },
		},
		"private_confession": {
			"label":   _tr("BEHAVIOR_PRIVATE_CONFESSION_LABEL"),
			"summary": _tr("BEHAVIOR_PRIVATE_CONFESSION_SUMMARY"),
			"style":   _tr("BEHAVIOR_PRIVATE_CONFESSION_STYLE"),
			"impact":  { "reality": -3, "positive": 2, "entropy": 1 },
		},
	}
	TEAMMATES = {
		"gloria": {
			"name":    _tr("TEAMMATE_GLORIA_NAME"),
			"title":   _tr("TEAMMATE_GLORIA_TITLE"),
			"persona": _tr("TEAMMATE_GLORIA_PERSONA"),
			"color":   Color(1.0, 0.902, 0.702, 1.0),
			"base_chance": 0.35,
			"trigger_keywords": [
				"logic", "complain", "negativity", "problem", "mistake",
				"質疑", "抱怨", "負能量", "問題", "錯誤",
			],
			"trigger_rules": {
				"complaint_counter_min": 2,
				"reality_score_max":     65,
				"positive_energy_min":   35,
			},
			"behaviors": [
				"moral_blackmail", "issue_replacement", "divine_protection",
				"weaponized_innocence", "selective_tolerance", "harmony_above_all",
			],
			"interference_goal": _tr("TEAMMATE_GLORIA_INTERFERENCE_GOAL"),
			"tone":          _tr("TEAMMATE_GLORIA_TONE"),
			"prompt_length": _tr("TEAMMATE_GLORIA_PROMPT_LENGTH"),
			"signature_lines": [
				_tr("TEAMMATE_GLORIA_SIG_1"),
				_tr("TEAMMATE_GLORIA_SIG_2"),
				_tr("TEAMMATE_GLORIA_SIG_3"),
			],
		},
		"donkey": {
			"name":    _tr("TEAMMATE_DONKEY_NAME"),
			"title":   _tr("TEAMMATE_DONKEY_TITLE"),
			"persona": _tr("TEAMMATE_DONKEY_PERSONA"),
			"color":   Color(0.8, 0.6, 0.302, 1.0),
			"base_chance": 0.4,
			"trigger_keywords": [
				"hero", "rescue", "princess", "plan", "women", "story", "female",
				"拯救", "公主", "計畫", "女性", "故事",
			],
			"trigger_rules": {
				"logic_success_only":  true,
				"positive_energy_max": 75,
			},
			"behaviors": [
				"heroic_nonsense", "blame_shifting", "epic_planning",
				"vanish_and_appear", "clique_alliance", "confident_incompetence",
			],
			"interference_goal": _tr("TEAMMATE_DONKEY_INTERFERENCE_GOAL"),
			"tone":          _tr("TEAMMATE_DONKEY_TONE"),
			"prompt_length": _tr("TEAMMATE_DONKEY_PROMPT_LENGTH"),
			"signature_lines": [
				_tr("TEAMMATE_DONKEY_SIG_1"),
				_tr("TEAMMATE_DONKEY_SIG_2"),
			],
		},
		"ark": {
			"name":    _tr("TEAMMATE_ARK_NAME"),
			"title":   _tr("TEAMMATE_ARK_TITLE"),
			"persona": _tr("TEAMMATE_ARK_PERSONA"),
			"color":   Color(0.502, 0.502, 0.702, 1.0),
			"base_chance": 0.32,
			"trigger_keywords": [
				"plan", "strategy", "process", "organize", "progress", "edit", "modify",
				"策略", "流程", "整理", "進度", "修改",
			],
			"trigger_rules": {
				"reality_score_min":  30,
				"positive_energy_min": 20,
			},
			"behaviors": [
				"overcomplicate", "black_box_operation", "absolute_plan",
				"constantly_changing_orders", "unrealistic_ambitions", "communication_barrier",
			],
			"interference_goal": _tr("TEAMMATE_ARK_INTERFERENCE_GOAL"),
			"tone":          _tr("TEAMMATE_ARK_TONE"),
			"prompt_length": _tr("TEAMMATE_ARK_PROMPT_LENGTH"),
			"signature_lines": [
				_tr("TEAMMATE_ARK_SIG_1"),
				_tr("TEAMMATE_ARK_SIG_2"),
			],
		},
		"one": {
			"name":    _tr("TEAMMATE_ONE_NAME"),
			"title":   _tr("TEAMMATE_ONE_TITLE"),
			"persona": _tr("TEAMMATE_ONE_PERSONA"),
			"color":   Color(0.6, 0.702, 0.6, 1.0),
			"base_chance": 0.1,
			"trigger_keywords": [
				"help", "message", "please", "exclude", "myanmar", "marginalize",
				"求助", "幫忙", "私訊", "拜託", "緬甸", "排擠",
			],
			"trigger_rules": {
				"reality_score_max":    55,
				"positive_energy_max":  45,
			},
			"behaviors": [
				"silent_agreement", "reliable_execution", "private_confession",
				"language_barrier", "kind_underdog",
			],
			"interference_goal": _tr("TEAMMATE_ONE_INTERFERENCE_GOAL"),
			"tone":          _tr("TEAMMATE_ONE_TONE"),
			"prompt_length": _tr("TEAMMATE_ONE_PROMPT_LENGTH"),
			"signature_lines": [
				_tr("TEAMMATE_ONE_SIG_1"),
				_tr("TEAMMATE_ONE_SIG_2"),
				_tr("TEAMMATE_ONE_SIG_3"),
				_tr("TEAMMATE_ONE_SIG_4"),
			],
		},
	}
	_team_relationships = {
		"gloria": {
			"player": { "status": "Saving/Purifying", "value": 50 },
			"donkey": { "status": "Tolerates",        "value": 30 },
			"ark":    { "status": "Uses",             "value": 40 },
			"one":    { "status": "Ignores",          "value": 20 },
		},
		"donkey": {
			"player": { "status": "Sidekick",        "value":  60 },
			"gloria": { "status": "Worships",        "value":  90 },
			"ark":    { "status": "Confused by",     "value":  10 },
			"one":    { "status": "Bullying target", "value": -20 },
		},
		"ark": {
			"player": { "status": "Variable",          "value":  50 },
			"gloria": { "status": "Analyzes",          "value":  30 },
			"donkey": { "status": "Disdains",          "value": -40 },
			"one":    { "status": "Calculates utility","value":  40 },
		},
		"one": {
			"player": { "status": "Secretly Envies", "value":  70 },
			"gloria": { "status": "Fears",           "value": -50 },
			"donkey": { "status": "Avoids",          "value": -30 },
			"ark":    { "status": "Obeys",           "value":  20 },
		},
		"teacher_chan": {
			"player": { "status": "Brainwashing", "value": 100 },
			"gloria": { "status": "Rival",        "value": -10 },
		},
	}
func get_teammate_info(teammate_id: String) -> Dictionary:
	return TEAMMATES.get(teammate_id, {})
func list_teammate_ids() -> Array:
	return TEAMMATES.keys()
func get_teammate_name(teammate_id: String) -> String:
	var info = get_teammate_info(teammate_id)
	return info.get("name", "Unknown")
func get_behavior_details(behavior_id: String) -> Dictionary:
	return BEHAVIOR_LIBRARY.get(behavior_id, {})
func should_trigger_interference(teammate_id: String, player_action: String, game_state) -> bool:
	var info = get_teammate_info(teammate_id)
	if info.is_empty():
		return false
	var action_lower = player_action.to_lower()
	for keyword in info.get("trigger_keywords", []):
		if action_lower.find(keyword.to_lower()) != -1:
			return true
	var rules = info.get("trigger_rules", {})
	var complaints = _extract_stat(game_state, "complaint_counter", 0)
	var reality_score = _extract_stat(game_state, "reality_score", 50)
	var positive_energy = _extract_stat(game_state, "positive_energy", 50)
	if rules.has("logic_success_only") and bool(rules["logic_success_only"]) and action_lower.find("success") == -1:
		return false
	if rules.has("complaint_counter_min") and complaints >= int(rules["complaint_counter_min"]):
		return true
	if rules.has("reality_score_max") and reality_score <= int(rules["reality_score_max"]):
		return true
	if rules.has("reality_score_min") and reality_score >= int(rules["reality_score_min"]):
		return true
	if rules.has("positive_energy_min") and positive_energy < int(rules["positive_energy_min"]):
		return false
	if rules.has("positive_energy_max") and positive_energy > int(rules["positive_energy_max"]):
		return false
	var base_chance = float(info.get("base_chance", 0.15))
	var mood_bonus = clamp((positive_energy - 50) / 100.0, -0.25, 0.25)
	var probability = clamp(base_chance + mood_bonus, 0.05, 0.95)
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	var roll := _rng.randf()
	var triggered: bool = roll < probability
	if triggered:
		_report_info("%s decided to intervene! (probability: %.0f%% | roll: %.2f)" % [
			get_teammate_name(teammate_id), probability * 100.0, roll
		])
	return triggered
func generate_interference_prompt(teammate_id: String, context: Dictionary) -> String:
	var info = get_teammate_info(teammate_id)
	if info.is_empty():
		return _tr("TEAMMATE_SYSTEM_DEFAULT_PROMPT")
	var player_action = str(context.get("player_action", _tr("TEAMMATE_SYSTEM_ACTION_MISSING")))
	var reality_score = int(context.get("reality_score", _extract_stat(GameState, "reality_score", 50)))
	var positive_energy = int(context.get("positive_energy", _extract_stat(GameState, "positive_energy", 50)))
	var entropy_level = int(context.get("entropy_level", context.get("entropy", _extract_stat(GameState, "entropy_level", 0))))
	var behavior_lines = _build_behavior_guidelines(info)
	if behavior_lines.is_empty():
		behavior_lines = _tr("TEAMMATE_SYSTEM_NO_BEHAVIORS")
	var recent_summary = ""
	if context.has("recent_events_summary"):
		recent_summary = str(context["recent_events_summary"])
	elif context.has("recent_events") and context["recent_events"] is Array and context["recent_events"].size() > 0:
		var events: Array = context["recent_events"]
		var slice_start = max(0, events.size() - 2)
		recent_summary = ", ".join(events.slice(slice_start, events.size()))
	var lines = []
	lines.append(_tr("TEAMMATE_SYSTEM_ROLE_LINE") % [info.get("name", teammate_id.capitalize()), info.get("title", ""), info.get("persona", _tr("TEAMMATE_SYSTEM_DEFAULT_PERSONA"))])
	lines.append(_tr("TEAMMATE_SYSTEM_PLAYER_ACTION") % player_action)
	if not recent_summary.is_empty():
		lines.append(_tr("TEAMMATE_SYSTEM_RECENT_FAILURES") % recent_summary)
	lines.append(_tr("TEAMMATE_SYSTEM_STATUS_HEADER"))
	lines.append(_tr("TEAMMATE_SYSTEM_REALITY_METER") % [reality_score, _describe_meter(reality_score, true)])
	lines.append(_tr("TEAMMATE_SYSTEM_POSITIVE_METER") % [positive_energy, _describe_meter(positive_energy, false)])
	lines.append(_tr("TEAMMATE_SYSTEM_ENTROPY_METER") % [entropy_level, _describe_entropy_level(entropy_level)])
	lines.append(_tr("TEAMMATE_SYSTEM_MISSION_GOAL") % info.get("interference_goal", _tr("TEAMMATE_SYSTEM_DEFAULT_GOAL")))
	lines.append("")
	lines.append(_tr("TEAMMATE_SYSTEM_METHODS_HEADER"))
	lines.append(behavior_lines)
	var signature: Array = info.get("signature_lines", [])
	if signature.size() > 0:
		lines.append(_tr("TEAMMATE_SYSTEM_TONE_REFERENCE") % ", ".join(signature))
	lines.append("")
	lines.append(_tr("TEAMMATE_SYSTEM_WRITE_NARRATIVE") % [info.get("tone", _tr("TEAMMATE_SYSTEM_DEFAULT_TONE")), info.get("prompt_length", _tr("TEAMMATE_SYSTEM_DEFAULT_LENGTH"))])
	lines.append(_tr("TEAMMATE_SYSTEM_NARRATIVE_MUST"))
	lines.append(_tr("TEAMMATE_SYSTEM_NARRATIVE_REQ1"))
	lines.append(_tr("TEAMMATE_SYSTEM_NARRATIVE_REQ2"))
	lines.append(_tr("TEAMMATE_SYSTEM_NARRATIVE_REQ3"))
	var assets_context = context.duplicate() if context else {}
	if not assets_context.has("asset_ids") and GameState:
		assets_context["asset_ids"] = GameState.get_metadata("current_asset_ids", [])
	var assets_info: Array = AssetRegistry.get_assets_for_context(assets_context)
	if assets_info.size() > 0:
		lines.append("")
		lines.append(_tr("TEAMMATE_SYSTEM_ASSETS_HEADER"))
		lines.append(AssetRegistry.format_assets_for_prompt(assets_info))
		lines.append(_tr("TEAMMATE_SYSTEM_ASSETS_MISUSE"))
	lines.append(_tr("TEAMMATE_SYSTEM_IRONIC_ENDING"))
	return "\n".join(lines)
func get_behavior_description(behavior_id: String) -> String:
	var details: Dictionary = get_behavior_details(behavior_id)
	if details.is_empty():
		return "Unknown Behavior"
	var impact: String = _format_impact(details.get("impact", {}))
	var label: String = details.get("label", behavior_id.capitalize())
	var summary: String = details.get("summary", "Unknown Behavior")
	if impact.is_empty():
		return "%s: %s" % [label, summary]
	return "%s: %s %s" % [label, summary, impact]
func get_all_relationships() -> Dictionary:
	return _team_relationships.duplicate(true)
func get_relationships_for(source_id: String) -> Dictionary:
	return _team_relationships.get(source_id, {}).duplicate(true)
func update_relationship(source_id: String, target_id: String, status: String, value_change: int = 0) -> void:
	if not _team_relationships.has(source_id):
		_team_relationships[source_id] = {}
	if not _team_relationships[source_id].has(target_id):
		_team_relationships[source_id][target_id] = { "status": status, "value": 0 }
	else:
		_team_relationships[source_id][target_id]["status"] = status
	var old_value: int = _team_relationships[source_id][target_id]["value"]
	_team_relationships[source_id][target_id]["value"] = clamp(old_value + value_change, -100, 100)
	var new_value: int = _team_relationships[source_id][target_id]["value"]
	if value_change != 0:
		_report_info("%s -> %s: status=%s | affinity %d -> %d (%+d)" % [
			source_id.capitalize(), target_id.capitalize(),
			status, old_value, new_value, value_change
		])
	relationship_updated.emit(source_id, target_id)
func get_state_snapshot() -> Dictionary:
	return { "relationships": _team_relationships.duplicate(true) }
func load_state_snapshot(data: Dictionary) -> void:
	if data.has("relationships") and data["relationships"] is Dictionary:
		_team_relationships = data["relationships"].duplicate(true)
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _build_behavior_guidelines(info: Dictionary) -> String:
	var lines = []
	for behavior_id in info.get("behaviors", []):
		var details = get_behavior_details(behavior_id)
		if details.is_empty():
			continue
		var label = details.get("label", behavior_id.capitalize())
		var summary = details.get("summary", "")
		var impact = _format_impact(details.get("impact", {}))
		var style = details.get("style", "")
		var line = _tr("TEAMMATE_SYSTEM_BEHAVIOR_FORMAT") % [label, summary]
		if not impact.is_empty():
			line += " %s" % impact
		if not style.is_empty():
			var method_prefix = _tr("TEAMMATE_SYSTEM_PREFERRED_APPROACH")
			line += "%s%s" % [method_prefix, style]
		lines.append(line)
	return "\n".join(lines)
func _format_impact(impact: Dictionary) -> String:
	if impact.is_empty():
		return ""
	var parts = []
	if impact.has("reality"):
		var reality_label = _tr("TEAMMATE_SYSTEM_REALITY_SCORE")
		parts.append("%s%+d" % [reality_label, int(impact["reality"])])
	if impact.has("positive"):
		var positive_label = _tr("TEAMMATE_SYSTEM_POSITIVE_ENERGY")
		parts.append("%s%+d" % [positive_label, int(impact["positive"])])
	if impact.has("entropy"):
		var entropy_label = _tr("TEAMMATE_SYSTEM_ENTROPY")
		parts.append("%s%+d" % [entropy_label, int(impact["entropy"])])
	var expected_label = _tr("TEAMMATE_SYSTEM_EXPECTED_IMPACT")
	var suffix = _tr("TEAMMATE_SYSTEM_IMPACT_SUFFIX")
	return "%s%s%s" % [expected_label, ", ".join(parts), suffix]
func _describe_meter(value: int, high_is_good: bool, _lang: String = "en") -> String:
	var bucket := ""
	if value >= 80:
		bucket = "VERY_HIGH"
	elif value >= 60:
		bucket = "HIGH"
	elif value >= 40:
		bucket = "MID"
	elif value >= 20:
		bucket = "LOW"
	else:
		bucket = "CRITICAL"
	var prefix := "TEAMMATE_SYSTEM_METER_REALITY_" if high_is_good else "TEAMMATE_SYSTEM_METER_POSITIVE_"
	return _tr(prefix + bucket)
func _describe_entropy_level(level: int, _lang: String = "zh") -> String:
	if level >= 60:
		return _tr("TEAMMATE_SYSTEM_ENTROPY_VERY_HIGH")
	if level >= 30:
		return _tr("TEAMMATE_SYSTEM_ENTROPY_HIGH")
	if level >= 10:
		return _tr("TEAMMATE_SYSTEM_ENTROPY_MID")
	return _tr("TEAMMATE_SYSTEM_ENTROPY_LOW")
func _extract_stat(source, key: String, default_value):
	if source == null:
		return default_value
	match typeof(source):
		TYPE_DICTIONARY:
			return source.get(key, default_value)
		TYPE_OBJECT:
			var value = source.get(key)
			return value if value != null else default_value
		_:
			return default_value
