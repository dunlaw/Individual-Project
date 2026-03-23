extends Node
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "CharacterExpressionLoader"
const CHARACTERS = {
	"protagonist": "protagonist",
	"gloria": "gloria",
	"donkey": "donkey",
	"ark": "ark",
	"one": "one",
	"teacher_chan": "teacher_chan",
}
const CHARACTER_ALIASES := {
	"you": "protagonist",
	"player": "protagonist",
	"main_character": "protagonist",
	"main character": "protagonist",
	"hero": "protagonist",
}
const EXPRESSIONS = {
	"neutral": "neutral",
	"happy": "happy",
	"sad": "sad",
	"angry": "angry",
	"confused": "confused",
	"shocked": "shocked",
	"thinking": "thinking",
	"embarrassed": "embarrassed",
}
const CHARACTER_ASSET_ROOT := "res://1.Codebase/src/assets/characters"
const LEGACY_EXPRESSIONS_SUBDIR := CHARACTER_ASSET_ROOT + "/expressions"
const SUPPORTED_TEXTURE_EXTENSIONS := ["png", "webp"]
const _PRELOADED_EXPRESSION_PATHS := {
	"protagonist": {
		"neutral": "res://1.Codebase/src/assets/characters/protagonist_neutral.png",
		"happy": "res://1.Codebase/src/assets/characters/protagonist_happy.png",
		"sad": "res://1.Codebase/src/assets/characters/protagonist_sad.png",
		"angry": "res://1.Codebase/src/assets/characters/protagonist_angry.png",
		"confused": "res://1.Codebase/src/assets/characters/protagonist_confused.png",
		"shocked": "res://1.Codebase/src/assets/characters/protagonist_shocked.png",
		"thinking": "res://1.Codebase/src/assets/characters/protagonist_thinking.png",
		"embarrassed": "res://1.Codebase/src/assets/characters/protagonist_embarrassed.png",
	},
	"gloria": {
		"neutral": "res://1.Codebase/src/assets/characters/gloria_protagonis_neutral.png",
		"happy": "res://1.Codebase/src/assets/characters/gloria_protagonis_happy.png",
		"sad": "res://1.Codebase/src/assets/characters/gloria_protagonis_sad.png",
		"angry": "res://1.Codebase/src/assets/characters/gloria_protagonis_angry.png",
		"confused": "res://1.Codebase/src/assets/characters/gloria_protagonis_confused.png",
		"shocked": "res://1.Codebase/src/assets/characters/gloria_protagonis_shocked.png",
		"thinking": "res://1.Codebase/src/assets/characters/gloria_protagonis_thinking.png",
		"embarrassed": "res://1.Codebase/src/assets/characters/gloria_protagonis_embarrassed.png",
	},
	"donkey": {
		"neutral": "res://1.Codebase/src/assets/characters/donkey_neutral.png",
		"happy": "res://1.Codebase/src/assets/characters/donkey_happy.png",
		"sad": "res://1.Codebase/src/assets/characters/donkey_sad.png",
		"angry": "res://1.Codebase/src/assets/characters/donkey_angry.png",
		"confused": "res://1.Codebase/src/assets/characters/donkey_confused.png",
		"shocked": "res://1.Codebase/src/assets/characters/donkey_shocked.png",
		"thinking": "res://1.Codebase/src/assets/characters/donkey_thinking.png",
		"embarrassed": "res://1.Codebase/src/assets/characters/donkey_embarrassed.png",
	},
	"ark": {
		"neutral": "res://1.Codebase/src/assets/characters/ark_neutral.png",
		"happy": "res://1.Codebase/src/assets/characters/ark_happy.png",
		"sad": "res://1.Codebase/src/assets/characters/ark_sad.png",
		"angry": "res://1.Codebase/src/assets/characters/ark_angry.png",
		"confused": "res://1.Codebase/src/assets/characters/ark_confused.png",
		"shocked": "res://1.Codebase/src/assets/characters/ark_shocked.png",
		"thinking": "res://1.Codebase/src/assets/characters/ark_thinking.png",
		"embarrassed": "res://1.Codebase/src/assets/characters/ark_embarrassed.png",
	},
	"one": {
		"neutral": "res://1.Codebase/src/assets/characters/one_neutral.png",
		"happy": "res://1.Codebase/src/assets/characters/one_happy.png",
		"sad": "res://1.Codebase/src/assets/characters/one_sad.png",
		"angry": "res://1.Codebase/src/assets/characters/one_angry.png",
		"confused": "res://1.Codebase/src/assets/characters/one_confused.png",
		"shocked": "res://1.Codebase/src/assets/characters/one_shocked.png",
		"thinking": "res://1.Codebase/src/assets/characters/one_thinking.png",
		"embarrassed": "res://1.Codebase/src/assets/characters/one_embarrassed.png",
	},
	"teacher_chan": {
		"neutral": "res://1.Codebase/src/assets/characters/teacher_chan_neutral.png",
		"happy": "res://1.Codebase/src/assets/characters/teacher_chan_happy.png",
		"sad": "res://1.Codebase/src/assets/characters/teacher_chan_sad.png",
		"angry": "res://1.Codebase/src/assets/characters/teacher_chan_angry.png",
		"confused": "res://1.Codebase/src/assets/characters/teacher_chan_confused.png",
		"shocked": "res://1.Codebase/src/assets/characters/teacher_chan_shocked.png",
		"thinking": "res://1.Codebase/src/assets/characters/teacher_chan_thinking.png",
		"embarrassed": "res://1.Codebase/src/assets/characters/teacher_chan_embarrassed.png",
	},
}
const _PRELOADED_PORTRAIT_PATHS := {
	"protagonist": "res://1.Codebase/src/assets/characters/protagonist_neutral.png",
	"gloria": "res://1.Codebase/src/assets/characters/gloria_protagonis_neutral.png",
	"donkey": "res://1.Codebase/src/assets/characters/donkey_neutral.png",
	"ark": "res://1.Codebase/src/assets/characters/ark_neutral.png",
	"one": "res://1.Codebase/src/assets/characters/one_neutral.png",
	"teacher_chan": "res://1.Codebase/src/assets/characters/teacher_chan_neutral.png",
}
const DEFAULT_TEXTURE_CACHE_CAPACITY := 24
var character_data: Dictionary = {
	"protagonist": {
		"id": "protagonist",
		"name": "You",
		"name_cn": "You",
		"default_portrait": "res://1.Codebase/src/assets/characters/protagonist_neutral.png",
		"expressions": { },
	},
	"gloria": {
		"id": "gloria",
		"name": "Gloria",
		"name_cn": "Saint Gloria",
		"default_portrait": "res://1.Codebase/src/assets/characters/gloria_protagonis_neutral.png",
		"expressions": { },
	},
	"donkey": {
		"id": "donkey",
		"name": "Knight Donkey",
		"name_cn": "Knight Donkey",
		"default_portrait": "res://1.Codebase/src/assets/characters/donkey_neutral.png",
		"expressions": { },
	},
	"ark": {
		"id": "ark",
		"name": "Archivist ARK",
		"name_cn": "Archivist ARK",
		"default_portrait": "res://1.Codebase/src/assets/characters/ark_neutral.png",
		"expressions": { },
	},
	"one": {
		"id": "one",
		"name": "One",
		"name_cn": "One",
		"default_portrait": "res://1.Codebase/src/assets/characters/one_neutral.png",
		"expressions": { },
	},
	"teacher_chan": {
		"id": "teacher_chan",
		"name": "Teacher Chan",
		"name_cn": "Teacher Chan",
		"default_portrait": "res://1.Codebase/src/assets/characters/teacher_chan_neutral.png",
		"expressions": { },
	},
}
var character_manifest: Dictionary = { }
var _texture_cache: LRUCache = LRUCache.new(DEFAULT_TEXTURE_CACHE_CAPACITY)
func _ready():
	_build_expression_manifest()
