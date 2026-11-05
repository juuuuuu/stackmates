extends GutTest

const MAIN_MENU_SCENE: PackedScene = preload("res://ui/main_menu.tscn")


func _menu() -> MainMenu:
	var menu: MainMenu = add_child_autofree(MAIN_MENU_SCENE.instantiate())
	watch_signals(menu)
	return menu


func test_host_emits_port_and_name_from_fields() -> void:
	var menu: MainMenu = _menu()
	var settings: SettingsStore = SettingsStore.new()
	settings.player_name = "Ju"
	settings.last_port = 28016
	menu.set_defaults(settings)
	menu.host_button.pressed.emit()
	assert_signal_emitted_with_parameters(menu, "host_requested", [28016, "Ju"])


func test_join_emits_address_port_and_name() -> void:
	var menu: MainMenu = _menu()
	menu.name_field.text = "Guest"
	menu.address_field.text = "10.0.0.5"
	menu.port_field.text = "30000"
	menu.join_button.pressed.emit()
	assert_signal_emitted_with_parameters(menu, "join_requested", ["10.0.0.5", 30000, "Guest"])


func test_empty_name_is_refused_with_error() -> void:
	var menu: MainMenu = _menu()
	menu.name_field.text = "   "
	menu.host_button.pressed.emit()
	assert_signal_not_emitted(menu, "host_requested")
	assert_false(menu.error_label.text.is_empty())


func test_name_field_is_limited_to_twelve_characters() -> void:
	assert_eq(_menu().name_field.max_length, 12)
