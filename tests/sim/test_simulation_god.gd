extends GutTest
## Mode test du host : son player (god_slot) saute à nouveau en l'air et ne
## meurt pas (retour au spawn sans redémarrage ni événement). Les autres
## players gardent les règles normales.

const JUMP_ROWS: Array[String] = ["....", "....", "....", "S...", "####"]


func _sim(rows: Array[String]) -> Simulation:
	return Simulation.new(Level.from_rows(rows))


func _run(sim: Simulation, slot: int, bits: int, ticks: int) -> void:
	sim.set_input(slot, bits)
	for i: int in ticks:
		sim.step()


## Deux appuis sur JUMP séparés d'un tick, le second en plein vol.
func _double_jump(sim: Simulation) -> Array[float]:
	_run(sim, 1, 0, 3)
	_run(sim, 1, InputBits.JUMP, 10)
	var after_first: float = sim.get_player(1).position.y
	_run(sim, 1, 0, 1)
	_run(sim, 1, InputBits.JUMP, 15)
	return [after_first, sim.get_player(1).position.y]


func test_god_player_jumps_again_in_the_air() -> void:
	var sim: Simulation = _sim(JUMP_ROWS)
	sim.add_player(1)
	sim.god_slot = 1
	var heights: Array[float] = _double_jump(sim)
	assert_lt(heights[1], heights[0], "le second saut relance vers le haut")


func test_normal_player_cannot_jump_in_the_air() -> void:
	var sim: Simulation = _sim(JUMP_ROWS)
	sim.add_player(1)
	var heights: Array[float] = _double_jump(sim)
	assert_gt(heights[1], heights[0], "sans mode test, le player redescend")


func test_god_player_respawns_instead_of_dying_on_a_spike() -> void:
	var sim: Simulation = _sim(["S^..", "####"])
	sim.add_player(1)
	sim.god_slot = 1
	_run(sim, 1, InputBits.RIGHT, 4)
	var player: PlayerState = sim.get_player(1)
	assert_false(player.dead)
	assert_false(sim.halted)
	assert_eq(player.position, Vector2(0, 0))
	assert_eq(sim.take_events().size(), 0)


func test_god_player_respawns_after_falling_out() -> void:
	var sim: Simulation = _sim(["S..", "#.."])
	sim.add_player(1)
	sim.god_slot = 1
	_run(sim, 1, InputBits.RIGHT, 90)
	assert_false(sim.get_player(1).dead)
	assert_false(sim.halted)


func test_other_players_still_die_when_host_is_god() -> void:
	var sim: Simulation = _sim(["S^.S", "####"])
	sim.add_player(1)
	sim.add_player(2)
	sim.god_slot = 1
	# Le player 2 part de x = 48 : 16 ticks de marche pour atteindre la zone létale.
	_run(sim, 2, InputBits.LEFT, 16)
	assert_true(sim.get_player(2).dead)
	assert_true(sim.halted)
