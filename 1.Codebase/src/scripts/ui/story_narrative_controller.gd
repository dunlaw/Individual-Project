extends "res://1.Codebase/src/scripts/ui/base_controller.gd"
class_name StoryNarrativeController
signal mission_generation_complete
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
const MAX_CONTENT_PREVIEW_LENGTH := 100
const MAX_MISSION_ASSETS := 4
const GLORIA_OPEN_SFX_IDS: Array[String] = [
	"gloria_open_01",
	"gloria_open_02",
	"gloria_open_03",
	"gloria_open_04",
]
const GLORIA_MAIN_SFX_IDS: Array[String] = [
	"gloria_guilt_01",
	"gloria_guilt_02",
	"gloria_guilt_03",
	"gloria_guilt_04",
	"gloria_guilt_05",
	"gloria_guilt_06",
	"gloria_guilt_07",
	"gloria_guilt_08",
	"gloria_pua_01",
	"gloria_pua_02",
	"gloria_pua_03",
	"gloria_pua_04",
	"gloria_pua_05",
	"gloria_pua_06",
	"gloria_pua_07",
	"gloria_pua_08",
	"gloria_pua_09",
	"gloria_pua_10",
]
const StoryUIHelper = preload("res://1.Codebase/src/scripts/ui/story_ui_helper.gd")
const NarrativePromptBuilder = preload("res://1.Codebase/src/scripts/core/ai/narrative_prompt_builder.gd")
const NarrativeResponseParser = preload("res://1.Codebase/src/scripts/core/ai/narrative_response_parser.gd")
var _last_request: Dictionary = { }
var _last_request_callback: Callable = Callable()
var _last_story_text: String = ""
var _last_story_id: int = 0
var _pending_choice_followup: bool = false
var _choice_followup_story_id: int = -1
var _night_cycle_pending: bool = false
var _night_cycle_ready: bool = false
var _cached_night_cycle_payload: Dictionary = {}
var _countdown_duration: float = 30.0
var _is_generating: bool = false
var _journal_summary_in_flight: bool = false
var _gloria_voice_rng: RandomNumberGenerator = RandomNumberGenerator.new()
const JOURNAL_SUMMARY_DELAY_SEC := 2.0
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func is_generating() -> bool:
	return _is_generating
func _init(p_story_scene: Control) -> void:
	super(p_story_scene)
	_gloria_voice_rng.randomize()
func _store_last_request(request_type: String, prompt: String, context: Dictionary, callback: Callable) -> void:
	var context_copy: Variant = context
	if context is Dictionary:
		context_copy = (context as Dictionary).duplicate(true)
	_last_request = {
		"type": request_type,
		"prompt": prompt,
		"context": context_copy,
	}
	_last_request_callback = callback if not callback.is_null() else Callable()
func has_retryable_request() -> bool:
	return not _last_request.is_empty()
func _get_retry_message(request_type: String, lang: String) -> String:
	var message := _tr("STORY_NARRATIVE_RETRYING_AI_REQUEST")
	match request_type:
		"mission":
			message = _tr("STORY_NARRATIVE_RETRYING_MISSION_GENERATION")
		"consequence":
			message = _tr("STORY_NARRATIVE_RETRYING_CONSEQUENCE_GENERATION")
		"teammate_interference":
			message = _tr("STORY_NARRATIVE_RETRYING_TEAMMATE_INTERFERENCE")
		"gloria_intervention":
			message = _tr("STORY_NARRATIVE_RETRYING_GLORIA_INTERVENTION")
		_:
			pass
	return message
func retry_last_request(force_mock: bool = false) -> bool:
	if _last_request.is_empty():
		return false
	if not story_scene:
		return false
	var ai_manager = get_ai_manager()
	if not ai_manager:
		return false
	var prompt_variant: Variant = _last_request.get("prompt", "")
	var prompt := String(prompt_variant)
	if prompt.is_empty():
		return false
	var callback_callable: Callable = _last_request_callback
	if not callback_callable.is_valid():
		return false
	var context_variant: Variant = _last_request.get("context", { })
	var context_payload: Dictionary = { }
	if context_variant is Dictionary:
		context_payload = (context_variant as Dictionary).duplicate(true)
	if force_mock:
		context_payload["force_mock"] = true
	var request_type := String(_last_request.get("type", "unknown"))
	var lang := "en"
	var game_state = get_game_state()
	if game_state:
		lang = String(game_state.current_language)
	var loading_message := _get_retry_message(request_type, lang)
	story_scene.show_loading(loading_message, "ai_retry")
	if story_scene.ui_controller:
		story_scene.ui_controller.set_status_text(loading_message)
	ai_manager.generate_story(prompt, context_payload, callback_callable)
	return true
func _get_asset_registry():
	if ServiceLocator and ServiceLocator.has_service("AssetRegistry"):
		return ServiceLocator.get_service("AssetRegistry")
	return null
func _get_voice_lang_code() -> String:
	var game_state = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	return "en" if lang == "en" else "zh"
func _build_gloria_sfx_keys(voice_ids: Array[String]) -> Array[String]:
	var lang_code := _get_voice_lang_code()
	var keys: Array[String] = []
	for voice_id in voice_ids:
		keys.append("gloria/%s/%s" % [lang_code, voice_id])
	return keys
