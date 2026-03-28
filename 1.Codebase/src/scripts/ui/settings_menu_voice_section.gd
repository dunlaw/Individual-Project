extends RefCounted
class_name SettingsMenuVoiceSection
static func gather_preferences(
	voice_enabled: bool,
	voice_output_enabled: bool,
	voice_input_enabled: bool,
	voice_voice_name: String,
	voice_input_mode: int,
	voice_proactive_enabled: bool,
) -> Dictionary:
	return {
		"prefer_native_audio": voice_enabled,
		"voice_output_enabled": voice_output_enabled,
		"voice_input_enabled": voice_input_enabled,
		"preferred_voice_name": voice_voice_name,
		"voice_input_mode": voice_input_mode,
		"proactive_audio_enabled": voice_proactive_enabled,
	}
static func supports_proactive_audio(ai_manager: Node) -> bool:
	if not ai_manager:
		return false
	if ai_manager.current_provider != ai_manager.AIProvider.GEMINI:
		return false
	var model_name := String(ai_manager.gemini_model).strip_edges().to_lower()
	if model_name == "gemini-3.1-flash-live-preview":
		return false
	return model_name.find("native-audio") != -1
static func build_availability_text(ai_manager: Node, voice_supported: bool) -> String:
	if not ai_manager:
		return "Native voice unavailable (AI Manager missing)."
	if not voice_supported:
		return "Current model does not expose native audio."
	var provider_name := "Unknown"
	var model_name := ""
	match ai_manager.current_provider:
		ai_manager.AIProvider.GEMINI:
			provider_name = "Gemini"
			model_name = ai_manager.gemini_model
		ai_manager.AIProvider.OPENROUTER:
			provider_name = "OpenRouter"
			model_name = ai_manager.openrouter_model
		ai_manager.AIProvider.OLLAMA:
			provider_name = "Ollama (Local)"
			model_name = ai_manager.ollama_model
	var suffix := ""
	if ai_manager.current_provider == ai_manager.AIProvider.GEMINI and String(model_name).strip_edges().to_lower() == "gemini-3.1-flash-live-preview":
		suffix = " Proactive listening is unavailable on Gemini 3.1 Flash Live."
	return "Native audio ready via %s (%s).%s" % [provider_name, model_name, suffix]
static func try_enable_gemini_native_audio(ai_manager: Node) -> bool:
	if not ai_manager:
		return false
	if ai_manager.current_provider != ai_manager.AIProvider.GEMINI:
		return false
	ai_manager.refresh_voice_capabilities()
	return ai_manager.is_native_voice_supported()
