class_name Ghost
extends Node2D

# One ghost. Waits in the house, leaves along a fixed route, then roams toward `target`.
# At each centre it takes the open direction closest to the target (ties: up, left, down, right).
# It never reverses, except at a dead end or when the world asks for a reversal on a mode change.
# The world sets `target` before each logic tick (chase target, or scatter corner).

# === ENUMS ===

enum Mode { HOUSE, LEAVING, ROAMING }

# === CONSTANTS ===

const RADIUS_PX: float = 4.0

# === STATE ===

var ghost_id: String = ""
var colour: Color = Color.WHITE
var mode: Mode = Mode.HOUSE
var target: Vector2i = Vector2i.ZERO
var _maze: Maze = null
var _mover: GridMover = null
var _start: Vector2i = Vector2i.ZERO
var _exit: Vector2i = Vector2i.ZERO
var _route: Array[Vector2i] = []


# === SETUP ===

func setup(maze: Maze, id: String, body: Color, start: Vector2i, exit: Vector2i, speed: float) -> void:
	_maze = maze
	ghost_id = id
	colour = body
	_start = start
	_exit = exit
	_mover = GridMover.new(maze, start, Vector2i.ZERO, speed, true)
	_mover.chooser = Callable(self, "_choose_direction")
	reset()


## Back to the start. The ghost that starts on the exit tile (Blinky) starts outside and roams.
func reset() -> void:
	_route.clear()
	if _start == _exit:
		mode = Mode.ROAMING
		_mover.reset_to(_start, Vector2i.LEFT)
	else:
		mode = Mode.HOUSE
		_mover.reset_to(_start, Vector2i.ZERO)
	queue_redraw()


## Starts leaving the house. Does nothing if the ghost is already out.
func release() -> void:
	if mode != Mode.HOUSE:
		return
	_route = _leave_route()
	mode = Mode.LEAVING


# === QUERIES ===

func position_tiles() -> Vector2:
	return _mover.position_tiles()


func current_tile() -> Vector2i:
	return _mover.tile


## Mode change: a roaming ghost turns back at its next opportunity.
func reverse_now() -> void:
	if mode == Mode.ROAMING and not _mover.is_stopped():
		_mover.queue(-_mover.facing)


## Direction at a centre: the open neighbour closest to `target`, never back unless it's a dead end.
## Ties go to the first in order up, left, down, right.
static func pick_toward(maze: Maze, tile: Vector2i, facing: Vector2i, goal: Vector2i) -> Vector2i:
	var order: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
	var back: Vector2i = -facing
	var best: Vector2i = Vector2i.ZERO
	var best_dist: float = 0.0
	for dir: Vector2i in order:
		if facing != Vector2i.ZERO and dir == back:
			continue
		if not maze.is_passable(tile + dir):
			continue
		var dist: float = float((tile + dir - goal).length_squared())
		if best == Vector2i.ZERO or dist < best_dist:
			best = dir
			best_dist = dist
	if best != Vector2i.ZERO:
		return best
	if facing != Vector2i.ZERO and maze.is_passable(tile + back):
		return back
	return Vector2i.ZERO


static func colour_for(id: String) -> Color:
	match id:
		"B":
			return Color(1.0, 0.1, 0.1)
		"K":
			return Color(1.0, 0.7, 0.9)
		"I":
			return Color(0.2, 0.9, 1.0)
		"C":
			return Color(1.0, 0.6, 0.2)
	return Color.WHITE


# === LOGIC TICK ===

func advance() -> void:
	if mode == Mode.HOUSE:
		return
	_mover.step()
	queue_redraw()


# === INTERNAL ===

## Horizontal moves to the exit column, then vertical moves through the door.
func _leave_route() -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	var dx: int = _exit.x - _start.x
	var step_x: Vector2i = Vector2i.RIGHT if dx > 0 else Vector2i.LEFT
	for i: int in absi(dx):
		route.append(step_x)
	var dy: int = _exit.y - _start.y
	var step_y: Vector2i = Vector2i.UP if dy < 0 else Vector2i.DOWN
	for i: int in absi(dy):
		route.append(step_y)
	return route


## Called by GridMover at each centre and when stopped. Returns the next direction.
func _choose_direction(m: GridMover) -> Vector2i:
	if mode == Mode.LEAVING:
		if not _route.is_empty():
			return _route.pop_front()
		mode = Mode.ROAMING
	if mode == Mode.ROAMING:
		return pick_toward(_maze, m.tile, m.facing, target)
	return Vector2i.ZERO


# === DRAWING ===

func _draw() -> void:
	if _mover == null:
		return
	var centre: Vector2 = (_mover.position_tiles() + Vector2(0.5, 0.5)) * MazeView.TILE_PX
	_draw_at(centre)
	# Near the tunnel edges, draw the other copy too.
	var width_px: float = float(_maze.width * MazeView.TILE_PX)
	if centre.x < RADIUS_PX:
		_draw_at(centre + Vector2(width_px, 0.0))
	elif centre.x > width_px - RADIUS_PX:
		_draw_at(centre - Vector2(width_px, 0.0))


func _draw_at(centre: Vector2) -> void:
	draw_circle(centre, RADIUS_PX, colour)
