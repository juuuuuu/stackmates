extends GutTest


func _sim(rows: Array[String]) -> Simulation:
	return Simulation.new(Level.from_rows(rows))


func test_add_player_places_at_spawn() -> void:
	var sim: Simulation = _sim(["S..S", "####"])
	var p: PlayerState = sim.add_player(2)
	assert_eq(p.position, Vector2(48, 0))
	assert_eq(sim.add_player(1).position, Vector2(0, 0))
	assert_eq(sim.add_player(5).position, Vector2(0, 0))


func test_right_for_one_second_moves_run_speed() -> void:
	var sim: Simulation = _sim(["S.........", "##########"])
	sim.add_player(1)
	sim.set_input(1, InputBits.RIGHT)
	for i: int in 60:
		sim.step()
	assert_almost_eq(sim.get_player(1).position.x, 96.0, 0.01)
	assert_eq(sim.tick, 60)


func test_left_into_wall_stops_at_tile_edge() -> void:
	var sim: Simulation = _sim(["#.S.", "####"])
	sim.add_player(1)
	sim.set_input(1, InputBits.LEFT)
	for i: int in 30:
		sim.step()
	assert_eq(sim.get_player(1).position.x, 16.0)
	assert_eq(sim.get_player(1).velocity.x, 0.0)


func test_facing_follows_last_direction() -> void:
	var sim: Simulation = _sim(["..S..", "#####"])
	sim.add_player(1)
	sim.set_input(1, InputBits.LEFT)
	sim.step()
	assert_true(sim.get_player(1).facing_left)
	sim.set_input(1, 0)
	sim.step()
	assert_true(sim.get_player(1).facing_left)
	sim.set_input(1, InputBits.RIGHT)
	sim.step()
	assert_false(sim.get_player(1).facing_left)


func test_player_leaves_grid_without_error() -> void:
	var sim: Simulation = _sim(["S..", "###"])
	sim.add_player(1)
	sim.set_input(1, InputBits.RIGHT)
	for i: int in 120:
		sim.step()
	assert_gt(sim.get_player(1).position.x, 48.0)


func test_remove_player() -> void:
	var sim: Simulation = _sim(["S..", "###"])
	sim.add_player(1)
	sim.remove_player(1)
	assert_null(sim.get_player(1))
	assert_eq(sim.players.size(), 0)
