# -*- coding: utf-8 -*-
"""Regenerate imprint skill icons with multi-tone family palettes (like blade_*)."""
from PIL import Image, ImageDraw
from pathlib import Path
import math

OUT = Path(r"G:/code/godot-project/godot-giant-pit/giant-pit/assets/ui/icons/skills")
BG = (28, 18, 12, 255)

# Cold blade reference: cream / gold / deep gold layers
# Gun: teal steel border + brass / copper / white core
GUN_BORDER = (78, 196, 200, 255)
GUN_HI = (220, 245, 248, 255)
GUN_MID = (232, 176, 80, 255)
GUN_LO = (196, 110, 48, 255)
GUN_ACCENT = (255, 120, 64, 255)

# Mage: violet border + orange flame / yellow core / magenta accent
MAGE_BORDER = (176, 108, 255, 255)
MAGE_HI = (255, 224, 128, 255)
MAGE_MID = (255, 106, 40, 255)
MAGE_LO = (220, 48, 72, 255)
MAGE_ACCENT = (255, 80, 200, 255)


def base(border):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((1, 1, 62, 62), radius=12, fill=BG, outline=(0, 0, 0, 255), width=1)
    d.rounded_rectangle((3, 3, 60, 60), radius=11, outline=border, width=4)
    return im, d


def save(im, name):
    im.save(OUT / name)
    print("wrote", name)


def tri(d, pts, fill):
    d.polygon(pts, fill=fill)


# ---- GUN ----
def gun_caliber():
    im, d = base(GUN_BORDER)
    d.ellipse((16, 16, 48, 48), outline=GUN_HI, width=3)
    d.ellipse((20, 20, 44, 44), outline=GUN_MID, width=2)
    d.ellipse((28, 28, 36, 36), fill=GUN_ACCENT)
    d.ellipse((30, 30, 34, 34), fill=GUN_HI)
    for a, b in [((32, 8), (32, 14)), ((32, 50), (32, 56)), ((8, 32), (14, 32)), ((50, 32), (56, 32))]:
        d.line([a, b], fill=GUN_MID, width=3)
    save(im, "gun_caliber.png")


def gun_sidestep():
    im, d = base(GUN_BORDER)
    d.line([(10, 46), (24, 30), (32, 36)], fill=GUN_LO, width=5)
    d.line([(12, 44), (26, 28), (34, 34), (50, 16)], fill=GUN_HI, width=3)
    d.polygon([(44, 12), (56, 12), (56, 24)], fill=GUN_MID)
    d.ellipse((48, 10, 58, 20), fill=GUN_ACCENT)
    d.ellipse((51, 13, 55, 17), fill=GUN_HI)
    save(im, "gun_sidestep.png")


def gun_piercer():
    im, d = base(GUN_BORDER)
    d.polygon([(8, 36), (40, 28), (58, 32), (40, 36)], fill=GUN_LO)
    d.polygon([(12, 34), (40, 30), (54, 32), (40, 34)], fill=GUN_MID)
    d.polygon([(30, 31), (52, 32), (30, 33)], fill=GUN_HI)
    d.ellipse((10, 28, 20, 38), fill=GUN_BORDER)
    save(im, "gun_piercer.png")


def gun_grenade():
    im, d = base(GUN_BORDER)
    d.ellipse((16, 22, 48, 54), fill=GUN_LO)
    d.ellipse((20, 26, 44, 50), fill=GUN_MID)
    d.ellipse((26, 32, 38, 44), fill=GUN_HI)
    d.rectangle((27, 14, 37, 24), fill=GUN_BORDER)
    d.arc((36, 6, 54, 24), 200, 330, fill=GUN_ACCENT, width=3)
    d.ellipse((48, 8, 56, 16), fill=GUN_ACCENT)
    save(im, "gun_grenade.png")


def gun_reload():
    im, d = base(GUN_BORDER)
    d.ellipse((14, 14, 50, 50), outline=GUN_HI, width=3)
    cols = [GUN_ACCENT, GUN_MID, GUN_MID, GUN_LO, GUN_MID, GUN_MID]
    for i, (cx, cy) in enumerate([(32, 18), (43, 25), (43, 39), (32, 46), (21, 39), (21, 25)]):
        d.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=cols[i])
        d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=GUN_HI)
    d.polygon([(46, 10), (58, 8), (52, 20)], fill=GUN_ACCENT)
    save(im, "gun_reload.png")


def gun_burst():
    im, d = base(GUN_BORDER)
    for i, (y, c) in enumerate([(18, GUN_HI), (30, GUN_MID), (42, GUN_LO)]):
        x = 10 + i * 7
        d.ellipse((x, y - 5, x + 26, y + 5), fill=c)
        d.ellipse((x + 18, y - 2, x + 24, y + 2), fill=GUN_ACCENT if i == 2 else GUN_HI)
    save(im, "gun_burst.png")


