extends RefCounted
class_name NarrativeResponseParser
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "NarrativeResponseParser"
const REQUIRED_CHARACTER_IDS := ["protagonist", "gloria", "donkey", "ark", "one"]
const ARCHETYPE_LABELS := {
	"en": {
		"cautious": "[Cautious]",
		"balanced": "[Balanced]",
		"reckless": "[Reckless]",
		"positive": "[Positive]",
		"complain": "[Complain]",
	},
	"zh": {
		"cautious": "[Cautious]",
		"balanced": "[Balanced]",
		"reckless": "[Reckless]",
		"positive": "[Positive]",
		"complain": "[Complain]",
	},
}
static func extract_primary_json_block(raw_text: String) -> String:
	var trimmed := raw_text.strip_edges()
	var depth := 0
	var first_index := -1
	var in_string := false
	var escape_next := false
	for i in range(trimmed.length()):
		var ch := trimmed.substr(i, 1)
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
		if ch == "{":
			if depth == 0:
				first_index = i
			depth += 1
		elif ch == "}":
			if depth > 0:
				depth -= 1
				if depth == 0 and first_index != -1:
					return trimmed.substr(first_index, i - first_index + 1).strip_edges()
	return ""
static func normalize_scene_directives(scene_variant: Variant) -> Dictionary:
	if not (scene_variant is Dictionary):
		return {}
	var scene_dict: Dictionary = (scene_variant as Dictionary).duplicate(true)
	var background := String(scene_dict.get("background", "")).strip_edges().to_lower()
	if background.is_empty():
		background = "default"
	if BackgroundLoader:
		var catalog = BackgroundLoader.get("backgrounds")
		if typeof(catalog) == TYPE_DICTIONARY and not catalog.has(background):
			if catalog.has(background + "_area"):
				background = background + "_area"
			elif background == "fire" and catalog.has("fire_area"):
				background = "fire_area"
			elif catalog.has("default"):
				background = "default"
	scene_dict["background"] = background
	scene_dict["atmosphere"] = String(scene_dict.get("atmosphere", "")).strip_edges()
	scene_dict["lighting"] = String(scene_dict.get("lighting", "")).strip_edges()
	return scene_dict
