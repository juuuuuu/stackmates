class_name SettingsStore
extends RefCounted
## Les réglages du joueur, sauvés dans user://settings.cfg.

const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION_PLAYER: String = "player"
const SECTION_NET: String = "net"

var player_name: String = ""
var last_address: String = "127.0.0.1"
var last_port: int = Session.DEFAULT_PORT


## Les valeurs par défaut si le fichier manque ou ne se lit pas.
static func load_from(path: String) -> SettingsStore:
	var settings: SettingsStore = SettingsStore.new()
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return settings
	settings.player_name = config.get_value(SECTION_PLAYER, "name", settings.player_name)
	settings.last_address = config.get_value(SECTION_NET, "last_address", settings.last_address)
	settings.last_port = config.get_value(SECTION_NET, "last_port", settings.last_port)
	return settings


func save_to(path: String) -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_PLAYER, "name", player_name)
	config.set_value(SECTION_NET, "last_address", last_address)
	config.set_value(SECTION_NET, "last_port", last_port)
	return config.save(path)
