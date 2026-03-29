extends RefCounted
class_name SettingsMenuAILogRenderer
const AIChartCanvas = preload("res://1.Codebase/src/scripts/ui/ai_chart_canvas.gd")
static func refresh_analytics(
	charts: Dictionary,
	kpi_labels: Array,
	log_entries: Array,
) -> void:
	var a: Dictionary = SettingsMenuAIAnalytics.compute_analytics(log_entries)
	var kpi_vals: Array = [
		str(a.get("total", 0)),
		"%.1f%%" % float(a.get("success_rate", 0.0)),
		SettingsMenuAIAnalytics.format_token_count(int(a.get("total_tokens", 0))),
		"%.2fs" % float(a.get("avg_response_time", 0.0)),
	]
	for i in range(mini(kpi_labels.size(), kpi_vals.size())):
		if is_instance_valid(kpi_labels[i]):
			(kpi_labels[i] as Label).text = kpi_vals[i]
	var chart_success_by_provider: AIChartCanvas = charts.get("success_by_provider") as AIChartCanvas
	if chart_success_by_provider and is_instance_valid(chart_success_by_provider):
		chart_success_by_provider.setup(
			AIChartCanvas.Type.HORIZONTAL_BAR,
			"Success Rate by Provider (%)",
			a.get("provider_labels", []),
			a.get("provider_success_rates", []),
			[Color(0.3, 0.9, 0.4), Color(0.35, 0.7, 1.0), Color(1.0, 0.7, 0.3),
			 Color(0.9, 0.5, 1.0), Color(0.4, 0.9, 0.9)],
		)
	var chart_mode_pie: AIChartCanvas = charts.get("mode_pie") as AIChartCanvas
	if chart_mode_pie and is_instance_valid(chart_mode_pie):
		var mode_colors: Array[Color] = [
			Color(0.3, 0.85, 0.4), Color(0.8, 0.9, 0.3),
			Color(1.0, 0.5, 0.3), Color(0.65, 0.4, 1.0),
		]
		chart_mode_pie.setup(
			AIChartCanvas.Type.PIE, "Call Mode Distribution",
			a.get("mode_labels", []), a.get("mode_counts", []), mode_colors,
		)
	var chart_hourly_requests: AIChartCanvas = charts.get("hourly_requests") as AIChartCanvas
	if chart_hourly_requests and is_instance_valid(chart_hourly_requests):
		chart_hourly_requests.setup(
			AIChartCanvas.Type.VERTICAL_BAR, "Requests / Hour (last 24 h)",
			a.get("hourly_labels", []), a.get("hourly_calls", []),
			[Color(0.35, 0.7, 1.0)],
		)
	var chart_success_per_hour: AIChartCanvas = charts.get("success_per_hour") as AIChartCanvas
	if chart_success_per_hour and is_instance_valid(chart_success_per_hour):
		chart_success_per_hour.setup(
			AIChartCanvas.Type.LINE, "Success Count / Hour (last 24 h)",
			a.get("hourly_labels", []), a.get("hourly_successes", []),
			[Color(0.3, 0.9, 0.4)],
		)
	var chart_calls_by_model: AIChartCanvas = charts.get("calls_by_model") as AIChartCanvas
	if chart_calls_by_model and is_instance_valid(chart_calls_by_model):
		chart_calls_by_model.setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Calls by Model",
			a.get("model_labels", []), a.get("model_counts", []),
			[Color(0.6, 0.82, 1.0)],
		)
	var chart_tokens_by_provider: AIChartCanvas = charts.get("tokens_by_provider") as AIChartCanvas
	if chart_tokens_by_provider and is_instance_valid(chart_tokens_by_provider):
		chart_tokens_by_provider.setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Total Tokens by Provider",
			a.get("provider_labels", []), a.get("provider_tokens", []),
			[Color(0.55, 0.82, 1.0)],
		)
	var chart_response_by_provider: AIChartCanvas = charts.get("response_by_provider") as AIChartCanvas
	if chart_response_by_provider and is_instance_valid(chart_response_by_provider):
		chart_response_by_provider.setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Avg Response Time / Provider (s)",
			a.get("provider_labels", []), a.get("provider_response_times", []),
			[Color(1.0, 0.72, 0.28)],
		)
	var chart_input_output_tokens: AIChartCanvas = charts.get("input_output_tokens") as AIChartCanvas
	if chart_input_output_tokens and is_instance_valid(chart_input_output_tokens):
		var stacked_labels: Array = (a.get("provider_labels", []) as Array).duplicate()
		var stacked_vals: Array = []
		var in_vals: Array = a.get("provider_input_tokens", [])
		var out_vals: Array = a.get("provider_output_tokens", [])
		for idx in range(stacked_labels.size()):
			stacked_labels.insert(idx * 2 + 1, stacked_labels[idx * 2] + " out")
			stacked_labels[idx * 2] = stacked_labels[idx * 2] + " in"
		for idx in range(in_vals.size()):
			stacked_vals.append(float(in_vals[idx]))
			stacked_vals.append(float(out_vals[idx]))
		chart_input_output_tokens.setup(
			AIChartCanvas.Type.VERTICAL_BAR, "Input vs Output Tokens by Provider",
			stacked_labels, stacked_vals,
			[Color(0.35, 0.70, 1.0), Color(0.35, 0.95, 0.60)],
		)
	var chart_tps_by_provider: AIChartCanvas = charts.get("tps_by_provider") as AIChartCanvas
	if chart_tps_by_provider and is_instance_valid(chart_tps_by_provider):
		chart_tps_by_provider.setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Avg TPS by Provider",
			a.get("provider_labels", []), a.get("provider_tps", []),
			[Color(0.78, 0.48, 1.0)],
		)
	var chart_hourly_tokens: AIChartCanvas = charts.get("hourly_tokens") as AIChartCanvas
	if chart_hourly_tokens and is_instance_valid(chart_hourly_tokens):
		chart_hourly_tokens.setup(
			AIChartCanvas.Type.LINE, "Token Usage / Hour (last 24 h)",
			a.get("hourly_labels", []), a.get("hourly_tokens", []), [],
		)
	var chart_cumulative_tokens: AIChartCanvas = charts.get("cumulative_tokens") as AIChartCanvas
	if chart_cumulative_tokens and is_instance_valid(chart_cumulative_tokens):
		chart_cumulative_tokens.setup(
			AIChartCanvas.Type.LINE, "Cumulative Total Tokens (session, newest last)",
			a.get("cumulative_labels", []), a.get("cumulative_tokens", []),
			[Color(1.0, 0.82, 0.35)],
		)
