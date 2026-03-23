extends Control
const ERROR_CONTEXT := "JournalSystem"
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
signal close_requested
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const UIConstants = preload("res://1.Codebase/src/scripts/ui/ui_constants.gd")
const MarkdownParser = preload("res://1.Codebase/src/scripts/ui/markdown_parser.gd")
const JournalAIParserScript = preload("res://1.Codebase/src/scripts/ui/journal_ai_parser.gd")
const ICON_SAVE = preload("res://1.Codebase/src/assets/ui/icon_save.svg")
const ICON_HOME = preload("res://1.Codebase/src/assets/ui/icon_home.svg")
const ICON_CLOSE = preload("res://1.Codebase/src/assets/ui/icon_close.svg")
const ICON_EDIT = preload("res://1.Codebase/src/assets/ui/icon_edit.svg")
const JOURNAL_EMOTION_ICONS := {
	"frustrated": "res://1.Codebase/src/assets/icons/fire.png",
	"hopeless": "res://1.Codebase/src/assets/icons/abyss.png",
	"angry": "res://1.Codebase/src/assets/icons/beast.png",
	"confused": "res://1.Codebase/src/assets/icons/orb.png",
	"tired": "res://1.Codebase/src/assets/icons/campfire.png",
	"custom": "res://1.Codebase/src/assets/icons/scroll.png",
}
@onready var entries_list: VBoxContainer = $JournalBook/MarginContainer/VBoxContainer/MainContent/RightPanel/ScrollContainer/EntriesList
@onready var custom_entry_overlay: Panel = $CustomEntryOverlay
@onready var custom_input: TextEdit = $CustomEntryOverlay/DialogPanel/MarginContainer/VBoxContainer/CustomInput
@onready var home_button: Button = $JournalBook/MarginContainer/VBoxContainer/Header/HomeButton
@onready var close_button: Button = $JournalBook/MarginContainer/VBoxContainer/Header/CloseButton
@onready var save_button: Button = $JournalBook/MarginContainer/VBoxContainer/Header/SaveButton
@onready var title_label: Label = $JournalBook/MarginContainer/VBoxContainer/Header/Title
@onready var latest_story_title_label: Label = $JournalBook/MarginContainer/VBoxContainer/MainContent/LeftPanel/ContextPanelContainer/ContextPanel/ContextMargin/ContextVBox/LatestStoryLabel
@onready var latest_story_text: RichTextLabel = $JournalBook/MarginContainer/VBoxContainer/MainContent/LeftPanel/ContextPanelContainer/ContextPanel/ContextMargin/ContextVBox/LatestStoryText
@onready var recent_events_title_label: Label = $JournalBook/MarginContainer/VBoxContainer/MainContent/LeftPanel/ContextPanelContainer/ContextPanel/ContextMargin/ContextVBox/RecentEventsLabel
@onready var recent_events_text: RichTextLabel = $JournalBook/MarginContainer/VBoxContainer/MainContent/LeftPanel/ContextPanelContainer/ContextPanel/ContextMargin/ContextVBox/RecentEventsText
@onready var suggestion_status: Label = $JournalBook/MarginContainer/VBoxContainer/MainContent/LeftPanel/SuggestionPanelContainer/SuggestionPanel/SuggestionMargin/SuggestionVBox/SuggestionStatus
@onready var suggestion_buttons_container: VBoxContainer = $JournalBook/MarginContainer/VBoxContainer/MainContent/LeftPanel/SuggestionPanelContainer/SuggestionPanel/SuggestionMargin/SuggestionVBox/SuggestionButtons
@onready var suggestion_header: Label = $JournalBook/MarginContainer/VBoxContainer/MainContent/LeftPanel/SuggestionPanelContainer/SuggestionPanel/SuggestionMargin/SuggestionVBox/SuggestionHeader
@onready var description_label: Label = $JournalBook/MarginContainer/VBoxContainer/Description
@onready var entry_prompt_label: Label = $JournalBook/MarginContainer/VBoxContainer/MainContent/RightPanel/EntryPrompt
@onready var new_entry_label: Label = $JournalBook/MarginContainer/VBoxContainer/NewEntryLabel
@onready var frustrated_button: Button = $JournalBook/MarginContainer/VBoxContainer/PresetPanel/PresetMargin/PresetVBox/ResponseOptions/FrustratedButton
@onready var hopeless_button: Button = $JournalBook/MarginContainer/VBoxContainer/PresetPanel/PresetMargin/PresetVBox/ResponseOptions/HopelessButton
@onready var angry_button: Button = $JournalBook/MarginContainer/VBoxContainer/PresetPanel/PresetMargin/PresetVBox/ResponseOptions/AngryButton
@onready var confused_button: Button = $JournalBook/MarginContainer/VBoxContainer/PresetPanel/PresetMargin/PresetVBox/ResponseOptions2/ConfusedButton
@onready var tired_button: Button = $JournalBook/MarginContainer/VBoxContainer/PresetPanel/PresetMargin/PresetVBox/ResponseOptions2/TiredButton
@onready var custom_button: Button = $JournalBook/MarginContainer/VBoxContainer/PresetPanel/PresetMargin/PresetVBox/ResponseOptions2/CustomButton
@onready var submit_custom_button: Button = $CustomEntryOverlay/DialogPanel/MarginContainer/VBoxContainer/ButtonsContainer/SubmitCustomButton
@onready var cancel_custom_button: Button = $CustomEntryOverlay/DialogPanel/MarginContainer/VBoxContainer/ButtonsContainer/CancelCustomButton
const PRESET_RESPONSES = {
	"frustrated": {
		"icon_path": JOURNAL_EMOTION_ICONS["frustrated"],
		"text_key": "JOURNAL_PRESET_FRUSTRATED",
		"reality_gain": 3,
	},
	"hopeless": {
		"icon_path": JOURNAL_EMOTION_ICONS["hopeless"],
		"text_key": "JOURNAL_PRESET_HOPELESS",
		"reality_gain": 5,
	},
	"angry": {
		"icon_path": JOURNAL_EMOTION_ICONS["angry"],
		"text_key": "JOURNAL_PRESET_ANGRY",
		"reality_gain": 4,
	},
	"confused": {
		"icon_path": JOURNAL_EMOTION_ICONS["confused"],
		"text_key": "JOURNAL_PRESET_CONFUSED",
		"reality_gain": 2,
	},
	"tired": {
		"icon_path": JOURNAL_EMOTION_ICONS["tired"],
		"text_key": "JOURNAL_PRESET_EXHAUSTED",
		"reality_gain": 3,
	},
}
var journal_entries: Array = []
var _pending_summary_jobs: Dictionary = { }
var _language: String = "en"
var _close_signal_emitted: bool = false
const MAX_SUGGESTIONS := GameConstants.Journal.MAX_SUGGESTIONS
const SUGGESTION_WORD_LIMIT := GameConstants.Journal.SUGGESTION_WORD_LIMIT
const SUMMARY_WORD_LIMIT := GameConstants.Journal.SUMMARY_WORD_LIMIT
const JOURNAL_NOTE_TAGS := ["journal"]
const SUGGESTION_TIMEOUT_SECONDS := GameConstants.Journal.SUGGESTION_TIMEOUT_SECONDS
const SUMMARY_REQUEST_TIMEOUT_SECONDS := 15.0
const MAX_SUMMARY_QUEUE_SIZE := 12
var _summary_queue: Array = []
var _summary_in_flight: bool = false
var _suggestion_in_flight: bool = false
var _suggestion_refresh_pending: bool = false
var _suggestion_timeout_timer: Timer = null
var _summary_timeout_timer: Timer = null
var _active_summary_entry_id: String = ""
var _entry_card_cache: Dictionary = { }
var _empty_state_label: Label = null
var _audio_manager: Node = null
var _is_shutting_down: bool = false
const GLORIA_DIARY_PEEK_THRESHOLD := GameConstants.Gloria.DIARY_PEEK_THRESHOLD
const GLORIA_DIARY_VERDICT_THRESHOLD := GameConstants.Gloria.DIARY_VERDICT_THRESHOLD
const META_KEY_GLORIA_PEEK_SHOWN := GameConstants.Gloria.META_DIARY_PEEK_SHOWN
const META_KEY_GLORIA_VERDICT_PENDING := GameConstants.Gloria.META_DIARY_VERDICT_PENDING
const META_KEY_GLORIA_VERDICT_SHOWN := GameConstants.Gloria.META_DIARY_VERDICT_SHOWN
const GLORIA_EMBARRASSED_TEXTURE = preload("res://1.Codebase/src/assets/characters/gloria_protagonis_embarrassed.png")
var _gloria_peek_banner: PanelContainer = null
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_is_shutting_down = true
		_abort_pending_summary_requests()
		_emit_close_requested()
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, _language)
	return key
