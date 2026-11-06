class_name MainMenu
extends Control
## Écran d'accueil : pseudo, adresse, port, puis Host ou Join.

signal host_requested(port: int, player_name: String)
signal join_requested(address: String, port: int, player_name: String)
signal options_requested

const ERROR_EMPTY_NAME: String = "Enter a name"

@onready var name_field: LineEdit = %NameField
@onready var address_field: LineEdit = %AddressField
@onready var port_field: LineEdit = %PortField
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var options_button: Button = %OptionsButton
@onready var error_label: Label = %ErrorLabel
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	options_button.pressed.connect(options_requested.emit)
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	version_label.text = "v" + version
	name_field.grab_focus()


func set_defaults(settings: SettingsStore) -> void:
	name_field.text = settings.player_name
	address_field.text = settings.last_address
	port_field.text = str(settings.last_port)


func show_error(text: String) -> void:
	error_label.text = text


func _port() -> int:
	var value: int = port_field.text.to_int()
	return value if value > 0 else Session.DEFAULT_PORT


## Le pseudo nettoyé, ou vide avec un message d'erreur affiché.
func _player_name() -> String:
	var player_name: String = name_field.text.strip_edges()
	if player_name.is_empty():
		show_error(tr(ERROR_EMPTY_NAME))
		name_field.grab_focus()
	return player_name


func _on_host_pressed() -> void:
	var player_name: String = _player_name()
	if not player_name.is_empty():
		host_requested.emit(_port(), player_name)


func _on_join_pressed() -> void:
	var player_name: String = _player_name()
	if not player_name.is_empty():
		join_requested.emit(address_field.text.strip_edges(), _port(), player_name)
