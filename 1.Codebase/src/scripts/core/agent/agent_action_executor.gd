class_name AgentActionExecutor
extends RefCounted
static func execute(action_data: Dictionary) -> Dictionary:
	var action: String = action_data.get("action", "")
	var params: Dictionary = action_data.get("params", {})
	match action:
		AgentProtocol.ACTION_SELECT_CHOICE:
			return _execute_select_choice(params)
		AgentProtocol.ACTION_START_MISSION:
			return _execute_start_mission()
		AgentProtocol.ACTION_START_NEW_GAME:
			return _execute_start_new_game()
		AgentProtocol.ACTION_CONTINUE_GAME:
			return _execute_continue_game()
		AgentProtocol.ACTION_GET_STATE:
			return _execute_get_state()
		AgentProtocol.ACTION_SUBMIT_PRAYER:
			return _execute_submit_prayer(params)
		AgentProtocol.ACTION_SET_AUTO_MODE:
			return _execute_set_auto_mode(params)
		AgentProtocol.ACTION_GO_TO_MENU:
			return _execute_go_to_menu()
		AgentProtocol.ACTION_SAVE_GAME:
			return _execute_save_game()
		AgentProtocol.ACTION_SET_STAT:
			return _execute_set_stat(params)
		AgentProtocol.ACTION_GET_STORY_HISTORY:
			return _execute_get_story_history()
		AgentProtocol.ACTION_SKIP_DIALOGUE:
			return _execute_skip_dialogue()
		AgentProtocol.ACTION_OPEN_JOURNAL:
			return _execute_open_journal()
		AgentProtocol.ACTION_CLOSE_OVERLAY:
			return _execute_close_overlay()
		AgentProtocol.ACTION_CONFIRM_OVERLAY:
			return _execute_confirm_overlay()
		AgentProtocol.ACTION_GET_AI_CONFIG:
			return _execute_get_ai_config()
		AgentProtocol.ACTION_SET_AI_PROVIDER:
			return _execute_set_ai_provider(params)
		AgentProtocol.ACTION_SET_AI_MODEL:
			return _execute_set_ai_model(params)
		AgentProtocol.ACTION_SET_API_KEY:
			return _execute_set_api_key(params)
		AgentProtocol.ACTION_SKIP_INTRO:
			return _execute_skip_intro()
		_:
			return AgentProtocol.create_error("UNKNOWN_ACTION", "Unknown action: " + action)
static func _execute_select_choice(params: Dictionary) -> Dictionary:
	var choice_id: int = params.get("choice_id", -1)
	if choice_id < 0:
		return AgentProtocol.create_error("INVALID_PARAMS", "Missing or invalid choice_id")
	var story_scene = _get_story_scene()
	if not story_scene:
		return AgentProtocol.create_error("SCENE_NOT_FOUND", "Story scene not active")
	var choice_controller = story_scene.get("choice_controller")
	if not choice_controller:
		return AgentProtocol.create_error("CONTROLLER_NOT_FOUND", "Choice controller not found")
	var current_choices = choice_controller.get("current_choices")
	if not current_choices or current_choices.is_empty():
		return AgentProtocol.create_error("NO_CHOICES", "No choices available")
	if choice_id >= current_choices.size():
		return AgentProtocol.create_error("INVALID_CHOICE", "Choice ID out of range (max: %d)" % (current_choices.size() - 1))
	if choice_controller.has_method("on_choice_selected"):
		choice_controller.call_deferred("on_choice_selected", choice_id)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SELECT_CHOICE, true, {
			"choice_id": choice_id,
			"choice_text": current_choices[choice_id].get("text", "")
		})
	if choice_controller.has_signal("choice_selected"):
		choice_controller.emit_signal("choice_selected", choice_id)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SELECT_CHOICE, true, {
			"choice_id": choice_id,
			"choice_text": current_choices[choice_id].get("text", "")
		})
	return AgentProtocol.create_error("METHOD_NOT_FOUND", "Cannot select choice")
