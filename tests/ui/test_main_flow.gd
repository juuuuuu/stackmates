extends GutTest

const MAIN_SCENE: PackedScene = preload("res://main.tscn")
const TEST_PORT: int = 28017


## Les textes attendus sont en anglais, quelle que soit la langue de la machine.
func before_each() -> void:
	TranslationServer.set_locale("en")


func _main() -> Main:
	var main: Main = MAIN_SCENE.instantiate()
	main.settings_path = "user://test_main_flow_settings.cfg"
	return add_child_autofree(main)


func _press(main: Node, action: String) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	main.get_viewport().push_input(event)


func test_starts_on_menu() -> void:
	var main: Main = _main()
	assert_eq(main.state, main.State.MENU)
	assert_not_null(main.screen_root.get_node_or_null("MainMenu"))


func test_host_then_cancel_returns_to_menu() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	assert_eq(main.state, main.State.LOBBY)
	var lobby: Lobby = main.screen_root.get_node("Lobby")
	assert_eq(lobby.row_count(), 1)
	assert_true(lobby.start_button.visible)
	_press(main, "ui_cancel")
	assert_eq(main.state, main.State.MENU)
	assert_false(main.session.is_host)


func test_host_start_shows_world_with_one_player() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(0)
	assert_eq(main.state, main.State.PLAYING)
	# En headless, _process ne tourne qu'après deux signaux process_frame.
	await get_tree().process_frame
	await get_tree().process_frame
	var view: WorldView = main.screen_root.get_node("WorldView")
	assert_eq(view.sprite_count(), 1)
	_press(main, "ui_cancel")
	assert_eq(main.state, main.State.MENU)


func test_last_level_finished_returns_to_lobby() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main.session.start_game(LevelList.PATHS.size() - 1)
	main.game_sync.level_finished.emit()
	assert_eq(main.state, main.State.VICTORY)
	assert_false(main.session.in_progress)
	main._on_victory_back()
	assert_eq(main.state, main.State.LOBBY)
	var lobby: Lobby = main.screen_root.get_node("Lobby")
	assert_eq(lobby.status_label.text, "Level clear!")
	_press(main, "ui_cancel")


func test_death_event_shows_name_in_banner() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(0)
	main._on_level_event(SimEvent.Kind.DEATH, 1)
	assert_eq(main.hud.banner_text(), "Ju died")
	TranslationServer.set_locale("fr")
	main._on_level_event(SimEvent.Kind.DEATH, 1)
	TranslationServer.set_locale("en")
	assert_eq(main.hud.banner_text(), "Ju et Ju est mort")
	_press(main, "ui_cancel")


func test_level_select_starts_at_chosen_index() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(3)
	assert_eq(main.state, main.State.PLAYING)
	assert_eq(main._level_index, 3)
	_press(main, "ui_cancel")


func test_victory_then_lobby_resets_screen() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(4)
	main.game_sync.level_finished.emit()
	assert_eq(main.state, main.State.VICTORY)
	assert_not_null(main.screen_root.get_node_or_null("Victory"))
	main._on_victory_back()
	assert_eq(main.state, main.State.LOBBY)
	assert_null(main.screen_root.get_node_or_null("Victory"))
	_press(main, "ui_cancel")


func test_two_deaths_same_tick_name_both() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(0)
	main._on_level_event(SimEvent.Kind.DEATH, 1)
	main._on_level_event(SimEvent.Kind.DEATH, 7)
	assert_eq(main.hud.banner_text(), "Ju and Player 7 died")
	_press(main, "ui_cancel")


func test_out_of_range_level_index_is_ignored() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_game_started(42)
	assert_eq(main.state, main.State.LOBBY)
	_press(main, "ui_cancel")
