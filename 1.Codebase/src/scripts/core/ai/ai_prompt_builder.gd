extends RefCounted
class_name AIPromptBuilder
const MAX_PRAYER_LENGTH := 320
const MAX_CHOICE_TEXT_PREVIEW := 60
const MAX_JOURNAL_ENTRIES := 3
const REALITY_SCORE_MAX := 100
const POSITIVE_ENERGY_MAX := 100
const AIPromptsI18n = preload("res://1.Codebase/src/scripts/core/ai/ai_prompts_i18n.gd")
const AIContextDeltaScript = preload("res://1.Codebase/src/scripts/core/ai/ai_context_delta.gd")
var game_state: Node = null
var asset_registry: Node = null
var memory_store: RefCounted = null
var ai_manager: Node = null
var _system_persona: String = ""
var _delta: AIContextDelta = null
var _pre_user_token_reserve: int = 0
func setup(p_game_state: Node, p_asset_registry: Node, p_memory_store: RefCounted, p_ai_manager: Node) -> void:
	game_state = p_game_state
	asset_registry = p_asset_registry
	memory_store = p_memory_store
	ai_manager = p_ai_manager
	_delta = AIContextDeltaScript.new()
func get_delta() -> AIContextDelta:
	return _delta
func reset_delta() -> void:
	if _delta:
		_delta.reset()
func set_system_persona(persona: String) -> void:
	_system_persona = persona