static func _execute_start_mission() -> Dictionary:
	var story_scene = _get_story_scene()
	if not story_scene:
		return AgentProtocol.create_error("SCENE_NOT_FOUND", "Story scene not active")
	var narrative_controller = story_scene.get("narrative_controller")
	if not narrative_controller:
		return AgentProtocol.create_error("CONTROLLER_NOT_FOUND", "Narrative controller not found")
	if narrative_controller.has_method("is_generating") and narrative_controller.is_generating():
		return AgentProtocol.create_error("BUSY", "AI is currently generating content")
	if narrative_controller.has_method("start_new_mission"):
		narrative_controller.call_deferred("start_new_mission")
		return AgentProtocol.create_ack(AgentProtocol.ACTION_START_MISSION, true)
	return AgentProtocol.create_error("METHOD_NOT_FOUND", "start_new_mission method not available")
static func _execute_start_new_game() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return AgentProtocol.create_error("NO_TREE", "Scene tree not available")
	var game_state = _get_game_state()
	if game_state and game_state.has_method("new_game"):
		game_state.new_game()
	var intro_story_path := "res://1.Codebase/src/scenes/ui/intro_story.tscn"
	var story_scene_path := "res://1.Codebase/src/scenes/ui/story_scene.tscn"
	var has_seen_intro := false
	var intro_script = load("res://1.Codebase/src/scripts/ui/intro_story.gd")
	if intro_script and intro_script.has_method("has_seen_intro"):
		has_seen_intro = intro_script.has_seen_intro()
	elif game_state and game_state.has_method("get_metadata"):
		has_seen_intro = game_state.get_metadata("intro_story_shown", false)
	var target_scene := intro_story_path if not has_seen_intro else story_scene_path
	if not ResourceLoader.exists(target_scene):
		target_scene = story_scene_path
	if ResourceLoader.exists(target_scene):
		tree.call_deferred("change_scene_to_file", target_scene)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_START_NEW_GAME, true, {
			"message": "Starting new game...",
			"scene": target_scene.get_file()
		})
	return AgentProtocol.create_error("SCENE_NOT_FOUND", "Cannot start new game, scene files not found")
static func _execute_continue_game() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return AgentProtocol.create_error("NO_TREE", "Scene tree not available")
	var game_state = _get_game_state()
	if not game_state:
		return AgentProtocol.create_error("NO_GAME_STATE", "GameState not available")
	var load_success := false
	if game_state.has_method("load_game"):
		load_success = game_state.load_game()
	elif tree.root:
		var save_system = _get_save_system()
		if save_system and save_system.has_method("load_game"):
			load_success = save_system.load_game()
	if not load_success:
		return AgentProtocol.create_error("NO_SAVE", "No save file found or failed to load")
	var story_scene_path := "res://1.Codebase/src/scenes/ui/story_scene.tscn"
	if ResourceLoader.exists(story_scene_path):
		tree.call_deferred("change_scene_to_file", story_scene_path)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_CONTINUE_GAME, true, {
			"message": "Continuing game..."
		})
	return AgentProtocol.create_error("SCENE_NOT_FOUND", "Story scene not found")
static func _execute_get_state() -> Dictionary:
	var state := GameStateExporter.export_full_state()
	return AgentProtocol.create_observation(state)
static func _execute_submit_prayer(params: Dictionary) -> Dictionary:
	var prayer_text: String = params.get("text", "")
	if prayer_text.is_empty():
		return AgentProtocol.create_error("INVALID_PARAMS", "Missing prayer text")
	var story_scene = _get_story_scene()
	if not story_scene:
		return AgentProtocol.create_error("SCENE_NOT_FOUND", "Story scene not active")
	var overlay_controller = story_scene.get("overlay_controller")
	if overlay_controller and overlay_controller.has_method("submit_prayer"):
		overlay_controller.submit_prayer(prayer_text)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SUBMIT_PRAYER, true, {
			"prayer_text": prayer_text
		})
	return AgentProtocol.create_error("METHOD_NOT_FOUND", "Prayer submission not available")
