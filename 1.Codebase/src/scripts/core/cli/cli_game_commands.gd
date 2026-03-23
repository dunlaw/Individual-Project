class_name CLIGameCommands
extends RefCounted
var _parser: CLICommandParser
func _init(parser: CLICommandParser) -> void:
	_parser = parser
func handle_status(game_state: Node, json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "status"):
		return 1
	var player_stats: Dictionary = { }
	if game_state.has_method("get"):
		var raw_stats: Variant = game_state.get("player_stats")
		if raw_stats is Dictionary:
			player_stats = (raw_stats as Dictionary).duplicate(true)
	var payload := {
		"ok": true,
		"command": "status",
		"language": String(game_state.get("current_language") if game_state.has_method("get") else "en"),
		"current_mission": int(game_state.get("current_mission") if game_state.has_method("get") else 0),
		"missions_completed": int(game_state.get("missions_completed") if game_state.has_method("get") else 0),
		"reality_score": int(game_state.get("reality_score") if game_state.has_method("get") else 50),
		"positive_energy": int(game_state.get("positive_energy") if game_state.has_method("get") else 50),
		"entropy_level": int(game_state.get("entropy_level") if game_state.has_method("get") else 0),
		"complaint_counter": int(game_state.get("complaint_counter") if game_state.has_method("get") else 0),
		"current_save_slot": int(game_state.get("current_save_slot") if game_state.has_method("get") else 1),
		"max_save_slots": _parser.get_max_save_slots(),
		"has_saved_game": bool(game_state.has_saved_game() if game_state.has_method("has_saved_game") else false),
		"player_stats": player_stats,
	}
	_parser.output_payload(payload, json_output)
	return 0
func handle_game_state_bool_command(
	game_state: Node,
	method_name: String,
	command_name: String,
	json_output: bool,
	extra_payload: Dictionary = { }
) -> int:
	if not _parser.ensure_game_state(game_state, json_output, command_name):
		return 1
	if not game_state.has_method(method_name):
		_parser.output_payload(
			{
				"ok": false,
				"command": command_name,
				"error": "GameState missing method: %s" % method_name,
			},
			json_output,
		)
		return 2
	var success: bool = bool(game_state.call(method_name))
	var payload := {
		"ok": success,
		"command": command_name,
		"method": method_name,
	}
	if not extra_payload.is_empty():
		payload.merge(extra_payload)
	_parser.output_payload(payload, json_output)
	return 0 if success else 1
func handle_new_game(game_state: Node, json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "new-game"):
		return 1
	if not game_state.has_method("new_game"):
		_parser.output_payload(
			{
				"ok": false,
				"command": "new-game",
				"error": "GameState missing method: new_game",
			},
			json_output,
		)
		return 2
	game_state.new_game()
	_parser.output_payload(
		{
			"ok": true,
			"command": "new-game",
		},
		json_output,
	)
	return 0
func handle_scenario(args: Array[String], json_output: bool) -> int:
	var lang := _parser.resolve_language(args)
	if not CLICommandParser.MissionScenarioLibraryScript.has_scenarios():
		_parser.output_payload(
			{
				"ok": false,
				"command": "scenario",
				"error": "No offline scenarios available",
			},
			json_output,
		)
		return 1
	var scenario_id := _parser.get_option(args, "--scenario-id").strip_edges().to_lower()
	var scenario: Dictionary = { }
	if scenario_id.is_empty():
		scenario = CLICommandParser.MissionScenarioLibraryScript.get_random_scenario()
	else:
		scenario = _parser.find_scenario_by_id(scenario_id)
		if scenario.is_empty():
			_parser.output_payload(
				{
					"ok": false,
					"command": "scenario",
					"error": "Scenario id not found: %s" % scenario_id,
					"available_ids": _parser.get_scenario_ids(),
				},
				json_output,
			)
			return 2
	var output := _parser.build_scenario_output(scenario, lang)
	output["ok"] = true
	output["command"] = "scenario"
	output["selection"] = "id" if not scenario_id.is_empty() else "random"
	_parser.output_payload(output, json_output)
	return 0
