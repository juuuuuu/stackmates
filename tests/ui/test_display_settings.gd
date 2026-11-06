extends GutTest
## Le rendu suit la fenêtre : 640x360 de base, étiré par canvas_items en gardant
## le ratio, avec un facteur non entier quand la fenêtre n'est pas un multiple
## exact (fenêtre maximisée sur un écran 1080p : 1920x1050). En plein écran
## 1080p le facteur vaut 3 exactement, donc les pixels restent entiers.


func test_stretch_fills_a_window_that_is_not_an_exact_multiple() -> void:
	var mode: String = ProjectSettings.get_setting("display/window/stretch/mode")
	var aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect")
	var scale_mode: String = ProjectSettings.get_setting("display/window/stretch/scale_mode")
	assert_eq(mode, "canvas_items")
	assert_eq(aspect, "keep")
	assert_eq(scale_mode, "fractional")


func test_base_viewport_scales_exactly_three_times_at_1080p() -> void:
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	assert_eq(1920 % width, 0)
	assert_eq(1080 % height, 0)
	assert_eq(1920.0 / width, 1080.0 / height)
