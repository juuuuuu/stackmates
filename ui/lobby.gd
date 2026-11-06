class_name Lobby
extends Control
## Écran d'attente : la liste des players, le choix du niveau et Start pour
## le host, Leave pour tous.

signal start_requested(level_index: int)
signal leave_requested

var _focus_placed: bool = false
var _local_ip: String = ""
var _public_ip: String = ""

@onready var status_label: Label = %StatusLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var level_select: OptionButton = %LevelSelect
@onready var start_button: Button = %StartButton
@onready var leave_button: Button = %LeaveButton
@onready var network_info: VBoxContainer = %NetworkInfo
@onready var local_ip_label: Label = %LocalIpLabel
@onready var public_ip_label: Label = %PublicIpLabel
@onready var port_label: Label = %PortLabel
@onready var upnp_label: Label = %UpnpLabel
@onready var copy_local_button: Button = %CopyLocalButton
@onready var copy_public_button: Button = %CopyPublicButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(leave_requested.emit)
	copy_local_button.pressed.connect(func() -> void: DisplayServer.clipboard_set(_local_ip))
	copy_public_button.pressed.connect(func() -> void: DisplayServer.clipboard_set(_public_ip))
	network_info.visible = false
	leave_button.grab_focus()


func set_status(text: String) -> void:
	status_label.text = text


## Une entrée "Level N" par niveau ; le premier est sélectionné.
func set_level_count(count: int) -> void:
	level_select.clear()
	for i: int in count:
		level_select.add_item(tr("Level %d") % (i + 1), i)
	if count > 0:
		level_select.select(0)


func selected_level() -> int:
	return maxi(level_select.selected, 0)


## Une ligne "<slot>. <pseudo>" par player, colorée par la Palette.
## Start et le choix du niveau ne sont visibles que chez le host.
func set_roster(roster: Dictionary, is_host: bool) -> void:
	for child: Node in player_list.get_children():
		player_list.remove_child(child)
		child.queue_free()
	var slots: Array = roster.keys()
	slots.sort()
	for slot: int in slots:
		var label: Label = Label.new()
		label.text = "%d. %s" % [slot, str(roster[slot])]
		label.modulate = Palette.of_slot(slot)
		player_list.add_child(label)
	start_button.visible = is_host
	level_select.visible = is_host
	network_info.visible = is_host
	if is_host and not _focus_placed:
		start_button.grab_focus()
		_focus_placed = true


func row_count() -> int:
	return player_list.get_child_count()


func _on_start_pressed() -> void:
	start_requested.emit(selected_level())


## Les infos à partager par le host : IP locale, IP publique, port, état UPnP.
## Une IP vide s'affiche "unknown".
func set_network_info(local_ip: String, public_ip: String, port: int, upnp_status: String) -> void:
	_local_ip = local_ip
	_public_ip = public_ip
	local_ip_label.text = (
		tr("Local IP") + ": " + (local_ip if not local_ip.is_empty() else tr("unknown"))
	)
	public_ip_label.text = (
		tr("Public IP") + ": " + (public_ip if not public_ip.is_empty() else tr("unknown"))
	)
	port_label.text = tr("Port") + ": " + str(port)
	upnp_label.text = upnp_status
	copy_local_button.disabled = local_ip.is_empty()
	copy_public_button.disabled = public_ip.is_empty()


func network_info_visible() -> bool:
	return network_info.visible
