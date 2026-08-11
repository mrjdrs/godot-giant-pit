extends RefCounted
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
	"mg_focus": "mgf_focus",
	"mg_lash": "mgf_lash",
	"mg_ring": "mgf_ring",
	"mg_ward": "mgf_ward",
	"mg_cascade": "mgf_cascade",
	"mg_meteor": "mgf_meteor",
	"mg_cataclysm": "mgf_cataclysm",
}

const DEFS := {
	"sk_chain": {
		"family": FAMILY_COLD,
		"name_key": "sk.chain",
		"icon": "res://assets/ui/icons/skills/blade_chain.png",
		"kind": "passive",
		"col": COL_SLASH,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"light_dmg": 0.06, "light_dmg_per": 0.04, "combo2_windup": 0.92},
	},
	"sk_dash": {
		"family": FAMILY_COLD,
		"name_key": "sk.dash",
		"icon": "res://assets/ui/icons/skills/blade_dash.png",
		"kind": "active",
		"col": COL_FORCE,
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
			"style": "dash_slash",
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(42, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 10.0,
			"damage_per_rank": 2.0,
			"knockback": 110.0,
			"poise": 8.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
		},
		"fx": {
			"id": "dash_trail",
			"trail_color": Color(0.62, 0.92, 1.0, 1.0),
			"flash_color": Color(0.78, 0.96, 1.0, 0.46),
			"trail_width": 6.0,
			"trail_width_per_rank": 0.8,
			"flash_radius": 30.0,
			"ghost": true,
			"camera_shake": 0.04,
		},
	},
	"sk_bolt": {
		"family": FAMILY_COLD,
		"name_key": "sk.bolt",
		"icon": "res://assets/ui/icons/skills/blade_bolt.png",
		"kind": "active",
		"col": COL_SLASH,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"sk_chain": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [18, 19, 20, 22, 24],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [220.0, 230.0, 240.0, 255.0, 270.0],
		"loud": false,
		"combat": {
			"style": "bolt",
			"windup": 0.10,
			"active": 0.10,
			"recovery": 0.16,
			"swing_from": -36.0,
			"swing_to": 18.0,
			"hit_size": Vector2(20, 16),
			"hit_offset": Vector2(22, 0),
			"damage": 12.0,
			"damage_per_rank": 2.5,
			"knockback": 90.0,
			"poise": 8.0,
			"lunge": 6.0,
			"proj_speed": 320.0,
			"pierce": 1,
			"pierce_at_rank3": 1,
		},
		"fx": {
			"id": "blade_qi",
			"trail_color": Color(1.0, 0.94, 0.62, 1.0),
			"flash_color": Color(1.0, 0.96, 0.78, 0.5),
			"trail_width": 7.0,
			"trail_width_per_rank": 0.6,
			"flash_radius": 28.0,
			"camera_shake": 0.05,
		},
	},
	"sk_quake": {
		"family": FAMILY_COLD,
		"name_key": "sk.quake",
		"icon": "res://assets/ui/icons/skills/blade_quake.png",
		"kind": "active",
		"col": COL_BREAK,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"sk_dash": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [3.2, 3.05, 2.9, 2.75, 2.55],
		"range": [96.0, 102.0, 108.0, 116.0, 124.0],
		"loud": true,
		"combat": {
			"style": "smash_wave",
			"windup": 0.22,
			"active": 0.14,
			"recovery": 0.26,
			"swing_from": -108.0,
			"swing_to": 78.0,
			"hit_size": Vector2(52, 36),
			"hit_offset": Vector2(32, 0),
			"damage": 22.0,
			"damage_per_rank": 4.0,
			"knockback": 200.0,
			"poise": 16.0,
			"lunge": 22.0,
			"wave_radius": 48.0,
			"wave_radius_per_rank": 6.0,
		},
		"fx": {
			"id": "shockwave",
			"trail_color": Color(1.0, 0.62, 0.28, 1.0),
			"flash_color": Color(1.0, 0.72, 0.36, 0.55),
			"trail_width": 11.0,
			"trail_width_per_rank": 1.2,
			"flash_radius": 44.0,
			"camera_shake": 0.22,
			"dust": true,
		},
	},
	"sk_stance": {
		"family": FAMILY_COLD,
		"name_key": "sk.stance",
		"icon": "res://assets/ui/icons/skills/blade_stance.png",
		"kind": "passive",
		"col": COL_FORCE,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"sk_dash": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"patk_pct": 0.03, "atk_spd": 0.03},
	},
	"sk_riposte": {
		"family": FAMILY_COLD,
		"name_key": "sk.riposte",
		"icon": "res://assets/ui/icons/skills/blade_riposte.png",
		"kind": "active",
		"col": COL_SLASH,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"sk_bolt": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [72.0, 76.0, 80.0, 86.0, 92.0],
		"loud": false,
		"combat": {
			"style": "riposte",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.20,
			"swing_from": 92.0,
			"swing_to": -96.0,
			"hit_size": Vector2(48, 28),
			"hit_offset": Vector2(20, 0),
			"damage": 18.0,
			"damage_per_rank": 3.0,
			"knockback": 160.0,
			"poise": 14.0,
			"lunge": 10.0,
			"invuln": 0.18,
			"invuln_per_rank": 0.02,
		},
		"fx": {
			"id": "riposte_flash",
			"trail_color": Color(0.88, 0.94, 1.0, 1.0),
			"flash_color": Color(0.92, 0.98, 1.0, 0.62),
			"trail_width": 9.0,
			"trail_width_per_rank": 0.8,
			"flash_radius": 40.0,
			"camera_shake": 0.10,
			"ghost": true,
		},
	},
	"sk_whirl": {
		"family": FAMILY_COLD,
		"name_key": "sk.whirl",
		"icon": "res://assets/ui/icons/skills/blade_whirl.png",
		"kind": "active",
		"col": COL_BREAK,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"sk_quake": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [32, 34, 36, 40, 44],
		"cooldown": [5.0, 4.8, 4.6, 4.3, 4.0],
		"range": [56.0, 60.0, 64.0, 70.0, 76.0],
		"loud": true,
		"combat": {
			"style": "whirl",
			"windup": 0.10,
			"active": 0.16,
			"recovery": 0.22,
			"swing_from": -160.0,
			"swing_to": 200.0,
			"hit_size": Vector2(70, 70),
			"hit_offset": Vector2(0, 0),
			"damage": 14.0,
			"damage_per_rank": 2.5,
			"knockback": 140.0,
			"poise": 12.0,
			"lunge": 0.0,
			"ticks": 2,
			"extra_tick_every": 2,
		},
		"fx": {
			"id": "whirl_ring",
			"trail_color": Color(0.42, 0.92, 0.72, 1.0),
			"flash_color": Color(0.55, 1.0, 0.82, 0.5),
			"trail_width": 10.0,
			"trail_width_per_rank": 1.0,
			"flash_radius": 56.0,
			"camera_shake": 0.12,
		},
	},
	"sk_ironwall": {
		"family": FAMILY_COLD,
		"name_key": "sk.ironwall",
		"icon": "res://assets/ui/icons/skills/blade_ironwall.png",
		"kind": "passive",
		"col": COL_FORCE,
		"row": 2,
		"level_req": 10,
		"max_rank": 3,
		"prereq": {"sk_stance": 1},
		"learn_cost": [3, 5, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"dr": 0.04},
	},
	"sk_myriad": {
		"family": FAMILY_COLD,
		"name_key": "sk.myriad",
		"icon": "res://assets/ui/icons/skills/blade_myriad.png",
		"kind": "active",
		"col": COL_SLASH,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"sk_riposte": 1},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [28, 30, 32, 36, 40],
		"cooldown": [4.4, 4.2, 4.0, 3.7, 3.4],
		"range": [80.0, 84.0, 88.0, 94.0, 100.0],
		"loud": false,
		"combat": {
			"style": "myriad",
			"windup": 0.08,
			"active": 0.10,
			"recovery": 0.22,
			"swing_from": -70.0,
			"swing_to": 80.0,
			"hit_size": Vector2(44, 26),
			"hit_offset": Vector2(22, 0),
			"damage": 11.0,
			"damage_per_rank": 2.0,
			"knockback": 80.0,
			"poise": 8.0,
			"lunge": 8.0,
			"ticks": 3,
			"swings": [
				{"from": -78.0, "to": 70.0},
				{"from": 86.0, "to": -92.0},
				{"from": -120.0, "to": 96.0},
			],
		},
		"fx": {
			"id": "myriad_arcs",
			"trail_color": Color(1.0, 0.42, 0.28, 1.0),
			"flash_color": Color(1.0, 0.72, 0.36, 0.55),
			"trail_width": 8.0,
			"trail_width_per_rank": 0.9,
			"flash_radius": 36.0,
			"camera_shake": 0.08,
			"ghost": true,
			"hitstop": 0.10,
		},
	},
	"sk_smash": {
		"family": FAMILY_COLD,
		"name_key": "sk.smash",
		"icon": "res://assets/ui/icons/skills/blade_smash.png",
		"kind": "active",
		"col": COL_BREAK,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"sk_whirl": 1},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [48, 50, 54, 58, 64],
		"cooldown": [6.0, 5.8, 5.5, 5.2, 4.8],
		"range": [140.0, 148.0, 156.0, 168.0, 180.0],
		"loud": true,
		"combat": {
			"style": "ground_slam",
			"windup": 0.32,
			"active": 0.16,
			"recovery": 0.28,
			"swing_from": -130.0,
			"swing_to": 90.0,
			"hit_size": Vector2(64, 64),
			"hit_offset": Vector2(0, 0),
			"damage": 28.0,
			"damage_per_rank": 5.0,
			"knockback": 260.0,
			"poise": 24.0,
			"lunge": 0.0,
			"jump": 18.0,
			"wave_radius": 70.0,
			"wave_radius_per_rank": 8.0,
		},
		"fx": {
			"id": "ground_crack",
			"trail_color": Color(1.0, 0.78, 0.28, 1.0),
			"flash_color": Color(1.0, 0.84, 0.42, 0.6),
			"trail_width": 13.0,
			"trail_width_per_rank": 1.4,
			"flash_radius": 64.0,
			"camera_shake": 0.32,
			"dust": true,
		},
	},
	"sk_draw": {
		"family": FAMILY_COLD,
		"name_key": "sk.draw",
		"icon": "res://assets/ui/icons/skills/blade_draw.png",
		"kind": "active",
		"col": COL_FORCE,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"sk_dash": 3, "sk_chain": 3},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [36, 38, 42, 46, 52],
		"cooldown": [7.0, 6.7, 6.4, 6.0, 5.5],
		"range": [160.0, 170.0, 182.0, 196.0, 214.0],
		"loud": true,
		"combat": {
			"style": "draw_slash",
			"windup": 0.28,
			"active": 0.12,
			"recovery": 0.30,
			"swing_from": -20.0,
			"swing_to": 12.0,
			"hit_size": Vector2(140, 28),
			"hit_offset": Vector2(70, 0),
			"damage": 34.0,
			"damage_per_rank": 6.0,
			"knockback": 220.0,
			"poise": 22.0,
			"lunge": 36.0,
			"hide_blade": true,
			"slash_len": 150.0,
			"slash_len_per_rank": 12.0,
		},
		"fx": {
			"id": "draw_slash",
			"trail_color": Color(1.0, 0.96, 0.78, 1.0),
			"flash_color": Color(1.0, 0.98, 0.88, 0.7),
			"trail_width": 16.0,
			"trail_width_per_rank": 1.6,
			"flash_radius": 80.0,
			"camera_shake": 0.28,
			"ghost": true,
		},
	},
	"hw_caliber": {
		"family": FAMILY_HOT,
		"name_key": "hw.caliber",
		"icon": "res://assets/ui/icons/skills/gun_caliber.png",
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
		"passive": {"light_dmg": 0.06, "light_dmg_per": 0.04, "proj_speed_pct": 0.04},
	},
	"hw_sidestep": {
		"family": FAMILY_HOT,
		"name_key": "hw.sidestep",
		"icon": "res://assets/ui/icons/skills/gun_sidestep.png",
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
			"style": "dash_shot",
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(42, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 10.0,
			"damage_per_rank": 2.0,
			"knockback": 110.0,
			"poise": 8.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
			"proj_speed": 420.0,
			"invuln": 0.12,
		},
		"fx": {
			"id": "dash_trail",
			"trail_color": Color(1.0, 0.72, 0.28, 1.0),
			"flash_color": Color(1.0, 0.82, 0.42, 0.46),
			"trail_width": 6.0,
			"trail_width_per_rank": 0.8,
			"flash_radius": 30.0,
			"ghost": true,
			"camera_shake": 0.04,
		},
	},
	"hw_piercer": {
		"family": FAMILY_HOT,
		"name_key": "hw.piercer",
		"icon": "res://assets/ui/icons/skills/gun_piercer.png",
		"kind": "active",
		"col": 0,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"hw_caliber": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [18, 19, 20, 22, 24],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [220.0, 230.0, 240.0, 255.0, 270.0],
		"loud": false,
		"combat": {
			"style": "gun_pierce",
			"windup": 0.10,
			"active": 0.10,
			"recovery": 0.16,
			"swing_from": -36.0,
			"swing_to": 18.0,
			"hit_size": Vector2(20, 16),
			"hit_offset": Vector2(22, 0),
			"damage": 12.0,
			"damage_per_rank": 2.5,
			"knockback": 90.0,
			"poise": 8.0,
			"lunge": 6.0,
			"proj_speed": 320.0,
			"pierce": 1,
			"pierce_at_rank3": 1,
		},
		"fx": {
			"id": "gun_tracer",
			"trail_color": Color(1.0, 0.78, 0.32, 1.0),
			"flash_color": Color(1.0, 0.86, 0.48, 0.5),
			"trail_width": 7.0,
			"trail_width_per_rank": 0.6,
			"flash_radius": 28.0,
			"camera_shake": 0.05,
		},
	},
	"hw_grenade": {
		"family": FAMILY_HOT,
		"name_key": "hw.grenade",
		"icon": "res://assets/ui/icons/skills/gun_grenade.png",
		"kind": "active",
		"col": 1,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"hw_sidestep": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [18, 19, 20, 22, 24],
		"cooldown": [3.2, 3.05, 2.9, 2.75, 2.55],
		"range": [96.0, 102.0, 108.0, 116.0, 124.0],
		"loud": true,
		"combat": {
			"style": "gun_grenade",
			"windup": 0.26,
			"active": 0.14,
			"recovery": 0.26,
			"swing_from": -108.0,
			"swing_to": 78.0,
			"hit_size": Vector2(52, 36),
			"hit_offset": Vector2(32, 0),
			"damage": 22.0,
			"damage_per_rank": 4.0,
			"knockback": 200.0,
			"poise": 16.0,
			"lunge": 22.0,
			"wave_radius": 48.0,
			"wave_radius_per_rank": 6.0,
		},
		"fx": {
			"id": "shockwave",
			"trail_color": Color(1.0, 0.58, 0.18, 1.0),
			"flash_color": Color(1.0, 0.68, 0.28, 0.55),
			"trail_width": 11.0,
			"trail_width_per_rank": 1.2,
			"flash_radius": 44.0,
			"camera_shake": 0.22,
			"dust": true,
		},
	},
	"hw_reload": {
		"family": FAMILY_HOT,
		"name_key": "hw.reload",
		"icon": "res://assets/ui/icons/skills/gun_reload.png",
		"kind": "passive",
		"col": 2,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"hw_sidestep": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"atk_spd": 0.03, "cd_cut": 0.02},
	},
	"hw_burst": {
		"family": FAMILY_HOT,
		"name_key": "hw.burst",
		"icon": "res://assets/ui/icons/skills/gun_burst.png",
		"kind": "active",
		"col": 0,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"hw_piercer": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [72.0, 76.0, 80.0, 86.0, 92.0],
		"loud": false,
		"combat": {
			"style": "gun_burst",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.20,
			"swing_from": 92.0,
			"swing_to": -96.0,
			"hit_size": Vector2(48, 28),
			"hit_offset": Vector2(20, 0),
			"damage": 18.0,
			"damage_per_rank": 3.0,
			"knockback": 160.0,
			"poise": 14.0,
			"lunge": 10.0,
			"ticks": 3,
			"extra_tick_every": 2,
			"proj_speed": 380.0,
		},
		"fx": {
			"id": "gun_burst",
			"trail_color": Color(1.0, 0.82, 0.38, 1.0),
			"flash_color": Color(1.0, 0.88, 0.52, 0.62),
			"trail_width": 9.0,
			"trail_width_per_rank": 0.8,
			"flash_radius": 40.0,
			"camera_shake": 0.10,
		},
	},
	"hw_mine": {
		"family": FAMILY_HOT,
		"name_key": "hw.mine",
		"icon": "res://assets/ui/icons/skills/gun_mine.png",
		"kind": "active",
		"col": 1,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"hw_grenade": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [32, 34, 36, 40, 44],
		"cooldown": [5.0, 4.8, 4.6, 4.3, 4.0],
		"range": [56.0, 60.0, 64.0, 70.0, 76.0],
		"loud": true,
		"combat": {
			"style": "gun_mine",
			"windup": 0.10,
			"active": 0.16,
			"recovery": 0.22,
			"swing_from": -160.0,
			"swing_to": 200.0,
			"hit_size": Vector2(70, 70),
			"hit_offset": Vector2(0, 0),
			"damage": 14.0,
			"damage_per_rank": 2.5,
			"knockback": 140.0,
			"poise": 12.0,
			"lunge": 0.0,
			"fuse": 0.85,
			"wave_radius": 40.0,
			"wave_radius_per_rank": 4.0,
		},
		"fx": {
			"id": "mine_blast",
			"trail_color": Color(1.0, 0.52, 0.18, 1.0),
			"flash_color": Color(1.0, 0.62, 0.28, 0.5),
			"trail_width": 10.0,
			"trail_width_per_rank": 1.0,
			"flash_radius": 56.0,
			"camera_shake": 0.12,
		},
	},
	"hw_brace": {
		"family": FAMILY_HOT,
		"name_key": "hw.brace",
		"icon": "res://assets/ui/icons/skills/gun_brace.png",
		"kind": "passive",
		"col": 2,
		"row": 2,
		"level_req": 10,
		"max_rank": 3,
		"prereq": {"hw_reload": 1},
		"learn_cost": [3, 5, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"dr": 0.04, "skill_dmg": 0.03, "move_cut": 0.35},
	},
	"hw_rail": {
		"family": FAMILY_HOT,
		"name_key": "hw.rail",
		"icon": "res://assets/ui/icons/skills/gun_rail.png",
		"kind": "active",
		"col": 0,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"hw_burst": 1},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [28, 30, 32, 36, 40],
		"cooldown": [4.4, 4.2, 4.0, 3.7, 3.4],
		"range": [80.0, 84.0, 88.0, 94.0, 100.0],
		"loud": false,
		"combat": {
			"style": "gun_rail",
			"windup": 0.08,
			"active": 0.10,
			"recovery": 0.22,
			"swing_from": -70.0,
			"swing_to": 80.0,
			"hit_size": Vector2(44, 26),
			"hit_offset": Vector2(22, 0),
			"damage": 11.0,
			"damage_per_rank": 2.0,
			"knockback": 80.0,
			"poise": 8.0,
			"lunge": 8.0,
			"proj_speed": 520.0,
			"pierce": 3,
			"pierce_at_rank3": 1,
		},
		"fx": {
			"id": "rail_beam",
			"trail_color": Color(1.0, 0.92, 0.48, 1.0),
			"flash_color": Color(1.0, 0.96, 0.62, 0.55),
			"trail_width": 8.0,
			"trail_width_per_rank": 0.9,
			"flash_radius": 36.0,
			"camera_shake": 0.08,
			"hitstop": 0.10,
		},
	},
	"hw_artillery": {
		"family": FAMILY_HOT,
		"name_key": "hw.artillery",
		"icon": "res://assets/ui/icons/skills/gun_artillery.png",
		"kind": "active",
		"col": 1,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"hw_mine": 1},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [48, 50, 54, 58, 64],
		"cooldown": [6.0, 5.8, 5.5, 5.2, 4.8],
		"range": [140.0, 148.0, 156.0, 168.0, 180.0],
		"loud": true,
		"combat": {
			"style": "gun_artillery",
			"windup": 0.32,
			"active": 0.16,
			"recovery": 0.28,
			"swing_from": -130.0,
			"swing_to": 90.0,
			"hit_size": Vector2(64, 64),
			"hit_offset": Vector2(0, 0),
			"damage": 28.0,
			"damage_per_rank": 5.0,
			"knockback": 260.0,
			"poise": 24.0,
			"lunge": 0.0,
			"wave_radius": 70.0,
			"wave_radius_per_rank": 8.0,
		},
		"fx": {
			"id": "artillery_crater",
			"trail_color": Color(1.0, 0.68, 0.22, 1.0),
			"flash_color": Color(1.0, 0.76, 0.32, 0.6),
			"trail_width": 13.0,
			"trail_width_per_rank": 1.4,
			"flash_radius": 64.0,
			"camera_shake": 0.32,
			"dust": true,
		},
	},
	"hw_overclock": {
		"family": FAMILY_HOT,
		"name_key": "hw.overclock",
		"icon": "res://assets/ui/icons/skills/gun_overclock.png",
		"kind": "active",
		"col": 2,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"hw_sidestep": 3, "hw_caliber": 3},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [36, 38, 42, 46, 52],
		"cooldown": [7.0, 6.7, 6.4, 6.0, 5.5],
		"range": [160.0, 170.0, 182.0, 196.0, 214.0],
		"loud": true,
		"combat": {
			"style": "gun_overclock",
			"windup": 0.28,
			"active": 0.12,
			"recovery": 0.30,
			"swing_from": -20.0,
			"swing_to": 12.0,
			"hit_size": Vector2(140, 28),
			"hit_offset": Vector2(70, 0),
			"damage": 34.0,
			"damage_per_rank": 6.0,
			"knockback": 220.0,
			"poise": 22.0,
			"lunge": 36.0,
			"ticks": 5,
			"extra_tick_every": 2,
			"proj_speed": 360.0,
			"spread": 24.0,
		},
		"fx": {
			"id": "overclock_salvo",
			"trail_color": Color(1.0, 0.82, 0.38, 1.0),
			"flash_color": Color(1.0, 0.90, 0.52, 0.7),
			"trail_width": 16.0,
			"trail_width_per_rank": 1.6,
			"flash_radius": 80.0,
			"camera_shake": 0.28,
			"ghost": true,
		},
	},
	"mgf_ember": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.ember",
		"icon": "res://assets/ui/icons/skills/flame_ember.png",
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
		"passive": {"burn_dps": 2.0, "burn_dps_per": 1.0, "burn_time": 2.2, "light_dmg": 0.06, "light_dmg_per": 0.04},
	},
	"mgf_blink": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.blink",
		"icon": "res://assets/ui/icons/skills/flame_blink.png",
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
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(42, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 10.0,
			"damage_per_rank": 2.0,
			"knockback": 110.0,
			"poise": 8.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
			"wave_radius": 28.0,
			"wave_radius_per_rank": 4.0,
			"burn_dps": 2.0,
			"burn_time": 2.0,
		},
		"fx": {
			"id": "blink_flare",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 6.0,
			"trail_width_per_rank": 0.8,
			"flash_radius": 30.0,
			"ghost": true,
			"camera_shake": 0.04,
		},
	},
	"mgf_bolt": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.bolt",
		"icon": "res://assets/ui/icons/skills/flame_bolt.png",
		"kind": "active",
		"col": 0,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgf_ember": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [18, 19, 20, 22, 24],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [220.0, 230.0, 240.0, 255.0, 270.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"windup": 0.10,
			"active": 0.10,
			"recovery": 0.16,
			"swing_from": -36.0,
			"swing_to": 18.0,
			"hit_size": Vector2(20, 16),
			"hit_offset": Vector2(22, 0),
			"damage": 12.0,
			"damage_per_rank": 2.5,
			"knockback": 90.0,
			"poise": 8.0,
			"lunge": 6.0,
			"proj_speed": 320.0,
			"pierce": 1,
			"burn_dps": 3.0,
			"burn_time": 2.2,
		},
		"fx": {
			"id": "flame_bolt",
			"trail_color": Color(1.0, 0.48, 0.12, 1.0),
			"flash_color": Color(1.0, 0.62, 0.22, 0.5),
			"trail_width": 7.0,
			"trail_width_per_rank": 0.6,
			"flash_radius": 28.0,
			"camera_shake": 0.05,
		},
	},
	"mgf_nova": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.nova",
		"icon": "res://assets/ui/icons/skills/flame_nova.png",
		"kind": "active",
		"col": 1,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgf_blink": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [18, 19, 20, 22, 24],
		"cooldown": [3.2, 3.05, 2.9, 2.75, 2.55],
		"range": [96.0, 102.0, 108.0, 116.0, 124.0],
		"loud": true,
		"combat": {
			"style": "mage_nova",
			"windup": 0.26,
			"active": 0.14,
			"recovery": 0.26,
			"swing_from": -108.0,
			"swing_to": 78.0,
			"hit_size": Vector2(52, 36),
			"hit_offset": Vector2(32, 0),
			"damage": 22.0,
			"damage_per_rank": 4.0,
			"knockback": 200.0,
			"poise": 16.0,
			"lunge": 22.0,
			"wave_radius": 48.0,
			"wave_radius_per_rank": 6.0,
			"burn_dps": 4.0,
			"burn_time": 2.4,
		},
		"fx": {
			"id": "nova_ring",
			"trail_color": Color(1.0, 0.32, 0.08, 1.0),
			"flash_color": Color(1.0, 0.48, 0.18, 0.55),
			"trail_width": 11.0,
			"trail_width_per_rank": 1.2,
			"flash_radius": 44.0,
			"camera_shake": 0.22,
			"dust": true,
		},
	},
	"mgf_focus": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.focus",
		"icon": "res://assets/ui/icons/skills/flame_focus.png",
		"kind": "passive",
		"col": 2,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgf_blink": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"mind_cut": 0.04, "mind_regen": 0.15},
	},
	"mgf_lash": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.lash",
		"icon": "res://assets/ui/icons/skills/flame_lash.png",
		"kind": "active",
		"col": 0,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgf_bolt": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [72.0, 76.0, 80.0, 86.0, 92.0],
		"loud": false,
		"combat": {
			"style": "mage_lash",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.20,
			"swing_from": 92.0,
			"swing_to": -96.0,
			"hit_size": Vector2(48, 28),
			"hit_offset": Vector2(20, 0),
			"damage": 18.0,
			"damage_per_rank": 3.0,
			"knockback": 160.0,
			"poise": 14.0,
			"lunge": 10.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
		},
		"fx": {
			"id": "lash_arc",
			"trail_color": Color(1.0, 0.38, 0.12, 1.0),
			"flash_color": Color(1.0, 0.52, 0.22, 0.62),
			"trail_width": 9.0,
			"trail_width_per_rank": 0.8,
			"flash_radius": 40.0,
			"camera_shake": 0.10,
		},
	},
	"mgf_ring": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.ring",
		"icon": "res://assets/ui/icons/skills/flame_ring.png",
		"kind": "active",
		"col": 1,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgf_nova": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [32, 34, 36, 40, 44],
		"cooldown": [5.0, 4.8, 4.6, 4.3, 4.0],
		"range": [56.0, 60.0, 64.0, 70.0, 76.0],
		"loud": true,
		"combat": {
			"style": "mage_ring",
			"windup": 0.10,
			"active": 0.16,
			"recovery": 0.22,
			"swing_from": -160.0,
			"swing_to": 200.0,
			"hit_size": Vector2(70, 70),
			"hit_offset": Vector2(0, 0),
			"damage": 14.0,
			"damage_per_rank": 2.5,
			"knockback": 140.0,
			"poise": 12.0,
			"lunge": 0.0,
			"ticks": 3,
			"extra_tick_every": 2,
			"burn_dps": 3.0,
			"burn_time": 2.0,
		},
		"fx": {
			"id": "flame_ring",
			"trail_color": Color(1.0, 0.36, 0.10, 1.0),
			"flash_color": Color(1.0, 0.48, 0.18, 0.5),
			"trail_width": 10.0,
			"trail_width_per_rank": 1.0,
			"flash_radius": 56.0,
			"camera_shake": 0.12,
		},
	},
	"mgf_ward": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.ward",
		"icon": "res://assets/ui/icons/skills/flame_ward.png",
		"kind": "passive",
		"col": 2,
		"row": 2,
		"level_req": 10,
		"max_rank": 3,
		"prereq": {"mgf_focus": 1},
		"learn_cost": [3, 5, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {"dr": 0.04, "reflect_burn": 1.5},
	},
	"mgf_cascade": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.cascade",
		"icon": "res://assets/ui/icons/skills/flame_cascade.png",
		"kind": "active",
		"col": 0,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgf_lash": 1},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [28, 30, 32, 36, 40],
		"cooldown": [4.4, 4.2, 4.0, 3.7, 3.4],
		"range": [80.0, 84.0, 88.0, 94.0, 100.0],
		"loud": false,
		"combat": {
			"style": "mage_cascade",
			"windup": 0.08,
			"active": 0.10,
			"recovery": 0.22,
			"swing_from": -70.0,
			"swing_to": 80.0,
			"hit_size": Vector2(44, 26),
			"hit_offset": Vector2(22, 0),
			"damage": 11.0,
			"damage_per_rank": 2.0,
			"knockback": 80.0,
			"poise": 8.0,
			"lunge": 8.0,
			"ticks": 3,
			"swings": [
				{"from": -78.0, "to": 70.0},
				{"from": 86.0, "to": -92.0},
				{"from": -120.0, "to": 96.0},
			],
			"burn_dps": 4.0,
			"burn_time": 2.4,
		},
		"fx": {
			"id": "cascade_waves",
			"trail_color": Color(1.0, 0.32, 0.08, 1.0),
			"flash_color": Color(1.0, 0.52, 0.18, 0.55),
			"trail_width": 8.0,
			"trail_width_per_rank": 0.9,
			"flash_radius": 36.0,
			"camera_shake": 0.08,
			"ghost": true,
			"hitstop": 0.10,
		},
	},
	"mgf_meteor": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.meteor",
		"icon": "res://assets/ui/icons/skills/flame_meteor.png",
		"kind": "active",
		"col": 1,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgf_ring": 1},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [48, 50, 54, 58, 64],
		"cooldown": [6.0, 5.8, 5.5, 5.2, 4.8],
		"range": [140.0, 148.0, 156.0, 168.0, 180.0],
		"loud": true,
		"combat": {
			"style": "mage_meteor",
			"windup": 0.32,
			"active": 0.16,
			"recovery": 0.28,
			"swing_from": -130.0,
			"swing_to": 90.0,
			"hit_size": Vector2(64, 64),
			"hit_offset": Vector2(0, 0),
			"damage": 28.0,
			"damage_per_rank": 5.0,
			"knockback": 260.0,
			"poise": 24.0,
			"lunge": 0.0,
			"wave_radius": 70.0,
			"wave_radius_per_rank": 8.0,
			"burn_dps": 6.0,
			"burn_time": 3.0,
		},
		"fx": {
			"id": "meteor_impact",
			"trail_color": Color(1.0, 0.28, 0.06, 1.0),
			"flash_color": Color(1.0, 0.42, 0.12, 0.6),
			"trail_width": 13.0,
			"trail_width_per_rank": 1.4,
			"flash_radius": 64.0,
			"camera_shake": 0.32,
			"dust": true,
		},
	},
	"mgf_cataclysm": {
		"family": FAMILY_MAGE_FIRE,
		"name_key": "mgf.cataclysm",
		"icon": "res://assets/ui/icons/skills/flame_cataclysm.png",
		"kind": "active",
		"col": 2,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgf_blink": 3, "mgf_ember": 3},
		"learn_cost": [5, 6, 8, 10, 12],
		"cast_cost": [36, 38, 42, 46, 52],
		"cooldown": [7.0, 6.7, 6.4, 6.0, 5.5],
		"range": [160.0, 170.0, 182.0, 196.0, 214.0],
		"loud": true,
		"combat": {
			"style": "mage_cataclysm",
			"windup": 0.28,
			"active": 0.12,
			"recovery": 0.30,
			"swing_from": -20.0,
			"swing_to": 12.0,
			"hit_size": Vector2(140, 28),
			"hit_offset": Vector2(70, 0),
			"damage": 34.0,
			"damage_per_rank": 6.0,
			"knockback": 220.0,
			"poise": 22.0,
			"lunge": 36.0,
			"ticks": 4,
			"extra_tick_every": 2,
			"wave_radius": 80.0,
			"wave_radius_per_rank": 10.0,
			"burn_dps": 8.0,
			"burn_time": 3.5,
		},
		"fx": {
			"id": "cataclysm_field",
			"trail_color": Color(1.0, 0.22, 0.04, 1.0),
			"flash_color": Color(1.0, 0.38, 0.10, 0.7),
			"trail_width": 16.0,
			"trail_width_per_rank": 1.6,
			"flash_radius": 80.0,
			"camera_shake": 0.28,
			"ghost": true,
		},
	},

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
}


