class_name Walkthrough
extends RefCounted
## Pilote un player du sim core par cibles, pour prouver qu'un niveau se joue.
## Helper de test : il ne vit que dans tests/.

const STEP_PX: float = 1.6
const DEFAULT_JUMP_TICKS: int = 30
const DEFAULT_MAX_TICKS: int = 900


## Charge la scène d'un level et en tire le Level du sim core.
static func load_level(path: String) -> Level:
	var scene: PackedScene = load(path)
	var root: Node = scene.instantiate()
	var level: Level = LevelLoader.from_scene_root(root)
	root.free()
	return level


static func idle_all(sim: Simulation) -> void:
	for player: PlayerState in sim.players:
		sim.set_input(player.slot, 0)


static func hold(sim: Simulation, slot: int, bits: int, ticks: int) -> void:
	sim.set_input(slot, bits)
	for i: int in ticks:
		sim.step()


## Marche vers target_x. Vrai à l'arrivée (ou si le player est entré dans la
## door en chemin), faux s'il meurt, si la sim gèle ou si max_ticks est atteint.
static func walk_to(
	sim: Simulation, slot: int, target_x: float, max_ticks: int = DEFAULT_MAX_TICKS
) -> bool:
	for i: int in max_ticks:
		var player: PlayerState = sim.get_player(slot)
		if player == null:
			return false
		if player.entered:
			sim.set_input(slot, 0)
			return true
		if player.dead or sim.halted:
			return false
		var dx: float = target_x - player.position.x
		if absf(dx) < STEP_PX:
			sim.set_input(slot, 0)
			return true
		sim.set_input(slot, InputBits.RIGHT if dx > 0.0 else InputBits.LEFT)
		sim.step()
	return false


## Un tick sans JUMP (relâche), puis JUMP plus la direction (-1, 0 ou 1)
## pendant ticks. Laisse l'input à 0.
static func jump_toward(
	sim: Simulation, slot: int, direction: int, ticks: int = DEFAULT_JUMP_TICKS
) -> void:
	var direction_bits: int = 0
	if direction > 0:
		direction_bits = InputBits.RIGHT
	elif direction < 0:
		direction_bits = InputBits.LEFT
	sim.set_input(slot, direction_bits)
	sim.step()
	hold(sim, slot, direction_bits | InputBits.JUMP, ticks)
	sim.set_input(slot, 0)