static func _execute_set_auto_mode(params: Dictionary) -> Dictionary:
	var enabled: bool = params.get("enabled", false)
	var delay_ms: int = params.get("delay_ms", 2000)
	var agent_server = _get_agent_server()
	if agent_server:
		agent_server.set_auto_mode(enabled, delay_ms)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SET_AUTO_MODE, true, {
			"enabled": enabled,
			"delay_ms": delay_ms
		})
	return AgentProtocol.create_error("SERVER_NOT_FOUND", "Agent server not available")
static func _execute_go_to_menu() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return AgentProtocol.create_error("NO_TREE", "Scene tree not available")
	var menu_path := "res://1.Codebase/src/scenes/ui/start_menu.tscn"
	if ResourceLoader.exists(menu_path):
		tree.call_deferred("change_scene_to_file", menu_path)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_GO_TO_MENU, true, {
			"message": "Returning to main menu..."
		})
	return AgentProtocol.create_error("SCENE_NOT_FOUND", "Menu scene not found")
static func _execute_save_game() -> Dictionary:
	var game_state = _get_game_state()
	if game_state and game_state.has_method("save_game"):
		game_state.save_game()
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SAVE_GAME, true, {
			"message": "Game saved successfully"
		})
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var save_system = _get_save_system()
		if save_system and save_system.has_method("save_game"):
			save_system.save_game()
			return AgentProtocol.create_ack(AgentProtocol.ACTION_SAVE_GAME, true, {
				"message": "Game saved via SaveLoadSystem"
			})
	return AgentProtocol.create_error("SAVE_FAILED", "Could not save game")
static func _execute_set_stat(params: Dictionary) -> Dictionary:
	var stat_name: String = params.get("stat", "")
	var value: int = params.get("value", -1)
	if stat_name.is_empty():
		return AgentProtocol.create_error("INVALID_PARAMS", "Missing stat name. Use: reality_score, positive_energy, entropy_level")
	var game_state = _get_game_state()
	if not game_state:
		return AgentProtocol.create_error("NO_GAME_STATE", "GameState not available")
	match stat_name:
		"reality_score", "reality":
			if game_state.get("reality_score") != null:
				game_state.reality_score = clampi(value, 0, 100)
				return AgentProtocol.create_ack(AgentProtocol.ACTION_SET_STAT, true, {
					"stat": "reality_score", "value": game_state.reality_score
				})
		"positive_energy", "energy":
			if game_state.get("positive_energy") != null:
				game_state.positive_energy = clampi(value, 0, 100)
				return AgentProtocol.create_ack(AgentProtocol.ACTION_SET_STAT, true, {
					"stat": "positive_energy", "value": game_state.positive_energy
				})
		"entropy_level", "entropy":
			if game_state.get("entropy_level") != null:
				game_state.entropy_level = clampi(value, 0, 100)
				return AgentProtocol.create_ack(AgentProtocol.ACTION_SET_STAT, true, {
					"stat": "entropy_level", "value": game_state.entropy_level
				})
	return AgentProtocol.create_error("INVALID_STAT", "Unknown stat: " + stat_name)
static func _execute_get_story_history() -> Dictionary:
	var game_state = _get_game_state()
	var history: Array = []
	if game_state and game_state.has_method("get_story_history"):
		history = game_state.get_story_history()
	elif game_state and game_state.get("story_history"):
		history = game_state.story_history
	elif game_state and game_state.get("conversation_history"):
		history = game_state.conversation_history
	return AgentProtocol.create_ack(AgentProtocol.ACTION_GET_STORY_HISTORY, true, {
		"history": history,
		"count": history.size()
	})
static func _execute_skip_dialogue() -> Dictionary:
	var story_scene = _get_story_scene()
	if not story_scene:
		return AgentProtocol.create_error("SCENE_NOT_FOUND", "Story scene not active")
	var text_display = story_scene.get("text_display")
	if text_display and text_display.has_method("skip_animation"):
		text_display.skip_animation()
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_DIALOGUE, true)
	var narrative = story_scene.get("narrative_controller")
	if narrative and narrative.has_method("skip_current"):
		narrative.skip_current()
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_DIALOGUE, true)
	return AgentProtocol.create_error("NO_DIALOGUE", "No dialogue to skip")
