class_name UpnpOpener
extends Node
## Ouvre le port UDP de la session sur la box via UPnP, puis le referme à la
## demande. Chaque job tourne dans un thread (la découverte bloque jusqu'à deux
## secondes) et rend son résultat sur le thread principal. Un seul job à la
## fois : une fermeture ou une ouverture demandée pendant un job part après
## lui, la fermeture d'abord.

signal finished(ok: bool, message: String)
signal closed

enum Job { OPEN, CLOSE }

## Fabrique du gateway ; les tests y mettent un faux.
var gateway_factory: Callable = func() -> UpnpGateway: return UpnpGateway.new()
## Faux dans les tests : le job tourne inline, son résultat reste différé.
var use_thread: bool = true

var _thread: Thread
## Le port de l'ouverture en cours ou de la dernière ouverture.
var _port: int = 0
## Le port réellement ouvert sur la box, celui que la fermeture retire.
var _mapped_port: int = 0
var _busy: bool = false
var _mapped: bool = false
var _close_requested: bool = false
var _open_requested: bool = false
var _requested_port: int = 0


func open(port: int) -> void:
	if _busy:
		_open_requested = true
		_requested_port = port
		return
	_port = port
	_start(Job.OPEN)


## Retire le mapping s'il existe. Pendant un job, la fermeture attend sa fin.
func close() -> void:
	if _busy:
		_close_requested = true
		return
	if _mapped:
		_start(Job.CLOSE)


## Seul gel possible : à la sortie de l'application, borné par la découverte.
func _exit_tree() -> void:
	_join()


func _start(job: Job) -> void:
	_busy = true
	_join()
	var gateway: UpnpGateway = gateway_factory.call()
	var port: int = _port if job == Job.OPEN else _mapped_port
	if use_thread:
		_thread = Thread.new()
		_thread.start(_work.bind(job, gateway, port))
	else:
		_work(job, gateway, port)


func _join() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null


## Tourne dans le thread : ne touche aucun état du node.
func _work(job: Job, gateway: UpnpGateway, port: int) -> void:
	var ok: bool = false
	if gateway.discover():
		ok = gateway.add_mapping(port) if job == Job.OPEN else gateway.delete_mapping(port)
	_finish.call_deferred(job, ok)


func _finish(job: Job, ok: bool) -> void:
	_busy = false
	if job == Job.OPEN:
		_mapped = ok
		if ok:
			_mapped_port = _port
		var message: String = tr("UPnP: port opened")
		if not ok:
			message = tr("UPnP: failed. Open UDP port %d on your router.") % _port
		finished.emit(ok, message)
	else:
		_mapped = false
		closed.emit()
	if _close_requested:
		_close_requested = false
		close()
	if not _busy and _open_requested:
		_open_requested = false
		open(_requested_port)
