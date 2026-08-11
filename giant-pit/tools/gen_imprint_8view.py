#!/usr/bin/env python3
"""Process top-down 8-view source art into game-ready sprite sheets."""
from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "characters" / "imprint" / "src"
CHAR_DIR = ROOT / "assets" / "characters"
OUT_DIR = ROOT / "assets" / "characters" / "imprint"
FRAME = 64
VIEWS = 8
LABELS = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]

# Each slot: ("src", column_index, flip_h) or ("portrait", 8dir_frame_index, flip_h)
SOURCE_MAPS: dict[str, list[tuple[str, int, bool]]] = {
	# Source columns: S, SE, E, NE, N, SW, W, SE(dup) — NW synthesized by mirroring NE
	"mage_8view_src.png": [
		("src", 0, False), ("src", 1, False), ("src", 2, False), ("src", 3, False),
		("src", 4, False), ("src", 3, True), ("src", 6, False), ("src", 5, False),
	],
	"hot_gun_8view_src.png": [("src", i, False) for i in range(VIEWS)],
	"affinity_8view_src.png": [("src", i, False) for i in range(VIEWS)],
	# Source columns: SE, SW, E, E, N, W, SW, SE — S/NE/NW filled from portrait
	"cold_blade_8view_src.png": [
		("portrait", 0, False), ("src", 0, False), ("src", 2, False), ("portrait", 3, False),
		("src", 4, False), ("portrait", 5, False), ("src", 5, False), ("src", 1, False),
	],
}
PORTRAITS: dict[str, str] = {
	"cold_blade_8view_src.png": "barbarian_cold_weapon.png",
}

OUTPUTS = {
	"cold_blade_8view.png": "cold_blade_8view_src.png",
	"hot_gun_8view.png": "hot_gun_8view_src.png",
	"mage_8view.png": "mage_8view_src.png",
	"affinity_8view.png": "affinity_8view_src.png",
}


def _is_key_color(r: int, g: int, b: int) -> bool:
    if r > 140 and g < 120 and b > 140:
        return True
    if g > 140 and r < 120 and b > 140:
        return True
    if r > 200 and g > 200 and b > 200:
        return True
    if abs(r - g) < 20 and abs(g - b) < 20 and (r + g + b) / 3 > 170:
        return True
    return False


def flood_transparent(img: Image.Image, tolerance: int = 34) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8 or _is_key_color(r, g, b):
                px[x, y] = (0, 0, 0, 0)
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    seeds: list[tuple[int, int]] = []
    for x, y in corners:
        r, g, b, a = px[x, y]
        if a > 0:
            seeds.append((x, y))
    if not seeds:
        return rgba
    visited = [[False] * w for _ in range(h)]
    for sx, sy in seeds:
        if visited[sy][sx]:
            continue
        sr, sg, sb, sa = px[sx, sy]
        q: deque[tuple[int, int]] = deque([(sx, sy)])
        visited[sy][sx] = True
        while q:
            x, y = q.popleft()
            px[x, y] = (0, 0, 0, 0)
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if nx < 0 or ny < 0 or nx >= w or ny >= h or visited[ny][nx]:
                    continue
                r, g, b, a = px[nx, ny]
                if a < 8:
                    visited[ny][nx] = True
                    q.append((nx, ny))
                    continue
                if abs(r - sr) + abs(g - sg) + abs(b - sb) <= tolerance:
                    visited[ny][nx] = True
                    q.append((nx, ny))
    return rgba


