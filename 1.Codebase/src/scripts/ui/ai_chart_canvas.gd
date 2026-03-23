extends Control
class_name AIChartCanvas
enum Type { HORIZONTAL_BAR, VERTICAL_BAR, PIE, LINE }
const BG_COLOR := Color(0.06, 0.09, 0.14, 1.0)
const BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.10)
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.07)
const TITLE_COLOR := Color(0.55, 0.82, 1.0)
const LABEL_COLOR := Color(0.72, 0.72, 0.72)
const VALUE_COLOR := Color(0.95, 0.95, 0.95)
const EMPTY_TEXT_COLOR := Color(0.58, 0.70, 0.86, 0.95)
const ZERO_BAR_MIN_SIZE := 1.5
const DEFAULT_COLORS: Array[Color] = [
	Color(0.30, 0.68, 1.00),
	Color(0.35, 0.95, 0.55),
	Color(1.00, 0.70, 0.25),
	Color(1.00, 0.38, 0.45),
	Color(0.78, 0.48, 1.00),
	Color(0.35, 0.90, 0.88),
	Color(1.00, 0.90, 0.28),
	Color(0.92, 0.58, 0.35),
]
const FONT_SIZE := 11
const TITLE_FONT_SIZE := 13
var chart_type: Type = Type.VERTICAL_BAR
var chart_title: String = ""
var labels: Array = []
var values: Array = []
var bar_colors: Array = []
func setup(p_type: Type, p_title: String, p_labels: Array, p_values: Array, p_colors: Array = []) -> void:
	chart_type = p_type
	chart_title = p_title
	labels = p_labels
	values = p_values
	bar_colors = p_colors
	queue_redraw()
func _draw() -> void:
	var r := get_rect()
	var W := r.size.x
	var H := r.size.y
	if W < 2.0 or H < 2.0:
		return
	draw_rect(r, BG_COLOR, true)
	draw_rect(r, BORDER_COLOR, false, 1.0)
	var font: Font = get_theme_font("font", "Label")
	var title_h := 0.0
	if font and chart_title != "":
		title_h = float(TITLE_FONT_SIZE) + 10.0
		draw_string(font, Vector2(8.0, float(TITLE_FONT_SIZE) + 4.0), chart_title,
			HORIZONTAL_ALIGNMENT_LEFT, W - 16.0, TITLE_FONT_SIZE, TITLE_COLOR)
	var plot := Rect2(Vector2(6.0, title_h + 2.0), Vector2(W - 12.0, H - title_h - 6.0))
	if not font:
		return
	match chart_type:
		Type.HORIZONTAL_BAR:
			_draw_hbar(plot, font)
		Type.VERTICAL_BAR:
			_draw_vbar(plot, font)
		Type.PIE:
			_draw_pie(plot, font)
		Type.LINE:
			_draw_line_chart(plot, font)
func _max_value() -> float:
	var m := 0.001
	for v in values:
		m = max(m, float(v))
	return m
func _get_color(i: int) -> Color:
	if i < bar_colors.size():
		return bar_colors[i]
	return DEFAULT_COLORS[i % DEFAULT_COLORS.size()]
func _fmt(v: float) -> String:
	if v >= 1_000_000.0:
		return "%.1fM" % (v / 1_000_000.0)
	if v >= 1_000.0:
		return "%.1fK" % (v / 1_000.0)
	if v == float(int(v)):
		return "%d" % int(v)
	return "%.1f" % v
func _has_positive_value() -> bool:
	for v in values:
		if float(v) > 0.0:
			return true
	return false
func _draw_empty_state(pr: Rect2, font: Font, message: String = "No data yet") -> void:
	var y: float = pr.position.y + pr.size.y * 0.5
	draw_string(font, Vector2(pr.position.x + 6.0, y), message,
		HORIZONTAL_ALIGNMENT_CENTER, maxf(0.0, pr.size.x - 12.0), FONT_SIZE, EMPTY_TEXT_COLOR)
