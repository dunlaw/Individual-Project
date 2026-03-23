extends Node
signal reality_score_changed(new_value: int)
signal positive_energy_changed(new_value: int)
signal entropy_level_changed(new_value: int)
signal stats_changed()
signal event_logged(event: Dictionary)
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "GameState"
const PlayerStatsScript = preload("res://1.Codebase/src/scripts/core/player_stats.gd")
const AIEventChannels = preload("res://1.Codebase/src/scripts/core/ai/ai_event_channels.gd")
const SaveLoadSystemScript = preload("res://1.Codebase/src/scripts/core/save_load_system.gd")
const EventLogSystemScript = preload("res://1.Codebase/src/scripts/core/event_log_system.gd")
const DebuffSystemScript = preload("res://1.Codebase/src/scripts/core/debuff_system.gd")
const MissionProgressModuleScript = preload("res://1.Codebase/src/scripts/core/mission_progress_module.gd")
const PhaseManagerModuleScript = preload("res://1.Codebase/src/scripts/core/phase_manager_module.gd")
const MetadataStoreModuleScript = preload("res://1.Codebase/src/scripts/core/metadata_store_module.gd")
const ApplicationLifecycleModuleScript = preload("res://1.Codebase/src/scripts/core/application_lifecycle_module.gd")
const AnalyticsModuleScript = preload("res://1.Codebase/src/scripts/core/analytics_module.gd")
const FSMChallengeModuleScript = preload("res://1.Codebase/src/scripts/core/fsm_challenge_module.gd")
var _player_stats: RefCounted = null
var _save_load_system: RefCounted = null
var _event_log_system: RefCounted = null
var _debuff_system: RefCounted = null
var _mission_progress: RefCounted = null
var _phase_manager: RefCounted = null
var _metadata_store: RefCounted = null
var _lifecycle_module: RefCounted = null
var _analytics_module: RefCounted = null
var _fsm_challenge: RefCounted = null
var reality_score: int:
	get:
		return _player_stats.reality_score if _player_stats else 50
	set(value):
		if _player_stats: _player_stats.reality_score = value
var positive_energy: int:
	get:
		return _player_stats.positive_energy if _player_stats else 50
	set(value):
		if _player_stats: _player_stats.positive_energy = value
var entropy_level: int:
	get:
		return _player_stats.entropy_level if _player_stats else 0
	set(value):
		if _player_stats: _player_stats.entropy_level = value
var player_stats: Dictionary:
	get:
		return _player_stats.skills if _player_stats else { }
	set(value):
		if _player_stats: _player_stats.skills = value
var player_skills: Dictionary:
	get:
		return player_stats
	set(value):
		player_stats = value
var current_mission: int:
	get: return _mission_progress.current_mission if _mission_progress else 0
	set(value): if _mission_progress: _mission_progress.current_mission = value
var current_mission_title: String:
	get: return _mission_progress.current_mission_title if _mission_progress else ""
	set(value): if _mission_progress: _mission_progress.current_mission_title = value
var mission_turn_count: int:
	get: return _mission_progress.mission_turn_count if _mission_progress else 0
	set(value): if _mission_progress: _mission_progress.mission_turn_count = value
var complaint_counter: int:
	get: return _mission_progress.complaint_counter if _mission_progress else 0
	set(value): if _mission_progress: _mission_progress.complaint_counter = value
var missions_completed: int:
	get: return _mission_progress.missions_completed if _mission_progress else 0
	set(value): if _mission_progress: _mission_progress.missions_completed = value
var game_phase: String:
	get: return _phase_manager.game_phase if _phase_manager else GameConstants.GamePhase.HONEYMOON
	set(value): if _phase_manager: _phase_manager.game_phase = value
var honeymoon_charges: int:
	get: return _phase_manager.honeymoon_charges if _phase_manager else 0
	set(value): if _phase_manager: _phase_manager.honeymoon_charges = value
var is_session_active: bool = false
var just_loaded_from_save: bool = false
var is_honeymoon_phase: bool:
	get:
		return _phase_manager.is_honeymoon_phase() if _phase_manager else false
	set(value):
		if _phase_manager:
			if value:
				_phase_manager.set_game_phase(GameConstants.GamePhase.HONEYMOON)
			elif _phase_manager.game_phase == GameConstants.GamePhase.HONEYMOON:
				_phase_manager.set_game_phase(GameConstants.GamePhase.NORMAL)
var active_debuffs: Array:
	get:
		return _debuff_system.active_debuffs if _debuff_system else []
	set(value):
		if _debuff_system: _debuff_system.active_debuffs = value
var cognitive_dissonance_active: bool:
	get:
		return _debuff_system.cognitive_dissonance_active if _debuff_system else false
	set(value):
		if _debuff_system: _debuff_system.cognitive_dissonance_active = value
var cognitive_dissonance_choices_left: int:
	get:
		return _debuff_system.cognitive_dissonance_choices_left if _debuff_system else 0
	set(value):
		if _debuff_system: _debuff_system.cognitive_dissonance_choices_left = value
var recent_events: Array:
	get:
		return _event_log_system.recent_events if _event_log_system else []
	set(value):
		if _event_log_system: _event_log_system.recent_events = value
var event_log: Array:
	get:
		return _event_log_system.event_log if _event_log_system else []
	set(value):
		if _event_log_system: _event_log_system.event_log = value
const MAX_EVENTS: int = GameConstants.Events.MAX_RECENT_EVENTS
const MAX_EVENT_LOG_SIZE: int = GameConstants.Events.MAX_EVENT_LOG_SIZE
var metadata: Dictionary:
	get: return _metadata_store.metadata if _metadata_store else {}
	set(value): if _metadata_store: _metadata_store.metadata = value