def keep_largest_component(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    seen = [[False] * w for _ in range(h)]
    best: list[tuple[int, int]] = []

    def neighbors(x: int, y: int):
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                yield nx, ny

    for y in range(h):
        for x in range(w):
            if seen[y][x] or px[x, y][3] < 20:
                continue
            stack = [(x, y)]
            comp: list[tuple[int, int]] = []
            seen[y][x] = True
            while stack:
                cx, cy = stack.pop()
                comp.append((cx, cy))
                for nx, ny in neighbors(cx, cy):
                    if not seen[ny][nx] and px[nx, ny][3] >= 20:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            if len(comp) > len(best):
                best = comp
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    for cx, cy in best:
        opx[cx, cy] = px[cx, cy]
    return out


def remove_small_blobs(img: Image.Image, min_size: int = 12) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    seen = [[False] * w for _ in range(h)]

    def neighbors(x: int, y: int):
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                yield nx, ny

    for y in range(h):
        for x in range(w):
            if seen[y][x] or px[x, y][3] < 20:
                continue
            stack = [(x, y)]
            comp: list[tuple[int, int]] = []
            seen[y][x] = True
            while stack:
                cx, cy = stack.pop()
                comp.append((cx, cy))
                for nx, ny in neighbors(cx, cy):
                    if not seen[ny][nx] and px[nx, ny][3] >= 20:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            if len(comp) < min_size:
                for cx, cy in comp:
                    px[cx, cy] = (0, 0, 0, 0)
    return rgba


def trim_alpha(img: Image.Image, pad: int = 2) -> Image.Image:
    rgba = img.convert("RGBA")
    bbox = rgba.getbbox()
    if not bbox:
        return rgba
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(rgba.width, x1 + pad)
    y1 = min(rgba.height, y1 + pad)
    return rgba.crop((x0, y0, x1, y1))


def scrub_artifacts(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 20:
                continue
            if _is_key_color(r, g, b):
                px[x, y] = (0, 0, 0, 0)
    return rgba


def fit_frame(cell: Image.Image) -> Image.Image:
    cell = flood_transparent(cell)
    cell = keep_largest_component(cell)
    cell = remove_small_blobs(cell)
    cell = trim_alpha(cell)
    canvas = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    bbox = cell.getbbox()
    if not bbox:
        return canvas
    cropped = cell.crop(bbox)
    pad = 4
    scale = min((FRAME - pad * 2) / cropped.width, (FRAME - pad * 2) / cropped.height)
    nw = max(1, int(cropped.width * scale))
    nh = max(1, int(cropped.height * scale))
    resized = cropped.resize((nw, nh), Image.Resampling.NEAREST)
    ox = (FRAME - nw) // 2
    oy = FRAME - nh - 2
    canvas.paste(resized, (ox, oy), resized)
    cleaned = remove_small_blobs(canvas, min_size=4)
    cleaned = keep_largest_component(cleaned)
    return scrub_artifacts(cleaned)


def _crop_character(img: Image.Image) -> Image.Image:
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


def _fit_portrait_frame(img: Image.Image) -> Image.Image:
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


def _make_portrait_frames(base: Image.Image) -> list[Image.Image]:
	south = _fit_portrait_frame(base)
	east = _fit_portrait_frame(_side_view(base, True))
	west = _fit_portrait_frame(_side_view(base, False))
	north = _fit_portrait_frame(ImageOps.flip(base))
	se = _fit_portrait_frame(_diag_view(base, False))
	sw = _fit_portrait_frame(_diag_view(base, True))
	ne = _fit_portrait_frame(ImageEnhance.Brightness(_diag_view(base, False)).enhance(1.04))
	nw = _fit_portrait_frame(ImageEnhance.Brightness(_diag_view(base, True)).enhance(1.04))
	return [south, se, east, ne, north, nw, west, sw]


def _load_portrait_frames(src_name: str) -> list[Image.Image]:
	portrait_file = PORTRAITS.get(src_name, "")
	if portrait_file == "":
		raise ValueError(f"no portrait configured for {src_name}")
	path = CHAR_DIR / portrait_file
	if not path.exists():
		raise FileNotFoundError(path)
	return _make_portrait_frames(_crop_character(Image.open(path)))


def _resolve_view(
	kind: str,
	index: int,
	flip_h: bool,
	src_frames: list[Image.Image],
	portrait_frames: list[Image.Image] | None,
) -> Image.Image:
	if kind == "src":
		frame = fit_frame(src_frames[index])
	elif kind == "portrait":
		if portrait_frames is None:
			raise ValueError("portrait frame requested but portrait art was not loaded")
		frame = portrait_frames[index]
	else:
		raise ValueError(f"unknown view kind: {kind}")
	if flip_h:
		frame = ImageOps.mirror(frame)
	return frame


def split_frames(img: Image.Image) -> list[Image.Image]:
    rgba = flood_transparent(img)
    w, h = rgba.size
    slice_w = w // VIEWS
    frames: list[Image.Image] = []
    for i in range(VIEWS):
        x0 = i * slice_w
        x1 = x0 + slice_w if i < VIEWS - 1 else w
        frames.append(rgba.crop((x0, 0, x1, h)))
    return frames


def build_sheet(src_name: str) -> Image.Image:
    src = SRC_DIR / src_name
    if not src.exists():
        raise FileNotFoundError(src)
    src_frames = split_frames(Image.open(src))
    slot_map = SOURCE_MAPS.get(src_name, [("src", i, False) for i in range(VIEWS)])
    if len(slot_map) != VIEWS:
        raise ValueError(f"{src_name}: expected {VIEWS} view slots, got {len(slot_map)}")
    portrait_frames = _load_portrait_frames(src_name) if src_name in PORTRAITS else None
    out_frames: list[Image.Image] = []
    for kind, index, flip_h in slot_map:
        out_frames.append(_resolve_view(kind, index, flip_h, src_frames, portrait_frames))
    sheet = Image.new("RGBA", (FRAME * VIEWS, FRAME), (0, 0, 0, 0))
    for i, frame in enumerate(out_frames):
        sheet.paste(frame, (i * FRAME, 0), frame)
    return sheet


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for out_name, src_name in OUTPUTS.items():
        sheet = build_sheet(src_name)
        out_path = OUT_DIR / out_name
        sheet.save(out_path)
        print(f"wrote {out_path} ({sheet.width}x{sheet.height})")


if __name__ == "__main__":
    main()
