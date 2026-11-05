class_name Level
extends RefCounted
## Un level : une grille de tiles et des spawns, dans l'ordre de lecture.

const WIDTH: int = 40
const HEIGHT: int = 22
const CHAR_SOLID: String = "#"
const CHAR_SPIKE: String = "^"
const CHAR_SPAWN: String = "S"

var grid: TileGrid
var spawns: Array[Vector2i] = []


## Construit un level depuis des lignes de texte : '#' solid, '^' spike,
## 'S' spawn, tout autre caractère vide.
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
	return level
