extends GutTest


func test_from_rows_reads_tiles_and_spawns() -> void:
	var level: Level = Level.from_rows(["S.^S", "####"])
	assert_eq(level.grid.width, 4)
	assert_eq(level.grid.height, 2)
	assert_eq(level.grid.get_tile(2, 0), TileGrid.Tile.SPIKE)
	assert_true(level.grid.is_solid(0, 1))
	assert_eq(level.spawns, [Vector2i(0, 0), Vector2i(3, 0)] as Array[Vector2i])
	assert_eq(level.grid.get_tile(0, 0), TileGrid.Tile.EMPTY)