const ButterflyEffectTrackerScript = preload("res://1.Codebase/src/scripts/core/butterfly_effect_tracker.gd")
var butterfly_tracker: Node = null
var _event_bus: Variant = null
var _error_reporter: Variant = null
var _localization_manager: Variant = null
var _ai_manager: Variant = null
var _audio_manager: Variant = null
var _achievement_system: Variant = null
var _teammate_system: Variant = null
var _tutorial_system: Variant = null
var _cached_stats_payload: Dictionary = { }
var _stats_cache_dirty: bool = true
enum Language { EN, ZH }
var current_language: String = "en"
var autosave_enabled: bool:
	get: return _lifecycle_module.autosave_enabled if _lifecycle_module else true
	set(value): if _lifecycle_module: _lifecycle_module.autosave_enabled = value
var autosave_interval: float:
	get: return _lifecycle_module.autosave_interval if _lifecycle_module else 300.0
	set(value): if _lifecycle_module: _lifecycle_module.autosave_interval = value
var settings: Dictionary:
	get: return _lifecycle_module.settings if _lifecycle_module else {}
	set(value): if _lifecycle_module: _lifecycle_module.settings = value
var debug_force_mission_complete: bool = false
var debug_force_trolley_next_turn: bool = false
var current_save_slot: int:
	get:
		return _save_load_system.current_save_slot if _save_load_system else 1
	set(value):
		if _save_load_system: _save_load_system.current_save_slot = value
const MAX_SAVE_SLOTS: int = GameConstants.SaveSystem.MAX_SAVE_SLOTS
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready():
	set_process(true)
	_refresh_service_cache()
	call_deferred("_refresh_service_cache")
	_player_stats = PlayerStatsScript.new()
	_player_stats.reality_score_changed.connect(_on_reality_score_changed)
	_player_stats.positive_energy_changed.connect(_on_positive_energy_changed)
	_player_stats.entropy_level_changed.connect(_on_entropy_level_changed)
	_player_stats.stats_changed.connect(_on_stats_changed)
	_save_load_system = SaveLoadSystemScript.new()
	_save_load_system.set_game_state(self)
	_event_log_system = EventLogSystemScript.new()
	_event_log_system.set_game_state(self)
	_event_log_system.event_logged.connect(_on_event_logged)
	_debuff_system = DebuffSystemScript.new()
	_mission_progress = MissionProgressModuleScript.new()
	_mission_progress.set_game_state(self)
	_mission_progress.complaint_triggered.connect(_on_complaint_triggered)
	_phase_manager = PhaseManagerModuleScript.new()
	_phase_manager.set_game_state(self)
	_phase_manager.phase_changed.connect(_on_phase_changed)
	_phase_manager.honeymoon_depleted.connect(_on_honeymoon_depleted)
	_metadata_store = MetadataStoreModuleScript.new()
	_lifecycle_module = ApplicationLifecycleModuleScript.new()
	_lifecycle_module.autosave_requested.connect(_on_autosave_requested)
	_analytics_module = AnalyticsModuleScript.new()
	_analytics_module.start_session()
	_fsm_challenge = FSMChallengeModuleScript.new()
	_fsm_challenge.challenge_started.connect(_on_fsm_challenge_started)
	_fsm_challenge.day_completed.connect(_on_fsm_day_completed)
	_fsm_challenge.challenge_crash_triggered.connect(_on_fsm_challenge_crashed)
	butterfly_tracker = ButterflyEffectTrackerScript.new()
	add_child(butterfly_tracker)
	_report_info("Initialized: reality=%d, positive_energy=%d, entropy=%d, phase=%s" % [
		reality_score, positive_energy, entropy_level, game_phase
	])
	_subscribe_to_eventbus()
func _subscribe_to_eventbus() -> void:
	var event_bus = _get_event_bus()
	if not event_bus:
		_report_warning("Unable to subscribe to EventBus; EventBus service missing")
		return
	event_bus.subscribe("get_reality_score", self, "_handle_get_reality_score")
	event_bus.subscribe("get_positive_energy", self, "_handle_get_positive_energy")
	event_bus.subscribe("get_entropy_level", self, "_handle_get_entropy_level")
	event_bus.subscribe("get_all_stats", self, "_handle_get_all_stats")
	event_bus.subscribe("modify_reality_score", self, "_handle_modify_reality_score")
	event_bus.subscribe("modify_positive_energy", self, "_handle_modify_positive_energy")
	event_bus.subscribe(AIEventChannels.CURRENT_LANGUAGE_REQUEST, self, "_handle_ai_language_request")
	event_bus.subscribe(AIEventChannels.RECENT_ASSETS_REQUEST, self, "_handle_recent_assets_request")
func _handle_get_reality_score(_data: Variant = null) -> int:
	return reality_score
func _handle_get_positive_energy(_data: Variant = null) -> int:
	return positive_energy
func _handle_get_entropy_level(_data: Variant = null) -> int:
	return entropy_level
func _handle_get_all_stats(_data: Variant = null) -> Dictionary:
	return _get_cached_stats_payload().duplicate(false)
func _get_cached_stats_payload() -> Dictionary:
	if _stats_cache_dirty or _cached_stats_payload.is_empty():
		_cached_stats_payload = {
			"reality_score": reality_score,
			"positive_energy": positive_energy,
			"entropy_level": entropy_level,
			"skills": player_stats.duplicate(true) if player_stats else { },
		}
		_stats_cache_dirty = false
	return _cached_stats_payload
