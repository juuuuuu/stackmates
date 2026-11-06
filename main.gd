class_name Main
extends Node
## Point d'entrée : écrans, session et synchronisation de la partie.
## Arguments après "--" : --host, --join=ADRESSE:PORT, --port=N, --name=PSEUDO,
## --smoke (test automatique : deux processus échangent inputs et snapshots).

enum State { MENU, CONNECTING, LOBBY, PLAYING, VICTORY, OPTIONS }

const MAIN_MENU_SCENE: PackedScene = preload("res://ui/main_menu.tscn")
const LOBBY_SCENE: PackedScene = preload("res://ui/lobby.tscn")
const WORLD_VIEW_SCENE: PackedScene = preload("res://ui/world_view.tscn")
const HUD_SCENE: PackedScene = preload("res://ui/hud.tscn")
const VICTORY_SCENE: PackedScene = preload("res://ui/victory.tscn")
const OPTIONS_SCENE: PackedScene = preload("res://ui/options.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://ui/pause_menu.tscn")
const BANNER_DEATH_SEC: float = 1.0
const BANNER_CLEAR_SEC: float = 1.5
const BANNER_LEVEL_CLEAR: String = "Level clear"
const STATUS_WAITING_PLAYERS: String = "Waiting for players..."
const STATUS_CONNECTING: String = "Connecting..."
const STATUS_WAITING_HOST: String = "Waiting for the host to start"
const STATUS_LEVEL_CLEAR: String = "Level clear!"
const ERROR_HOST_LEFT: String = "Host left"
const SMOKE_TIMEOUT_SEC: float = 20.0
const SMOKE_HOST_MIN_SNAPSHOTS: int = 30
const SMOKE_CLIENT_SNAPSHOTS: int = 10
const SMOKE_EXPECTED_PLAYERS: int = 2
const SMOKE_CLIENT_SLOT: int = 2
const SMOKE_CLIENT_SPAWN_X: float = 96.0
const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_TIMEOUT: int = 2
const DEFAULT_PLAYER_NAME: String = "Player"
const REASON_TEXTS: Dictionary[String, String] = {
	Roster.REASON_FULL: "Game is full",
	Roster.REASON_IN_PROGRESS: "Game in progress",
	Roster.REASON_BAD_NAME: "Invalid name",
	Session.REASON_TIMEOUT: "Timed out",
	Session.REASON_REFUSED: "Connection refused",
}

var state: State = State.MENU
## Les bandeaux de la partie ; null hors partie.
var hud: Hud
## Le menu Échap ; null quand il est fermé.
var pause_menu: PauseMenu
## Le fichier de réglages ; les tests le redirigent avant d'ajouter la scène.
var settings_path: String = SettingsStore.DEFAULT_PATH
## Les sondes réseau du host (IP publique, UPnP) ; coupées par les tests et le smoke.
var network_probes_enabled: bool = true

var _settings: SettingsStore
var _screen: Node
var _lobby: Lobby
var _world_view: WorldView
var _level_scene: PackedScene
var _level_index: int = 0
var _level: Level
var _smoke: bool = false
var _smoke_started: bool = false
var _smoke_snapshots: int = 0
var _death_names: Array[String] = []
var _host_port: int = 0
var _local_ip: String = ""
var _public_ip: String = ""
## Texte affiché tant que l'IP publique est vide : "searching..." ou "unknown".
var _public_ip_status: String = ""
var _upnp_status: String = ""
var _public_ip_probe: PublicIpProbe
var _upnp_opener: UpnpOpener

@onready var session: Session = $Session
@onready var game_sync: GameSync = $GameSync
@onready var audio: GameAudio = $GameAudio
@onready var screen_root: Control = $ScreenRoot


