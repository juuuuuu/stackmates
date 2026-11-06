class_name MainMenu
extends Control
## Écran d'accueil : pseudo, adresse, port, puis Host ou Join.

signal host_requested(port: int, player_name: String)
signal join_requested(address: String, port: int, player_name: String)
signal options_requested

const ERROR_EMPTY_NAME: String = "Enter a name"
const ERROR_INVALID_PORT: String = "Invalid port"
const PORT_MAX: int = 65535

@onready var name_field: LineEdit = %NameField
@onready var address_field: LineEdit = %AddressField
@onready var port_field: LineEdit = %PortField
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var error_label: Label = %ErrorLabel
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	options_button.pressed.connect(options_requested.emit)
	quit_button.pressed.connect(get_tree().quit)
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	version_label.text = "v" + version
	name_field.grab_focus()


func set_defaults(settings: SettingsStore) -> void:
	name_field.text = settings.player_name
	address_field.text = settings.last_address
	port_field.text = str(settings.last_port)


func show_error(text: String) -> void:
	error_label.text = text


## Le port saisi : 28015 si le champ est vide, 0 (refus) s'il n'est pas un
## entier de 1 à 65535.
func _port() -> int:
	var text: String = port_field.text.strip_edges()
	if text.is_empty():
		return Session.DEFAULT_PORT
	if not text.is_valid_int():
		return 0
	var value: int = text.to_int()
	return value if value >= 1 and value <= PORT_MAX else 0


## Le port validé, ou 0 avec un message d'erreur affiché.
func _valid_port() -> int:
	var port: int = _port()
	if port == 0:
		show_error(tr(ERROR_INVALID_PORT))
		port_field.grab_focus()
	return port


## Le pseudo nettoyé, ou vide avec un message d'erreur affiché.
func _player_name() -> String:
	var player_name: String = name_field.text.strip_edges()
	if player_name.is_empty():
		show_error(tr(ERROR_EMPTY_NAME))
		name_field.grab_focus()
	return player_name


func _on_host_pressed() -> void:
	var player_name: String = _player_name()
	if player_name.is_empty():
		return
	var port: int = _valid_port()
	if port != 0:
		host_requested.emit(port, player_name)


func _on_join_pressed() -> void:
	var player_name: String = _player_name()
	if player_name.is_empty():
		return
	var port: int = _valid_port()
	if port != 0:
		join_requested.emit(address_field.text.strip_edges(), port, player_name)
