class_name UpnpOpener
extends Node
## Ouvre le port UDP de la session sur la box via UPnP, puis le referme à la
## demande. Chaque job tourne dans un thread (la découverte bloque jusqu'à deux
## secondes) et rend son résultat sur le thread principal. Un seul job à la
## fois : une fermeture demandée pendant l'ouverture part juste après elle.

signal finished(ok: bool, message: String)
signal closed

enum Job { OPEN, CLOSE }

## Fabrique du gateway ; les tests y mettent un faux.
var gateway_factory: Callable = func() -> UpnpGateway: return UpnpGateway.new()
## Faux dans les tests : le job tourne inline, son résultat reste différé.
var use_thread: bool = true

var _thread: Thread
var _port: int = 0
var _busy: bool = false
var _mapped: bool = false
var _close_requested: bool = false


func open(port: int) -> void:
	if _busy:
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
	if use_thread:
		_thread = Thread.new()
		_thread.start(_work.bind(job, gateway, _port))
	else:
		_work(job, gateway, _port)


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
