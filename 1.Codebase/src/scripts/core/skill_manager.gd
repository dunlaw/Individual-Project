extends Node
const EmbeddedSkillRegistry = preload("res://1.Codebase/generated/embedded_skill_registry.gd")
const SKILLS_BASE_PATHS := [
	"res://1.Codebase/src/skills",
	"res://src/skills",
]
const SKILL_FILE_NAME := "SKILL.md"
const ERROR_CONTEXT := "SkillManager"
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
var _skills_cache: Dictionary = {}
var _purpose_map: Dictionary = {}
var _initialized: bool = false
func _ready() -> void:
	_scan_skills()
func _scan_skills() -> void:
	_skills_cache.clear()
	_purpose_map.clear()
	_initialized = false
	var existing_paths := _get_existing_skill_paths()
	if _scan_skills_from_paths(existing_paths):
		_initialized = true
		_debug_log("Initialized with %d skills from project files" % _skills_cache.size())
		return
	if _load_embedded_skills():
		var fallback_reason := "skills directories unavailable" if existing_paths.is_empty() else "skills directories contained no loadable skills"
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Using embedded skill registry", {
			"reason": fallback_reason,
			"paths": existing_paths,
		})
		_debug_log("Initialized with %d skills from embedded registry" % _skills_cache.size())
		return
	if existing_paths.is_empty():
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skills directory does not exist", { "paths": SKILLS_BASE_PATHS })
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "No skills could be loaded", { "paths": existing_paths })
func _get_existing_skill_paths() -> Array[String]:
	var existing_paths: Array[String] = []
	for base_path in SKILLS_BASE_PATHS:
		if DirAccess.dir_exists_absolute(base_path):
			existing_paths.append(base_path)
	return existing_paths
func _scan_skills_from_paths(paths: Array[String]) -> bool:
	for base_path in paths:
		var loaded_count := _scan_skills_from_directory(base_path)
		if loaded_count > 0:
			_debug_log("Loaded %d skills from %s" % [loaded_count, base_path])
			return true
	return false
func _scan_skills_from_directory(base_path: String) -> int:
	var dir := DirAccess.open(base_path)
	if not dir:
		return 0
	var loaded_count := 0
	dir.list_dir_begin()
	var folder_name := dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var skill_path := base_path + "/" + folder_name + "/" + SKILL_FILE_NAME
			var metadata := _parse_skill_metadata(skill_path)
			if not metadata.is_empty():
				metadata["folder"] = folder_name
				metadata["path"] = skill_path
				_register_skill(str(metadata.get("name", folder_name)), metadata)
				loaded_count += 1
		folder_name = dir.get_next()
	dir.list_dir_end()
	return loaded_count
func _load_embedded_skills() -> bool:
	var embedded_skills: Dictionary = EmbeddedSkillRegistry.get_skills()
	if embedded_skills.is_empty():
		return false
	for skill_name_variant in embedded_skills.keys():
		var skill_name := str(skill_name_variant)
		var metadata_variant: Variant = embedded_skills.get(skill_name_variant, {})
		if metadata_variant is Dictionary and not (metadata_variant as Dictionary).is_empty():
			_register_skill(skill_name, metadata_variant)
	if _skills_cache.is_empty():
		return false
	_initialized = true
	return true
func _register_skill(skill_name: String, metadata: Dictionary) -> void:
	var normalized := metadata.duplicate(true)
	normalized["name"] = skill_name
	if str(normalized.get("folder", "")).is_empty():
		normalized["folder"] = skill_name
	_skills_cache[skill_name] = normalized
	var triggers_variant: Variant = normalized.get("purpose_triggers", [])
	if triggers_variant is Array:
		for trigger in triggers_variant:
			_purpose_map[str(trigger)] = skill_name
	_debug_log("Loaded skill: %s" % skill_name)
