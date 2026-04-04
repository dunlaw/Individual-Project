extends Control
signal prayer_requested
const ERROR_CONTEXT := "NightCycleOverlay"
const UIStyleManager  = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const STAGE_BG        = preload("res://1.Codebase/src/assets/ui/miss_chan_stage_background.png")
const CHAN_HAPPY    = preload("res://1.Codebase/src/assets/characters/teacher_chan_happy.png")
const CHAN_NEUTRAL  = preload("res://1.Codebase/src/assets/characters/teacher_chan_neutral.png")
const CHAN_RAISED   = preload("res://1.Codebase/src/assets/characters/teacher_chan_arms_raised.png")
const CHAN_BOWING   = preload("res://1.Codebase/src/assets/characters/teacher_chan_bowing.png")
const CHAN_REACH    = preload("res://1.Codebase/src/assets/characters/teacher_chan_reaching.png")
const CHAN_SINGING  = preload("res://1.Codebase/src/assets/characters/teacher_chan_eyes_closed_singing.png")
const CHAN_POINT    = preload("res://1.Codebase/src/assets/characters/teacher_chan_pointing.png")
const CHAN_PLEAD    = preload("res://1.Codebase/src/assets/characters/teacher_chan_pleading_hands.png")
const CHAN_SIDE     = preload("res://1.Codebase/src/assets/characters/teacher_chan_dramatic_side.png")
const ICON_SCROLL   = preload("res://1.Codebase/src/assets/icons/scroll.png")
const ICON_CRYSTAL  = preload("res://1.Codebase/src/assets/icons/crystal.png")
const ICON_SPIRIT   = preload("res://1.Codebase/src/assets/icons/spirit.png")
const ICON_CAMPFIRE = preload("res://1.Codebase/src/assets/icons/campfire.png")
var _reflection_panel: PanelContainer
var _reflection_label: RichTextLabel
var _concert_panel: PanelContainer
var _concert_song_label: Label
var _concert_text_label: RichTextLabel
var _concert_portrait: TextureRect
var _concert_lyrics_container: VBoxContainer
var _concert_video_placeholder: PanelContainer
var _honeymoon_panel: PanelContainer
var _honeymoon_label: RichTextLabel
var _title_label: Label
var _pray_button: Button
var _skip_button: Button
var _spotlight_node: ColorRect = null
var _stage_lights: Array[ColorRect] = []
var current_language: String          = "en"
var current_lyrics: Array             = []
var lyrics_animation_time: float      = 0.0
var lyrics_line_index: int            = 0
const LYRICS_LINE_DURATION: float     = 1.0
var _content_received: bool           = false
var _content_failsafe_timer: Timer
var _audio_manager: Node              = null
var _concert_tweens: Array[Tween]     = []
var _crowd_player: AudioStreamPlayer  = null
var _port_timer: float  = 0.0
var _port_index: int    = 0
const PORT_INTERVAL: float = 3.5
var _portraits: Array   = []
func _ready() -> void:
	for child in get_children(): child.queue_free()
	var gs = ServiceLocator.get_game_state() if ServiceLocator else null
	current_language = gs.current_language if gs else "en"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	_build_ui()
	_start_failsafe_timer()
	if get_parent() == get_tree().root:
		get_tree().create_timer(0.5).timeout.connect(_on_failsafe_timeout)
	modulate.a = 0.0
	var t = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(self, "modulate:a", 1.0, 0.7)
func _process(delta: float) -> void:
	if current_lyrics.size() > 0 and lyrics_line_index < current_lyrics.size():
		lyrics_animation_time += delta
		if lyrics_animation_time >= LYRICS_LINE_DURATION:
			lyrics_animation_time = 0.0
			lyrics_line_index += 1
			_refresh_lyrics()
	if lyrics_line_index >= current_lyrics.size() and _pray_button and not _pray_button.visible:
		_finish_concert()
	if _concert_portrait and _portraits.size() > 1:
		_port_timer += delta
		if _port_timer >= PORT_INTERVAL:
			_port_timer = 0.0
			_port_index = (_port_index + 1) % _portraits.size()
			var pt = create_tween()
			pt.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			pt.tween_property(_concert_portrait, "modulate:a", 0.0, 0.22)
			pt.tween_callback(func(): _concert_portrait.texture = _portraits[_port_index])
			pt.tween_property(_concert_portrait, "modulate:a", 1.0, 0.22)
