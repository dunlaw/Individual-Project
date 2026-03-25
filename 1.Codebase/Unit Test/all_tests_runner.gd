extends Node

# ---------------------------------------------------------------------------
# Inline assertion tracking  (assert_test calls within this file)
# ---------------------------------------------------------------------------
var _inline_passed: int = 0
var _inline_failed: int = 0
var _inline_failures: Array[String] = []

# ---------------------------------------------------------------------------
# Aggregated sub-suite tracking
# ---------------------------------------------------------------------------
var _total_passed: int = 0
var _total_failed: int = 0
var _suites_with_results: int = 0
var _suites_without_results: int = 0
var _suite_failures: Array[String] = []   # suite names that had failures

# Per-suite timing/result records for the final table.
# Each entry: { name, passed, failed, duration_ms, tracked, timed_out, category }
var _suite_records: Array[Dictionary] = []

# Scratch variable filled by _capture_suite_result() before tree_exited
var _pending_result: Dictionary = {}

# ---------------------------------------------------------------------------
# Files to exclude from auto-discovery
# ---------------------------------------------------------------------------
const SKIP_FILES: Array[String] = [
	"all_tests_runner.gd",
	"ui_tests_runner.gd",
	"quick_verify.gd",
	"test_prayer_sanitization.gd",         # extends SceneTree — not a Node
	"test_gemini_session_resumption.gd",   # extends SceneTree — not a Node
]

