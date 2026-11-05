extends GutTest


func test_round_trip_and_defaults() -> void:
	var path: String = "user://test_settings_%d.cfg" % Time.get_ticks_usec()
	var fresh: SettingsStore = SettingsStore.load_from(path)
	assert_eq(fresh.player_name, "")
	assert_eq(fresh.last_address, "127.0.0.1")
	assert_eq(fresh.last_port, 28015)
	fresh.player_name = "Ju"
	fresh.last_address = "10.0.0.2"
	fresh.last_port = 28016
	assert_eq(fresh.save_to(path), OK)
	var again: SettingsStore = SettingsStore.load_from(path)
	assert_eq(again.player_name, "Ju")
	assert_eq(again.last_address, "10.0.0.2")
	assert_eq(again.last_port, 28016)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
