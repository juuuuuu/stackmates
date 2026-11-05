extends Node
## Point d'entrée : lit les arguments de ligne de commande, pilote la session
## et la synchronisation de la partie.
## Arguments après "--" : --host, --join=ADRESSE:PORT, --port=N, --name=PSEUDO,
## --smoke (test automatique : deux processus échangent inputs et snapshots).

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

var _smoke: bool = false
var _smoke_started: bool = false
var _smoke_snapshots: int = 0
var _level_scene: PackedScene

@onready var session: Session = $Session
@onready var game_sync: GameSync = $GameSync


func _ready() -> void:
	var args: Dictionary[String, String] = _parse_args(OS.get_cmdline_user_args())
	_smoke = args.has("smoke")
	game_sync.session = session
	session.joined.connect(_on_joined)
	session.join_failed.connect(_on_join_failed)
	session.roster_changed.connect(_on_roster_changed)
	session.host_left.connect(_on_host_left)
	session.game_started.connect(_on_game_started)
	game_sync.snapshot_received.connect(_on_snapshot_received)
	if _smoke:
		game_sync.local_input_source = func() -> int: return InputBits.RIGHT
		var timer: SceneTreeTimer = get_tree().create_timer(SMOKE_TIMEOUT_SEC)
		timer.timeout.connect(_quit_with.bind(EXIT_TIMEOUT, "SMOKE TIMEOUT"))
	var player_name: String = _arg(args, "name", DEFAULT_PLAYER_NAME)
	var port: int = int(_arg(args, "port", str(Session.DEFAULT_PORT)))
	if args.has("host"):
		var error: Error = session.host(port, player_name)
		if error != OK:
			_quit_with(EXIT_FAILED, "host error: %s" % error_string(error))
	elif args.has("join"):
		var parts: PackedStringArray = args["join"].split(":")
		var join_port: int = port if parts.size() < 2 else int(parts[1])
		var error: Error = session.join(parts[0], join_port, player_name)
		if error != OK:
			_quit_with(EXIT_FAILED, "join error: %s" % error_string(error))


func _process(_delta: float) -> void:
	if not _smoke or not session.is_host:
		return
	var enough_snapshots: bool = game_sync.snapshots_sent >= SMOKE_HOST_MIN_SNAPSHOTS
	if game_sync.inputs_received >= 1 and enough_snapshots:
		_quit_with(EXIT_OK, "SMOKE OK (host)")


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


func _on_roster_changed(roster: Dictionary) -> void:
	var host_ready: bool = _smoke and session.is_host and not _smoke_started
	if host_ready and roster.size() >= SMOKE_EXPECTED_PLAYERS:
		_smoke_started = true
		session.start_game(0)


func _on_joined(_slot: int) -> void:
	pass


func _on_join_failed(reason: String) -> void:
	if _smoke:
		_quit_with(EXIT_FAILED, "join failed: %s" % reason)


func _on_host_left() -> void:
	if _smoke:
		_quit_with(EXIT_FAILED, "host left")


func _on_game_started(level_index: int) -> void:
	_level_scene = load(LevelList.PATHS[level_index])
	var level_root: Node = _level_scene.instantiate()
	var level: Level = LevelLoader.from_scene_root(level_root)
	level_root.free()
	if session.is_host:
		game_sync.start_as_host(level, session.roster.slots())
	else:
		game_sync.start_as_client()


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
