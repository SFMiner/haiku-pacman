class_name Ghost
extends Node2D

# One ghost. Modes:
#   HOUSE: waits in the house.  LEAVING: follows a fixed route out through the door.
#   ROAMING: chases, heading for `target` (only deadly mode).
#   FRIGHTENED: blue, turns at random, can be eaten.  EATEN: eyes only, heads back to the house.
# At each centre it picks a direction from the mode's rule. It reverses only at dead ends, or when
# the mode changes (enter_frightened). The world sets `target` and `flashing` before each logic tick.

# === ENUMS ===

enum Mode { HOUSE, LEAVING, ROAMING, FRIGHTENED, EATEN }

# === CONSTANTS ===

const RADIUS_PX: float = 4.0
const FRIGHTENED_COLOUR: Color = Color(0.2, 0.3, 1.0)
const FLASH_COLOUR: Color = Color(1.0, 1.0, 1.0)
const EYE_COLOUR: Color = Color(1.0, 1.0, 1.0)
const PUPIL_COLOUR: Color = Color(0.1, 0.2, 0.9)

# === STATE ===

var ghost_id: String = ""
var colour: Color = Color.WHITE
var mode: Mode = Mode.HOUSE
var target: Vector2i = Vector2i.ZERO
var flashing: bool = false
var _maze: Maze = null
var _mover: GridMover = null
var _start: Vector2i = Vector2i.ZERO
var _exit: Vector2i = Vector2i.ZERO
var _home: Vector2i = Vector2i.ZERO
var _route: Array[Vector2i] = []
var _speed: float = 0.0
var _frightened_speed: float = 0.0
var _eyes_speed: float = 0.0


# === SETUP ===

func setup(maze: Maze, id: String, body: Color, start: Vector2i, exit: Vector2i, speed: float) -> void:
	_maze = maze
	ghost_id = id
	colour = body
	_start = start
	_exit = exit
	_home = start
	_speed = speed
	_frightened_speed = speed * 0.5
	_eyes_speed = speed * 1.5
	_mover = GridMover.new(maze, start, Vector2i.ZERO, speed, true)
	_mover.chooser = Callable(self, "_choose_direction")
	reset()


## Tile that eyes head for, and the centre they leave from.
func set_home(tile: Vector2i) -> void:
	_home = tile


func set_speeds(frightened_tiles_per_tick: float, eyes_tiles_per_tick: float) -> void:
	_frightened_speed = frightened_tiles_per_tick
	_eyes_speed = eyes_tiles_per_tick


## Back to the start. The ghost that starts on the exit tile (Blinky) starts outside and roams.
func reset() -> void:
	_route.clear()
	flashing = false
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
	_route = _leave_route(_start)
	mode = Mode.LEAVING


## Power pellet eaten. A roaming ghost turns blue and turns back once. Others are unchanged.
func enter_frightened() -> void:
	if mode != Mode.ROAMING:
		return
	reverse_now()
	mode = Mode.FRIGHTENED
	queue_redraw()


## Power pellet timer ran out.
func end_frightened() -> void:
	if mode == Mode.FRIGHTENED:
		mode = Mode.ROAMING
		queue_redraw()


## Pac-Man ate this frightened ghost. It becomes eyes and heads back to the house.
func eat() -> void:
	if mode != Mode.FRIGHTENED:
		return
	mode = Mode.EATEN
	_route.clear()
	queue_redraw()


## Only roaming ghosts kill Pac-Man.
func is_deadly() -> bool:
	return mode == Mode.ROAMING


# === QUERIES ===

func position_tiles() -> Vector2:
	return _mover.position_tiles()


func current_tile() -> Vector2i:
	return _mover.tile


## Mode change: a roaming ghost turns back at its next opportunity.
func reverse_now() -> void:
	if mode == Mode.ROAMING and not _mover.is_stopped():
		_mover.queue(-_mover.facing)


## Frightened choice: a random open direction, never back unless it's a dead end.
static func pick_random(maze: Maze, tile: Vector2i, facing: Vector2i) -> Vector2i:
	var options: Array[Vector2i] = []
	var back: Vector2i = -facing
	for dir: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		if facing != Vector2i.ZERO and dir == back:
			continue
		if maze.is_passable(tile + dir):
			options.append(dir)
	if not options.is_empty():
		return options[randi() % options.size()]
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
	_mover.speed = _speed_for_mode()
	_mover.step()
	queue_redraw()


# === INTERNAL ===

func _speed_for_mode() -> float:
	match mode:
		Mode.FRIGHTENED:
			return _frightened_speed
		Mode.EATEN:
			return _eyes_speed
	return _speed


## Horizontal moves to the exit column, then vertical moves through the door.
func _leave_route(from: Vector2i) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	var dx: int = _exit.x - from.x
	var step_x: Vector2i = Vector2i.RIGHT if dx > 0 else Vector2i.LEFT
	for i: int in absi(dx):
		route.append(step_x)
	var dy: int = _exit.y - from.y
	var step_y: Vector2i = Vector2i.UP if dy < 0 else Vector2i.DOWN
	for i: int in absi(dy):
		route.append(step_y)
	return route


## Called by GridMover at each centre and when stopped. Returns the next direction.
func _choose_direction(m: GridMover) -> Vector2i:
	match mode:
		Mode.LEAVING:
			if not _route.is_empty():
				return _route.pop_front()
			mode = Mode.ROAMING
			return GhostPath.next_step(_maze, m.tile, m.facing, target)
		Mode.ROAMING:
			return GhostPath.next_step(_maze, m.tile, m.facing, target)
		Mode.FRIGHTENED:
			return pick_random(_maze, m.tile, m.facing)
		Mode.EATEN:
			if m.tile == _home:
				# Eyes reached the house: leave again from the centre.
				_route = _leave_route(_home)
				mode = Mode.LEAVING
				if not _route.is_empty():
					return _route.pop_front()
				mode = Mode.ROAMING
				return GhostPath.next_step(_maze, m.tile, m.facing, target)
			return GhostPath.next_step(_maze, m.tile, m.facing, _home, true)
	return Vector2i.ZERO


# === DRAWING ===

func _draw() -> void:
	if _mover == null:
		return
	var centre: Vector2 = (_mover.position_tiles() + Vector2(0.5, 0.5)) * MazeView.TILE_PX
	var width_px: float = float(_maze.width * MazeView.TILE_PX)
	var offsets: Array[float] = [0.0]
	if centre.x < RADIUS_PX:
		offsets.append(width_px)
	elif centre.x > width_px - RADIUS_PX:
		offsets.append(-width_px)
	for offset: float in offsets:
		var at: Vector2 = centre + Vector2(offset, 0.0)
		if mode == Mode.EATEN:
			_draw_eyes(at)
		else:
			draw_circle(at, RADIUS_PX, _body_colour())


func _body_colour() -> Color:
	if mode == Mode.FRIGHTENED:
		return FLASH_COLOUR if flashing else FRIGHTENED_COLOUR
	return colour


func _draw_eyes(at: Vector2) -> void:
	var dir: Vector2 = Vector2(_mover.facing)
	for side: float in [-2.0, 2.0]:
		var eye: Vector2 = at + Vector2(side, -1.0)
		draw_circle(eye, 1.8, EYE_COLOUR)
		draw_circle(eye + dir * 0.8, 0.9, PUPIL_COLOUR)