func _parse_skill_metadata(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	var content := file.get_as_text()
	file.close()
	return _parse_frontmatter(content)
func _parse_frontmatter(content: String) -> Dictionary:
	var result: Dictionary = {}
	if not content.begins_with("---"):
		return result
	var end_marker := content.find("\n---", 3)
	if end_marker == -1:
		return result
	var frontmatter := content.substr(4, end_marker - 4).strip_edges()
	var lines := frontmatter.split("\n")
	var current_key := ""
	var in_array := false
	var array_items: Array = []
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.is_empty():
			continue
		if in_array:
			if stripped.begins_with("- "):
				array_items.append(stripped.substr(2).strip_edges())
			else:
				result[current_key] = array_items
				in_array = false
				array_items = []
		if not in_array:
			var colon_pos := stripped.find(":")
			if colon_pos > 0:
				current_key = stripped.substr(0, colon_pos).strip_edges()
				var value := stripped.substr(colon_pos + 1).strip_edges()
				if value.is_empty():
					in_array = true
					array_items = []
				else:
					result[current_key] = value
	if in_array and not array_items.is_empty():
		result[current_key] = array_items
	return result
func get_available_skills_xml() -> String:
	if _skills_cache.is_empty():
		return ""
	var xml := "<available_skills>\n"
	for skill_name in _skills_cache:
		var skill: Dictionary = _skills_cache[skill_name]
		xml += "  <skill>\n"
		xml += "    <name>%s</name>\n" % skill.get("name", "")
		xml += "    <description>%s</description>\n" % skill.get("description", "")
		xml += "  </skill>\n"
	xml += "</available_skills>"
	return xml
func get_skill_for_purpose(purpose: String) -> String:
	return _purpose_map.get(purpose, "")
func load_skill(skill_name: String, language: String = "") -> String:
	if not _skills_cache.has(skill_name):
		push_error("[SkillManager] SKILL NOT FOUND in cache: skill='%s'. Was it scanned and registered?" % skill_name)
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skill not found", { "skill_name": skill_name })
		return ""
	var skill: Dictionary = _skills_cache[skill_name]
	var embedded_content := _load_embedded_skill_content(skill, language)
	if not embedded_content.is_empty():
		return embedded_content
	for file_path in _get_skill_candidate_paths(skill, language):
		if file_path.is_empty() or not FileAccess.file_exists(file_path):
			continue
		return _read_skill_body(file_path)
	push_error("[SkillManager] SKILL FILE NOT FOUND: skill='%s', language='%s', base_path='%s'. Check that SKILL.%s.md exists in the skill directory." % [skill_name, language, skill.get("path", ""), language])
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skill file not found", {
		"skill_name": skill_name,
		"language": language,
		"path": skill.get("path", ""),
	})
	return ""
func _load_embedded_skill_content(skill: Dictionary, language: String) -> String:
	var content_variant: Variant = skill.get("content", {})
	if not content_variant is Dictionary:
		return ""
	var content_map := content_variant as Dictionary
	if not language.is_empty():
		var localized_content := str(content_map.get(language, "")).strip_edges()
		if not localized_content.is_empty():
			return localized_content
	var english_content := str(content_map.get("en", "")).strip_edges()
	if not english_content.is_empty():
		return english_content
	for value in content_map.values():
		var fallback_content := str(value).strip_edges()
		if not fallback_content.is_empty():
			return fallback_content
	return ""
func _get_skill_candidate_paths(skill: Dictionary, language: String) -> Array[String]:
	var base_path: String = skill.get("path", "")
	if base_path.is_empty():
		return []
	var candidates: Array[String] = []
	if not language.is_empty():
		var extension_index := base_path.rfind(".")
		if extension_index != -1:
			candidates.append("%s.%s%s" % [
				base_path.substr(0, extension_index),
				language,
				base_path.substr(extension_index),
			])
	if base_path not in candidates:
		candidates.append(base_path)
	return candidates
func _read_skill_body(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	var content := file.get_as_text()
	file.close()
	var end_marker := content.find("\n---", 3)
	if end_marker != -1:
		content = content.substr(end_marker + 5).strip_edges()
	return content
func get_skill_metadata(skill_name: String) -> Dictionary:
	return _skills_cache.get(skill_name, {})
func get_all_skill_names() -> Array:
	return _skills_cache.keys()
func reload_skills() -> void:
	_scan_skills()
func is_initialized() -> bool:
	return _initialized
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
