extends GutTest


func _sim(rows: Array[String]) -> Simulation:
	return Simulation.new(Level.from_rows(rows))


func _run(sim: Simulation, slot: int, bits: int, ticks: int) -> void:
	sim.set_input(slot, bits)
	for i: int in ticks:
		sim.step()


func test_fall_speed_is_capped() -> void:
	var rows: Array[String] = ["S.."]
	for i: int in 39:
		rows.append("...")
	var sim: Simulation = _sim(rows)
	sim.add_player(1)
	_run(sim, 1, 0, 50)
	assert_false(sim.get_player(1).dead)
	assert_eq(sim.get_player(1).velocity.y, SimConstants.MAX_FALL_SPEED)


func test_spike_kills_and_halts() -> void:
	var sim: Simulation = _sim(["S^.S", "####"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 4)
	assert_true(sim.get_player(1).dead)
	assert_true(sim.halted)
	var events: Array[SimEvent] = sim.take_events()
	assert_eq(events.size(), 1)
	assert_eq(events[0].kind, SimEvent.Kind.DEATH)
	assert_eq(events[0].slot, 1)
	assert_eq(sim.take_events().size(), 0)


func test_falling_out_kills() -> void:
	var sim: Simulation = _sim(["S..", "..."])
	sim.add_player(1)
	_run(sim, 1, 0, 60)
	assert_true(sim.get_player(1).dead)
	assert_eq(sim.take_events()[0].kind, SimEvent.Kind.DEATH)


func test_halted_sim_ignores_inputs_but_counts_ticks() -> void:
	var sim: Simulation = _sim(["S^.S", "####"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 4)
	var tick_after_death: int = sim.tick
	var x_before: float = sim.get_player(2).position.x
	_run(sim, 2, InputBits.LEFT, 10)
	assert_eq(sim.get_player(2).position.x, x_before)
	assert_eq(sim.tick, tick_after_death + 10)


func test_restart_puts_everyone_back_and_resumes() -> void:
	var sim: Simulation = _sim(["S^.S", "####"])
	sim.add_player(1)
	sim.add_player(2)
	sim.set_input(2, InputBits.LEFT)
	_run(sim, 1, InputBits.RIGHT, 2)
	var tick_before: int = sim.tick
	sim.restart()
	assert_false(sim.halted)
	assert_false(sim.get_player(1).dead)
	assert_eq(sim.get_player(1).position, Vector2(0, 0))
	assert_eq(sim.get_player(2).position, Vector2(48, 0))
	assert_eq(sim.get_player(2).velocity, Vector2.ZERO)
	assert_eq(sim.tick, tick_before)
	# Les inputs tenus restent valables : le player 2 reprend sa marche à gauche.
	sim.step()
	assert_almost_eq(sim.get_player(2).position.x, 46.4, 0.01)
	assert_eq(sim.tick, tick_before + 1)


func test_dead_player_is_not_moved() -> void:
	var sim: Simulation = _sim(["S^..", "####"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT, 4)
	var x_dead: float = sim.get_player(1).position.x
	sim.halted = false
	_run(sim, 1, InputBits.RIGHT, 5)
	assert_eq(sim.get_player(1).position.x, x_dead)


func test_walker_dies_on_spike() -> void:
	var sim: Simulation = _sim(["S^..", "####"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT, 4)
	assert_true(sim.get_player(1).dead)


func test_neighbour_survives() -> void:
	var sim: Simulation = _sim(["S^..", "####"])
	sim.add_player(1)
	_run(sim, 1, 0, 10)
	assert_false(sim.get_player(1).dead)
	_run(sim, 1, InputBits.RIGHT, 1)
	assert_false(sim.get_player(1).dead)


func test_jumper_clears_a_single_spike() -> void:
	var sim: Simulation = _sim(["S....^....", "##########"])
	sim.add_player(1)
	# Départ du saut 27 px avant la tile du spike, dans la fenêtre mesurée par
	# tests/sim/test_spike_window.gd.
	_run(sim, 1, 0, 5)
	_run(sim, 1, InputBits.RIGHT, 33)
	_run(sim, 1, InputBits.RIGHT | InputBits.JUMP, 40)
	assert_false(sim.get_player(1).dead)
	assert_gt(sim.get_player(1).position.x, 96.0)


func test_overlaps_spike_zone_only() -> void:
	var level: Level = Level.from_rows(["^"])
	assert_true(level.grid.overlaps_spike(Rect2(0, 0, 16, 16)))
	assert_false(level.grid.overlaps_spike(Rect2(0, -6, 16, 16)))
	assert_true(level.grid.overlaps_spike(Rect2(0, -5, 16, 16)))
	assert_false(level.grid.overlaps_spike(Rect2(-11, 0, 16, 16)))
	assert_true(level.grid.overlaps_spike(Rect2(-10, 0, 16, 16)))


func test_held_jump_does_not_fire_after_restart() -> void:
	# Le saut tenu part du spawn et retombe sur le spike trois tiles plus loin.
	var sim: Simulation = _sim(["S..^.", "#####"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT | InputBits.JUMP, 40)
	assert_true(sim.get_player(1).dead)
	sim.restart()
	_run(sim, 1, InputBits.JUMP, 2)
	assert_true(sim.get_player(1).on_ground)


func test_held_input_survives_restart_without_new_packet() -> void:
	# Un client dont aucun paquet n'arrive au tick qui suit le restart garde son
	# input : un JUMP toujours tenu ne compte pas comme une pression neuve.
	var sim: Simulation = _sim(["S...^", "#####"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT | InputBits.JUMP, 40)
	assert_true(sim.get_player(1).dead)
	sim.restart()
	sim.step()
	_run(sim, 1, InputBits.RIGHT | InputBits.JUMP, 1)
	assert_true(sim.get_player(1).on_ground)
	assert_almost_eq(sim.get_player(1).position.x, 3.2, 0.01)
