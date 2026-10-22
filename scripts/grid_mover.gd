class_name GridMover
extends RefCounted

# Pure grid movement: no nodes, so it can be tested headless.
# A mover sits on `tile` and travels toward `tile + facing`, with `progress` (0..1) along that edge.
# Turns are queued and taken at the next tile centre where the new direction is open.
# Reversing is immediate, as in the arcade, because it keeps the same spot on the path.

# === STATE ===

var maze: Maze = null
var tile: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i.ZERO
var queued: Vector2i = Vector2i.ZERO
var progress: float = 0.0
var speed: float = 0.0
var ghost: bool = false


# === SETUP ===

func _init(maze_ref: Maze, start: Vector2i, start_facing: Vector2i, tiles_per_tick: float, is_ghost: bool = false) -> void:
	maze = maze_ref
	tile = start
	facing = start_facing
	speed = tiles_per_tick
	ghost = is_ghost


# === QUERIES ===

func can_move(dir: Vector2i) -> bool:
	return maze.is_passable(tile + dir, ghost)


## Visual position in tile units. Can sit just past the tunnel edge (x < 0 or x >= width) while crossing.
func position_tiles() -> Vector2:
	return Vector2(tile) + Vector2(facing) * progress


func is_stopped() -> bool:
	return facing == Vector2i.ZERO


# === COMMANDS ===

func queue(dir: Vector2i) -> void:
	queued = dir


# === LOGIC TICK ===

## Advances one logic tick. Returns true on the tick the mover reaches a new tile centre.
func step() -> bool:
	if is_stopped():
		if queued != Vector2i.ZERO and can_move(queued):
			facing = queued
			queued = Vector2i.ZERO
		else:
			return false
	_try_reverse()
	progress += speed
	if progress < 1.0:
		return false
	progress -= 1.0
	tile = maze.wrap_tile(tile + facing)
	_choose_direction_at_centre()
	return true


# === INTERNAL ===

## Reverses only when the queued direction is the opposite of facing.
func _try_reverse() -> void:
	if queued == Vector2i.ZERO or queued != -facing:
		return
	if progress <= 0.0:
		# On a centre, just turn around if the way back is open.
		if can_move(queued):
			facing = queued
			queued = Vector2i.ZERO
		return
	# Mid-edge: the way back is the tile we just left, which is always open.
	tile = maze.wrap_tile(tile + facing)
	facing = -facing
	progress = 1.0 - progress
	queued = Vector2i.ZERO


func _choose_direction_at_centre() -> void:
	if queued != Vector2i.ZERO and can_move(queued):
		facing = queued
		queued = Vector2i.ZERO
	if not can_move(facing):
		facing = Vector2i.ZERO
		progress = 0.0
