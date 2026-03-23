extends Control
signal close_requested
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ERROR_CONTEXT := "FSMRebirthExplanation"
@onready var title_label: Label = $Root/ContentPanel/Margin/VBox/Header/Title
@onready var header_icon: TextureRect = $Root/ContentPanel/Margin/VBox/Header/HeaderIcon
@onready var close_button: Button = $Root/ContentPanel/Margin/VBox/Header/CloseButton
@onready var subtitle_label: Label = $Root/ContentPanel/Margin/VBox/SubtitleLabel
@onready var content_panel: PanelContainer = $Root/ContentPanel
@onready var margin_container: MarginContainer = $Root/ContentPanel/Margin
@onready var scroll_container: ScrollContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer
@onready var content_vbox: VBoxContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox
@onready var bg_gradient: TextureRect = $Root/BackgroundGradient
@onready var tab_mechanism: Button = $Root/ContentPanel/Margin/VBox/TabBar/TabMechanism
@onready var tab_comparison: Button = $Root/ContentPanel/Margin/VBox/TabBar/TabComparison
@onready var tab_philosophy: Button = $Root/ContentPanel/Margin/VBox/TabBar/TabPhilosophy
@onready var mechanism_section: VBoxContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection
@onready var comparison_section: VBoxContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection
@onready var philosophy_section: VBoxContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection
@onready var mech_card1: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard1
@onready var mech_title1: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard1/CardMargin1/CardVBox1/CardTitle1
@onready var mech_body1: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard1/CardMargin1/CardVBox1/CardBody1
@onready var mech_card2: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard2
@onready var mech_title2: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard2/CardMargin2/CardVBox2/CardTitle2
@onready var mech_body2: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard2/CardMargin2/CardVBox2/CardBody2
@onready var mech_card3: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard3
@onready var mech_title3: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard3/CardMargin3/CardVBox3/CardTitle3
@onready var mech_body3: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard3/CardMargin3/CardVBox3/CardBody3
@onready var mech_card4: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard4
@onready var mech_title4: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard4/CardMargin4/CardVBox4/CardTitle4
@onready var mech_body4: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/MechanismSection/MechanismCard4/CardMargin4/CardVBox4/CardBody4
@onready var comp_intro_label: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompIntro/IntroMargin/IntroLabel
@onready var journal_card: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompColumns/JournalCard
@onready var journal_title: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompColumns/JournalCard/JournalMargin/JournalVBox/JournalTitle
@onready var journal_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompColumns/JournalCard/JournalMargin/JournalVBox/JournalBody
@onready var journal_warning: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompColumns/JournalCard/JournalMargin/JournalVBox/JournalWarning
@onready var fsm_card: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompColumns/FSMCard
@onready var fsm_title: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompColumns/FSMCard/FSMMargin/FSMVBox/FSMTitle
@onready var fsm_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompColumns/FSMCard/FSMMargin/FSMVBox/FSMBody
@onready var effects_card: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/EffectsCard
@onready var effects_title: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/EffectsCard/EffectsMargin/EffectsVBox/EffectsTitle
@onready var ej_label: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/EffectsCard/EffectsMargin/EffectsVBox/EffectsColumns/EffectsJournalCol/EJLabel
@onready var ej_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/EffectsCard/EffectsMargin/EffectsVBox/EffectsColumns/EffectsJournalCol/EJBody
@onready var ef_label: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/EffectsCard/EffectsMargin/EffectsVBox/EffectsColumns/EffectsFSMCol/EFLabel
@onready var ef_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/EffectsCard/EffectsMargin/EffectsVBox/EffectsColumns/EffectsFSMCol/EFBody
@onready var gloria_card: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/GloriaCard
@onready var gloria_image: TextureRect = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/GloriaCard/GloriaMargin/GloriaHBox/GloriaImage
@onready var gloria_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/GloriaCard/GloriaMargin/GloriaHBox/GloriaVBox/GloriaBody
@onready var conseq_card: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/ConsequencesCard
@onready var conseq_title: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/ConsequencesCard/ConseqMargin/ConseqVBox/ConseqTitle
@onready var conseq_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/ConsequencesCard/ConseqMargin/ConseqVBox/ConseqBody
@onready var philo_title: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/PhiloIntro/PhiloIntroMargin/PhiloIntroVBox/PhiloTitle
@onready var philo_intro_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/PhiloIntro/PhiloIntroMargin/PhiloIntroVBox/PhiloIntroBody
@onready var day_cards_container: VBoxContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/DayCardsContainer
@onready var conc_card: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/ConclusionCard
@onready var conc_title: Label = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/ConclusionCard/ConcMargin/ConcVBox/ConcTitle
@onready var conc_body: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/ConclusionCard/ConcMargin/ConcVBox/ConcBody
@onready var conc_gloria: TextureRect = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/ConclusionCard/ConcMargin/ConcVBox/ConcHBox/ConcGloria
@onready var conc_fsm: TextureRect = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/ConclusionCard/ConcMargin/ConcVBox/ConcHBox/ConcFSM
@onready var conc_teacher: TextureRect = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/ConclusionCard/ConcMargin/ConcVBox/ConcHBox/ConcTeacher
var audio_manager: Node = null
var _current_tab: int = 0 
var _card_tweens: Array = []
var _bg_tween: Tween = null
const DAY_ACCENT_COLORS: Array = [
	Color(1.0, 0.84, 0.0),
	Color(0.31, 0.76, 0.97),
	Color(0.65, 0.84, 0.65),
	Color(0.81, 0.58, 0.84),
	Color(1.0, 0.54, 0.40),
	Color(0.95, 0.55, 0.66),
	Color(0.45, 0.78, 0.85),
	Color(0.72, 0.68, 0.95),
]
func _ready() -> void:
	z_index = 200
	_refresh_services()
	_setup_ui()
	_connect_signals()
	_populate_all_content()
	_switch_tab(0)
	UIStyleManager.fade_in(self, 0.5)
	_update_layout()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_start_bg_animation()
	if audio_manager:
		audio_manager.play_music("mountain_king")
