extends GutTest
## La porte se dessine sur deux tuiles : la tuile au-dessus de chaque door
## reste vide dans tous les niveaux.


func test_tile_above_every_door_is_empty() -> void:
	for path: String in LevelList.PATHS:
		var level: Level = Walkthrough.load_level(path)
		var above: Vector2i = level.door_tile + Vector2i(0, -1)
		assert_eq(level.grid.get_tile(above.x, above.y), TileGrid.Tile.EMPTY, path)
