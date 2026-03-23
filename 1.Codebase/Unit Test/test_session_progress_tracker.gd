extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const SessionProgressTrackerScript = preload("res://1.Codebase/src/scripts/core/session_progress_tracker.gd")
var tracker: SessionProgressTracker = null
func _ready() -> void:
	print("[SessionProgressTrackerTest] Starting unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_save_load_payload()
	_test_metadata_management()
	_test_language_setting()
	_test_reset()
	_teardown()
	print("[SessionProgressTrackerTest] All tests completed.")
	queue_free()
func _setup() -> void:
	print("[Test Setup] Creating SessionProgressTracker...")
	tracker = SessionProgressTrackerScript.new()
func _teardown() -> void:
	if tracker:
		tracker = null
func _test_initialization() -> void:
	print("[Test] Initialization...")
	_assert(tracker != null, "Tracker should be created")
	_assert(tracker.current_mission == 0, "Current mission should start at 0")
	_assert(tracker.missions_completed == 0, "Missions completed should start at 0")
	_assert(tracker.game_phase == GameConstants.GamePhase.HONEYMOON, "Should start in HONEYMOON phase")
	_assert(tracker.is_session_active == false, "Session should not be active initially")
	print("[Test] Initialization PASSED")
func _test_save_load_payload() -> void:
	print("[Test] Save/Load payload...")
	tracker.current_mission = 5
	tracker.missions_completed = 4
	tracker.complaint_counter = 3
	tracker.game_phase = GameConstants.GamePhase.CRISIS
	tracker.honeymoon_charges = 2
	tracker.is_session_active = true
	tracker.current_language = "zh"
	tracker.metadata = {"key": "value", "nested": {"a": 1}}
	var payload = tracker.get_save_payload()
	_assert(payload.current_mission == 5, "Payload should match current_mission")
	_assert(payload.missions_completed == 4, "Payload should match missions_completed")
	_assert(payload.game_phase == GameConstants.GamePhase.CRISIS, "Payload should match game_phase")
	_assert(payload.metadata.key == "value", "Payload should match metadata")
	_assert(payload.is_session_active == true, "Payload should match is_session_active")
	var new_tracker = SessionProgressTrackerScript.new()
	new_tracker.apply_save_payload(payload)
	_assert(new_tracker.current_mission == 5, "Restored mission should match")
	_assert(new_tracker.missions_completed == 4, "Restored missions completed should match")
	_assert(new_tracker.game_phase == GameConstants.GamePhase.CRISIS, "Restored game phase should match")
	_assert(new_tracker.is_session_active == true, "Restored session active should match")
	_assert(new_tracker.metadata.key == "value", "Restored metadata should match")
	_assert(new_tracker.metadata == tracker.metadata, "Metadata content should match")
	_assert(not is_same(new_tracker.metadata, tracker.metadata), "Metadata should be a new instance")
	print("[Test] Save/Load payload PASSED")
func _test_metadata_management() -> void:
	print("[Test] Metadata management...")
	tracker.metadata = {"keep": 1, "delete1": 2, "delete2": 3}
	var removed = tracker.delete_metadata_keys(["delete1", "delete2", "missing"])
	_assert(removed.size() == 2, "Should remove 2 keys")
	_assert("delete1" in removed, "Should report delete1 removed")
	_assert("delete2" in removed, "Should report delete2 removed")
	_assert(tracker.metadata.has("keep"), "Should keep other keys")
	_assert(not tracker.metadata.has("delete1"), "Should remove delete1")
	print("[Test] Metadata management PASSED")
func _test_language_setting() -> void:
	print("[Test] Language setting...")
	tracker.current_language = "en"
	tracker.set_language("zh")
	_assert(tracker.current_language == "zh", "Should set language to zh")
	tracker.set_language("")
	_assert(tracker.current_language == "zh", "Should ignore empty language")
	print("[Test] Language setting PASSED")
func _test_reset() -> void:
	print("[Test] Reset...")
	tracker.current_mission = 10
	tracker.metadata = {"dirty": true}
	tracker.is_session_active = true
	tracker.reset()
	_assert(tracker.current_mission == 0, "Should reset mission")
	_assert(tracker.metadata.is_empty(), "Should clear metadata")
	_assert(tracker.is_session_active == false, "Should reset session active")
	_assert(tracker.game_phase == GameConstants.GamePhase.HONEYMOON, "Should reset phase")
	print("[Test] Reset PASSED")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
