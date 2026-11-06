class_name GameLog
extends RefCounted
## Lignes de log horodatées. Godot les écrit dans user://logs/godot.log
## (réglage debug/file_logging, actif par défaut sur desktop).


## `HH:MM:SS [tag] message`, heure locale.
static func line(tag: String, message: String) -> String:
	return "%s [%s] %s" % [Time.get_time_string_from_system(), tag, message]


static func info(tag: String, message: String) -> void:
	print(line(tag, message))
