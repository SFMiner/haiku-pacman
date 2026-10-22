extends RefCounted

# Each test_* method runs under tests/run_tests.gd. Counts are checked by expect().

# === STATE ===

var passes: int = 0
var fails: int = 0


# === HELPERS ===

func expect(condition: bool, message: String) -> void:
	if condition:
		passes += 1
	else:
		fails += 1
		print("  FAIL: %s" % message)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


# === TESTS: SCALING ===

func test_ghost_speed_rises_then_caps() -> void:
	var data: Dictionary = Tuning.load_file()
	expect(_near(LevelRules.ghost_factor(data, 1), 0.75), "level 1 ghosts at the base 75%")
	expect(_near(LevelRules.ghost_factor(data, 2), 0.8), "level 2 ghosts at 80%")
	expect(_near(LevelRules.ghost_factor(data, 20), 0.95), "ghost speed caps at 95%")


func test_pacman_speed_rises_then_caps() -> void:
	var data: Dictionary = Tuning.load_file()
	expect(_near(LevelRules.pacman_factor(data, 1), 0.8), "level 1 Pac-Man at the base 80%")
	expect(_near(LevelRules.pacman_factor(data, 10), 0.9), "Pac-Man speed caps at 90%")


func test_frightened_time_shrinks_to_floor() -> void:
	var data: Dictionary = Tuning.load_file()
	expect(_near(LevelRules.frightened_seconds(data, 1), 6.0), "level 1 frightened time is 6 s")
	expect(_near(LevelRules.frightened_seconds(data, 2), 5.5), "level 2 frightened time is 5.5 s")
	expect(_near(LevelRules.frightened_seconds(data, 20), 1.0), "frightened time floors at 1 s")


func test_scatter_scale_shrinks_to_floor() -> void:
	var data: Dictionary = Tuning.load_file()
	expect(_near(LevelRules.scatter_scale(data, 1), 1.0), "level 1 scatter is full length")
	expect(_near(LevelRules.scatter_scale(data, 2), 0.85), "level 2 scatter is 85%")
	expect(_near(LevelRules.scatter_scale(data, 10), 0.2), "scatter floors at 20%")


func test_schedule_scales_scatter_only() -> void:
	var data: Dictionary = Tuning.load_file()
	expect(LevelRules.schedule_ticks(data, 1) == Tuning.schedule_ticks(data), "level 1 schedule matches the base schedule")
	# First phase is scatter 7 s = 420 ticks; at level 2 it is 85% of that, 357 ticks. Chase stays 1200.
	var level_two: Array[int] = LevelRules.schedule_ticks(data, 2)
	expect(level_two[0] == 357 and level_two[1] == 1200, "level 2 scatter shortens to 357 ticks, chase stays 1200 (got %s)" % str(level_two.slice(0, 2)))


# === TESTS: FRUIT ===

func test_fruit_points_by_level_with_cap() -> void:
	var data: Dictionary = Tuning.load_file()
	expect(LevelRules.fruit_points(data, 1) == 100, "level 1 fruit is 100 points")
	expect(LevelRules.fruit_points(data, 3) == 500, "level 3 fruit is 500 points")
	expect(LevelRules.fruit_points(data, 20) == 5000, "fruit points cap at the last table value")


func test_fruit_appears_twice_per_level() -> void:
	var data: Dictionary = Tuning.load_file()
	var triggers: Array = data.get("fruit_dot_triggers", [])
	expect(not LevelRules.fruit_spawn_due(69, 0, triggers), "no fruit at 69 dots")
	var spawns: int = 0
	var spawned: int = 0
	for dots: int in range(0, 201):
		if LevelRules.fruit_spawn_due(dots, spawned, triggers):
			spawned += 1
			spawns += 1
	expect(spawns == 2, "fruit spawns exactly twice in a level (got %d)" % spawns)


# === TESTS: EXTRA LIFE ===

func test_extra_life_once_per_game() -> void:
	expect(LevelRules.extra_life_due(9990, 10000, 10000, false), "extra life when the score crosses 10,000")
	expect(not LevelRules.extra_life_due(10000, 10010, 10000, false), "no second crossing once past the threshold")
	expect(not LevelRules.extra_life_due(9000, 9500, 10000, false), "no extra life below the threshold")
	expect(not LevelRules.extra_life_due(9990, 10000, 10000, true), "no extra life if already given this game")
