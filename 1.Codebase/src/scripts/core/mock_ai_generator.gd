extends RefCounted
class_name MockAIGenerator
const MissionScenarioLibrary := preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
const GameConstants := preload("res://1.Codebase/src/scripts/core/game_constants.gd")
static var _rng := RandomNumberGenerator.new()
static var _seeded := false
static var _consequence_call_count: int = 0
static var _night_set_index: int = 0
static var _current_scenario: Dictionary = {}
static func _ensure_rng() -> void:
	if not _seeded:
		_rng.randomize()
		_seeded = true
func generate_mock_mission_response(prompt: String, language: String = "en") -> String:
	return generate_response(prompt, {"purpose": "mission", "language": language})
func generate_mock_disaster_response(prompt: String, language: String = "en") -> String:
	return generate_response(prompt, {"purpose": "prayer", "language": language})
func _extract_scene_directives(response: String) -> Dictionary:
	var story_text := response
	var directives := {}
	var start := response.find("[SCENE_DIRECTIVES]")
	var end_pos := response.find("[/SCENE_DIRECTIVES]")
	if start != -1 and end_pos != -1 and end_pos > start:
		story_text = response.substr(0, start) + response.substr(end_pos + "[/SCENE_DIRECTIVES]".length())
		var block = response.substr(start + "[SCENE_DIRECTIVES]".length(), end_pos - start - "[SCENE_DIRECTIVES]".length())
		for line in block.split("\n"):
			line = line.strip_edges()
			if ":" in line:
				var parts = line.split(":", false, 1)
				if parts.size() > 1:
					directives[parts[0].strip_edges().to_lower()] = parts[1].strip_edges()
	return {"story_text": story_text.strip_edges(), "directives": directives}
static func generate_response(prompt: String, context: Dictionary) -> String:
	_ensure_rng()
	var purpose: String = ""
	if context.has("purpose"):
		purpose = str(context["purpose"]).to_lower()
	if purpose.is_empty():
		purpose = _infer_purpose(prompt.to_lower())
	match purpose:
		"mission", "new_mission", "mission_generation", "story", "intro_story":
			return _generate_mission(context)
		"choice_followup":
			return _generate_choice_followup(context)
		"consequence":
			return _generate_consequence(context)
		"prayer", "prayer_result", "prayer_consequence":
			return _generate_prayer(context)
		"interference", "teammate_interference":
			return _generate_interference(context)
		"gloria_intervention":
			return _generate_gloria_intervention(context)
		"trolley_problem":
			return _generate_trolley_problem(context)
		"night_cycle":
			return _generate_night_cycle(context)
		"journal_story_summary", "journal_summary", "journal_prompt":
			return _generate_journal_summary(context)
		"test":
			return _generate_test_response()
		_:
			return _generate_generic()
static func _infer_purpose(prompt_lower: String) -> String:
	if "night cycle" in prompt_lower:
		return "night_cycle"
	if "prayer" in prompt_lower or "my prayer" in prompt_lower:
		return "prayer"
	if "choice summary follow-up" in prompt_lower or "choice follow-up" in prompt_lower:
		return "choice_followup"
	if "interference" in prompt_lower or "teammate" in prompt_lower:
		return "interference"
	if "mission" in prompt_lower or "objective" in prompt_lower:
		return "mission"
	if "consequence" in prompt_lower or "result" in prompt_lower:
		return "consequence"
	return "generic"
static func _generate_mission(context: Dictionary) -> String:
	_ensure_rng()
	var story_text := ""
	_current_scenario = {}
	if MissionScenarioLibrary.has_scenarios():
		var cycles_before: int = MissionScenarioLibrary.get_cycles_completed()
		var scenario := MissionScenarioLibrary.get_random_scenario()
		if MissionScenarioLibrary.get_cycles_completed() > cycles_before:
			_show_simulation_loop_notification(_resolve_language(context))
		if scenario.size() > 0:
			_current_scenario = scenario
			story_text = _format_library_scenario(scenario, context)
	if story_text.is_empty():
		story_text = _build_random_story(context)
	return JSON.stringify(_build_mission_response(story_text, context))
