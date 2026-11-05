class_name TileGrid
extends RefCounted
## Grille de tiles d'un level. Hors grille, tout est EMPTY.

enum Tile { EMPTY, SOLID, SPIKE }

## Retrait sur les bords droit et bas d'un rect, pour que deux rects qui se
## touchent ne se recouvrent pas.
const EDGE_EPSILON: float = 0.001

var width: int
var height: int
var _tiles: Array[Tile] = []


static func create(w: int, h: int) -> TileGrid:
	var grid: TileGrid = TileGrid.new()
	grid.width = w
	grid.height = h
	grid._tiles.resize(w * h)
	return grid


func get_tile(x: int, y: int) -> Tile:
	if not _contains(x, y):
		return Tile.EMPTY
	return _tiles[y * width + x]


func set_tile(x: int, y: int, tile: Tile) -> void:
	if _contains(x, y):
		_tiles[y * width + x] = tile


func is_solid(x: int, y: int) -> bool:
	return get_tile(x, y) == Tile.SOLID


func overlaps_solid(rect: Rect2) -> bool:
	var x0: int = floori(rect.position.x / SimConstants.TILE_SIZE)
	var x1: int = floori((rect.end.x - EDGE_EPSILON) / SimConstants.TILE_SIZE)
	var y0: int = floori(rect.position.y / SimConstants.TILE_SIZE)
	var y1: int = floori((rect.end.y - EDGE_EPSILON) / SimConstants.TILE_SIZE)
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			if is_solid(x, y):
				return true
	return false


func _contains(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height
