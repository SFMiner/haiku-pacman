extends Node2D

# Top-level flow: title screen → a run (World and HUD) → game over → title. Owns the high score table and pause.

# === CONSTANTS ===

const MAZE_OFFSET: Vector2 = Vector2(0, 20)

# === STATE ===

var _title: TitleScreen = null
var _hud: Hud = null
var _world: World = null
var _scores: Dictionary = {}


# === LIFECYCLE ===

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_scores = SaveManager.load_scores()
	_world = null
	_hud = Hud.new()
	add_child(_hud)
	_hud.hide()
	_hud.pause_pressed.connect(_toggle_pause)
	_title = TitleScreen.new()
	add_child(_title)
	_title.start_requested.connect(_start_run)
	_show_title()
	# Debug gate: HAIKU_AUTOSTART=default|classic starts a run straight away.
	var auto_mode: String = OS.get_environment("HAIKU_AUTOSTART")
	if auto_mode in Game.MAZE_PATHS:
		_start_run(auto_mode)
	var shot_path: String = OS.get_environment("HAIKU_SHOT")
	if shot_path != "":
		_save_screenshot(shot_path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if _world == null:
		if event.is_action_pressed("start"):
			_start_run(_title.mode)
		elif event.is_action_pressed("move_left"):
			_title.cycle_mode(-1)
		elif event.is_action_pressed("move_right"):
			_title.cycle_mode(1)
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _notification(what: int) -> void:
	# Keep a new record if the window closes mid-run.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_store_high_score()


# === INTERNAL: FLOW ===

func _show_title() -> void:
	Game.ui_open = true
	_hud.hide()
	_title.set_scores(_scores)
	_title.show()


func _start_run(mode: String) -> void:
	Game.maze_mode = mode
	Game.reset_run()
	Game.high_score = int(_scores.get(mode, 0))
	Game.ui_open = false
	Sfx.set_paused(false)
	_title.hide()
	_hud.set_paused(false)
	_hud.show()
	_world = World.new()
	_world.position = MAZE_OFFSET
	add_child(_world)
	move_child(_world, 0)
	_world.run_finished.connect(_end_run)
	_world.setup(Game.maze_path())


func _end_run() -> void:
	_store_high_score()
	if _world != null:
		_world.queue_free()
		_world = null
	_show_title()


func _toggle_pause() -> void:
	if _world == null:
		return
	Game.ui_open = not Game.ui_open
	Sfx.set_paused(Game.ui_open)
	_hud.set_paused(Game.ui_open)
	if Game.ui_open:
		_store_high_score()


func _store_high_score() -> void:
	if SaveManager.record(_scores, Game.maze_mode, Game.high_score):
		SaveManager.save_scores(_scores)


# === DEBUG ===

## Windowed-only smoke check: HAIKU_SHOT=<png path> saves the viewport after a few frames and quits.
func _save_screenshot(path: String) -> void:
	for i: int in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
