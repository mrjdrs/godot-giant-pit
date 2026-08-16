# -*- coding: utf-8 -*-
"""Generate the 25 war-scar skill icons used by skill_catalog.gd."""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw


OUT = Path(__file__).resolve().parents[1] / "assets/ui/icons/skills"
BG = (28, 18, 12, 255)
BORDER = (126, 48, 34, 255)
CRIMSON = (190, 38, 32, 255)
RED = (232, 70, 38, 255)
GOLD = (232, 168, 56, 255)
CREAM = (255, 232, 164, 255)
IRON = (116, 112, 104, 255)
DARK = (58, 28, 22, 255)

ACTIVE = [
    "dashslash", "groundwave", "ironstance", "riposte", "whirlwind",
    "mountainbreak", "warcry", "chainassault", "shieldbreak",
    "desperaterush", "bloodrage", "cataclysm",
]
PASSIVE = [
    "bloodinstinct", "heavyarm", "toughbone", "battlelust", "bloodthirst",
    "immovable", "ironskin", "scarheal", "breaksight", "lethalfocus",
    "laststand", "veteran", "immortalscar",
]


def base(passive: bool):
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    edge = IRON if passive else BORDER
    draw.rounded_rectangle((1, 1, 62, 62), radius=12, fill=BG, outline=(0, 0, 0, 255), width=1)
    draw.rounded_rectangle((3, 3, 60, 60), radius=11, outline=edge, width=4)
    draw.rounded_rectangle((7, 7, 56, 56), radius=9, outline=DARK, width=2)
    return image, draw


def polar(cx, cy, radius, angle):
    a = math.radians(angle)
    return cx + radius * math.cos(a), cy + radius * math.sin(a)


def blade(draw, angle, length=38, width=7, center=(32, 32), color=CREAM):
    cx, cy = center
    ux, uy = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    vx, vy = -uy, ux
    start = (cx - ux * length * 0.40, cy - uy * length * 0.40)
    tip = (cx + ux * length * 0.60, cy + uy * length * 0.60)
    points = [
        (start[0] + vx * width / 2, start[1] + vy * width / 2),
        (tip[0] - ux * 5 + vx * width / 2, tip[1] - uy * 5 + vy * width / 2),
        tip,
        (tip[0] - ux * 5 - vx * width / 2, tip[1] - uy * 5 - vy * width / 2),
        (start[0] - vx * width / 2, start[1] - vy * width / 2),
    ]
    draw.polygon(points, fill=color)
    draw.line([start, tip], fill=GOLD, width=2)


def shield(draw, fill=IRON):
    draw.polygon([(32, 10), (50, 19), (47, 43), (32, 55), (17, 43), (14, 19)], fill=fill)
    draw.polygon([(32, 16), (44, 22), (42, 39), (32, 48), (22, 39), (20, 22)], fill=DARK)
    draw.line([(32, 17), (32, 47)], fill=CREAM, width=3)


def draw_active(draw, name, index):
    if name in {"dashslash", "desperaterush"}:
        draw.line([(9, 48), (24, 34), (39, 37), (55, 15)], fill=CRIMSON, width=7)
        blade(draw, -42, center=(36, 30))
        if name == "desperaterush":
            draw.polygon([(43, 10), (57, 12), (52, 25)], fill=RED)
    elif name in {"groundwave", "mountainbreak", "cataclysm"}:
        blade(draw, 72, center=(31, 24))
        rings = 2 if name != "cataclysm" else 3
        for i in range(rings):
            inset = 10 + i * 6
            draw.arc((inset, 30 + i * 2, 64 - inset, 58 - i * 2), 185, 355, fill=(GOLD, RED, CREAM)[i], width=3)
        if name == "mountainbreak":
            draw.line([(32, 36), (24, 55), (34, 45), (40, 56)], fill=CRIMSON, width=3)
    elif name == "ironstance":
        shield(draw)
        blade(draw, -90, length=30, width=5, center=(32, 33), color=GOLD)
    elif name == "riposte":
        draw.arc((9, 10, 55, 54), 205, 25, fill=RED, width=6)
        blade(draw, -32, center=(34, 31))
        draw.ellipse((27, 27, 37, 37), fill=CREAM)
    elif name == "whirlwind":
        for inset, color in [(10, CRIMSON), (16, GOLD), (22, CREAM)]:
            draw.arc((inset, inset, 64 - inset, 64 - inset), 25, 330, fill=color, width=4)
        blade(draw, -20, length=27, width=5)
    elif name == "warcry":
        draw.ellipse((22, 22, 42, 42), fill=CRIMSON)
        for angle in range(0, 360, 45):
            draw.line([polar(32, 32, 12, angle), polar(32, 32, 24, angle)], fill=GOLD, width=4)
        draw.ellipse((28, 28, 36, 36), fill=CREAM)
    elif name == "chainassault":
        for angle, center in [(-35, (23, 22)), (35, (40, 30)), (-20, (29, 44))]:
            blade(draw, angle, length=25, width=4, center=center, color=(CREAM, GOLD, RED)[abs(angle) % 3])
    elif name == "shieldbreak":
        shield(draw, fill=(92, 88, 82, 255))
        blade(draw, 45, length=48, width=8, color=RED)
        draw.line([(18, 18), (28, 28), (22, 38), (34, 48)], fill=CREAM, width=3)
    elif name == "bloodrage":
        draw.polygon([(32, 8), (47, 31), (41, 49), (32, 56), (23, 49), (17, 31)], fill=CRIMSON)
        draw.polygon([(32, 18), (40, 32), (36, 45), (28, 45), (24, 32)], fill=RED)
        draw.ellipse((28, 31, 36, 39), fill=CREAM)
    else:
        blade(draw, -45 + index * 13)