func _mark_stats_cache_dirty() -> void:
	_stats_cache_dirty = true
func _handle_ai_language_request(_data: Variant = null) -> String:
	return current_language
func _handle_recent_assets_request(_data: Variant = null):
	return get_metadata("recent_assets_data", [])
func _handle_modify_reality_score(data: Dictionary) -> void:
	var amount = data.get("amount", 0)
	var reason = data.get("reason", "")
	modify_reality_score(amount, reason)
func _handle_modify_positive_energy(data: Dictionary) -> void:
	var amount = data.get("amount", 0)
	var reason = data.get("reason", "")
	modify_positive_energy(amount, reason)
func _notification(what: int) -> void:
	if _lifecycle_module:
		_lifecycle_module.handle_notification(what)
func _on_autosave_requested() -> void:
	var success = autosave()
	if success:
		_debug_log("[GameState] Autosave completed successfully")
	else:
		_report_error("Failed to autosave")
func _on_complaint_triggered() -> void:
	var achievement_system = _get_achievement_system()
	if achievement_system:
		achievement_system.check_gloria_trigger()
func _on_phase_changed(old_phase: String, new_phase: String) -> void:
	_report_info("Game phase changed", {"from": old_phase, "to": new_phase})
	var event_en := "Game phase changed: %s" % _phase_label(new_phase, "en")
	add_event(event_en, event_en)
func _on_honeymoon_depleted() -> void:
	add_event(
		"Honeymoon phase depleted; teammates reveal their true nature",
		"Honeymoon phase depleted; teammates reveal their true nature",
	)
func _on_fsm_challenge_started() -> void:
	_report_info("FSM Challenge started")
	add_event("Started FSM 30-Day Rebirth Challenge", "Started FSM 30-Day Rebirth Challenge")
func _on_fsm_day_completed(day: int) -> void:
	_report_info("FSM Challenge day completed", {"day": day})
	if _player_stats:
		_player_stats.modify_reality_score(GameConstants.FSMChallenge.REALITY_PENALTY_PER_DAY, "FSM Challenge Day %d" % day)
		_player_stats.modify_positive_energy(GameConstants.FSMChallenge.POSITIVE_ENERGY_GAIN_PER_DAY, "FSM Challenge Day %d" % day)
		_player_stats.modify_entropy(GameConstants.FSMChallenge.ENTROPY_GAIN_PER_DAY, "FSM Challenge Day %d" % day)
	add_event("Completed FSM Challenge Day %d" % day, "Completed FSM Challenge Day %d" % day)
func _on_fsm_challenge_crashed() -> void:
	_report_info("FSM Challenge crashed after 5 days")
	add_event("FSM 30-Day Challenge permanently cancelled", "FSM 30-Day Challenge permanently cancelled")
func get_fsm_challenge_module() -> RefCounted:
	return _fsm_challenge
func _exit_tree():
	set_process(false)
	if _debuff_system:
		_debuff_system.clear_all()
	if _event_log_system:
		_event_log_system.clear_events()
	if _metadata_store:
		_metadata_store.clear()
	if butterfly_tracker:
		butterfly_tracker.queue_free()
		butterfly_tracker = null
func _process(delta: float):
	if _lifecycle_module and _lifecycle_module.process_autosave(delta):
		autosave()
func _stat_label(stat_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_stat(stat_id, lang) if localization_manager else stat_id.capitalize()
func _skill_label(skill_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_skill(skill_id, lang) if localization_manager else skill_id.capitalize()
func _teammate_label(teammate_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_teammate(teammate_id, lang) if localization_manager else teammate_id.capitalize()
func _phase_label(phase_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_phase(phase_id, lang) if localization_manager else phase_id.capitalize()
func _translate_reason(reason: String, lang: String) -> String:
	if reason.strip_edges().is_empty():
		return ""
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_reason(reason, lang) if localization_manager else reason
func _on_reality_score_changed(new_value: int, old_value: int) -> void:
	_mark_stats_cache_dirty()
	reality_score_changed.emit(new_value)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"reality_score_changed",
			{
				"new_value": new_value,
				"old_value": old_value,
				"delta": new_value - old_value,
				"timestamp": Time.get_ticks_msec(),
			},
		)
	check_reality_triggers()
func _on_positive_energy_changed(new_value: int, old_value: int) -> void:
	_mark_stats_cache_dirty()
	positive_energy_changed.emit(new_value)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"positive_energy_changed",
			{
				"new_value": new_value,
				"old_value": old_value,
				"delta": new_value - old_value,
				"timestamp": Time.get_ticks_msec(),
			},
		)
func _on_entropy_level_changed(new_value: int, old_value: int) -> void:
	_mark_stats_cache_dirty()
	entropy_level_changed.emit(new_value)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"entropy_level_changed",
			{
				"new_value": new_value,
				"old_value": old_value,
				"delta": new_value - old_value,
				"timestamp": Time.get_ticks_msec(),
			},
		)
func _on_stats_changed() -> void:
	_mark_stats_cache_dirty()
	stats_changed.emit()
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"stats_changed",
			{
				"reality_score": reality_score,
				"positive_energy": positive_energy,
				"entropy_level": entropy_level,
				"timestamp": Time.get_ticks_msec(),
			},
		)
	if _analytics_module:
		_analytics_module.record_attribute_snapshot(reality_score, positive_energy, entropy_level)
func _on_event_logged(event: Dictionary) -> void:
	event_logged.emit(event)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish("event_logged", event)
