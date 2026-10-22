extends Node

# === SIGNALS ===

signal score_changed(score: int)
signal lives_changed(lives: int)
signal level_changed(level: int)

# === STATE ===

var ui_open: bool = false
var score: int = 0:
	set(value):
		score = value
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
## Scatter/chase cycle. Owned here so it survives deaths and resets only on a new run.
var mode_schedule: ModeSchedule = ModeSchedule.new(Tuning.schedule_ticks(Tuning.load_file()))


# === PUBLIC API ===

func reset_run() -> void:
	score = 0
	lives = 3
	level = 1
	mode_schedule.reset()
