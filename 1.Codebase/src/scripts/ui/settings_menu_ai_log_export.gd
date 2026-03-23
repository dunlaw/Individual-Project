extends RefCounted
class_name SettingsMenuAILogExport

## Exports log_entries + metrics to a timestamped JSON file.
## notifier: Node with show_success(msg)/show_warning(msg) methods (may be null).
static func export_json(
	log_entries: Array,
	metrics: Dictionary,
	tr_callable: Callable,
	notifier: Node,
) -> void:
	var ts: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path: String = "user://ai_call_log_%s.json" % ts
	var export_data: Dictionary = {
		"exported_at": Time.get_datetime_string_from_system(),
		"summary": metrics,
		"call_log": log_entries,
	}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data, "\t"))
		file.close()
		var abs_path: String = ProjectSettings.globalize_path(path)
		if notifier:
			var msg: String = tr_callable.call("SETTINGS_AI_LOG_EXPORT_JSON_SUCCESS", "Exported %d records to:\n%s") % [log_entries.size(), abs_path]
			notifier.show_success(msg)
	else:
		if notifier:
			var msg: String = tr_callable.call("SETTINGS_AI_LOG_EXPORT_JSON_FAILED", "Export failed: could not write file.")
			notifier.show_warning(msg)

## Exports log_entries and computed chart data to a timestamped CSV file.
static func export_csv(
	log_entries: Array,
	tr_callable: Callable,
	notifier: Node,
) -> void:
	var analytics: Dictionary = SettingsMenuAIAnalytics.compute_analytics(log_entries)
	var ts: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path: String = "user://ai_usage_charts_%s.csv" % ts
	var lines: PackedStringArray = []
	lines.append("section,timestamp,provider,model,status,input_tokens,output_tokens,response_time_sec,mode,purpose,error")
	for entry in log_entries:
		var status_text: String = "ERR"
		if bool(entry.get("success", false)):
			status_text = str(int(entry.get("status_code", 200)))
		elif str(entry.get("mode", "")) in ["mock", "mock_fallback"]:
			status_text = "MOCK"
		lines.append(SettingsMenuAIAnalytics.csv_row([
			"call_log",
			str(entry.get("timestamp", "")),
			str(entry.get("provider", "")),
			str(entry.get("model", "")),
			status_text,
			str(int(entry.get("input_tokens", 0))),
			str(int(entry.get("output_tokens", 0))),
			"%.3f" % float(entry.get("response_time_sec", 0.0)),
			str(entry.get("mode", "")),
			str(entry.get("purpose", "")),
			str(entry.get("error", "")),
		]))
	lines.append("")
	lines.append("section,metric,label,value")
	SettingsMenuAIAnalytics.append_metric_series(lines, "provider_success_rate", analytics.get("provider_labels", []), analytics.get("provider_success_rates", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "provider_total_tokens", analytics.get("provider_labels", []), analytics.get("provider_tokens", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "provider_avg_response_seconds", analytics.get("provider_labels", []), analytics.get("provider_response_times", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "provider_input_tokens", analytics.get("provider_labels", []), analytics.get("provider_input_tokens", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "provider_output_tokens", analytics.get("provider_labels", []), analytics.get("provider_output_tokens", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "provider_tps", analytics.get("provider_labels", []), analytics.get("provider_tps", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "mode_distribution", analytics.get("mode_labels", []), analytics.get("mode_counts", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "model_calls", analytics.get("model_labels", []), analytics.get("model_counts", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "hourly_calls", analytics.get("hourly_labels", []), analytics.get("hourly_calls", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "hourly_tokens", analytics.get("hourly_labels", []), analytics.get("hourly_tokens", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "hourly_successes", analytics.get("hourly_labels", []), analytics.get("hourly_successes", []))
	SettingsMenuAIAnalytics.append_metric_series(lines, "cumulative_tokens", analytics.get("cumulative_labels", []), analytics.get("cumulative_tokens", []))
	lines.append(SettingsMenuAIAnalytics.csv_row(["summary", "total_calls", "", str(int(analytics.get("total", 0)))]))
	lines.append(SettingsMenuAIAnalytics.csv_row(["summary", "success_rate_percent", "", "%.2f" % float(analytics.get("success_rate", 0.0))]))
	lines.append(SettingsMenuAIAnalytics.csv_row(["summary", "total_tokens", "", str(int(analytics.get("total_tokens", 0)))]))
	lines.append(SettingsMenuAIAnalytics.csv_row(["summary", "avg_response_seconds", "", "%.3f" % float(analytics.get("avg_response_time", 0.0))]))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
		file.close()
		var abs_path: String = ProjectSettings.globalize_path(path)
		if notifier:
			notifier.show_success(tr_callable.call("SETTINGS_AI_LOG_EXPORT_CSV_SUCCESS", "CSV exported:\n%s") % abs_path)
	else:
		if notifier:
			notifier.show_warning(tr_callable.call("SETTINGS_AI_LOG_EXPORT_CSV_FAILED", "CSV export failed: could not write file."))
