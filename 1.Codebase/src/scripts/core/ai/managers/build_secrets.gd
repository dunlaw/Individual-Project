class_name BuildSecrets
extends RefCounted
const GEMINI_API_KEY_1 = ""
const GEMINI_API_KEY_2 = ""
const GEMINI_API_KEY_3 = ""
const WEB_PROXY_URL = ""
static func get_all_gemini_api_keys() -> Array:
	var keys: Array = []
	for k in [GEMINI_API_KEY_1, GEMINI_API_KEY_2, GEMINI_API_KEY_3]:
		var s := String(k).strip_edges()
		if not s.is_empty() and s not in keys:
			keys.append(s)
	if not _is_web_runtime():
		for i in range(1, 4):
			var env_key := String(OS.get_environment("GEMINI_API_KEY_" + str(i))).strip_edges()
			if not env_key.is_empty() and env_key not in keys:
				keys.append(env_key)
	return keys
static func get_gemini_api_key() -> String:
	var keys := get_all_gemini_api_keys()
	return keys[0] if not keys.is_empty() else ""
static func get_web_proxy_url() -> String:
	return String(WEB_PROXY_URL).strip_edges()
static func _is_web_runtime() -> bool:
	var normalized_name := OS.get_name().to_lower()
	if normalized_name == "html5":
		return true
	for feature in ["web", "html5", "emscripten", "javascript"]:
		if OS.has_feature(feature):
			return true
	return false
