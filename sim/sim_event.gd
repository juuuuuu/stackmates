class_name SimEvent
extends RefCounted
## Un fait notable produit par le sim core pendant un tick. Le host les draine
## et les diffuse aux clients.

enum Kind { DEATH, KEY_TAKEN, DOOR_OPENED, LEVEL_CLEAR, JUMP }

var kind: Kind
var slot: int


static func make(event_kind: Kind, event_slot: int) -> SimEvent:
	var event: SimEvent = SimEvent.new()
	event.kind = event_kind
	event.slot = event_slot
	return event
