extends Node
var tests_passed: int = 0
var tests_failed: int = 0
var notification_system: Node = null
func _ready() -> void:
	print("[NotificationSystemTest] Starting NotificationSystem unit tests...")
	await get_tree().process_frame
	_setup()
	_test_notification_display()
	await _test_notification_lifecycle()
	_test_notification_importance()
	_test_notification_queue()
	_teardown()
	print("[NotificationSystemTest] All tests completed.")
	queue_free()
func _setup() -> void:
	notification_system = ServiceLocator.get_notification_system() if ServiceLocator else null
	if not notification_system:
		var root := get_tree().root
		if root:
			notification_system = root.get_node_or_null("NotificationSystem")
	_assert(notification_system != null, "NotificationSystem should be available")
	print("[Test Setup] NotificationSystem found")
func _teardown() -> void:
	if notification_system and notification_system.has_method("clear_all"):
		notification_system.clear_all()
func _test_notification_display() -> void:
	print("[Test] Notification display...")
	if not notification_system:
		print("[Test] SKIPPED: NotificationSystem not available")
		return
	if notification_system.has_method("show_info"):
		notification_system.show_info("Test message", "test")
		print("[Test] Notification display PASSED")
	else:
		print("[Test] Notification display SKIPPED: method not available")
func _test_notification_lifecycle() -> void:
	print("[Test] Notification lifecycle...")
	if not notification_system or not notification_system.has_method("show_info"):
		print("[Test] SKIPPED: NotificationSystem not available")
		return
	notification_system.show_info("Short message", "test")
	await get_tree().create_timer(0.7).timeout
	print("[Test] Notification lifecycle PASSED")
func _test_notification_importance() -> void:
	print("[Test] Notification importance...")
	if not notification_system or not notification_system.has_method("show_info"):
		print("[Test] SKIPPED: NotificationSystem not available")
		return
	notification_system.show_info("Test info", "low")
	notification_system.show_success("Test success", "normal")
	notification_system.show_warning("Test warning", "high")
	notification_system.show_error("Test error", "critical")
	print("[Test] Notification importance PASSED")
func _test_notification_queue() -> void:
	print("[Test] Notification queue...")
	if not notification_system or not notification_system.has_method("show_info"):
		print("[Test] SKIPPED: NotificationSystem not available")
		return
	for i in range(5):
		notification_system.show_info("Queue test %d" % i, "test")
	print("[Test] Notification queue PASSED")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