static func def(skill_id: String) -> Dictionary:
	return DEFS.get(migrate_id(skill_id), {})


static func migrate_id(skill_id: String) -> String:
	if DEFS.has(skill_id):
		return skill_id
	return str(LEGACY_SKILL_MAP.get(skill_id, skill_id))


static func has_id(skill_id: String) -> bool:
	return DEFS.has(migrate_id(skill_id))


static func all_ids() -> Array:
	return DEFS.keys()


static func normalize_imprint(family: String) -> String:
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


static func display_name(skill_id: String) -> String:
	var d := def(skill_id)
	if d.is_empty():
		return skill_id
	return Loc.t(str(d.get("name_key", skill_id)))


static func icon_path(skill_id: String) -> String:
	return str(def(skill_id).get("icon", ""))


static func kind(skill_id: String) -> String:
	return str(def(skill_id).get("kind", "active"))


static func is_active(skill_id: String) -> bool:
	return kind(skill_id) == "active"


static func is_passive(skill_id: String) -> bool:
	return kind(skill_id) == "passive"


static func is_innate(skill_id: String) -> bool:
	var sid := migrate_id(skill_id)
	for fam in INNATE_BY_FAMILY.keys():
		if sid in INNATE_BY_FAMILY[fam]:
			return true
	return false


