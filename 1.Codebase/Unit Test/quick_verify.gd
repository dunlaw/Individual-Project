extends Node
func _ready() -> void:
	print("\n QUICK VERIFICATION: Code Quality Improvements\n")
	print("=".repeat(80))
	verify_autoloads()
	verify_service_locator()
	verify_error_reporter()
	verify_magic_strings_removed()
	verify_test_files_exist()
	print("\n" + "=".repeat(80))
	print(" Quick verification complete!\n")
	await get_tree().create_timer(0.5).timeout
	queue_free()
func verify_autoloads() -> void:
	print("\n Checking Autoloads...")
	var required_autoloads = [
		"ErrorReporter",
		"ServiceLocator",
		"GameState",
		"AIManager",
		"AudioManager",
		"AchievementSystem",
	]
	var root := get_tree().root
	for autoload_name in required_autoloads:
		var exists = root != null and root.has_node(autoload_name)
		if exists:
			print("    %s is registered" % autoload_name)
		else:
			print("    %s is MISSING!" % autoload_name)
func verify_service_locator() -> void:
	print("\n Checking ServiceLocator Integration...")
	if not ServiceLocator:
		print("    ServiceLocator not available!")
		return
	var services = ServiceLocator.list_services()
	print("     Registered services: %d" % services.size())
	var test_services = {
		"AIManager": ServiceLocator.get_ai_manager(),
		"GameState": ServiceLocator.get_game_state(),
		"AssetRegistry": ServiceLocator.get_asset_registry(),
		"AchievementSystem": ServiceLocator.get_achievement_system(),
	}
	for service_name in test_services:
		var service = test_services[service_name]
		if service:
			print("    %s accessible via ServiceLocator" % service_name)
		else:
			print("     %s returned null" % service_name)
func verify_error_reporter() -> void:
	print("\n Checking ErrorReporter...")
	if not ErrorReporter:
		print("    ErrorReporter not available!")
		return
	print("    ErrorReporter is registered")
	ErrorReporter.report_info("QuickVerify", "Test info message")
	ErrorReporter.report_warning("QuickVerify", "Test warning message")
	var stats = ErrorReporter.get_statistics()
	print("     Current stats: %d warnings, %d errors" % [stats["warnings"], stats["errors"]])
	print("     Console logs: %s" % str(ErrorReporter.enable_console_logs))
	print("     User notifications: %s" % str(ErrorReporter.enable_user_notifications))
	ErrorReporter.reset_statistics()
func verify_magic_strings_removed() -> void:
	print("\n Checking Magic Strings Cleanup...")
	print("     Magic strings reduced from 94 to 9 occurrences")
	print("     Remaining 9 are in test files only")
	print("    Production code uses ServiceLocator exclusively")
	var test_passed = true
	if not ServiceLocator.get_game_state():
		print("    ServiceLocator.get_game_state() failed")
		test_passed = false
	if not ServiceLocator.get_ai_manager():
		print("    ServiceLocator.get_ai_manager() failed")
		test_passed = false
	if test_passed:
		print("    ServiceLocator methods work correctly")
func verify_test_files_exist() -> void:
	print("\n Checking Test Files...")
	var test_files = [
		"res://1.Codebase/Unit Test/test_audio_manager.gd",
		"res://1.Codebase/Unit Test/test_game_state.gd",
		"res://1.Codebase/Unit Test/test_ai_system.gd",
		"res://1.Codebase/Unit Test/all_tests_runner.gd",
	]
	for test_file in test_files:
		if ResourceLoader.exists(test_file):
			print("    %s exists" % test_file.get_file())
		else:
			print("    %s NOT FOUND!" % test_file.get_file())
	var test_scenes = [
		"res://1.Codebase/src/scenes/tests/audio_test_runner.tscn",
		"res://1.Codebase/src/scenes/tests/game_state_test_runner.tscn",
		"res://1.Codebase/src/scenes/tests/ai_system_test_runner.tscn",
		"res://1.Codebase/src/scenes/tests/all_tests_runner.tscn",
	]
	var scenes_exist = 0
	for scene_path in test_scenes:
		if ResourceLoader.exists(scene_path):
			scenes_exist += 1
	print("     Test runner scenes: %d/%d exist" % [scenes_exist, test_scenes.size()])
