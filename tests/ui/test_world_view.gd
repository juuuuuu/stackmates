extends GutTest

const WORLD_VIEW_SCENE: PackedScene = preload("res://ui/world_view.tscn")
const LEVEL_SCENE: PackedScene = preload("res://levels/level_01.tscn")


func _frame(entries: Array, level_flags: int = 0) -> Snapshot:
	var s: Snapshot = Snapshot.new()
	s.level_flags = level_flags
	for e: Array in entries:
		var slot: int = e[0]
		var position: Vector2 = e[1]
		var flag_bits: int = e[2]
		s.slots.append(slot)
		s.positions.append(position)
		s.flags.append(flag_bits)
	return s


func _view() -> WorldView:
	var view: WorldView = add_child_autofree(WORLD_VIEW_SCENE.instantiate())
	view.show_level(LEVEL_SCENE, Level.from_rows(["S.K.D", "#####"]))
	return view


func test_show_frame_creates_moves_and_removes_sprites() -> void:
	var view: WorldView = _view()
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
	var view: WorldView = _view()
	view.show_frame(_frame([[1, Vector2(10, 20), 0]]))
	view.show_frame(null)
	assert_eq(view.sprite_count(), 1)


func test_key_at_tile_then_above_carrier_then_hidden() -> void:
	var view: WorldView = _view()
	view.show_frame(_frame([[1, Vector2(10, 20), 0]]))
	assert_eq(view.key_sprite().position, Vector2(32, 0))
	assert_true(view.key_sprite().visible)
	view.show_frame(
		_frame([[1, Vector2(10, 20), Snapshot.FLAG_KEY_CARRIER]], Snapshot.LEVEL_FLAG_KEY_TAKEN)
	)
	assert_eq(view.key_sprite().position, Vector2(10, 8))
	assert_true(view.key_sprite().visible)
	var door_flags: int = Snapshot.LEVEL_FLAG_KEY_TAKEN | Snapshot.LEVEL_FLAG_DOOR_OPEN
	view.show_frame(_frame([[1, Vector2(10, 20), 0]], door_flags))
	assert_false(view.key_sprite().visible)


func test_door_sprite_follows_open_flag() -> void:
	var view: WorldView = _view()
	view.show_frame(_frame([]))
	assert_eq(view.door_sprite().position, Vector2(64, 0))
	assert_eq(view.door_sprite().region_rect, Rect2(48, 0, 16, 16))
	view.show_frame(_frame([], Snapshot.LEVEL_FLAG_DOOR_OPEN))
	assert_eq(view.door_sprite().region_rect, Rect2(64, 0, 16, 16))


func test_entered_player_is_hidden_then_removed() -> void:
	var view: WorldView = _view()
	view.show_frame(_frame([[1, Vector2(0, 0), Snapshot.FLAG_ENTERED], [2, Vector2(16, 0), 0]]))
	var p1: Sprite2D = view.get_node("Players/Player1")
	var p2: Sprite2D = view.get_node("Players/Player2")
	assert_false(p1.visible)
	assert_true(p2.visible)
	view.show_frame(_frame([[2, Vector2(16, 0), 0]]))
	assert_eq(view.sprite_count(), 1)


func test_dead_player_is_greyed() -> void:
	var view: WorldView = _view()
	view.show_frame(_frame([[1, Vector2(0, 0), Snapshot.FLAG_DEAD]]))
	var p1: Sprite2D = view.get_node("Players/Player1")
	assert_eq(p1.modulate, WorldView.DEAD_MODULATE)
	view.show_frame(_frame([[1, Vector2(0, 0), 0]]))
	assert_eq(p1.modulate, Color.WHITE)
