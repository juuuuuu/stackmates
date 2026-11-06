extends GutTest
## La doc d'installation doit suivre le moteur : chemins des logs, Gatekeeper, vie privée.

const README: String = "res://README.md"
const ITCH_PAGE: String = "res://docs/itch-page.md"
const LOG_DIR_WINDOWS: String = "%APPDATA%\\Godot\\app_userdata\\Stackmates\\logs\\"
const LOG_DIR_LINUX: String = "~/.local/share/godot/app_userdata/Stackmates/logs/"
const LOG_DIR_MACOS: String = "~/Library/Application Support/Godot/app_userdata/Stackmates/logs/"


func _text(path: String) -> String:
	var text: String = FileAccess.get_file_as_string(path)
	assert_false(text.is_empty(), path)
	return text


## Le chemin Linux documenté est celui que le moteur utilise vraiment.
func test_linux_log_path_matches_engine_user_dir() -> void:
	var home: String = OS.get_environment("HOME")
	var engine_dir: String = OS.get_user_data_dir() + "/logs/"
	var expected: String = engine_dir.replace(home, "~")
	assert_eq(expected, LOG_DIR_LINUX)
	assert_true(_text(README).contains(expected), "README : " + expected)
	assert_true(_text(ITCH_PAGE).contains(expected), "itch : " + expected)


func test_docs_give_godot_app_userdata_paths_for_all_platforms() -> void:
	for path: String in [README, ITCH_PAGE]:
		var text: String = _text(path)
		assert_true(text.contains(LOG_DIR_WINDOWS), path + " windows")
		assert_true(text.contains(LOG_DIR_MACOS), path + " macos")
		assert_false(text.contains("share/Stackmates/logs"), path + " ancien chemin")


func test_docs_give_the_macos_15_gatekeeper_route() -> void:
	assert_true(_text(README).contains("Ouvrir quand même"))
	assert_true(_text(ITCH_PAGE).contains("Open Anyway"))
	assert_true(_text(ITCH_PAGE).contains("xattr -dr com.apple.quarantine Stackmates.app"))


func test_docs_warn_that_logs_hold_ips_and_names() -> void:
	assert_true(_text(README).contains("adresses IP"))
	assert_true(_text(ITCH_PAGE).contains("IP addresses"))
