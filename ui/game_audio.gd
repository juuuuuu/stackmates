class_name GameAudio
extends Node
## Les deux bus audio du jeu (Music, Sfx) et leurs volumes. Un volume à 0
## coupe le bus.

const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "Sfx"
const MASTER_BUS: String = "Master"
const SILENT_LINEAR: float = 0.0001


func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)


func set_music_volume(linear: float) -> void:
	_set_bus_volume(BUS_MUSIC, linear)


func set_sfx_volume(linear: float) -> void:
	_set_bus_volume(BUS_SFX, linear)


func music_volume_db() -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC))


func is_music_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(BUS_MUSIC))


static func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var index: int = AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, MASTER_BUS)


static func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, linear <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, SILENT_LINEAR)))