func _exit_tree() -> void:
	if _content_failsafe_timer: _content_failsafe_timer.queue_free()
	for tw in _concert_tweens:
		if tw and tw.is_valid(): tw.kill()
	_concert_tweens.clear()
	if is_instance_valid(_crowd_player):
		_crowd_player.stop()
		_crowd_player.queue_free()
		_crowd_player = null
	var audio = _get_audio()
	if audio and audio.has_method("stop_music"): audio.stop_music(0.5)
func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.09, 0.07, 0.18, 1.0)
	add_child(bg)
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.04, 0.02, 0.10, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_create_particles()
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var page = MarginContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("margin_left",   44)
	page.add_theme_constant_override("margin_right",  44)
	page.add_theme_constant_override("margin_top",    0)
	page.add_theme_constant_override("margin_bottom", 50)
	scroll.add_child(page)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	page.add_child(vbox)
	_build_night_label(vbox)
	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left",   0)
	content_margin.add_theme_constant_override("margin_right",  0)
	content_margin.add_theme_constant_override("margin_top",    24)
	content_margin.add_theme_constant_override("margin_bottom", 0)
	vbox.add_child(content_margin)
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 20)
	content_margin.add_child(content_vbox)
	_build_reflection_section(content_vbox)
	_build_concert_section(content_vbox)
	_build_honeymoon_section(content_vbox)
	_build_footer(content_vbox)
	_skip_button = Button.new()
	_skip_button.text = _tr("NIGHT_SKIP_CONCERT") if not _tr("NIGHT_SKIP_CONCERT").begins_with("NIGHT_") \
		else (_tr("NIGHT_CYCLE_SKIP"))
	_skip_button.visible = false
	_skip_button.pressed.connect(_on_skip_pressed)
	add_child(_skip_button)
	_skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_button.anchor_left = 1.0; _skip_button.anchor_right  = 1.0
	_skip_button.offset_left = -120; _skip_button.offset_right  = -16
	_skip_button.offset_top  = 16;   _skip_button.offset_bottom = 58
	_pray_button = Button.new()
	_pray_button.text = "✦  " + (_tr("NIGHT_BUTTON_PRAY") if not _tr("NIGHT_BUTTON_PRAY").begins_with("NIGHT_") else "祈禱儀式")
	_pray_button.visible = false
	_pray_button.pressed.connect(_on_pray_pressed)
	var _pn := StyleBoxFlat.new()
	_pn.bg_color = Color(0.12, 0.04, 0.28, 0.92)
	_pn.border_color = Color(0.88, 0.74, 0.18, 1.0)
	_pn.border_width_left = 2; _pn.border_width_right = 2
	_pn.border_width_top = 2; _pn.border_width_bottom = 2
	_pn.corner_radius_top_left = 14; _pn.corner_radius_top_right = 14
	_pn.corner_radius_bottom_left = 14; _pn.corner_radius_bottom_right = 14
	_pn.shadow_color = Color(0.88, 0.72, 0.14, 0.50); _pn.shadow_size = 14
	_pn.content_margin_left = 20; _pn.content_margin_right = 20
	_pn.content_margin_top = 10; _pn.content_margin_bottom = 10
	_pray_button.add_theme_stylebox_override("normal", _pn)
	var _ph := _pn.duplicate() as StyleBoxFlat
	_ph.bg_color = Color(0.20, 0.07, 0.42, 0.96); _ph.shadow_size = 20
	_pray_button.add_theme_stylebox_override("hover", _ph)
	var _pp := _pn.duplicate() as StyleBoxFlat
	_pp.bg_color = Color(0.08, 0.02, 0.20, 1.0)
	_pray_button.add_theme_stylebox_override("pressed", _pp)
	_pray_button.add_theme_color_override("font_color", Color(0.95, 0.85, 0.30))
	_pray_button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.50))
	_pray_button.add_theme_font_size_override("font_size", 17)
	add_child(_pray_button)
	_pray_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pray_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pray_button.anchor_left = 1.0; _pray_button.anchor_right = 1.0
	_pray_button.offset_left = -190; _pray_button.offset_right = -16
	_pray_button.offset_top = 16; _pray_button.offset_bottom = 70
func _build_night_label(parent: VBoxContainer) -> void:
	var bar = MarginContainer.new()
	bar.add_theme_constant_override("margin_top",    20)
	bar.add_theme_constant_override("margin_bottom", 6)
	bar.add_theme_constant_override("margin_left",   0)
	bar.add_theme_constant_override("margin_right",  0)
	parent.add_child(bar)
	_title_label = Label.new()
	_title_label.text = _tr("NIGHT_REFLECTION") if not _tr("NIGHT_REFLECTION").begins_with("NIGHT_") \
		else (_tr("NIGHT_CYCLE_NIGHT"))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0.68, 0.60, 0.90, 0.80))
	bar.add_child(_title_label)
