class_name Main
extends Node
## Point d'entrée : écrans, session et synchronisation de la partie.
## Arguments après "--" : --host, --join=ADRESSE:PORT, --port=N, --name=PSEUDO,
## --smoke (test automatique : deux processus échangent inputs et snapshots).

enum State { MENU, CONNECTING, LOBBY, PLAYING }

const MAIN_MENU_SCENE: PackedScene = preload("res://ui/main_menu.tscn")
const LOBBY_SCENE: PackedScene = preload("res://ui/lobby.tscn")
const WORLD_VIEW_SCENE: PackedScene = preload("res://ui/world_view.tscn")
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

var state: State = State.MENU
## Le fichier de réglages ; les tests le redirigent avant d'ajouter la scène.
var settings_path: String = SettingsStore.DEFAULT_PATH

var _settings: SettingsStore
var _screen: Node
var _lobby: Lobby
var _world_view: WorldView
var _level_scene: PackedScene
var _level_index: int = 0
var _smoke: bool = false
var _smoke_started: bool = false
var _smoke_snapshots: int = 0

@onready var session: Session = $Session
@onready var game_sync: GameSync = $GameSync
@onready var screen_root: Control = $ScreenRoot


func _ready() -> void:
	var args: Dictionary[String, String] = _parse_args(OS.get_cmdline_user_args())
	_smoke = args.has("smoke")
	_settings = SettingsStore.load_from(settings_path)
	game_sync.session = session
	session.joined.connect(_on_joined)
	session.join_failed.connect(_on_join_failed)
	session.roster_changed.connect(_on_roster_changed)
	session.host_left.connect(_on_host_left)
	session.game_started.connect(_on_game_started)
	session.game_finished.connect(_on_game_finished)
	game_sync.snapshot_received.connect(_on_snapshot_received)
	game_sync.level_finished.connect(_on_level_finished)
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
	elif event.is_action_pressed("ui_cancel") and state != State.MENU:
		_leave_to_menu("")
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


## Le texte lisible d'une raison de refus ou d'échec de connexion.
static func _reason_text(reason: String) -> String:
	if reason.begins_with(Roster.REASON_VERSION):
		var parts: PackedStringArray = reason.split(":")
		if parts.size() == 3:
			return "Version mismatch (you: %s, host: %s)" % [parts[1], parts[2]]
		return "Version mismatch"
	match reason:
		Roster.REASON_FULL:
			return "Game is full"
		Roster.REASON_IN_PROGRESS:
			return "Game in progress"
		Roster.REASON_BAD_NAME:
			return "Invalid name"
		Session.REASON_TIMEOUT:
			return "Timed out"
		Session.REASON_REFUSED:
			return "Connection refused"
	return reason


# Écrans


func _show_menu(error_text: String) -> void:
	state = State.MENU
	_lobby = null
	_world_view = null
	var menu: MainMenu = _replace_screen(MAIN_MENU_SCENE)
	menu.set_defaults(_settings)
	menu.show_error(error_text)
	menu.host_requested.connect(_on_host_requested)
	menu.join_requested.connect(_on_join_requested)


func _show_lobby(status: String) -> void:
	_world_view = null
	_lobby = _replace_screen(LOBBY_SCENE)
	_lobby.set_status(status)
	_lobby.set_roster(session.roster.to_dict(), session.is_host)
	_lobby.start_requested.connect(_on_start_requested)
	_lobby.leave_requested.connect(_leave_to_menu.bind(""))


func _show_world() -> void:
	_lobby = null
	_world_view = _replace_screen(WORLD_VIEW_SCENE)
	_world_view.show_level(_level_scene)


func _replace_screen(scene: PackedScene) -> Node:
	if _screen != null:
		screen_root.remove_child(_screen)
		_screen.queue_free()
	_screen = scene.instantiate()
	screen_root.add_child(_screen)
	return _screen


func _leave_to_menu(error_text: String) -> void:
	game_sync.stop()
	session.leave()
	_show_menu(error_text)


func _toggle_fullscreen() -> void:
	var window: Window = get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN


func _save_settings(player_name: String, address: String, port: int) -> void:
	_settings.player_name = player_name
	_settings.last_address = address
	_settings.last_port = port
	if _settings.save_to(settings_path) != OK:
		push_warning("settings not saved")


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
		_fail_or_menu("Cannot host on port %d (%s)" % [port, error_string(error)])
		return
	state = State.LOBBY
	_show_lobby(STATUS_WAITING_PLAYERS)


func _start_join(address: String, port: int, player_name: String) -> void:
	var error: Error = session.join(address, port, player_name)
	if error != OK:
		_fail_or_menu("Cannot connect (%s)" % error_string(error))
		return
	state = State.CONNECTING
	_show_lobby(STATUS_CONNECTING)


func _on_joined(_slot: int) -> void:
	state = State.LOBBY
	if _lobby != null:
		_lobby.set_status(STATUS_WAITING_HOST)


func _on_join_failed(reason: String) -> void:
	_fail_or_menu(_reason_text(reason))


func _on_host_left() -> void:
	if _smoke:
		_quit_with(EXIT_FAILED, "host left")
		return
	_leave_to_menu(ERROR_HOST_LEFT)


func _on_roster_changed(roster: Dictionary) -> void:
	if _lobby != null:
		_lobby.set_roster(roster, session.is_host)
	var host_ready: bool = _smoke and session.is_host and not _smoke_started
	if host_ready and roster.size() >= SMOKE_EXPECTED_PLAYERS:
		_smoke_started = true
		session.start_game(0)


func _on_start_requested() -> void:
	session.start_game(0)


func _on_game_started(level_index: int) -> void:
	_level_index = level_index
	_level_scene = load(LevelList.PATHS[level_index])
	var level_root: Node = _level_scene.instantiate()
	var level: Level = LevelLoader.from_scene_root(level_root)
	level_root.free()
	if session.is_host:
		game_sync.start_as_host(level, session.roster.slots())
	else:
		game_sync.start_as_client()
	state = State.PLAYING
	_show_world()


## Host : niveau suivant s'il existe, sinon fin de partie.
func _on_level_finished() -> void:
	var next_index: int = _level_index + 1
	if next_index < LevelList.PATHS.size():
		session.start_game(next_index)
	else:
		session.finish_game()


func _on_game_finished() -> void:
	game_sync.stop()
	state = State.LOBBY
	_show_lobby(STATUS_LEVEL_CLEAR)


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
