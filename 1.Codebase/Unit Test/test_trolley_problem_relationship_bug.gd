extends Node
var _test_log: Array = []
var _passed: int = 0
var _failed: int = 0
class MockServiceLocator extends Node:
	var teammate_system = null
	func get_teammate_system():
		return teammate_system
	func get_achievement_system():
		return null
class MockTeammateSystem extends Node:
	var relationships_updated = []
	var _team_relationships := {
		"player": {"gloria": {"status": "Neutral", "value": 0}},
		"gloria": {"player": {"status": "Neutral", "value": 0}},
	}
	func update_relationship(source: String, target: String, status: String, value: int):
		if not _team_relationships.has(source):
			_team_relationships[source] = {}
		_team_relationships[source][target] = {
			"status": status,
			"value": value,
		}
		relationships_updated.append({
			"source": source,
			"target": target,
			"status": status,
			"value": value
		})
	func get_relationships_for(source_id: String) -> Dictionary:
		return _team_relationships.get(source_id, {})
class MockGameState extends Node:
	var reality_score = 50
	var positive_energy = 50
	var entropy_level = 0
	var butterfly_tracker = null
	func modify_reality_score(amount): pass
	func modify_positive_energy(amount): pass
	func modify_entropy(amount, reason): pass
func _ready() -> void:
	print(" RUNNING TROLLEY PROBLEM BUG REPRODUCTION TEST")
	test_reproduction()
	if _failed == 0:
		print(" TEST PASSED (Bug Reproduced if failing expectedly, or Logic verified)")
	queue_free()
func test_reproduction():
	var TrolleyGenScript = load("res://1.Codebase/src/scripts/core/trolley_problem_generator.gd")
	var generator = TrolleyGenScript.new()
	add_child(generator)
	var test_dilemma = {
		"template_type": "test",
		"choices": [
			{
				"id": "choice_1",
				"text": "Test Choice",
				"relationship_changes": [
					{
						"target": "gloria",
						"value": -10,
						"status": "Disappointed"
					}
				]
			}
		]
	}
	generator.current_dilemma = test_dilemma
	var teammate_system = ServiceLocator.get_teammate_system() if ServiceLocator and ServiceLocator.has_method("get_teammate_system") else null
	var using_mock := false
	if teammate_system == null:
		teammate_system = MockTeammateSystem.new()
		add_child(teammate_system)
		using_mock = true
		if ServiceLocator and ServiceLocator.has_method("register_service"):
			ServiceLocator.register_service("TeammateSystem", teammate_system)
	if teammate_system:
		teammate_system.update_relationship("player", "gloria", "Neutral", 0)
		teammate_system.update_relationship("gloria", "player", "Neutral", 0)
		if teammate_system.has_method("get_relationships_for"):
			var p_to_g = teammate_system.get_relationships_for("player")
			if p_to_g.has("gloria") and p_to_g["gloria"] is Dictionary:
				p_to_g["gloria"]["value"] = 0
				p_to_g["gloria"]["status"] = "Neutral"
			var g_to_p = teammate_system.get_relationships_for("gloria")
			if g_to_p.has("player") and g_to_p["player"] is Dictionary:
				g_to_p["player"]["value"] = 0
				g_to_p["player"]["status"] = "Neutral"
	generator.resolve_dilemma("choice_1")
	var player_to_gloria = teammate_system.get_relationships_for("player").get("gloria", {})
	var gloria_to_player = teammate_system.get_relationships_for("gloria").get("player", {})
	print("Player -> Gloria: ", player_to_gloria)
	print("Gloria -> Player: ", gloria_to_player)
	if player_to_gloria.get("status") == "Disappointed" and player_to_gloria.get("value") == -10:
		print(" BUG CONFIRMED: Player -> Gloria was updated with 'Disappointed'")
		_failed += 1
	else:
		print(" Player -> Gloria was NOT updated (or updated differently)")
		_passed += 1
	if gloria_to_player.get("status") == "Disappointed" and gloria_to_player.get("value") == -10:
		print(" Gloria -> Player was updated with 'Disappointed' (Correct)")
		_passed += 1
	else:
		print(" Gloria -> Player was NOT updated correctly")
		_failed += 1
	if using_mock and ServiceLocator and ServiceLocator.has_method("unregister_service"):
		ServiceLocator.unregister_service("TeammateSystem")