static func _build_mission_response(story_text: String, context: Dictionary) -> Dictionary:
	_ensure_rng()
	var backgrounds: Array[String] = [
		"ruins",
		"cave",
		"dungeon",
		"forest",
		"temple",
		"laboratory",
		"library",
		"throne_room",
		"battlefield",
		"crystal_cavern",
		"bridge",
		"garden",
		"portal_area",
		"safe_zone",
		"water",
		"fire_area",
	]
	var background: String = backgrounds[_rng.randi_range(0, backgrounds.size() - 1)]
	var expressions: Array[String] = ["neutral", "happy", "sad", "angry", "confused", "shocked", "thinking", "embarrassed"]
	var lang := _resolve_language(context)
	var choices: Array[Dictionary] = _build_choice_followup_payload(lang)
	var preview_lines: Array[String] = _build_choice_preview_lines(choices, lang)
	var story_with_preview := story_text
	if not preview_lines.is_empty():
		story_with_preview += "\n\n" + "\n".join(preview_lines)
	var response := {
		"mission_title": _pick(
			[
				"Operation Mandatory Smile",
				"Project Glitter Leak",
				"The Department of Forced Hope",
				"Entropy Compliance Audit",
				"Enthusiasm Containment Protocol",
				"Operation Compliance Rainbow",
				"Emergency Optimism Surge",
				"Mandatory Wonder Deployment",
			],
		),
		"scene": {
			"background": background,
			"atmosphere": _pick(["tense", "calm", "mysterious", "chaotic"]),
			"lighting": _pick(["normal", "dim", "bright"]),
		},
		"characters": {
			"protagonist": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"gloria": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"donkey": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"ark": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"one": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
		},
		"story_text": story_with_preview,
		"choices": choices,
	}
	return response
static func _format_library_scenario(scenario: Dictionary, context: Dictionary) -> String:
	if scenario.is_empty():
		return ""
	var lang: String = MissionScenarioLibrary._resolve_language(context)
	var keys: Dictionary = scenario.get("translation_keys", {}) as Dictionary
	var fallback: Dictionary = scenario.get("fallback", {}) as Dictionary
	var lines: Array[String] = []
	var title: String = MissionScenarioLibrary._get_localized_text(keys.get("title", ""), fallback.get("title", "Unnamed Operation"), lang)
	lines.append("**Mission Codename: %s**" % title)
	var description: String = MissionScenarioLibrary._get_localized_text(keys.get("description", ""), fallback.get("description", ""), lang)
	if not description.is_empty():
		lines.append(description)
	lines.append("")
	var objective: String = MissionScenarioLibrary._get_localized_text(keys.get("objective", ""), fallback.get("objective", "Objective not provided."), lang)
	lines.append("Mission Objective: %s" % objective)
	var assets: Array = scenario.get("assets", []) as Array
	if assets is Array and not assets.is_empty():
		var asset_names: Array[String] = []
		for asset in assets:
			asset_names.append(str(asset))
		lines.append("Assets: %s" % ", ".join(asset_names))
	var complication: String = MissionScenarioLibrary._get_localized_text(keys.get("complication", ""), fallback.get("complication", ""), lang)
	if not complication.is_empty():
		lines.append("Complication: %s" % complication)
	var choices: Array[String] = MissionScenarioLibrary._get_choice_list(scenario, lang)
	if choices.size() > 0:
		lines.append("")
		lines.append("Choices (all escalate entropy):")
		for choice_text in choices:
			lines.append("- %s" % choice_text)
	lines.append("")
	lines.append("Status monitor: %s" % _build_status_line(context))
	lines.append("Reminder: the harder you try, the faster the world burns.")
	return "\n".join(lines)
