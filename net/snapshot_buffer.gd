class_name SnapshotBuffer
extends RefCounted
## Les derniers snapshots reçus, par tick croissant, pour l'interpolation.

const CAPACITY: int = 32

var _snapshots: Array[Snapshot] = []


## Ignore un snapshot dont le tick n'avance pas (reçu en retard ou doublon).
func push(s: Snapshot) -> bool:
	if s.tick <= latest_tick():
		return false
	_snapshots.append(s)
	if _snapshots.size() > CAPACITY:
		_snapshots.pop_front()
	return true


func latest_tick() -> int:
	if _snapshots.is_empty():
		return -1
	return _snapshots[-1].tick


func size() -> int:
	return _snapshots.size()


## L'état interpolé au tick demandé. Avant le premier snapshot : le premier.
## Après le dernier : le dernier. Null si le buffer est vide.
func sample(render_tick: float) -> Snapshot:
	if _snapshots.is_empty():
		return null
	var oldest: Snapshot = _snapshots[0]
	var newest: Snapshot = _snapshots[-1]
	if render_tick <= oldest.tick:
		return oldest
	if render_tick >= newest.tick:
		return newest
	for i: int in range(_snapshots.size() - 1):
		var older: Snapshot = _snapshots[i]
		var newer: Snapshot = _snapshots[i + 1]
		if older.tick <= render_tick and render_tick < newer.tick:
			return _interpolate(older, newer, render_tick)
	return newest


## Positions interpolées ; tick, flags et level_flags du plus récent. Un slot
## absent du plus ancien garde sa position du plus récent.
static func _interpolate(older: Snapshot, newer: Snapshot, render_tick: float) -> Snapshot:
	var t: float = (render_tick - older.tick) / float(newer.tick - older.tick)
	var result: Snapshot = Snapshot.new()
	result.tick = newer.tick
	result.level_flags = newer.level_flags
	result.slots = newer.slots.duplicate()
	result.flags = newer.flags.duplicate()
	for i: int in newer.slots.size():
		var position: Vector2 = newer.positions[i]
		var j: int = older.index_of(newer.slots[i])
		if j != -1:
			position = older.positions[j].lerp(position, t)
		result.positions.append(position)
	return result
