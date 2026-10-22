class_name Maze
extends RefCounted

# Pure grid logic: no nodes, so it can be tested headless.

# === CONSTANTS ===

const TILE_EMPTY: int = 0
const TILE_WALL: int = 1
const TILE_DOT: int = 2
const TILE_ENERGIZER: int = 3
const TILE_DOOR: int = 4

const START_MARKERS: String = "PBIKCF"

# === STATE ===

var width: int = 0
var height: int = 0
var starts: Dictionary = {}
var _tiles: PackedInt32Array = PackedInt32Array()
var _dot_count: int = 0
var _energizer_count: int = 0


# === FACTORIES ===

static func load_file(path: String) -> Maze:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Maze: cannot open %s (error %d)" % [path, FileAccess.get_open_error()])
		return null
	var lines: PackedStringArray = PackedStringArray()
	while not file.eof_reached():
		var line: String = file.get_line().trim_suffix("\r")
		if line.length() > 0:
			lines.append(line)
	return from_lines(lines)


static func from_lines(lines: PackedStringArray) -> Maze:
	if lines.is_empty():
		push_error("Maze: no rows")
		return null
	var maze: Maze = Maze.new()
	maze.width = lines[0].length()
	maze.height = lines.size()
	maze._tiles.resize(maze.width * maze.height)
	for y: int in maze.height:
		var row: String = lines[y]
		if row.length() != maze.width:
			push_error("Maze: row %d has width %d, expected %d" % [y, row.length(), maze.width])
			return null
		for x: int in maze.width:
			var ch: String = row[x]
			var code: int = _code_for_char(ch)
			if code < 0:
				if START_MARKERS.contains(ch):
					code = TILE_EMPTY
					maze.starts[ch] = Vector2i(x, y)
				else:
					push_error("Maze: unknown tile '%s' at %d,%d" % [ch, x, y])
					return null
			maze._tiles[y * maze.width + x] = code
			if code == TILE_DOT:
				maze._dot_count += 1
			elif code == TILE_ENERGIZER:
				maze._energizer_count += 1
	return maze


static func _code_for_char(ch: String) -> int:
	if ch == "#":
		return TILE_WALL
	if ch == ".":
		return TILE_DOT
	if ch == "o":
		return TILE_ENERGIZER
	if ch == "-":
		return TILE_DOOR
	if ch == " ":
		return TILE_EMPTY
	return -1


# === QUERIES ===

func tile_at(x: int, y: int) -> int:
	return _tiles[y * width + x]


## Wraps the tunnel: stepping off the left edge re-enters on the right, and the reverse.
func wrap_tile(tile: Vector2i) -> Vector2i:
	var x: int = tile.x
	if x < 0:
		x = width - 1
	elif x >= width:
		x = 0
	return Vector2i(x, tile.y)


## Pac-Man can't enter walls or doors. Ghosts pass through doors when `ghost` is true.
func is_passable(tile: Vector2i, ghost: bool = false) -> bool:
	var t: Vector2i = wrap_tile(tile)
	if t.y < 0 or t.y >= height:
		return false
	var code: int = tile_at(t.x, t.y)
	if code == TILE_WALL:
		return false
	if code == TILE_DOOR:
		return ghost
	return true


func dot_count() -> int:
	return _dot_count


func energizer_count() -> int:
	return _energizer_count


func pellets_left() -> int:
	return _dot_count + _energizer_count


# === MUTATION ===

## Removes a pellet from the tile. Returns the tile code it held (TILE_EMPTY if there was nothing).
func eat(tile: Vector2i) -> int:
	var t: Vector2i = wrap_tile(tile)
	var idx: int = t.y * width + t.x
	var code: int = _tiles[idx]
	if code == TILE_DOT:
		_dot_count -= 1
	elif code == TILE_ENERGIZER:
		_energizer_count -= 1
	else:
		return TILE_EMPTY
	_tiles[idx] = TILE_EMPTY
	return code
