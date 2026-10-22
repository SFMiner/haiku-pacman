class_name World
extends Node2D

# Owns the maze view and every actor. Runs the fixed logic tick, the ghost house, power pellets,
# fruit, levels, and the death and restart flow.

# === SIGNALS ===

## Emitted when the game-over pause ends. main.gd then returns to the title screen.
signal run_finished

# === CONSTANTS ===

## Pac-Man and a ghost (or the fruit) touch when their centres are closer than this, in tiles.
const CAUGHT_DISTANCE: float = 0.5
const DEFAULT_RELEASE_ORDER: Array = ["B", "K", "I", "C"]
const DEFAULT_RELEASE_SECONDS: Array = [0.0, 2.0, 5.0, 8.0]
const FRUIT_COLOUR: Color = Color(1.0, 0.2, 0.2)
const LEVEL_FLASH_PERIOD_TICKS: int = 10

# === STATE ===

var _level_path: String = ""
var _data: Dictionary = {}
var _maze: Maze = null
var _view: MazeView = null
var _pacman: Pacman = null
var _ghosts: Array[Ghost] = []
var _house: GhostHouse = null
var _power: PowerPellet = null
var _ghost_points: int = 200
var _last_released: int = -1
var _death_ticks: int = 0
var _death_pause_ticks: int = 0
var _game_over: bool = false
var _game_over_ticks: int = 0
var _level_clearing: bool = false
var _level_clear_ticks: int = 0
var _dots_at_start: int = 0
var _fruit_next: int = 0
var _fruit_ticks: int = 0
var _score_seen: int = 0


# === SETUP ===

func setup(level_path: String) -> void:
	_level_path = level_path
	_data = Tuning.load_file()
	_ghost_points = int(_data.get("ghost_points_base", 200))
	_death_pause_ticks = Tuning.ticks_for_seconds(float(_data.get("death_pause_seconds", 2.0)))
	_start_level(1)


## Builds a fresh maze and every actor for `level`, then resets positions.
func _start_level(level: int) -> void:
	Game.level = level
	Game.mode_schedule = ModeSchedule.new(LevelRules.schedule_ticks(_data, level))
	_build_actors(Maze.load_file(_level_path), level)
	_dots_at_start = _maze.dot_count()
	_fruit_next = 0
	_fruit_ticks = 0
	_level_clearing = false
	_view.visible = true
	_score_seen = Game.score
	_reset_positions()
	queue_redraw()


func _build_actors(maze: Maze, level: int) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.free()
	_maze = maze
	_view = MazeView.new()
	add_child(_view)
	_view.show_maze(maze)
	_pacman = Pacman.new()
	add_child(_pacman)
	var pac_speed: float = Tuning.tiles_per_tick_factor(_data, LevelRules.pacman_factor(_data, level))
	_pacman.setup(maze, _view, maze.starts["P"], pac_speed)
	_pacman.energizer_eaten.connect(_on_energizer_eaten)
	_build_ghosts(level)
	var frightened_ticks: int = Tuning.ticks_for_seconds(LevelRules.frightened_seconds(_data, level))
	var flash_ticks: int = Tuning.ticks_for_seconds(float(_data.get("frightened_flash_seconds", 2.0)))
	_power = PowerPellet.new(frightened_ticks, flash_ticks)


func _build_ghosts(level: int) -> void:
	var order: Array = _data.get("ghost_release_order", DEFAULT_RELEASE_ORDER)
	var seconds: Array = _data.get("ghost_release_seconds", DEFAULT_RELEASE_SECONDS)
	var speed: float = Tuning.tiles_per_tick_factor(_data, LevelRules.ghost_factor(_data, level))
	var release_ticks: Array[int] = []
	for i: int in order.size():
		release_ticks.append(Tuning.ticks_for_seconds(float(seconds[i])))
	var exit: Vector2i = _maze.starts["B"]
	var home: Vector2i = _maze.starts["K"]
	_ghosts = []
	for id: String in order:
		var ghost: Ghost = Ghost.new()
		add_child(ghost)
		ghost.setup(_maze, id, Ghost.colour_for(id), _maze.starts[id], exit, speed)
		ghost.set_home(home)
		ghost.set_speeds(Tuning.tiles_per_tick(_data, "ghost_frightened_speed_factor"), Tuning.tiles_per_tick(_data, "ghost_eyes_speed_factor"))
		_ghosts.append(ghost)
	_house = GhostHouse.new(release_ticks)


# === LOGIC TICK ===

