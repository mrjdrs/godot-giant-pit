#!/usr/bin/env python3
"""Build 4-direction HD-2D sheets: chroma-key, despill, flatten, no black halo."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "characters" / "imprint" / "src"
OUT_DIR = ROOT / "assets" / "characters" / "imprint" / "weapon"
PREVIEW_DIR = ROOT / "tools" / "_preview"
FW, FH = 64, 88
GUTTER = 2
SQUASH = 0.80
WIDEN = 1.08
SOURCES = {
    "blade_4dir.png": "war_scar_4dir.png",
    "bow_4dir.png": "hawk_eye_4dir.png",
    "element_4dir.png": "element_caster_4dir.png",
    "focus_4dir.png": "affinity_binder_4dir.png",
}


def _dilate(mask: np.ndarray) -> np.ndarray:
    out = mask.copy()
    out[1:, :] |= mask[:-1, :]
    out[:-1, :] |= mask[1:, :]
    out[:, 1:] |= mask[:, :-1]
    out[:, :-1] |= mask[:, 1:]
    return out


def _erode(mask: np.ndarray) -> np.ndarray:
    return ~_dilate(~mask)


def _ring(mask: np.ndarray, width: int = 1) -> np.ndarray:
    inner = mask
    for _ in range(width):
        inner = _erode(inner)
    return mask & ~inner


def key_background(arr: np.ndarray) -> np.ndarray:
    r = arr[:, :, 0].astype(np.int16)
    g = arr[:, :, 1].astype(np.int16)
    b = arr[:, :, 2].astype(np.int16)
    a = arr[:, :, 3].astype(np.int16)
    # Only true chroma pink. Never key interior highlights as "white bg".
    magenta = (r >= 185) & (b >= 185) & (g <= 130) & ((r + b - 2 * g) >= 140)
    key = (a < 12) | magenta
    border = np.zeros(key.shape, dtype=bool)
    border[0, :] = True
    border[-1, :] = True
    border[:, 0] = True
    border[:, -1] = True
    grow = key | (border & magenta)
    pink_fringe = (r >= 150) & (b >= 150) & (g <= 175) & ((r + b - 2 * g) >= 55)
    for _ in range(18):
        nxt = _dilate(grow) & ~grow
        take = nxt & (pink_fringe | (a < 28))
        if not take.any():
            break
        grow |= take
    arr = arr.copy()
    arr[grow] = 0
    return arr


def despill_magenta(arr: np.ndarray) -> np.ndarray:
    r = arr[:, :, 0].astype(np.int16)
    g = arr[:, :, 1].astype(np.int16)
    b = arr[:, :, 2].astype(np.int16)
    a = arr[:, :, 3]
    spill = np.minimum(r, b) - g
    spill = np.clip(spill, 0, 255).astype(np.int16)
    edge = _ring(a > 16, 4)
    cut = np.where(edge, spill, (spill * 0.35).astype(np.int16))
    arr = arr.copy()
    arr[:, :, 0] = np.clip(r - cut, 0, 255).astype(np.uint8)
    arr[:, :, 2] = np.clip(b - cut, 0, 255).astype(np.uint8)
    return arr


def propagate_rgb(arr: np.ndarray, passes: int = 10) -> np.ndarray:
    """Give low-alpha / fringe pixels the color of nearby solid paint."""
    out = arr.copy()
    for _ in range(passes):
        a = out[:, :, 3]
        solid = a >= 200
        if not solid.any():
            break
        rgb = out[:, :, :3].astype(np.int32)
        weight = a.astype(np.int32)
        acc = np.zeros_like(rgb)
        wsum = np.zeros(a.shape, dtype=np.int32)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)):
            sy = slice(max(0, dy), a.shape[0] + min(0, dy))
            sx = slice(max(0, dx), a.shape[1] + min(0, dx))
            dy_dst = slice(max(0, -dy), a.shape[0] + min(0, -dy))
            dx_dst = slice(max(0, -dx), a.shape[1] + min(0, -dx))
            src_w = weight[sy, sx]
            acc[dy_dst, dx_dst] += rgb[sy, sx] * src_w[:, :, None]
            wsum[dy_dst, dx_dst] += src_w
        need = (a > 0) & (a < 230) & (wsum > 0)
        if not need.any():
            break
        filled = acc[need] // np.maximum(wsum[need], 1)[:, None]
        out[:, :, :3][need] = np.clip(filled, 0, 255).astype(np.uint8)
    return out


def _inward_rgb(arr: np.ndarray, src_mask: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    rgb = arr[:, :, :3].astype(np.int32)
    acc = np.zeros_like(rgb)
    cnt = np.zeros(src_mask.shape, dtype=np.int32)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)):
        sy = slice(max(0, dy), src_mask.shape[0] + min(0, dy))
        sx = slice(max(0, dx), src_mask.shape[1] + min(0, dx))
        dy_dst = slice(max(0, -dy), src_mask.shape[0] + min(0, -dy))
        dx_dst = slice(max(0, -dx), src_mask.shape[1] + min(0, -dx))
        src = src_mask[sy, sx]
        acc[dy_dst, dx_dst] += rgb[sy, sx] * src[:, :, None]
        cnt[dy_dst, dx_dst] += src.astype(np.int32)
    return acc, cnt


def recolor_silhouette_edge(arr: np.ndarray, rings: int = 3) -> np.ndarray:
    """Paint the outer rings with inward body color so LINEAR never samples a black fringe."""
    out = arr.copy()
    opaque = out[:, :, 3] >= 24
    halo = _ring(opaque, rings)
    if not halo.any():
        return out
    interior = opaque
    for _ in range(max(rings, 2) + 2):
        interior = _erode(interior)
    if not interior.any():
        interior = _erode(opaque)
    acc, cnt = _inward_rgb(out, interior)
    ok = halo & (cnt > 0)
    if ok.any():
        out[:, :, :3][ok] = np.clip(acc[ok] // cnt[ok][:, None], 0, 255).astype(np.uint8)
        out[:, :, 3][ok] = np.maximum(out[:, :, 3][ok], 210)
    out[halo & (cnt == 0)] = 0
    rim = _ring(out[:, :, 3] >= 24, 1)
    out[:, :, 3][rim] = np.minimum(out[:, :, 3][rim], 200)
    return out


def drop_dust(arr: np.ndarray) -> np.ndarray:
    a = arr[:, :, 3]
    luma = arr[:, :, 0].astype(np.int16) + arr[:, :, 1] + arr[:, :, 2]
    kill = (a < 36) | ((a < 90) & (luma < 140))
    out = arr.copy()
    out[kill] = 0
    out[out[:, :, 3] == 0] = 0
    return out


def crop_opaque(arr: np.ndarray, pad: int = 4) -> np.ndarray:
    ys, xs = np.where(arr[:, :, 3] >= 20)
    if ys.size == 0:
        return arr
    y0 = max(0, int(ys.min()) - pad)
    x0 = max(0, int(xs.min()) - pad)
    y1 = min(arr.shape[0], int(ys.max()) + 1 + pad)
    x1 = min(arr.shape[1], int(xs.max()) + 1 + pad)
    return arr[y0:y1, x0:x1]


def fit_flat(arr: np.ndarray) -> np.ndarray:
    canvas = np.zeros((FH, FW, 4), dtype=np.uint8)
    h, w = arr.shape[:2]
    if w < 2 or h < 2:
        return canvas
    img = Image.fromarray(arr, "RGBA")
    flat_w = max(1, int(w * WIDEN))
    flat_h = max(1, int(h * SQUASH))
    flat = img.resize((flat_w, flat_h), Image.Resampling.LANCZOS)
    scale = min((FW - 6) / flat_w, (FH - 8) / flat_h)
    nw = max(1, int(flat_w * scale))
    nh = max(1, int(flat_h * scale))
    resized = np.array(flat.resize((nw, nh), Image.Resampling.LANCZOS), dtype=np.uint8)
    resized = drop_dust(propagate_rgb(recolor_silhouette_edge(resized, rings=2), passes=6))
    ox = (FW - nw) // 2
    oy = FH - nh - 3
    canvas[oy : oy + nh, ox : ox + nw] = resized
    canvas[canvas[:, :, 3] == 0] = 0
    return canvas


def split_four(arr: np.ndarray) -> list[np.ndarray]:
    w = arr.shape[1]
    col_w = w // 4
    return [arr[:, i * col_w : (i + 1) * col_w] for i in range(4)]


def process_sheet(src: Path) -> Image.Image:
    raw = np.array(Image.open(src).convert("RGBA"), dtype=np.uint8)
    keyed = key_background(raw)
    frames = []
    for part in split_four(keyed):
        part = key_background(part)
        part = despill_magenta(part)
        part = recolor_silhouette_edge(part, rings=5)
        part = propagate_rgb(part, passes=12)
        part = drop_dust(part)
        part = crop_opaque(part, 6)
        frames.append(fit_flat(part))
    stride = FW + GUTTER
    sheet = np.zeros((FH, stride * 3 + FW, 4), dtype=np.uint8)
    for i, frame in enumerate(frames):
        x0 = i * stride
        sheet[:, x0 : x0 + FW] = frame
    return Image.fromarray(sheet, "RGBA")


def write_preview(sheets: dict[str, Image.Image]) -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    floor = (198, 184, 150, 255)
    gap = 12
    sheet_w = next(iter(sheets.values())).width
    cell_w, cell_h = sheet_w + 16, FH + 20
    preview = Image.new("RGBA", (cell_w, cell_h * len(sheets) + gap), floor)
    y = 8
    for name in SOURCES:
        sheet = sheets[name]
        row = Image.new("RGBA", (cell_w, cell_h), floor)
        row.paste(sheet, (8, 8), sheet)
        preview.paste(row, (0, y))
        y += cell_h
    out = PREVIEW_DIR / "imprint_4dir_floor.png"
    preview.save(out)
    zoomed = preview.resize((preview.width * 3, preview.height * 3), Image.Resampling.NEAREST)
    zoom_path = PREVIEW_DIR / "imprint_4dir_floor_x3.png"
    zoomed.save(zoom_path)
    print(f"wrote {out}")
    print(f"wrote {zoom_path}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheets: dict[str, Image.Image] = {}
    for out_name, src_name in SOURCES.items():
        src = SRC_DIR / src_name
        if not src.exists():
            raise FileNotFoundError(src)
        sheet = process_sheet(src)
        out = OUT_DIR / out_name
        sheet.save(out)
        sheets[out_name] = sheet
        arr = np.array(sheet)
        fringe = int(
            (
                (arr[:, :, 3] >= 20)
                & (arr[:, :, 3] < 180)
                & (arr[:, :, 0].astype(np.int16) + arr[:, :, 1] + arr[:, :, 2] < 240)
            ).sum()
        )
        print(f"wrote {out} ({sheet.width}x{sheet.height}) dark_fringe={fringe}")
    write_preview(sheets)


if __name__ == "__main__":
    main()
