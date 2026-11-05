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
	var jump_pressed: bool = (input & InputBits.JUMP) != 0 and (player.previous_input & InputBits.JUMP) == 0
	if jump_pressed:
		player.jump_buffer_ticks_left = SimConstants.JUMP_BUFFER_TICKS
	elif player.jump_buffer_ticks_left > 0:
		player.jump_buffer_ticks_left -= 1
	if player.on_ground:
		player.coyote_ticks_left = SimConstants.COYOTE_TICKS
	elif player.coyote_ticks_left > 0:
		player.coyote_ticks_left -= 1
	var can_jump: bool = player.on_ground or player.coyote_ticks_left > 0
	if player.jump_buffer_ticks_left > 0 and can_jump:
		player.velocity.y = -SimConstants.JUMP_SPEED
		player.jump_buffer_ticks_left = 0
		player.coyote_ticks_left = 0
		player.on_ground = false
	player.velocity.y += SimConstants.GRAVITY * SimConstants.DT
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
	_move_y(player, player.velocity.y * SimConstants.DT)
	player.previous_input = input


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


## Déplace le player en y. Vers le bas, une collision pose le player sur la
## tile (on_ground). Vers le haut, elle le ramène sous la tile.
func _move_y(player: PlayerState, dy: float) -> void:
	player.position.y += dy
	if not level.grid.overlaps_solid(player.rect()):
		player.on_ground = false
		return
	if dy > 0.0:
		var bottom_edge: float = player.position.y + SimConstants.PLAYER_SIZE - TileGrid.EDGE_EPSILON
		var tile_y: int = floori(bottom_edge / SimConstants.TILE_SIZE)
		player.position.y = tile_y * SimConstants.TILE_SIZE - SimConstants.PLAYER_SIZE
		player.on_ground = true
	else:
		var tile_y: int = floori(player.position.y / SimConstants.TILE_SIZE)
		player.position.y = (tile_y + 1) * SimConstants.TILE_SIZE
	player.velocity.y = 0.0
