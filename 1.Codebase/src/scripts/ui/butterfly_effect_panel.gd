extends Control
signal close_requested
const ERROR_CONTEXT := "ButterflyEffectPanel"
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const UIConstants = preload("res://1.Codebase/src/scripts/ui/ui_constants.gd")
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const SECRET_BUTTERFLY_TEXTURE_PATH := "res://1.Codebase/src/assets/ui/butterfly_effect.png"
const LEGAL_MAVERICKS_URL := "https://en.wikipedia.org/wiki/Legal_Mavericks"
const LEGAL_MAVERICKS_CLICKS_NEEDED := 5
@onready var _panel: Panel = $MainMargin/Panel
@onready var _header_bar: HBoxContainer = $MainMargin/Panel/VBoxMain/HeaderBar
@onready var _title_block: VBoxContainer = $MainMargin/Panel/VBoxMain/HeaderBar/TitleBlock
@onready var _title_label: Label = $MainMargin/Panel/VBoxMain/HeaderBar/TitleBlock/TitleLabel
@onready var _subtitle_label: Label = $MainMargin/Panel/VBoxMain/HeaderBar/TitleBlock/SubtitleLabel
@onready var _close_button: Button = $MainMargin/Panel/VBoxMain/HeaderBar/CloseButton
@onready var _explain_button: Button = $MainMargin/Panel/VBoxMain/HeaderBar/ExplainButton
@onready var _stats := {
	"tracked": $MainMargin/Panel/VBoxMain/StatsGrid/StatCardTracked/StatMargin1/StatBoxTracked/StatValueTracked,
	"active": $MainMargin/Panel/VBoxMain/StatsGrid/StatCardActive/StatMargin2/StatBoxActive/StatValueActive,
	"triggered": $MainMargin/Panel/VBoxMain/StatsGrid/StatCardTriggered/StatMargin3/StatBoxTriggered/StatValueTriggered,
	"scenes": $MainMargin/Panel/VBoxMain/StatsGrid/StatCardScenes/StatMargin4/StatBoxScenes/StatValueScenes,
}
@onready var _stat_cards := [
	$MainMargin/Panel/VBoxMain/StatsGrid/StatCardTracked,
	$MainMargin/Panel/VBoxMain/StatsGrid/StatCardActive,
	$MainMargin/Panel/VBoxMain/StatsGrid/StatCardTriggered,
	$MainMargin/Panel/VBoxMain/StatsGrid/StatCardScenes,
]
@onready var _timeline_list: VBoxContainer = $MainMargin/Panel/VBoxMain/TimelineScroll/TimelineList
@onready var _timeline_scroll: ScrollContainer = $MainMargin/Panel/VBoxMain/TimelineScroll
@onready var _empty_state: Label = $MainMargin/Panel/VBoxMain/EmptyState
@onready var _footer_hint: Label = $MainMargin/Panel/VBoxMain/FooterHint
@onready var _critical_badge: Label = $MainMargin/Panel/VBoxMain/TimelineHeader/TagLegend/CriticalBadge
@onready var _major_badge: Label = $MainMargin/Panel/VBoxMain/TimelineHeader/TagLegend/MajorBadge
@onready var _minor_badge: Label = $MainMargin/Panel/VBoxMain/TimelineHeader/TagLegend/MinorBadge
@onready var _timeline_title: Label = $MainMargin/Panel/VBoxMain/TimelineHeader/TimelineTitle
var events: Array = []
var _lang: String = "en"
var _is_ready: bool = false
var _game_state: Variant = null
var _audio_manager: Variant = null
var _secret_click_count: int = 0
var _secret_easter_egg_unlocked: bool = false
var _background_image_rect: TextureRect = null
var _secret_image_container: CenterContainer = null
var _secret_image_rect: TextureRect = null
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	_game_state = _get_game_state()
	_audio_manager = _get_audio_manager()
	_lang = _game_state.current_language if _game_state else "en"
	_is_ready = true
	_apply_styles()
	_setup_background_image()
	_setup_secret_butterfly_image()
	_connect_signals()
	_refresh_ui()
	if _panel:
		UIStyleManager.fade_in(_panel, 0.25)
	if _close_button:
		_close_button.grab_focus()
