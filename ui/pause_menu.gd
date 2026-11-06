class_name PauseMenu
extends Control
## Le menu Échap pendant une partie : reprendre ou quitter la partie. La
## simulation continue derrière, seuls les inputs du player local sont coupés.

signal resume_requested
signal leave_requested

@onready var resume_button: Button = %ResumeButton
@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	resume_button.pressed.connect(resume_requested.emit)
	leave_button.pressed.connect(leave_requested.emit)
	resume_button.grab_focus()