func _ready() -> void:
	var args: Dictionary[String, String] = _parse_args(OS.get_cmdline_user_args())
	_smoke = args.has("smoke")
	_settings = SettingsStore.load_from(settings_path)
	audio.set_music_volume(_settings.music_volume)
	audio.set_sfx_volume(_settings.sfx_volume)
	_set_fullscreen(_settings.fullscreen)
	game_sync.session = session
	game_sync.local_input_source = _read_local_input
	session.joined.connect(_on_joined)
	session.join_failed.connect(_on_join_failed)
	session.roster_changed.connect(_on_roster_changed)
	session.host_left.connect(_on_host_left)
	session.game_started.connect(_on_game_started)
	session.game_finished.connect(_on_game_finished)
	game_sync.snapshot_received.connect(_on_snapshot_received)
	game_sync.level_finished.connect(_on_level_finished)
	game_sync.level_event.connect(_on_level_event)
	_upnp_opener = UpnpOpener.new()
	_upnp_opener.finished.connect(_on_upnp_finished)
	add_child(_upnp_opener)
	if _smoke:
		game_sync.local_input_source = func() -> int: return InputBits.RIGHT
		var timer: SceneTreeTimer = get_tree().create_timer(SMOKE_TIMEOUT_SEC)
		timer.timeout.connect(_quit_with.bind(EXIT_TIMEOUT, "SMOKE TIMEOUT"))
	var player_name: String = _arg(args, "name", DEFAULT_PLAYER_NAME)
	var port: int = int(_arg(args, "port", str(Session.DEFAULT_PORT)))
	if args.has("host"):
		_start_host(port, player_name)
	elif args.has("join"):
		var parts: PackedStringArray = args["join"].split(":")
		var join_port: int = port if parts.size() < 2 else int(parts[1])
		_start_join(parts[0], join_port, player_name)
	else:
		_show_menu("")


func _process(delta: float) -> void:
	if state == State.PLAYING and _world_view != null:
		_world_view.show_frame(game_sync.current_frame(delta))
	if _smoke and session.is_host:
		var enough_snapshots: bool = game_sync.snapshots_sent >= SMOKE_HOST_MIN_SNAPSHOTS
		if game_sync.inputs_received >= 1 and enough_snapshots:
			_quit_with(EXIT_OK, "SMOKE OK (host)")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


static func _parse_args(raw: PackedStringArray) -> Dictionary[String, String]:
	var args: Dictionary[String, String] = {}
	for item: String in raw:
		var key: String = item.trim_prefix("--")
		var value: String = ""
		var separator: int = key.find("=")
		if separator != -1:
			value = key.substr(separator + 1)
			key = key.substr(0, separator)
		args[key] = value
	return args


static func _arg(args: Dictionary[String, String], key: String, fallback: String) -> String:
	if args.has(key) and not args[key].is_empty():
		return args[key]
	return fallback


## Le texte lisible, traduit, d'une raison de refus ou d'échec de connexion.
func _reason_text(reason: String) -> String:
	if reason.begins_with(Roster.REASON_VERSION):
		var parts: PackedStringArray = reason.split(":")
		if parts.size() == 3:
			return tr("Version mismatch (you: %s, host: %s)") % [parts[1], parts[2]]
		return tr("Version mismatch")
	if REASON_TEXTS.has(reason):
		return tr(REASON_TEXTS[reason])
	return reason


# Écrans


func _show_menu(error_text: String) -> void:
	state = State.MENU
	_clear_hud()
	audio.stop_music()
	_lobby = null
	_world_view = null
	var menu: MainMenu = _replace_screen(MAIN_MENU_SCENE)
	menu.set_defaults(_settings)
	menu.show_error(error_text)
	menu.host_requested.connect(_on_host_requested)
	menu.join_requested.connect(_on_join_requested)
	menu.options_requested.connect(_on_options_requested)


