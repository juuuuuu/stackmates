class_name Palette
extends RefCounted
## Les 8 couleurs des players, dans l'ordre des slots. La même palette que
## tools/gen_assets.py.

const COLORS: Array[Color] = [
	Color("#e63946"),
	Color("#457bd3"),
	Color("#2fb344"),
	Color("#f2c94c"),
	Color("#9b5de5"),
	Color("#f4845f"),
	Color("#4cc9f0"),
	Color("#f78fb3"),
]


static func of_slot(slot: int) -> Color:
	return COLORS[clampi(slot - 1, 0, COLORS.size() - 1)]