func _should_force_mock() -> bool:
	if not AIManager:
		return true
	return AIManager.gemini_api_key.strip_edges().is_empty() and AIManager.openrouter_api_key.strip_edges().is_empty()
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_language = GameState.current_language if GameState else (LocalizationManager.get_language() if LocalizationManager else "en")
	if _suggestion_timeout_timer == null:
		_suggestion_timeout_timer = Timer.new()
		_suggestion_timeout_timer.one_shot = true
		add_child(_suggestion_timeout_timer)
		_suggestion_timeout_timer.timeout.connect(_on_suggestion_timeout)
	if home_button and not home_button.pressed.is_connected(Callable(self, "_on_home_pressed")):
		home_button.pressed.connect(_on_home_pressed)
	if LocalizationManager and not LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.connect(_on_language_changed)
	_connect_button_sounds()
	_apply_modern_styling()
	_apply_language_texts()
	var _audio := _get_audio_manager()
	if _audio and _audio.has_method("is_music_playing") and not _audio.is_music_playing():
		if _audio.has_method("play_music"):
			_audio.play_music("background_music", true)
	load_journal()
	refresh_entries_display()
	_load_context_preview()
	_seed_initial_suggestions()
	_check_gloria_diary_reactions()
	var book_panel = $JournalBook
	if book_panel:
		UIStyleManager.fade_in(book_panel, 0.4)
		UIStyleManager.slide_in_from_bottom(book_panel, 0.5, 25.0)
func _exit_tree() -> void:
	if LocalizationManager and LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE:
			_on_home_pressed()
			get_viewport().set_input_as_handled()