static func normalize_character_directives(characters_variant: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if characters_variant is Dictionary:
		for key in (characters_variant as Dictionary).keys():
			var value = (characters_variant as Dictionary)[key]
			var entry: Dictionary = {}
			if value is Dictionary:
				entry = (value as Dictionary).duplicate(true)
			else:
				entry["expression"] = String(value)
			var expression := String(entry.get("expression", "neutral")).strip_edges().to_lower()
			if CharacterExpressionLoader and not CharacterExpressionLoader.EXPRESSIONS.has(expression):
				expression = "neutral"
			entry["expression"] = expression if not expression.is_empty() else "neutral"
			normalized[String(key)] = entry
	for required_id in REQUIRED_CHARACTER_IDS:
		if not normalized.has(required_id):
			normalized[required_id] = {"expression": "neutral"}
	return normalized
static func normalize_ai_choice_payload(payload: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if payload is Array:
		for entry in payload:
			if entry is Dictionary:
				var archetype := String(entry.get("archetype", "")).to_lower()
				var summary := String(entry.get("summary", "")).strip_edges()
				if archetype.is_empty() or summary.is_empty():
					continue
				normalized.append({
					"archetype": archetype,
					"summary": summary,
				})
	return normalized
static func normalize_asset_directives(assets_variant: Variant) -> Array:
	var normalized: Array = []
	if assets_variant is Array:
		for entry in assets_variant:
			if entry is Dictionary:
				normalized.append((entry as Dictionary).duplicate(true))
	return normalized
static func extract_archetype_choices_from_text(story_text: String, lang: String) -> Array[Dictionary]:
	var normalized_lang := "zh" if lang == "zh" else "en"
	var label_map: Dictionary = ARCHETYPE_LABELS.get(normalized_lang, ARCHETYPE_LABELS.get("en", {}))
	var plain_text := String(story_text).replace("\r", "\n")
	var results: Array[Dictionary] = []
	for archetype in label_map.keys():
		var label: String = String(label_map[archetype])
		if label.is_empty():
			continue
		var search_index := plain_text.find(label)
		if search_index == -1:
			continue
		var summary := _extract_summary_after_label(plain_text, search_index + label.length())
		if summary.is_empty():
			continue
		results.append({
			"archetype": archetype,
			"summary": summary,
		})
	return results
static func _extract_summary_after_label(text: String, start_idx: int) -> String:
	var end_idx := text.find("\n", start_idx)
	if end_idx == -1:
		end_idx = text.length()
	var summary := text.substr(start_idx, end_idx - start_idx).strip_edges()
	while not summary.is_empty() and (summary.begins_with(":") or summary.begins_with(char(0xFF1A)) or summary.begins_with("-") or summary.begins_with(", ") or summary.begins_with("/")):
		summary = summary.substr(1).strip_edges()
	return summary
static func parse_mission_response(response: Dictionary, ai_manager: Variant) -> Dictionary:
	var result := {
		"success": false,
		"story_text": "",
		"directives": {},
		"choices": [] as Array[Dictionary],
		"mission_title": "",
		"error": "",
	}
	if not response.get("success", false):
		result["error"] = String(response.get("error", "Unknown error"))
		return result
	var story_content: String = String(response.get("content", ""))
	if story_content.is_empty():
		story_content = String(response.get("text", ""))
	if story_content.is_empty():
		result["error"] = "Empty response content"
		return result
	var json_parser := JSON.new()
	var directives: Dictionary = {}
	var clean_content: String = story_content
	var ai_choice_payload: Array[Dictionary] = []
	var json_candidate := extract_primary_json_block(story_content)
	var parse_source := json_candidate if not json_candidate.is_empty() else story_content
	if json_parser.parse(parse_source) == OK and json_parser.data is Dictionary:
		var json_data: Dictionary = json_parser.data
		if json_data.has("mission_title"):
			result["mission_title"] = String(json_data["mission_title"]).strip_edges()
		if json_data.has("scene"):
			directives["scene"] = normalize_scene_directives(json_data["scene"])
		if json_data.has("characters"):
			directives["characters"] = normalize_character_directives(json_data["characters"])
		if json_data.has("assets"):
			directives["assets"] = normalize_asset_directives(json_data["assets"])
		if json_data.has("relationships"):
			directives["relationships"] = json_data["relationships"]
		if json_data.has("story_text"):
			clean_content = String(json_data["story_text"])
		if json_data.has("choices"):
			ai_choice_payload = normalize_ai_choice_payload(json_data.get("choices", []))
	else:
		if ai_manager:
			directives = ai_manager.parse_scene_directives(story_content)
			if directives.has("scene"):
				directives["scene"] = normalize_scene_directives(directives["scene"])
			if directives.has("characters"):
				directives["characters"] = normalize_character_directives(directives["characters"])
			if directives.has("assets"):
				directives["assets"] = normalize_asset_directives(directives["assets"])
			clean_content = ai_manager.extract_story_content(story_content)
	if clean_content.is_empty() and ai_manager:
		clean_content = ai_manager.extract_story_content(story_content)
	var trimmed_content := clean_content.strip_edges()
	var looks_like_raw_json := trimmed_content.begins_with("{") or trimmed_content.begins_with("[")
	if looks_like_raw_json:
		var validation_parser := JSON.new()
		var is_valid_json := validation_parser.parse(trimmed_content) == OK
		if not is_valid_json:
			ErrorReporterBridge.report_info(ERROR_CONTEXT, "Detected incomplete JSON in content, attempting recovery")
			var json_block_str = extract_primary_json_block(story_content)
			if not json_block_str.is_empty():
				clean_content = story_content.replace(json_block_str, "").strip_edges()
			if clean_content.strip_edges().is_empty() or _looks_like_incomplete_json(clean_content):
				if directives.has("story_text"):
					clean_content = String(directives["story_text"])
				elif not directives.is_empty():
					clean_content = _generate_fallback_from_directives(directives)
				else:
					result["error"] = "AI response contains incomplete JSON with no extractable story content"
					return result
		elif trimmed_content.ends_with("}") or trimmed_content.ends_with("]"):
			var json_block_str = extract_primary_json_block(story_content)
			if not json_block_str.is_empty():
				clean_content = story_content.replace(json_block_str, "").strip_edges()
			if clean_content.is_empty() and directives.has("story_text"):
				clean_content = String(directives["story_text"])
			elif clean_content.is_empty():
				clean_content = story_content
	elif trimmed_content.is_empty():
		var json_block_str = extract_primary_json_block(story_content)
		if not json_block_str.is_empty():
			clean_content = story_content.replace(json_block_str, "").strip_edges()
		if clean_content.is_empty() and directives.has("story_text"):
			clean_content = String(directives["story_text"])
		elif clean_content.is_empty():
			clean_content = story_content
	result["success"] = true
	result["story_text"] = clean_content
	result["directives"] = directives
	result["choices"] = ai_choice_payload
	return result
static func _looks_like_incomplete_json(text: String) -> bool:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return false
	if not trimmed.begins_with("{") and not trimmed.begins_with("["):
		return false
	var open_braces := trimmed.count("{")
	var close_braces := trimmed.count("}")
	var open_brackets := trimmed.count("[")
	var close_brackets := trimmed.count("]")
	if open_braces != close_braces or open_brackets != close_brackets:
		return true
	var parser := JSON.new()
	return parser.parse(trimmed) != OK
static func _generate_fallback_from_directives(directives: Dictionary) -> String:
	var parts: Array[String] = []
	if directives.has("scene") and directives["scene"] is Dictionary:
		var scene: Dictionary = directives["scene"]
		var atmosphere := String(scene.get("atmosphere", "")).strip_edges()
		if not atmosphere.is_empty():
			parts.append("The atmosphere is %s." % atmosphere)
	if parts.is_empty():
		return "[Story content loading...]"
	return " ".join(parts)
static func parse_night_cycle_response(response: Dictionary) -> Dictionary:
	var result := {
		"success": false,
		"payload": {},
		"error": "",
	}
	if not response.get("success", false):
		result["error"] = "Response indicates failure"
		return result
	var content: String = String(response.get("content", response.get("text", "")))
	if content.is_empty():
		result["error"] = "Empty response content"
		return result
	var json_parser := JSON.new()
	var json_block = extract_primary_json_block(content)
	if json_block.is_empty():
		json_block = content
	if json_parser.parse(json_block) == OK and json_parser.data is Dictionary:
		result["success"] = true
		result["payload"] = json_parser.data
	else:
		result["error"] = "Failed to parse JSON"
	return result
static func extract_gloria_speech(content: String, ai_manager: Variant) -> String:
	var clean_content := content
	if ai_manager:
		clean_content = ai_manager.extract_story_content(content)
	if clean_content.strip_edges().begins_with("{"):
		var json_check = JSON.new()
		if json_check.parse(clean_content) == OK and json_check.data is Dictionary:
			var data = json_check.data
			for key in ["speech", "text", "content", "gloria_text", "message", "story_text"]:
				if data.has(key):
					return String(data[key])
	if clean_content.strip_edges().is_empty() and not content.strip_edges().is_empty():
		if not content.strip_edges().begins_with("[SCENE"):
			clean_content = content
	if clean_content.strip_edges().is_empty() or clean_content.strip_edges().begins_with("{"):
		return "Gloria glares at you silently..."
	return clean_content
