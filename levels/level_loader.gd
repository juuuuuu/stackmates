class_name LevelLoader
extends RefCounted
## Construit un Level depuis une scène de level : le TileMapLayer "Tiles"
## (custom data "kind") et les Marker2D sous "Spawns", triés par nom.

const TILES_NODE: String = "Tiles"
const SPAWNS_NODE: String = "Spawns"
const KEY_NODE: String = "Key"
const DOOR_NODE: String = "Door"
const KIND_LAYER: String = "kind"
const KIND_SOLID: String = "solid"
const KIND_SPIKE: String = "spike"


static func from_scene_root(root: Node) -> Level:
	var level: Level = Level.new()
	level.grid = TileGrid.create(Level.WIDTH, Level.HEIGHT)
	var tiles: TileMapLayer = root.get_node(TILES_NODE) as TileMapLayer
	for cell: Vector2i in tiles.get_used_cells():
		var data: TileData = tiles.get_cell_tile_data(cell)
		if data == null:
			continue
		var kind: String = data.get_custom_data(KIND_LAYER)
		if kind == KIND_SOLID:
			level.grid.set_tile(cell.x, cell.y, TileGrid.Tile.SOLID)
		elif kind == KIND_SPIKE:
			level.grid.set_tile(cell.x, cell.y, TileGrid.Tile.SPIKE)
	var markers: Array[Node] = root.get_node(SPAWNS_NODE).get_children()
	markers.sort_custom(_by_natural_name)
	for marker: Node in markers:
		var marker_2d: Marker2D = marker as Marker2D
		if marker_2d != null:
			level.spawns.append(_tile_of(marker_2d))
	var key_marker: Marker2D = root.get_node_or_null(KEY_NODE) as Marker2D
	if key_marker != null:
		level.key_tile = _tile_of(key_marker)
	var door_marker: Marker2D = root.get_node_or_null(DOOR_NODE) as Marker2D
	if door_marker != null:
		level.door_tile = _tile_of(door_marker)
	return level


static func _tile_of(marker: Marker2D) -> Vector2i:
	return Vector2i((marker.position / SimConstants.TILE_SIZE).floor())


static func _by_natural_name(a: Node, b: Node) -> bool:
	return String(a.name).naturalnocasecmp_to(String(b.name)) < 0
