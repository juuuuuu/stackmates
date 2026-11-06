extends GutTest

const MAIN_MENU_SCENE: PackedScene = preload("res://ui/main_menu.tscn")


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_french_locale_translates_scene_and_code_texts() -> void:
	TranslationServer.set_locale("fr")
	var menu: MainMenu = add_child_autofree(MAIN_MENU_SCENE.instantiate())
	# Les scènes sont traduites à l'affichage : text garde la clé, atr() la traduit.
	assert_eq(menu.host_button.atr(menu.host_button.text), "Héberger")
	assert_eq(tr("Level clear!"), "Niveau terminé !")
	assert_eq(tr("%s died") % "Ju et Lo", "Mort de Ju et Lo")


func test_unknown_locale_falls_back_to_english() -> void:
	TranslationServer.set_locale("de")
	var menu: MainMenu = add_child_autofree(MAIN_MENU_SCENE.instantiate())
	assert_eq(menu.host_button.atr(menu.host_button.text), "Host")
	assert_eq(tr("Game is full"), "Game is full")


func test_player_fallback_name_is_translated() -> void:
	TranslationServer.set_locale("fr")
	assert_eq(Roster.new().name_of(3), "Joueur 3")