static func refresh_table(
	container: VBoxContainer,
	log_entries: Array,
	tr_callable: Callable,
	on_entry_selected: Callable = Callable(),
) -> void:
	if not container:
		return
	for child in container.get_children():
		child.queue_free()
	if log_entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.name = "AILogEmptyLabel"
		empty_lbl.text = tr_callable.call("SETTINGS_AI_LOG_EMPTY", "No AI calls recorded yet.")
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_lbl.add_theme_font_size_override("font_size", 14)
		container.add_child(empty_lbl)
		return
	var col_widths := [170, 90, 160, 70, 80, 80, 75, 90, 100]
	var reversed_entries: Array = log_entries.duplicate()
	reversed_entries.reverse()
	for row_idx in range(reversed_entries.size()):
		var entry: Dictionary = reversed_entries[row_idx]
		var row_panel := PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row_style := StyleBoxFlat.new()
		var success: bool = bool(entry.get("success", false))
		var mode: String = str(entry.get("mode", ""))
		if not success:
			row_style.bg_color = Color(0.35, 0.12, 0.12, 0.85) if row_idx % 2 == 0 else Color(0.3, 0.1, 0.1, 0.85)
		elif mode == "mock" or mode == "mock_fallback":
			row_style.bg_color = Color(0.18, 0.22, 0.12, 0.85) if row_idx % 2 == 0 else Color(0.15, 0.19, 0.10, 0.85)
		else:
			row_style.bg_color = Color(0.12, 0.18, 0.12, 0.85) if row_idx % 2 == 0 else Color(0.10, 0.15, 0.10, 0.85)
		row_panel.add_theme_stylebox_override("panel", row_style)
		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_top", 4)
		row_margin.add_theme_constant_override("margin_left", 14)
		row_margin.add_theme_constant_override("margin_right", 14)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		row_panel.add_child(row_margin)
		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 4)
		row_margin.add_child(row_hbox)
		var status_code: int = int(entry.get("status_code", 0))
		var status_text: String = ""
		var status_color := Color(0.9, 0.9, 0.9)
		if mode == "mock" or mode == "mock_fallback":
			status_text = "MOCK"
			status_color = Color(0.8, 0.9, 0.4)
		elif not success:
			status_text = str(status_code) if status_code > 0 else "ERR"
			status_color = Color(1.0, 0.4, 0.4)
		else:
			status_text = str(status_code) if status_code > 0 else "200"
			status_color = Color(0.4, 1.0, 0.4)
		var timestamp_str: String = str(entry.get("timestamp", ""))
		if timestamp_str.length() > 19:
			timestamp_str = timestamp_str.substr(0, 19)
		timestamp_str = timestamp_str.replace("T", " ")
		var cell_values: Array = [
			timestamp_str,
			str(entry.get("provider", "")),
			str(entry.get("model", "")),
			status_text,
			str(int(entry.get("input_tokens", 0))),
			str(int(entry.get("output_tokens", 0))),
			"%.2f" % float(entry.get("response_time_sec", 0.0)),
			str(entry.get("mode", "")),
			str(entry.get("purpose", "")),
		]
		var cell_colors: Array = [
			Color(0.85, 0.85, 0.85), Color(0.7, 0.85, 1.0), Color(0.85, 0.85, 1.0),
			status_color, Color(0.8, 1.0, 0.8), Color(0.8, 1.0, 0.8),
			Color(1.0, 0.9, 0.6), Color(0.9, 0.8, 1.0), Color(0.85, 0.85, 0.85),
		]
		for i in range(cell_values.size()):
			var cell_lbl := Label.new()
			cell_lbl.text = str(cell_values[i])
			cell_lbl.add_theme_font_size_override("font_size", 11)
			cell_lbl.add_theme_color_override("font_color", cell_colors[i])
			cell_lbl.custom_minimum_size = Vector2(col_widths[i], 0)
			cell_lbl.clip_text = true
			cell_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			row_hbox.add_child(cell_lbl)
		if not success:
			var err_str: String = str(entry.get("error", ""))
			if not err_str.is_empty():
				row_panel.tooltip_text = "Error: " + err_str
		elif bool(entry.get("detail_available", false)):
			row_panel.tooltip_text = tr_callable.call(
				"SETTINGS_AI_LOG_DETAIL_OPEN_HINT",
				"Click to inspect full request and response details.",
			)
		if on_entry_selected.is_valid() and bool(entry.get("detail_available", false)):
			row_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			row_panel.gui_input.connect(
				func(event: InputEvent) -> void:
					if event is InputEventMouseButton:
						var mouse_event := event as InputEventMouseButton
						if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
							on_entry_selected.call(entry)
			)
		container.add_child(row_panel)