func _pick_gloria_sfx_key(voice_ids: Array[String]) -> String:
	var candidate_keys: Array[String] = _build_gloria_sfx_keys(voice_ids)
	if candidate_keys.is_empty():
		return ""
	var audio_manager = get_audio_manager()
	if audio_manager and audio_manager.has_method("has_sound"):
		var playable: Array[String] = []
		for key in candidate_keys:
			if audio_manager.has_sound(key):
				playable.append(key)
		if playable.is_empty() and audio_manager.has_method("reload_sound_catalog"):
			audio_manager.reload_sound_catalog()
			for key in candidate_keys:
				if audio_manager.has_sound(key):
					playable.append(key)
		candidate_keys = playable
	if candidate_keys.is_empty():
		return ""
	var index: int = _gloria_voice_rng.randi_range(0, candidate_keys.size() - 1)
	return String(candidate_keys[index])
func _play_random_gloria_sfx(voice_ids: Array[String], volume_multiplier: float = 0.85) -> void:
	var audio_manager = get_audio_manager()
	if not audio_manager or not audio_manager.has_method("play_sfx"):
		return
	var key := _pick_gloria_sfx_key(voice_ids)
	if key.is_empty():
		return
	_report_info("GloriaVoice key=%s" % key)
	audio_manager.play_sfx(key, volume_multiplier)
func _update_story_display(new_content: String, replace_existing: bool = true) -> void:
	if not story_scene or not story_scene.ui_controller:
		return
	if replace_existing:
		story_scene.ui_controller.clear_story_text()
	await story_scene.ui_controller.display_story(new_content)
func start_new_mission(prepared_assets: Dictionary = { }) -> void:
	_debug_log("[DEBUG_NARRATIVE] Requesting New Mission Generation...")
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		_report_error("AIManager or GameState not available")
		return
	if _is_first_round(game_state):
		_debug_log("[DEBUG_NARRATIVE] First round detected, generating intro story")
		_request_intro_story_generation()
		return
	if game_state:
		game_state.debug_force_mission_complete = false
	var asset_data: Dictionary = { }
	if prepared_assets is Dictionary and (prepared_assets as Dictionary).size() > 0:
		asset_data = (prepared_assets as Dictionary).duplicate(true)
	elif story_scene.asset_controller:
		var prepared_variant: Variant = story_scene.asset_controller.prepare_mission_assets(MAX_MISSION_ASSETS)
		if prepared_variant is Dictionary:
			asset_data = prepared_variant
	var selected_assets: Array = asset_data.get("asset_list", [])
	var selected_ids: Array = asset_data.get("asset_ids", [])
	if selected_assets.is_empty():
		_report_error("No assets available for mission")
		return
	if story_scene.asset_controller:
		story_scene.asset_controller.setup_asset_interactions(selected_ids)
		story_scene.update_asset_display()
	var prompt: String = build_mission_prompt(selected_assets)
	var context: Dictionary = {
		"purpose": "new_mission",
		"mission_number": game_state.current_mission + 1,
		"assets": selected_assets,
	}
	_report_info("Generating new mission narrative (Mission #%d)..." % context.get("mission_number", 0))
	_report_info("Assets: %s" % [selected_ids])
	story_scene.show_loading("Generating mission...")
	_is_generating = true
	var mission_callback := Callable(self, "_on_mission_generated")
	_store_last_request("mission", prompt, context, mission_callback)
	ai_manager.generate_story(prompt, context, mission_callback)
func build_mission_prompt(selected_assets: Array) -> String:
	var game_state = get_game_state()
	var asset_registry = _get_asset_registry()
	return NarrativePromptBuilder.build_mission_prompt(game_state, selected_assets, asset_registry)
func _on_mission_generated(response: Dictionary) -> void:
	_is_generating = false
	story_scene.hide_loading()
	_debug_log("[DEBUG_NARRATIVE] Mission Generation Response Received. Success: %s" % response.get("success", false))
	if not response.get("success", false):
		var error_msg: String = String(response.get("error", "Unknown error"))
		_report_error(
			"Mission generation failed: %s" % error_msg,
			{"error": error_msg}
		)
		_update_story_display("Failed to generate mission. Please try again.")
		emit_signal("mission_generation_complete")
		return
	var ai_manager = get_ai_manager()
	var parsed := NarrativeResponseParser.parse_mission_response(response, ai_manager)
	if not parsed.get("success", false):
		var error_msg: String = String(parsed.get("error", "Unknown parse error"))
		_report_error("Mission parse failed: %s" % error_msg, {"error": error_msg})
		_update_story_display("Failed to parse mission. Please try again.")
		emit_signal("mission_generation_complete")
		return
	var clean_content: String = String(parsed.get("story_text", ""))
	if clean_content.strip_edges().is_empty():
		_report_error("Mission generated but story_text is empty", {
			"parsed": parsed,
			"response_keys": response.keys() if response is Dictionary else []
		})
		_update_story_display("Mission generated successfully, but the story content is empty. This may be a parsing error.")
		emit_signal("mission_generation_complete")
		return
	var directives: Dictionary = parsed.get("directives", {})
	var ai_choice_payload: Array[Dictionary] = parsed.get("choices", [])
	var mission_title: String = String(parsed.get("mission_title", ""))
	_report_info("Mission generated successfully! Title: \"%s\" | Content: %d chars | Choices: %d" % [
		mission_title if not mission_title.is_empty() else "(untitled)",
		clean_content.length(), ai_choice_payload.size()
	])
	if not mission_title.is_empty():
		var game_state = get_game_state()
		if game_state:
			game_state.current_mission_title = mission_title
	if not directives.is_empty():
		story_scene.apply_scene_directives(directives)
		if directives.has("relationships"):
			_process_relationship_updates(directives["relationships"])
	var sanitized: String = StoryUIHelper.sanitize_story_text(clean_content)
	await _update_story_display(sanitized)
	_last_story_text = sanitized
	var game_state = get_game_state()
	if game_state:
		game_state.set_latest_story_text(sanitized)
	_refresh_story_nav_buttons()
	_last_story_id += 1
	if game_state:
		game_state.mission_turn_count = 1
	_record_mission_start(sanitized)
	_update_story_choices(ai_choice_payload, sanitized)
	emit_signal("mission_generation_complete")
