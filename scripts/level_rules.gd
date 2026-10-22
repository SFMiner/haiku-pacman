class_name LevelRules
extends RefCounted

# Level scaling, fruit and extra-life rules. Numbers come from tuning.json.
# Pure logic, so it can be tested headless. Level 1 uses the base values.


# === SPEEDS AND TIMERS ===

## Ghost speed factor for a level, rising by a step and capped.
static func ghost_factor(data: Dictionary, level: int) -> float:
	var start: float = float(data.get("ghost_speed_factor", 0.75))
	var step: float = float(data.get("level_ghost_speed_step", 0.0))
	var cap: float = float(data.get("level_ghost_speed_cap", start))
	return minf(start + step * float(level - 1), cap)


## Pac-Man speed factor for a level, rising by a step and capped.
static func pacman_factor(data: Dictionary, level: int) -> float:
	var start: float = float(data.get("pacman_speed_factor", 0.8))
	var step: float = float(data.get("level_pacman_speed_step", 0.0))
	var cap: float = float(data.get("level_pacman_speed_cap", start))
	return minf(start + step * float(level - 1), cap)


## Frightened time in seconds, shrinking each level down to a floor.
static func frightened_seconds(data: Dictionary, level: int) -> float:
	var start: float = float(data.get("frightened_seconds", 6.0))
	var step: float = float(data.get("level_frightened_step", 0.0))
	var floor_value: float = float(data.get("level_frightened_min", 0.0))
	return maxf(floor_value, start - step * float(level - 1))


## Multiplier for the scatter phases: shorter each level, down to a floor.
static func scatter_scale(data: Dictionary, level: int) -> float:
	var step: float = float(data.get("level_scatter_step", 0.0))
	var floor_value: float = float(data.get("level_scatter_min", 0.2))
	return maxf(floor_value, 1.0 - step * float(level - 1))


## Scatter/chase phase lengths in ticks for a level. Scatter phases (even indexes) are scaled.
static func schedule_ticks(data: Dictionary, level: int) -> Array[int]:
	var base: Array[int] = Tuning.schedule_ticks(data)
	var scale: float = scatter_scale(data, level)
	var out: Array[int] = []
	for i: int in base.size():
		var ticks: int = base[i]
		if i % 2 == 0 and ticks >= 0:
			ticks = roundi(float(ticks) * scale)
		out.append(ticks)
	return out


# === FRUIT AND EXTRA LIFE ===

## Points for the fruit on a level. Uses the last table entry past the end.
static func fruit_points(data: Dictionary, level: int) -> int:
	var table: Array = data.get("fruit_points", [100])
	var index: int = mini(level - 1, table.size() - 1)
	return int(table[index])


## True when the dots eaten this level reach the next fruit trigger.
static func fruit_spawn_due(dots_eaten: int, spawned: int, triggers: Array) -> bool:
	return spawned < triggers.size() and dots_eaten >= int(triggers[spawned])


## True on the score change that first crosses the threshold, and only if not given yet this game.
static func extra_life_due(before: int, after: int, threshold: int, already_given: bool) -> bool:
	return not already_given and before < threshold and after >= threshold
