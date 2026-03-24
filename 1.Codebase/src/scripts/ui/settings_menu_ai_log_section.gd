extends RefCounted
class_name SettingsMenuAILogSection

const AIChartCanvas = preload("res://1.Codebase/src/scripts/ui/ai_chart_canvas.gd")

## Builds the AI log tab page and analytics content.
## Returns a Dictionary with all created node references.
## icons keys: history, options, refresh, save, delete, info, check, sync
## handlers keys: toggle_log, toggle_charts, refresh, export_json, export_csv,
##   clear, chart_size_changed, chart_visibility_toggled, tab_changed
static func build_log_page(
	tab_container: TabContainer,
	icons: Dictionary,
	tr_callable: Callable,
	initial_chart_width: float,
	initial_chart_height: float,
	handlers: Dictionary,
) -> Dictionary:
	var outer_vbox := VBoxContainer.new()
	outer_vbox.name = "AILogOuterVBox"
	outer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_theme_constant_override("separation", 4)
	tab_container.add_child(outer_vbox)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_top", 8)
	header_margin.add_theme_constant_override("margin_left", 14)
	header_margin.add_theme_constant_override("margin_right", 14)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(header_margin)
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 6)
	header_margin.add_child(header_hbox)
	var title_lbl := Label.new()
	title_lbl.name = "AILogTitle"
	title_lbl.text = tr_callable.call("SETTINGS_AI_LOG_TITLE", "AI Call Log")
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)
	var log_toggle := Button.new()
	log_toggle.name = "AILogToggleLog"
	log_toggle.text = tr_callable.call("SETTINGS_AI_LOG_TOGGLE_LOG", "Log")
	log_toggle.icon = icons.get("history") as Texture2D
	log_toggle.expand_icon = true
	log_toggle.toggle_mode = true
	log_toggle.button_pressed = true
	log_toggle.custom_minimum_size = Vector2(82, 32)
	log_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	log_toggle.pressed.connect(_get_handler(handlers, "toggle_log"))
	header_hbox.add_child(log_toggle)
	var charts_toggle := Button.new()
	charts_toggle.name = "AILogToggleCharts"
	charts_toggle.text = tr_callable.call("SETTINGS_AI_LOG_TOGGLE_CHARTS", "Charts")
	charts_toggle.icon = icons.get("options") as Texture2D
	charts_toggle.expand_icon = true
	charts_toggle.toggle_mode = true
	charts_toggle.button_pressed = false
	charts_toggle.custom_minimum_size = Vector2(92, 32)
	charts_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	charts_toggle.pressed.connect(_get_handler(handlers, "toggle_charts"))
	header_hbox.add_child(charts_toggle)
	var sep := VSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.25)
	sep.custom_minimum_size = Vector2(2, 28)
	header_hbox.add_child(sep)
	var refresh_btn := Button.new()
	refresh_btn.name = "AILogRefreshButton"
	refresh_btn.icon = icons.get("refresh") as Texture2D
	refresh_btn.expand_icon = true
	refresh_btn.tooltip_text = tr_callable.call("SETTINGS_AI_LOG_REFRESH_TOOLTIP", "Refresh")
	refresh_btn.custom_minimum_size = Vector2(36, 32)
	refresh_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	refresh_btn.pressed.connect(_get_handler(handlers, "refresh"))
	header_hbox.add_child(refresh_btn)
	var export_btn := Button.new()
	export_btn.name = "AILogExportButton"
	export_btn.icon = icons.get("save") as Texture2D
	export_btn.expand_icon = true
	export_btn.tooltip_text = tr_callable.call("SETTINGS_AI_LOG_EXPORT_JSON_TOOLTIP", "Export log to JSON")
	export_btn.custom_minimum_size = Vector2(36, 32)
	export_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	export_btn.pressed.connect(_get_handler(handlers, "export_json"))
	header_hbox.add_child(export_btn)
	var export_csv_btn := Button.new()
	export_csv_btn.name = "AILogExportCsvButton"
	export_csv_btn.text = tr_callable.call("SETTINGS_AI_LOG_EXPORT_CSV_SHORT", "CSV")
	export_csv_btn.icon = icons.get("save") as Texture2D
	export_csv_btn.expand_icon = true
	export_csv_btn.tooltip_text = tr_callable.call("SETTINGS_AI_LOG_EXPORT_CSV_TOOLTIP", "Export log and chart data to CSV")
	export_csv_btn.custom_minimum_size = Vector2(72, 32)
	export_csv_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	export_csv_btn.pressed.connect(_get_handler(handlers, "export_csv"))
	header_hbox.add_child(export_csv_btn)
	var clear_btn := Button.new()
	clear_btn.name = "AILogClearButton"
	clear_btn.icon = icons.get("delete") as Texture2D
	clear_btn.expand_icon = true
	clear_btn.tooltip_text = tr_callable.call("SETTINGS_AI_LOG_CLEAR_TOOLTIP", "Clear log")
	clear_btn.custom_minimum_size = Vector2(36, 32)
	clear_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clear_btn.pressed.connect(_get_handler(handlers, "clear"))
	header_hbox.add_child(clear_btn)
	var log_view := VBoxContainer.new()
	log_view.name = "AILogTableView"
	log_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_theme_constant_override("separation", 2)
	outer_vbox.add_child(log_view)
	var col_widths := [170, 90, 160, 70, 80, 80, 75, 90, 100]
	var col_names_en := ["Time", "Provider", "Model", "Status", "In Tok", "Out Tok", "Time(s)", "Mode", "Purpose"]
	var header_panel := PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.12, 0.22, 0.32, 1.0)
	header_style.set_corner_radius_all(4)
	header_style.border_width_bottom = 2
	header_style.border_color = Color(0.3, 0.6, 0.9, 0.6)
	header_panel.add_theme_stylebox_override("panel", header_style)
	var header_margin2 := MarginContainer.new()
	header_margin2.add_theme_constant_override("margin_top", 5)
	header_margin2.add_theme_constant_override("margin_left", 14)
	header_margin2.add_theme_constant_override("margin_right", 14)
	header_margin2.add_theme_constant_override("margin_bottom", 5)
	header_panel.add_child(header_margin2)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 4)
	header_margin2.add_child(header_row)
	for i in range(col_names_en.size()):
		var lbl := Label.new()
		lbl.text = col_names_en[i]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
		lbl.custom_minimum_size = Vector2(col_widths[i], 0)
		lbl.clip_text = true
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		header_row.add_child(lbl)
	log_view.add_child(header_panel)
	var log_scroll := ScrollContainer.new()
	log_scroll.name = "AILogScroll"
	log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_child(log_scroll)
	var log_rows_container := VBoxContainer.new()
	log_rows_container.name = "AILogRows"
	log_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_rows_container.add_theme_constant_override("separation", 2)
	log_scroll.add_child(log_rows_container)
	var empty_lbl := Label.new()
	empty_lbl.name = "AILogEmptyLabel"
	empty_lbl.text = tr_callable.call("SETTINGS_AI_LOG_EMPTY", "No AI calls recorded yet.")
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	empty_lbl.add_theme_font_size_override("font_size", 14)
	log_rows_container.add_child(empty_lbl)
	var analytics_scroll := ScrollContainer.new()
	analytics_scroll.name = "AIAnalyticsScroll"
	analytics_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	analytics_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	analytics_scroll.visible = false
	outer_vbox.add_child(analytics_scroll)
	var analytics_result := _build_analytics_content(
		analytics_scroll, icons, tr_callable,
		initial_chart_width, initial_chart_height, handlers
	)
	tab_container.tab_changed.connect(_get_handler(handlers, "tab_changed"))
	var result: Dictionary = {
		"outer_vbox": outer_vbox,
		"log_view_panel": log_view,
		"log_rows_container": log_rows_container,
		"analytics_view": analytics_scroll,
	}
	for key in analytics_result.keys():
		result[key] = analytics_result[key]
	return result

