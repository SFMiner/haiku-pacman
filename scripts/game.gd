extends Node

# === SIGNALS ===

signal score_changed(score: int)
signal lives_changed(lives: int)
signal level_changed(level: int)

# === CONSTANTS ===

const MAZE_PATHS: Dictionary = {
	"default": "res://data/maze_default.txt",
	"classic": "res://data/maze_classic.txt",
}

# === STATE ===

## "default" or "classic". Chosen on the title screen; each mode keeps its own high score.
var maze_mode: String = "default"
var ui_open: bool = false
var score: int = 0:
	set(value):
		score = value
		if score > high_score:
			high_score = score
		score_changed.emit(score)
var lives: int = 3:
	set(value):
		lives = value
		lives_changed.emit(lives)
var level: int = 1:
	set(value):
		level = value
		level_changed.emit(level)
var high_score: int = 0
## Once per game: the 10,000-point extra life has been given.
var extra_life_given: bool = false
## Scatter/chase cycle. Owned here so it survives deaths and resets only on a new run.
var mode_schedule: ModeSchedule = ModeSchedule.new(Tuning.schedule_ticks(Tuning.load_file()))


# === PUBLIC API ===

## Maze file for the chosen mode.
func maze_path() -> String:
	return String(MAZE_PATHS.get(maze_mode, MAZE_PATHS["default"]))


func reset_run() -> void:
	score = 0
	lives = 3
	level = 1
	extra_life_given = false
	mode_schedule.reset()