static func format_detail_text(entry: Dictionary, tr_callable: Callable) -> String:
	var lines: PackedStringArray = []
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_REQUEST_TIME", "Request Time"))
	lines.append(_format_timestamp(str(entry.get("request_timestamp", entry.get("timestamp", "")))))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_DURATION", "Duration"))
	lines.append("%dms" % int(entry.get("duration_msec", int(round(float(entry.get("response_time_sec", 0.0)) * 1000.0)))))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_TOKENS", "Token Usage (In/Out)"))
	lines.append("In: %d" % int(entry.get("input_tokens", 0)))
	lines.append("Out: %d" % int(entry.get("output_tokens", 0)))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_PROTOCOL", "Request Protocol"))
	lines.append(str(entry.get("protocol", "")))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_ENDPOINT", "Endpoint"))
	lines.append(str(entry.get("request_endpoint", "-")) if not str(entry.get("request_endpoint", "")).is_empty() else "-")
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_PROVIDER", "Provider"))
	lines.append(str(entry.get("provider", "")))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_MODEL", "Model"))
	lines.append(str(entry.get("model", "")))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_ACCOUNT", "Account"))
	lines.append(str(entry.get("account", "-")) if not str(entry.get("account", "")).is_empty() else "-")
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_PURPOSE", "Purpose"))
	lines.append(str(entry.get("purpose", "")))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_PROMPT_MODULES", "Prompt Modules Breakdown"))
	lines.append(format_prompt_modules(entry))
	lines.append("")
	lines.append(tr_callable.call("SETTINGS_AI_LOG_DETAIL_AI_RESPONSE_TEXT", "AI Response (plain text)"))
	var ai_text := extract_ai_response_text(str(entry.get("response_body", "")))
	lines.append(ai_text if not ai_text.is_empty() else "(not available)")
	lines.append("")
	lines.append("%s (Request)" % tr_callable.call("SETTINGS_AI_LOG_DETAIL_REQUEST", "Request"))
	lines.append(format_request_body(entry))
	lines.append("")
	lines.append("%s (Response)" % tr_callable.call("SETTINGS_AI_LOG_DETAIL_RESPONSE", "Response"))
	lines.append(format_response_body(entry))
	return "\n".join(lines)
