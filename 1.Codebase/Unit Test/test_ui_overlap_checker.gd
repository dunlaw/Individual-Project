extends Node
const SCENES_TO_CHECK: Array[String] = [
	"res://1.Codebase/src/scenes/ui/start_menu.tscn",
	"res://1.Codebase/src/scenes/ui/pause_menu.tscn",
	"res://1.Codebase/src/scenes/ui/settings_menu.tscn",
	"res://1.Codebase/src/scenes/ui/save_load_menu.tscn",
	"res://1.Codebase/src/scenes/ui/notification_popup.tscn",
	"res://1.Codebase/src/scenes/ui/notification_system.tscn",
	"res://1.Codebase/src/scenes/ui/achievement_viewer.tscn",
	"res://1.Codebase/src/scenes/ui/asset_viewer.tscn",
	"res://1.Codebase/src/scenes/ui/journal_system.tscn",
	"res://1.Codebase/src/scenes/ui/gameplay_stats_viewer.tscn",
	"res://1.Codebase/src/scenes/ui/loading_screen.tscn",
	"res://1.Codebase/src/scenes/ui/intro_page.tscn",
	"res://1.Codebase/src/scenes/ui/terms_page.tscn",
	"res://1.Codebase/src/scenes/ui/creative_statement.tscn",
	"res://1.Codebase/src/scenes/ui/choice_selection_overlay.tscn",
	"res://1.Codebase/src/scenes/ui/tutorial_popup.tscn",
	"res://1.Codebase/src/scenes/ui/butterfly_effect_panel.tscn",
	"res://1.Codebase/src/scenes/ui/prayer_notice.tscn",
]
var _pass_count: int = 0
var _fail_count: int = 0
func _ready() -> void:
	print("=".repeat(60))
	print("UI OVERLAP & TEXTURE CHECKER")
	print("=".repeat(60))
	await get_tree().process_frame
	await _run_checks()
	_print_summary()
	queue_free()
func _run_checks() -> void:
	var overlay_script: GDScript = preload("res://1.Codebase/src/scripts/core/ui_debug_overlay.gd")
	for scene_path in SCENES_TO_CHECK:
		var packed: PackedScene = load(scene_path)
		if packed == null:
			print("[SKIP] Cannot load: %s" % scene_path)
			continue
		var instance: Node = packed.instantiate()
		add_child(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		var checker: CanvasLayer = overlay_script.new()
		add_child(checker)
		var result: Dictionary = checker.run_headless_check(instance)
		checker.queue_free()
		# Process result while instance is still alive (result holds node references)
		var scene_name := scene_path.get_file()
		var overlaps: Array = result.get("overlapping_pairs", [])
		var missing: Array = result.get("missing_textures", [])
		var has_issues := overlaps.size() > 0 or missing.size() > 0
		if has_issues:
			_fail_count += 1
			print("[FAIL] %s" % scene_name)
			if overlaps.size() > 0:
				var _overlap_count_lbl = LocalizationManager.get_translation("TEST_UI_OVERLAP_COUNT_ZH", "zh") if LocalizationManager else "Overlap Count"
				print("  %s: %d" % [_overlap_count_lbl, overlaps.size()])
				var _overlap_lbl = LocalizationManager.get_translation("TEST_UI_OVERLAP_LABEL_ZH", "zh") if LocalizationManager else "Overlap"
				for pair in overlaps:
					print("    %s: %s  <->  %s" % [
						_overlap_lbl,
						pair[0].get_path(),
						pair[1].get_path(),
					])
			if missing.size() > 0:
				var _missing_count_lbl = LocalizationManager.get_translation("TEST_UI_MISSING_TEXTURE_COUNT_ZH", "zh") if LocalizationManager else "Missing Texture Nodes"
				print("  %s: %d" % [_missing_count_lbl, missing.size()])
				var _missing_lbl = LocalizationManager.get_translation("TEST_UI_MISSING_TEXTURE_LABEL_ZH", "zh") if LocalizationManager else "Missing Texture"
				for ctrl in missing:
					print("    %s: %s" % [_missing_lbl, (ctrl as Node).get_path()])
		else:
			_pass_count += 1
			var _ctrl_lbl = LocalizationManager.get_translation("TEST_UI_CONTROL_COUNT_LABEL_ZH", "zh") if LocalizationManager else "Controls"
			print("[PASS] %s  (%s: %d)" % [scene_name, _ctrl_lbl, result.get("control_count", 0)])
		# Free instance only after result processing is complete
		instance.queue_free()
		await get_tree().process_frame
func _print_summary() -> void:
	print("=".repeat(60))
	print("Results: Pass %d / Fail %d / Total %d scenes" % [
		_pass_count,
		_fail_count,
		_pass_count + _fail_count,
	])
	if _fail_count > 0:
		print(LocalizationManager.get_translation("TEST_UI_CHECK_ISSUES_ZH", "zh") if LocalizationManager else "Please check [FAIL] scenes above for overlap and missing texture issues.")
	else:
		print(LocalizationManager.get_translation("TEST_UI_ALL_PASS_ZH", "zh") if LocalizationManager else "All scenes passed!")
	print("=".repeat(60))
