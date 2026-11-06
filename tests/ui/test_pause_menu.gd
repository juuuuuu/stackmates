extends GutTest

const PAUSE_MENU_SCENE: PackedScene = preload("res://ui/pause_menu.tscn")


func test_buttons_emit() -> void:
	var menu: PauseMenu = add_child_autofree(PAUSE_MENU_SCENE.instantiate())
	watch_signals(menu)
	menu.resume_button.pressed.emit()
	assert_signal_emitted(menu, "resume_requested")
	menu.leave_button.pressed.emit()
	assert_signal_emitted(menu, "leave_requested")
