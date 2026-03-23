class_name AgentProtocol
extends RefCounted
const MSG_TYPE_OBSERVATION := "observation"
const MSG_TYPE_ACTION := "action"
const MSG_TYPE_ERROR := "error"
const MSG_TYPE_WELCOME := "welcome"
const MSG_TYPE_ACK := "ack"
const ACTION_SELECT_CHOICE := "select_choice"
const ACTION_START_MISSION := "start_mission"
const ACTION_START_NEW_GAME := "start_new_game"
const ACTION_CONTINUE_GAME := "continue_game"
const ACTION_GET_STATE := "get_state"
const ACTION_SUBMIT_PRAYER := "submit_prayer"
const ACTION_SET_AUTO_MODE := "set_auto_mode"
const ACTION_GO_TO_MENU := "go_to_menu"
const ACTION_SAVE_GAME := "save_game"
const ACTION_SET_STAT := "set_stat"
const ACTION_GET_STORY_HISTORY := "get_story_history"
const ACTION_SKIP_DIALOGUE := "skip_dialogue"
const ACTION_OPEN_JOURNAL := "open_journal"
const ACTION_CLOSE_OVERLAY := "close_overlay"
const ACTION_CONFIRM_OVERLAY := "confirm_overlay"
const ACTION_GET_AI_CONFIG := "get_ai_config"
const ACTION_SET_AI_PROVIDER := "set_ai_provider"
const ACTION_SET_AI_MODEL := "set_ai_model"
const ACTION_SET_API_KEY := "set_api_key"
const ACTION_SKIP_INTRO := "skip_intro"
const SCENE_STORY := "story"
const SCENE_NIGHT_CYCLE := "night_cycle"
const SCENE_LOADING := "loading"
const SCENE_MENU := "menu"
const PROTOCOL_VERSION := "1.0.0"
const DEFAULT_WS_PORT := 9876
const DEFAULT_TCP_PORT := 9877
static func create_welcome_message() -> Dictionary:
	return {
		"type": MSG_TYPE_WELCOME,
		"protocol_version": PROTOCOL_VERSION,
		"game": "Glorious Deliverance Agency 1",
		"available_actions": [
			ACTION_SELECT_CHOICE,
			ACTION_START_MISSION,
			ACTION_START_NEW_GAME,
			ACTION_CONTINUE_GAME,
			ACTION_GET_STATE,
			ACTION_SUBMIT_PRAYER,
			ACTION_SET_AUTO_MODE,
			ACTION_GO_TO_MENU,
			ACTION_SAVE_GAME,
			ACTION_SET_STAT,
			ACTION_GET_STORY_HISTORY,
			ACTION_SKIP_DIALOGUE,
			ACTION_OPEN_JOURNAL,
			ACTION_CLOSE_OVERLAY,
			ACTION_CONFIRM_OVERLAY,
			ACTION_GET_AI_CONFIG,
			ACTION_SET_AI_PROVIDER,
			ACTION_SET_AI_MODEL,
			ACTION_SET_API_KEY,
			ACTION_SKIP_INTRO,
		]
	}
static func create_observation(game_state: Dictionary) -> Dictionary:
	return {
		"type": MSG_TYPE_OBSERVATION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": game_state
	}
static func create_error(error_code: String, message: String) -> Dictionary:
	return {
		"type": MSG_TYPE_ERROR,
		"error_code": error_code,
		"message": message
	}
static func create_ack(action: String, success: bool, data: Dictionary = {}) -> Dictionary:
	var result := {
		"type": MSG_TYPE_ACK,
		"action": action,
		"success": success
	}
	if not data.is_empty():
		result["data"] = data
	return result
static func parse_action_message(json_string: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(json_string) != OK:
		return {"error": "Invalid JSON"}
	var data = parser.data
	if not data is Dictionary:
		return {"error": "Expected JSON object"}
	if not data.has("action"):
		return {"error": "Missing 'action' field"}
	return data
static func to_json(data: Dictionary) -> String:
	return JSON.stringify(data)
