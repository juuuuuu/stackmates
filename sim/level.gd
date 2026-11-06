class_name Level
extends RefCounted
## Un level : une grille de tiles et des spawns, dans l'ordre de lecture.

const WIDTH: int = 40
const HEIGHT: int = 22
const CHAR_SOLID: String = "#"
const CHAR_SPIKE: String = "^"
const CHAR_SPAWN: String = "S"
const CHAR_KEY: String = "K"
const CHAR_DOOR: String = "D"
const NO_TILE: Vector2i = Vector2i(-1, -1)

var grid: TileGrid
var spawns: Array[Vector2i] = []
var key_tile: Vector2i = NO_TILE
var door_tile: Vector2i = NO_TILE


## Construit un level depuis des lignes de texte : '#' solid, '^' spike,
## 'S' spawn, 'K' key, 'D' door, tout autre caractère vide.
static func from_rows(rows: Array[String]) -> Level:
	var level: Level = Level.new()
	var rows_count: int = rows.size()
	var columns_count: int = 0
	if rows_count > 0:
		columns_count = rows[0].length()
	level.grid = TileGrid.create(columns_count, rows_count)
	for y: int in rows_count:
		var row: String = rows[y]
		for x: int in row.length():
			var c: String = row[x]
			if c == CHAR_SOLID:
				level.grid.set_tile(x, y, TileGrid.Tile.SOLID)
			elif c == CHAR_SPIKE:
				level.grid.set_tile(x, y, TileGrid.Tile.SPIKE)
			elif c == CHAR_SPAWN:
				level.spawns.append(Vector2i(x, y))
			elif c == CHAR_KEY:
				level.key_tile = Vector2i(x, y)
			elif c == CHAR_DOOR:
				level.door_tile = Vector2i(x, y)
	return level


func has_key() -> bool:
	return key_tile != NO_TILE


func key_rect() -> Rect2:
	return _tile_rect(key_tile)


func door_rect() -> Rect2:
	return _tile_rect(door_tile)


static func _tile_rect(tile: Vector2i) -> Rect2:
	var size: int = SimConstants.TILE_SIZE
	return Rect2(tile.x * size, tile.y * size, size, size)
