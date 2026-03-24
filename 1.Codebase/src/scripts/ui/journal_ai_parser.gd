extends RefCounted
class_name JournalAIParser

## Pure stateless helper for JournalSystem.
##
## Contains all prompt-building and response-parsing logic that has no
## dependency on node state.  Pass a `tr_fn: Callable` (e.g.
## Callable(self, "_tr")) to functions that need localized strings.
##
## Usage:
##   var suggestions = JournalAIParser.parse_suggestions(raw_text, MAX_SUGGESTIONS)
##   var prompt = JournalAIParser.build_suggestion_prompt(story, events, stats, tr_fn, lang, MAX, LIMIT)

# ── Suggestion prompt building ─────────────────────────────────────────────────

static func build_suggestion_prompt(
	story_excerpt: String,
	events_text: String,
	stats: Dictionary,
	tr_fn: Callable,
	language: String,
	max_suggestions: int,
	word_limit: int,
) -> String:
	var lines: Array[String] = []
	var reality := int(stats.get("reality", 0))
	var positive := int(stats.get("positive", 0))
	var entropy := int(stats.get("entropy", 0))
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_ROLE"))
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_OBJECTIVE"))
	lines.append("")
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_MISSION_HEADER"))
	lines.append(story_excerpt)
	lines.append("")
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_EVENTS_HEADER"))
	lines.append(events_text)
	lines.append("")
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_STATS_HEADER"))
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_STAT_REALITY") % reality)
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_STAT_POSITIVE") % positive)
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_STAT_ENTROPY") % entropy)
	lines.append("")
	for guardrail in build_guardrail_lines(tr_fn, max_suggestions, word_limit):
		lines.append(guardrail)
	lines.append("")
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_JSON_RULE"))
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_STRUCTURE"))
	lines.append("{")
	lines.append("  \"language\": \"%s\"," % language)
	lines.append("  \"tone\": \"dark_humor\",")
	lines.append("  \"suggestions\": [")
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_TEMPLATE_TEXT") % word_limit)
	lines.append("  ]")
	lines.append("}")
	lines.append(tr_fn.call("JOURNAL_AI_PROMPT_FINAL_INSTRUCTION") % [max_suggestions, word_limit])
	return "\n".join(lines)

static func build_guardrail_lines(tr_fn: Callable, max_suggestions: int, word_limit: int) -> Array[String]:
	var lines: Array[String] = []
	lines.append(tr_fn.call("JOURNAL_AI_SUGGESTION_JSON"))
	lines.append(tr_fn.call("JOURNAL_AI_SUGGESTION_COUNT") % max_suggestions)
	lines.append(tr_fn.call("JOURNAL_AI_SUGGESTION_LIMIT") % word_limit)
	lines.append(tr_fn.call("JOURNAL_AI_SUGGESTION_TONE"))
	return lines

static func fallback_suggestions(tr_fn: Callable) -> Array[String]:
	return [
		tr_fn.call("JOURNAL_FALLBACK_SUGGESTION_1"),
		tr_fn.call("JOURNAL_FALLBACK_SUGGESTION_2"),
		tr_fn.call("JOURNAL_FALLBACK_SUGGESTION_3"),
	]

# ── Story summary prompt building ─────────────────────────────────────────────

static func build_story_summary_prompt(story_text: String, tr_fn: Callable) -> String:
	const MAX_INPUT_CHARS := 500
	var truncated := story_text
	if truncated.length() > MAX_INPUT_CHARS:
		truncated = truncated.substr(0, MAX_INPUT_CHARS) + "..."
	var lines: Array[String] = []
	lines.append(tr_fn.call("JOURNAL_AI_SUMMARY_ROLE"))
	lines.append(tr_fn.call("JOURNAL_AI_SUMMARY_INSTRUCTION"))
	lines.append(tr_fn.call("JOURNAL_AI_SUMMARY_FORMAT"))
	lines.append("")
	lines.append(tr_fn.call("JOURNAL_AI_SUMMARY_STORY_LABEL"))
	lines.append(truncated)
	lines.append("")
	lines.append(tr_fn.call("JOURNAL_AI_SUMMARY_OUTPUT_LABEL"))
	return "\n".join(lines)