func _exit_tree() -> void:
	character_data.clear()
	character_manifest.clear()
	_texture_cache.clear()
func _build_expression_manifest() -> void:
	character_manifest.clear()
	var registered_count := 0
	for char_id in _PRELOADED_EXPRESSION_PATHS.keys():
		var entry: Dictionary = _ensure_character_entry(char_id)
		var expression_paths: Dictionary = {}
		var preloaded_exprs: Dictionary = _PRELOADED_EXPRESSION_PATHS.get(char_id, {})
		for expression in preloaded_exprs.keys():
			var texture_path := String(preloaded_exprs[expression])
			expression_paths[expression] = texture_path
			registered_count += 1
		character_data[char_id] = entry
		character_manifest[char_id] = {
			"default_portrait": entry.get("default_portrait", ""),
			"expressions": expression_paths.keys(),
			"expression_paths": expression_paths,
		}
	for char_id in _PRELOADED_PORTRAIT_PATHS.keys():
		if not character_manifest.has(char_id) or character_manifest[char_id].get("expression_paths", {}).is_empty():
			var portrait_path := String(_PRELOADED_PORTRAIT_PATHS.get(char_id, ""))
			var entry: Dictionary = _ensure_character_entry(char_id)
			character_data[char_id] = entry
			character_manifest[char_id] = {
				"default_portrait": entry.get("default_portrait", ""),
				"expressions": ["neutral"],
				"expression_paths": { "neutral": portrait_path },
			}
			registered_count += 1
	_report_info("Registered %d expression paths (lazy-load with LRU cache, capacity=%d)." % [registered_count, _texture_cache.get_capacity()])
	var discovered_assets := _scan_character_assets()
	var additional_count := 0
	for char_id in discovered_assets.keys():
		var entry: Dictionary = _ensure_character_entry(char_id)
		var manifest_entry: Dictionary = discovered_assets[char_id]
		if manifest_entry.has("default_portrait"):
			entry["default_portrait"] = manifest_entry.get("default_portrait", "")
		character_data[char_id] = entry
		var existing_manifest: Dictionary = character_manifest.get(char_id, {})
		var existing_paths: Dictionary = existing_manifest.get("expression_paths", {})
		if manifest_entry.has("expressions"):
			var expr_map: Dictionary = manifest_entry.get("expressions", {})
			for expression in expr_map.keys():
				if existing_paths.has(expression):
					continue
				existing_paths[expression] = expr_map.get(expression, "")
				additional_count += 1
		if not existing_paths.has("neutral"):
			var default_path: String = String(entry.get("default_portrait", ""))
			if default_path != "":
				existing_paths["neutral"] = default_path
				additional_count += 1
		existing_manifest["default_portrait"] = entry.get("default_portrait", "")
		existing_manifest["expressions"] = existing_paths.keys()
		existing_manifest["expression_paths"] = existing_paths
		character_manifest[char_id] = existing_manifest
	if additional_count > 0:
		_report_info("Registered %d additional expression paths via directory scan." % additional_count)
	_report_info("Total: %d character expression paths registered." % _count_total_expressions())
