extends SceneTree

# Runs every test_* method in the listed suites and prints a summary.
# Usage: godot --headless --path <project> --script res://tests/run_tests.gd
# Exit code is 1 on any failed check, any test that records no checks, or any suite that won't load.

const SUITES: Array[String] = [
	"res://tests/test_maze.gd",
	"res://tests/test_grid_mover.gd",
	"res://tests/test_ghost_rules.gd",
	"res://tests/test_ghost_ai.gd",
]


func _init() -> void:
	var tests_run: int = 0
	var checks_passed: int = 0
	var checks_failed: int = 0
	var problems: int = 0
	for path: String in SUITES:
		var script: Script = load(path)
		if script == null:
			print("SUITE FAILED TO LOAD: %s" % path)
			problems += 1
			continue
		var suite: RefCounted = script.new()
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			tests_run += 1
			var before: int = suite.passes + suite.fails
			print("RUN %s::%s" % [path.get_file(), method_name])
			suite.call(method_name)
			if suite.passes + suite.fails == before:
				print("  NO CHECKS RECORDED: %s" % method_name)
				problems += 1
		checks_passed += suite.passes
		checks_failed += suite.fails
	print("TESTS: %d run, %d checks passed, %d failed, %d problems" % [tests_run, checks_passed, checks_failed, problems])
	quit(1 if checks_failed > 0 or problems > 0 else 0)
