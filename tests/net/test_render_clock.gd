extends GutTest


func test_first_advance_snaps_to_target() -> void:
	var c: RenderClock = RenderClock.new()
	assert_eq(c.advance(0.016, 100), 94.0)


func test_steady_advance_follows_tick_rate() -> void:
	var c: RenderClock = RenderClock.new()
	c.advance(0.0, 100)
	var t: float = c.advance(0.5, 130)
	assert_almost_eq(t, 124.0, 0.5)


func test_large_drift_snaps() -> void:
	var c: RenderClock = RenderClock.new()
	c.advance(0.0, 100)
	assert_eq(c.advance(0.0, 500), 494.0)
