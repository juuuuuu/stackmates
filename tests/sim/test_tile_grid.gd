extends GutTest


func test_create_is_all_empty() -> void:
	var g: TileGrid = TileGrid.create(3, 2)
	assert_eq(g.width, 3)
	assert_eq(g.height, 2)
	assert_eq(g.get_tile(2, 1), TileGrid.Tile.EMPTY)


func test_set_then_get() -> void:
	var g: TileGrid = TileGrid.create(3, 2)
	g.set_tile(1, 1, TileGrid.Tile.SOLID)
	assert_true(g.is_solid(1, 1))
	assert_false(g.is_solid(0, 1))


func test_get_tile_outside_is_empty() -> void:
	var g: TileGrid = TileGrid.create(3, 2)
	assert_eq(g.get_tile(-1, 0), TileGrid.Tile.EMPTY)
	assert_eq(g.get_tile(3, 5), TileGrid.Tile.EMPTY)
	assert_false(g.is_solid(99, 99))


func test_overlaps_solid_edges_are_exclusive() -> void:
	var level: Level = Level.from_rows(["#.#", "###"])
	assert_false(level.grid.overlaps_solid(Rect2(16, 0, 16, 16)))
	assert_true(level.grid.overlaps_solid(Rect2(15, 0, 16, 16)))
	assert_true(level.grid.overlaps_solid(Rect2(16, 1, 16, 16)))
