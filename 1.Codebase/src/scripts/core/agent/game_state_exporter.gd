class_name GameStateExporter
extends RefCounted
static func export_full_state() -> Dictionary:
	var state := {
		"current_scene": _get_current_scene(),
		"mission": _get_mission_info(),
		"story_text": _get_story_text(),
		"available_choices": _get_available_choices(),
		"stats": _get_stats(),
		"scene": _get_scene_state(),
		"waiting_for_action": _is_waiting_for_input(),
		"is_generating": _is_ai_generating(),
		"overlay": _get_overlay_state(),
		"ai_error": _get_ai_error(),
		"ai_call_log": _get_ai_call_log(),
	}
	return state
static func _get_current_scene() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return "unknown"
	var current := tree.current_scene
	if not current:
		return "unknown"
	var scene_name := current.name.to_lower()
	if "story" in scene_name:
		return AgentProtocol.SCENE_STORY
	elif "night" in scene_name:
		return AgentProtocol.SCENE_NIGHT_CYCLE
	elif "menu" in scene_name or "splash" in scene_name:
		return AgentProtocol.SCENE_MENU
	return scene_name
static func _get_mission_info() -> Dictionary:
	var game_state = _get_game_state()
	if not game_state:
		return {}
	return {
		"mission_number": game_state.current_mission,
		"mission_title": game_state.current_mission_title if game_state.get("current_mission_title") else "",
		"turn_count": game_state.mission_turn_count if game_state.get("mission_turn_count") else 0
	}
static func _get_story_text() -> String:
	var game_state = _get_game_state()
	if game_state and game_state.has_method("get_latest_story_text"):
		return game_state.get_latest_story_text("")
	return ""
static func _get_available_choices() -> Array:
	var choices: Array = []
	var story_scene = _get_story_scene()
	if not story_scene:
		return choices
	var choice_controller = story_scene.get("choice_controller")
	if not choice_controller:
		return choices
	var current_choices = choice_controller.get("current_choices")
	if not current_choices or not current_choices is Array:
		return choices
	for i in range(current_choices.size()):
		var choice = current_choices[i]
		if choice is Dictionary:
			choices.append({
				"id": i,
				"archetype": choice.get("type", "unknown"),
				"text": choice.get("text", ""),
				"summary": choice.get("summary", "")
			})
	return choices
static func _get_stats() -> Dictionary:
	var game_state = _get_game_state()
	if not game_state:
		return {
			"reality_score": 50,
			"positive_energy": 50,
			"entropy_level": 0
		}
	return {
		"reality_score": game_state.reality_score,
		"positive_energy": game_state.positive_energy,
		"entropy_level": game_state.entropy_level
	}
static func _get_scene_state() -> Dictionary:
	var result := {
		"background": "",
		"characters": {}
	}
	var story_scene = _get_story_scene()
	if not story_scene:
		return result
	if story_scene.has_method("get_current_background"):
		result["background"] = story_scene.get_current_background()
	elif story_scene.get("current_background"):
		result["background"] = story_scene.current_background
	if story_scene.has_method("get_character_states"):
		result["characters"] = story_scene.get_character_states()
	return result
static func _is_waiting_for_input() -> bool:
	var choices := _get_available_choices()
	if not choices.is_empty():
		return true
	var story_scene = _get_story_scene()
	if story_scene and story_scene.get("is_waiting_for_input"):
		return true
	return false
static func _is_ai_generating() -> bool:
	var story_scene = _get_story_scene()
	if not story_scene:
		return false
	var narrative_controller = story_scene.get("narrative_controller")
	if narrative_controller and narrative_controller.has_method("is_generating"):
		return narrative_controller.is_generating()
	return false
static func _get_game_state():
	var service_locator = _get_service_locator()
	if service_locator and service_locator.has_method("get_game_state"):
		var sl_game_state = service_locator.call("get_game_state")
		if sl_game_state != null:
			return sl_game_state
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("GameState")
	return null
static func _get_story_scene():
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var current := tree.current_scene
	if current and "story" in current.name.to_lower():
		return current
	return null
static func _get_overlay_state() -> Dictionary:
	var result := {
		"active": false,
		"type": "",
		"has_confirm_button": false
	}
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return result
	var story_scene = _get_story_scene()
	if story_scene:
		var overlay_controller = story_scene.get("overlay_controller")
		if overlay_controller:
			var gloria = overlay_controller.get("gloria_overlay") if overlay_controller.has_method("get") else null
			if gloria and gloria is Control and gloria.visible:
				result["active"] = true
				result["type"] = "gloria_intervention"
				result["has_confirm_button"] = true
				return result
	for group in ["overlay", "popup", "dialog"]:
		for node in tree.get_nodes_in_group(group):
			if node is Control and node.visible:
				result["active"] = true
				result["type"] = node.name
				result["has_confirm_button"] = _has_confirm_button(node)
				return result
	return result
static func _has_confirm_button(node: Node) -> bool:
	var button_names := ["ContinueButton", "ConfirmButton", "AcceptButton", "OkButton", "CloseButton"]
	for btn_name in button_names:
		var btn = node.get_node_or_null(btn_name)
		if btn and btn is Button and btn.visible and not btn.disabled:
			return true
	for child in node.get_children():
		if child is Button and child.visible and not child.disabled:
			var text = child.text.to_lower()
			if "continue" in text or "accept" in text or "confirm" in text or "ok" in text:
				return true
		if _has_confirm_button(child):
			return true
	return false
static func _get_ai_error() -> Dictionary:
	var result := {
		"has_error": false,
		"message": "",
		"timestamp": 0
	}
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return result
	var ai_manager = _get_ai_manager()
	if not ai_manager:
		return result
	var last_error: String = ai_manager.last_ai_error if ai_manager.get("last_ai_error") else ""
	var last_timestamp: int = ai_manager.last_ai_error_timestamp if ai_manager.get("last_ai_error_timestamp") else 0
	if not last_error.is_empty():
		result["has_error"] = true
		result["message"] = last_error
		result["timestamp"] = last_timestamp
		var now = Time.get_ticks_msec()
		result["seconds_ago"] = (now - last_timestamp) / 1000.0 if last_timestamp > 0 else 0
	return result
static func _get_service_locator():
	if ServiceLocator and ServiceLocator.has_method("get_service"):
		return ServiceLocator
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("ServiceLocator")
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
static func _get_ai_call_log() -> Array:
	var ai_manager = _get_ai_manager()
	if ai_manager and ai_manager.has_method("get_call_log"):
		return ai_manager.get_call_log()
	return []
