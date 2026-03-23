class_name AISettingsMenuBuilder
extends RefCounted
@warning_ignore("shadowed_global_identifier")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var _menu: Control
func _init(menu: Control) -> void:
	_menu = menu
func rebuild_layout_into_tabs() -> void:
	var panel = _menu.panel
	var original_scroll = _menu.original_scroll
	var buttons_container = _menu.buttons_container
	var main_vbox = _menu.main_vbox
	var tab_container: TabContainer
	if panel and original_scroll and panel.get_parent() == original_scroll:
		panel.reparent(_menu)
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.offset_left = 0
		panel.offset_top = 0
		panel.offset_right = 0
		panel.offset_bottom = 0
	if original_scroll:
		original_scroll.visible = false
	if buttons_container:
		buttons_container.visible = false
	if main_vbox:
		main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for child in main_vbox.get_children():
			main_vbox.remove_child(child)
		var global_settings = VBoxContainer.new()
		global_settings.name = "GlobalSettings"
		global_settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		global_settings.add_theme_constant_override("separation", 10)
		var global_margin = MarginContainer.new()
		global_margin.add_theme_constant_override("margin_top", 10)
		global_margin.add_theme_constant_override("margin_left", 10)
		global_margin.add_theme_constant_override("margin_right", 10)
		global_margin.add_theme_constant_override("margin_bottom", 5)
		global_margin.add_child(global_settings)
		main_vbox.add_child(global_margin)
		_move_control(_menu.provider_label, global_settings)
		_move_control(_menu.provider_option, global_settings)
		_move_control(_menu.provider_status_label, global_settings)
		_move_control(_menu.test_button, global_settings)
		_move_control(_menu.status_label, global_settings)
		_create_max_tokens_controls(global_settings)
		tab_container = TabContainer.new()
		tab_container.name = "AISettingsTabs"
		tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.add_child(tab_container)
		_menu.tab_container = tab_container
		if buttons_container:
			if buttons_container.get_parent():
				buttons_container.get_parent().remove_child(buttons_container)
			main_vbox.add_child(buttons_container)
			buttons_container.visible = true
	_menu.tab_online_providers = _create_tab_page("Online Providers")
	_menu.tab_local_llm = _create_tab_page("Local LLM")
	_menu.tab_safety = _create_tab_page("Safety")
	_menu.tab_memory = _create_tab_page("Memory")
	_menu.tab_behavior = _create_tab_page("Behavior")
	_menu.tab_metrics = _create_tab_page("Metrics")
	_menu.tab_mock_mode = _create_tab_page(_menu._tr("AI_SETTINGS_TAB_MOCK_MODE"))
	_create_mock_mode_section(_menu.tab_mock_mode)
	_create_online_provider_sections()
	_create_local_llm_sections()
	var tab_safety = _menu.tab_safety
	_menu.safety_level_label = Label.new()
	_menu.safety_level_label.name = "SafetyLevelLabel"
	tab_safety.add_child(_menu.safety_level_label)
	_menu.safety_level_option = OptionButton.new()
	_menu.safety_level_option.name = "SafetyLevelOption"
	_menu.safety_level_option.add_item("Game Mode (Block None) Recommended")
	_menu.safety_level_option.add_item("Low Blocking (Block Few)")
	_menu.safety_level_option.add_item("Standard (Default)")
	_menu.safety_level_option.add_item("High Blocking (Strict)")
	tab_safety.add_child(_menu.safety_level_option)
	_menu.safety_hint_label = Label.new()
	_menu.safety_hint_label.name = "SafetyHintLabel"
	_menu.safety_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.safety_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	tab_safety.add_child(_menu.safety_hint_label)
	var tab_memory = _menu.tab_memory
	_move_control(_menu.memory_settings_label, tab_memory)
	_move_control(_menu.memory_hint_label, tab_memory)
	_add_separator(tab_memory)
	_move_control(_menu.memory_limit_container, tab_memory)
	_move_control(_menu.memory_summary_container, tab_memory)
	_move_control(_menu.memory_full_container, tab_memory)
	_add_separator(tab_memory)
	_move_control(_menu.context_layers_label, tab_memory)
	_move_control(_menu.context_panel, tab_memory)
	if _menu.context_panel:
		_menu.context_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_menu.context_panel.custom_minimum_size.y = 200
	_move_control(_menu.ai_tone_style_label, _menu.tab_behavior)
	_move_control(_menu.ai_tone_style_input, _menu.tab_behavior)
	var tab_metrics = _menu.tab_metrics
	_move_control(_menu.metrics_label, tab_metrics)
	_move_control(_menu.metrics_chart_container, tab_metrics)
	if _menu.metrics_chart_container:
		_menu.metrics_chart_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_menu.metrics_chart_container.custom_minimum_size.y = 200
	_move_control(_menu.last_response_time_label, tab_metrics)
	_move_control(_menu.total_api_calls_label, tab_metrics)
	_move_control(_menu.total_tokens_used_label, tab_metrics)
	_move_control(_menu.last_input_tokens_label, tab_metrics)
	_move_control(_menu.last_output_tokens_label, tab_metrics)
	_add_separator(tab_metrics)
	_create_cumulative_stats_labels(tab_metrics)
