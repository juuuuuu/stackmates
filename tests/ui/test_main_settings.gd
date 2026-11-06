extends GutTest
## Réglages depuis l'écran Options : écriture sur disque et reflet de F11.

const MAIN_SCENE: PackedScene = preload("res://main.tscn")
const SETTINGS_PATH: String = "user://test_main_settings.cfg"


func before_each() -> void:
	TranslationServer.set_locale("en")
	# Repart d'un fichier absent : un run précédent peut avoir écrit des valeurs.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func _main() -> Main:
	var main: Main = MAIN_SCENE.instantiate()
	main.settings_path = SETTINGS_PATH
	main.network_probes_enabled = false
	return add_child_autofree(main)


func _press(main: Node, action: String) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	main.get_viewport().push_input(event)


func test_slider_changes_are_saved_on_options_close() -> void:
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


func test_settings_are_saved_when_main_leaves_the_tree() -> void:
	var main: Main = _main()
	main._on_options_requested()
	var options: OptionsScreen = main.screen_root.get_node("Options")
	options.sfx_slider.value = 0.35
	main.get_parent().remove_child(main)
	var on_disk: SettingsStore = SettingsStore.load_from(main.settings_path)
	assert_eq(on_disk.sfx_volume, 0.35, "écrit à la sortie de l'arbre")
	main.free()
