extends GutTest


func test_buses_exist_after_ready() -> void:
	var audio: GameAudio = add_child_autofree(GameAudio.new())
	assert_not_null(audio)
	assert_ne(AudioServer.get_bus_index(GameAudio.BUS_MUSIC), -1)
	assert_ne(AudioServer.get_bus_index(GameAudio.BUS_SFX), -1)


func test_zero_volume_mutes_bus() -> void:
	var audio: GameAudio = add_child_autofree(GameAudio.new())
	audio.set_music_volume(0.0)
	assert_true(audio.is_music_muted())
	audio.set_music_volume(0.5)
	assert_false(audio.is_music_muted())
	assert_almost_eq(audio.music_volume_db(), linear_to_db(0.5), 0.01)


func test_play_records_last_sound_and_ignores_unknown() -> void:
	var audio: GameAudio = add_child_autofree(GameAudio.new())
	audio.play("jump")
	assert_eq(audio.last_played, "jump")
	audio.play("nope")
	assert_eq(audio.last_played, "jump")


func test_music_starts_and_stops() -> void:
	var audio: GameAudio = add_child_autofree(GameAudio.new())
	audio.start_music()
	assert_true(audio.is_music_playing())
	audio.stop_music()
	assert_false(audio.is_music_playing())