static func _build_analytics_content(
	parent_scroll: ScrollContainer,
	icons: Dictionary,
	tr_callable: Callable,
	initial_chart_width: float,
	initial_chart_height: float,
	handlers: Dictionary,
) -> Dictionary:
	var chart_rows: Array[Control] = []
	var chart_canvases: Array[Control] = []
	var kpi_labels: Array = []
	var av := VBoxContainer.new()
	av.name = "AIAnalyticsVBox"
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_theme_constant_override("separation", 12)
	parent_scroll.add_child(av)
	var am := MarginContainer.new()
	am.add_theme_constant_override("margin_top", 10)
	am.add_theme_constant_override("margin_left", 14)
	am.add_theme_constant_override("margin_right", 14)
	am.add_theme_constant_override("margin_bottom", 14)
	am.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_child(am)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	am.add_child(inner)
	var controls_row := HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 8)
	controls_row.custom_minimum_size = Vector2(0, 34)
	inner.add_child(controls_row)
	var controls_title := Label.new()
	controls_title.text = tr_callable.call("SETTINGS_AI_LOG_CHART_CONTROLS", "Chart Controls")
	controls_title.add_theme_font_size_override("font_size", 12)
	controls_title.add_theme_color_override("font_color", Color(0.7, 0.88, 1.0))
	controls_row.add_child(controls_title)
	var width_label := Label.new()
	width_label.text = "W"
	width_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	controls_row.add_child(width_label)
	var chart_width_spin := SpinBox.new()
	chart_width_spin.min_value = 260
	chart_width_spin.max_value = 1400
	chart_width_spin.step = 10
	chart_width_spin.value = initial_chart_width
	chart_width_spin.custom_minimum_size = Vector2(96, 0)
	chart_width_spin.value_changed.connect(_get_handler(handlers, "chart_size_changed"))
	controls_row.add_child(chart_width_spin)
	var height_label := Label.new()
	height_label.text = "H"
	height_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	controls_row.add_child(height_label)
	var chart_height_spin := SpinBox.new()
	chart_height_spin.min_value = 140
	chart_height_spin.max_value = 760
	chart_height_spin.step = 10
	chart_height_spin.value = initial_chart_height
	chart_height_spin.custom_minimum_size = Vector2(96, 0)
	chart_height_spin.value_changed.connect(_get_handler(handlers, "chart_size_changed"))
	controls_row.add_child(chart_height_spin)
	var chart_toggle_button := Button.new()
	chart_toggle_button.text = tr_callable.call("SETTINGS_AI_LOG_HIDE_GRAPHS", "Hide Graphs")
	chart_toggle_button.toggle_mode = true
	chart_toggle_button.button_pressed = true
	chart_toggle_button.custom_minimum_size = Vector2(118, 30)
	chart_toggle_button.pressed.connect(_get_handler(handlers, "chart_visibility_toggled"))
	controls_row.add_child(chart_toggle_button)
	var controls_sep := VSeparator.new()
	controls_sep.custom_minimum_size = Vector2(2, 22)
	controls_sep.modulate = Color(1, 1, 1, 0.2)
	controls_row.add_child(controls_sep)
	var export_csv_btn2 := Button.new()
	export_csv_btn2.text = tr_callable.call("SETTINGS_AI_LOG_EXPORT_CSV", "Export CSV")
	export_csv_btn2.icon = icons.get("save") as Texture2D
	export_csv_btn2.expand_icon = true
	export_csv_btn2.custom_minimum_size = Vector2(120, 30)
	export_csv_btn2.pressed.connect(_get_handler(handlers, "export_csv"))
	controls_row.add_child(export_csv_btn2)
	var controls_spacer := Control.new()
	controls_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_row.add_child(controls_spacer)
	var kpi_hbox := HBoxContainer.new()
	kpi_hbox.add_theme_constant_override("separation", 8)
	kpi_hbox.custom_minimum_size = Vector2(0, 78)
	inner.add_child(kpi_hbox)
	var kpi_icons: Array[Texture2D] = [
		icons.get("info") as Texture2D,
		icons.get("check") as Texture2D,
		icons.get("sync") as Texture2D,
		icons.get("refresh") as Texture2D,
	]
	var kpi_titles := [
		tr_callable.call("SETTINGS_AI_LOG_KPI_TOTAL_CALLS", "Total Calls"),
		tr_callable.call("SETTINGS_AI_LOG_KPI_SUCCESS_RATE", "Success Rate"),
		tr_callable.call("SETTINGS_AI_LOG_KPI_TOTAL_TOKENS", "Total Tokens"),
		tr_callable.call("SETTINGS_AI_LOG_KPI_AVG_RESPONSE", "Avg Response"),
	]
	var kpi_defaults := ["0", "0%", "0", "0s"]
	var kpi_accent_colors: Array[Color] = [
		Color(0.4, 0.75, 1.0), Color(0.35, 0.92, 0.55),
		Color(1.0, 0.80, 0.30), Color(0.85, 0.60, 1.0),
	]
	for i in range(kpi_titles.size()):
		var kpi_panel := PanelContainer.new()
		kpi_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kpi_style := StyleBoxFlat.new()
		kpi_style.bg_color = Color(0.09, 0.14, 0.22, 1.0)
		kpi_style.set_corner_radius_all(8)
		kpi_style.border_width_bottom = 3
		kpi_style.border_color = kpi_accent_colors[i]
		kpi_panel.add_theme_stylebox_override("panel", kpi_style)
		var kpi_inner := VBoxContainer.new()
		kpi_inner.alignment = BoxContainer.ALIGNMENT_CENTER
		kpi_inner.add_theme_constant_override("separation", 3)
		kpi_panel.add_child(kpi_inner)
		var icon_row := HBoxContainer.new()
		icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
		icon_row.add_theme_constant_override("separation", 4)
		kpi_inner.add_child(icon_row)
		var icon_rect := TextureRect.new()
		icon_rect.texture = kpi_icons[i]
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.modulate = kpi_accent_colors[i]
		icon_row.add_child(icon_rect)
		var kpi_title := Label.new()
		kpi_title.text = kpi_titles[i]
		kpi_title.add_theme_font_size_override("font_size", 10)
		kpi_title.add_theme_color_override("font_color", kpi_accent_colors[i])
		kpi_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kpi_title.autowrap_mode = TextServer.AUTOWRAP_WORD
		icon_row.add_child(kpi_title)
		var kpi_val := Label.new()
		kpi_val.text = kpi_defaults[i]
		kpi_val.add_theme_font_size_override("font_size", 20)
		kpi_val.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		kpi_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kpi_inner.add_child(kpi_val)
		kpi_hbox.add_child(kpi_panel)
		kpi_labels.append(kpi_val)
	_add_section_header(inner, icons.get("check") as Texture2D,
		tr_callable.call("SETTINGS_AI_LOG_HDR_PROVIDER_SUCCESS", "Provider Success Rate"))
	chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	row1.custom_minimum_size = Vector2(0, initial_chart_height)
	inner.add_child(row1)
	chart_rows.append(row1)
	var chart_success_by_provider: Control = _make_chart_canvas(
		row1, AIChartCanvas.Type.HORIZONTAL_BAR, "Success Rate by Provider (%)",
		initial_chart_width, initial_chart_height, chart_canvases)
	var chart_mode_pie: Control = _make_chart_canvas(
		row1, AIChartCanvas.Type.PIE, "Call Mode Distribution",
		initial_chart_width, initial_chart_height, chart_canvases)
	_add_section_header(inner, icons.get("history") as Texture2D,
		tr_callable.call("SETTINGS_AI_LOG_HDR_REQUESTS_TIMELINE", "Requests Timeline (last 24 h)"))
	chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row2 := HBoxContainer.new()
	row2.custom_minimum_size = Vector2(0, initial_chart_height)
	inner.add_child(row2)
	chart_rows.append(row2)
	var chart_hourly_requests: Control = _make_chart_canvas(
		row2, AIChartCanvas.Type.VERTICAL_BAR, "Requests / Hour (last 24 h)",
		initial_chart_width, initial_chart_height, chart_canvases)
	_add_section_header(inner, icons.get("info") as Texture2D,
		tr_callable.call("SETTINGS_AI_LOG_HDR_SUCCESS_ERROR", "Success / Error per Hour"))
	chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 10)
	row3.custom_minimum_size = Vector2(0, initial_chart_height)
	inner.add_child(row3)
	chart_rows.append(row3)
	var chart_success_per_hour: Control = _make_chart_canvas(
		row3, AIChartCanvas.Type.LINE, "Success Count / Hour (last 24 h)",
		initial_chart_width, initial_chart_height, chart_canvases)
	var chart_calls_by_model: Control = _make_chart_canvas(
		row3, AIChartCanvas.Type.HORIZONTAL_BAR, "Calls by Model",
		initial_chart_width, initial_chart_height, chart_canvases)
	_add_section_header(inner, icons.get("sync") as Texture2D,
		tr_callable.call("SETTINGS_AI_LOG_HDR_TOKEN_LATENCY", "Token and Latency by Provider"))
	chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row4 := HBoxContainer.new()
	row4.add_theme_constant_override("separation", 10)
	row4.custom_minimum_size = Vector2(0, initial_chart_height)
	inner.add_child(row4)
	chart_rows.append(row4)
	var chart_tokens_by_provider: Control = _make_chart_canvas(
		row4, AIChartCanvas.Type.HORIZONTAL_BAR, "Total Tokens by Provider",
		initial_chart_width, initial_chart_height, chart_canvases)
	var chart_response_by_provider: Control = _make_chart_canvas(
		row4, AIChartCanvas.Type.HORIZONTAL_BAR, "Avg Response Time / Provider (s)",
		initial_chart_width, initial_chart_height, chart_canvases)
	_add_section_header(inner, icons.get("options") as Texture2D,
		tr_callable.call("SETTINGS_AI_LOG_HDR_TOKEN_BREAKDOWN", "Token Breakdown and Speed"))
	chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row5 := HBoxContainer.new()
	row5.add_theme_constant_override("separation", 10)
	row5.custom_minimum_size = Vector2(0, initial_chart_height)
	inner.add_child(row5)
	chart_rows.append(row5)
	var chart_input_output_tokens: Control = _make_chart_canvas(
		row5, AIChartCanvas.Type.VERTICAL_BAR, "Input vs Output Tokens by Provider",
		initial_chart_width, initial_chart_height, chart_canvases)
	var chart_tps_by_provider: Control = _make_chart_canvas(
		row5, AIChartCanvas.Type.HORIZONTAL_BAR, "Avg Tokens / Second by Provider (TPS)",
		initial_chart_width, initial_chart_height, chart_canvases)
	_add_section_header(inner, icons.get("refresh") as Texture2D,
		tr_callable.call("SETTINGS_AI_LOG_HDR_TOKEN_TRENDS", "Token Trends (last 24 h)"))
	chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row6 := HBoxContainer.new()
	row6.custom_minimum_size = Vector2(0, initial_chart_height)
	inner.add_child(row6)
	chart_rows.append(row6)
	var chart_hourly_tokens: Control = _make_chart_canvas(
		row6, AIChartCanvas.Type.LINE, "Token Usage / Hour (last 24 h)",
		initial_chart_width, initial_chart_height, chart_canvases)
	var row7 := HBoxContainer.new()
	row7.custom_minimum_size = Vector2(0, initial_chart_height)
	inner.add_child(row7)
	chart_rows.append(row7)
	var chart_cumulative_tokens: Control = _make_chart_canvas(
		row7, AIChartCanvas.Type.LINE, "Cumulative Total Tokens (session)",
		initial_chart_width, initial_chart_height, chart_canvases)
	return {
		"chart_toggle_button": chart_toggle_button,
		"chart_width_spin": chart_width_spin,
		"chart_height_spin": chart_height_spin,
		"kpi_labels": kpi_labels,
		"chart_rows": chart_rows,
		"chart_canvases": chart_canvases,
		"chart_success_by_provider": chart_success_by_provider,
		"chart_mode_pie": chart_mode_pie,
		"chart_hourly_requests": chart_hourly_requests,
		"chart_success_per_hour": chart_success_per_hour,
		"chart_calls_by_model": chart_calls_by_model,
		"chart_tokens_by_provider": chart_tokens_by_provider,
		"chart_response_by_provider": chart_response_by_provider,
		"chart_input_output_tokens": chart_input_output_tokens,
		"chart_tps_by_provider": chart_tps_by_provider,
		"chart_hourly_tokens": chart_hourly_tokens,
		"chart_cumulative_tokens": chart_cumulative_tokens,
	}

