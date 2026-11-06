class_name WorldView
extends Node2D
## Affiche un level, sa key, sa door et les players d'un snapshot. Il ne
## décide rien : il dessine l'état que GameSync lui donne.

const PLAYERS_TEXTURE: Texture2D = preload("res://assets/players.png")
const TILES_TEXTURE: Texture2D = preload("res://assets/tiles.png")
const SPRITE_NAME_PREFIX: String = "Player"
const KEY_CARRY_OFFSET: Vector2 = Vector2(0, -12)
const DEAD_MODULATE: Color = Color(0.45, 0.45, 0.45)
const ATLAS_KEY: int = 2
const ATLAS_DOOR_CLOSED: int = 3
const ATLAS_DOOR_OPEN: int = 4
## La door se dessine sur deux tuiles : son sprite part de la tuile au-dessus.
const DOOR_HEIGHT_TILES: int = 2
const DOOR_SPRITE_OFFSET: Vector2 = Vector2(0, -SimConstants.TILE_SIZE)
const LOCAL_MARKER_SEC: float = 3.0
## Le label fait 23 px de haut : son bas reste 3 px au-dessus du sprite.
const LOCAL_MARKER_OFFSET: Vector2 = Vector2(-6, -26)

var _sprites: Dictionary[int, Sprite2D] = {}
var _level: Level
var _local_slot: int = 0
var _marker_remaining_sec: float = 0.0

@onready var _level_root: Node2D = $LevelRoot
@onready var _players: Node2D = $Players
@onready var _key: Sprite2D = $Key
@onready var _door: Sprite2D = $Door
@onready var _local_marker: Label = $LocalMarker


func _ready() -> void:
	_setup_tile_sprite(_key, ATLAS_KEY)
	_setup_door_sprite()
	_key.visible = false
	_door.visible = false
	_local_marker.visible = false


## Relance le marqueur "You" au-dessus du player local pour LOCAL_MARKER_SEC.
func set_local_slot(slot: int) -> void:
	_local_slot = slot
	_marker_remaining_sec = LOCAL_MARKER_SEC


func local_marker_visible() -> bool:
	return _local_marker.visible


func _process(delta: float) -> void:
	if _marker_remaining_sec > 0.0:
		_marker_remaining_sec -= delta


## Remplace le level affiché par une instance de la scène donnée, et place
## la key et la door d'après les données du level.
func show_level(level_scene: PackedScene, level: Level) -> void:
	for child: Node in _level_root.get_children():
		_level_root.remove_child(child)
		child.queue_free()
	_level_root.add_child(level_scene.instantiate())
	_level = level
	_door.visible = level.door_tile != Level.NO_TILE
	_door.position = Vector2(level.door_tile) * SimConstants.TILE_SIZE + DOOR_SPRITE_OFFSET
	_key.visible = level.has_key()
	_key.position = Vector2(level.key_tile) * SimConstants.TILE_SIZE


## Place un sprite par player du snapshot et retire ceux des players absents.
## Un snapshot null ne change rien.
func show_frame(frame: Snapshot) -> void:
	if frame == null:
		return
	for i: int in frame.slots.size():
		var sprite: Sprite2D = _sprite_for(frame.slots[i])
		var bits: int = frame.flags[i]
		sprite.position = frame.positions[i]
		sprite.flip_h = (bits & Snapshot.FLAG_FACING_LEFT) != 0
		sprite.visible = (bits & Snapshot.FLAG_ENTERED) == 0
		sprite.modulate = DEAD_MODULATE if (bits & Snapshot.FLAG_DEAD) != 0 else Color.WHITE
	for slot: int in _sprites.keys():
		if frame.index_of(slot) == -1:
			var sprite: Sprite2D = _sprites[slot]
			_sprites.erase(slot)
			_players.remove_child(sprite)
			sprite.queue_free()
	_show_level_state(frame)
	_show_local_marker(frame)


func sprite_count() -> int:
	return _sprites.size()


func key_sprite() -> Sprite2D:
	return _key


func door_sprite() -> Sprite2D:
	return _door


## La door suit son flag ; la key reste à sa tile, suit son porteur, ou
## disparaît une fois la door ouverte.
func _show_level_state(frame: Snapshot) -> void:
	if _level == null:
		return
	var door_open: bool = (frame.level_flags & Snapshot.LEVEL_FLAG_DOOR_OPEN) != 0
	_set_door_atlas(door_open)
	if not _level.has_key() or door_open:
		_key.visible = false
		return
	if (frame.level_flags & Snapshot.LEVEL_FLAG_KEY_TAKEN) == 0:
		_key.visible = true
		_key.position = Vector2(_level.key_tile) * SimConstants.TILE_SIZE
		return
	var carrier: int = _carrier_index(frame)
	_key.visible = carrier != -1
	if carrier != -1:
		_key.position = frame.positions[carrier] + KEY_CARRY_OFFSET


static func _carrier_index(frame: Snapshot) -> int:
	for i: int in frame.slots.size():
		if (frame.flags[i] & Snapshot.FLAG_KEY_CARRIER) != 0:
			return i
	return -1


func _setup_tile_sprite(sprite: Sprite2D, atlas_index: int) -> void:
	sprite.centered = false
	sprite.texture = TILES_TEXTURE
	sprite.region_enabled = true
	_set_atlas(sprite, atlas_index)


static func _set_atlas(sprite: Sprite2D, atlas_index: int) -> void:
	var size: int = SimConstants.TILE_SIZE
	sprite.region_rect = Rect2(size * atlas_index, 0, size, size)


func _setup_door_sprite() -> void:
	_door.centered = false
	_door.texture = TILES_TEXTURE
	_door.region_enabled = true
	_set_door_atlas(false)


func _set_door_atlas(opened: bool) -> void:
	var size: int = SimConstants.TILE_SIZE
	var index: int = ATLAS_DOOR_OPEN if opened else ATLAS_DOOR_CLOSED
	_door.region_rect = Rect2(size * index, 0, size, size * DOOR_HEIGHT_TILES)


func _sprite_for(slot: int) -> Sprite2D:
	if _sprites.has(slot):
		return _sprites[slot]
	var size: int = SimConstants.TILE_SIZE
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = SPRITE_NAME_PREFIX + str(slot)
	sprite.centered = false
	sprite.texture = PLAYERS_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(size * (slot - 1), 0, size, size)
	_players.add_child(sprite)
	_sprites[slot] = sprite
	return sprite


func _show_local_marker(frame: Snapshot) -> void:
	var index: int = frame.index_of(_local_slot)
	var shown: bool = _marker_remaining_sec > 0.0 and index != -1
	_local_marker.visible = shown
	if shown:
		_local_marker.position = frame.positions[index] + LOCAL_MARKER_OFFSET