static func _build_status_line(context: Dictionary) -> String:
	var ctx: Dictionary = {}
	if context:
		ctx = context
	var reality: int = _context_stat(ctx, "reality_score", GameConstants.Stats.INITIAL_REALITY_SCORE)
	var positive: int = _context_stat(ctx, "positive_energy", GameConstants.Stats.INITIAL_POSITIVE_ENERGY)
	var entropy: int = _context_stat(ctx, "entropy_level", GameConstants.Stats.INITIAL_ENTROPY)
	return "Reality %d/100 | Positive Energy %d/100 | Entropy %d" % [reality, positive, entropy]
static func _build_random_story(context: Dictionary) -> String:
	var lang := _resolve_language(context)
	var status: String = _build_status_line(context)
	var title: String = _get_translation(_pick(["MOCK_STORY_TITLE_1", "MOCK_STORY_TITLE_2", "MOCK_STORY_TITLE_3", "MOCK_STORY_TITLE_4", "MOCK_STORY_TITLE_5", "MOCK_STORY_TITLE_6", "MOCK_STORY_TITLE_7", "MOCK_STORY_TITLE_8"]), lang)
	var setup: String = _get_translation(_pick(["MOCK_STORY_SETUP_1", "MOCK_STORY_SETUP_2", "MOCK_STORY_SETUP_3", "MOCK_STORY_SETUP_4", "MOCK_STORY_SETUP_5", "MOCK_STORY_SETUP_6", "MOCK_STORY_SETUP_7", "MOCK_STORY_SETUP_8"]), lang)
	var context_detail: String = _get_translation(_pick(["MOCK_STORY_CONTEXT_1", "MOCK_STORY_CONTEXT_2", "MOCK_STORY_CONTEXT_3", "MOCK_STORY_CONTEXT_4", "MOCK_STORY_CONTEXT_5", "MOCK_STORY_CONTEXT_6", "MOCK_STORY_CONTEXT_7", "MOCK_STORY_CONTEXT_8"]), lang)
	var twist: String = _get_translation(_pick(["MOCK_STORY_TWIST_1", "MOCK_STORY_TWIST_2", "MOCK_STORY_TWIST_3", "MOCK_STORY_TWIST_4", "MOCK_STORY_TWIST_5", "MOCK_STORY_TWIST_6", "MOCK_STORY_TWIST_7", "MOCK_STORY_TWIST_8"]), lang)
	var goal: String = _get_translation(_pick(["MOCK_STORY_GOAL_1", "MOCK_STORY_GOAL_2", "MOCK_STORY_GOAL_3", "MOCK_STORY_GOAL_4", "MOCK_STORY_GOAL_5", "MOCK_STORY_GOAL_6", "MOCK_STORY_GOAL_7", "MOCK_STORY_GOAL_8"]), lang)
	var context_label: String = _get_translation("MOCK_STORY_CONTEXT_LABEL", lang)
	var objective_label: String = _get_translation("MOCK_STORY_OBJECTIVE_LABEL", lang)
	var complication_label: String = _get_translation("MOCK_STORY_COMPLICATION_LABEL", lang)
	var status_label: String = _get_translation("MOCK_STORY_STATUS_LABEL", lang)
	var reminder: String = _get_translation("MOCK_STORY_REMINDER", lang)
	var story_lines: Array = []
	story_lines.append("**Mission Codename: %s**" % title)
	story_lines.append(setup)
	story_lines.append("%s %s" % [context_label, context_detail])
	story_lines.append("%s %s" % [objective_label, goal])
	story_lines.append("%s %s" % [complication_label, twist])
	story_lines.append("")
	story_lines.append("%s %s" % [status_label, status])
	story_lines.append(reminder)
	return "\n".join(story_lines)
