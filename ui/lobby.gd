class_name Lobby
extends Control
## Écran d'attente : la liste des players, Start pour le host, Leave.

signal start_requested
signal leave_requested

@onready var status_label: Label = %StatusLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_button: Button = %StartButton
@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	start_button.pressed.connect(start_requested.emit)
	leave_button.pressed.connect(leave_requested.emit)
	leave_button.grab_focus()


func set_status(text: String) -> void:
	status_label.text = text


## Une ligne "<slot>. <pseudo>" par player, colorée par la Palette.
## Start n'est visible que chez le host.
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
	if is_host:
		start_button.grab_focus()


func row_count() -> int:
	return player_list.get_child_count()
