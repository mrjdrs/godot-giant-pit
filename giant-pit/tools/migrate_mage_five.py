# -*- coding: utf-8 -*-
"""Transform skill_catalog.gd for five mage element families."""
from __future__ import annotations

import re
from pathlib import Path

CATALOG = Path(r"G:/code/godot-project/godot-giant-pit/giant-pit/scripts/skills/skill_catalog.gd")

MG_IDS = [
    "mg_ember",
    "mg_blink",
    "mg_bolt",
    "mg_nova",
    "mg_ward",
    "mg_meteor",
    "mg_pyre",
    "mg_conduit",
    "mg_erupt",
    "mg_phoenix",
    "mg_cataclysm",
]


def rename_mg_to_mgf(text: str) -> str:
    # Longest first to avoid partial replaces
    for old in sorted(MG_IDS, key=len, reverse=True):
        new = "mgf_" + old[3:]
        text = text.replace(f'"{old}"', f'"{new}"')
        text = text.replace(f"'{old}'", f"'{new}'")
    return text


HEADER_OLD = '''extends RefCounted
## 烙印技能树（冷兵器·刀 / 热武器·火铳 / 魔元素·焰咒）。晶核加点，释放耗念力。

const HOTKEY_SLOTS := ["rmb", "q", "e", "r", "f", "c"]
const CRYSTAL_ID := "crystal_core"
const COL_SLASH := 0 ## 斩
const COL_BREAK := 1 ## 破
const COL_FORCE := 2 ## 势
const ROW_LEVELS := [1, 5, 10, 15]
const FAMILY_COLD := "cold_blade"
const FAMILY_HOT := "hot_gun"
const FAMILY_MAGE := "mage_flame"
const INNATE_BY_FAMILY := {
	FAMILY_COLD: ["sk_chain", "sk_dash"],
	FAMILY_HOT: ["hw_caliber", "hw_sidestep"],
	FAMILY_MAGE: ["mg_ember", "mg_blink"],
}
const INNATE_IDS := ["sk_chain", "sk_dash"] ## 兼容；优先 innate_ids_for()
const LEGACY_SKILL_MAP := {
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
}'''

HEADER_NEW = '''extends RefCounted
## 烙印技能树（冷兵器·刀 / 热武器·火铳 / 魔元素五系）。晶核加点，释放耗念力。

const HOTKEY_SLOTS := ["rmb", "q", "e", "r", "f", "c"]
const CRYSTAL_ID := "crystal_core"
const COL_SLASH := 0 ## 斩
const COL_BREAK := 1 ## 破
const COL_FORCE := 2 ## 势
const ROW_LEVELS := [1, 5, 10, 15, 20]
const FAMILY_COLD := "cold_blade"
const FAMILY_HOT := "hot_gun"
const FAMILY_MAGE := "mage" ## 烙印：魔（兼容旧 mage_flame）
const FAMILY_MAGE_FLAME_LEGACY := "mage_flame"
const FAMILY_MAGE_FIRE := "mage_fire"
const FAMILY_MAGE_ICE := "mage_ice"
const FAMILY_MAGE_ACID := "mage_acid"
const FAMILY_MAGE_DARK := "mage_dark"
const FAMILY_MAGE_LIGHT := "mage_light"
const MAGE_ELEMENTS := ["fire", "ice", "acid", "dark", "light"]
const MAGE_FAMILY_BY_ELEMENT := {
	"fire": FAMILY_MAGE_FIRE,
	"ice": FAMILY_MAGE_ICE,
	"acid": FAMILY_MAGE_ACID,
	"dark": FAMILY_MAGE_DARK,
	"light": FAMILY_MAGE_LIGHT,
}
const INNATE_BY_FAMILY := {
	FAMILY_COLD: ["sk_chain", "sk_dash"],
	FAMILY_HOT: ["hw_caliber", "hw_sidestep"],
	FAMILY_MAGE_FIRE: ["mgf_ember", "mgf_blink"],
	FAMILY_MAGE_ICE: ["mgi_frostmark", "mgi_froststep"],
	FAMILY_MAGE_ACID: ["mga_stain", "mga_acidflash"],
	FAMILY_MAGE_DARK: ["mgd_shadowbite", "mgd_shadowstep"],
	FAMILY_MAGE_LIGHT: ["mgl_grace", "mgl_lightstep"],
	## 烙印级兼容：默认火系天生
	FAMILY_MAGE: ["mgf_ember", "mgf_blink"],
	FAMILY_MAGE_FLAME_LEGACY: ["mgf_ember", "mgf_blink"],
}
const INNATE_IDS := ["sk_chain", "sk_dash"] ## 兼容；优先 innate_ids_for()
const LEGACY_SKILL_MAP := {
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
	"mg_ward": "mgf_ward",
	"mg_meteor": "mgf_meteor",
	"mg_pyre": "mgf_pyre",
	"mg_conduit": "mgf_conduit",
	"mg_erupt": "mgf_erupt",
	"mg_phoenix": "mgf_phoenix",
	"mg_cataclysm": "mgf_cataclysm",
}'''

