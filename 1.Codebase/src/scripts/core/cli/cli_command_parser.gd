class_name CLICommandParser
extends RefCounted
const MissionScenarioLibraryScript = preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
const SaveLoadSystemScript = preload("res://1.Codebase/src/scripts/core/save_load_system.gd")
const AIConfigManagerScript = preload("res://1.Codebase/src/scripts/core/ai/managers/ai_config_manager.gd")
const CreditsContent = preload("res://1.Codebase/src/scripts/core/credits_content.gd")
const DEFAULT_EVENT_LIMIT := 6
const MAX_EVENT_LIMIT := 100
const PROVIDER_ENUMS := {
	"gemini": AIConfigManagerScript.AIProvider.GEMINI,
	"openrouter": AIConfigManagerScript.AIProvider.OPENROUTER,
	"ollama": AIConfigManagerScript.AIProvider.OLLAMA,
	"openai": AIConfigManagerScript.AIProvider.OPENAI,
	"claude": AIConfigManagerScript.AIProvider.CLAUDE,
	"lmstudio": AIConfigManagerScript.AIProvider.LMSTUDIO,
	"ai-router": AIConfigManagerScript.AIProvider.AI_ROUTER,
	"mock": AIConfigManagerScript.AIProvider.MOCK_MODE,
}
const API_KEY_PROVIDER_PROPERTIES := {
	"gemini": "gemini_api_key",
	"openrouter": "openrouter_api_key",
	"openai": "openai_api_key",
	"claude": "claude_api_key",
	"ai-router": "ai_router_api_key",
}
const PROVIDER_MODEL_PROPERTIES := {
	"gemini": "gemini_model",
	"openrouter": "openrouter_model",
	"ollama": "ollama_model",
	"openai": "openai_model",
	"claude": "claude_model",
	"lmstudio": "lmstudio_model",
	"ai-router": "ai_router_model",
}
const API_KEY_PROVIDER_ENUMS := {
	"gemini": AIConfigManagerScript.AIProvider.GEMINI,
	"openrouter": AIConfigManagerScript.AIProvider.OPENROUTER,
	"openai": AIConfigManagerScript.AIProvider.OPENAI,
	"claude": AIConfigManagerScript.AIProvider.CLAUDE,
	"ai-router": AIConfigManagerScript.AIProvider.AI_ROUTER,
}
const SUPPORTED_COMMANDS := [
	"help",
	"status",
	"autosave",
	"save",
	"load",
	"new-game",
	"scenario",
	"scenario-list",
	"save-info",
	"delete-save",
	"events",
	"ai-status",
	"provider-list",
	"set-provider",
	"set-language",
	"set-api-key",
	"ai-usage",
	"prayer",
	"journal",
	"journal-list",
	"credits",
	"story-pages",
	"special-scenes",
	"check-rage",
]
const COMMAND_ALIASES := {
	"h": "help",
	"new": "new-game",
	"scenarios": "scenario-list",
	"saves": "save-info",
	"rm-save": "delete-save",
	"logs": "events",
	"providers": "ai-status",
	"list-providers": "provider-list",
	"ai-config": "ai-status",
	"use-provider": "set-provider",
	"provider": "set-provider",
	"lang": "set-language",
	"apikey": "set-api-key",
	"set-key": "set-api-key",
	"tokens": "ai-usage",
	"usage": "ai-usage",
	"pray": "prayer",
	"diary": "journal",
	"journals": "journal-list",
	"intro": "story-pages",
	"story": "story-pages",
	"scenes": "special-scenes",
	"rage": "check-rage",
	"anger": "check-rage",
}
var _owner: Node
func _init(owner: Node) -> void:
	_owner = owner
func parse_command(args: Array[String]) -> String:
	if has_flag(args, "--cli-help"):
		return "help"
	var command := canonical_command(get_option(args, "--cli-command").strip_edges())
	if not command.is_empty():
		return command
	if has_flag(args, "--cli"):
		for arg in args:
			if arg.begins_with("--"):
				continue
			command = canonical_command(arg.strip_edges())
			if not command.is_empty():
				return command
	return ""