static func _add_section_header(parent: Control, icon_tex: Texture2D, text: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.custom_minimum_size = Vector2(0, 24)
	parent.add_child(hbox)
	var icon_rect := TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.custom_minimum_size = Vector2(18, 18)
	icon_rect.modulate = Color(0.55, 0.82, 1.0)
	hbox.add_child(icon_rect)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.88, 1.0))
	hbox.add_child(lbl)
	var sep := HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.modulate = Color(1, 1, 1, 0.15)
	hbox.add_child(sep)

static func _make_chart_canvas(
	parent: Control,
	chart_type: int,
	title: String,
	width: float,
	height: float,
	canvases: Array[Control],
) -> Control:
	var canvas := AIChartCanvas.new()
	canvas.chart_type = chart_type
	canvas.chart_title = title
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(width, height)
	parent.add_child(canvas)
	canvases.append(canvas)
	return canvas

static func _get_handler(handlers: Dictionary, key: String) -> Callable:
	if handlers.has(key):
		var val: Variant = handlers[key]
		if val is Callable:
			return val as Callable
	return Callable()

## Applies localized text to all named widgets inside the AI-log tab root.
## tr_fn  – Callable(key: String, fallback: String) -> String
## ai_log_ctrl – the SettingsMenuAILogController instance (may be null)
static func normalize_language_texts(root: Node, tr_fn: Callable, ai_log_ctrl: Object) -> void:
	if root == null:
		return
	var title := root.find_child("AILogTitle", true, false) as Label
	if title:
		title.text = tr_fn.call("SETTINGS_AI_LOG_TITLE", "AI Call Log")
	var toggle_log := root.find_child("AILogToggleLog", true, false) as Button
	if toggle_log:
		toggle_log.text = tr_fn.call("SETTINGS_AI_LOG_TOGGLE_LOG", "Log")
	var toggle_charts := root.find_child("AILogToggleCharts", true, false) as Button
	if toggle_charts:
		toggle_charts.text = tr_fn.call("SETTINGS_AI_LOG_TOGGLE_CHARTS", "Charts")
	var refresh_btn := root.find_child("AILogRefreshButton", true, false) as Button
	if refresh_btn:
		refresh_btn.tooltip_text = tr_fn.call("SETTINGS_AI_LOG_REFRESH_TOOLTIP", "Refresh")
	var export_btn := root.find_child("AILogExportButton", true, false) as Button
	if export_btn:
		export_btn.tooltip_text = tr_fn.call("SETTINGS_AI_LOG_EXPORT_JSON_TOOLTIP", "Export log to JSON")
	var export_csv_btn := root.find_child("AILogExportCsvButton", true, false) as Button
	if export_csv_btn:
		export_csv_btn.text = tr_fn.call("SETTINGS_AI_LOG_EXPORT_CSV_SHORT", "CSV")
		export_csv_btn.tooltip_text = tr_fn.call("SETTINGS_AI_LOG_EXPORT_CSV_TOOLTIP", "Export log and chart data to CSV")
	var clear_btn := root.find_child("AILogClearButton", true, false) as Button
	if clear_btn:
		clear_btn.tooltip_text = tr_fn.call("SETTINGS_AI_LOG_CLEAR_TOOLTIP", "Clear log")
	var empty_lbl := root.find_child("AILogEmptyLabel", true, false) as Label
	if empty_lbl:
		empty_lbl.text = tr_fn.call("SETTINGS_AI_LOG_EMPTY", "No AI calls recorded yet.")
	if ai_log_ctrl != null and is_instance_valid(ai_log_ctrl):
		var toggle_btn = ai_log_ctrl.get("_ai_chart_toggle_button")
		if toggle_btn != null and is_instance_valid(toggle_btn):
			var charts_open = ai_log_ctrl.get("_ai_charts_open")
			toggle_btn.text = (
				tr_fn.call("SETTINGS_AI_LOG_HIDE_GRAPHS", "Hide Graphs")
				if charts_open else
				tr_fn.call("SETTINGS_AI_LOG_SHOW_GRAPHS", "Show Graphs")
			)