def gun_mine():
    im, d = base(GUN_BORDER)
    d.ellipse((16, 20, 48, 52), fill=GUN_LO)
    d.ellipse((22, 26, 42, 46), fill=GUN_MID)
    for ang in range(0, 360, 45):
        a = math.radians(ang)
        x1, y1 = 32 + 10 * math.cos(a), 36 + 10 * math.sin(a)
        x2, y2 = 32 + 18 * math.cos(a), 36 + 18 * math.sin(a)
        d.line([(x1, y1), (x2, y2)], fill=GUN_HI, width=3)
    d.ellipse((28, 32, 36, 40), fill=GUN_ACCENT)
    save(im, "gun_mine.png")


def gun_brace():
    im, d = base(GUN_BORDER)
    d.polygon([(14, 42), (26, 16), (38, 16), (50, 42)], fill=GUN_LO)
    d.polygon([(18, 40), (28, 20), (36, 20), (46, 40)], fill=GUN_MID)
    d.rectangle((18, 36, 46, 50), fill=GUN_BORDER)
    d.line([(16, 28), (48, 28)], fill=GUN_HI, width=3)
    save(im, "gun_brace.png")


def gun_rail():
    im, d = base(GUN_BORDER)
    d.rectangle((8, 26, 56, 38), fill=GUN_LO)
    d.rectangle((10, 28, 54, 36), fill=GUN_MID)
    d.rectangle((12, 30, 52, 34), fill=GUN_HI)
    d.polygon([(48, 22), (60, 32), (48, 42)], fill=GUN_ACCENT)
    d.ellipse((10, 24, 20, 40), fill=GUN_BORDER)
    save(im, "gun_rail.png")


def gun_artillery():
    im, d = base(GUN_BORDER)
    d.polygon([(22, 14), (42, 14), (38, 32), (26, 32)], fill=GUN_MID)
    d.ellipse((20, 32, 44, 52), fill=GUN_LO)
    d.ellipse((24, 36, 40, 48), fill=GUN_ACCENT)
    d.polygon([(18, 40), (10, 54), (24, 48)], fill=GUN_HI)
    d.polygon([(46, 40), (54, 54), (40, 48)], fill=GUN_HI)
    save(im, "gun_artillery.png")


def gun_overclock():
    im, d = base(GUN_BORDER)
    d.ellipse((24, 24, 40, 40), fill=GUN_LO)
    d.ellipse((28, 28, 36, 36), fill=GUN_HI)
    for i in range(5):
        a = math.radians(-50 + i * 25)
        x2, y2 = 32 + 22 * math.cos(a), 32 + 22 * math.sin(a)
        d.line([(32, 32), (x2, y2)], fill=GUN_MID if i % 2 == 0 else GUN_ACCENT, width=3)
        d.ellipse((x2 - 4, y2 - 4, x2 + 4, y2 + 4), fill=GUN_HI)
    save(im, "gun_overclock.png")


# ---- MAGE ----
def flame_ember():
    im, d = base(MAGE_BORDER)
    for cx, cy, r, c in [(22, 42, 7, MAGE_LO), (34, 34, 9, MAGE_MID), (44, 42, 5, MAGE_HI), (28, 26, 4, MAGE_ACCENT)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=c)
    d.ellipse((32, 30, 38, 36), fill=MAGE_HI)
    save(im, "flame_ember.png")


def flame_blink():
    im, d = base(MAGE_BORDER)
    d.ellipse((10, 28, 28, 46), outline=MAGE_MID, width=3)
    d.ellipse((14, 32, 24, 42), fill=MAGE_LO)
    d.ellipse((36, 16, 54, 34), outline=MAGE_HI, width=3)
    d.ellipse((40, 20, 50, 30), fill=MAGE_ACCENT)
    d.line([(26, 36), (40, 26)], fill=MAGE_MID, width=4)
    d.polygon([(38, 20), (52, 14), (48, 28)], fill=MAGE_HI)
    save(im, "flame_blink.png")


def flame_bolt():
    im, d = base(MAGE_BORDER)
    d.polygon([(10, 38), (26, 16), (54, 30), (26, 46), (18, 34)], fill=MAGE_LO)
    d.polygon([(18, 34), (28, 20), (46, 30), (28, 40)], fill=MAGE_MID)
    d.polygon([(26, 28), (38, 30), (26, 34)], fill=MAGE_HI)
    d.ellipse((30, 26, 38, 34), fill=MAGE_ACCENT)
    save(im, "flame_bolt.png")


