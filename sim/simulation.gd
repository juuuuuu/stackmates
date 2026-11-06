class_name Simulation
extends RefCounted
## Le sim core : fait avancer tous les players d'un tick sur un level.
## Aucune dépendance aux nodes. Le host est le seul à l'exécuter.

var level: Level
var tick: int = 0
var players: Array[PlayerState] = []
## Gelée après une mort ou un level clear, jusqu'au restart.
var halted: bool = false
## Slot du key carrier, 0 si personne ne porte la key.
var key_carrier: int = 0
## La key a quitté sa tile (portée, ou consommée par la door).
var key_taken: bool = false
var door_open: bool = false

var _inputs: Dictionary[int, int] = {}
var _events: Array[SimEvent] = []


func _init(initial_level: Level) -> void:
	level = initial_level


func add_player(slot: int) -> PlayerState:
	var player: PlayerState = PlayerState.new()
	player.slot = slot
	player.position = _spawn_position(slot)
	players.append(player)
	_sort_players()
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


## Rend les événements produits depuis le dernier appel, puis les oublie.
func take_events() -> Array[SimEvent]:
	var events: Array[SimEvent] = _events
	_events = []
	return events


## Remet tout le monde aux spawns et reprend. Le tick continue.
func restart() -> void:
	for player: PlayerState in players:
		player.position = _spawn_position(player.slot)
		player.velocity = Vector2.ZERO
		player.on_ground = false
		player.dead = false
		player.entered = false
		player.last_dx = 0.0
		player.coyote_ticks_left = 0
		player.jump_buffer_ticks_left = 0
		player.previous_input = 0
	_inputs.clear()
	_events = []
	halted = false
	key_carrier = 0
	key_taken = false
	door_open = false
	_sort_players()


## Vrai quand tous les players sont entrés dans la door.
func is_level_clear() -> bool:
	if players.is_empty():
		return false
	for player: PlayerState in players:
		if not player.entered:
			return false
	return true


func step() -> void:
	tick += 1
	if halted:
		return
	_sort_players()
	var active: Array[PlayerState] = []
	for player: PlayerState in players:
		player.last_dx = 0.0
		if player.is_active():
			active.append(player)
	for player: PlayerState in active:
		_apply_vertical_intent(player, _input_of(player.slot))
	for player: PlayerState in active:
		_apply_horizontal_intent(player, _input_of(player.slot))
		_move_x(player, player.velocity.x * SimConstants.DT, [])
	for player: PlayerState in active:
		_move_y(player, player.velocity.y * SimConstants.DT)
	if _apply_deaths(active):
		halted = true
		return
	_apply_key_and_door(active)
	if is_level_clear():
		_events.append(SimEvent.make(SimEvent.Kind.LEVEL_CLEAR, 0))
		halted = true
		return
	for player: PlayerState in active:
		player.previous_input = _input_of(player.slot)


func _input_of(slot: int) -> int:
	if _inputs.has(slot):
		return _inputs[slot]
	return 0


## Les plus bas d'abord (position.y décroissante), puis par slot.
func _sort_players() -> void:
	players.sort_custom(
		func(a: PlayerState, b: PlayerState) -> bool:
			if a.position.y != b.position.y:
				return a.position.y > b.position.y
			return a.slot < b.slot
	)


func _spawn_position(slot: int) -> Vector2:
	var spawns: Array[Vector2i] = level.spawns
	if spawns.is_empty():
		return Vector2.ZERO
	var index: int = slot - 1
	if index < 0 or index >= spawns.size():
		index = 0
	return Vector2(spawns[index]) * SimConstants.TILE_SIZE


## Jump buffer, coyote time, saut et gravité, avec la chute bornée.
func _apply_vertical_intent(player: PlayerState, input: int) -> void:
	var jump_held: bool = (input & InputBits.JUMP) != 0
	var jump_was_held: bool = (player.previous_input & InputBits.JUMP) != 0
	if jump_held and not jump_was_held:
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
	player.velocity.y = minf(player.velocity.y, SimConstants.MAX_FALL_SPEED)


func _apply_horizontal_intent(player: PlayerState, input: int) -> void:
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