static func is_loud(skill_id: String, _rank: int = 1) -> bool:
	return bool(def(skill_id).get("loud", false))


static func level_req(skill_id: String) -> int:
	return int(def(skill_id).get("level_req", 1))


static func max_rank(skill_id: String) -> int:
	return int(def(skill_id).get("max_rank", 1))


static func prereq(skill_id: String) -> Dictionary:
	return def(skill_id).get("prereq", {})


static func tree_col(skill_id: String) -> int:
	return int(def(skill_id).get("col", 0))


static func tree_row(skill_id: String) -> int:
	return int(def(skill_id).get("row", 0))


static func row_level(row: int) -> int:
	if row < 0:
		return 1
	if row >= ROW_LEVELS.size():
		## 超出表则按末档外推：+5 每档
		return int(ROW_LEVELS[-1]) + (row - ROW_LEVELS.size() + 1) * 5
	return int(ROW_LEVELS[row])


static func _rank_pick(value, rank: int, fallback = 0):
	var r := clampi(rank, 1, 99)
	if typeof(value) == TYPE_ARRAY:
		var arr: Array = value
		if arr.is_empty():
			return fallback
		return arr[clampi(r - 1, 0, arr.size() - 1)]
	if value == null:
		return fallback
	return value


static func learn_cost_for_rank(skill_id: String, rank: int) -> int:
	return int(_rank_pick(def(skill_id).get("learn_cost", 1), rank, 1))