func _apply_modern_styling() -> void:
	var book_panel = $JournalBook
	if book_panel:
		book_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		UIStyleManager.apply_panel_style(book_panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	if home_button:
		UIStyleManager.apply_button_style(home_button, "primary", "medium")
		home_button.icon = ICON_HOME
		home_button.text = ""
		home_button.expand_icon = true
		home_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyleManager.add_hover_scale_effect(home_button, 1.06)
		UIStyleManager.add_press_feedback(home_button)
		home_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if close_button:
		UIStyleManager.apply_button_style(close_button, "secondary", "medium")
		close_button.icon = ICON_CLOSE
		close_button.text = ""
		close_button.expand_icon = true
		close_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyleManager.add_hover_scale_effect(close_button, 1.06)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if save_button:
		UIStyleManager.apply_button_style(save_button, "success", "medium")
		save_button.icon = ICON_SAVE
		save_button.text = _tr("JOURNAL_SYSTEM_SAVE")
		save_button.expand_icon = true
		save_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIStyleManager.add_hover_scale_effect(save_button, 1.06)
		UIStyleManager.add_press_feedback(save_button)
	var context_panel = get_node_or_null("JournalBook/MarginContainer/VBoxContainer/ContextPanelContainer/ContextPanel")
	if context_panel:
		UIStyleManager.apply_panel_style(context_panel, 0.92, UIStyleManager.CORNER_RADIUS_MEDIUM)
	var suggestion_panel = get_node_or_null("JournalBook/MarginContainer/VBoxContainer/SuggestionPanelContainer/SuggestionPanel")
	if suggestion_panel:
		UIStyleManager.apply_panel_style(suggestion_panel, 0.92, UIStyleManager.CORNER_RADIUS_MEDIUM)
	var button_configs = [
		{ "button": frustrated_button, "color": UIConstants.COLOR_ACCENT_ORANGE },
		{ "button": hopeless_button, "color": Color(0.6, 0.6, 0.8) },
		{ "button": angry_button, "color": UIConstants.COLOR_ERROR },
		{ "button": confused_button, "color": UIConstants.COLOR_WARNING },
		{ "button": tired_button, "color": Color(0.7, 0.7, 0.9) },
		{ "button": custom_button, "color": UIConstants.COLOR_ACCENT_BLUE, "icon": ICON_EDIT },
	]
	for config in button_configs:
		var btn = config.get("button")
		if btn:
			UIStyleManager.apply_button_style(btn, "primary", "medium")
			UIStyleManager.add_hover_scale_effect(btn, 1.05)
			UIStyleManager.add_press_feedback(btn)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var accent_color = config.get("color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", accent_color)
			if config.has("icon"):
				btn.icon = config.get("icon")
				btn.expand_icon = true
	if submit_custom_button:
		UIStyleManager.apply_button_style(submit_custom_button, "success", "medium")
		UIStyleManager.add_hover_scale_effect(submit_custom_button, 1.05)
		UIStyleManager.add_press_feedback(submit_custom_button)
	if cancel_custom_button:
		UIStyleManager.apply_button_style(cancel_custom_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(cancel_custom_button, 1.05)
		UIStyleManager.add_press_feedback(cancel_custom_button)
func load_journal() -> void:
	if GameState:
		journal_entries = GameState.get_journal_entries()
	else:
		journal_entries = []
	if journal_entries.is_empty():
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "No saved journal entries found; starting fresh")
	else:
		for i in range(journal_entries.size()):
			var entry = journal_entries[i]
			if not (entry is Dictionary):
				entry = { }
			if not entry.has("id"):
				entry["id"] = "%s_%d" % [str(Time.get_unix_time_from_system()), Time.get_ticks_msec() + i]
			if not entry.has("emoji"):
				entry["emoji"] = ""
			if not entry.has("icon_path"):
				entry["icon_path"] = _resolve_entry_icon_path(entry)
			if not entry.has("type"):
				entry["type"] = "legacy"
			if not entry.has("source"):
				entry["source"] = "legacy"
			if not entry.has("reality_gain"):
				entry["reality_gain"] = 0
			if not entry.has("ai_summary"):
				entry["ai_summary"] = ""
			if not entry.has("ai_summary_pending"):
				entry["ai_summary_pending"] = false
			journal_entries[i] = entry
			_debug_log("Journal loaded successfully. Total entries: %d" % journal_entries.size())
func _reload_entries_from_state() -> void:
	if not GameState:
		return
	var stored_entries = GameState.get_journal_entries()
	if stored_entries is Array:
		journal_entries = (stored_entries as Array).duplicate(true)
func save_journal() -> void:
	if GameState:
		GameState.set_journal_entries(journal_entries)
	var success = GameState.save_game()
	if success:
		_debug_log("Journal saved successfully. Total entries: %d" % journal_entries.size())
	else:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Failed to save journal")
		var error_label = Label.new()
		error_label.text = _tr("JOURNAL_SAVE_FAILED")
		error_label.add_theme_color_override("font_color", UIConstants.COLOR_ERROR)
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if is_instance_valid(entries_list):
			entries_list.add_child(error_label)
			entries_list.move_child(error_label, 0)
func add_entry(emotion_type: String, custom_text: String = "") -> void:
	var entry_id = "%s_%d" % [str(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	var timestamp = Time.get_datetime_string_from_system()
	var entry: Dictionary = { }
	var achievement_system = ServiceLocator.get_achievement_system() if ServiceLocator else null
	if achievement_system:
		achievement_system.check_journal_entry()
	var trimmed_text := custom_text.strip_edges()
	if trimmed_text.is_empty():
		var preset = PRESET_RESPONSES.get(emotion_type, PRESET_RESPONSES["frustrated"])
		var preset_text := ""
		var text_key: String = str(preset.get("text_key", ""))
		if not text_key.is_empty():
			preset_text = _tr(text_key)
		entry = {
			"id": entry_id,
			"timestamp": timestamp,
			"icon_path": str(preset.get("icon_path", "")),
			"text": preset_text,
			"type": emotion_type,
			"source": "preset",
			"reality_gain": preset["reality_gain"],
			"ai_summary": "",
			"ai_summary_pending": true,
		}
		GameState.modify_reality_score(preset["reality_gain"])
	else:
		entry = {
			"id": entry_id,
			"timestamp": timestamp,
			"icon_path": JOURNAL_EMOTION_ICONS["custom"],
			"text": trimmed_text,
			"type": emotion_type if emotion_type != "custom" else "custom",
			"source": "custom",
			"reality_gain": 5,
			"ai_summary": "",
			"ai_summary_pending": true,
		}
		GameState.modify_reality_score(5)
	journal_entries.append(entry)
	var AchievementSystem = ServiceLocator.get_achievement_system() if ServiceLocator else null
	if AchievementSystem:
		AchievementSystem.check_journal_entry()
	_register_entry_note(entry)
	save_journal()
	refresh_entries_display()
	_generate_entry_summary(entry_id, entry)
	_request_ai_suggestions()
	show_feedback(entry)
	_check_gloria_diary_reactions()
func refresh_entries_display() -> void:
	if not is_instance_valid(entries_list):
		return
	if journal_entries.is_empty():
		_show_empty_state()
		_cleanup_unused_entry_cards([])
		return
	_hide_empty_state()
	var desired_ids: Array[String] = []
	var ordered_entries = journal_entries.duplicate(true)
	ordered_entries.reverse()
	for idx in range(ordered_entries.size()):
		var entry = ordered_entries[idx]
		var entry_id := str(entry.get("id", ""))
		if entry_id.is_empty():
			continue
		desired_ids.append(entry_id)
		var card := _ensure_entry_card(entry_id, entry)
		if card.get_parent() != entries_list:
			entries_list.add_child(card)
		entries_list.move_child(card, idx)
	_cleanup_unused_entry_cards(desired_ids)
func _ensure_entry_card(entry_id: String, entry: Dictionary) -> PanelContainer:
	var checksum := _entry_checksum(entry)
	if _entry_card_cache.has(entry_id):
		var cached: Dictionary = _entry_card_cache[entry_id]
		var node: PanelContainer = cached.get("node")
		if not is_instance_valid(node):
			_entry_card_cache.erase(entry_id)
		else:
			if cached.get("checksum", "") != checksum:
				_update_entry_card(node, entry)
				cached["checksum"] = checksum
			return node
	var new_card := _build_entry_card(entry)
	_entry_card_cache[entry_id] = {
		"node": new_card,
		"checksum": checksum,
	}
	return new_card
func _entry_checksum(entry: Dictionary) -> String:
	return "%s|%s|%s|%s|%s|%s" % [
		str(entry.get("id", "")),
		_resolve_entry_icon_path(entry),
		str(entry.get("timestamp", "")),
		str(entry.get("text", "")),
		str(entry.get("ai_summary", "")),
		str(entry.get("ai_summary_pending", false)),
	]
func _build_entry_card(entry: Dictionary) -> PanelContainer:
	var container := PanelContainer.new()
	UIStyleManager.apply_panel_style(container, 0.92, UIStyleManager.CORNER_RADIUS_MEDIUM)
	container.name = "JournalEntry_%s" % entry.get("id", "unknown")
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UIConstants.MARGIN_MEDIUM)
	margin.add_theme_constant_override("margin_top", UIConstants.MARGIN_MEDIUM)
	margin.add_theme_constant_override("margin_right", UIConstants.MARGIN_MEDIUM)
	margin.add_theme_constant_override("margin_bottom", UIConstants.MARGIN_MEDIUM)
	container.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
	margin.add_child(vbox)
	var header_box := HBoxContainer.new()
	header_box.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
	vbox.add_child(header_box)
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_box.add_child(icon_rect)
	var time_label := Label.new()
	time_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_TINY)
	time_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(time_label)
	var gain_label := Label.new()
	gain_label.add_theme_color_override("font_color", UIConstants.COLOR_SUCCESS)
	gain_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SMALL)
	header_box.add_child(gain_label)
	var text_label := RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.add_theme_font_size_override("normal_font_size", UIConstants.FONT_SIZE_BODY)
	text_label.add_theme_color_override("default_color", UIConstants.COLOR_TITLE)
	text_label.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(text_label)
	var pending_box := PanelContainer.new()
	var pending_style := StyleBoxFlat.new()
	pending_style.bg_color = Color(0.12, 0.14, 0.18, 0.7)
	pending_style.set_corner_radius_all(UIConstants.CORNER_RADIUS_SMALL)
	pending_style.set_border_width_all(UIConstants.BORDER_WIDTH)
	pending_style.border_color = Color(0.85, 0.8, 0.5, 0.3)
	pending_box.add_theme_stylebox_override("panel", pending_style)
	var pending_margin := MarginContainer.new()
	pending_margin.add_theme_constant_override("margin_left", UIConstants.MARGIN_SMALL)
	pending_margin.add_theme_constant_override("margin_top", UIConstants.MARGIN_SMALL)
	pending_margin.add_theme_constant_override("margin_right", UIConstants.MARGIN_SMALL)
	pending_margin.add_theme_constant_override("margin_bottom", UIConstants.MARGIN_SMALL)
	pending_box.add_child(pending_margin)
	var pending_label := Label.new()
	pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	pending_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SMALL)
	pending_label.add_theme_color_override("font_color", UIConstants.COLOR_WARNING)
	pending_margin.add_child(pending_label)
	vbox.add_child(pending_box)
	var summary_box := PanelContainer.new()
	var summary_style := StyleBoxFlat.new()
	summary_style.bg_color = Color(0.1, 0.15, 0.22, 0.8)
	summary_style.set_corner_radius_all(UIConstants.CORNER_RADIUS_SMALL)
	summary_style.set_border_width_all(UIConstants.BORDER_WIDTH)
	summary_style.border_color = UIConstants.COLOR_ACCENT_BLUE
	summary_box.add_theme_stylebox_override("panel", summary_style)
	var summary_margin := MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", UIConstants.MARGIN_SMALL)
	summary_margin.add_theme_constant_override("margin_top", UIConstants.MARGIN_SMALL)
	summary_margin.add_theme_constant_override("margin_right", UIConstants.MARGIN_SMALL)
	summary_margin.add_theme_constant_override("margin_bottom", UIConstants.MARGIN_SMALL)
	summary_box.add_child(summary_margin)
	var summary_label := Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	summary_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SMALL)
	summary_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_HIGHLIGHT)
	summary_margin.add_child(summary_label)
	vbox.add_child(summary_box)
	container.set_meta(
		"refs",
		{
			"icon": icon_rect,
			"timestamp": time_label,
			"gain": gain_label,
			"text": text_label,
			"pending_box": pending_box,
			"pending_label": pending_label,
			"summary_box": summary_box,
			"summary_label": summary_label,
		},
	)
	_update_entry_card(container, entry)
	return container
