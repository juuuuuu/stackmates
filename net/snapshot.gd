class_name Snapshot
extends RefCounted
## L'état d'un level à un tick, tel que le host l'envoie aux clients.
## Les trois tableaux sont alignés : l'index i décrit le player slots[i].

const FLAG_FACING_LEFT: int = 1
const FLAG_ON_GROUND: int = 2
const FLAG_DEAD: int = 4
const FLAG_KEY_CARRIER: int = 8
const FLAG_ENTERED: int = 16
const LEVEL_FLAG_DOOR_OPEN: int = 1
const LEVEL_FLAG_KEY_TAKEN: int = 2

var tick: int = 0
var level_flags: int = 0
var slots: PackedInt32Array = PackedInt32Array()
var positions: PackedVector2Array = PackedVector2Array()
var flags: PackedByteArray = PackedByteArray()


static func from_simulation(sim: Simulation) -> Snapshot:
	var s: Snapshot = Snapshot.new()
	s.tick = sim.tick
	if sim.door_open:
		s.level_flags |= LEVEL_FLAG_DOOR_OPEN
	if sim.key_taken:
		s.level_flags |= LEVEL_FLAG_KEY_TAKEN
	for player: PlayerState in sim.players:
		var player_flags: int = 0
		if player.facing_left:
			player_flags |= FLAG_FACING_LEFT
		if player.on_ground:
			player_flags |= FLAG_ON_GROUND
		if player.dead:
			player_flags |= FLAG_DEAD
		if player.slot == sim.key_carrier:
			player_flags |= FLAG_KEY_CARRIER
		if player.entered:
			player_flags |= FLAG_ENTERED
		s.slots.append(player.slot)
		s.positions.append(player.position)
		s.flags.append(player_flags)
	return s


func index_of(slot: int) -> int:
	return slots.find(slot)
