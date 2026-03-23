extends RefCounted
const LOADING_PHRASE_KEYS := [
	"LOADING_PHRASE_1",
	"LOADING_PHRASE_2",
	"LOADING_PHRASE_3",
	"LOADING_PHRASE_4",
	"LOADING_PHRASE_5",
	"LOADING_PHRASE_6",
	"LOADING_PHRASE_7",
	"LOADING_PHRASE_8",
]
const LOADING_DOTS_SEQUENCE := ["", ".", "..", "..."]
const SUBLABEL_KEY_MAP := {
	"mission": "LOADING_SUB_MISSION",
	"choice": "LOADING_SUB_CHOICE",
	"consequence": "LOADING_SUB_CONSEQUENCE",
	"night": "LOADING_SUB_NIGHT",
	"interference": "LOADING_SUB_INTERFERENCE",
	"gloria": "LOADING_SUB_GLORIA",
	"trolley": "LOADING_SUB_TROLLEY",
	"default": "LOADING_SUB_DEFAULT",
}
const STAGE_LABEL_KEY_MAP := {
	"starting": "LOADING_STAGE_STARTING",
	"processing": "LOADING_STAGE_PROCESSING",
	"streaming": "LOADING_STAGE_STREAMING",
	"complete": "LOADING_STAGE_COMPLETE",
}
static func _get_tr(key: String, lang: String = "") -> String:
	var lm = ServiceLocator.get_localization_manager() if ServiceLocator else null
	if lm:
		if lang.is_empty():
			return lm.get_translation(key)
		return lm.get_translation(key, lang)
	return key
static func get_random_loading_phrase(lang: String) -> String:
	var key: String = LOADING_PHRASE_KEYS[randi() % LOADING_PHRASE_KEYS.size()]
	return _get_tr(key, lang)
static func get_loading_dots_for_time(animation_time: float) -> String:
	var dots_index := int(animation_time * 2) % LOADING_DOTS_SEQUENCE.size()
	return LOADING_DOTS_SEQUENCE[dots_index]
static func format_elapsed_time(elapsed_seconds: float) -> String:
	var minutes := int(elapsed_seconds) / 60
	var seconds := int(elapsed_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]
static func get_loading_sublabel(context: String, lang: String) -> String:
	if context in SUBLABEL_KEY_MAP:
		return _get_tr(SUBLABEL_KEY_MAP[context], lang)
	return _get_tr(SUBLABEL_KEY_MAP["default"], lang)
class LoadingConfig extends RefCounted:
	var main_text: String = ""
	var sub_text: String = ""
	var show_timer: bool = true
	var show_model: bool = true
	var show_dots: bool = true
	var context: String = "default"
	func _init(p_context: String = "default") -> void:
		context = p_context
static func create_mission_loading_config(lang: String) -> LoadingConfig:
	var config := LoadingConfig.new("mission")
	config.main_text = get_random_loading_phrase(lang)
	config.sub_text = get_loading_sublabel("mission", lang)
	return config
static func create_choice_loading_config(lang: String) -> LoadingConfig:
	var config := LoadingConfig.new("choice")
	config.main_text = get_random_loading_phrase(lang)
	config.sub_text = get_loading_sublabel("choice", lang)
	return config
static func create_consequence_loading_config(lang: String) -> LoadingConfig:
	var config := LoadingConfig.new("consequence")
	config.main_text = get_random_loading_phrase(lang)
	config.sub_text = get_loading_sublabel("consequence", lang)
	return config
static func parse_progress_update(update: Dictionary) -> Dictionary:
	var result := {
		"stage": update.get("stage", "processing"),
		"message": update.get("message", ""),
		"percent": float(update.get("progress", 0.0)),
		"tokens": int(update.get("tokens_used", 0)),
		"model": update.get("model", ""),
	}
	return result
static func get_progress_display_text(progress_info: Dictionary, lang: String) -> String:
	var stage: String = progress_info.get("stage", "processing")
	var message: String = progress_info.get("message", "")
	if not message.is_empty():
		return message
	if stage in STAGE_LABEL_KEY_MAP:
		return _get_tr(STAGE_LABEL_KEY_MAP[stage], lang)
	return get_random_loading_phrase(lang)
