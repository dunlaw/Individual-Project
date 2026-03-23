extends Node
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "LLMTestRunner"
var _completed: bool = false
var _timeout_timer: Timer
func _ready() -> void:
	_report_info("Starting local LLM smoke test.")
	if AIManager == null:
		_report_error("AIManager autoload unavailable.")
		_quit_with_code(1)
		return
	_timeout_timer = Timer.new()
	_timeout_timer.wait_time = 15.0
	_timeout_timer.one_shot = true
	add_child(_timeout_timer)
	_timeout_timer.timeout.connect(_on_timeout)
	_timeout_timer.start()
	var error_callable := Callable(self, "_on_ai_error")
	if AIManager.ai_error.is_connected(error_callable):
		AIManager.ai_error.disconnect(error_callable)
	AIManager.ai_error.connect(error_callable)
	var token_callable := Callable(self, "_on_token")
	if not OllamaClient.token.is_connected(token_callable):
		OllamaClient.token.connect(token_callable)
	AIManager.current_provider = AIManager.AIProvider.OLLAMA
	AIManager.ollama_use_chat = true
	if AIManager.has_method("_apply_ollama_configuration"):
		AIManager._apply_ollama_configuration()
	if not OllamaClient.health_check(1.0, true):
		_report_error("Ollama service unavailable. Ensure the local runtime is running.")
		_quit_with_code(1)
		return
	var prompt := "Provide a one sentence status update for Glorious Deliverance Agency."
	AIManager.request_ai(prompt, Callable(self, "_on_ai_response"), { "purpose": "test" })
func _on_ai_response(response) -> void:
	if _completed:
		return
	_completed = true
	_timeout_timer.stop()
	var text := ""
	if response is Dictionary:
		if not response.get("success", true):
			var error_text := str(response.get("error", "Unknown error"))
			_report_error("Local LLM reported failure: %s" % error_text)
			_quit_with_code(1)
			return
		text = str(response.get("content", ""))
	else:
		text = str(response)
	_report_info("Final response: %s" % text.strip_edges())
	_quit_with_code(0)
func _on_ai_error(message: String) -> void:
	if _completed:
		return
	_completed = true
	_timeout_timer.stop()
	_report_error("Error: %s" % message)
	_quit_with_code(1)
func _on_token(task_id: int, text: String) -> void:
	if _completed:
		return
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	_report_info("token: %s" % trimmed)
func _on_timeout() -> void:
	if _completed:
		return
	_completed = true
	_report_error("Timed out waiting for local LLM response.")
	_quit_with_code(2)
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _quit_with_code(code: int) -> void:
	if get_tree():
		get_tree().quit(code)
func _exit_tree() -> void:
	var error_callable := Callable(self, "_on_ai_error")
	if AIManager.ai_error.is_connected(error_callable):
		AIManager.ai_error.disconnect(error_callable)
	var token_callable := Callable(self, "_on_token")
	if OllamaClient.token.is_connected(token_callable):
		OllamaClient.token.disconnect(token_callable)
