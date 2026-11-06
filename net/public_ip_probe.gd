class_name PublicIpProbe
extends HTTPRequest
## Demande l'IP publique à api.ipify.org. Émet resolved ou failed, une fois.

signal resolved(address: String)
signal failed

const URL: String = "https://api.ipify.org"
const TIMEOUT_SEC: float = 8.0
const HTTP_OK: int = 200


func _ready() -> void:
	timeout = TIMEOUT_SEC
	request_completed.connect(_on_completed)


func start() -> void:
	if request(URL) != OK:
		failed.emit()


func _on_completed(
	result: int, code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	var text: String = body.get_string_from_utf8().strip_edges()
	if result == RESULT_SUCCESS and code == HTTP_OK and text.is_valid_ip_address():
		resolved.emit(text)
	else:
		failed.emit()
