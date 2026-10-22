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


func _maze(lines: Array[String]) -> Maze:
	var rows: PackedStringArray = PackedStringArray()
	for line: String in lines:
		rows.append(line)
	return Maze.from_lines(rows)


# === TESTS: CHASE TARGETS ===

func test_blinky_targets_pacman() -> void:
	var target: Vector2i = GhostAI.target_tile("B", Vector2i(10, 10), Vector2i.RIGHT, Vector2i.ZERO, Vector2i(1, 1))
	expect(target == Vector2i(10, 10), "Blinky heads for Pac-Man's tile")


func test_pinky_four_ahead_and_up_quirk() -> void:
	var ghost: Vector2i = Vector2i(1, 1)
	expect(GhostAI.target_tile("K", Vector2i(10, 10), Vector2i.RIGHT, Vector2i.ZERO, ghost) == Vector2i(14, 10), "Pinky targets 4 tiles ahead when facing Right")
	expect(GhostAI.target_tile("K", Vector2i(10, 10), Vector2i.UP, Vector2i.ZERO, ghost) == Vector2i(6, 6), "Pinky facing Up shifts 4 tiles left too (quirk)")
	expect(GhostAI.target_tile("K", Vector2i(10, 10), Vector2i.ZERO, Vector2i.ZERO, ghost) == Vector2i(10, 10), "Pinky targets Pac-Man when he is stopped")


func test_inky_doubles_the_vector_through_the_pivot() -> void:
	# Pivot is 2 ahead of Pac-Man (12,10). Doubled from Blinky (4,4): (2*12-4, 2*10-4) = (20,16).
	var target: Vector2i = GhostAI.target_tile("I", Vector2i(10, 10), Vector2i.RIGHT, Vector2i(4, 4), Vector2i(1, 1))
	expect(target == Vector2i(20, 16), "Inky targets twice the Blinky-to-pivot vector")
	# Facing up: pivot is (10,8), shifted 2 left to (8,8). Doubled from Blinky (4,4): (12,12).
	var up_target: Vector2i = GhostAI.target_tile("I", Vector2i(10, 10), Vector2i.UP, Vector2i(4, 4), Vector2i(1, 1))
	expect(up_target == Vector2i(12, 12), "Inky's pivot shifts 2 left when Pac-Man faces up")


func test_clyde_chases_when_far_and_retreats_when_near() -> void:
	expect(GhostAI.target_tile("C", Vector2i(20, 20), Vector2i.RIGHT, Vector2i.ZERO, Vector2i(0, 0)) == Vector2i(20, 20), "Clyde chases Pac-Man when more than 8 tiles away")
	expect(GhostAI.target_tile("C", Vector2i(8, 0), Vector2i.RIGHT, Vector2i.ZERO, Vector2i(0, 0)) == GhostAI.scatter_corner("C"), "Clyde at exactly 8 tiles retreats to his corner")
	expect(GhostAI.target_tile("C", Vector2i(12, 10), Vector2i.RIGHT, Vector2i.ZERO, Vector2i(10, 10)) == GhostAI.scatter_corner("C"), "Clyde close to Pac-Man retreats to his corner")


# === TESTS: DIRECTION CHOICE ===

func test_never_reverses_in_corridor_toward_a_target_behind() -> void:
	var maze: Maze = _maze(["#####", "#...#", "#####"])
	if maze == null:
		expect(false, "corridor maze parses")
		return
	expect(Ghost.pick_toward(maze, Vector2i(2, 1), Vector2i.RIGHT, Vector2i(0, 1)) == Vector2i.RIGHT, "ghost keeps going Right even with the target behind it")


func test_dead_end_reverses() -> void:
	var maze: Maze = _maze(["#####", "#...#", "#####"])
	if maze == null:
		expect(false, "dead-end maze parses")
		return
	expect(Ghost.pick_toward(maze, Vector2i(1, 1), Vector2i.LEFT, Vector2i(0, 1)) == Vector2i.RIGHT, "dead end reverses to Right")


func test_picks_the_open_direction_closest_to_target() -> void:
	var maze: Maze = _maze(["#####", "##.##", "#...#", "##.##", "#####"])
	if maze == null:
		expect(false, "crossroads maze parses")
		return
	expect(Ghost.pick_toward(maze, Vector2i(2, 2), Vector2i.RIGHT, Vector2i(2, 5)) == Vector2i.DOWN, "turns Down toward a target below")
	expect(Ghost.pick_toward(maze, Vector2i(2, 2), Vector2i.RIGHT, Vector2i(5, 2)) == Vector2i.RIGHT, "keeps Right toward a target ahead")


func test_tie_goes_to_priority_order() -> void:
	var maze: Maze = _maze(["#####", "##.##", "#...#", "##.##", "#####"])
	if maze == null:
		expect(false, "tie maze parses")
		return
	# Up (2,1) and Down (2,3) are equally far from (0,2); Up comes first.
	expect(Ghost.pick_toward(maze, Vector2i(2, 2), Vector2i.RIGHT, Vector2i(0, 2)) == Vector2i.UP, "tie between Up and Down goes to Up")


# === TESTS: SCATTER / CHASE CYCLE ===

func test_schedule_flips_between_scatter_and_chase() -> void:
	# scatter 2, chase 3, scatter 1, chase forever
	var phases: Array[int] = [2, 3, 1, -1]
	var schedule: ModeSchedule = ModeSchedule.new(phases)
	expect(schedule.is_scatter(), "starts in scatter")
	expect(not schedule.tick(), "no flip after 1 tick")
	expect(schedule.tick(), "flips to chase after 2 ticks")
	expect(not schedule.is_scatter(), "now in chase")
	var flips: int = 0
	for t: int in 2:
		if schedule.tick():
			flips += 1
	expect(flips == 0, "chase phase runs its full 3 ticks")
	expect(schedule.tick() and schedule.is_scatter(), "flips back to scatter on the 5th tick")
	expect(schedule.tick() and not schedule.is_scatter(), "flips to forever-chase on the 6th tick")
	expect(not schedule.tick() and not schedule.is_scatter(), "final forever phase never flips back")