func _stat_change_importance(amount: int) -> int:
	var magnitude: int = abs(amount)
	var thresholds := GameConstants.Stats.STAT_CHANGE_IMPORTANCE_THRESHOLDS
	var base_importance := thresholds.size() + 1
	for i in range(thresholds.size()):
		if magnitude >= thresholds[i]:
			return base_importance - i
	return 1
func _notify_stat_change(stat_id: String, amount: int, reason: String) -> void:
	var event_bus = _get_event_bus()
	if not event_bus:
		return
	if amount == 0:
		return
	var note_en := "%s %+d" % [_stat_label(stat_id, "en"), amount]
	var note_zh := "%s %+d" % [_stat_label(stat_id, "zh"), amount]
	var reason_en := _translate_reason(reason, "en")
	var reason_zh := _translate_reason(reason, "zh")
	if not reason_en.is_empty():
		note_en += " (%s)" % reason_en
	if not reason_zh.is_empty():
		note_zh += " (%s)" % reason_zh
	var importance := _stat_change_importance(amount)
	event_bus.publish(
		AIEventChannels.REGISTER_NOTE_PAIR,
		{
			"text_en": note_en,
			"text_zh": note_zh,
			"tags": ["stat", stat_id],
			"importance": importance,
			"source": "stat_change",
		},
	)
func modify_reality_score(amount: int, reason: String = ""):
	if not _player_stats:
		_report_error(
			"modify_reality_score called without PlayerStats",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "amount": amount, "reason": reason },
		)
		return
	var old_score = reality_score
	_player_stats.modify_reality_score(amount, reason)
	var audio_manager = _get_audio_manager()
	if audio_manager and abs(amount) >= 3:
		if amount > 0:
			audio_manager.play_sfx("resource_gain_positive", 0.7)
		else:
			audio_manager.play_sfx("resource_spend_negative", 0.7)
	var reason_en := _translate_reason(reason, "en")
	var event_en := "Reality score change: %+d" % amount
	if not reason_en.is_empty():
		event_en += " (%s)" % reason_en
	add_event(event_en, event_en)
	_notify_stat_change("reality", amount, reason)
func check_reality_triggers():
	if reality_score >= GameConstants.Stats.HIGH_REALITY_THRESHOLD:
		_report_info("High reality threshold reached! Reality: %d (threshold: %d)" % [reality_score, GameConstants.Stats.HIGH_REALITY_THRESHOLD])
		set_metadata("high_reality_triggered", true)
		add_event(
			"Your heightened reality perception makes Gloria uncomfortable, she will attack more frequently.",
			"Your heightened reality perception makes Gloria uncomfortable, she will attack more frequently.",
		)
		if complaint_counter >= GameConstants.Gloria.HIGH_REALITY_COMPLAINT_THRESHOLD:
			set_metadata("gloria_attack_pending", true)
	elif reality_score <= GameConstants.Stats.LOW_REALITY_THRESHOLD:
		_report_warning("LOW REALITY WARNING! Reality: %d (threshold: %d)" % [reality_score, GameConstants.Stats.LOW_REALITY_THRESHOLD])
		_debug_log("[DEBUG_STATE] ! LOW REALITY TRIGGERED ! Score: %d" % reality_score)
		set_metadata("low_reality_triggered", true)
		var audio_manager = _get_audio_manager()
		if audio_manager:
			audio_manager.play_sfx("resource_depleted_alert", 0.9)
		add_event(
			"Your reality perception is dangerously low. The world feels increasingly unreal.",
			"Your reality perception is dangerously low. The world feels increasingly unreal.",
		)
		if not cognitive_dissonance_active:
			add_debuff(
				GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
				GameConstants.Debuffs.COGNITIVE_DISSONANCE_DURATION,
				"Cognitive dissonance triggered by low reality perception",
			)
			cognitive_dissonance_active = true
			cognitive_dissonance_choices_left = GameConstants.Debuffs.COGNITIVE_DISSONANCE_DURATION
func modify_positive_energy(amount: int, reason: String = ""):
	if not _player_stats:
		_report_error(
			"modify_positive_energy called without PlayerStats",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "amount": amount, "reason": reason },
		)
		return
	var old_pe = positive_energy
	_player_stats.modify_positive_energy(amount, reason)
	_report_info("Positive Energy %d -> %d (%+d)%s" % [old_pe, positive_energy, amount, (" [%s]" % reason if not reason.is_empty() else "")])
	var audio_manager = _get_audio_manager()
	if audio_manager and abs(amount) >= 5:
		if amount > 0:
			audio_manager.play_sfx("resource_gain_positive", 0.6)
		else:
			audio_manager.play_sfx("resource_spend_negative", 0.6)
	var reason_en := _translate_reason(reason, "en")
	var event_en := "Positive energy change: %+d" % amount
	if not reason_en.is_empty():
		event_en += " (%s)" % reason_en
	add_event(event_en, event_en)
	_notify_stat_change("positive", amount, reason)
func calculate_void_entropy() -> float:
	return _player_stats.calculate_void_entropy() if _player_stats else 0.0
func get_entropy_threshold() -> String:
	return _player_stats.get_entropy_threshold() if _player_stats else "low"
func get_entropy_level_label(lang: String = "en") -> String:
	return _player_stats.get_entropy_level_label(lang) if _player_stats else (_tr("GAME_STATE_UNKNOWN"))