func _show_lobby(status: String) -> void:
	_close_pause_menu()
	_clear_hud()
	audio.stop_music()
	_world_view = null
	_lobby = _replace_screen(LOBBY_SCENE)
	_lobby.set_status(status)
	_lobby.set_level_count(LevelList.count())
	_lobby.set_roster(session.roster.to_dict(), session.is_host)
	_lobby.start_requested.connect(_on_start_requested)
	_lobby.leave_requested.connect(_leave_to_menu.bind(""))
	_refresh_network_info()


func _show_world() -> void:
	_lobby = null
	_world_view = _replace_screen(WORLD_VIEW_SCENE)
	_world_view.show_level(_level_scene, _level)
	_world_view.set_local_slot(session.local_slot)
	if hud == null:
		hud = HUD_SCENE.instantiate()
		add_child(hud)


func _clear_hud() -> void:
	if hud != null:
		remove_child(hud)
		hud.queue_free()
		hud = null


func _replace_screen(scene: PackedScene) -> Node:
	if _screen != null:
		screen_root.remove_child(_screen)
		_screen.queue_free()
	_screen = scene.instantiate()
	screen_root.add_child(_screen)
	return _screen


func _leave_to_menu(error_text: String) -> void:
	_close_pause_menu()
	_stop_network_probes()
	game_sync.stop()
	session.leave()
	_show_menu(error_text)


## Échap : en partie, ouvre ou ferme le menu ; dans les options, revient au
## menu ; ailleurs hors menu principal, quitte la session.
func _on_cancel_pressed() -> void:
	match state:
		State.MENU:
			pass
		State.PLAYING:
			if pause_menu == null:
				_open_pause_menu()
			else:
				_close_pause_menu()
		State.OPTIONS:
			_on_options_closed()
		_:
			_leave_to_menu("")


## Vrai quand le menu Échap est ouvert : le player local n'envoie plus rien.
func is_input_blocked() -> bool:
	return pause_menu != null


func _read_local_input() -> int:
	if is_input_blocked():
		return 0
	return InputReader.read_bits()


func _open_pause_menu() -> void:
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	pause_menu.resume_requested.connect(_on_pause_resume)
	pause_menu.leave_requested.connect(_on_pause_leave)
	add_child(pause_menu)


func _close_pause_menu() -> void:
	if pause_menu == null:
		return
	remove_child(pause_menu)
	pause_menu.queue_free()
	pause_menu = null


func _on_pause_resume() -> void:
	_close_pause_menu()


func _on_pause_leave() -> void:
	_close_pause_menu()
	_leave_to_menu("")


func _toggle_fullscreen() -> void:
	_settings.fullscreen = not _settings.fullscreen
	_set_fullscreen(_settings.fullscreen)
	_persist_settings()


func _set_fullscreen(enabled: bool) -> void:
	var window: Window = get_window()
	window.mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED


func _persist_settings() -> void:
	if _settings.save_to(settings_path) != OK:
		push_warning("settings not saved")


func _show_options() -> void:
	state = State.OPTIONS
	var options: OptionsScreen = _replace_screen(OPTIONS_SCENE)
	options.set_settings(_settings)
	options.music_changed.connect(_on_music_changed)
	options.sfx_changed.connect(_on_sfx_changed)
	options.fullscreen_changed.connect(_on_fullscreen_changed)
	options.closed.connect(_on_options_closed)


func _on_options_requested() -> void:
	_show_options()


func _on_options_closed() -> void:
	_show_menu("")


func _on_music_changed(linear: float) -> void:
	_settings.music_volume = linear
	audio.set_music_volume(linear)
	_persist_settings()


func _on_sfx_changed(linear: float) -> void:
	_settings.sfx_volume = linear
	audio.set_sfx_volume(linear)
	_persist_settings()


func _on_fullscreen_changed(enabled: bool) -> void:
	_settings.fullscreen = enabled
	_set_fullscreen(enabled)
	_persist_settings()


func _save_settings(player_name: String, address: String, port: int) -> void:
	_settings.player_name = player_name
	_settings.last_address = address
	_settings.last_port = port
	_persist_settings()


