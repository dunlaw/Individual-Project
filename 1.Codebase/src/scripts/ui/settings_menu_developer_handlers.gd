extends RefCounted
class_name SettingsMenuDeveloperHandlers
const SettingsMenuDeveloperSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_developer_section.gd")
var _get_game_state_fn: Callable  
var _show_notification_fn: Callable  
var _play_sfx_fn: Callable  
var _report_info_fn: Callable  
var _reality_score_spinbox: SpinBox = null
var _positive_energy_spinbox: SpinBox = null
var _entropy_level_spinbox: SpinBox = null
var _honeymoon_charges_spinbox: SpinBox = null
var _mission_turn_spinbox: SpinBox = null
func setup(
	get_game_state_fn: Callable,
	show_notification_fn: Callable,
	play_sfx_fn: Callable,
	report_info_fn: Callable,
) -> void:
	_get_game_state_fn     = get_game_state_fn
	_show_notification_fn  = show_notification_fn
	_play_sfx_fn           = play_sfx_fn
	_report_info_fn        = report_info_fn
func set_node_refs(result: Dictionary) -> void:
	_reality_score_spinbox     = result.get("reality_score_spinbox")
	_positive_energy_spinbox   = result.get("positive_energy_spinbox")
	_entropy_level_spinbox     = result.get("entropy_level_spinbox")
	_honeymoon_charges_spinbox = result.get("honeymoon_charges_spinbox")
	_mission_turn_spinbox      = result.get("mission_turn_spinbox")
func _gs() -> Node:
	return _get_game_state_fn.call()
func _notify(msg: String, ok: bool = true) -> void:
	_show_notification_fn.call(msg, ok)
func _sfx(name: String) -> void:
	_play_sfx_fn.call(name)
func _on_force_mission_complete_toggled(toggled: bool) -> void:
	var gs := _gs()
	if gs:
		gs.debug_force_mission_complete = toggled
func _on_reality_score_changed(value: float) -> void:
	var gs := _gs()
	if gs:
		gs.reality_score = int(value)
func _on_positive_energy_changed(value: float) -> void:
	var gs := _gs()
	if gs:
		gs.positive_energy = int(value)
func _on_entropy_level_changed(value: float) -> void:
	var gs := _gs()
	if gs:
		gs.entropy_level = int(value)
func _on_honeymoon_charges_changed(value: float) -> void:
	var gs := _gs()
	if gs:
		gs.honeymoon_charges = int(value)
func _on_mission_turn_changed(value: float) -> void:
	var gs := _gs()
	if gs:
		gs.mission_turn_count = int(value)
func _on_max_stats_pressed() -> void:
	_sfx("menu_click")
	SettingsMenuDeveloperSectionScript.on_max_stats(_gs(), {
		"reality":        _reality_score_spinbox,
		"positive_energy": _positive_energy_spinbox,
		"entropy":        _entropy_level_spinbox,
		"honeymoon":      _honeymoon_charges_spinbox,
	}, _show_notification_fn)
func _on_reset_stats_pressed() -> void:
	_sfx("menu_click")
	SettingsMenuDeveloperSectionScript.on_reset_stats(_gs(), {
		"reality":        _reality_score_spinbox,
		"positive_energy": _positive_energy_spinbox,
		"entropy":        _entropy_level_spinbox,
		"honeymoon":      _honeymoon_charges_spinbox,
		"mission_turn":   _mission_turn_spinbox,
	}, _show_notification_fn)
func _on_clear_debuffs_pressed() -> void:
	_sfx("menu_click")
	var gs := _gs()
	if gs:
		if gs.has_method("clear_all_debuffs") and gs.clear_all_debuffs():
			_notify("All debuffs cleared!", true)
		else:
			_notify("Debuff system not available", false)
	else:
		_notify("GameState not available", false)
func _on_add_honeymoon_pressed() -> void:
	_sfx("menu_click")
	var gs := _gs()
	if gs:
		gs.honeymoon_charges = min(10, gs.honeymoon_charges + 5)
		if _honeymoon_charges_spinbox:
			_honeymoon_charges_spinbox.value = gs.honeymoon_charges
		_notify("Added 5 honeymoon charges!", true)
func _on_autosave_toggled(toggled: bool) -> void:
	_sfx("menu_click")
	var gs := _gs()
	if gs:
		gs.autosave_enabled = toggled
		_notify("Autosave enabled" if toggled else "Autosave disabled", true)
func _on_infinite_resources_toggled(toggled: bool) -> void:
	_sfx("menu_click")
	var gs := _gs()
	if gs:
		gs.set_metadata("debug_infinite_resources", toggled)
		_notify("Infinite resources enabled" if toggled else "Infinite resources disabled", true)
func _on_skip_dialogue_toggled(toggled: bool) -> void:
	_sfx("menu_click")
	var gs := _gs()
	if gs:
		gs.settings["auto_advance_enabled"] = toggled
		_notify("Auto-advance dialogue enabled" if toggled else "Auto-advance dialogue disabled", true)
func _on_god_mode_toggled(toggled: bool) -> void:
	_sfx("menu_click")
	var gs := _gs()
	if gs:
		gs.set_metadata("debug_god_mode", toggled)
		_notify("God mode enabled" if toggled else "God mode disabled", true)
func _on_fsm_jump_to_day_pressed(target_day_id: int, status_label: Label) -> void:
	_sfx("menu_click")
	SettingsMenuDeveloperSectionScript.on_fsm_jump_to_day(
		target_day_id, status_label, _gs(), _show_notification_fn, _report_info_fn)
func _on_fsm_reset_pressed(status_label: Label) -> void:
	_sfx("menu_click")
	SettingsMenuDeveloperSectionScript.on_fsm_reset(
		status_label, _gs(), _show_notification_fn, _report_info_fn)
