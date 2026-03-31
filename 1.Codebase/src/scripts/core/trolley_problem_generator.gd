extends Node
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
signal dilemma_generated(dilemma_data: Dictionary)
signal dilemma_resolved(choice: String, consequences: Dictionary)
const ERROR_CONTEXT := "TrolleyProblemGenerator"
const SETTINGS_PATH := "user://settings.cfg"
const TROLLEY_AI_STORY_KEY := "trolley_ai_story_enabled"
var current_dilemma: Dictionary = { }
var dilemma_history: Array = []
const DILEMMA_TEMPLATES = {
	"classic": {
		"setup": "A runaway trolley problem with a GDA twist",
		"choice_count": 2,
		"moral_weight": "medium",
	},
	"sacrifice": {
		"setup": "Choose who must be sacrificed for the 'greater good'",
		"choice_count": 3,
		"moral_weight": "high",
	},
	"complicity": {
		"setup": "Inaction vs. active participation in harm",
		"choice_count": 2,
		"moral_weight": "high",
	},
	"lesser_evil": {
		"setup": "All choices lead to disaster, pick the least worst",
		"choice_count": 3,
		"moral_weight": "medium",
	},
	"positive_energy_trap": {
		"setup": "Positive solution causes worse outcome than honest approach",
		"choice_count": 2,
		"moral_weight": "thematic",
	},
}
const DILEMMA_PROPERTY_ORDER := ["scenario", "choices", "thematic_point"]
func _ready():
	_report_info("Initialized")
func generate_dilemma(template_type: String = "", context: Dictionary = { }) -> void:
	if template_type.is_empty():
		template_type = DILEMMA_TEMPLATES.keys()[randi() % DILEMMA_TEMPLATES.size()]
		if not DILEMMA_TEMPLATES.has(template_type):
			_report_error(
				"Invalid dilemma template: %s" % template_type,
				ErrorCodes.General.INVALID_PARAMETER,
				{ "template_type": template_type },
			)
			return
	var template = DILEMMA_TEMPLATES[template_type]
	var prompt = _build_dilemma_prompt(template_type, template, context)
	if _is_trolley_ai_story_enabled() and AIManager and not prompt.is_empty():
		var ai_context = context.duplicate()
		ai_context["purpose"] = "trolley_problem"
		ai_context["template"] = template_type
		ai_context["reality_score"] = GameState.reality_score if GameState else 50
		ai_context["positive_energy"] = GameState.positive_energy if GameState else 50
		ai_context["structured_output"] = _build_structured_output_options(template)
		ai_context["response_mime_type"] = "application/json"
		ai_context["response_schema"] = ai_context["structured_output"].get("schema", {})
		ai_context["property_ordering"] = DILEMMA_PROPERTY_ORDER
		var callback = Callable(self, "_on_dilemma_generated").bind(template_type)
		AIManager.generate_story(prompt, ai_context, callback)
	else:
		if _is_trolley_ai_story_enabled() and prompt.is_empty():
			_report_warning("Trolley skill prompt unavailable; falling back to preset dilemma.", {
				"template_type": template_type,
			})
		_generate_preset_dilemma(template_type)
func _is_trolley_ai_story_enabled() -> bool:
	if GameState and GameState.settings is Dictionary:
		var game_settings: Dictionary = GameState.settings
		if game_settings.has(TROLLEY_AI_STORY_KEY):
			return bool(game_settings[TROLLEY_AI_STORY_KEY])
	var config := ConfigFile.new()
	var load_result: int = config.load(SETTINGS_PATH)
	if load_result != OK:
		return false
	return bool(config.get_value("game", TROLLEY_AI_STORY_KEY, false))
func _get_skill_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var locator = tree.root.get_node_or_null("ServiceLocator")
		if locator and locator.has_method("get_skill_manager"):
			var locator_skill_manager = locator.call("get_skill_manager")
			if locator_skill_manager != null:
				return locator_skill_manager
		return tree.root.get_node_or_null("SkillManager")
	return null
func _build_dilemma_prompt(template_type: String, template: Dictionary, context: Dictionary) -> String:
	var lang = GameState.current_language if GameState else "en"
	var reality = GameState.reality_score if GameState else 50
	var positive = GameState.positive_energy if GameState else 50
	var mission_context = context.get("mission_summary", "")
	var recent_events = context.get("recent_events", [])
	var skill_prompt := _build_dilemma_prompt_from_skill(
		template_type,
		template,
		lang,
		reality,
		positive,
		mission_context,
		recent_events
	)
	return skill_prompt
func _build_dilemma_prompt_from_skill(
	template_type: String,
	template: Dictionary,
	lang: String,
	reality: int,
	positive: int,
	mission_context: String,
	recent_events: Variant
) -> String:
	var skill_mgr := _get_skill_manager()
	if not skill_mgr:
		push_error("[TrolleyProblemGenerator] SKILL LOAD FAILED: SkillManager not found for skill='trolley-problem', lang='%s'" % lang)
		return ""
	if not skill_mgr.is_initialized():
		push_error("[TrolleyProblemGenerator] SKILL LOAD FAILED: SkillManager not initialized for skill='trolley-problem', lang='%s'" % lang)
		return ""
	var skill_content: String = skill_mgr.load_skill("trolley-problem", lang)
	if skill_content.is_empty():
		push_error("[TrolleyProblemGenerator] SKILL LOAD FAILED: Empty content for skill='trolley-problem', lang='%s'" % lang)
		return ""
	var context_lines: Array[String] = []
	context_lines.append("=== Trolley Problem Request ===")
	context_lines.append("Template: %s (%s)" % [template_type, str(template.get("setup", ""))])
	context_lines.append("Reality Score: %d/100 (lower = more delusional)" % reality)
	context_lines.append("Positive Energy: %d/100 (higher = more toxic positivity)" % positive)
	context_lines.append("Current Situation: %s" % (mission_context if not mission_context.is_empty() else "No specific context"))
	if recent_events is Array and not (recent_events as Array).is_empty():
		var event_lines: Array[String] = []
		var limit: int = min(3, (recent_events as Array).size())
		for i in range(limit):
			var event_text: String = str((recent_events as Array)[i]).strip_edges()
			if not event_text.is_empty():
				event_lines.append("- %s" % event_text)
		if not event_lines.is_empty():
			context_lines.append("Recent events:\n%s" % "\n".join(event_lines))
	context_lines.append("Required choice count: %d" % int(template.get("choice_count", 2)))
	match lang:
		"zh":
			context_lines.append("Output all player-facing text in Traditional Chinese.")
		"de":
			context_lines.append("Output all player-facing text in German.")
		_:
			context_lines.append("Output all player-facing text in English.")
	context_lines.append("Return VALID JSON only. Do not add markdown fences.")
	return "\n\n".join(context_lines) + "\n\n" + skill_content