func _extract_primary_json_block(raw_text: String) -> String:
	return NarrativeResponseParser.extract_primary_json_block(raw_text)
func _normalize_scene_directives(scene_variant) -> Dictionary:
	return NarrativeResponseParser.normalize_scene_directives(scene_variant)
func _normalize_character_directives(characters_variant) -> Dictionary:
	return NarrativeResponseParser.normalize_character_directives(characters_variant)
func _normalize_ai_choice_payload(payload) -> Array[Dictionary]:
	return NarrativeResponseParser.normalize_ai_choice_payload(payload)
func _extract_archetype_choices_from_text(story_text: String, lang: String) -> Array[Dictionary]:
	return NarrativeResponseParser.extract_archetype_choices_from_text(story_text, lang)
func _update_story_choices(ai_choices: Array[Dictionary], story_text: String, allow_followup: bool = true) -> void:
	if not story_scene or not story_scene.choice_controller:
		return
	var lang := _get_current_language()
	var final_choices := ai_choices
	var initial_report := NarrativeResponseParser.get_ai_choice_validation_report(final_choices, lang)
	_debug_log("[DEBUG_NARRATIVE] Updating Story Choices. AI Payload Size: %d" % ai_choices.size())
	_debug_log("[Narrative] Updating choices | lang=%s | ai_choices=%d | valid=%s | reason=%s" % [
		lang,
		final_choices.size(),
		str(initial_report.get("valid", false)),
		str(initial_report.get("reason", "unknown")),
	])
	if not bool(initial_report.get("valid", false)):
		if not final_choices.is_empty():
			_debug_log("[Narrative] AI choices invalid; attempting story-text extraction | details=%s" % [initial_report])
		final_choices = _extract_archetype_choices_from_text(story_text, lang)
		var extracted_report := NarrativeResponseParser.get_ai_choice_validation_report(final_choices, lang)
		_debug_log("[Narrative] Extracted choices from text | count=%d | valid=%s | reason=%s" % [
			final_choices.size(),
			str(extracted_report.get("valid", false)),
			str(extracted_report.get("reason", "unknown")),
		])
	if not _are_ai_choices_valid(final_choices, lang):
		print("[StoryNarrative] DEBUG: AI choices INVALID (count=%d) — entering fallback path" % final_choices.size())
		_debug_log("[Narrative] No valid AI choices available after extraction; falling back to legacy generator")
		if allow_followup and not _pending_choice_followup:
			_debug_log("[Narrative] Triggering choice_followup fallback request")
			_request_story_choice_followup(story_text, lang)
			if not _pending_choice_followup:
				_debug_log("[Narrative] choice_followup resolved synchronously (mock mode); skipping legacy fallback")
				return
		elif allow_followup:
			_debug_log("[Narrative] choice_followup already pending for current story; skipping duplicate request")
		else:
			_debug_log("[Narrative] choice_followup disabled for this update path")
		print("[StoryNarrative] DEBUG: Falling back to generate_choices() legacy path")
		story_scene.choice_controller.generate_choices()
		return
	print("[StoryNarrative] DEBUG: AI choices VALID (count=%d) — applying directly via apply_ai_choices (FIX ACTIVE)" % final_choices.size())
	_debug_log("[Narrative] Applying valid AI choices to controller without follow-up")
	story_scene.choice_controller.apply_ai_choices(final_choices, lang)
func _are_ai_choices_valid(ai_choices: Array[Dictionary], lang: String) -> bool:
	return NarrativeResponseParser.are_ai_choices_valid(ai_choices, lang)
func _request_story_choice_followup(story_text: String, lang: String) -> void:
	var ai_manager = get_ai_manager()
	var excerpt := story_text.strip_edges()
	if not ai_manager or excerpt.is_empty():
		return
	if _pending_choice_followup and _choice_followup_story_id == _last_story_id:
		return
	_pending_choice_followup = true
	_choice_followup_story_id = _last_story_id
	var prompt := NarrativePromptBuilder.build_choice_followup_prompt(excerpt, lang)
	_debug_log("[Narrative] Requesting follow-up choice summaries")
	var context := {
		"purpose": "choice_followup",
	}
	var callback := Callable(self, "_on_choice_followup_generated")
	ai_manager.generate_story(prompt, context, callback)