func handle_scenario_list(json_output: bool) -> int:
	var ids := _parser.get_scenario_ids()
	_parser.output_payload(
		{
			"ok": true,
			"command": "scenario-list",
			"count": ids.size(),
			"ids": ids,
		},
		json_output,
	)
	return 0
func handle_events(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "events"):
		return 1
	var lang := _parser.resolve_language(args)
	var limit_result := _parser.resolve_limit_option(args, "events", json_output)
	if not bool(limit_result.get("ok", false)):
		return 2
	var limit := int(limit_result.get("limit", CLICommandParser.DEFAULT_EVENT_LIMIT))
	var notes: Array = []
	if game_state.has_method("get_recent_event_notes"):
		notes = game_state.call("get_recent_event_notes", limit, lang)
	_parser.output_payload(
		{
			"ok": true,
			"command": "events",
			"language": lang,
			"limit": limit,
			"count": notes.size(),
			"events": notes,
		},
		json_output,
	)
	return 0
func handle_set_language(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "set-language"):
		return 1
	var raw_target := _parser.get_option(args, "--set-lang").strip_edges()
	if raw_target.is_empty():
		raw_target = _parser.get_option(args, "--lang").strip_edges()
	var target := _parser.normalize_language(raw_target)
	if target.is_empty():
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-language",
				"error": "Invalid language. Supported: en, zh",
			},
			json_output,
		)
		return 2
	var previous_language := String(game_state.get("current_language") if game_state.has_method("get") else "en")
	var localization_manager := _parser.get_localization_manager()
	if localization_manager != null and localization_manager.has_method("set_language"):
		localization_manager.call("set_language", target)
	elif game_state.has_method("set"):
		game_state.set("current_language", target)
	var current_language := String(game_state.get("current_language") if game_state.has_method("get") else target)
	_parser.output_payload(
		{
			"ok": current_language == target,
			"command": "set-language",
			"previous_language": previous_language,
			"language": current_language,
		},
		json_output,
	)
	return 0 if current_language == target else 1
func handle_prayer(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "prayer"):
		return 1
	var prayer_text := _parser.get_option(args, "--text").strip_edges()
	if prayer_text.is_empty():
		prayer_text = _parser.get_option(args, "--prayer").strip_edges()
	var context := _parser.get_option(args, "--context").strip_edges()
	if context.is_empty():
		context = "default"
	var simulate := _parser.has_flag(args, "--simulate") or _parser.has_flag(args, "--dry-run")
	if prayer_text.is_empty():
		_parser.output_payload(
			{
				"ok": true,
				"command": "prayer",
				"info": "Prayer mode available",
				"context": context,
				"current_stats": {
					"reality_score": int(game_state.get("reality_score") if game_state.has_method("get") else 50),
					"positive_energy": int(game_state.get("positive_energy") if game_state.has_method("get") else 50),
					"entropy_level": int(game_state.get("entropy_level") if game_state.has_method("get") else 0),
				},
				"usage": "Use --text=<prayer> to submit a prayer, or --simulate to preview without submitting",
			},
			json_output,
		)
		return 0
	if simulate:
		_parser.output_payload(
			{
				"ok": true,
				"command": "prayer",
				"simulate": true,
				"prayer_text": prayer_text,
				"context": context,
				"message": "Prayer simulation mode, no changes will be made",
			},
			json_output,
		)
		return 0
	_parser.output_payload(
		{
			"ok": true,
			"command": "prayer",
			"submitted": true,
			"prayer_text": prayer_text,
			"context": context,
			"message": "Prayer submitted successfully (AI processing not available in CLI mode)",
		},
		json_output,
	)
	return 0
