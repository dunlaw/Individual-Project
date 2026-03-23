extends RefCounted
class_name SettingsMenuAgentServerSection
func build_section(
		parent: VBoxContainer,
		texts: Dictionary,
		initial_running: bool,
		on_toggled: Callable,
		on_help_pressed: Callable,
) -> Dictionary:
	var section_label := Label.new()
	section_label.name = "AgentServerLabel"
	section_label.text = String(texts.get("section_title", "Agent Server"))
	section_label.add_theme_font_size_override("font_size", 20)
	section_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.8))
	parent.add_child(section_label)
	var desc_label := Label.new()
	desc_label.text = String(texts.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	parent.add_child(desc_label)
	var enabled_check := CheckBox.new()
	enabled_check.text = String(texts.get("enable", "Enable"))
	enabled_check.add_theme_font_size_override("font_size", 16)
	if enabled_check.has_method("set_pressed_no_signal"):
		enabled_check.call("set_pressed_no_signal", initial_running)
	else:
		enabled_check.button_pressed = initial_running
	if on_toggled.is_valid():
		enabled_check.toggled.connect(on_toggled)
	parent.add_child(enabled_check)
	var ports_hbox := HBoxContainer.new()
	ports_hbox.add_theme_constant_override("separation", 20)
	var ws_label := Label.new()
	ws_label.text = String(texts.get("ws", "WebSocket: ws://localhost:9876"))
	ws_label.add_theme_font_size_override("font_size", 14)
	ws_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	ports_hbox.add_child(ws_label)
	var tcp_label := Label.new()
	tcp_label.text = String(texts.get("tcp", "TCP: localhost:9877"))
	tcp_label.add_theme_font_size_override("font_size", 14)
	tcp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	ports_hbox.add_child(tcp_label)
	parent.add_child(ports_hbox)
	var mcp_label := Label.new()
	mcp_label.text = String(texts.get("mcp", "MCP Server: mcp/gda1_server.py"))
	mcp_label.add_theme_font_size_override("font_size", 14)
	mcp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	parent.add_child(mcp_label)
	var status_label := Label.new()
	status_label.name = "AgentServerStatusLabel"
	status_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(status_label)
	var help_button := Button.new()
	help_button.text = String(texts.get("how_to_connect", "How to Connect"))
	help_button.custom_minimum_size = Vector2(200, 36)
	if on_help_pressed.is_valid():
		help_button.pressed.connect(on_help_pressed)
	parent.add_child(help_button)
	return {
		"enabled_check": enabled_check,
		"status_label": status_label,
		"help_button": help_button,
	}
func update_status_label(
		status_label: Label,
		selected_language: String,
		is_running: bool,
		agent_count: int,
) -> void:
	if not status_label:
		return
	var status_text := ""
	if selected_language == "en":
		var state := "Running" if is_running else "Disabled"
		status_text = "Status: %s | Connected agents: %d" % [state, agent_count]
	else:
		var state := "Running" if is_running else "Disabled"
		status_text = "Status: %s | Connected agents: %d" % [state, agent_count]
	status_label.text = status_text
	if is_running:
		status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	else:
		status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
func ensure_help_popup(
		owner: Node,
		popup: AcceptDialog,
		title: String,
		body: String,
		ok_text: String,
) -> AcceptDialog:
	var target_popup := popup
	if target_popup == null:
		target_popup = AcceptDialog.new()
		owner.add_child(target_popup)
	target_popup.title = title
	target_popup.dialog_text = body
	target_popup.ok_button_text = ok_text
	return target_popup