func _on_choice_followup_generated(response: Dictionary) -> void:
	_pending_choice_followup = false
	if not response.get("success", false):
		_ensure_fallback_choices()
		return
	var content := String(response.get("content", response.get("text", "")))
	if content.is_empty():
		_ensure_fallback_choices()
		return
	var parser := JSON.new()
	var parse_source := content
	if parser.parse(parse_source) != OK or not (parser.data is Dictionary):
		var json_block := _extract_primary_json_block(content)
		if json_block.is_empty():
			_ensure_fallback_choices()
			return
		parse_source = json_block
		parser = JSON.new()
		if parser.parse(parse_source) != OK or not (parser.data is Dictionary):
			_ensure_fallback_choices()
			return
	var json_data: Dictionary = parser.data
	if not json_data.has("choices"):
		_ensure_fallback_choices()
		return
	var ai_choices := _normalize_ai_choice_payload(json_data.get("choices", []))
	var validation_report := NarrativeResponseParser.get_ai_choice_validation_report(ai_choices, _get_current_language())
	if not bool(validation_report.get("valid", false)):
		_debug_log("[Narrative] Follow-up choices arrived but failed validation | details=%s" % [validation_report])
		_ensure_fallback_choices()
		return
	if _choice_followup_story_id != _last_story_id:
		return
	_debug_log("[Narrative] Follow-up choices received and accepted: %d" % ai_choices.size())
	_update_story_choices(ai_choices, _last_story_text, false)
func _ensure_fallback_choices() -> void:
	if not story_scene or not story_scene.choice_controller:
		return
	if story_scene.choice_controller.current_choices.is_empty():
		print("[StoryNarrative] DEBUG: Choice followup failed — generating fallback choices")
		story_scene.choice_controller.generate_choices()
func _get_current_language() -> String:
	var game_state = get_game_state()
	if game_state:
		return game_state.current_language
	return "en"
func _normalize_asset_directives(assets_variant) -> Array:
	return NarrativeResponseParser.normalize_asset_directives(assets_variant)
func _process_relationship_updates(updates_variant) -> void:
	if not (updates_variant is Array):
		return
	var teammate_system = ServiceLocator.get_teammate_system() if ServiceLocator else null
	if not teammate_system:
		return
	for update in (updates_variant as Array):
		if not (update is Dictionary):
			continue
		var source_id = String(update.get("source", "")).strip_edges().to_lower()
		var target_id = String(update.get("target", "")).strip_edges().to_lower()
		var status = String(update.get("status", "")).strip_edges()
		var value_change = int(update.get("value_change", 0))
		if source_id.is_empty() or target_id.is_empty() or status.is_empty():
			continue
		if source_id == "you" or source_id == "me": source_id = "player"
		if target_id == "you" or target_id == "me": target_id = "player"
		teammate_system.update_relationship(source_id, target_id, status, value_change)
		_debug_log("[Narrative] Updated relationship: %s -> %s (%s, %+d)" % [source_id, target_id, status, value_change])
func _record_mission_start(content: String) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var choice_data: Dictionary = {
		"type": "mission_start",
		"choice_type": "major",
		"text": "New mission started",
		"mission_number": game_state.current_mission,
		"content_preview": content.substr(0, MAX_CONTENT_PREVIEW_LENGTH) if content.length() > MAX_CONTENT_PREVIEW_LENGTH else content,
		"tags": ["mission", "system"],
	}
	if game_state.butterfly_tracker:
		game_state.butterfly_tracker.record_choice(choice_data)
func handle_prayer_consequence(data: Dictionary) -> void:
	var prayer_text: String = data.get("prayer_text", "")
	var disaster_text: String = data.get("disaster", "")
	if prayer_text.is_empty() or disaster_text.is_empty():
		return
	var combined_text = "[PLAYER PRAYER]\n%s\n\n[DIVINE RESPONSE]\n%s" % [prayer_text, disaster_text]
	_last_story_text = combined_text
	var game_state = get_game_state()
	if game_state:
		game_state.set_latest_story_text(combined_text)
		game_state.add_event(
			"Prayer Answered",
			"Prayer: %s\nResult: %s" % [prayer_text.substr(0, 50), disaster_text.substr(0, 50)]
		)
	_refresh_story_nav_buttons()
	_debug_log("[Narrative] Processed prayer consequence. Context updated.")
func request_consequence_generation(choice: Dictionary, success: bool) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	var lang: String = game_state.current_language
	var prompt: String = _build_consequence_prompt(choice, success, lang)
	var context: Dictionary = {
		"purpose": "consequence",
		"choice": choice,
		"success": success,
	}
	var choice_text: String = String(choice.get("text", "?"))
	_report_info("Generating consequence for choice: \"%s\" (success: %s)" % [choice_text, success])
	story_scene.show_loading("Generating consequence...")
	_is_generating = true
	var consequence_callback := Callable(self, "_on_consequence_generated")
	_store_last_request("consequence", prompt, context, consequence_callback)
	ai_manager.generate_story(prompt, context, consequence_callback)
func _build_consequence_prompt(choice: Dictionary, success: bool, lang: String) -> String:
	var game_state = get_game_state()
	var force_complete: bool = game_state.debug_force_mission_complete if game_state else false
	if not force_complete and game_state:
		var max_rounds: int = int(game_state.settings.get("max_rounds_per_mission", 0))
		if max_rounds > 0 and game_state.mission_turn_count >= max_rounds - 1:
			force_complete = true
	return NarrativePromptBuilder.build_consequence_prompt(choice, success, lang, force_complete)
