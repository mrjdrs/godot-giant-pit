# -*- coding: utf-8 -*-
from pathlib import Path
import re

p = Path(r"G:/code/godot-project/godot-giant-pit/giant-pit/scripts/skills/skill_catalog.gd")
t = p.read_text(encoding="utf-8")
ids = sorted(set(re.findall(r'"(mg_[a-z_]+)"', t)))
print(ids)

# Rename remaining mg_* skill keys (not already in LEGACY as source keys we want to keep)
# Keep legacy map keys mg_ember etc. — rename only skill def keys and prereqs that still use old names
# Safer: rename specific leftover skill ids
leftover = [
    "mg_focus", "mg_lash", "mg_ring", "mg_cascade",
]
for old in leftover:
    new = "mgf_" + old[3:]
    t = t.replace(f'"{old}"', f'"{new}"')

# Fix LEGACY map: restore proper mg_* -> mgf_* and add leftover
legacy_block = '''const LEGACY_SKILL_MAP := {
	"core_s_chain": "sk_chain",
	"rune_s_chain": "sk_chain",
	"core_s_quake": "sk_quake",
	"rune_s_quake": "sk_quake",
	"core_s_dash": "sk_dash",
	"rune_s_cloudstep": "sk_dash",
	"core_s_bolt": "sk_bolt",
	"core_s_whirl": "sk_whirl",
	"core_s_smash": "sk_smash",
	"rune_s_ironwall": "sk_ironwall",
	"mg_ember": "mgf_ember",
	"mg_blink": "mgf_blink",
	"mg_bolt": "mgf_bolt",
	"mg_nova": "mgf_nova",
	"mg_focus": "mgf_focus",
	"mg_lash": "mgf_lash",
	"mg_ring": "mgf_ring",
	"mg_ward": "mgf_ward",
	"mg_cascade": "mgf_cascade",
	"mg_meteor": "mgf_meteor",
	"mg_cataclysm": "mgf_cataclysm",
}'''

t2 = re.sub(r"const LEGACY_SKILL_MAP := \{.*?\n\}", legacy_block, t, count=1, flags=re.S)
if t2 == t:
    raise SystemExit("legacy replace failed")
p.write_text(t2, encoding="utf-8")
ids2 = sorted(set(re.findall(r'"(mg_[a-z_]+)"', t2)))
print("remaining mg_", ids2)
print("mgf keys", sorted(set(re.findall(r'"(mgf_[a-z_]+)"', t2))))