func handle_journal_entry(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "journal"):
		return 1
	var entry_text := _parser.get_option(args, "--text").strip_edges()
	if entry_text.is_empty():
		entry_text = _parser.get_option(args, "--entry").strip_edges()
	var emotion := _parser.get_option(args, "--emotion").strip_edges().to_lower()
	if entry_text.is_empty() and emotion.is_empty():
		_parser.output_payload(
			{
				"ok": true,
				"command": "journal",
				"info": "Journal system available",
				"usage": "Use --text=<entry> or --emotion=<frustrated|hopeless|angry|confused|tired> to add an entry",
				"emotions": ["frustrated", "hopeless", "angry", "confused", "tired"],
			},
			json_output,
		)
		return 0
	var reality_gain := 0
	var entry_type := "custom"
	if not emotion.is_empty():
		match emotion:
			"frustrated":
				reality_gain = 3
				entry_type = "frustrated"
			"hopeless":
				reality_gain = 5
				entry_type = "hopeless"
			"angry":
				reality_gain = 4
				entry_type = "angry"
			"confused":
				reality_gain = 2
				entry_type = "confused"
			"tired", "exhausted":
				reality_gain = 3
				entry_type = "tired"
			_:
				_parser.output_payload(
					{
						"ok": false,
						"command": "journal",
						"error": "Invalid emotion: %s" % emotion,
						"valid_emotions": ["frustrated", "hopeless", "angry", "confused", "tired"],
					},
					json_output,
				)
				return 2
	var current_reality := int(game_state.get("reality_score") if game_state.has_method("get") else 50)
	var new_reality := current_reality + reality_gain
	if reality_gain > 0 and game_state.has_method("set"):
		game_state.set("reality_score", new_reality)
	_parser.output_payload(
		{
			"ok": true,
			"command": "journal",
			"entry_added": true,
			"entry_type": entry_type,
			"entry_text": entry_text if not entry_text.is_empty() else ("Preset: " + emotion),
			"reality_gain": reality_gain,
			"reality_score": {
				"before": current_reality,
				"after": new_reality,
			},
		},
		json_output,
	)
	return 0
func handle_journal_list(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "journal-list"):
		return 1
	_parser.output_payload(
		{
			"ok": true,
			"command": "journal-list",
			"message": "Journal entries are stored in GameState but not directly accessible via CLI",
			"info": "Use the graphical interface to view full journal history",
		},
		json_output,
	)
	return 0
func handle_credits(args: Array[String], json_output: bool) -> int:
	var lang := _parser.resolve_language(args)
	var credits_text := CLICommandParser.CreditsContent.get_credits_text_plain(lang)
	_parser.output_payload(
		{
			"ok": true,
			"command": "credits",
			"language": lang,
			"credits": credits_text,
		},
		json_output,
	)
	return 0
func handle_story_pages(args: Array[String], json_output: bool) -> int:
	var page_num := 0
	var raw_page := _parser.get_option(args, "--page").strip_edges()
	if not raw_page.is_empty() and raw_page.is_valid_int():
		page_num = int(raw_page)
	var lang := _parser.resolve_language(args)
	if page_num < 1 or page_num > 40:
		_parser.output_payload(
			{
				"ok": true,
				"command": "story-pages",
				"total_pages": 40,
				"message": "40-page introduction story available",
				"usage": "Use --page=<1-40> to view a specific page",
				"info": "Story pages are best viewed in the graphical interface with illustrations",
			},
			json_output,
		)
		return 0
	_parser.output_payload(
		{
			"ok": true,
			"command": "story-pages",
			"page": page_num,
			"total_pages": 40,
			"language": lang,
			"message": "Story page content requires graphical interface for full experience",
			"info": "Use the intro story scene in GUI mode to view the complete narrative with illustrations",
		},
		json_output,
	)
	return 0