func _on_consequence_generated(response: Dictionary) -> void:
	_is_generating = false
	story_scene.hide_loading()
	if not response.get("success", false):
		_report_warning("Consequence generation failed: success=false")
		story_scene.overlay_controller.show_gloria_overlay("Gloria glares at you silently...")
		return
	var content: String = String(response.get("content", response.get("text", "")))
	if content.is_empty():
		_report_warning("Consequence generation failed: content empty")
		story_scene.overlay_controller.show_gloria_overlay("Gloria glares at you silently...")
		return
	var ai_manager = get_ai_manager()
	if not ai_manager:
		_report_warning("Consequence generation failed: AI manager missing")
		story_scene.overlay_controller.show_gloria_overlay(content if not content.is_empty() else "Gloria glares at you silently...")
		return
	var parsed := NarrativeResponseParser.parse_mission_response(response, ai_manager)
	var directives: Dictionary = parsed.get("directives", {})
	var ai_choice_payload: Array[Dictionary] = parsed.get("choices", [])
	var clean_content: String = String(parsed.get("story_text", ""))
	if clean_content.strip_edges().is_empty():
		clean_content = ai_manager.extract_story_content(content)
	if not directives.is_empty():
		if directives.has("characters"):
			directives["characters"] = _normalize_character_directives(directives.get("characters", { }))
		if directives.has("scene"):
			directives["scene"] = _normalize_scene_directives(directives.get("scene", { }))
		story_scene.apply_scene_directives(directives)
		if directives.has("relationships"):
			_process_relationship_updates(directives["relationships"])
	var sanitized: String = StoryUIHelper.sanitize_story_text(clean_content)
	await _update_story_display(sanitized)
	_last_story_text = sanitized
	var game_state_ref = get_game_state()
	if game_state_ref:
		game_state_ref.set_latest_story_text(sanitized)
	_refresh_story_nav_buttons()
	_record_butterfly_consequence(_last_request.get("context", {}), sanitized)
	var directives_map: Dictionary = directives
	var mission_status: String = String(directives_map.get("mission_status", "ongoing")).to_lower()
	_report_info("Consequence generated | %d chars | Mission status: %s" % [sanitized.length(), mission_status])
	var game_state = get_game_state()
	if game_state and game_state.debug_force_mission_complete:
		_debug_log("[Narrative] Debug override: forcing mission completion.")
		mission_status = "complete"
	if game_state and mission_status != "complete":
		var max_rounds: int = int(game_state.settings.get("max_rounds_per_mission", 0))
		if max_rounds > 0 and game_state.mission_turn_count >= max_rounds - 1:
			_debug_log("[Narrative] Max rounds override: turn %d >= limit %d, forcing mission completion." % [game_state.mission_turn_count, max_rounds - 1])
			mission_status = "complete"
	if mission_status == "complete":
		_debug_log("[Narrative] AI signaled mission completion.")
		_handle_mission_completion(sanitized)
	else:
		if game_state and game_state.positive_energy <= 30:
			var last_turn = game_state.get_metadata("last_gloria_auto_turn", -999)
			var current_turn = game_state.mission_turn_count
			if current_turn - last_turn >= 3:
				var last_choice = _last_request.get("context", {}).get("choice", {})
				if last_choice.is_empty():
					last_choice = {"text": "Unknown action"}
				game_state.set_metadata("last_gloria_auto_turn", current_turn)
				_debug_log("[Narrative] Triggering automatic Gloria intervention (Positive Energy <= %d)" % GameConstants.Choice.GLORIA_POSITIVE_THRESHOLD)
				request_gloria_intervention(last_choice)
				return
		_update_story_choices(ai_choice_payload, sanitized)
		if story_scene and story_scene.flow_controller:
			story_scene.flow_controller._try_schedule_trolley_problem()
func _handle_mission_completion(last_text: String) -> void:
	if not story_scene or not story_scene.flow_controller:
		return
	var game_state = get_game_state()
	if game_state:
		game_state.complete_mission(true)
	_schedule_journal_summary_request()
	if story_scene.has_method("show_mission_complete_countdown"):
		story_scene.show_mission_complete_countdown(_countdown_duration)
	if story_scene.choice_controller:
		story_scene.choice_controller.hide_choice_buttons()
		if story_scene.choice_controller.has_method("clear_and_hide"):
			story_scene.choice_controller.clear_and_hide()
	_night_cycle_pending = true
	_night_cycle_ready = false
	_cached_night_cycle_payload = {}
	request_night_cycle_generation(last_text, true)
	await story_scene.get_tree().create_timer(_countdown_duration).timeout
	_night_cycle_pending = false
	var payload: Dictionary = {}
	if not _cached_night_cycle_payload.is_empty():
		payload = _cached_night_cycle_payload
	else:
		_report_warning("Night cycle AI not ready after countdown, using fallback payload.")
		game_state = get_game_state()
		if game_state and game_state.debug_force_mission_complete:
			_debug_log("[Narrative] Clearing stuck debug_force_mission_complete flag on countdown end.")
			game_state.debug_force_mission_complete = false
		payload = {
			"reflection_text": last_text,
			"teacher_chan_text": "...",
			"concert_lyrics": ["(Lyrics unavailable due to timeout)"],
			"honeymoon_text": "...",
			"prayer_prompt": "Pray."
		}
	story_scene.hide_loading()
	story_scene.flow_controller.enter_night_cycle(payload)
