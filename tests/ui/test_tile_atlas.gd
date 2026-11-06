extends GutTest
## Les placeholders se lisent d'un coup d'œil : porte en arche sur deux tuiles,
## cadre clair et ouverture sombre ; spike rouge.

const TILES: Texture2D = preload("res://assets/tiles.png")


func test_atlas_holds_two_tile_tall_doors() -> void:
	assert_eq(TILES.get_width(), 80)
	assert_eq(TILES.get_height(), 32)


func test_spike_is_red() -> void:
	var pixel: Color = TILES.get_image().get_pixel(24, 13)
	assert_gt(pixel.r, 0.6)
	assert_lt(pixel.g, 0.35)
	assert_lt(pixel.b, 0.35)


func test_door_frame_is_light_and_opening_is_dark() -> void:
	var image: Image = TILES.get_image()
	var frame: Color = image.get_pixel(48, 24)
	assert_gt(frame.r, 0.7, "cadre de pierre clair, bord gauche de la porte fermée")
	var opening: Color = image.get_pixel(72, 24)
	assert_lt(opening.r, 0.15, "ouverture sombre au centre de la porte ouverte")