func _exit_tree() -> void:
	for t in _card_tweens:
		if t and t.is_valid():
			t.kill()
	_card_tweens.clear()
	if _bg_tween and _bg_tween.is_valid():
		_bg_tween.kill()
	_bg_tween = null
func _refresh_services() -> void:
	if ServiceLocator:
		audio_manager = ServiceLocator.get_audio_manager()
func _setup_ui() -> void:
	if content_panel:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.06, 0.06, 0.12, 0.92)
		panel_style.corner_radius_top_left = 0
		panel_style.corner_radius_top_right = 0
		panel_style.corner_radius_bottom_left = 0
		panel_style.corner_radius_bottom_right = 0
		panel_style.shadow_color = Color(0, 0, 0, 0)
		panel_style.shadow_size = 0
		content_panel.add_theme_stylebox_override("panel", panel_style)
	if title_label:
		title_label.text = _tr("FSM_REBIRTH_TITLE")
		UIStyleManager.add_glow_effect(title_label, Color(1, 0.9, 0.4, 1), 0.4)
	if subtitle_label:
		subtitle_label.text = _tr("FSM_REBIRTH_PHILOSOPHY_INTRO")
		subtitle_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.85, 0.7))
	if header_icon:
		UIStyleManager.pulse_effect(header_icon, 0.06, 2.0)
	if close_button:
		UIStyleManager.apply_button_style(close_button, "danger", "medium")
		UIStyleManager.add_hover_scale_effect(close_button, 1.08)
		UIStyleManager.add_press_feedback(close_button)
		close_button.text = _tr("UI_CLOSE_BUTTON")
	_style_tab_buttons()
	_style_all_cards()