static func spent_cost(skill_id: String, rank: int) -> int:
	var total := 0
	for i in range(1, maxi(rank, 0) + 1):
		total += learn_cost_for_rank(skill_id, i)
	return total


static func cast_cost(skill_id: String, rank: int = 1) -> int:
	if skill_id == "":
		return 0
	return int(_rank_pick(def(skill_id).get("cast_cost", 0), rank, 0))


static func cooldown(skill_id: String, rank: int = 1) -> float:
	return float(_rank_pick(def(skill_id).get("cooldown", 0.0), rank, 0.0))


static func skill_range(skill_id: String, rank: int = 1) -> float:
	return float(_rank_pick(def(skill_id).get("range", 80.0), rank, 80.0))


static func combat(skill_id: String, rank: int = 1) -> Dictionary:
	var base: Dictionary = def(skill_id).get("combat", {}).duplicate(true)
	if base.is_empty():
		return {}
	var r := maxi(rank, 1)
	base["damage"] = float(base.get("damage", 10.0)) + float(base.get("damage_per_rank", 0.0)) * float(r - 1)
	if base.has("invuln"):
		base["invuln"] = float(base.get("invuln", 0.0)) + float(base.get("invuln_per_rank", 0.0)) * float(r - 1)
	if base.has("wave_radius"):
		base["wave_radius"] = float(base.get("wave_radius", 40.0)) + float(base.get("wave_radius_per_rank", 0.0)) * float(r - 1)
	if base.has("slash_len"):
		base["slash_len"] = float(base.get("slash_len", 120.0)) + float(base.get("slash_len_per_rank", 0.0)) * float(r - 1)
	var ticks := int(base.get("ticks", 1))
	var extra_every := int(base.get("extra_tick_every", 0))
	if extra_every > 0:
		ticks += int(floor(float(r - 1) / float(extra_every)))
	if int(base.get("pierce_at_rank3", 0)) > 0 and r >= 3:
		base["pierce"] = int(base.get("pierce", 1)) + int(base.get("pierce_at_rank3", 0))
	base["ticks"] = maxi(ticks, 1)
	base["rank"] = r
	base["range"] = skill_range(skill_id, r)
	return base