func _create_tab_page(tab_name: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name + "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = tab_name + "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	margin.add_child(vbox)
	_menu.tab_container.add_child(scroll)
	return vbox
func _move_control(node: Control, new_parent: Control) -> void:
	if node:
		if node.get_parent():
			node.get_parent().remove_child(node)
		new_parent.add_child(node)
		node.visible = true
func _add_separator(parent: Control) -> void:
	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.3)
	parent.add_child(sep)
func _create_cumulative_stats_labels(parent: Control) -> void:
	_menu.cumulative_header_label = Label.new()
	_menu.cumulative_header_label.name = "CumulativeHeaderLabel"
	_menu.cumulative_header_label.add_theme_font_size_override("font_size", 18)
	_menu.cumulative_header_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	parent.add_child(_menu.cumulative_header_label)
	_menu.cumulative_api_calls_label = Label.new()
	_menu.cumulative_api_calls_label.name = "CumulativeAPICallsLabel"
	parent.add_child(_menu.cumulative_api_calls_label)
	_menu.cumulative_tokens_label = Label.new()
	_menu.cumulative_tokens_label.name = "CumulativeTokensLabel"
	parent.add_child(_menu.cumulative_tokens_label)
	_menu.cumulative_avg_response_label = Label.new()
	_menu.cumulative_avg_response_label.name = "CumulativeAvgResponseLabel"
	parent.add_child(_menu.cumulative_avg_response_label)
	_menu.cumulative_first_request_label = Label.new()
	_menu.cumulative_first_request_label.name = "CumulativeFirstRequestLabel"
	_menu.cumulative_first_request_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	parent.add_child(_menu.cumulative_first_request_label)
func _create_max_tokens_controls(parent: VBoxContainer) -> void:
	_menu.max_tokens_container = HBoxContainer.new()
	_menu.max_tokens_container.name = "MaxTokensContainer"
	_menu.max_tokens_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu.max_tokens_container.add_theme_constant_override("separation", 12)
	parent.add_child(_menu.max_tokens_container)
	_menu.max_tokens_label = Label.new()
	_menu.max_tokens_label.name = "MaxTokensLabel"
	_menu.max_tokens_label.text = "Max AI Reply Tokens (Per Request):"
	_menu.max_tokens_container.add_child(_menu.max_tokens_label)
	_menu.max_tokens_spin = SpinBox.new()
	_menu.max_tokens_spin.name = "MaxTokensSpin"
	_menu.max_tokens_spin.min_value = 1
	_menu.max_tokens_spin.max_value = 8192
	_menu.max_tokens_spin.step = 1
	_menu.max_tokens_spin.value = 4096
	_menu.max_tokens_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu.max_tokens_container.add_child(_menu.max_tokens_spin)
	_menu.max_tokens_hint_label = Label.new()
	_menu.max_tokens_hint_label.name = "MaxTokensHintLabel"
	_menu.max_tokens_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.max_tokens_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_menu.max_tokens_hint_label.text = "Limits one AI response length (output only). Not full-playthrough total, and not input token limit."
	parent.add_child(_menu.max_tokens_hint_label)
