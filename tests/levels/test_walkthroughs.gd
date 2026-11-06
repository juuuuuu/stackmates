extends GutTest
## Chaque niveau est prouvé jouable par un parcours scripté dans le sim core.


func test_level_01_two_players() -> void:
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_01.tscn"))
	sim.add_player(1)
	sim.add_player(2)
	Walkthrough.idle_all(sim)
	for slot: int in [1, 2]:
		assert_true(Walkthrough.walk_to(sim, slot, 440.0))
		Walkthrough.jump_toward(sim, slot, 1)
		assert_true(Walkthrough.walk_to(sim, slot, 520.0))
		Walkthrough.jump_toward(sim, slot, 1)
		assert_true(Walkthrough.walk_to(sim, slot, 576.0))
		Walkthrough.idle_all(sim)
	assert_true(sim.door_open)
	assert_true(sim.is_level_clear())


func test_level_02_needs_a_stack() -> void:
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_02.tscn"))
	sim.add_player(1)
	sim.add_player(2)
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 2, 304.0))
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 1, 272.0))
	Walkthrough.jump_toward(sim, 1, 1)
	assert_eq(sim.get_player(1).position, Vector2(304, 304))
	Walkthrough.jump_toward(sim, 1, 1)
	assert_true(Walkthrough.walk_to(sim, 1, 352.0))
	assert_eq(sim.key_carrier, 1)
	assert_true(Walkthrough.walk_to(sim, 1, 48.0))
	assert_true(sim.door_open)
	assert_true(Walkthrough.walk_to(sim, 2, 48.0))
	assert_true(sim.is_level_clear())


func test_level_02_cannot_be_cleared_alone_from_the_floor() -> void:
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_02.tscn"))
	sim.add_player(1)
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 1, 300.0))
	Walkthrough.jump_toward(sim, 1, 1, 60)
	assert_eq(sim.key_carrier, 0)
	assert_lt(sim.get_player(1).position.x, 320.0)
