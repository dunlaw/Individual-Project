extends RefCounted
class_name SaveVersionMigrator
const CURRENT_SAVE_VERSION := 2
var _migrations: Dictionary = {}
func _init() -> void:
	_register_migrations()
func _register_migrations() -> void:
	_migrations[0] = _migrate_v0_to_v1
	_migrations[1] = _migrate_v1_to_v2
func get_current_version() -> int:
	return CURRENT_SAVE_VERSION
func get_save_version(data: Dictionary) -> int:
	return int(data.get("save_version", 0))
func needs_migration(data: Dictionary) -> bool:
	return get_save_version(data) < CURRENT_SAVE_VERSION
func stamp_version(data: Dictionary) -> Dictionary:
	data["save_version"] = CURRENT_SAVE_VERSION
	return data
func migrate(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var version := get_save_version(migrated)
	if version >= CURRENT_SAVE_VERSION:
		return migrated
	var steps_applied := 0
	while version < CURRENT_SAVE_VERSION:
		if not _migrations.has(version):
			ErrorReporter.report_warning(
				"SaveVersionMigrator",
				"No migration found for version %d, skipping to current" % version,
			)
			break
		var migration_func: Callable = _migrations[version]
		migrated = migration_func.call(migrated)
		var new_version := version + 1
		migrated["save_version"] = new_version
		steps_applied += 1
		ErrorReporter.report_info(
			"SaveVersionMigrator",
			"Migrated save from v%d to v%d" % [version, new_version],
		)
		version = new_version
	if steps_applied > 0:
		migrated["migration_timestamp"] = Time.get_unix_time_from_system()
		migrated["migrated_from_version"] = get_save_version(data)
		ErrorReporter.report_info(
			"SaveVersionMigrator",
			"Save migration complete: v%d -> v%d (%d steps)" % [
				get_save_version(data), version, steps_applied
			],
		)
	return migrated
func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
	if not data.has("player_stats_data"):
		data["player_stats_data"] = {
			"reality_score": data.get("reality_score", 50),
			"positive_energy": data.get("positive_energy", 50),
			"entropy_level": data.get("entropy_level", 0),
			"skills": data.get("player_stats", {
				"logic": 5, "perception": 5, "composure": 5, "empathy": 5
			}),
		}
		for key in ["reality_score", "positive_energy", "entropy_level", "player_stats"]:
			data.erase(key)
	if not data.has("debuff_system_data") and data.has("active_debuffs"):
		data["debuff_system_data"] = {
			"active_debuffs": data.get("active_debuffs", []),
			"cognitive_dissonance_active": data.get("cognitive_dissonance_active", false),
			"cognitive_dissonance_choices_left": data.get("cognitive_dissonance_choices_left", 0),
		}
		for key in ["active_debuffs", "cognitive_dissonance_active", "cognitive_dissonance_choices_left"]:
			data.erase(key)
	if not data.has("metadata"):
		data["metadata"] = {}
	return data
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	if not data.has("fsm_challenge_data"):
		data["fsm_challenge_data"] = {}
	if not data.has("analytics_data"):
		data["analytics_data"] = {}
	if not data.has("butterfly_tracker"):
		data["butterfly_tracker"] = {}
	if not data.has("teammate_state"):
		data["teammate_state"] = {}
	if not data.has("achievement_state"):
		data["achievement_state"] = {}
	if not data.has("current_language"):
		data["current_language"] = "en"
	return data