func _draw_hbar(pr: Rect2, font: Font) -> void:
	var n := values.size()
	if n == 0:
		_draw_empty_state(pr, font)
		return
	var mv := _max_value()
	var all_zero: bool = not _has_positive_value()
	var lbl_w := clampf(pr.size.x * 0.28, 50.0, 120.0)
	var val_w := 42.0
	var bar_x := pr.position.x + lbl_w + 4.0
	var bar_max_w := pr.size.x - lbl_w - val_w - 8.0
	var row_h := pr.size.y / float(n)
	var bar_pad := maxf(2.0, row_h * 0.15)
	for i in range(n):
		var y := pr.position.y + i * row_h
		var cy := y + row_h * 0.5
		var lbl: String = str(labels[i]) if i < labels.size() else ""
		if lbl.length() > 12:
			lbl = lbl.substr(0, 11) + "…"
		draw_string(font, Vector2(pr.position.x, cy + float(FONT_SIZE) * 0.45),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, lbl_w, FONT_SIZE, LABEL_COLOR)
		var fill_w := bar_max_w * (float(values[i]) / mv)
		if all_zero:
			fill_w = maxf(fill_w, ZERO_BAR_MIN_SIZE)
		draw_rect(Rect2(bar_x, y + bar_pad, bar_max_w, row_h - bar_pad * 2.0), Color(1.0, 1.0, 1.0, 0.05), true)
		draw_rect(Rect2(bar_x, y + bar_pad, fill_w, row_h - bar_pad * 2.0), _get_color(i), true)
		draw_string(font, Vector2(bar_x + fill_w + 4.0, cy + float(FONT_SIZE) * 0.45),
			_fmt(float(values[i])), HORIZONTAL_ALIGNMENT_LEFT, val_w, FONT_SIZE, VALUE_COLOR)
	draw_line(Vector2(bar_x, pr.position.y), Vector2(bar_x, pr.end.y), GRID_COLOR, 1.0)
func _draw_vbar(pr: Rect2, font: Font) -> void:
	var n := values.size()
	if n == 0:
		_draw_empty_state(pr, font)
		return
	var mv := _max_value()
	var all_zero: bool = not _has_positive_value()
	var lbl_h := float(FONT_SIZE) + 6.0
	var bar_area_h := pr.size.y - lbl_h
	var bar_w_total := pr.size.x / float(n)
	var bar_pad := maxf(1.5, bar_w_total * 0.12)
	for gi in range(5):
		var gy := pr.position.y + bar_area_h * gi / 4.0
		draw_line(Vector2(pr.position.x, gy), Vector2(pr.end.x, gy), GRID_COLOR, 1.0)
	for i in range(n):
		var bx := pr.position.x + i * bar_w_total
		var fill_h := bar_area_h * (float(values[i]) / mv)
		if all_zero:
			fill_h = maxf(fill_h, ZERO_BAR_MIN_SIZE)
		draw_rect(
			Rect2(bx + bar_pad, pr.position.y, bar_w_total - bar_pad * 2.0, bar_area_h),
			Color(1.0, 1.0, 1.0, 0.04),
			true,
		)
		var bar_rect := Rect2(bx + bar_pad, pr.position.y + bar_area_h - fill_h,
			bar_w_total - bar_pad * 2.0, fill_h)
		draw_rect(bar_rect, _get_color(i), true)
		var val_str := _fmt(float(values[i]))
		draw_string(font, Vector2(bx + bar_pad, pr.position.y + bar_area_h - fill_h - 1.0),
			val_str, HORIZONTAL_ALIGNMENT_LEFT, bar_w_total - bar_pad * 2.0,
			FONT_SIZE - 1, VALUE_COLOR)
		var lbl: String = str(labels[i]) if i < labels.size() else ""
		if lbl.length() > 5:
			lbl = lbl.substr(0, 4) + "…"
		draw_string(font, Vector2(bx + 2.0, pr.end.y - 1.0),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, bar_w_total - 2.0, FONT_SIZE - 2, LABEL_COLOR)
