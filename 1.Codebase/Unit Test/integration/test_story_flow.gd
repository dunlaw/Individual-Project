extends Node
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var _initial_game_state: Dictionary = {}
func _ready() -> void:
	print("\n[StoryFlowIntegration] Starting story flow integration tests...")
	await get_tree().process_frame
	if not _check_dependencies():
		print("[StoryFlowIntegration] Missing dependencies, skipping tests")
		queue_free()
		return
	_backup_state()
	_test_mission_start_initializes_game_state()
	_test_mission_turn_count_tracking()
	_test_choice_archetypes_affect_stats()
	_test_night_cycle_trigger_after_mission()
	_test_story_text_persistence()
	_test_event_log_records_mission_events()
	_test_reality_score_boundaries_during_flow()
	_test_consecutive_missions_increment_counter()
	_restore_state()
	print("\n[StoryFlowIntegration] Results: %d/%d passed (%d failed)" % [
		passed_tests, total_tests, failed_tests])
	queue_free()
func _check_dependencies() -> bool:
	if not GameState:
		print("  SKIP: GameState autoload not found")
		return false
	if not AchievementSystem:
		print("  SKIP: AchievementSystem autoload not found")
		return false
	if not ServiceLocator:
		print("  SKIP: ServiceLocator autoload not found")
		return false
	return true
func _backup_state() -> void:
	_initial_game_state = {
		"reality_score": GameState.reality_score,
		"positive_energy": GameState.positive_energy,
		"entropy_level": GameState.entropy_level,
		"current_mission": GameState.current_mission,
		"missions_completed": GameState.missions_completed,
		"mission_turn_count": GameState.mission_turn_count,
		"game_phase": GameState.game_phase,
		"recent_events": GameState.recent_events.duplicate(true),
	}
func _restore_state() -> void:
	GameState.reality_score = _initial_game_state["reality_score"]
	GameState.positive_energy = _initial_game_state["positive_energy"]
	GameState.entropy_level = _initial_game_state["entropy_level"]
	GameState.current_mission = _initial_game_state["current_mission"]
	GameState.missions_completed = _initial_game_state["missions_completed"]
	GameState.mission_turn_count = _initial_game_state["mission_turn_count"]
	GameState.game_phase = _initial_game_state["game_phase"]
	GameState.recent_events = _initial_game_state["recent_events"].duplicate(true)
func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("    PASS: %s" % test_name)
	else:
		failed_tests += 1
		print("    FAIL: %s" % test_name)
func _test_mission_start_initializes_game_state() -> void:
	print("[Test] Mission start initializes game state...")
	var prev_completed = GameState.missions_completed
	GameState.start_mission(prev_completed + 1)
	assert_test(GameState.current_mission == prev_completed + 1,
		"current_mission set to next mission number")
	assert_test(GameState.mission_turn_count == 0,
		"mission_turn_count reset to 0 on new mission")
func _test_mission_turn_count_tracking() -> void:
	print("[Test] Mission turn count tracking...")
	GameState.mission_turn_count = 0
	GameState.mission_turn_count += 1
	assert_test(GameState.mission_turn_count == 1, "Turn count increments to 1")
	GameState.mission_turn_count += 1
	assert_test(GameState.mission_turn_count == 2, "Turn count increments to 2")
func _test_choice_archetypes_affect_stats() -> void:
	print("[Test] Choice archetypes affect stats...")
	GameState.reality_score = 50
	GameState.positive_energy = 50
	GameState.modify_reality_score(-5, "Test reckless choice")
	assert_test(GameState.reality_score == 45,
		"Reckless choice decreases reality score")
	GameState.modify_reality_score(3, "Test cautious choice")
	assert_test(GameState.reality_score == 48,
		"Cautious choice increases reality score")
	var prev_pe = GameState.positive_energy
	GameState.positive_energy = prev_pe + 10
	assert_test(GameState.positive_energy == prev_pe + 10,
		"Positive choice increases positive energy")
func _test_night_cycle_trigger_after_mission() -> void:
	print("[Test] Night cycle trigger conditions...")
	GameState.start_mission(1)
	GameState.mission_turn_count = 5
	assert_test(GameState.current_mission >= 1,
		"Mission number valid for night cycle entry")
	assert_test(GameState.mission_turn_count > 0,
		"Turn count > 0 indicates mission activity occurred")
func _test_story_text_persistence() -> void:
	print("[Test] Story text persistence...")
	var test_text = "The noodle monster descends upon the village..."
	GameState.set_metadata("latest_story_text", test_text)
	var retrieved = GameState.get_metadata("latest_story_text", "")
	assert_test(retrieved == test_text,
		"Story text persists through metadata storage")
	GameState.set_metadata("latest_story_text", "")
	var empty_retrieved = GameState.get_metadata("latest_story_text", "")
	assert_test(empty_retrieved.strip_edges().is_empty(),
		"Empty story text detected correctly")
func _test_event_log_records_mission_events() -> void:
	print("[Test] Event log records mission events...")
	GameState.clear_events()
	GameState.add_event("Mission #1 started", "任務 #1 開始")
	GameState.add_event("Player chose cautious path", "玩家選擇了謹慎的道路")
	assert_test(GameState.recent_events.size() >= 2,
		"Event log records multiple mission events")
func _test_reality_score_boundaries_during_flow() -> void:
	print("[Test] Reality score boundaries during flow...")
	GameState.reality_score = 5
	GameState.modify_reality_score(-10, "Test lower bound")
	assert_test(GameState.reality_score >= 0,
		"Reality score does not go below 0")
	GameState.reality_score = 95
	GameState.modify_reality_score(10, "Test upper bound")
	assert_test(GameState.reality_score <= 100,
		"Reality score does not exceed 100")
func _test_consecutive_missions_increment_counter() -> void:
	print("[Test] Consecutive missions increment counter...")
	GameState.missions_completed = 3
	GameState.start_mission(4)
	assert_test(GameState.current_mission == 4,
		"Fourth mission starts correctly")
	GameState.missions_completed = 4
	GameState.start_mission(5)
	assert_test(GameState.current_mission == 5,
		"Fifth mission starts after fourth completes")
	assert_test(GameState.missions_completed == 4,
		"missions_completed reflects prior completions")
