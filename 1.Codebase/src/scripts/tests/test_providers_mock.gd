extends SceneTree
class MockOllamaClient:
	extends Node
	signal token(task_id, text)
	signal completed(task_id, ok, data)
	signal error(task_id, reason)
	signal request_started(task_id)
	var last_endpoint: String = ""
	var last_payload: Dictionary = {}
	var mock_response_text: String = ""
	func configure(_host, _port, _model, _use_chat, _options) -> void:
		pass
	func health_check(_timeout) -> bool:
		return true
	func ask_chat(messages: Array, opts: Dictionary, stream: bool = true) -> int:
		last_endpoint = "/api/chat"
		last_payload = {
			"messages": messages,
			"options": opts,
			"stream": stream
		}
		call_deferred("_simulate_response", 1)
		return 1
	func ask_prompt(prompt: String, opts: Dictionary, stream: bool = true) -> int:
		last_endpoint = "/api/generate"
		last_payload = {
			"prompt": prompt,
			"options": opts,
			"stream": stream
		}
		call_deferred("_simulate_response", 1)
		return 1
	func cancel(_task_id: int) -> void:
		pass
	func _simulate_response(task_id: int) -> void:
		request_started.emit(task_id)
		token.emit(task_id, mock_response_text)
		completed.emit(task_id, true, {"text": mock_response_text})
func _init() -> void:
	call_deferred("_run_tests")
func _run_tests() -> void:
	print("========================================================")
	print("   RUNNING MOCK AI PROVIDER TESTS (NO NETWORK)   ")
	print("========================================================")
	var total_errors := 0
	total_errors += test_openrouter_formatting()
	total_errors += test_ollama_formatting()
	if total_errors == 0:
		print("\n ALL TESTS PASSED")
		quit(0)
	else:
		print("\n %d TESTS FAILED" % total_errors)
		quit(1)
func test_openrouter_formatting() -> int:
	print("\n[TEST] OpenRouter Request Formatting & Response Parsing")
	var OpenRouterProvider = load("res://1.Codebase/src/scripts/core/ai/openrouter_provider.gd")
	var provider = OpenRouterProvider.new()
	var mock_response_body := JSON.stringify({
		"choices": [
			{ "message": { "content": "OpenRouter Success" } }
		]
	})
	var input_messages = [
		{
			"role": "model",
			"parts": [
				{ "text": "Hello user." },
				{ "thoughtSignature": "hidden_thought" }
			]
		}
	]
	var sent_msgs: Array = provider._messages_to_openai_format(input_messages)
	var parsed_response: Dictionary = provider.parse_response(
		HTTPRequest.RESULT_SUCCESS,
		200,
		mock_response_body.to_utf8_buffer(),
	)
	var err_count := 0
	if sent_msgs[0]["role"] != "assistant":
		print(" FAIL: Role 'model' not converted to 'assistant'. Got: " + sent_msgs[0]["role"])
		err_count += 1
	else:
		print(" PASS: Role 'model' -> 'assistant'")
	if sent_msgs[0]["content"] != "Hello user.":
		print(" FAIL: Content not flattened correctly. Got: " + str(sent_msgs[0]["content"]))
		err_count += 1
	else:
		print(" PASS: 'parts' flattened to string, 'thoughtSignature' ignored")
	if not bool(parsed_response.get("success", false)) or String(parsed_response.get("content", "")) != "OpenRouter Success":
		print(" FAIL: Response parsing failed. Success=%s Content=%s" % [parsed_response.get("success", false), parsed_response.get("content", "")])
		err_count += 1
	else:
		print(" PASS: Mock response parsed correctly")
	provider = null
	return err_count
func test_ollama_formatting() -> int:
	print("\n[TEST] Ollama Request Formatting")
	var OllamaProvider = load("res://1.Codebase/src/scripts/core/ai/ollama_provider.gd")
	var provider = OllamaProvider.new()
	var mock_client := MockOllamaClient.new()
	provider.setup(mock_client)
	provider.host = "localhost"
	var input_messages = [
		{
			"role": "model",
			"parts": [
				{ "text": "I am Ollama." }
			]
		}
	]
	provider.send_request(input_messages, Callable())
	var sent_msgs: Array = mock_client.last_payload.get("messages", [])
	var err_count := 0
	if mock_client.last_endpoint != "/api/chat":
		print(" FAIL: Expected chat endpoint, got: %s" % mock_client.last_endpoint)
		err_count += 1
	else:
		print(" PASS: Chat endpoint selected")
	if sent_msgs[0]["role"] != "assistant":
		print(" FAIL: Role 'model' not converted to 'assistant'")
		err_count += 1
	else:
		print(" PASS: Role 'model' -> 'assistant'")
	provider = null
	return err_count
