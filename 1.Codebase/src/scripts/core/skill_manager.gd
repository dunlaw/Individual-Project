extends Node
const SKILLS_BASE_PATH := "res://1.Codebase/src/skills"
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
	if not DirAccess.dir_exists_absolute(SKILLS_BASE_PATH):
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skills directory does not exist", { "path": SKILLS_BASE_PATH })
		return
	var dir := DirAccess.open(SKILLS_BASE_PATH)
	if not dir:
		DirAccess.make_dir_recursive_absolute(SKILLS_BASE_PATH)
		dir = DirAccess.open(SKILLS_BASE_PATH)
	if not dir:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Cannot open skills directory", { "path": SKILLS_BASE_PATH })
		return
	dir.list_dir_begin()
	var folder_name := dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var skill_path := SKILLS_BASE_PATH + "/" + folder_name + "/" + SKILL_FILE_NAME
			var metadata := _parse_skill_metadata(skill_path)
			if not metadata.is_empty():
				metadata["folder"] = folder_name
				metadata["path"] = skill_path
				_skills_cache[metadata["name"]] = metadata
				var triggers: Array = metadata.get("purpose_triggers", [])
				for trigger in triggers:
					_purpose_map[trigger] = metadata["name"]
				_debug_log("Loaded skill: %s" % metadata["name"])
		folder_name = dir.get_next()
	dir.list_dir_end()
	_initialized = true
	_debug_log("Initialized with %d skills" % _skills_cache.size())
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
func load_skill(skill_name: String) -> String:
	if not _skills_cache.has(skill_name):
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skill not found", { "skill_name": skill_name })
		return ""
	var skill: Dictionary = _skills_cache[skill_name]
	var file_path: String = skill.get("path", "")
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skill file not found", { "file_path": file_path })
		return ""
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
