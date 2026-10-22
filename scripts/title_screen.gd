class_name TitleScreen
extends Control

# Title screen: name, maze mode choice, the high score for the chosen mode, controls and Start.
# Built in code. Keys are handled by main.gd, and the buttons take no focus, so keys never press them.

# === SIGNALS ===

signal start_requested(mode: String)

# === CONSTANTS ===

const MODES: Array[String] = ["default", "classic"]
const MODE_LABELS: Dictionary = {"default": "DEFAULT", "classic": "CLASSIC"}
const TITLE_COLOUR: Color = Color(1.0, 0.9, 0.1)
const TEXT_COLOUR: Color = Color.WHITE
const WALL_COLOUR: Color = Color(0.13, 0.27, 1.0)

# === STATE ===

var mode: String = "default"
var _scores: Dictionary = {}
var _mode_buttons: Dictionary = {}
var _score_label: Label = null


# === LIFECYCLE ===

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(16.0, 0.0)
	box.size = Vector2(192.0, 288.0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	box.add_child(_label("HAIKU PAC", 28, TITLE_COLOUR))
	box.add_child(_spacer(12.0))

	var mode_row: HBoxContainer = HBoxContainer.new()
	mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_row.add_theme_constant_override("separation", 8)
	box.add_child(mode_row)
	for choice: String in MODES:
		var button: Button = _button(MODE_LABELS[choice], 10)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(88.0, 26.0)
		button.add_theme_stylebox_override("pressed", _selected_style())
		button.add_theme_color_override("font_pressed_color", TITLE_COLOUR)
		button.pressed.connect(select_mode.bind(choice))
		mode_row.add_child(button)
		_mode_buttons[choice] = button

	_score_label = _label("", 10, TEXT_COLOUR)
	box.add_child(_score_label)
	box.add_child(_spacer(8.0))

	var start: Button = _button("START", 12)
	start.custom_minimum_size = Vector2(120.0, 30.0)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func() -> void: start_requested.emit(mode))
	box.add_child(start)
	box.add_child(_spacer(16.0))

	box.add_child(_label("ARROWS OR WASD: MOVE", 8, TEXT_COLOUR))
	box.add_child(_label("P OR ESC: PAUSE", 8, TEXT_COLOUR))
	box.add_child(_label("ENTER OR SPACE: START", 8, TEXT_COLOUR))

	select_mode(mode)


# === PUBLIC API ===

func set_scores(scores: Dictionary) -> void:
	_scores = scores
	_update_score_label()


## Chooses a maze mode and shows its high score.
func select_mode(choice: String) -> void:
	mode = choice
	for key: String in _mode_buttons:
		var button: Button = _mode_buttons[key]
		button.button_pressed = key == mode
	_update_score_label()


## Steps the mode choice by `step` (-1 or 1), wrapping around. Used by the arrow keys.
func cycle_mode(step: int) -> void:
	var index: int = MODES.find(mode)
	select_mode(MODES[posmod(index + step, MODES.size())])


# === INTERNAL ===

func _update_score_label() -> void:
	_score_label.text = "HIGH SCORE  %d" % int(_scores.get(mode, 0))


func _label(text: String, font_size: int, colour: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label


func _button(text: String, font_size: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	return button


## The chosen mode button shows a solid blue fill, so the choice reads at a glance.
func _selected_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = WALL_COLOUR
	style.set_corner_radius_all(3)
	return style


func _spacer(height: float) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	return spacer