func build_prompt(prompt: String, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	var language := _get_language()
	if not _delta:
		_delta = AIContextDeltaScript.new()
	var minimum_user_message := _build_minimum_user_message(prompt, context, language)
	_pre_user_token_reserve = min(_delta.token_budget, _delta.estimate_tokens(minimum_user_message))
	_delta.begin_build()
	_append_section_incremental(messages, "static_context",
		_get_static_context_messages(language))
	_append_single_incremental(messages, "system_persona",
		{ "role": "system", "content": _system_persona })
	_append_budgeted_message(messages,
		{ "role": "assistant", "content": _get_acknowledgement_message(language) },
		_pre_user_token_reserve)
	_append_section_incremental(messages, "entropy_modifier",
		_get_entropy_modifier_message(language))
	_append_section_incremental(messages, "long_term_context",
		_get_long_term_context(language))
	_append_section_incremental(messages, "notes_context",
		_get_notes_context(language))
	_append_short_term_memory(messages, _get_short_term_memory(), language)
	var user_available_tokens := _delta.remaining_budget()
	var user_message_content := _build_user_message_incremental(
		prompt,
		context,
		language,
		user_available_tokens,
	)
	if _delta.estimate_tokens(user_message_content) > user_available_tokens:
		user_message_content = _truncate_text_to_budget(
			_build_minimum_user_message(prompt, context, language),
			user_available_tokens,
		)
	var user_message := { "role": "user", "content": user_message_content }
	var parts_array: Array = [{ "text": user_message_content }]
	var voice_part := _build_voice_inline_part()
	if not voice_part.is_empty():
		parts_array.append(voice_part)
		user_message["voice_inline_attached"] = true
	user_message["parts"] = parts_array
	messages.append(user_message)
	_delta.add_tokens(_delta.estimate_tokens(user_message_content))
	_pre_user_token_reserve = 0
	_delta.finish_build()
	return messages
func _has_budget_with_reserve(text: String, reserve_tokens: int = 0) -> bool:
	if not _delta:
		return true
	return _delta.get_current_tokens() + _delta.estimate_tokens(text) + reserve_tokens <= _delta.token_budget
func _append_budgeted_message(messages: Array[Dictionary], msg: Dictionary, reserve_tokens: int = 0) -> bool:
	var content: String = str(msg.get("content", ""))
	if content.is_empty():
		return false
	if not _has_budget_with_reserve(content, reserve_tokens):
		return false
	messages.append(msg)
	_delta.add_tokens(_delta.estimate_tokens(content))
	return true
func _append_section_incremental(messages: Array[Dictionary], section_name: String, section_msgs: Array[Dictionary]) -> void:
	if section_msgs.is_empty():
		return
	var fingerprint := _delta.fingerprint_messages(section_msgs)
	if _delta.has_section_changed(section_name, fingerprint):
		if _has_budget_with_reserve(fingerprint, _pre_user_token_reserve):
			for msg in section_msgs:
				messages.append(msg)
			_delta.record_section(section_name, fingerprint)
			_delta.add_tokens(_delta.estimate_tokens(fingerprint))
		else:
			var summary := _summarize_section(section_name, section_msgs)
			if _append_budgeted_message(messages, { "role": "system", "content": summary }):
				_delta.record_section(section_name, summary)
	else:
		_append_budgeted_message(messages, _delta.build_unchanged_marker(section_name), _pre_user_token_reserve)
func _append_single_incremental(messages: Array[Dictionary], section_name: String, msg: Dictionary) -> void:
	var content: String = str(msg.get("content", ""))
	if content.is_empty():
		return
	if _delta.has_section_changed(section_name, content):
		if _has_budget_with_reserve(content, _pre_user_token_reserve):
			messages.append(msg)
			_delta.record_section(section_name, content)
			_delta.add_tokens(_delta.estimate_tokens(content))
		else:
			var summary := _summarize_single_section(section_name, content)
			if _append_budgeted_message(messages, { "role": "system", "content": summary }):
				_delta.record_section(section_name, summary)
	else:
		_append_budgeted_message(messages, _delta.build_unchanged_marker(section_name), _pre_user_token_reserve)
func _summarize_section(section_name: String, section_msgs: Array[Dictionary]) -> String:
	var total_chars := 0
	var msg_count := section_msgs.size()
	for msg in section_msgs:
		total_chars += str(msg.get("content", "")).length()
	return "[context:%s updated, %d messages, ~%d chars - truncated for budget]" % [
		section_name, msg_count, total_chars]
func _summarize_single_section(section_name: String, content: String) -> String:
	return "[context:%s updated, 1 message, ~%d chars - truncated for budget]" % [
		section_name, content.length()]
func _append_short_term_memory(messages: Array[Dictionary], short_term_entries: Array[Dictionary], language: String) -> void:
	var omitted_entries: Array[Dictionary] = []
	for entry in short_term_entries:
		var msg_copy := _sanitize_short_term_entry(entry)
		var content := str(msg_copy.get("content", ""))
		if content.is_empty():
			continue
		if not _should_include_short_term_entry(content, language):
			continue
		if _has_budget_with_reserve(content, _pre_user_token_reserve):
			messages.append(msg_copy)
			_delta.add_tokens(_delta.estimate_tokens(content))
		else:
			omitted_entries.append(msg_copy)
	if omitted_entries.is_empty():
		return
	var summary := _summarize_section("short_term_memory", omitted_entries)
	_append_budgeted_message(messages, { "role": "system", "content": summary })
func _sanitize_short_term_entry(entry: Dictionary) -> Dictionary:
	var msg_copy = entry.duplicate(true)
	if msg_copy.get("role") == "model" or msg_copy.get("role") == "assistant":
		if msg_copy.has("thought_signature"):
			var sanitized_parts: Array = []
			sanitized_parts.append({ "text": str(msg_copy.get("content", "")) })
			if msg_copy.has("parts") and msg_copy["parts"] is Array:
				for part in msg_copy["parts"]:
					if not (part is Dictionary):
						continue
					if part.has("text") or part.has("inlineData") or part.has("fileData") or part.has("functionCall") or part.has("functionResponse"):
						sanitized_parts.append(part)
			sanitized_parts[0]["thoughtSignature"] = str(msg_copy["thought_signature"])
			msg_copy["parts"] = sanitized_parts
			msg_copy.erase("thought_signature")
	return msg_copy
func _build_minimum_user_message(prompt: String, context: Dictionary, language: String) -> String:
	var content_parts: Array[String] = []
	content_parts.append(AIPromptsI18n.get_section_header("session_data", language))
	content_parts.append(AIPromptsI18n.get_language_instruction(language))
	var meta_lines := _build_metadata_lines(context, language)
	if meta_lines.size() > 0:
		content_parts.append("\n".join(meta_lines))
	content_parts.append(_build_prompt_chunk(prompt, language, _delta.token_budget))
	return "\n".join(content_parts)
func _build_user_message_incremental(prompt: String, context: Dictionary, language: String, available_tokens: int = -1) -> String:
	if available_tokens < 0:
		available_tokens = _delta.token_budget
	var content_parts: Array[String] = []
	content_parts.append(AIPromptsI18n.get_section_header("session_data", language))
	content_parts.append(AIPromptsI18n.get_language_instruction(language))
	var meta_lines := _build_metadata_lines(context, language)
	if meta_lines.size() > 0:
		content_parts.append("\n".join(meta_lines))
	if _should_use_compact_user_context(context):
		var compact_used_tokens := _delta.estimate_tokens("\n".join(content_parts))
		var compact_remaining_tokens: int = max(1, available_tokens - compact_used_tokens)
		content_parts.append(_build_prompt_chunk(prompt, language, compact_remaining_tokens))
		return "\n".join(content_parts)
	var used_tokens := _delta.estimate_tokens("\n".join(content_parts))
	var events_block := _collect_recent_events(language)
	used_tokens = _append_user_context_block(content_parts, used_tokens, available_tokens,
		"recent_events", "recent_events", events_block, "[recent_events unchanged]", language)
	var butterfly_block := _collect_butterfly_context(language)
	used_tokens = _append_user_context_block(content_parts, used_tokens, available_tokens,
		"butterfly_effect", "butterfly_effect", butterfly_block, "[butterfly_effect unchanged]", language)
	var reflections_block := _collect_player_reflections(language)
	used_tokens = _append_user_context_block(content_parts, used_tokens, available_tokens,
		"player_reflections", "player_reflections", reflections_block, "[player_reflections unchanged]", language)
	var assets_block := _collect_assets_context(context)
	used_tokens = _append_user_context_block(content_parts, used_tokens, available_tokens,
		"available_assets", "available_assets", assets_block, "[available_assets unchanged]", language)
	var stat_snapshot := _build_stat_snapshot(context, language)
	if not stat_snapshot.is_empty():
		var stat_chunk := "\n" + stat_snapshot
		var stat_tokens := _delta.estimate_tokens(stat_chunk)
		if used_tokens + stat_tokens <= available_tokens:
			content_parts.append(stat_snapshot)
			used_tokens += stat_tokens
	var remaining_tokens: int = max(1, available_tokens - used_tokens)
	content_parts.append(_build_prompt_chunk(prompt, language, remaining_tokens))
	return "\n".join(content_parts)
func _should_use_compact_user_context(context: Dictionary) -> bool:
	var purpose := String(context.get("purpose", "")).strip_edges().to_lower()
	return purpose == "choice_followup"
func _append_user_context_block(content_parts: Array[String], used_tokens: int, available_tokens: int,
	section_name: String, header_key: String, block: String, unchanged_marker: String, language: String) -> int:
	if _delta.has_section_changed(section_name, block):
		if block.is_empty():
			_delta.record_section(section_name, block)
			return used_tokens
		var section_header := "\n" + AIPromptsI18n.get_section_header(header_key, language)
		var section_chunk := section_header + "\n" + block
		var section_tokens := _delta.estimate_tokens(section_chunk)
		if used_tokens + section_tokens <= available_tokens:
			content_parts.append(section_header)
			content_parts.append(block)
			_delta.record_section(section_name, block)
			return used_tokens + section_tokens
		var summary := _summarize_single_section(section_name, block)
		var summary_chunk := "\n" + summary
		var summary_tokens := _delta.estimate_tokens(summary_chunk)
		if used_tokens + summary_tokens <= available_tokens:
			content_parts.append(summary)
			_delta.record_section(section_name, summary)
			return used_tokens + summary_tokens
	elif not block.is_empty():
		var unchanged_chunk := "\n" + unchanged_marker
		var unchanged_tokens := _delta.estimate_tokens(unchanged_chunk)
		if used_tokens + unchanged_tokens <= available_tokens:
			content_parts.append(unchanged_marker)
			return used_tokens + unchanged_tokens
	return used_tokens
func _build_prompt_chunk(prompt: String, language: String, available_tokens: int) -> String:
	var prompt_header := "\n" + AIPromptsI18n.get_section_header("prompt", language) + "\n"
	var prompt_text := prompt.strip_edges()
	var full_chunk := prompt_header + prompt_text
	if available_tokens <= 0:
		return prompt_header + "[prompt truncated for budget]"
	if _delta.estimate_tokens(full_chunk) <= available_tokens:
		return full_chunk
	var truncated_notice := "[prompt truncated for budget]"
	var header_and_notice := prompt_header + truncated_notice
	if _delta.estimate_tokens(header_and_notice) >= available_tokens:
		return _truncate_text_to_budget(header_and_notice, available_tokens)
	var remaining_chars: int = max(0, (available_tokens * AIContextDeltaScript.CHARS_PER_TOKEN) - header_and_notice.length() - 1)
	var truncated_prompt := prompt_text.substr(0, remaining_chars)
	var compact_chunk := prompt_header + truncated_prompt + "\n" + truncated_notice
	return _truncate_text_to_budget(compact_chunk, available_tokens)
func _truncate_text_to_budget(text: String, available_tokens: int) -> String:
	if available_tokens <= 0:
		return ""
	var max_chars: int = max(1, available_tokens * AIContextDeltaScript.CHARS_PER_TOKEN)
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars)
func _collect_recent_events(language: String) -> String:
	if not game_state:
		return ""
	var recent_event_lines: Array = game_state.get_recent_event_notes(6, language)
	if recent_event_lines.size() == 0:
		return ""
	var lines: Array[String] = []
	for line in recent_event_lines:
		lines.append("- " + str(line))
	return "\n".join(lines)
