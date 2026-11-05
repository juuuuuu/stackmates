extends Node
## Point d'entrée : lit les arguments de ligne de commande, pilote la session.
## Arguments après "--" : --host, --join=ADRESSE:PORT, --port=N, --name=PSEUDO,
## --smoke (test automatique : sort en 0 si la connexion réussit).

const SMOKE_TIMEOUT_SEC: float = 20.0
const SMOKE_HOST_LINGER_SEC: float = 1.0
const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_TIMEOUT: int = 2
const DEFAULT_PLAYER_NAME: String = "Player"

var _smoke: bool = false

@onready var session: Session = $Session


func _ready() -> void:
	var args: Dictionary[String, String] = _parse_args(OS.get_cmdline_user_args())
	_smoke = args.has("smoke")
	session.joined.connect(_on_joined)
	session.join_failed.connect(_on_join_failed)
	session.roster_changed.connect(_on_roster_changed)
	session.host_left.connect(_on_host_left)
	if _smoke:
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
	if _smoke and session.is_host and roster.size() >= 2:
		var timer: SceneTreeTimer = get_tree().create_timer(SMOKE_HOST_LINGER_SEC)
		timer.timeout.connect(_quit_with.bind(EXIT_OK, "SMOKE OK"))


func _on_joined(slot: int) -> void:
	if _smoke:
		_quit_with(EXIT_OK, "SMOKE OK (slot %d)" % slot)


func _on_join_failed(reason: String) -> void:
	if _smoke:
		_quit_with(EXIT_FAILED, "join failed: %s" % reason)


func _on_host_left() -> void:
	if _smoke:
		_quit_with(EXIT_FAILED, "host left")


func _quit_with(code: int, message: String) -> void:
	print(message)
	session.leave()
	get_tree().quit(code)