SKELETON = r'''
	"mgi_frostmark": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.frostmark",
		"icon": "res://assets/ui/icons/skills/ice_frostmark.png",
		"kind": "passive",
		"col": 0,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"chill_slow": 0.22, "chill_slow_per": 0.04, "chill_time": 2.4, "light_dmg": 0.05, "light_dmg_per": 0.03},
	},
	"mgi_froststep": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.froststep",
		"icon": "res://assets/ui/icons/skills/ice_froststep.png",
		"kind": "active",
		"col": 2,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": [10, 11, 12, 13, 14],
		"cooldown": [2.4, 2.3, 2.2, 2.1, 2.0],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_blink",
			"element": "ice",
			"status": "chill",
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(42, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 9.0,
			"damage_per_rank": 2.0,
			"knockback": 90.0,
			"poise": 8.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
		},
		"fx": {
			"id": "ice_step",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
			"ghost": true,
		},
	},
	"mgi_shard": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.shard",
		"icon": "res://assets/ui/icons/skills/ice_shard.png",
		"kind": "active",
		"col": 0,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgi_frostmark": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [1.9, 1.8, 1.7, 1.6, 1.45],
		"range": [210.0, 220.0, 230.0, 245.0, 260.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "ice",
			"status": "chill",
			"windup": 0.09,
			"active": 0.10,
			"recovery": 0.14,
			"swing_from": -36.0,
			"swing_to": 18.0,
			"hit_size": Vector2(18, 14),
			"hit_offset": Vector2(22, 0),
			"damage": 11.0,
			"damage_per_rank": 2.2,
			"knockback": 70.0,
			"poise": 7.0,
			"lunge": 4.0,
			"chill_slow": 0.3,
			"chill_time": 2.2,
			"chill_stacks": 1,
		},
		"fx": {
			"id": "ice_shard",
			"trail_color": Color(0.45, 0.78, 1.0, 1.0),
			"flash_color": Color(0.75, 0.95, 1.0, 0.55),
			"trail_width": 4.0,
			"flash_radius": 18.0,
		},
	},
	"mgi_rime": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.rime",
		"icon": "res://assets/ui/icons/skills/ice_rime.png",
		"kind": "active",
		"col": 1,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgi_frostmark": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [20, 22, 24, 26, 28],
		"cooldown": [3.2, 3.0, 2.8, 2.6, 2.4],
		"range": [90.0, 96.0, 102.0, 110.0, 120.0],
		"loud": false,
		"combat": {
			"style": "mage_nova",
			"element": "ice",
			"status": "chill",
			"windup": 0.12,
			"active": 0.14,
			"recovery": 0.18,
			"swing_from": -20.0,
			"swing_to": 20.0,
			"hit_size": Vector2(70, 70),
			"hit_offset": Vector2(0, 0),
			"damage": 10.0,
			"damage_per_rank": 2.0,
			"knockback": 40.0,
			"poise": 6.0,
			"wave_radius": 56.0,
			"wave_radius_per_rank": 6.0,
			"chill_slow": 0.35,
			"chill_time": 2.6,
			"chill_stacks": 2,
		},
		"fx": {
			"id": "ice_rime",
			"trail_color": Color(0.6, 0.88, 1.0, 1.0),
			"flash_color": Color(0.8, 0.95, 1.0, 0.5),
			"flash_radius": 56.0,
		},
	},
	"mga_stain": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.stain",
		"icon": "res://assets/ui/icons/skills/acid_stain.png",
		"kind": "passive",
		"col": 0,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"corrode_amp": 0.12, "corrode_amp_per": 0.03, "corrode_time": 3.5, "pdef_cut": 2.0, "pdef_cut_per": 0.8},
	},
	"mga_acidflash": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.acidflash",
		"icon": "res://assets/ui/icons/skills/acid_flash.png",
		"kind": "active",
		"col": 2,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": [10, 11, 12, 13, 14],
		"cooldown": [2.4, 2.3, 2.2, 2.1, 2.0],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_blink",
			"element": "acid",
			"status": "corrode",
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(42, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 9.0,
			"damage_per_rank": 2.0,
			"knockback": 100.0,
			"poise": 8.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
		},
		"fx": {
			"id": "acid_step",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
			"ghost": true,
		},
	},
	"mga_spit": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.spit",
		"icon": "res://assets/ui/icons/skills/acid_spit.png",
		"kind": "active",
		"col": 0,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mga_stain": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [1.9, 1.8, 1.7, 1.6, 1.45],
		"range": [200.0, 210.0, 220.0, 235.0, 250.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "acid",
			"status": "corrode",
			"windup": 0.10,
			"active": 0.10,
			"recovery": 0.16,
			"swing_from": -30.0,
			"swing_to": 16.0,
			"hit_size": Vector2(20, 16),
			"hit_offset": Vector2(22, 0),
			"damage": 11.0,
			"damage_per_rank": 2.2,
			"knockback": 80.0,
			"poise": 7.0,
			"corrode_amp": 0.18,
			"corrode_time": 3.5,
			"pdef_cut": 4.0,
		},
		"fx": {
			"id": "acid_spit",
			"trail_color": Color(0.48, 0.9, 0.18, 1.0),
			"flash_color": Color(0.65, 1.0, 0.25, 0.5),
			"trail_width": 5.0,
			"flash_radius": 16.0,
		},
	},
	"mga_cloud": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.cloud",
		"icon": "res://assets/ui/icons/skills/acid_cloud.png",
		"kind": "active",
		"col": 1,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mga_stain": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [22, 24, 26, 28, 30],
		"cooldown": [3.4, 3.2, 3.0, 2.8, 2.55],
		"range": [96.0, 102.0, 110.0, 118.0, 128.0],
		"loud": false,
		"combat": {
			"style": "mage_nova",
			"element": "acid",
			"status": "corrode",
			"windup": 0.14,
			"active": 0.16,
			"recovery": 0.2,
			"hit_size": Vector2(72, 72),
			"hit_offset": Vector2(0, 0),
			"damage": 9.0,
			"damage_per_rank": 1.8,
			"knockback": 30.0,
			"poise": 5.0,
			"wave_radius": 60.0,
			"wave_radius_per_rank": 6.0,
			"corrode_amp": 0.22,
			"corrode_time": 4.0,
			"pdef_cut": 5.0,
		},
		"fx": {
			"id": "acid_cloud",
			"trail_color": Color(0.5, 0.88, 0.2, 1.0),
			"flash_color": Color(0.6, 0.95, 0.25, 0.45),
			"flash_radius": 60.0,
		},
	},
	"mgd_shadowbite": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.shadowbite",
		"icon": "res://assets/ui/icons/skills/dark_shadowbite.png",
		"kind": "passive",
		"col": 0,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"weaken_cut": 0.12, "weaken_cut_per": 0.03, "weaken_time": 3.5, "light_dmg": 0.04, "light_dmg_per": 0.03},
	},
	"mgd_shadowstep": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.shadowstep",
		"icon": "res://assets/ui/icons/skills/dark_shadowstep.png",
		"kind": "active",
		"col": 2,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": [10, 11, 12, 13, 14],
		"cooldown": [2.4, 2.3, 2.2, 2.1, 2.0],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_blink",
			"element": "dark",
			"status": "weaken",
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(42, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 9.0,
			"damage_per_rank": 2.0,
			"knockback": 100.0,
			"poise": 8.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
			"weaken_cut": 0.15,
			"weaken_time": 3.0,
		},
		"fx": {
			"id": "dark_step",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.45),
			"trail_width": 5.0,
			"flash_radius": 28.0,
			"ghost": true,
		},
	},
	"mgd_bolt": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.bolt",
		"icon": "res://assets/ui/icons/skills/dark_bolt.png",
		"kind": "active",
		"col": 0,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgd_shadowbite": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [1.9, 1.8, 1.7, 1.6, 1.45],
		"range": [210.0, 220.0, 230.0, 245.0, 260.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "dark",
			"status": "weaken",
			"windup": 0.10,
			"active": 0.10,
			"recovery": 0.15,
			"hit_size": Vector2(18, 14),
			"hit_offset": Vector2(22, 0),
			"damage": 11.0,
			"damage_per_rank": 2.2,
			"knockback": 75.0,
			"poise": 7.0,
			"weaken_cut": 0.18,
			"weaken_time": 3.5,
		},
		"fx": {
			"id": "dark_bolt",
			"trail_color": Color(0.42, 0.15, 0.7, 1.0),
			"flash_color": Color(0.3, 0.08, 0.5, 0.55),
			"trail_width": 4.0,
			"flash_radius": 16.0,
		},
	},
	"mgd_vortex": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.vortex",
		"icon": "res://assets/ui/icons/skills/dark_vortex.png",
		"kind": "active",
		"col": 1,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgd_shadowbite": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [22, 24, 26, 28, 30],
		"cooldown": [3.4, 3.2, 3.0, 2.8, 2.55],
		"range": [90.0, 96.0, 102.0, 110.0, 120.0],
		"loud": false,
		"combat": {
			"style": "mage_nova",
			"element": "dark",
			"status": "weaken",
			"windup": 0.14,
			"active": 0.16,
			"recovery": 0.2,
			"hit_size": Vector2(70, 70),
			"hit_offset": Vector2(0, 0),
			"damage": 9.0,
			"damage_per_rank": 1.8,
			"knockback": 20.0,
			"poise": 6.0,
			"wave_radius": 58.0,
			"wave_radius_per_rank": 6.0,
			"weaken_cut": 0.22,
			"weaken_time": 4.0,
		},
		"fx": {
			"id": "dark_vortex",
			"trail_color": Color(0.38, 0.12, 0.65, 1.0),
			"flash_color": Color(0.25, 0.06, 0.45, 0.5),
			"flash_radius": 58.0,
		},
	},
	"mgl_grace": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.grace",
		"icon": "res://assets/ui/icons/skills/light_grace.png",
		"kind": "passive",
		"col": 0,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"bless_hps": 1.5, "bless_hps_per": 0.6, "bless_shield": 6.0, "bless_shield_per": 2.0, "bless_time": 3.0},
	},
	"mgl_lightstep": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.lightstep",
		"icon": "res://assets/ui/icons/skills/light_step.png",
		"kind": "active",
		"col": 2,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": [10, 11, 12, 13, 14],
		"cooldown": [2.4, 2.3, 2.2, 2.1, 2.0],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_blink",
			"element": "light",
			"status": "bless",
			"self_cast": true,
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(42, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 6.0,
			"damage_per_rank": 1.2,
			"knockback": 80.0,
			"poise": 6.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
			"bless_heal": 8.0,
			"bless_shield": 8.0,
			"bless_time": 2.5,
		},
		"fx": {
			"id": "light_step",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.45),
			"trail_width": 5.0,
			"flash_radius": 30.0,
			"ghost": true,
		},
	},
	"mgl_ray": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.ray",
		"icon": "res://assets/ui/icons/skills/light_ray.png",
		"kind": "active",
		"col": 0,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgl_grace": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [200.0, 210.0, 220.0, 235.0, 250.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "light",
			"status": "bless",
			"self_cast": true,
			"windup": 0.10,
			"active": 0.10,
			"recovery": 0.16,
			"hit_size": Vector2(18, 14),
			"hit_offset": Vector2(22, 0),
			"damage": 8.0,
			"damage_per_rank": 1.6,
			"knockback": 60.0,
			"poise": 5.0,
			"bless_heal": 12.0,
			"bless_shield": 10.0,
			"bless_time": 3.0,
		},
		"fx": {
			"id": "light_ray",
			"trail_color": Color(1.0, 0.9, 0.45, 1.0),
			"flash_color": Color(1.0, 0.95, 0.65, 0.55),
			"trail_width": 4.0,
			"flash_radius": 18.0,
		},
	},
	"mgl_aegis": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.aegis",
		"icon": "res://assets/ui/icons/skills/light_aegis.png",
		"kind": "active",
		"col": 1,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgl_grace": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [18, 20, 22, 24, 26],
		"cooldown": [4.0, 3.8, 3.5, 3.2, 2.9],
		"range": [40.0, 40.0, 40.0, 40.0, 40.0],
		"loud": false,
		"combat": {
			"style": "mage_ward",
			"element": "light",
			"status": "bless",
			"self_cast": true,
			"windup": 0.08,
			"active": 0.12,
			"recovery": 0.18,
			"hit_size": Vector2(48, 48),
			"hit_offset": Vector2(0, 0),
			"damage": 0.0,
			"damage_per_rank": 0.0,
			"knockback": 0.0,
			"poise": 0.0,
			"bless_heal": 6.0,
			"bless_shield": 18.0,
			"bless_hps": 2.0,
			"bless_time": 4.0,
		},
		"fx": {
			"id": "light_aegis",
			"trail_color": Color(1.0, 0.94, 0.6, 1.0),
			"flash_color": Color(1.0, 0.98, 0.75, 0.5),
			"flash_radius": 48.0,
		},
	},
'''