func _collect_butterfly_context(language: String) -> String:
	if not game_state or not game_state.butterfly_tracker:
		return ""
	var butterfly_context: String = game_state.butterfly_tracker.get_context_for_ai(language)
	if butterfly_context.is_empty():
		return ""
	var parts: Array[String] = []
	parts.append(butterfly_context)
	parts.append(AIPromptsI18n.get_butterfly_effect_instruction("reference_past", language))
	parts.append(AIPromptsI18n.get_butterfly_effect_instruction("trigger_callback", language))
	var suggested_choice: Dictionary = game_state.butterfly_tracker.suggest_choice_for_callback()
	if not suggested_choice.is_empty():
		var choice_id: String = suggested_choice.get("id", "")
		var choice_text: String = suggested_choice.get("choice_text", "")
		var scenes_ago: int = game_state.butterfly_tracker.current_scene_number - suggested_choice.get("scene_number", 0)
		var callback_text := AIPromptsI18n.get_butterfly_effect_instruction("suggested_callback", language)
		parts.append(callback_text % [choice_text.left(MAX_CHOICE_TEXT_PREVIEW), scenes_ago, choice_id])
	return "\n".join(parts)
func _collect_player_reflections(language: String) -> String:
	if not game_state:
		return ""
	var reflections: Array = game_state.get_recent_journal_entries(MAX_JOURNAL_ENTRIES)
	if reflections.size() == 0:
		return ""
	var lines: Array[String] = []
	for entry in reflections:
		var timestamp := str(entry.get("timestamp", ""))
		var reflection_text := str(entry.get("text", "")).strip_edges()
		var summary_text := str(entry.get("ai_summary", "")).strip_edges()
		var reflection_line := ""
		if not timestamp.is_empty():
			reflection_line += "[" + timestamp + "] "
		reflection_line += reflection_text
		if not summary_text.is_empty():
			reflection_line += _get_reflection_label(language) + summary_text
		lines.append("- " + reflection_line)
	return "\n".join(lines)
