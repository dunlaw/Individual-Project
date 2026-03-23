extends RefCounted
class_name SettingsMenuDeveloperSection
static func build_section(
	tab: VBoxContainer,
	existing_nodes: Dictionary,
	initial: Dictionary,
	game_state: Node,
	handlers: Dictionary,
	images: Dictionary,
) -> Dictionary:
	var result: Dictionary = {}
	var text_speed_option: OptionButton = existing_nodes.get("text_speed_option")
	if text_speed_option:
		text_speed_option.add_item("Instant", 0)
		text_speed_option.add_item("Fast", 1)
		text_speed_option.add_item("Normal", 2)
		text_speed_option.add_item("Slow", 3)
		var h := _get_handler(handlers, "on_text_speed_selected")
		if h is Callable and h.is_valid():
			text_speed_option.item_selected.connect(h)
		var ts: float = float(initial.get("text_speed", 1.0))
		if ts == 0.0: text_speed_option.select(0)
		elif ts == 2.0: text_speed_option.select(1)
		elif ts == 1.0: text_speed_option.select(2)
		elif ts == 0.5: text_speed_option.select(3)
		else: text_speed_option.select(2)
	var screen_shake_check: CheckBox = existing_nodes.get("screen_shake_check")
	if screen_shake_check:
		var h := _get_handler(handlers, "on_screen_shake_toggled")
		if h is Callable and h.is_valid():
			screen_shake_check.toggled.connect(h)
		screen_shake_check.button_pressed = bool(initial.get("screen_shake_enabled", true))
	var max_rounds_spinbox: SpinBox = existing_nodes.get("max_rounds_spinbox")
	if max_rounds_spinbox:
		max_rounds_spinbox.min_value = 0
		max_rounds_spinbox.max_value = 30
		max_rounds_spinbox.step = 1
		var mr: int = int(initial.get("max_rounds_per_mission", 0))
		if game_state and game_state.settings.has("max_rounds_per_mission"):
			mr = int(game_state.settings["max_rounds_per_mission"])
		max_rounds_spinbox.value = mr
		var h := _get_handler(handlers, "on_max_rounds_changed")
		if h is Callable and h.is_valid():
			max_rounds_spinbox.value_changed.connect(h)
	var force_mission_complete_check := CheckBox.new()
	tab.add_child(force_mission_complete_check)
	var h_fmc := _get_handler(handlers, "on_force_mission_complete_toggled")
	if h_fmc is Callable and h_fmc.is_valid():
		force_mission_complete_check.toggled.connect(h_fmc)
	if game_state:
		force_mission_complete_check.button_pressed = game_state.debug_force_mission_complete
	result["force_mission_complete_check"] = force_mission_complete_check
	var gloria_hbox := HBoxContainer.new()
	gloria_hbox.add_theme_constant_override("separation", 10)
	var force_gloria_button := Button.new()
	force_gloria_button.text = "Queue Gloria (Next Turn)"
	force_gloria_button.custom_minimum_size = Vector2(250, 40)
	force_gloria_button.focus_mode = Control.FOCUS_NONE
	var h_gloria := _get_handler(handlers, "on_force_gloria_pressed")
	if h_gloria is Callable and h_gloria.is_valid():
		force_gloria_button.pressed.connect(h_gloria)
	gloria_hbox.add_child(force_gloria_button)
	var force_gloria_status_label := Label.new()
	force_gloria_status_label.text = ""
	force_gloria_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	gloria_hbox.add_child(force_gloria_status_label)
	tab.add_child(gloria_hbox)
	result["force_gloria_button"] = force_gloria_button
	result["force_gloria_status_label"] = force_gloria_status_label
	var trolley_hbox := HBoxContainer.new()
	trolley_hbox.add_theme_constant_override("separation", 10)
	var force_trolley_button := Button.new()
	force_trolley_button.text = "Force Trolley Problem Now"
	force_trolley_button.custom_minimum_size = Vector2(250, 40)
	force_trolley_button.focus_mode = Control.FOCUS_NONE
	var h_trolley := _get_handler(handlers, "on_force_trolley_pressed")
	if h_trolley is Callable and h_trolley.is_valid():
		force_trolley_button.pressed.connect(h_trolley)
	trolley_hbox.add_child(force_trolley_button)
	var force_trolley_status_label := Label.new()
	force_trolley_status_label.text = ""
	force_trolley_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	trolley_hbox.add_child(force_trolley_status_label)
	tab.add_child(trolley_hbox)
	result["force_trolley_button"] = force_trolley_button
	result["force_trolley_status_label"] = force_trolley_status_label
	var force_honeymoon_check := CheckBox.new()
	force_honeymoon_check.text = "Force Honeymoon Phase"
	tab.add_child(force_honeymoon_check)
	var h_honey := _get_handler(handlers, "on_force_honeymoon_toggled")
	if h_honey is Callable and h_honey.is_valid():
		force_honeymoon_check.toggled.connect(h_honey)
	if game_state:
		force_honeymoon_check.button_pressed = game_state.is_honeymoon_phase
	result["force_honeymoon_check"] = force_honeymoon_check
	_add_separator(tab)
	var reality_score_label := Label.new()
	var reality_score_spinbox := SpinBox.new()
	_build_spinbox_row(tab, reality_score_label, reality_score_spinbox, 0, 100,
		int(game_state.reality_score) if game_state else 0)
	var h_rs := _get_handler(handlers, "on_reality_score_changed")
	if h_rs is Callable and h_rs.is_valid():
		reality_score_spinbox.value_changed.connect(h_rs)
	result["reality_score_label"] = reality_score_label
	result["reality_score_spinbox"] = reality_score_spinbox
	var positive_energy_label := Label.new()
	var positive_energy_spinbox := SpinBox.new()
	_build_spinbox_row(tab, positive_energy_label, positive_energy_spinbox, 0, 100,
		int(game_state.positive_energy) if game_state else 0)
	var h_pe := _get_handler(handlers, "on_positive_energy_changed")
	if h_pe is Callable and h_pe.is_valid():
		positive_energy_spinbox.value_changed.connect(h_pe)
	result["positive_energy_label"] = positive_energy_label
	result["positive_energy_spinbox"] = positive_energy_spinbox
	var entropy_level_label := Label.new()
	var entropy_level_spinbox := SpinBox.new()
	_build_spinbox_row(tab, entropy_level_label, entropy_level_spinbox, 0, 100,
		int(game_state.entropy_level) if game_state else 0)
	var h_el := _get_handler(handlers, "on_entropy_level_changed")
	if h_el is Callable and h_el.is_valid():
		entropy_level_spinbox.value_changed.connect(h_el)
	result["entropy_level_label"] = entropy_level_label
	result["entropy_level_spinbox"] = entropy_level_spinbox
	var honeymoon_charges_label := Label.new()
	var honeymoon_charges_spinbox := SpinBox.new()
	_build_spinbox_row(tab, honeymoon_charges_label, honeymoon_charges_spinbox, 0, 10,
		int(game_state.honeymoon_charges) if game_state else 0)
	var h_hc := _get_handler(handlers, "on_honeymoon_charges_changed")
	if h_hc is Callable and h_hc.is_valid():
		honeymoon_charges_spinbox.value_changed.connect(h_hc)
	result["honeymoon_charges_label"] = honeymoon_charges_label
	result["honeymoon_charges_spinbox"] = honeymoon_charges_spinbox
	var mission_turn_label := Label.new()
	var mission_turn_spinbox := SpinBox.new()
	_build_spinbox_row(tab, mission_turn_label, mission_turn_spinbox, 0, 100,
		int(game_state.mission_turn_count) if game_state else 0)
	var h_mt := _get_handler(handlers, "on_mission_turn_changed")
	if h_mt is Callable and h_mt.is_valid():
		mission_turn_spinbox.value_changed.connect(h_mt)
	result["mission_turn_label"] = mission_turn_label
	result["mission_turn_spinbox"] = mission_turn_spinbox
	_add_separator(tab)
	var quick_actions_label := Label.new()
	quick_actions_label.name = "QuickActionsLabel"
	quick_actions_label.add_theme_font_size_override("font_size", 20)
	quick_actions_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab.add_child(quick_actions_label)
	result["quick_actions_label"] = quick_actions_label
	var quick_actions_grid := GridContainer.new()
	quick_actions_grid.columns = 2
	quick_actions_grid.add_theme_constant_override("h_separation", 10)
	quick_actions_grid.add_theme_constant_override("v_separation", 10)
	tab.add_child(quick_actions_grid)
	var max_stats_button := Button.new()
	max_stats_button.custom_minimum_size = Vector2(200, 40)
	var h_ms := _get_handler(handlers, "on_max_stats_pressed")
	if h_ms is Callable and h_ms.is_valid():
		max_stats_button.pressed.connect(h_ms)
	quick_actions_grid.add_child(max_stats_button)
	result["max_stats_button"] = max_stats_button
	var reset_stats_button := Button.new()
	reset_stats_button.custom_minimum_size = Vector2(200, 40)
	var h_reset := _get_handler(handlers, "on_reset_stats_pressed")
	if h_reset is Callable and h_reset.is_valid():
		reset_stats_button.pressed.connect(h_reset)
	quick_actions_grid.add_child(reset_stats_button)
	result["reset_stats_button"] = reset_stats_button
	var clear_debuffs_button := Button.new()
	clear_debuffs_button.custom_minimum_size = Vector2(200, 40)
	var h_cd := _get_handler(handlers, "on_clear_debuffs_pressed")
	if h_cd is Callable and h_cd.is_valid():
		clear_debuffs_button.pressed.connect(h_cd)
	quick_actions_grid.add_child(clear_debuffs_button)
	result["clear_debuffs_button"] = clear_debuffs_button
	var add_honeymoon_button := Button.new()
	add_honeymoon_button.custom_minimum_size = Vector2(200, 40)
	var h_ah := _get_handler(handlers, "on_add_honeymoon_pressed")
	if h_ah is Callable and h_ah.is_valid():
		add_honeymoon_button.pressed.connect(h_ah)
	quick_actions_grid.add_child(add_honeymoon_button)
	result["add_honeymoon_button"] = add_honeymoon_button
	_add_separator(tab)
	var toggles_label := Label.new()
	toggles_label.name = "TogglesLabel"
	toggles_label.add_theme_font_size_override("font_size", 20)
	toggles_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab.add_child(toggles_label)
	result["toggles_label"] = toggles_label
	var autosave_toggle := CheckBox.new()
	if game_state:
		autosave_toggle.set_pressed_no_signal(game_state.autosave_enabled)
	var h_as := _get_handler(handlers, "on_autosave_toggled")
	if h_as is Callable and h_as.is_valid():
		autosave_toggle.toggled.connect(h_as)
	tab.add_child(autosave_toggle)
	result["autosave_toggle"] = autosave_toggle
	var infinite_resources_toggle := CheckBox.new()
	if game_state:
		infinite_resources_toggle.set_pressed_no_signal(game_state.get_metadata("debug_infinite_resources", false))
	var h_ir := _get_handler(handlers, "on_infinite_resources_toggled")
	if h_ir is Callable and h_ir.is_valid():
		infinite_resources_toggle.toggled.connect(h_ir)
	tab.add_child(infinite_resources_toggle)
	result["infinite_resources_toggle"] = infinite_resources_toggle
	var skip_dialogue_toggle := CheckBox.new()
	if game_state:
		skip_dialogue_toggle.set_pressed_no_signal(game_state.settings.get("auto_advance_enabled", false))
	var h_sd := _get_handler(handlers, "on_skip_dialogue_toggled")
	if h_sd is Callable and h_sd.is_valid():
		skip_dialogue_toggle.toggled.connect(h_sd)
	tab.add_child(skip_dialogue_toggle)
	result["skip_dialogue_toggle"] = skip_dialogue_toggle
	var god_mode_toggle := CheckBox.new()
	if game_state:
		god_mode_toggle.set_pressed_no_signal(game_state.get_metadata("debug_god_mode", false))
	var h_gm := _get_handler(handlers, "on_god_mode_toggled")
	if h_gm is Callable and h_gm.is_valid():
		god_mode_toggle.toggled.connect(h_gm)
	tab.add_child(god_mode_toggle)
	result["god_mode_toggle"] = god_mode_toggle
	_add_separator(tab)
	var fsm_challenge_label := Label.new()
	fsm_challenge_label.text = "FSM Challenge Debug"
	fsm_challenge_label.add_theme_font_size_override("font_size", 18)
	tab.add_child(fsm_challenge_label)
	var fsm_status_label := Label.new()
	fsm_status_label.name = "FSMStatusLabel"
	update_fsm_status_label(fsm_status_label, game_state)
	tab.add_child(fsm_status_label)
	var fsm_img_row := HBoxContainer.new()
	fsm_img_row.name = "FSMImageRow"
	fsm_img_row.alignment = BoxContainer.ALIGNMENT_CENTER
	fsm_img_row.add_theme_constant_override("separation", 18)
	fsm_img_row.custom_minimum_size = Vector2(0, 140)
	var fsm_img_data := [
		{"tex": images.get("fsm_guide"),   "caption": _tr("FSM_IMG_CAPTION_GUIDE"),          "tint": Color(0.85, 0.95, 1.0, 1.0)},
		{"tex": images.get("fsm_teacher"), "caption": "Teacher Chan",                         "tint": Color(1.0, 0.95, 0.75, 1.0)},
		{"tex": images.get("fsm_gloria"),  "caption": _tr("FSM_IMG_CAPTION_GLORIA_NEUTRAL"), "tint": Color(0.85, 1.0, 0.88, 1.0)},
	]
	for img_entry in fsm_img_data:
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var img_panel := PanelContainer.new()
		var img_panel_style := StyleBoxFlat.new()
		img_panel_style.bg_color = Color(0.08, 0.10, 0.18, 0.85)
		img_panel_style.set_corner_radius_all(10)
		img_panel_style.border_width_bottom = 2
		img_panel_style.border_color = Color(0.35, 0.55, 0.90, 0.55)
		img_panel_style.content_margin_left = 6
		img_panel_style.content_margin_right = 6
		img_panel_style.content_margin_top = 6
		img_panel_style.content_margin_bottom = 6
		img_panel.add_theme_stylebox_override("panel", img_panel_style)
		var tex_rect := TextureRect.new()
		tex_rect.texture = img_entry["tex"]
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(100, 100)
		tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_rect.modulate = img_entry["tint"]
		img_panel.add_child(tex_rect)
		col.add_child(img_panel)
		var cap_lbl := Label.new()
		cap_lbl.text = img_entry["caption"]
		cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap_lbl.add_theme_font_size_override("font_size", 11)
		cap_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.95, 0.85))
		col.add_child(cap_lbl)
		fsm_img_row.add_child(col)
	tab.add_child(fsm_img_row)
	var fsm_jump_hbox := HBoxContainer.new()
	fsm_jump_hbox.add_theme_constant_override("separation", 8)
	var fsm_jump_label := Label.new()
	fsm_jump_label.text = "Jump to Day:"
	fsm_jump_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var fsm_jump_option := OptionButton.new()
	fsm_jump_option.name = "FSMJumpOption"
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_0"), 0)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_1"), 1)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_2"), 2)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_3"), 3)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_4"), 4)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_5"), 5)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_6"), 6)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_7"), 7)
	fsm_jump_option.add_item("⚠️ " + _tr_bilingual("FSM_JUMP_DAY_8_INPROGRESS"), 78)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_8_CRASHED"), 8)
	fsm_jump_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fsm_jump_button := Button.new()
	fsm_jump_button.text = "Apply"
	var h_fj := _get_handler(handlers, "on_fsm_jump_to_day_pressed")
	if h_fj is Callable and h_fj.is_valid():
		fsm_jump_button.pressed.connect(func():
			h_fj.call(fsm_jump_option.get_selected_id(), fsm_status_label)
		)
	fsm_jump_hbox.add_child(fsm_jump_label)
	fsm_jump_hbox.add_child(fsm_jump_option)
	fsm_jump_hbox.add_child(fsm_jump_button)
	tab.add_child(fsm_jump_hbox)
	var fsm_reset_button := Button.new()
	fsm_reset_button.text = "Reset FSM Challenge"
	var h_fr := _get_handler(handlers, "on_fsm_reset_pressed")
	if h_fr is Callable and h_fr.is_valid():
		fsm_reset_button.pressed.connect(func():
			h_fr.call(fsm_status_label)
		)
	tab.add_child(fsm_reset_button)
	_add_separator(tab)
	return result
