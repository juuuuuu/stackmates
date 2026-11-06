extends GutTest


func test_line_has_time_tag_and_message() -> void:
	var text: String = GameLog.line("net", "host on port 28015")
	assert_true(text.ends_with(" [net] host on port 28015"), text)
	assert_eq(text.length(), "HH:MM:SS [net] host on port 28015".length())


func test_file_logging_is_on_with_bounded_rotation() -> void:
	var enabled: bool = ProjectSettings.get_setting("debug/file_logging/enable_file_logging.pc")
	var log_path: String = ProjectSettings.get_setting("debug/file_logging/log_path")
	var max_files: int = ProjectSettings.get_setting("debug/file_logging/max_log_files")
	assert_true(enabled)
	assert_eq(log_path, "user://logs/godot.log")
	assert_true(max_files >= 1 and max_files <= 10, str(max_files))
