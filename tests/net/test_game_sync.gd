extends GutTest


func test_tick_stays_monotonic_across_levels() -> void:
	# Un snapshot de l'ancien niveau arrivé en retard ne doit pas bloquer le
	# buffer du client : le tick ne repart jamais à zéro.
	var session: Session = add_child_autofree(Session.new())
	var sync: GameSync = add_child_autofree(GameSync.new())
	sync.session = session
	sync.start_as_host(Level.from_rows(["S..", "###"]), [1])
	for i: int in 5:
		sync.simulation.step()
	var tick_before: int = sync.simulation.tick
	sync.start_as_host(Level.from_rows(["S...", "####"]), [1])
	assert_eq(sync.simulation.tick, tick_before)
	assert_eq(sync.simulation.players.size(), 1)
	sync.stop()


func test_player_left_restarts_even_if_others_entered() -> void:
	var session: Session = add_child_autofree(Session.new())
	var sync: GameSync = add_child_autofree(GameSync.new())
	sync.session = session
	sync.start_as_host(Level.from_rows(["S.K.D.S", "#######"]), [1, 2])
	sync.simulation.set_input(1, InputBits.RIGHT)
	for i: int in 40:
		sync.simulation.step()
	assert_true(sync.simulation.get_player(1).entered)
	sync._on_roster_changed({1: "Host"})
	assert_eq(sync.simulation.players.size(), 1)
	assert_false(sync.simulation.get_player(1).entered)
	assert_false(sync.simulation.halted)
	sync.simulation.step()
	assert_false(sync.simulation.is_level_clear())
	sync.stop()


func test_player_left_during_clear_keeps_next_level() -> void:
	var session: Session = add_child_autofree(Session.new())
	var sync: GameSync = add_child_autofree(GameSync.new())
	sync.session = session
	sync.start_as_host(Level.from_rows(["SKD", "###"]), [1, 2])
	sync.simulation.set_input(1, InputBits.RIGHT)
	sync.simulation.set_input(2, InputBits.RIGHT)
	for i: int in 40:
		sync.simulation.step()
	assert_true(sync.simulation.is_level_clear())
	sync._on_roster_changed({1: "Host"})
	assert_true(sync.simulation.halted)
	assert_true(sync.simulation.get_player(1).entered)
	sync.stop()


func test_player_left_during_death_banner_restarts_once() -> void:
	var session: Session = add_child_autofree(Session.new())
	var sync: GameSync = add_child_autofree(GameSync.new())
	sync.session = session
	watch_signals(sync)
	sync.start_as_host(Level.from_rows(["S^.S", "####"]), [1, 2])
	sync.simulation.set_input(1, InputBits.RIGHT)
	for i: int in 4:
		sync._host_tick(0)
	assert_true(sync.simulation.get_player(1).dead)
	sync.simulation.set_input(1, 0)
	sync._on_roster_changed({1: "Host"})
	assert_signal_emit_count(sync, "level_restarted", 1)
	for i: int in 90:
		sync._host_tick(0)
	assert_signal_emit_count(sync, "level_restarted", 1)
	sync.stop()


func test_god_slot_carries_over_to_the_next_level_and_stops_with_the_game() -> void:
	var session: Session = add_child_autofree(Session.new())
	var sync: GameSync = add_child_autofree(GameSync.new())
	sync.session = session
	sync.start_as_host(Level.from_rows(["S..", "###"]), [1])
	sync.set_god_slot(1)
	assert_eq(sync.simulation.god_slot, 1)
	sync.start_as_host(Level.from_rows(["S...", "####"]), [1])
	assert_eq(sync.simulation.god_slot, 1)
	sync.stop()
	assert_eq(sync.god_slot, Simulation.NO_SLOT)
