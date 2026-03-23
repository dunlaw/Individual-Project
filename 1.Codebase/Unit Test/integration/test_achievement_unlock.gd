extends Node
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var _initial_achievements: Dictionary = {}
var _initial_progress: Dictionary = {}
var _initial_reality: int = 0
var _initial_positive: int = 0
var _initial_entropy: int = 0
var _signal_log: Array = []
func _ready() -> void:
	print("\n[AchievementUnlockIntegration] Starting achievement unlock integration tests...")
	await get_tree().process_frame
	if not _check_dependencies():
		print("[AchievementUnlockIntegration] Missing dependencies, skipping tests")
		queue_free()
		return
	_backup_state()
	_test_mission_complete_triggers_achievement()
	_test_stat_change_triggers_reality_achievement()
	_test_stat_change_triggers_positive_achievement()
	_test_skill_check_chain_unlocks_achievement()
	_test_dilemma_progression_unlocks_achievements()
	await _test_achievement_signal_reaches_listeners()
	await _test_achievement_survives_save_load_cycle()
	_test_full_gameplay_loop_achievements()
	_restore_state()
	print("\n[AchievementUnlockIntegration] Results: %d/%d passed (%d failed)" % [
		passed_tests, total_tests, failed_tests])
	queue_free()
func _check_dependencies() -> bool:
	if not AchievementSystem:
		print("  SKIP: AchievementSystem autoload not found")
		return false
	if not GameState:
		print("  SKIP: GameState autoload not found")
		return false
	return true
func _backup_state() -> void:
	_initial_achievements = AchievementSystem.unlocked_achievements.duplicate(true)
	_initial_progress = AchievementSystem._progress_counters.duplicate(true)
	_initial_reality = GameState.reality_score
	_initial_positive = GameState.positive_energy
	_initial_entropy = GameState.entropy_level
func _restore_state() -> void:
	AchievementSystem.unlocked_achievements = _initial_achievements.duplicate(true)
	AchievementSystem._progress_counters = _initial_progress.duplicate(true)
	AchievementSystem.save_achievements()
	GameState.reality_score = _initial_reality
	GameState.positive_energy = _initial_positive
	GameState.entropy_level = _initial_entropy
func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("    PASS: %s" % test_name)
	else:
		failed_tests += 1
		print("    FAIL: %s" % test_name)
func _test_mission_complete_triggers_achievement() -> void:
	print("[Test] Mission complete → first_mission achievement...")
	AchievementSystem.reset_achievements()
	GameState.start_mission(1)
	GameState.mission_turn_count = 5
	AchievementSystem.check_mission_complete()
	assert_test(AchievementSystem.is_unlocked("first_mission"),
		"First mission completion unlocks first_mission achievement")
	assert_test(AchievementSystem._progress_counters["missions_completed"] == 1,
		"Progress counter tracks mission completion")
func _test_stat_change_triggers_reality_achievement() -> void:
	print("[Test] Reality score change → reality achievements...")
	AchievementSystem.reset_achievements()
	GameState.reality_score = 85
	AchievementSystem._check_reality_achievements(GameState.reality_score)
	assert_test(AchievementSystem.is_unlocked("reality_seeker"),
		"High reality score (85) unlocks reality_seeker")
	AchievementSystem.unlocked_achievements.erase("reality_crisis")
	GameState.reality_score = 15
	AchievementSystem._check_reality_achievements(GameState.reality_score)
	assert_test(AchievementSystem.is_unlocked("reality_crisis"),
		"Low reality score (15) unlocks reality_crisis")
func _test_stat_change_triggers_positive_achievement() -> void:
	print("[Test] Positive energy change → positive achievements...")
	AchievementSystem.reset_achievements()
	GameState.positive_energy = 95
	AchievementSystem._check_positive_achievements(GameState.positive_energy)
	assert_test(AchievementSystem.is_unlocked("positive_victim"),
		"High positive energy (95) unlocks positive_victim")
	AchievementSystem.unlocked_achievements.erase("positive_resistance")
	GameState.positive_energy = 15
	AchievementSystem._check_positive_achievements(GameState.positive_energy)
	assert_test(AchievementSystem.is_unlocked("positive_resistance"),
		"Low positive energy (15) unlocks positive_resistance")
func _test_skill_check_chain_unlocks_achievement() -> void:
	print("[Test] Skill check chain → logic_master achievement...")
	AchievementSystem.reset_achievements()
	for i in range(10):
		AchievementSystem.check_skill_check_success("logic")
	assert_test(AchievementSystem.is_unlocked("logic_master"),
		"10 logic successes unlocks logic_master")
	assert_test(AchievementSystem._progress_counters["logic_successes"] == 10,
		"Logic success counter accurately tracks 10 checks")
