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


# === TESTS ===

func test_blocked_turn_waits() -> void:
	var maze: Maze = _maze(["#######", "#.....#", "#######"])
	if maze == null:
		expect(false, "corridor maze parses")
		return
	var mover: GridMover = GridMover.new(maze, Vector2i(1, 1), Vector2i.RIGHT, 0.25)
	mover.queue(Vector2i.UP)
	for i: int in 12:
		mover.step()
	expect(mover.facing == Vector2i.RIGHT, "blocked Up turn is ignored, still facing Right")
	expect(mover.tile == Vector2i(4, 1), "moved three tiles right in 12 ticks")


func test_queued_turn_taken_only_at_centre() -> void:
	var maze: Maze = _maze(["#####", "#...#", "#.#.#", "#...#", "#####"])
	if maze == null:
		expect(false, "turn maze parses")
		return
	var mover: GridMover = GridMover.new(maze, Vector2i(1, 1), Vector2i.RIGHT, 0.25)
	# Down is open at (1,2) and (3,2), but blocked at (2,2).
	mover.queue(Vector2i.DOWN)
	for i: int in 2:
		mover.step()
	expect(mover.facing == Vector2i.RIGHT, "turn not taken mid-tile")
	for i: int in 6:
		mover.step()
	expect(mover.tile == Vector2i(3, 1) and mover.facing == Vector2i.DOWN, "turns Down at (3,1), the first open junction")
	expect(mover.progress < 0.01, "turn happens on the centre")
	for i: int in 4:
		mover.step()
	expect(mover.tile == Vector2i(3, 2), "moved down one tile after the turn")


func test_step_reports_tile_arrivals() -> void:
	var maze: Maze = _maze(["#####", "#...#", "#####"])
	if maze == null:
		expect(false, "arrival maze parses")
		return
	var mover: GridMover = GridMover.new(maze, Vector2i(1, 1), Vector2i.RIGHT, 0.25)
	var arrivals: int = 0
	for i: int in 4:
		if mover.step():
			arrivals += 1
	expect(arrivals == 1, "exactly one arrival in four ticks at 0.25 tiles per tick")
	expect(mover.tile == Vector2i(2, 1), "arrived at (2,1)")


func test_stops_at_wall() -> void:
	var maze: Maze = _maze(["#####", "#...#", "#####"])
	if maze == null:
		expect(false, "wall maze parses")
		return
	var mover: GridMover = GridMover.new(maze, Vector2i(1, 1), Vector2i.RIGHT, 0.25)
	for i: int in 40:
		mover.step()
	expect(mover.tile == Vector2i(3, 1), "stops on the last open tile")
	expect(mover.is_stopped(), "stopped against the wall")
	expect(mover.progress == 0.0, "no leftover progress when stopped")


func test_reverse_mid_edge_keeps_position() -> void:
	var maze: Maze = _maze(["#####", "#...#", "#####"])
	if maze == null:
		expect(false, "reverse maze parses")
		return
	var mover: GridMover = GridMover.new(maze, Vector2i(1, 1), Vector2i.RIGHT, 0.25)
	mover.step()
	mover.step()
	var before: Vector2 = mover.position_tiles()
	mover.queue(Vector2i.LEFT)
	mover.step()
	expect(mover.facing == Vector2i.LEFT, "reversed to Left mid-edge")
	expect(mover.position_tiles().is_equal_approx(before - Vector2(0.25, 0.0)), "reversal moves one step back from the same spot")


func test_tunnel_wraps_while_moving() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	if maze == null:
		expect(false, "classic layout loads for tunnel movement test")
		return
	var mover: GridMover = GridMover.new(maze, Vector2i(0, 14), Vector2i.LEFT, 0.25)
	for i: int in 4:
		mover.step()
	expect(mover.tile == Vector2i(27, 14), "left edge wraps to x=27 on row 14")
	expect(mover.facing == Vector2i.LEFT, "keeps heading Left through the tunnel")


func test_ghost_passes_door_pacman_does_not() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	if maze == null:
		expect(false, "classic layout loads for door movement test")
		return
	var pac: GridMover = GridMover.new(maze, Vector2i(13, 13), Vector2i.UP, 0.25)
	var ghost: GridMover = GridMover.new(maze, Vector2i(13, 13), Vector2i.UP, 0.25, true)
	expect(not pac.can_move(Vector2i.UP), "Pac-Man can't enter the door at (13,12)")
	expect(ghost.can_move(Vector2i.UP), "ghost can enter the door at (13,12)")