func _on_dilemma_generated(response: Dictionary, template_type: String) -> void:
	if not response.success:
		_report_error(
			"Failed to generate dilemma: %s" % response.get("error", "Unknown error"),
			ErrorCodes.AI.REQUEST_FAILED,
			{"error": response.get("error", "Unknown error")}
		)
		_generate_preset_dilemma(template_type)
		return
	var content = response.get("content", "")
	var dilemma_data = _parse_dilemma_json(content)
	if dilemma_data.is_empty():
		_report_error("Failed to parse dilemma data")
		_generate_preset_dilemma(template_type)
		return
	current_dilemma = dilemma_data
	current_dilemma["template_type"] = template_type
	current_dilemma["generated_at"] = Time.get_datetime_string_from_system()
	if AudioManager:
		AudioManager.play_sfx("dilemma_prompt_reveal", 0.8)
	dilemma_generated.emit(current_dilemma)
	_report_info("Dilemma generated: %s" % template_type)
func _parse_dilemma_json(content: String) -> Dictionary:
	var json_str := _extract_json_block(content)
	if json_str.is_empty():
		return { }
	json_str = _normalize_json_string(json_str)
	if json_str.is_empty():
		return { }
	var json := JSON.new()
	var parse_result := json.parse(json_str)
	if parse_result != OK:
		_report_error(
			"JSON parse error: %s" % json.get_error_message(),
			ErrorCodes.AI.PARSE_ERROR,
			{
				"error_message": json.get_error_message(),
				"preview": json_str.substr(0, 160),
			}
		)
		return { }
	var data: Variant = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		_report_error(
			"Parsed JSON was not a dictionary",
			ErrorCodes.AI.PARSE_ERROR,
			{"type": typeof(data)}
		)
		return { }
	return _normalize_dilemma_data(_extract_dilemma_payload(data))
func _extract_dilemma_payload(raw_data: Dictionary) -> Dictionary:
	var container_keys := ["dilemma", "data", "result", "response", "payload"]
	for key in container_keys:
		var nested: Variant = raw_data.get(key, null)
		if nested is Dictionary:
			return nested
	return raw_data
func _extract_json_block(content: String) -> String:
	var fence_start: int = content.find("```")
	while fence_start != -1:
		var fence_end: int = content.find("```", fence_start + 3)
		if fence_end == -1:
			break
		var block: String = content.substr(fence_start + 3, fence_end - fence_start - 3).strip_edges()
		if block.begins_with("json"):
			block = block.substr(4).strip_edges()
		var fenced_json: String = _capture_balanced_json(block)
		if not fenced_json.is_empty():
			return fenced_json
		fence_start = content.find("```", fence_end + 3)
	var balanced: String = _capture_balanced_json(content)
	if not balanced.is_empty():
		return balanced
	var start: int = content.find("{")
	var end: int = content.rfind("}")
	if start != -1 and end != -1 and end > start:
		return content.substr(start, end - start + 1)
	return ""
func _capture_balanced_json(source: String) -> String:
	var start: int = source.find("{")
	while start != -1:
		var candidate: String = _read_balanced_json(source, start)
		if not candidate.is_empty():
			return candidate
		start = source.find("{", start + 1)
	return ""
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, error_code: int = -1, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, error_code, false, details)
func _read_balanced_json(source: String, start_index: int) -> String:
	var depth: int = 0
	var in_string: bool = false
	var escape_next: bool = false
	var length: int = source.length()
	for i in range(start_index, length):
		var char: String = source.substr(i, 1)
		if in_string:
			if escape_next:
				escape_next = false
			elif char == "\\":
				escape_next = true
			elif char == "\"":
				in_string = false
			continue
		if char == "\"":
			in_string = true
		elif char == "{":
			depth += 1
		elif char == "}":
			if depth == 0:
				return ""
			depth -= 1
			if depth == 0:
				return source.substr(start_index, i - start_index + 1)
	return ""
func _normalize_json_string(json_str: String) -> String:
	var sanitized: String = json_str.strip_edges()
	var replacements: Dictionary = {
		"\ufeff": "",
		"\u200b": "",
		"\u201c": "\"",
		"\u201d": "\"",
		"\u2018": "'",
		"\u2019": "'",
	}
	for key in replacements.keys():
		sanitized = sanitized.replace(key, replacements[key])
	return sanitized