static func _execute_open_journal() -> Dictionary:
	var story_scene = _get_story_scene()
	if story_scene:
		var overlay = story_scene.get("overlay_controller")
		if overlay and overlay.has_method("open_journal"):
			overlay.open_journal()
			return AgentProtocol.create_ack(AgentProtocol.ACTION_OPEN_JOURNAL, true)
		if overlay and overlay.has_method("show_journal"):
			overlay.show_journal()
			return AgentProtocol.create_ack(AgentProtocol.ACTION_OPEN_JOURNAL, true)
	return AgentProtocol.create_error("JOURNAL_NOT_FOUND", "Cannot open journal")
static func _execute_close_overlay() -> Dictionary:
	var story_scene = _get_story_scene()
	if story_scene:
		var overlay = story_scene.get("overlay_controller")
		if overlay and overlay.has_method("close_all"):
			overlay.close_all()
			return AgentProtocol.create_ack(AgentProtocol.ACTION_CLOSE_OVERLAY, true)
		if overlay and overlay.has_method("hide"):
			overlay.hide()
			return AgentProtocol.create_ack(AgentProtocol.ACTION_CLOSE_OVERLAY, true)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		for node in tree.get_nodes_in_group("overlay"):
			if node.has_method("hide"):
				node.hide()
		return AgentProtocol.create_ack(AgentProtocol.ACTION_CLOSE_OVERLAY, true, {
			"message": "Attempted to close overlays"
		})
	return AgentProtocol.create_error("NO_OVERLAY", "No overlay to close")
static func _execute_confirm_overlay() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return AgentProtocol.create_error("NO_TREE", "Scene tree not available")
	var overlay_types := ["gloria_intervention", "overlay", "popup", "dialog"]
	for group in overlay_types:
		for node in tree.get_nodes_in_group(group):
			if not node.visible:
				continue
			var button = _find_confirm_button(node)
			if button and button.visible and not button.disabled:
				if button.has_method("emit_signal"):
					button.emit_signal("pressed")
					return AgentProtocol.create_ack(AgentProtocol.ACTION_CONFIRM_OVERLAY, true, {
						"message": "Clicked confirm button"
					})
	var story_scene = _get_story_scene()
	if story_scene:
		var overlay = story_scene.get("overlay_controller")
		if overlay:
			var gloria = overlay.get("gloria_overlay") if overlay.has_method("get") else null
			if gloria and gloria.visible:
				var btn = gloria.get_node_or_null("ContentPanel/Margin/VBox/ContinueButton")
				if btn and btn.visible and not btn.disabled:
					btn.emit_signal("pressed")
					return AgentProtocol.create_ack(AgentProtocol.ACTION_CONFIRM_OVERLAY, true, {
						"message": "Clicked Gloria continue button"
					})
	if tree.root:
		var result = _find_and_click_overlay_button(tree.root)
		if result:
			return result
	return AgentProtocol.create_error("NO_CONFIRM", "No confirm button found in overlays")
static func _find_confirm_button(node: Node) -> Button:
	var button_names := ["ContinueButton", "ConfirmButton", "AcceptButton", "OkButton", "CloseButton"]
	for btn_name in button_names:
		var btn = node.get_node_or_null(btn_name)
		if btn and btn is Button:
			return btn
	for child in node.get_children():
		if child is Button:
			var text = child.text.to_lower()
			if "continue" in text or "accept" in text or "confirm" in text or "ok" in text:
				return child
		var found = _find_confirm_button(child)
		if found:
			return found
	return null
static func _find_and_click_overlay_button(node: Node) -> Dictionary:
	if node is Control and node.visible:
		var name_lower = node.name.to_lower()
		if "overlay" in name_lower or "popup" in name_lower or "intervention" in name_lower:
			var btn = _find_confirm_button(node)
			if btn and btn.visible and not btn.disabled:
				btn.emit_signal("pressed")
				return AgentProtocol.create_ack(AgentProtocol.ACTION_CONFIRM_OVERLAY, true, {
					"message": "Clicked button in " + node.name
				})
	for child in node.get_children():
		var result = _find_and_click_overlay_button(child)
		if result:
			return result
	return {}
