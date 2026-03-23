extends Node
var tests_passed: int = 0
var tests_failed: int = 0
var test_timeout: float = 5.0
func _ready() -> void:
	print("[AISystemTest] Starting AI system unit tests...")
	await get_tree().process_frame
	_test_service_locator_access()
	_test_provider_configuration()
	await _test_mock_ai_generator()
	_test_memory_store()
	_test_context_builder()
	print("[AISystemTest] All tests completed.")
	queue_free()
func _test_service_locator_access() -> void:
	print("[Test] ServiceLocator access...")
	_assert(ServiceLocator != null, "ServiceLocator should exist")
	var ai_manager = ServiceLocator.get_ai_manager()
	_assert(ai_manager != null, "AIManager should be accessible via ServiceLocator")
	_assert(ai_manager == AIManager, "ServiceLocator should return the same AIManager instance")
	var services = ServiceLocator.list_services()
	_assert(services.size() > 0, "ServiceLocator should have registered services")
	_assert(services.has("AIManager"), "AIManager should be registered")
	_assert(services.has("GameState"), "GameState should be registered")
	print("[Test] ServiceLocator access PASSED")
func _test_provider_configuration() -> void:
	print("[Test] Provider configuration...")
	var ai_manager = ServiceLocator.get_ai_manager()
	_assert(ai_manager != null, "AIManager should exist")
	_assert(
		ai_manager.current_provider in [
			ai_manager.AIProvider.GEMINI,
			ai_manager.AIProvider.OPENROUTER,
			ai_manager.AIProvider.OLLAMA,
			ai_manager.AIProvider.OPENAI,
			ai_manager.AIProvider.CLAUDE,
			ai_manager.AIProvider.LMSTUDIO,
			ai_manager.AIProvider.AI_ROUTER,
			ai_manager.AIProvider.MOCK_MODE,
		],
		"Current provider should be valid",
	)
	var original_provider = ai_manager.current_provider
	ai_manager.current_provider = ai_manager.AIProvider.OLLAMA
	_assert(ai_manager.current_provider == ai_manager.AIProvider.OLLAMA, "Should switch to OLLAMA")
	ai_manager.current_provider = ai_manager.AIProvider.GEMINI
	_assert(ai_manager.current_provider == ai_manager.AIProvider.GEMINI, "Should switch to GEMINI")
	ai_manager.current_provider = original_provider
	var original_model = ai_manager.gemini_model
	ai_manager.gemini_model = "gemini-3-flash-preview"
	_assert(ai_manager.gemini_model == "gemini-3-flash-preview", "Should update Gemini model")
	ai_manager.gemini_model = original_model
	print("[Test] Provider configuration PASSED")
func _test_mock_ai_generator() -> void:
	print("[Test] Mock AI generator...")
	var MockAIGenerator = load("res://1.Codebase/src/scripts/core/mock_ai_generator.gd")
	_assert(MockAIGenerator != null, "MockAIGenerator should load")
	var mock_gen = MockAIGenerator.new()
	var mission_response = mock_gen.generate_mock_mission_response("Test mission prompt", "en")
	_assert(mission_response is String, "Should return string response")
	_assert(mission_response.length() > 0, "Response should not be empty")
	var disaster_response = mock_gen.generate_mock_disaster_response("Test prayer", "en")
	_assert(disaster_response is String, "Should return string response")
	_assert(disaster_response.length() > 0, "Response should not be empty")
	var zh_response = mock_gen.generate_mock_mission_response("Test mission prompt", "zh")
	_assert(zh_response is String, "Should return Chinese response")
	_assert(zh_response.length() > 0, "Chinese response should not be empty")
	var response_with_directives = """
	Story text here.
	[SCENE_DIRECTIVES]
	BACKGROUND:park
	CHARACTER:gloria
	[/SCENE_DIRECTIVES]
	More story.
	"""
	var parsed = mock_gen._extract_scene_directives(response_with_directives)
	_assert(parsed.has("story_text"), "Should have story_text")
	_assert(parsed.has("directives"), "Should have directives")
	mock_gen = null
	print("[Test] Mock AI generator PASSED")
func _test_memory_store() -> void:
	print("[Test] AI memory store...")
	var AIMemoryStore = load("res://1.Codebase/src/scripts/core/ai_memory_store.gd")
	_assert(AIMemoryStore != null, "AIMemoryStore should load")
	var memory = AIMemoryStore.new()
	memory.register_note("Test note EN", (LocalizationManager.get_translation("TEST_NOTE_ZH", "zh") if LocalizationManager else "Test Note") + " ZH", ["test", "demo"], 3, "test")
	var notes_en = memory.get_notes("en", 5)
	_assert(notes_en.size() > 0, "Should have English notes")
	var notes_zh = memory.get_notes("zh", 5)
	_assert(notes_zh.size() > 0, "Should have Chinese notes")
	var count = memory.get_note_count()
	_assert(count >= 1, "Should have at least 1 note")
	var test_notes = memory.get_notes_by_tag("test", "en", 5)
	_assert(test_notes.size() >= 1, "Should find notes with 'test' tag")
	var type_notes = memory.get_notes_by_type("test", "en", 5)
	_assert(type_notes.size() >= 1, "Should find notes of type 'test'")
	memory.clear_all_notes()
	var cleared_count = memory.get_note_count()
	_assert(cleared_count == 0, "Notes should be cleared")
	memory = null
	print("[Test] AI memory store PASSED")
func _test_context_builder() -> void:
	print("[Test] AI context builder...")
	var ai_manager = ServiceLocator.get_ai_manager()
	_assert(ai_manager != null, "AIManager should exist")
	_assert(ai_manager.memory_store != null, "Memory store should be initialized")
	ai_manager.register_note_pair("Test EN", (LocalizationManager.get_translation("TEST_STAT_MODIFIER", "zh") if LocalizationManager else "Test") + " ZH", ["test"], 2, "test_type")
	var note_count = ai_manager.memory_store.get_note_count()
	_assert(note_count > 0, "Should have notes registered")
	ai_manager.clear_notes()
	var cleared_count = ai_manager.memory_store.get_note_count()
	_assert(cleared_count == 0, "Notes should be cleared")
	_assert(ai_manager.custom_ai_tone_style is String, "AI tone style should be string")
	_assert(ai_manager.custom_ai_tone_style.length() > 0, "AI tone style should not be empty")
	print("[Test] AI context builder PASSED")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