func modify_entropy(amount: int, reason: String = ""):
	if not _player_stats:
		_report_error(
			"modify_entropy called without PlayerStats",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "amount": amount, "reason": reason },
		)
		return
	var old_entropy = entropy_level
	_player_stats.modify_entropy(amount, reason)
	_report_info("Entropy %d -> %d (%+d)%s" % [old_entropy, entropy_level, amount, (" [%s]" % reason if not reason.is_empty() else "")])
	if amount > 0:
		var reason_en := _translate_reason(reason, "en")
		var event_en := "World entropy surge: +%d" % amount
		if not reason_en.is_empty():
			event_en += " (%s)" % reason_en
		add_event(event_en, event_en)
	_notify_stat_change("entropy", amount, reason)
func add_complaint():
	if not _mission_progress:
		return false
	return _mission_progress.add_complaint()
func reset_complaint_counter():
	if _mission_progress:
		_mission_progress.reset_complaint_counter()
func get_stat(stat_name: String) -> int:
	if not _player_stats:
		_report_error(
			"Stat not found",
			ErrorCodes.GameState.STAT_NOT_FOUND,
			false,
			{ "stat_name": stat_name, "reason": "PlayerStats not initialized" },
		)
		return 0
	return _player_stats.get_skill(stat_name)
func modify_stat(stat_name: String, amount: int):
	if not _player_stats:
		_report_error(
			"Invalid stat modification",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "stat_name": stat_name, "amount": amount, "reason": "PlayerStats not initialized" },
		)
		return
	_player_stats.modify_skill(stat_name, amount)
func skill_check(stat_name: String, difficulty: int = 5) -> Dictionary:
	if not _player_stats:
		return { "success": false, "roll": 0, "skill_value": 0, "total": 0, "difficulty": difficulty }
	_player_stats.cognitive_dissonance_active = cognitive_dissonance_active
	var result = _player_stats.skill_check(stat_name, difficulty)
	if result["success"]:
		var achievement_system = _get_achievement_system()
		if achievement_system and achievement_system.has_method("check_skill_check_success"):
			achievement_system.check_skill_check_success(stat_name)
	return result
func add_debuff(debuff_name: String, duration: int, effect: String):
	if not _debuff_system:
		return
	var audio_manager = _get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("penalty_detained_alert", 0.8)
	_debuff_system.add_debuff(debuff_name, duration, effect)
func process_debuffs():
	if not _debuff_system:
		return
	_debuff_system.process_debuffs()
func clear_all_debuffs() -> bool:
	if not _debuff_system:
		return false
	_debuff_system.clear_all()
	return true
func use_cognitive_dissonance_choice():
	if not _debuff_system:
		return
	_debuff_system.use_cognitive_dissonance_choice()
func set_game_phase(phase: String):
	if _phase_manager:
		_phase_manager.set_game_phase(phase)
func is_in_honeymoon() -> bool:
	return _phase_manager.is_honeymoon_phase() if _phase_manager else false
func enter_honeymoon_phase():
	if _phase_manager:
		_phase_manager.enter_honeymoon_phase()
	var audio_manager = _get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("safe_zone_recovery", 0.8)
	add_event(
		"Honeymoon charges reset to %d" % GameConstants.Honeymoon.INITIAL_CHARGES,
		"Honeymoon charges reset to %d" % GameConstants.Honeymoon.INITIAL_CHARGES,
	)
func exit_honeymoon_phase():
	if _phase_manager:
		_phase_manager.exit_honeymoon_phase()
func start_mission(mission_id: int):
	if _mission_progress:
		_mission_progress.start_mission(mission_id)
	if _analytics_module:
		_analytics_module.start_mission_tracking()
	_report_info("Mission #%d started | Reality: %d | PE: %d | Entropy: %d | Phase: %s" % [
		mission_id, reality_score, positive_energy, entropy_level, game_phase.to_upper()
	])
	var event_en := "Mission #%d started" % mission_id
	add_event(event_en, event_en)
	if _phase_manager:
		_phase_manager.check_phase_on_mission_start()
func complete_mission(success: bool):
	if _mission_progress:
		_mission_progress.complete_mission(success)
	if _analytics_module:
		_analytics_module.complete_mission_tracking()
	_debug_log("[DEBUG_STATE] Mission Completed! Success: %s, Total Completed: %d" % [success, missions_completed])
	var audio_manager = _get_audio_manager()
	if audio_manager:
		if success:
			audio_manager.play_sfx("asset_acquired_confirm", 0.8)
		else:
			audio_manager.play_sfx("session_fail_sting", 0.7)
	var achievement_system = _get_achievement_system()
	if achievement_system:
		achievement_system.check_mission_complete()
	var tutorial_system = _get_tutorial_system()
	if tutorial_system:
		tutorial_system.check_tutorial_trigger("first_mission_complete")
	if success:
		modify_entropy(10, "Mission 'success' paradox")
	var success_text := "success" if success else "failed"
	_report_info("Mission #%d completed (%s) | Total completed: %d | Reality: %d | PE: %d | Entropy: %d" % [
		current_mission, success_text, missions_completed,
		reality_score, positive_energy, entropy_level
	])
	var event_en := "Mission #%d completed (%s)" % [current_mission, success_text]
	add_event(event_en, event_en)
	record_event(
		"mission_complete",
		{
			"mission_number": current_mission,
			"success": success,
			"outcome": success_text,
		},
	)
func record_event(event_type: String, details: Dictionary = { }):
	if not _event_log_system:
		return { }
	return _event_log_system.record_event(event_type, details)
func consume_honeymoon_charge(reason: String = ""):
	if not _phase_manager:
		return
	var old_charges = honeymoon_charges
	_phase_manager.consume_honeymoon_charge(reason)
	if old_charges != honeymoon_charges:
		var reason_en := _translate_reason(reason, "en")
		var note_en := "Honeymoon charge -1"
		if not reason_en.is_empty():
			note_en += " (%s)" % reason_en
		add_event(note_en, note_en)