static func _get_story_scene():
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var current := tree.current_scene
	if current and "story" in current.name.to_lower():
		return current
	return null
static func _get_menu_scene():
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var current := tree.current_scene
	if current and ("menu" in current.name.to_lower() or "start" in current.name.to_lower()):
		return current
	return null
static func _get_game_state():
	var service_locator = _get_service_locator()
	if service_locator and service_locator.has_method("get_game_state"):
		var sl_game_state = service_locator.call("get_game_state")
		if sl_game_state != null:
			return sl_game_state
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("GameState")
	return null
static func _get_agent_server():
	var service_locator = _get_service_locator()
	if service_locator and service_locator.has_method("get_game_agent_server"):
		var sl_agent_server = service_locator.call("get_game_agent_server")
		if sl_agent_server != null:
			return sl_agent_server
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("GameAgentServer")
	return null
static func _get_ai_manager():
	var service_locator = _get_service_locator()
	if service_locator and service_locator.has_method("get_ai_manager"):
		var sl_ai_manager = service_locator.call("get_ai_manager")
		if sl_ai_manager != null:
			return sl_ai_manager
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("AIManager")
	return null
static func _get_save_system():
	var service_locator = _get_service_locator()
	if service_locator and service_locator.has_method("get_service"):
		var sl_save_system = service_locator.call("get_service", "SaveLoadSystem")
		if sl_save_system != null:
			return sl_save_system
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("SaveLoadSystem")
	return null
static func _get_service_locator():
	if ServiceLocator and ServiceLocator.has_method("get_service"):
		return ServiceLocator
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("ServiceLocator")
	return null
static func _execute_get_ai_config() -> Dictionary:
	var ai_manager = _get_ai_manager()
	if not ai_manager:
		return AgentProtocol.create_error("AI_MANAGER_NOT_FOUND", "AIManager not available")
	var providers := ["gemini", "openrouter", "ollama", "openai", "claude", "lmstudio", "ai_router", "mock"]
	var current_provider_idx: int = ai_manager.current_provider if ai_manager.get("current_provider") != null else 0
	var current_provider: String = providers[current_provider_idx] if current_provider_idx < providers.size() else "unknown"
	var config := {
		"current_provider": current_provider,
		"current_provider_id": current_provider_idx,
		"available_providers": providers,
		"gemini": {
			"model": ai_manager.gemini_model if ai_manager.get("gemini_model") else "",
			"has_api_key": not (ai_manager.gemini_api_key if ai_manager.get("gemini_api_key") else "").is_empty()
		},
		"openrouter": {
			"model": ai_manager.openrouter_model if ai_manager.get("openrouter_model") else "",
			"has_api_key": not (ai_manager.openrouter_api_key if ai_manager.get("openrouter_api_key") else "").is_empty()
		},
		"ollama": {
			"model": ai_manager.ollama_model if ai_manager.get("ollama_model") else "",
			"host": ai_manager.ollama_host if ai_manager.get("ollama_host") else "127.0.0.1",
			"port": ai_manager.ollama_port if ai_manager.get("ollama_port") else 11434
		},
		"openai": {
			"model": ai_manager.openai_model if ai_manager.get("openai_model") else "",
			"has_api_key": not (ai_manager.openai_api_key if ai_manager.get("openai_api_key") else "").is_empty()
		},
		"claude": {
			"model": ai_manager.claude_model if ai_manager.get("claude_model") else "",
			"has_api_key": not (ai_manager.claude_api_key if ai_manager.get("claude_api_key") else "").is_empty()
		},
		"lmstudio": {
			"model": ai_manager.lmstudio_model if ai_manager.get("lmstudio_model") else "",
			"host": ai_manager.lmstudio_host if ai_manager.get("lmstudio_host") else "127.0.0.1",
			"port": ai_manager.lmstudio_port if ai_manager.get("lmstudio_port") else 1234
		},
		"ai_router": {
			"model": ai_manager.ai_router_model if ai_manager.get("ai_router_model") else "",
			"host": ai_manager.ai_router_host if ai_manager.get("ai_router_host") else "127.0.0.1",
			"port": ai_manager.ai_router_port if ai_manager.get("ai_router_port") else 8046,
			"has_api_key": not (ai_manager.ai_router_api_key if ai_manager.get("ai_router_api_key") else "").is_empty()
		}
	}
	return AgentProtocol.create_ack(AgentProtocol.ACTION_GET_AI_CONFIG, true, config)