func _build_reflection_section(parent: VBoxContainer) -> void:
	_reflection_panel = _make_card(Color(0.10, 0.11, 0.22, 0.97), Color(0.42, 0.52, 0.88, 0.75), 4, false)
	parent.add_child(_reflection_panel)
	var inner = _card_inner(_reflection_panel)
	var ref_hdr = _section_header(ICON_SCROLL, "NIGHT_HEADING_REFLECTION",
		_tr("NIGHT_CYCLE_REFLECTION"),
		Color(0.55, 0.78, 1.0))
	inner.add_child(ref_hdr)
	inner.add_child(_hsep(Color(0.42, 0.62, 1.0, 0.30)))
	_reflection_label = _make_rtl(16)
	_reflection_label.add_theme_color_override("default_color", Color(0.88, 0.90, 1.0))
	inner.add_child(_reflection_label)
func _build_concert_section(parent: VBoxContainer) -> void:
	_concert_panel = _make_card(Color(0.07, 0.03, 0.18, 0.98), Color(0.68, 0.32, 1.0, 0.92), 3, true)
	parent.add_child(_concert_panel)
	var outer = _card_inner(_concert_panel)
	_add_stage_lights(_concert_panel)
	var hdr_row = HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 10)
	outer.add_child(hdr_row)
	var conc_icon_lbl = _make_icon(ICON_CAMPFIRE, 24)
	hdr_row.add_child(conc_icon_lbl)
	var sect_lbl = Label.new()
	sect_lbl.text = _tr("NIGHT_HEADING_CONCERT") if not _tr("NIGHT_HEADING_CONCERT").begins_with("NIGHT_") \
		else (_tr("NIGHT_CYCLE_MISS_CHANS_LITURGY"))
	sect_lbl.add_theme_font_size_override("font_size", 19)
	sect_lbl.add_theme_color_override("font_color", Color(0.80, 0.58, 1.0))
	sect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(sect_lbl)
	hdr_row.add_child(_make_live_badge())
	var conc_icon = _make_icon(ICON_CRYSTAL, 22)
	hdr_row.add_child(conc_icon)
	hdr_row.move_child(conc_icon, 0)
	_concert_song_label = Label.new()
	_concert_song_label.text = "♪     ♪"
	_concert_song_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_concert_song_label.add_theme_font_size_override("font_size", 30)
	_concert_song_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.22))
	_concert_song_label.add_theme_color_override("font_outline_color", Color(0.38, 0.0, 0.65, 1.0))
	_concert_song_label.add_theme_constant_override("outline_size", 6)
	outer.add_child(_concert_song_label)
	outer.add_child(_hsep(Color(0.60, 0.28, 0.95, 0.35)))
	var stage_area = Control.new()
	stage_area.custom_minimum_size = Vector2(0, 400)
	stage_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_area.clip_contents = true
	outer.add_child(stage_area)
	var stage_bg = TextureRect.new()
	stage_bg.texture = STAGE_BG
	stage_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_area.add_child(stage_bg)
	var stage_dim = ColorRect.new()
	stage_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_dim.color = Color(0.0, 0.0, 0.08, 0.38)
	stage_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_area.add_child(stage_dim)
	_spotlight_node = ColorRect.new()
	_spotlight_node.color = Color(1.0, 0.88, 0.3, 0.18)
	_spotlight_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_spotlight_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_area.add_child(_spotlight_node)
	_concert_portrait = TextureRect.new()
	_concert_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_concert_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_concert_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	_concert_portrait.modulate = Color(1.18, 1.15, 1.18, 1.0)
	_portraits = [
		CHAN_HAPPY, CHAN_SINGING, CHAN_RAISED, CHAN_POINT,
		CHAN_REACH, CHAN_BOWING, CHAN_PLEAD, CHAN_SIDE, CHAN_NEUTRAL
	]
	_concert_portrait.texture = _portraits[0]
	stage_area.add_child(_concert_portrait)
	var name_bar = PanelContainer.new()
	var nb_style = StyleBoxFlat.new()
	nb_style.bg_color = Color(0.35, 0.06, 0.55, 0.88)
	nb_style.corner_radius_top_left    = 8; nb_style.corner_radius_top_right    = 8
	nb_style.corner_radius_bottom_left = 8; nb_style.corner_radius_bottom_right = 8
	nb_style.content_margin_left = 24; nb_style.content_margin_right  = 24
	nb_style.content_margin_top  = 5;  nb_style.content_margin_bottom = 5
	name_bar.add_theme_stylebox_override("panel", nb_style)
	name_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_bar.offset_top    = -42
	name_bar.offset_bottom = -8
	name_bar.offset_left   = 200
	name_bar.offset_right  = -200
	name_bar.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	stage_area.add_child(name_bar)
	var name_lbl = Label.new()
	name_lbl.text = "✦  Miss Chan  ✦"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.22, 0.0, 0.42, 0.90))
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_bar.add_child(name_lbl)
	var desc_card = _make_card(Color(0.06, 0.03, 0.15, 0.94), Color(0.60, 0.28, 0.88, 0.55), 2, false)
	desc_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(desc_card)
	var desc_vb = _card_inner(desc_card)
	desc_vb.add_theme_constant_override("separation", 8)
	var perf_hdr_row = HBoxContainer.new()
	perf_hdr_row.add_theme_constant_override("separation", 6)
	desc_vb.add_child(perf_hdr_row)
	perf_hdr_row.add_child(_make_icon(ICON_CAMPFIRE, 18))
	var perf_lbl = Label.new()
	perf_lbl.text = _tr("NIGHT_HEADING_CONCERT") if not _tr("NIGHT_HEADING_CONCERT").begins_with("NIGHT_") \
		else (_tr("NIGHT_CYCLE_TONIGHTS_PERFORMANCE"))
	perf_lbl.add_theme_font_size_override("font_size", 14)
	perf_lbl.add_theme_color_override("font_color", Color(0.90, 0.62, 1.0))
	perf_hdr_row.add_child(perf_lbl)
	_concert_text_label = _make_rtl(14)
	_concert_text_label.add_theme_color_override("default_color", Color(0.88, 0.86, 1.0))
	desc_vb.add_child(_concert_text_label)
	_concert_video_placeholder = _make_card(Color(0.03, 0.0, 0.09, 0.99), Color(0.72, 0.22, 1.0, 0.88), 2, false)
	_concert_video_placeholder.custom_minimum_size = Vector2(0, 150)
	_concert_video_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(_concert_video_placeholder)
	var lyc = CenterContainer.new()
	_card_inner(_concert_video_placeholder).add_child(lyc)
	_concert_lyrics_container = VBoxContainer.new()
	_concert_lyrics_container.custom_minimum_size = Vector2(520, 0)
	lyc.add_child(_concert_lyrics_container)
