extends GutTest

const OPTIONS_SCENE: PackedScene = preload("res://ui/options.tscn")


func test_sliders_emit_and_back_closes() -> void:
	var options: OptionsScreen = add_child_autofree(OPTIONS_SCENE.instantiate())
	var settings: SettingsStore = SettingsStore.new()
	settings.music_volume = 0.25
	options.set_settings(settings)
	assert_eq(options.music_slider.value, 0.25)
	watch_signals(options)
	options.sfx_slider.value = 0.5
	assert_signal_emitted_with_parameters(options, "sfx_changed", [0.5])
	options.fullscreen_check.button_pressed = true
	assert_signal_emitted_with_parameters(options, "fullscreen_changed", [true])
	options.back_button.pressed.emit()
	assert_signal_emitted(options, "closed")