static func _execute_set_ai_provider(params: Dictionary) -> Dictionary:
	var provider: String = params.get("provider", "").to_lower()
	if provider.is_empty():
		return AgentProtocol.create_error("INVALID_PARAMS", "Missing provider. Options: gemini, openrouter, ollama, openai, claude, lmstudio, ai_router, mock")
	var ai_manager = _get_ai_manager()
	if not ai_manager:
		return AgentProtocol.create_error("AI_MANAGER_NOT_FOUND", "AIManager not available")
	var provider_map := {
		"gemini": 0, "openrouter": 1, "ollama": 2, "openai": 3,
		"claude": 4, "lmstudio": 5, "ai_router": 6, "mock": 7
	}
	if not provider_map.has(provider):
		return AgentProtocol.create_error("INVALID_PROVIDER", "Unknown provider: " + provider + ". Options: " + ", ".join(provider_map.keys()))
	var provider_id: int = provider_map[provider]
	ai_manager.current_provider = provider_id
	if ai_manager.has_method("save_settings"):
		ai_manager.save_settings()
	return AgentProtocol.create_ack(AgentProtocol.ACTION_SET_AI_PROVIDER, true, {
		"provider": provider,
		"provider_id": provider_id
	})
static func _execute_set_ai_model(params: Dictionary) -> Dictionary:
	var provider: String = params.get("provider", "").to_lower()
	var model: String = params.get("model", "")
	if model.is_empty():
		return AgentProtocol.create_error("INVALID_PARAMS", "Missing model name")
	var ai_manager = _get_ai_manager()
	if not ai_manager:
		return AgentProtocol.create_error("AI_MANAGER_NOT_FOUND", "AIManager not available")
	if provider.is_empty():
		var providers := ["gemini", "openrouter", "ollama", "openai", "claude", "lmstudio", "ai_router"]
		var idx: int = ai_manager.current_provider if ai_manager.get("current_provider") != null else 0
		provider = providers[idx] if idx < providers.size() else "gemini"
	match provider:
		"gemini":
			ai_manager.gemini_model = model
		"openrouter":
			ai_manager.openrouter_model = model
		"ollama":
			ai_manager.ollama_model = model
		"openai":
			ai_manager.openai_model = model
		"claude":
			ai_manager.claude_model = model
		"lmstudio":
			ai_manager.lmstudio_model = model
		"ai_router":
			ai_manager.ai_router_model = model
		_:
			return AgentProtocol.create_error("INVALID_PROVIDER", "Unknown provider: " + provider)
	if ai_manager.has_method("save_settings"):
		ai_manager.save_settings()
	return AgentProtocol.create_ack(AgentProtocol.ACTION_SET_AI_MODEL, true, {
		"provider": provider,
		"model": model
	})
