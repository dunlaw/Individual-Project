extends Node
var tests_passed: int = 0
var tests_failed: int = 0
var initial_achievements: Dictionary = {}
var initial_progress: Dictionary = {}
var signal_received: bool = false
var signal_achievement_id: String = ""
func _ready() -> void:
	print("[AchievementSystemTest] Starting AchievementSystem unit tests...")
	await get_tree().process_frame
	if not AchievementSystem:
		_assert_test(false, "AchievementSystem autoload exists")
		print("[AchievementSystemTest] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
		queue_free()
		return
	_backup_state()
	_test_system_initialization()
	_test_unlock_achievement()
	await _test_duplicate_unlock_prevention()
	_test_invalid_achievement()
	_test_progress_counters()
	_test_mission_achievements()
	_test_stat_based_achievements()
	_test_skill_check_achievements()
	_test_dilemma_achievements()
	await _test_signal_emission()
	await _test_save_load_persistence()
	_test_state_snapshot()
	_test_achievement_queries()
	_test_reset_functionality()
	_restore_state()
	print("[AchievementSystemTest] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _assert_test(condition: bool, label: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % label)
		return
	tests_failed += 1
	print("    FAIL  %s%s" % [label, (": %s" % details) if not details.is_empty() else ""])
func _backup_state() -> void:
	initial_achievements = AchievementSystem.unlocked_achievements.duplicate(true)
	initial_progress = AchievementSystem._progress_counters.duplicate(true)
	AchievementSystem.reset_achievements()
func _restore_state() -> void:
	AchievementSystem.unlocked_achievements = initial_achievements.duplicate(true)
	AchievementSystem._progress_counters = initial_progress.duplicate(true)
	AchievementSystem.save_achievements()
func _test_system_initialization() -> void:
	print("[Test] System initialization...")
	_assert_test(AchievementSystem != null, "AchievementSystem autoload exists")
	_assert_test(AchievementSystem.ACHIEVEMENTS is Dictionary, "ACHIEVEMENTS is a Dictionary")
	_assert_test(AchievementSystem.ACHIEVEMENTS.size() > 0, "ACHIEVEMENTS contains definitions")
	_assert_test(AchievementSystem.unlocked_achievements is Dictionary, "unlocked_achievements is a Dictionary")
	_assert_test(AchievementSystem._progress_counters is Dictionary, "Progress counters exist")
	_assert_test(AchievementSystem.ACHIEVEMENTS.has("first_mission"), "first_mission achievement exists")
	_assert_test(AchievementSystem.ACHIEVEMENTS.has("reality_seeker"), "reality_seeker achievement exists")
	_assert_test(AchievementSystem.ACHIEVEMENTS.has("skill_master"), "skill_master achievement exists")
func _test_unlock_achievement() -> void:
	print("[Test] Unlock achievement...")
	var initial_count = AchievementSystem.get_unlocked_count()
	AchievementSystem.unlock_achievement("first_mission")
	_assert_test(AchievementSystem.is_unlocked("first_mission"), "Achievement unlock marks first_mission unlocked")
	_assert_test(AchievementSystem.get_unlocked_count() == initial_count + 1, "Unlocked count increases by one")
	_assert_test(AchievementSystem.unlocked_achievements.has("first_mission"), "Unlocked achievement is stored in dictionary")
	var timestamp = AchievementSystem.unlocked_achievements["first_mission"]
	_assert_test(timestamp > 0, "Unlocked achievement timestamp is positive")
func _test_duplicate_unlock_prevention() -> void:
	print("[Test] Duplicate unlock prevention...")
	AchievementSystem.unlock_achievement("survivor")
	var count_after_first = AchievementSystem.get_unlocked_count()
	var timestamp_first = AchievementSystem.unlocked_achievements["survivor"]
	await get_tree().create_timer(0.01).timeout
	AchievementSystem.unlock_achievement("survivor")
	var count_after_second = AchievementSystem.get_unlocked_count()
	var timestamp_second = AchievementSystem.unlocked_achievements["survivor"]
	_assert_test(count_after_second == count_after_first, "Duplicate unlock does not increase count")
	_assert_test(timestamp_second == timestamp_first, "Duplicate unlock does not change timestamp")
func _test_invalid_achievement() -> void:
	print("[Test] Invalid achievement handling...")
	var count_before = AchievementSystem.get_unlocked_count()
	AchievementSystem.unlock_achievement("nonexistent_achievement_xyz")
	var count_after = AchievementSystem.get_unlocked_count()
	_assert_test(count_after == count_before, "Invalid achievement does not change unlocked count")
	_assert_test(not AchievementSystem.is_unlocked("nonexistent_achievement_xyz"), "Invalid achievement stays locked")
func _test_progress_counters() -> void:
	print("[Test] Progress counters...")
	AchievementSystem._progress_counters["missions_completed"] = 0
	AchievementSystem._progress_counters["journal_entries"] = 0
	AchievementSystem._progress_counters["gloria_triggers"] = 0
	_assert_test(AchievementSystem._progress_counters.has("missions_completed"), "Progress counters include missions_completed")
	_assert_test(AchievementSystem._progress_counters.has("journal_entries"), "Progress counters include journal_entries")
	_assert_test(AchievementSystem._progress_counters.has("gloria_triggers"), "Progress counters include gloria_triggers")
	_assert_test(AchievementSystem._progress_counters.has("prayers_made"), "Progress counters include prayers_made")
	_assert_test(AchievementSystem._progress_counters.has("logic_successes"), "Progress counters include logic_successes")
	_assert_test(AchievementSystem._progress_counters.has("perception_successes"), "Progress counters include perception_successes")
func _test_mission_achievements() -> void:
	print("[Test] Mission achievements...")
	AchievementSystem._progress_counters["missions_completed"] = 0
	AchievementSystem.unlocked_achievements.erase("first_mission")
	AchievementSystem.unlocked_achievements.erase("survivor")
	AchievementSystem.unlocked_achievements.erase("veteran")
	AchievementSystem.check_mission_complete()
	_assert_test(AchievementSystem._progress_counters["missions_completed"] == 1, "Mission completion increments counter to 1")
	_assert_test(AchievementSystem.is_unlocked("first_mission"), "First mission completion unlocks first_mission")
	AchievementSystem._progress_counters["missions_completed"] = 9
	AchievementSystem.check_mission_complete()
	_assert_test(AchievementSystem._progress_counters["missions_completed"] == 10, "Mission counter reaches 10")
	_assert_test(AchievementSystem.is_unlocked("survivor"), "Mission counter 10 unlocks survivor")
	AchievementSystem._progress_counters["missions_completed"] = 49
	AchievementSystem.check_mission_complete()
	_assert_test(AchievementSystem._progress_counters["missions_completed"] == 50, "Mission counter reaches 50")
	_assert_test(AchievementSystem.is_unlocked("veteran"), "Mission counter 50 unlocks veteran")
func _test_stat_based_achievements() -> void:
	print("[Test] Stat-based achievements...")
	AchievementSystem.unlocked_achievements.erase("reality_seeker")
	AchievementSystem.unlocked_achievements.erase("reality_crisis")
	AchievementSystem.unlocked_achievements.erase("positive_resistance")
	AchievementSystem.unlocked_achievements.erase("positive_victim")
	AchievementSystem.unlocked_achievements.erase("entropy_witness")
	AchievementSystem._check_reality_achievements(85)
	_assert_test(AchievementSystem.is_unlocked("reality_seeker"), "High reality unlocks reality_seeker")
	AchievementSystem.unlocked_achievements.erase("reality_seeker")
	AchievementSystem._check_reality_achievements(15)
	_assert_test(AchievementSystem.is_unlocked("reality_crisis"), "Low reality unlocks reality_crisis")
	AchievementSystem._check_positive_achievements(25)
	_assert_test(AchievementSystem.is_unlocked("positive_resistance"), "Low positive energy unlocks positive_resistance")
	AchievementSystem.unlocked_achievements.erase("positive_resistance")
	AchievementSystem._check_positive_achievements(95)
	_assert_test(AchievementSystem.is_unlocked("positive_victim"), "High positive energy unlocks positive_victim")
	AchievementSystem._check_entropy_achievements(105)
	_assert_test(AchievementSystem.is_unlocked("entropy_witness"), "High entropy unlocks entropy_witness")
func _test_skill_check_achievements() -> void:
	print("[Test] Skill check achievements...")
	AchievementSystem._progress_counters["logic_successes"] = 0
	AchievementSystem._progress_counters["perception_successes"] = 0
	AchievementSystem.unlocked_achievements.erase("logic_master")
	AchievementSystem.unlocked_achievements.erase("perception_expert")
	for i in range(10):
		AchievementSystem.check_skill_check_success("logic")
	_assert_test(AchievementSystem._progress_counters["logic_successes"] == 10, "Logic success counter reaches 10")
	_assert_test(AchievementSystem.is_unlocked("logic_master"), "Ten logic successes unlock logic_master")
	for i in range(10):
		AchievementSystem.check_skill_check_success("perception")
	_assert_test(AchievementSystem._progress_counters["perception_successes"] == 10, "Perception success counter reaches 10")
	_assert_test(AchievementSystem.is_unlocked("perception_expert"), "Ten perception successes unlock perception_expert")
func _test_dilemma_achievements() -> void:
	print("[Test] Dilemma achievements...")
	AchievementSystem._progress_counters["dilemmas_resolved"] = 0
	AchievementSystem.unlocked_achievements.erase("moral_philosopher")
	AchievementSystem.unlocked_achievements.erase("trolley_conductor")
	AchievementSystem.unlocked_achievements.erase("complicit")
	AchievementSystem.check_dilemma_resolved()
	_assert_test(AchievementSystem._progress_counters["dilemmas_resolved"] == 1, "First dilemma increments counter to 1")
	_assert_test(AchievementSystem.is_unlocked("moral_philosopher"), "First dilemma unlocks moral_philosopher")
	AchievementSystem._progress_counters["dilemmas_resolved"] = 4
	AchievementSystem.check_dilemma_resolved()
	_assert_test(AchievementSystem._progress_counters["dilemmas_resolved"] == 5, "Fifth dilemma increments counter to 5")
	_assert_test(AchievementSystem.is_unlocked("trolley_conductor"), "Fifth dilemma unlocks trolley_conductor")
	AchievementSystem._progress_counters["dilemmas_resolved"] = 9
	AchievementSystem.check_dilemma_resolved()
	_assert_test(AchievementSystem._progress_counters["dilemmas_resolved"] == 10, "Tenth dilemma increments counter to 10")
	_assert_test(AchievementSystem.is_unlocked("complicit"), "Tenth dilemma unlocks complicit")
func _test_signal_emission() -> void:
	print("[Test] Signal emission...")
	signal_received = false
	signal_achievement_id = ""
	if not AchievementSystem.achievement_unlocked.is_connected(_on_achievement_unlocked):
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementSystem.unlocked_achievements.erase("diary_keeper")
	AchievementSystem.unlock_achievement("diary_keeper")
	await get_tree().create_timer(0.05).timeout
	_assert_test(signal_received, "achievement_unlocked signal is emitted")
	_assert_test(signal_achievement_id == "diary_keeper", "achievement_unlocked emits the correct id")
	if AchievementSystem.achievement_unlocked.is_connected(_on_achievement_unlocked):
		AchievementSystem.achievement_unlocked.disconnect(_on_achievement_unlocked)
func _on_achievement_unlocked(achievement_id: String, _achievement_data: Dictionary) -> void:
	signal_received = true
	signal_achievement_id = achievement_id
func _test_save_load_persistence() -> void:
	print("[Test] Save/load persistence...")
	AchievementSystem.reset_achievements()
	AchievementSystem.unlock_achievement("first_mission")
	AchievementSystem.unlock_achievement("reality_seeker")
	AchievementSystem._progress_counters["missions_completed"] = 5
	AchievementSystem._progress_counters["journal_entries"] = 3
	AchievementSystem.save_achievements()
	await get_tree().create_timer(0.1).timeout
	var saved_achievements = AchievementSystem.unlocked_achievements.duplicate(true)
	var saved_progress = AchievementSystem._progress_counters.duplicate(true)
	AchievementSystem.unlocked_achievements.clear()
	AchievementSystem._progress_counters["missions_completed"] = 0
	AchievementSystem._progress_counters["journal_entries"] = 0
	AchievementSystem.load_achievements()
	await get_tree().create_timer(0.1).timeout
	_assert_test(AchievementSystem.is_unlocked("first_mission"), "Achievement save/load restores first_mission")
	_assert_test(AchievementSystem.is_unlocked("reality_seeker"), "Achievement save/load restores reality_seeker")
	_assert_test(AchievementSystem._progress_counters["missions_completed"] == saved_progress["missions_completed"], "Achievement save/load restores missions counter")
	_assert_test(AchievementSystem._progress_counters["journal_entries"] == saved_progress["journal_entries"], "Achievement save/load restores journal counter")
	_assert_test(AchievementSystem.unlocked_achievements == saved_achievements, "Achievement save/load preserves unlocked snapshot")
func _test_state_snapshot() -> void:
	print("[Test] State snapshot...")
	AchievementSystem.reset_achievements()
	AchievementSystem.unlock_achievement("survivor")
	AchievementSystem._progress_counters["missions_completed"] = 12
	var snapshot = AchievementSystem.get_state_snapshot()
	_assert_test(snapshot.has("unlocked"), "State snapshot includes unlocked achievements")
	_assert_test(snapshot.has("progress"), "State snapshot includes progress counters")
	_assert_test(snapshot["unlocked"].has("survivor"), "State snapshot includes survivor")
	_assert_test(snapshot["progress"]["missions_completed"] == 12, "State snapshot stores mission counter")
	AchievementSystem.reset_achievements()
	_assert_test(AchievementSystem.get_unlocked_count() == 0, "reset_achievements clears unlocked state")
	AchievementSystem.load_state_snapshot(snapshot)
	_assert_test(AchievementSystem.is_unlocked("survivor"), "load_state_snapshot restores survivor")
	_assert_test(AchievementSystem._progress_counters["missions_completed"] == 12, "load_state_snapshot restores mission counter")
func _test_achievement_queries() -> void:
	print("[Test] Achievement queries...")
	AchievementSystem.reset_achievements()
	AchievementSystem.unlock_achievement("first_mission")
	AchievementSystem.unlock_achievement("reality_seeker")
	AchievementSystem.unlock_achievement("survivor")
	_assert_test(AchievementSystem.get_unlocked_count() == 3, "get_unlocked_count returns the correct value")
	_assert_test(AchievementSystem.get_total_count() == AchievementSystem.ACHIEVEMENTS.size(), "get_total_count matches achievement definition count")
	var percentage = AchievementSystem.get_progress_percentage()
	var expected_percentage = (3.0 / AchievementSystem.ACHIEVEMENTS.size()) * 100.0
	_assert_test(abs(percentage - expected_percentage) < 0.1, "get_progress_percentage is correct")
	var achievement_list = AchievementSystem.get_achievement_list()
	_assert_test(achievement_list is Array, "get_achievement_list returns an Array")
	_assert_test(achievement_list.size() == AchievementSystem.ACHIEVEMENTS.size(), "get_achievement_list returns all achievements")
	var found_first_mission = false
	for achievement in achievement_list:
		_assert_test(achievement.has("id"), "Achievement query includes id")
		_assert_test(achievement.has("unlocked"), "Achievement query includes unlocked status")
		_assert_test(achievement.has("title"), "Achievement query includes title")
		if achievement["id"] == "first_mission":
			found_first_mission = true
			_assert_test(achievement["unlocked"] == true, "Achievement query marks first_mission unlocked")
			_assert_test(achievement.has("unlocked_at"), "Unlocked achievements expose unlocked_at")
	_assert_test(found_first_mission, "Achievement list contains first_mission")
func _test_reset_functionality() -> void:
	print("[Test] Reset functionality...")
	AchievementSystem.unlock_achievement("first_mission")
	AchievementSystem.unlock_achievement("survivor")
	AchievementSystem._progress_counters["missions_completed"] = 15
	AchievementSystem._progress_counters["journal_entries"] = 8
	_assert_test(AchievementSystem.get_unlocked_count() > 0, "Reset test begins with unlocked achievements")
	AchievementSystem.reset_achievements()
	_assert_test(AchievementSystem.get_unlocked_count() == 0, "reset_achievements clears unlocked achievements")
	_assert_test(AchievementSystem._progress_counters["missions_completed"] == 0, "reset_achievements clears mission counter")
	_assert_test(AchievementSystem._progress_counters["journal_entries"] == 0, "reset_achievements clears journal counter")
	_assert_test(AchievementSystem._progress_counters["gloria_triggers"] == 0, "reset_achievements clears gloria counter")
	_assert_test(AchievementSystem._progress_counters["prayers_made"] == 0, "reset_achievements clears prayer counter")
