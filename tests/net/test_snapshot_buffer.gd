extends GutTest


func _at(tick: int, x: float, slots: Array[int] = [1]) -> Snapshot:
	var s: Snapshot = Snapshot.new()
	s.tick = tick
	for slot: int in slots:
		s.slots.append(slot)
		s.positions.append(Vector2(x, 0))
		s.flags.append(0)
	return s


func test_push_older_tick_is_ignored() -> void:
	var b: SnapshotBuffer = SnapshotBuffer.new()
	assert_true(b.push(_at(10, 0)))
	assert_false(b.push(_at(9, 0)))
	assert_false(b.push(_at(10, 0)))
	assert_eq(b.size(), 1)
	assert_eq(b.latest_tick(), 10)


func test_sample_interpolates_between_two() -> void:
	var b: SnapshotBuffer = SnapshotBuffer.new()
	b.push(_at(10, 0))
	b.push(_at(20, 100))
	assert_eq(b.sample(15.0).positions[0].x, 50.0)
	assert_eq(b.sample(15.0).tick, 20)


func test_sample_clamps_outside_range() -> void:
	var b: SnapshotBuffer = SnapshotBuffer.new()
	b.push(_at(10, 0))
	b.push(_at(20, 100))
	assert_eq(b.sample(25.0).positions[0].x, 100.0)
	assert_eq(b.sample(5.0).positions[0].x, 0.0)


func test_sample_slot_present_in_one_side_only() -> void:
	var b: SnapshotBuffer = SnapshotBuffer.new()
	b.push(_at(10, 0, [1]))
	b.push(_at(20, 100, [1, 2]))
	var s: Snapshot = b.sample(15.0)
	assert_eq(s.index_of(2), 1)
	assert_eq(s.positions[1].x, 100.0)


func test_empty_and_capacity() -> void:
	var b: SnapshotBuffer = SnapshotBuffer.new()
	assert_null(b.sample(0.0))
	assert_eq(b.latest_tick(), -1)
	for i: int in 40:
		b.push(_at(i, 0))
	assert_eq(b.size(), SnapshotBuffer.CAPACITY)
	assert_eq(b.sample(0.0).tick, 8)