func setup(initial_events: Array) -> void:
	events = initial_events.duplicate(true) if initial_events else []
	if _is_ready:
		_refresh_ui()
func _connect_signals() -> void:
	if _close_button and not _close_button.pressed.is_connected(_on_close_pressed):
		_close_button.pressed.connect(_on_close_pressed)
	if _explain_button and not _explain_button.pressed.is_connected(_on_explain_pressed):
		_explain_button.pressed.connect(_on_explain_pressed)
func _apply_styles() -> void:
	if _panel:
		UIStyleManager.apply_panel_style(_panel, 0.96, UIStyleManager.CORNER_RADIUS_LARGE)
	if _close_button:
		UIStyleManager.apply_button_style(_close_button, "accent", "medium")
		UIStyleManager.add_hover_scale_effect(_close_button, 1.05)
		UIStyleManager.add_press_feedback(_close_button)
		_close_button.text = _tr("BUTTERFLY_CLOSE_2")
		_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _explain_button:
		UIStyleManager.apply_button_style(_explain_button, "normal", "medium")
		_explain_button.text = LocalizationManager.get_translation("BUTTERFLY_BTN_EXPLAIN") if LocalizationManager else "How it Works"
	if _title_label:
		_title_label.text = _tr("BUTTERFLY_BUTTERFLY_EFFECT_INTEL")
	if _subtitle_label:
		_subtitle_label.text = _tr("BUTTERFLY_EVERY_FORCED_SMILE_LEAVES_RIPPLES")
	if _timeline_title:
		_timeline_title.text = _tr("BUTTERFLY_RIPPLE_TIMELINE")
	if _footer_hint:
		_footer_hint.text = _tr("BUTTERFLY_TIP_REVISIT_OLDER_SCENES_TO")
	_set_badge_text(_critical_badge, _tr("BUTTERFLY_BADGE_CRITICAL"), _tr("BUTTERFLY_BADGE_CRITICAL"), Color(1.0, 0.5, 0.6))
	_set_badge_text(_major_badge, _tr("BUTTERFLY_BADGE_MAJOR"), _tr("BUTTERFLY_BADGE_MAJOR"), Color(0.6, 0.8, 1.0))
	_set_badge_text(_minor_badge, _tr("BUTTERFLY_BADGE_MINOR"), _tr("BUTTERFLY_BADGE_MINOR"), Color(0.6, 0.9, 0.7))
	var card_colors: Array[Color] = [
		Color(0.18, 0.24, 0.36, 0.95),
		Color(0.2, 0.28, 0.2, 0.95),
		Color(0.32, 0.22, 0.25, 0.95),
		Color(0.24, 0.2, 0.3, 0.95),
	]
	for i in range(_stat_cards.size()):
		_style_stat_card(_stat_cards[i], card_colors[i % card_colors.size()])
func _setup_background_image() -> void:
	if not _panel or is_instance_valid(_background_image_rect):
		return
	var texture := _load_texture_safe(SECRET_BUTTERFLY_TEXTURE_PATH)
	if texture == null:
		return
	_background_image_rect = TextureRect.new()
	_background_image_rect.name = "ButterflyBackgroundImage"
	_background_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_image_rect.offset_left = 2.0
	_background_image_rect.offset_top = 2.0
	_background_image_rect.offset_right = -2.0
	_background_image_rect.offset_bottom = -2.0
	_background_image_rect.texture = texture
	_background_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_image_rect.modulate = Color(1.0, 1.0, 1.0, 0.12)
	_panel.add_child(_background_image_rect)
	_panel.move_child(_background_image_rect, 0)
