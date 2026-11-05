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