# Session


## Depuis le menu : sauve les réglages puis héberge.
func _on_host_requested(port: int, player_name: String) -> void:
	_save_settings(player_name, _settings.last_address, port)
	_start_host(port, player_name)


## Depuis le menu : sauve les réglages puis rejoint.
func _on_join_requested(address: String, port: int, player_name: String) -> void:
	_save_settings(player_name, address, port)
	_start_join(address, port, player_name)


func _start_host(port: int, player_name: String) -> void:
	var error: Error = session.host(port, player_name)
	if error != OK:
		GameLog.info("net", "host failed on port %d: %s" % [port, error_string(error)])
		_fail_or_menu(tr("Cannot host on port %d (%s)") % [port, error_string(error)])
		return
	state = State.LOBBY
	_show_lobby(tr(STATUS_WAITING_PLAYERS))
	_start_network_probes(port)


func _start_join(address: String, port: int, player_name: String) -> void:
	var error: Error = session.join(address, port, player_name)
	if error != OK:
		GameLog.info("net", "join failed: %s" % error_string(error))
		_fail_or_menu(tr("Cannot connect (%s)") % error_string(error))
		return
	state = State.CONNECTING
	_show_lobby(tr(STATUS_CONNECTING))


func _on_joined(_slot: int) -> void:
	state = State.LOBBY
	if _lobby != null:
		_lobby.set_status(tr(STATUS_WAITING_HOST))


func _on_join_failed(reason: String) -> void:
	_fail_or_menu(_reason_text(reason))


func _on_host_left() -> void:
	if _smoke:
		_quit_with(EXIT_FAILED, "host left")
		return
	_leave_to_menu(tr(ERROR_HOST_LEFT))


func _on_roster_changed(roster: Dictionary) -> void:
	if _lobby != null:
		_lobby.set_roster(roster, session.is_host)
	var host_ready: bool = _smoke and session.is_host and not _smoke_started
	if host_ready and roster.size() >= SMOKE_EXPECTED_PLAYERS:
		_smoke_started = true
		session.start_game(0)


func _on_start_requested(level_index: int) -> void:
	session.start_game(level_index)


func _on_game_started(level_index: int) -> void:
	if level_index < 0 or level_index >= LevelList.count():
		push_warning("niveau inconnu : %d" % level_index)
		return
	_level_index = level_index
	_level_scene = load(LevelList.PATHS[level_index])
	var level_root: Node = _level_scene.instantiate()
	_level = LevelLoader.from_scene_root(level_root)
	level_root.free()
	if session.is_host:
		game_sync.start_as_host(_level, session.roster.slots())
	else:
		game_sync.start_as_client()
	state = State.PLAYING
	_show_world()
	audio.start_music()


## Host : niveau suivant s'il existe, sinon fin de partie.
func _on_level_finished() -> void:
	GameLog.info("game", "level %d finished" % _level_index)
	var next_index: int = _level_index + 1
	if next_index < LevelList.PATHS.size():
		session.start_game(next_index)
	else:
		session.finish_game()


## Bandeau et son d'un événement de niveau. Hors partie, rien.
func _on_level_event(kind: int, slot: int) -> void:
	if state != State.PLAYING or hud == null:
		return
	match kind:
		SimEvent.Kind.DEATH:
			if hud.banner_text().is_empty():
				_death_names.clear()
			_death_names.append(session.roster.name_of(slot))
			var names: String = (" " + tr("and") + " ").join(_death_names)
			hud.show_banner(tr("%s died") % names, BANNER_DEATH_SEC)
			audio.play("death")
		SimEvent.Kind.LEVEL_CLEAR:
			hud.show_banner(tr(BANNER_LEVEL_CLEAR), BANNER_CLEAR_SEC)
			audio.play("clear")
		SimEvent.Kind.KEY_TAKEN:
			audio.play("key")
		SimEvent.Kind.DOOR_OPENED:
			audio.play("door")
		SimEvent.Kind.JUMP:
			audio.play("jump")


