# -*- coding: utf-8 -*-
from pathlib import Path
import re
t = Path(r"G:/code/godot-project/godot-giant-pit/giant-pit/scripts/skills/skill_catalog.gd").read_text(encoding="utf-8")
# skill def keys only
keys = re.findall(r'^\t"(m[a-z]+_[a-z_]+)": \{', t, re.M)
print("mage def keys:", keys)
print("count", len(keys))
