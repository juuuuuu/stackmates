class_name RenderClock
extends RefCounted
## L'horloge de rendu d'un client : suit le dernier tick reçu avec un retard
## d'interpolation, se recale en douceur, et saute si la dérive est grande.

const INTERPOLATION_DELAY_TICKS: int = 6
const SNAP_THRESHOLD_TICKS: float = 3.0
const CATCH_UP_RATE: float = 0.1

var render_tick: float = -1.0


func advance(delta_sec: float, latest_tick: int) -> float:
	var target: float = latest_tick - INTERPOLATION_DELAY_TICKS
	render_tick += delta_sec * SimConstants.TICK_RATE
	var drift: float = target - render_tick
	if render_tick < 0.0 or absf(drift) > SNAP_THRESHOLD_TICKS:
		render_tick = target
	else:
		render_tick += drift * CATCH_UP_RATE
	return render_tick