static func _execute_set_api_key(params: Dictionary) -> Dictionary:
	var provider: String = params.get("provider", "").to_lower()
	var api_key: String = params.get("api_key", "")
	if provider.is_empty():
		return AgentProtocol.create_error("INVALID_PARAMS", "Missing provider. Options: gemini, openrouter, openai, claude, ai_router")
	if api_key.is_empty():
		return AgentProtocol.create_error("INVALID_PARAMS", "Missing api_key")
	var ai_manager = _get_ai_manager()
	if not ai_manager:
		return AgentProtocol.create_error("AI_MANAGER_NOT_FOUND", "AIManager not available")
	match provider:
		"gemini":
			ai_manager.gemini_api_key = api_key
		"openrouter":
			ai_manager.openrouter_api_key = api_key
		"openai":
			ai_manager.openai_api_key = api_key
		"claude":
			ai_manager.claude_api_key = api_key
		"ai_router":
			ai_manager.ai_router_api_key = api_key
		_:
			return AgentProtocol.create_error("INVALID_PROVIDER", "Provider does not use API key or unknown: " + provider)
	if ai_manager.has_method("save_settings"):
		ai_manager.save_settings()
	return AgentProtocol.create_ack(AgentProtocol.ACTION_SET_API_KEY, true, {
		"provider": provider,
		"key_set": true,
		"key_preview": api_key.substr(0, 8) + "..." if api_key.length() > 8 else "(short key)"
	})
static func _execute_skip_intro() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return AgentProtocol.create_error("NO_TREE", "Scene tree not available")
	var current := tree.current_scene
	if not current:
		return AgentProtocol.create_error("NO_SCENE", "No current scene")
	var guide_page = _find_game_guide_page(current)
	if guide_page:
		if guide_page.has_method("_on_close_pressed"):
			guide_page.call_deferred("_on_close_pressed")
			return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
				"message": "Closing game guide page..."
			})
		elif guide_page.has_signal("guide_closed"):
			guide_page.emit_signal("guide_closed")
			guide_page.queue_free()
			return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
				"message": "Dismissed game guide..."
			})
	var scene_name := current.name.to_lower()
	if "intro" in scene_name:
		if current.has_method("_go_to_story_scene"):
			var config := ConfigFile.new()
			config.load("user://settings.cfg")
			config.set_value("game", "intro_story_seen", true)
			config.set_value("game", "game_guide_seen", true)
			config.save("user://settings.cfg")
			current.call_deferred("_go_to_story_scene")
			return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
				"message": "Skipping directly to story scene..."
			})
		if current.has_method("_on_skip_pressed"):
			current.call_deferred("_on_skip_pressed")
			return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
				"message": "Skipping intro story..."
			})
		elif current.has_method("_complete_intro"):
			current.call_deferred("_complete_intro")
			return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
				"message": "Completing intro..."
			})
	for node in tree.get_nodes_in_group("guide"):
		if node is Control and node.visible:
			if node.has_method("_on_close_pressed"):
				node.call_deferred("_on_close_pressed")
				return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
					"message": "Closing game guide..."
				})
			if node.has_signal("guide_closed"):
				node.emit_signal("guide_closed")
				return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
					"message": "Dismissed game guide..."
				})
	for child in current.get_children():
		if child is Control and child.visible:
			var child_name := child.name.to_lower()
			if "guide" in child_name or "popup" in child_name or "tutorial" in child_name:
				if child.has_method("_on_close_pressed"):
					child.call_deferred("_on_close_pressed")
					return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
					"message": "Closing guide page..."
				})
				if child.has_method("hide"):
					child.call_deferred("hide")
					return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
						"message": "Hiding tutorial overlay..."
					})
	var story_scene_path := "res://1.Codebase/src/scenes/ui/story_scene.tscn"
	if ResourceLoader.exists(story_scene_path):
		var config := ConfigFile.new()
		config.load("user://settings.cfg")
		config.set_value("game", "intro_story_seen", true)
		config.set_value("game", "game_guide_seen", true)
		config.save("user://settings.cfg")
		tree.call_deferred("change_scene_to_file", story_scene_path)
		return AgentProtocol.create_ack(AgentProtocol.ACTION_SKIP_INTRO, true, {
			"message": "Force navigating to story scene..."
		})
	return AgentProtocol.create_error("NOT_IN_INTRO", "Not in intro or guide screen")
static func _find_game_guide_page(node: Node) -> Control:
	if node is Control:
		var node_name := node.name.to_lower()
		if "guide" in node_name and node.visible:
			if node.has_method("_on_close_pressed") or node.has_signal("guide_closed"):
				return node
	for child in node.get_children():
		var found = _find_game_guide_page(child)
		if found:
			return found
	return null
