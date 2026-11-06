class_name TileGrid
extends RefCounted
## Grille de tiles d'un level. Hors grille, tout est EMPTY.

enum Tile { EMPTY, SOLID, SPIKE }

## Retrait sur les bords droit et bas d'un rect, pour que deux rects qui se
## touchent ne se recouvrent pas.
const EDGE_EPSILON: float = 0.001
## Zone létale de 6 px de côté au centre de la base de la tile : un marcheur
## meurt, et la fenêtre de départ de saut devant un spike isolé fait au moins
## 12 ticks (tests/sim/test_spike_window.gd).
const SPIKE_INSET_X: float = 5.0
const SPIKE_INSET_TOP: float = 10.0
const SPIKE_ZONE_SIZE: float = 6.0

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
	return overlaps_tile(rect, Tile.SOLID)


## Vrai si une tile du type donné recouvre le rect (bords droit et bas exclus).
func overlaps_tile(rect: Rect2, tile: Tile) -> bool:
	var x0: int = floori(rect.position.x / SimConstants.TILE_SIZE)
	var x1: int = floori((rect.end.x - EDGE_EPSILON) / SimConstants.TILE_SIZE)
	var y0: int = floori(rect.position.y / SimConstants.TILE_SIZE)
	var y1: int = floori((rect.end.y - EDGE_EPSILON) / SimConstants.TILE_SIZE)
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			if get_tile(x, y) == tile:
				return true
	return false


func _contains(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height


## Vrai si le rect recouvre la zone létale d'une tile SPIKE (bords exclusifs).
func overlaps_spike(rect: Rect2) -> bool:
	var size: int = SimConstants.TILE_SIZE
	var x0: int = floori(rect.position.x / size)
	var x1: int = floori((rect.end.x - EDGE_EPSILON) / size)
	var y0: int = floori(rect.position.y / size)
	var y1: int = floori((rect.end.y - EDGE_EPSILON) / size)
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			if get_tile(x, y) != Tile.SPIKE:
				continue
			var zone: Rect2 = Rect2(
				x * size + SPIKE_INSET_X,
				y * size + SPIKE_INSET_TOP,
				SPIKE_ZONE_SIZE,
				SPIKE_ZONE_SIZE
			)
			if _rects_overlap(rect, zone):
				return true
	return false


static func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return (
		a.position.x < b.end.x - EDGE_EPSILON
		and b.position.x < a.end.x - EDGE_EPSILON
		and a.position.y < b.end.y - EDGE_EPSILON
		and b.position.y < a.end.y - EDGE_EPSILON
	)