func canonical_command(raw_command: String) -> String:
	var command := raw_command.strip_edges().to_lower()
	if command.is_empty():
		return ""
	return String(COMMAND_ALIASES.get(command, command))
func resolve_language(args: Array[String]) -> String:
	var lang := get_option(args, "--lang").strip_edges().to_lower()
	if lang.is_empty():
		var game_state := get_game_state()
		if game_state != null and game_state.has_method("get"):
			lang = str(game_state.get("current_language")).strip_edges().to_lower()
	var normalized := normalize_language(lang)
	return normalized if not normalized.is_empty() else "en"
func normalize_language(raw_language: String) -> String:
	var lang := raw_language.strip_edges().to_lower()
	if lang in ["zh", "zh-tw", "zh-cn", "chinese"]:
		return "zh"
	if lang in ["en", "en-us", "en-gb", "english"]:
		return "en"
	return ""
func normalize_provider(raw_provider: String) -> String:
	var normalized := raw_provider.strip_edges().to_lower()
	var compact := normalized.replace("-", "").replace("_", "").replace(" ", "")
	if compact.is_empty():
		return ""
	if normalized in ["gemini", "google", "google-ai"]:
		return "gemini"
	if compact in ["gemini", "google", "googleai"]:
		return "gemini"
	if normalized in ["openrouter", "open-router"]:
		return "openrouter"
	if compact == "openrouter":
		return "openrouter"
	if normalized in ["ollama", "local", "offline"]:
		return "ollama"
	if compact in ["ollama", "local"]:
		return "ollama"
	if compact in ["offlinemode", "mockmode"]:
		return "mock"
	if normalized in ["openai", "gpt", "chatgpt"]:
		return "openai"
	if compact in ["openai", "gpt", "chatgpt"]:
		return "openai"
	if normalized in ["claude", "anthropic"]:
		return "claude"
	if compact in ["claude", "anthropic"]:
		return "claude"
	if normalized in ["lmstudio", "lm-studio", "local-openai"]:
		return "lmstudio"
	if compact in ["lmstudio", "localopenai"]:
		return "lmstudio"
	if normalized in ["ai-router", "ai_router", "airouter", "router"]:
		return "ai-router"
	if compact in ["airouter", "router"]:
		return "ai-router"
	if normalized in ["mock", "mock-mode", "test"]:
		return "mock"
	if compact in ["mock", "test"]:
		return "mock"
	return ""
func normalize_api_key_provider(raw_provider: String) -> String:
	var provider := normalize_provider(raw_provider)
	if API_KEY_PROVIDER_PROPERTIES.has(provider):
		return provider
	return ""
func get_first_non_command_positional(args: Array[String]) -> String:
	for arg in args:
		var token := String(arg).strip_edges()
		if token.is_empty():
			continue
		if token.begins_with("--"):
			continue
		var canon := canonical_command(token)
		if SUPPORTED_COMMANDS.has(canon):
			continue
		return token
	return ""
func has_flag(args: Array[String], flag: String) -> bool:
	return args.has(flag)
func get_option(args: Array[String], key: String) -> String:
	for i in range(args.size()):
		var arg := args[i]
		if arg == key:
			if i + 1 < args.size():
				return args[i + 1]
			return ""
		var prefix := key + "="
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return ""
func output_payload(payload: Dictionary, json_output: bool) -> void:
	if json_output:
		print(JSON.stringify(payload))
	else:
		print(JSON.stringify(payload, "  "))