func _update_entry_card(card: PanelContainer, entry: Dictionary) -> void:
	var refs: Dictionary = card.get_meta("refs", { })
	var icon_rect: TextureRect = refs.get("icon")
	var time_label: Label = refs.get("timestamp")
	var gain_label: Label = refs.get("gain")
	var text_label: RichTextLabel = refs.get("text")
	var pending_box: PanelContainer = refs.get("pending_box")
	var pending_label: Label = refs.get("pending_label")
	var summary_box: PanelContainer = refs.get("summary_box")
	var summary_label: Label = refs.get("summary_label")
	if icon_rect:
		var icon_path := _resolve_entry_icon_path(entry)
		if icon_path.is_empty():
			icon_rect.texture = null
			icon_rect.visible = false
		else:
			icon_rect.texture = load(icon_path)
			icon_rect.visible = icon_rect.texture != null
	if time_label:
		time_label.text = " " + str(entry.get("timestamp", Time.get_datetime_string_from_system()))
	if gain_label:
		gain_label.text = _tr("JOURNAL_REALITY_GAIN") % entry.get("reality_gain", 0)
	if text_label:
		text_label.text = str(entry.get("text", ""))
	var pending: bool = bool(entry.get("ai_summary_pending", false))
	var summary_text: String = str(entry.get("ai_summary", "")).strip_edges()
	if pending:
		if pending_box:
			pending_box.visible = true
		if pending_label:
			pending_label.text = _tr("JOURNAL_AI_GENERATING")
		if summary_box:
			summary_box.visible = false
	else:
		if pending_box:
			pending_box.visible = false
		if summary_box:
			if summary_text.is_empty():
				summary_box.visible = false
			else:
				summary_box.visible = true
				if summary_label:
					summary_label.text = summary_text
func _resolve_entry_icon_path(entry: Dictionary) -> String:
	if not (entry is Dictionary):
		return ""
	var icon_path := str(entry.get("icon_path", "")).strip_edges()
	if not icon_path.is_empty():
		return icon_path
	var entry_type := str(entry.get("type", "")).strip_edges()
	if JOURNAL_EMOTION_ICONS.has(entry_type):
		return str(JOURNAL_EMOTION_ICONS[entry_type])
	return ""
func _cleanup_unused_entry_cards(desired_ids: Array[String]) -> void:
	var desired_set: Array[String] = desired_ids.duplicate()
	for entry_id in _entry_card_cache.keys():
		if desired_set.has(entry_id):
			continue
		var cached: Dictionary = _entry_card_cache[entry_id]
		var node: PanelContainer = cached.get("node")
		if is_instance_valid(node):
			node.queue_free()
		_entry_card_cache.erase(entry_id)
func _show_empty_state() -> void:
	if _empty_state_label and is_instance_valid(_empty_state_label):
		return
	var label := Label.new()
	label.text = _tr("JOURNAL_EMPTY_STATE")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	entries_list.add_child(label)
	_empty_state_label = label
func _hide_empty_state() -> void:
	if _empty_state_label and is_instance_valid(_empty_state_label):
		_empty_state_label.queue_free()
	_empty_state_label = null
func _load_context_preview() -> void:
	if not is_instance_valid(latest_story_text) or not GameState:
		return
	latest_story_title_label.text = _tr("JOURNAL_SECTION_LATEST_STORY")
	recent_events_title_label.text = _tr("JOURNAL_SECTION_RECENT_EVENTS")
	suggestion_header.text = _tr("JOURNAL_SECTION_AI_SUGGESTIONS")
	var story_summary = GameState.get_latest_story_summary("")
	if not story_summary.is_empty():
		latest_story_text.text = story_summary
	elif GameState.is_story_summary_pending():
		_use_fallback_summary()
	else:
		var story_raw = GameState.get_latest_story_text("")
		if story_raw.strip_edges().is_empty():
			latest_story_text.text = "[i]%s[/i]" % _tr("JOURNAL_NO_STORY")
		else:
			_use_fallback_summary()
	var events = GameState.get_recent_event_notes(5, _language)
	if events.is_empty():
		recent_events_text.text = "[i]%s[/i]" % _tr("JOURNAL_NO_MILESTONES")
	else:
		var builder := ""
		for line in events:
			builder += "• " + line + "\n"
		recent_events_text.text = builder.strip_edges()