static func format_request_body(entry: Dictionary) -> String:
	var request_body := str(entry.get("request_body", ""))
	if request_body.is_empty():
		return "{}"
	return _pretty_json_string(request_body)
static func format_response_body(entry: Dictionary) -> String:
	var response_body := str(entry.get("response_body", ""))
	if response_body.is_empty():
		return "{}"
	return _pretty_json_string(response_body)
static func _extract_messages_from_body(request_body: String) -> Array:
	if request_body.is_empty():
		return []
	var json := JSON.new()
	if json.parse(request_body) != OK:
		return []
	var data: Variant = json.data
	if not (data is Dictionary):
		return []
	var d := data as Dictionary
	if d.has("messages"):
		var msgs: Variant = d["messages"]
		if msgs is Array:
			return msgs as Array
	if d.has("contents"):
		var contents: Variant = d["contents"]
		if contents is Array:
			return contents as Array
	return []
static func _get_message_text(msg: Dictionary) -> String:
	var content: Variant = msg.get("content", "")
	if content is String and not (content as String).is_empty():
		return content as String
	var parts: Variant = msg.get("parts", null)
	if parts is Array:
		var text_parts: PackedStringArray = []
		for part_var in (parts as Array):
			if part_var is Dictionary:
				var part := part_var as Dictionary
				if part.has("text"):
					text_parts.append(str(part["text"]))
		if text_parts.size() > 0:
			return "\n".join(text_parts)
	return str(content)
static func _extract_sections_from_user_message(content: String) -> Array:
	var sections: Array = []
	var current_name := "(preamble)"
	var current_lines: PackedStringArray = []
	for line in content.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("===") and stripped.ends_with("===") and stripped.length() > 6:
			if current_lines.size() > 0:
				sections.append({"name": current_name, "content": "\n".join(current_lines).strip_edges()})
				current_lines = PackedStringArray()
			current_name = stripped.lstrip("=").rstrip("=").strip_edges()
		else:
			current_lines.append(line)
	if current_lines.size() > 0:
		sections.append({"name": current_name, "content": "\n".join(current_lines).strip_edges()})
	return sections
static func format_prompt_modules(entry: Dictionary) -> String:
	var request_body := str(entry.get("request_body", ""))
	var messages := _extract_messages_from_body(request_body)
	if messages.is_empty():
		return "(no detailed request data — enable \"Save Detailed AI Call Logs\" in settings)"
	var lines: PackedStringArray = []
	var msg_idx := 0
	for msg_var in messages:
		if not (msg_var is Dictionary):
			continue
		var msg := msg_var as Dictionary
		var role := str(msg.get("role", "unknown"))
		var content := _get_message_text(msg)
		msg_idx += 1
		if content.begins_with("[context:"):
			lines.append("[%d] %-12s → %s" % [msg_idx, role, content])
			continue
		if role == "user":
			lines.append("[%d] %-12s → USER MESSAGE (sections):" % [msg_idx, role])
			var sections := _extract_sections_from_user_message(content)
			for sec_var in sections:
				if not (sec_var is Dictionary):
					continue
				var sec := sec_var as Dictionary
				var sec_name := str(sec.get("name", ""))
				var sec_content := str(sec.get("content", ""))
				if sec_content.is_empty():
					lines.append("          § %s: (empty / not used)" % sec_name)
				else:
					var preview := sec_content
					if preview.length() > 300:
						preview = preview.substr(0, 300) + "…[truncated]"
					lines.append("          § %s:" % sec_name)
					for sub_line in preview.split("\n"):
						lines.append("              %s" % sub_line)
		else:
			var preview := content
			if preview.length() > 250:
				preview = preview.substr(0, 250) + "…[truncated]"
			lines.append("[%d] %-12s →" % [msg_idx, role])
			for sub_line in preview.split("\n"):
				lines.append("              %s" % sub_line)
	return "\n".join(lines)
