extends GutTest


func _sim(rows: Array[String]) -> Simulation:
	return Simulation.new(Level.from_rows(rows))


func _run(sim: Simulation, slot: int, bits: int, ticks: int) -> void:
	sim.set_input(slot, bits)
	for i: int in ticks:
		sim.step()


func test_walking_into_grounded_player_pushes_it() -> void:
	var sim: Simulation = _sim(["SS....", "######"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 10)
	assert_almost_eq(sim.get_player(1).position.x, 16.0, 0.01)
	assert_almost_eq(sim.get_player(2).position.x, 32.0, 0.01)


func test_chain_push_moves_everyone() -> void:
	var sim: Simulation = _sim(["SSS...", "######"])
	sim.add_player(1)
	sim.add_player(2)
	sim.add_player(3)
	_run(sim, 1, InputBits.RIGHT, 10)
	assert_almost_eq(sim.get_player(2).position.x, 32.0, 0.01)
	assert_almost_eq(sim.get_player(3).position.x, 48.0, 0.01)


func test_wall_blocks_whole_chain() -> void:
	var sim: Simulation = _sim(["SSS#", "####"])
	sim.add_player(1)
	sim.add_player(2)
	sim.add_player(3)
	_run(sim, 1, InputBits.RIGHT, 10)
	assert_eq(sim.get_player(1).position.x, 0.0)
	assert_eq(sim.get_player(2).position.x, 16.0)
	assert_eq(sim.get_player(3).position.x, 32.0)
	assert_eq(sim.get_player(1).velocity.x, 0.0)


func test_opposite_pushes_cancel() -> void:
	var sim: Simulation = _sim([".SS.", "####"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, 0, 1)
	sim.set_input(1, InputBits.RIGHT)
	sim.set_input(2, InputBits.LEFT)
	for i: int in 10:
		sim.step()
	assert_almost_eq(sim.get_player(1).position.x, 16.0, 0.01)
	assert_almost_eq(sim.get_player(2).position.x, 32.0, 0.01)


func test_airborne_player_cannot_push_grounded_player() -> void:
	# Le player 1 tombe de (0, 0) et croise en l'air le player 2 posé en (32, 32).
	var sim: Simulation = _sim(["S.....", "......", "..S...", "######"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 12)
	assert_false(sim.get_player(1).on_ground)
	assert_almost_eq(sim.get_player(1).position.x, 19.2, 0.01)
	assert_eq(sim.get_player(2).position.x, 32.0)


func test_grounded_player_walks_through_airborne_player() -> void:
	# Le player 1 (16, 16) tombe ; le player 2 (0, 32) marche sous lui.
	var sim: Simulation = _sim(["......", ".S....", "S.....", "######"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 2, InputBits.RIGHT, 2)
	assert_false(sim.get_player(1).on_ground)
	assert_eq(sim.get_player(1).position.x, 16.0)
	assert_almost_eq(sim.get_player(2).position.x, 3.2, 0.01)


func test_overlapping_players_separate_without_error() -> void:
	var sim: Simulation = _sim(["S.....", "######"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 10)
	assert_almost_eq(sim.get_player(1).position.x, 16.0, 0.01)
	assert_almost_eq(sim.get_player(2).position.x, 32.0, 0.01)
