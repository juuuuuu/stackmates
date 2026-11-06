extends GutTest

const LEVEL_01_SCENE: PackedScene = preload("res://levels/level_01.tscn")


func test_level_01_loads() -> void:
	var root: Node = add_child_autofree(LEVEL_01_SCENE.instantiate())
	var level: Level = LevelLoader.from_scene_root(root)
	assert_eq(level.grid.width, 40)
	assert_eq(level.grid.height, 22)
	assert_true(level.grid.is_solid(0, 0))
	assert_true(level.grid.is_solid(30, 19))
	assert_false(level.grid.is_solid(5, 5))
	assert_eq(level.spawns.size(), 8)
	assert_eq(level.spawns[0], Vector2i(3, 20))
	assert_eq(level.spawns[7], Vector2i(24, 20))


func test_level_01_has_key_door_and_spike() -> void:
	var root: Node = add_child_autofree(LEVEL_01_SCENE.instantiate())
	var level: Level = LevelLoader.from_scene_root(root)
	assert_eq(level.key_tile, Vector2i(10, 20))
	assert_eq(level.door_tile, Vector2i(36, 16))
	assert_eq(level.grid.get_tile(28, 20), TileGrid.Tile.SPIKE)
	assert_eq(level.spawns.size(), 8)