func _collect_assets_context(context: Dictionary) -> String:
	if not asset_registry:
		return ""
	var assets_for_prompt: Array = asset_registry.get_assets_for_context(context)
	if assets_for_prompt.size() == 0:
		return ""
	if game_state:
		var asset_ids: Array = []
		for asset in assets_for_prompt:
			asset_ids.append(asset.get("id", ""))
		game_state.set_metadata("recent_assets_data", assets_for_prompt)
		game_state.set_metadata("recent_asset_icons", asset_registry.get_asset_icons(assets_for_prompt))
		game_state.set_metadata("current_asset_ids", asset_ids)
	var parts: Array[String] = []
	parts.append(asset_registry.format_assets_for_prompt(assets_for_prompt, _get_language()))
	parts.append(AIPromptsI18n.get_text(AIPromptsI18n.ASSET_CONTEXT_INSTRUCTIONS, "freshest_context", _get_language()))
	return "\n".join(parts)
func _build_user_message(prompt: String, context: Dictionary, language: String) -> String:
	var content_parts: Array[String] = []
	content_parts.append(AIPromptsI18n.get_section_header("session_data", language))
	content_parts.append(AIPromptsI18n.get_language_instruction(language))
	var meta_lines := _build_metadata_lines(context, language)
	if meta_lines.size() > 0:
		content_parts.append("\n".join(meta_lines))
	_append_recent_events(content_parts, language)
	_append_butterfly_effect_context(content_parts, language)
	_append_player_reflections(content_parts, language)
	_append_assets_context(content_parts, context)
	_append_stat_snapshot(content_parts, context, language)
	content_parts.append("\n" + AIPromptsI18n.get_section_header("prompt", language))
	content_parts.append(prompt.strip_edges())
	return "\n".join(content_parts)
