extends RefCounted
class_name SettingsMenuAIAnalytics

## Analyses an array of AI log entry dictionaries and returns aggregated metrics.
## Pure computation — no UI or state dependencies.
static func compute_analytics(log_entries: Array) -> Dictionary:
	var total := log_entries.size()
	var total_success := 0
	var total_tokens := 0
	var total_time := 0.0
	var by_provider: Dictionary = {}
	var by_mode: Dictionary = {}
	var by_model: Dictionary = {}
	var hourly: Dictionary = {}
	var now_unix := Time.get_unix_time_from_system()
	var cumulative_running := 0
	var cumulative_labels: Array = []
	var cumulative_tokens: Array = []
	for idx in range(log_entries.size()):
		var entry: Dictionary = log_entries[idx]
		var success := bool(entry.get("success", false))
		var in_tok := int(entry.get("input_tokens", 0))
		var out_tok := int(entry.get("output_tokens", 0))
		var tokens := in_tok + out_tok
		var rtime := float(entry.get("response_time_sec", 0.0))
		var provider := str(entry.get("provider", "UNKNOWN"))
		var model := str(entry.get("model", "UNKNOWN"))
		var mode := str(entry.get("mode", "unknown"))
		var ts_str := str(entry.get("timestamp", "")).replace("T", " ")
		if success:
			total_success += 1
		total_tokens += tokens
		total_time += rtime
		if not by_provider.has(provider):
			by_provider[provider] = {
				"calls": 0, "success": 0, "tokens": 0,
				"input_tokens": 0, "output_tokens": 0,
				"response_time": 0.0, "output_tokens_for_tps": 0, "tps_time": 0.0,
			}
		by_provider[provider]["calls"] = int(by_provider[provider]["calls"]) + 1
		if success:
			by_provider[provider]["success"] = int(by_provider[provider]["success"]) + 1
		by_provider[provider]["tokens"] = int(by_provider[provider]["tokens"]) + tokens
		by_provider[provider]["input_tokens"] = int(by_provider[provider]["input_tokens"]) + in_tok
		by_provider[provider]["output_tokens"] = int(by_provider[provider]["output_tokens"]) + out_tok
		by_provider[provider]["response_time"] = float(by_provider[provider]["response_time"]) + rtime
		if rtime > 0.0 and out_tok > 0:
			by_provider[provider]["output_tokens_for_tps"] = int(by_provider[provider]["output_tokens_for_tps"]) + out_tok
			by_provider[provider]["tps_time"] = float(by_provider[provider]["tps_time"]) + rtime
		by_mode[mode] = int(by_mode.get(mode, 0)) + 1
		by_model[model] = int(by_model.get(model, 0)) + 1
		if ts_str.length() >= 10:
			var entry_unix := Time.get_unix_time_from_datetime_string(ts_str)
			if entry_unix > 0:
				var hours_ago := (now_unix - entry_unix) / 3600.0
				if hours_ago >= 0.0 and hours_ago < 24.0:
					var bucket := int(hours_ago)
					if not hourly.has(bucket):
						hourly[bucket] = {"calls": 0, "tokens": 0, "successes": 0}
					hourly[bucket]["calls"] = int(hourly[bucket]["calls"]) + 1
					hourly[bucket]["tokens"] = int(hourly[bucket]["tokens"]) + tokens
					if success:
						hourly[bucket]["successes"] = int(hourly[bucket]["successes"]) + 1
		cumulative_running += tokens
		cumulative_labels.append(str(idx + 1))
		cumulative_tokens.append(float(cumulative_running))
	var provider_labels: Array = []
	var provider_success_rates: Array = []
	var provider_tokens: Array = []
	var provider_input_tokens: Array = []
	var provider_output_tokens: Array = []
	var provider_response_times: Array = []
	var provider_tps: Array = []
	for prov in by_provider.keys():
		var p: Dictionary = by_provider[prov]
		var calls := int(p.get("calls", 0))
		provider_labels.append(prov)
		provider_success_rates.append(float(p.get("success", 0)) / float(max(1, calls)) * 100.0)
		provider_tokens.append(float(p.get("tokens", 0)))
		provider_input_tokens.append(float(p.get("input_tokens", 0)))
		provider_output_tokens.append(float(p.get("output_tokens", 0)))
		provider_response_times.append(float(p.get("response_time", 0.0)) / float(max(1, calls)))
		var tps_out := int(p.get("output_tokens_for_tps", 0))
		var tps_t := float(p.get("tps_time", 0.0))
		provider_tps.append(float(tps_out) / max(0.001, tps_t))
	var hourly_labels: Array = []
	var hourly_calls: Array = []
	var hourly_tokens: Array = []
	var hourly_successes: Array = []
	for h in range(23, -1, -1):
		var d: Dictionary = hourly.get(h, {"calls": 0, "tokens": 0, "successes": 0})
		hourly_labels.insert(0, "%dh" % h if h > 0 else "now")
		hourly_calls.insert(0, float(d.get("calls", 0)))
		hourly_tokens.insert(0, float(d.get("tokens", 0)))
		hourly_successes.insert(0, float(d.get("successes", 0)))
	var mode_labels: Array = []
	var mode_counts: Array = []
	for m in by_mode.keys():
		mode_labels.append(m)
		mode_counts.append(float(by_mode[m]))
	var model_labels: Array = []
	var model_counts: Array = []
	for mdl in by_model.keys():
		model_labels.append(mdl)
		model_counts.append(float(by_model[mdl]))
	return {
		"total": total,
		"total_success": total_success,
		"success_rate": float(total_success) / float(max(1, total)) * 100.0,
		"total_tokens": total_tokens,
		"avg_response_time": total_time / float(max(1, total)),
		"provider_labels": provider_labels,
		"provider_success_rates": provider_success_rates,
		"provider_tokens": provider_tokens,
		"provider_input_tokens": provider_input_tokens,
		"provider_output_tokens": provider_output_tokens,
		"provider_response_times": provider_response_times,
		"provider_tps": provider_tps,
		"hourly_labels": hourly_labels,
		"hourly_calls": hourly_calls,
		"hourly_tokens": hourly_tokens,
		"hourly_successes": hourly_successes,
		"mode_labels": mode_labels,
		"mode_counts": mode_counts,
		"model_labels": model_labels,
		"model_counts": model_counts,
		"cumulative_labels": cumulative_labels,
		"cumulative_tokens": cumulative_tokens,
	}

## Formats a token count using K / M suffixes.
static func format_token_count(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (float(n) / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (float(n) / 1_000.0)
	return str(n)

## Appends chart metric rows to a PackedStringArray for CSV export.
static func append_metric_series(
	lines: PackedStringArray,
	metric: String,
	labels: Array,
	values: Array,
) -> void:
	var count := mini(labels.size(), values.size())
	for idx in range(count):
		lines.append(csv_row(["chart_metric", metric, str(labels[idx]), str(values[idx])]))

## Formats an array of cells into a CSV row string.
static func csv_row(cells: Array) -> String:
	var escaped: PackedStringArray = []
	for cell in cells:
		escaped.append(csv_escape(str(cell)))
	return ",".join(escaped)

## Escapes a single CSV value, quoting it if needed.
static func csv_escape(value: String) -> String:
	var v := value.replace("\"", "\"\"")
	if v.contains(",") or v.contains("\n") or v.contains("\r") or v.contains("\""):
		return "\"" + v + "\""
	return v