func _build_honeymoon_section(parent: VBoxContainer) -> void:
	_honeymoon_panel = _make_card(Color(0.13, 0.07, 0.22, 0.96), Color(0.68, 0.42, 0.92, 0.65), 4, false)
	parent.add_child(_honeymoon_panel)
	var inner = _card_inner(_honeymoon_panel)
	var honey_hdr = _section_header(ICON_SPIRIT, "NIGHT_HEADING_HONEYMOON",
		_tr("NIGHT_CYCLE_HONEYMOON_MIRAGE"),
		Color(0.90, 0.70, 1.0))
	inner.add_child(honey_hdr)
	inner.add_child(_hsep(Color(0.72, 0.45, 1.0, 0.30)))
	_honeymoon_label = _make_rtl(15)
	_honeymoon_label.add_theme_color_override("default_color", Color(0.92, 0.88, 1.0))
	inner.add_child(_honeymoon_label)
func _build_footer(parent: VBoxContainer) -> void:
	var sep = HSeparator.new()
	sep.modulate = Color(0.55, 0.30, 0.88, 0.45)
	parent.add_child(sep)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 32)
	parent.add_child(margin)
	var prompt_lbl = Label.new()
	prompt_lbl.text = _tr("NIGHT_PROMPT_DEFAULT") if not _tr("NIGHT_PROMPT_DEFAULT").begins_with("NIGHT_") \
		else (_tr("NIGHT_CYCLE_PRAY_TO_THE_FLYING_SPAGHETTI"))
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 14)
	prompt_lbl.add_theme_color_override("font_color", Color(0.68, 0.88, 1.0, 0.50))
	margin.add_child(prompt_lbl)
func _make_card(bg: Color, border: Color, border_w: int, glow: bool) -> PanelContainer:
	var pc = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left   = border_w; s.border_width_right  = border_w
	s.border_width_top    = border_w; s.border_width_bottom = border_w
	s.border_color = border
	s.corner_radius_top_left    = 12; s.corner_radius_top_right    = 12
	s.corner_radius_bottom_left = 12; s.corner_radius_bottom_right = 12
	if glow:
		s.shadow_color = border; s.shadow_color.a = 0.40; s.shadow_size = 18
	s.content_margin_top = 16; s.content_margin_bottom = 18
	s.content_margin_left = 20; s.content_margin_right = 20
	pc.add_theme_stylebox_override("panel", s)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	return pc
