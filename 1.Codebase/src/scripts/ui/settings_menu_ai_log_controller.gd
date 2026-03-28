extends RefCounted
class_name SettingsMenuAILogController
const SettingsMenuAILogRendererScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_renderer.gd")
const SettingsMenuAILogExportScript   = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_export.gd")
const SettingsMenuAIAnalyticsScript   = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_analytics.gd")
var _ai_log_rows_container: VBoxContainer = null
var _ai_log_view_panel: Control = null
var _ai_analytics_view: Control = null
var _ai_save_details_check: CheckBox = null
var _ai_detail_dialog: AcceptDialog = null
var _ai_detail_text: TextEdit = null
var _ai_detail_copy_all_btn: Button = null
var _ai_detail_copy_request_btn: Button = null
var _ai_detail_copy_response_btn: Button = null
var _ai_chart_toggle_button: Button = null
var _ai_chart_width_spin: SpinBox = null
var _ai_chart_height_spin: SpinBox = null
var _ai_kpi_labels: Array = []
var _ai_chart_rows: Array[Control] = []
var _ai_chart_canvases: Array[Control] = []
var _chart_success_by_provider: Control = null
var _chart_mode_pie: Control = null
var _chart_hourly_requests: Control = null
var _chart_tokens_by_provider: Control = null
var _chart_response_by_provider: Control = null
var _chart_hourly_tokens: Control = null
var _chart_input_output_tokens: Control = null
var _chart_success_per_hour: Control = null
var _chart_tps_by_provider: Control = null
var _chart_cumulative_tokens: Control = null
var _chart_calls_by_model: Control = null
var _ai_showing_charts: bool = false
var _ai_charts_open: bool = true
var _ai_chart_width: float = 480.0
var _ai_chart_height: float = 190.0
var _tab_container: TabContainer = null  
var _tr_fn: Callable                      
var _selected_log_entry: Dictionary = { }
func initialize(
	result: Dictionary,
	chart_width: float,
	chart_height: float,
	tab_container: TabContainer,
	tr_fn: Callable,
) -> void:
	_ai_chart_width  = chart_width
	_ai_chart_height = chart_height
	_tab_container   = tab_container
	_tr_fn           = tr_fn
	_ai_log_view_panel    = result["log_view_panel"]     as Control
	_ai_log_rows_container = result["log_rows_container"] as VBoxContainer
	_ai_analytics_view    = result["analytics_view"]     as Control
	_ai_save_details_check = result.get("save_details_check") as CheckBox
	_ai_detail_dialog = result.get("detail_dialog") as AcceptDialog
	_ai_detail_text = result.get("detail_text") as TextEdit
	_ai_detail_copy_all_btn = result.get("detail_copy_all_btn") as Button
	_ai_detail_copy_request_btn = result.get("detail_copy_request_btn") as Button
	_ai_detail_copy_response_btn = result.get("detail_copy_response_btn") as Button
	_ai_chart_toggle_button = result["chart_toggle_button"] as Button
	_ai_chart_width_spin  = result["chart_width_spin"]   as SpinBox
	_ai_chart_height_spin = result["chart_height_spin"]  as SpinBox
	var kpi_raw: Variant = result["kpi_labels"]
	if kpi_raw is Array:
		_ai_kpi_labels = kpi_raw
	_ai_chart_rows.assign(result["chart_rows"])
	_ai_chart_canvases.assign(result["chart_canvases"])
	_chart_success_by_provider  = result["chart_success_by_provider"]  as Control
	_chart_mode_pie             = result["chart_mode_pie"]             as Control
	_chart_hourly_requests      = result["chart_hourly_requests"]      as Control
	_chart_success_per_hour     = result["chart_success_per_hour"]     as Control
	_chart_calls_by_model       = result["chart_calls_by_model"]       as Control
	_chart_tokens_by_provider   = result["chart_tokens_by_provider"]   as Control
	_chart_response_by_provider = result["chart_response_by_provider"] as Control
	_chart_input_output_tokens  = result["chart_input_output_tokens"]  as Control
	_chart_tps_by_provider      = result["chart_tps_by_provider"]      as Control
	_chart_hourly_tokens        = result["chart_hourly_tokens"]        as Control
	_chart_cumulative_tokens    = result["chart_cumulative_tokens"]    as Control
	var ai_manager: Node = ServiceLocator.get_ai_manager() if ServiceLocator else null
	if is_instance_valid(_ai_save_details_check) and ai_manager != null:
		var enabled := bool(ai_manager.get("save_detailed_ai_call_logs"))
		if _ai_save_details_check.has_method("set_pressed_no_signal"):
			_ai_save_details_check.call("set_pressed_no_signal", enabled)
		else:
			_ai_save_details_check.button_pressed = enabled
	_apply_ai_chart_layout()
