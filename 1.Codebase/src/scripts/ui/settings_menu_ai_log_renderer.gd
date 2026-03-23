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
		container.add_child(row_panel)