func _card_inner(pc: PanelContainer) -> VBoxContainer:
	return pc.get_child(pc.get_child_count() - 1) as VBoxContainer
func _make_icon(tex: Texture2D, size: int = 20) -> TextureRect:
	var r = TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	return r
func _section_header(icon_tex: Texture2D, key: String, fallback: String, col: Color) -> HBoxContainer:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var icon_rect = _make_icon(icon_tex, 22)
	hb.add_child(icon_rect)
	var title_lbl = Label.new()
	title_lbl.text = _tr(key) if not _tr(key).begins_with("NIGHT_") else fallback
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", col)
	title_lbl.uppercase = true
	hb.add_child(title_lbl)
	return hb
func _hsep(col: Color) -> HSeparator:
	var s = HSeparator.new()
	s.modulate = col
	return s
func _make_rtl(font_size: int = 15) -> RichTextLabel:
	var r = RichTextLabel.new()
	r.fit_content = true
	r.bbcode_enabled = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD
	r.add_theme_font_size_override("normal_font_size", font_size)
	r.add_theme_color_override("default_color", Color(0.90, 0.90, 0.90))
	return r
func _make_live_badge() -> PanelContainer:
	var b = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.85, 0.0, 0.0, 0.95)
	s.corner_radius_top_left    = 6; s.corner_radius_top_right    = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	s.content_margin_left = 12; s.content_margin_right  = 12
	s.content_margin_top  = 4;  s.content_margin_bottom = 4
	b.add_theme_stylebox_override("panel", s)
	var lbl = Label.new()
	lbl.text = "● " + (_tr("NIGHT_LIVE") if not _tr("NIGHT_LIVE").begins_with("NIGHT_") \
		else (_tr("NIGHT_CYCLE_LIVE")))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	b.add_child(lbl)
	var t = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); t.set_loops()
	t.tween_property(b, "modulate:a", 1.0, 0.5)
	t.tween_property(b, "modulate:a", 0.42, 0.5)
	return b
func set_content(payload: Dictionary) -> void:
	if _content_received: return
	_content_received = true
	if _content_failsafe_timer: _content_failsafe_timer.stop()
	var reflection = String(payload.get("reflection_text", ""))
	var concert    = String(payload.get("teacher_chan_text", ""))
	var honeymoon  = String(payload.get("honeymoon_text", ""))
	var prompt     = String(payload.get("prayer_prompt", ""))
	var song_title = String(payload.get("song_title", ""))
	var lyrics: Array = []
	if payload.has("concert_lyrics"):
		var l = payload.get("concert_lyrics")
		if l is Array: lyrics = l
	if concert.strip_edges().is_empty():
		concert = _tr("NIGHT_CONCERT_FALLBACK")
	if lyrics.is_empty() and AIManager and not _should_use_preset():
		_request_ai_lyrics(reflection, concert, song_title, honeymoon, prompt)
		return
	_apply(reflection, concert, lyrics, song_title, honeymoon, prompt)
func _apply(reflection: String, concert: String, lyrics: Array,
			song_title: String, honeymoon: String, _prompt: String,
			_is_fallback: bool = false) -> void:
	var clean = _strip_choices(reflection)
	if not is_instance_valid(_reflection_panel) or not is_instance_valid(_concert_panel):
		return
	_reflection_panel.visible = not clean.strip_edges().is_empty()
	if _reflection_panel.visible: _reflection_label.text = clean
	_honeymoon_panel.visible = not honeymoon.strip_edges().is_empty()
	if _honeymoon_panel.visible: _honeymoon_label.text = honeymoon
	var concert_text := concert
	if concert_text.strip_edges().is_empty():
		concert_text = _tr("NIGHT_CONCERT_FALLBACK")
	var final_lyrics = lyrics if lyrics.size() >= 2 else _get_preset_lyrics()
	var has_concert = not concert_text.strip_edges().is_empty() or final_lyrics.size() > 0
	_concert_panel.visible = has_concert
	if has_concert:
		_concert_text_label.text = concert_text
		var title_str = song_title if not song_title.is_empty() else _tr("NIGHT_SONG_DEFAULT")
		_concert_song_label.text = "♪  " + title_str + "  ♪"
		_animate_concert()
		current_lyrics = final_lyrics
		lyrics_line_index = 0; lyrics_animation_time = 0.0
		if final_lyrics.size() > 0:
			_skip_button.visible = true
			_refresh_lyrics()
		else:
			_finish_concert()
	else:
		_finish_concert()