func _draw_pie(pr: Rect2, font: Font) -> void:
	var n := values.size()
	if n == 0:
		_draw_empty_state(pr, font)
		return
	var total := 0.0
	for v in values:
		total += float(v)
	if total <= 0.0:
		var pie_w_empty: float = pr.size.x * 0.55
		var cx_empty: float = pr.position.x + pie_w_empty * 0.5
		var cy_empty: float = pr.position.y + pr.size.y * 0.5
		var radius_empty: float = minf(pie_w_empty * 0.42, pr.size.y * 0.42)
		var inner_r_empty: float = radius_empty * 0.42
		draw_circle(Vector2(cx_empty, cy_empty), radius_empty, Color(0.55, 0.82, 1.0, 0.22))
		draw_circle(Vector2(cx_empty, cy_empty), inner_r_empty, BG_COLOR)
		_draw_empty_state(pr, font)
		return
	var pie_w := pr.size.x * 0.55
	var cx := pr.position.x + pie_w * 0.5
	var cy := pr.position.y + pr.size.y * 0.5
	var radius := minf(pie_w * 0.42, pr.size.y * 0.42)
	var inner_r := radius * 0.42
	var angle := -PI * 0.5
	for i in range(n):
		var slice := (float(values[i]) / total) * TAU
		var steps: int = maxi(8, int(slice * 24.0))
		var pts := PackedVector2Array()
		pts.append(Vector2(cx, cy))
		for s in range(steps + 1):
			var a := angle + slice * s / float(steps)
			pts.append(Vector2(cx + cos(a) * radius, cy + sin(a) * radius))
		draw_polygon(pts, PackedColorArray([_get_color(i)]))
		angle += slice
	var donut_pts := PackedVector2Array()
	for s in range(33):
		var a := TAU * s / 32.0
		donut_pts.append(Vector2(cx + cos(a) * inner_r, cy + sin(a) * inner_r))
	draw_colored_polygon(donut_pts, BG_COLOR)
	var leg_x := pr.position.x + pie_w + 8.0
	var leg_y := pr.position.y + 6.0
	var row_h := float(FONT_SIZE) + 8.0
	for i in range(n):
		if i >= labels.size():
			break
		draw_rect(Rect2(leg_x, leg_y + i * row_h + 1.0, FONT_SIZE - 1, FONT_SIZE - 1),
			_get_color(i), true)
		var pct := "%.0f%%" % (float(values[i]) / total * 100.0)
		var lbl: String = str(labels[i])
		if lbl.length() > 10:
			lbl = lbl.substr(0, 9) + "…"
		draw_string(font, Vector2(leg_x + float(FONT_SIZE) + 3.0, leg_y + i * row_h + float(FONT_SIZE)),
			"%s %s" % [lbl, pct], HORIZONTAL_ALIGNMENT_LEFT,
			pr.end.x - leg_x - float(FONT_SIZE) - 3.0, FONT_SIZE - 1, LABEL_COLOR)
func _draw_line_chart(pr: Rect2, font: Font) -> void:
	var n := values.size()
	if n < 2:
		_draw_empty_state(pr, font)
		return
	var mv := _max_value()
	var all_zero: bool = not _has_positive_value()
	var lbl_h := float(FONT_SIZE) + 8.0
	var ph := pr.size.y - lbl_h
	var pw := pr.size.x
	var step_x := pw / float(n - 1)
	for gi in range(5):
		var gy := pr.position.y + ph * gi / 4.0
		draw_line(Vector2(pr.position.x, gy), Vector2(pr.end.x, gy), GRID_COLOR, 1.0)
	if all_zero:
		var baseline_y: float = pr.position.y + ph - 1.0
		draw_line(
			Vector2(pr.position.x, baseline_y),
			Vector2(pr.end.x, baseline_y),
			Color(0.30, 0.68, 1.00, 0.85),
			2.0,
		)
		_draw_empty_state(Rect2(pr.position, Vector2(pr.size.x, ph * 0.6)), font, "All values are 0")
	else:
		var fill_pts := PackedVector2Array()
		fill_pts.append(Vector2(pr.position.x, pr.position.y + ph))
		for i in range(n):
			var x := pr.position.x + i * step_x
			var y := pr.position.y + ph - (float(values[i]) / mv) * ph
			fill_pts.append(Vector2(x, y))
		fill_pts.append(Vector2(pr.position.x + (n - 1) * step_x, pr.position.y + ph))
		draw_colored_polygon(fill_pts, Color(0.30, 0.68, 1.00, 0.18))
		for i in range(n - 1):
			var x1 := pr.position.x + i * step_x
			var y1 := pr.position.y + ph - (float(values[i]) / mv) * ph
			var x2 := pr.position.x + (i + 1) * step_x
			var y2 := pr.position.y + ph - (float(values[i + 1]) / mv) * ph
			draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.30, 0.68, 1.00), 2.0)
	var label_step: int = maxi(1, int(n / 6))
	for i in range(0, n, label_step):
		if i >= labels.size():
			break
		var x := pr.position.x + i * step_x
		var lbl: String = str(labels[i])
		draw_string(font, Vector2(x - 8.0, pr.end.y - 1.0),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2, LABEL_COLOR)
	var max_label: String = "0" if all_zero else _fmt(mv)
	draw_string(font, Vector2(pr.position.x + 2.0, pr.position.y + float(FONT_SIZE) + 2.0),
		max_label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 1, VALUE_COLOR)
