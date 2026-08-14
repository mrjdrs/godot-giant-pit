# -*- coding: utf-8 -*-
"""Generate affinity (nat_*) skill icons."""
from PIL import Image, ImageDraw
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets" / "ui" / "icons" / "skills"
BG = (22, 28, 18, 255)
BORDER = (139, 107, 184, 255)
HI = (180, 230, 120, 255)
MID = (90, 170, 70, 255)
LO = (48, 92, 40, 255)
ACCENT = (232, 196, 80, 255)


def base():
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((1, 1, 62, 62), radius=12, fill=BG, outline=(42, 31, 24, 255), width=1)
    d.rounded_rectangle((3, 3, 60, 60), radius=11, outline=BORDER, width=4)
    return im, d


def save(im, name):
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / name)
    print("wrote", name)


def nat_grove():
    im, d = base()
    d.ellipse((22, 28, 42, 52), fill=LO)
    d.polygon([(32, 10), (18, 34), (46, 34)], fill=MID)
    d.polygon([(32, 16), (24, 32), (40, 32)], fill=HI)
    d.ellipse((28, 36, 36, 44), fill=ACCENT)
    save(im, "nat_grove.png")


def nat_leafstep():
    im, d = base()
    d.polygon([(12, 40), (28, 18), (36, 24), (22, 46)], fill=MID)
    d.polygon([(14, 38), (28, 20), (32, 24), (20, 42)], fill=HI)
    d.line([(36, 28), (52, 16)], fill=ACCENT, width=3)
    d.ellipse((48, 12, 56, 20), fill=HI)
    save(im, "nat_leafstep.png")


def nat_thorn():
    im, d = base()
    d.polygon([(10, 36), (40, 28), (54, 20), (42, 34), (16, 44)], fill=MID)
    d.polygon([(40, 28), (54, 20), (48, 32)], fill=HI)
    d.polygon([(22, 18), (28, 30), (16, 28)], fill=LO)
    save(im, "nat_thorn.png")


def nat_whirl():
    im, d = base()
    d.ellipse((16, 16, 48, 48), outline=MID, width=4)
    d.ellipse((22, 22, 42, 42), outline=HI, width=2)
    d.polygon([(32, 8), (36, 20), (28, 20)], fill=ACCENT)
    d.polygon([(52, 32), (40, 36), (40, 28)], fill=HI)
    save(im, "nat_whirl.png")


if __name__ == "__main__":
    nat_grove()
    nat_leafstep()
    nat_thorn()
    nat_whirl()
