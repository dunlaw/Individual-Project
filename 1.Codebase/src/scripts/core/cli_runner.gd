extends Node
const ERROR_CONTEXT := "CLIRunner"
var _parser: CLICommandParser
var _ai_commands: CLIAICommands
var _game_commands: CLIGameCommands
var _save_commands: CLISaveCommands
func _ready() -> void:
	_parser = CLICommandParser.new(self)
	_game_commands = CLIGameCommands.new(_parser)
	_ai_commands = CLIAICommands.new(_parser)
	_save_commands = CLISaveCommands.new(_parser, _game_commands)
	if not _is_cli_mode_requested():
		return
	var args := _get_cli_args()
	if _parser.has_flag(args, "--cli-silent"):
		_apply_silent_mode()
	call_deferred("_run_cli_mode")
func _is_cli_mode_requested() -> bool:
	var args := _get_cli_args()
	if args.is_empty():
		return false
	return _parser.has_flag(args, "--cli") \
		or _parser.has_flag(args, "--cli-help") \
		or not _parser.get_option(args, "--cli-command").is_empty()
func _run_cli_mode() -> void:
	var args := _get_cli_args()
	var command := _parser.parse_command(args)
	var json_output := _parser.has_flag(args, "--json") \
		or _parser.get_option(args, "--cli-output").to_lower() == "json"
	if command.is_empty() or command == "help":
		_parser.output_help(json_output)
		_quit_tree(0)
		return
	var exit_code := _execute_command(command, args, json_output)
	_quit_tree(exit_code)
func _execute_command(command: String, args: Array[String], json_output: bool) -> int:
	var game_state := _parser.get_game_state()
	match command:
		"status":
			return _game_commands.handle_status(game_state, json_output)
		"autosave":
			return _game_commands.handle_game_state_bool_command(game_state, "autosave", "autosave", json_output)
		"save":
			return _save_commands.handle_save(game_state, args, json_output)
		"load":
			return _save_commands.handle_load(game_state, args, json_output)
		"new-game":
			return _game_commands.handle_new_game(game_state, json_output)
		"scenario":
			return _game_commands.handle_scenario(args, json_output)
		"scenario-list":
			return _game_commands.handle_scenario_list(json_output)
		"save-info":
			return _save_commands.handle_save_info(game_state, args, json_output)
		"delete-save":
			return _save_commands.handle_delete_save(game_state, args, json_output)
		"events":
			return _game_commands.handle_events(game_state, args, json_output)
		"ai-status":
			return _ai_commands.handle_ai_status(args, json_output)
		"provider-list":
			return _ai_commands.handle_provider_list(json_output)
		"set-provider":
			return _ai_commands.handle_set_provider(args, json_output)
		"set-language":
			return _game_commands.handle_set_language(game_state, args, json_output)
		"set-api-key":
			return _ai_commands.handle_set_api_key(args, json_output)
		"ai-usage":
			return _ai_commands.handle_ai_usage(args, json_output)
		"prayer":
			return _game_commands.handle_prayer(game_state, args, json_output)
		"journal":
			return _game_commands.handle_journal_entry(game_state, args, json_output)
		"journal-list":
			return _game_commands.handle_journal_list(game_state, args, json_output)
		"credits":
			return _game_commands.handle_credits(args, json_output)
		"story-pages":
			return _game_commands.handle_story_pages(args, json_output)
		"special-scenes":
			return _game_commands.handle_special_scenes(game_state, args, json_output)
		"check-rage":
			return _game_commands.handle_check_rage(game_state, json_output)
		_:
			_parser.output_payload(
				{
					"ok": false,
					"command": command,
					"error": "Unknown CLI command: %s" % command,
					"supported_commands": CLICommandParser.SUPPORTED_COMMANDS,
				},
				json_output,
			)
			return 2
func _quit_tree(exit_code: int) -> void:
	get_tree().quit(exit_code)
func _apply_silent_mode() -> void:
	Engine.print_error_messages = false
	var reporter := _parser.get_error_reporter()
	if reporter != null:
		if reporter.has_method("set"):
			reporter.set("enable_console_logs", false)
			reporter.set("enable_user_notifications", false)
func _get_cli_args() -> Array[String]:
	var user_args := OS.get_cmdline_user_args()
	var args: Array[String] = []
	if not user_args.is_empty():
		for value in user_args:
			args.append(String(value))
		return args
	var full_args := OS.get_cmdline_args()
	for value in full_args:
		args.append(String(value))
	return args
func _canonical_command(raw_command: String) -> String:
	return _parser.canonical_command(raw_command)
func _resolve_slot_option(args: Array[String], command_name: String, json_output: bool, allow_missing: bool) -> Dictionary:
	return _parser.resolve_slot_option(args, command_name, json_output, allow_missing)
func _resolve_limit_option(args: Array[String], command_name: String, json_output: bool) -> Dictionary:
	return _parser.resolve_limit_option(args, command_name, json_output)
func _normalize_language(raw_language: String) -> String:
	return _parser.normalize_language(raw_language)
func _normalize_provider(raw_provider: String) -> String:
	return _parser.normalize_provider(raw_provider)
func _normalize_api_key_provider(raw_provider: String) -> String:
	return _parser.normalize_api_key_provider(raw_provider)
func _get_scenario_ids() -> Array[String]:
	return _parser.get_scenario_ids()
func _find_scenario_by_id(scenario_id: String) -> Dictionary:
	return _parser.find_scenario_by_id(scenario_id)
func _get_current_provider(ai_manager: Node) -> String:
	return _parser.get_current_provider(ai_manager)
