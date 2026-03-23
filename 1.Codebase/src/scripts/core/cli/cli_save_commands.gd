class_name CLISaveCommands
extends RefCounted
var _parser: CLICommandParser
var _game_commands: CLIGameCommands
func _init(parser: CLICommandParser, game_commands: CLIGameCommands) -> void:
	_parser = parser
	_game_commands = game_commands
func handle_save(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "save"):
		return 1
	var slot_result := _parser.resolve_slot_option(args, "save", json_output, true)
	if not bool(slot_result.get("ok", false)):
		return 2
	var slot_provided := bool(slot_result.get("provided", false))
	var slot := int(slot_result.get("slot", -1))
	if slot_provided and game_state.has_method("save_game_to_slot"):
		var save_success := bool(game_state.call("save_game_to_slot", slot))
		return _emit_save_load_result(save_success, "save", json_output, slot)
	return _game_commands.handle_game_state_bool_command(game_state, "save_game", "save", json_output)
func handle_load(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "load"):
		return 1
	var slot_result := _parser.resolve_slot_option(args, "load", json_output, true)
	if not bool(slot_result.get("ok", false)):
		return 2
	var slot_provided := bool(slot_result.get("provided", false))
	var slot := int(slot_result.get("slot", -1))
	if slot_provided and game_state.has_method("load_game_from_slot"):
		var load_success := bool(game_state.call("load_game_from_slot", slot))
		return _emit_save_load_result(load_success, "load", json_output, slot)
	return _game_commands.handle_game_state_bool_command(game_state, "load_game", "load", json_output)
func _emit_save_load_result(success: bool, command_name: String, json_output: bool, slot: int) -> int:
	_parser.output_payload(
		{
			"ok": success,
			"command": command_name,
			"slot": slot,
		},
		json_output,
	)
	return 0 if success else 1
func handle_save_info(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "save-info"):
		return 1
	var include_autosave_only := _parser.has_flag(args, "--autosave")
	var slot_result := _parser.resolve_slot_option(args, "save-info", json_output, true)
	if not bool(slot_result.get("ok", false)):
		return 2
	var slot_provided := bool(slot_result.get("provided", false))
	var slot := int(slot_result.get("slot", -1))
	if include_autosave_only and slot_provided:
		_parser.output_payload(
			{
				"ok": false,
				"command": "save-info",
				"error": "Use only one target: --autosave or --slot=<n>",
			},
			json_output,
		)
		return 2
	if include_autosave_only:
		if not game_state.has_method("get_autosave_info"):
			_parser.output_payload(
				{
					"ok": false,
					"command": "save-info",
					"error": "GameState missing method: get_autosave_info",
				},
				json_output,
			)
			return 2
		_parser.output_payload(
			{
				"ok": true,
				"command": "save-info",
				"target": "autosave",
				"info": game_state.get_autosave_info(),
			},
			json_output,
		)
		return 0
	if slot_provided:
		if not game_state.has_method("get_save_slot_info"):
			_parser.output_payload(
				{
					"ok": false,
					"command": "save-info",
					"error": "GameState missing method: get_save_slot_info",
				},
				json_output,
			)
			return 2
		_parser.output_payload(
			{
				"ok": true,
				"command": "save-info",
				"target": "slot",
				"slot": slot,
				"info": game_state.get_save_slot_info(slot),
			},
			json_output,
		)
		return 0
	var max_slots := _parser.get_max_save_slots()
	var slots: Array[Dictionary] = []
	if game_state.has_method("get_save_slot_info"):
		for index in range(1, max_slots + 1):
			var info: Dictionary = game_state.get_save_slot_info(index)
			var normalized: Dictionary = info.duplicate(true)
			normalized["slot"] = index
			slots.append(normalized)
	var payload := {
		"ok": true,
		"command": "save-info",
		"target": "all",
		"max_slots": max_slots,
		"current_slot": int(game_state.get("current_save_slot") if game_state.has_method("get") else 1),
		"latest": game_state.get_latest_save_info() if game_state.has_method("get_latest_save_info") else { "exists": false },
		"autosave": game_state.get_autosave_info() if game_state.has_method("get_autosave_info") else { "exists": false },
		"slots": slots,
	}
	_parser.output_payload(payload, json_output)
	return 0
func handle_delete_save(game_state: Node, args: Array[String], json_output: bool) -> int:
	if not _parser.ensure_game_state(game_state, json_output, "delete-save"):
		return 1
	var wants_autosave := _parser.has_flag(args, "--autosave")
	var slot_result := _parser.resolve_slot_option(args, "delete-save", json_output, true)
	if not bool(slot_result.get("ok", false)):
		return 2
	var slot_provided := bool(slot_result.get("provided", false))
	var slot := int(slot_result.get("slot", -1))
	if wants_autosave == slot_provided:
		_parser.output_payload(
			{
				"ok": false,
				"command": "delete-save",
				"error": "Specify exactly one target: --autosave or --slot=<n>",
			},
			json_output,
		)
		return 2
	if wants_autosave:
		if not game_state.has_method("delete_autosave"):
			_parser.output_payload(
				{
					"ok": false,
					"command": "delete-save",
					"error": "GameState missing method: delete_autosave",
				},
				json_output,
			)
			return 2
		var autosave_deleted := bool(game_state.delete_autosave())
		_parser.output_payload(
			{
				"ok": autosave_deleted,
				"command": "delete-save",
				"target": "autosave",
			},
			json_output,
		)
		return 0 if autosave_deleted else 1
	if not game_state.has_method("delete_save_slot"):
		_parser.output_payload(
			{
				"ok": false,
				"command": "delete-save",
				"error": "GameState missing method: delete_save_slot",
			},
			json_output,
		)
		return 2
	var slot_deleted := bool(game_state.call("delete_save_slot", slot))
	_parser.output_payload(
		{
			"ok": slot_deleted,
			"command": "delete-save",
			"target": "slot",
			"slot": slot,
		},
		json_output,
	)
	return 0 if slot_deleted else 1