func _create_online_provider_sections() -> void:
	var tab_online = _menu.tab_online_providers
	var gemini_section = _create_provider_section("Google Gemini", tab_online)
	_menu.tab_gemini = gemini_section
	_move_control(_menu.gemini_label, gemini_section)
	_move_control(_menu.gemini_key_input, gemini_section)
	_move_control(_menu.gemini_hint_label, gemini_section)
	_move_control(_menu.gemini_model_label, gemini_section)
	_move_control(_menu.gemini_model_option, gemini_section)
	if _menu.gemini_model_input:
		_move_control(_menu.gemini_model_input, gemini_section)
	else:
		_create_gemini_model_input(gemini_section)
	_move_control(_menu.gemini_model_notice_label, gemini_section)
	_move_control(_menu.gemini_disabled_label, gemini_section)
	_add_separator(tab_online)
	var openrouter_section = _create_provider_section("OpenRouter", tab_online)
	_menu.tab_openrouter = openrouter_section
	_move_control(_menu.openrouter_label, openrouter_section)
	_move_control(_menu.openrouter_key_input, openrouter_section)
	_move_control(_menu.openrouter_hint_label, openrouter_section)
	_move_control(_menu.openrouter_model_label, openrouter_section)
	_move_control(_menu.openrouter_model_option, openrouter_section)
	_move_control(_menu.openrouter_model_input, openrouter_section)
	_create_openrouter_auto_router_controls(openrouter_section)
	_move_control(_menu.openrouter_disabled_label, openrouter_section)
	_add_separator(tab_online)
	var openai_section = _create_provider_section("OpenAI", tab_online)
	_menu.tab_openai = openai_section
	_create_openai_controls(openai_section)
	_add_separator(tab_online)
	var claude_section = _create_provider_section("Claude (Anthropic)", tab_online)
	_menu.tab_claude = claude_section
	_create_claude_controls(claude_section)
func _create_local_llm_sections() -> void:
	var tab_local = _menu.tab_local_llm
	var ollama_section = _create_provider_section("Ollama", tab_local)
	_menu.tab_ollama = ollama_section
	_move_control(_menu.ollama_header_label, ollama_section)
	_move_control(_menu.ollama_info_label, ollama_section)
	_move_control(_menu.ollama_host_label, ollama_section)
	_move_control(_menu.ollama_host_input, ollama_section)
	_move_control(_menu.ollama_port_label, ollama_section)
	_move_control(_menu.ollama_port_spin, ollama_section)
	_move_control(_menu.ollama_model_label, ollama_section)
	_move_control(_menu.ollama_model_input, ollama_section)
	_move_control(_menu.ollama_use_chat_check, ollama_section)
	_move_control(_menu.ollama_options_label, ollama_section)
	_move_control(_menu.ollama_options_input, ollama_section)
	_move_control(_menu.ollama_hint_label, ollama_section)
	_move_control(_menu.ollama_disabled_label, ollama_section)
	_add_separator(tab_local)
	var lmstudio_section = _create_provider_section("LMStudio", tab_local)
	_menu.tab_lmstudio = lmstudio_section
	_create_lmstudio_controls(lmstudio_section)
	_add_separator(tab_local)
	var ai_router_section = _create_provider_section("AI Router (Local Proxy)", tab_local)
	_menu.tab_ai_router = ai_router_section
	_create_ai_router_controls(ai_router_section)
func _create_provider_section(title: String, parent: VBoxContainer) -> VBoxContainer:
	var header = Label.new()
	header.name = title.replace(" ", "") + "Header"
	header.text = title
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	parent.add_child(header)
	var section = VBoxContainer.new()
	section.name = title.replace(" ", "") + "Section"
	section.add_theme_constant_override("separation", 10)
	parent.add_child(section)
	return section
func _create_gemini_model_input(parent: VBoxContainer) -> void:
	_menu.gemini_model_input = LineEdit.new()
	_menu.gemini_model_input.name = "GeminiModelInput"
	_menu.gemini_model_input.placeholder_text = "Enter custom Gemini model when 'Custom' is selected"
	_menu.gemini_model_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu.gemini_model_input.editable = false
	_menu.gemini_model_input.modulate = Color(0.7, 0.7, 0.7, 1)
	parent.add_child(_menu.gemini_model_input)
