extends Node
@export var scene_to_inspect: String = "res://1.Codebase/src/scenes/ui/start_menu.tscn"
@export var headless_report: bool = false
const OverlayScene := preload("res://1.Codebase/src/scenes/tests/ui_debug_overlay.tscn")
func _ready() -> void:
	print("[UIInspector] Loading scene: ", scene_to_inspect)
	if scene_to_inspect.is_empty():
		print("[UIInspector] ERROR: scene_to_inspect is empty. Set it in the Inspector.")
		if headless_report:
			get_tree().quit()
		return
	var packed: PackedScene = load(scene_to_inspect)
	if packed == null:
		print("[UIInspector] ERROR: Cannot load scene: ", scene_to_inspect)
		if headless_report:
			get_tree().quit()
		return
	var scene_instance: Node = packed.instantiate()
	add_child(scene_instance)
	print("[UIInspector] Scene loaded: ", scene_instance.name)
	var overlay: CanvasLayer = OverlayScene.instantiate()
	add_child(overlay)
	if headless_report:
		await get_tree().process_frame
		await get_tree().process_frame
		overlay._print_report()
		await get_tree().create_timer(0.3).timeout
		get_tree().quit()
	else:
		await get_tree().process_frame
		overlay._set_overlay_visible(true)
		print("[UIInspector] Overlay active. F9=Toggle Display  F10=Print Report to Output")
