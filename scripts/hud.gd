class_name Hud
extends Control

# Score and high score above the maze, lives and level below it, plus the pause button and pause overlay.
# Drawn in code. Reads Game directly; main.gd shows it during a run.

# === SIGNALS ===

signal pause_pressed

# === CONSTANTS ===

const FONT_SIZE: int = 10
const TEXT_COLOUR: Color = Color.WHITE
const LIFE_COLOUR: Color = Color(1.0, 0.9, 0.1)
const LIFE_RADIUS: float = 5.0
const MAX_LIFE_ICONS: int = 5
const MAZE_RECT: Rect2 = Rect2(0.0, 20.0, 224.0, 248.0)

# === STATE ===

var _pause_button: Button = null
var _paused: bool = false


# === LIFECYCLE ===

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_button = Button.new()
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.position = Vector2(80.0, 269.0)
	_pause_button.size = Vector2(64.0, 18.0)
	_pause_button.add_theme_font_size_override("font_size", 8)
	_pause_button.text = "PAUSE"
	_pause_button.pressed.connect(_on_pause_pressed)
	add_child(_pause_button)


func _process(_delta: float) -> void:
	queue_redraw()


# === PUBLIC API ===

func set_paused(paused: bool) -> void:
	_paused = paused
	_pause_button.text = "RESUME" if paused else "PAUSE"


# === INTERNAL ===

func _on_pause_pressed() -> void:
	pause_pressed.emit()


# === DRAWING ===

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(4.0, 14.0), "SCORE %d" % Game.score, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOUR)
	draw_string(font, Vector2(0.0, 14.0), "HIGH %d" % Game.high_score, HORIZONTAL_ALIGNMENT_RIGHT, 220, FONT_SIZE, TEXT_COLOUR)
	for i: int in mini(Game.lives, MAX_LIFE_ICONS):
		draw_circle(Vector2(10.0 + float(i) * 14.0, 278.0), LIFE_RADIUS, LIFE_COLOUR)
	draw_string(font, Vector2(0.0, 284.0), "LEVEL %d" % Game.level, HORIZONTAL_ALIGNMENT_RIGHT, 220, FONT_SIZE, TEXT_COLOUR)
	if _paused:
		draw_rect(MAZE_RECT, Color(0.0, 0.0, 0.0, 0.6))
		draw_string(font, Vector2(0.0, 150.0), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 224, 16, TEXT_COLOUR)