func _count_total_expressions() -> int:
	var total := 0
	for char_id in character_manifest.keys():
		var manifest_entry: Dictionary = character_manifest[char_id]
		var paths: Dictionary = manifest_entry.get("expression_paths", {})
		total += paths.size()
	return total
func get_character_texture(char_id: String, expression: String = "neutral") -> Texture2D:
	var canonical_id := _resolve_character_id(char_id)
	if not character_data.has(canonical_id):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Unknown character: %s" % char_id,
			{ "char_id": char_id },
		)
		return null
	var cache_key := "%s_%s" % [canonical_id, expression]
	var cached_texture = _texture_cache.get_value(cache_key)
	if cached_texture != null:
		return cached_texture
	var manifest_entry: Dictionary = character_manifest.get(canonical_id, {})
	var expression_paths: Dictionary = manifest_entry.get("expression_paths", {})
	if expression_paths.has(expression):
		var texture := _load_texture(String(expression_paths[expression]))
		if texture:
			_texture_cache.put(cache_key, texture)
			return texture
	var neutral_key := "%s_neutral" % canonical_id
	var neutral_cached = _texture_cache.get_value(neutral_key)
	if neutral_cached != null:
		return neutral_cached
	if expression_paths.has("neutral"):
		var texture := _load_texture(String(expression_paths["neutral"]))
		if texture:
			_texture_cache.put(neutral_key, texture)
			return texture
	var char_entry: Dictionary = character_data[canonical_id]
	if char_entry.has("default_portrait"):
		var default_path: String = String(char_entry.get("default_portrait", ""))
		if default_path != "":
			var texture := _load_texture(default_path)
			if texture:
				_texture_cache.put(neutral_key, texture)
				return texture
	return null
