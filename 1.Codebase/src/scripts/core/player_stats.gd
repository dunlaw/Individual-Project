extends RefCounted
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "PlayerStats"
signal reality_score_changed(new_value: int, old_value: int)
signal positive_energy_changed(new_value: int, old_value: int)
signal entropy_level_changed(new_value: int, old_value: int)
signal stats_changed()
var _reality_score: int = GameConstants.Stats.INITIAL_REALITY_SCORE
var reality_score: int:
	get: return _reality_score
	set(value):
		var old_value = _reality_score
		_reality_score = clamp(value, GameConstants.Stats.MIN_REALITY_SCORE, GameConstants.Stats.MAX_REALITY_SCORE)
		if _reality_score != old_value:
			reality_score_changed.emit(_reality_score, old_value)
var _positive_energy: int = GameConstants.Stats.INITIAL_POSITIVE_ENERGY
var positive_energy: int:
	get: return _positive_energy
	set(value):
		var old_value = _positive_energy
		_positive_energy = clamp(value, GameConstants.Stats.MIN_POSITIVE_ENERGY, GameConstants.Stats.MAX_POSITIVE_ENERGY)
		if _positive_energy != old_value:
			positive_energy_changed.emit(_positive_energy, old_value)
			if _positive_energy > old_value:
				modify_entropy((_positive_energy - old_value) * 2, "Positive energy curse")
var _entropy_level: int = GameConstants.Stats.INITIAL_ENTROPY
var entropy_level: int:
	get: return _entropy_level
	set(value):
		var old_value = _entropy_level
		_entropy_level = max(GameConstants.Stats.MIN_ENTROPY, value)
		if _entropy_level != old_value:
			entropy_level_changed.emit(_entropy_level, old_value)
var skills: Dictionary = GameConstants.Skills.DEFAULT_SKILLS.duplicate()
var cognitive_dissonance_active: bool = false
func modify_reality_score(amount: int, reason: String = "") -> void:
	var old_score = reality_score
	reality_score += amount
	var reason_str := " [%s]" % reason if not reason.is_empty() else ""
	_report_info("Reality: %d -> %d (%+d)%s" % [old_score, reality_score, amount, reason_str])
func modify_positive_energy(amount: int, reason: String = "") -> void:
	var old_energy = positive_energy
	positive_energy += amount
	var reason_str := " [%s]" % reason if not reason.is_empty() else ""
	_report_info("Positive Energy: %d -> %d (%+d)%s" % [old_energy, positive_energy, amount, reason_str])
func modify_entropy(amount: int, reason: String = "") -> void:
	var old_entropy = entropy_level
	entropy_level += amount
	var reason_str := " [%s]" % reason if not reason.is_empty() else ""
	_report_info("Entropy: %d -> %d (%+d)%s" % [old_entropy, entropy_level, amount, reason_str])
func calculate_void_entropy() -> float:
	var divisor = GameConstants.Entropy.BASE_ENTROPY_DIVISOR
	var multiplier = GameConstants.Entropy.POSITIVE_ENERGY_MULTIPLIER
	var pe_component = (float(positive_energy) / divisor) * (1.0 - multiplier)
	var reality_component = (1.0 - (float(reality_score) / (divisor * 2.0))) * multiplier
	return clamp(pe_component + reality_component, 0.0, 1.0)
func get_entropy_threshold() -> String:
	var entropy = calculate_void_entropy()
	if entropy >= GameConstants.Entropy.MEDIUM_THRESHOLD:
		return "high"
	elif entropy >= GameConstants.Entropy.LOW_THRESHOLD:
		return "medium"
	else:
		return "low"
func get_entropy_level_label(lang: String = "en") -> String:
	var threshold = get_entropy_threshold()
	if LocalizationManager and LocalizationManager.has_method("tr_entropy_level"):
		return LocalizationManager.tr_entropy_level(threshold, lang)
	match threshold:
		"low":
			return "Stable"
		"medium":
			return "Unstable"
		"high":
			return "Chaotic"
		_:
			return "Unknown"
func get_skill(skill_name: String) -> int:
	return skills.get(skill_name, 0)