func _animate_concert() -> void:
	_start_music()
	var pt = create_tween()
	pt.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); pt.set_loops()
	pt.tween_property(_concert_panel, "modulate", Color(1.0, 0.92, 1.0), 1.6)
	pt.tween_property(_concert_panel, "modulate", Color(1.0, 1.0, 1.0),  1.6)
	_concert_tweens.append(pt)
	if _concert_portrait:
		var bt = create_tween()
		bt.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); bt.set_loops()
		bt.tween_property(_concert_portrait, "scale", Vector2(1.05, 1.05), 0.75).set_trans(Tween.TRANS_SINE)
		bt.tween_property(_concert_portrait, "scale", Vector2(1.0,  1.0),  0.75).set_trans(Tween.TRANS_SINE)
		_concert_tweens.append(bt)
		_concert_portrait.pivot_offset = _concert_portrait.size / 2.0
	if _spotlight_node:
		var st = create_tween()
		st.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); st.set_loops()
		st.tween_property(_spotlight_node, "color", Color(1.0, 1.0, 0.28, 0.22), 1.4)
		st.tween_property(_spotlight_node, "color", Color(1.0, 0.88, 0.48, 0.06), 1.4)
		_concert_tweens.append(st)
	if _concert_song_label:
		var sg = create_tween()
		sg.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); sg.set_loops()
		sg.tween_property(_concert_song_label, "scale", Vector2(1.04, 1.04), 1.0).set_trans(Tween.TRANS_SINE)
		sg.tween_property(_concert_song_label, "scale", Vector2(1.0,  1.0),  1.0).set_trans(Tween.TRANS_SINE)
		_concert_tweens.append(sg)
func _refresh_lyrics() -> void:
	if not is_instance_valid(_concert_lyrics_container):
		return
	for c in _concert_lyrics_container.get_children(): c.queue_free()
	var start = max(0, lyrics_line_index - 1)
	var stop  = min(current_lyrics.size(), start + 3)
	for i in range(start, stop):
		var lbl = RichTextLabel.new()
		lbl.bbcode_enabled = true;  lbl.fit_content = true
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.custom_minimum_size.y = 40
		var txt = str(current_lyrics[i])
		if i == lyrics_line_index:
			lbl.text = "[center][wave amp=55 freq=9][rainbow freq=1.1 sat=0.9 val=1.0]%s[/rainbow][/wave][/center]" % txt
			lbl.add_theme_font_size_override("normal_font_size", 28)
			lbl.add_theme_constant_override("outline_size", 3)
			lbl.add_theme_color_override("font_outline_color", Color(0.5, 0.0, 0.5, 0.8))
		elif i == lyrics_line_index - 1:
			lbl.text = "[center][color=#ddaaff]%s[/color][/center]" % txt
			lbl.add_theme_font_size_override("normal_font_size", 17); lbl.modulate.a = 0.50
		else:
			lbl.text = "[center][color=#aaaaee]%s[/color][/center]" % txt
			lbl.add_theme_font_size_override("normal_font_size", 15); lbl.modulate.a = 0.38
		_concert_lyrics_container.add_child(lbl)
func _finish_concert() -> void:
	_skip_button.visible = false
	if not _pray_button.visible:
		_pray_button.visible = true
		_pray_button.modulate.a = 0.0
		var t = create_tween()
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(_pray_button, "modulate:a", 1.0, 0.6)
		for c in _concert_video_placeholder.get_children(): c.queue_free()
		var ended = Label.new()
		ended.text = _tr("NIGHT_CONCERT_ENDED")
		ended.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ended.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		ended.set_anchors_preset(Control.PRESET_FULL_RECT)
		_concert_video_placeholder.add_child(ended)
func _on_pray_pressed() -> void:
	var a = _get_audio()
	if a and a.has_method("play_sfx"): a.play_sfx("happy_click")
	if a and a.has_method("stop_music"):
		a.stop_music(1.0)
	if is_instance_valid(_crowd_player) and _crowd_player.playing:
		var fade := create_tween()
		fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade.tween_property(_crowd_player, "volume_db", -80.0, 1.0)
		fade.tween_callback(func(): if is_instance_valid(_crowd_player): _crowd_player.stop())
	prayer_requested.emit()
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE:
			if _pray_button and _pray_button.visible:
				_on_pray_pressed()
				get_viewport().set_input_as_handled()
			elif _skip_button and _skip_button.visible:
				_on_skip_pressed()
				get_viewport().set_input_as_handled()
