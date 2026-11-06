class_name PlayerState
extends RefCounted
## L'état d'un player dans le sim core. La position est le coin haut gauche,
## en px. La vitesse est en px par seconde.

var slot: int
var position: Vector2
var velocity: Vector2
var on_ground: bool
var facing_left: bool
var coyote_ticks_left: int
var jump_buffer_ticks_left: int
var previous_input: int
var dead: bool
var entered: bool
var last_dx: float


## Un player mort ou entré dans la door n'est ni déplacé ni obstacle.
func is_active() -> bool:
	return not dead and not entered


func rect() -> Rect2:
	return Rect2(position, Vector2(SimConstants.PLAYER_SIZE, SimConstants.PLAYER_SIZE))