func request_night_cycle_generation(last_text: String, is_background: bool = false) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	var lang: String = game_state.current_language
	var prompt: String = _build_night_cycle_prompt(last_text, lang)
	var context: Dictionary = {
		"purpose": "night_cycle",
		"last_text": last_text,
		"is_background": is_background
	}
	if not is_background:
		story_scene.show_loading("Generating night cycle content...")
	var callback := Callable(self, "_on_night_cycle_generated")
	_store_last_request("night_cycle", prompt, context, callback)
	ai_manager.generate_story(prompt, context, callback)
func _build_night_cycle_prompt(last_text: String, lang: String) -> String:
	return NarrativePromptBuilder.build_night_cycle_prompt(last_text, lang)
func _on_night_cycle_generated(response: Dictionary) -> void:
	var is_background: bool = false
	if _last_request.has("context") and _last_request["context"] is Dictionary:
		is_background = _last_request["context"].get("is_background", false)
	if not is_background:
		story_scene.hide_loading()
	_debug_log("[DEBUG] _on_night_cycle_generated: Received response from AI.")
	var payload: Dictionary = {}
	if not response.get("success", false):
		_report_warning("AI response success=false during night cycle; using cached story text.")
		var game_state = get_game_state()
		payload = {
			"reflection_text": _last_story_text,
			"teacher_chan_text": "...",
			"honeymoon_text": "...",
			"prayer_prompt": "..."
		}
	else:
		var content: String = String(response.get("content", response.get("text", "")))
		var json_parser := JSON.new()
		var json_block = _extract_primary_json_block(content)
		if json_block.is_empty(): json_block = content
		if json_parser.parse(json_block) == OK and json_parser.data is Dictionary:
			payload = json_parser.data
			_debug_log("[DEBUG] Successfully parsed AI response as JSON.")
		else:
			_report_warning("Failed to parse night cycle AI response as JSON. Using fallback payload.")
			payload = {
				"reflection_text": _last_story_text,
				"teacher_chan_text": content.substr(0, 100),
				"concert_lyrics": ["Error parsing lyrics"],
				"honeymoon_text": "...",
				"prayer_prompt": "Pray."
			}
	var game_state = get_game_state()
	if game_state and game_state.debug_force_mission_complete:
		_debug_log("[Narrative] Night cycle payload ready. Clearing debug flag.")
		game_state.debug_force_mission_complete = false
	if is_background:
		_debug_log("[Narrative] Night cycle payload cached. Waiting for countdown to finish.")
		_cached_night_cycle_payload = payload
		_night_cycle_ready = true
	else:
		_debug_log("[DEBUG] Final payload being sent to FlowController immediately (non-background).")
		story_scene.flow_controller.enter_night_cycle(payload)
func request_teammate_interference(teammate_id: String, player_action: String) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	var teammate_lower := teammate_id.to_lower()
	if teammate_lower == "gloria":
		_play_random_gloria_sfx(GLORIA_OPEN_SFX_IDS, 0.8)
	var lang: String = game_state.current_language
	var prompt: String = _build_interference_prompt(teammate_id, player_action, lang)
	var context: Dictionary = {
		"purpose": "teammate_interference",
		"teammate_id": teammate_lower,
		"action": player_action,
	}
	_report_info("%s interference triggered! Generating response..." % teammate_id.capitalize())
	story_scene.show_loading("Generating teammate interference...")
	var interference_callback := Callable(self, "_on_teammate_interference_generated").bind(teammate_lower)
	_store_last_request("teammate_interference", prompt, context, interference_callback)
	ai_manager.generate_story(prompt, context, interference_callback)
func _build_interference_prompt(teammate_id: String, action: String, lang: String) -> String:
	var game_state = get_game_state()
	var is_honeymoon: bool = game_state.is_in_honeymoon() if game_state else false
	return NarrativePromptBuilder.build_interference_prompt(teammate_id, action, lang, is_honeymoon)
func _on_teammate_interference_generated(response: Dictionary, teammate_id: String = "") -> void:
	story_scene.hide_loading()
	if not response.get("success", false):
		return
	var content: String = String(response.get("content", response.get("text", "")))
	if content.is_empty():
		return
	var ai_manager = get_ai_manager()
	if not ai_manager:
		return
	var directives = ai_manager.parse_scene_directives(content)
	if not directives.is_empty():
		if directives.has("characters"):
			directives["characters"] = _normalize_character_directives(directives.get("characters", { }))
		if directives.has("scene"):
			directives["scene"] = _normalize_scene_directives(directives.get("scene", { }))
		story_scene.apply_scene_directives(directives)
	var clean_content = ai_manager.extract_story_content(content)
	var sanitized: String = StoryUIHelper.sanitize_story_text(clean_content)
	var game_state = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var prefix: String = "[TEAMMATE INTERFERENCE]\n\n"
	if lang == "zh":
		prefix = "[Teammate Interference]\n\n"
	var combined_text := prefix + sanitized
	await _update_story_display(combined_text)
	_last_story_text = combined_text
	var game_state_teammate = get_game_state()
	if game_state_teammate:
		game_state_teammate.set_latest_story_text(combined_text)
	_refresh_story_nav_buttons()
	_last_story_id += 1
	story_scene.choice_controller.generate_choices()
	if teammate_id == "gloria":
		_play_random_gloria_sfx(GLORIA_MAIN_SFX_IDS, 0.88)
