extends CanvasLayer
const UIConstants = preload("res://1.Codebase/src/scripts/ui/ui_constants.gd")
const NOTIFICATION_DURATION = UIConstants.NOTIFICATION_DURATION_NORMAL
const FADE_DURATION = UIConstants.FADE_OUT_DURATION
var notification_scene = preload("res://1.Codebase/src/scenes/ui/notification_popup.tscn")
var active_notifications: Array = []
var notification_queue: Array = []
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
func show_notification(message: String, notification_type: String = "info", description: String = "") -> void:
	var normalized_type: String = notification_type.strip_edges().to_lower()
	match normalized_type:
		"error":
			show_error(message, description)
		"warning":
			show_warning(message, description)
		"success":
			show_success(message, description)
		"achievement":
			show_achievement(message, description)
		"info", "tutorial", "":
			show_info(message, description)
		_:
			show_info(message, description)
func show_error(title: String, description: String = ""):
	_add_notification(title, description, UIConstants.COLOR_ERROR)
func show_warning(title: String, description: String = ""):
	_add_notification(title, description, UIConstants.COLOR_WARNING)
func show_info(title: String, description: String = ""):
	_add_notification(title, description, UIConstants.COLOR_ACCENT_BLUE)
func show_success(title: String, description: String = ""):
	_add_notification(title, description, UIConstants.COLOR_SUCCESS)
func show_achievement(title: String, description: String = "", icon_path: String = "", header: String = ""):
	_add_notification(title, description, UIConstants.COLOR_SUCCESS, icon_path, header)
func _add_notification(title: String, description: String, color: Color, icon_path: String = "", header: String = ""):
	var notification = notification_scene.instantiate()
	add_child(notification)
	var target_y = 60 + (active_notifications.size() * 90)
	var start_pos = Vector2(-300, target_y)
	var end_pos = Vector2(20, target_y)
	notification.position = start_pos
	notification.modulate.a = 0.0
	notification.setup(title, description, color, NOTIFICATION_DURATION, icon_path, header)
	active_notifications.append(notification)
	var tween = notification.create_tween()
	tween.set_parallel(true)
	tween.tween_property(notification, "position", end_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	notification.tree_exited.connect(_on_notification_removed.bind(notification))
	await get_tree().create_timer(NOTIFICATION_DURATION).timeout
	if is_instance_valid(notification):
		_dismiss_notification(notification)
func _dismiss_notification(notification: Control):
	if notification in active_notifications:
		var tween = create_tween()
		tween.tween_property(notification, "modulate:a", 0.0, FADE_DURATION)
		await tween.finished
		if is_instance_valid(notification):
			notification.queue_free()
func _on_notification_removed(notification: Control):
	if notification in active_notifications:
		active_notifications.erase(notification)
	for i in range(active_notifications.size()):
		var notif = active_notifications[i]
		if is_instance_valid(notif):
			var tween = create_tween()
			tween.tween_property(notif, "position:y", 60 + (i * 90), 0.3)
func clear_all():
	for notif in active_notifications:
		if is_instance_valid(notif):
			notif.queue_free()
	active_notifications.clear()
	notification_queue.clear()
