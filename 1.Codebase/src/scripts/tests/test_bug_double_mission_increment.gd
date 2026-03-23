extends Node
var tests_passed: int = 0
var tests_failed: int = 0
var _game_state_snapshot: Dictionary = {}
func _ready() -> void:
	print("Running mission increment regression test...")
	await get_tree().process_frame
	if not GameState or not AchievementSystem:
		_assert_test(false, "GameState and AchievementSystem autoloads are available")
		queue_free()
		return
	_game_state_snapshot = GameState.get_save_data()
	_test_mission_completion_only_increments_once()
	GameState.load_save_data(_game_state_snapshot)
	print("Mission increment regression summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _assert_test(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("PASS: %s" % test_name)
		return
	tests_failed += 1
	print("FAIL: %s" % test_name)
	if not details.is_empty():
		print(details)
func _test_mission_completion_only_increments_once() -> void:
	var completed_before: int = GameState.missions_completed
	var achievement_before: int = AchievementSystem._progress_counters.get("missions_completed", 0)
	var next_mission_id := completed_before + 1
	GameState.start_mission(next_mission_id)
	GameState.complete_mission(true)
	_assert_test(
		GameState.missions_completed == completed_before + 1,
		"GameState.missions_completed increases by exactly 1 per completion",
		"Expected %d, got %d" % [completed_before + 1, GameState.missions_completed],
	)
	_assert_test(
		AchievementSystem._progress_counters.get("missions_completed", 0) == achievement_before + 1,
		"AchievementSystem mission counter increases by exactly 1 per completion",
		"Expected %d, got %d" % [
			achievement_before + 1,
			AchievementSystem._progress_counters.get("missions_completed", 0),
		],
	)
	GameState.start_mission(GameState.missions_completed + 1)
	_assert_test(
		GameState.current_mission == completed_before + 2,
		"Starting the next mission advances current_mission to the next slot",
		"Expected mission %d, got %d" % [completed_before + 2, GameState.current_mission],
	)
	_assert_test(
		GameState.missions_completed == completed_before + 1,
		"Starting a new mission does not double-increment missions_completed",
		"Expected %d, got %d" % [completed_before + 1, GameState.missions_completed],
	)
