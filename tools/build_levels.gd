extends SceneTree
## Construit le TileSet et les scènes de level depuis levels/src/*.txt.
## Usage : godot --headless --path . -s tools/build_levels.gd

const TILESET_PATH: String = "res://assets/tileset.tres"
const TILES_TEXTURE_PATH: String = "res://assets/tiles.png"
const SRC_DIR: String = "res://levels/src"
const OUT_DIR: String = "res://levels"
const KIND_LAYER: String = "kind"
const SOURCE_ID: int = 0
const ATLAS_SOLID: Vector2i = Vector2i(0, 0)
const ATLAS_SPIKE: Vector2i = Vector2i(1, 0)


func _init() -> void:
	quit(_build())


func _build() -> int:
	if _build_tileset() != OK:
		push_error("échec de la sauvegarde du TileSet")
		return 1
	var tileset: TileSet = load(TILESET_PATH)
	var dir: DirAccess = DirAccess.open(SRC_DIR)
	if dir == null:
		push_error("dossier introuvable : %s" % SRC_DIR)
		return 1
	var count: int = 0
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".txt"):
			continue
		var rows: Array[String] = _read_rows(SRC_DIR.path_join(file_name))
		if rows.is_empty():
			return 1
		var out_path: String = OUT_DIR.path_join(file_name.get_basename() + ".tscn")
		if _build_level(rows, tileset, out_path) != OK:
			push_error("échec de la sauvegarde de %s" % out_path)
			return 1
		count += 1
	print("levels construits : %d" % count)
	return 0


func _build_tileset() -> Error:
	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(SimConstants.TILE_SIZE, SimConstants.TILE_SIZE)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, KIND_LAYER)
	tileset.set_custom_data_layer_type(0, TYPE_STRING)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = load(TILES_TEXTURE_PATH)
	source.texture_region_size = tileset.tile_size
	source.create_tile(ATLAS_SOLID)
	source.create_tile(ATLAS_SPIKE)
	# Le custom data se pose après add_source : le TileData doit connaître son TileSet.
	tileset.add_source(source, SOURCE_ID)
	source.get_tile_data(ATLAS_SOLID, 0).set_custom_data(KIND_LAYER, "solid")
	source.get_tile_data(ATLAS_SPIKE, 0).set_custom_data(KIND_LAYER, "spike")
	return ResourceSaver.save(tileset, TILESET_PATH)


## Lit un fichier de level et vérifie ses dimensions. Vide si invalide.
func _read_rows(path: String) -> Array[String]:
	var rows: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var row: String = line.trim_suffix("\r")
		if not row.is_empty():
			rows.append(row)
	if rows.size() != Level.HEIGHT:
		push_error("%s : %d lignes au lieu de %d" % [path, rows.size(), Level.HEIGHT])
		return []
	for y: int in rows.size():
		if rows[y].length() != Level.WIDTH:
			var found: int = rows[y].length()
			push_error(
				"%s : ligne %d de %d caractères au lieu de %d" % [path, y, found, Level.WIDTH]
			)
			return []
	return rows


func _build_level(rows: Array[String], tileset: TileSet, out_path: String) -> Error:
	var level_root: Node2D = Node2D.new()
	level_root.name = "Level"
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset
	level_root.add_child(tiles)
	tiles.owner = level_root
	var spawns: Node2D = Node2D.new()
	spawns.name = "Spawns"
	level_root.add_child(spawns)
	spawns.owner = level_root
	var spawn_count: int = 0
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			var c: String = row[x]
			if c == Level.CHAR_SOLID:
				tiles.set_cell(Vector2i(x, y), SOURCE_ID, ATLAS_SOLID)
			elif c == Level.CHAR_SPIKE:
				tiles.set_cell(Vector2i(x, y), SOURCE_ID, ATLAS_SPIKE)
			elif c == Level.CHAR_SPAWN:
				spawn_count += 1
				_add_marker(spawns, level_root, "Spawn%d" % spawn_count, x, y)
			elif c == Level.CHAR_KEY:
				_add_marker(level_root, level_root, "Key", x, y)
			elif c == Level.CHAR_DOOR:
				_add_marker(level_root, level_root, "Door", x, y)
	var scene: PackedScene = PackedScene.new()
	var pack_error: Error = scene.pack(level_root)
	level_root.free()
	if pack_error != OK:
		return pack_error
	return ResourceSaver.save(scene, out_path)


## Pose un Marker2D au centre de la tile (x, y).
func _add_marker(parent: Node, owner_node: Node, marker_name: String, x: int, y: int) -> void:
	var half: float = SimConstants.TILE_SIZE / 2.0
	var marker: Marker2D = Marker2D.new()
	marker.name = marker_name
	marker.position = Vector2(x * SimConstants.TILE_SIZE + half, y * SimConstants.TILE_SIZE + half)
	parent.add_child(marker)
	marker.owner = owner_node