func _build_metadata_lines(context: Dictionary, language: String) -> Array[String]:
	var meta_lines: Array[String] = []
	if context.has("purpose"):
		var safe_purpose := _sanitize_user_text(str(context["purpose"]))
		if not safe_purpose.is_empty():
			meta_lines.append(_get_metadata_format("purpose", language) % safe_purpose)
	if context.has("choice_text"):
		var safe_choice := _sanitize_user_text(str(context["choice_text"]))
		if not safe_choice.is_empty():
			meta_lines.append(_get_metadata_format("player_choice", language) % safe_choice)
	if context.has("success"):
		meta_lines.append(_get_metadata_format("success_check", language) % ("true" if bool(context["success"]) else "false"))
	if context.has("prayer_text"):
		var safe_prayer := _sanitize_user_text(str(context["prayer_text"]), MAX_PRAYER_LENGTH)
		if not safe_prayer.is_empty():
			meta_lines.append(_get_metadata_format("player_prayer", language) % safe_prayer)
	if context.has("player_action"):
		var safe_action := _sanitize_user_text(str(context["player_action"]))
		if not safe_action.is_empty():
			meta_lines.append(_get_metadata_format("player_action", language) % safe_action)
	if context.has("teammate"):
		var safe_teammate := _sanitize_user_text(str(context["teammate"]))
		if not safe_teammate.is_empty():
			meta_lines.append(_get_metadata_format("current_teammate", language) % safe_teammate)
	return meta_lines
