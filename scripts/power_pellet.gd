class_name PowerPellet
extends RefCounted

# Frightened timer and the eat-ghost chain for power pellets. Pure logic, so it can be tested headless.
# The chain (200, 400, 800, 1600) resets when a pellet's timer ends, or when a new pellet is eaten.

# === CONSTANTS ===

const MAX_CHAIN_STEP: int = 3
const BLINK_TICKS: int = 8

# === STATE ===

var duration_ticks: int = 0
var flash_ticks: int = 0
var ticks_left: int = 0
var chain: int = 0


# === SETUP ===

func _init(duration: int, flash: int) -> void:
	duration_ticks = duration
	flash_ticks = flash


## A new pellet restarts the timer and the chain.
func start() -> void:
	ticks_left = duration_ticks
	chain = 0


## Cancels the timer (on death or restart).
func stop() -> void:
	ticks_left = 0
	chain = 0


# === QUERIES ===

func is_active() -> bool:
	return ticks_left > 0


## Near the end of the timer, the frightened ghosts blink (colour is not the only cue).
func is_flashing() -> bool:
	return ticks_left > 0 and ticks_left <= flash_ticks and (ticks_left / BLINK_TICKS) % 2 == 0


## Points for the next ghost eaten in this pellet. Advances the chain.
func eat_ghost(base_points: int) -> int:
	var points: int = base_points << mini(chain, MAX_CHAIN_STEP)
	chain += 1
	return points


# === LOGIC TICK ===

## Returns true on the tick the timer runs out.
func tick() -> bool:
	if ticks_left <= 0:
		return false
	ticks_left -= 1
	if ticks_left > 0:
		return false
	chain = 0
	return true
