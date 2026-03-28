extends RefCounted
class_name AIConfigManager
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const CONFIG_FILE_PATH := "user://ai_settings.cfg"
const GEMINI_DEFAULT_MODEL := "gemini-3.1-flash-lite-preview"
const DEFAULT_OLLAMA_MODEL := "gemma3:1b"
const DEFAULT_OPENROUTER_MODEL := "openrouter/free"
const DEFAULT_OPENAI_MODEL := "gpt-5.2"
const DEFAULT_CLAUDE_MODEL := "claude-sonnet-4-5-20250929"
const DEFAULT_MAX_TOKENS := 4096
const MAX_TOKENS_CAP := 8192
enum AIProvider {
	GEMINI = 0,
	OPENROUTER = 1,
	OLLAMA = 2,
	OPENAI = 3,
	CLAUDE = 4,
	LMSTUDIO = 5,
	AI_ROUTER = 6,
	MOCK_MODE = 7,
}
var current_provider: AIProvider = AIProvider.GEMINI
var gemini_api_key: String = ""
var gemini_access_token: String = ""
var gemini_project_id: String = ""
var gemini_location: String = ""
var gemini_model: String = GEMINI_DEFAULT_MODEL
var gemini_allow_web_requests: bool = true
var gemini_safety_settings: String = "BLOCK_NONE"
var openrouter_api_key: String = ""
var openrouter_model: String = DEFAULT_OPENROUTER_MODEL
var openrouter_use_auto_router: bool = false
var ollama_host: String = "127.0.0.1"
var ollama_port: int = 11434
var ollama_model: String = DEFAULT_OLLAMA_MODEL
var ollama_use_chat: bool = true
var ollama_options: Dictionary = {
	"temperature": 0.7,
	"top_p": 0.9,
	"top_k": 40,
	"repeat_penalty": 1.1,
}
var openai_api_key: String = ""
var openai_model: String = DEFAULT_OPENAI_MODEL
var claude_api_key: String = ""
var claude_model: String = DEFAULT_CLAUDE_MODEL
var lmstudio_host: String = "127.0.0.1"
var lmstudio_port: int = 1234
var lmstudio_model: String = ""
var ai_router_host: String = "127.0.0.1"
var ai_router_port: int = 8046
var ai_router_api_key: String = ""
var ai_router_model: String = ""
var ai_router_api_format: int = 0
var ai_router_custom_endpoint: String = ""
var web_proxy_url: String = ""
var max_tokens: int = DEFAULT_MAX_TOKENS
var memory_max_items: int = 20
var memory_summary_threshold: int = 10
var memory_full_entries: int = 5
var custom_ai_tone_style: String = ""
var default_ai_tone_style: String = "Maintain dark humor, ironic detachment, and satire of forced positivity."
var voice_config: Dictionary = { }
const ERROR_CONTEXT := "AIConfigManager"
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _init() -> void:
	custom_ai_tone_style = default_ai_tone_style
func save_settings() -> Error:
	var config = ConfigFile.new()
	config.set_value("ai", "provider", current_provider)
	config.set_value("ai", "gemini_key", gemini_api_key)
	config.set_value("ai", "gemini_access_token", gemini_access_token)
	config.set_value("ai", "gemini_project_id", gemini_project_id)
	config.set_value("ai", "gemini_location", gemini_location)
	config.set_value("ai", "gemini_model", gemini_model)
	config.set_value("ai", "gemini_allow_web_requests", gemini_allow_web_requests)
	config.set_value("ai", "gemini_safety_settings", gemini_safety_settings)
	config.set_value("ai", "openrouter_key", openrouter_api_key)
	config.set_value("ai", "openrouter_model", openrouter_model)
	config.set_value("ai", "openrouter_use_auto_router", openrouter_use_auto_router)
	config.set_value("ai", "ollama_host", ollama_host)
	config.set_value("ai", "ollama_port", ollama_port)
	config.set_value("ai", "ollama_model", ollama_model)
	config.set_value("ai", "ollama_use_chat", ollama_use_chat)
	config.set_value("ai", "ollama_options", ollama_options)
	config.set_value("ai", "openai_key", openai_api_key)
	config.set_value("ai", "openai_model", openai_model)
	config.set_value("ai", "claude_key", claude_api_key)
	config.set_value("ai", "claude_model", claude_model)
	config.set_value("ai", "lmstudio_host", lmstudio_host)
	config.set_value("ai", "lmstudio_port", lmstudio_port)
	config.set_value("ai", "lmstudio_model", lmstudio_model)
	config.set_value("ai", "ai_router_host", ai_router_host)
	config.set_value("ai", "ai_router_port", ai_router_port)
	config.set_value("ai", "ai_router_api_key", ai_router_api_key)
	config.set_value("ai", "ai_router_model", ai_router_model)
	config.set_value("ai", "ai_router_api_format", ai_router_api_format)
	config.set_value("ai", "ai_router_custom_endpoint", ai_router_custom_endpoint)
	config.set_value("ai", "max_tokens", max_tokens)
	config.set_value("ai", "memory_limit", memory_max_items)
	config.set_value("ai", "memory_summary_threshold", memory_summary_threshold)
	config.set_value("ai", "memory_full_entries", memory_full_entries)
	config.set_value("ai", "custom_ai_tone_style", custom_ai_tone_style)
	if not voice_config.is_empty():
		for key in voice_config:
			config.set_value("voice", key, voice_config[key])
	var err = config.save(CONFIG_FILE_PATH)
	if err == OK:
		_report_info("Settings saved to %s" % CONFIG_FILE_PATH)
	else:
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to save settings: %d" % err,
			err,
			false,
			{ "error_code": err },
		)
	return err