func _on_skip_pressed() -> void:
	var a = _get_audio()
	if a and a.has_method("play_sfx"): a.play_sfx("menu_click")
	lyrics_line_index = current_lyrics.size()
	_refresh_lyrics()
	_finish_concert()
func _start_failsafe_timer() -> void:
	_content_failsafe_timer = Timer.new()
	_content_failsafe_timer.wait_time = 35.0
	_content_failsafe_timer.one_shot  = true
	_content_failsafe_timer.timeout.connect(_on_failsafe_timeout)
	add_child(_content_failsafe_timer)
	_content_failsafe_timer.start()
func _on_failsafe_timeout() -> void:
	if _content_received: return
	_apply(
		_tr("NIGHT_REFLECTION_FALLBACK"), _tr("NIGHT_CONCERT_FALLBACK"),
		_get_preset_lyrics(), _tr("NIGHT_SONG_DEFAULT"),
		"", _tr("NIGHT_PROMPT_DEFAULT"), true
	)
func _request_ai_lyrics(refl: String, concert: String, song: String,
						honey: String, prompt: String) -> void:
	_concert_song_label.text = _tr("NIGHT_GENERATING_LYRICS")
	if is_instance_valid(_concert_text_label):
		_concert_text_label.text = concert if not concert.strip_edges().is_empty() else _tr("NIGHT_CONCERT_FALLBACK")
	_show_lyrics_loading_placeholder()
	var ctx = { "purpose": "concert_lyrics", "song_title": song,
				"reflection": refl, "concert_theme": concert }
	AIManager.generate_story(
		_build_lyrics_prompt(refl, song), ctx,
		Callable(self, "_on_ai_lyrics").bind(refl, concert, song, honey, prompt)
	)
func _show_lyrics_loading_placeholder() -> void:
	if not is_instance_valid(_concert_lyrics_container):
		return
	for c in _concert_lyrics_container.get_children():
		c.queue_free()
	var loading_lbl := RichTextLabel.new()
	loading_lbl.bbcode_enabled = true
	loading_lbl.fit_content = true
	loading_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	loading_lbl.custom_minimum_size = Vector2(0, 60)
	loading_lbl.text = "[center][color=#bbaaee]♪  ...  ♪[/color][/center]"
	loading_lbl.add_theme_font_size_override("normal_font_size", 22)
	_concert_lyrics_container.add_child(loading_lbl)
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_loops()
	t.tween_property(loading_lbl, "modulate:a", 0.2, 0.9)
	t.tween_property(loading_lbl, "modulate:a", 1.0, 0.9)
	_concert_tweens.append(t)
func _on_ai_lyrics(resp: Dictionary, refl: String, concert: String,
				   song: String, honey: String, prompt: String) -> void:
	if not is_instance_valid(self) or not is_instance_valid(_concert_lyrics_container):
		return
	var lyrics: Array = []
	if resp.get("success", false):
		var json = JSON.new()
		if json.parse(resp.get("content", "")) == OK:
			if json.data is Array: lyrics = json.data
			elif json.data is Dictionary and json.data.has("lyrics"):
				lyrics = json.data["lyrics"]
	_apply(refl, concert, lyrics if lyrics.size() >= 2 else [],
		   song, honey, prompt, lyrics.size() < 2)
func _build_lyrics_prompt(refl: String, song: String) -> String:
	var lang = LocalizationManager.get_language()
	if lang == "en":
		return """Generate 8-12 lyric lines for Teacher Chan's brainwashing concert.
Context: Title="%s", Events="%s". Style: syrupy cult positivity.
IMPORTANT: Return ONLY a raw JSON list. Example: ["Smile always","Love is duty"]""" % [song, refl]
	else:
		return _tr("NIGHT_SONG_PROMPT") % [song, refl]
func _get_preset_lyrics() -> Array:
	var l = []
	for i in range(1, 11): l.append(_tr("NIGHT_LYRICS_" + str(i)))
	return l
func _should_use_preset() -> bool:
	if not AIManager: return true
	if AIManager.has_method("is_mock_override_enabled") and AIManager.is_mock_override_enabled():
		return true
	var provider_value: Variant = AIManager.get("current_provider")
	if provider_value != null and int(provider_value) == int(AIConfigManager.AIProvider.MOCK_MODE):
		return true
	return AIManager.gemini_api_key.strip_edges().is_empty() \
		and AIManager.openrouter_api_key.strip_edges().is_empty()
