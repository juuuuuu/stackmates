extends GutTest


func _sim(rows: Array[String]) -> Simulation:
	return Simulation.new(Level.from_rows(rows))


func _run(sim: Simulation, slot: int, bits: int, ticks: int) -> void:
	sim.set_input(slot, bits)
	for i: int in ticks:
		sim.step()


func test_stands_on_floor() -> void:
	var sim: Simulation = _sim(["S..", "###"])
	sim.add_player(1)
	_run(sim, 1, 0, 10)
	assert_eq(sim.get_player(1).position.y, 0.0)
	assert_true(sim.get_player(1).on_ground)
	assert_eq(sim.get_player(1).velocity.y, 0.0)


func test_falls_and_lands() -> void:
	var sim: Simulation = _sim(["S..", "...", "###"])
	sim.add_player(1)
	_run(sim, 1, 0, 60)
	assert_eq(sim.get_player(1).position.y, 16.0)
	assert_true(sim.get_player(1).on_ground)


func test_jump_rise_is_between_two_and_three_tiles() -> void:
	var sim: Simulation = _sim(["...", "...", "...", "S..", "###"])
	sim.add_player(1)
	_run(sim, 1, 0, 5)
	_run(sim, 1, InputBits.JUMP, 1)
	var top: float = 48.0
	for i: int in 40:
		sim.step()
		top = minf(top, sim.get_player(1).position.y)
	var rise: float = 48.0 - top
	assert_gt(rise, 32.0)
	assert_lt(rise, 48.0)


func test_can_climb_two_tile_ledge() -> void:
	var sim: Simulation = _sim(
		[
			"......#",
			"......#",
			"......#",
			"....###",
			"...S###",
			"#######",
		]
	)
	sim.add_player(1)
	_run(sim, 1, 0, 5)
	_run(sim, 1, InputBits.JUMP | InputBits.RIGHT, 90)
	assert_eq(sim.get_player(1).position, Vector2(80, 32))
	assert_true(sim.get_player(1).on_ground)


func test_cannot_climb_three_tile_ledge() -> void:
	var sim: Simulation = _sim(
		[
			"......#",
			"......#",
			"....###",
			"....###",
			"...S###",
			"#######",
		]
	)
	sim.add_player(1)
	_run(sim, 1, 0, 5)
	_run(sim, 1, InputBits.JUMP | InputBits.RIGHT, 120)
	assert_eq(sim.get_player(1).position, Vector2(48, 64))
	assert_true(sim.get_player(1).on_ground)


func test_coyote_time_allows_late_jump() -> void:
	var sim: Simulation = _sim(["S...", "##..", "....", "####"])
	sim.add_player(1)
	_run(sim, 1, 0, 5)
	sim.set_input(1, InputBits.RIGHT)
	while sim.get_player(1).on_ground:
		sim.step()
	_run(sim, 1, InputBits.RIGHT, 2)
	_run(sim, 1, InputBits.RIGHT | InputBits.JUMP, 1)
	assert_lt(sim.get_player(1).velocity.y, 0.0)


func test_no_jump_after_coyote_expires() -> void:
	var sim: Simulation = _sim(["S...", "##..", "....", "####"])
	sim.add_player(1)
	_run(sim, 1, 0, 5)
	sim.set_input(1, InputBits.RIGHT)
	while sim.get_player(1).on_ground:
		sim.step()
	_run(sim, 1, InputBits.RIGHT, 10)
	_run(sim, 1, InputBits.RIGHT | InputBits.JUMP, 1)
	assert_gt(sim.get_player(1).velocity.y, 0.0)


func test_jump_buffer_triggers_on_landing() -> void:
	var sim: Simulation = _sim(["S..", "...", "###"])
	sim.add_player(1)
	_run(sim, 1, 0, 7)
	_run(sim, 1, InputBits.JUMP, 1)
	_run(sim, 1, 0, 7)
	assert_lt(sim.get_player(1).position.y, 16.0)
	assert_false(sim.get_player(1).on_ground)


func test_jump_buffer_expires() -> void:
	var sim: Simulation = _sim(["S..", "...", "###"])
	sim.add_player(1)
	_run(sim, 1, InputBits.JUMP, 1)
	_run(sim, 1, 0, 30)
	assert_eq(sim.get_player(1).position.y, 16.0)
	assert_true(sim.get_player(1).on_ground)