func output_help(json_output: bool) -> void:
	var help_payload := {
		"ok": true,
		"command": "help",
		"usage": [
			"-- --cli --cli-command=status [--json]",
			"-- --cli --cli-command=save [--slot=2] [--json]",
			"-- --cli --cli-command=load [--slot=2] [--json]",
			"-- --cli --cli-command=save-info [--slot=2|--autosave] [--json]",
			"-- --cli --cli-command=delete-save --slot=2 [--json]",
			"-- --cli --cli-command=delete-save --autosave [--json]",
			"-- --cli --cli-command=events [--limit=10] [--lang=en|zh] [--json]",
			"-- --cli --cli-command=ai-status [--json]",
			"-- --cli --cli-command=ai-usage [--detailed] [--json]",
			"-- --cli --cli-command=provider-list [--json]",
			"-- --cli --cli-command=set-provider --provider=ollama [--json]",
			"-- --cli --cli-command=set-language --lang=en|zh [--json]",
			"-- --cli --cli-command=set-api-key --provider=openrouter --api-key=<key>|--api-key-env=<VAR>|--api-key-file=<path> [--set-current] [--json]",
			"-- --cli --cli-command=scenario [--scenario-id=<id>] [--lang=en|zh] [--json]",
			"-- --cli --cli-command=scenario-list [--json]",
			"-- --cli --cli-command=prayer [--text=<prayer>] [--context=default|night] [--simulate] [--json]",
			"-- --cli --cli-command=journal [--text=<entry>|--emotion=<type>] [--json]",
			"-- --cli --cli-command=journal-list [--json]",
			"-- --cli --cli-command=credits [--lang=en|zh] [--json]",
			"-- --cli --cli-command=story-pages [--page=<1-40>] [--lang=en|zh] [--json]",
			"-- --cli --cli-command=special-scenes [--scene=<type>] [--json]",
			"-- --cli --cli-command=check-rage [--json]",
			"-- --cli-help",
		],
		"options": {
			"--json": "Compact JSON output",
			"--cli-output=json": "Same as --json",
			"--lang=en|zh": "Language override",
			"--slot=<n>": "Save slot index (1-%d)" % get_max_save_slots(),
			"--autosave": "Target autosave for save-info/delete-save",
			"--limit=<n>": "Max event lines for events command",
			"--provider=<name>": "Provider for set-provider/set-api-key",
			"--to=<name>": "Provider alias for set-provider",
			"--api-key=<value>": "Direct API key for set-api-key",
			"--api-key-env=<VAR>": "Read API key from environment variable",
			"--api-key-file=<path>": "Read API key from file (first line / text, trimmed)",
			"--clear-key": "Clear provider API key",
			"--set-current": "Switch current provider while setting key",
			"--scenario-id=<id>": "Fetch a specific offline scenario",
			"--detailed": "Show detailed AI usage statistics",
			"--verbose": "Alias for --detailed",
			"--text=<content>": "Text content for prayer or journal entry",
			"--prayer=<content>": "Alias for --text in prayer command",
			"--entry=<content>": "Alias for --text in journal command",
			"--emotion=<type>": "Journal entry emotion (frustrated|hopeless|angry|confused|tired)",
			"--context=<type>": "Prayer context (default|night)",
			"--simulate": "Simulate prayer without submitting",
			"--dry-run": "Alias for --simulate",
			"--page=<1-40>": "Story page number to view",
			"--scene=<type>": "Special scene type (trolley-problem|night-cycle|teacher-singing|gloria-intervention)",
			"--type=<type>": "Alias for --scene",
			"--cli-silent": "Suppress engine error output where possible",
		},
		"supported_commands": SUPPORTED_COMMANDS,
	}
	output_payload(help_payload, json_output)
func ensure_game_state(game_state: Node, json_output: bool, command_name: String) -> bool:
	if game_state != null:
		return true
	output_payload(
		{
			"ok": false,
			"command": command_name,
			"error": "GameState service unavailable",
		},
		json_output,
	)
	return false
