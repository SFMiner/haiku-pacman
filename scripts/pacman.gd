class_name Pacman
extends Node2D

# Player-controlled Pac-Man. Logic lives in GridMover. The World calls advance() on the logic tick.

# === CONSTANTS ===

const RADIUS_PX: float = 3.5
const COLOR: Color = Color(1.0, 0.9, 0.1)

# === STATE ===

var _maze: Maze = null
var _view: MazeView = null
var _mover: GridMover = null
var _start: Vector2i = Vector2i.ZERO
var _points_dot: int = 10
var _points_energizer: int = 50


# === SETUP ===

func setup(maze: Maze, view: MazeView, start: Vector2i) -> void:
	_maze = maze
	_view = view
	_start = start
	var data: Dictionary = Tuning.load_file()
	_points_dot = int(data.get("points_dot", 10))
	_points_energizer = int(data.get("points_energizer", 50))
	var speed: float = Tuning.tiles_per_tick(data, "pacman_speed_factor")
	_mover = GridMover.new(maze, start, Vector2i.ZERO, speed)
	queue_redraw()


func reset() -> void:
	_mover.reset_to(_start, Vector2i.ZERO)
	queue_redraw()


func position_tiles() -> Vector2:
	return _mover.position_tiles()


func current_tile() -> Vector2i:
	return _mover.tile


## Direction Pac-Man is moving; ZERO when stopped against a wall.
func current_facing() -> Vector2i:
	return _mover.facing


# === LOGIC TICK ===

func advance() -> void:
	if _mover == null:
		return
	_read_input()
	if _mover.step():
		_on_tile_entered(_mover.tile)
	queue_redraw()


func _read_input() -> void:
	var held: Array[Vector2i] = []
	if Input.is_action_pressed("move_up"):
		held.append(Vector2i.UP)
	if Input.is_action_pressed("move_down"):
		held.append(Vector2i.DOWN)
	if Input.is_action_pressed("move_left"):
		held.append(Vector2i.LEFT)
	if Input.is_action_pressed("move_right"):
		held.append(Vector2i.RIGHT)
	for dir: Vector2i in held:
		_mover.queue(dir)


# === INTERNAL ===

func _on_tile_entered(tile: Vector2i) -> void:
	var code: int = _maze.eat(tile)
	if code == Maze.TILE_EMPTY:
		return
	_view.erase_tile(tile)
	if code == Maze.TILE_DOT:
		Game.score += _points_dot
	elif code == Maze.TILE_ENERGIZER:
		Game.score += _points_energizer
	Sfx.play("chomp")


# === DRAWING ===

func _draw() -> void:
	if _mover == null:
		return
	var centre: Vector2 = (_mover.position_tiles() + Vector2(0.5, 0.5)) * MazeView.TILE_PX
	_draw_pacman_at(centre)
	# Near the tunnel edges, draw the other copy too so Pac-Man slides through instead of popping.
	var width_px: float = float(_maze.width * MazeView.TILE_PX)
	if centre.x < RADIUS_PX:
		_draw_pacman_at(centre + Vector2(width_px, 0.0))
	elif centre.x > width_px - RADIUS_PX:
		_draw_pacman_at(centre - Vector2(width_px, 0.0))


func _draw_pacman_at(centre: Vector2) -> void:
	draw_circle(centre, RADIUS_PX, COLOR)
