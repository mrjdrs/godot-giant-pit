#!/usr/bin/env python3
"""Generate a heavy greatsword chop WAV for 大刀 attacks."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "sfx_blade_chop.wav"
RATE = 44100
DURATION = 0.32


def main() -> None:
    n = int(RATE * DURATION)
    seed = 2463534242
    samples: list[int] = []
    for i in range(n):
        t = i / RATE
        seed = (seed ^ ((seed << 13) & 0xFFFFFFFF)) & 0xFFFFFFFF
        seed = (seed ^ (seed >> 17)) & 0xFFFFFFFF
        seed = (seed ^ ((seed << 5) & 0xFFFFFFFF)) & 0xFFFFFFFF
        noise = (seed & 0x7FFFFFFF) / 2147483647.0 * 2.0 - 1.0
        whoosh = noise * math.exp(-t * 16.0) * (1.0 - t / DURATION) * 0.38
        freq = 380.0 * math.exp(-t * 9.0) + 70.0
        blade = math.sin(2 * math.pi * freq * t) * math.exp(-t * 12.0) * 0.62
        thump = math.sin(2 * math.pi * 62.0 * t) * math.exp(-t * 20.0) * 0.78
        click = math.sin(2 * math.pi * 1650.0 * t) * math.exp(-t * 55.0) * 0.22
        s = max(-1.0, min(1.0, whoosh + blade + thump + click))
        samples.append(int(round(s * 32767.0)))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", v) for v in samples))
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
