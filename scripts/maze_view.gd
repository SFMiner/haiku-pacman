class_name MazeView
extends Node2D

# Draws a Maze into one Image and shows it as a single texture, so the whole maze costs one draw call.
# Eaten pellets are erased by repainting their tile.

# === CONSTANTS ===

const TILE_PX: int = 8
const WALL_COLOR: Color = Color(0.13, 0.27, 1.0)
const DOT_COLOR: Color = Color(1.0, 0.85, 0.7)
const DOOR_COLOR: Color = Color(1.0, 0.7, 0.8)

# === STATE ===

var _maze: Maze = null
var _image: Image = null
var _texture: ImageTexture = null


# === PUBLIC API ===

func show_maze(maze: Maze) -> void:
	_maze = maze
	_image = Image.create_empty(maze.width * TILE_PX, maze.height * TILE_PX, false, Image.FORMAT_RGBA8)
	_image.fill(Color.BLACK)
	for y: int in maze.height:
		for x: int in maze.width:
			_paint_tile(x, y)
	_texture = ImageTexture.create_from_image(_image)
	queue_redraw()


## Call after Maze.eat() so the pellet disappears from the picture.
func erase_tile(tile: Vector2i) -> void:
	if _image == null:
		return
	_image.fill_rect(_tile_rect(tile.x, tile.y), Color.BLACK)
	_texture.update(_image)


# === DRAWING ===

func _draw() -> void:
	if _texture != null:
		draw_texture(_texture, Vector2.ZERO)


func _paint_tile(x: int, y: int) -> void:
	var rect: Rect2i = _tile_rect(x, y)
	var code: int = _maze.tile_at(x, y)
	if code == Maze.TILE_WALL:
		_image.fill_rect(rect, WALL_COLOR)
	elif code == Maze.TILE_DOT:
		_image.fill_rect(Rect2i(rect.position + Vector2i(3, 3), Vector2i(2, 2)), DOT_COLOR)
	elif code == Maze.TILE_ENERGIZER:
		_image.fill_rect(Rect2i(rect.position + Vector2i(2, 2), Vector2i(4, 4)), DOT_COLOR)
	elif code == Maze.TILE_DOOR:
		_image.fill_rect(Rect2i(rect.position + Vector2i(0, 3), Vector2i(TILE_PX, 2)), DOOR_COLOR)


func _tile_rect(x: int, y: int) -> Rect2i:
	return Rect2i(x * TILE_PX, y * TILE_PX, TILE_PX, TILE_PX)
