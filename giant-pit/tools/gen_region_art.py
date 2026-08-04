#!/usr/bin/env python3
"""Generate v0.3 region art (32x32) for floor-1 three zones + boss."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets"

INK = "#2A1F18"
GOLD = "#E8A838"
BRAND = "#C45C2A"
MIND = "#6B4C9A"
MIND2 = "#9B7BC8"
ALCH = "#3D8B7A"
ALCH2 = "#5BB8A5"
METAL = "#8A9098"
SILVER = "#C0C8D0"
COPPER = "#B87333"
COPPER2 = "#D49040"
RUST = "#8A5030"
GREEN = "#3A6B3A"
GREEN2 = "#4A8B3A"
GREEN3 = "#6BB84A"
MOSS_Y = "#A0E060"
MIRE = "#5A4838"
MIRE2 = "#6B5848"
WATER = "#3A6A7A"
WATER2 = "#4A8AA0"
CORRIDOR = "#2A3540"
CORRIDOR2 = "#3A4550"
CORRIDOR3 = "#4A5560"
SHADOW = "#1A2028"
BOSS_S = "#3A2A48"
BOSS_S2 = "#4A3A58"
BOSS_S3 = "#5A4A68"
RED = "#C42A2A"
ORANGE = "#E87830"
STONE = "#6B5344"
STONE2 = "#8B7355"
HAIR = "#3A2A20"
SHELL = "#7A6A58"
SHELL2 = "#9A8A78"


def new_img() -> Image.Image:
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))


def hex_to_rgba(c: str) -> tuple[int, int, int, int]:
    c = c.lstrip("#")
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


def px(img: Image.Image, x: int, y: int, c: str) -> None:
    if 0 <= x < 32 and 0 <= y < 32:
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


def make_floor(base: str, alt: str, dots: list[tuple[int, int]], accent: str | None = None) -> Image.Image:
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, base)
    fill_rect(img, 0, 0, 16, 16, alt)
    fill_rect(img, 16, 16, 16, 16, alt)
    for x, y in dots:
        fill_rect(img, x, y, 2, 2, accent or base)
    return img


def make_wall(top: str, body: str, bottom: str) -> Image.Image:
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, body)
    fill_rect(img, 0, 0, 32, 8, top)
    fill_rect(img, 2, 10, 12, 10, bottom)
    fill_rect(img, 18, 12, 12, 10, bottom)
    fill_rect(img, 4, 22, 24, 8, top)
    return img


def make_wall_corner(top: str, body: str) -> Image.Image:
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, body)
    fill_rect(img, 0, 0, 16, 32, top)
    fill_rect(img, 0, 0, 32, 16, top)
    fill_rect(img, 16, 16, 14, 14, body)
    return img


# --- Tiles ---

def gen_tiles_a() -> None:
    specs = [
        ("tile_a_floor_01.png", MIRE2, MIRE, [(4, 4), (20, 6), (8, 22), (24, 24)], GREEN),
        ("tile_a_floor_02.png", MIRE2, GREEN, [(6, 8), (18, 4), (10, 18), (22, 20)], GREEN2),
        ("tile_a_floor_03.png", GREEN, MIRE2, [(2, 2), (28, 4), (4, 28), (26, 26)], MOSS_Y),
        ("tile_a_floor_04.png", MIRE, GREEN2, [(8, 6), (22, 10), (6, 20), (20, 22)], GREEN3),
    ]
    for name, base, alt, dots, acc in specs:
        save(make_floor(base, alt, dots, acc), f"tiles/region_a/{name}")

    img = make_floor(MIRE2, WATER, [(8, 8), (20, 12), (12, 20)], WATER2)
    fill_rect(img, 10, 14, 12, 6, WATER2)
    save(img, "tiles/region_a/tile_a_water.png")

    img = make_floor(GREEN, GREEN2, [(4, 4), (16, 8), (8, 18), (22, 22)], MOSS_Y)
    fill_rect(img, 12, 10, 8, 8, GREEN3)
    fill_rect(img, 14, 12, 4, 4, MOSS_Y)
    save(img, "tiles/region_a/tile_a_moss.png")

    save(make_wall(HAIR, GREEN, MIRE), "tiles/region_a/tile_a_wall.png")
    save(make_wall_corner(HAIR, GREEN), "tiles/region_a/tile_a_wall_corner.png")


def gen_tiles_b() -> None:
    specs = [
        ("tile_b_floor_01.png", STONE2, STONE, [(4, 4), (20, 6), (8, 22), (24, 24)], COPPER),
        ("tile_b_floor_02.png", STONE2, RUST, [(6, 8), (18, 4), (10, 18), (22, 20)], COPPER2),
        ("tile_b_floor_03.png", STONE, STONE2, [(2, 2), (28, 4), (4, 28), (26, 26)], ALCH),
        ("tile_b_floor_04.png", RUST, STONE2, [(8, 6), (22, 10), (6, 20), (20, 22)], COPPER),
    ]
    for name, base, alt, dots, acc in specs:
        save(make_floor(base, alt, dots, acc), f"tiles/region_b/{name}")

    img = make_floor(STONE2, STONE, [(4, 4), (24, 24)], COPPER)
    fill_rect(img, 10, 0, 3, 32, COPPER)
    fill_rect(img, 0, 14, 32, 2, COPPER2)
    fill_rect(img, 18, 8, 2, 16, RED)
    save(img, "tiles/region_b/tile_b_vein.png")

    img = make_floor(STONE2, METAL, [(6, 6), (20, 10), (10, 22)], ALCH)
    fill_rect(img, 12, 12, 8, 4, COPPER)
    fill_rect(img, 14, 18, 4, 4, ALCH2)
    save(img, "tiles/region_b/tile_b_scrap.png")

    save(make_wall(HAIR, RUST, STONE), "tiles/region_b/tile_b_wall.png")
    save(make_wall_corner(HAIR, RUST), "tiles/region_b/tile_b_wall_corner.png")


def gen_tiles_c() -> None:
    specs = [
        ("tile_c_floor_01.png", CORRIDOR2, CORRIDOR, [(4, 4), (20, 6), (8, 22), (24, 24)], GOLD),
        ("tile_c_floor_02.png", CORRIDOR2, CORRIDOR3, [(6, 8), (18, 4), (10, 18), (22, 20)], MIND),
        ("tile_c_floor_03.png", CORRIDOR, CORRIDOR2, [(2, 2), (28, 4), (4, 28), (26, 26)], GOLD),
        ("tile_c_floor_04.png", CORRIDOR3, CORRIDOR, [(8, 6), (22, 10), (6, 20), (20, 22)], MIND2),
    ]
    for name, base, alt, dots, acc in specs:
        save(make_floor(base, alt, dots, acc), f"tiles/region_c/{name}")

    img = make_floor(CORRIDOR2, CORRIDOR, [(8, 8), (20, 20)], GOLD)
    fill_rect(img, 14, 6, 4, 20, GOLD)
    fill_rect(img, 12, 12, 8, 4, "#FFF0A0")
    save(img, "tiles/region_c/tile_c_lamp.png")

    img = make_floor(CORRIDOR, SHADOW, [(4, 4), (24, 24)], MIND)
    fill_rect(img, 0, 14, 32, 4, SHADOW)
    fill_rect(img, 14, 0, 4, 32, SHADOW)
    save(img, "tiles/region_c/tile_c_shadow.png")

    save(make_wall(SHADOW, CORRIDOR2, CORRIDOR), "tiles/region_c/tile_c_wall.png")
    save(make_wall_corner(SHADOW, CORRIDOR2), "tiles/region_c/tile_c_wall_corner.png")


def gen_tiles_boss() -> None:
    save(make_floor(BOSS_S2, BOSS_S, [(4, 4), (20, 8), (10, 22), (24, 24)], GOLD), "tiles/region_boss/tile_boss_floor_01.png")
    save(make_floor(BOSS_S2, BOSS_S3, [(6, 6), (18, 10), (8, 20), (22, 22)], BRAND), "tiles/region_boss/tile_boss_floor_02.png")

    img = make_floor(BOSS_S2, BOSS_S, [(8, 8)], BRAND)
    fill_rect(img, 14, 2, 4, 28, INK)
    fill_rect(img, 4, 14, 24, 3, INK)
    fill_rect(img, 16, 16, 6, 2, GOLD)
    save(img, "tiles/region_boss/tile_boss_crack.png")

    save(make_wall(INK, BOSS_S, BOSS_S3), "tiles/region_boss/tile_boss_wall.png")


def gen_shared() -> None:
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, STONE2)
    fill_rect(img, 0, 0, 10, 32, GREEN)
    fill_rect(img, 22, 0, 10, 32, CORRIDOR2)
    fill_rect(img, 10, 0, 4, 32, COPPER)
    fill_rect(img, 18, 0, 4, 32, GOLD)
    fill_rect(img, 0, 14, 32, 2, HAIR)
    save(img, "tiles/shared/tile_border.png")


# --- Props ---

def gen_warp() -> None:
    # inactive
    img = new_img()
    fill_rect(img, 8, 18, 16, 8, METAL)
    fill_rect(img, 10, 10, 12, 10, STONE)
    fill_rect(img, 12, 8, 8, 4, HAIR)
    fill_rect(img, 14, 12, 4, 6, "#4A4840")
    fill_rect(img, 15, 14, 2, 2, INK)
    outline_rect(img, 10, 10, 12, 10)
    save(img, "props/warp/prop_warp_inactive.png")

    # active
    img = new_img()
    fill_rect(img, 8, 18, 16, 8, ALCH)
    fill_rect(img, 10, 10, 12, 10, ALCH2)
    fill_rect(img, 12, 6, 8, 6, GOLD)
    fill_rect(img, 14, 4, 4, 4, "#FFF0A0")
    fill_rect(img, 14, 14, 4, 4, MIND2)
    fill_rect(img, 15, 12, 2, 8, MIND)
    outline_rect(img, 10, 10, 12, 10, GOLD)
    save(img, "props/warp/prop_warp_active.png")

    for key, color, name in [("a", GREEN3, "prop_warp_flag_a"), ("b", COPPER2, "prop_warp_flag_b"), ("c", GOLD, "prop_warp_flag_c")]:
        img = new_img()
        fill_rect(img, 8, 18, 16, 8, METAL)
        fill_rect(img, 10, 10, 12, 10, ALCH2)
        fill_rect(img, 12, 6, 8, 6, GOLD)
        outline_rect(img, 8, 8, 16, 16, color)
        fill_rect(img, 14, 4, 4, 3, color)
        save(img, f"props/warp/{name}.png")


def gen_extract_descent_boss() -> None:
    img = new_img()
    fill_rect(img, 14, 6, 4, 18, METAL)
    fill_rect(img, 12, 4, 8, 5, ALCH2)
    fill_rect(img, 13, 2, 6, 3, GOLD)
    fill_rect(img, 10, 24, 12, 4, STONE)
    fill_rect(img, 15, 10, 2, 6, ALCH)
    outline_rect(img, 12, 4, 8, 5, GOLD)
    save(img, "props/extract/prop_extract.png")

    img = new_img()
    fill_rect(img, 14, 6, 4, 16, METAL)
    fill_rect(img, 12, 4, 8, 5, BRAND)
    fill_rect(img, 13, 2, 6, 3, ORANGE)
    fill_rect(img, 10, 22, 12, 4, STONE)
    fill_rect(img, 15, 12, 2, 2, GOLD)
    fill_rect(img, 15, 16, 2, 2, GOLD)
    save(img, "props/extract/prop_distress.png")

    img = new_img()
    fill_rect(img, 6, 6, 20, 20, "#4A4848")
    fill_rect(img, 10, 10, 12, 12, "#2A2A30")
    fill_rect(img, 12, 12, 8, 8, "#1A1A20")
    fill_rect(img, 14, 8, 4, 2, "#606068")
    fill_rect(img, 14, 22, 4, 2, "#606068")
    fill_rect(img, 8, 14, 2, 4, "#606068")
    fill_rect(img, 22, 14, 2, 4, "#606068")
    outline_rect(img, 6, 6, 20, 20, "#707078")
    save(img, "props/descent/prop_descent_locked.png")

    img = new_img()
    fill_rect(img, 6, 18, 20, 8, BOSS_S)
    fill_rect(img, 8, 12, 16, 8, BOSS_S2)
    fill_rect(img, 12, 8, 8, 6, BOSS_S3)
    fill_rect(img, 14, 6, 4, 4, GOLD)
    fill_rect(img, 10, 14, 12, 2, BRAND)
    fill_rect(img, 15, 16, 2, 4, MIND2)
    outline_rect(img, 8, 12, 16, 8, GOLD)
    save(img, "props/boss/prop_boss_altar.png")


def gen_gather() -> None:
    # ore A moss/red
    img = new_img()
    fill_rect(img, 8, 14, 16, 12, MIRE)
    fill_rect(img, 10, 10, 12, 8, GREEN)
    fill_rect(img, 12, 12, 4, 6, GREEN3)
    fill_rect(img, 18, 14, 3, 5, MOSS_Y)
    fill_rect(img, 14, 8, 4, 4, RED)
    save(img, "props/gather/prop_ore_a.png")

    img = new_img()
    fill_rect(img, 8, 14, 16, 12, STONE)
    fill_rect(img, 10, 10, 12, 8, STONE2)
    fill_rect(img, 12, 12, 4, 6, COPPER)
    fill_rect(img, 18, 14, 3, 5, COPPER2)
    fill_rect(img, 14, 8, 4, 4, RED)
    save(img, "props/gather/prop_ore_b.png")

    img = new_img()
    fill_rect(img, 8, 14, 16, 12, CORRIDOR)
    fill_rect(img, 10, 10, 12, 8, CORRIDOR2)
    fill_rect(img, 12, 12, 4, 6, GOLD)
    fill_rect(img, 18, 14, 3, 5, MIND2)
    fill_rect(img, 14, 8, 4, 4, "#FFF0A0")
    save(img, "props/gather/prop_ore_c.png")

    img = new_img()
    fill_rect(img, 10, 18, 12, 8, GREEN)
    fill_rect(img, 12, 12, 8, 8, GREEN2)
    fill_rect(img, 14, 8, 4, 6, MOSS_Y)
    fill_rect(img, 8, 20, 3, 4, MIRE)
    save(img, "props/gather/prop_forage_a.png")

    img = new_img()
    fill_rect(img, 10, 18, 12, 8, RUST)
    fill_rect(img, 12, 12, 8, 8, COPPER)
    fill_rect(img, 14, 8, 4, 6, COPPER2)
    fill_rect(img, 8, 20, 3, 4, STONE)
    save(img, "props/gather/prop_forage_b.png")

    img = new_img()
    fill_rect(img, 10, 18, 12, 8, CORRIDOR2)
    fill_rect(img, 12, 12, 8, 8, MIND)
    fill_rect(img, 14, 8, 4, 6, GOLD)
    fill_rect(img, 8, 20, 3, 4, CORRIDOR)
    save(img, "props/gather/prop_forage_c.png")


# --- Enemies ---

def gen_enemies_a() -> None:
    # moss grub
    img = new_img()
    fill_rect(img, 8, 18, 16, 8, GREEN)
    fill_rect(img, 10, 14, 12, 6, GREEN2)
    fill_rect(img, 12, 11, 8, 5, GREEN3)
    fill_rect(img, 14, 9, 4, 3, MOSS_Y)
    for x in (10, 14, 18):
        fill_rect(img, x, 20, 1, 5, MIRE)
    fill_rect(img, 13, 12, 2, 2, INK)
    fill_rect(img, 17, 12, 2, 2, INK)
    outline_rect(img, 8, 18, 16, 8)
    save(img, "enemies/region_a/enemy_a_moss_grub.png")

    # spore spitter
    img = new_img()
    fill_rect(img, 10, 14, 12, 12, GREEN)
    fill_rect(img, 12, 12, 8, 4, GREEN2)
    fill_rect(img, 11, 26, 3, 4, MIRE)
    fill_rect(img, 18, 26, 3, 4, MIRE)
    fill_rect(img, 8, 16, 3, 4, MIND2)
    fill_rect(img, 21, 16, 3, 4, MIND2)
    fill_rect(img, 14, 8, 4, 5, MOSS_Y)
    fill_rect(img, 13, 18, 2, 2, INK)
    fill_rect(img, 17, 18, 2, 2, INK)
    outline_rect(img, 10, 14, 12, 12)
    save(img, "enemies/region_a/enemy_a_spore_spitter.png")

    # scale rock
    img = new_img()
    fill_rect(img, 8, 22, 6, 6, STONE)
    fill_rect(img, 18, 22, 6, 6, STONE)
    fill_rect(img, 6, 12, 20, 14, SHELL)
    fill_rect(img, 8, 10, 16, 6, SHELL2)
    fill_rect(img, 10, 8, 12, 4, MIRE)
    fill_rect(img, 10, 14, 4, 3, GREEN3)
    fill_rect(img, 16, 16, 5, 3, GREEN2)
    fill_rect(img, 11, 11, 3, 2, BRAND)
    fill_rect(img, 18, 11, 3, 2, BRAND)
    fill_rect(img, 14, 20, 4, 2, INK)
    outline_rect(img, 6, 12, 20, 14)
    save(img, "enemies/region_a/enemy_a_scale_rock.png")


def gen_enemies_b() -> None:
    # copper mite
    img = new_img()
    fill_rect(img, 10, 16, 12, 10, COPPER)
    fill_rect(img, 12, 12, 8, 6, COPPER2)
    fill_rect(img, 8, 20, 3, 6, RUST)
    fill_rect(img, 21, 20, 3, 6, RUST)
    fill_rect(img, 14, 10, 4, 4, METAL)
    fill_rect(img, 13, 14, 2, 2, INK)
    fill_rect(img, 17, 14, 2, 2, INK)
    outline_rect(img, 10, 16, 12, 10)
    save(img, "enemies/region_b/enemy_b_copper_mite.png")

    # slag spitter
    img = new_img()
    fill_rect(img, 10, 14, 12, 12, "#5A6860")
    fill_rect(img, 12, 12, 8, 4, ALCH)
    fill_rect(img, 11, 26, 3, 4, STONE)
    fill_rect(img, 18, 26, 3, 4, STONE)
    fill_rect(img, 8, 16, 3, 4, COPPER)
    fill_rect(img, 21, 16, 3, 4, ORANGE)
    fill_rect(img, 14, 8, 4, 5, COPPER2)
    fill_rect(img, 13, 18, 2, 2, INK)
    fill_rect(img, 17, 18, 2, 2, INK)
    outline_rect(img, 10, 14, 12, 12)
    save(img, "enemies/region_b/enemy_b_slag_spitter.png")

    # rust beetle
    img = new_img()
    fill_rect(img, 8, 16, 16, 10, RUST)
    fill_rect(img, 10, 12, 12, 8, COPPER)
    fill_rect(img, 12, 10, 8, 6, METAL)
    fill_rect(img, 14, 8, 4, 4, SILVER)
    for x in (7, 11, 19, 23):
        fill_rect(img, x, 24, 2, 5, STONE)
    fill_rect(img, 12, 18, 2, 2, INK)
    fill_rect(img, 18, 18, 2, 2, INK)
    outline_rect(img, 8, 16, 16, 10)
    save(img, "enemies/region_b/enemy_b_rust_beetle.png")


def gen_enemies_c() -> None:
    # lamp wisp
    img = new_img()
    fill_rect(img, 12, 12, 8, 8, GOLD)
    fill_rect(img, 14, 14, 4, 4, "#FFF0A0")
    fill_rect(img, 10, 8, 3, 5, ORANGE)
    fill_rect(img, 19, 9, 3, 4, MIND2)
    fill_rect(img, 8, 16, 3, 4, GOLD)
    fill_rect(img, 21, 15, 3, 5, MIND)
    fill_rect(img, 14, 6, 4, 3, GOLD)
    outline_rect(img, 12, 12, 8, 8, CORRIDOR)
    save(img, "enemies/region_c/enemy_c_lamp_wisp.png")

    # shade grub
    img = new_img()
    fill_rect(img, 8, 18, 16, 8, CORRIDOR)
    fill_rect(img, 10, 14, 12, 6, CORRIDOR2)
    fill_rect(img, 12, 11, 8, 5, CORRIDOR3)
    fill_rect(img, 14, 9, 4, 3, SHADOW)
    for x in (10, 14, 18):
        fill_rect(img, x, 20, 1, 5, SHADOW)
    fill_rect(img, 13, 12, 2, 2, GOLD)
    fill_rect(img, 17, 12, 2, 2, GOLD)
    outline_rect(img, 8, 18, 16, 8)
    save(img, "enemies/region_c/enemy_c_shade_grub.png")

    # lantern shell
    img = new_img()
    fill_rect(img, 8, 16, 16, 10, CORRIDOR2)
    fill_rect(img, 10, 12, 12, 8, METAL)
    fill_rect(img, 12, 10, 8, 6, GOLD)
    fill_rect(img, 14, 8, 4, 4, "#FFF0A0")
    for x in (7, 11, 19, 23):
        fill_rect(img, x, 24, 2, 5, CORRIDOR)
    fill_rect(img, 12, 18, 2, 2, INK)
    fill_rect(img, 18, 18, 2, 2, INK)
    outline_rect(img, 8, 16, 16, 10, GOLD)
    save(img, "enemies/region_c/enemy_c_lantern_shell.png")


def gen_elites() -> None:
    # mire lord — large moss mass
    img = new_img()
    fill_rect(img, 6, 14, 20, 14, GREEN)
    fill_rect(img, 8, 10, 16, 10, GREEN2)
    fill_rect(img, 10, 6, 12, 8, GREEN3)
    fill_rect(img, 12, 4, 8, 4, MOSS_Y)
    fill_rect(img, 4, 18, 4, 8, MIRE)
    fill_rect(img, 24, 18, 4, 8, MIRE)
    fill_rect(img, 12, 14, 3, 3, INK)
    fill_rect(img, 18, 14, 3, 3, INK)
    fill_rect(img, 14, 20, 4, 3, WATER2)
    outline_rect(img, 6, 14, 20, 14)
    save(img, "enemies/elites/elite_a_mire_lord.png")

    # copper warden — golem-like
    img = new_img()
    fill_rect(img, 8, 14, 16, 14, COPPER)
    fill_rect(img, 10, 10, 12, 8, COPPER2)
    fill_rect(img, 12, 6, 8, 6, METAL)
    fill_rect(img, 8, 18, 16, 2, ALCH)
    fill_rect(img, 15, 10, 2, 18, ALCH2)
    fill_rect(img, 4, 16, 4, 8, RUST)
    fill_rect(img, 24, 16, 4, 8, RUST)
    fill_rect(img, 13, 12, 2, 2, GOLD)
    fill_rect(img, 17, 12, 2, 2, GOLD)
    outline_rect(img, 8, 14, 16, 14)
    save(img, "enemies/elites/elite_b_copper_warden.png")

    # blind keeper — lantern figure
    img = new_img()
    fill_rect(img, 10, 16, 12, 12, CORRIDOR2)
    fill_rect(img, 11, 10, 10, 8, CORRIDOR3)
    fill_rect(img, 12, 6, 8, 6, METAL)
    fill_rect(img, 14, 2, 4, 6, GOLD)
    fill_rect(img, 15, 0, 2, 3, "#FFF0A0")
    fill_rect(img, 8, 14, 3, 10, MIND)
    fill_rect(img, 21, 14, 3, 10, MIND)
    fill_rect(img, 13, 12, 2, 2, GOLD)
    fill_rect(img, 17, 12, 2, 2, GOLD)
    outline_rect(img, 10, 16, 12, 12, GOLD)
    save(img, "enemies/elites/elite_c_blind_keeper.png")


def gen_guards() -> None:
    # A swamp heart guardian — toad-like stone
    img = new_img()
    fill_rect(img, 8, 14, 16, 14, GREEN2)
    fill_rect(img, 10, 10, 12, 8, ALCH)
    fill_rect(img, 12, 8, 8, 4, MIND2)
    fill_rect(img, 14, 6, 4, 3, GOLD)
    fill_rect(img, 6, 20, 4, 6, MIRE)
    fill_rect(img, 22, 20, 4, 6, MIRE)
    fill_rect(img, 12, 14, 3, 2, INK)
    fill_rect(img, 17, 14, 3, 2, INK)
    fill_rect(img, 14, 18, 4, 2, ALCH2)
    outline_rect(img, 8, 14, 16, 14, GOLD)
    save(img, "enemies/guards/guard_a_warp.png")

    # B copper heart
    img = new_img()
    fill_rect(img, 8, 14, 16, 14, COPPER)
    fill_rect(img, 10, 10, 12, 8, METAL)
    fill_rect(img, 12, 8, 8, 4, COPPER2)
    fill_rect(img, 14, 6, 4, 3, GOLD)
    fill_rect(img, 6, 18, 4, 8, RUST)
    fill_rect(img, 22, 18, 4, 8, RUST)
    fill_rect(img, 13, 14, 2, 2, ALCH2)
    fill_rect(img, 17, 14, 2, 2, ALCH2)
    fill_rect(img, 14, 18, 4, 3, GOLD)
    outline_rect(img, 8, 14, 16, 14, GOLD)
    save(img, "enemies/guards/guard_b_warp.png")

    # C corridor heart
    img = new_img()
    fill_rect(img, 8, 14, 16, 14, CORRIDOR2)
    fill_rect(img, 10, 10, 12, 8, MIND)
    fill_rect(img, 12, 8, 8, 4, GOLD)
    fill_rect(img, 14, 4, 4, 5, "#FFF0A0")
    fill_rect(img, 6, 18, 4, 8, CORRIDOR)
    fill_rect(img, 22, 18, 4, 8, CORRIDOR)
    fill_rect(img, 13, 14, 2, 2, INK)
    fill_rect(img, 17, 14, 2, 2, INK)
    fill_rect(img, 14, 18, 4, 3, MIND2)
    outline_rect(img, 8, 14, 16, 14, GOLD)
    save(img, "enemies/guards/guard_c_warp.png")


def gen_boss() -> None:
    img = new_img()
    # crowned beast — dense silhouette
    fill_rect(img, 6, 16, 20, 14, BOSS_S)
    fill_rect(img, 8, 12, 16, 10, BOSS_S2)
    fill_rect(img, 10, 8, 12, 8, BOSS_S3)
    # crown
    fill_rect(img, 12, 2, 8, 6, GOLD)
    fill_rect(img, 11, 4, 2, 4, BRAND)
    fill_rect(img, 19, 4, 2, 4, BRAND)
    fill_rect(img, 15, 0, 2, 4, "#FFF0A0")
    # eyes / maw
    fill_rect(img, 12, 12, 3, 3, RED)
    fill_rect(img, 17, 12, 3, 3, RED)
    fill_rect(img, 14, 18, 4, 3, INK)
    # claws
    fill_rect(img, 2, 20, 5, 6, BOSS_S3)
    fill_rect(img, 25, 20, 5, 6, BOSS_S3)
    fill_rect(img, 4, 26, 2, 4, GOLD)
    fill_rect(img, 26, 26, 2, 4, GOLD)
    # chest rune
    fill_rect(img, 14, 16, 4, 4, MIND2)
    outline_rect(img, 6, 16, 20, 14, GOLD)
    save(img, "enemies/bosses/boss_floor1_pit_crown.png")


# --- Materials delta ---

def gen_materials() -> None:
    img = new_img()
    fill_rect(img, 12, 12, 8, 8, WATER2)
    fill_rect(img, 14, 10, 4, 12, ALCH2)
    fill_rect(img, 15, 14, 2, 4, "#C8F0E8")
    outline_rect(img, 12, 12, 8, 8, GREEN3)
    save(img, "materials/mat_mire_pearl.png")

    img = new_img()
    fill_rect(img, 10, 14, 12, 8, COPPER)
    fill_rect(img, 12, 10, 8, 8, COPPER2)
    fill_rect(img, 14, 8, 4, 4, GOLD)
    fill_rect(img, 11, 18, 10, 2, METAL)
    outline_rect(img, 10, 14, 12, 8)
    save(img, "materials/mat_fold_copper.png")

    img = new_img()
    fill_rect(img, 12, 10, 8, 14, GOLD)
    fill_rect(img, 14, 8, 4, 4, "#FFF0A0")
    fill_rect(img, 13, 14, 6, 6, ORANGE)
    fill_rect(img, 15, 16, 2, 4, BRAND)
    outline_rect(img, 12, 10, 8, 14, CORRIDOR)
    save(img, "materials/mat_lamp_oil_crystal.png")

    img = new_img()
    fill_rect(img, 14, 6, 4, 20, CORRIDOR2)
    fill_rect(img, 12, 8, 8, 6, MIND)
    fill_rect(img, 13, 18, 6, 6, HAIR)
    fill_rect(img, 15, 4, 2, 4, GOLD)
    save(img, "materials/mat_blind_wick.png")

    # special mind key
    img = new_img()
    fill_rect(img, 10, 10, 12, 12, MIND)
    fill_rect(img, 12, 8, 8, 16, MIND2)
    fill_rect(img, 14, 6, 4, 4, GOLD)
    fill_rect(img, 15, 4, 2, 3, "#FFF0A0")
    fill_rect(img, 14, 14, 4, 4, BRAND)
    fill_rect(img, 8, 14, 3, 4, GOLD)
    fill_rect(img, 21, 14, 3, 4, GOLD)
    outline_rect(img, 10, 10, 12, 12, GOLD)
    save(img, "materials/item_special_mind_floor1.png")


def main() -> None:
    gen_tiles_a()
    gen_tiles_b()
    gen_tiles_c()
    gen_tiles_boss()
    gen_shared()
    gen_warp()
    gen_extract_descent_boss()
    gen_gather()
    gen_enemies_a()
    gen_enemies_b()
    gen_enemies_c()
    gen_elites()
    gen_guards()
    gen_boss()
    gen_materials()
    print("done")


if __name__ == "__main__":
    main()
