class_name LevelDirector
extends RefCounted
## Transforme les événements du sim en actions datées : redémarrer le niveau
## une seconde après une mort, passer au suivant 1,5 s après un level clear.

enum Action { NONE, RESTART, NEXT_LEVEL }

const DEATH_DELAY_TICKS: int = 60
const CLEAR_DELAY_TICKS: int = 90

var _pending: Action = Action.NONE
var _due_tick: int = 0


func on_event(event: SimEvent, tick: int) -> void:
	match event.kind:
		SimEvent.Kind.DEATH:
			if _pending == Action.NONE:
				_schedule(Action.RESTART, tick + DEATH_DELAY_TICKS)
		SimEvent.Kind.LEVEL_CLEAR:
			_schedule(Action.NEXT_LEVEL, tick + CLEAR_DELAY_TICKS)


## Rend l'action échue une seule fois, sinon NONE.
func poll(tick: int) -> Action:
	if _pending == Action.NONE or tick < _due_tick:
		return Action.NONE
	var action: Action = _pending
	_pending = Action.NONE
	return action


func _schedule(action: Action, due_tick: int) -> void:
	_pending = action
	_due_tick = due_tick
