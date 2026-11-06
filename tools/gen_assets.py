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
SPIKE_FILL = "#e5e7eb"
KEY_FILL = "#f2c94c"
DOOR_FILL = "#8b5e3c"
DOOR_FRAME = "#5c3d26"
DOOR_OPENING = "#1f2933"
TILE_COUNT = 5
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


def draw_tiles() -> None:
    """Atlas : 0 solid, 1 spike, 2 key, 3 door fermée, 4 door ouverte."""
    image = Image.new("RGBA", (TILE_COUNT * TILE, TILE), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    draw.rectangle([0, 0, TILE - 1, TILE - 1], fill=rgba(SOLID_FILL), outline=rgba(SOLID_BORDER))
    draw.polygon([(TILE, TILE - 1), (2 * TILE - 1, TILE - 1), (TILE + 7, 1), (TILE + 8, 1)], fill=rgba(SPIKE_FILL))
    key_x = 2 * TILE
    draw.rectangle([key_x + 2, 2, key_x + 7, 7], outline=rgba(KEY_FILL))
    draw.rectangle([key_x + 3, 3, key_x + 6, 6], outline=rgba(KEY_FILL))
    draw.rectangle([key_x + 8, 7, key_x + 9, 13], fill=rgba(KEY_FILL))
    draw.rectangle([key_x + 10, 10, key_x + 11, 10], fill=rgba(KEY_FILL))
    draw.rectangle([key_x + 10, 12, key_x + 11, 12], fill=rgba(KEY_FILL))
    closed_x = 3 * TILE
    draw.rectangle([closed_x, 0, closed_x + TILE - 1, TILE - 1], fill=rgba(DOOR_FILL), outline=rgba(DOOR_FRAME))
    draw.rectangle([closed_x + 11, 8, closed_x + 12, 9], fill=rgba(KEY_FILL))
    open_x = 4 * TILE
    draw.rectangle([open_x, 0, open_x + TILE - 1, TILE - 1], fill=rgba(DOOR_OPENING), outline=rgba(DOOR_FRAME))
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