func _setup_secret_butterfly_image() -> void:
	if not _header_bar or is_instance_valid(_secret_image_container):
		return
	var texture := _load_texture_safe(SECRET_BUTTERFLY_TEXTURE_PATH)
	if texture == null:
		return
	var icon_size := Vector2(52, 52)
	_secret_image_container = CenterContainer.new()
	_secret_image_container.name = "SecretButterflyImage"
	_secret_image_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_secret_image_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_secret_image_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_secret_image_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_secret_image_container.custom_minimum_size = icon_size
	_secret_image_container.tooltip_text = _tr("EASTER_EGG_LEGAL_MAVERICKS_HINT").format({"remaining": LEGAL_MAVERICKS_CLICKS_NEEDED})
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = icon_size
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.1, 0.12, 0.2, 0.8)
	frame_style.border_color = Color(0.5, 0.65, 0.85, 0.35)
	frame_style.border_width_left = 1
	frame_style.border_width_top = 1
	frame_style.border_width_right = 1
	frame_style.border_width_bottom = 1
	frame_style.corner_radius_top_left = 10
	frame_style.corner_radius_top_right = 10
	frame_style.corner_radius_bottom_left = 10
	frame_style.corner_radius_bottom_right = 10
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.2)
	frame_style.shadow_size = 4
	frame.add_theme_stylebox_override("panel", frame_style)
	_secret_image_container.add_child(frame)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	frame.add_child(margin)
	_secret_image_rect = TextureRect.new()
	_secret_image_rect.texture = texture
	_secret_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_secret_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_secret_image_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secret_image_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_secret_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_secret_image_rect)
	# Add to HeaderBar (HBox) between TitleBlock and buttons, not inside TitleBlock (VBox)
	_header_bar.add_child(_secret_image_container)
	_header_bar.move_child(_secret_image_container, 1)
	if not _secret_image_container.gui_input.is_connected(_on_secret_image_gui_input):
		_secret_image_container.gui_input.connect(_on_secret_image_gui_input)
func _set_badge_text(badge: Label, en_text: String, zh_text: String, tint: Color) -> void:
	if not badge:
		return
	badge.text = en_text if _lang == "en" else zh_text
	badge.add_theme_color_override("font_color", tint)
	badge.add_theme_color_override("font_outline_color", tint.darkened(0.5))
	badge.add_theme_constant_override("outline_size", 1)
func _style_stat_card(card: PanelContainer, bg_color: Color) -> void:
	if not card:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = bg_color.lightened(0.3)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = UIConstants.CORNER_RADIUS
	style.corner_radius_top_right = UIConstants.CORNER_RADIUS
	style.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
	style.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
	card.add_theme_stylebox_override("panel", style)
func _refresh_ui() -> void:
	var entries = _resolve_entries()
	_update_stats(entries)
	_populate_timeline(entries)
func _resolve_entries() -> Array:
	if not events.is_empty():
		return _normalize_entries(events)
	var tracker_summary: Array = []
	var tracker = _get_tracker()
	if tracker and tracker.has_method("get_butterfly_effect_summary"):
		tracker_summary = tracker.get_butterfly_effect_summary(_lang)
	return _normalize_entries(tracker_summary)
func _normalize_entries(raw_entries: Array) -> Array:
	var normalized: Array = []
	for item in raw_entries:
		if item is Dictionary:
			normalized.append((item as Dictionary).duplicate(true))
		else:
			normalized.append(
				{
					"choice_text": str(item),
					"choice_type": "major",
					"scenes_ago": 0,
					"scene_number": 0,
					"consequences_triggered": 0,
					"consequences_total": 0,
					"recent_consequences": [],
					"tags": [],
				},
			)
	return normalized
func _update_stats(entries: Array) -> void:
	var total_choices := entries.size()
	var triggered := 0
	var total_consequences := 0
	var scenes_sum := 0.0
	for entry in entries:
		triggered += int(entry.get("consequences_triggered", 0))
		total_consequences += int(entry.get("consequences_total", 0))
		scenes_sum += float(entry.get("scenes_ago", 0))
	var pending: int = max(total_consequences - triggered, 0)
	var avg_scenes := 0.0
	if entries.size() > 0:
		avg_scenes = scenes_sum / entries.size()
	var avg_display := _round_to_tenths(avg_scenes)
	if _stats.has("tracked"):
		_stats["tracked"].text = str(total_choices)
	if _stats.has("active"):
		_stats["active"].text = str(pending)
	if _stats.has("triggered"):
		_stats["triggered"].text = str(triggered)
	if _stats.has("scenes"):
		_stats["scenes"].text = str(avg_display)