func load_settings() -> Error:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	if err != OK:
		_report_info("No config file found, using defaults")
		return err
	_report_info("Loading settings from %s" % CONFIG_FILE_PATH)
	current_provider = config.get_value("ai", "provider", AIProvider.GEMINI)
	web_proxy_url = BuildSecrets.get_web_proxy_url()
	gemini_api_key = config.get_value("ai", "gemini_key", "")
	var injected_gemini_key := BuildSecrets.get_gemini_api_key()
	if gemini_api_key.strip_edges().is_empty() and injected_gemini_key != "":
		_report_info("No user key found; using build-time injected API key as fallback")
		gemini_api_key = injected_gemini_key
	gemini_access_token = config.get_value("ai", "gemini_access_token", "")
	gemini_project_id = config.get_value("ai", "gemini_project_id", "")
	gemini_location = config.get_value("ai", "gemini_location", "")
	gemini_model = _normalize_gemini_model_name(str(config.get_value("ai", "gemini_model", GEMINI_DEFAULT_MODEL)))
	var migrated_gemini := _migrate_gemini_model(config)
	gemini_allow_web_requests = bool(config.get_value("ai", "gemini_allow_web_requests", gemini_allow_web_requests))
	gemini_safety_settings = config.get_value("ai", "gemini_safety_settings", "BLOCK_NONE")
	openrouter_api_key = config.get_value("ai", "openrouter_key", "")
	openrouter_model = config.get_value("ai", "openrouter_model", DEFAULT_OPENROUTER_MODEL)
	openrouter_use_auto_router = bool(config.get_value("ai", "openrouter_use_auto_router", false))
	var migrated_openrouter := _migrate_openrouter_model(config)
	ollama_host = str(config.get_value("ai", "ollama_host", ollama_host))
	ollama_port = int(config.get_value("ai", "ollama_port", ollama_port))
	ollama_model = str(config.get_value("ai", "ollama_model", DEFAULT_OLLAMA_MODEL))
	var migrated := _migrate_ollama_model(config)
	ollama_use_chat = bool(config.get_value("ai", "ollama_use_chat", ollama_use_chat))
	var stored_options = config.get_value("ai", "ollama_options", ollama_options)
	if stored_options is Dictionary:
		ollama_options = (stored_options as Dictionary).duplicate(true)
	openai_api_key = config.get_value("ai", "openai_key", "")
	openai_model = config.get_value("ai", "openai_model", DEFAULT_OPENAI_MODEL)
	claude_api_key = config.get_value("ai", "claude_key", "")
	claude_model = config.get_value("ai", "claude_model", DEFAULT_CLAUDE_MODEL)
	lmstudio_host = str(config.get_value("ai", "lmstudio_host", lmstudio_host))
	lmstudio_port = int(config.get_value("ai", "lmstudio_port", lmstudio_port))
	lmstudio_model = str(config.get_value("ai", "lmstudio_model", ""))
	ai_router_host = str(config.get_value("ai", "ai_router_host", ai_router_host))
	ai_router_port = int(config.get_value("ai", "ai_router_port", ai_router_port))
	ai_router_api_key = str(config.get_value("ai", "ai_router_api_key", ""))
	ai_router_model = str(config.get_value("ai", "ai_router_model", ""))
	ai_router_api_format = int(config.get_value("ai", "ai_router_api_format", 0))
	ai_router_custom_endpoint = str(config.get_value("ai", "ai_router_custom_endpoint", ""))
	max_tokens = _normalize_max_tokens(int(config.get_value("ai", "max_tokens", DEFAULT_MAX_TOKENS)))
	memory_max_items = int(config.get_value("ai", "memory_limit", memory_max_items))
	memory_summary_threshold = int(config.get_value("ai", "memory_summary_threshold", memory_summary_threshold))
	memory_full_entries = int(config.get_value("ai", "memory_full_entries", memory_full_entries))
	custom_ai_tone_style = config.get_value("ai", "custom_ai_tone_style", default_ai_tone_style)
	voice_config.clear()
	if config.has_section("voice"):
		for key in config.get_section_keys("voice"):
			voice_config[key] = config.get_value("voice", key)
	if migrated:
		config.save(CONFIG_FILE_PATH)
	if migrated_gemini:
		config.save(CONFIG_FILE_PATH)
	if migrated_openrouter:
		config.save(CONFIG_FILE_PATH)
	_apply_web_mock_defaults()
	return OK
