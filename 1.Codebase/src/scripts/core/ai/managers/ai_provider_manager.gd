extends RefCounted
class_name AIProviderManager
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const GeminiProvider = preload("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
const OpenRouterProvider = preload("res://1.Codebase/src/scripts/core/ai/openrouter_provider.gd")
const OllamaProvider = preload("res://1.Codebase/src/scripts/core/ai/ollama_provider.gd")
const OpenAIProvider = preload("res://1.Codebase/src/scripts/core/ai/openai_provider.gd")
const ClaudeProvider = preload("res://1.Codebase/src/scripts/core/ai/claude_provider.gd")
const LMStudioProvider = preload("res://1.Codebase/src/scripts/core/ai/lmstudio_provider.gd")
const AIRouterProvider = preload("res://1.Codebase/src/scripts/core/ai/ai_router_provider.gd")
var _gemini_provider: GeminiProvider = null
var _openrouter_provider: OpenRouterProvider = null
var _ollama_provider: OllamaProvider = null
var _openai_provider: OpenAIProvider = null
var _claude_provider: ClaudeProvider = null
var _lmstudio_provider: LMStudioProvider = null
var _ai_router_provider: AIRouterProvider = null
var _ollama_client: Node = null
const ERROR_CONTEXT := "AIProviderManager"
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
var _config_manager: AIConfigManager = null
signal provider_request_completed(success: bool)
signal provider_request_error(message: String)
signal provider_request_progress(update: Dictionary)
func set_config_manager(config_mgr: AIConfigManager) -> void:
	_config_manager = config_mgr
func initialize_providers(
		http_request: HTTPRequest,
		live_api_client,
		voice_session,
		ollama_client = null,
) -> void:
	_ollama_client = ollama_client
	_gemini_provider = GeminiProvider.new()
	_gemini_provider.setup(http_request, live_api_client, voice_session)
	_gemini_provider.request_completed.connect(_on_provider_request_completed)
	_gemini_provider.request_error.connect(_on_provider_error)
	_gemini_provider.request_progress.connect(_on_provider_progress)
	_openrouter_provider = OpenRouterProvider.new()
	_openrouter_provider.setup(http_request)
	_openrouter_provider.request_completed.connect(_on_provider_request_completed)
	_openrouter_provider.request_error.connect(_on_provider_error)
	_openrouter_provider.request_progress.connect(_on_provider_progress)
	_ollama_provider = OllamaProvider.new()
	_ollama_provider.setup(_ollama_client)
	_ollama_provider.request_completed.connect(_on_provider_request_completed)
	_ollama_provider.request_error.connect(_on_provider_error)
	_ollama_provider.request_progress.connect(_on_provider_progress)
	_openai_provider = OpenAIProvider.new()
	_openai_provider.setup(http_request)
	_openai_provider.request_completed.connect(_on_provider_request_completed)
	_openai_provider.request_error.connect(_on_provider_error)
	_openai_provider.request_progress.connect(_on_provider_progress)
	_claude_provider = ClaudeProvider.new()
	_claude_provider.setup(http_request)
	_claude_provider.request_completed.connect(_on_provider_request_completed)
	_claude_provider.request_error.connect(_on_provider_error)
	_claude_provider.request_progress.connect(_on_provider_progress)
	_lmstudio_provider = LMStudioProvider.new()
	_lmstudio_provider.setup(http_request)
	_lmstudio_provider.request_completed.connect(_on_provider_request_completed)
	_lmstudio_provider.request_error.connect(_on_provider_error)
	_lmstudio_provider.request_progress.connect(_on_provider_progress)
	_ai_router_provider = AIRouterProvider.new()
	_ai_router_provider.setup(http_request)
	_ai_router_provider.request_completed.connect(_on_provider_request_completed)
	_ai_router_provider.request_error.connect(_on_provider_error)
	_ai_router_provider.request_progress.connect(_on_provider_progress)
	_report_info("Providers initialized: Gemini, OpenRouter, Ollama, OpenAI, Claude, LMStudio, AIRouter")
func get_current_provider():
	if not _config_manager:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Config manager not set")
		return null
	match _config_manager.current_provider:
		AIConfigManager.AIProvider.GEMINI:
			return _gemini_provider
		AIConfigManager.AIProvider.OPENROUTER:
			return _openrouter_provider
		AIConfigManager.AIProvider.OLLAMA:
			return _ollama_provider
		AIConfigManager.AIProvider.OPENAI:
			return _openai_provider
		AIConfigManager.AIProvider.CLAUDE:
			return _claude_provider
		AIConfigManager.AIProvider.LMSTUDIO:
			return _lmstudio_provider
		AIConfigManager.AIProvider.AI_ROUTER:
			return _ai_router_provider
		AIConfigManager.AIProvider.MOCK_MODE:
			return null
	return null
func get_provider_name(provider: AIConfigManager.AIProvider) -> String:
	match provider:
		AIConfigManager.AIProvider.GEMINI:
			return "GEMINI"
		AIConfigManager.AIProvider.OPENROUTER:
			return "OPENROUTER"
		AIConfigManager.AIProvider.OLLAMA:
			return "OLLAMA"
		AIConfigManager.AIProvider.OPENAI:
			return "OPENAI"
		AIConfigManager.AIProvider.CLAUDE:
			return "CLAUDE"
		AIConfigManager.AIProvider.LMSTUDIO:
			return "LMSTUDIO"
		AIConfigManager.AIProvider.AI_ROUTER:
			return "AI_ROUTER"
		AIConfigManager.AIProvider.MOCK_MODE:
			return "MOCK_MODE"
	return "UNKNOWN"
func get_current_provider_name() -> String:
	if not _config_manager:
		return "UNKNOWN"
	return get_provider_name(_config_manager.current_provider)
func sync_provider(provider_type: AIConfigManager.AIProvider) -> void:
	if not _config_manager:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Cannot sync provider, config manager not set")
		return
	var config := _config_manager.get_provider_config(provider_type)
	match provider_type:
		AIConfigManager.AIProvider.GEMINI:
			if _gemini_provider:
				_gemini_provider.apply_configuration(config)
				_report_info("Synced Gemini provider")
		AIConfigManager.AIProvider.OPENROUTER:
			if _openrouter_provider:
				_openrouter_provider.apply_configuration(config)
				_report_info("Synced OpenRouter provider")
		AIConfigManager.AIProvider.OLLAMA:
			if _ollama_provider:
				_ollama_provider.apply_configuration(config)
				_report_info("Synced Ollama provider")
		AIConfigManager.AIProvider.OPENAI:
			if _openai_provider:
				_openai_provider.apply_configuration(config)
				_report_info("Synced OpenAI provider")
		AIConfigManager.AIProvider.CLAUDE:
			if _claude_provider:
				_claude_provider.apply_configuration(config)
				_report_info("Synced Claude provider")
		AIConfigManager.AIProvider.LMSTUDIO:
			if _lmstudio_provider:
				_lmstudio_provider.apply_configuration(config)
				_report_info("Synced LMStudio provider")
		AIConfigManager.AIProvider.AI_ROUTER:
			if _ai_router_provider:
				_ai_router_provider.apply_configuration(config)
				_report_info("Synced AI Router provider")
		AIConfigManager.AIProvider.MOCK_MODE:
			_report_info("Mock Mode selected, no provider to sync")
func sync_all_providers() -> void:
	sync_provider(AIConfigManager.AIProvider.GEMINI)
	sync_provider(AIConfigManager.AIProvider.OPENROUTER)
	sync_provider(AIConfigManager.AIProvider.OLLAMA)
	sync_provider(AIConfigManager.AIProvider.OPENAI)
	sync_provider(AIConfigManager.AIProvider.CLAUDE)
	sync_provider(AIConfigManager.AIProvider.LMSTUDIO)
	sync_provider(AIConfigManager.AIProvider.AI_ROUTER)
	_report_info("All providers synced")
func is_provider_configured(provider: AIConfigManager.AIProvider) -> bool:
	if not _config_manager:
		return false
	return _config_manager.is_provider_configured(provider)
func is_ollama_ready(timeout_sec: float = 0.5) -> bool:
	if _ollama_provider == null:
		return false
	sync_provider(AIConfigManager.AIProvider.OLLAMA)
	if _ollama_client == null or not _ollama_client.has_method("health_check"):
		return false
	return _ollama_client.health_check(timeout_sec)
func get_provider_instance(provider_type: AIConfigManager.AIProvider):
	match provider_type:
		AIConfigManager.AIProvider.GEMINI:
			return _gemini_provider
		AIConfigManager.AIProvider.OPENROUTER:
			return _openrouter_provider
		AIConfigManager.AIProvider.OLLAMA:
			return _ollama_provider
		AIConfigManager.AIProvider.OPENAI:
			return _openai_provider
		AIConfigManager.AIProvider.CLAUDE:
			return _claude_provider
		AIConfigManager.AIProvider.LMSTUDIO:
			return _lmstudio_provider
		AIConfigManager.AIProvider.AI_ROUTER:
			return _ai_router_provider
		AIConfigManager.AIProvider.MOCK_MODE:
			return null
	return null
func are_providers_initialized() -> bool:
	return _gemini_provider != null and _openrouter_provider != null and _ollama_provider != null and _openai_provider != null and _claude_provider != null and _lmstudio_provider != null and _ai_router_provider != null
func _on_provider_request_completed(success: bool) -> void:
	provider_request_completed.emit(success)
func _on_provider_error(message: String) -> void:
	provider_request_error.emit(message)
func _on_provider_progress(update: Dictionary) -> void:
	provider_request_progress.emit(update)