func _append_recent_events(content_parts: Array[String], language: String) -> void:
	if not game_state:
		return
	var recent_event_lines: Array = game_state.get_recent_event_notes(6, language)
	if recent_event_lines.size() > 0:
		content_parts.append("\n" + AIPromptsI18n.get_section_header("recent_events", language))
		for line in recent_event_lines:
			content_parts.append("- " + line)
func _append_butterfly_effect_context(content_parts: Array[String], language: String) -> void:
	if not game_state or not game_state.butterfly_tracker:
		return
	var butterfly_context: String = game_state.butterfly_tracker.get_context_for_ai(language)
	if butterfly_context.is_empty():
		return
	content_parts.append("\n" + AIPromptsI18n.get_section_header("butterfly_effect", language))
	content_parts.append(butterfly_context)
	content_parts.append(AIPromptsI18n.get_butterfly_effect_instruction("reference_past", language))
	content_parts.append(AIPromptsI18n.get_butterfly_effect_instruction("trigger_callback", language))
	var suggested_choice: Dictionary = game_state.butterfly_tracker.suggest_choice_for_callback()
	if not suggested_choice.is_empty():
		var choice_id: String = suggested_choice.get("id", "")
		var choice_text: String = suggested_choice.get("choice_text", "")
		var scenes_ago: int = game_state.butterfly_tracker.current_scene_number - suggested_choice.get("scene_number", 0)
		var callback_text := AIPromptsI18n.get_butterfly_effect_instruction("suggested_callback", language)
		content_parts.append(callback_text % [choice_text.left(MAX_CHOICE_TEXT_PREVIEW), scenes_ago, choice_id])
func _append_player_reflections(content_parts: Array[String], language: String) -> void:
	if not game_state:
		return
	var reflections: Array = game_state.get_recent_journal_entries(MAX_JOURNAL_ENTRIES)
	if reflections.size() == 0:
		return
	content_parts.append("\n" + AIPromptsI18n.get_section_header("player_reflections", language))
	for entry in reflections:
		var timestamp := str(entry.get("timestamp", ""))
		var reflection_text := str(entry.get("text", "")).strip_edges()
		var summary_text := str(entry.get("ai_summary", "")).strip_edges()
		var reflection_line := ""
		if not timestamp.is_empty():
			reflection_line += "[" + timestamp + "] "
		reflection_line += reflection_text
		if not summary_text.is_empty():
			reflection_line += _get_reflection_label(language) + summary_text
		content_parts.append("- " + reflection_line)
func _append_assets_context(content_parts: Array[String], context: Dictionary) -> void:
	if not asset_registry:
		return
	var assets_for_prompt: Array = asset_registry.get_assets_for_context(context)
	if assets_for_prompt.size() == 0:
		return
	if game_state:
		var asset_ids: Array = []
		for asset in assets_for_prompt:
			asset_ids.append(asset.get("id", ""))
		game_state.set_metadata("recent_assets_data", assets_for_prompt)
		game_state.set_metadata("recent_asset_icons", asset_registry.get_asset_icons(assets_for_prompt))
		game_state.set_metadata("current_asset_ids", asset_ids)
	var language := _get_language()
	content_parts.append("\n" + AIPromptsI18n.get_section_header("available_assets", language))
	content_parts.append(asset_registry.format_assets_for_prompt(assets_for_prompt, language))
	content_parts.append(AIPromptsI18n.get_text(AIPromptsI18n.ASSET_CONTEXT_INSTRUCTIONS, "freshest_context", language))
func _build_stat_snapshot(context: Dictionary, language: String) -> String:
	var stat_parts: Array[String] = []
	if context.has("reality_score"):
		stat_parts.append(_get_stat_format("reality", language) % [int(context["reality_score"]), REALITY_SCORE_MAX])
	if context.has("positive_energy"):
		stat_parts.append(_get_stat_format("positive", language) % [int(context["positive_energy"]), POSITIVE_ENERGY_MAX])
	if context.has("entropy_level"):
		stat_parts.append(_get_stat_format("entropy", language) % int(context["entropy_level"]))
	elif context.has("entropy"):
		stat_parts.append(_get_stat_format("entropy", language) % int(context["entropy"]))
	if stat_parts.size() > 0:
		return _get_stat_format("stats_label", language) % ", ".join(stat_parts)
	return ""