func _apply_web_mock_defaults() -> void:
	if not _is_web_runtime():
		return
	var has_live_keys := not gemini_api_key.strip_edges().is_empty() \
		or not gemini_access_token.strip_edges().is_empty() \
		or not openrouter_api_key.strip_edges().is_empty() \
		or not openai_api_key.strip_edges().is_empty() \
		or not claude_api_key.strip_edges().is_empty() \
		or not ai_router_api_key.strip_edges().is_empty()
	if has_live_keys:
		return
	if not web_proxy_url.strip_edges().is_empty():
		_report_info("Web runtime: using Gemini proxy for live AI content.")
		current_provider = AIProvider.GEMINI
		return
	if current_provider != AIProvider.MOCK_MODE:
		_report_warning("Web runtime without API keys detected; defaulting provider to MOCK_MODE for offline content.")
	current_provider = AIProvider.MOCK_MODE
func _is_web_runtime() -> bool:
	var normalized_name := OS.get_name().to_lower()
	if normalized_name == "html5":
		return true
	for feature in ["web", "html5", "emscripten", "javascript"]:
		if OS.has_feature(feature):
			return true
	return false
func _migrate_gemini_model(config: ConfigFile) -> bool:
	var resolved := _normalize_gemini_model_name(gemini_model)
	if resolved.is_empty() or resolved == gemini_model:
		return false
	_report_info("Migrating Gemini model from '%s' to '%s'" % [gemini_model, resolved])
	gemini_model = resolved
	config.set_value("ai", "gemini_model", gemini_model)
	return true
func _migrate_openrouter_model(config: ConfigFile) -> bool:
	var normalized := openrouter_model.strip_edges().to_lower()
	if normalized == "google/gemini-pro" or normalized == "google/gemini-pro-vision" or normalized == "google/gemini-2.0-flash-001" or normalized == "google/gemini-2.5-flash":
		_report_info("Migrating OpenRouter model from '%s' to '%s'" % [openrouter_model, DEFAULT_OPENROUTER_MODEL])
		openrouter_model = DEFAULT_OPENROUTER_MODEL
		config.set_value("ai", "openrouter_model", openrouter_model)
		return true
	return false
func set_gemini_model(value: String) -> void:
	gemini_model = _normalize_gemini_model_name(value)
func _normalize_gemini_model_name(value: String) -> String:
	var trimmed := value.strip_edges()
	if trimmed.is_empty():
		return ""
	var lower := trimmed.to_lower()
	if lower == "gemini-2.5-flash" or lower == "gemini-flash-latest":
		return "gemini-3.1-flash-lite-preview"
	if lower in [
		"gemini-2.5-flash-native-audio-preview-09-2025",
		"gemini-2.5-flash-native-audio-preview-12-2025",
		"gemini-2.5-flash-preview-native-audio-dialog",
		"gemini-2.5-flash-exp-native-audio-thinking-dialog",
		"gemini-2.5-flash-live-preview",
	]:
		return "gemini-3.1-flash-live-preview"
	if lower == "gemini-live-2.5-flash-preview":
		return "gemini-3.1-flash-live-preview"
	if lower == "gemini-2.5-flash-lite":
		return "gemini-3.1-flash-lite-preview"
	if lower == "gemini-3-pro-preview":
		return "gemini-3.1-pro-preview"
	return trimmed
func _migrate_ollama_model(config: ConfigFile) -> bool:
	var normalized := ollama_model.strip_edges().to_lower()
	if normalized.is_empty() or normalized.begins_with("llama3"):
		_report_info("Migrating Ollama model from '%s' to '%s'" % [ollama_model, DEFAULT_OLLAMA_MODEL])
		ollama_model = DEFAULT_OLLAMA_MODEL
		config.set_value("ai", "ollama_model", ollama_model)
		return true
	return false
func set_max_tokens(value: int) -> void:
	max_tokens = _normalize_max_tokens(value)
func _normalize_max_tokens(value: int) -> int:
	return clampi(value, 1, MAX_TOKENS_CAP)
func get_ai_system_persona() -> String:
	return "You are the story director for Glorious Deliverance Agency 1 (GDA1). You are responsible for creating scenarios full of dark humor and challenging tasks. " + custom_ai_tone_style