func modify_skill(skill_name: String, amount: int) -> void:
	if skills.has(skill_name):
		var old_value = skills[skill_name]
		skills[skill_name] = clamp(
			skills[skill_name] + amount,
			GameConstants.Skills.MIN_SKILL_VALUE,
			GameConstants.Skills.MAX_SKILL_VALUE,
		)
		if skills[skill_name] != old_value:
			_report_info("Skill %s: %d -> %d (%+d)" % [skill_name.capitalize(), old_value, skills[skill_name], skills[skill_name] - old_value])
			if AudioManager and amount > 0:
				AudioManager.play_sfx("asset_upgrade_confirm", 0.7)
			stats_changed.emit()
func skill_check(skill_name: String, difficulty: int = 5) -> Dictionary:
	var skill_value = get_skill(skill_name)
	if AudioManager:
		AudioManager.play_sfx("chance_roll_trigger")
	var roll = randi_range(
		GameConstants.Skills.MIN_DICE_ROLL,
		GameConstants.Skills.MAX_DICE_ROLL,
	)
	var total = skill_value + roll
	if cognitive_dissonance_active and skill_name == "logic":
		total += GameConstants.Skills.COGNITIVE_DISSONANCE_PENALTY
	var success = total >= difficulty
	var cd_str := " (Cognitive Dissonance penalty: %d)" % GameConstants.Skills.COGNITIVE_DISSONANCE_PENALTY if cognitive_dissonance_active and skill_name == "logic" else ""
	var result_str := "SUCCESS" if success else "FAILED"
	_report_info("%s check (DC %d): Roll %d + Skill %d = %d vs %d -> %s%s" % [
		skill_name.capitalize(), difficulty, roll, skill_value, total, difficulty, result_str, cd_str
	])
	return {
		"success": success,
		"roll": roll,
		"skill_value": skill_value,
		"total": total,
		"difficulty": difficulty,
		"skill_name": skill_name,
	}
func get_all_stats() -> Dictionary:
	return {
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"entropy_level": entropy_level,
		"skills": skills.duplicate(),
	}
func reset() -> void:
	var old_reality := _reality_score
	var old_positive := _positive_energy
	var old_entropy := _entropy_level
	_reality_score = GameConstants.Stats.INITIAL_REALITY_SCORE
	_positive_energy = GameConstants.Stats.INITIAL_POSITIVE_ENERGY
	_entropy_level = GameConstants.Stats.INITIAL_ENTROPY
	skills = GameConstants.Skills.DEFAULT_SKILLS.duplicate()
	cognitive_dissonance_active = false
	_report_info("Reset: reality %d->%d, positive_energy %d->%d, entropy %d->%d, skills reset" % [
		old_reality, _reality_score, old_positive, _positive_energy, old_entropy, _entropy_level
	])
	reality_score_changed.emit(_reality_score, old_reality)
	positive_energy_changed.emit(_positive_energy, old_positive)
	entropy_level_changed.emit(_entropy_level, old_entropy)
	stats_changed.emit()
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func get_save_data() -> Dictionary:
	return {
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"entropy_level": entropy_level,
		"skills": skills.duplicate(),
		"cognitive_dissonance_active": cognitive_dissonance_active,
	}
func load_save_data(data: Dictionary) -> void:
	var old_reality := _reality_score
	var old_positive := _positive_energy
	var old_entropy := _entropy_level
	_reality_score = data.get("reality_score", GameConstants.Stats.INITIAL_REALITY_SCORE)
	_positive_energy = data.get("positive_energy", GameConstants.Stats.INITIAL_POSITIVE_ENERGY)
	_entropy_level = data.get("entropy_level", GameConstants.Stats.INITIAL_ENTROPY)
	var skills_data = data.get("skills", GameConstants.Skills.DEFAULT_SKILLS)
	skills = skills_data.duplicate() if skills_data is Dictionary else GameConstants.Skills.DEFAULT_SKILLS.duplicate()
	cognitive_dissonance_active = data.get("cognitive_dissonance_active", false)
	_report_info("Loaded: reality=%d, positive_energy=%d, entropy=%d, dissonance=%s" % [
		_reality_score, _positive_energy, _entropy_level, cognitive_dissonance_active
	])
	reality_score_changed.emit(_reality_score, old_reality)
	positive_energy_changed.emit(_positive_energy, old_positive)
	entropy_level_changed.emit(_entropy_level, old_entropy)
	stats_changed.emit()
