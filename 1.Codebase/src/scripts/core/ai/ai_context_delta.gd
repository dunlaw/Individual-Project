extends RefCounted
class_name AIContextDelta
const CHARS_PER_TOKEN := 4
const DEFAULT_TOKEN_BUDGET := 24000
const USER_MSG_RESERVE := 4000
const STATIC_SECTIONS := [
	"static_context",
	"system_persona",
]
const MAX_STALE_CYCLES := 8
var _fingerprints: Dictionary = {}
var _stale_counts: Dictionary = {}
var token_budget: int = DEFAULT_TOKEN_BUDGET
var _current_tokens: int = 0
var _is_first_request: bool = true
var _included_sections: Dictionary = {}
func reset() -> void:
	_fingerprints.clear()
	_stale_counts.clear()
	_current_tokens = 0
	_is_first_request = true
	_included_sections.clear()
func begin_build() -> void:
	_current_tokens = 0
	_included_sections.clear()
func finish_build() -> void:
	_is_first_request = false
	for section_name in _fingerprints.keys():
		if not _included_sections.has(section_name):
			_stale_counts[section_name] = _stale_counts.get(section_name, 0) + 1
func has_section_changed(section_name: String, content: String) -> bool:
	if _is_first_request:
		return true
	var new_hash := content.hash()
	var old_hash: int = _fingerprints.get(section_name, -1)
	if new_hash != old_hash:
		return true
	var stale: int = _stale_counts.get(section_name, 0)
	if stale >= MAX_STALE_CYCLES:
		return true
	return false
func record_section(section_name: String, content: String) -> void:
	_fingerprints[section_name] = content.hash()
	_stale_counts[section_name] = 0
	_included_sections[section_name] = true
func estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
	return max(1, text.length() / CHARS_PER_TOKEN)
func add_tokens(count: int) -> void:
	_current_tokens += count
func get_current_tokens() -> int:
	return _current_tokens
func remaining_budget() -> int:
	return max(0, token_budget - _current_tokens)
func has_budget(text: String) -> bool:
	return _current_tokens + estimate_tokens(text) <= token_budget
func is_first_request() -> bool:
	return _is_first_request
func fingerprint_messages(messages: Array) -> String:
	var parts: Array[String] = []
	for msg in messages:
		if msg is Dictionary:
			parts.append(str(msg.get("content", "")))
	return "\n".join(parts)
func build_unchanged_marker(section_name: String) -> Dictionary:
	return {
		"role": "system",
		"content": "[context:%s unchanged from previous request]" % section_name,
	}