static func fx(skill_id: String, rank: int = 1) -> Dictionary:
	var base: Dictionary = def(skill_id).get("fx", {}).duplicate(true)
	if base.is_empty():
		return {}
	var r := maxi(rank, 1)
	base["trail_width"] = float(base.get("trail_width", 8.0)) + float(base.get("trail_width_per_rank", 0.0)) * float(r - 1)
	base["flash_radius"] = float(base.get("flash_radius", 32.0)) + 3.0 * float(r - 1)
	base["rank"] = r
	return base


static func passive(skill_id: String) -> Dictionary:
	return def(skill_id).get("passive", {})


static func prereqs_met(skill_id: String, rank_fn: Callable) -> bool:
	var pre := prereq(skill_id)
	for pid in pre.keys():
		if int(rank_fn.call(str(pid))) < int(pre[pid]):
			return false
	return true


static func is_required_by_others(skill_id: String, current_rank: int, rank_fn: Callable) -> bool:
	var sid := migrate_id(skill_id)
	var fam := family_of(sid)
	for other in DEFS.keys():
		if other == sid:
			continue
		if family_of(str(other)) != fam:
			continue
		if int(rank_fn.call(str(other))) <= 0:
			continue
		var pre: Dictionary = DEFS[other].get("prereq", {})
		if not pre.has(sid):
			continue
		if current_rank <= int(pre[sid]):
			return true
	return false


