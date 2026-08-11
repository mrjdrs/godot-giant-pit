#!/usr/bin/env python3
"""Build 8-direction sprite sheets from imprint portrait art."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "characters"
OUT_DIR = ROOT / "assets" / "characters" / "imprint"
FRAME = 64

# Sheet order: S, SE, E, NE, N, NW, W, SW
SOURCES = {
    "cold_blade_8dir.png": "barbarian_cold_weapon.png",
    "hot_gun_8dir.png": "officer_hot_weapon.png",
    "mage_8dir.png": "mage_magic_staff.png",
    "affinity_8dir.png": "forest_child_nature.png",
}


def crop_character(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    bbox = rgba.getbbox()
    if not bbox:
        return rgba
    x0, y0, x1, y1 = bbox
    pad = int(max(x1 - x0, y1 - y0) * 0.04)
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(rgba.width, x1 + pad)
    y1 = min(rgba.height, y1 + pad)
    return rgba.crop((x0, y0, x1, y1))


def fit_frame(img: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    scale = min((FRAME - 8) / img.width, (FRAME - 6) / img.height)
    nw = max(1, int(img.width * scale))
    nh = max(1, int(img.height * scale))
    resized = img.resize((nw, nh), Image.Resampling.NEAREST)
    ox = (FRAME - nw) // 2
    oy = FRAME - nh - 4
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def _side_view(base: Image.Image, facing_right: bool = True) -> Image.Image:
    w, h = base.size
    squeezed = base.resize((max(1, int(w * 0.72)), h), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ox = (w - squeezed.width) // 2 + (4 if facing_right else -4)
    canvas.paste(squeezed, (ox, 0), squeezed)
    if not facing_right:
        canvas = ImageOps.mirror(canvas)
    return canvas


def _diag_view(base: Image.Image, flip_x: bool = False) -> Image.Image:
    w, h = base.size
    squeezed = base.resize((max(1, int(w * 0.82)), h), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ox = (w - squeezed.width) // 2 + (2 if not flip_x else -2)
    oy = 1
    canvas.paste(squeezed, (ox, oy), squeezed)
    if flip_x:
        canvas = ImageOps.mirror(canvas)
    return canvas


def make_direction_frames(base: Image.Image) -> list[Image.Image]:
    south = fit_frame(base)
    east = fit_frame(_side_view(base, True))
    west = fit_frame(_side_view(base, False))
    north = fit_frame(ImageOps.flip(base))
    se = fit_frame(_diag_view(base, False))
    sw = fit_frame(_diag_view(base, True))
    ne = fit_frame(ImageEnhance.Brightness(_diag_view(base, False)).enhance(1.04))
    nw = fit_frame(ImageEnhance.Brightness(_diag_view(base, True)).enhance(1.04))
    return [south, se, east, ne, north, nw, west, sw]


def build_sheet(src_name: str) -> Image.Image:
    src = SRC_DIR / src_name
    if not src.exists():
        raise FileNotFoundError(src)
    base = crop_character(Image.open(src))
    frames = make_direction_frames(base)
    sheet = Image.new("RGBA", (FRAME * 8, FRAME), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * FRAME, 0), frame)
    return sheet


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for out_name, src_name in SOURCES.items():
        sheet = build_sheet(src_name)
        out_path = OUT_DIR / out_name
        sheet.save(out_path)
        print(f"wrote {out_path} ({sheet.width}x{sheet.height})")


if __name__ == "__main__":
    main()