static func update_fsm_status_label(label: Label, game_state: Node) -> void:
	if not game_state:
		label.text = "Status: GameState not available"
		return
	var fsm_module: Variant = game_state.get_fsm_challenge_module()
	if not fsm_module:
		label.text = "Status: FSM Module not available"
		return
	if fsm_module.challenge_crashed:
		label.text = "Status: Challenge Crashed (Day 8 completed)"
	elif fsm_module.is_challenge_active:
		label.text = "Status: Active | Day: %d | Start: %s | Days Completed: %s" % [
			fsm_module.current_day,
			fsm_module.challenge_start_date,
			str(fsm_module.days_completed)
		]
	else:
		label.text = "Status: Not started"
static func _build_spinbox_row(
	tab: VBoxContainer,
	label: Label,
	spinbox: SpinBox,
	min_val: int,
	max_val: int,
	current_val: int,
) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	spinbox.custom_minimum_size = Vector2(100, 0)
	spinbox.min_value = min_val
	spinbox.max_value = max_val
	spinbox.step = 1
	spinbox.value = current_val
	hbox.add_child(spinbox)
	tab.add_child(hbox)
static func _add_separator(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	parent.add_child(sep)
static func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
static func _tr_bilingual(key: String) -> String:
	if LocalizationManager:
		var zh: String = LocalizationManager.get_translation(key, "zh")
		var en: String = LocalizationManager.get_translation(key, "en")
		if zh != en and not zh.is_empty():
			return "%s / %s" % [zh, en]
		return en if not en.is_empty() else key
	return key
static func _get_handler(handlers: Dictionary, key: String) -> Callable:
	if handlers.has(key):
		var val: Variant = handlers[key]
		if val is Callable:
			return val as Callable
	return Callable()
static func update_debug_button_status(button: Button, label: Label, success: bool, message: String) -> void:
	if not is_instance_valid(label):
		return
	label.text = message
	if success:
		label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		if is_instance_valid(button):
			button.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		if is_instance_valid(button):
			button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
static func on_fsm_jump_to_day(target_day_id: int, status_label: Label, game_state: Node, notify_fn: Callable, report_fn: Callable) -> void:
	if not game_state:
		notify_fn.call("GameState not available", false)
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		notify_fn.call("FSM Module not available", false)
		return
	fsm_module.reset()
	if target_day_id == 0:
		game_state.save_game()
		game_state.autosave()
		update_fsm_status_label(status_label, game_state)
		var msg := "FSM Challenge: jumped to Not Started"
		notify_fn.call(msg, true)
		report_fn.call("%s (slot + autosave updated)" % msg)
		return
	var today_dt := Time.get_datetime_dict_from_system()
	var today_str := "%04d-%02d-%02d" % [today_dt.year, today_dt.month, today_dt.day]
	fsm_module.is_challenge_active = true
	fsm_module.challenge_start_date = today_str
	fsm_module.last_login_date = today_str
	fsm_module.challenge_completed = false
	fsm_module.challenge_crashed = false
	if target_day_id == 78:
		for d in range(1, 8):
			fsm_module.days_completed.append(d)
		fsm_module.current_day = 8
		fsm_module.challenge_crashed = false
		fsm_module.challenge_completed = false
		game_state.save_game()
		game_state.autosave()
		update_fsm_status_label(status_label, game_state)
		var msg78 := "FSM Challenge: Day 8 In Progress (not yet complete)"
		notify_fn.call(msg78, true)
		report_fn.call("%s (slot + autosave updated)" % msg78)
		return
	for d in range(1, target_day_id + 1):
		fsm_module.days_completed.append(d)
	fsm_module.current_day = target_day_id
	if target_day_id >= GameConstants.FSMChallenge.DAYS_BEFORE_CRASH:
		fsm_module.challenge_crashed = true
		fsm_module.is_challenge_active = false
	game_state.save_game()
	game_state.autosave()
	update_fsm_status_label(status_label, game_state)
	var msg := "FSM Challenge: jumped to Day %d completed" % target_day_id
	if fsm_module.challenge_crashed:
		msg += " (Crashed)"
	notify_fn.call(msg, true)
	report_fn.call("%s (slot + autosave updated)" % msg)
static func on_fsm_reset(status_label: Label, game_state: Node, notify_fn: Callable, report_fn: Callable) -> void:
	if not game_state:
		notify_fn.call("GameState not available", false)
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		notify_fn.call("FSM Module not available", false)
		return
	fsm_module.reset()
	game_state.save_game()
	game_state.autosave()
	update_fsm_status_label(status_label, game_state)
	var msg := "FSM Challenge has been reset"
	notify_fn.call(msg, true)
	report_fn.call("%s (slot + autosave updated)" % msg)
static func on_max_stats(game_state: Node, spinboxes: Dictionary, notify_fn: Callable) -> void:
	if not game_state:
		return
	game_state.reality_score = 100
	game_state.positive_energy = 100
	game_state.entropy_level = 0
	game_state.honeymoon_charges = 10
	var sb_reality: SpinBox = spinboxes.get("reality") as SpinBox
	var sb_positive: SpinBox = spinboxes.get("positive_energy") as SpinBox
	var sb_entropy: SpinBox = spinboxes.get("entropy") as SpinBox
	var sb_honeymoon: SpinBox = spinboxes.get("honeymoon") as SpinBox
	if sb_reality: sb_reality.value = 100
	if sb_positive: sb_positive.value = 100
	if sb_entropy: sb_entropy.value = 0
	if sb_honeymoon: sb_honeymoon.value = 10
	notify_fn.call("All stats maximized!", true)
static func on_reset_stats(game_state: Node, spinboxes: Dictionary, notify_fn: Callable) -> void:
	if not game_state:
		return
	game_state.reality_score = 50
	game_state.positive_energy = 50
	game_state.entropy_level = 0
	game_state.honeymoon_charges = 3
	game_state.mission_turn_count = 0
	var sb_reality: SpinBox = spinboxes.get("reality") as SpinBox
	var sb_positive: SpinBox = spinboxes.get("positive_energy") as SpinBox
	var sb_entropy: SpinBox = spinboxes.get("entropy") as SpinBox
	var sb_honeymoon: SpinBox = spinboxes.get("honeymoon") as SpinBox
	var sb_mission: SpinBox = spinboxes.get("mission_turn") as SpinBox
	if sb_reality: sb_reality.value = 50
	if sb_positive: sb_positive.value = 50
	if sb_entropy: sb_entropy.value = 0
	if sb_honeymoon: sb_honeymoon.value = 3
	if sb_mission: sb_mission.value = 0
	notify_fn.call("All stats reset to defaults!", true)
