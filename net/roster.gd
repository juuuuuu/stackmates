class_name Roster
extends RefCounted
## Les players d'une session : slot, pseudo et pair réseau. Le host en a
## l'autorité. Un client n'en reçoit que les slots et les pseudos.

const MAX_NAME_LENGTH: int = 12
const REASON_VERSION: String = "version_mismatch"
const REASON_IN_PROGRESS: String = "in_progress"
const REASON_FULL: String = "full"
const REASON_BAD_NAME: String = "bad_name"

var _names: Dictionary[int, String] = {}
var _peers: Dictionary[int, int] = {}


## Vide si la demande est acceptée, sinon la première raison de refus dans
## l'ordre version, partie en cours, session pleine, pseudo invalide.
func validate_join(
	protocol_version: int, expected_version: int, player_name: String, in_progress: bool
) -> String:
	if protocol_version != expected_version:
		return REASON_VERSION
	if in_progress:
		return REASON_IN_PROGRESS
	if size() >= SimConstants.MAX_PLAYERS:
		return REASON_FULL
	if player_name.is_empty() or player_name.length() > MAX_NAME_LENGTH:
		return REASON_BAD_NAME
	return ""


## Donne le plus petit slot libre, ou -1 si la session est pleine ou si le
## pair a déjà un slot : un pair, un slot.
func add(peer_id: int, player_name: String) -> int:
	if slot_of(peer_id) != -1:
		return -1
	for slot: int in range(1, SimConstants.MAX_PLAYERS + 1):
		if not _names.has(slot):
			_names[slot] = player_name
			_peers[slot] = peer_id
			return slot
	return -1


## Retire le pair et rend son slot, ou -1 s'il est inconnu.
func remove_peer(peer_id: int) -> int:
	var slot: int = slot_of(peer_id)
	if slot == -1:
		return -1
	_names.erase(slot)
	_peers.erase(slot)
	return slot


func slot_of(peer_id: int) -> int:
	for slot: int in _peers:
		if _peers[slot] == peer_id:
			return slot
	return -1


func peer_of(slot: int) -> int:
	if _peers.has(slot):
		return _peers[slot]
	return -1


func name_of(slot: int) -> String:
	if _names.has(slot):
		return _names[slot]
	return ""


func slots() -> Array[int]:
	var result: Array[int] = []
	for slot: int in _names:
		result.append(slot)
	result.sort()
	return result


func size() -> int:
	return _names.size()


func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for slot: int in _names:
		result[slot] = _names[slot]
	return result


## Remplace le contenu par les slots et pseudos reçus du host.
func apply_dict(roster_dict: Dictionary) -> void:
	_names.clear()
	_peers.clear()
	for slot: int in roster_dict:
		_names[slot] = str(roster_dict[slot])