func _append_stat_snapshot(content_parts: Array[String], context: Dictionary, language: String) -> void:
	var stat_snapshot := _build_stat_snapshot(context, language)
	if not stat_snapshot.is_empty():
		content_parts.append(stat_snapshot)
func _get_language() -> String:
	return game_state.current_language if game_state else "en"
func _get_static_context_messages(language: String) -> Array[Dictionary]:
	if ai_manager and ai_manager.has_method("_get_static_context_messages"):
		return ai_manager._get_static_context_messages(language)
	return []
func _get_entropy_modifier_message(language: String) -> Array[Dictionary]:
	if ai_manager and ai_manager.has_method("_get_entropy_modifier_message"):
		return ai_manager._get_entropy_modifier_message(language)
	return []
func _get_long_term_context(language: String) -> Array[Dictionary]:
	if memory_store and memory_store.has_method("get_long_term_context"):
		return _coerce_message_array(memory_store.get_long_term_context(language))
	return []
func _get_notes_context(language: String) -> Array[Dictionary]:
	if memory_store and memory_store.has_method("get_notes_context"):
		return _coerce_message_array(memory_store.get_notes_context(language))
	return []
func _get_short_term_memory() -> Array[Dictionary]:
	if memory_store and memory_store.has_method("get_short_term_memory"):
		return _coerce_message_array(memory_store.get_short_term_memory())
	return []
func _build_voice_inline_part() -> Dictionary:
	if ai_manager and ai_manager.has_method("_build_voice_inline_part"):
		return ai_manager._build_voice_inline_part()
	return { }
func _sanitize_user_text(text: String, max_length: int = 256) -> String:
	if ai_manager and ai_manager.has_method("sanitize_user_text"):
		return ai_manager.sanitize_user_text(text, max_length)
	return text.strip_edges()
func _should_include_short_term_entry(content: String, language: String) -> bool:
	if language == "zh":
		return true
	return not _contains_cjk(content)
func _contains_cjk(text: String) -> bool:
	for i in range(text.length()):
		var codepoint := text.unicode_at(i)
		if (codepoint >= 0x3400 and codepoint <= 0x4DBF) or (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or (codepoint >= 0xF900 and codepoint <= 0xFAFF):
			return true
	return false
func _get_metadata_format(key: String, language: String) -> String:
	return AIPromptsI18n.get_text(AIPromptsI18n.METADATA_LABELS, key, language)
func _get_stat_format(key: String, language: String) -> String:
	return AIPromptsI18n.get_text(AIPromptsI18n.STATS_FORMAT, key, language)
func _get_reflection_label(language: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation("AI_CTX_INSIGHT_LABEL", language)
	return " | Insight: "
func _get_acknowledgement_message(language: String) -> String:
	if LocalizationManager:
		var localized := LocalizationManager.get_translation("AI_CTX_ACKNOWLEDGEMENT_MESSAGE", language)
		if localized != "AI_CTX_ACKNOWLEDGEMENT_MESSAGE":
			return localized
	return "Acknowledged. I will maintain ironic, pessimistic storytelling for GDA1 while enforcing the recorded facts."
func _coerce_message_array(raw_messages) -> Array[Dictionary]:
	var safe_messages: Array[Dictionary] = []
	if raw_messages is Array:
		for entry in raw_messages:
			if entry is Dictionary:
				safe_messages.append((entry as Dictionary).duplicate(true))
			elif entry != null:
				safe_messages.append({ "role": "system", "content": str(entry) })
	return safe_messages