func _create_openai_controls(parent: VBoxContainer) -> void:
	_menu.openai_label = Label.new()
	_menu.openai_label.name = "OpenAILabel"
	_menu.openai_label.text = "OpenAI API Key:"
	parent.add_child(_menu.openai_label)
	_menu.openai_key_input = LineEdit.new()
	_menu.openai_key_input.name = "OpenAIKeyInput"
	_menu.openai_key_input.secret = true
	_menu.openai_key_input.placeholder_text = "sk-..."
	_menu.openai_key_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.openai_key_input)
	_menu.openai_hint_label = Label.new()
	_menu.openai_hint_label.name = "OpenAIHintLabel"
	_menu.openai_hint_label.text = "Get your key from: https://platform.openai.com/api-keys"
	_menu.openai_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_menu.openai_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_menu.openai_hint_label)
	_menu.openai_model_label = Label.new()
	_menu.openai_model_label.name = "OpenAIModelLabel"
	_menu.openai_model_label.text = "OpenAI Model:"
	parent.add_child(_menu.openai_model_label)
	_menu.openai_model_input = LineEdit.new()
	_menu.openai_model_input.name = "OpenAIModelInput"
	_menu.openai_model_input.text = "gpt-5.2"
	_menu.openai_model_input.placeholder_text = "gpt-5.2, gpt-4o, gpt-4.1, o3, o1, etc."
	_menu.openai_model_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.openai_model_input)
	_menu.openai_disabled_label = Label.new()
	_menu.openai_disabled_label.name = "OpenAIDisabledLabel"
	_menu.openai_disabled_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_menu.openai_disabled_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.openai_disabled_label.visible = false
	parent.add_child(_menu.openai_disabled_label)
func _create_claude_controls(parent: VBoxContainer) -> void:
	_menu.claude_label = Label.new()
	_menu.claude_label.name = "ClaudeLabel"
	_menu.claude_label.text = "Claude API Key:"
	parent.add_child(_menu.claude_label)
	_menu.claude_key_input = LineEdit.new()
	_menu.claude_key_input.name = "ClaudeKeyInput"
	_menu.claude_key_input.secret = true
	_menu.claude_key_input.placeholder_text = "sk-ant-..."
	_menu.claude_key_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.claude_key_input)
	_menu.claude_hint_label = Label.new()
	_menu.claude_hint_label.name = "ClaudeHintLabel"
	_menu.claude_hint_label.text = "Get your key from: https://console.anthropic.com/settings/keys"
	_menu.claude_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_menu.claude_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_menu.claude_hint_label)
	_menu.claude_model_label = Label.new()
	_menu.claude_model_label.name = "ClaudeModelLabel"
	_menu.claude_model_label.text = "Claude Model:"
	parent.add_child(_menu.claude_model_label)
	_menu.claude_model_input = LineEdit.new()
	_menu.claude_model_input.name = "ClaudeModelInput"
	_menu.claude_model_input.text = "claude-sonnet-4-5-20250929"
	_menu.claude_model_input.placeholder_text = "claude-sonnet-4-5-20250929, claude-opus-4-5-20251101, claude-haiku-4-5-20251001, etc."
	_menu.claude_model_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.claude_model_input)
	_menu.claude_disabled_label = Label.new()
	_menu.claude_disabled_label.name = "ClaudeDisabledLabel"
	_menu.claude_disabled_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_menu.claude_disabled_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.claude_disabled_label.visible = false
	parent.add_child(_menu.claude_disabled_label)
