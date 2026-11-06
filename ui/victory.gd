class_name Victory
extends Control
## Écran de fin : tous les niveaux sont finis. Retour au lobby automatique
## après AUTO_RETURN_SEC, ou plus tôt chez le host avec le bouton.

signal back_requested

const AUTO_RETURN_SEC: float = 6.0

var _remaining_sec: float = AUTO_RETURN_SEC
var _requested: bool = false

@onready var player_list: VBoxContainer = %PlayerList
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_request_back)


## Lignes colorées par la Palette ; le bouton n'est visible que chez le host.
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
	back_button.visible = is_host
	if is_host:
		back_button.grab_focus()


func row_count() -> int:
	return player_list.get_child_count()


func remaining_sec() -> float:
	return _remaining_sec


func _process(delta: float) -> void:
	if _requested:
		return
	_remaining_sec -= delta
	if _remaining_sec <= 0.0:
		_request_back()


func _request_back() -> void:
	if _requested:
		return
	_requested = true
	back_requested.emit()
