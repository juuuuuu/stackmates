extends GutTest
## Règle de placement : aucun spike à moins de 6 tuiles d'un spawn, et une
## poussée au départ (le dernier de la file marche une demi-seconde) ne tue
## personne, même à huit joueurs.

const MIN_TILES: int = 6
const HALF_SECOND_TICKS: int = 30


func test_no_spike_within_six_tiles_of_a_spawn() -> void:
	for path: String in LevelList.PATHS:
		var level: Level = Walkthrough.load_level(path)
		for spawn: Vector2i in level.spawns:
			for y: int in Level.HEIGHT:
				for x: int in Level.WIDTH:
					if level.grid.get_tile(x, y) != TileGrid.Tile.SPIKE:
						continue
					var distance: int = maxi(absi(x - spawn.x), absi(y - spawn.y))
					assert_true(
						distance >= MIN_TILES,
						"%s spawn %s spike %s" % [path, spawn, Vector2i(x, y)]
					)


func test_rear_walker_half_second_kills_nobody_on_every_level() -> void:
	for path: String in LevelList.PATHS:
		var sim: Simulation = Simulation.new(Walkthrough.load_level(path))
		for slot: int in range(1, SimConstants.MAX_PLAYERS + 1):
			sim.add_player(slot)
		Walkthrough.idle_all(sim)
		Walkthrough.hold(sim, _leftmost_slot(sim), InputBits.RIGHT, HALF_SECOND_TICKS)
		for player: PlayerState in sim.players:
			assert_false(player.dead, "%s slot %d" % [path, player.slot])


func _leftmost_slot(sim: Simulation) -> int:
	var best: PlayerState = sim.players[0]
	for player: PlayerState in sim.players:
		if player.position.x < best.position.x:
			best = player
	return best.slot