func resolve_slot_option(args: Array[String], command_name: String, json_output: bool, allow_missing: bool) -> Dictionary:
	var raw_slot := get_option(args, "--slot").strip_edges()
	if raw_slot.is_empty():
		if allow_missing:
			return {
				"ok": true,
				"provided": false,
				"slot": -1,
			}
		output_payload(
			{
				"ok": false,
				"command": command_name,
				"error": "Missing required option: --slot=<n>",
			},
			json_output,
		)
		return { "ok": false }
	if not raw_slot.is_valid_int():
		output_payload(
			{
				"ok": false,
				"command": command_name,
				"error": "Invalid slot value: %s" % raw_slot,
			},
			json_output,
		)
		return { "ok": false }
	var slot := int(raw_slot)
	var max_slots := get_max_save_slots()
	if slot < 1 or slot > max_slots:
		output_payload(
			{
				"ok": false,
				"command": command_name,
				"error": "Slot out of range: %d (valid: 1-%d)" % [slot, max_slots],
			},
			json_output,
		)
		return { "ok": false }
	return {
		"ok": true,
		"provided": true,
		"slot": slot,
	}
func resolve_limit_option(args: Array[String], command_name: String, json_output: bool) -> Dictionary:
	var raw_limit := get_option(args, "--limit").strip_edges()
	if raw_limit.is_empty():
		return {
			"ok": true,
			"limit": DEFAULT_EVENT_LIMIT,
		}
	if not raw_limit.is_valid_int():
		output_payload(
			{
				"ok": false,
				"command": command_name,
				"error": "Invalid limit value: %s" % raw_limit,
			},
			json_output,
		)
		return { "ok": false }
	var parsed_limit := int(raw_limit)
	if parsed_limit < 1:
		parsed_limit = 1
	elif parsed_limit > MAX_EVENT_LIMIT:
		parsed_limit = MAX_EVENT_LIMIT
	return {
		"ok": true,
		"limit": parsed_limit,
	}
func get_max_save_slots() -> int:
	return int(SaveLoadSystemScript.MAX_SAVE_SLOTS)
func get_game_state() -> Node:
	if ServiceLocator != null and ServiceLocator.has_method("get_game_state"):
		var located: Variant = ServiceLocator.get_game_state()
		if located != null:
			return located
	return GameState if GameState != null else null
func get_localization_manager() -> Node:
	if ServiceLocator != null and ServiceLocator.has_method("get_localization_manager"):
		var located: Variant = ServiceLocator.get_localization_manager()
		if located != null:
			return located
	return LocalizationManager if LocalizationManager != null else null
func get_error_reporter() -> Node:
	if ServiceLocator != null and ServiceLocator.has_method("get_error_reporter"):
		var located: Variant = ServiceLocator.get_error_reporter()
		if located != null:
			return located
	return ErrorReporter if ErrorReporter != null else null
func get_ai_manager() -> Node:
	if ServiceLocator != null and ServiceLocator.has_method("get_ai_manager"):
		var located: Variant = ServiceLocator.get_ai_manager()
		if located != null:
			return located
	return AIManager if AIManager != null else null
func get_current_provider(ai_manager: Node) -> String:
	if ai_manager == null or not ai_manager.has_method("get"):
		return ""
	var provider_value := int(ai_manager.get("current_provider"))
	for provider in PROVIDER_ENUMS.keys():
		if int(PROVIDER_ENUMS[provider]) == provider_value:
			return provider
	return ""
func get_current_api_key_provider(ai_manager: Node) -> String:
	var provider := get_current_provider(ai_manager)
	if API_KEY_PROVIDER_PROPERTIES.has(provider):
		return provider
	return ""
func get_supported_providers() -> Array[String]:
	var providers: Array[String] = []
	for key in PROVIDER_ENUMS.keys():
		providers.append(String(key))
	providers.sort()
	return providers
func get_api_key_supported_providers() -> Array[String]:
	var providers: Array[String] = []
	for key in API_KEY_PROVIDER_PROPERTIES.keys():
		providers.append(String(key))
	providers.sort()
	return providers
func get_provider_api_key(ai_manager: Node, provider: String, provider_value: int) -> String:
	if ai_manager == null:
		return ""
	if ai_manager.has_method("get_provider_api_key"):
		return String(ai_manager.call("get_provider_api_key", provider_value))
	var property_name := String(API_KEY_PROVIDER_PROPERTIES.get(provider, ""))
	if property_name.is_empty():
		return ""
	return String(ai_manager.get(property_name))
