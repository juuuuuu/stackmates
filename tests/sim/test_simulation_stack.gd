extends GutTest


func _sim(rows: Array[String]) -> Simulation:
	return Simulation.new(Level.from_rows(rows))


func _run(sim: Simulation, slot: int, bits: int, ticks: int) -> void:
	sim.set_input(slot, bits)
	for i: int in ticks:
		sim.step()


func test_player_lands_on_head() -> void:
	var sim: Simulation = _sim(["S..", "...", "S..", "###"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, 0, 60)
	assert_eq(sim.get_player(1).position.y, 16.0)
	assert_true(sim.get_player(1).on_ground)
	assert_eq(sim.get_player(2).position.y, 32.0)


func test_carried_player_follows_carrier() -> void:
	var sim: Simulation = _sim(["S....", "S....", "#####"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, 0, 5)
	_run(sim, 2, InputBits.RIGHT, 10)
	assert_almost_eq(sim.get_player(2).position.x, 16.0, 0.01)
	assert_almost_eq(sim.get_player(1).position.x, 16.0, 0.01)
	assert_true(sim.get_player(1).on_ground)


func test_carried_player_adds_own_movement() -> void:
	var sim: Simulation = _sim(["S....", "S....", "#####"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, 0, 5)
	sim.set_input(1, InputBits.RIGHT)
	sim.set_input(2, InputBits.RIGHT)
	for i: int in 5:
		sim.step()
	assert_almost_eq(sim.get_player(2).position.x, 8.0, 0.01)
	assert_almost_eq(sim.get_player(1).position.x, 16.0, 0.01)


func test_carried_player_can_jump_from_head() -> void:
	var sim: Simulation = _sim(["S..", "S..", "###"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, 0, 5)
	_run(sim, 1, InputBits.JUMP, 1)
	assert_lt(sim.get_player(1).velocity.y, 0.0)


func test_stack_of_three_moves_together() -> void:
	var sim: Simulation = _sim(["S....", "S....", "S....", "#####"])
	sim.add_player(1)
	sim.add_player(2)
	sim.add_player(3)
	_run(sim, 1, 0, 5)
	_run(sim, 3, InputBits.RIGHT, 5)
	assert_almost_eq(sim.get_player(1).position.x, 8.0, 0.01)
	assert_almost_eq(sim.get_player(2).position.x, 8.0, 0.01)
	assert_almost_eq(sim.get_player(3).position.x, 8.0, 0.01)


func test_three_tile_ledge_needs_a_stack() -> void:
	var sim: Simulation = _sim(
		[
			"......#",
			"......#",
			"....###",
			"...S###",
			"...S###",
			"#######",
		]
	)
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, 0, 5)
	assert_eq(sim.get_player(1).position.y, 48.0)
	_run(sim, 1, InputBits.JUMP | InputBits.RIGHT, 90)
	assert_eq(sim.get_player(1).position, Vector2(80, 16))
	assert_true(sim.get_player(1).on_ground)