func _create_openrouter_auto_router_controls(parent: VBoxContainer) -> void:
	_add_separator(parent)
	_menu.openrouter_auto_router_check = CheckBox.new()
	_menu.openrouter_auto_router_check.name = "OpenRouterAutoRouterCheck"
	_menu.openrouter_auto_router_check.text = "Enable Auto Router for Cost Optimization"
	_menu.openrouter_auto_router_check.add_theme_font_size_override("font_size", 16)
	parent.add_child(_menu.openrouter_auto_router_check)
	_menu.openrouter_auto_router_info_label = Label.new()
	_menu.openrouter_auto_router_info_label.name = "OpenRouterAutoRouterInfoLabel"
	_menu.openrouter_auto_router_info_label.text = "When enabled, OpenRouter's Auto Router (openrouter/auto) automatically selects the most cost-effective model based on your prompt. Simple tasks like heartbeats and status checks are routed to cheaper (even free!) models, while complex interactions use more capable models. This can significantly reduce API costs."
	_menu.openrouter_auto_router_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_menu.openrouter_auto_router_info_label.add_theme_font_size_override("font_size", 14)
	_menu.openrouter_auto_router_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_menu.openrouter_auto_router_info_label)
	_menu.openrouter_auto_router_link_label = RichTextLabel.new()
	_menu.openrouter_auto_router_link_label.name = "OpenRouterAutoRouterLinkLabel"
	_menu.openrouter_auto_router_link_label.bbcode_enabled = true
	_menu.openrouter_auto_router_link_label.fit_content = true
	_menu.openrouter_auto_router_link_label.scroll_active = false
	_menu.openrouter_auto_router_link_label.add_theme_font_size_override("normal_font_size", 14)
	_menu.openrouter_auto_router_link_label.text = "[color=#6699ff][url=https://openrouter.ai/docs/features/auto-router]Learn more about Auto Router at openrouter.ai/docs/features/auto-router[/url][/color]"
	_menu.openrouter_auto_router_link_label.meta_clicked.connect(_menu._on_openrouter_auto_router_link_clicked)
	parent.add_child(_menu.openrouter_auto_router_link_label)
func _create_lmstudio_controls(parent: VBoxContainer) -> void:
	_menu.lmstudio_header_label = Label.new()
	_menu.lmstudio_header_label.name = "LMStudioHeaderLabel"
	_menu.lmstudio_header_label.text = "Configure LMStudio"
	_menu.lmstudio_header_label.add_theme_font_size_override("font_size", 18)
	parent.add_child(_menu.lmstudio_header_label)
	_menu.lmstudio_info_label = Label.new()
	_menu.lmstudio_info_label.name = "LMStudioInfoLabel"
	_menu.lmstudio_info_label.text = "LMStudio provides a local OpenAI-compatible API. Default: http://127.0.0.1:1234"
	_menu.lmstudio_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_menu.lmstudio_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_menu.lmstudio_info_label)
	_menu.lmstudio_host_label = Label.new()
	_menu.lmstudio_host_label.name = "LMStudioHostLabel"
	_menu.lmstudio_host_label.text = "LMStudio Host:"
	parent.add_child(_menu.lmstudio_host_label)
	_menu.lmstudio_host_input = LineEdit.new()
	_menu.lmstudio_host_input.name = "LMStudioHostInput"
	_menu.lmstudio_host_input.text = "127.0.0.1"
	_menu.lmstudio_host_input.placeholder_text = "127.0.0.1"
	_menu.lmstudio_host_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.lmstudio_host_input)
	_menu.lmstudio_port_label = Label.new()
	_menu.lmstudio_port_label.name = "LMStudioPortLabel"
	_menu.lmstudio_port_label.text = "LMStudio Port:"
	parent.add_child(_menu.lmstudio_port_label)
	_menu.lmstudio_port_spin = SpinBox.new()
	_menu.lmstudio_port_spin.name = "LMStudioPortSpin"
	_menu.lmstudio_port_spin.min_value = 1
	_menu.lmstudio_port_spin.max_value = 65535
	_menu.lmstudio_port_spin.value = 1234
	_menu.lmstudio_port_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.lmstudio_port_spin)
	_menu.lmstudio_model_label = Label.new()
	_menu.lmstudio_model_label.name = "LMStudioModelLabel"
	_menu.lmstudio_model_label.text = "Model (optional):"
	parent.add_child(_menu.lmstudio_model_label)
	_menu.lmstudio_model_input = LineEdit.new()
	_menu.lmstudio_model_input.name = "LMStudioModelInput"
	_menu.lmstudio_model_input.placeholder_text = "Leave empty to use currently loaded model"
	_menu.lmstudio_model_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.lmstudio_model_input)
	_menu.lmstudio_disabled_label = Label.new()
	_menu.lmstudio_disabled_label.name = "LMStudioDisabledLabel"
	_menu.lmstudio_disabled_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_menu.lmstudio_disabled_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.lmstudio_disabled_label.visible = false
	parent.add_child(_menu.lmstudio_disabled_label)