func _style_tab_buttons() -> void:
	var tabs: Array = [tab_mechanism, tab_comparison, tab_philosophy]
	var tab_texts: Array = [
		_tr("FSM_REBIRTH_SECTION_HOW_IT_WORKS"),
		_tr("FSM_REBIRTH_SECTION_COMPARISON"),
		_tr("FSM_REBIRTH_PHILOSOPHY_TITLE"),
	]
	for i in range(tabs.size()):
		var tab: Button = tabs[i]
		if tab:
			tab.text = tab_texts[i]
			UIStyleManager.add_hover_scale_effect(tab, 1.05)
			UIStyleManager.add_press_feedback(tab)
			tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _update_tab_visual(active_index: int) -> void:
	var tabs: Array = [tab_mechanism, tab_comparison, tab_philosophy]
	for i in range(tabs.size()):
		var tab: Button = tabs[i]
		if not tab:
			continue
		if i == active_index:
			var active_style := StyleBoxFlat.new()
			active_style.bg_color = Color(0.35, 0.25, 0.1, 0.9)
			active_style.corner_radius_top_left = 10
			active_style.corner_radius_top_right = 10
			active_style.corner_radius_bottom_left = 10
			active_style.corner_radius_bottom_right = 10
			active_style.border_width_left = 2
			active_style.border_width_top = 2
			active_style.border_width_right = 2
			active_style.border_width_bottom = 2
			active_style.border_color = Color(1, 0.84, 0, 0.8)
			active_style.shadow_color = Color(1, 0.84, 0, 0.25)
			active_style.shadow_size = 6
			active_style.shadow_offset = Vector2(0, 2)
			active_style.content_margin_left = 16
			active_style.content_margin_right = 16
			active_style.content_margin_top = 8
			active_style.content_margin_bottom = 8
			tab.add_theme_stylebox_override("normal", active_style)
			tab.add_theme_stylebox_override("hover", active_style)
			tab.add_theme_stylebox_override("pressed", active_style)
			tab.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
			tab.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.6))
			tab.add_theme_font_size_override("font_size", 17)
		else:
			var inactive_style := StyleBoxFlat.new()
			inactive_style.bg_color = Color(0.12, 0.12, 0.18, 0.7)
			inactive_style.corner_radius_top_left = 10
			inactive_style.corner_radius_top_right = 10
			inactive_style.corner_radius_bottom_left = 10
			inactive_style.corner_radius_bottom_right = 10
			inactive_style.border_width_left = 1
			inactive_style.border_width_top = 1
			inactive_style.border_width_right = 1
			inactive_style.border_width_bottom = 1
			inactive_style.border_color = Color(0.4, 0.4, 0.55, 0.5)
			inactive_style.content_margin_left = 16
			inactive_style.content_margin_right = 16
			inactive_style.content_margin_top = 8
			inactive_style.content_margin_bottom = 8
			var hover_style := inactive_style.duplicate()
			hover_style.bg_color = Color(0.18, 0.18, 0.25, 0.8)
			hover_style.border_color = Color(0.5, 0.5, 0.7, 0.7)
			tab.add_theme_stylebox_override("normal", inactive_style)
			tab.add_theme_stylebox_override("hover", hover_style)
			tab.add_theme_stylebox_override("pressed", inactive_style)
			tab.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
			tab.add_theme_color_override("font_hover_color", Color(0.85, 0.85, 0.95))
			tab.add_theme_font_size_override("font_size", 16)
func _style_all_cards() -> void:
	var mech_cards: Array = [mech_card1, mech_card2, mech_card3, mech_card4]
	var card_accent_colors: Array = [
		Color(0.0, 0.55, 0.35, 0.5),  
		Color(0.1, 0.35, 0.55, 0.5),  
		Color(0.55, 0.2, 0.15, 0.5),  
		Color(0.35, 0.15, 0.45, 0.5), 
	]
	for i in range(mech_cards.size()):
		if mech_cards[i]:
			_apply_card_style(mech_cards[i], card_accent_colors[i])
	var comp_intro: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/ComparisonSection/CompIntro
	if comp_intro:
		_apply_card_style(comp_intro, Color(0.2, 0.18, 0.1, 0.5))
	if journal_card:
		_apply_card_style(journal_card, Color(0.05, 0.3, 0.15, 0.5))
	if fsm_card:
		_apply_card_style(fsm_card, Color(0.4, 0.1, 0.1, 0.5))
	if effects_card:
		_apply_card_style(effects_card, Color(0.3, 0.25, 0.05, 0.5))
	if gloria_card:
		_apply_card_style(gloria_card, Color(0.3, 0.15, 0.35, 0.5))
	if conseq_card:
		_apply_card_style(conseq_card, Color(0.4, 0.15, 0.1, 0.5))
	var philo_intro_card: PanelContainer = $Root/ContentPanel/Margin/VBox/ScrollContainer/ContentVBox/PhilosophySection/PhiloIntro
	if philo_intro_card:
		_apply_card_style(philo_intro_card, Color(0.3, 0.25, 0.05, 0.5))
	if conc_card:
		_apply_card_style(conc_card, Color(0.25, 0.2, 0.05, 0.6))
