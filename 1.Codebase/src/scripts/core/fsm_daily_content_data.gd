extends RefCounted
class_name FSMDailyContentData
const FSM_DAILY_KEYS = {
	1: {"theme_key": "FSM_DAY1_THEME", "content_key": "FSM_DAY1_CONTENT", "sublimation_key": "FSM_DAY1_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_1.png"},
	2: {"theme_key": "FSM_DAY2_THEME", "content_key": "FSM_DAY2_CONTENT", "sublimation_key": "FSM_DAY2_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_2.png"},
	3: {"theme_key": "FSM_DAY3_THEME", "content_key": "FSM_DAY3_CONTENT", "sublimation_key": "FSM_DAY3_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_3.png"},
	4: {"theme_key": "FSM_DAY4_THEME", "content_key": "FSM_DAY4_CONTENT", "sublimation_key": "FSM_DAY4_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_4.png"},
	5: {"theme_key": "FSM_DAY5_THEME", "content_key": "FSM_DAY5_CONTENT", "sublimation_key": "FSM_DAY5_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_5.png"},
	6: {"theme_key": "FSM_DAY6_THEME", "content_key": "FSM_DAY6_CONTENT", "sublimation_key": "FSM_DAY6_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_6.png"},
	7: {"theme_key": "FSM_DAY7_THEME", "content_key": "FSM_DAY7_CONTENT", "sublimation_key": "FSM_DAY7_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_7.png"},
	8: {"theme_key": "FSM_DAY8_THEME", "content_key": "FSM_DAY8_CONTENT", "sublimation_key": "FSM_DAY8_SUBLIMATION", "image_path": "res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_8.png"},
}
static func get_day_content(day: int) -> Dictionary:
	if not FSM_DAILY_KEYS.has(day):
		return {}
	var keys = FSM_DAILY_KEYS[day]
	var theme_key := keys["theme_key"] as String
	var content_key := keys["content_key"] as String
	var sublimation_key := keys["sublimation_key"] as String
	var theme_text := theme_key
	var content_text := content_key
	var sublimation_text := sublimation_key
	if LocalizationManager:
		theme_text = LocalizationManager.get_translation(theme_key)
		content_text = LocalizationManager.get_translation(content_key)
		sublimation_text = LocalizationManager.get_translation(sublimation_key)
	return {"theme": theme_text, "content": content_text, "sublimation": sublimation_text}
static func get_day_theme(day: int) -> String:
	var data = get_day_content(day)
	return data.get("theme", "")
static func get_day_text(day: int) -> String:
	var data = get_day_content(day)
	return data.get("content", "")
static func get_day_sublimation(day: int) -> String:
	var data = get_day_content(day)
	return data.get("sublimation", "")
static func get_day_image_path(day: int) -> String:
	if not FSM_DAILY_KEYS.has(day):
		return ""
	return FSM_DAILY_KEYS[day].get("image_path", "")