func _create_ai_router_controls(parent: VBoxContainer) -> void:
	_menu.ai_router_header_label = Label.new()
	_menu.ai_router_header_label.name = "AIRouterHeaderLabel"
	_menu.ai_router_header_label.text = "Configure AI Router"
	_menu.ai_router_header_label.add_theme_font_size_override("font_size", 18)
	parent.add_child(_menu.ai_router_header_label)
	_menu.ai_router_info_label = Label.new()
	_menu.ai_router_info_label.name = "AIRouterInfoLabel"
	_menu.ai_router_info_label.text = "AI Router connects to cloud AI models through a local proxy service (e.g., Antigravity Manager, One API, New API). Supports OpenAI, Claude, and Gemini API formats."
	_menu.ai_router_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_menu.ai_router_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_menu.ai_router_info_label)
	_menu.ai_router_host_label = Label.new()
	_menu.ai_router_host_label.name = "AIRouterHostLabel"
	_menu.ai_router_host_label.text = "Router Host:"
	parent.add_child(_menu.ai_router_host_label)
	_menu.ai_router_host_input = LineEdit.new()
	_menu.ai_router_host_input.name = "AIRouterHostInput"
	_menu.ai_router_host_input.text = "127.0.0.1"
	_menu.ai_router_host_input.placeholder_text = "127.0.0.1"
	_menu.ai_router_host_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.ai_router_host_input)
	_menu.ai_router_port_label = Label.new()
	_menu.ai_router_port_label.name = "AIRouterPortLabel"
	_menu.ai_router_port_label.text = "Router Port:"
	parent.add_child(_menu.ai_router_port_label)
	_menu.ai_router_port_spin = SpinBox.new()
	_menu.ai_router_port_spin.name = "AIRouterPortSpin"
	_menu.ai_router_port_spin.min_value = 1
	_menu.ai_router_port_spin.max_value = 65535
	_menu.ai_router_port_spin.value = 8046
	_menu.ai_router_port_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.ai_router_port_spin)
	_menu.ai_router_api_key_label = Label.new()
	_menu.ai_router_api_key_label.name = "AIRouterAPIKeyLabel"
	_menu.ai_router_api_key_label.text = "API Key (optional):"
	parent.add_child(_menu.ai_router_api_key_label)
	_menu.ai_router_api_key_input = LineEdit.new()
	_menu.ai_router_api_key_input.name = "AIRouterAPIKeyInput"
	_menu.ai_router_api_key_input.secret = true
	_menu.ai_router_api_key_input.placeholder_text = "e.g., sk-antigravity or your router's API key"
	_menu.ai_router_api_key_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.ai_router_api_key_input)
	_menu.ai_router_format_label = Label.new()
	_menu.ai_router_format_label.name = "AIRouterFormatLabel"
	_menu.ai_router_format_label.text = "API Format:"
	parent.add_child(_menu.ai_router_format_label)
	_menu.ai_router_format_option = OptionButton.new()
	_menu.ai_router_format_option.name = "AIRouterFormatOption"
	_menu.ai_router_format_option.add_item("OpenAI Format")
	_menu.ai_router_format_option.add_item("Claude Format")
	_menu.ai_router_format_option.add_item("Gemini Format")
	_menu.ai_router_format_option.selected = 0
	_menu.ai_router_format_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.ai_router_format_option)
	_menu.ai_router_model_label = Label.new()
	_menu.ai_router_model_label.name = "AIRouterModelLabel"
	_menu.ai_router_model_label.text = "Model:"
	parent.add_child(_menu.ai_router_model_label)
	_menu.ai_router_model_input = LineEdit.new()
	_menu.ai_router_model_input.name = "AIRouterModelInput"
	_menu.ai_router_model_input.placeholder_text = "e.g., gemini-3-flash, claude-sonnet-4-5, gemini-3.1-flash-thinking"
	_menu.ai_router_model_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.ai_router_model_input)
	_menu.ai_router_endpoint_label = Label.new()
	_menu.ai_router_endpoint_label.name = "AIRouterEndpointLabel"
	_menu.ai_router_endpoint_label.text = "Custom Endpoint (optional):"
	parent.add_child(_menu.ai_router_endpoint_label)
	_menu.ai_router_endpoint_input = LineEdit.new()
	_menu.ai_router_endpoint_input.name = "AIRouterEndpointInput"
	_menu.ai_router_endpoint_input.placeholder_text = "OpenAI: /v1/chat/completions, Claude: /v1/messages, Gemini: /v1beta/models/..."
	_menu.ai_router_endpoint_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_menu.ai_router_endpoint_input)
	var ai_router_api_hint_label = Label.new()
	ai_router_api_hint_label.name = "AIRouterAPIHintLabel"
	ai_router_api_hint_label.text = "Note: API key requirement depends on your routing service. Some services (e.g., local-only routers) don't require a key, while others (e.g., cloud-based routers) do."
	ai_router_api_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	ai_router_api_hint_label.add_theme_font_size_override("font_size", 13)
	ai_router_api_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(ai_router_api_hint_label)
	_menu.ai_router_disabled_label = Label.new()
	_menu.ai_router_disabled_label.name = "AIRouterDisabledLabel"
	_menu.ai_router_disabled_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_menu.ai_router_disabled_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.ai_router_disabled_label.visible = false
	parent.add_child(_menu.ai_router_disabled_label)