func request_gloria_intervention(choice: Dictionary) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	_play_random_gloria_sfx(GLORIA_OPEN_SFX_IDS, 0.8)
	var lang: String = game_state.current_language
	var prompt: String = _build_gloria_prompt(choice, lang)
	var context: Dictionary = {
		"purpose": "gloria_intervention",
		"choice": choice,
	}
	game_state.set_metadata("last_gloria_auto_turn", game_state.mission_turn_count)
	_report_info("Gloria intervention triggered! Positive Energy: %d | Generating PUA response..." % game_state.positive_energy)
	story_scene.show_loading("Generating Gloria intervention...")
	_is_generating = true
	var gloria_callback := Callable(self, "_on_gloria_intervention_generated")
	_store_last_request("gloria_intervention", prompt, context, gloria_callback)
	ai_manager.generate_story(prompt, context, gloria_callback)
func _build_gloria_prompt(choice: Dictionary, lang: String) -> String:
	return NarrativePromptBuilder.build_gloria_prompt(choice, lang)
func _on_gloria_intervention_generated(response: Dictionary) -> void:
	_is_generating = false
	story_scene.hide_loading()
	if not response.get("success", false):
		return
	var content: String = String(response.get("content", response.get("text", "")))
	if content.is_empty():
		return
	var ai_manager = get_ai_manager()
	if not ai_manager:
		return
	var directives = ai_manager.parse_scene_directives(content)
	if not directives.is_empty():
		if directives.has("characters"):
			directives["characters"] = _normalize_character_directives(directives.get("characters", { }))
		if directives.has("scene"):
			directives["scene"] = _normalize_scene_directives(directives.get("scene", { }))
		story_scene.apply_scene_directives(directives)
	var clean_content := NarrativeResponseParser.extract_gloria_speech(content, ai_manager)
	_report_info("Gloria speaks! (%d chars of toxic positivity)" % clean_content.length())
	_debug_log("[Narrative] Showing Gloria overlay with content length: %d" % clean_content.length())
	story_scene.overlay_controller.show_gloria_overlay(clean_content)
func on_ai_request_progress(update: Dictionary) -> void:
	var progress_info: Dictionary = StoryUIHelper.parse_progress_update(update)
	if story_scene.ui_controller:
		story_scene.ui_controller.update_loading_progress(progress_info)
func on_ai_error(error_message: String) -> void:
	_report_error(
		"AI Error: %s" % error_message,
		{"error_message": error_message}
	)
	if story_scene.ui_controller:
		story_scene.hide_loading()
	var game_state = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var error_display: String = ""
	if lang == "zh":
		error_display = "AI generation failed: " + error_message
	else:
		error_display = "AI generation failed: " + error_message
	_update_story_display(error_display)
func _is_first_round(game_state: Variant) -> bool:
	if not game_state:
		return false
	var missions_completed: int = game_state.missions_completed
	var current_mission: int = game_state.current_mission
	var has_intro_shown: bool = game_state.get_metadata("intro_story_shown", false)
	return missions_completed == 0 and current_mission == 0 and not has_intro_shown
func _request_intro_story_generation() -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		_report_error("AIManager or GameState not available for intro")
		return
	var lang: String = game_state.current_language
	var prompt: String = NarrativePromptBuilder.build_intro_story_prompt(lang)
	var context: Dictionary = {
		"purpose": "intro_story",
		"is_first_round": true,
	}
	var loading_msg := _tr("STORY_NARRATIVE_GENERATING_INTRODUCTION")
	story_scene.show_loading(loading_msg)
	_is_generating = true
	var intro_callback := Callable(self, "_on_intro_story_generated")
	_store_last_request("intro_story", prompt, context, intro_callback)
	ai_manager.generate_story(prompt, context, intro_callback)
func _on_intro_story_generated(response: Dictionary) -> void:
	_is_generating = false
	story_scene.hide_loading()
	_debug_log("[DEBUG_NARRATIVE] Intro Story Generation Response Received. Success: %s" % response.get("success", false))
	if not response.get("success", false):
		var error_msg: String = String(response.get("error", "Unknown error"))
		_report_error("Intro story generation failed: %s" % error_msg, {"error": error_msg})
		_update_story_display("Failed to generate introduction. Please try again.")
		emit_signal("mission_generation_complete")
		return
	var ai_manager = get_ai_manager()
	var parsed := NarrativeResponseParser.parse_mission_response(response, ai_manager)
	if not parsed.get("success", false):
		var error_msg: String = String(parsed.get("error", "Unknown parse error"))
		_report_error("Intro story parse failed: %s" % error_msg, {"error": error_msg})
		_update_story_display("Failed to parse introduction. Please try again.")
		emit_signal("mission_generation_complete")
		return
	var clean_content: String = String(parsed.get("story_text", ""))
	if clean_content.strip_edges().is_empty():
		_report_error("Intro story generated but story_text is empty", {
			"parsed": parsed,
			"response_keys": response.keys() if response is Dictionary else []
		})
		_update_story_display("Introduction generated successfully, but the story content is empty. This may be a parsing error.")
		emit_signal("mission_generation_complete")
		return
	var directives: Dictionary = parsed.get("directives", {})
	var ai_choice_payload: Array[Dictionary] = parsed.get("choices", [])
	var mission_title: String = String(parsed.get("mission_title", ""))
	if not mission_title.is_empty():
		var game_state = get_game_state()
		if game_state:
			game_state.current_mission_title = mission_title
	if not directives.is_empty():
		story_scene.apply_scene_directives(directives)
		if directives.has("relationships"):
			_process_relationship_updates(directives["relationships"])
	var sanitized: String = StoryUIHelper.sanitize_story_text(clean_content)
	await _update_story_display(sanitized)
	_last_story_text = sanitized
	var game_state = get_game_state()
	if game_state:
		game_state.set_latest_story_text(sanitized)
		game_state.set_metadata("intro_story_shown", true)
	_refresh_story_nav_buttons()
	_last_story_id += 1
	_update_story_choices(ai_choice_payload, sanitized)
	emit_signal("mission_generation_complete")
