extends GutTest


func _snapshot(tick: int, count: int) -> Snapshot:
	var s: Snapshot = Snapshot.new()
	s.tick = tick
	s.level_flags = Snapshot.LEVEL_FLAG_DOOR_OPEN
	for i: int in count:
		s.slots.append(i + 1)
		s.positions.append(Vector2(16.5 * i, 100.0 - i))
		s.flags.append(i % 16)
	return s


func test_round_trip_eight_players() -> void:
	var bytes: PackedByteArray = SnapshotCodec.encode(_snapshot(123456, 8))
	assert_eq(bytes.size(), 86)
	var d: Snapshot = SnapshotCodec.decode(bytes)
	assert_eq(d.tick, 123456)
	assert_eq(d.level_flags, 1)
	assert_eq(d.slots.size(), 8)
	assert_eq(d.positions[3], Vector2(49.5, 97.0))
	assert_eq(d.flags[5], 5)
	assert_eq(d.index_of(7), 6)
	assert_eq(d.index_of(9), -1)


func test_round_trip_empty() -> void:
	var d: Snapshot = SnapshotCodec.decode(SnapshotCodec.encode(_snapshot(5, 0)))
	assert_eq(d.tick, 5)
	assert_eq(d.slots.size(), 0)


func test_decode_truncated_returns_null() -> void:
	var bytes: PackedByteArray = SnapshotCodec.encode(_snapshot(1, 2))
	assert_null(SnapshotCodec.decode(bytes.slice(0, 20)))
	assert_null(SnapshotCodec.decode(PackedByteArray()))


func test_decode_bad_count_returns_null() -> void:
	var bytes: PackedByteArray = SnapshotCodec.encode(_snapshot(1, 1))
	bytes[5] = 9
	assert_null(SnapshotCodec.decode(bytes))


func test_from_simulation() -> void:
	var sim: Simulation = Simulation.new(Level.from_rows(["S..S", "####"]))
	sim.add_player(1)
	sim.add_player(2)
	sim.set_input(2, InputBits.LEFT)
	for i: int in 3:
		sim.step()
	var s: Snapshot = Snapshot.from_simulation(sim)
	assert_eq(s.tick, 3)
	assert_eq(s.slots, PackedInt32Array([1, 2]))
	assert_eq(s.positions[0], sim.get_player(1).position)
	assert_true(bool(s.flags[1] & Snapshot.FLAG_FACING_LEFT))
	assert_true(bool(s.flags[0] & Snapshot.FLAG_ON_GROUND))


func test_from_simulation_sets_level_and_player_flags() -> void:
	var sim: Simulation = Simulation.new(Level.from_rows(["S.K.D^S", "#######"]))
	sim.add_player(1)
	sim.add_player(2)
	sim.set_input(1, InputBits.RIGHT)
	for i: int in 15:
		sim.step()
	var s: Snapshot = Snapshot.from_simulation(sim)
	assert_true(bool(s.level_flags & Snapshot.LEVEL_FLAG_KEY_TAKEN))
	assert_false(bool(s.level_flags & Snapshot.LEVEL_FLAG_DOOR_OPEN))
	assert_true(bool(s.flags[0] & Snapshot.FLAG_KEY_CARRIER))
	for i: int in 25:
		sim.step()
	s = Snapshot.from_simulation(sim)
	assert_true(bool(s.level_flags & Snapshot.LEVEL_FLAG_DOOR_OPEN))
	assert_true(bool(s.flags[0] & Snapshot.FLAG_ENTERED))
	assert_false(bool(s.flags[0] & Snapshot.FLAG_KEY_CARRIER))
	sim.restart()
	sim.set_input(2, InputBits.LEFT)
	for i: int in 4:
		sim.step()
	s = Snapshot.from_simulation(sim)
	assert_true(bool(s.flags[1] & Snapshot.FLAG_DEAD))
	assert_eq(SnapshotCodec.decode(SnapshotCodec.encode(s)).flags[1], s.flags[1])