func _on_ai_log_tab_changed(tab_idx: int) -> void:
	if _tab_container and tab_idx == _tab_container.get_tab_count() - 1:
		_refresh_ai_log_table()
		if _ai_showing_charts:
			_refresh_analytics_view()
func _on_ai_log_toggle_log_pressed() -> void:
	_ai_showing_charts = false
	if _ai_log_view_panel:
		_ai_log_view_panel.visible = true
	if _ai_analytics_view:
		_ai_analytics_view.visible = false
	_refresh_ai_log_table()
func _on_ai_log_toggle_charts_pressed() -> void:
	_ai_showing_charts = true
	if _ai_log_view_panel:
		_ai_log_view_panel.visible = false
	if _ai_analytics_view:
		_ai_analytics_view.visible = true
	_refresh_analytics_view()
func _on_ai_log_refresh_pressed() -> void:
	if _ai_showing_charts:
		_refresh_analytics_view()
	else:
		_refresh_ai_log_table()
func _on_ai_export_pressed() -> void:
	var ai_manager: Node = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	var metrics: Dictionary = {}
	if ai_manager and ai_manager.has_method("get_ai_metrics"):
		metrics = ai_manager.get_ai_metrics()
	var notifier: Node = ServiceLocator.get_notification_system() if ServiceLocator else null
	SettingsMenuAILogExportScript.export_json(log_entries, metrics, _tr_fn, notifier)
func _on_ai_export_csv_pressed() -> void:
	var ai_manager: Node = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	var notifier: Node = ServiceLocator.get_notification_system() if ServiceLocator else null
	SettingsMenuAILogExportScript.export_csv(log_entries, _tr_fn, notifier)
func _on_ai_chart_size_changed(_value: float) -> void:
	if is_instance_valid(_ai_chart_width_spin):
		_ai_chart_width = maxf(260.0, float(_ai_chart_width_spin.value))
	if is_instance_valid(_ai_chart_height_spin):
		_ai_chart_height = maxf(140.0, float(_ai_chart_height_spin.value))
	_apply_ai_chart_layout()
func _on_ai_chart_visibility_toggled() -> void:
	_ai_charts_open = _ai_chart_toggle_button.button_pressed if is_instance_valid(_ai_chart_toggle_button) else true
	_apply_ai_chart_layout()
func _on_ai_log_clear_pressed() -> void:
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else null
	if ai_manager and ai_manager.has_method("clear_call_log"):
		ai_manager.clear_call_log()
	if _ai_showing_charts:
		_refresh_analytics_view()
	else:
		_refresh_ai_log_table()
func _refresh_analytics_view() -> void:
	var ai_manager: Node = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	SettingsMenuAILogRendererScript.refresh_analytics({
		"success_by_provider":  _chart_success_by_provider,
		"mode_pie":             _chart_mode_pie,
		"hourly_requests":      _chart_hourly_requests,
		"success_per_hour":     _chart_success_per_hour,
		"calls_by_model":       _chart_calls_by_model,
		"tokens_by_provider":   _chart_tokens_by_provider,
		"response_by_provider": _chart_response_by_provider,
		"input_output_tokens":  _chart_input_output_tokens,
		"tps_by_provider":      _chart_tps_by_provider,
		"hourly_tokens":        _chart_hourly_tokens,
		"cumulative_tokens":    _chart_cumulative_tokens,
	}, _ai_kpi_labels, log_entries)
