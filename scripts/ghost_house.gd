class_name GhostHouse
extends RefCounted

# Decides when each ghost leaves the house. Pure logic: the world says whether the house is clear.
# Ghosts leave one at a time, in list order. Each release time counts ticks from the last reset.

# === STATE ===

var _release_ticks: Array[int] = []
var _elapsed: int = 0
var _next: int = 0


# === SETUP ===

func _init(release_ticks: Array[int]) -> void:
	_release_ticks = release_ticks.duplicate()


func reset() -> void:
	_elapsed = 0
	_next = 0


func all_released() -> bool:
	return _next >= _release_ticks.size()


# === LOGIC TICK ===

## Returns the index of the ghost to release on this tick, or -1.
## `house_clear` is true when the previously released ghost has left the house.
func tick(house_clear: bool) -> int:
	if all_released():
		return -1
	_elapsed += 1
	if house_clear and _elapsed >= _release_ticks[_next]:
		var index: int = _next
		_next += 1
		return index
	return -1