func get_recent_records(limit: int = 10) -> Array:
	if not _event_log_system:
		return []
	return _event_log_system.get_recent_records(limit)
func clear_event_log():
	if not _event_log_system:
		return
	_event_log_system.clear_event_log()
func get_recent_event_notes(limit: int = 6, lang: String = "en") -> Array:
	if not _event_log_system:
		return []
	return _event_log_system.get_recent_event_notes(limit, lang)
func add_event(event_en: String, event_zh: String = ""):
	if not _event_log_system:
		return
	_event_log_system.current_language = current_language
	_event_log_system.add_event(event_en, event_zh)
func get_events_summary() -> String:
	if not _event_log_system:
		return ""
	return _event_log_system.get_events_summary()
func clear_events():
	if not _event_log_system:
		return
	_event_log_system.clear_events()
func set_metadata(key: String, value) -> void:
	if _metadata_store:
		_metadata_store.set_value(key, value)
func get_metadata(key: String, default_value = null):
	if _metadata_store:
		return _metadata_store.get_value(key, default_value)
	return default_value
func delete_local_logs() -> Dictionary:
	var result := {
		"event_log_cleared": false,
		"metadata_keys_removed": [],
		"files_deleted": 0,
	}
	clear_event_log()
	result["event_log_cleared"] = true
	if _metadata_store:
		var store_result = _metadata_store.delete_local_logs()
		result["metadata_keys_removed"] = store_result.get("metadata_keys_removed", [])
		result["files_deleted"] = store_result.get("files_deleted", 0)
	return result
func set_latest_story_text(text: String) -> void:
	if _metadata_store:
		_metadata_store.set_latest_story_text(text)
func get_latest_story_text(default_value: String = "") -> String:
	if _metadata_store:
		return _metadata_store.get_latest_story_text(default_value)
	return default_value
func set_latest_story_summary(summary: String) -> void:
	if _metadata_store:
		_metadata_store.set_latest_story_summary(summary)
func get_latest_story_summary(default_value: String = "") -> String:
	if _metadata_store:
		return _metadata_store.get_latest_story_summary(default_value)
	return default_value
func is_story_summary_pending() -> bool:
	if _metadata_store:
		return _metadata_store.is_story_summary_pending()
	return false
func get_journal_entries() -> Array:
	if _metadata_store:
		return _metadata_store.get_journal_entries()
	return []
func set_journal_entries(entries: Array) -> void:
	if _metadata_store:
		_metadata_store.set_journal_entries(entries)
func append_journal_entry(entry: Dictionary) -> void:
	if _metadata_store:
		_metadata_store.append_journal_entry(entry)
func get_recent_journal_entries(limit: int = 3) -> Array:
	if _metadata_store:
		return _metadata_store.get_recent_journal_entries(limit)
	return []
func get_story_history() -> Array:
	if _metadata_store:
		return _metadata_store.get_story_history()
	return []
func get_story_history_count() -> int:
	if _metadata_store:
		return _metadata_store.get_story_history_count()
	return 0
func get_story_at_index(index: int) -> String:
	if _metadata_store:
		return _metadata_store.get_story_at_index(index)
	return ""
func clear_story_history() -> void:
	if _metadata_store:
		_metadata_store.clear_story_history()
func get_save_data() -> Dictionary:
	var data := {
		"current_language": current_language,
		"is_session_active": is_session_active,
		"max_rounds_per_mission": settings.get("max_rounds_per_mission", 0),
	}
	if _mission_progress:
		data.merge(_mission_progress.get_save_data())
	if _phase_manager:
		data.merge(_phase_manager.get_save_data())
	if _metadata_store:
		data["metadata"] = _metadata_store.get_save_data()
	else:
		data["metadata"] = {}
	if _player_stats:
		data["player_stats_data"] = _player_stats.get_save_data()
	else:
		data["player_stats_data"] = {
			"reality_score": 50,
			"positive_energy": 50,
			"entropy_level": 0,
			"skills": { "logic": 5, "perception": 5, "composure": 5, "empathy": 5 },
		}
	if _event_log_system:
		var event_data = _event_log_system.get_save_data()
		data["recent_events"] = event_data.get("recent_events", [])
		data["event_log"] = event_data.get("event_log", [])
	if _debuff_system:
		data["debuff_system_data"] = _debuff_system.get_save_data()
	var event_bus = _get_event_bus()
	if event_bus:
		var ai_state = event_bus.request(AIEventChannels.STATE_SNAPSHOT_REQUEST)
		if ai_state is Dictionary:
			data["ai_state"] = (ai_state as Dictionary).duplicate(true)
	var audio_manager = _get_audio_manager()
	if audio_manager:
		data["audio_settings"] = audio_manager.get_volume_settings()
	var achievement_system = _get_achievement_system()
	if achievement_system and achievement_system.has_method("get_state_snapshot"):
		var achievement_state: Dictionary = achievement_system.get_state_snapshot()
		data["achievement_state"] = achievement_state
		var meta_ref: Dictionary = data["metadata"]
		var unlocked_data = achievement_state.get("unlocked", { })
		meta_ref["achievements"] = unlocked_data if unlocked_data is Dictionary else { }
		var progress_data = achievement_state.get("progress", { })
		meta_ref["achievement_progress"] = progress_data if progress_data is Dictionary else { }
	var teammate_system = _get_teammate_system()
	if teammate_system and teammate_system.has_method("get_state_snapshot"):
		data["teammate_state"] = teammate_system.get_state_snapshot()
	if butterfly_tracker:
		data["butterfly_tracker"] = butterfly_tracker.get_save_data()
	if _analytics_module:
		data["analytics_data"] = _analytics_module.get_save_data()
	if _fsm_challenge:
		data["fsm_challenge_data"] = _fsm_challenge.get_save_data()
	return data
