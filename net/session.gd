class_name Session
extends Node
## Une session réseau : le host sert et joue, les clients rejoignent.
## Porte le transport ENet, le handshake et le roster. Une raison de refus
## de version a la forme "version_mismatch:<version client>:<version host>".

signal roster_changed(roster: Dictionary)
signal joined(local_slot: int)
signal join_failed(reason: String)
signal host_left
signal game_started(level_index: int)

const PROTOCOL_VERSION: int = 1
const DEFAULT_PORT: int = 28015
const CONNECT_TIMEOUT_SEC: float = 10.0
const HOST_PEER_ID: int = 1
const REASON_TIMEOUT: String = "timeout"
const REASON_REFUSED: String = "refused"

var is_host: bool = false
var local_slot: int = 0
var in_progress: bool = false
var roster: Roster = Roster.new()

var _peer: ENetMultiplayerPeer
var _player_name: String = ""
var _joining: bool = false


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host(port: int, player_name: String) -> Error:
	_player_name = player_name
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, SimConstants.MAX_PLAYERS - 1)
	if error != OK:
		return error
	_peer = peer
	multiplayer.multiplayer_peer = peer
	is_host = true
	in_progress = false
	roster = Roster.new()
	local_slot = roster.add(HOST_PEER_ID, player_name)
	roster_changed.emit(roster.to_dict())
	return OK


func join(address: String, port: int, player_name: String) -> Error:
	_player_name = player_name
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		return error
	_peer = peer
	multiplayer.multiplayer_peer = peer
	is_host = false
	local_slot = 0
	roster = Roster.new()
	_joining = true
	get_tree().create_timer(CONNECT_TIMEOUT_SEC).timeout.connect(_on_join_timeout)
	return OK


func leave() -> void:
	_joining = false
	if _peer != null:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	is_host = false
	in_progress = false
	local_slot = 0
	roster = Roster.new()


## Host seulement : démarre le level pour tout le monde.
func start_game(level_index: int) -> void:
	if not is_host:
		return
	_game_started.rpc(level_index)


func slot_of_peer(peer_id: int) -> int:
	return roster.slot_of(peer_id)


func peer_of_slot(slot: int) -> int:
	return roster.peer_of(slot)


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_host:
		return
	if roster.remove_peer(peer_id) != -1:
		_broadcast_roster()


func _on_connected_to_server() -> void:
	_request_join.rpc_id(HOST_PEER_ID, PROTOCOL_VERSION, _player_name)


func _on_connection_failed() -> void:
	_fail(REASON_REFUSED)


func _on_server_disconnected() -> void:
	var was_joining: bool = _joining
	leave()
	if was_joining:
		join_failed.emit(REASON_REFUSED)
	else:
		host_left.emit()


func _on_join_timeout() -> void:
	if _joining:
		_fail(REASON_TIMEOUT)


func _fail(reason: String) -> void:
	leave()
	join_failed.emit(reason)


func _broadcast_roster() -> void:
	var roster_dict: Dictionary = roster.to_dict()
	roster_changed.emit(roster_dict)
	_roster_changed.rpc(roster_dict)


@rpc("any_peer", "call_remote", "reliable")
func _request_join(protocol_version: int, player_name: String) -> void:
	if not is_host:
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	var reason: String = roster.validate_join(
		protocol_version, PROTOCOL_VERSION, player_name, in_progress
	)
	if reason.is_empty():
		var slot: int = roster.add(peer_id, player_name)
		_join_accepted.rpc_id(peer_id, slot, roster.to_dict())
		_broadcast_roster()
		return
	if reason == Roster.REASON_VERSION:
		reason = "%s:%d:%d" % [reason, protocol_version, PROTOCOL_VERSION]
	_join_refused.rpc_id(peer_id, reason)
	_peer.disconnect_peer(peer_id, false)


@rpc("authority", "call_remote", "reliable")
func _join_accepted(slot: int, roster_dict: Dictionary) -> void:
	_joining = false
	local_slot = slot
	roster.apply_dict(roster_dict)
	roster_changed.emit(roster.to_dict())
	joined.emit(slot)


@rpc("authority", "call_remote", "reliable")
func _join_refused(reason: String) -> void:
	_fail(reason)


@rpc("authority", "call_remote", "reliable")
func _roster_changed(roster_dict: Dictionary) -> void:
	roster.apply_dict(roster_dict)
	roster_changed.emit(roster.to_dict())


@rpc("authority", "call_local", "reliable")
func _game_started(level_index: int) -> void:
	in_progress = true
	game_started.emit(level_index)
