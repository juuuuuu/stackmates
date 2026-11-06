extends GutTest
## Mesure la fenêtre de départ de saut devant un spike isolé : le nombre de
## ticks consécutifs où, en courant vers la droite depuis le spawn, presser
## JUMP fait survivre le player. Un client en retard a besoin de marge.

const MIN_WINDOW_TICKS: int = 12
const SCAN_TICKS: int = 200
const RUN_TICKS: int = 200
const SPAWN_COLUMN: int = 5
const SPIKE_COLUMN: int = 20


static func _place(row: String, column: int, c: String) -> String:
	return row.substr(0, column) + c + row.substr(column + 1)


func _rows() -> Array[String]:
	var rows: Array[String] = []
	var empty: String = ".".repeat(Level.WIDTH)
	for y: int in Level.HEIGHT - 2:
		rows.append(empty)
	var ground_row: String = _place(_place(empty, SPAWN_COLUMN, "S"), SPIKE_COLUMN, "^")
	rows.append(ground_row)
	rows.append("#".repeat(Level.WIDTH))
	return rows


func _survives_when_jumping_at(tick: int) -> bool:
	var sim: Simulation = Simulation.new(Level.from_rows(_rows()))
	sim.add_player(1)
	Walkthrough.hold(sim, 1, InputBits.RIGHT, tick)
	Walkthrough.hold(sim, 1, InputBits.RIGHT | InputBits.JUMP, RUN_TICKS)
	return not sim.get_player(1).dead


func test_jump_window_over_a_lone_spike_is_at_least_twelve_ticks() -> void:
	var window: int = 0
	var first: int = -1
	for tick: int in SCAN_TICKS:
		if _survives_when_jumping_at(tick):
			if first == -1:
				first = tick
			window += 1
	assert_true(
		window >= MIN_WINDOW_TICKS, "fenêtre : %d ticks à partir du tick %d" % [window, first]
	)
