class_name Hud
extends CanvasLayer
## Les bandeaux de la partie : "X died", "Level clear". Un texte à la fois.

var _remaining_sec: float = 0.0

@onready var _panel: PanelContainer = %BannerPanel
@onready var _label: Label = %BannerLabel


func _ready() -> void:
	_panel.visible = false


func show_banner(text: String, seconds: float) -> void:
	_label.text = text
	_remaining_sec = seconds
	_panel.visible = true


## Le texte affiché, ou vide quand rien n'est affiché.
func banner_text() -> String:
	if not _panel.visible:
		return ""
	return _label.text


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_remaining_sec -= delta
	if _remaining_sec <= 0.0:
		_panel.visible = false
		_label.text = ""
