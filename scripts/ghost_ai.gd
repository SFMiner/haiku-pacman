class_name GhostAI
extends RefCounted

# Chase targets from GDD.md. Pure logic, so it can be tested headless.
# Scatter mode does not use these: the world sends each ghost to its scatter_corner instead.

# === CONSTANTS ===

const PINKY_LOOKAHEAD: int = 4
const INKY_LOOKAHEAD: int = 2
const CLYDE_SHY_DISTANCE: float = 8.0


# === QUERIES ===

## Chase target for a ghost. `blinky_tile` is Blinky's current tile, used by Inky.
static func target_tile(ghost_id: String, pacman_tile: Vector2i, pacman_dir: Vector2i, blinky_tile: Vector2i, ghost_tile: Vector2i) -> Vector2i:
	match ghost_id:
		"B":
			return pacman_tile
		"K":
			var pinky: Vector2i = pacman_tile + pacman_dir * PINKY_LOOKAHEAD
			# Known arcade quirk, kept on purpose: facing up also shifts Pinky's target 4 tiles left.
			if pacman_dir == Vector2i.UP:
				pinky += Vector2i.LEFT * PINKY_LOOKAHEAD
			return pinky
		"I":
			var pivot: Vector2i = pacman_tile + pacman_dir * INKY_LOOKAHEAD
			return pivot * 2 - blinky_tile
		"C":
			if Vector2(ghost_tile - pacman_tile).length() > CLYDE_SHY_DISTANCE:
				return pacman_tile
			return scatter_corner("C")
	return pacman_tile


## Corner each ghost heads for in scatter mode. Corners sit just outside the maze, as in the arcade.
static func scatter_corner(ghost_id: String) -> Vector2i:
	match ghost_id:
		"B":
			return Vector2i(25, -3)
		"K":
			return Vector2i(2, -3)
		"I":
			return Vector2i(27, 34)
		"C":
			return Vector2i(0, 34)
	return Vector2i.ZERO