static func crystal_drop_chance(enemy_id: String, is_boss: bool = false) -> float:
	if is_boss or enemy_id == "boss_floor1":
		return 1.0
	if enemy_id.begins_with("special_"):
		return 0.70
	if enemy_id.begins_with("elite_"):
		return 0.60
	if enemy_id.begins_with("guard_"):
		return 0.40
	return 0.20


static func crystal_drop_count(enemy_id: String, is_boss: bool = false) -> int:
	if is_boss or enemy_id == "boss_floor1":
		return randi_range(4, 6)
	if enemy_id.begins_with("special_"):
		return randi_range(2, 4)
	if enemy_id.begins_with("elite_"):
		return randi_range(2, 3)
	if enemy_id.begins_with("guard_"):
		return randi_range(1, 2)
	return 1


static func fallback_icon(skill_id: String) -> String:
	var path := icon_path(skill_id)
	if path != "" and ResourceLoader.exists(path):
		return path
	match migrate_id(skill_id):
		"sk_chain":
			return "res://assets/runes/rune_s_chain.png"
		"sk_quake":
			return "res://assets/runes/rune_s_quake.png"
		"sk_dash":
			return "res://assets/runes/rune_s_cloudstep.png"
		"sk_bolt":
			return "res://assets/runes/rune_s_ironwall.png"
		"sk_whirl":
			return "res://assets/brands/brand_copper.png"
		"sk_smash":
			return "res://assets/brands/brand_gold.png"
		"sk_ironwall":
			return "res://assets/ui/icons/skills/skill_slot_defend.png"
		"sk_stance":
			return "res://assets/ui/icons/skills/skill_slot_passive.png"
		"sk_riposte":
			return "res://assets/ui/icons/skills/skill_slot_finisher.png"
		"sk_myriad":
			return "res://assets/ui/icons/skills/skill_slot_ultimate.png"
		"sk_draw":
			return "res://assets/ui/icons/skills/skill_slot_dodge.png"
		_:
			return "res://assets/ui/icons/skills/skill_slot_basic.png"