func _populate_timeline(entries: Array) -> void:
	if not _timeline_list:
		return
	for child in _timeline_list.get_children():
		child.queue_free()
	if entries.is_empty():
		_timeline_scroll.visible = false
		_empty_state.visible = true
		_empty_state.text = _tr("BUTTERFLY_NO_RIPPLES_RECORDED_YET_TRY")
		return
	_timeline_scroll.visible = true
	_empty_state.visible = false
	for entry in entries:
		var card = _build_timeline_entry(entry)
		_timeline_list.add_child(card)
func _build_timeline_entry(entry: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	var choice_type := str(entry.get("choice_type", "major")).to_lower()
	match choice_type:
		"critical":
			style.bg_color = Color(0.32, 0.12, 0.16, 0.92)
			style.border_color = Color(1.0, 0.45, 0.5)
		"minor":
			style.bg_color = Color(0.14, 0.2, 0.18, 0.92)
			style.border_color = Color(0.45, 0.9, 0.65)
		_:
			style.bg_color = Color(0.16, 0.22, 0.32, 0.92)
			style.border_color = Color(0.45, 0.75, 0.95)
	style.border_width_left = 3
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = UIConstants.CORNER_RADIUS
	style.corner_radius_top_right = UIConstants.CORNER_RADIUS
	style.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
	style.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
	container.add_theme_stylebox_override("panel", style)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	container.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	var scene_number := int(entry.get("scene_number", 0))
	var scenes_ago := int(entry.get("scenes_ago", 0))
	var scene_label = Label.new()
	scene_label.text = _format_scene_text(scene_number, scenes_ago)
	scene_label.add_theme_font_size_override("font_size", 16)
	scene_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	header.add_child(scene_label)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var type_badge = Label.new()
	type_badge.text = _format_type_badge(choice_type)
	type_badge.add_theme_font_size_override("font_size", 14)
	type_badge.add_theme_color_override("font_color", style.border_color)
	header.add_child(type_badge)
	var choice_label = Label.new()
	choice_label.text = str(entry.get("choice_text", "???"))
	choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	choice_label.add_theme_font_size_override("font_size", 20)
	choice_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1))
	vbox.add_child(choice_label)
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	vbox.add_child(stats_row)
	var triggered: int = int(entry.get("consequences_triggered", 0))
	var total: int = max(int(entry.get("consequences_total", 0)), 0)
	var pending: int = max(total - triggered, 0)
	var triggered_label = Label.new()
	triggered_label.text = _format_triggered_text(triggered, total)
	triggered_label.add_theme_font_size_override("font_size", 15)
	triggered_label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.9))
	stats_row.add_child(triggered_label)
	var pending_label = Label.new()
	pending_label.text = _format_pending_text(pending)
	pending_label.add_theme_font_size_override("font_size", 15)
	pending_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.6))
	stats_row.add_child(pending_label)
	var tags: Array = entry.get("tags", [])
	if tags and tags.size() > 0:
		var tag_box = HBoxContainer.new()
		tag_box.add_theme_constant_override("separation", 6)
		vbox.add_child(tag_box)
		for tag in tags:
			var tag_label = Label.new()
			tag_label.text = "#" + str(tag)
			tag_label.add_theme_font_size_override("font_size", 13)
			tag_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
			tag_box.add_child(tag_label)
	var recent_consequences: Array = entry.get("recent_consequences", [])
	if recent_consequences and recent_consequences.size() > 0:
		var divider = HSeparator.new()
		vbox.add_child(divider)
		var recent_label = Label.new()
		recent_label.text = _tr("BUTTERFLY_RECENT_RIPPLES")
		recent_label.add_theme_font_size_override("font_size", 15)
		recent_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
		vbox.add_child(recent_label)
		for consequence in recent_consequences:
			var cons_label = Label.new()
			cons_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			cons_label.text = "• " + str(consequence.get("description", "???"))
			cons_label.add_theme_font_size_override("font_size", 15)
			cons_label.add_theme_color_override("font_color", _severity_color(consequence.get("severity", "medium")))
			vbox.add_child(cons_label)
	return container