func get_character_name(char_id: String, use_chinese: bool = false) -> String:
	var canonical_id := _resolve_character_id(char_id)
	if not character_data.has(canonical_id):
		return ""
	var char = character_data[canonical_id]
	if use_chinese and char.has("name_cn"):
		return char.name_cn
	return char.get("name", "")
func get_all_characters() -> Array:
	return character_data.keys()
func get_manifest() -> Dictionary:
	return character_manifest.duplicate(true)
func get_canonical_id(char_id: String) -> String:
	return _resolve_character_id(char_id)
func get_expression_path(char_id: String, expression: String = "neutral") -> String:
	var canonical_id := _resolve_character_id(char_id)
	if not character_manifest.has(canonical_id):
		return ""
	var manifest_entry: Dictionary = character_manifest[canonical_id]
	var path_map: Dictionary = manifest_entry.get("expression_paths", { })
	if path_map.has(expression):
		return String(path_map[expression])
	return String(manifest_entry.get("default_portrait", ""))
func has_character(char_id: String) -> bool:
	var canonical_id := _resolve_character_id(char_id)
	return character_data.has(canonical_id)
func get_available_expressions(char_id: String) -> Array:
	var canonical_id := _resolve_character_id(char_id)
	if not character_manifest.has(canonical_id):
		return []
	var manifest_entry: Dictionary = character_manifest[canonical_id]
	return manifest_entry.get("expressions", []).duplicate()