func is_provider_configured(ai_manager: Node, provider_value: int, provider_name: String) -> bool:
	if ai_manager == null:
		return false
	if ai_manager.has_method("is_provider_configured"):
		return bool(ai_manager.call("is_provider_configured", provider_value))
	if API_KEY_PROVIDER_PROPERTIES.has(provider_name):
		return not get_provider_api_key(ai_manager, provider_name, provider_value).is_empty()
	return true
func mask_secret(secret: String) -> String:
	if secret.is_empty():
		return ""
	if secret.length() <= 4:
		return repeat_token("*", secret.length())
	var visible := secret.substr(secret.length() - 4, 4)
	return repeat_token("*", secret.length() - 4) + visible
func repeat_token(token: String, count: int) -> String:
	var out := ""
	for _i in range(max(0, count)):
		out += token
	return out
func read_secret_from_file(path: String) -> Dictionary:
	var normalized_path := path.strip_edges()
	if normalized_path.is_empty():
		return {
			"ok": false,
			"error": "Missing file path for --api-key-file",
		}
	var file := FileAccess.open(normalized_path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"error": "Unable to read API key file: %s" % normalized_path,
		}
	var value := file.get_as_text().strip_edges()
	file.close()
	return {
		"ok": true,
		"value": value,
	}
func translate_or_fallback(key: String, fallback: String, lang: String) -> String:
	var localization_manager := get_localization_manager()
	if localization_manager != null and not key.is_empty():
		var translated := String(localization_manager.call("get_translation", key, lang))
		if not translated.is_empty() and translated != key:
			return translated.strip_edges()
	return fallback.strip_edges()
func build_scenario_output(scenario: Dictionary, lang: String) -> Dictionary:
	var fallback: Dictionary = scenario.get("fallback", {}) as Dictionary
	var keys: Dictionary = scenario.get("translation_keys", {}) as Dictionary
	return {
		"id": String(scenario.get("id", "")),
		"language": lang,
		"title": translate_or_fallback(String(keys.get("title", "")), String(fallback.get("title", "")), lang),
		"description": translate_or_fallback(String(keys.get("description", "")), String(fallback.get("description", "")), lang),
		"objective": translate_or_fallback(String(keys.get("objective", "")), String(fallback.get("objective", "")), lang),
		"complication": translate_or_fallback(String(keys.get("complication", "")), String(fallback.get("complication", "")), lang),
		"choices": resolve_scenario_choices(keys, fallback, lang),
		"assets": scenario.get("assets", []),
	}
func resolve_scenario_choices(keys: Dictionary, fallback: Dictionary, lang: String) -> Array[String]:
	var choice_key := String(keys.get("choices", ""))
	var localized := translate_or_fallback(choice_key, "", lang).replace("\\n", "\n")
	var localized_choices: Array[String] = []
	if not localized.is_empty():
		var lines: PackedStringArray = localized.split("\n")
		for raw_line in lines:
			var line := raw_line.strip_edges()
			if not line.is_empty():
				localized_choices.append(line)
	if not localized_choices.is_empty():
		return localized_choices
	var fallback_choices: Array[String] = []
	var raw_fallback: Variant = fallback.get("choices", [])
	if raw_fallback is Array:
		for item in raw_fallback:
			fallback_choices.append(String(item))
	return fallback_choices
func get_scenario_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var raw_entries: Variant = MissionScenarioLibraryScript.SCENARIOS
	if raw_entries is Array:
		for entry in raw_entries:
			if entry is Dictionary:
				entries.append((entry as Dictionary).duplicate(true))
	return entries
func get_scenario_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in get_scenario_entries():
		ids.append(String(entry.get("id", "")))
	return ids
func find_scenario_by_id(scenario_id: String) -> Dictionary:
	for entry in get_scenario_entries():
		var entry_id := String(entry.get("id", "")).to_lower()
		if entry_id == scenario_id:
			return entry.duplicate(true)
	return { }