def draw_passive(draw, name, index):
    rng = random.Random(8200 + index)
    if name in {"heavyarm", "ironskin", "immovable"}:
        shield(draw, fill=IRON if name != "immovable" else GOLD)
        if name == "heavyarm":
            draw.rectangle((12, 34, 52, 43), fill=CRIMSON)
        elif name == "ironskin":
            for x in (23, 32, 41):
                draw.line([(x, 18), (x, 46)], fill=CREAM, width=2)
        else:
            draw.rectangle((12, 48, 52, 54), fill=CREAM)
    elif name in {"bloodinstinct", "bloodthirst", "scarheal"}:
        draw.polygon([(32, 9), (47, 30), (42, 47), (32, 55), (22, 47), (17, 30)], fill=CRIMSON)
        draw.ellipse((25, 27, 39, 41), fill=RED)
        if name == "scarheal":
            draw.line([(32, 23), (32, 45)], fill=CREAM, width=5)
            draw.line([(22, 34), (42, 34)], fill=CREAM, width=5)
        elif name == "bloodthirst":
            draw.polygon([(22, 26), (42, 26), (32, 47)], fill=CREAM)
        else:
            blade(draw, -45, length=26, width=4, center=(33, 34), color=CREAM)
    elif name in {"breaksight", "lethalfocus"}:
        draw.ellipse((10, 18, 54, 46), fill=GOLD)
        draw.ellipse((16, 22, 48, 42), fill=DARK)
        draw.ellipse((25, 25, 39, 39), fill=RED)
        draw.ellipse((29, 29, 35, 35), fill=CREAM)
        if name == "lethalfocus":
            for angle in (0, 90, 180, 270):
                draw.line([polar(32, 32, 17, angle), polar(32, 32, 25, angle)], fill=CREAM, width=2)
    elif name in {"laststand", "immortalscar"}:
        draw.ellipse((13, 13, 51, 51), outline=GOLD, width=5)
        draw.arc((19, 19, 45, 45), 45, 315, fill=CRIMSON, width=6)
        draw.line([(32, 18), (32, 47)], fill=CREAM, width=4)
        if name == "immortalscar":
            for angle in range(0, 360, 60):
                draw.ellipse((*polar(32, 32, 23, angle), *polar(32, 32, 23, angle)), fill=CREAM)
    elif name == "toughbone":
        draw.line([(17, 18), (47, 46)], fill=CREAM, width=9)
        draw.line([(47, 18), (17, 46)], fill=CREAM, width=9)
        for x, y in [(15, 16), (49, 48), (49, 16), (15, 48)]:
            draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=GOLD)
    elif name == "battlelust":
        for y, width, color in [(47, 38, CRIMSON), (37, 28, RED), (27, 18, GOLD)]:
            draw.polygon([(32 - width // 2, y), (32, y - 18), (32 + width // 2, y)], fill=color)
    elif name == "veteran":
        draw.ellipse((14, 14, 50, 50), fill=GOLD)
        draw.ellipse((20, 20, 44, 44), fill=DARK)
        draw.polygon([(32, 18), (37, 28), (49, 29), (40, 37), (43, 49), (32, 42), (21, 49), (24, 37), (15, 29), (27, 28)], fill=CREAM)
    else:
        for _ in range(5):
            x, y = rng.randint(14, 46), rng.randint(14, 46)
            draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(CRIMSON, GOLD, CREAM)[rng.randrange(3)])


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for passive, names in ((False, ACTIVE), (True, PASSIVE)):
        for index, name in enumerate(names):
            image, draw = base(passive)
            (draw_passive if passive else draw_active)(draw, name, index)
            path = OUT / f"ws_{name}.png"
            image.save(path)
            print("wrote", path.name)
    print("done")


if __name__ == "__main__":
    main()