func _apply_card_style(panel: PanelContainer, accent_bg: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent_bg.r * 0.4 + 0.06, accent_bg.g * 0.4 + 0.06, accent_bg.b * 0.4 + 0.08, 0.88)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent_bg.r + 0.2, accent_bg.g + 0.2, accent_bg.b + 0.2, 0.4)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if tab_mechanism:
		tab_mechanism.pressed.connect(_on_tab_mechanism)
	if tab_comparison:
		tab_comparison.pressed.connect(_on_tab_comparison)
	if tab_philosophy:
		tab_philosophy.pressed.connect(_on_tab_philosophy)
func _on_resized() -> void:
	_update_layout()
func _update_layout() -> void:
	var vp_size = get_viewport_rect().size
	if content_panel:
		content_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		content_panel.custom_minimum_size = vp_size
	if margin_container:
		var horizontal_margin = clampi(int(vp_size.x * 0.04), 28, 60)
		var vertical_margin = clampi(int(vp_size.y * 0.03), 20, 40)
		margin_container.add_theme_constant_override("margin_left", horizontal_margin)
		margin_container.add_theme_constant_override("margin_right", horizontal_margin)
		margin_container.add_theme_constant_override("margin_top", vertical_margin)
		margin_container.add_theme_constant_override("margin_bottom", vertical_margin)
	if scroll_container:
		scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _populate_all_content() -> void:
	_populate_mechanism_content()
	_populate_comparison_content()
	_populate_philosophy_content()
func _populate_mechanism_content() -> void:
	if mech_title1:
		mech_title1.text = "🌅 " + _tr("FSM_REBIRTH_DAILY_LOGIN_TITLE")
	if mech_body1:
		mech_body1.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_DAILY_LOGIN_BODY") + "[/color]"
	if mech_title2:
		mech_title2.text = "📋 " + _tr("FSM_REBIRTH_SECTION_HOW_IT_WORKS")
	if mech_body2:
		mech_body2.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_HOW_TO") + "[/color]"
	if mech_title3:
		mech_title3.text = "⚠️ " + _tr("FSM_REBIRTH_IMPORTANT_NOTE_TITLE")
	if mech_body3:
		mech_body3.text = "[color=#FFB4AB]" + _tr("FSM_REBIRTH_IMPORTANT_NOTE") + "[/color]"
	if mech_title4:
		mech_title4.text = "📜 " + _tr("FSM_REBIRTH_DAILY_RULE_TITLE")
	if mech_body4:
		mech_body4.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_DAILY_RULE") + "[/color]"