HELPERS_OLD_START = "static func family_of(skill_id: String) -> String:"


HELPERS_NEW = '''static func normalize_imprint(family: String) -> String:
	if family in [FAMILY_MAGE, FAMILY_MAGE_FLAME_LEGACY, "mage_flame", "mage"]:
		return FAMILY_MAGE
	return family


static func is_mage_imprint(family: String) -> bool:
	return normalize_imprint(family) == FAMILY_MAGE


static func mage_skill_family(element: String = "fire") -> String:
	return str(MAGE_FAMILY_BY_ELEMENT.get(element, FAMILY_MAGE_FIRE))


static func active_tree_family(imprint: String, mage_element: String = "fire") -> String:
	var imp := normalize_imprint(imprint)
	if imp == FAMILY_MAGE:
		return mage_skill_family(mage_element)
	return imp


static func dash_skill_for(imprint: String, mage_element: String = "fire") -> String:
	var fam := active_tree_family(imprint, mage_element)
	match fam:
		FAMILY_HOT:
			return "hw_sidestep"
		FAMILY_MAGE_FIRE:
			return "mgf_blink"
		FAMILY_MAGE_ICE:
			return "mgi_froststep"
		FAMILY_MAGE_ACID:
			return "mga_acidflash"
		FAMILY_MAGE_DARK:
			return "mgd_shadowstep"
		FAMILY_MAGE_LIGHT:
			return "mgl_lightstep"
		_:
			return "sk_dash"


static func family_of(skill_id: String) -> String:
	return str(def(skill_id).get("family", FAMILY_COLD))


static func innate_ids_for(family: String) -> Array:
	var fam := family
	if is_mage_imprint(family):
		fam = FAMILY_MAGE_FIRE
	return INNATE_BY_FAMILY.get(fam, INNATE_BY_FAMILY[FAMILY_COLD]).duplicate()


static func innate_ids_for_tree(tree_family: String) -> Array:
	return INNATE_BY_FAMILY.get(tree_family, INNATE_BY_FAMILY[FAMILY_COLD]).duplicate()


static func tree_bounds(family: String) -> Dictionary:
	var cols := 1
	var rows := 1
	for sid in tree_ids(family):
		var d: Dictionary = DEFS[str(sid)]
		cols = maxi(cols, int(d.get("col", 0)) + 1)
		rows = maxi(rows, int(d.get("row", 0)) + 1)
	return {"cols": cols, "rows": rows}


static func col_name_keys(family: String = FAMILY_COLD) -> Array:
	var bounds := tree_bounds(family)
	var n := int(bounds.get("cols", 3))
	var keys: Array = []
	match family:
		FAMILY_HOT:
			keys = ["skill.col.shot", "skill.col.blast", "skill.col.mech"]
		FAMILY_MAGE_FIRE, FAMILY_MAGE, FAMILY_MAGE_FLAME_LEGACY:
			keys = ["skill.col.spell", "skill.col.zone", "skill.col.source"]
		FAMILY_MAGE_ICE:
			keys = ["skill.col.frost", "skill.col.rime", "skill.col.flow"]
		FAMILY_MAGE_ACID:
			keys = ["skill.col.venom", "skill.col.mist", "skill.col.flux"]
		FAMILY_MAGE_DARK:
			keys = ["skill.col.shade", "skill.col.void", "skill.col.veil"]
		FAMILY_MAGE_LIGHT:
			keys = ["skill.col.radiance", "skill.col.aegis", "skill.col.grace"]
		_:
			keys = ["skill.col.slash", "skill.col.break", "skill.col.force"]
	while keys.size() < n:
		keys.append("skill.col.extra_%d" % keys.size())
	return keys.slice(0, n)


static func panel_title_key(family: String = FAMILY_COLD) -> String:
	match family:
		FAMILY_HOT:
			return "skill.panel_title_hot"
		FAMILY_MAGE_FIRE, FAMILY_MAGE, FAMILY_MAGE_FLAME_LEGACY:
			return "skill.panel_title_mage_fire"
		FAMILY_MAGE_ICE:
			return "skill.panel_title_mage_ice"
		FAMILY_MAGE_ACID:
			return "skill.panel_title_mage_acid"
		FAMILY_MAGE_DARK:
			return "skill.panel_title_mage_dark"
		FAMILY_MAGE_LIGHT:
			return "skill.panel_title_mage_light"
		_:
			return "skill.panel_title"


static func imprint_display_key(family: String = FAMILY_COLD) -> String:
	var imp := normalize_imprint(family)
	match imp:
		FAMILY_HOT:
			return "stat.imprint_hot"
		FAMILY_MAGE:
			return "stat.imprint_mage"
		_:
			return "stat.imprint_blade"


static func tree_ids(family: String = "") -> Array:
	var fam := family if family != "" else FAMILY_COLD
	if is_mage_imprint(fam):
		fam = FAMILY_MAGE_FIRE
	var ids: Array = []
	for sid in DEFS.keys():
		if family_of(str(sid)) == fam:
			ids.append(sid)
	ids.sort_custom(func(a, b):
		var da: Dictionary = DEFS[a]
		var db: Dictionary = DEFS[b]
		if int(da.get("row", 0)) != int(db.get("row", 0)):
			return int(da.get("row", 0)) < int(db.get("row", 0))
		return int(da.get("col", 0)) < int(db.get("col", 0))
	)
	return ids
'''


