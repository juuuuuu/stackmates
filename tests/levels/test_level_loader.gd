extends GutTest


func test_level_01_loads() -> void:
	var scene: PackedScene = load("res://levels/level_01.tscn")
	var root: Node = add_child_autofree(scene.instantiate())
	var level: Level = LevelLoader.from_scene_root(root)
	assert_eq(level.grid.width, 40)
	assert_eq(level.grid.height, 22)
	assert_true(level.grid.is_solid(0, 0))
	assert_true(level.grid.is_solid(30, 19))
	assert_false(level.grid.is_solid(5, 5))
	assert_eq(level.spawns.size(), 8)
	assert_eq(level.spawns[0], Vector2i(3, 20))
	assert_eq(level.spawns[7], Vector2i(24, 20))