func _populate_comparison_content() -> void:
	if comp_intro_label:
		comp_intro_label.text = "[center][color=#FFECB3][font_size=20]" + _tr("FSM_REBIRTH_COMPARISON_INTRO") + "[/font_size][/color][/center]"
	if journal_title:
		journal_title.text = _tr("FSM_REBIRTH_JOURNAL_TITLE")
	if journal_body:
		journal_body.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_JOURNAL_BODY") + "[/color]"
	if journal_warning:
		journal_warning.text = "[color=#FF8A65]" + _tr("FSM_REBIRTH_JOURNAL_WARNING") + "[/color]"
	if fsm_title:
		fsm_title.text = _tr("FSM_REBIRTH_FSM_TITLE")
	if fsm_body:
		fsm_body.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_FSM_BODY") + "[/color]"
	if effects_title:
		effects_title.text = _tr("FSM_REBIRTH_EFFECTS_TITLE")
	if ej_label:
		ej_label.text = "📖 " + _tr("FSM_REBIRTH_EFFECTS_JOURNAL_LABEL")
	if ej_body:
		ej_body.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_EFFECTS_JOURNAL") + "[/color]"
	if ef_label:
		ef_label.text = "🍝 " + _tr("FSM_REBIRTH_EFFECTS_FSM_LABEL")
	if ef_body:
		ef_body.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_EFFECTS_FSM") + "[/color]"
	if gloria_body:
		gloria_body.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_GLORIA") + "[/color]"
	if conseq_title:
		conseq_title.text = "⚡ " + _tr("FSM_REBIRTH_CONSEQUENCES_TITLE")
	if conseq_body:
		conseq_body.text = "[color=#E0E0E0]" + _tr("FSM_REBIRTH_CONSEQUENCES") + "[/color]"
func _populate_philosophy_content() -> void:
	if philo_title:
		philo_title.text = "✨ " + _tr("FSM_REBIRTH_PHILOSOPHY_TITLE")
	if philo_intro_body:
		philo_intro_body.text = "[color=#FFECB3]" + _tr("FSM_REBIRTH_PHILOSOPHY_INTRO") + "[/color]"
	_create_day_cards()
	if conc_title:
		conc_title.text = _tr("FSM_REBIRTH_CONCLUSION_TITLE")
	if conc_body:
		conc_body.text = "[center][color=#FFECB3]" + _tr("FSM_REBIRTH_CONCLUSION_BODY") + "[/color][/center]"
func _create_day_cards() -> void:
	if not day_cards_container:
		return
	for child in day_cards_container.get_children():
		child.queue_free()
	for day in range(1, 9):
		var day_str := str(day)
		var accent: Color = DAY_ACCENT_COLORS[day - 1]
		var card := PanelContainer.new()
		card.layout_mode = 2
		card.clip_contents = true
		_apply_card_style(card, Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.5))
		var bg_image := TextureRect.new()
		var tex = load("res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_%d.png" % day)
		if tex:
			bg_image.texture = tex
		bg_image.layout_mode = 2
		bg_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bg_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bg_image.expand_mode = 1  
		bg_image.stretch_mode = 6  
		bg_image.modulate = Color(1.0, 1.0, 1.0, 0.4)
		card.add_child(bg_image)
		var overlay := ColorRect.new()
		overlay.layout_mode = 2
		overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
		overlay.color = Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.08, 0.6)
		card.add_child(overlay)
		var card_margin := MarginContainer.new()
		card_margin.layout_mode = 2
		card_margin.add_theme_constant_override("margin_left", 28)
		card_margin.add_theme_constant_override("margin_top", 22)
		card_margin.add_theme_constant_override("margin_right", 28)
		card_margin.add_theme_constant_override("margin_bottom", 22)
		card.add_child(card_margin)
		var card_vbox := VBoxContainer.new()
		card_vbox.layout_mode = 2
		card_vbox.add_theme_constant_override("separation", 12)
		card_margin.add_child(card_vbox)
		var title_hbox := HBoxContainer.new()
		title_hbox.layout_mode = 2
		title_hbox.add_theme_constant_override("separation", 12)
		card_vbox.add_child(title_hbox)
		var day_badge := Label.new()
		day_badge.layout_mode = 2
		day_badge.text = "Day %d" % day
		day_badge.add_theme_font_size_override("font_size", 14)
		day_badge.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15))
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = accent
		badge_style.corner_radius_top_left = 8
		badge_style.corner_radius_top_right = 8
		badge_style.corner_radius_bottom_left = 8
		badge_style.corner_radius_bottom_right = 8
		badge_style.content_margin_left = 12
		badge_style.content_margin_right = 12
		badge_style.content_margin_top = 4
		badge_style.content_margin_bottom = 4
		day_badge.add_theme_stylebox_override("normal", badge_style)
		title_hbox.add_child(day_badge)
		var day_title := Label.new()
		day_title.layout_mode = 2
		day_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_title.text = _tr("FSM_REBIRTH_DAY%s_TITLE" % day_str)
		day_title.add_theme_font_size_override("font_size", 22)
		day_title.add_theme_color_override("font_color", accent)
		day_title.autowrap_mode = TextServer.AUTOWRAP_WORD
		title_hbox.add_child(day_title)
		var sep := HSeparator.new()
		sep.layout_mode = 2
		var sep_style := StyleBoxFlat.new()
		sep_style.bg_color = Color(accent.r, accent.g, accent.b, 0.45)
		sep_style.content_margin_top = 1
		sep_style.content_margin_bottom = 1
		sep.add_theme_stylebox_override("separator", sep_style)
		card_vbox.add_child(sep)
		var reality_label := RichTextLabel.new()
		reality_label.layout_mode = 2
		reality_label.bbcode_enabled = true
		reality_label.fit_content = true
		reality_label.add_theme_font_size_override("normal_font_size", 16)
		reality_label.text = "[color=#F0F0F0]" + _tr("FSM_REBIRTH_DAY%s_REALITY" % day_str) + "[/color]"
		card_vbox.add_child(reality_label)
		var sublim_label := RichTextLabel.new()
		sublim_label.layout_mode = 2
		sublim_label.bbcode_enabled = true
		sublim_label.fit_content = true
		sublim_label.add_theme_font_size_override("normal_font_size", 16)
		sublim_label.text = "[color=#B9F6CA]" + _tr("FSM_REBIRTH_DAY%s_SUBLIMATION" % day_str) + "[/color]"
		card_vbox.add_child(sublim_label)
		var meaning_label := RichTextLabel.new()
		meaning_label.layout_mode = 2
		meaning_label.bbcode_enabled = true
		meaning_label.fit_content = true
		meaning_label.add_theme_font_size_override("normal_font_size", 16)
		meaning_label.text = "[color=#FFE082]" + _tr("FSM_REBIRTH_DAY%s_MEANING" % day_str) + "[/color]"
		card_vbox.add_child(meaning_label)
		day_cards_container.add_child(card)