def replace_helpers(text: str) -> str:
    # Replace from family_of through tree_ids inclusive
    start = text.find("static func family_of(skill_id: String) -> String:")
    end = text.find("static func display_name(skill_id: String) -> String:")
    if start < 0 or end < 0:
        raise SystemExit(f"helper markers not found start={start} end={end}")
    return text[:start] + HELPERS_NEW + "\n\n" + text[end:]


def main() -> None:
    text = CATALOG.read_text(encoding="utf-8")
    if HEADER_OLD not in text:
        # maybe already partially transformed
        if "FAMILY_MAGE_FIRE" in text:
            print("Already transformed?")
            return
        raise SystemExit("HEADER_OLD not found")
    text = text.replace(HEADER_OLD, HEADER_NEW, 1)
    text = rename_mg_to_mgf(text)
    # fire family on all mgf defs
    text = text.replace('"family": FAMILY_MAGE,', '"family": FAMILY_MAGE_FIRE,')
    # also name_key mg. -> mgf. for fire
    text = re.sub(r'"name_key": "mg\.', '"name_key": "mgf.', text)
    # insert skeleton before closing of DEFS
    marker = "\n}\n\n\nstatic func def"
    if marker not in text:
        raise SystemExit("DEFS end marker not found")
    text = text.replace(marker, ",\n" + SKELETON.rstrip() + "\n}\n\n\nstatic func def", 1)
    text = replace_helpers(text)
    # fix row_level for extended ROW_LEVELS
    text = text.replace(
        """static func row_level(row: int) -> int:
	if row < 0 or row >= ROW_LEVELS.size():
		return 1
	return int(ROW_LEVELS[row])""",
        """static func row_level(row: int) -> int:
	if row < 0:
		return 1
	if row >= ROW_LEVELS.size():
		## 超出表则按末档外推：+5 每档
		return int(ROW_LEVELS[-1]) + (row - ROW_LEVELS.size() + 1) * 5
	return int(ROW_LEVELS[row])""",
    )
    CATALOG.write_text(text, encoding="utf-8")
    print("OK wrote", CATALOG)
    # sanity
    t2 = CATALOG.read_text(encoding="utf-8")
    print("mgf_ember", "mgf_ember" in t2)
    print("mgi_frostmark", "mgi_frostmark" in t2)
    print("FAMILY_MAGE_FIRE", t2.count("FAMILY_MAGE_FIRE"))
    print("legacy mg_ember map", '"mg_ember": "mgf_ember"' in t2)


if __name__ == "__main__":
    main()
