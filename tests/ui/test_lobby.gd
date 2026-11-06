extends GutTest

const LOBBY_SCENE: PackedScene = preload("res://ui/lobby.tscn")


func test_roster_rows_and_start_visibility() -> void:
	var lobby: Lobby = add_child_autofree(LOBBY_SCENE.instantiate())
	lobby.set_roster({1: "Host", 2: "Guest"}, true)
	assert_eq(lobby.row_count(), 2)
	assert_true(lobby.start_button.visible)
	lobby.set_roster({1: "Host"}, false)
	assert_eq(lobby.row_count(), 1)
	assert_false(lobby.start_button.visible)


func test_level_select_lists_levels_for_host_only() -> void:
	var lobby: Lobby = add_child_autofree(LOBBY_SCENE.instantiate())
	lobby.set_level_count(5)
	lobby.set_roster({1: "Host"}, true)
	assert_eq(lobby.level_select.item_count, 5)
	assert_true(lobby.level_select.visible)
	lobby.level_select.select(2)
	assert_eq(lobby.selected_level(), 2)
	watch_signals(lobby)
	lobby.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(lobby, "start_requested", [2])
	lobby.set_roster({1: "Host"}, false)
	assert_false(lobby.level_select.visible)
