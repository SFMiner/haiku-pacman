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


# === TESTS: GHOST HOUSE ===

func test_release_order_and_timing() -> void:
	var ticks: Array[int] = [0, 120, 300, 480]
	var house: GhostHouse = GhostHouse.new(ticks)
	var releases: Array = []
	for t: int in range(1, 501):
		var index: int = house.tick(true)
		if index >= 0:
			releases.append([t, index])
	expect(releases == [[1, 0], [120, 1], [300, 2], [480, 3]], "releases at 1, 120, 300, 480 ticks in order (got %s)" % str(releases))


func test_release_waits_for_house_clear() -> void:
	var ticks: Array[int] = [0, 10]
	var house: GhostHouse = GhostHouse.new(ticks)
	var early: int = 0
	for t: int in 500:
		if house.tick(false) >= 0:
			early += 1
	expect(early == 0, "nothing released while the house is not clear")
	expect(house.tick(true) == 0, "first ghost released once the house is clear")
	early = 0
	for t: int in 500:
		if house.tick(false) >= 0:
			early += 1
	expect(early == 0, "second ghost waits while the first is still in the house")


# === TESTS: LEAVING THE HOUSE ===

func test_every_ghost_leaves_classic_house() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	if maze == null:
		expect(false, "classic layout loads for ghost house test")
		return
	var speed: float = Tuning.tiles_per_tick(Tuning.load_file(), "ghost_speed_factor")
	var exit: Vector2i = maze.starts["B"]
	var blinky: Ghost = Ghost.new()
	blinky.setup(maze, "B", Ghost.colour_for("B"), maze.starts["B"], exit, speed)
	expect(blinky.mode == Ghost.Mode.ROAMING, "Blinky starts outside and roams")
	for id: String in ["K", "I", "C"]:
		var ghost: Ghost = Ghost.new()
		ghost.setup(maze, id, Ghost.colour_for(id), maze.starts[id], exit, speed)
		expect(ghost.mode == Ghost.Mode.HOUSE, "%s starts in the house" % id)
		ghost.release()
		var ticks: int = 0
		while ghost.mode != Ghost.Mode.ROAMING and ticks < 600:
			ghost.advance()
			ticks += 1
		expect(ghost.mode == Ghost.Mode.ROAMING, "%s leaves the house within 600 ticks" % id)
		expect(ghost.position_tiles().distance_to(Vector2(exit)) < 0.2, "%s ends at the exit tile" % id)
		ghost.free()
	blinky.free()