func load_save_data(data: Dictionary):
	if _player_stats:
		if data.has("player_stats_data"):
			_player_stats.load_save_data(data["player_stats_data"])
		else:
			var legacy_data = {
				"reality_score": data.get("reality_score", 50),
				"positive_energy": data.get("positive_energy", 50),
				"entropy_level": data.get("entropy_level", 0),
				"skills": data.get("player_stats", { "logic": 5, "perception": 5, "composure": 5, "empathy": 5 }),
			}
			_player_stats.load_save_data(legacy_data)
	if _event_log_system:
		var event_data = {
			"event_log": data.get("event_log", []),
			"recent_events": data.get("recent_events", []),
		}
		_event_log_system.load_save_data(event_data)
	if _debuff_system:
		if data.has("debuff_system_data"):
			_debuff_system.load_save_data(data["debuff_system_data"])
		else:
			var legacy_debuff_data = {
				"active_debuffs": data.get("active_debuffs", []),
				"cognitive_dissonance_active": data.get("cognitive_dissonance_active", false),
				"cognitive_dissonance_choices_left": data.get("cognitive_dissonance_choices_left", 0),
			}
			_debuff_system.load_save_data(legacy_debuff_data)
	if _mission_progress:
		_mission_progress.load_save_data(data)
	if _phase_manager:
		_phase_manager.load_save_data(data)
	if _metadata_store:
		var metadata_data = data.get("metadata", {})
		_metadata_store.load_save_data(metadata_data if metadata_data is Dictionary else {})
	is_session_active = data.get("is_session_active", false)
	if data.has("max_rounds_per_mission"):
		settings["max_rounds_per_mission"] = int(data["max_rounds_per_mission"])
	var saved_language: String = data.get("current_language", "en")
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		current_language = config.get_value("game", "language", saved_language)
	else:
		current_language = saved_language
	if _event_log_system:
		_event_log_system.current_language = current_language
	_mark_stats_cache_dirty()
	stats_changed.emit()
	var audio_manager = _get_audio_manager()
	if data.has("audio_settings") and audio_manager:
		audio_manager.apply_volume_settings(data["audio_settings"])
	var event_bus = _get_event_bus()
	if data.has("ai_state") and event_bus:
		event_bus.publish(AIEventChannels.LOAD_STATE_SNAPSHOT, data["ai_state"])
	if data.has("achievement_state"):
		var achievement_system = _get_achievement_system()
		if achievement_system and achievement_system.has_method("load_state_snapshot"):
			achievement_system.load_state_snapshot(data["achievement_state"])
		else:
			set_metadata("pending_achievement_state", data["achievement_state"])
	if data.has("teammate_state"):
		var teammate_system = _get_teammate_system()
		if teammate_system and teammate_system.has_method("load_state_snapshot"):
			teammate_system.load_state_snapshot(data["teammate_state"])
		else:
			set_metadata("pending_teammate_state", data["teammate_state"])
	if data.has("butterfly_tracker") and butterfly_tracker:
		butterfly_tracker.load_save_data(data["butterfly_tracker"])
	if data.has("analytics_data") and _analytics_module:
		_analytics_module.load_save_data(data["analytics_data"])
	if data.has("fsm_challenge_data") and _fsm_challenge:
		_fsm_challenge.load_save_data(data["fsm_challenge_data"])
	just_loaded_from_save = true
	_report_info("Save data loaded: mission=%d, reality=%d, positive_energy=%d, entropy=%d, language=%s, phase=%s" % [
		current_mission, reality_score, positive_energy, entropy_level, current_language, game_phase
	])
func _refresh_service_cache() -> void:
	if not ServiceLocator:
		return
	_event_bus = ServiceLocator.get_event_bus()
	_error_reporter = ServiceLocator.get_error_reporter()
	_localization_manager = ServiceLocator.get_localization_manager()
	_ai_manager = ServiceLocator.get_ai_manager()
	_audio_manager = ServiceLocator.get_audio_manager()
	_achievement_system = ServiceLocator.get_achievement_system()
	_teammate_system = ServiceLocator.get_teammate_system()
	_tutorial_system = ServiceLocator.get_tutorial_system()
func _get_event_bus() -> Variant:
	if not is_instance_valid(_event_bus):
		_refresh_service_cache()
	return _event_bus
func _get_error_reporter() -> Variant:
	if not is_instance_valid(_error_reporter):
		_refresh_service_cache()
	return _error_reporter
func _get_localization_manager() -> Variant:
	if not is_instance_valid(_localization_manager):
		_refresh_service_cache()
	return _localization_manager
func _get_ai_manager() -> Variant:
	if not is_instance_valid(_ai_manager):
		_refresh_service_cache()
	return _ai_manager
func _get_audio_manager() -> Variant:
	if not is_instance_valid(_audio_manager):
		_refresh_service_cache()
	return _audio_manager
func _get_achievement_system() -> Variant:
	if not is_instance_valid(_achievement_system):
		_refresh_service_cache()
	return _achievement_system
func _get_teammate_system() -> Variant:
	if not is_instance_valid(_teammate_system):
		_refresh_service_cache()
	return _teammate_system
func _get_tutorial_system() -> Variant:
	if not is_instance_valid(_tutorial_system):
		_refresh_service_cache()
	return _tutorial_system
