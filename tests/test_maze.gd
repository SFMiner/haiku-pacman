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


# === TESTS ===

func test_small_grid_counts() -> void:
	var maze: Maze = Maze.from_lines(PackedStringArray(["#####", "#.o #", "#  P#", "#####"]))
	expect(maze != null, "small grid parses")
	if maze == null:
		return
	expect(maze.width == 5 and maze.height == 4, "small grid is 5x4")
	expect(maze.dot_count() == 1, "small grid has 1 dot")
	expect(maze.energizer_count() == 1, "small grid has 1 energizer")
	expect(maze.starts.get("P") == Vector2i(3, 2), "P start is at (3,2)")


func test_bad_width_is_rejected() -> void:
	var maze: Maze = Maze.from_lines(PackedStringArray(["###", "##"]))
	expect(maze == null, "ragged rows return null")


func test_unknown_tile_is_rejected() -> void:
	var maze: Maze = Maze.from_lines(PackedStringArray(["#x#"]))
	expect(maze == null, "unknown character returns null")


func test_classic_layout() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	expect(maze != null, "classic layout loads")
	if maze == null:
		return
	expect(maze.width == 28 and maze.height == 31, "classic is 28x31")
	expect(maze.dot_count() == 240, "classic has 240 dots")
	expect(maze.energizer_count() == 4, "classic has 4 energizers")
	expect(maze.starts.get("P") == Vector2i(13, 23), "classic Pac-Man start")
	expect(maze.starts.get("B") == Vector2i(13, 11), "classic Blinky start")
	expect(maze.starts.get("I") == Vector2i(11, 14), "classic Inky start")
	expect(maze.starts.get("K") == Vector2i(13, 14), "classic Pinky start")
	expect(maze.starts.get("C") == Vector2i(15, 14), "classic Clyde start")
	expect(maze.starts.get("F") == Vector2i(13, 17), "classic fruit spot")


func test_default_layout() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_default.txt")
	expect(maze != null, "default layout loads")
	if maze == null:
		return
	expect(maze.width == 28 and maze.height == 31, "default is 28x31")
	expect(maze.dot_count() == 401, "default has 401 dots")
	expect(maze.energizer_count() == 4, "default has 4 energizers")
	expect(maze.starts.size() == 6, "default has all six start markers")


func test_tunnel_wraps() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	if maze == null:
		expect(false, "classic layout loads for tunnel test")
		return
	expect(maze.wrap_tile(Vector2i(-1, 14)) == Vector2i(27, 14), "left edge wraps to right")
	expect(maze.wrap_tile(Vector2i(28, 14)) == Vector2i(0, 14), "right edge wraps to left")
	expect(maze.is_passable(Vector2i(-1, 14)), "tunnel edge is passable")
	expect(not maze.is_passable(Vector2i(0, 1)), "outer wall blocks Pac-Man")


func test_doors_block_pacman_not_ghosts() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	if maze == null:
		expect(false, "classic layout loads for door test")
		return
	var door: Vector2i = Vector2i(13, 12)
	expect(maze.tile_at(door.x, door.y) == Maze.TILE_DOOR, "classic door tile at (13,12)")
	expect(not maze.is_passable(door), "Pac-Man can't pass the door")
	expect(maze.is_passable(door, true), "ghosts can pass the door")


func test_eating_removes_pellets_once() -> void:
	var maze: Maze = Maze.load_file("res://data/maze_classic.txt")
	if maze == null:
		expect(false, "classic layout loads for eat test")
		return
	var before: int = maze.pellets_left()
	expect(maze.eat(Vector2i(1, 1)) == Maze.TILE_DOT, "eating a dot returns TILE_DOT")
	expect(maze.dot_count() == 239, "dot count drops to 239")
	expect(maze.eat(Vector2i(1, 1)) == Maze.TILE_EMPTY, "second eat of the same tile does nothing")
	expect(maze.pellets_left() == before - 1, "pellets_left drops by exactly one")
	expect(maze.eat(Vector2i(1, 3)) == Maze.TILE_ENERGIZER, "eating an energizer returns TILE_ENERGIZER")
	expect(maze.energizer_count() == 3, "energizer count drops to 3")