var _story_summary_in_flight: bool = false
func _request_story_summary() -> void:
	if _is_shutting_down:
		return
	if _story_summary_in_flight:
		return
	if not AIManager:
		_use_fallback_summary()
		return
	var story_raw = GameState.get_latest_story_text("")
	var story_clean = _extract_clean_story_text(story_raw)
	if story_clean.is_empty():
		return
	_story_summary_in_flight = true
	var prompt := _build_story_summary_prompt(story_clean)
	var context := {
		"purpose": "journal_story_summary",
		"language": _language,
		"bypass_rate_limit": true,
	}
	if _should_force_mock():
		context["force_mock"] = true
	AIManager.generate_story(prompt, context, Callable(self, "_on_story_summary_generated"))
func _build_story_summary_prompt(story_text: String) -> String:
	return JournalAIParserScript.build_story_summary_prompt(story_text, Callable(self, "_tr"))
func _on_story_summary_generated(response: Dictionary) -> void:
	if _is_shutting_down:
		return
	_story_summary_in_flight = false
	if not bool(response.get("success", false)):
		_use_fallback_summary()
		return
	var summary := str(response.get("content", "")).strip_edges()
	summary = summary.replace("\"", "").replace("'", "")
	if summary.is_empty():
		_use_fallback_summary()
		return
	var max_summary_chars := 60 if _language == "zh" else 150
	if summary.length() > max_summary_chars:
		summary = summary.substr(0, max_summary_chars) + "..."
	GameState.set_latest_story_summary(summary)
	if is_instance_valid(latest_story_text):
		latest_story_text.text = summary
func _use_fallback_summary() -> void:
	var story_raw = GameState.get_latest_story_text("")
	var story_clean = _extract_clean_story_text(story_raw)
	if story_clean.is_empty():
		if is_instance_valid(latest_story_text):
			latest_story_text.text = "[i]%s[/i]" % _tr("JOURNAL_NO_STORY")
		return
	var max_chars := 60 if _language == "zh" else 150
	var fallback: String = story_clean
	if fallback.length() > max_chars:
		fallback = fallback.substr(0, max_chars) + "..."
	GameState.set_latest_story_summary(fallback)
	if is_instance_valid(latest_story_text):
		latest_story_text.text = fallback
func _extract_clean_story_text(raw_text: String) -> String:
	return JournalAIParserScript.extract_clean_story_text(raw_text)
func _apply_language_texts() -> void:
	if not LocalizationManager:
		return
	description_label.text = LocalizationManager.get_translation("UI_JOURNAL_DESCRIPTION", _language)
	entry_prompt_label.text = LocalizationManager.get_translation("UI_JOURNAL_ENTRY_PROMPT", _language)
	frustrated_button.text = LocalizationManager.get_translation("UI_JOURNAL_BUTTON_FRUSTRATED", _language)
	hopeless_button.text = LocalizationManager.get_translation("UI_JOURNAL_BUTTON_HOPELESS", _language)
	angry_button.text = LocalizationManager.get_translation("UI_JOURNAL_BUTTON_ANGRY", _language)
	confused_button.text = LocalizationManager.get_translation("UI_JOURNAL_BUTTON_CONFUSED", _language)
	tired_button.text = LocalizationManager.get_translation("UI_JOURNAL_BUTTON_TIRED", _language)
	custom_button.text = LocalizationManager.get_translation("UI_JOURNAL_BUTTON_CUSTOM", _language)
	if new_entry_label:
		new_entry_label.text = _tr("JOURNAL_SYSTEM_WRITE_A_NEW_JOURNAL_ENTRY")
	if title_label:
		title_label.text = _tr("JOURNAL_SYSTEM_PERSONAL_JOURNAL")
	if suggestion_status:
		suggestion_status.text = LocalizationManager.get_translation("JOURNAL_LOADING_SUGGESTIONS", _language)
	if suggestion_header:
		suggestion_header.text = LocalizationManager.get_translation("JOURNAL_SECTION_AI_SUGGESTIONS", _language)
	if submit_custom_button:
		submit_custom_button.text = _tr("JOURNAL_SYSTEM_SUBMIT")
	if cancel_custom_button:
		cancel_custom_button.text = _tr("JOURNAL_SYSTEM_CANCEL")
	if custom_input:
		custom_input.placeholder_text = _tr("JOURNAL_SYSTEM_WRITE_YOUR_TRUE_FEELINGS")
	if save_button:
		save_button.text = _tr("JOURNAL_SYSTEM_SAVE_2")
func _on_language_changed(new_language: String) -> void:
	if _is_shutting_down:
		return
	_language = new_language
	_apply_language_texts()
	_load_context_preview()
	refresh_entries_display()
	_seed_initial_suggestions()
func _seed_initial_suggestions() -> void:
	if not suggestion_status:
		return
	_suggestion_in_flight = false
	_suggestion_refresh_pending = false
	_cancel_suggestion_timeout()
	_populate_suggestion_buttons(_fallback_suggestions())
func _request_ai_suggestions() -> void:
	if _is_shutting_down:
		return
	for child in suggestion_buttons_container.get_children():
		child.queue_free()
	if not suggestion_status:
		return
	if _suggestion_in_flight:
		_suggestion_refresh_pending = true
		return
	if not AIManager:
		_suggestion_in_flight = false
		suggestion_status.text = _tr("JOURNAL_AI_FALLBACK")
		_populate_suggestion_buttons(_fallback_suggestions())
		_process_summary_queue()
		_cancel_suggestion_timeout()
		return
	suggestion_status.text = _tr("JOURNAL_LOADING_SUGGESTIONS")
	var recent_events = GameState.get_recent_event_notes(5, _language)
	var latest_story = GameState.get_latest_story_text("")
	var stats := {
		"reality": GameState.reality_score,
		"positive": GameState.positive_energy,
		"entropy": GameState.entropy_level,
	}
	var events_text := ""
	if recent_events.size() > 0:
		events_text = "\n".join(recent_events)
	else:
		events_text = _tr("JOURNAL_NO_EVENTS")
	var story_excerpt = latest_story.strip_edges()
	if story_excerpt.is_empty():
		story_excerpt = _tr("JOURNAL_NO_NARRATIVE")
	var prompt = _build_suggestion_prompt(story_excerpt, events_text, stats)
	var context = {
		"purpose": "journal_prompt",
		"language": _language,
		"reality_score": stats["reality"],
		"positive_energy": stats["positive"],
		"entropy_level": stats["entropy"],
		"expected_schema": "journal_suggestions_v1",
		"stats": stats.duplicate(true),
		"bypass_rate_limit": true,
	}
	if _should_force_mock():
		context["force_mock"] = true
	var callback = Callable(self, "_on_suggestions_generated")
	_suggestion_in_flight = true
	_start_suggestion_timeout()
	_debug_log("[JournalSystem] Requesting AI suggestions. Prompt length: %d, force_mock: %s" % [prompt.length(), context.get("force_mock", false)])
	_debug_log("[JournalSystem] Prompt preview: %s" % prompt.left(300))
	AIManager.generate_story(prompt, context, callback)
