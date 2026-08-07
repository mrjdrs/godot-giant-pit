#!/usr/bin/env python3
"""Generate side-view pixel art for giant-pit Phase A–C."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets"

OUT = "#00000000"
INK = "#2A1F18"
SKIN = "#E8C090"
SKIN2 = "#C4A070"
CLOTH = "#5A6B4A"
CLOTH2 = "#4A5A3A"
HAIR = "#3A2A20"
BRAND = "#C45C2A"
METAL = "#8A9098"
METAL2 = "#B0B8C0"
WOOD = "#8B5A2B"
WOOD2 = "#6B4020"
GREEN = "#4A8B3A"
GREEN2 = "#6BB84A"
MOSS = "#3A6B4A"
MOSS2 = "#5A8B5A"
FOG = "#A8C0B8"
COPPER = "#B87333"
COPPER2 = "#D89850"
STONE = "#6B5344"
STONE2 = "#8B7355"
DEEP = "#3A3548"
DEEP2 = "#4A4560"
GOLD = "#E8A838"
RED = "#C42A2A"
CRYSTAL = "#7EC8E8"
SHELL = "#7A6A58"


def hex_to_rgba(c: str) -> tuple[int, int, int, int]:
    if c == OUT:
        return (0, 0, 0, 0)
    c = c.lstrip("#")
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


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


def save(img: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"wrote {path.relative_to(ROOT.parent)}")


def draw_player_side(pose: str) -> Image.Image:
    img = new_img(32, 48)
    # standing silhouette, origin near feet
    body_y = 8
    if pose == "jump":
        body_y = 4
    if pose == "dodge":
        body_y = 14
    # boots
    fill_rect(img, 10, body_y + 34, 5, 4, HAIR)
    fill_rect(img, 17, body_y + 34, 5, 4, HAIR)
    if pose == "run":
        fill_rect(img, 8, body_y + 34, 5, 4, HAIR)
        fill_rect(img, 19, body_y + 32, 5, 4, HAIR)
    # legs
    fill_rect(img, 11, body_y + 24, 10, 11, CLOTH)
    fill_rect(img, 11, body_y + 24, 10, 2, CLOTH2)
    # torso
    fill_rect(img, 10, body_y + 12, 12, 13, CLOTH)
    fill_rect(img, 11, body_y + 22, 10, 2, BRAND)
    # head
    fill_rect(img, 12, body_y + 2, 8, 8, SKIN)
    fill_rect(img, 12, body_y + 2, 8, 3, HAIR)
    px(img, 18, body_y + 6, INK)  # eye
    # arm + blade pose
    if pose in ("idle", "run", "jump"):
        fill_rect(img, 20, body_y + 14, 4, 8, SKIN2)
        fill_rect(img, 22, body_y + 8, 3, 14, METAL)
        fill_rect(img, 21, body_y + 6, 5, 3, METAL2)
    elif pose == "light":
        fill_rect(img, 18, body_y + 10, 10, 4, SKIN2)
        fill_rect(img, 24, body_y + 4, 4, 16, METAL)
        fill_rect(img, 23, body_y + 2, 6, 3, METAL2)
    elif pose == "heavy":
        fill_rect(img, 16, body_y + 6, 8, 5, SKIN2)
        fill_rect(img, 20, body_y - 2, 5, 18, METAL)
        fill_rect(img, 19, body_y - 4, 7, 3, GOLD)
    elif pose == "dodge":
        fill_rect(img, 8, body_y + 16, 6, 4, SKIN2)
        fill_rect(img, 6, body_y + 12, 3, 12, METAL)
    outline_rect(img, 10, body_y + 12, 12, 13, INK)
    outline_rect(img, 12, body_y + 2, 8, 8, INK)
    return img


def draw_dummy_side() -> Image.Image:
    img = new_img(32, 48)
    fill_rect(img, 12, 8, 8, 28, WOOD)
    fill_rect(img, 8, 36, 16, 6, WOOD2)
    fill_rect(img, 10, 12, 12, 10, SHELL)
    outline_rect(img, 12, 8, 8, 28, INK)
    outline_rect(img, 10, 12, 12, 10, INK)
    px(img, 14, 16, INK)
    px(img, 18, 16, INK)
    return img


def draw_enemy_side(biome: str, kind: str) -> Image.Image:
    img = new_img(32, 48)
    if biome == "moss":
        body, accent = MOSS, GREEN2
    elif biome == "copper":
        body, accent = COPPER, COPPER2
    elif biome == "echo":
        body, accent = DEEP, CRYSTAL
    else:
        body, accent = STONE, STONE2
    h = 36 if kind == "mob" else 40
    if kind == "boss":
        h = 44
        fill_rect(img, 6, 4, 20, h, body)
        fill_rect(img, 8, 8, 16, 8, accent)
        outline_rect(img, 6, 4, 20, h, INK)
    elif kind == "elite":
        fill_rect(img, 8, 6, 16, h, body)
        fill_rect(img, 10, 10, 12, 6, accent)
        fill_rect(img, 20, 14, 6, 14, METAL)
        outline_rect(img, 8, 6, 16, h, INK)
    elif kind == "guard":
        fill_rect(img, 9, 8, 14, h - 2, body)
        fill_rect(img, 11, 10, 10, 6, METAL2)
        outline_rect(img, 9, 8, 14, h - 2, INK)
    else:
        fill_rect(img, 10, 12, 12, h - 8, body)
        fill_rect(img, 12, 14, 8, 5, accent)
        outline_rect(img, 10, 12, 12, h - 8, INK)
    # eye
    px(img, 18, 18, RED)
    fill_rect(img, 10, 40, 5, 4, INK)
    fill_rect(img, 17, 40, 5, 4, INK)
    return img


def draw_tile(kind: str, biome: str) -> Image.Image:
    img = new_img(32, 32)
    if biome == "moss":
        base, top = MOSS, MOSS2
        if kind == "mud":
            base, top = "#2A4A38", "#3A6A48"
        if kind == "fog":
            fill_rect(img, 0, 0, 32, 32, FOG)
            return img
    elif biome == "copper":
        base, top = COPPER, STONE2
    elif biome == "echo":
        base, top = DEEP, DEEP2
    else:
        base, top = STONE, STONE2
    if kind == "bg":
        fill_rect(img, 0, 0, 32, 32, base)
        for i in range(0, 32, 8):
            fill_rect(img, i, 0, 2, 32, top)
    elif kind == "platform":
        fill_rect(img, 0, 0, 32, 12, top)
        fill_rect(img, 0, 12, 32, 20, base)
        outline_rect(img, 0, 0, 32, 12, INK)
    else:  # ground
        fill_rect(img, 0, 0, 32, 10, top)
        fill_rect(img, 0, 10, 32, 22, base)
        outline_rect(img, 0, 0, 32, 10, INK)
        if biome == "moss" and kind == "ground":
            for x in (4, 12, 20, 26):
                px(img, x, 3, GREEN2)
    return img


def draw_prop(name: str) -> Image.Image:
    img = new_img(32, 48)
    if name == "extract":
        fill_rect(img, 8, 8, 16, 28, ALCH := "#3D8B7A")
        fill_rect(img, 10, 12, 12, 8, "#5BB8A5")
        outline_rect(img, 8, 8, 16, 28, INK)
    elif name == "warp":
        fill_rect(img, 10, 6, 12, 30, MIND := "#6B4C9A")
        fill_rect(img, 12, 10, 8, 8, "#9B7BC8")
        outline_rect(img, 10, 6, 12, 30, INK)
    elif name == "gather":
        fill_rect(img, 8, 20, 16, 16, WOOD)
        fill_rect(img, 12, 12, 8, 10, GREEN)
        outline_rect(img, 8, 20, 16, 16, INK)
    elif name == "shortcut":
        fill_rect(img, 6, 10, 20, 24, CRYSTAL)
        fill_rect(img, 10, 14, 12, 12, "#4A90B8")
        outline_rect(img, 6, 10, 20, 24, INK)
    elif name == "descent":
        fill_rect(img, 4, 8, 24, 32, "#2A2030")
        fill_rect(img, 10, 16, 12, 16, DEEP2)
        outline_rect(img, 4, 8, 24, 32, INK)
    elif name == "winch":
        fill_rect(img, 6, 12, 20, 24, METAL)
        fill_rect(img, 10, 16, 12, 8, COPPER)
        outline_rect(img, 6, 12, 20, 24, INK)
    elif name == "spotlight":
        fill_rect(img, 12, 8, 8, 28, METAL)
        fill_rect(img, 8, 6, 16, 8, GOLD)
        outline_rect(img, 12, 8, 8, 28, INK)
    else:
        fill_rect(img, 8, 8, 16, 28, STONE)
    return img


def draw_ui_icon(name: str) -> Image.Image:
    img = new_img(32, 32)
    if name == "erosion":
        fill_rect(img, 4, 8, 24, 16, "#3A2060")
        fill_rect(img, 6, 10, 20, 12, "#6B4C9A")
        outline_rect(img, 4, 8, 24, 16, INK)
    elif name == "rule_moss":
        fill_rect(img, 6, 6, 20, 20, MOSS)
        fill_rect(img, 10, 10, 12, 12, FOG)
    elif name == "rule_copper":
        fill_rect(img, 6, 6, 20, 20, COPPER)
        fill_rect(img, 10, 14, 12, 8, METAL)
    elif name == "rule_echo":
        fill_rect(img, 6, 6, 20, 20, DEEP)
        fill_rect(img, 10, 10, 12, 12, CRYSTAL)
    elif name == "map_node":
        fill_rect(img, 8, 8, 16, 16, STONE2)
        outline_rect(img, 8, 8, 16, 16, INK)
    elif name == "map_hidden":
        fill_rect(img, 8, 8, 16, 16, "#3A354880")
    else:
        fill_rect(img, 8, 8, 16, 16, BRAND)
    return img


def main() -> None:
    for pose in ("idle", "run", "jump", "light", "heavy", "dodge"):
        save(draw_player_side(pose), f"characters/player/side/player_{pose}.png")
    save(draw_dummy_side(), "enemies/side/dummy_post.png")
    for biome in ("moss", "copper", "echo"):
        for kind in ("mob", "elite", "guard"):
            save(draw_enemy_side(biome, kind), f"enemies/side/{biome}_{kind}.png")
        for tile in ("ground", "platform", "bg", "mud" if biome == "moss" else "ground"):
            if tile == "mud" and biome != "moss":
                continue
            save(draw_tile(tile if tile != "mud" else "mud", biome), f"tiles/side/{biome}/{tile}.png")
        if biome == "moss":
            save(draw_tile("fog", "moss"), "tiles/side/moss/fog.png")
    save(draw_enemy_side("echo", "boss"), "enemies/side/floor_boss.png")
    for prop in ("extract", "warp", "gather", "shortcut", "descent", "winch", "spotlight"):
        save(draw_prop(prop), f"props/side/{prop}.png")
    for icon in ("erosion", "rule_moss", "rule_copper", "rule_echo", "map_node", "map_hidden"):
        save(draw_ui_icon(icon), f"ui/side/{icon}.png")
    print("sideview art done")


if __name__ == "__main__":
    main()
