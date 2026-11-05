class_name GameSync
extends Node
## Synchronise la partie. Le host fait tourner la simulation à chaque tick
## physique et diffuse un snapshot tous les SNAPSHOT_INTERVAL_TICKS. Un client
## envoie ses inputs à chaque tick et interpole les snapshots reçus.

signal snapshot_received(s: Snapshot)

const SNAPSHOT_INTERVAL_TICKS: int = 2
const HOST_PEER_ID: int = 1

var session: Session
var simulation: Simulation
var buffer: SnapshotBuffer
var snapshots_sent: int = 0
var inputs_received: int = 0
var local_input_source: Callable = InputReader.read_bits

var _running: bool = false
var _clock: RenderClock
var _local_tick: int = 0


func start_as_host(level: Level, slots: Array[int]) -> void:
	simulation = Simulation.new(level)
	for slot: int in slots:
		simulation.add_player(slot)
	buffer = null
	snapshots_sent = 0
	inputs_received = 0
	if not session.roster_changed.is_connected(_on_roster_changed):
		session.roster_changed.connect(_on_roster_changed)
	_running = true


func start_as_client() -> void:
	simulation = null
	buffer = SnapshotBuffer.new()
	_clock = RenderClock.new()
	_local_tick = 0
	_running = true


func stop() -> void:
	_running = false
	simulation = null
	buffer = null


## L'état à afficher maintenant. Host : la simulation telle quelle. Client :
## l'interpolation des snapshots. Null si rien n'est prêt.
func current_frame(delta_sec: float) -> Snapshot:
	if not _running:
		return null
	if simulation != null:
		return Snapshot.from_simulation(simulation)
	if buffer == null or buffer.size() == 0:
		return null
	return buffer.sample(_clock.advance(delta_sec, buffer.latest_tick()))


func _physics_process(_delta: float) -> void:
	if not _running:
		return
	var bits: int = local_input_source.call()
	if simulation != null:
		_host_tick(bits)
	else:
		_local_tick += 1
		_send_input.rpc_id(HOST_PEER_ID, _local_tick, bits)


func _host_tick(bits: int) -> void:
	simulation.set_input(session.local_slot, bits)
	simulation.step()
	if simulation.tick % SNAPSHOT_INTERVAL_TICKS == 0:
		_receive_snapshot.rpc(SnapshotCodec.encode(Snapshot.from_simulation(simulation)))
		snapshots_sent += 1


## Retire de la simulation les players qui ont quitté la session.
func _on_roster_changed(roster: Dictionary) -> void:
	if simulation == null:
		return
	for player: PlayerState in simulation.players.duplicate():
		if not roster.has(player.slot):
			simulation.remove_player(player.slot)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _send_input(_tick: int, bits: int) -> void:
	if simulation == null:
		return
	var slot: int = session.slot_of_peer(multiplayer.get_remote_sender_id())
	if slot <= 0:
		return
	simulation.set_input(slot, bits)
	inputs_received += 1


@rpc("authority", "call_remote", "unreliable")
func _receive_snapshot(bytes: PackedByteArray) -> void:
	if buffer == null:
		return
	var s: Snapshot = SnapshotCodec.decode(bytes)
	if s != null and buffer.push(s):
		snapshot_received.emit(s)
