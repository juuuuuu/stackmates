#!/usr/bin/env python3
"""Génère les PNG placeholders de Stackmates. Sortie déterministe.

Usage : python3 -I tools/gen_assets.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
TILE = 16
BLACK = (0, 0, 0, 255)
TRANSPARENT = (0, 0, 0, 0)
SOLID_FILL = "#6b7280"
SOLID_BORDER = "#374151"
SPIKE_FILL = "#d7263d"
SPIKE_BASE = "#7a1420"
SPIKE_TIP = "#ffd6d6"
KEY_FILL = "#f2c94c"
DOOR_FILL = "#8b5e3c"
DOOR_PLANK = "#5c3d26"
DOOR_FRAME = "#d9d2c5"
DOOR_SILL = "#8e877a"
DOOR_OPENING = "#0b0f14"
TILE_COUNT = 5
# La porte occupe deux tuiles de haut : l'atlas fait 32 px de haut, les autres
# tuiles n'utilisent que les 16 px du haut.
ATLAS_HEIGHT = 2 * TILE
DOOR_ARCH_TOP = 2
PALETTE = [
    "#e63946",
    "#457bd3",
    "#2fb344",
    "#f2c94c",
    "#9b5de5",
    "#f4845f",
    "#4cc9f0",
    "#f78fb3",
]


def rgba(hex_color: str) -> tuple[int, int, int, int]:
    value = hex_color.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


def darken(color: tuple[int, int, int, int], factor: float = 0.6) -> tuple[int, int, int, int]:
    return (int(color[0] * factor), int(color[1] * factor), int(color[2] * factor), 255)


def draw_spike(draw: ImageDraw.ImageDraw, x: int) -> None:
    """Triangle rouge pointe en haut, base sombre, pointe claire : lisible comme un danger."""
    draw.polygon([(x, TILE - 1), (x + TILE - 1, TILE - 1), (x + 7, 0), (x + 8, 0)], fill=rgba(SPIKE_FILL))
    draw.rectangle([x, TILE - 2, x + TILE - 1, TILE - 1], fill=rgba(SPIKE_BASE))
    draw.rectangle([x + 7, 0, x + 8, 2], fill=rgba(SPIKE_TIP))


def draw_door(draw: ImageDraw.ImageDraw, x: int, opened: bool) -> None:
    """Arche de 16 sur 32 px : cadre de pierre clair de 2 px, battant en bois ou ouverture noire."""
    top = DOOR_ARCH_TOP
    bottom = ATLAS_HEIGHT - 1
    draw.rounded_rectangle([x, top, x + TILE - 1, top + 14], radius=7, fill=rgba(DOOR_FRAME))
    draw.rectangle([x, top + 7, x + TILE - 1, bottom], fill=rgba(DOOR_FRAME))
    inner = rgba(DOOR_OPENING) if opened else rgba(DOOR_FILL)
    draw.rounded_rectangle([x + 2, top + 2, x + TILE - 3, top + 12], radius=5, fill=inner)
    draw.rectangle([x + 2, top + 7, x + TILE - 3, bottom - 2], fill=inner)
    draw.rectangle([x, bottom - 1, x + TILE - 1, bottom], fill=rgba(DOOR_SILL))
    if not opened:
        for plank_x in (x + 6, x + 10):
            draw.line([(plank_x, top + 6), (plank_x, bottom - 3)], fill=rgba(DOOR_PLANK))
        draw.rectangle([x + 10, top + 16, x + 11, top + 17], fill=rgba(KEY_FILL))


def draw_tiles() -> None:
    """Atlas : 0 solid, 1 spike, 2 key (16 px de haut), 3 door fermée, 4 door ouverte (32 px)."""
    image = Image.new("RGBA", (TILE_COUNT * TILE, ATLAS_HEIGHT), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    draw.rectangle([0, 0, TILE - 1, TILE - 1], fill=rgba(SOLID_FILL), outline=rgba(SOLID_BORDER))
    draw_spike(draw, TILE)
    key_x = 2 * TILE
    draw.rectangle([key_x + 2, 2, key_x + 7, 7], outline=rgba(KEY_FILL))
    draw.rectangle([key_x + 3, 3, key_x + 6, 6], outline=rgba(KEY_FILL))
    draw.rectangle([key_x + 8, 7, key_x + 9, 13], fill=rgba(KEY_FILL))
    draw.rectangle([key_x + 10, 10, key_x + 11, 10], fill=rgba(KEY_FILL))
    draw.rectangle([key_x + 10, 12, key_x + 11, 12], fill=rgba(KEY_FILL))
    draw_door(draw, 3 * TILE, opened=False)
    draw_door(draw, 4 * TILE, opened=True)
    image.save(ASSETS / "tiles.png")


def draw_players() -> None:
    image = Image.new("RGBA", (len(PALETTE) * TILE, TILE), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    for index, hex_color in enumerate(PALETTE):
        x = index * TILE
        fill = rgba(hex_color)
        draw.rectangle([x, 0, x + TILE - 1, TILE - 1], fill=fill, outline=darken(fill))
        draw.rectangle([x + 4, 5, x + 5, 6], fill=BLACK)
        draw.rectangle([x + 10, 5, x + 11, 6], fill=BLACK)
    image.save(ASSETS / "players.png")


if __name__ == "__main__":
    ASSETS.mkdir(exist_ok=True)
    draw_tiles()
    draw_players()
    print("assets générés dans", ASSETS)
