#!/usr/bin/env python3
"""Generate MVP 32x32 cartoon-pixel PNGs for giant-pit."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets"

# Palette
OUT = "#00000000"
INK = "#2A1F18"
STONE = "#6B5344"
STONE2 = "#8B7355"
STONE3 = "#A89070"
STONE_D = "#5A4038"
ALCH = "#3D8B7A"
ALCH2 = "#5BB8A5"
MIND = "#6B4C9A"
MIND2 = "#9B7BC8"
BRAND = "#C45C2A"
GOLD = "#E8A838"
SKIN = "#E8C090"
SKIN2 = "#C4A070"
CLOTH = "#5A6B4A"
CLOTH2 = "#4A5A3A"
HAIR = "#3A2A20"
METAL = "#8A9098"
RED = "#C42A2A"
RED2 = "#E84838"
RED3 = "#A82020"
COPPER = "#B87333"
SILVER = "#C0C8D0"
SHELL = "#7A6A58"
SHELL2 = "#9A8A78"
GREEN = "#4A8B3A"
GREEN2 = "#6BB84A"
PURPLE_D = "#3A2060"
DEEP = "#3A3548"
DEEP2 = "#4A4560"
CRYSTAL = "#7EC8E8"
CRYSTAL2 = "#4A90B8"
WOOD = "#8B5A2B"
WOOD2 = "#6B4020"
PAPER = "#E8D8B0"
ORANGE = "#E87830"


def new_img() -> Image.Image:
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))


def hex_to_rgba(c: str) -> tuple[int, int, int, int]:
    if c == OUT:
        return (0, 0, 0, 0)
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


# --- Characters ---

def draw_player() -> None:
    img = new_img()
    # boots
    fill_rect(img, 10, 28, 4, 3, HAIR)
    fill_rect(img, 18, 28, 4, 3, HAIR)
    # legs / tunic
    fill_rect(img, 10, 20, 12, 9, CLOTH)
    fill_rect(img, 10, 20, 12, 2, CLOTH2)
    # belt
    fill_rect(img, 11, 19, 10, 2, BRAND)
    # torso / arms
    fill_rect(img, 9, 14, 14, 6, SKIN2)
    fill_rect(img, 11, 13, 10, 3, CLOTH)
    # head
    fill_rect(img, 11, 7, 10, 7, SKIN)
    fill_rect(img, 11, 5, 10, 3, HAIR)
    # eyes
    fill_rect(img, 13, 10, 2, 2, INK)
    fill_rect(img, 17, 10, 2, 2, INK)
    # blade on back/side
    fill_rect(img, 23, 8, 3, 16, METAL)
    fill_rect(img, 23, 6, 3, 3, BRAND)
    fill_rect(img, 24, 24, 2, 4, GOLD)
    outline_rect(img, 11, 7, 10, 7)
    save(img, "characters/player/player_explorer.png")


def draw_blade() -> None:
    img = new_img()
    fill_rect(img, 14, 4, 4, 20, METAL)
    fill_rect(img, 15, 5, 2, 16, SILVER)
    fill_rect(img, 13, 22, 6, 3, BRAND)
    fill_rect(img, 14, 25, 4, 5, WOOD)
    fill_rect(img, 15, 3, 2, 2, GOLD)
    outline_rect(img, 14, 4, 4, 20)
    save(img, "characters/player/weapon_blade.png")


def draw_brand(name: str, rim: str, core: str) -> None:
    img = new_img()
    # diamond brand mark
    for y, xs in [
        (8, range(14, 18)),
        (9, range(12, 20)),
        (10, range(11, 21)),
        (11, range(10, 22)),
        (12, range(10, 22)),
        (13, range(11, 21)),
        (14, range(12, 20)),
        (15, range(13, 19)),
        (16, range(14, 18)),
        (17, range(15, 17)),
    ]:
        for x in xs:
            px(img, x, y, rim)
    fill_rect(img, 13, 11, 6, 4, core)
    fill_rect(img, 15, 10, 2, 6, GOLD if name == "gold" else core)
    # rune scratch
    fill_rect(img, 14, 12, 4, 1, INK)
    fill_rect(img, 15, 13, 1, 2, INK)
    save(img, f"brands/brand_{name}.png")


# --- Enemies ---

def draw_pit_grub() -> None:
    img = new_img()
    fill_rect(img, 8, 18, 16, 8, "#A89060")
    fill_rect(img, 10, 14, 12, 6, "#C4A878")
    fill_rect(img, 12, 11, 8, 5, "#D4B888")
    fill_rect(img, 14, 9, 4, 3, "#E0C898")
    # segments
    for x in (10, 14, 18):
        fill_rect(img, x, 20, 1, 5, STONE)
    fill_rect(img, 13, 12, 2, 2, INK)
    fill_rect(img, 17, 12, 2, 2, INK)
    fill_rect(img, 15, 15, 2, 1, RED)
    outline_rect(img, 8, 18, 16, 8)
    save(img, "enemies/enemy_pit_grub.png")


def draw_spore_spitter() -> None:
    img = new_img()
    # body bulb
    fill_rect(img, 10, 14, 12, 12, GREEN)
    fill_rect(img, 12, 12, 8, 4, GREEN2)
    # stalk legs
    fill_rect(img, 11, 26, 3, 4, "#3A5A28")
    fill_rect(img, 18, 26, 3, 4, "#3A5A28")
    # spore sacs
    fill_rect(img, 8, 16, 3, 4, MIND2)
    fill_rect(img, 21, 16, 3, 4, MIND2)
    fill_rect(img, 14, 8, 4, 5, "#C8E880")
    fill_rect(img, 15, 6, 2, 3, "#E0F0A0")
    fill_rect(img, 13, 18, 2, 2, INK)
    fill_rect(img, 17, 18, 2, 2, INK)
    outline_rect(img, 10, 14, 12, 12)
    save(img, "enemies/enemy_spore_spitter.png")


def draw_shell_beetle() -> None:
    img = new_img()
    fill_rect(img, 8, 16, 16, 10, SHELL)
    fill_rect(img, 10, 12, 12, 8, SHELL2)
    # hard shell ridge
    fill_rect(img, 12, 10, 8, 6, METAL)
    fill_rect(img, 14, 8, 4, 4, SILVER)
    # legs
    for x in (7, 11, 19, 23):
        fill_rect(img, x, 24, 2, 5, STONE)
    fill_rect(img, 12, 18, 2, 2, INK)
    fill_rect(img, 18, 18, 2, 2, INK)
    fill_rect(img, 14, 21, 4, 2, HAIR)
    outline_rect(img, 8, 16, 16, 10)
    save(img, "enemies/enemy_shell_beetle.png")


def draw_scale_rock() -> None:
    img = new_img()
    fill_rect(img, 8, 22, 6, 6, STONE)
    fill_rect(img, 18, 22, 6, 6, STONE)
    fill_rect(img, 6, 12, 20, 14, SHELL)
    fill_rect(img, 8, 10, 16, 6, SHELL2)
    fill_rect(img, 10, 8, 12, 4, STONE_D)
    # scales
    fill_rect(img, 10, 14, 4, 3, STONE3)
    fill_rect(img, 16, 16, 5, 3, STONE3)
    fill_rect(img, 12, 18, 6, 3, "#A89880")
    fill_rect(img, 11, 11, 3, 2, BRAND)
    fill_rect(img, 18, 11, 3, 2, BRAND)
    fill_rect(img, 14, 20, 4, 2, INK)
    fill_rect(img, 4, 16, 3, 4, STONE_D)
    fill_rect(img, 25, 16, 3, 4, STONE_D)
    outline_rect(img, 6, 12, 20, 14)
    save(img, "enemies/enemy_scale_rock.png")


def draw_rune_wisp() -> None:
    img = new_img()
    # floating core
    fill_rect(img, 12, 12, 8, 8, GOLD)
    fill_rect(img, 14, 14, 4, 4, BRAND)
    fill_rect(img, 15, 15, 2, 2, "#FFF0A0")
    # flame wisps
    fill_rect(img, 10, 8, 3, 5, ORANGE)
    fill_rect(img, 19, 9, 3, 4, ORANGE)
    fill_rect(img, 8, 16, 3, 4, BRAND)
    fill_rect(img, 21, 15, 3, 5, BRAND)
    fill_rect(img, 14, 6, 4, 3, GOLD)
    fill_rect(img, 13, 22, 2, 4, ORANGE)
    fill_rect(img, 17, 23, 2, 3, BRAND)
    outline_rect(img, 12, 12, 8, 8)
    save(img, "enemies/enemy_rune_wisp.png")


def draw_alchemy_golem() -> None:
    img = new_img()
    # blocky body
    fill_rect(img, 8, 14, 16, 14, ALCH)
    fill_rect(img, 10, 10, 12, 8, ALCH2)
    fill_rect(img, 12, 6, 8, 6, METAL)
    # copper seams
    fill_rect(img, 8, 18, 16, 2, COPPER)
    fill_rect(img, 15, 10, 2, 18, COPPER)
    # eyes / core
    fill_rect(img, 13, 12, 2, 2, GOLD)
    fill_rect(img, 17, 12, 2, 2, GOLD)
    fill_rect(img, 14, 20, 4, 4, MIND)
    # arms
    fill_rect(img, 4, 16, 4, 8, ALCH)
    fill_rect(img, 24, 16, 4, 8, ALCH)
    outline_rect(img, 8, 14, 16, 14)
    save(img, "enemies/enemy_alchemy_golem.png")


def draw_depth_lurker() -> None:
    img = new_img()
    fill_rect(img, 6, 16, 20, 10, DEEP)
    fill_rect(img, 8, 12, 16, 8, DEEP2)
    fill_rect(img, 10, 8, 12, 6, "#5A5080")
    # tendrils
    fill_rect(img, 4, 20, 3, 8, PURPLE_D)
    fill_rect(img, 25, 18, 3, 10, PURPLE_D)
    fill_rect(img, 12, 26, 2, 5, MIND)
    fill_rect(img, 18, 26, 2, 5, MIND)
    # glowing eyes
    fill_rect(img, 12, 14, 3, 2, MIND2)
    fill_rect(img, 17, 14, 3, 2, MIND2)
    fill_rect(img, 14, 18, 4, 2, INK)
    outline_rect(img, 6, 16, 20, 10)
    save(img, "enemies/enemy_depth_lurker.png")


def draw_crystal_guardian() -> None:
    img = new_img()
    fill_rect(img, 10, 18, 12, 10, STONE)
    fill_rect(img, 11, 10, 10, 12, CRYSTAL2)
    fill_rect(img, 13, 6, 6, 8, CRYSTAL)
    fill_rect(img, 14, 4, 4, 4, "#B8E8F8")
    # crystal spikes
    fill_rect(img, 7, 12, 3, 8, CRYSTAL)
    fill_rect(img, 22, 12, 3, 8, CRYSTAL)
    fill_rect(img, 12, 14, 2, 2, INK)
    fill_rect(img, 18, 14, 2, 2, INK)
    fill_rect(img, 14, 22, 4, 3, MIND)
    outline_rect(img, 11, 10, 10, 12)
    save(img, "enemies/enemy_crystal_guardian.png")


# --- Materials ---

def draw_glow_moss() -> None:
    img = new_img()
    fill_rect(img, 10, 18, 12, 8, GREEN)
    fill_rect(img, 12, 14, 8, 6, GREEN2)
    fill_rect(img, 14, 10, 4, 6, "#A0E060")
    fill_rect(img, 8, 20, 3, 4, "#3A6B28")
    fill_rect(img, 21, 16, 3, 5, "#A0E060")
    fill_rect(img, 15, 8, 2, 3, "#D0F080")
    save(img, "materials/mat_glow_moss.png")


def draw_bitter_root() -> None:
    img = new_img()
    fill_rect(img, 14, 6, 4, 18, WOOD)
    fill_rect(img, 15, 8, 2, 14, WOOD2)
    fill_rect(img, 10, 20, 5, 3, "#A07040")
    fill_rect(img, 17, 18, 5, 3, "#A07040")
    fill_rect(img, 12, 24, 3, 4, STONE)
    fill_rect(img, 18, 22, 3, 5, STONE)
    fill_rect(img, 13, 10, 2, 2, GREEN)
    save(img, "materials/mat_bitter_root.png")


def draw_deep_red_ore() -> None:
    img = new_img()
    fill_rect(img, 10, 18, 12, 8, STONE_D)
    fill_rect(img, 8, 14, 16, 8, "#6B5048")
    fill_rect(img, 12, 10, 10, 8, "#7A5A50")
    fill_rect(img, 14, 8, 6, 4, "#8A6A60")
    fill_rect(img, 14, 12, 4, 4, RED)
    fill_rect(img, 16, 14, 3, 3, RED2)
    fill_rect(img, 12, 16, 3, 3, RED3)
    fill_rect(img, 18, 18, 2, 2, "#FF6A4A")
    fill_rect(img, 10, 20, 2, 2, RED)
    outline_rect(img, 8, 14, 16, 12)
    save(img, "materials/mat_deep_red_ore.png")


def draw_copper_vein() -> None:
    img = new_img()
    fill_rect(img, 9, 14, 14, 12, STONE)
    fill_rect(img, 11, 10, 10, 8, STONE2)
    fill_rect(img, 13, 12, 3, 8, COPPER)
    fill_rect(img, 17, 14, 3, 6, "#D49040")
    fill_rect(img, 12, 18, 6, 2, COPPER)
    fill_rect(img, 15, 10, 2, 2, GOLD)
    save(img, "materials/mat_copper_vein.png")


def draw_silver_dust() -> None:
    img = new_img()
    fill_rect(img, 10, 14, 12, 10, STONE2)
    fill_rect(img, 12, 10, 8, 8, SILVER)
    fill_rect(img, 14, 8, 4, 4, "#E8F0F8")
    fill_rect(img, 11, 18, 2, 2, SILVER)
    fill_rect(img, 19, 16, 2, 2, "#E8F0F8")
    fill_rect(img, 15, 20, 3, 2, METAL)
    save(img, "materials/mat_silver_dust.png")


def draw_beast_scale() -> None:
    img = new_img()
    fill_rect(img, 10, 10, 12, 14, SHELL)
    fill_rect(img, 12, 8, 8, 6, SHELL2)
    fill_rect(img, 14, 12, 6, 8, STONE3)
    fill_rect(img, 13, 16, 4, 2, BRAND)
    outline_rect(img, 10, 10, 12, 14)
    save(img, "materials/mat_beast_scale.png")


def draw_chitin_plate() -> None:
    img = new_img()
    fill_rect(img, 8, 12, 16, 12, METAL)
    fill_rect(img, 10, 10, 12, 6, SILVER)
    fill_rect(img, 12, 14, 8, 6, "#707880")
    fill_rect(img, 14, 8, 4, 3, SHELL2)
    outline_rect(img, 8, 12, 16, 12)
    save(img, "materials/mat_chitin_plate.png")


def draw_ember_gland() -> None:
    img = new_img()
    fill_rect(img, 11, 12, 10, 12, BRAND)
    fill_rect(img, 13, 10, 6, 6, ORANGE)
    fill_rect(img, 14, 8, 4, 4, GOLD)
    fill_rect(img, 15, 14, 2, 4, "#FFF0A0")
    fill_rect(img, 12, 22, 3, 3, RED3)
    fill_rect(img, 17, 22, 3, 3, RED3)
    outline_rect(img, 11, 12, 10, 12)
    save(img, "materials/mat_ember_gland.png")


def draw_mind_shard() -> None:
    img = new_img()
    fill_rect(img, 14, 6, 4, 20, MIND)
    fill_rect(img, 12, 10, 8, 12, MIND2)
    fill_rect(img, 15, 8, 2, 4, "#D0B8F0")
    fill_rect(img, 13, 16, 2, 4, PURPLE_D)
    fill_rect(img, 17, 18, 2, 4, PURPLE_D)
    outline_rect(img, 12, 10, 8, 12)
    save(img, "materials/mat_mind_shard.png")


def draw_mind_core() -> None:
    img = new_img()
    fill_rect(img, 10, 10, 12, 12, MIND)
    fill_rect(img, 12, 8, 8, 16, MIND2)
    fill_rect(img, 14, 12, 4, 8, "#D0B8F0")
    fill_rect(img, 15, 14, 2, 4, GOLD)
    fill_rect(img, 8, 14, 3, 4, MIND)
    fill_rect(img, 21, 14, 3, 4, MIND)
    outline_rect(img, 10, 10, 12, 12)
    save(img, "materials/mat_mind_core.png")


def draw_alchem_slag() -> None:
    img = new_img()
    fill_rect(img, 10, 14, 12, 10, "#5A6860")
    fill_rect(img, 12, 12, 8, 4, ALCH)
    fill_rect(img, 11, 18, 10, 3, COPPER)
    fill_rect(img, 14, 10, 4, 3, ALCH2)
    outline_rect(img, 10, 14, 12, 10)
    save(img, "materials/mat_alchem_slag.png")


def draw_rune_ash() -> None:
    img = new_img()
    fill_rect(img, 10, 16, 12, 8, "#4A4840")
    fill_rect(img, 12, 12, 8, 8, "#6A6860")
    fill_rect(img, 14, 10, 4, 4, GOLD)
    fill_rect(img, 11, 18, 2, 2, BRAND)
    fill_rect(img, 19, 20, 2, 2, BRAND)
    fill_rect(img, 15, 14, 2, 2, "#E8D080")
    save(img, "materials/mat_rune_ash.png")


# --- Runes ---

def rune_base(img: Image.Image, rim: str = MIND) -> None:
    fill_rect(img, 8, 8, 16, 16, rim)
    fill_rect(img, 10, 10, 12, 12, "#2A2040")
    outline_rect(img, 8, 8, 16, 16, GOLD)


def draw_runes() -> None:
    # tough - shield
    img = new_img()
    rune_base(img, ALCH)
    fill_rect(img, 13, 12, 6, 8, ALCH2)
    fill_rect(img, 14, 11, 4, 2, SILVER)
    fill_rect(img, 15, 18, 2, 2, ALCH2)
    save(img, "runes/rune_tough.png")

    # swift - boot/speed lines
    img = new_img()
    rune_base(img, GREEN)
    fill_rect(img, 12, 14, 8, 4, GREEN2)
    fill_rect(img, 10, 13, 3, 2, "#A0E060")
    fill_rect(img, 10, 17, 3, 2, "#A0E060")
    fill_rect(img, 18, 15, 4, 2, GOLD)
    save(img, "runes/rune_swift.png")

    # slash - blades
    img = new_img()
    rune_base(img, BRAND)
    fill_rect(img, 12, 11, 2, 10, SILVER)
    fill_rect(img, 16, 11, 2, 10, SILVER)
    fill_rect(img, 14, 14, 4, 2, GOLD)
    save(img, "runes/rune_slash.png")

    # sidestep - curve arrow
    img = new_img()
    rune_base(img, COPPER)
    fill_rect(img, 12, 12, 8, 2, GOLD)
    fill_rect(img, 18, 12, 2, 8, GOLD)
    fill_rect(img, 14, 18, 6, 2, GOLD)
    fill_rect(img, 12, 16, 2, 2, GOLD)
    save(img, "runes/rune_sidestep.png")

    # edge - sharp triangle
    img = new_img()
    rune_base(img, METAL)
    fill_rect(img, 15, 10, 2, 12, SILVER)
    fill_rect(img, 13, 14, 6, 2, GOLD)
    fill_rect(img, 14, 12, 4, 2, SILVER)
    save(img, "runes/rune_edge.png")

    # reach - long slash
    img = new_img()
    rune_base(img, STONE2)
    fill_rect(img, 10, 15, 12, 2, SILVER)
    fill_rect(img, 11, 13, 2, 6, METAL)
    fill_rect(img, 19, 13, 2, 6, METAL)
    save(img, "runes/rune_reach.png")

    # burn - flame
    img = new_img()
    rune_base(img, BRAND)
    fill_rect(img, 14, 10, 4, 10, ORANGE)
    fill_rect(img, 15, 12, 2, 6, GOLD)
    fill_rect(img, 12, 14, 2, 4, BRAND)
    fill_rect(img, 18, 14, 2, 4, BRAND)
    save(img, "runes/rune_burn.png")

    # quake - mountain smash
    img = new_img()
    rune_base(img, STONE)
    fill_rect(img, 12, 16, 8, 4, STONE2)
    fill_rect(img, 14, 12, 4, 6, STONE3)
    fill_rect(img, 15, 10, 2, 3, GOLD)
    fill_rect(img, 11, 18, 2, 2, BRAND)
    fill_rect(img, 19, 18, 2, 2, BRAND)
    save(img, "runes/rune_quake.png")


# --- Tiles ---

def draw_floors() -> None:
    specs = [
        ("tile_floor_01.png", STONE2, STONE, [(4, 4), (20, 6), (8, 22), (24, 24), (14, 12)]),
        ("tile_floor_02.png", STONE2, "#7A6548", [(6, 8), (18, 4), (10, 18), (22, 20), (16, 14)]),
        ("tile_floor_03.png", "#7A6548", STONE2, [(2, 2), (28, 4), (4, 28), (26, 26), (12, 16)]),
        ("tile_floor_04.png", STONE2, STONE3, [(8, 6), (22, 10), (6, 20), (20, 22), (14, 14)]),
    ]
    for name, base, alt, dots in specs:
        img = new_img()
        fill_rect(img, 0, 0, 32, 32, base)
        fill_rect(img, 0, 0, 16, 16, alt)
        fill_rect(img, 16, 16, 16, 16, alt)
        for x, y in dots:
            fill_rect(img, x, y, 2, 2, STONE if base != STONE else STONE3)
        save(img, f"tiles/pit_floor/{name}")

    # crack
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, STONE2)
    fill_rect(img, 0, 0, 16, 16, STONE)
    fill_rect(img, 14, 4, 2, 24, STONE_D)
    fill_rect(img, 8, 14, 16, 2, STONE_D)
    fill_rect(img, 16, 16, 8, 2, HAIR)
    save(img, "tiles/pit_floor/tile_floor_crack.png")

    # vein
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, STONE2)
    fill_rect(img, 10, 0, 3, 32, COPPER)
    fill_rect(img, 0, 12, 32, 2, RED)
    fill_rect(img, 18, 8, 2, 16, RED2)
    fill_rect(img, 6, 20, 8, 2, COPPER)
    save(img, "tiles/pit_floor/tile_floor_vein.png")

    # deep recolor
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, DEEP2)
    fill_rect(img, 0, 0, 16, 16, DEEP)
    fill_rect(img, 16, 16, 16, 16, DEEP)
    for x, y in [(4, 4), (20, 6), (8, 22), (24, 24)]:
        fill_rect(img, x, y, 2, 2, MIND)
    save(img, "tiles/pit_floor/tile_floor_deep.png")


def draw_walls() -> None:
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, STONE_D)
    fill_rect(img, 0, 0, 32, 8, HAIR)
    fill_rect(img, 2, 10, 12, 10, STONE)
    fill_rect(img, 18, 12, 12, 10, STONE)
    fill_rect(img, 4, 22, 24, 8, "#4A3830")
    save(img, "tiles/pit_wall/tile_wall.png")

    img = new_img()
    fill_rect(img, 0, 0, 32, 32, STONE_D)
    fill_rect(img, 0, 0, 16, 32, HAIR)
    fill_rect(img, 0, 0, 32, 16, HAIR)
    fill_rect(img, 16, 16, 14, 14, STONE)
    save(img, "tiles/pit_wall/tile_wall_corner.png")

    img = new_img()
    fill_rect(img, 0, 0, 32, 32, STONE_D)
    fill_rect(img, 0, 0, 8, 32, HAIR)
    fill_rect(img, 24, 0, 8, 32, HAIR)
    fill_rect(img, 8, 4, 16, 24, "#3A3028")
    fill_rect(img, 10, 8, 12, 16, WOOD2)
    fill_rect(img, 14, 14, 4, 4, GOLD)
    save(img, "tiles/pit_wall/tile_wall_door.png")


def draw_props() -> None:
    # ore node
    img = new_img()
    fill_rect(img, 8, 14, 16, 12, STONE)
    fill_rect(img, 10, 10, 12, 8, STONE2)
    fill_rect(img, 12, 12, 4, 6, RED)
    fill_rect(img, 18, 14, 3, 5, COPPER)
    fill_rect(img, 14, 8, 4, 4, RED2)
    save(img, "tiles/pit_props/prop_ore_node.png")

    # forage
    img = new_img()
    fill_rect(img, 10, 18, 12, 8, GREEN)
    fill_rect(img, 12, 12, 8, 8, GREEN2)
    fill_rect(img, 14, 8, 4, 6, "#A0E060")
    fill_rect(img, 8, 20, 3, 4, WOOD)
    fill_rect(img, 21, 16, 3, 5, "#A0E060")
    save(img, "tiles/pit_props/prop_forage.png")

    # extract beacon
    img = new_img()
    fill_rect(img, 14, 8, 4, 18, METAL)
    fill_rect(img, 12, 6, 8, 4, ALCH2)
    fill_rect(img, 13, 4, 6, 3, GOLD)
    fill_rect(img, 10, 24, 12, 4, STONE)
    fill_rect(img, 15, 10, 2, 4, ALCH)
    save(img, "tiles/pit_props/prop_extract.png")

    # distress
    img = new_img()
    fill_rect(img, 14, 8, 4, 16, METAL)
    fill_rect(img, 12, 6, 8, 4, BRAND)
    fill_rect(img, 13, 4, 6, 3, ORANGE)
    fill_rect(img, 10, 22, 12, 4, STONE)
    fill_rect(img, 15, 12, 2, 2, GOLD)
    fill_rect(img, 15, 16, 2, 2, GOLD)
    save(img, "tiles/pit_props/prop_distress.png")

    # descent
    img = new_img()
    fill_rect(img, 6, 6, 20, 20, HAIR)
    fill_rect(img, 10, 10, 12, 12, INK)
    fill_rect(img, 12, 12, 8, 8, "#1A1010")
    fill_rect(img, 14, 8, 4, 2, STONE3)
    fill_rect(img, 14, 22, 4, 2, STONE3)
    fill_rect(img, 8, 14, 2, 4, STONE3)
    fill_rect(img, 22, 14, 2, 4, STONE3)
    save(img, "tiles/pit_props/prop_descent.png")

    # alchem chest
    img = new_img()
    fill_rect(img, 8, 14, 16, 12, WOOD)
    fill_rect(img, 8, 12, 16, 4, WOOD2)
    fill_rect(img, 14, 16, 4, 4, GOLD)
    fill_rect(img, 10, 18, 12, 2, COPPER)
    fill_rect(img, 12, 10, 8, 3, ALCH)
    outline_rect(img, 8, 14, 16, 12)
    save(img, "tiles/pit_props/prop_alchem_chest.png")


def draw_hub() -> None:
    # stone brick floor
    img = new_img()
    fill_rect(img, 0, 0, 32, 32, "#7A7068")
    fill_rect(img, 1, 1, 14, 14, "#8A8078")
    fill_rect(img, 17, 1, 14, 14, "#8A8078")
    fill_rect(img, 1, 17, 14, 14, "#8A8078")
    fill_rect(img, 17, 17, 14, 14, "#8A8078")
    save(img, "tiles/hub/hub_floor.png")

    # board
    img = new_img()
    fill_rect(img, 8, 6, 16, 20, WOOD)
    fill_rect(img, 10, 8, 12, 14, PAPER)
    fill_rect(img, 12, 10, 8, 2, INK)
    fill_rect(img, 12, 14, 8, 2, INK)
    fill_rect(img, 12, 18, 6, 2, BRAND)
    fill_rect(img, 14, 26, 4, 4, WOOD2)
    save(img, "tiles/hub/hub_board.png")

    # alchemy bench
    img = new_img()
    fill_rect(img, 6, 18, 20, 8, WOOD2)
    fill_rect(img, 8, 14, 16, 6, WOOD)
    fill_rect(img, 10, 10, 5, 6, ALCH)
    fill_rect(img, 18, 8, 4, 8, COPPER)
    fill_rect(img, 12, 8, 3, 3, ALCH2)
    fill_rect(img, 20, 6, 2, 3, GOLD)
    save(img, "tiles/hub/hub_alchemy.png")

    # quiet door
    img = new_img()
    fill_rect(img, 8, 4, 16, 26, WOOD2)
    fill_rect(img, 10, 6, 12, 20, WOOD)
    fill_rect(img, 14, 14, 4, 4, MIND)
    fill_rect(img, 15, 8, 2, 4, MIND2)
    fill_rect(img, 20, 16, 2, 3, GOLD)
    save(img, "tiles/hub/hub_quiet_door.png")

    # pit mouth
    img = new_img()
    fill_rect(img, 4, 8, 24, 18, STONE)
    fill_rect(img, 8, 12, 16, 14, INK)
    fill_rect(img, 10, 14, 12, 10, "#1A1018")
    fill_rect(img, 12, 10, 8, 3, MIND)
    fill_rect(img, 6, 20, 4, 4, STONE_D)
    fill_rect(img, 22, 20, 4, 4, STONE_D)
    save(img, "tiles/hub/hub_pit_mouth.png")


def main() -> None:
    draw_player()
    draw_blade()
    draw_brand("iron", METAL, "#606870")
    draw_brand("copper", COPPER, "#D49040")
    draw_brand("silver", SILVER, "#E8F0F8")
    draw_brand("gold", GOLD, "#FFF0A0")

    draw_pit_grub()
    draw_spore_spitter()
    draw_shell_beetle()
    draw_scale_rock()
    draw_rune_wisp()
    draw_alchemy_golem()
    draw_depth_lurker()
    draw_crystal_guardian()

    draw_glow_moss()
    draw_bitter_root()
    draw_deep_red_ore()
    draw_copper_vein()
    draw_silver_dust()
    draw_beast_scale()
    draw_chitin_plate()
    draw_ember_gland()
    draw_mind_shard()
    draw_mind_core()
    draw_alchem_slag()
    draw_rune_ash()

    draw_runes()
    draw_floors()
    draw_walls()
    draw_props()
    draw_hub()
    print("done")


if __name__ == "__main__":
    main()
