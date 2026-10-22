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


# === TESTS: CHAIN ===

func test_chain_values_double_then_cap() -> void:
	var pellet: PowerPellet = PowerPellet.new(60, 10)
	pellet.start()
	var points: Array[int] = []
	for i: int in 5:
		points.append(pellet.eat_ghost(200))
	expect(points == [200, 400, 800, 1600, 1600], "chain is 200, 400, 800, 1600 then stays 1600 (got %s)" % str(points))


func test_chain_resets_when_timer_ends() -> void:
	var pellet: PowerPellet = PowerPellet.new(5, 2)
	pellet.start()
	pellet.eat_ghost(200)
	var ends: int = 0
	for i: int in 10:
		if pellet.tick():
			ends += 1
	expect(ends == 1, "timer ends exactly once in 10 ticks (ended %d times)" % ends)
	expect(not pellet.is_active(), "pellet is no longer active after its timer")
	expect(pellet.eat_ghost(200) == 200, "chain restarts at 200 after the timer ends")


func test_new_pellet_restarts_chain() -> void:
	var pellet: PowerPellet = PowerPellet.new(60, 10)
	pellet.start()
	pellet.eat_ghost(200)
	pellet.eat_ghost(200)
	pellet.start()
	expect(pellet.eat_ghost(200) == 200, "a new pellet restarts the chain at 200")


func test_stop_cancels_timer_and_chain() -> void:
	var pellet: PowerPellet = PowerPellet.new(60, 10)
	pellet.start()
	pellet.eat_ghost(200)
	pellet.stop()
	expect(not pellet.is_active() and pellet.chain == 0, "stop cancels the timer and the chain")


# === TESTS: FLASHING ===

func test_flashes_only_in_the_last_seconds() -> void:
	var pellet: PowerPellet = PowerPellet.new(100, 16)
	pellet.start()
	expect(not pellet.is_flashing(), "no flashing at the start of the timer")
	for i: int in 84:
		pellet.tick()
	expect(pellet.is_flashing(), "flashing with 16 ticks left (blink on)")
	for i: int in 8:
		pellet.tick()
	expect(not pellet.is_flashing(), "blink off 8 ticks later")


# === TESTS: FRIGHTENED GHOSTS ===

func test_eaten_ghost_is_harmless_and_returns_home() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	if maze == null:
		expect(false, "classic layout loads for scoring test")
		return
	var speed: float = Tuning.tiles_per_tick(Tuning.load_file(), "ghost_speed_factor")
	var ghost: Ghost = Ghost.new()
	ghost.setup(maze, "B", Ghost.colour_for("B"), maze.starts["B"], maze.starts["B"], speed)
	ghost.set_home(maze.starts["K"])
	ghost.enter_frightened()
	expect(ghost.mode == Ghost.Mode.FRIGHTENED, "roaming ghost turns frightened on an energizer")
	expect(not ghost.is_deadly(), "frightened ghost does not kill Pac-Man")
	ghost.eat()
	expect(ghost.mode == Ghost.Mode.EATEN and not ghost.is_deadly(), "eaten ghost is eyes and harmless")
	var back: bool = false
	for i: int in 3000:
		ghost.advance()
		if ghost.mode == Ghost.Mode.LEAVING or ghost.mode == Ghost.Mode.ROAMING:
			back = true
			break
	expect(back, "eyes return to the house and leave again")
	ghost.free()