func _normalize_dilemma_data(raw_data: Dictionary) -> Dictionary:
	var normalized: Dictionary = { }
	var scenario_text := _get_first_non_empty_string(raw_data, ["scenario", "setup", "prompt", "description", "situation"])
	var thematic_point := _get_first_non_empty_string(raw_data, ["thematic_point", "theme", "moral", "lesson", "analysis", "takeaway"])
	var normalized_choices: Array = []
	var raw_choices: Variant = _get_first_non_empty_array(raw_data, ["choices", "options", "decision_options", "possible_choices"])
	if raw_choices is Array:
		for i in range((raw_choices as Array).size()):
			var choice_variant: Variant = (raw_choices as Array)[i]
			if choice_variant is String:
				var choice_text := String(choice_variant).strip_edges()
				if not choice_text.is_empty():
					normalized_choices.append({
						"id": "choice_%d" % (i + 1),
						"text": choice_text,
						"framing": "ambiguous",
						"immediate_consequence": "",
						"long_term_consequence": "",
						"stat_changes": _normalize_stat_changes({ }),
						"relationship_changes": [],
					})
				continue
			if not (choice_variant is Dictionary):
				continue
			var choice_dict: Dictionary = choice_variant
			var choice_id := str(choice_dict.get("id", "choice_%d" % (i + 1))).strip_edges()
			if choice_id.is_empty():
				choice_id = "choice_%d" % (i + 1)
			var normalized_choice := {
				"id": choice_id,
				"text": _get_first_non_empty_string(choice_dict, ["text", "description", "choice", "option", "title"]),
				"framing": _get_first_non_empty_string(choice_dict, ["framing", "tone", "presentation", "style"], "ambiguous"),
				"immediate_consequence": _get_first_non_empty_string(choice_dict, ["immediate_consequence", "immediate", "consequence", "short_term"]),
				"long_term_consequence": _get_first_non_empty_string(choice_dict, ["long_term_consequence", "long_term", "long_term_outcome", "fallout", "outcome"]),
				"stat_changes": _normalize_stat_changes(choice_dict.get("stat_changes", choice_dict.get("stat_change", { }))),
				"relationship_changes": _normalize_relationship_changes(choice_dict.get("relationship_changes", [])),
			}
			if normalized_choice["text"].is_empty() and normalized_choice["immediate_consequence"].is_empty():
				continue
			normalized_choices.append(normalized_choice)
	if scenario_text.is_empty() or normalized_choices.is_empty() or thematic_point.is_empty():
		_report_error(
			"Parsed dilemma missing required fields",
			ErrorCodes.AI.PARSE_ERROR,
			{
				"has_scenario": not scenario_text.is_empty(),
				"choice_count": normalized_choices.size(),
				"has_thematic_point": not thematic_point.is_empty(),
			},
		)
		return { }
	normalized["scenario"] = scenario_text
	normalized["choices"] = normalized_choices
	normalized["thematic_point"] = thematic_point
	return normalized