static func _generate_consequence(context: Dictionary) -> String:
	_ensure_rng()
	_consequence_call_count += 1
	var lang := _resolve_language(context)
	var choice_dict = context.get("choice", {})
	var choice_text: String = "that choice"
	if choice_dict is Dictionary:
		choice_text = str(choice_dict.get("text", "that choice"))
	var success: bool = bool(context.get("success", false))
	var reality_score: int = _context_stat(context, "reality_score", 50)
	var entropy_level: int = _context_stat(context, "entropy_level", 0)
	var offset: int = _consequence_call_count % 100
	var story_lines: Array = []
	var scenario_consequence := _get_scenario_consequence(success, offset)
	if not scenario_consequence.is_empty():
		story_lines.append(scenario_consequence)
		var teammate_label: String = _get_translation("MOCK_CONSEQUENCE_TEAMMATE_LABEL", lang)
		var sabotage: Array[String] = [
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_1", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_2", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_3", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_4", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_5", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_6", lang),
		]
		var sabotage_idx: int = (offset + 1) % sabotage.size()
		story_lines.append("%s %s" % [teammate_label, sabotage[sabotage_idx]])
	else:
		var opening: String = _get_translation("MOCK_CONSEQUENCE_OPENING_SUCCESS", lang) if success else _get_translation("MOCK_CONSEQUENCE_OPENING_FAIL", lang)
		var reactions_success: Array[String] = [
			_get_translation("MOCK_CONSEQUENCE_REACT_SUCCESS_1", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_SUCCESS_2", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_SUCCESS_3", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_SUCCESS_4", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_SUCCESS_5", lang),
		]
		var reactions_fail: Array[String] = [
			_get_translation("MOCK_CONSEQUENCE_REACT_FAIL_1", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_FAIL_2", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_FAIL_3", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_FAIL_4", lang),
			_get_translation("MOCK_CONSEQUENCE_REACT_FAIL_5", lang),
		]
		var sabotage: Array[String] = [
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_1", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_2", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_3", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_4", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_5", lang),
			_get_translation("MOCK_CONSEQUENCE_SABOTAGE_6", lang),
		]
		var nudges: Array[String] = [
			_get_translation("MOCK_CONSEQUENCE_NUDGE_1", lang),
			_get_translation("MOCK_CONSEQUENCE_NUDGE_2", lang),
			_get_translation("MOCK_CONSEQUENCE_NUDGE_3", lang),
			_get_translation("MOCK_CONSEQUENCE_NUDGE_4", lang),
			_get_translation("MOCK_CONSEQUENCE_NUDGE_5", lang),
		]
		var teammate_label: String = _get_translation("MOCK_CONSEQUENCE_TEAMMATE_LABEL", lang)
		var reactions: Array[String] = reactions_success if success else reactions_fail
		var reaction_idx: int = (offset) % reactions.size()
		var sabotage_idx: int = (offset + 1) % sabotage.size()
		var nudge_idx: int = (offset + 2) % nudges.size()
		story_lines.append("%s: %s" % [opening, choice_text])
		story_lines.append(reactions[reaction_idx])
		story_lines.append("%s %s" % [teammate_label, sabotage[sabotage_idx]])
		story_lines.append(nudges[nudge_idx])
	if lang == "en":
		if reality_score < 30:
			story_lines.append("(Reality is fraying — this choice leaves deeper marks than expected.)")
		elif entropy_level > 60:
			story_lines.append("(The void entropy spikes. Your action ripples outward in unexpected ways.)")
	else:
		if reality_score < 30:
			story_lines.append("（現實正在崩潰——這個選擇留下了比預期更深的印記。）")
		elif entropy_level > 60:
			story_lines.append("（虛空熵值飆升。你的行動以意想不到的方式向外擴散。）")
	var story_text = "\n".join(story_lines)
	var expressions = ["neutral", "happy", "sad", "angry", "confused", "shocked", "thinking", "embarrassed"]
	var choices: Array[Dictionary] = _build_choice_followup_payload(lang)
	var response = {
		"characters": {
			"protagonist": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"gloria": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"donkey": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"ark": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"one": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
		},
		"story_text": story_text,
		"choices": choices,
	}
	return JSON.stringify(response)
static func _get_scenario_consequence(success: bool, offset: int) -> String:
	if _current_scenario.is_empty():
		return ""
	var fallback: Dictionary = _current_scenario.get("fallback", {}) as Dictionary
	var pool_key: String = "consequence_success" if success else "consequence_fail"
	var pool: Array = fallback.get(pool_key, []) as Array
	if pool.is_empty():
		return ""
	var idx: int = offset % pool.size()
	return str(pool[idx])
static func _generate_prayer(context: Dictionary) -> String:
	var lang := _resolve_language(context)
	var prayer_text: String = str(context.get("prayer_text", "We believe in sunshine."))
	var reality_score: int = _context_stat(context, "reality_score", GameConstants.Stats.INITIAL_REALITY_SCORE)
	var backlash: String = _get_translation(_pick(["MOCK_PRAYER_BACKLASH_1", "MOCK_PRAYER_BACKLASH_2", "MOCK_PRAYER_BACKLASH_3", "MOCK_PRAYER_BACKLASH_4", "MOCK_PRAYER_BACKLASH_5", "MOCK_PRAYER_BACKLASH_6"]), lang)
	var clarity_line: String = _get_translation("MOCK_PRAYER_CLARITY_LOW", lang) if reality_score < GameConstants.UI.STAT_COLOR_MEDIUM_THRESHOLD else _get_translation("MOCK_PRAYER_CLARITY_HIGH", lang)
	var whisper_prefix: String = _get_translation("MOCK_PRAYER_WHISPER_PREFIX", lang) % prayer_text
	var fsm_prefix: String = _get_translation("MOCK_PRAYER_FSM_PREFIX", lang) % backlash
	var entropy_line: String = _get_translation("MOCK_PRAYER_ENTROPY_LINE", lang)
	var lines: Array = []
	lines.append(whisper_prefix)
	lines.append(fsm_prefix)
	lines.append(clarity_line)
	lines.append(entropy_line)
	return "\n".join(lines)
static func _generate_interference(context: Dictionary) -> String:
	var lang := _resolve_language(context)
	var teammate: String = str(context.get("teammate_id", context.get("teammate", "gloria"))).to_lower()
	var player_action: String = str(context.get("action", context.get("player_action", "your sensible attempt")))
	match teammate:
		"gloria":
			return _get_translation("MOCK_INTERFERENCE_GLORIA", lang) % player_action
		"donkey":
			return _get_translation("MOCK_INTERFERENCE_DONKEY", lang) % player_action
		"ark":
			return _get_translation("MOCK_INTERFERENCE_ARK", lang)
		"one":
			return _get_translation("MOCK_INTERFERENCE_ONE", lang)
		_:
			return _get_translation("MOCK_INTERFERENCE_DEFAULT", lang)
static func _generate_gloria_intervention(context: Dictionary) -> String:
	var lang := _resolve_language(context)
	var choice_text := "your last decision"
	var choice_variant = context.get("choice", null)
	if choice_variant is Dictionary:
		choice_text = String((choice_variant as Dictionary).get("text", choice_text)).strip_edges()
	var speech: String = _get_translation("MOCK_GLORIA_INTERVENTION_SPEECH", lang) % choice_text
	return JSON.stringify(
		{
			"speech": speech,
		},
	)
static func _generate_choice_followup(context: Dictionary) -> String:
	var lang := _resolve_language(context)
	var payload := {
		"choices": _build_choice_followup_payload(lang),
	}
	return JSON.stringify(payload)
static func _generate_night_cycle(context: Dictionary) -> String:
	_current_scenario = {}
	var lang := _resolve_language(context)
	var last_text := String(context.get("last_text", "")).strip_edges()
	if last_text.length() > 240:
		last_text = last_text.substr(0, 240) + "..."
	var reflection: String = _get_translation("MOCK_NIGHT_REFLECTION", lang) % last_text
	var teacher: String = _get_translation("MOCK_NIGHT_TEACHER", lang)
	var honeymoon: String = _get_translation("MOCK_NIGHT_HONEYMOON", lang)
	var prayer_prompt: String = _get_translation("MOCK_NIGHT_PRAYER_PROMPT", lang)
	var set_a: Array[String] = [
		_get_translation("MOCK_NIGHT_LYRICS_1", lang),
		_get_translation("MOCK_NIGHT_LYRICS_2", lang),
		_get_translation("MOCK_NIGHT_LYRICS_3", lang),
		_get_translation("MOCK_NIGHT_LYRICS_4", lang),
	]
	var set_b: Array[String] = [
		_get_translation("MOCK_NIGHT_LYRICS_5", lang),
		_get_translation("MOCK_NIGHT_LYRICS_6", lang),
		_get_translation("MOCK_NIGHT_LYRICS_7", lang),
		_get_translation("MOCK_NIGHT_LYRICS_8", lang),
	]
	var lyrics: Array[String] = set_a if (_night_set_index % 2 == 0) else set_b
	_night_set_index += 1
	return JSON.stringify(
		{
			"reflection_text": reflection,
			"teacher_chan_text": teacher,
			"concert_lyrics": lyrics,
			"honeymoon_text": honeymoon,
			"prayer_prompt": prayer_prompt,
		},
	)
static func _generate_journal_summary(context: Dictionary) -> String:
	var lang := _resolve_language(context)
	var source := String(context.get("story_text", context.get("last_text", ""))).strip_edges()
	if source.length() > 120:
		source = source.substr(0, 120) + "..."
	if source.is_empty():
		return _get_translation("MOCK_JOURNAL_EMPTY", lang)
	return _get_translation("MOCK_JOURNAL_WITH_SOURCE", lang) % source
static func _generate_test_response() -> String:
	return "Offline mock response: systems ready to embrace your forced optimism."
static func _resolve_language(context: Dictionary) -> String:
	if context.has("language"):
		var lang_value := String(context.get("language", "")).strip_edges().to_lower()
		if lang_value == "zh":
			return "zh"
		if not lang_value.is_empty():
			return "en"
	return _get_current_language()
static func _build_choice_followup_payload(lang: String) -> Array[Dictionary]:
	if not _current_scenario.is_empty():
		var fallback: Dictionary = _current_scenario.get("fallback", {}) as Dictionary
		var scenario_choices: Array = fallback.get("followup_choices", []) as Array
		if scenario_choices.size() >= 5:
			var result: Array[Dictionary] = []
			for entry in scenario_choices:
				if entry is Dictionary:
					result.append(entry as Dictionary)
			if result.size() >= 5:
				return result
	return [
		{ "archetype": "cautious", "summary": _get_translation("MOCK_CHOICE_CAUTIOUS", lang) },
		{ "archetype": "balanced", "summary": _get_translation("MOCK_CHOICE_BALANCED", lang) },
		{ "archetype": "reckless", "summary": _get_translation("MOCK_CHOICE_RECKLESS", lang) },
		{ "archetype": "positive", "summary": _get_translation("MOCK_CHOICE_POSITIVE", lang) },
		{ "archetype": "complain", "summary": _get_translation("MOCK_CHOICE_COMPLAIN", lang) },
	]
static func _build_choice_preview_lines(choices: Array[Dictionary], lang: String) -> Array[String]:
	var labels := {
		"cautious": _get_translation("MOCK_LABEL_CAUTIOUS", lang),
		"balanced": _get_translation("MOCK_LABEL_BALANCED", lang),
		"reckless": _get_translation("MOCK_LABEL_RECKLESS", lang),
		"positive": _get_translation("MOCK_LABEL_POSITIVE", lang),
		"complain": _get_translation("MOCK_LABEL_COMPLAIN", lang),
	}
	var lines: Array[String] = []
	for entry in choices:
		if not (entry is Dictionary):
			continue
		var archetype := String((entry as Dictionary).get("archetype", "")).to_lower()
		var summary := String((entry as Dictionary).get("summary", "")).strip_edges()
		if archetype.is_empty() or summary.is_empty():
			continue
		var label := String(labels.get(archetype, "[Choice]"))
		lines.append("%s %s" % [label, summary])
	return lines
static func _generate_trolley_problem(context: Dictionary) -> String:
	var lang := _resolve_language(context)
	var template: String = str(context.get("template", ""))
	if lang == "zh":
		match template:
			"sacrifice", "complicity", "lesser_evil":
				pass
			_:
				template = "positive_energy_trap"
		var dilemma := {
			"scenario": "突然間，一名市民走進你的服務窗口，面色灰白，眼神空洞。他三週前失業了。Gloria站在你身後低聲催促：「告訴他一切都是天意！給他正能量！笑！」ARK的分析靜靜地閃爍：「受試者需要具體的就業資源和心理健康轉介。強制正向強化可能放大自我歸咎。」你只有三秒鐘。",
			"choices": [
				{
					"id": "positive",
					"text": "跟隨Gloria：「一切都是天意！保持正向！」",
					"framing": "positive",
					"immediate_consequence": "他勉強擠出一個微笑。Gloria拍拍你的肩膀：「做得好。」",
					"long_term_consequence": "因相信「一切皆有意義」，他停止積極求職。六個月後，他出現在機構的「成功案例」影片裡帶著從未真正痊癒的微笑。",
					"stat_changes": {"reality": -10, "positive_energy": 18, "entropy": 3},
					"relationship_changes": [{"target": "gloria", "value": 8, "status": "讚許"}, {"target": "ark", "value": -8, "status": "失望"}]
				},
				{
					"id": "realistic",
					"text": "跟隨ARK：提供就業資源，並承認他的痛苦是真實的",
					"framing": "honest",
					"immediate_consequence": "Gloria事後把你拉到一旁：「你太負面了。你在傷害他。」他帶著通紅的雙眼和三份轉介表格離開。",
					"long_term_consequence": "兩個月後他找到工作。他發了一封電郵給你，但機構的郵件過濾系統自動將其標記為「無關信件」並送進垃圾桶。",
					"stat_changes": {"reality": 8, "positive_energy": -12, "entropy": 1},
					"relationship_changes": [{"target": "gloria", "value": -12, "status": "敵對"}, {"target": "ark", "value": 10, "status": "認同"}]
				},
			],
			"thematic_point": "毒性正能量最殘忍的地方：它讓受害者相信，自己的痛苦是自己的錯。",
		}
		return JSON.stringify(dilemma)
	else:
		var dilemma := {
			"scenario": "Suddenly, a citizen walks into your service window, face ashen, eyes hollow. He lost his job three weeks ago. Gloria stands behind you and hisses: 'Tell him everything happens for a reason! Give him positive energy! Smile!' ARK's analysis flashes quietly: 'Subject requires concrete employment resources and mental health referral. Forced positivity reinforcement is likely to amplify self-blame.' You have three seconds.",
			"choices": [
				{
					"id": "positive",
					"text": "Follow Gloria: 'Everything happens for a reason! Stay positive!'",
					"framing": "positive",
					"immediate_consequence": "He forces a weak smile. Gloria pats your shoulder: 'Well done.' You're rated 'Excellent Attitude' in the monthly report.",
					"long_term_consequence": "Believing 'everything has meaning,' he stops actively job-seeking. Six months later, he appears in the Agency's 'success story' video, smiling a smile that never truly healed.",
					"stat_changes": {"reality": -10, "positive_energy": 18, "entropy": 3},
					"relationship_changes": [{"target": "gloria", "value": 8, "status": "Praises"}, {"target": "ark", "value": -8, "status": "Disappointed"}]
				},
				{
					"id": "realistic",
					"text": "Follow ARK: Provide job resources and acknowledge his pain is real",
					"framing": "honest",
					"immediate_consequence": "Gloria pulls you aside afterward: 'You're being negative. You're hurting him.' He leaves with reddened eyes, and three referral forms in his hand.",
					"long_term_consequence": "Two months later he finds work. He sends you an email, but the Agency's mail filter auto-tags it 'irrelevant' and sends it to trash. You never see what it said.",
					"stat_changes": {"reality": 8, "positive_energy": -12, "entropy": 1},
					"relationship_changes": [{"target": "gloria", "value": -12, "status": "Hostile"}, {"target": "ark", "value": 10, "status": "Aligned"}]
				},
			],
			"thematic_point": "The cruelest part of toxic positivity: it makes victims believe their suffering is their own fault.",
		}
		return JSON.stringify(dilemma)
static func _generate_generic() -> String:
	var lang := _get_current_language()
	var filler_keys := ["AI_OFFLINE_FILLER_1", "AI_OFFLINE_FILLER_2", "AI_OFFLINE_FILLER_3", "AI_OFFLINE_FILLER_4", "AI_OFFLINE_FILLER_5"]
	var filler_key := _pick(filler_keys)
	var filler := _get_translation(filler_key, lang)
	if filler == filler_key or filler.is_empty():
		filler = _pick(
			[
				"The cosmos enjoys how you polish despair until it shines.",
				"Positive energy behaves like spam email: once subscribed, never gone.",
				"Every desperate effort is fuel for the entropy furnace.",
				"Optimism is the only renewable resource that generates more suffering the more efficiently you harvest it.",
				"You called it resilience. The entropy monitor called it data. The cosmos has filed it under both.",
			]
		)
	var prefix := _get_translation("AI_OFFLINE_PREFIX", lang)
	if prefix == "AI_OFFLINE_PREFIX" or prefix.is_empty():
		prefix = "AI service offline. Local narrative module says:"
	return "%s %s" % [prefix, filler]
static func _show_simulation_loop_notification(lang: String) -> void:
	var locator := _get_service_locator()
	if locator == null:
		return
	var notif_sys = locator.call("get_notification_system")
	if notif_sys == null or not is_instance_valid(notif_sys):
		return
	var title: String = _get_translation("MOCK_SIM_LOOP_TITLE", lang)
	var desc: String = _get_translation("MOCK_SIM_LOOP_DESC", lang)
	notif_sys.call("show_info", title, desc)
static func _get_current_language() -> String:
	var game_state := _get_game_state()
	if game_state and "current_language" in game_state:
		var lang = game_state.get("current_language")
		if typeof(lang) == TYPE_STRING and not lang.is_empty():
			return lang
	return "en"
static func _get_translation(key: String, language: String) -> String:
	var locator := _get_service_locator()
	if locator == null or not locator.has_method("get_localization_manager"):
		return key
	var loc_manager = locator.call("get_localization_manager")
	if loc_manager == null or not loc_manager.has_method("get_translation"):
		return key
	return loc_manager.get_translation(key, language)
static func _pick(options: Array) -> String:
	_ensure_rng()
	if options.is_empty():
		return ""
	return String(options[_rng.randi_range(0, options.size() - 1)])
static func _get_game_state() -> Node:
	var locator := _get_service_locator()
	if locator == null or not locator.has_method("get_game_state"):
		return null
	var game_state: Node = locator.call("get_game_state")
	return game_state if is_instance_valid(game_state) else null
static func _get_service_locator() -> Node:
	if typeof(ServiceLocator) != TYPE_NIL and ServiceLocator != null and is_instance_valid(ServiceLocator):
		return ServiceLocator
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		var root := (tree as SceneTree).root
		if root:
			var locator := root.get_node_or_null("ServiceLocator")
			if locator:
				return locator
	return null
static func _context_stat(context: Dictionary, key: String, fallback: int) -> int:
	if context.has(key):
		return int(context[key])
	var game_state := _get_game_state()
	if game_state:
		var value = game_state.get(key)
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			return int(value)
	return fallback
