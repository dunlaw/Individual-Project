extends Node
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n[CLIRunnerTest] Starting compatibility runner...")
	await get_tree().process_frame
	await _run_suite("CLIRunnerParserTest", "res://1.Codebase/Unit Test/test_cli_runner_parser.gd")
	await _run_suite("CLIRunnerIntegrationTest", "res://1.Codebase/Unit Test/test_cli_runner_integration.gd")
	print("[CLIRunnerTest] Compatibility runner completed. Passed=%d Failed=%d" % [tests_passed, tests_failed])
	queue_free()
func _run_suite(label: String, script_path: String) -> void:
	var suite_script: Script = load(script_path)
	if suite_script == null:
		tests_failed += 1
		print("   FAIL: %s script not found at %s" % [label, script_path])
		return
	var suite_instance: Node = suite_script.new()
	if suite_instance == null:
		tests_failed += 1
		print("   FAIL: %s could not be instantiated" % label)
		return
	add_child(suite_instance)
	await suite_instance.tree_exited
	var results := _read_results(suite_instance)
	if results.is_empty():
		tests_failed += 1
		print("   FAIL: %s completed without tracked results" % label)
		return
	tests_passed += results.get("passed", 0)
	tests_failed += results.get("failed", 0)
func _read_results(inst: Node) -> Dictionary:
	if "tests_passed" in inst:
		return {
			"passed": inst.get("tests_passed"),
			"failed": inst.get("tests_failed") if "tests_failed" in inst else 0,
		}
	if "_passed" in inst and inst.get("_passed") is int:
		return {
			"passed": inst.get("_passed"),
			"failed": inst.get("_failed") if "_failed" in inst and inst.get("_failed") is int else 0,
		}
	return {}
