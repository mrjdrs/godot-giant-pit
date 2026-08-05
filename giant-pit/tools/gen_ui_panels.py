#!/usr/bin/env python3
"""Generate v0.4 UI panels, chrome, icons, and new rune set."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets"

INK = "#2A1F18"
PANEL = "#3A3028"
PANEL2 = "#4A4038"
PANEL3 = "#5A5048"
EDGE = "#3D8B7A"
EDGE2 = "#5BB8A5"
GOLD = "#E8A838"
GOLD2 = "#FFF0A0"
BRAND = "#C45C2A"
MIND = "#6B4C9A"
MIND2 = "#9B7BC8"
RED = "#C42A2A"
RED2 = "#E84838"
METAL = "#8A9098"
SILVER = "#C0C8D0"
WOOD = "#8B5A2B"
PAPER = "#E8D8B0"
GRAY = "#606870"
GRAY2 = "#808890"
GREEN = "#4A8B3A"
ALCH = "#3D8B7A"


def rgba(c: str) -> tuple[int, int, int, int]:
    c = c.lstrip("#")
    if len(c) == 8:
        return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), int(c[6:8], 16))
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


def new_img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(img: Image.Image, x: int, y: int, c: str) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), rgba(c))


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


def draw_title_bar(img: Image.Image, title_blocks: list[tuple[int, int]]) -> None:
    """Pixel-block title decoration; title_blocks are relative glyph stubs."""
    fill_rect(img, 0, 0, img.width, 24, PANEL)
    fill_rect(img, 0, 0, img.width, 3, GOLD)
    fill_rect(img, 0, 21, img.width, 3, EDGE)
    # close button top-right
    fill_rect(img, img.width - 20, 4, 16, 16, BRAND)
    fill_rect(img, img.width - 17, 7, 10, 2, GOLD2)
    fill_rect(img, img.width - 17, 15, 10, 2, GOLD2)
    # title glyph stubs (decorative bars forming readable block title)
    ox = 12
    for dx, w in title_blocks:
        fill_rect(img, ox + dx, 8, w, 8, GOLD)


def draw_panel_frame(img: Image.Image) -> None:
    fill_rect(img, 0, 0, img.width, img.height, PANEL2)
    outline_rect(img, 0, 0, img.width, img.height, EDGE)
    outline_rect(img, 2, 2, img.width - 4, img.height - 4, INK)
    fill_rect(img, 4, 4, img.width - 8, img.height - 8, PANEL3)


def draw_slot(img: Image.Image, x: int, y: int, size: int = 28, selected: bool = False, locked: bool = False) -> None:
    fill_rect(img, x, y, size, size, PANEL)
    outline_rect(img, x, y, size, size, EDGE if not selected else GOLD)
    if selected:
        outline_rect(img, x + 1, y + 1, size - 2, size - 2, GOLD2)
    if locked:
        fill_rect(img, x + size // 2 - 3, y + size // 2 - 4, 6, 8, GRAY)
        fill_rect(img, x + size // 2 - 2, y + size // 2 - 6, 4, 3, METAL)


def draw_label_row(img: Image.Image, x: int, y: int, icon_c: str, bar_w: int = 100) -> None:
    fill_rect(img, x, y, 12, 12, icon_c)
    outline_rect(img, x, y, 12, 12, INK)
    fill_rect(img, x + 16, y + 2, bar_w, 8, PANEL)
    fill_rect(img, x + 16, y + 2, bar_w // 2, 8, icon_c)


# --- Panels ---

def gen_panel_stats() -> None:
    img = new_img(320, 240)
    draw_panel_frame(img)
    # title 「属性」 as block pattern
    draw_title_bar(img, [(0, 6), (8, 6), (16, 4), (22, 6)])
    # left: clean text list area (no progress bars — labels overlaid at runtime)
    fill_rect(img, 12, 32, 180, 196, PANEL)
    outline_rect(img, 12, 32, 180, 196, EDGE)
    # subtle row guides only (no colored bars)
    for i in range(11):
        y = 40 + i * 16
        fill_rect(img, 18, y + 14, 168, 1, PANEL2)
    # right equip area — empty box only; slot icons drawn by UI at runtime
    fill_rect(img, 200, 32, 108, 196, PANEL)
    outline_rect(img, 200, 32, 108, 196, GOLD)
    for i in range(3):
        y = 48 + i * 56
        fill_rect(img, 208, y + 40, 92, 1, PANEL2)
    save(img, "ui/panels/panel_stats.png")


def gen_panel_bag() -> None:
    img = new_img(320, 240)
    draw_panel_frame(img)
    draw_title_bar(img, [(0, 6), (8, 4), (14, 6), (22, 6)])
    # gold bar
    fill_rect(img, 12, 32, 296, 28, PANEL)
    outline_rect(img, 12, 32, 296, 28, GOLD)
    fill_rect(img, 20, 38, 16, 16, GOLD)
    fill_rect(img, 24, 42, 8, 8, GOLD2)
    fill_rect(img, 44, 40, 120, 12, PANEL2)
    fill_rect(img, 44, 40, 60, 12, GOLD)
    # 10 slots 2x5
    fill_rect(img, 12, 68, 296, 120, PANEL)
    outline_rect(img, 12, 68, 296, 120, EDGE)
    for row in range(2):
        for col in range(5):
            sx = 28 + col * 56
            sy = 80 + row * 48
            draw_slot(img, sx, sy, 36, selected=(row == 0 and col == 0))
    # weight bar
    fill_rect(img, 12, 200, 296, 28, PANEL)
    outline_rect(img, 12, 200, 296, 28, EDGE)
    fill_rect(img, 24, 210, 260, 10, PANEL2)
    fill_rect(img, 24, 210, 140, 10, ALCH)
    outline_rect(img, 24, 210, 260, 10, INK)
    save(img, "ui/panels/panel_bag.png")


def gen_panel_skills() -> None:
    img = new_img(320, 240)
    draw_panel_frame(img)
    draw_title_bar(img, [(0, 6), (8, 6), (16, 4), (22, 8)])
    # left skill slots
    fill_rect(img, 12, 32, 120, 196, PANEL)
    outline_rect(img, 12, 32, 120, 196, EDGE)
    fill_rect(img, 20, 40, 48, 8, GOLD)
    active = [(28, 56, METAL), (28, 96, BRAND), (28, 136, ALCH)]
    gray = [(28, 176, GRAY), (72, 56, GRAY2), (72, 96, GRAY)]
    for x, y, c in active:
        draw_slot(img, x, y, 32)
        fill_rect(img, x + 8, y + 8, 16, 16, c)
    for x, y, c in gray:
        draw_slot(img, x, y, 32)
        fill_rect(img, x + 8, y + 8, 16, 16, c)
        fill_rect(img, x + 20, y + 4, 8, 8, GRAY)  # lock hint
    # right learn list
    fill_rect(img, 140, 32, 168, 196, PANEL)
    outline_rect(img, 140, 32, 168, 196, MIND)
    # tabs
    fill_rect(img, 148, 40, 64, 16, BRAND)
    fill_rect(img, 220, 40, 64, 16, PANEL2)
    outline_rect(img, 148, 40, 64, 16, GOLD)
    outline_rect(img, 220, 40, 64, 16, GRAY)
    # rune rows
    for i in range(4):
        y = 68 + i * 36
        draw_slot(img, 152, y, 28)
        fill_rect(img, 156, y + 4, 20, 20, GOLD if i < 3 else GRAY)
        fill_rect(img, 188, y + 6, 80, 16, PANEL2)
        if i == 3:
            fill_rect(img, 250, y + 8, 12, 12, GRAY)  # lock
        else:
            fill_rect(img, 248, y + 6, 40, 16, EDGE2)  # learn btn
    save(img, "ui/panels/panel_skills.png")


# --- Chrome ---

def gen_chrome() -> None:
    img = new_img(32, 16)
    fill_rect(img, 0, 0, 32, 16, EDGE)
    fill_rect(img, 0, 4, 32, 8, EDGE2)
    save(img, "ui/chrome/ui_frame_edge.png")

    img = new_img(16, 16)
    fill_rect(img, 0, 0, 16, 16, EDGE)
    fill_rect(img, 4, 4, 12, 12, PANEL3)
    fill_rect(img, 0, 0, 4, 4, GOLD)
    save(img, "ui/chrome/ui_frame_corner.png")

    img = new_img(48, 20)
    fill_rect(img, 0, 0, 48, 20, EDGE)
    fill_rect(img, 2, 2, 44, 16, EDGE2)
    outline_rect(img, 0, 0, 48, 20, GOLD)
    save(img, "ui/chrome/ui_btn_normal.png")

    img = new_img(48, 20)
    fill_rect(img, 0, 0, 48, 20, GRAY)
    fill_rect(img, 2, 2, 44, 16, GRAY2)
    outline_rect(img, 0, 0, 48, 20, INK)
    save(img, "ui/chrome/ui_btn_disabled.png")

    img = new_img(16, 16)
    fill_rect(img, 0, 0, 16, 16, BRAND)
    fill_rect(img, 3, 3, 10, 2, GOLD2)
    fill_rect(img, 3, 11, 10, 2, GOLD2)
    fill_rect(img, 7, 5, 2, 6, GOLD2)
    # X
    for i in range(8):
        px(img, 4 + i, 4 + i, GOLD2)
        px(img, 11 - i, 4 + i, GOLD2)
    save(img, "ui/chrome/ui_btn_close.png")

    img = new_img(32, 32)
    fill_rect(img, 0, 0, 32, 32, PANEL)
    outline_rect(img, 0, 0, 32, 32, EDGE)
    outline_rect(img, 2, 2, 28, 28, INK)
    save(img, "ui/chrome/ui_slot_empty.png")

    img = new_img(32, 32)
    fill_rect(img, 0, 0, 32, 32, PANEL)
    outline_rect(img, 0, 0, 32, 32, GOLD)
    outline_rect(img, 2, 2, 28, 28, GOLD2)
    save(img, "ui/chrome/ui_slot_selected.png")

    img = new_img(16, 16)
    fill_rect(img, 4, 6, 8, 8, GRAY)
    fill_rect(img, 5, 3, 6, 5, METAL)
    fill_rect(img, 7, 8, 2, 3, INK)
    save(img, "ui/chrome/ui_lock.png")

    img = new_img(48, 16)
    fill_rect(img, 0, 0, 48, 16, BRAND)
    fill_rect(img, 4, 4, 40, 8, GOLD)
    outline_rect(img, 0, 0, 48, 16, GOLD2)
    save(img, "ui/chrome/ui_tab_skill.png")

    img = new_img(48, 16)
    fill_rect(img, 0, 0, 48, 16, MIND)
    fill_rect(img, 4, 4, 40, 8, MIND2)
    outline_rect(img, 0, 0, 48, 16, GOLD)
    save(img, "ui/chrome/ui_tab_attr.png")


# --- Stat icons ---

def icon_base(body: str) -> Image.Image:
    img = new_img(32, 32)
    fill_rect(img, 4, 4, 24, 24, body)
    outline_rect(img, 4, 4, 24, 24, INK)
    return img


def gen_stat_icons() -> None:
    # hp heart-ish
    img = icon_base(RED)
    fill_rect(img, 10, 10, 5, 5, RED2)
    fill_rect(img, 17, 10, 5, 5, RED2)
    fill_rect(img, 12, 14, 8, 8, RED2)
    save(img, "ui/icons/stats/icon_hp.png")

    img = icon_base(MIND)
    fill_rect(img, 12, 8, 8, 16, MIND2)
    fill_rect(img, 14, 12, 4, 8, GOLD)
    save(img, "ui/icons/stats/icon_mind.png")

    img = icon_base(GOLD)
    fill_rect(img, 10, 10, 12, 12, GOLD2)
    fill_rect(img, 14, 8, 4, 4, BRAND)
    fill_rect(img, 14, 14, 4, 4, INK)
    save(img, "ui/icons/stats/icon_mind_lv.png")

    img = icon_base(GREEN)
    fill_rect(img, 12, 8, 8, 16, "#6BB84A")
    fill_rect(img, 14, 18, 4, 6, WOOD)
    save(img, "ui/icons/stats/icon_vitality.png")

    img = icon_base(BRAND)
    fill_rect(img, 10, 12, 12, 8, "#E87830")
    fill_rect(img, 14, 8, 4, 16, METAL)
    save(img, "ui/icons/stats/icon_str.png")

    img = icon_base(METAL)
    fill_rect(img, 14, 6, 4, 18, SILVER)
    fill_rect(img, 12, 20, 8, 4, WOOD)
    fill_rect(img, 15, 8, 2, 10, GOLD)
    save(img, "ui/icons/stats/icon_patk.png")

    img = icon_base(ALCH)
    fill_rect(img, 10, 10, 12, 14, EDGE2)
    fill_rect(img, 13, 8, 6, 4, SILVER)
    save(img, "ui/icons/stats/icon_pdef.png")

    # gray placeholders
    for name, mark in [
        ("icon_agi", (12, 10, 8, 12)),
        ("icon_int", (14, 8, 4, 16)),
        ("icon_crit", (12, 12, 8, 8)),
        ("icon_critdmg", (10, 10, 12, 12)),
    ]:
        img = icon_base(GRAY)
        fill_rect(img, *mark, GRAY2)
        save(img, f"ui/icons/stats/{name}.png")

    # slot markers
    img = new_img(32, 32)
    fill_rect(img, 6, 4, 6, 24, METAL)
    fill_rect(img, 8, 2, 4, 4, GOLD)
    outline_rect(img, 6, 4, 6, 24, INK)
    save(img, "ui/icons/stats/slot_weapon.png")

    img = new_img(32, 32)
    fill_rect(img, 8, 8, 16, 18, WOOD)
    fill_rect(img, 10, 10, 12, 8, "#A07040")
    outline_rect(img, 8, 8, 16, 18, INK)
    save(img, "ui/icons/stats/slot_chest.png")

    img = new_img(32, 32)
    fill_rect(img, 12, 6, 8, 8, GOLD)
    fill_rect(img, 14, 14, 4, 12, METAL)
    fill_rect(img, 12, 24, 8, 4, MIND2)
    save(img, "ui/icons/stats/slot_pendant.png")

    img = new_img(32, 32)
    fill_rect(img, 6, 8, 20, 18, WOOD)
    fill_rect(img, 8, 10, 16, 8, "#A07040")
    fill_rect(img, 10, 12, 12, 4, ALCH)
    outline_rect(img, 6, 8, 20, 18, INK)
    save(img, "ui/icons/stats/equip_chest.png")

    img = new_img(32, 32)
    fill_rect(img, 10, 6, 12, 10, GOLD)
    fill_rect(img, 12, 8, 8, 6, GOLD2)
    fill_rect(img, 14, 16, 4, 10, METAL)
    fill_rect(img, 12, 24, 8, 4, MIND)
    outline_rect(img, 10, 6, 12, 10, INK)
    save(img, "ui/icons/stats/equip_pendant.png")


def gen_bag_icons() -> None:
    img = new_img(32, 32)
    fill_rect(img, 8, 8, 16, 16, GOLD)
    fill_rect(img, 12, 12, 8, 8, GOLD2)
    outline_rect(img, 8, 8, 16, 16, INK)
    save(img, "ui/icons/bag/icon_gold.png")

    img = new_img(128, 16)
    fill_rect(img, 0, 0, 128, 16, PANEL)
    outline_rect(img, 0, 0, 128, 16, GOLD)
    fill_rect(img, 4, 2, 12, 12, GOLD)
    fill_rect(img, 20, 4, 100, 8, PANEL2)
    fill_rect(img, 20, 4, 40, 8, GOLD2)
    save(img, "ui/icons/bag/ui_gold_bar.png")

    img = new_img(128, 8)
    fill_rect(img, 0, 0, 128, 8, PANEL)
    outline_rect(img, 0, 0, 128, 8, INK)
    save(img, "ui/icons/bag/ui_weight_bar_bg.png")

    img = new_img(128, 8)
    fill_rect(img, 0, 0, 128, 8, ALCH)
    fill_rect(img, 0, 2, 128, 4, EDGE2)
    save(img, "ui/icons/bag/ui_weight_bar_fill.png")

    img = new_img(32, 32)
    fill_rect(img, 6, 8, 20, 16, PAPER)
    fill_rect(img, 8, 10, 16, 2, INK)
    fill_rect(img, 8, 14, 12, 2, INK)
    fill_rect(img, 8, 18, 10, 2, BRAND)
    outline_rect(img, 6, 8, 20, 16, WOOD)
    save(img, "ui/icons/bag/item_paper_note.png")

    img = new_img(32, 32)
    fill_rect(img, 6, 10, 20, 14, WOOD)
    fill_rect(img, 8, 8, 16, 6, "#A07040")
    fill_rect(img, 12, 14, 8, 6, ALCH)
    fill_rect(img, 14, 4, 4, 6, GOLD)
    outline_rect(img, 6, 10, 20, 14, INK)
    save(img, "ui/icons/bag/item_bag_expand.png")

    img = new_img(32, 32)
    fill_rect(img, 10, 6, 12, 20, MIND)
    fill_rect(img, 12, 8, 8, 12, MIND2)
    fill_rect(img, 14, 4, 4, 4, GOLD)
    fill_rect(img, 13, 22, 6, 4, "#C8B0E8")
    outline_rect(img, 10, 6, 12, 20, INK)
    save(img, "ui/icons/bag/item_mind_potion.png")


def gen_skill_slots() -> None:
    specs = [
        ("skill_slot_basic", METAL, False),
        ("skill_slot_finisher", BRAND, False),
        ("skill_slot_dodge", ALCH, False),
        ("skill_slot_defend", GRAY, True),
        ("skill_slot_ultimate", GRAY2, True),
        ("skill_slot_passive", GRAY, True),
    ]
    for name, color, gray in specs:
        img = new_img(32, 32)
        fill_rect(img, 2, 2, 28, 28, PANEL if not gray else "#3A3A40")
        outline_rect(img, 2, 2, 28, 28, EDGE if not gray else GRAY)
        fill_rect(img, 8, 8, 16, 16, color)
        if name.endswith("basic"):
            fill_rect(img, 14, 6, 4, 18, SILVER)
        elif name.endswith("finisher"):
            fill_rect(img, 10, 10, 12, 12, GOLD)
        elif name.endswith("dodge"):
            fill_rect(img, 10, 14, 12, 4, GOLD2)
        if gray:
            fill_rect(img, 20, 4, 8, 8, GRAY)
        save(img, f"ui/icons/skills/{name}.png")


# --- New runes ---

def rune_frame(rim: str) -> Image.Image:
    img = new_img(32, 32)
    fill_rect(img, 6, 6, 20, 20, rim)
    fill_rect(img, 8, 8, 16, 16, "#2A2040")
    outline_rect(img, 6, 6, 20, 20, GOLD)
    return img


def gen_new_runes() -> None:
    # chain slash — multi blades
    img = rune_frame(BRAND)
    fill_rect(img, 10, 10, 2, 12, SILVER)
    fill_rect(img, 14, 10, 2, 12, SILVER)
    fill_rect(img, 18, 10, 2, 12, SILVER)
    fill_rect(img, 11, 14, 10, 2, GOLD)
    save(img, "runes/rune_s_chain.png")

    # quake smash
    img = rune_frame(WOOD)
    fill_rect(img, 10, 16, 12, 6, "#6B5344")
    fill_rect(img, 12, 10, 8, 8, "#8B7355")
    fill_rect(img, 14, 8, 4, 4, GOLD)
    fill_rect(img, 9, 20, 2, 2, BRAND)
    fill_rect(img, 21, 20, 2, 2, BRAND)
    save(img, "runes/rune_s_quake.png")

    # cloudstep
    img = rune_frame(ALCH)
    fill_rect(img, 10, 14, 12, 4, EDGE2)
    fill_rect(img, 8, 12, 4, 3, SILVER)
    fill_rect(img, 8, 17, 4, 3, SILVER)
    fill_rect(img, 18, 13, 6, 6, GOLD)
    save(img, "runes/rune_s_cloudstep.png")

    # ironwall
    img = rune_frame(METAL)
    fill_rect(img, 10, 10, 12, 14, SILVER)
    fill_rect(img, 12, 8, 8, 4, GRAY2)
    fill_rect(img, 14, 14, 4, 6, METAL)
    save(img, "runes/rune_s_ironwall.png")

    # toughbone
    img = rune_frame(GREEN)
    fill_rect(img, 12, 8, 8, 16, "#6BB84A")
    fill_rect(img, 14, 12, 4, 10, PAPER)
    save(img, "runes/rune_a_toughbone.png")

    # heavyarm
    img = rune_frame(BRAND)
    fill_rect(img, 10, 12, 12, 10, "#E87830")
    fill_rect(img, 14, 8, 4, 16, METAL)
    fill_rect(img, 12, 18, 8, 4, GOLD)
    save(img, "runes/rune_a_heavyarm.png")

    # sharpeye
    img = rune_frame(GOLD)
    fill_rect(img, 10, 12, 12, 8, GOLD2)
    fill_rect(img, 14, 14, 4, 4, INK)
    fill_rect(img, 15, 10, 2, 12, BRAND)
    save(img, "runes/rune_a_sharpeye.png")

    # cruel crit dmg
    img = rune_frame(RED)
    fill_rect(img, 12, 10, 8, 12, RED2)
    fill_rect(img, 14, 8, 4, 4, GOLD)
    fill_rect(img, 10, 16, 4, 4, BRAND)
    fill_rect(img, 18, 16, 4, 4, BRAND)
    save(img, "runes/rune_a_cruel.png")


def main() -> None:
    gen_panel_stats()
    gen_panel_bag()
    gen_panel_skills()
    gen_chrome()
    gen_stat_icons()
    gen_bag_icons()
    gen_skill_slots()
    gen_new_runes()
    print("done")


if __name__ == "__main__":
    main()