# Maximum seconds a single discovered suite may run before it is force-killed.
const SUITE_TIMEOUT_SEC: float = 60.0

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("   RUNNING ALL UNIT TESTS")
	print("=".repeat(80))
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	await get_tree().process_frame

	var discovered := _discover_test_files("res://1.Codebase/Unit Test")
	discovered.sort()

	var total_suites := 1 + discovered.size()   # 1 inline + N discovered
	print("\n   Discovered %d test files  (+1 inline suite)  = %d suites total" \
			% [discovered.size(), total_suites])
	print("   Skipping %d file(s): %s\n" \
			% [SKIP_FILES.size(), ", ".join(SKIP_FILES)])

	# ── Suite 1: inline quick checks ──────────────────────────────────────
	_print_suite_header(1, total_suites, "Quick Sanity Checks  [inline]")
	var t0 := Time.get_ticks_msec()
	_test_service_locator()
	_test_error_reporter()
	_test_game_state_quick()
	_test_ai_system_quick()
	_flush_inline_to_totals()
	var inline_ms := Time.get_ticks_msec() - t0
	_print_suite_footer_inline(inline_ms)
	_suite_records.append({
		"name": "Quick Sanity Checks [inline]",
		"passed": _inline_passed,
		"failed": _inline_failed,
		"duration_ms": inline_ms,
		"tracked": true,
		"timed_out": false,
		"category": "inline",
	})

	# ── Auto-discovered suites ────────────────────────────────────────────
	for idx in discovered.size():
		var path: String = discovered[idx]
		var suite_name: String = path.get_file().get_basename()
		var category: String = "integration" if "/integration/" in path else "unit"
		_print_suite_header(idx + 2, total_suites, suite_name + "  [" + category + "]")
		var ts := Time.get_ticks_msec()
		_pending_result = {}
		await _run_test_file(path)
		var dur_ms := Time.get_ticks_msec() - ts
		_print_suite_footer_file(suite_name, dur_ms)
		_suite_records.append({
			"name": suite_name,
			"passed": _pending_result.get("passed", 0),
			"failed": _pending_result.get("failed", 0),
			"duration_ms": dur_ms,
			"tracked": not _pending_result.is_empty(),
			"timed_out": _pending_result.get("timed_out", false),
			"category": category,
		})

	_print_final_summary(total_suites)
	await get_tree().create_timer(0.2).timeout
	_prepare_for_shutdown()
	Engine.print_error_messages = false
	get_tree().quit(0 if _total_failed == 0 else 1)

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------
func _discover_test_files(base_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(base_path)
	if dir == null:
		push_warning("all_tests_runner: cannot open '%s'" % base_path)
		return files
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			files.append_array(_discover_test_files(base_path + "/" + entry))
		elif entry.begins_with("test_") and entry.ends_with(".gd") \
				and entry not in SKIP_FILES:
			files.append(base_path + "/" + entry)
		entry = dir.get_next()
	dir.list_dir_end()
	return files

# ---------------------------------------------------------------------------
# Running a single discovered test file
# ---------------------------------------------------------------------------
func _run_test_file(path: String) -> void:
	var TestClass = load(path)
	if TestClass == null:
		push_warning("all_tests_runner: cannot load '%s'" % path)
		return
	var inst: Node = TestClass.new()
	# Connect BEFORE adding to tree so we catch tree_exiting
	inst.tree_exiting.connect(_capture_suite_result.bind(inst))
	add_child(inst)
	# Per-suite watchdog: force-kill a hanging suite so the rest can continue.
	var _timed_out := false
	var _watchdog := get_tree().create_timer(SUITE_TIMEOUT_SEC)
	_watchdog.timeout.connect(func():
		if is_instance_valid(inst) and inst.is_inside_tree():
			_timed_out = true
			push_warning("all_tests_runner: suite '%s' timed out after %.0fs — force-killing" \
					% [path.get_file(), SUITE_TIMEOUT_SEC])
			inst.queue_free()
	)
	await inst.tree_exited
	if _timed_out:
		_pending_result["timed_out"] = true

# Read result properties while the node is still in the tree
func _capture_suite_result(inst: Node) -> void:
	_pending_result = _read_results(inst)

# Try every naming convention used across the test files
func _read_results(inst: Node) -> Dictionary:
	# Convention A: tests_passed / tests_failed
	if "tests_passed" in inst:
		return {
			"passed": inst.get("tests_passed"),
			"failed": inst.get("tests_failed") if "tests_failed" in inst else 0,
		}
	# Convention B: passed_tests / failed_tests  (integration/ folder)
	if "passed_tests" in inst:
		return {
			"passed": inst.get("passed_tests"),
			"failed": inst.get("failed_tests") if "failed_tests" in inst else 0,
		}
	# Convention C: _passed / _failed  (int)
	if "_passed" in inst and inst.get("_passed") is int:
		return {
			"passed": inst.get("_passed"),
			"failed": inst.get("_failed") if "_failed" in inst and inst.get("_failed") is int else 0,
		}
	# Convention D: _passed_tests + _total_tests
	if "_passed_tests" in inst:
		var p: int = inst.get("_passed_tests")
		var total: int = inst.get("_total_tests") if "_total_tests" in inst else 0
		return {"passed": p, "failed": maxi(0, total - p)}
	# Convention E: _test_results  Array[{name, passed}]
	if "_test_results" in inst and inst.get("_test_results") is Array:
		var p := 0
		var f := 0
		var failed_names: Array[String] = []
		for r in inst.get("_test_results"):
			if r.get("passed", false):
				p += 1
			else:
				f += 1
				var n: String = r.get("name", "")
				if n != "":
					failed_names.append(n)
		return {"passed": p, "failed": f, "failed_names": failed_names}
	# Convention F: test_results  Array[{name, passed}]  (no leading underscore)
	if "test_results" in inst and inst.get("test_results") is Array:
		var p := 0
		var f := 0
		var failed_names: Array[String] = []
		for r in inst.get("test_results"):
			if r.get("passed", false):
				p += 1
			else:
				f += 1
				var n: String = r.get("name", "")
				if n != "":
					failed_names.append(n)
		return {"passed": p, "failed": f, "failed_names": failed_names}
	# Unknown — no trackable counter
	return {}

# ---------------------------------------------------------------------------
# Printing helpers
# ---------------------------------------------------------------------------
func _print_suite_header(idx: int, total: int, suite_name: String) -> void:
	print("\n [%d/%d]  %s" % [idx, total, suite_name])
	print("-".repeat(80))

func _flush_inline_to_totals() -> void:
	_total_passed += _inline_passed
	_total_failed += _inline_failed
	_suites_with_results += 1

func _print_suite_footer_inline(duration_ms: int) -> void:
	var mark := "PASS" if _inline_failed == 0 else "FAIL"
	print("         [%s]  %d passed  %d failed  |  %d ms" \
			% [mark, _inline_passed, _inline_failed, duration_ms])

func _print_suite_footer_file(suite_name: String, duration_ms: int) -> void:
	if _pending_result.get("timed_out", false):
		print("         [TIME]  timed out after %d ms  —  counted as 1 failure" % duration_ms)
		_total_failed += 1
		_suites_with_results += 1
		_suite_failures.append(suite_name + "  [TIMEOUT]")
		return
	if _pending_result.is_empty():
		print("         [----]  results not tracked  |  %d ms" % duration_ms)
		_suites_without_results += 1
	else:
		var p: int = _pending_result.get("passed", 0)
		var f: int = _pending_result.get("failed", 0)
		var mark := "PASS" if f == 0 else "FAIL"
		print("         [%s]  %d passed  %d failed  |  %d ms" % [mark, p, f, duration_ms])
		_total_passed += p
		_total_failed += f
		_suites_with_results += 1
		if f > 0:
			_suite_failures.append(suite_name)
			var failed_names: Array = _pending_result.get("failed_names", [])
			for fname in failed_names:
				print("    FAIL  %s" % fname)

func _print_final_summary(total_suites: int) -> void:
	var total_assertions := _total_passed + _total_failed
	var pass_rate := 100.0 * float(_total_passed) / float(total_assertions) \
			if total_assertions > 0 else 0.0

	# ── Category breakdown ──────────────────────────────────────────────
	var unit_p := 0; var unit_f := 0; var unit_count := 0
	var integ_p := 0; var integ_f := 0; var integ_count := 0
	for rec in _suite_records:
		if rec.get("category", "unit") == "integration":
			integ_count += 1
			integ_p += rec.get("passed", 0)
			integ_f += rec.get("failed", 0)
		else:
			unit_count += 1
			unit_p += rec.get("passed", 0)
			unit_f += rec.get("failed", 0)

	print("\n" + "=".repeat(80))
	print("   FINAL TEST SUMMARY")
	print("=".repeat(80))
	print("")
	print("  Suites run       : %d  (unit: %d  integration: %d)" \
			% [total_suites, unit_count, integ_count])
	print("  Suites tracked   : %d" % _suites_with_results)
	if _suites_without_results > 0:
		print("  Suites untracked : %d  !! check output above !!" \
				% _suites_without_results)
	print("")
	print("  Total assertions : %d" % total_assertions)
	print("  Passed           : %d  (unit: %d  integration: %d)" \
			% [_total_passed, unit_p, integ_p])
	print("  Failed           : %d  (unit: %d  integration: %d)" \
			% [_total_failed, unit_f, integ_f])
	print("  Pass rate        : %.1f%%" % pass_rate)
	print("")

	if _total_failed == 0:
		print("   ALL TRACKED TESTS PASSED!")
		if _suites_without_results > 0:
			print("   (%d untracked suites — check their output above)" \
					% _suites_without_results)
	else:
		print("   SOME TESTS FAILED")
		if _inline_failures.size() > 0:
			print("")
			print("  Failed inline assertions:")
			for name in _inline_failures:
				print("    FAIL  %s" % name)
		if _suite_failures.size() > 0:
			print("")
			print("  Suites with failures:")
			for s in _suite_failures:
				print("    FAIL  %s" % s)

	# ── Per-suite timing table ──────────────────────────────────────────
	print("")
	print("  Per-suite results  (sorted by duration, slowest first):")
	print("  %-42s  %5s  %5s  %7s  %s" % ["Suite", "pass", "fail", "ms", "status"])
	print("  " + "-".repeat(72))
	var sorted_records := _suite_records.duplicate()
	sorted_records.sort_custom(func(a, b): return a["duration_ms"] > b["duration_ms"])
	for rec in sorted_records:
		var status: String
		if rec.get("timed_out", false):
			status = "TIMEOUT"
		elif not rec.get("tracked", true):
			status = "----"
		elif rec.get("failed", 0) > 0:
			status = "FAIL"
		else:
			status = "pass"
		var label: String = rec["name"]
		if label.length() > 42:
			label = label.substr(0, 39) + "..."
		print("  %-42s  %5d  %5d  %7d  %s" % [
			label,
			rec.get("passed", 0),
			rec.get("failed", 0),
			rec.get("duration_ms", 0),
			status,
		])

	# ── Slowest-suite callout ───────────────────────────────────────────
	if _suite_records.size() >= 3:
		print("")
		print("  Slowest suites:")
		for i in mini(3, sorted_records.size()):
			var rec: Dictionary = sorted_records[i]
			print("    %d ms  —  %s" % [rec.get("duration_ms", 0), rec["name"]])

	print("\n" + "=".repeat(80) + "\n")

# ---------------------------------------------------------------------------
# Inline assertion helper  (used only by the four quick-check methods below)
# ---------------------------------------------------------------------------
func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		_inline_passed += 1
		print("    PASS  %s" % test_name)
	else:
		_inline_failed += 1
		_inline_failures.append(test_name)
		print("    FAIL  %s" % test_name)

# ---------------------------------------------------------------------------
# Inline quick-check suites
# ---------------------------------------------------------------------------
func _test_service_locator() -> void:
	assert_test(ServiceLocator != null, "ServiceLocator exists")
	var ai_manager = ServiceLocator.get_ai_manager()
	assert_test(ai_manager != null, "Can get AIManager via ServiceLocator")
	var game_state = ServiceLocator.get_game_state()
	assert_test(game_state != null, "Can get GameState via ServiceLocator")
	var asset_registry = ServiceLocator.get_asset_registry()
	assert_test(asset_registry != null, "Can get AssetRegistry via ServiceLocator")
	var achievement_system = ServiceLocator.get_achievement_system()
	assert_test(achievement_system != null, "Can get AchievementSystem via ServiceLocator")
	var services = ServiceLocator.list_services()
	assert_test(services.size() > 5, "ServiceLocator has multiple services registered")

func _test_error_reporter() -> void:
	assert_test(ErrorReporter != null, "ErrorReporter exists as autoload")
	ErrorReporter.report_info("TestSuite", "Test info message")
	assert_test(true, "Can report info message")
	ErrorReporter.report_warning("TestSuite", "Test warning message")
	assert_test(true, "Can report warning message")
	var prev := ErrorReporter.enable_console_logs
	ErrorReporter.enable_console_logs = false
	ErrorReporter.report_error("TestSuite", "Test error message", 42, false, {"detail": "test"})
	ErrorReporter.enable_console_logs = prev
	assert_test(true, "Can report error with details")
	var stats = ErrorReporter.get_statistics()
	assert_test(stats.has("errors"), "ErrorReporter tracks error statistics")
	assert_test(stats.has("warnings"), "ErrorReporter tracks warning statistics")
	assert_test(stats["total"] > 0, "ErrorReporter counts total messages")
	assert_test(ErrorReporter.enable_console_logs is bool, "ErrorReporter has console_logs config")
	assert_test(ErrorReporter.enable_user_notifications is bool, "ErrorReporter has notifications config")
	ErrorReporter.reset_statistics()

func _test_game_state_quick() -> void:
	assert_test(GameState != null, "GameState exists")
	var init_reality := GameState.reality_score
	GameState.modify_reality_score(5, "Test")
	assert_test(GameState.reality_score == init_reality + 5, "Reality score modification works")
	GameState.reality_score = init_reality
	GameState.reality_score = 98
	GameState.modify_reality_score(10, "Test clamping")
	assert_test(GameState.reality_score == 100, "Reality score clamps at 100")
	GameState.reality_score = init_reality
	GameState.clear_events()
	GameState.add_event(
		"Test event EN",
		(LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") if LocalizationManager else "Test Event") + " ZH",
	)
	assert_test(GameState.recent_events.size() > 0, "Event logging works")
	var result := GameState.skill_check("logic", 5)
	assert_test(result.has("success"), "Skill check returns result structure")
	assert_test(result.has("roll"), "Skill check includes roll value")
	GameState.set_game_phase(GameConstants.GamePhase.CRISIS)
	assert_test(GameState.game_phase == GameConstants.GamePhase.CRISIS, "Game phase changes correctly")
	GameState.set_game_phase(GameConstants.GamePhase.NORMAL)
	var entropy := GameState.calculate_void_entropy()
	assert_test(entropy >= 0.0 and entropy <= 1.0, "Entropy calculation returns valid range")

func _test_ai_system_quick() -> void:
	assert_test(AIManager != null, "AIManager exists")
	var current_provider = AIManager.current_provider
	assert_test(
		current_provider in [
			AIManager.AIProvider.GEMINI,
			AIManager.AIProvider.OPENROUTER,
			AIManager.AIProvider.OLLAMA,
			AIManager.AIProvider.OPENAI,
			AIManager.AIProvider.CLAUDE,
			AIManager.AIProvider.LMSTUDIO,
			AIManager.AIProvider.AI_ROUTER,
			AIManager.AIProvider.MOCK_MODE,
		],
		"AIManager has valid provider",
	)
	assert_test(AIManager.memory_store != null, "AIManager has memory store")
	AIManager.clear_notes()
	AIManager.register_note_pair(
		"Test EN",
		(LocalizationManager.get_translation("TEST_STAT_MODIFIER", "zh") if LocalizationManager else "Test") + " ZH",
		["test"], 2, "test",
	)
	var note_count: int = AIManager.memory_store.get_note_count()
	assert_test(note_count > 0, "AI note registration works")
	AIManager.clear_notes()
	assert_test(AIManager.gemini_model is String, "Gemini model configured")
	assert_test(AIManager.openrouter_model is String, "OpenRouter model configured")
	assert_test(AIManager.ollama_model is String, "Ollama model configured")
	assert_test(AIManager.custom_ai_tone_style.length() > 0, "AI tone style is set")

# ---------------------------------------------------------------------------
# Shutdown
# ---------------------------------------------------------------------------
func _prepare_for_shutdown() -> void:
	_inline_failures.clear()
	_suite_failures.clear()
	if AIManager:
		if AIManager.has_method("cancel_parallel_requests"):
			AIManager.cancel_parallel_requests()
		if AIManager.has_method("cancel_pending_requests"):
			AIManager.cancel_pending_requests()
		if AIManager.has_method("clear_pending_voice_input"):
			AIManager.clear_pending_voice_input()
		if AIManager.has_method("clear_notes"):
			AIManager.clear_notes()
		if AIManager.has_method("clear_memory"):
			AIManager.clear_memory()
		if AIManager.has_method("clear_call_log"):
			AIManager.clear_call_log()
		AIManager.pending_callback = Callable()
		AIManager.last_prompt_metrics = {}
	if GameState and GameState.has_method("clear_all_debuffs"):
		GameState.clear_all_debuffs()