func _refresh_ai_log_table() -> void:
	var ai_manager: Node = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	SettingsMenuAILogRendererScript.refresh_table(
		_ai_log_rows_container,
		log_entries,
		_tr_fn,
		Callable(self, "_on_ai_log_entry_selected"),
	)
func _apply_ai_chart_layout() -> void:
	for row in _ai_chart_rows:
		if is_instance_valid(row):
			row.visible = _ai_charts_open
			if row is HBoxContainer:
				row.custom_minimum_size = Vector2(0, _ai_chart_height)
	for canvas in _ai_chart_canvases:
		if is_instance_valid(canvas):
			canvas.visible = _ai_charts_open
			canvas.custom_minimum_size = Vector2(_ai_chart_width, _ai_chart_height)
	if is_instance_valid(_ai_chart_toggle_button):
		_ai_chart_toggle_button.text = (
			_tr_fn.call("SETTINGS_AI_LOG_HIDE_GRAPHS", "Hide Graphs")
			if _ai_charts_open else
			_tr_fn.call("SETTINGS_AI_LOG_SHOW_GRAPHS", "Show Graphs")
		)
func _on_ai_log_entry_selected(entry: Dictionary) -> void:
	_selected_log_entry = entry.duplicate(true)
	print(
		"[Godot-Cmd-Debug] AI Log UI - open detail provider=%s purpose=%s status=%s" %
		[
			str(entry.get("provider", "")),
			str(entry.get("purpose", "")),
			str(entry.get("status_code", "")),
		]
	)
	if not is_instance_valid(_ai_detail_dialog) or not is_instance_valid(_ai_detail_text):
		return
	_ai_detail_text.text = SettingsMenuAILogRendererScript.format_detail_text(_selected_log_entry, _tr_fn)
	if is_instance_valid(_ai_detail_copy_request_btn):
		_ai_detail_copy_request_btn.disabled = str(_selected_log_entry.get("request_body", "")).is_empty()
	if is_instance_valid(_ai_detail_copy_response_btn):
		_ai_detail_copy_response_btn.disabled = str(_selected_log_entry.get("response_body", "")).is_empty()
	_ai_detail_dialog.popup_centered(Vector2i(1160, 760))
func _on_ai_log_copy_all_pressed() -> void:
	if is_instance_valid(_ai_detail_text):
		print("[Godot-Cmd-Debug] AI Log UI - copy all detail text")
		DisplayServer.clipboard_set(_ai_detail_text.text)
func _on_ai_log_copy_request_pressed() -> void:
	if not _selected_log_entry.is_empty():
		print("[Godot-Cmd-Debug] AI Log UI - copy request body")
		DisplayServer.clipboard_set(SettingsMenuAILogRendererScript.format_request_body(_selected_log_entry))
func _on_ai_log_copy_response_pressed() -> void:
	if not _selected_log_entry.is_empty():
		print("[Godot-Cmd-Debug] AI Log UI - copy response body")
		DisplayServer.clipboard_set(SettingsMenuAILogRendererScript.format_response_body(_selected_log_entry))
func _on_ai_log_save_details_toggled(button_pressed: bool) -> void:
	var ai_manager: Node = ServiceLocator.get_ai_manager() if ServiceLocator else null
	if ai_manager == null:
		return
	ai_manager.set("save_detailed_ai_call_logs", button_pressed)
	if ai_manager.has_method("save_ai_settings"):
		ai_manager.save_ai_settings()
	print("[Godot-Cmd-Debug] AI Log UI - save detailed logs toggled: %s" % ("ON" if button_pressed else "OFF"))