func _on_tab_mechanism() -> void:
	_switch_tab(0)
func _on_tab_comparison() -> void:
	_switch_tab(1)
func _on_tab_philosophy() -> void:
	_switch_tab(2)
func _switch_tab(index: int) -> void:
	if audio_manager and _current_tab != index:
		audio_manager.play_sfx("ui_click", 0.6)
	_current_tab = index
	_update_tab_visual(index)
	if scroll_container:
		scroll_container.scroll_vertical = 0
	var sections: Array = [mechanism_section, comparison_section, philosophy_section]
	for i in range(sections.size()):
		var section = sections[i]
		if not section:
			continue
		if i == index:
			section.show()
			_animate_section_in(section)
		else:
			section.hide()
func _animate_section_in(section: VBoxContainer) -> void:
	if not section:
		return
	for t in _card_tweens:
		if t and t.is_valid():
			t.kill()
	_card_tweens.clear()
	var delay := 0.0
	for child in section.get_children():
		if child is Control:
			child.modulate.a = 0.0
			var tween := create_tween()
			_card_tweens.append(tween)
			tween.tween_property(child, "modulate:a", 1.0, 0.35).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			delay += 0.08
func _start_bg_animation() -> void:
	if not bg_gradient:
		return
	_bg_tween = create_tween()
	_bg_tween.set_loops(0)
	_bg_tween.tween_property(bg_gradient, "modulate:a", 0.5, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bg_tween.tween_property(bg_gradient, "modulate:a", 0.75, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if conc_gloria:
		UIStyleManager.pulse_effect(conc_gloria, 0.04, 2.5)
	if conc_fsm:
		UIStyleManager.pulse_effect(conc_fsm, 0.05, 3.0)
	if conc_teacher:
		UIStyleManager.pulse_effect(conc_teacher, 0.04, 2.8)
	if gloria_image:
		UIStyleManager.pulse_effect(gloria_image, 0.03, 2.0)
func _on_close_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("ui_click", 0.8)
	close_requested.emit()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(queue_free)
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			accept_event()