## Déplace le player en x contre les tiles et les autres players au sol, qu'il
## pousse en chaîne (push chain). Un player déjà dans la chaîne (pushed)
## n'est pas repoussé. Rend le déplacement réel.
func _move_x(player: PlayerState, dx: float, pushed: Array[PlayerState]) -> float:
	if dx == 0.0:
		return 0.0
	var start_x: float = player.position.x
	player.position.x += dx
	_resolve_tiles_x(player, dx)
	if player.on_ground:
		for other: PlayerState in players:
			if other == player or not other.is_active() or not other.on_ground:
				continue
			if pushed.has(other) or not _overlaps(player.rect(), other.rect()):
				continue
			var overlap: float = player.position.x + SimConstants.PLAYER_SIZE - other.position.x
			if dx < 0.0:
				overlap = player.position.x - (other.position.x + SimConstants.PLAYER_SIZE)
			var chain: Array[PlayerState] = pushed.duplicate()
			chain.append(player)
			var moved: float = _move_x(other, overlap, chain)
			if absf(moved) < absf(overlap) - TileGrid.EDGE_EPSILON:
				if dx > 0.0:
					player.position.x = other.position.x - SimConstants.PLAYER_SIZE
				else:
					player.position.x = other.position.x + SimConstants.PLAYER_SIZE
				player.velocity.x = 0.0
	var actual: float = player.position.x - start_x
	player.last_dx += actual
	return actual


## Ramène le player au bord de la tile solide qu'il recouvre, s'il y en a une.
func _resolve_tiles_x(player: PlayerState, dx: float) -> void:
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
		var bottom_edge: float = (
			player.position.y + SimConstants.PLAYER_SIZE - TileGrid.EDGE_EPSILON
		)
		var tile_y: int = floori(bottom_edge / SimConstants.TILE_SIZE)
		player.position.y = tile_y * SimConstants.TILE_SIZE - SimConstants.PLAYER_SIZE
		player.on_ground = true
	else:
		var tile_y: int = floori(player.position.y / SimConstants.TILE_SIZE)
		player.position.y = (tile_y + 1) * SimConstants.TILE_SIZE
	player.velocity.y = 0.0


## Tue les players sur un spike ou sortis par le bas. Vrai si au moins un mort.
func _apply_deaths(active: Array[PlayerState]) -> bool:
	var any_death: bool = false
	var bottom: float = level.grid.height * SimConstants.TILE_SIZE
	for player: PlayerState in active:
		var on_spike: bool = level.grid.overlaps_tile(player.rect(), TileGrid.Tile.SPIKE)
		if on_spike or player.position.y >= bottom:
			player.dead = true
			_events.append(SimEvent.make(SimEvent.Kind.DEATH, player.slot))
			any_death = true
	return any_death


## Ramassage de la key, ouverture de la door par le porteur, entrée des players.
func _apply_key_and_door(active: Array[PlayerState]) -> void:
	if level.has_key() and not key_taken:
		for player: PlayerState in active:
			if _overlaps(player.rect(), level.key_rect()):
				key_carrier = player.slot
				key_taken = true
				_events.append(SimEvent.make(SimEvent.Kind.KEY_TAKEN, player.slot))
				break
	if not door_open and key_carrier != 0:
		var carrier: PlayerState = get_player(key_carrier)
		if carrier != null and carrier.is_active() and _overlaps(carrier.rect(), level.door_rect()):
			door_open = true
			key_carrier = 0
			_events.append(SimEvent.make(SimEvent.Kind.DOOR_OPENED, carrier.slot))
	if door_open:
		for player: PlayerState in active:
			if _overlaps(player.rect(), level.door_rect()):
				player.entered = true


## Recouvrement de deux rects, bords droit et bas exclus, comme pour les tiles.
static func _overlaps(a: Rect2, b: Rect2) -> bool:
	var epsilon: float = TileGrid.EDGE_EPSILON
	return (
		a.position.x < b.end.x - epsilon
		and b.position.x < a.end.x - epsilon
		and a.position.y < b.end.y - epsilon
		and b.position.y < a.end.y - epsilon
	)
