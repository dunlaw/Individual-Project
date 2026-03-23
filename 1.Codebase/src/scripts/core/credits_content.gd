extends RefCounted
class_name CreditsContent
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
		+ _tr("CREDITS_SITA_DISCLAIMER") + "\n\n"
		+ _tr("CREDITS_AKIBARANGER")
	)
static func get_credits_text_plain(_lang: String) -> String:
	var text := get_hidden_credits_text()
	var regex = RegEx.new()
	regex.compile("\\[/?[^\\]]+\\]")
	text = regex.sub(text, "", true)
	return text