func _format_scene_text(scene_number: int, scenes_ago: int) -> String:
	if _lang == "en":
		var ago_text = "Now" if scenes_ago <= 0 else ("%d scenes ago" % scenes_ago)
		return "Scene %d • %s" % [scene_number, ago_text]
	else:
		var ago_text = _tr("BUTTERFLY_NOW") if scenes_ago <= 0 else (_tr("BUTTERFLY_SCENES_AGO_FMT") % scenes_ago)
		return _tr("BUTTERFLY_SCENE_FMT") % [scene_number, ago_text]
func _format_type_badge(choice_type: String) -> String:
	match choice_type:
		"critical":
			return _tr("BUTTERFLY_CRITICAL")
		"minor":
			return _tr("BUTTERFLY_MINOR")
		_:
			return _tr("BUTTERFLY_MAJOR")
func _format_triggered_text(triggered: int, total: int) -> String:
	if _lang == "en":
		return "Triggered: %d / %d" % [triggered, total]
	return _tr("BUTTERFLY_TRIGGERED_FMT") % [triggered, total]
func _format_pending_text(pending: int) -> String:
	if _lang == "en":
		return "Remaining: %d" % pending
	return _tr("BUTTERFLY_PENDING_FMT") % pending
func _severity_color(severity: String) -> Color:
	match severity:
		"low":
			return Color(0.68, 0.9, 0.72)
		"high":
			return Color(1.0, 0.65, 0.55)
		_:
			return Color(0.95, 0.9, 0.75)
func _on_close_pressed() -> void:
	if _audio_manager:
		_audio_manager.play_sfx("menu_close", 0.7)
	close_requested.emit()
	queue_free()
func _on_explain_pressed() -> void:
	if _audio_manager:
		_audio_manager.play_sfx("ui_click_heavy")
	var explain_scene = load("res://1.Codebase/src/scenes/ui/butterfly_effect_explanation.tscn")
	if explain_scene:
		var instance = explain_scene.instantiate()
		add_child(instance)
		if instance.has_method("setup"):
			instance.setup()
func _on_secret_image_gui_input(event: InputEvent) -> void:
	if _secret_easter_egg_unlocked:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_secret_click_count += 1
	_pulse_secret_image()
	if _secret_click_count >= LEGAL_MAVERICKS_CLICKS_NEEDED:
		_secret_easter_egg_unlocked = true
		if _audio_manager:
			_audio_manager.play_sfx("group_present", 0.9)
		OS.shell_open(LEGAL_MAVERICKS_URL)
		_show_legal_mavericks_easter_egg()
		return
	var remaining := LEGAL_MAVERICKS_CLICKS_NEEDED - _secret_click_count
	if _secret_image_container:
		_secret_image_container.tooltip_text = _tr("EASTER_EGG_LEGAL_MAVERICKS_CLICK").format({"remaining": remaining})
func _pulse_secret_image() -> void:
	if not is_instance_valid(_secret_image_container):
		return
	var tween := create_tween()
	tween.tween_property(_secret_image_container, "scale", Vector2(1.06, 1.06), 0.08)
	tween.tween_property(_secret_image_container, "scale", Vector2.ONE, 0.08)