static func extract_prompt_text(request_body: String) -> String:
	var messages := _extract_messages_from_body(request_body)
	var user_content := ""
	for msg_var in messages:
		if msg_var is Dictionary:
			var msg := msg_var as Dictionary
			if str(msg.get("role", "")) == "user":
				user_content = _get_message_text(msg)
	if user_content.is_empty():
		return ""
	var sections := _extract_sections_from_user_message(user_content)
	for sec_var in sections:
		if not (sec_var is Dictionary):
			continue
		var sec := sec_var as Dictionary
		var sec_name := str(sec.get("name", "")).to_upper()
		if "PROMPT" in sec_name:
			return str(sec.get("content", ""))
	return user_content
static func extract_active_modules_summary(request_body: String) -> String:
	var messages := _extract_messages_from_body(request_body)
	var active: PackedStringArray = []
	var sys_idx := 0
	for msg_var in messages:
		if not (msg_var is Dictionary):
			continue
		var msg := msg_var as Dictionary
		var role := str(msg.get("role", ""))
		var content := _get_message_text(msg)
		if content.begins_with("[context:") and " unchanged]" in content:
			continue
		if role == "system":
			if content.begins_with("[context:") and " updated," in content:
				var start := content.find(":") + 1
				var end := content.find(" updated,")
				if end > start:
					active.append(content.substr(start, end - start) + "(summarised)")
					continue
			sys_idx += 1
			active.append("system_%d" % sys_idx)
		elif role == "assistant" or role == "model":
			active.append("acknowledgement")
		elif role == "user":
			var sections := _extract_sections_from_user_message(content)
			for sec_var in sections:
				if not (sec_var is Dictionary):
					continue
				var sec := sec_var as Dictionary
				var sec_content := str(sec.get("content", ""))
				if not sec_content.is_empty():
					active.append(str(sec.get("name", "")))
	return ", ".join(active)
static func extract_ai_response_text(response_body: String) -> String:
	if response_body.is_empty():
		return ""
	var json := JSON.new()
	if json.parse(response_body) != OK:
		return response_body
	var data: Variant = json.data
	if not (data is Dictionary):
		return ""
	var d := data as Dictionary
	if d.has("choices"):
		var choices: Variant = d["choices"]
		if choices is Array and (choices as Array).size() > 0:
			var first_choice: Variant = (choices as Array)[0]
			if first_choice is Dictionary:
				var fc := first_choice as Dictionary
				var message: Variant = fc.get("message", null)
				if message is Dictionary:
					return str((message as Dictionary).get("content", ""))
	if d.has("candidates"):
		var candidates: Variant = d["candidates"]
		if candidates is Array and (candidates as Array).size() > 0:
			var first_cand: Variant = (candidates as Array)[0]
			if first_cand is Dictionary:
				var fc := first_cand as Dictionary
				var cand_content: Variant = fc.get("content", null)
				if cand_content is Dictionary:
					var parts: Variant = (cand_content as Dictionary).get("parts", null)
					if parts is Array and (parts as Array).size() > 0:
						var first_part: Variant = (parts as Array)[0]
						if first_part is Dictionary:
							return str((first_part as Dictionary).get("text", ""))
	if d.has("message"):
		var message: Variant = d.get("message", null)
		if message is Dictionary:
			return str((message as Dictionary).get("content", ""))
	return ""
static func _pretty_json_string(raw_text: String) -> String:
	var json := JSON.new()
	if json.parse(raw_text) == OK:
		return JSON.stringify(json.data, "\t")
	return raw_text
static func _format_timestamp(timestamp: String) -> String:
	var formatted := timestamp
	if formatted.length() > 19:
		formatted = formatted.substr(0, 19)
	return formatted.replace("T", " ")
