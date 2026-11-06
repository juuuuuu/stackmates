class_name Lobby
extends Control
## Écran d'attente : la liste des players, le choix du niveau et Start pour
## le host, Leave pour tous.

signal start_requested(level_index: int)
signal leave_requested

var _focus_placed: bool = false

@onready var status_label: Label = %StatusLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var level_select: OptionButton = %LevelSelect
@onready var start_button: Button = %StartButton
@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(leave_requested.emit)
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
	if is_host and not _focus_placed:
		start_button.grab_focus()
		_focus_placed = true


func row_count() -> int:
	return player_list.get_child_count()


func _on_start_pressed() -> void:
	start_requested.emit(selected_level())
