class_name UpnpOpener
extends Node
## Tente d'ouvrir le port UDP de la session sur la box via UPnP, dans un
## thread (la découverte bloque jusqu'à deux secondes). Émet finished sur le
## thread principal avec un message traduit.

signal finished(ok: bool, message: String)

const DISCOVER_TIMEOUT_MS: int = 2000
const DESCRIPTION: String = "Stackmates"
const PROTOCOL: String = "UDP"

var _thread: Thread
var _port: int = 0


func open(port: int) -> void:
	if _thread != null and _thread.is_alive():
		return
	_port = port
	_thread = Thread.new()
	_thread.start(_work.bind(port))


func _exit_tree() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()


func _work(port: int) -> void:
	var upnp: UPNP = UPNP.new()
	var ok: bool = false
	var discovered: int = upnp.discover(DISCOVER_TIMEOUT_MS)
	if discovered == UPNP.UPNP_RESULT_SUCCESS and upnp.get_device_count() > 0:
		ok = upnp.add_port_mapping(port, port, DESCRIPTION, PROTOCOL) == UPNP.UPNP_RESULT_SUCCESS
	_finish.call_deferred(ok)


func _finish(ok: bool) -> void:
	var message: String = tr("UPnP: port opened")
	if not ok:
		message = tr("UPnP: failed. Open UDP port %d on your router.") % _port
	finished.emit(ok, message)
