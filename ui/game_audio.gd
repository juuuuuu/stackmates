class_name GameAudio
extends Node
## Les deux bus audio du jeu (Music, Sfx), leurs volumes, les effets sonores
## et la boucle musicale. Un volume à 0 coupe le bus.

const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "Sfx"
const MASTER_BUS: String = "Master"
const SILENT_LINEAR: float = 0.0001
const SOUNDS: Dictionary[String, String] = {
	"jump": "res://assets/audio/jump.wav",
	"death": "res://assets/audio/death.wav",
	"key": "res://assets/audio/key.wav",
	"door": "res://assets/audio/door.wav",
	"clear": "res://assets/audio/clear.wav",
	"victory": "res://assets/audio/victory.wav",
}
const MUSIC_PATH: String = "res://assets/audio/music.wav"
## Un lecteur d'effets par joueur possible : huit sauts au même tick s'entendent.
const SFX_PLAYERS: int = SimConstants.MAX_PLAYERS

## Le dernier son demandé, pour les tests.
var last_played: String = ""

var _music: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _streams: Dictionary[String, AudioStream] = {}


func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	_music.stream = _looping_music()
	add_child(_music)
	for i: int in SFX_PLAYERS:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)
	for sound: String in SOUNDS:
		_streams[sound] = load(SOUNDS[sound])


## Joue un effet ; un nom inconnu est ignoré.
func play(sound: String) -> void:
	if not _streams.has(sound):
		return
	last_played = sound
	var player: AudioStreamPlayer = _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_PLAYERS
	player.stream = _streams[sound]
	player.play()


func start_music() -> void:
	if not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()


func is_music_playing() -> bool:
	return _music.playing


## La musique importée, dupliquée et bouclée sur toute sa longueur. L'importeur
## compresse en QOA : la longueur en échantillons vient de get_length(), pas de
## data.size().
static func _looping_music() -> AudioStreamWAV:
	var source: AudioStreamWAV = load(MUSIC_PATH)
	var music: AudioStreamWAV = source.duplicate()
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_begin = 0
	music.loop_end = roundi(music.get_length() * music.mix_rate)
	return music


func music_stream() -> AudioStreamWAV:
	return _music.stream as AudioStreamWAV


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