func request_journal_story_summary() -> void:
	if _journal_summary_in_flight:
		return
	var game_state = get_game_state()
	if not game_state:
		return
	var story_raw: String = game_state.get_latest_story_text("")
	if story_raw.strip_edges().is_empty():
		return
	var ai_manager = get_ai_manager()
	if not ai_manager:
		return
	_journal_summary_in_flight = true
	var lang: String = game_state.current_language
	var prompt := _build_journal_summary_prompt(story_raw, lang)
	var context := {
		"purpose": "journal_story_summary",
		"language": lang,
		"is_background": true,
	}
	var callback := Callable(self, "_on_journal_story_summary_generated")
	ai_manager.generate_story(prompt, context, callback)
func _build_journal_summary_prompt(story_text: String, lang: String) -> String:
	var max_input_chars := 500
	var truncated := story_text.strip_edges()
	if truncated.length() > max_input_chars:
		truncated = truncated.substr(0, max_input_chars) + "..."
	var lines: Array[String] = []
	if lang == "zh":
		lines.append("You are a game journal summary assistant.")
		lines.append("Please condense the following game story into a concise summary of 10-30 characters.")
		lines.append("Output only the summary text without any punctuation, quotes, or additional explanations.")
		lines.append("")
		lines.append("Story content:")
		lines.append(truncated)
		lines.append("")
		lines.append("Summary (10-30 chars):")
	else:
		lines.append("You are a game journal summary assistant.")
		lines.append("Condense the following game story into a compact 10-30 word summary.")
		lines.append("Output only the summary text, no quotes, punctuation marks, or extra explanation.")
		lines.append("")
		lines.append("Story content:")
		lines.append(truncated)
		lines.append("")
		lines.append("Summary (10-30 words):")
	return "\n".join(lines)
func _on_journal_story_summary_generated(response: Dictionary) -> void:
	_journal_summary_in_flight = false
	if not response.get("success", false):
		return
	var summary := str(response.get("content", "")).strip_edges()
	summary = summary.replace("\"", "").replace("'", "")
	if summary.is_empty():
		return
	var game_state = get_game_state()
	if not game_state:
		return
	var lang: String = game_state.current_language
	var max_summary_chars := 60 if lang == "zh" else 150
	if summary.length() > max_summary_chars:
		summary = summary.substr(0, max_summary_chars) + "..."
	game_state.set_latest_story_summary(summary)
func _schedule_journal_summary_request() -> void:
	if not story_scene:
		return
	var timer := story_scene.get_tree().create_timer(JOURNAL_SUMMARY_DELAY_SEC)
	timer.timeout.connect(_on_journal_summary_timer_expired)
func _on_journal_summary_timer_expired() -> void:
	if _is_generating:
		_schedule_journal_summary_request()
		return
	request_journal_story_summary()
func _record_butterfly_consequence(context: Dictionary, consequence_text: String) -> void:
	var game_state = get_game_state()
	if not game_state or not game_state.butterfly_tracker:
		return
	var tracker = game_state.butterfly_tracker
	if not tracker.has_method("trigger_consequence_for_choice"):
		return
	var choice: Dictionary = context.get("choice", {})
	if choice.is_empty():
		return
	var choice_text: String = String(choice.get("text", "")).strip_edges()
	if choice_text.is_empty():
		return
	var matching_choice: Dictionary = {}
	var recorded_choices: Variant = tracker.get("recorded_choices")
	if recorded_choices is Array:
		for recorded in recorded_choices:
			if recorded is Dictionary:
				var recorded_text: String = String(recorded.get("choice_text", "")).strip_edges()
				if recorded_text == choice_text:
					matching_choice = recorded
					break
	if matching_choice.is_empty():
		_debug_log("[Narrative] Could not find matching butterfly choice for consequence")
		return
	var consequence_summary: String = consequence_text.strip_edges()
	if consequence_summary.length() > 100:
		consequence_summary = consequence_summary.substr(0, 97) + "..."
	var success: bool = bool(context.get("success", false))
	var severity: String = "medium"
	if not success:
		severity = "high"
	elif success and choice.get("type", "") == "critical":
		severity = "low"
	var choice_id: String = String(matching_choice.get("id", ""))
	if not choice_id.is_empty():
		tracker.trigger_consequence_for_choice(choice_id, consequence_summary, severity)
		_debug_log("[Narrative] Recorded butterfly consequence for choice '%s'" % choice_id)
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info("StoryNarrativeController", message)
func _refresh_story_nav_buttons() -> void:
	if story_scene and story_scene.ui_controller:
		story_scene.ui_controller.refresh_nav_buttons()