func handle_special_scenes(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "special-scenes"):
		return 1
	var scene_type := _parser.get_option(args, "--scene").strip_edges().to_lower()
	if scene_type.is_empty():
		scene_type = _parser.get_option(args, "--type").strip_edges().to_lower()
	var available_scenes := [
		"trolley-problem",
		"night-cycle",
		"teacher-singing",
		"gloria-intervention",
	]
	if scene_type.is_empty():
		_parser.output_payload(
			{
				"ok": true,
				"command": "special-scenes",
				"available_scenes": available_scenes,
				"usage": "Use --scene=<type> to check a specific scene type",
				"info": "Special scenes are interactive and best experienced in graphical mode",
			},
			json_output,
		)
		return 0
	var scene_info := {}
	match scene_type:
		"trolley-problem", "trolley":
			scene_info = {
				"scene": "Trolley Problem",
				"description": "Moral dilemma scenarios that test ethical decision-making",
				"status": "Available in GUI mode only",
				"types": ["classic", "sacrifice", "complicity", "lesser_evil", "positive_energy_trap"],
			}
		"night-cycle", "night":
			scene_info = {
				"scene": "Night Cycle",
				"description": "Nightly reflection and Teacher Chan's liturgy",
				"status": "Available in GUI mode only",
				"features": ["reflection", "teacher_singing", "prayer_option"],
			}
		"teacher-singing", "singing", "concert":
			scene_info = {
				"scene": "Teacher Chan's Singing",
				"description": "Teacher Chan performs musical liturgy",
				"status": "Part of night cycle, GUI mode only",
				"features": ["character_portrait", "lyrics_animation", "particle_effects"],
			}
		"gloria-intervention", "gloria":
			scene_info = {
				"scene": "Gloria Intervention",
				"description": "Special intervention scenes",
				"status": "Available in GUI mode only",
			}
		_:
			_parser.output_payload(
				{
					"ok": false,
					"command": "special-scenes",
					"error": "Unknown scene type: %s" % scene_type,
					"available_scenes": available_scenes,
				},
				json_output,
			)
			return 2
	scene_info["ok"] = true
	scene_info["command"] = "special-scenes"
	_parser.output_payload(scene_info, json_output)
	return 0
func handle_check_rage(game_state: Node, json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "check-rage"):
		return 1
	var reality_score := int(game_state.get("reality_score") if game_state.has_method("get") else 50)
	var positive_energy := int(game_state.get("positive_energy") if game_state.has_method("get") else 50)
	var entropy_level := int(game_state.get("entropy_level") if game_state.has_method("get") else 0)
	var rage_threshold_reality := 20
	var rage_threshold_positive := 15
	var rage_threshold_entropy := 80
	var is_rage_triggered := reality_score <= rage_threshold_reality or positive_energy <= rage_threshold_positive or entropy_level >= rage_threshold_entropy
	var rage_reasons: Array[String] = []
	if reality_score <= rage_threshold_reality:
		rage_reasons.append("Reality score too low (%d <= %d)" % [reality_score, rage_threshold_reality])
	if positive_energy <= rage_threshold_positive:
		rage_reasons.append("Positive energy too low (%d <= %d)" % [positive_energy, rage_threshold_positive])
	if entropy_level >= rage_threshold_entropy:
		rage_reasons.append("Entropy level too high (%d >= %d)" % [entropy_level, rage_threshold_entropy])
	_parser.output_payload(
		{
			"ok": true,
			"command": "check-rage",
			"rage_mode_triggered": is_rage_triggered,
			"current_stats": {
				"reality_score": reality_score,
				"positive_energy": positive_energy,
				"entropy_level": entropy_level,
			},
			"thresholds": {
				"reality_minimum": rage_threshold_reality,
				"positive_energy_minimum": rage_threshold_positive,
				"entropy_maximum": rage_threshold_entropy,
			},
			"rage_reasons": rage_reasons,
			"message": "Rage mode is a concept, low stats affect game events" if is_rage_triggered else "Stats are within normal range",
		},
		json_output,
	)
	return 0