def flame_nova():
    im, d = base(MAGE_BORDER)
    d.ellipse((22, 22, 42, 42), fill=MAGE_HI)
    d.ellipse((26, 26, 38, 38), fill=MAGE_ACCENT)
    for i in range(8):
        a = i * math.pi / 4
        x1, y1 = 32 + 8 * math.cos(a), 32 + 8 * math.sin(a)
        x2, y2 = 32 + 22 * math.cos(a), 32 + 22 * math.sin(a)
        d.line([(x1, y1), (x2, y2)], fill=MAGE_MID if i % 2 == 0 else MAGE_LO, width=4)
    save(im, "flame_nova.png")


def flame_focus():
    im, d = base(MAGE_BORDER)
    d.ellipse((14, 14, 50, 50), outline=MAGE_MID, width=3)
    d.ellipse((20, 20, 44, 44), outline=MAGE_ACCENT, width=2)
    d.ellipse((26, 26, 38, 38), fill=MAGE_LO)
    d.ellipse((28, 28, 36, 36), fill=MAGE_HI)
    d.polygon([(32, 8), (38, 18), (26, 18)], fill=MAGE_MID)
    save(im, "flame_focus.png")


def flame_lash():
    im, d = base(MAGE_BORDER)
    d.arc((8, 12, 56, 56), 200, 50, fill=MAGE_LO, width=7)
    d.arc((14, 18, 50, 50), 210, 40, fill=MAGE_MID, width=4)
    d.arc((18, 22, 46, 46), 220, 30, fill=MAGE_HI, width=2)
    d.ellipse((44, 14, 56, 26), fill=MAGE_ACCENT)
    d.ellipse((48, 18, 54, 24), fill=MAGE_HI)
    save(im, "flame_lash.png")


def flame_ring():
    im, d = base(MAGE_BORDER)
    d.ellipse((12, 12, 52, 52), outline=MAGE_LO, width=6)
    d.ellipse((18, 18, 46, 46), outline=MAGE_MID, width=4)
    d.ellipse((24, 24, 40, 40), outline=MAGE_HI, width=2)
    d.ellipse((28, 28, 36, 36), fill=MAGE_ACCENT)
    save(im, "flame_ring.png")


def flame_ward():
    im, d = base(MAGE_BORDER)
    d.polygon([(32, 10), (52, 20), (48, 48), (32, 56), (16, 48), (12, 20)], fill=MAGE_LO)
    d.polygon([(32, 16), (46, 24), (44, 44), (32, 50), (20, 44), (18, 24)], fill=MAGE_MID)
    d.polygon([(32, 22), (40, 28), (38, 40), (32, 44), (26, 40), (24, 28)], fill=MAGE_HI)
    d.ellipse((28, 28, 36, 36), fill=MAGE_ACCENT)
    save(im, "flame_ward.png")


def flame_cascade():
    im, d = base(MAGE_BORDER)
    cols = [MAGE_LO, MAGE_MID, MAGE_HI]
    for i, y in enumerate([16, 28, 40]):
        w = 12 + i * 7
        c = cols[i]
        d.polygon([(32 - w, y + 10), (32, y), (32 + w, y + 10), (32, y + 5)], fill=c)
    d.ellipse((28, 8, 36, 16), fill=MAGE_ACCENT)
    save(im, "flame_cascade.png")


def flame_meteor():
    im, d = base(MAGE_BORDER)
    d.ellipse((26, 8, 46, 28), fill=MAGE_HI)
    d.ellipse((30, 12, 42, 24), fill=MAGE_ACCENT)
    d.polygon([(34, 24), (14, 54), (28, 46), (34, 56), (40, 44), (52, 52)], fill=MAGE_MID)
    d.polygon([(34, 28), (22, 48), (34, 42), (40, 50)], fill=MAGE_LO)
    save(im, "flame_meteor.png")


def flame_cataclysm():
    im, d = base(MAGE_BORDER)
    d.ellipse((14, 14, 50, 50), fill=MAGE_LO)
    d.ellipse((20, 20, 44, 44), fill=MAGE_MID)
    d.ellipse((26, 26, 38, 38), fill=MAGE_HI)
    d.ellipse((28, 28, 36, 36), fill=MAGE_ACCENT)
    for i in range(4):
        a = i * math.pi / 2 + 0.4
        x2, y2 = 32 + 24 * math.cos(a), 32 + 24 * math.sin(a)
        d.line([(32, 32), (x2, y2)], fill=MAGE_HI, width=4)
    save(im, "flame_cataclysm.png")


def main():
    for fn in [
        gun_caliber, gun_sidestep, gun_piercer, gun_grenade, gun_reload, gun_burst,
        gun_mine, gun_brace, gun_rail, gun_artillery, gun_overclock,
        flame_ember, flame_blink, flame_bolt, flame_nova, flame_focus, flame_lash,
        flame_ring, flame_ward, flame_cascade, flame_meteor, flame_cataclysm,
    ]:
        fn()
    print("done")


if __name__ == "__main__":
    main()