func _start_suggestion_timeout() -> void:
	if _suggestion_timeout_timer:
		_suggestion_timeout_timer.stop()
		_suggestion_timeout_timer.start(SUGGESTION_TIMEOUT_SECONDS)
func _cancel_suggestion_timeout() -> void:
	if _suggestion_timeout_timer:
		_suggestion_timeout_timer.stop()
func _on_suggestion_timeout() -> void:
	if _is_shutting_down:
		return
	if not _suggestion_in_flight:
		return
	_suggestion_in_flight = false
	suggestion_status.text = _tr("JOURNAL_AI_FALLBACK")
	_populate_suggestion_buttons(_fallback_suggestions())
	_process_summary_queue()
func _build_suggestion_prompt(story_excerpt: String, events_text: String, stats: Dictionary) -> String:
	return JournalAIParserScript.build_suggestion_prompt(
		story_excerpt, events_text, stats,
		Callable(self, "_tr"), _language, MAX_SUGGESTIONS, SUGGESTION_WORD_LIMIT
	)
func _fallback_suggestions() -> Array[String]:
	return JournalAIParserScript.fallback_suggestions(Callable(self, "_tr"))
func _parse_suggestions(raw_text: String) -> Array[String]:
	return JournalAIParserScript.parse_suggestions(raw_text, MAX_SUGGESTIONS)
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func _play_sfx(sfx_name: String) -> void:
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_name)
func _connect_button_sounds() -> void:
	var menu_click_buttons = [
		home_button, close_button,
		frustrated_button, hopeless_button, angry_button,
		confused_button, tired_button, custom_button,
		cancel_custom_button
	]
	for btn in menu_click_buttons:
		if btn:
			if not btn.pressed.is_connected(_play_sfx.bind("menu_click")):
				btn.pressed.connect(_play_sfx.bind("menu_click"))
	var happy_click_buttons = [
		save_button, submit_custom_button
	]
	for btn in happy_click_buttons:
		if btn:
			if not btn.pressed.is_connected(_play_sfx.bind("happy_click")):
				btn.pressed.connect(_play_sfx.bind("happy_click"))
func _populate_suggestion_buttons(suggestions: Array) -> void:
	var status_label := suggestion_status
	for child in suggestion_buttons_container.get_children():
		child.queue_free()
	if suggestions.is_empty():
		suggestions = _fallback_suggestions()
	for suggestion in suggestions:
		var button := Button.new()
		button.text = suggestion
		button.custom_minimum_size = Vector2(0, 40)
		button.size_flags_horizontal = Control.SIZE_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD
		button.clip_text = false
		UIStyleManager.apply_button_style(button, "primary", "small")
		UIStyleManager.add_hover_scale_effect(button, 1.03)
		UIStyleManager.add_press_feedback(button)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		suggestion_buttons_container.add_child(button)
		button.pressed.connect(Callable(self, "_on_suggestion_button_pressed").bind(suggestion))
	if status_label:
		status_label.text = _tr("JOURNAL_SUGGESTION_HINT")
func _on_suggestions_generated(response: Dictionary) -> void:
	if _is_shutting_down:
		return
	_suggestion_in_flight = false
	_cancel_suggestion_timeout()
	_debug_log("[JournalSystem] Suggestions response received. Success: %s" % str(response.get("success", false)))
	if response.has("content"):
		_debug_log("[JournalSystem] Response content preview: %s" % str(response.get("content", "")).left(200))
	if response.has("error"):
		_debug_log("[JournalSystem] Response error: %s" % str(response.get("error", "")))
	if not response.get("success", false):
		var error_prefix := _tr("JOURNAL_AI_ERROR_PREFIX")
		suggestion_status.text = "%s %s" % [error_prefix, str(response.get("error", ""))]
		_populate_suggestion_buttons(_fallback_suggestions())
		_process_summary_queue()
		return
	var suggestions = _parse_suggestions(str(response.get("content", "")))
	_debug_log("[JournalSystem] Parsed suggestions count: %d" % suggestions.size())
	if suggestions.is_empty():
		suggestion_status.text = _tr("JOURNAL_AI_EMPTY_RESPONSE")
		_populate_suggestion_buttons(_fallback_suggestions())
	else:
		_populate_suggestion_buttons(suggestions)
	if _suggestion_refresh_pending:
		_suggestion_refresh_pending = false
		_request_ai_suggestions()
	else:
		_process_summary_queue()
func _on_suggestion_button_pressed(suggestion_text: String) -> void:
	custom_entry_overlay.visible = true
	custom_input.text = suggestion_text
	custom_input.grab_focus()
	custom_input.set_caret_column(suggestion_text.length(), 0)
func _generate_entry_summary(entry_id: String, entry: Dictionary) -> void:
	if entry_id.is_empty():
		return
	if _pending_summary_jobs.has(entry_id):
		return
	_pending_summary_jobs[entry_id] = true
	_summary_queue.append(
		{
			"id": entry_id,
			"entry": entry.duplicate(true),
		},
	)
	_enforce_summary_queue_limit()
	_process_summary_queue()
func _enforce_summary_queue_limit() -> void:
	while _summary_queue.size() > MAX_SUMMARY_QUEUE_SIZE:
		var dropped_request = _summary_queue.pop_back()
		_abandon_queued_summary(dropped_request)
func _abandon_queued_summary(request: Variant, log_warning: bool = true) -> void:
	if not (request is Dictionary):
		return
	var request_dict: Dictionary = request
	var entry_id := str(request_dict.get("id", ""))
	if entry_id.is_empty():
		return
	_pending_summary_jobs.erase(entry_id)
	if journal_entries.is_empty():
		_reload_entries_from_state()
	if journal_entries.is_empty():
		return
	var updated := false
	for i in range(journal_entries.size()):
		if journal_entries[i].get("id", "") == entry_id:
			var entry = journal_entries[i]
			entry["ai_summary_pending"] = false
			entry["ai_summary"] = _tr("JOURNAL_AI_UNAVAILABLE")
			journal_entries[i] = entry
			updated = true
			break
	if updated:
		save_journal()
		refresh_entries_display()
	if log_warning:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Dropping pending journal summary due to queue overflow",
			{ "entry_id": entry_id, "queue_size": _summary_queue.size() },
		)
func _process_summary_queue() -> void:
	if _is_shutting_down:
		return
	if _summary_in_flight:
		return
	if _suggestion_in_flight:
		return
	if _summary_queue.is_empty():
		return
	var request = _summary_queue[0]
	_summary_queue.remove_at(0)
	var entry_id = str(request.get("id", ""))
	var entry_data = request.get("entry", { })
	_perform_summary_request(entry_id, entry_data)
