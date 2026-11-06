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
