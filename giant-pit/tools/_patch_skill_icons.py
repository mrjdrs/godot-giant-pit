# -*- coding: utf-8 -*-
import re
from pathlib import Path

p = Path(r"G:/code/godot-project/godot-giant-pit/giant-pit/scripts/skills/skill_catalog.gd")
t = p.read_text(encoding="utf-8")
mapping = {
    "hw_caliber": "gun_caliber.png",
    "hw_sidestep": "gun_sidestep.png",
    "hw_piercer": "gun_piercer.png",
    "hw_grenade": "gun_grenade.png",
    "hw_reload": "gun_reload.png",
    "hw_burst": "gun_burst.png",
    "hw_mine": "gun_mine.png",
    "hw_brace": "gun_brace.png",
    "hw_rail": "gun_rail.png",
    "hw_artillery": "gun_artillery.png",
    "hw_overclock": "gun_overclock.png",
    "mg_ember": "flame_ember.png",
    "mg_blink": "flame_blink.png",
    "mg_bolt": "flame_bolt.png",
    "mg_nova": "flame_nova.png",
    "mg_focus": "flame_focus.png",
    "mg_lash": "flame_lash.png",
    "mg_ring": "flame_ring.png",
    "mg_ward": "flame_ward.png",
    "mg_cascade": "flame_cascade.png",
    "mg_meteor": "flame_meteor.png",
    "mg_cataclysm": "flame_cataclysm.png",
}
lines = t.splitlines(True)
out = []
current = None
for line in lines:
    m = re.match(r'\t"(hw_\w+|mg_\w+)": \{', line)
    if m:
        current = m.group(1)
    if current and '"icon":' in line and current in mapping:
        line = re.sub(
            r'res://assets/ui/icons/skills/[^"]+',
            f"res://assets/ui/icons/skills/{mapping[current]}",
            line,
        )
        current = None
    out.append(line)
text = "".join(out)
p.write_text(text, encoding="utf-8")
missing = [k for k, v in mapping.items() if v not in text]
print("missing", missing)
print("done")
