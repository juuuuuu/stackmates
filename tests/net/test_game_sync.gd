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
