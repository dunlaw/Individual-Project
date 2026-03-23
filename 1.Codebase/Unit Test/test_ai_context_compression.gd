extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const AIPromptBuilderScript = preload("res://1.Codebase/src/scripts/core/ai/ai_prompt_builder.gd")
var _prompt_builder: AIPromptBuilder = null
var _game_state: Node = null
var _asset_registry: Node = null
var _memory_store: RefCounted = null
func _ready() -> void:
	print("[AIContextCompressionTest] Starting tests...")
	await get_tree().process_frame
	_test_long_term_context_is_summarized_when_budget_is_tight()
	_test_long_term_context_is_kept_when_budget_allows()
	_test_system_persona_is_summarized_when_budget_is_tight()
	_test_prompt_and_short_term_memory_stay_within_budget()
	_teardown()
	print("[AIContextCompressionTest] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _setup(long_term_messages: Array[Dictionary], short_term_messages: Array[Dictionary] = [], notes_messages: Array[Dictionary] = []) -> void:
	_teardown()
	_game_state = _create_game_state_mock()
	_asset_registry = _create_asset_registry_mock()
	_memory_store = _create_memory_store_mock(long_term_messages, short_term_messages, notes_messages)
	_prompt_builder = AIPromptBuilderScript.new()
	_prompt_builder.setup(_game_state, _asset_registry, _memory_store, null)
func _teardown() -> void:
	if is_instance_valid(_game_state):
		_game_state.free()
	_game_state = null
	if is_instance_valid(_asset_registry):
		_asset_registry.free()
	_asset_registry = null
	_memory_store = null
	_prompt_builder = null
func _test_long_term_context_is_summarized_when_budget_is_tight() -> void:
	print("[Test] Long-term context compresses under tight token budget...")
	var oversized_text := "LONG_TERM_FACT ".repeat(180)
	_setup([
		{"role": "system", "content": oversized_text}
	])
	var delta := _prompt_builder.get_delta()
	delta.token_budget = 40
	var messages := _prompt_builder.build_prompt("Budget compression prompt", {"purpose": "compression_test"})
	var all_content := _join_message_content(messages)
	_assert(
		all_content.contains("[context:long_term_context updated"),
		"Long-term context falls back to a summary marker when over budget"
	)
	_assert(
		not all_content.contains(oversized_text.substr(0, 120)),
		"Oversized long-term context is not injected verbatim when summarized"
	)
func _test_long_term_context_is_kept_when_budget_allows() -> void:
	print("[Test] Long-term context stays verbatim when budget allows...")
	var oversized_text := "LONG_TERM_FACT ".repeat(40)
	_setup([
		{"role": "system", "content": oversized_text}
	])
	var delta := _prompt_builder.get_delta()
	delta.token_budget = 4000
	var messages := _prompt_builder.build_prompt("Budget roomy prompt", {"purpose": "compression_test"})
	var all_content := _join_message_content(messages)
	_assert(
		all_content.contains(oversized_text.substr(0, 120)),
		"Long-term context stays verbatim when token budget is sufficient"
	)
	_assert(
		not all_content.contains("[context:long_term_context updated"),
		"Summary marker is not used when the full section fits"
	)
func _test_system_persona_is_summarized_when_budget_is_tight() -> void:
	print("[Test] System persona falls back to a summary marker under tight budget...")
	_setup([])
	var oversized_persona := "PERSONA_RULE ".repeat(180)
	_prompt_builder.set_system_persona(oversized_persona)
	var delta := _prompt_builder.get_delta()
	delta.token_budget = 60
	var messages := _prompt_builder.build_prompt("Persona compression prompt", {"purpose": "compression_test"})
	var all_content := _join_message_content(messages)
	_assert(
		all_content.contains("[context:system_persona updated"),
		"Oversized single system sections fall back to a summary marker"
	)
	_assert(
		not all_content.contains(oversized_persona.substr(0, 120)),
		"Oversized system persona is not injected verbatim when summarized"
	)
func _test_prompt_and_short_term_memory_stay_within_budget() -> void:
	print("[Test] Prompt build keeps short-term memory and prompt within the token budget...")
	var oversized_short_term := "SHORT_TERM_MEMORY ".repeat(220)
	var oversized_prompt := "CURRENT_PROMPT ".repeat(180)
	_setup([], [
		{"role": "assistant", "content": oversized_short_term}
	])
	var delta := _prompt_builder.get_delta()
	delta.token_budget = 90
	var messages := _prompt_builder.build_prompt(oversized_prompt, {"purpose": "compression_test"})
	var all_content := _join_message_content(messages)
	_assert(
		delta.get_current_tokens() <= delta.token_budget,
		"Prompt builder does not exceed the configured token budget"
	)
	_assert(
		all_content.contains("CURRENT_PROMPT"),
		"Current prompt text is preserved even when older short-term memory is compressed"
	)
	_assert(
		all_content.contains("[context:short_term_memory updated") or not all_content.contains(oversized_short_term.substr(0, 120)),
		"Short-term memory is compressed before it can push the prompt over budget"
	)
func _join_message_content(messages: Array) -> String:
	var parts: Array[String] = []
	for msg in messages:
		if msg is Dictionary:
			parts.append(str(msg.get("content", "")))
	return "\n".join(parts)
func _create_game_state_mock() -> Node:
	var script := GDScript.new()
	script.source_code = """
extends Node
var current_language: String = "en"
var butterfly_tracker = null
func get_recent_event_notes(_limit, _lang):
	return []
func get_recent_journal_entries(_limit):
	return []
func set_metadata(_key, _value):
	pass
"""
	script.reload()
	var node := Node.new()
	node.set_script(script)
	return node
func _create_asset_registry_mock() -> Node:
	var script := GDScript.new()
	script.source_code = """
extends Node
func get_assets_for_context(_context):
	return []
func format_assets_for_prompt(_assets):
	return ""
func get_asset_icons(_assets):
	return []
"""
	script.reload()
	var node := Node.new()
	node.set_script(script)
	return node
func _create_memory_store_mock(long_term_messages: Array[Dictionary], short_term_messages: Array[Dictionary], notes_messages: Array[Dictionary]) -> RefCounted:
	var script := GDScript.new()
	script.source_code = """
extends RefCounted
var _long_term_messages: Array = []
var _short_term_messages: Array = []
var _notes_messages: Array = []
func configure(long_term_messages, short_term_messages, notes_messages):
	_long_term_messages = long_term_messages
	_short_term_messages = short_term_messages
	_notes_messages = notes_messages
func get_long_term_context(_lang):
	return _long_term_messages
func get_notes_context(_lang):
	return _notes_messages
func get_short_term_memory():
	return _short_term_messages
"""
	script.reload()
	var store = script.new()
	store.configure(long_term_messages, short_term_messages, notes_messages)
	return store
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