func get_state_snapshot() -> Dictionary:
	return {
		"provider": current_provider,
		"gemini_model": gemini_model,
		"gemini_safety_settings": gemini_safety_settings,
		"openrouter_model": openrouter_model,
		"ollama_host": ollama_host,
		"ollama_port": ollama_port,
		"ollama_model": ollama_model,
		"openai_model": openai_model,
		"claude_model": claude_model,
		"lmstudio_host": lmstudio_host,
		"lmstudio_port": lmstudio_port,
		"lmstudio_model": lmstudio_model,
		"max_tokens": max_tokens,
		"custom_tone": custom_ai_tone_style,
		"memory_max": memory_max_items,
		"memory_threshold": memory_summary_threshold,
	}
func load_state_snapshot(state: Dictionary) -> void:
	if state.has("provider"):
		current_provider = state["provider"]
	if state.has("gemini_model"):
		set_gemini_model(str(state["gemini_model"]))
	if state.has("gemini_safety_settings"):
		gemini_safety_settings = state["gemini_safety_settings"]
	if state.has("openrouter_model"):
		openrouter_model = state["openrouter_model"]
	if state.has("ollama_host"):
		ollama_host = state["ollama_host"]
	if state.has("ollama_port"):
		ollama_port = state["ollama_port"]
	if state.has("ollama_model"):
		ollama_model = state["ollama_model"]
	if state.has("openai_model"):
		openai_model = state["openai_model"]
	if state.has("claude_model"):
		claude_model = state["claude_model"]
	if state.has("lmstudio_host"):
		lmstudio_host = state["lmstudio_host"]
	if state.has("lmstudio_port"):
		lmstudio_port = state["lmstudio_port"]
	if state.has("lmstudio_model"):
		lmstudio_model = state["lmstudio_model"]
	if state.has("max_tokens"):
		set_max_tokens(int(state["max_tokens"]))
	if state.has("custom_tone"):
		custom_ai_tone_style = state["custom_tone"]
	if state.has("memory_max"):
		memory_max_items = state["memory_max"]
	if state.has("memory_threshold"):
		memory_summary_threshold = state["memory_threshold"]
func is_provider_configured(provider: AIProvider) -> bool:
	match provider:
		AIProvider.GEMINI:
			return not gemini_api_key.is_empty() or not gemini_access_token.is_empty()
		AIProvider.OPENROUTER:
			return not openrouter_api_key.is_empty()
		AIProvider.OLLAMA:
			return true
		AIProvider.OPENAI:
			return not openai_api_key.is_empty()
		AIProvider.CLAUDE:
			return not claude_api_key.is_empty()
		AIProvider.LMSTUDIO:
			return true
		AIProvider.AI_ROUTER:
			return true
		AIProvider.MOCK_MODE:
			return true
		_:
			return false
func get_provider_config(provider: AIProvider) -> Dictionary:
	match provider:
		AIProvider.GEMINI:
			return {
				"api_key": gemini_api_key,
				"access_token": gemini_access_token,
				"project_id": gemini_project_id,
				"location": gemini_location,
				"model": gemini_model,
				"allow_web_requests": gemini_allow_web_requests,
				"safety_settings": gemini_safety_settings,
				"web_proxy_url": web_proxy_url,
			}
		AIProvider.OPENROUTER:
			return {
				"api_key": openrouter_api_key,
				"model": openrouter_model,
				"use_auto_router": openrouter_use_auto_router,
			}
		AIProvider.OLLAMA:
			return {
				"host": ollama_host,
				"port": ollama_port,
				"model": ollama_model,
				"use_chat": ollama_use_chat,
				"options": ollama_options.duplicate(),
			}
		AIProvider.OPENAI:
			return {
				"api_key": openai_api_key,
				"model": openai_model,
			}
		AIProvider.CLAUDE:
			return {
				"api_key": claude_api_key,
				"model": claude_model,
			}
		AIProvider.LMSTUDIO:
			return {
				"host": lmstudio_host,
				"port": lmstudio_port,
				"model": lmstudio_model,
			}
		AIProvider.AI_ROUTER:
			return {
				"host": ai_router_host,
				"port": ai_router_port,
				"api_key": ai_router_api_key,
				"model": ai_router_model,
				"api_format": ai_router_api_format,
				"custom_endpoint": ai_router_custom_endpoint,
			}
		AIProvider.MOCK_MODE:
			return {}
		_:
			return {}
func get_memory_config() -> Dictionary:
	return {
		"max_items": memory_max_items,
		"summary_threshold": memory_summary_threshold,
		"full_entries": memory_full_entries,
	}
func get_voice_config() -> Dictionary:
	return voice_config.duplicate()
func set_voice_config(config: Dictionary) -> void:
	voice_config = config.duplicate()