# ── Suggestion response parsing ────────────────────────────────────────────────

static func parse_suggestions(raw_text: String, max_suggestions: int) -> Array[String]:
	var cleaned := raw_text.strip_edges()
	if cleaned.is_empty():
		return []
	var json_candidate := extract_primary_json_block(cleaned)
	if json_candidate.is_empty() and cleaned.begins_with("["):
		json_candidate = cleaned
	if not json_candidate.is_empty():
		var parsed: Array[String] = _try_parse_json_suggestions(json_candidate, max_suggestions)
		if parsed.size() > 0:
			return parsed
	var fallback: Array[String] = _parse_list_suggestions_from_text(cleaned, max_suggestions)
	if fallback.size() > 0:
		return fallback
	return []

static func _try_parse_json_suggestions(json_text: String, max_suggestions: int) -> Array[String]:
	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		return []
	return _normalize_suggestion_payload(parser.data, max_suggestions)

static func _normalize_suggestion_payload(payload: Variant, max_suggestions: int) -> Array[String]:
	var suggestions: Array[String] = []
	if payload is Dictionary:
		var dict_payload: Dictionary = (payload as Dictionary)
		if dict_payload.has("suggestions"):
			var nested: Array[String] = _normalize_suggestion_payload(dict_payload.get("suggestions", []), max_suggestions)
			if nested.size() > 0:
				return nested
		if dict_payload.has("items"):
			var alt: Array[String] = _normalize_suggestion_payload(dict_payload.get("items", []), max_suggestions)
			if alt.size() > 0:
				return alt
		var single: String = _collect_text_from_dict(dict_payload)
		if not single.is_empty():
			suggestions.append(single)
	elif payload is Array:
		for entry in (payload as Array):
			var text: String = ""
			if entry is Dictionary:
				text = _collect_text_from_dict(entry)
			elif entry is String:
				text = strip_list_prefix(entry)
			else:
				text = strip_list_prefix(str(entry))
			if text.is_empty():
				continue
			suggestions.append(text)
			if suggestions.size() >= max_suggestions:
				break
	if suggestions.size() > max_suggestions:
		suggestions.resize(max_suggestions)
	return suggestions

static func _collect_text_from_dict(data: Dictionary) -> String:
	var text_keys := ["text", "prompt", "content", "body", "summary", "value", "note"]
	for key in text_keys:
		if data.has(key):
			var candidate := str(data.get(key, "")).strip_edges()
			if not candidate.is_empty():
				return candidate
	var title := str(data.get("title", "")).strip_edges()
	var description := str(data.get("description", "")).strip_edges()
	var details := str(data.get("details", description)).strip_edges()
	if not title.is_empty() and not details.is_empty():
		return "%s: %s" % [title, details]
	if not title.is_empty():
		return title
	if not details.is_empty():
		return details
	return ""

static func _parse_list_suggestions_from_text(raw_text: String, max_suggestions: int) -> Array[String]:
	var suggestions: Array[String] = []
	var lines := raw_text.split("\n")
	for line in lines:
		var cleaned_line := strip_list_prefix(line)
		if cleaned_line.is_empty():
			continue
		suggestions.append(cleaned_line)
		if suggestions.size() >= max_suggestions:
			break
	if suggestions.is_empty():
		var alt_lines := raw_text.split("\r")
		for segment in alt_lines:
			var candidate := strip_list_prefix(segment)
			if candidate.is_empty():
				continue
			suggestions.append(candidate)
			if suggestions.size() >= max_suggestions:
				break
	if suggestions.size() > max_suggestions:
		suggestions.resize(max_suggestions)
	return suggestions

static func strip_list_prefix(line: String) -> String:
	var trimmed := line.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed.length() >= 2:
		var first_two := trimmed.substr(0, 2)
		if first_two == "- " or first_two == "* ":
			return trimmed.substr(2).strip_edges()
	var first_char := trimmed.substr(0, 1)
	if first_char.is_valid_int():
		if trimmed.length() > 1:
			var second_char := trimmed.substr(1, 1)
			if second_char == "." or second_char == ")" or second_char == ":":
				return trimmed.substr(2).strip_edges()
			if second_char == " " and trimmed.length() > 2:
				return trimmed.substr(2).strip_edges()
	if trimmed.begins_with("("):
		var closing_index := trimmed.find(")")
		if closing_index > 0 and closing_index < 4:
			return trimmed.substr(closing_index + 1).strip_edges()
	return trimmed

