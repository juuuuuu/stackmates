class_name Simulation
extends RefCounted
## Le sim core : fait avancer tous les players d'un tick sur un level.
## Aucune dépendance aux nodes. Le host est le seul à l'exécuter.

var level: Level
var tick: int = 0
var players: Array[PlayerState] = []
var _inputs: Dictionary[int, int] = {}


func _init(initial_level: Level) -> void:
	level = initial_level


func add_player(slot: int) -> PlayerState:
	var player: PlayerState = PlayerState.new()
	player.slot = slot
	player.position = _spawn_position(slot)
	players.append(player)
	players.sort_custom(func(a: PlayerState, b: PlayerState) -> bool: return a.slot < b.slot)
	return player


func remove_player(slot: int) -> void:
	var player: PlayerState = get_player(slot)
	if player != null:
		players.erase(player)
	_inputs.erase(slot)


func get_player(slot: int) -> PlayerState:
	for player: PlayerState in players:
		if player.slot == slot:
			return player
	return null


func set_input(slot: int, bits: int) -> void:
	_inputs[slot] = bits


func step() -> void:
	tick += 1
	for player: PlayerState in players:
		_step_player(player, _input_of(player.slot))


func _input_of(slot: int) -> int:
	if _inputs.has(slot):
		return _inputs[slot]
	return 0


func _spawn_position(slot: int) -> Vector2:
	var spawns: Array[Vector2i] = level.spawns
	if spawns.is_empty():
		return Vector2.ZERO
	var index: int = slot - 1
	if index < 0 or index >= spawns.size():
		index = 0
	return Vector2(spawns[index]) * SimConstants.TILE_SIZE


func _step_player(player: PlayerState, input: int) -> void:
	var direction: int = 0
	if (input & InputBits.LEFT) != 0:
		direction -= 1
	if (input & InputBits.RIGHT) != 0:
		direction += 1
	player.velocity.x = direction * SimConstants.RUN_SPEED
	if direction < 0:
		player.facing_left = true
	elif direction > 0:
		player.facing_left = false
	_move_x(player, player.velocity.x * SimConstants.DT)


## Déplace le player en x et le ramène au bord de la tile en cas de collision.
func _move_x(player: PlayerState, dx: float) -> void:
	if dx == 0.0:
		return
	player.position.x += dx
	if not level.grid.overlaps_solid(player.rect()):
		return
	if dx > 0.0:
		var right_edge: float = player.position.x + SimConstants.PLAYER_SIZE - TileGrid.EDGE_EPSILON
		var tile_x: int = floori(right_edge / SimConstants.TILE_SIZE)
		player.position.x = tile_x * SimConstants.TILE_SIZE - SimConstants.PLAYER_SIZE
	else:
		var tile_x: int = floori(player.position.x / SimConstants.TILE_SIZE)
		player.position.x = (tile_x + 1) * SimConstants.TILE_SIZE
	player.velocity.x = 0.0