func _scan_character_assets() -> Dictionary:
	var results: Dictionary = { }
	var pending: Array = [CHARACTER_ASSET_ROOT]
	while pending.size() > 0:
		var current_path: String = pending.pop_back()
		var dir := DirAccess.open(current_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		while true:
			var entry := dir.get_next()
			if entry == "":
				break
			if entry == "." or entry == "..":
				continue
			var entry_path := "%s/%s" % [current_path, entry]
			if dir.current_is_dir():
				if entry.begins_with("."):
					continue
				pending.append(entry_path)
				continue
			if entry.begins_with("."):
				continue
			var extension := entry.get_extension().to_lower()
			if SUPPORTED_TEXTURE_EXTENSIONS.find(extension) == -1:
				continue
			var base_name := entry.get_basename()
			_register_character_asset(results, base_name, entry_path)
		dir.list_dir_end()
	return results
func _register_character_asset(results: Dictionary, base_name: String, resource_path: String) -> void:
	var lowered_name := base_name.to_lower().strip_edges()
	if lowered_name == "":
		return
	if lowered_name.begins_with("portrait_"):
		var raw_char_id := lowered_name.substr(9, lowered_name.length() - 9)
		var char_id := _resolve_character_id(raw_char_id)
		var entry := _get_or_create_manifest_entry(results, char_id)
		entry["default_portrait"] = resource_path
		results[char_id] = entry
		return
	var sanitized := lowered_name
	sanitized = sanitized.replace("(", "_").replace(")", "")
	sanitized = sanitized.replace("[", "_").replace("]", "")
	sanitized = sanitized.replace("{", "_").replace("}", "")
	sanitized = sanitized.replace("'", "").replace("\"", "")
	sanitized = sanitized.replace("-", "_").replace(" ", "_")
	while sanitized.contains("__"):
		sanitized = sanitized.replace("__", "_")
	var parts := sanitized.split("_")
	if parts.size() < 2:
		return
	for idx in range(parts.size() - 1, -1, -1):
		var candidate_expr := parts[idx]
		if not EXPRESSIONS.has(candidate_expr):
			continue
		var char_parts := parts.slice(0, idx)
		if char_parts.size() == 0:
			continue
		var raw_char_id := "_".join(char_parts)
		if raw_char_id == "":
			continue
		var char_id := _resolve_character_id(raw_char_id)
		var entry := _get_or_create_manifest_entry(results, char_id)
		var expr_map: Dictionary = entry.get("expressions", { })
		expr_map[candidate_expr] = resource_path
		entry["expressions"] = expr_map
		if not entry.has("default_portrait") or String(entry.get("default_portrait", "")) == "":
			if candidate_expr == "neutral":
				entry["default_portrait"] = resource_path
		results[char_id] = entry
		return
func _resolve_character_id(raw_id: String) -> String:
	var lowered := raw_id.to_lower().strip_edges()
	if lowered == "":
		return lowered
	if CHARACTER_ALIASES.has(lowered):
		return CHARACTER_ALIASES[lowered]
	var sanitized_alias := lowered.replace(" ", "_")
	if CHARACTER_ALIASES.has(sanitized_alias):
		return CHARACTER_ALIASES[sanitized_alias]
	for alias in CHARACTER_ALIASES.keys():
		if lowered.begins_with(alias):
			return CHARACTER_ALIASES[alias]
		var alias_sanitized := String(alias).replace(" ", "_")
		if sanitized_alias.begins_with(alias_sanitized):
			return CHARACTER_ALIASES[alias]
	if character_data.has(lowered):
		return lowered
	for canonical in character_data.keys():
		if lowered.begins_with(canonical):
			return canonical
	return lowered
func _get_or_create_manifest_entry(results: Dictionary, char_id: String) -> Dictionary:
	if not results.has(char_id):
		results[char_id] = {
			"expressions": { },
		}
	return results[char_id]
func _ensure_character_entry(char_id: String) -> Dictionary:
	var lowered := char_id.to_lower()
	if not character_data.has(lowered):
		character_data[lowered] = {
			"id": lowered,
			"name": _derive_display_name(lowered),
			"name_cn": "",
			"default_portrait": "",
			"expressions": { },
		}
	return character_data[lowered]
func _derive_display_name(char_id: String) -> String:
	var parts := char_id.split("_")
	var formatted_parts: Array = []
	for part in parts:
		var trimmed := String(part).strip_edges()
		if trimmed == "":
			continue
		var capitalized := trimmed.substr(0, 1).to_upper() + trimmed.substr(1, trimmed.length() - 1)
		formatted_parts.append(capitalized)
	if formatted_parts.size() == 0:
		return char_id.capitalize()
	return " ".join(formatted_parts)
func _load_texture(resource_path: String) -> Texture2D:
	if resource_path == "":
		return null
	if _can_use_imported_textures() and not _should_skip_imported_texture(resource_path):
		var resource := ResourceLoader.load(resource_path, "Texture2D")
		if resource is Texture2D:
			return resource
	if FileAccess.file_exists(resource_path):
		var image := Image.new()
		var image_load_error: int = image.load(resource_path)
		if image_load_error == OK:
			return ImageTexture.create_from_image(image)
	return null
func _can_use_imported_textures() -> bool:
	return true
func _should_skip_imported_texture(resource_path: String) -> bool:
	if not (OS.has_environment("GITHUB_ACTIONS") or OS.has_environment("CI")):
		return false
	var imported_path: String = _get_imported_texture_path(resource_path)
	if imported_path == "":
		return false
	var abs_path: String = ProjectSettings.globalize_path(imported_path)
	return not FileAccess.file_exists(abs_path)
func _get_imported_texture_path(resource_path: String) -> String:
	var import_file_path := "%s.import" % resource_path
	if not FileAccess.file_exists(import_file_path):
		return ""
	var file := FileAccess.open(import_file_path, FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	var search_prefix := "path=\""
	var start_pos := content.find(search_prefix)
	while start_pos != -1:
		var is_valid_start := (start_pos == 0)
		if not is_valid_start:
			var prev_c := content[start_pos - 1]
			is_valid_start = (prev_c == "\n" or prev_c == "\r" or prev_c == " " or prev_c == "\t")
		if is_valid_start:
			var value_start := start_pos + search_prefix.length()
			var value_end := content.find("\"", value_start)
			if value_end > value_start:
				return content.substr(value_start, value_end - value_start)
		start_pos = content.find(search_prefix, start_pos + 1)
	return ""
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func reload_expressions():
	_texture_cache.clear()
	_build_expression_manifest()
	_report_info("Expressions reloaded (cache cleared)")