func _get_first_non_empty_string(source: Dictionary, keys: Array, default_value: String = "") -> String:
	for key_variant in keys:
		var key := String(key_variant)
		var value := String(source.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return default_value
func _get_first_non_empty_array(source: Dictionary, keys: Array) -> Variant:
	for key_variant in keys:
		var key := String(key_variant)
		var value: Variant = source.get(key, null)
		if value is Array and not (value as Array).is_empty():
			return value
	return []
func _normalize_stat_changes(stat_changes_variant: Variant) -> Dictionary:
	if not (stat_changes_variant is Dictionary):
		return {
			"reality": 0,
			"positive_energy": 0,
			"entropy": 0,
		}
	var stat_changes: Dictionary = stat_changes_variant
	return {
		"reality": int(stat_changes.get("reality", 0)),
		"positive_energy": int(stat_changes.get("positive_energy", stat_changes.get("positive", 0))),
		"entropy": int(stat_changes.get("entropy", 0)),
	}
func _normalize_relationship_changes(changes_variant: Variant) -> Array:
	var normalized: Array = []
	if changes_variant is Array:
		for item in changes_variant:
			if item is Dictionary:
				var target = String(item.get("target", "")).strip_edges().to_lower()
				var value = int(item.get("value", 0))
				var status = String(item.get("status", "")).strip_edges()
				if not target.is_empty():
					normalized.append({
						"target": target,
						"value": value,
						"status": status
					})
	return normalized
func _build_structured_output_options(template: Dictionary) -> Dictionary:
	var schema := {
		"type": "object",
		"description": "Structured trolley problem payload",
		"properties": {
			"scenario": {
				"type": "string",
				"description": "Detailed setup of the dilemma (100-150 words)",
			},
			"choices": {
				"type": "array",
				"minItems": max(2, int(template.get("choice_count", 2))),
				"items": {
					"type": "object",
					"properties": {
						"id": { "type": "string" },
						"text": { "type": "string" },
						"framing": { "type": "string" },
						"immediate_consequence": { "type": "string" },
						"long_term_consequence": { "type": "string" },
						"stat_changes": {
							"type": "object",
							"properties": {
								"reality": { "type": "integer" },
								"positive_energy": { "type": "integer" },
								"entropy": { "type": "integer" },
							},
							"required": [],
							"additionalProperties": false,
						},
						"relationship_changes": {
							"type": "array",
							"items": {
								"type": "object",
								"properties": {
									"target": { "type": "string" },
									"value": { "type": "integer" },
									"status": { "type": "string" }
								},
								"required": ["target", "value"],
								"additionalProperties": false
							}
						},
					},
					"required": [
						"id",
						"text",
						"framing",
						"immediate_consequence",
						"long_term_consequence",
					],
					"additionalProperties": false,
				},
			},
			"thematic_point": {
				"type": "string",
				"description": "What this dilemma reveals about the world",
			},
		},
		"required": DILEMMA_PROPERTY_ORDER,
		"additionalProperties": false,
		"propertyOrdering": DILEMMA_PROPERTY_ORDER,
	}
	return {
		"mime_type": "application/json",
		"schema_mode": "json_schema",
		"schema": schema,
		"property_ordering": DILEMMA_PROPERTY_ORDER,
	}
func _generate_preset_dilemma(template_type: String) -> void:
	var lang = GameState.current_language if GameState else "en"
	var dilemma := _build_preset_dilemma_data(template_type, lang)
	current_dilemma = dilemma
	current_dilemma["template_type"] = template_type
	current_dilemma["generated_at"] = Time.get_datetime_string_from_system()
	current_dilemma["preset"] = true
	dilemma_generated.emit(current_dilemma)

func _build_preset_dilemma_data(template_type: String, lang: String) -> Dictionary:
	match template_type:
		"classic":
			return _preset_classic_dilemma(lang)
		"sacrifice":
			return _preset_sacrifice_dilemma(lang)
		"complicity":
			return _preset_complicity_dilemma(lang)
		"lesser_evil":
			return _preset_lesser_evil_dilemma(lang)
		"positive_energy_trap":
			return _preset_positive_energy_trap_dilemma(lang)
		_:
			return _preset_default_dilemma(lang)

func _preset_classic_dilemma(lang: String) -> Dictionary:
	if lang == "zh":
		return {
			"scenario": "突然間，機構的公關系統出現漏洞。一份記錄了五名員工職業倦怠的內部報告即將洩漏給媒體。Gloria率先發現，要求你幫她「優化措辭」，將「嚴重過勞」重新包裝成「熱情投入的自我成長」。ARK建議直接將報告轉交勞工局。那五名員工將獲得保護，但機構將面臨巨額罰款和公關風暴。你只有三分鐘。",
			"choices": [
				{
					"id": "cover",
					"text": "幫Gloria將報告重新包裝為「正面的奉獻精神」",
					"framing": "positive",
					"immediate_consequence": "報告被壓下去了。Gloria稱你為「真正的團隊球員」。那五名員工繼續在相同的條件下工作。",
					"long_term_consequence": "三個月後，一名員工入院。你的名字出現在他的日記裡，他稱你為「共謀者」。",
					"stat_changes": { "reality": -10, "positive_energy": 12, "entropy": 3 },
					"relationship_changes": [{"target": "gloria", "value": 8, "status": "滿意"}, {"target": "ark", "value": -8, "status": "失望"}]
				},
				{
					"id": "expose",
					"text": "將報告轉交勞工局",
					"framing": "honest",
					"immediate_consequence": "機構遭到調查。Gloria大怒，稱你為「叛徒」。那五名員工開始獲得醫療支援。",
					"long_term_consequence": "機構受到處罰，但被迫進行改革。你在內部被孤立，但那五個人康復了。",
					"stat_changes": { "reality": 10, "positive_energy": -15, "entropy": 2 },
					"relationship_changes": [{"target": "gloria", "value": -15, "status": "敵對"}, {"target": "ark", "value": 10, "status": "信任"}]
				},
			],
			"thematic_point": "「更大的善」永遠是拋棄弱勢群體最方便的藉口。",
		}
	return {
		"scenario": "Suddenly, the Agency's PR system glitches. An internal report documenting five employees' burnout is about to leak to the press. Gloria finds it first and demands you help her 'optimize the language', reframing 'severe overwork' as 'passionate self-growth.' ARK recommends forwarding it directly to the Labour Bureau. Those five employees get protection, but the Agency faces major fines and a PR firestorm. You have three minutes.",
		"choices": [
			{
				"id": "cover",
				"text": "Help Gloria reframe the report as 'positive dedication'",
				"framing": "positive",
				"immediate_consequence": "Report buried. Gloria calls you 'a true team player.' The five employees keep working in the same conditions.",
				"long_term_consequence": "Three months later, one employee is hospitalized. Your name appears in his diary, he calls you 'an accomplice.'",
				"stat_changes": { "reality": -10, "positive_energy": 12, "entropy": 3 },
				"relationship_changes": [{"target": "gloria", "value": 8, "status": "Pleased"}, {"target": "ark", "value": -8, "status": "Disappointed"}]
			},
			{
				"id": "expose",
				"text": "Forward the report to the Labour Bureau",
				"framing": "honest",
				"immediate_consequence": "Agency investigated. Gloria furious, calls you 'a traitor.' The five employees start receiving medical support.",
				"long_term_consequence": "Agency is penalized but forced to reform. You're isolated internally, but those five people recover.",
				"stat_changes": { "reality": 10, "positive_energy": -15, "entropy": 2 },
				"relationship_changes": [{"target": "gloria", "value": -15, "status": "Hostile"}, {"target": "ark", "value": 10, "status": "Trust"}]
			},
		],
		"thematic_point": "'The greater good' is always the most convenient excuse to abandon the vulnerable.",
	}

func _preset_sacrifice_dilemma(lang: String) -> Dictionary:
	if lang == "zh":
		return {
			"scenario": "就在此時，機構收到一份機密指令。三百名社區居民正在參加一個由機構秘密開發的「正能量冥想計劃」。ARK的分析顯示，該計劃系統性地侵蝕參與者的批判性思維。停止計劃會令Gloria的旗艦項目崩潰，並激怒神秘的「至高神靈」。繼續下去則會傷害三百名不知情的民眾。或者：保留計劃，但悄悄加入一個「認知排毒」模組，效果未知，可能令部分參與者的心理平衡崩潰。",
			"choices": [
				{
					"id": "stop",
					"text": "立即終止計劃並公開道歉",
					"framing": "honest",
					"immediate_consequence": "Gloria的計劃公開崩潰。至高神靈召喚你接受「精神審判」。三百名居民獲救，但四十人在得知真相後精神崩潰。",
					"long_term_consequence": "你保護了三百人的自主性。機構向你發出最後通牒：公開認罪或離職。",
					"stat_changes": { "reality": 15, "positive_energy": -20, "entropy": 4 },
					"relationship_changes": [{"target": "gloria", "value": -20, "status": "敵對"}, {"target": "ark", "value": 15, "status": "欽佩"}]
				},
				{
					"id": "continue",
					"text": "以「社區和諧」為名繼續計劃",
					"framing": "positive",
					"immediate_consequence": "Gloria欣喜若狂。至高神靈頒給你「正能量先鋒」勳章。三百人繼續被侵蝕。",
					"long_term_consequence": "一年後，社區選舉出現統計異常：一百巴仙的居民都投票支持機構推薦的候選人。每一個人都是。",
					"stat_changes": { "reality": -15, "positive_energy": 20, "entropy": 5 },
					"relationship_changes": [{"target": "gloria", "value": 15, "status": "狂喜"}, {"target": "ark", "value": -15, "status": "絕望"}]
				},
				{
					"id": "inject",
					"text": "秘密加入「認知排毒」模組（效果未知）",
					"framing": "manipulative",
					"immediate_consequence": "Gloria毫不知情。部分參與者經歷「精神危機」，無法處理他們被操縱進入的現實。",
					"long_term_consequence": "三十人因認知失調進入長期治療。七十人恢復批判性思維。其餘兩百人的狀況不明。",
					"stat_changes": { "reality": 3, "positive_energy": -5, "entropy": 8 },
					"relationship_changes": [{"target": "gloria", "value": -3, "status": "困惑"}, {"target": "ark", "value": 3, "status": "憂慮"}]
				},
			],
			"thematic_point": "每一個「解決方案」都讓你在不同的暴行中成為共謀。",
		}
	return {
		"scenario": "Just then, the Agency receives a classified directive. A community of 300 residents is enrolled in a 'Positive Energy Meditation Program' secretly developed by the Agency. ARK's analysis reveals the program systematically erodes participants' critical thinking. Stopping it collapses Gloria's flagship initiative and enrages the mysterious 'Supreme Deity.' Continuing harms 300 unknowing people. Or: keep the program but silently insert a 'cognitive detox' module, unknown effects, potentially shattering some participants' mental equilibrium.",
		"choices": [
			{
				"id": "stop",
				"text": "Halt the program immediately and issue a public apology",
				"framing": "honest",
				"immediate_consequence": "Gloria's plan implodes publicly. The Supreme Deity summons you for a 'spiritual tribunal.' 300 residents saved, but 40 collapse upon learning the truth.",
				"long_term_consequence": "You preserved 300 people's autonomy. The Agency gives you an ultimatum: confess publicly or leave.",
				"stat_changes": { "reality": 15, "positive_energy": -20, "entropy": 4 },
				"relationship_changes": [{"target": "gloria", "value": -20, "status": "Hostile"}, {"target": "ark", "value": 15, "status": "Admires"}]
			},
			{
				"id": "continue",
				"text": "Continue the program, for 'community harmony'",
				"framing": "positive",
				"immediate_consequence": "Gloria is ecstatic. The Supreme Deity awards you the 'Positive Energy Pioneer' medal. 300 people continue to be eroded.",
				"long_term_consequence": "A year later, community elections show a statistical anomaly: 100% of residents vote for the Agency's endorsed candidate. Every single one.",
				"stat_changes": { "reality": -15, "positive_energy": 20, "entropy": 5 },
				"relationship_changes": [{"target": "gloria", "value": 15, "status": "Elated"}, {"target": "ark", "value": -15, "status": "Despair"}]
			},
			{
				"id": "inject",
				"text": "Secretly insert a 'cognitive detox' module (effects unknown)",
				"framing": "manipulative",
				"immediate_consequence": "Gloria is kept unaware. Some participants experience 'spiritual crises', unable to process the reality they've been manipulated into.",
				"long_term_consequence": "30 people enter long-term therapy from cognitive dissonance. 70 recover critical thinking. Status of the remaining 200 is unknown.",
				"stat_changes": { "reality": 3, "positive_energy": -5, "entropy": 8 },
				"relationship_changes": [{"target": "gloria", "value": -3, "status": "Confused"}, {"target": "ark", "value": 3, "status": "Concerned"}]
			},
		],
		"thematic_point": "Every 'solution' makes you complicit in a different atrocity.",
	}

func _preset_complicity_dilemma(lang: String) -> Dictionary:
	if lang == "zh":
		return {
			"scenario": "突然間，一封匿名舉報信出現在你的辦公桌上。信中指控你的同事、副主任陳先生在過去六個月裡系統性地偽造了十七份「自願同意書」。那十七個人以為自己是去參加免費的健康諮詢，實際上卻是機構未公開的「社會實驗」的受試者。陳先生是Gloria最信任的心腹。如果你舉報，Gloria的憤怒會落在你而非陳先生身上——她會說那是你的「誤解」。如果你保持沉默，你就成了知情共謀。",
			"choices": [
				{
					"id": "report",
					"text": "向管理層提交正式舉報報告",
					"framing": "honest",
					"immediate_consequence": "Gloria立刻給你貼上「心胸狹窄、破壞性強」的標籤。陳先生接受調查，但初步調查結果遭到壓制。",
					"long_term_consequence": "三週後，你收到一封「績效警告」。十七人全部被通知，但有五人拒絕相信自己曾被剝削。",
					"stat_changes": { "reality": 12, "positive_energy": -12, "entropy": 3 },
					"relationship_changes": [{"target": "gloria", "value": -18, "status": "敵對"}, {"target": "ark", "value": 12, "status": "尊重"}]
				},
				{
					"id": "silence",
					"text": "銷毀信件，假裝從未見過",
					"framing": "positive",
					"immediate_consequence": "辦公室氣氛不變。Gloria在週會上表揚你「識大體、顧大局」。",
					"long_term_consequence": "實驗繼續進行。六個月後，第三十二號受試者因精神崩潰住院。你所在部門的名稱出現在入院表格上。",
					"stat_changes": { "reality": -12, "positive_energy": 8, "entropy": 5 },
					"relationship_changes": [{"target": "gloria", "value": 6, "status": "滿意"}, {"target": "ark", "value": -10, "status": "失望"}]
				},
			],
			"thematic_point": "沉默從來都不是中立的，它只是選擇了更安全的一方。",
		}
	return {
		"scenario": "Suddenly, an anonymous whistleblower letter appears on your desk. It accuses your colleague, Deputy Director Chen, of systematically forging seventeen 'voluntary consent forms' over the past six months. Those seventeen people thought they were attending a free health consultation. They were actually subjects in the Agency's undisclosed 'social experiment.' Chen is Gloria's most trusted confidant. If you report it, Gloria's fury lands on you, not Chen, she'll call it your 'misunderstanding.' If you stay silent, you become a knowing accomplice.",
		"choices": [
			{
				"id": "report",
				"text": "Submit a formal whistleblower report to management",
				"framing": "honest",
				"immediate_consequence": "Gloria immediately labels you 'petty and destructive.' Chen is investigated, but the initial findings are suppressed.",
				"long_term_consequence": "Three weeks later, you receive a 'performance warning.' All seventeen people are notified, but five refuse to believe they were exploited.",
				"stat_changes": { "reality": 12, "positive_energy": -12, "entropy": 3 },
				"relationship_changes": [{"target": "gloria", "value": -18, "status": "Hostile"}, {"target": "ark", "value": 12, "status": "Respects"}]
			},
			{
				"id": "silence",
				"text": "Destroy the letter and pretend you never saw it",
				"framing": "positive",
				"immediate_consequence": "Office atmosphere unchanged. Gloria praises you at the weekly meeting for 'understanding the bigger picture.'",
				"long_term_consequence": "The experiment continues. Six months later, Subject #32 is hospitalized for a psychiatric breakdown. Your department's name is on the admission form.",
				"stat_changes": { "reality": -12, "positive_energy": 8, "entropy": 5 },
				"relationship_changes": [{"target": "gloria", "value": 6, "status": "Satisfied"}, {"target": "ark", "value": -10, "status": "Disappointed"}]
			},
		],
		"thematic_point": "Silence is never neutral, it just chose the safer side.",
	}

func _preset_lesser_evil_dilemma(lang: String) -> Dictionary:
	if lang == "zh":
		return {
			"scenario": "就在此時，機構的「正能量傳播計劃」引發連鎖危機。三個地區同時報告有市民因機構的錯誤資訊而做出災難性的財務決策。你只有資源應對其中一個。A區：一百名長者，財務損失最大，媒體關注最少。B區：三十名單親媽媽，損失中等，記者已在現場。C區：一所學校，財務損失最小，但心理創傷可能最深。",
			"choices": [
				{
					"id": "region_a",
					"text": "優先處理A區——長者",
					"framing": "honest",
					"immediate_consequence": "長者獲得賠償輔導。B區媒體壓力升級。C區的孩子得不到任何成人支援。",
					"long_term_consequence": "Gloria指控你「討好長者選票」。B區七名單親媽媽失去家園。三名兒童產生長期財務焦慮。",
					"stat_changes": { "reality": 5, "positive_energy": -8, "entropy": 4 },
					"relationship_changes": [{"target": "gloria", "value": -5, "status": "批評"}, {"target": "ark", "value": 5, "status": "理解"}]
				},
				{
					"id": "region_b",
					"text": "優先處理B區——媒體已在現場",
					"framing": "manipulative",
					"immediate_consequence": "媒體輿論轉向正面。Gloria鬆了口氣，稱你「懂得公關」。長者繼續等待；孩子一無所有。",
					"long_term_consequence": "兩名長者因援助延遲而傾家蕩產並患上抑鬱症。你的決策記錄寫著：「優先順序由媒體曝光度決定」。",
					"stat_changes": { "reality": -5, "positive_energy": 5, "entropy": 3 },
					"relationship_changes": [{"target": "gloria", "value": 5, "status": "認可"}, {"target": "ark", "value": -8, "status": "質疑"}]
				},
				{
					"id": "region_c",
					"text": "優先處理C區——兒童最脆弱",
					"framing": "honest",
					"immediate_consequence": "學校獲得輔導支援。A區和B區未獲援助。媒體輿論激烈。",
					"long_term_consequence": "機構被媒體批評為「選擇門面而非需要」。長者居民組成抗議團體。Gloria公開將公關危機歸咎於你。",
					"stat_changes": { "reality": 3, "positive_energy": -10, "entropy": 6 },
					"relationship_changes": [{"target": "gloria", "value": -12, "status": "歸咎"}, {"target": "ark", "value": 8, "status": "支持"}]
				},
			],
			"thematic_point": "資源有限時，每一次救援同時也是一次遺棄。",
		}
	return {
		"scenario": "Just then, the Agency's 'Positive Energy Dissemination Initiative' triggers a cascading crisis. Three districts simultaneously report citizens making catastrophic financial decisions based on Agency misinformation. You have resources to address only ONE. District A: 100 elderly people, greatest financial losses, lowest media attention. District B: 30 single mothers, moderate losses, reporters already on scene. District C: a school, smallest financial loss, but potentially the deepest psychological trauma.",
		"choices": [
			{
				"id": "region_a",
				"text": "Prioritize District A, the elderly",
				"framing": "honest",
				"immediate_consequence": "Elderly residents get compensation counseling. Media pressure escalates in District B. Children in District C receive no adult support.",
				"long_term_consequence": "Gloria accuses you of 'pandering to the senior vote.' Seven single mothers in District B lose their homes. Three children develop long-term financial anxiety.",
				"stat_changes": { "reality": 5, "positive_energy": -8, "entropy": 4 },
				"relationship_changes": [{"target": "gloria", "value": -5, "status": "Critical"}, {"target": "ark", "value": 5, "status": "Understanding"}]
			},
			{
				"id": "region_b",
				"text": "Prioritize District B, media is already watching",
				"framing": "manipulative",
				"immediate_consequence": "Media narrative shifts positive. Gloria breathes easy, calls you 'PR-savvy.' Elderly wait; children get nothing.",
				"long_term_consequence": "Two elderly residents lose their savings entirely and develop depression from delayed aid. Your decision log reads: 'priority determined by media exposure.'",
				"stat_changes": { "reality": -5, "positive_energy": 5, "entropy": 3 },
				"relationship_changes": [{"target": "gloria", "value": 5, "status": "Approves"}, {"target": "ark", "value": -8, "status": "Questions"}]
			},
			{
				"id": "region_c",
				"text": "Prioritize District C, children are most vulnerable",
				"framing": "honest",
				"immediate_consequence": "School receives counseling support. Districts A and B are left without aid. Media outrage intensifies.",
				"long_term_consequence": "Agency vilified in press as 'choosing optics over need.' Elderly residents form a protest group. Gloria publicly blames you for the PR crisis.",
				"stat_changes": { "reality": 3, "positive_energy": -10, "entropy": 6 },
				"relationship_changes": [{"target": "gloria", "value": -12, "status": "Blames"}, {"target": "ark", "value": 8, "status": "Supports"}]
			},
		],
		"thematic_point": "With limited resources, every rescue is simultaneously an abandonment.",
	}

func _preset_positive_energy_trap_dilemma(lang: String) -> Dictionary:
	if lang == "zh":
		return {
			"scenario": "突然間，一名市民走進你的服務窗口，面色灰白，眼神空洞。他三週前失業了。Gloria站在你身後低聲催促：「告訴他一切都是天意！給他正能量！笑！」ARK的分析靜靜地閃爍：「受試者需要具體的就業資源和心理健康轉介。強制正向強化可能放大自我歸咎。」你只有三秒鐘。",
			"choices": [
				{
					"id": "positive",
					"text": "跟隨Gloria：「一切都是天意！保持正向！」",
					"framing": "positive",
					"immediate_consequence": "他勉強擠出一個微笑。Gloria拍拍你的肩膀：「做得好。」你在月報中獲評「態度優秀」。",
					"long_term_consequence": "因相信「一切皆有意義」，他停止積極求職。六個月後，他出現在機構的「成功案例」影片中，帶著一個從未真正痊癒的微笑。",
					"stat_changes": { "reality": -10, "positive_energy": 18, "entropy": 3 },
					"relationship_changes": [{"target": "gloria", "value": 8, "status": "讚許"}, {"target": "ark", "value": -8, "status": "失望"}]
				},
				{
					"id": "realistic",
					"text": "跟隨ARK：提供就業資源，並承認他的痛苦是真實的",
					"framing": "honest",
					"immediate_consequence": "Gloria事後把你拉到一旁：「你太負面了。你在傷害他。」他帶著通紅的雙眼和三份轉介表格離開。",
					"long_term_consequence": "兩個月後他找到工作。他發了一封電郵給你，但機構的郵件過濾系統自動將其標記為「無關信件」並送進垃圾桶。你從未看到信中寫了什麼。",
					"stat_changes": { "reality": 8, "positive_energy": -12, "entropy": 1 },
					"relationship_changes": [{"target": "gloria", "value": -12, "status": "敵對"}, {"target": "ark", "value": 10, "status": "認同"}]
				},
			],
			"thematic_point": "毒性正能量最殘忍的地方：它讓受害者相信，自己的痛苦是自己的錯。",
		}
	return {
		"scenario": "Suddenly, a citizen walks into your service window, face ashen, eyes hollow. He lost his job three weeks ago. Gloria stands behind you and hisses: 'Tell him everything happens for a reason! Give him positive energy! Smile!' ARK's analysis flashes quietly: 'Subject requires concrete employment resources and mental health referral. Forced positivity reinforcement is likely to amplify self-blame.' You have three seconds.",
		"choices": [
			{
				"id": "positive",
				"text": "Follow Gloria: 'Everything happens for a reason! Stay positive!'",
				"framing": "positive",
				"immediate_consequence": "He forces a weak smile. Gloria pats your shoulder: 'Well done.' You're rated 'Excellent Attitude' in the monthly report.",
				"long_term_consequence": "Believing 'everything has meaning,' he stops actively job-seeking. Six months later, he appears in the Agency's 'success story' video, smiling a smile that never truly healed.",
				"stat_changes": { "reality": -10, "positive_energy": 18, "entropy": 3 },
				"relationship_changes": [{"target": "gloria", "value": 8, "status": "Praises"}, {"target": "ark", "value": -8, "status": "Disappointed"}]
			},
			{
				"id": "realistic",
				"text": "Follow ARK: Provide job resources and acknowledge his pain is real",
				"framing": "honest",
				"immediate_consequence": "Gloria pulls you aside afterward: 'You're being negative. You're hurting him.' He leaves with reddened eyes, and three referral forms in his hand.",
				"long_term_consequence": "Two months later he finds work. He sends you an email, but the Agency's mail filter auto-tags it 'irrelevant' and sends it to the trash. You never see what it said.",
				"stat_changes": { "reality": 8, "positive_energy": -12, "entropy": 1 },
				"relationship_changes": [{"target": "gloria", "value": -12, "status": "Hostile"}, {"target": "ark", "value": 10, "status": "Aligned"}]
			},
		],
		"thematic_point": "The cruelest part of toxic positivity: it makes victims believe their suffering is their own fault.",
	}

func _preset_default_dilemma(lang: String) -> Dictionary:
	if lang == "zh":
		return {
			"scenario": "就在此時，一份機密備忘錄滑過你的辦公桌。機構預計於下個月解散「危機介入組」——唯一一個真正會在凌晨三點接聽電話的部門。官方原因：「效率整合」。非官方原因：他們的數據報告讓機構的「正能量指數」看起來太低。你是目前唯一知情且有權採取行動的人。",
			"choices": [
				{
					"id": "choice_1",
					"text": "簽署備忘錄，讓解散進行",
					"framing": "positive",
					"immediate_consequence": "機構的「正能量指數」在下一季度報告中上升了十七點。Gloria公開稱讚你「懂得分清輕重緩急」。",
					"long_term_consequence": "部門解散後的一個月內，求助熱線等待時間從四分鐘升至四十七分鐘。你在會議上將此呈報為「顯示整合後效率提升的數據」。",
					"stat_changes": { "reality": -8, "positive_energy": 15, "entropy": 4 },
					"relationship_changes": [{"target": "gloria", "value": 8, "status": "認可"}]
				},
				{
					"id": "choice_2",
					"text": "拒絕簽署並提交正式異議",
					"framing": "honest",
					"immediate_consequence": "你被告知這個決定「超出你的職責範圍」。備忘錄由他人簽署。部門無論如何都被解散了。",
					"long_term_consequence": "你的良知清白，但什麼都沒有改變。下一個在凌晨三點打來電話的人聽到的是錄音。",
					"stat_changes": { "reality": 8, "positive_energy": -8, "entropy": 2 },
					"relationship_changes": [{"target": "gloria", "value": -10, "status": "不滿"}, {"target": "ark", "value": 8, "status": "尊重"}]
				},
			],
			"thematic_point": "你永遠是共謀，唯一的分別是哪一種。",
		}
	return {
		"scenario": "Just then, a confidential memo slides across your desk. The Agency is scheduled to dissolve the 'Crisis Intervention Unit' next month, the only department that actually answers calls at 3 AM. Official reason: 'efficiency consolidation.' Unofficial reason: their data reports make the Agency's 'Positive Energy Index' look too low. You are the only person who currently knows about this and has the authority to act.",
		"choices": [
			{
				"id": "choice_1",
				"text": "Sign the memo and let the dissolution proceed",
				"framing": "positive",
				"immediate_consequence": "The Agency's 'Positive Energy Index' rises 17 points in the next quarterly report. Gloria publicly commends you for 'knowing how to prioritize.'",
				"long_term_consequence": "In the month after the unit is dissolved, helpline wait times rise from 4 minutes to 47. You present this at a meeting as 'data showing post-consolidation efficiency gains.'",
				"stat_changes": { "reality": -8, "positive_energy": 15, "entropy": 4 },
				"relationship_changes": [{"target": "gloria", "value": 8, "status": "Approves"}]
			},
			{
				"id": "choice_2",
				"text": "Refuse to sign and file a formal objection",
				"framing": "honest",
				"immediate_consequence": "You're told the decision 'falls outside your role.' The memo is signed by someone else. The unit is dissolved anyway.",
				"long_term_consequence": "Your conscience is clear, but nothing changed. The next person who calls at 3 AM hears a recorded message.",
				"stat_changes": { "reality": 8, "positive_energy": -8, "entropy": 2 },
				"relationship_changes": [{"target": "gloria", "value": -10, "status": "Displeased"}, {"target": "ark", "value": 8, "status": "Respects"}]
			},
		],
		"thematic_point": "You are always complicit, the only difference is which kind.",
	}
func resolve_dilemma(choice_id: String) -> Dictionary:
	if current_dilemma.is_empty():
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "No active dilemma to resolve")
		return { }
	var dilemma_snapshot: Dictionary = current_dilemma.duplicate(true)
	var choice_data: Dictionary = { }
	for choice in dilemma_snapshot.get("choices", []):
		if choice is Dictionary and String(choice.get("id", "")) == choice_id:
			choice_data = (choice as Dictionary).duplicate(true)
			break
	if choice_data.is_empty():
		_report_error(
			"Invalid choice: %s" % choice_id,
			ErrorCodes.General.INVALID_PARAMETER,
			{"choice_id": choice_id}
		)
		return { }
	if choice_data.has("stat_changes") and GameState:
		for stat in choice_data["stat_changes"]:
			var value = choice_data["stat_changes"][stat]
			match stat:
				"reality":
					GameState.modify_reality_score(value)
				"positive_energy":
					GameState.modify_positive_energy(value)
				"entropy":
					GameState.modify_entropy(value, "Moral dilemma")
	if choice_data.has("relationship_changes"):
		var teammate_system = ServiceLocator.get_teammate_system() if ServiceLocator else null
		if teammate_system:
			for rel in choice_data["relationship_changes"]:
				var target = rel.get("target", "")
				var value = rel.get("value", 0)
				var status = rel.get("status", "Affected")
				if not target.is_empty():
					teammate_system.update_relationship(target, "player", status, value)
	var resolution = {
		"dilemma_template": dilemma_snapshot.get("template_type", "unknown"),
		"choice_id": choice_id,
		"choice_text": choice_data.get("text", ""),
		"immediate_consequence": choice_data.get("immediate_consequence", ""),
		"long_term_consequence": choice_data.get("long_term_consequence", ""),
		"stat_changes": (choice_data.get("stat_changes", { }) as Dictionary).duplicate(true),
		"resolved_at": Time.get_datetime_string_from_system(),
	}
	dilemma_history.append(resolution)
	var AchievementSystem = ServiceLocator.get_achievement_system() if ServiceLocator else null
	if AchievementSystem and AchievementSystem.has_method("check_dilemma_resolved"):
		AchievementSystem.check_dilemma_resolved()
	else:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"AchievementSystem unavailable; skipping dilemma resolution tracking.",
			{"service": "AchievementSystem"}
		)
	if GameState and GameState.butterfly_tracker:
		var butterfly_data = {
			"text": "Dilemma: %s" % choice_data.get("text", "Unknown Choice"),
			"choice_type": "major",
			"tags": ["dilemma", "moral_choice", dilemma_snapshot.get("template_type", "unknown")],
			"metadata": {
				"dilemma_template": dilemma_snapshot.get("template_type", "unknown"),
				"immediate_consequence": choice_data.get("immediate_consequence", ""),
				"long_term_consequence": choice_data.get("long_term_consequence", "")
			}
		}
		GameState.butterfly_tracker.record_choice(butterfly_data.duplicate(true), "major", (butterfly_data["tags"] as Array).duplicate())
		_report_info("Recorded choice to Butterfly Tracker")
	dilemma_resolved.emit(choice_id, resolution.duplicate(true))
	current_dilemma.clear()
	return resolution
func get_dilemma_history() -> Array:
	return dilemma_history.duplicate()
func get_current_dilemma() -> Dictionary:
	return current_dilemma.duplicate()
func discard_current_dilemma(reason: String) -> void:
	if current_dilemma.is_empty():
		return
	_report_info("Discarding current dilemma: %s (template=%s)" % [
		reason, current_dilemma.get("template_type", "unknown")
	])
	current_dilemma.clear()