func _on_game_finished() -> void:
	GameLog.info("game", "victory")
	game_sync.stop()
	state = State.VICTORY
	_show_victory()


func _show_victory() -> void:
	_close_pause_menu()
	_clear_hud()
	audio.stop_music()
	audio.play("victory")
	_world_view = null
	var victory: Victory = _replace_screen(VICTORY_SCENE)
	victory.set_roster(session.roster.to_dict(), session.is_host)
	victory.back_requested.connect(_on_victory_back)


func _on_victory_back() -> void:
	if state != State.VICTORY:
		return
	state = State.LOBBY
	_show_lobby(tr(STATUS_LEVEL_CLEAR))


## En smoke : quitte avec le code d'échec. Sinon : retour au menu avec le message.
func _fail_or_menu(message: String) -> void:
	if _smoke:
		_quit_with(EXIT_FAILED, "join failed: %s" % message)
		return
	_leave_to_menu(message)


# Smoke


func _on_snapshot_received(s: Snapshot) -> void:
	if not _smoke:
		return
	_smoke_snapshots += 1
	if _smoke_snapshots < SMOKE_CLIENT_SNAPSHOTS:
		return
	var index: int = s.index_of(SMOKE_CLIENT_SLOT)
	if s.slots.size() != SMOKE_EXPECTED_PLAYERS or index == -1:
		_quit_with(EXIT_FAILED, "smoke: %d players, slot 2 index %d" % [s.slots.size(), index])
		return
	if s.positions[index].x <= SMOKE_CLIENT_SPAWN_X:
		_quit_with(EXIT_FAILED, "smoke: slot 2 did not move (x=%f)" % s.positions[index].x)
		return
	_quit_with(EXIT_OK, "SMOKE OK (client, slot 2 x=%f)" % s.positions[index].x)


func _quit_with(code: int, message: String) -> void:
	print(message)
	game_sync.stop()
	session.leave()
	get_tree().quit(code)


# Infos réseau du host


func _start_network_probes(port: int) -> void:
	_host_port = port
	_local_ip = NetInfo.local_ipv4()
	_public_ip = ""
	_public_ip_status = tr("unknown")
	_upnp_status = tr("UPnP: opening the port...")
	if not network_probes_enabled or _smoke:
		_refresh_network_info()
		return
	_public_ip_status = tr("searching...")
	_refresh_network_info()
	_public_ip_probe = PublicIpProbe.new()
	_public_ip_probe.resolved.connect(_on_public_ip_resolved)
	_public_ip_probe.failed.connect(_on_public_ip_failed)
	add_child(_public_ip_probe)
	_public_ip_probe.start()
	_upnp_opener.open(port)


## Ferme le mapping UPnP (sans attendre) et arrête la sonde d'IP publique.
func _stop_network_probes() -> void:
	_upnp_opener.close()
	if _public_ip_probe != null:
		remove_child(_public_ip_probe)
		_public_ip_probe.queue_free()
		_public_ip_probe = null


func _on_public_ip_resolved(address: String) -> void:
	GameLog.info("net", "public ip %s" % address)
	_public_ip = address
	_refresh_network_info()


func _on_public_ip_failed() -> void:
	GameLog.info("net", "public ip unknown")
	_public_ip_status = tr("unknown")
	_refresh_network_info()


func _on_upnp_finished(ok: bool, message: String) -> void:
	GameLog.info("net", "upnp %s on port %d" % ["ok" if ok else "failed", _host_port])
	_upnp_status = message
	_refresh_network_info()


func _refresh_network_info() -> void:
	if _lobby != null and session.is_host:
		_lobby.set_network_info(_local_ip, _public_ip, _public_ip_status, _host_port, _upnp_status)