func _create_mock_mode_section(parent: VBoxContainer) -> void:
	var header = Label.new()
	header.name = "MockModeHeader"
	header.text = _menu._tr("AI_SETTINGS_MOCK_SECTION_TITLE")
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	parent.add_child(header)
	_add_separator(parent)
	var description = Label.new()
	description.name = "MockModeDescription"
	description.text = _menu._tr("AI_SETTINGS_MOCK_SECTION_DESCRIPTION")
	description.add_theme_font_size_override("font_size", 16)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(description)
	_add_separator(parent)
	var enable_header = Label.new()
	enable_header.name = "MockModeEnableHeader"
	enable_header.text = _menu._tr("AI_SETTINGS_MOCK_ENABLE_HEADER")
	enable_header.add_theme_font_size_override("font_size", 20)
	enable_header.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	parent.add_child(enable_header)
	var enable_instructions = Label.new()
	enable_instructions.name = "MockModeEnableInstructions"
	enable_instructions.text = _menu._tr("AI_SETTINGS_MOCK_ENABLE_INSTRUCTIONS")
	enable_instructions.add_theme_font_size_override("font_size", 16)
	enable_instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(enable_instructions)
	_add_separator(parent)
	var status_header = Label.new()
	status_header.name = "MockModeStatusHeader"
	status_header.text = _menu._tr("AI_SETTINGS_MOCK_STATUS_HEADER")
	status_header.add_theme_font_size_override("font_size", 20)
	status_header.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	parent.add_child(status_header)
	var mock_status_label = Label.new()
	mock_status_label.name = "MockModeStatusLabel"
	mock_status_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(mock_status_label)
	_menu._mock_mode_status_label = mock_status_label
	_menu._update_mock_mode_status()
	_add_separator(parent)
	var fallback_note = Label.new()
	fallback_note.name = "MockModeFallbackNote"
	fallback_note.text = _menu._tr("AI_SETTINGS_MOCK_FALLBACK_NOTE")
	fallback_note.add_theme_font_size_override("font_size", 14)
	fallback_note.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	fallback_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(fallback_note)
func apply_modern_styles() -> void:
	if _menu.panel:
		var style = UIStyleManager.create_panel_style(0.98, 0)
		_menu.panel.add_theme_stylebox_override("panel", style)
	if _menu.save_button:
		UIStyleManager.apply_button_style(_menu.save_button, "primary", "large")
		UIStyleManager.add_hover_scale_effect(_menu.save_button)
	if _menu.back_button:
		UIStyleManager.apply_button_style(_menu.back_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(_menu.back_button)
	if _menu.home_button:
		UIStyleManager.apply_button_style(_menu.home_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(_menu.home_button)
	if _menu.test_button:
		UIStyleManager.apply_button_style(_menu.test_button, "accent", "medium")
		UIStyleManager.add_press_feedback(_menu.test_button)
