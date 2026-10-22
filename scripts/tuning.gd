class_name Tuning
extends RefCounted

# Loads data/tuning.json. Gameplay numbers live in the data file, not in code.

# === CONSTANTS ===

const PATH: String = "res://data/tuning.json"
## Logic ticks per second. Movement steps once per tick, so speeds are per tick, not per frame.
const LOGIC_HZ: int = 60


# === FACTORIES ===

static func load_file(path: String = PATH) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Tuning: cannot parse %s" % path)
		return {}
	return parsed


static func ticks_for_seconds(seconds: float) -> int:
	return roundi(seconds * float(LOGIC_HZ))


## Scatter/chase phase lengths in ticks. A negative second value becomes -1 (forever).
static func schedule_ticks(data: Dictionary) -> Array[int]:
	var phases: Array[int] = []
	for seconds: Variant in data.get("scatter_chase_seconds", []):
		var value: float = float(seconds)
		phases.append(-1 if value < 0.0 else ticks_for_seconds(value))
	return phases


## Tiles per logic tick for a speed factor (1.0 = base speed).
static func tiles_per_tick(data: Dictionary, factor_key: String) -> float:
	return tiles_per_tick_factor(data, float(data.get(factor_key, 1.0)))


## Tiles per logic tick for a factor given directly (used for per-level speeds).
static func tiles_per_tick_factor(data: Dictionary, factor: float) -> float:
	var base: float = float(data.get("base_speed_tiles_per_sec", 0.0))
	return base * factor / float(LOGIC_HZ)