func _physics_process(_delta: float) -> void:
	if Game.ui_open:
		return
	if _game_over:
		_tick_game_over()
		return
	if _level_clearing:
		_tick_level_clear()
		return
	if _death_ticks > 0:
		_death_ticks -= 1
		if _death_ticks == 0:
			_reset_positions()
		return
	if Game.mode_schedule.tick():
		_reverse_roaming_ghosts()
	if _power.tick():
		_end_frightened()
	_update_targets()
	_pacman.advance()
	if _maze.pellets_left() == 0:
		_begin_level_clear()
		return
	_check_fruit()
	_check_extra_life()
	_tick_ghost_house()
	for ghost: Ghost in _ghosts:
		ghost.flashing = _power.is_flashing()
		ghost.advance()
	_check_contacts()
	queue_redraw()


# === INTERNAL: GAME OVER ===

## Counts down the game-over message, then tells main.gd the run is finished.
func _tick_game_over() -> void:
	_game_over_ticks -= 1
	if _game_over_ticks > 0:
		return
	set_physics_process(false)
	run_finished.emit()


# === INTERNAL: LEVELS ===

func _begin_level_clear() -> void:
	_level_clearing = true
	_level_clear_ticks = Tuning.ticks_for_seconds(float(_data.get("level_clear_seconds", 2.0)))
	_power.stop()
	_fruit_ticks = 0
	queue_redraw()


## The maze flashes, then the next level starts.
func _tick_level_clear() -> void:
	_level_clear_ticks -= 1
	_view.visible = (_level_clear_ticks / LEVEL_FLASH_PERIOD_TICKS) % 2 == 0
	if _level_clear_ticks <= 0:
		_start_level(Game.level + 1)


# === INTERNAL: FRUIT AND EXTRA LIFE ===

func _check_fruit() -> void:
	var eaten: int = _dots_at_start - _maze.dot_count()
	var triggers: Array = _data.get("fruit_dot_triggers", [70, 170])
	if LevelRules.fruit_spawn_due(eaten, _fruit_next, triggers):
		_fruit_next += 1
		_fruit_ticks = Tuning.ticks_for_seconds(float(_data.get("fruit_seconds", 9.0)))
	if _fruit_ticks <= 0:
		return
	_fruit_ticks -= 1
	var fruit_pos: Vector2 = Vector2(_maze.starts["F"])
	if _tile_distance(_pacman.position_tiles(), fruit_pos) < CAUGHT_DISTANCE:
		Game.score += LevelRules.fruit_points(_data, Game.level)
		_fruit_ticks = 0
		Sfx.play("fruit")


func _check_extra_life() -> void:
	var before: int = _score_seen
	_score_seen = Game.score
	var threshold: int = int(_data.get("extra_life_score", 10000))
	if LevelRules.extra_life_due(before, Game.score, threshold, Game.extra_life_given):
		Game.extra_life_given = true
		Game.lives += 1


# === INTERNAL: GHOSTS AND CONTACTS ===

func _on_energizer_eaten() -> void:
	_power.start()
	for ghost: Ghost in _ghosts:
		ghost.enter_frightened()


func _end_frightened() -> void:
	for ghost: Ghost in _ghosts:
		ghost.end_frightened()


func _tick_ghost_house() -> void:
	# The house counts as clear once the last released ghost is out (eyes returning do not block it).
	var house_clear: bool = _last_released < 0 or _ghosts[_last_released].mode not in [Ghost.Mode.HOUSE, Ghost.Mode.LEAVING]
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


## Frightened ghosts are eaten. Roaming ghosts kill Pac-Man.
func _check_contacts() -> void:
	var pac_pos: Vector2 = _pacman.position_tiles()
	for ghost: Ghost in _ghosts:
		if _tile_distance(pac_pos, ghost.position_tiles()) >= CAUGHT_DISTANCE:
			continue
		if ghost.mode == Ghost.Mode.FRIGHTENED:
			_eat_ghost(ghost)
		elif ghost.is_deadly():
			_on_pacman_caught()
			return


func _eat_ghost(ghost: Ghost) -> void:
	Game.score += _power.eat_ghost(_ghost_points)
	ghost.eat()
	Sfx.play("eat_ghost")


func _on_pacman_caught() -> void:
	Game.lives -= 1
	_pacman.visible = false
	_power.stop()
	_fruit_ticks = 0
	if Game.lives <= 0:
		_game_over = true
		_game_over_ticks = Tuning.ticks_for_seconds(float(_data.get("game_over_seconds", 3.0)))
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
	_power.stop()
	for ghost: Ghost in _ghosts:
		ghost.reset()
	_house.reset()
	_last_released = -1


# === DRAWING ===

func _draw() -> void:
	if _fruit_ticks > 0:
		var centre: Vector2 = (Vector2(_maze.starts["F"]) + Vector2(0.5, 0.5)) * MazeView.TILE_PX
		draw_circle(centre, 3.5, FRUIT_COLOUR)
	if _game_over:
		draw_string(ThemeDB.fallback_font, Vector2(56.0, 150.0), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
