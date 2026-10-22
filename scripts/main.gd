extends Node2D

# === CONSTANTS ===

const MAZE_PATH: String = "res://data/maze_default.txt"
const MAZE_OFFSET: Vector2 = Vector2(0, 20)

# === LIFECYCLE ===

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var maze: Maze = Maze.load_file(MAZE_PATH)
	if maze == null:
		return
	var view: MazeView = MazeView.new()
	view.position = MAZE_OFFSET
	add_child(view)
	view.show_maze(maze)
	var start: Vector2i = maze.starts["P"]
	var pacman: Pacman = Pacman.new()
	view.add_child(pacman)
	pacman.setup(maze, view, start)
	var shot_path: String = OS.get_environment("HAIKU_SHOT")
	if shot_path != "":
		_save_screenshot(shot_path)


# === DEBUG ===

## Windowed-only smoke check: HAIKU_SHOT=<png path> saves the viewport after a few frames and quits.
func _save_screenshot(path: String) -> void:
	for i: int in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
