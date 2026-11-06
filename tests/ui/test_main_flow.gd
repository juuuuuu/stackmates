extends GutTest

const MAIN_SCENE: PackedScene = preload("res://main.tscn")
const TEST_PORT: int = 28017


## Les textes attendus sont en anglais, quelle que soit la langue de la machine.
func before_each() -> void:
	TranslationServer.set_locale("en")


func _main() -> Main:
	var main: Main = MAIN_SCENE.instantiate()
	main.settings_path = "user://test_main_flow_settings.cfg"
	main.network_probes_enabled = false
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
	main._on_pause_leave()
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
	assert_eq(main.hud.banner_text(), "Mort de Ju et Ju")
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


func test_options_screen_opens_and_closes() -> void:
	var main: Main = _main()
	main._on_options_requested()
	assert_eq(main.state, main.State.OPTIONS)
	assert_not_null(main.screen_root.get_node_or_null("Options"))
	main._on_options_closed()
	assert_eq(main.state, main.State.MENU)


func test_events_play_sounds_and_music_follows_the_game() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(0)
	assert_true(main.audio.is_music_playing())
	main._on_level_event(SimEvent.Kind.JUMP, 1)
	assert_eq(main.audio.last_played, "jump")
	main._on_level_event(SimEvent.Kind.KEY_TAKEN, 1)
	assert_eq(main.audio.last_played, "key")
	_press(main, "ui_cancel")
	main._on_pause_leave()
	assert_false(main.audio.is_music_playing())


func test_level_event_outside_game_is_ignored() -> void:
	var main: Main = _main()
	main._on_level_event(SimEvent.Kind.JUMP, 1)
	assert_eq(main.state, main.State.MENU)
	assert_eq(main.audio.last_played, "")


func test_escape_toggles_pause_menu() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(0)
	_press(main, "ui_cancel")
	assert_eq(main.state, main.State.PLAYING)
	assert_not_null(main.pause_menu)
	assert_true(main.is_input_blocked())
	var bits: int = main.game_sync.local_input_source.call()
	assert_eq(bits, 0)
	_press(main, "ui_cancel")
	assert_null(main.pause_menu)
	assert_false(main.is_input_blocked())
	_press(main, "ui_cancel")
	main._on_pause_leave()
	assert_eq(main.state, main.State.MENU)


func test_escape_in_lobby_leaves() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	_press(main, "ui_cancel")
	assert_eq(main.state, main.State.MENU)


func test_victory_closes_pause_menu() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(4)
	_press(main, "ui_cancel")
	assert_not_null(main.pause_menu)
	main.game_sync.level_finished.emit()
	assert_eq(main.state, main.State.VICTORY)
	assert_null(main.pause_menu)
	assert_false(main.is_input_blocked())
	main._on_victory_back()
	_press(main, "ui_cancel")


func test_host_without_probes_shows_public_ip_unknown() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	var lobby: Lobby = main.screen_root.get_node("Lobby")
	assert_eq(lobby.public_ip_label.text, "Public IP: unknown")


func test_slider_changes_are_saved_on_options_close() -> void:
	# Repart d'un fichier absent : un run précédent peut avoir écrit 0.25.
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_main_flow_settings.cfg"))
	var main: Main = _main()
	main._on_options_requested()
	var options: OptionsScreen = main.screen_root.get_node("Options")
	options.music_slider.value = 0.25
	var on_disk: SettingsStore = SettingsStore.load_from(main.settings_path)
	assert_ne(on_disk.music_volume, 0.25, "pas encore écrit")
	options.back_button.pressed.emit()
	on_disk = SettingsStore.load_from(main.settings_path)
	assert_eq(on_disk.music_volume, 0.25, "écrit à la fermeture")


func test_f11_in_options_updates_the_checkbox() -> void:
	var main: Main = _main()
	main._on_options_requested()
	var options: OptionsScreen = main.screen_root.get_node("Options")
	var before: bool = options.fullscreen_check.button_pressed
	_press(main, "toggle_fullscreen")
	assert_eq(options.fullscreen_check.button_pressed, not before)
	_press(main, "toggle_fullscreen")


func test_pause_menu_blocks_movement_input() -> void:
	var main: Main = _main()
	main._on_host_requested(TEST_PORT, "Ju")
	main._on_start_requested(0)
	Input.action_press("move_right")
	_press(main, "ui_cancel")
	assert_not_null(main.pause_menu)
	var blocked_bits: int = main.game_sync.local_input_source.call()
	assert_eq(blocked_bits, 0, "bloqué par le menu")
	_press(main, "ui_cancel")
	var released_bits: int = main.game_sync.local_input_source.call()
	assert_eq(released_bits, InputBits.RIGHT, "libéré")
	Input.action_release("move_right")
	main._on_pause_leave()