static func extract_primary_json_block(raw_text: String) -> String:
	var trimmed := raw_text.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed.begins_with("{") or trimmed.begins_with("["):
		return trimmed
	var stack: Array[String] = []
	var first_index := -1
	var in_string := false
	var escape_next := false
	for i in range(raw_text.length()):
		var ch := raw_text.substr(i, 1)
		if escape_next:
			escape_next = false
			continue
		if ch == "\\":
			escape_next = true
			continue
		if ch == "\"":
			in_string = not in_string
			continue
		if in_string:
			continue
		if ch == "{" or ch == "[":
			if stack.is_empty():
				first_index = i
			stack.append(ch)
		elif ch == "}" or ch == "]":
			if stack.is_empty():
				continue
			var expected: String = stack.back()
			if (expected == "{" and ch == "}") or (expected == "[" and ch == "]"):
				stack.pop_back()
				if stack.is_empty() and first_index != -1:
					return raw_text.substr(first_index, i - first_index + 1).strip_edges()
	return ""

# ── Story text cleaning (game-story JSON aware) ───────────────────────────────

static func extract_clean_story_text(raw_text: String) -> String:
	var trimmed := raw_text.strip_edges()
	if trimmed.is_empty():
		return ""
	if looks_like_raw_json(trimmed):
		var extracted := try_extract_story_from_json(trimmed)
		if not extracted.is_empty():
			return extracted
	var clean := remove_json_fragments(trimmed)
	return clean.strip_edges()

static func looks_like_raw_json(text: String) -> bool:
	if text.begins_with("{") or text.begins_with("["):
		return true
	if text.find("\"expression\":") >= 0:
		return true
	if text.find("\"relationships\":") >= 0:
		return true
	if text.find("\"teammateReactions\":") >= 0:
		return true
	if text.find("\"storyText\":") >= 0:
		return true
	return false

static func try_extract_story_from_json(text: String) -> String:
	var story_key_patterns := [
		"\"storyText\":",
		"\"story_text\":",
		"\"narrative\":",
		"\"content\":",
		"\"text\":",
	]
	for pattern in story_key_patterns:
		var idx := text.find(pattern)
		if idx < 0:
			continue
		var value_start: int = idx + pattern.length()
		while value_start < text.length() and text[value_start] in " \t\n":
			value_start += 1
		if value_start >= text.length():
			continue
		if text[value_start] == "\"":
			var value_end := _find_json_string_end(text, value_start + 1)
			if value_end > value_start:
				var extracted := text.substr(value_start + 1, value_end - value_start - 1)
				extracted = extracted.replace("\\n", "\n").replace("\\\"", "\"")
				return extracted.strip_edges()
	return ""

static func _find_json_string_end(text: String, start: int) -> int:
	var i := start
	while i < text.length():
		if text[i] == "\\":
			i += 2
			continue
		if text[i] == "\"":
			return i
		i += 1
	return -1

static func remove_json_fragments(text: String) -> String:
	var result := text
	var patterns := [
		RegEx.new(),
		RegEx.new(),
		RegEx.new(),
		RegEx.new(),
	]
	patterns[0].compile("\"[a-zA-Z_]+\"\\s*:\\s*\\{[^}]*\\}")
	patterns[1].compile("\"expression\"\\s*:\\s*\"[^\"]*\"")
	patterns[2].compile("\"relationships\"\\s*:\\s*\\[[^\\]]*\\]")
	patterns[3].compile("\"[a-zA-Z_]+\"\\s*:\\s*\\[[^\\]]*\\]")
	for regex in patterns:
		result = regex.sub(result, "", true)
	result = result.replace(",\n", "\n").replace(",}", "}")
	var multi_space := RegEx.new()
	multi_space.compile("\\s{3,}")
	result = multi_space.sub(result, " ", true)
	return result.strip_edges()
