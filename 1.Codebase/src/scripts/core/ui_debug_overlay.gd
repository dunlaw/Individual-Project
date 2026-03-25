extends CanvasLayer
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "UIDebugOverlay"
const OVERLAY_COLOR_NORMAL := Color(0.0, 1.0, 0.0, 0.5)
const OVERLAY_COLOR_OVERLAP := Color(1.0, 0.0, 0.0, 0.7)
const OVERLAY_COLOR_MISSING_TEX := Color(1.0, 0.5, 0.0, 0.8)
const INFO_PANEL_BG := Color(0.0, 0.0, 0.0, 0.75)
var _visible_overlay: bool = false
var _draw_node: Node2D
var _info_label: Label
var _controls: Array[Control] = []
var _overlapping_pairs: Array = []
var _missing_texture_nodes: Array[Control] = []
func _loc(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	layer = 100
	_draw_node = Node2D.new()
	_draw_node.name = "DrawNode"
	_draw_node.z_index = 100
	_draw_node.draw.connect(_on_draw)
	add_child(_draw_node)
	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.position = Vector2(8.0, 8.0)
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", Color.WHITE)
	_info_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_info_label.add_theme_constant_override("shadow_offset_x", 1)
	_info_label.add_theme_constant_override("shadow_offset_y", 1)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_info_label)
	_set_overlay_visible(false)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9:
			_toggle_overlay()
		elif event.keycode == KEY_F10:
			_print_report()
func _toggle_overlay() -> void:
	_set_overlay_visible(not _visible_overlay)
func _set_overlay_visible(value: bool) -> void:
	_visible_overlay = value
	_draw_node.visible = value
	_info_label.visible = value
	if value:
		_refresh()
func _refresh() -> void:
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	_controls = []
	_collect_controls(root, _controls)
	_overlapping_pairs = _detect_overlaps(_controls)
	_missing_texture_nodes = _check_missing_textures(_controls)
	_draw_node.queue_redraw()
	_update_info_label()
func _collect_controls(node: Node, result: Array[Control]) -> void:
	if node is Control:
		var ctrl := node as Control
		if ctrl.visible and ctrl.get_global_rect().size != Vector2.ZERO:
			result.append(ctrl)
	for child in node.get_children():
		_collect_controls(child, result)
func _detect_overlaps(controls: Array[Control]) -> Array:
	var pairs := []
	for i in range(controls.size()):
		for j in range(i + 1, controls.size()):
			var a := controls[i]
			var b := controls[j]
			# Skip background/decorative nodes that intentionally pass through mouse input
			if a.mouse_filter == Control.MOUSE_FILTER_IGNORE or b.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				continue
			if _are_ancestor_related(a, b):
				continue
			var rect_a := a.get_global_rect()
			var rect_b := b.get_global_rect()
			if rect_a.intersects(rect_b):
				pairs.append([a, b])
	return pairs
func _are_ancestor_related(a: Node, b: Node) -> bool:
	var node := a.get_parent()
	while node != null:
		if node == b:
			return true
		node = node.get_parent()
	node = b.get_parent()
	while node != null:
		if node == a:
			return true
		node = node.get_parent()
	return false
func _check_missing_textures(controls: Array[Control]) -> Array[Control]:
	var missing: Array[Control] = []
	for ctrl in controls:
		if ctrl is TextureRect:
			var tr := ctrl as TextureRect
			if tr.texture == null:
				missing.append(ctrl)
	return missing
func _on_draw() -> void:
	if not _visible_overlay:
		return
	var overlapping_nodes: Array[Control] = []
	for pair in _overlapping_pairs:
		for node in pair:
			if node not in overlapping_nodes:
				overlapping_nodes.append(node)
	for ctrl in _controls:
		var rect := ctrl.get_global_rect()
		var color: Color
		if ctrl in _missing_texture_nodes:
			color = OVERLAY_COLOR_MISSING_TEX
		elif ctrl in overlapping_nodes:
			color = OVERLAY_COLOR_OVERLAP
		else:
			color = OVERLAY_COLOR_NORMAL
		_draw_node.draw_rect(rect, color, false, 2.0)
		var label_pos := rect.position + Vector2(2.0, 2.0)
		_draw_node.draw_string(
			ThemeDB.fallback_font,
			label_pos,
			ctrl.name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			11,
			color
		)
func _update_info_label() -> void:
	var lines: Array[String] = []
	lines.append(_loc("DEBUG_OVERLAY_TITLE"))
	lines.append(_loc("DEBUG_OVERLAY_CONTROL_COUNT") % _controls.size())
	lines.append(_loc("DEBUG_OVERLAY_OVERLAP_COUNT") % _overlapping_pairs.size())
	lines.append(_loc("DEBUG_OVERLAY_MISSING_TEX_COUNT") % _missing_texture_nodes.size())
	if _overlapping_pairs.size() > 0:
		lines.append("")
		lines.append(_loc("DEBUG_OVERLAY_OVERLAP_HEADER"))
		for pair in _overlapping_pairs:
			lines.append(_loc("DEBUG_OVERLAY_OVERLAP_ITEM") % [pair[0].get_path(), pair[1].get_path()])
	if _missing_texture_nodes.size() > 0:
		lines.append("")
		lines.append(_loc("DEBUG_OVERLAY_MISSING_TEX_HEADER"))
		for ctrl in _missing_texture_nodes:
			lines.append(_loc("DEBUG_OVERLAY_MISSING_TEX_ITEM") % ctrl.get_path())
	_info_label.text = "\n".join(lines)
func _print_report() -> void:
	_refresh()
	var report_lines: Array[String] = []
	report_lines.append("=".repeat(60))
	report_lines.append(_loc("DEBUG_OVERLAY_REPORT_SCENE") % (get_tree().current_scene.name if get_tree().current_scene != null else "N/A"))
	report_lines.append(_loc("DEBUG_OVERLAY_CONTROL_COUNT") % _controls.size())
	report_lines.append(_loc("DEBUG_OVERLAY_OVERLAP_COUNT") % _overlapping_pairs.size())
	report_lines.append(_loc("DEBUG_OVERLAY_MISSING_TEX_COUNT") % _missing_texture_nodes.size())
	if _overlapping_pairs.size() > 0:
		report_lines.append(_loc("DEBUG_OVERLAY_OVERLAP_REPORT_HEADER"))
		for pair in _overlapping_pairs:
			report_lines.append("  %s  <->  %s" % [pair[0].get_path(), pair[1].get_path()])
	if _missing_texture_nodes.size() > 0:
		report_lines.append(_loc("DEBUG_OVERLAY_MISSING_TEX_REPORT_HEADER"))
		for ctrl in _missing_texture_nodes:
			report_lines.append("  %s" % ctrl.get_path())
	report_lines.append("=".repeat(60))
	_report_info("\n".join(report_lines))
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func run_headless_check(root_node: Node) -> Dictionary:
	var controls: Array[Control] = []
	_collect_controls(root_node, controls)
	var overlaps := _detect_overlaps(controls)
	var missing := _check_missing_textures(controls)
	return {
		"control_count": controls.size(),
		"overlapping_pairs": overlaps,
		"missing_textures": missing,
	}
