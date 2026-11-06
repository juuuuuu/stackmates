#!/usr/bin/env python3
"""Génère les sons et la musique placeholders de Stackmates. Déterministe.

Mono, 16 bits, 22050 Hz. Usage : python3 -I tools/gen_audio.py
"""

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio"
RATE = 22050
AMPLITUDE = 0.25
BPM = 140
BEAT = 60.0 / BPM


def square(phase: float) -> float:
    return 1.0 if (phase % 1.0) < 0.5 else -1.0


def triangle(phase: float) -> float:
    p = phase % 1.0
    return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p


def tone(freq_from: float, freq_to: float, seconds: float, shape=square, decay: bool = True) -> list[float]:
    """Une note (ou un glissando) avec une enveloppe linéaire décroissante."""
    count = int(RATE * seconds)
    out = []
    phase = 0.0
    for i in range(count):
        t = i / count
        freq = freq_from + (freq_to - freq_from) * t
        phase += freq / RATE
        env = (1.0 - t) if decay else 1.0
        out.append(shape(phase) * env)
    return out


def silence(seconds: float) -> list[float]:
    return [0.0] * int(RATE * seconds)


def chord(freqs: list[float], seconds: float) -> list[float]:
    parts = [tone(f, f, seconds) for f in freqs]
    return [sum(p[i] for p in parts) / len(parts) for i in range(len(parts[0]))]


def write(name: str, samples: list[float], amplitude: float = AMPLITUDE) -> None:
    with wave.open(str(OUT / f"{name}.wav"), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        frames = bytearray()
        for s in samples:
            value = max(-1.0, min(1.0, s * amplitude))
            frames += struct.pack("<h", int(value * 32767))
        out.writeframes(bytes(frames))


NOTE = {"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.0, "A4": 440.0, "B4": 493.88,
        "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99, "C3": 130.81, "F3": 174.61, "G3": 196.0, "A3": 220.0}

MELODY = [
    "C4", "E4", "G4", "E4", "C5", "G4", "E4", "G4",
    "A4", "C5", "E5", "C5", "A4", "G4", "E4", "G4",
    "F4", "A4", "C5", "A4", "F4", "E4", "D4", "E4",
    "G4", "B4", "D5", "B4", "G4", "E4", "D4", "C4",
]
BASS = ["C3", "C3", "A3", "A3", "F3", "F3", "G3", "G3"]


def music() -> list[float]:
    """Deux fois quatre mesures : la mélodie en croches, la basse en noires."""
    eighth = BEAT / 2.0
    melody: list[float] = []
    for _ in range(2):
        for name in MELODY:
            melody += tone(NOTE[name], NOTE[name], eighth)
    bass: list[float] = []
    for _ in range(2):
        for name in BASS:
            for _beat in range(2):
                bass += tone(NOTE[name], NOTE[name], BEAT, shape=triangle, decay=False)
    length = min(len(melody), len(bass))
    return [0.6 * melody[i] + 0.4 * bass[i] for i in range(length)]


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    write("jump", tone(300.0, 600.0, 0.12))
    write("death", tone(400.0, 100.0, 0.35))
    write("key", tone(660.0, 660.0, 0.08) + tone(880.0, 880.0, 0.08))
    write("door", chord([220.0, 277.18, 329.63], 0.4))
    arpeggio = [523.25, 659.25, 783.99, 1046.5]
    write("clear", sum((tone(f, f, 0.1) for f in arpeggio), []))
    victory = sum((tone(f * 2.0, f * 2.0, 0.1) for f in arpeggio), [])
    write("victory", victory + silence(0.05) + victory)
    write("music", music(), amplitude=0.2)
    print("audio généré dans", OUT)
