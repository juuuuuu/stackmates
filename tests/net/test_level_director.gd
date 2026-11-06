extends GutTest


func test_death_schedules_restart_after_one_second() -> void:
	var d: LevelDirector = LevelDirector.new()
	d.on_event(SimEvent.make(SimEvent.Kind.DEATH, 1), 100)
	assert_eq(d.poll(159), LevelDirector.Action.NONE)
	assert_eq(d.poll(160), LevelDirector.Action.RESTART)
	assert_eq(d.poll(161), LevelDirector.Action.NONE)


func test_second_death_does_not_delay_restart() -> void:
	var d: LevelDirector = LevelDirector.new()
	d.on_event(SimEvent.make(SimEvent.Kind.DEATH, 1), 100)
	d.on_event(SimEvent.make(SimEvent.Kind.DEATH, 2), 100)
	assert_eq(d.poll(160), LevelDirector.Action.RESTART)


func test_clear_schedules_next_level() -> void:
	var d: LevelDirector = LevelDirector.new()
	d.on_event(SimEvent.make(SimEvent.Kind.LEVEL_CLEAR, 0), 100)
	assert_eq(d.poll(189), LevelDirector.Action.NONE)
	assert_eq(d.poll(190), LevelDirector.Action.NEXT_LEVEL)


func test_player_left_restarts_now() -> void:
	var d: LevelDirector = LevelDirector.new()
	d.on_player_left(100)
	assert_eq(d.poll(100), LevelDirector.Action.RESTART)


func test_player_left_does_not_cancel_next_level() -> void:
	var d: LevelDirector = LevelDirector.new()
	d.on_event(SimEvent.make(SimEvent.Kind.LEVEL_CLEAR, 0), 100)
	d.on_player_left(120)
	assert_eq(d.poll(120), LevelDirector.Action.NONE)
	assert_eq(d.poll(190), LevelDirector.Action.NEXT_LEVEL)


func test_other_events_schedule_nothing() -> void:
	var d: LevelDirector = LevelDirector.new()
	d.on_event(SimEvent.make(SimEvent.Kind.KEY_TAKEN, 1), 100)
	d.on_event(SimEvent.make(SimEvent.Kind.DOOR_OPENED, 1), 100)
	assert_eq(d.poll(1000), LevelDirector.Action.NONE)
