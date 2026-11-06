extends GutTest
## Chaque niveau est prouvé jouable par un parcours scripté dans le sim core.

const LEVEL_03_SPIKES: Array[float] = [224.0, 320.0, 416.0, 512.0]
## Distance entre le player et le bord de la tile d'un spike isolé au départ
## du saut : fenêtre calculée de 17,8 à 28,6 px, marche à 1,6 px près.
const JUMP_LEAD_PX: float = 24.0


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


func _cross_spikes(sim: Simulation, slot: int, direction: int) -> void:
	var spikes: Array[float] = LEVEL_03_SPIKES.duplicate()
	if direction < 0:
		spikes.reverse()
	for spike_x: float in spikes:
		var start_x: float = spike_x - JUMP_LEAD_PX
		if direction < 0:
			start_x = spike_x + JUMP_LEAD_PX
		assert_true(Walkthrough.walk_to(sim, slot, start_x))
		Walkthrough.jump_toward(sim, slot, direction)
		assert_false(sim.get_player(slot).dead)


func test_level_03_spikes_are_jumpable() -> void:
	# Le player 2 spawne devant le 1 : il part en premier, sinon le 1 le pousse
	# dans le premier spike. Il prend donc la key.
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_03.tscn"))
	sim.add_player(1)
	sim.add_player(2)
	Walkthrough.idle_all(sim)
	for slot: int in [2, 1]:
		_cross_spikes(sim, slot, 1)
		assert_true(Walkthrough.walk_to(sim, slot, 560.0))
		Walkthrough.jump_toward(sim, slot, 1)
		assert_true(Walkthrough.walk_to(sim, slot, 592.0))
		if slot == 2:
			assert_eq(sim.key_carrier, 2)
		assert_true(Walkthrough.walk_to(sim, slot, 560.0))
		_cross_spikes(sim, slot, -1)
		assert_true(Walkthrough.walk_to(sim, slot, 48.0))
		Walkthrough.idle_all(sim)
	assert_true(sim.is_level_clear())


func test_level_03_walking_into_a_spike_kills() -> void:
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_03.tscn"))
	sim.add_player(1)
	Walkthrough.idle_all(sim)
	assert_false(Walkthrough.walk_to(sim, 1, 300.0))
	assert_true(sim.get_player(1).dead)


func test_level_04_corridor_push_chain() -> void:
	# Le player 2 spawne devant : poussé jusqu'au fond, il prend la key. Le
	# player 1 le suit dans le couloir, puis le 2 ressort en poussant le 1.
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_04.tscn"))
	sim.add_player(1)
	sim.add_player(2)
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 2, 592.0))
	assert_eq(sim.key_carrier, 2)
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 1, 500.0))
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 2, 200.0))
	assert_lt(sim.get_player(1).position.x, 200.0)
	for slot: int in [1, 2]:
		assert_true(Walkthrough.walk_to(sim, slot, 150.0))
		Walkthrough.jump_toward(sim, slot, -1)
		assert_true(Walkthrough.walk_to(sim, slot, 80.0))
		Walkthrough.idle_all(sim)
	assert_true(sim.door_open)
	assert_true(sim.is_level_clear())


func test_level_04_no_jumping_in_the_corridor() -> void:
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_04.tscn"))
	sim.add_player(1)
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 1, 400.0))
	Walkthrough.jump_toward(sim, 1, 0, 10)
	assert_eq(sim.get_player(1).position.y, 320.0)


func test_level_05_combination() -> void:
	# Le player 2 spawne devant : il franchit les spikes en premier, puis sert
	# de marche contre le bloc ; le 1 prend la key et tout le monde revient.
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_05.tscn"))
	sim.add_player(1)
	sim.add_player(2)
	Walkthrough.idle_all(sim)
	for slot: int in [2, 1]:
		for spike_x: float in [288.0, 368.0]:
			assert_true(Walkthrough.walk_to(sim, slot, spike_x - JUMP_LEAD_PX))
			Walkthrough.jump_toward(sim, slot, 1)
		Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 2, 432.0))
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 1, 400.0))
	Walkthrough.jump_toward(sim, 1, 1)
	assert_eq(sim.get_player(1).position, Vector2(432, 304))
	Walkthrough.jump_toward(sim, 1, 1)
	assert_true(Walkthrough.walk_to(sim, 1, 480.0))
	assert_eq(sim.key_carrier, 1)
	for slot: int in [1, 2]:
		assert_true(Walkthrough.walk_to(sim, slot, 420.0))
		for spike_x: float in [368.0, 288.0]:
			assert_true(Walkthrough.walk_to(sim, slot, spike_x + JUMP_LEAD_PX))
			Walkthrough.jump_toward(sim, slot, -1)
		assert_true(Walkthrough.walk_to(sim, slot, 130.0))
		Walkthrough.jump_toward(sim, slot, -1)
		assert_true(Walkthrough.walk_to(sim, slot, 64.0))
		Walkthrough.idle_all(sim)
	assert_true(sim.is_level_clear())


func test_level_02_block_reaches_the_wall() -> void:
	# Pas de poche à droite du bloc : un porteur qui continue à droite reste
	# sur le bloc jusqu'au mur et peut revenir.
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_02.tscn"))
	sim.add_player(1)
	sim.add_player(2)
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 2, 304.0))
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 1, 272.0))
	Walkthrough.jump_toward(sim, 1, 1)
	Walkthrough.jump_toward(sim, 1, 1)
	assert_true(Walkthrough.walk_to(sim, 1, 600.0))
	Walkthrough.hold(sim, 1, InputBits.RIGHT, 60)
	assert_eq(sim.get_player(1).position, Vector2(608, 272))


func test_level_05_block_reaches_the_wall() -> void:
	var sim: Simulation = Simulation.new(Walkthrough.load_level("res://levels/level_05.tscn"))
	sim.add_player(1)
	sim.add_player(2)
	Walkthrough.idle_all(sim)
	for slot: int in [2, 1]:
		for spike_x: float in [288.0, 368.0]:
			assert_true(Walkthrough.walk_to(sim, slot, spike_x - JUMP_LEAD_PX))
			Walkthrough.jump_toward(sim, slot, 1)
		Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 2, 432.0))
	Walkthrough.idle_all(sim)
	assert_true(Walkthrough.walk_to(sim, 1, 400.0))
	Walkthrough.jump_toward(sim, 1, 1)
	Walkthrough.jump_toward(sim, 1, 1)
	assert_true(Walkthrough.walk_to(sim, 1, 600.0))
	Walkthrough.hold(sim, 1, InputBits.RIGHT, 60)
	assert_eq(sim.get_player(1).position, Vector2(608, 272))