func _tr(key: String) -> String:
	var lm = ServiceLocator.get_localization_manager() if ServiceLocator else null
	if lm: return lm.get_translation(key, current_language)
	return key
func _get_audio() -> Node:
	if is_instance_valid(_audio_manager): return _audio_manager
	if ServiceLocator: _audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _start_music() -> void:
	var a = _get_audio()
	if a and a.has_method("play_music") and a.has_method("has_sound"):
		if a.has_sound("night_concert_guitar"):
			a.play_music("night_concert_guitar", true)
			if a.music_player:
				a.music_player.volume_db = -40.0
				var tw = create_tween()
				tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tw.tween_property(a.music_player, "volume_db", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		elif a.has_sound("background_music"):
			a.play_music("background_music", true)
	_start_crowd_ambience(a)
func _start_crowd_ambience(audio_mgr: Node) -> void:
	if is_instance_valid(_crowd_player):
		_crowd_player.stop()
		_crowd_player.queue_free()
		_crowd_player = null
	var crowd_path := "res://1.Codebase/src/assets/music/night_concert_crowd.mp3"
	if not ResourceLoader.exists(crowd_path):
		ErrorReporterBridge.report_warning("NightCycleOverlay", "night_concert_crowd.mp3 not found, skipping crowd ambience")
		return
	var crowd_stream := ResourceLoader.load(crowd_path) as AudioStream
	if crowd_stream == null:
		ErrorReporterBridge.report_warning("NightCycleOverlay", "Failed to load night_concert_crowd.mp3")
		return
	if crowd_stream.has_method("set_loop"):
		crowd_stream.loop = true
	_crowd_player = AudioStreamPlayer.new()
	_crowd_player.stream = crowd_stream
	_crowd_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_crowd_player.pitch_scale = 1.4   
	var music_bus_idx = AudioServer.get_bus_index("Music")
	_crowd_player.bus = "Music" if music_bus_idx != -1 else "Master"
	add_child(_crowd_player)
	_crowd_player.volume_db = -40.0
	_crowd_player.play()
	var crowd_tw = create_tween()
	crowd_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	crowd_tw.tween_property(_crowd_player, "volume_db", -3.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_concert_tweens.append(crowd_tw)
	ErrorReporterBridge.report_info("NightCycleOverlay", "Crowd cheering + guitar sync playing...")
func _create_particles() -> void:
	var p = GPUParticles2D.new()
	p.name = "NightParticles"; add_child(p)
	p.z_index = -5; p.amount = 35; p.lifetime = 6.0
	p.position = Vector2(960, 1100)
	p.process_material = _particle_mat()
	var tex = load("res://1.Codebase/src/assets/icons/crystal.png")
	if tex: p.texture = tex
func _particle_mat() -> ParticleProcessMaterial:
	var m = ParticleProcessMaterial.new()
	m.particle_flag_disable_z  = true
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents     = Vector3(960, 1, 1)
	m.direction = Vector3(0, -1, 0); m.gravity = Vector3(0, -20, 0)
	m.initial_velocity_min = 45.0; m.initial_velocity_max = 90.0
	m.scale_min = 0.08; m.scale_max = 0.28
	m.color = Color(1.0, 1.0, 1.0, 0.28)
	return m
func _strip_choices(text: String) -> String:
	if text.is_empty(): return text
	var clean = text
	for marker in ["[Choice Preview]","[choice preview]","[CHOICE PREVIEW]",
				   "[Choices]","[choices]","[CHOICES]"]:
		var pos = clean.find(marker)
		if pos != -1: clean = clean.substr(0, pos).strip_edges()
	for prefix in ["[Cautious]","[Balanced]","[Reckless]","[Positive]","[Complain]",
				   "[cautious]","[balanced]","[reckless]","[positive]","[complain]"]:
		var pos = clean.find(prefix)
		if pos != -1: clean = clean.substr(0, pos).strip_edges()
	return clean
func _add_stage_lights(panel: PanelContainer) -> void:
	var hues = [0.82, 0.60, 0.72]
	for i in range(3):
		var light = ColorRect.new()
		light.size = Vector2(100, 100)
		light.color = Color.from_hsv(hues[i], 0.88, 1.0, 0.14)
		light.z_index = -1
		panel.add_child(light)
		light.position = Vector2(40 + i * 260, 6)
		_stage_lights.append(light)
		var tw = create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); tw.set_loops()
		tw.tween_property(light, "color:a", 0.30, 1.6 + i * 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(light, "color:a", 0.05, 1.6 + i * 0.45).set_trans(Tween.TRANS_SINE)
		_concert_tweens.append(tw)
