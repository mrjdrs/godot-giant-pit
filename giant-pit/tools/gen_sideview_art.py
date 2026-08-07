#!/usr/bin/env python3
"""Generate side-view pixel art for giant-pit Phase A–C with volume shading."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets"

OUT = "#00000000"
INK = "#2A1F18"
SKIN = "#E8C090"
SKIN2 = "#C4A070"
SKIN3 = "#A88058"
CLOTH = "#5A6B4A"
CLOTH2 = "#4A5A3A"
CLOTH3 = "#3A4A2A"
HAIR = "#3A2A20"
BRAND = "#C45C2A"
METAL = "#8A9098"
METAL2 = "#B0B8C0"
METAL3 = "#6A7078"
WOOD = "#8B5A2B"
WOOD2 = "#6B4020"
WOOD3 = "#A07040"
GREEN = "#4A8B3A"
GREEN2 = "#6BB84A"
GREEN3 = "#2A6B2A"
MOSS = "#3A6B4A"
MOSS2 = "#5A8B5A"
MOSS3 = "#2A4B38"
FOG = "#A8C0B8"
FOG2 = "#C8D8D0"
COPPER = "#B87333"
COPPER2 = "#D89850"
COPPER3 = "#8A5020"
STONE = "#6B5344"
STONE2 = "#8B7355"
STONE3 = "#4A3828"
DEEP = "#3A3548"
DEEP2 = "#4A4560"
DEEP3 = "#2A2538"
GOLD = "#E8A838"
RED = "#C42A2A"
CRYSTAL = "#7EC8E8"
CRYSTAL2 = "#A8E0F8"
SHELL = "#7A6A58"
ALCH = "#3D8B7A"
ALCH2 = "#5BB8A5"
ALCH3 = "#2A6B5A"
PAPER = "#E8E0C8"
MIND = "#6B4C9A"
MIND2 = "#9B7BC8"
HUB_STONE = "#7A7068"
HUB_STONE2 = "#8A8078"
HUB_STONE3 = "#5A5048"
HUB_WARM = "#9A8870"


def hex_to_rgba(c: str) -> tuple[int, int, int, int]:
    if c == OUT:
        return (0, 0, 0, 0)
    c = c.lstrip("#")
    if len(c) == 8:
        return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), int(c[6:8], 16))
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


def _clamp(v: int) -> int:
    return max(0, min(255, v))


def lighten(c: str, amt: float = 0.12) -> str:
    r, g, b, a = hex_to_rgba(c)
    return "#%02X%02X%02X" % (
        _clamp(int(r + (255 - r) * amt)),
        _clamp(int(g + (255 - g) * amt)),
        _clamp(int(b + (255 - b) * amt)),
    )


def darken(c: str, amt: float = 0.12) -> str:
    r, g, b, a = hex_to_rgba(c)
    return "#%02X%02X%02X" % (_clamp(int(r * (1 - amt))), _clamp(int(g * (1 - amt))), _clamp(int(b * (1 - amt))))


def new_img(w: int = 32, h: int = 48) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(img: Image.Image, x: int, y: int, c: str) -> None:
    w, h = img.size
    if 0 <= x < w and 0 <= y < h:
        img.putpixel((x, y), hex_to_rgba(c))


def fill_rect(img: Image.Image, x: int, y: int, w: int, h: int, c: str) -> None:
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px(img, xx, yy, c)


def outline_rect(img: Image.Image, x: int, y: int, w: int, h: int, c: str = INK) -> None:
    for xx in range(x, x + w):
        px(img, xx, y, c)
        px(img, xx, y + h - 1, c)
    for yy in range(y, y + h):
        px(img, x, yy, c)
        px(img, x + w - 1, yy, c)


def shade_rect(img: Image.Image, x: int, y: int, w: int, h: int, base: str, hi: str | None = None, sh: str | None = None) -> None:
    hi = hi or lighten(base, 0.14)
    sh = sh or darken(base, 0.16)
    fill_rect(img, x, y, w, h, base)
    fill_rect(img, x, y, w, 1, hi)
    fill_rect(img, x, y, 1, h, hi)
    fill_rect(img, x, y + h - 1, w, 1, sh)
    fill_rect(img, x + w - 1, y, 1, h, sh)
    for i in range(max(1, (w * h) // 10)):
        rx = x + (i * 5 + 3) % max(1, w)
        ry = y + (i * 7 + 2) % max(1, h)
        px(img, rx, ry, sh if i % 3 == 0 else hi)


def save(img: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"wrote {path.relative_to(ROOT.parent)}")


def _biome_palette(biome: str) -> tuple[str, str, str, str]:
    if biome == "moss":
        return MOSS, MOSS2, MOSS3, GREEN2
    if biome == "copper":
        return COPPER, COPPER2, COPPER3, STONE2
    if biome == "echo":
        return DEEP, DEEP2, DEEP3, CRYSTAL
    return STONE, STONE2, STONE3, STONE2


def draw_player_side(pose: str) -> Image.Image:
    img = new_img(32, 48)
    body_y = 8
    if pose == "jump":
        body_y = 4
    if pose == "dodge":
        body_y = 14
    shade_rect(img, 10, body_y + 34, 5, 4, HAIR, darken(HAIR, 0.08), darken(HAIR, 0.2))
    shade_rect(img, 17, body_y + 34, 5, 4, HAIR, darken(HAIR, 0.08), darken(HAIR, 0.2))
    if pose == "run":
        shade_rect(img, 8, body_y + 34, 5, 4, HAIR)
        shade_rect(img, 19, body_y + 32, 5, 4, HAIR)
    shade_rect(img, 11, body_y + 24, 10, 11, CLOTH, CLOTH2, CLOTH3)
    fill_rect(img, 11, body_y + 24, 10, 2, CLOTH2)
    shade_rect(img, 10, body_y + 12, 12, 13, CLOTH, CLOTH2, CLOTH3)
    fill_rect(img, 11, body_y + 22, 10, 2, BRAND)
    shade_rect(img, 12, body_y + 2, 8, 8, SKIN, SKIN2, SKIN3)
    fill_rect(img, 12, body_y + 2, 8, 3, HAIR)
    px(img, 18, body_y + 6, INK)
    if pose in ("idle", "run", "jump"):
        shade_rect(img, 20, body_y + 14, 4, 8, SKIN2, SKIN, SKIN3)
        shade_rect(img, 22, body_y + 8, 3, 14, METAL, METAL2, METAL3)
        shade_rect(img, 21, body_y + 6, 5, 3, METAL2)
    elif pose in ("light", "light1"):
        shade_rect(img, 18, body_y + 12, 12, 4, SKIN2)
        shade_rect(img, 26, body_y + 10, 5, 14, METAL, METAL2, METAL3)
        shade_rect(img, 25, body_y + 8, 7, 3, METAL2)
        fill_rect(img, 28, body_y + 22, 3, 3, GOLD)
    elif pose == "light2":
        shade_rect(img, 16, body_y + 6, 8, 5, SKIN2)
        shade_rect(img, 22, body_y - 4, 4, 18, METAL, METAL2, METAL3)
        shade_rect(img, 20, body_y - 6, 8, 3, METAL2)
        fill_rect(img, 22, body_y + 12, 4, 3, GOLD)
        shade_rect(img, 20, body_y + 14, 3, 6, SKIN)
    elif pose == "light3":
        shade_rect(img, 14, body_y + 16, 10, 5, SKIN2)
        shade_rect(img, 22, body_y + 18, 8, 4, METAL, METAL2, METAL3)
        shade_rect(img, 28, body_y + 16, 4, 8, METAL2, METAL, METAL3)
        fill_rect(img, 30, body_y + 22, 3, 4, GOLD)
        shade_rect(img, 10, body_y + 30, 5, 4, HAIR)
        shade_rect(img, 17, body_y + 32, 5, 4, HAIR)
    elif pose == "heavy":
        shade_rect(img, 16, body_y + 6, 8, 5, SKIN2)
        shade_rect(img, 20, body_y - 2, 5, 18, METAL, METAL2, METAL3)
        shade_rect(img, 19, body_y - 4, 7, 3, GOLD)
    elif pose == "dodge":
        shade_rect(img, 8, body_y + 16, 6, 4, SKIN2)
        shade_rect(img, 6, body_y + 12, 3, 12, METAL, METAL2, METAL3)
    outline_rect(img, 10, body_y + 12, 12, 13, INK)
    outline_rect(img, 12, body_y + 2, 8, 8, INK)
    return img


def draw_dummy_side() -> Image.Image:
    img = new_img(32, 48)
    shade_rect(img, 12, 8, 8, 28, WOOD, WOOD3, WOOD2)
    shade_rect(img, 8, 36, 16, 6, WOOD2, WOOD, darken(WOOD2, 0.15))
    shade_rect(img, 10, 12, 12, 10, SHELL, lighten(SHELL), darken(SHELL))
    outline_rect(img, 12, 8, 8, 28, INK)
    outline_rect(img, 10, 12, 12, 10, INK)
    px(img, 14, 16, INK)
    px(img, 18, 16, INK)
    return img


def draw_enemy_side(biome: str, kind: str) -> Image.Image:
    img = new_img(32, 48)
    body, accent, shadow, hi = _biome_palette(biome)
    h = 36 if kind == "mob" else 40
    if kind == "boss":
        h = 44
        shade_rect(img, 6, 4, 20, h, body, hi, shadow)
        shade_rect(img, 8, 8, 16, 8, accent, lighten(accent), darken(accent))
        outline_rect(img, 6, 4, 20, h, INK)
    elif kind == "elite":
        shade_rect(img, 8, 6, 16, h, body, hi, shadow)
        shade_rect(img, 10, 10, 12, 6, accent)
        shade_rect(img, 20, 14, 6, 14, METAL, METAL2, METAL3)
        outline_rect(img, 8, 6, 16, h, INK)
    elif kind == "guard":
        shade_rect(img, 9, 8, 14, h - 2, body, hi, shadow)
        shade_rect(img, 11, 10, 10, 6, METAL2, METAL, METAL3)
        outline_rect(img, 9, 8, 14, h - 2, INK)
    else:
        shade_rect(img, 10, 12, 12, h - 8, body, hi, shadow)
        shade_rect(img, 12, 14, 8, 5, accent)
        outline_rect(img, 10, 12, 12, h - 8, INK)
    px(img, 18, 18, RED)
    shade_rect(img, 10, 40, 5, 4, INK)
    shade_rect(img, 17, 40, 5, 4, INK)
    return img


def draw_tile(kind: str, biome: str, variant: int = 0) -> Image.Image:
    img = new_img(32, 32)
    base, top, shadow, accent = _biome_palette(biome)
    if biome == "moss" and kind == "mud":
        base, top, shadow, accent = "#2A4A38", "#3A6A48", "#1A3028", GREEN3
    if kind == "fog":
        fill_rect(img, 0, 0, 32, 32, FOG)
        for i in range(0, 32, 6):
            fill_rect(img, i, 8 + (i % 5), 4, 2, FOG2)
        return img
    if kind == "wall":
        shade_rect(img, 0, 0, 32, 32, shadow, base, darken(shadow, 0.1))
        for y in range(4, 32, 8):
            fill_rect(img, 0, y, 32, 1, darken(base, 0.08))
        for x in (4, 16, 26):
            px(img, x, 10, accent)
        return img
    if kind == "platform":
        shade_rect(img, 0, 0, 32, 12, top, lighten(top), darken(top, 0.12))
        shade_rect(img, 0, 12, 32, 20, base, hi := lighten(base), shadow)
        outline_rect(img, 0, 0, 32, 12, INK)
        if variant % 2 == 1:
            px(img, 8, 4, accent)
            px(img, 22, 6, accent)
        return img
    if kind == "ground":
        shade_rect(img, 0, 0, 32, 10, top, lighten(top), darken(top, 0.1))
        shade_rect(img, 0, 10, 32, 22, base, lighten(base, 0.08), shadow)
        outline_rect(img, 0, 0, 32, 10, INK)
        cracks = [(6, 18), (14, 22), (24, 16)] if variant % 2 == 0 else [(10, 20), (20, 14)]
        for cx, cy in cracks:
            px(img, cx, cy, shadow)
            px(img, cx + 1, cy, darken(shadow, 0.08))
        if biome == "moss":
            for x in (4 + variant, 12, 20, 26):
                px(img, x % 28 + 2, 3, GREEN2)
        if biome == "copper":
            px(img, 8 + variant * 2, 16, COPPER2)
            px(img, 20, 20, COPPER3)
        if biome == "echo":
            px(img, 14, 18, CRYSTAL)
            px(img, 22, 14, CRYSTAL2)
        return img
    # legacy small bg tile
    shade_rect(img, 0, 0, 32, 32, base, top, shadow)
    for i in range(0, 32, 8):
        fill_rect(img, i, 0, 2, 32, top)
    return img


def draw_parallax(biome: str, layer: str) -> Image.Image:
    img = Image.new("RGBA", (160, 96), (0, 0, 0, 0))
    base, mid, shadow, accent = _biome_palette(biome)
    sky_top = darken(base, 0.35) if layer == "far" else darken(base, 0.25)
    sky_bot = darken(mid, 0.15)
    for y in range(96):
        t = y / 95.0
        r1, g1, b1, _ = hex_to_rgba(sky_top)
        r2, g2, b2, _ = hex_to_rgba(sky_bot)
        c = "#%02X%02X%02X" % (int(r1 + (r2 - r1) * t), int(g1 + (g2 - g1) * t), int(b1 + (b2 - b1) * t))
        fill_rect(img, 0, y, 160, 1, c)
    if layer == "far":
        for x, h in ((12, 52), (48, 68), (92, 44), (128, 58)):
            shade_rect(img, x, 96 - h, 14, h, shadow, darken(shadow, 0.05), darken(shadow, 0.2))
        if biome == "moss":
            for x in (30, 70, 110):
                fill_rect(img, x, 70, 6, 8, GREEN3)
        if biome == "copper":
            for x in (24, 80, 136):
                fill_rect(img, x, 60, 8, 3, COPPER2)
        if biome == "echo":
            for x in (20, 60, 100, 140):
                px(img, x, 50, CRYSTAL)
    else:
        for x, h in ((8, 36), (56, 48), (104, 32), (144, 40)):
            shade_rect(img, x, 96 - h, 10, h, mid, lighten(mid), shadow)
        fill_rect(img, 0, 82, 160, 14, darken(base, 0.08))
        if biome == "moss":
            fill_rect(img, 0, 86, 160, 6, MOSS3)
        if biome == "copper":
            fill_rect(img, 0, 86, 160, 6, STONE3)
        if biome == "echo":
            fill_rect(img, 0, 86, 160, 6, DEEP3)
    return img


def draw_prop(name: str) -> Image.Image:
    img = new_img(32, 48)
    if name == "extract":
        shade_rect(img, 8, 8, 16, 28, ALCH, ALCH2, ALCH3)
        shade_rect(img, 10, 12, 12, 8, ALCH2)
        fill_rect(img, 14, 10, 4, 4, GOLD)
        outline_rect(img, 8, 8, 16, 28, INK)
    elif name == "warp":
        shade_rect(img, 10, 6, 12, 30, MIND, MIND2, darken(MIND, 0.15))
        shade_rect(img, 12, 10, 8, 8, MIND2)
        outline_rect(img, 10, 6, 12, 30, INK)
    elif name == "gather":
        shade_rect(img, 8, 20, 16, 16, WOOD, WOOD3, WOOD2)
        shade_rect(img, 12, 12, 8, 10, GREEN, GREEN2, GREEN3)
        outline_rect(img, 8, 20, 16, 16, INK)
    elif name == "shortcut":
        shade_rect(img, 6, 10, 20, 24, CRYSTAL, CRYSTAL2, "#4A90B8")
        shade_rect(img, 10, 14, 12, 12, "#4A90B8")
        outline_rect(img, 6, 10, 20, 24, INK)
    elif name == "descent":
        shade_rect(img, 4, 8, 24, 32, "#2A2030", DEEP2, "#1A1020")
        shade_rect(img, 10, 16, 12, 16, DEEP2)
        outline_rect(img, 4, 8, 24, 32, INK)
    elif name == "winch":
        shade_rect(img, 6, 12, 20, 24, METAL, METAL2, METAL3)
        shade_rect(img, 10, 16, 12, 8, COPPER, COPPER2, COPPER3)
        outline_rect(img, 6, 12, 20, 24, INK)
    elif name == "spotlight":
        shade_rect(img, 12, 8, 8, 28, METAL, METAL2, METAL3)
        shade_rect(img, 8, 6, 16, 8, GOLD, lighten(GOLD), darken(GOLD))
        outline_rect(img, 12, 8, 8, 28, INK)
    else:
        shade_rect(img, 8, 8, 16, 28, STONE, STONE2, STONE3)
    return img


def draw_ui_icon(name: str) -> Image.Image:
    img = new_img(32, 32)
    if name == "erosion":
        shade_rect(img, 4, 8, 24, 16, "#3A2060", "#6B4C9A", "#2A1038")
        fill_rect(img, 8, 12, 16, 8, "#6B4C9A")
        outline_rect(img, 4, 8, 24, 16, INK)
    elif name == "rule_moss":
        shade_rect(img, 6, 6, 20, 20, MOSS, MOSS2, MOSS3)
        fill_rect(img, 10, 10, 12, 12, FOG)
    elif name == "rule_copper":
        shade_rect(img, 6, 6, 20, 20, COPPER, COPPER2, COPPER3)
        fill_rect(img, 10, 14, 12, 8, METAL)
    elif name == "rule_echo":
        shade_rect(img, 6, 6, 20, 20, DEEP, DEEP2, DEEP3)
        fill_rect(img, 10, 10, 12, 12, CRYSTAL)
    elif name == "map_node":
        shade_rect(img, 8, 8, 16, 16, STONE2, lighten(STONE2), STONE3)
        outline_rect(img, 8, 8, 16, 16, INK)
    elif name == "map_hidden":
        fill_rect(img, 8, 8, 16, 16, "#3A354880")
    else:
        shade_rect(img, 8, 8, 16, 16, BRAND)
    return img


def draw_hub_floor() -> Image.Image:
    img = new_img(32, 32)
    shade_rect(img, 0, 0, 32, 32, HUB_STONE3, HUB_STONE, HUB_STONE3)
    for ox, oy in ((1, 1), (17, 1), (1, 17), (17, 17)):
        shade_rect(img, ox, oy, 14, 14, HUB_STONE2, lighten(HUB_STONE2), HUB_STONE3)
    fill_rect(img, 0, 0, 32, 1, darken(HUB_STONE3, 0.05))
    fill_rect(img, 0, 16, 32, 1, darken(HUB_STONE3, 0.08))
    return img


def draw_hub_wall() -> Image.Image:
    img = new_img(32, 32)
    shade_rect(img, 0, 0, 32, 32, HUB_STONE3, HUB_WARM, darken(HUB_STONE3, 0.12))
    for y in range(0, 32, 8):
        fill_rect(img, 0, y, 32, 1, darken(HUB_STONE3, 0.06))
    for x in (6, 20):
        px(img, x, 12, ALCH3)
    return img


def draw_hub_board() -> Image.Image:
    img = new_img(32, 32)
    shade_rect(img, 8, 6, 16, 20, WOOD, WOOD3, WOOD2)
    shade_rect(img, 10, 8, 12, 14, PAPER, lighten(PAPER), darken(PAPER, 0.08))
    fill_rect(img, 12, 10, 8, 2, INK)
    fill_rect(img, 12, 14, 8, 2, INK)
    fill_rect(img, 12, 18, 6, 2, BRAND)
    shade_rect(img, 14, 26, 4, 4, WOOD2)
    outline_rect(img, 8, 6, 16, 20, INK)
    return img


def draw_hub_alchemy() -> Image.Image:
    img = new_img(32, 32)
    shade_rect(img, 6, 18, 20, 8, WOOD2, WOOD, darken(WOOD2, 0.12))
    shade_rect(img, 8, 14, 16, 6, WOOD, WOOD3, WOOD2)
    shade_rect(img, 10, 10, 5, 6, ALCH, ALCH2, ALCH3)
    shade_rect(img, 18, 8, 4, 8, COPPER, COPPER2, COPPER3)
    fill_rect(img, 12, 8, 3, 3, ALCH2)
    fill_rect(img, 20, 6, 2, 3, GOLD)
    return img


def draw_hub_quiet_door() -> Image.Image:
    img = new_img(32, 32)
    shade_rect(img, 8, 4, 16, 26, WOOD2, WOOD, darken(WOOD2, 0.15))
    shade_rect(img, 10, 6, 12, 20, WOOD, WOOD3, WOOD2)
    fill_rect(img, 14, 14, 4, 4, MIND)
    fill_rect(img, 15, 8, 2, 4, MIND2)
    fill_rect(img, 20, 16, 2, 3, GOLD)
    outline_rect(img, 8, 4, 16, 26, INK)
    return img


def draw_hub_pit_mouth() -> Image.Image:
    img = new_img(32, 32)
    shade_rect(img, 4, 10, 24, 18, HUB_STONE3, HUB_STONE, darken(HUB_STONE3, 0.2))
    fill_rect(img, 8, 14, 16, 10, "#1A1410")
    fill_rect(img, 10, 16, 12, 6, "#0A0806")
    shade_rect(img, 6, 8, 20, 4, HUB_WARM, lighten(HUB_WARM), HUB_STONE3)
    fill_rect(img, 14, 6, 4, 4, GOLD)
    outline_rect(img, 4, 10, 24, 18, INK)
    return img


def draw_archetype_enemy(kind: str) -> Image.Image:
    w, h = (40, 56) if kind == "boss" else (32, 48)
    img = new_img(w, h)
    ox = 4 if kind == "boss" else 0
    if kind == "melee":
        shade_rect(img, 10 + ox, 14, 12, 22, MOSS, MOSS2, MOSS3)
        shade_rect(img, 8 + ox, 36, 6, 6, METAL3, METAL, METAL2)
        shade_rect(img, 18 + ox, 36, 6, 6, METAL3, METAL, METAL2)
        fill_rect(img, 14 + ox, 10, 8, 4, GREEN2)
        shade_rect(img, 22 + ox, 18, 8, 4, METAL, METAL2, METAL3)
    elif kind == "ranged":
        shade_rect(img, 11 + ox, 16, 10, 20, COPPER, COPPER2, COPPER3)
        shade_rect(img, 8 + ox, 22, 6, 10, WOOD, WOOD3, WOOD2)
        fill_rect(img, 20 + ox, 20, 6, 6, GREEN)
        px(img, 24 + ox, 22, GREEN2)
    elif kind == "flyer":
        shade_rect(img, 12 + ox, 18, 8, 12, DEEP, CRYSTAL, DEEP3)
        fill_rect(img, 6 + ox, 20, 8, 3, CRYSTAL2)
        fill_rect(img, 18 + ox, 20, 8, 3, CRYSTAL2)
        fill_rect(img, 14 + ox, 12, 4, 4, GOLD)
    elif kind == "elite":
        shade_rect(img, 8 + ox, 10, 16, 26, MOSS, MOSS2, MOSS3)
        shade_rect(img, 10 + ox, 12, 12, 8, METAL2, METAL, METAL3)
        shade_rect(img, 20 + ox, 16, 6, 16, COPPER, COPPER2, COPPER3)
        fill_rect(img, 12 + ox, 8, 8, 4, GOLD)
    elif kind == "boss":
        shade_rect(img, 8, 8, 24, 36, DEEP, DEEP2, DEEP3)
        shade_rect(img, 10, 12, 20, 10, COPPER, COPPER2, COPPER3)
        fill_rect(img, 14, 6, 12, 6, GOLD)
        shade_rect(img, 6, 40, 8, 8, STONE3, STONE, STONE2)
        shade_rect(img, 26, 40, 8, 8, STONE3, STONE, STONE2)
    px(img, 18 + ox, 20, RED)
    outline_rect(img, 10 + ox, 14 if kind != "boss" else 8, 12 if kind != "boss" else 24, 22 if kind != "boss" else 36, INK)
    return img


def draw_projectile(kind: str) -> Image.Image:
    img = new_img(16, 16)
    if kind == "shock":
        fill_rect(img, 2, 6, 12, 4, CRYSTAL)
        fill_rect(img, 6, 2, 4, 12, CRYSTAL2)
    else:
        fill_rect(img, 4, 4, 8, 8, GREEN2)
        fill_rect(img, 6, 6, 4, 4, FOG)
    return img


def main() -> None:
    for pose in ("idle", "run", "jump", "light", "light1", "light2", "light3", "heavy", "dodge"):
        save(draw_player_side(pose), f"characters/player/side/player_{pose}.png")
    save(draw_dummy_side(), "enemies/side/dummy_post.png")
    for biome in ("moss", "copper", "echo"):
        for kind in ("mob", "elite", "guard"):
            save(draw_enemy_side(biome, kind), f"enemies/side/{biome}_{kind}.png")
        save(draw_parallax(biome, "far"), f"tiles/side/{biome}/bg_far.png")
        save(draw_parallax(biome, "mid"), f"tiles/side/{biome}/bg_mid.png")
        for tile in ("ground", "platform", "wall", "bg"):
            save(draw_tile(tile, biome), f"tiles/side/{biome}/{tile}.png")
        save(draw_tile("ground", biome, 1), f"tiles/side/{biome}/ground_b.png")
        if biome == "moss":
            save(draw_tile("mud", "moss"), "tiles/side/moss/mud.png")
            save(draw_tile("fog", "moss"), "tiles/side/moss/fog.png")
    save(draw_enemy_side("echo", "boss"), "enemies/side/floor_boss.png")
    for arch in ("melee", "ranged", "flyer", "elite", "boss"):
        save(draw_archetype_enemy(arch), f"enemies/side/side_{arch}.png")
    save(draw_projectile("spore"), "enemies/side/proj_spore.png")
    save(draw_projectile("shock"), "enemies/side/proj_shock.png")
    for prop in ("extract", "warp", "gather", "shortcut", "descent", "winch", "spotlight"):
        save(draw_prop(prop), f"props/side/{prop}.png")
    for icon in ("erosion", "rule_moss", "rule_copper", "rule_echo", "map_node", "map_hidden"):
        save(draw_ui_icon(icon), f"ui/side/{icon}.png")
    save(draw_hub_floor(), "tiles/hub/hub_floor.png")
    save(draw_hub_wall(), "tiles/hub/hub_wall.png")
    save(draw_hub_board(), "tiles/hub/hub_board.png")
    save(draw_hub_alchemy(), "tiles/hub/hub_alchemy.png")
    save(draw_hub_quiet_door(), "tiles/hub/hub_quiet_door.png")
    save(draw_hub_pit_mouth(), "tiles/hub/hub_pit_mouth.png")
    print("sideview art done")


if __name__ == "__main__":
    main()
