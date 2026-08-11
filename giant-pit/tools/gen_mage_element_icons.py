# -*- coding: utf-8 -*-
"""Generate five-element mage skill icons."""
from PIL import Image, ImageDraw
from pathlib import Path

OUT = Path(r"G:/code/godot-project/godot-giant-pit/giant-pit/assets/ui/icons/skills")
BG = (28, 18, 12, 255)

PALETTES = {
    "ice": {
        "border": (120, 190, 255, 255),
        "hi": (230, 250, 255, 255),
        "mid": (120, 200, 255, 255),
        "lo": (60, 120, 200, 255),
        "accent": (180, 240, 255, 255),
    },
    "acid": {
        "border": (160, 220, 40, 255),
        "hi": (220, 255, 120, 255),
        "mid": (140, 210, 40, 255),
        "lo": (80, 140, 20, 255),
        "accent": (255, 255, 80, 255),
    },
    "dark": {
        "border": (140, 70, 220, 255),
        "hi": (200, 150, 255, 255),
        "mid": (90, 40, 150, 255),
        "lo": (40, 10, 70, 255),
        "accent": (255, 80, 200, 255),
    },
    "light": {
        "border": (255, 210, 90, 255),
        "hi": (255, 250, 220, 255),
        "mid": (255, 220, 120, 255),
        "lo": (200, 150, 40, 255),
        "accent": (255, 255, 255, 255),
    },
}


def base(border):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((1, 1, 62, 62), radius=12, fill=BG, outline=(0, 0, 0, 255), width=1)
    d.rounded_rectangle((3, 3, 60, 60), radius=11, outline=border, width=4)
    return im, d


def save(im, name):
    im.save(OUT / name)
    print("wrote", name)


def mark(pal, name, kind):
    im, d = base(pal["border"])
    if kind == "passive":
        d.ellipse((18, 18, 46, 46), outline=pal["hi"], width=3)
        d.ellipse((24, 24, 40, 40), fill=pal["mid"])
        d.ellipse((28, 28, 36, 36), fill=pal["accent"])
    elif kind == "step":
        d.line([(12, 48), (28, 28), (36, 34)], fill=pal["lo"], width=5)
        d.line([(14, 46), (30, 26), (38, 32), (52, 14)], fill=pal["hi"], width=3)
        d.ellipse((46, 10, 58, 22), fill=pal["mid"])
        d.ellipse((50, 14, 54, 18), fill=pal["accent"])
    elif kind == "bolt":
        d.polygon([(10, 34), (42, 26), (56, 32), (42, 38)], fill=pal["lo"])
        d.polygon([(14, 32), (42, 28), (52, 32), (42, 36)], fill=pal["mid"])
        d.polygon([(28, 30), (50, 32), (28, 34)], fill=pal["hi"])
    elif kind == "nova":
        d.ellipse((14, 14, 50, 50), outline=pal["mid"], width=3)
        d.ellipse((22, 22, 42, 42), outline=pal["hi"], width=2)
        d.ellipse((28, 28, 36, 36), fill=pal["accent"])
        for a, b in [((32, 6), (32, 14)), ((32, 50), (32, 58)), ((6, 32), (14, 32)), ((50, 32), (58, 32))]:
            d.line([a, b], fill=pal["lo"], width=3)
    elif kind == "ward":
        d.polygon([(32, 10), (52, 20), (48, 46), (32, 56), (16, 46), (12, 20)], outline=pal["hi"], fill=pal["lo"])
        d.polygon([(32, 16), (46, 24), (42, 42), (32, 50), (22, 42), (18, 24)], fill=pal["mid"])
        d.ellipse((28, 28, 36, 36), fill=pal["accent"])
    save(im, name)


def main():
    specs = [
        ("ice", "ice_frostmark.png", "passive"),
        ("ice", "ice_froststep.png", "step"),
        ("ice", "ice_shard.png", "bolt"),
        ("ice", "ice_rime.png", "nova"),
        ("acid", "acid_stain.png", "passive"),
        ("acid", "acid_flash.png", "step"),
        ("acid", "acid_spit.png", "bolt"),
        ("acid", "acid_cloud.png", "nova"),
        ("dark", "dark_shadowbite.png", "passive"),
        ("dark", "dark_shadowstep.png", "step"),
        ("dark", "dark_bolt.png", "bolt"),
        ("dark", "dark_vortex.png", "nova"),
        ("light", "light_grace.png", "passive"),
        ("light", "light_step.png", "step"),
        ("light", "light_ray.png", "bolt"),
        ("light", "light_aegis.png", "ward"),
    ]
    for elem, fname, kind in specs:
        mark(PALETTES[elem], fname, kind)
    print("done")


if __name__ == "__main__":
    main()
