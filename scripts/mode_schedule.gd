class_name ModeSchedule
extends RefCounted

# Scatter/chase cycle. Pure logic: Game owns one, and the world ticks it on the logic tick.
# Phases alternate scatter, chase, scatter, ... A phase length of -1 means forever.

# === STATE ===

var _phases: Array[int] = []
var _index: int = 0
var _left: int = 0


# === SETUP ===

func _init(phases: Array[int]) -> void:
	_phases = phases.duplicate()
	reset()


func reset() -> void:
	_index = 0
	_left = _phase_length()


# === QUERIES ===

func is_scatter() -> bool:
	return _index % 2 == 0


# === LOGIC TICK ===

## Returns true on the tick the mode flips (scatter to chase, or chase to scatter).
func tick() -> bool:
	if _phase_length() < 0:
		return false
	_left -= 1
	if _left > 0:
		return false
	_index = mini(_index + 1, _phases.size() - 1)
	_left = _phase_length()
	return true


# === INTERNAL ===

func _phase_length() -> int:
	if _index >= _phases.size():
		return -1
	return _phases[_index]