func _perform_summary_request(entry_id: String, entry: Dictionary) -> void:
	if _is_shutting_down:
		return
	if entry_id.is_empty():
		_summary_in_flight = false
		_process_summary_queue()
		return
	if not AIManager:
		_mark_summary_failed(entry_id)
		_summary_in_flight = false
		_process_summary_queue()
		return
	_summary_in_flight = true
	if not (entry is Dictionary):
		entry = { }
	var recent_events = GameState.get_recent_event_notes(4, _language)
	var latest_story = GameState.get_latest_story_text("")
	var entry_text = str(entry.get("text", "")).strip_edges()
	var prompt_template := _tr("JOURNAL_SUMMARY_PROMPT_TEMPLATE")
	var events_text = "\n".join(recent_events) if recent_events.size() > 0 else LocalizationManager.get_translation("JOURNAL_NO_EXTRA_EVENTS", _language)
	var prompt = prompt_template % [entry_text, events_text, latest_story.strip_edges(), SUMMARY_WORD_LIMIT]
	var context = {
		"purpose": "journal_summary",
		"reality_score": GameState.reality_score,
		"positive_energy": GameState.positive_energy,
		"entropy_level": GameState.entropy_level,
		"bypass_rate_limit": true,
	}
	if _should_force_mock():
		context["force_mock"] = true
	var callback = Callable(self, "_on_entry_summary_generated").bind(entry_id)
	_start_summary_timeout(entry_id)
	AIManager.generate_story(prompt, context, callback)
func _ensure_summary_timeout_timer() -> void:
	if _summary_timeout_timer != null:
		return
	_summary_timeout_timer = Timer.new()
	_summary_timeout_timer.one_shot = true
	add_child(_summary_timeout_timer)
	_summary_timeout_timer.timeout.connect(_on_summary_request_timeout)
func _start_summary_timeout(entry_id: String) -> void:
	if entry_id.is_empty():
		return
	_ensure_summary_timeout_timer()
	_active_summary_entry_id = entry_id
	_summary_timeout_timer.start(SUMMARY_REQUEST_TIMEOUT_SECONDS)
func _stop_summary_timeout(entry_id: String = "") -> void:
	if _summary_timeout_timer == null:
		return
	if not entry_id.is_empty() and entry_id != _active_summary_entry_id:
		return
	_summary_timeout_timer.stop()
	_active_summary_entry_id = ""
func _on_summary_request_timeout() -> void:
	if _active_summary_entry_id.is_empty():
		return
	ErrorReporterBridge.report_warning(
		ERROR_CONTEXT,
		"Journal summary request timed out; falling back to local message",
		{ "entry_id": _active_summary_entry_id },
	)
	_mark_summary_failed(_active_summary_entry_id)
func _limit_summary_text(raw_text: String) -> String:
	var cleaned = raw_text.strip_edges()
	if cleaned.is_empty():
		return cleaned
	if _language == "en":
		var words = cleaned.split(" ")
		if words.size() <= SUMMARY_WORD_LIMIT:
			return cleaned
		return " ".join(words.slice(0, SUMMARY_WORD_LIMIT)) + "..."
	var max_chars := SUMMARY_WORD_LIMIT
	if cleaned.length() <= max_chars:
		return cleaned
	return cleaned.substr(0, max_chars) + "..."
func _mark_summary_failed(entry_id: String, process_queue: bool = true) -> void:
	_stop_summary_timeout(entry_id)
	if journal_entries.is_empty():
		_reload_entries_from_state()
	var updated := false
	for i in range(journal_entries.size()):
		if journal_entries[i].get("id", "") == entry_id:
			var entry = journal_entries[i]
			entry["ai_summary_pending"] = false
			entry["ai_summary"] = _tr("JOURNAL_AI_UNAVAILABLE")
			journal_entries[i] = entry
			updated = true
			break
	if updated:
		save_journal()
		refresh_entries_display()
	_pending_summary_jobs.erase(entry_id)
	if _summary_in_flight:
		_summary_in_flight = false
	if process_queue and not _is_shutting_down:
		_process_summary_queue()
func _on_entry_summary_generated(response: Dictionary, entry_id: String) -> void:
	if _is_shutting_down:
		return
	_stop_summary_timeout(entry_id)
	if journal_entries.is_empty():
		_reload_entries_from_state()
	if journal_entries.is_empty():
		return
	if not bool(response.get("success", false)):
		_mark_summary_failed(entry_id)
		return
	var summary_text = _limit_summary_text(str(response.get("content", "")))
	var updated := false
	for i in range(journal_entries.size()):
		if journal_entries[i].get("id", "") == entry_id:
			var entry = journal_entries[i]
			entry["ai_summary"] = summary_text
			entry["ai_summary_pending"] = false
			entry["ai_summary_timestamp"] = Time.get_datetime_string_from_system()
			journal_entries[i] = entry
			save_journal()
			refresh_entries_display()
			_register_entry_summary(entry)
			_load_context_preview()
			updated = true
			break
	if _summary_in_flight:
		_summary_in_flight = false
	_pending_summary_jobs.erase(entry_id)
	_process_summary_queue()
func _register_entry_note(entry: Dictionary) -> void:
	if not AIManager:
		return
	var reflection_text = str(entry.get("text", "")).strip_edges()
	if reflection_text.is_empty():
		return
	var importance = clamp(int(abs(entry.get("reality_gain", 0))) + 2, 1, 5)
	if _language == "en":
		AIManager.register_note_pair(reflection_text, "", JOURNAL_NOTE_TAGS, importance, "journal_entry")
	else:
		AIManager.register_note_pair("", reflection_text, JOURNAL_NOTE_TAGS, importance, "journal_entry")
func _register_entry_summary(entry: Dictionary) -> void:
	if not AIManager:
		return
	var summary_text = str(entry.get("ai_summary", "")).strip_edges()
	if summary_text.is_empty():
		return
	var tags := JOURNAL_NOTE_TAGS.duplicate()
	if not tags.has("summary"):
		tags.append("summary")
	if _language == "en":
		AIManager.register_note_pair(summary_text, "", tags, 4, "journal_summary")
	else:
		AIManager.register_note_pair("", summary_text, tags, 4, "journal_summary")
