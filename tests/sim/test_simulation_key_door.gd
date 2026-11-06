extends GutTest


func _sim(rows: Array[String]) -> Simulation:
	return Simulation.new(Level.from_rows(rows))


func _run(sim: Simulation, slot: int, bits: int, ticks: int) -> void:
	sim.set_input(slot, bits)
	for i: int in ticks:
		sim.step()


func test_walking_over_key_takes_it() -> void:
	var sim: Simulation = _sim(["S.K..", "#####"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT, 15)
	assert_eq(sim.key_carrier, 1)
	assert_true(sim.key_taken)
	assert_eq(sim.take_events()[0].kind, SimEvent.Kind.KEY_TAKEN)


func test_second_player_cannot_take_the_key() -> void:
	var sim: Simulation = _sim(["S.K.S", "#####"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 15)
	sim.set_input(1, 0)
	_run(sim, 2, InputBits.LEFT, 15)
	assert_eq(sim.key_carrier, 1)


func test_carrier_opens_door_and_key_disappears() -> void:
	var sim: Simulation = _sim(["S.K.D", "#####"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT, 40)
	assert_true(sim.door_open)
	assert_eq(sim.key_carrier, 0)
	var kinds: Array[int] = []
	for e: SimEvent in sim.take_events():
		kinds.append(e.kind)
	assert_eq(kinds.slice(0, 2), [SimEvent.Kind.KEY_TAKEN, SimEvent.Kind.DOOR_OPENED] as Array[int])


func test_non_carrier_does_not_open_door() -> void:
	var sim: Simulation = _sim(["S..D.K", "######"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT, 25)
	assert_false(sim.door_open)
	assert_false(sim.get_player(1).entered)


func test_entering_requires_open_door_and_clears_when_all_in() -> void:
	var sim: Simulation = _sim(["S.K.D.S", "#######"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 40)
	assert_true(sim.get_player(1).entered)
	assert_false(sim.is_level_clear())
	assert_false(sim.halted)
	sim.set_input(1, 0)
	_run(sim, 2, InputBits.LEFT, 25)
	assert_true(sim.get_player(2).entered)
	assert_true(sim.is_level_clear())
	assert_true(sim.halted)
	var last: SimEvent = sim.take_events().back()
	assert_eq(last.kind, SimEvent.Kind.LEVEL_CLEAR)


func test_entered_player_ignores_input() -> void:
	var sim: Simulation = _sim(["S.K.D.......S", "#############"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 40)
	var x_in_door: float = sim.get_player(1).position.x
	_run(sim, 1, InputBits.RIGHT, 10)
	assert_eq(sim.get_player(1).position.x, x_in_door)


func test_two_players_entering_same_tick_clear_once() -> void:
	# Le player 2 attend sur la door fermée ; le porteur arrive, l'ouvre, et
	# les deux entrent au même tick.
	var sim: Simulation = _sim(["S.K.DS", "######"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 2, InputBits.LEFT, 10)
	sim.set_input(2, 0)
	_run(sim, 1, InputBits.RIGHT, 40)
	var clears: int = 0
	for e: SimEvent in sim.take_events():
		if e.kind == SimEvent.Kind.LEVEL_CLEAR:
			clears += 1
	assert_eq(clears, 1)
	assert_true(sim.is_level_clear())


func test_restart_resets_key_and_door() -> void:
	var sim: Simulation = _sim(["S.K.D.", "######"])
	sim.add_player(1)
	_run(sim, 1, InputBits.RIGHT, 40)
	assert_true(sim.door_open)
	sim.restart()
	assert_eq(sim.key_carrier, 0)
	assert_false(sim.key_taken)
	assert_false(sim.door_open)


func test_restart_resets_entered() -> void:
	var sim: Simulation = _sim(["S.K.D.S", "#######"])
	sim.add_player(1)
	sim.add_player(2)
	_run(sim, 1, InputBits.RIGHT, 40)
	assert_true(sim.get_player(1).entered)
	sim.restart()
	assert_false(sim.get_player(1).entered)
	assert_eq(sim.get_player(1).position, Vector2(0, 0))