func _report_info(message: String, details: Dictionary = { }) -> void:
	var reporter = _get_error_reporter()
	if reporter:
		reporter.report_info("GameState", message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	var reporter = _get_error_reporter()
	if reporter:
		reporter.report_warning("GameState", message, details)
func _report_error(message: String, error_code: int = -1, notify_user: bool = false, details: Dictionary = { }) -> void:
	var reporter = _get_error_reporter()
	if reporter:
		reporter.report_error("GameState", message, error_code, notify_user, details)
func autosave():
	if not _save_load_system:
		return false
	return _save_load_system.autosave()
func save_game_to_slot(slot: int = -1) -> bool:
	if not _save_load_system:
		return false
	_report_info("Saving game to slot %d | Mission: %d | Reality: %d | PE: %d | Entropy: %d" % [
		slot if slot >= 0 else current_save_slot, current_mission,
		reality_score, positive_energy, entropy_level
	])
	return _save_load_system.save_to_slot(slot)
func save_game():
	return save_game_to_slot(current_save_slot)
func get_save_load_system() -> RefCounted:
	return _save_load_system
func load_game_from_slot(slot: int = -1) -> bool:
	if not _save_load_system:
		return false
	_report_info("Loading game from slot %d..." % (slot if slot >= 0 else current_save_slot))
	var result = _save_load_system.load_from_slot(slot)
	if result:
		_report_info("Game loaded! Mission: %d | Reality: %d | PE: %d | Entropy: %d | Phase: %s" % [
			current_mission, reality_score, positive_energy, entropy_level, game_phase.to_upper()
		])
	return result
func load_game() -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.load_game()
func get_autosave_info() -> Dictionary:
	if not _save_load_system:
		return { "exists": false }
	return _save_load_system.get_autosave_info()
func get_save_slot_info(slot: int) -> Dictionary:
	if not _save_load_system:
		return { "exists": false }
	return _save_load_system.get_save_slot_info(slot)
func get_latest_save_info() -> Dictionary:
	if not _save_load_system:
		return { "exists": false }
	return _save_load_system.get_latest_save_info()
func has_saved_game() -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.has_saved_game()
func delete_save_slot(slot: int) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.delete_save_slot(slot)
func delete_autosave() -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.delete_autosave()
func export_save_slot_to_path(slot: int, destination_path: String) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.export_slot_to_path(slot, destination_path)
func export_autosave_to_path(destination_path: String) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.export_autosave_to_path(destination_path)
func import_save_slot_from_path(slot: int, source_path: String) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.import_slot_from_path(slot, source_path)
func import_autosave_from_path(source_path: String) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.import_autosave_from_path(source_path)
func new_game():
	_report_info("Starting new game reset")
	if _player_stats:
		_player_stats.reset()
	if _debuff_system:
		_debuff_system.reset()
	if _event_log_system:
		_event_log_system.reset()
	if _mission_progress:
		_mission_progress.reset()
	if _phase_manager:
		_phase_manager.reset()
	if _fsm_challenge:
		_fsm_challenge.reset()
	if _metadata_store:
		var preserved_journal = _metadata_store.get_journal_entries()
		_metadata_store.clear()
		if not preserved_journal.is_empty():
			_metadata_store.set_journal_entries(preserved_journal)
	_mark_stats_cache_dirty()
	stats_changed.emit()
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(AIEventChannels.CLEAR_MEMORY)
	if butterfly_tracker:
		butterfly_tracker.clear_all()
	if _analytics_module:
		_analytics_module.reset()
	is_session_active = false
	_report_info("New game initialized")
	_report_info("=== NEW GAME STARTED === Reality: %d | Positive Energy: %d | Entropy: %d" % [
		_player_stats.reality_score, _player_stats.positive_energy, _player_stats.entropy_level
	])
	_debug_log("[DEBUG_STATE] === NEW GAME STARTED ===")
	_debug_log("[DEBUG_STATE] Stats Reset -> Reality: %d, Positive: %d, Entropy: %d" % [_player_stats.reality_score, _player_stats.positive_energy, _player_stats.entropy_level])
	_debug_log("[DEBUG_STATE] ========================")
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info("GameState", message)
func record_choice_for_analytics(choice_text: String, choice_index: int = -1) -> void:
	if _analytics_module:
		_analytics_module.record_choice(choice_text, choice_index)
func get_analytics_summary() -> Dictionary:
	if _analytics_module:
		return _analytics_module.get_analytics_summary()
	return {}
func get_session_playtime() -> float:
	if _analytics_module:
		_analytics_module.update_playtime()
		return _analytics_module.current_session_playtime
	return 0.0
func get_total_playtime() -> float:
	if _analytics_module:
		_analytics_module.update_playtime()
		return _analytics_module.total_playtime + _analytics_module.current_session_playtime
	return 0.0
func get_average_decision_time() -> float:
	if _analytics_module:
		return _analytics_module.get_average_decision_time()
	return 0.0
func get_most_common_choices(limit: int = 5) -> Array[Dictionary]:
	if _analytics_module:
		return _analytics_module.get_most_common_choices(limit)
	return []
func get_least_common_choices(limit: int = 5) -> Array[Dictionary]:
	if _analytics_module:
		return _analytics_module.get_least_common_choices(limit)
	return []
func get_attribute_trends(limit: int = 10) -> Array[Dictionary]:
	if _analytics_module:
		return _analytics_module.get_attribute_trends(limit)
	return []
func get_attribute_change_rates() -> Dictionary:
	if _analytics_module:
		return _analytics_module.calculate_attribute_change_rates()
	return {}