func show_feedback(entry: Dictionary) -> void:
	var feedback = PanelContainer.new()
	var feedback_style = StyleBoxFlat.new()
	feedback_style.bg_color = UIConstants.COLOR_BG_UNLOCKED
	feedback_style.border_color = UIConstants.COLOR_BORDER_SUCCESS
	feedback_style.set_border_width_all(3)
	feedback_style.set_corner_radius_all(UIConstants.CORNER_RADIUS_LARGE)
	feedback.add_theme_stylebox_override("panel", feedback_style)
	var feedback_margin = MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", UIConstants.MARGIN_LARGE)
	feedback_margin.add_theme_constant_override("margin_top", UIConstants.MARGIN_SMALL)
	feedback_margin.add_theme_constant_override("margin_right", UIConstants.MARGIN_LARGE)
	feedback_margin.add_theme_constant_override("margin_bottom", UIConstants.MARGIN_SMALL)
	feedback.add_child(feedback_margin)
	var feedback_label = Label.new()
	feedback_label.text = _tr("JOURNAL_ENTRY_SAVED") % entry["reality_gain"]
	feedback_label.add_theme_color_override("font_color", UIConstants.COLOR_TITLE)
	feedback_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SUBTITLE)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_margin.add_child(feedback_label)
	entries_list.add_child(feedback)
	entries_list.move_child(feedback, 0)
	feedback.modulate.a = 0.0
	feedback.scale = Vector2(0.7, 0.7)
	var tween = feedback.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(feedback, "modulate:a", 1.0, 0.4)
	tween.tween_property(feedback, "scale", Vector2(1.0, 1.0), 0.4)
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(feedback):
		var fade_tween = create_tween()
		fade_tween.set_parallel(true)
		fade_tween.set_ease(Tween.EASE_IN)
		fade_tween.tween_property(feedback, "modulate:a", 0.0, 0.4)
		fade_tween.tween_property(feedback, "scale", Vector2(0.9, 0.9), 0.4)
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(feedback):
			feedback.queue_free()
func _on_preset_selected(emotion_type: String) -> void:
	add_entry(emotion_type)
func _on_custom_pressed() -> void:
	custom_entry_overlay.visible = true
	custom_input.grab_focus()
func _on_submit_custom() -> void:
	var text = custom_input.text.strip_edges()
	if text.is_empty():
		return
	add_entry("custom", text)
	custom_input.text = ""
	custom_entry_overlay.visible = false
func _on_cancel_custom() -> void:
	custom_input.text = ""
	custom_entry_overlay.visible = false
func _abort_pending_summary_requests() -> void:
	_cancel_suggestion_timeout()
	_suggestion_in_flight = false
	_suggestion_refresh_pending = false
	var active_entry_id := _active_summary_entry_id
	var orphaned_requests: Array = _summary_queue.duplicate(true)
	_summary_queue.clear()
	_stop_summary_timeout()
	if _summary_in_flight and not active_entry_id.is_empty():
		_mark_summary_failed(active_entry_id, false)
		_summary_in_flight = false
	for request in orphaned_requests:
		_abandon_queued_summary(request, false)
func _emit_close_requested() -> void:
	if _close_signal_emitted:
		return
	_close_signal_emitted = true
	close_requested.emit()
func _on_close_pressed() -> void:
	_is_shutting_down = true
	_emit_close_requested()
	queue_free()
func _on_save_pressed() -> void:
	save_journal()
	var confirm_label = Label.new()
	confirm_label.text = _tr("JOURNAL_SAVED")
	confirm_label.add_theme_color_override("font_color", UIConstants.COLOR_SUCCESS)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SUBTITLE)
	entries_list.add_child(confirm_label)
	entries_list.move_child(confirm_label, 0)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(confirm_label):
		confirm_label.queue_free()
func _on_home_pressed() -> void:
	save_journal()
	var parent = get_parent()
	if parent and (parent.name == "StartMenu" or parent.get_script() and parent.get_script().get_path().contains("start_menu")):
		_emit_close_requested()
		queue_free()
	else:
		GameState.save_game()
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/start_menu.tscn")
func add_mission_reflection(mission_result: String) -> void:
	var entry_id = "%s_%d" % [str(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	var label_text = _tr("JOURNAL_MISSION_OUTCOME") + " " + mission_result
	var entry = {
		"id": entry_id,
		"timestamp": Time.get_datetime_string_from_system(),
		"emoji": "",
		"text": label_text,
		"type": "mission",
		"source": "auto",
		"reality_gain": 2,
		"ai_summary": "",
		"ai_summary_pending": true,
	}
	journal_entries.append(entry)
	GameState.modify_reality_score(2)
	_register_entry_note(entry)
	save_journal()
	refresh_entries_display()
	_generate_entry_summary(entry_id, entry)
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
func _check_gloria_diary_reactions() -> void:
	if not GameState:
		return
	var entry_count := journal_entries.size()
	if entry_count >= GLORIA_DIARY_PEEK_THRESHOLD:
		var peek_shown: bool = GameState.get_metadata(META_KEY_GLORIA_PEEK_SHOWN, false)
		if not peek_shown:
			GameState.set_metadata(META_KEY_GLORIA_PEEK_SHOWN, true)
			_show_gloria_diary_banner()
	if entry_count >= GLORIA_DIARY_VERDICT_THRESHOLD:
		var verdict_shown: bool = GameState.get_metadata(META_KEY_GLORIA_VERDICT_SHOWN, false)
		if not verdict_shown:
			GameState.set_metadata(META_KEY_GLORIA_VERDICT_PENDING, true)
func _show_gloria_diary_banner() -> void:
	if _gloria_peek_banner and is_instance_valid(_gloria_peek_banner):
		return
	if not is_instance_valid(entries_list):
		return
	var scroll_container := entries_list.get_parent()
	if not scroll_container:
		return
	var right_panel := scroll_container.get_parent()
	if not right_panel:
		return
	var banner := PanelContainer.new()
	banner.name = "GloriaDiaryPeekBanner"
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.22, 0.04, 0.04, 0.93)
	banner_style.border_color = Color(0.9, 0.15, 0.15, 0.85)
	banner_style.set_border_width_all(2)
	banner_style.set_corner_radius_all(UIConstants.CORNER_RADIUS)
	banner_style.shadow_size = 10
	banner_style.shadow_color = Color(1.0, 0.0, 0.0, 0.22)
	banner.add_theme_stylebox_override("panel", banner_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UIConstants.MARGIN_MEDIUM)
	margin.add_theme_constant_override("margin_top", UIConstants.MARGIN_SMALL)
	margin.add_theme_constant_override("margin_right", UIConstants.MARGIN_MEDIUM)
	margin.add_theme_constant_override("margin_bottom", UIConstants.MARGIN_SMALL)
	banner.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
	margin.add_child(hbox)
	var gloria_portrait := TextureRect.new()
	if GLORIA_EMBARRASSED_TEXTURE:
		gloria_portrait.texture = GLORIA_EMBARRASSED_TEXTURE
	gloria_portrait.custom_minimum_size = Vector2(72, 72)
	gloria_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	gloria_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gloria_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(gloria_portrait)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)
	var title_lbl := Label.new()
	var body_lbl := Label.new()
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = _tr("JOURNAL_GLORIA_DIARY_WARNING")
	body_lbl.text = _tr("JOURNAL_GLORIA_DIARY_REACTION")
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	title_lbl.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SMALL + 2)
	body_lbl.add_theme_color_override("font_color", Color(0.9, 0.72, 0.72))
	body_lbl.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SMALL)
	vbox.add_child(title_lbl)
	vbox.add_child(body_lbl)
	_gloria_peek_banner = banner
	right_panel.add_child(banner)
	right_panel.move_child(banner, scroll_container.get_index())
	banner.modulate.a = 0.0
	var tween := banner.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(banner, "modulate:a", 1.0, 0.6)
