extends RefCounted
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "PhaseManagerModule"
signal phase_changed(old_phase: String, new_phase: String)
signal honeymoon_charge_consumed(remaining: int)
signal honeymoon_depleted()
var game_phase: String = GameConstants.GamePhase.HONEYMOON
var honeymoon_charges: int = 0
var _game_state: Variant = null
func set_game_state(gs: Variant) -> void:
	_game_state = gs
func is_honeymoon_phase() -> bool:
	return game_phase == GameConstants.GamePhase.HONEYMOON
func set_game_phase(phase: String) -> void:
	var old_phase = game_phase
	game_phase = phase
	_report_info("Phase transition: %s -> %s" % [old_phase.to_upper(), phase.to_upper()])
	phase_changed.emit(old_phase, phase)
func enter_honeymoon_phase() -> void:
	set_game_phase(GameConstants.GamePhase.HONEYMOON)
	honeymoon_charges = GameConstants.Honeymoon.INITIAL_CHARGES
	_report_info("Honeymoon phase entered. Charges: %d" % honeymoon_charges)
func exit_honeymoon_phase() -> void:
	set_game_phase(GameConstants.GamePhase.NORMAL)
	honeymoon_charges = GameConstants.Honeymoon.MIN_CHARGES
func consume_honeymoon_charge(reason: String = "") -> void:
	if game_phase != GameConstants.GamePhase.HONEYMOON:
		return
	if honeymoon_charges <= GameConstants.Honeymoon.MIN_CHARGES:
		return
	var old_charges = honeymoon_charges
	honeymoon_charges = max(GameConstants.Honeymoon.MIN_CHARGES, honeymoon_charges - 1)
	var reason_str := " (%s)" % reason if not reason.is_empty() else ""
	_report_info("Charge consumed: %d -> %d%s" % [old_charges, honeymoon_charges, reason_str])
	honeymoon_charge_consumed.emit(honeymoon_charges)
	if honeymoon_charges == GameConstants.Honeymoon.MIN_CHARGES:
		_report_info("All charges depleted! Teammates reveal their true nature...")
		honeymoon_depleted.emit()
		set_game_phase(GameConstants.GamePhase.NORMAL)
func check_phase_on_mission_start() -> void:
	if game_phase == GameConstants.GamePhase.HONEYMOON and honeymoon_charges <= GameConstants.Honeymoon.MIN_CHARGES:
		set_game_phase(GameConstants.GamePhase.NORMAL)
	elif game_phase != GameConstants.GamePhase.HONEYMOON:
		set_game_phase(GameConstants.GamePhase.NORMAL)
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func reset() -> void:
	game_phase = GameConstants.GamePhase.HONEYMOON
	honeymoon_charges = 0
func get_save_data() -> Dictionary:
	return {
		"game_phase": game_phase,
		"honeymoon_charges": honeymoon_charges,
	}
func load_save_data(data: Dictionary) -> void:
	game_phase = data.get("game_phase", GameConstants.GamePhase.HONEYMOON)
	honeymoon_charges = data.get("honeymoon_charges", 0)
