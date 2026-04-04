extends RefCounted
class_name CreditsContent
const SITA_ALBUM_URL := "https://music.apple.com/gb/album/all-the-best/645845365"
const NIETZSCHE_LIBRARY_URL := "https://sussex.primo.exlibrisgroup.com/permalink/44SUS_INST/1cg8kvi/alma99730537902461"
const IMG_ALL_THE_BEST_SITA := "res://1.Codebase/src/assets/ui/all_the_best_sita_chan.png"
const IMG_ITUNES_STORE_SITA := "res://1.Codebase/src/assets/ui/itunes_store_backup_sita_chan.png"
const IMG_BORROW_NIETZSCHE := "res://1.Codebase/src/assets/ui/borrow_nietzsche_sussex_library.png"
const IMG_SUSSEX_LIBRARY := "res://1.Codebase/src/assets/ui/sussex_university_library.png"
static func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
static func get_hidden_credits_text() -> String:
	return (
		_tr("CREDITS_HIDDEN_INTRO") + "\n\n"
		+ _tr("CREDITS_NIETZSCHE_HEADING") + "\n"
		+ _tr("CREDITS_NIETZSCHE_BODY_1") + "\n\n"
		+ _tr("CREDITS_NIETZSCHE_BODY_2") + "\n\n"
		+ _get_nietzsche_images_bbcode() + "\n\n"
		+ _tr("CREDITS_PROGRAMMER_HEADING") + "\n"
		+ _tr("CREDITS_PROGRAMMER_BODY_1") + "\n\n"
		+ _tr("CREDITS_PROGRAMMER_BODY_2") + "\n\n"
		+ _tr("CREDITS_PROGRAMMER_BODY_3") + "\n\n"
		+ _tr("CREDITS_REST_WELL") + "\n\n"
		+ _tr("CREDITS_HEALTH_HEADING") + "\n"
		+ _tr("CREDITS_HEALTH_BODY_1") + "\n\n"
		+ _tr("CREDITS_HEALTH_BODY_2") + "\n\n"
		+ _tr("CREDITS_HEALTH_WARNING") + "\n\n"
		+ _tr("CREDITS_SITA_HEADING") + "\n"
		+ _tr("CREDITS_SITA_BODY_1") + "\n\n"
		+ _tr("CREDITS_SITA_BODY_2") + "\n\n"
		+ _get_sita_images_bbcode() + "\n\n"
		+ _tr("CREDITS_SITA_DISCLAIMER") + "\n\n"
		+ _tr("CREDITS_AKIBARANGER")
	)
static func _get_sita_images_bbcode() -> String:
	var bbcode := ""
	bbcode += "[center]"
	bbcode += "[url=" + SITA_ALBUM_URL + "][img width=300]" + IMG_ALL_THE_BEST_SITA + "[/img][/url]\n"
	bbcode += "[url=" + SITA_ALBUM_URL + "][img width=300]" + IMG_ITUNES_STORE_SITA + "[/img][/url]\n"
	bbcode += "[/center]"
	bbcode += "[i]" + _tr("CREDITS_SITA_ITUNES_NOTE") + "[/i]\n"
	bbcode += "[color=#aaaaaa](" + _tr("CREDITS_SITA_CLICK_HINT") + ")[/color]"
	return bbcode
static func _get_nietzsche_images_bbcode() -> String:
	var bbcode := ""
	bbcode += "[center]"
	if ResourceLoader.exists(IMG_SUSSEX_LIBRARY):
		bbcode += "[url=" + NIETZSCHE_LIBRARY_URL + "][img width=300]" + IMG_SUSSEX_LIBRARY + "[/img][/url]\n"
	bbcode += "[url=" + NIETZSCHE_LIBRARY_URL + "][img width=300]" + IMG_BORROW_NIETZSCHE + "[/img][/url]\n"
	bbcode += "[/center]"
	bbcode += "[i]" + _tr("CREDITS_NIETZSCHE_LIBRARY_NOTE") + "[/i]\n"
	bbcode += "[color=#aaaaaa](" + _tr("CREDITS_NIETZSCHE_CLICK_HINT") + ")[/color]"
	return bbcode
static func get_credits_text_plain(_lang: String) -> String:
	var text := get_hidden_credits_text()
	var regex = RegEx.new()
	regex.compile("\\[/?[^\\]]+\\]")
	text = regex.sub(text, "", true)
	return text
