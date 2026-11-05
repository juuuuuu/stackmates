class_name InputReader
extends RefCounted
## Lit les actions pressées sur cette machine et les traduit en bits d'input.


static func read_bits() -> int:
	var bits: int = 0
	if Input.is_action_pressed("move_left"):
		bits |= InputBits.LEFT
	if Input.is_action_pressed("move_right"):
		bits |= InputBits.RIGHT
	if Input.is_action_pressed("jump"):
		bits |= InputBits.JUMP
	return bits
