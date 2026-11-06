extends GutTest

const VICTORY_SCENE: PackedScene = preload("res://ui/victory.tscn")


func test_victory_counts_down_then_requests_back_once() -> void:
	var victory: Victory = add_child_autofree(VICTORY_SCENE.instantiate())
	victory.set_roster({1: "Host", 2: "Guest"}, false)
	watch_signals(victory)
	assert_false(victory.back_button.visible)
	victory._process(5.0)
	assert_signal_not_emitted(victory, "back_requested")
	victory._process(1.5)
	victory._process(1.0)
	assert_signal_emit_count(victory, "back_requested", 1)


func test_host_sees_back_button_and_rows() -> void:
	var victory: Victory = add_child_autofree(VICTORY_SCENE.instantiate())
	victory.set_roster({1: "Host", 2: "Guest"}, true)
	assert_true(victory.back_button.visible)
	assert_eq(victory.row_count(), 2)
