extends GutTest

const HUD_SCENE: PackedScene = preload("res://ui/hud.tscn")


func test_banner_shows_then_clears() -> void:
	var hud: Hud = add_child_autofree(HUD_SCENE.instantiate())
	assert_eq(hud.banner_text(), "")
	hud.show_banner("Ju died", 1.0)
	assert_eq(hud.banner_text(), "Ju died")
	hud._process(0.5)
	assert_eq(hud.banner_text(), "Ju died")
	hud._process(0.6)
	assert_eq(hud.banner_text(), "")


func test_test_mode_badge_toggles() -> void:
	var hud: Hud = add_child_autofree(HUD_SCENE.instantiate())
	assert_false(hud.test_mode_visible())
	hud.set_test_mode(true)
	assert_true(hud.test_mode_visible())
	hud.set_test_mode(false)
	assert_false(hud.test_mode_visible())
