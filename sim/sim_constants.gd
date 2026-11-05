class_name SimConstants
extends RefCounted
## Constantes du sim core. Unités : px, secondes, ticks.

const TILE_SIZE: int = 16
const TICK_RATE: int = 60
const DT: float = 1.0 / 60.0
const RUN_SPEED: float = 96.0
const JUMP_HEIGHT: float = 40.0
const JUMP_APEX_TIME: float = 0.25
const GRAVITY: float = 1280.0  # 2 * JUMP_HEIGHT / JUMP_APEX_TIME ** 2
const JUMP_SPEED: float = 320.0  # GRAVITY * JUMP_APEX_TIME
const COYOTE_TICKS: int = 4
const JUMP_BUFFER_TICKS: int = 4
const MAX_PLAYERS: int = 8
const PLAYER_SIZE: int = 16
