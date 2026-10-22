class_name World
extends Node2D

# Owns the maze view and every actor. Runs the fixed logic tick, the ghost house, and the death and restart flow.

# === CONSTANTS ===

## Pac-Man and a roaming ghost touch when their centres are closer than this, in tiles.
const CAUGHT_DISTANCE: float = 0.5
const DEFAULT_RELEASE_ORDER: Array = ["B", "K", "I", "C"]
const DEFAULT_RELEASE_SECONDS: Array = [0.0, 2.0, 5.0, 8.0]

# === STATE ===

var _maze: Maze = null
var _view: MazeView = null
var _pacman: Pacman = null
var _ghosts: Array[Ghost] = []
var _house: GhostHouse = null
var _last_released: int = -1
var _death_ticks: int = 0
var _death_pause_ticks: int = 0
var _game_over: bool = false


# === SETUP ===

func setup(maze: Maze) -> void:
	_maze = maze
	var data: Dictionary = Tuning.load_file()
	_view = MazeView.new()
	add_child(_view)
	_view.show_maze(maze)
	_pacman = Pacman.new()
	add_child(_pacman)
	_pacman.setup(maze, _view, maze.starts["P"])
	_build_ghosts(data)
	_death_pause_ticks = Tuning.ticks_for_seconds(float(data.get("death_pause_seconds", 2.0)))
	_reset_positions()


func _build_ghosts(data: Dictionary) -> void:
	var order: Array = data.get("ghost_release_order", DEFAULT_RELEASE_ORDER)
	var seconds: Array = data.get("ghost_release_seconds", DEFAULT_RELEASE_SECONDS)
	var speed: float = Tuning.tiles_per_tick(data, "ghost_speed_factor")
	var release_ticks: Array[int] = []
	for i: int in order.size():
		release_ticks.append(Tuning.ticks_for_seconds(float(seconds[i])))
	var exit: Vector2i = _maze.starts["B"]
	for id: String in order:
		var ghost: Ghost = Ghost.new()
		add_child(ghost)
		ghost.setup(_maze, id, Ghost.colour_for(id), _maze.starts[id], exit, speed)
		_ghosts.append(ghost)
	_house = GhostHouse.new(release_ticks)


# === LOGIC TICK ===

func _physics_process(_delta: float) -> void:
	if Game.ui_open or _game_over:
		return
	if _death_ticks > 0:
		_death_ticks -= 1
		if _death_ticks == 0:
			_reset_positions()
		return
	if Game.mode_schedule.tick():
		_reverse_roaming_ghosts()
	_update_targets()
	_pacman.advance()
	_tick_ghost_house()
	for ghost: Ghost in _ghosts:
		ghost.advance()
	_check_caught()


func _unhandled_input(event: InputEvent) -> void:
	if _game_over and event.is_action_pressed("start") and not event.is_echo():
		Game.reset_run()
		_game_over = false
		_reset_positions()
		queue_redraw()


# === INTERNAL ===

func _tick_ghost_house() -> void:
	var house_clear: bool = _last_released < 0 or _ghosts[_last_released].mode == Ghost.Mode.ROAMING
	var index: int = _house.tick(house_clear)
	if index >= 0:
		_ghosts[index].release()
		_last_released = index


## Chase target, or scatter corner while the schedule is in scatter mode.
func _update_targets() -> void:
	var pac_tile: Vector2i = _pacman.current_tile()
	var pac_dir: Vector2i = _pacman.current_facing()
	var blinky_tile: Vector2i = _blinky().current_tile()
	var scatter: bool = Game.mode_schedule.is_scatter()
	for ghost: Ghost in _ghosts:
		if scatter:
			ghost.target = GhostAI.scatter_corner(ghost.ghost_id)
		else:
			ghost.target = GhostAI.target_tile(ghost.ghost_id, pac_tile, pac_dir, blinky_tile, ghost.current_tile())


func _blinky() -> Ghost:
	for ghost: Ghost in _ghosts:
		if ghost.ghost_id == "B":
			return ghost
	return _ghosts[0]


func _reverse_roaming_ghosts() -> void:
	for ghost: Ghost in _ghosts:
		ghost.reverse_now()


func _check_caught() -> void:
	var pac_pos: Vector2 = _pacman.position_tiles()
	for ghost: Ghost in _ghosts:
		if ghost.mode != Ghost.Mode.ROAMING:
			continue
		if _tile_distance(pac_pos, ghost.position_tiles()) < CAUGHT_DISTANCE:
			_on_pacman_caught()
			return


func _on_pacman_caught() -> void:
	Game.lives -= 1
	_pacman.visible = false
	if Game.lives <= 0:
		_game_over = true
		queue_redraw()
		return
	_death_ticks = _death_pause_ticks


## Distance between two tile positions, going the short way round the tunnel.
func _tile_distance(a: Vector2, b: Vector2) -> float:
	var dx: float = absf(a.x - b.x)
	dx = minf(dx, float(_maze.width) - dx)
	return Vector2(dx, absf(a.y - b.y)).length()


func _reset_positions() -> void:
	_pacman.reset()
	_pacman.visible = true
	for ghost: Ghost in _ghosts:
		ghost.reset()
	_house.reset()
	_last_released = -1


# === DRAWING ===

func _draw() -> void:
	if _game_over:
		draw_string(ThemeDB.fallback_font, Vector2(56.0, 150.0), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