func _test_dilemma_progression_unlocks_achievements() -> void:
	print("[Test] Dilemma resolution progression → moral achievements...")
	AchievementSystem.reset_achievements()
	AchievementSystem.check_dilemma_resolved()
	assert_test(AchievementSystem.is_unlocked("moral_philosopher"),
		"First dilemma unlocks moral_philosopher")
	for i in range(4):
		AchievementSystem.check_dilemma_resolved()
	assert_test(AchievementSystem.is_unlocked("trolley_conductor"),
		"5th dilemma unlocks trolley_conductor")
	for i in range(5):
		AchievementSystem.check_dilemma_resolved()
	assert_test(AchievementSystem.is_unlocked("complicit"),
		"10th dilemma unlocks complicit")
func _test_achievement_signal_reaches_listeners() -> void:
	print("[Test] Achievement signal emission to listeners...")
	AchievementSystem.reset_achievements()
	_signal_log.clear()
	if not AchievementSystem.achievement_unlocked.is_connected(_on_achievement_signal):
		AchievementSystem.achievement_unlocked.connect(_on_achievement_signal)
	AchievementSystem.unlock_achievement("diary_keeper")
	await get_tree().create_timer(0.05).timeout
	assert_test(_signal_log.size() == 1,
		"Signal emitted exactly once for single unlock")
	assert_test(_signal_log.size() > 0 and _signal_log[0] == "diary_keeper",
		"Signal carries correct achievement ID")
	AchievementSystem.unlock_achievement("diary_keeper")
	await get_tree().create_timer(0.05).timeout
	assert_test(_signal_log.size() == 1,
		"Duplicate unlock does not emit additional signal")
	if AchievementSystem.achievement_unlocked.is_connected(_on_achievement_signal):
		AchievementSystem.achievement_unlocked.disconnect(_on_achievement_signal)
func _on_achievement_signal(achievement_id: String, _data: Dictionary) -> void:
	_signal_log.append(achievement_id)
func _test_achievement_survives_save_load_cycle() -> void:
	print("[Test] Achievement persistence through save/load...")
	AchievementSystem.reset_achievements()
	AchievementSystem.unlock_achievement("first_mission")
	AchievementSystem.unlock_achievement("reality_seeker")
	AchievementSystem._progress_counters["missions_completed"] = 7
	AchievementSystem._progress_counters["logic_successes"] = 4
	AchievementSystem.save_achievements()
	await get_tree().create_timer(0.1).timeout
	var saved_data = AchievementSystem.unlocked_achievements.duplicate(true)
	var saved_progress = AchievementSystem._progress_counters.duplicate(true)
	AchievementSystem.unlocked_achievements.clear()
	AchievementSystem._progress_counters["missions_completed"] = 0
	AchievementSystem._progress_counters["logic_successes"] = 0
	AchievementSystem.load_achievements()
	await get_tree().create_timer(0.1).timeout
	assert_test(AchievementSystem.is_unlocked("first_mission"),
		"first_mission survives save/load cycle")
	assert_test(AchievementSystem.is_unlocked("reality_seeker"),
		"reality_seeker survives save/load cycle")
	assert_test(AchievementSystem._progress_counters["missions_completed"] == 7,
		"Mission progress counter survives save/load")
	assert_test(AchievementSystem._progress_counters["logic_successes"] == 4,
		"Logic counter survives save/load")
func _test_full_gameplay_loop_achievements() -> void:
	print("[Test] Full gameplay loop: mission → stats → skills → achievements...")
	AchievementSystem.reset_achievements()
	GameState.start_mission(1)
	AchievementSystem.check_mission_complete()
	assert_test(AchievementSystem.is_unlocked("first_mission"),
		"[Loop] Mission completion triggers first_mission")
	GameState.reality_score = 82
	AchievementSystem._check_reality_achievements(82)
	assert_test(AchievementSystem.is_unlocked("reality_seeker"),
		"[Loop] High reality triggers reality_seeker")
	AchievementSystem.check_dilemma_resolved()
	assert_test(AchievementSystem.is_unlocked("moral_philosopher"),
		"[Loop] Dilemma resolution triggers moral_philosopher")
	var unlocked_count = AchievementSystem.get_unlocked_count()
	assert_test(unlocked_count >= 3,
		"[Loop] Multiple achievements unlocked in single session (got %d)" % unlocked_count)
	var percentage = AchievementSystem.get_progress_percentage()
	assert_test(percentage > 0.0 and percentage < 100.0,
		"[Loop] Progress percentage reflects partial completion (%.1f%%)" % percentage)
