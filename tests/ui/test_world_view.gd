extends GutTest

const WORLD_VIEW_SCENE: PackedScene = preload("res://ui/world_view.tscn")


func _frame(entries: Array) -> Snapshot:
	var s: Snapshot = Snapshot.new()
	for e: Array in entries:
		var slot: int = e[0]
		var position: Vector2 = e[1]
		var flag_bits: int = e[2]
		s.slots.append(slot)
		s.positions.append(position)
		s.flags.append(flag_bits)
	return s


func test_show_frame_creates_moves_and_removes_sprites() -> void:
	var view: WorldView = add_child_autofree(WORLD_VIEW_SCENE.instantiate())
	view.show_frame(
		_frame([[1, Vector2(10, 20), 0], [3, Vector2(50, 60), Snapshot.FLAG_FACING_LEFT]])
	)
	assert_eq(view.sprite_count(), 2)
	var s3: Sprite2D = view.get_node("Players/Player3")
	assert_eq(s3.position, Vector2(50, 60))
	assert_true(s3.flip_h)
	assert_eq(s3.region_rect, Rect2(32, 0, 16, 16))
	view.show_frame(_frame([[3, Vector2(51, 60), 0]]))
	assert_eq(view.sprite_count(), 1)
	assert_false(s3.flip_h)
	assert_eq(s3.position, Vector2(51, 60))


func test_show_frame_null_changes_nothing() -> void:
	var view: WorldView = add_child_autofree(WORLD_VIEW_SCENE.instantiate())
	view.show_frame(_frame([[1, Vector2(10, 20), 0]]))
	view.show_frame(null)
	assert_eq(view.sprite_count(), 1)