func _show_legal_mavericks_easter_egg() -> void:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 20
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.02, 0.95)
	overlay.add_child(bg)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.02, 0.03, 0.06, 0.55)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(vignette)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var popup_panel := Panel.new()
	popup_panel.custom_minimum_size = Vector2(720, 600)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.09, 0.985)
	sb.border_color = Color(0.36, 0.5, 0.7, 0.82)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	sb.shadow_size = 26
	popup_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(popup_panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	popup_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = _tr("EASTER_EGG_LEGAL_MAVERICKS_TITLE")
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 1.0))
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	var subtitle_lbl := Label.new()
	subtitle_lbl.text = _tr("EASTER_EGG_LEGAL_MAVERICKS_SUBTITLE")
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.56, 0.66, 0.78))
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_lbl)
	var sep := HSeparator.new()
	sep.modulate = Color(0.36, 0.5, 0.7, 0.45)
	vbox.add_child(sep)
	var popup_texture := _load_texture_safe(SECRET_BUTTERFLY_TEXTURE_PATH)
	if popup_texture:
		var img_rect := TextureRect.new()
		img_rect.texture = popup_texture
		img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img_rect.custom_minimum_size = Vector2(172, 172)
		img_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		img_rect.modulate = Color(0.9, 0.92, 1.0, 0.96)
		vbox.add_child(img_rect)
	var body_panel := PanelContainer.new()
	body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body_style := StyleBoxFlat.new()
	body_style.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	body_style.border_color = Color(0.2, 0.28, 0.38, 0.9)
	body_style.border_width_left = 1
	body_style.border_width_top = 1
	body_style.border_width_right = 1
	body_style.border_width_bottom = 1
	body_style.corner_radius_top_left = 14
	body_style.corner_radius_top_right = 14
	body_style.corner_radius_bottom_left = 14
	body_style.corner_radius_bottom_right = 14
	body_panel.add_theme_stylebox_override("panel", body_style)
	vbox.add_child(body_panel)
	var body_margin := MarginContainer.new()
	body_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	body_margin.add_theme_constant_override("margin_left", 18)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_right", 18)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	body_panel.add_child(body_margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_child(scroll)
	var body_lbl := RichTextLabel.new()
	body_lbl.bbcode_enabled = true
	body_lbl.fit_content = true
	body_lbl.scroll_active = false
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("normal_font_size", 20)
	body_lbl.add_theme_color_override("default_color", Color(0.9, 0.92, 0.96))
	body_lbl.add_theme_constant_override("line_separation", 10)
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.text = _tr("EASTER_EGG_LEGAL_MAVERICKS_BODY")
	scroll.add_child(body_lbl)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	vbox.add_child(button_row)
	var open_btn := Button.new()
	open_btn.text = _tr("EASTER_EGG_LEGAL_MAVERICKS_OPEN")
	open_btn.custom_minimum_size = Vector2(190, 44)
	UIStyleManager.apply_button_style(open_btn, "accent", "medium")
	UIStyleManager.add_hover_scale_effect(open_btn, 1.04)
	open_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	open_btn.pressed.connect(func() -> void:
		OS.shell_open(LEGAL_MAVERICKS_URL)
	)
	button_row.add_child(open_btn)
	var close_btn := Button.new()
	close_btn.text = _tr("EASTER_EGG_CLOSE")
	close_btn.custom_minimum_size = Vector2(150, 44)
	UIStyleManager.apply_button_style(close_btn, "normal", "medium")
	UIStyleManager.add_hover_scale_effect(close_btn, 1.04)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(overlay.queue_free)
	button_row.add_child(close_btn)
	overlay.modulate.a = 0.0
	add_child(overlay)
	UIStyleManager.fade_in(overlay, 0.25)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
func _get_game_state() -> Variant:
	if typeof(ServiceLocator) != TYPE_NIL and ServiceLocator:
		var gs = ServiceLocator.get_game_state()
		if gs:
			return gs
	if typeof(GameState) != TYPE_NIL:
		return GameState
	return null
func _get_tracker() -> Variant:
	if _game_state and _game_state.butterfly_tracker:
		return _game_state.butterfly_tracker
	return null
func _get_audio_manager() -> Variant:
	if typeof(ServiceLocator) != TYPE_NIL and ServiceLocator:
		return ServiceLocator.get_audio_manager()
	if typeof(AudioManager) != TYPE_NIL:
		return AudioManager
	return null
func _load_texture_safe(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Failed to load butterfly effect easter egg texture", {"path": path})
	return texture
func _round_to_tenths(value: float) -> float:
	return snappedf(value, 0.1)
