class_name WorldView
extends Node2D
## Affiche un level et les players d'un snapshot. Il ne décide rien : il
## dessine l'état que GameSync lui donne.

const PLAYERS_TEXTURE: Texture2D = preload("res://assets/players.png")
const SPRITE_NAME_PREFIX: String = "Player"

var _sprites: Dictionary[int, Sprite2D] = {}

@onready var _level_root: Node2D = $LevelRoot
@onready var _players: Node2D = $Players


## Remplace le level affiché par une instance de la scène donnée.
func show_level(level_scene: PackedScene) -> void:
	for child: Node in _level_root.get_children():
		_level_root.remove_child(child)
		child.queue_free()
	_level_root.add_child(level_scene.instantiate())


## Place un sprite par player du snapshot et retire ceux des players absents.
## Un snapshot null ne change rien.
func show_frame(frame: Snapshot) -> void:
	if frame == null:
		return
	for i: int in frame.slots.size():
		var sprite: Sprite2D = _sprite_for(frame.slots[i])
		sprite.position = frame.positions[i]
		sprite.flip_h = (frame.flags[i] & Snapshot.FLAG_FACING_LEFT) != 0
	for slot: int in _sprites.keys():
		if frame.index_of(slot) == -1:
			var sprite: Sprite2D = _sprites[slot]
			_sprites.erase(slot)
			_players.remove_child(sprite)
			sprite.queue_free()


func sprite_count() -> int:
	return _sprites.size()


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
