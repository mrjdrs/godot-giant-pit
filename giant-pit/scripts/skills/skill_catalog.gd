extends RefCounted
## 烙印技能树（战痕·刀 / 鹰眼·弓 / 元素五系 / 亲和）。晶核加点，释放耗念力。

const HOTKEY_SLOTS := ["rmb", "q", "e", "r", "f", "c"]
const CRYSTAL_ID := "crystal_core"
const COL_SLASH := 0 ## 斩
const COL_BREAK := 1 ## 破
const COL_FORCE := 2 ## 势
const ROW_LEVELS := [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
const FAMILY_COLD := "cold_blade" ## 展示：战痕烙印
const FAMILY_HOT := "hot_gun" ## 展示：鹰眼烙印
const FAMILY_MAGE := "mage" ## 展示：元素烙印（兼容旧 mage_flame）
const FAMILY_AFFINITY := "affinity_nature" ## 展示：亲和烙印
const AFFINITY_KINDS := ["animal", "plant"]
const HELD_BLADE := "blade"
const HELD_BOW := "bow"
const HELD_ELEMENT := "element"
const HELD_FOCUS := "focus"
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
	FAMILY_COLD: ["ws_passive_bloodinstinct"],
	FAMILY_HOT: ["hw_caliber", "hw_sidestep"],
	FAMILY_MAGE_FIRE: ["mgf_ember", "mgf_blink"],
	FAMILY_MAGE_ICE: ["mgi_frostmark", "mgi_froststep"],
	FAMILY_MAGE_ACID: ["mga_stain", "mga_acidflash"],
	FAMILY_MAGE_DARK: ["mgd_shadowbite", "mgd_shadowstep"],
	FAMILY_MAGE_LIGHT: ["mgl_grace", "mgl_lightstep"],
	## 烙印级兼容：默认火系天生
	FAMILY_MAGE: ["mgf_ember", "mgf_blink"],
	FAMILY_MAGE_FLAME_LEGACY: ["mgf_ember", "mgf_blink"],
	FAMILY_AFFINITY: ["nat_grove", "nat_leafstep"],
}
const INNATE_IDS := ["ws_passive_bloodinstinct"] ## 兼容；优先 innate_ids_for()
const LEGACY_SKILL_MAP := {
	"sk_chain": "ws_passive_bloodinstinct",
	"sk_dash": "ws_active_dashslash",
	"sk_bolt": "ws_active_groundwave",
	"sk_quake": "ws_active_groundwave",
	"sk_stance": "ws_passive_battlelust",
	"sk_riposte": "ws_active_riposte",
	"sk_whirl": "ws_active_whirlwind",
	"sk_ironwall": "ws_passive_heavyarm",
	"sk_myriad": "ws_active_chainassault",
	"sk_smash": "ws_active_cataclysm",
	"sk_draw": "ws_active_shieldbreak",
	"core_s_chain": "ws_passive_bloodinstinct",
	"rune_s_chain": "ws_passive_bloodinstinct",
	"core_s_quake": "ws_active_groundwave",
	"rune_s_quake": "ws_active_groundwave",
	"core_s_dash": "ws_active_dashslash",
	"rune_s_cloudstep": "ws_active_dashslash",
	"core_s_bolt": "ws_active_groundwave",
	"core_s_whirl": "ws_active_whirlwind",
	"core_s_smash": "ws_active_cataclysm",
	"rune_s_ironwall": "ws_passive_heavyarm",
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
	"ws_passive_bloodinstinct": {
		"family": FAMILY_COLD, "name_key": "ws.bloodinstinct", "icon": "res://assets/ui/icons/skills/ws_bloodinstinct.png",
		"kind": "passive", "col": COL_BREAK, "row": 0, "level_req": 1, "max_rank": 5, "prereq": {},
		"learn_cost": [0, 1, 2, 3, 4], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"basic_hit_heal_max_hp": 0.005, "heal_per_10_str": 0.002, "heal_cap": 0.02, "base_per_rank": 0.0015, "str_per_rank": 0.0005},
	},
	"ws_active_dashslash": {
		"family": FAMILY_COLD, "name_key": "ws.dashslash", "icon": "res://assets/ui/icons/skills/ws_dashslash.png",
		"kind": "active", "col": COL_SLASH, "row": 1, "level_req": 5, "max_rank": 5, "prereq": {"ws_passive_bloodinstinct": 1},
		"learn_cost": [2, 3, 4, 5, 6], "cast_cost": [10, 12, 14, 16, 18], "cooldown": [6.0, 5.7, 5.4, 5.1, 4.8], "range": 120.0, "loud": false,
		"combat": {"style": "ws_dashslash", "patk_multiplier": 1.2, "dash_distance": 120.0, "path_width": 40.0, "max_targets": 1, "weapon_variants": true},
		"fx": {"id": "ws_dashslash", "trail_color": Color(0.86, 0.22, 0.16, 1.0), "flash_color": Color(1.0, 0.72, 0.28, 0.65), "trail_width": 8.0, "flash_radius": 32.0, "ghost": true, "camera_shake": 0.08},
	},
	"ws_passive_heavyarm": {
		"family": FAMILY_COLD, "name_key": "ws.heavyarm", "icon": "res://assets/ui/icons/skills/ws_heavyarm.png",
		"kind": "passive", "col": COL_FORCE, "row": 1, "level_req": 5, "max_rank": 5, "prereq": {"ws_passive_bloodinstinct": 1},
		"learn_cost": [2, 3, 4, 5, 6], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"dr": 0.04, "dr_per_rank": 0.01, "total_dr_cap": 0.60},
	},
	"ws_active_groundwave": {
		"family": FAMILY_COLD, "name_key": "ws.groundwave", "icon": "res://assets/ui/icons/skills/ws_groundwave.png",
		"kind": "active", "col": COL_SLASH, "row": 2, "level_req": 10, "max_rank": 5, "prereq": {"ws_active_dashslash": 1},
		"learn_cost": [3, 4, 5, 6, 8], "cast_cost": [18, 20, 22, 24, 26], "cooldown": [10.0, 9.5, 9.0, 8.5, 8.0], "range": 100.0, "loud": true,
		"combat": {"style": "ws_groundwave", "patk_multiplier": 1.5, "arc_degrees": 90.0, "wave_radius": 100.0, "weapon_variants": true},
		"fx": {"id": "ws_groundwave", "trail_color": Color(0.72, 0.28, 0.12, 1.0), "flash_color": Color(1.0, 0.62, 0.20, 0.62), "trail_width": 11.0, "flash_radius": 52.0, "camera_shake": 0.18, "dust": true},
	},
	"ws_passive_toughbone": {
		"family": FAMILY_COLD, "name_key": "ws.toughbone", "icon": "res://assets/ui/icons/skills/ws_toughbone.png",
		"kind": "passive", "col": COL_FORCE, "row": 2, "level_req": 10, "max_rank": 5, "prereq": {"ws_passive_heavyarm": 1},
		"learn_cost": [3, 4, 5, 6, 8], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"hitstun_cut": 0.20, "hitstun_cut_per_rank": 0.04, "poise_damage_multiplier": 1.15, "poise_bonus_per_rank": 0.03},
	},
	"ws_active_ironstance": {
		"family": FAMILY_COLD, "name_key": "ws.ironstance", "icon": "res://assets/ui/icons/skills/ws_ironstance.png",
		"kind": "active", "col": COL_SLASH, "row": 3, "level_req": 15, "max_rank": 5, "prereq": {"ws_active_groundwave": 1},
		"learn_cost": [4, 5, 6, 8, 10], "cast_cost": [15, 17, 19, 21, 23], "cooldown": [14.0, 13.3, 12.6, 11.9, 11.2], "range": 60.0, "loud": true,
		"combat": {"style": "ws_ironstance", "duration": 3.0, "dr_bonus": 0.40, "rooted": true, "end_patk_multiplier": 0.8, "wave_radius": 60.0, "weapon_variants": true},
		"fx": {"id": "ws_ironstance", "trail_color": Color(0.62, 0.54, 0.42, 1.0), "flash_color": Color(1.0, 0.82, 0.42, 0.60), "trail_width": 10.0, "flash_radius": 60.0, "camera_shake": 0.16, "dust": true},
	},
	"ws_passive_battlelust": {
		"family": FAMILY_COLD, "name_key": "ws.battlelust", "icon": "res://assets/ui/icons/skills/ws_battlelust.png",
		"kind": "passive", "col": COL_FORCE, "row": 3, "level_req": 15, "max_rank": 5, "prereq": {"ws_passive_toughbone": 1},
		"learn_cost": [4, 5, 6, 8, 10], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"lost_hp_step": 0.10, "patk_per_step": 0.02, "patk_per_step_per_rank": 0.005, "max_patk_bonus": 0.10, "max_bonus_per_rank": 0.02},
	},
	"ws_active_riposte": {
		"family": FAMILY_COLD, "name_key": "ws.riposte", "icon": "res://assets/ui/icons/skills/ws_riposte.png",
		"kind": "active", "col": COL_SLASH, "row": 4, "level_req": 20, "max_rank": 5, "prereq": {"ws_active_ironstance": 1},
		"learn_cost": [5, 6, 8, 10, 12], "cast_cost": [20, 22, 24, 26, 28], "cooldown": [12.0, 11.4, 10.8, 10.2, 9.6], "range": 80.0, "loud": false,
		"combat": {"style": "ws_riposte", "parry_window": 0.5, "patk_multiplier": 2.0, "invuln": 0.5, "weapon_variants": true},
		"fx": {"id": "ws_riposte", "trail_color": Color(1.0, 0.86, 0.46, 1.0), "flash_color": Color(1.0, 0.96, 0.78, 0.76), "trail_width": 9.0, "flash_radius": 42.0, "camera_shake": 0.12, "ghost": true},
	},
	"ws_passive_bloodthirst": {
		"family": FAMILY_COLD, "name_key": "ws.bloodthirst", "icon": "res://assets/ui/icons/skills/ws_bloodthirst.png",
		"kind": "passive", "col": COL_FORCE, "row": 4, "level_req": 20, "max_rank": 5, "prereq": {"ws_passive_battlelust": 1},
		"learn_cost": [5, 6, 8, 10, 12], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"kill_heal_max_hp": 0.03, "heal_per_rank": 0.005, "internal_cooldown": 8.0, "cooldown_cut_per_rank": 1.0, "min_cooldown": 4.0},
	},
	"ws_active_whirlwind": {
		"family": FAMILY_COLD, "name_key": "ws.whirlwind", "icon": "res://assets/ui/icons/skills/ws_whirlwind.png",
		"kind": "active", "col": COL_SLASH, "row": 5, "level_req": 25, "max_rank": 5, "prereq": {"ws_active_riposte": 1},
		"learn_cost": [6, 8, 10, 12, 15], "cast_cost": [25, 27, 29, 31, 33], "cooldown": [14.0, 13.3, 12.6, 11.9, 11.2], "range": 70.0, "loud": true,
		"combat": {"style": "ws_whirlwind", "patk_multiplier": 0.8, "ticks": 3, "wave_radius": 70.0, "duration": 1.2, "move_speed_cut": 0.50, "weapon_variants": true},
		"fx": {"id": "ws_whirlwind", "trail_color": Color(0.92, 0.34, 0.16, 1.0), "flash_color": Color(1.0, 0.72, 0.28, 0.54), "trail_width": 12.0, "flash_radius": 70.0, "camera_shake": 0.14},
	},
	"ws_passive_immovable": {
		"family": FAMILY_COLD, "name_key": "ws.immovable", "icon": "res://assets/ui/icons/skills/ws_immovable.png",
		"kind": "passive", "col": COL_FORCE, "row": 5, "level_req": 25, "max_rank": 5, "prereq": {"ws_passive_bloodthirst": 1},
		"learn_cost": [6, 8, 10, 12, 15], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"still_seconds_per_stack": 2.0, "max_stacks": 2, "dr_per_stack": 0.08, "dr_per_rank": 0.02, "patk_per_stack": 0.05, "patk_per_rank": 0.01},
	},
	"ws_active_mountainbreak": {
		"family": FAMILY_COLD, "name_key": "ws.mountainbreak", "icon": "res://assets/ui/icons/skills/ws_mountainbreak.png",
		"kind": "active", "col": COL_SLASH, "row": 6, "level_req": 30, "max_rank": 5, "prereq": {"ws_active_whirlwind": 1},
		"learn_cost": [8, 10, 12, 15, 18], "cast_cost": [35, 37, 39, 41, 43], "cooldown": [18.0, 17.1, 16.2, 15.3, 14.4], "range": 80.0, "loud": true,
		"combat": {"style": "ws_mountainbreak", "patk_multiplier": 2.8, "poise_multiplier": 2.0, "single_target": true, "weapon_variants": true},
		"fx": {"id": "ws_mountainbreak", "trail_color": Color(0.74, 0.22, 0.10, 1.0), "flash_color": Color(1.0, 0.66, 0.22, 0.66), "trail_width": 14.0, "flash_radius": 54.0, "camera_shake": 0.28, "dust": true},
	},
	"ws_passive_ironskin": {
		"family": FAMILY_COLD, "name_key": "ws.ironskin", "icon": "res://assets/ui/icons/skills/ws_ironskin.png",
		"kind": "passive", "col": COL_FORCE, "row": 6, "level_req": 30, "max_rank": 5, "prereq": {"ws_passive_immovable": 1},
		"learn_cost": [8, 10, 12, 15, 18], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"hp_threshold": 0.30, "threshold_per_rank": 0.02, "max_threshold": 0.40, "dr": 0.15, "dr_per_rank": 0.03},
	},
	"ws_active_warcry": {
		"family": FAMILY_COLD, "name_key": "ws.warcry", "icon": "res://assets/ui/icons/skills/ws_warcry.png",
		"kind": "active", "col": COL_SLASH, "row": 7, "level_req": 35, "max_rank": 5, "prereq": {"ws_active_mountainbreak": 1},
		"learn_cost": [10, 12, 15, 18, 22], "cast_cost": [30, 32, 34, 36, 38], "cooldown": [25.0, 23.75, 22.5, 21.25, 20.0], "range": 120.0, "loud": true,
		"combat": {"style": "ws_warcry", "duration": 5.0, "dr_bonus": 0.20, "patk_bonus": 0.15, "enemy_slow": 0.15, "wave_radius": 120.0, "weapon_variants": true},
		"fx": {"id": "ws_warcry", "trail_color": Color(0.64, 0.10, 0.08, 1.0), "flash_color": Color(1.0, 0.38, 0.16, 0.62), "trail_width": 10.0, "flash_radius": 120.0, "camera_shake": 0.22},
	},
	"ws_passive_scarheal": {
		"family": FAMILY_COLD, "name_key": "ws.scarheal", "icon": "res://assets/ui/icons/skills/ws_scarheal.png",
		"kind": "passive", "col": COL_FORCE, "row": 7, "level_req": 35, "max_rank": 5, "prereq": {"ws_passive_ironskin": 1},
		"learn_cost": [10, 12, 15, 18, 22], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"hp_threshold": 0.50, "heal_max_hp": 0.015, "heal_per_rank": 0.003, "interval": 3.0, "interval_cut_per_rank": 0.3, "min_interval": 2.0, "combat_only": true},
	},
	"ws_active_chainassault": {
		"family": FAMILY_COLD, "name_key": "ws.chainassault", "icon": "res://assets/ui/icons/skills/ws_chainassault.png",
		"kind": "active", "col": COL_SLASH, "row": 8, "level_req": 40, "max_rank": 5, "prereq": {"ws_active_warcry": 1},
		"learn_cost": [12, 15, 18, 22, 26], "cast_cost": [40, 42, 44, 46, 48], "cooldown": [16.0, 15.2, 14.4, 13.6, 12.8], "range": 90.0, "loud": false,
		"combat": {"style": "ws_chainassault", "patk_multiplier": 0.65, "ticks": 5, "duration": 1.5, "aim_adjust": true, "weapon_variants": true},
		"fx": {"id": "ws_chainassault", "trail_color": Color(0.96, 0.46, 0.18, 1.0), "flash_color": Color(1.0, 0.82, 0.42, 0.60), "trail_width": 9.0, "flash_radius": 44.0, "camera_shake": 0.10, "ghost": true},
	},
	"ws_passive_breaksight": {
		"family": FAMILY_COLD, "name_key": "ws.breaksight", "icon": "res://assets/ui/icons/skills/ws_breaksight.png",
		"kind": "passive", "col": COL_FORCE, "row": 8, "level_req": 40, "max_rank": 5, "prereq": {"ws_passive_scarheal": 1},
		"learn_cost": [12, 15, 18, 22, 26], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"vs_broken_crit": 0.12, "crit_per_rank": 0.03, "vs_broken_crit_damage": 0.15, "crit_damage_per_rank": 0.03},
	},
	"ws_active_shieldbreak": {
		"family": FAMILY_COLD, "name_key": "ws.shieldbreak", "icon": "res://assets/ui/icons/skills/ws_shieldbreak.png",
		"kind": "active", "col": COL_SLASH, "row": 9, "level_req": 45, "max_rank": 5, "prereq": {"ws_active_chainassault": 1},
		"learn_cost": [15, 18, 22, 26, 30], "cast_cost": [45, 47, 49, 51, 53], "cooldown": [22.0, 20.9, 19.8, 18.7, 17.6], "range": 80.0, "loud": true,
		"combat": {"style": "ws_shieldbreak", "patk_multiplier": 3.2, "broken_damage_multiplier": 1.5, "poise_multiplier": 2.5, "weapon_variants": true},
		"fx": {"id": "ws_shieldbreak", "trail_color": Color(0.76, 0.18, 0.08, 1.0), "flash_color": Color(1.0, 0.72, 0.24, 0.72), "trail_width": 15.0, "flash_radius": 58.0, "camera_shake": 0.30, "dust": true},
	},
	"ws_passive_lethalfocus": {
		"family": FAMILY_COLD, "name_key": "ws.lethalfocus", "icon": "res://assets/ui/icons/skills/ws_lethalfocus.png",
		"kind": "passive", "col": COL_FORCE, "row": 9, "level_req": 45, "max_rank": 5, "prereq": {"ws_passive_breaksight": 1},
		"learn_cost": [15, 18, 22, 26, 30], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"target_poise_threshold": 0.30, "elite_boss_only": true, "patk_bonus": 0.10, "patk_per_rank": 0.02, "poise_damage_bonus": 0.20, "poise_per_rank": 0.04},
	},
	"ws_active_desperaterush": {
		"family": FAMILY_COLD, "name_key": "ws.desperaterush", "icon": "res://assets/ui/icons/skills/ws_desperaterush.png",
		"kind": "active", "col": COL_SLASH, "row": 10, "level_req": 50, "max_rank": 5, "prereq": {"ws_active_shieldbreak": 1},
		"learn_cost": [18, 22, 26, 30, 36], "cast_cost": [50, 52, 54, 56, 58], "cooldown": [20.0, 19.0, 18.0, 17.0, 16.0], "range": 200.0, "loud": true,
		"combat": {"style": "ws_desperaterush", "patk_multiplier": 3.2, "dash_distance": 200.0, "low_hp_threshold": 0.40, "low_hp_multiplier": 1.25, "weapon_variants": true},
		"fx": {"id": "ws_desperaterush", "trail_color": Color(0.72, 0.06, 0.06, 1.0), "flash_color": Color(1.0, 0.34, 0.14, 0.68), "trail_width": 13.0, "flash_radius": 48.0, "camera_shake": 0.24, "ghost": true},
	},
	"ws_passive_laststand": {
		"family": FAMILY_COLD, "name_key": "ws.laststand", "icon": "res://assets/ui/icons/skills/ws_laststand.png",
		"kind": "passive", "col": COL_FORCE, "row": 10, "level_req": 50, "max_rank": 5, "prereq": {"ws_passive_lethalfocus": 1},
		"learn_cost": [18, 22, 26, 30, 36], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"lethal_guard_hp": 1, "guard_duration": 2.0, "guard_dr": 0.50, "guard_dr_per_rank": 0.05, "internal_cooldown": 60.0, "cooldown_cut_per_rank": 5.0, "min_cooldown": 40.0},
	},
	"ws_active_bloodrage": {
		"family": FAMILY_COLD, "name_key": "ws.bloodrage", "icon": "res://assets/ui/icons/skills/ws_bloodrage.png",
		"kind": "active", "col": COL_SLASH, "row": 11, "level_req": 55, "max_rank": 5, "prereq": {"ws_active_desperaterush": 1},
		"learn_cost": [22, 26, 30, 36, 42], "cast_cost": [35, 37, 39, 41, 43], "cooldown": [30.0, 28.5, 27.0, 25.5, 24.0], "range": 0.0, "loud": true,
		"combat": {"style": "ws_bloodrage", "current_hp_cost": 0.10, "min_remaining_hp": 1, "duration": 8.0, "patk_bonus": 0.30, "lifesteal": 0.15, "weapon_variants": true},
		"fx": {"id": "ws_bloodrage", "trail_color": Color(0.64, 0.02, 0.04, 1.0), "flash_color": Color(1.0, 0.16, 0.10, 0.68), "trail_width": 12.0, "flash_radius": 72.0, "camera_shake": 0.18},
	},
	"ws_passive_veteran": {
		"family": FAMILY_COLD, "name_key": "ws.veteran", "icon": "res://assets/ui/icons/skills/ws_veteran.png",
		"kind": "passive", "col": COL_FORCE, "row": 11, "level_req": 55, "max_rank": 5, "prereq": {"ws_passive_laststand": 1},
		"learn_cost": [22, 26, 30, 36, 42], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"str_bonus": 3, "vit_bonus": 3, "stat_per_rank": 1, "max_hp_bonus": 0.05, "max_hp_per_rank": 0.01},
	},
	"ws_active_cataclysm": {
		"family": FAMILY_COLD, "name_key": "ws.cataclysm", "icon": "res://assets/ui/icons/skills/ws_cataclysm.png",
		"kind": "active", "col": COL_SLASH, "row": 12, "level_req": 60, "max_rank": 5, "prereq": {"ws_active_bloodrage": 1},
		"learn_cost": [26, 30, 36, 42, 50], "cast_cost": [65, 67, 69, 71, 73], "cooldown": [45.0, 42.75, 40.5, 38.25, 36.0], "range": 260.0, "loud": true,
		"combat": {"style": "ws_cataclysm", "center_patk_multiplier": 5.0, "edge_patk_multiplier": 2.5, "center_radius": 80.0, "outer_radius": 160.0, "windup": 0.8, "windup_dr": 0.20, "weapon_variants": true, "ultimate": true},
		"fx": {"id": "ws_cataclysm", "trail_color": Color(0.86, 0.12, 0.04, 1.0), "flash_color": Color(1.0, 0.74, 0.22, 0.82), "trail_width": 18.0, "flash_radius": 160.0, "camera_shake": 0.45, "dust": true},
	},
	"ws_passive_immortalscar": {
		"family": FAMILY_COLD, "name_key": "ws.immortalscar", "icon": "res://assets/ui/icons/skills/ws_immortalscar.png",
		"kind": "passive", "col": COL_FORCE, "row": 12, "level_req": 60, "max_rank": 5, "prereq": {"ws_passive_veteran": 1},
		"learn_cost": [26, 30, 36, 42, 50], "cast_cost": 0, "cooldown": 0.0, "loud": false,
		"passive": {"healing_bonus": 0.20, "healing_per_rank": 0.05, "laststand_cooldown_cut": 15.0, "first_ultimate_dr": 0.10, "ultimate_dr_per_rank": 0.02, "ultimate_dr_duration": 5.0},
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
		"passive": {
			"burn_dps": 2.0,
			"burn_dps_per": 1.0,
			"burn_time": 2.2,
			"light_dmg": 0.06,
			"light_dmg_per": 0.04,
		},
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
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 10.0,
			"damage_per_rank": 1.8,
			"knockback": 80.0,
			"poise": 8.0,
			"spawn_zone": true,
			"zone_dur": 3.0,
			"wave_radius": 28.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_blink",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 12.0,
			"damage_per_rank": 2.2,
			"knockback": 80.0,
			"poise": 8.0,
			"pierce": 1,
			"proj_speed": 320.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_bolt",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": true,
		"combat": {
			"style": "mage_nova",
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 22.0,
			"damage_per_rank": 4.0,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 48.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_nova",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"passive": {
			"mind_cut": 0.04,
			"mind_regen": 0.15,
		},
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
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_beam",
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 14.0,
			"damage_per_rank": 2.5,
			"knockback": 80.0,
			"poise": 8.0,
			"beam_len": 110.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_lash",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_orbit",
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 8.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"ticks": 4,
			"orbit_radius": 52.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_ring",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"max_rank": 5,
		"prereq": {"mgf_focus": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"dr_pct": 0.04,
			"reflect_burn": 1.5,
		},
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
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_rain",
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 10.0,
			"damage_per_rank": 1.8,
			"knockback": 80.0,
			"poise": 8.0,
			"rain_count": 5,
			"range": 140.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_cascade",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": true,
		"combat": {
			"style": "mage_meteor",
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 38.0,
			"damage_per_rank": 6.8,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 68.0,
			"fuse": 0.35,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_meteor",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"prereq": {"mgf_ward": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": true,
		"combat": {
			"style": "mage_field",
			"element": "fire",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 6.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 72.0,
			"field_dur": 4.0,
			"burn_dps": 3.0,
			"burn_time": 2.2,
			"status": "burn",
		},
		"fx": {
			"id": "fire_cataclysm",
			"trail_color": Color(1.0, 0.42, 0.18, 1.0),
			"flash_color": Color(1.0, 0.58, 0.28, 0.46),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"passive": {
			"chill_slow": 0.22,
			"chill_slow_per": 0.04,
			"chill_time": 2.4,
		},
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
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 9.0,
			"damage_per_rank": 1.6,
			"knockback": 80.0,
			"poise": 8.0,
			"spawn_zone": true,
			"zone_dur": 3.0,
			"wave_radius": 28.0,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
			"status": "chill",
		},
		"fx": {
			"id": "ice_froststep",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "ice",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 11.0,
			"damage_per_rank": 2.0,
			"knockback": 80.0,
			"poise": 8.0,
			"proj_speed": 280.0,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
			"status": "chill",
		},
		"fx": {
			"id": "ice_shard",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_nova",
			"element": "ice",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 10.0,
			"damage_per_rank": 1.8,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 56.0,
			"chill_stacks": 2,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"status": "chill",
		},
		"fx": {
			"id": "ice_rime",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgi_permafrost": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.permafrost",
		"icon": "res://assets/ui/icons/skills/ice_permafrost.png",
		"kind": "passive",
		"col": 2,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgi_froststep": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"chill_time_bonus": 0.4,
			"freeze_at_cut": 1,
		},
	},
	"mgi_wall": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.wall",
		"icon": "res://assets/ui/icons/skills/ice_wall.png",
		"kind": "active",
		"col": 0,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgi_shard": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_wall",
			"element": "ice",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 8.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wall_len": 72.0,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
			"status": "chill",
		},
		"fx": {
			"id": "ice_wall",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgi_pulse": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.pulse",
		"icon": "res://assets/ui/icons/skills/ice_pulse.png",
		"kind": "active",
		"col": 1,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgi_rime": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_pulse",
			"element": "ice",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 18.0,
			"damage_per_rank": 3.2,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 64.0,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
			"status": "chill",
		},
		"fx": {
			"id": "ice_pulse",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgi_frostarmor": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.frostarmor",
		"icon": "res://assets/ui/icons/skills/ice_frostarmor.png",
		"kind": "passive",
		"col": 2,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgi_permafrost": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"shield_on_chill_hit": 6.0,
		},
	},
	"mgi_rain": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.rain",
		"icon": "res://assets/ui/icons/skills/ice_rain.png",
		"kind": "active",
		"col": 0,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgi_wall": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_rain",
			"element": "ice",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 9.0,
			"damage_per_rank": 1.6,
			"knockback": 80.0,
			"poise": 8.0,
			"rain_count": 6,
			"range": 130.0,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
			"status": "chill",
		},
		"fx": {
			"id": "ice_rain",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgi_field": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.field",
		"icon": "res://assets/ui/icons/skills/ice_field.png",
		"kind": "active",
		"col": 1,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgi_pulse": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_field",
			"element": "ice",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 5.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 64.0,
			"field_dur": 3.0,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
			"status": "chill",
		},
		"fx": {
			"id": "ice_field",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgi_shatter": {
		"family": FAMILY_MAGE_ICE,
		"name_key": "mgi.shatter",
		"icon": "res://assets/ui/icons/skills/ice_shatter.png",
		"kind": "active",
		"col": 2,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgi_frostarmor": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_shatter",
			"element": "ice",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 32.0,
			"damage_per_rank": 5.8,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 48.0,
			"chill_slow": 0.28,
			"chill_time": 2.0,
			"chill_stacks": 1,
			"status": "chill",
		},
		"fx": {
			"id": "ice_shatter",
			"trail_color": Color(0.55, 0.85, 1.0, 1.0),
			"flash_color": Color(0.7, 0.92, 1.0, 0.42),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"passive": {
			"corrode_amp": 0.12,
			"corrode_amp_per": 0.03,
			"corrode_time": 3.5,
			"pdef_cut": 2.0,
		},
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
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 9.0,
			"damage_per_rank": 1.6,
			"knockback": 80.0,
			"poise": 8.0,
			"spawn_zone": true,
			"zone_dur": 3.0,
			"wave_radius": 28.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_acidflash",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "acid",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 11.0,
			"damage_per_rank": 2.0,
			"knockback": 80.0,
			"poise": 8.0,
			"proj_speed": 300.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_spit",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_cloud",
			"element": "acid",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 7.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 64.0,
			"field_dur": 3.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_cloud",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mga_dissolve": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.dissolve",
		"icon": "res://assets/ui/icons/skills/acid_dissolve.png",
		"kind": "passive",
		"col": 2,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mga_acidflash": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"pdef_cut_per": 0.8,
			"corrode_amp_per": 0.04,
		},
	},
	"mga_etch": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.etch",
		"icon": "res://assets/ui/icons/skills/acid_etch.png",
		"kind": "active",
		"col": 0,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mga_spit": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_beam",
			"element": "acid",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 13.0,
			"damage_per_rank": 2.3,
			"knockback": 80.0,
			"poise": 8.0,
			"beam_len": 100.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_etch",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mga_corrodering": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.corrodering",
		"icon": "res://assets/ui/icons/skills/acid_corrodering.png",
		"kind": "active",
		"col": 1,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mga_cloud": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_orbit",
			"element": "acid",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 7.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"ticks": 4,
			"orbit_radius": 48.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_corrodering",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mga_resist": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.resist",
		"icon": "res://assets/ui/icons/skills/acid_resist.png",
		"kind": "passive",
		"col": 2,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mga_dissolve": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"corrode_dmg_bonus": 0.08,
		},
	},
	"mga_rain": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.rain",
		"icon": "res://assets/ui/icons/skills/acid_rain.png",
		"kind": "active",
		"col": 0,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mga_etch": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_rain",
			"element": "acid",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 9.0,
			"damage_per_rank": 1.6,
			"knockback": 80.0,
			"poise": 8.0,
			"rain_count": 5,
			"range": 120.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_rain",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mga_field": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.field",
		"icon": "res://assets/ui/icons/skills/acid_field.png",
		"kind": "active",
		"col": 1,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mga_corrodering": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_field",
			"element": "acid",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 5.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 76.0,
			"field_dur": 4.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_field",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mga_shatter": {
		"family": FAMILY_MAGE_ACID,
		"name_key": "mga.shatter",
		"icon": "res://assets/ui/icons/skills/acid_shatter.png",
		"kind": "active",
		"col": 2,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mga_resist": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_shatter",
			"element": "acid",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 28.0,
			"damage_per_rank": 5.0,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 44.0,
			"corrode_amp": 0.15,
			"corrode_time": 3.0,
			"pdef_cut": 3.0,
			"status": "corrode",
		},
		"fx": {
			"id": "acid_shatter",
			"trail_color": Color(0.55, 0.92, 0.22, 1.0),
			"flash_color": Color(0.7, 1.0, 0.3, 0.4),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"passive": {
			"weaken_cut": 0.12,
			"weaken_cut_per": 0.03,
			"weaken_time": 4.0,
		},
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
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 9.0,
			"damage_per_rank": 1.6,
			"knockback": 80.0,
			"poise": 8.0,
			"spawn_zone": true,
			"zone_dur": 3.0,
			"wave_radius": 28.0,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_shadowstep",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "dark",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 11.0,
			"damage_per_rank": 2.0,
			"knockback": 80.0,
			"poise": 8.0,
			"pierce": 2,
			"proj_speed": 340.0,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_bolt",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_vortex",
			"element": "dark",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 8.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 56.0,
			"field_dur": 1.5,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_vortex",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgd_darken": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.darken",
		"icon": "res://assets/ui/icons/skills/dark_darken.png",
		"kind": "passive",
		"col": 2,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgd_shadowstep": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"weaken_cut_per": 0.04,
		},
	},
	"mgd_chain": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.chain",
		"icon": "res://assets/ui/icons/skills/dark_chain.png",
		"kind": "active",
		"col": 0,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgd_bolt": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_chain",
			"element": "dark",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 10.0,
			"damage_per_rank": 1.8,
			"knockback": 80.0,
			"poise": 8.0,
			"chain_count": 3,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_chain",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgd_orbit": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.orbit",
		"icon": "res://assets/ui/icons/skills/dark_orbit.png",
		"kind": "active",
		"col": 1,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgd_vortex": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_orbit",
			"element": "dark",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 7.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"ticks": 4,
			"orbit_radius": 50.0,
			"lifesteal": 0.05,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_orbit",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgd_shadow": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.shadow",
		"icon": "res://assets/ui/icons/skills/dark_shadow.png",
		"kind": "passive",
		"col": 2,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgd_darken": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"low_hp_ms": 0.06,
			"lifesteal": 0.04,
		},
	},
	"mgd_rain": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.rain",
		"icon": "res://assets/ui/icons/skills/dark_rain.png",
		"kind": "active",
		"col": 0,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgd_chain": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_rain",
			"element": "dark",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 9.0,
			"damage_per_rank": 1.6,
			"knockback": 80.0,
			"poise": 8.0,
			"rain_count": 5,
			"range": 130.0,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_rain",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgd_field": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.field",
		"icon": "res://assets/ui/icons/skills/dark_field.png",
		"kind": "active",
		"col": 1,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgd_orbit": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_field",
			"element": "dark",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 5.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 68.0,
			"field_dur": 3.5,
			"lifesteal": 0.08,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_field",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgd_drain": {
		"family": FAMILY_MAGE_DARK,
		"name_key": "mgd.drain",
		"icon": "res://assets/ui/icons/skills/dark_drain.png",
		"kind": "active",
		"col": 2,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgd_shadow": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_drain",
			"element": "dark",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 34.0,
			"damage_per_rank": 6.1,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 40.0,
			"lifesteal": 0.25,
			"weaken_cut": 0.18,
			"weaken_time": 4.0,
			"status": "weaken",
		},
		"fx": {
			"id": "dark_drain",
			"trail_color": Color(0.45, 0.18, 0.72, 1.0),
			"flash_color": Color(0.35, 0.12, 0.55, 0.7),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"passive": {
			"bless_hps": 1.5,
			"bless_hps_per": 0.5,
			"bless_shield": 6.0,
			"bless_time": 3.0,
		},
	},
	"mgl_lightstep": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.lightstep",
		"icon": "res://assets/ui/icons/skills/light_lightstep.png",
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
			"self_cast": true,
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 0.0,
			"damage_per_rank": 1.5,
			"wave_radius": 32.0,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_lightstep",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_bolt",
			"element": "light",
			"self_cast": true,
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 10.0,
			"damage_per_rank": 1.8,
			"knockback": 80.0,
			"poise": 8.0,
			"proj_speed": 360.0,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_ray",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
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
		"cast_cost": [16, 17, 18, 20, 22],
		"cooldown": [2.0, 1.9, 1.8, 1.7, 1.55],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_nova",
			"element": "light",
			"self_cast": true,
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 0.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 48.0,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_aegis",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgl_faith": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.faith",
		"icon": "res://assets/ui/icons/skills/light_faith.png",
		"kind": "passive",
		"col": 2,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"mgl_lightstep": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"bless_time_bonus": 1.0,
			"bless_shield_per": 2.0,
		},
	},
	"mgl_dome": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.dome",
		"icon": "res://assets/ui/icons/skills/light_dome.png",
		"kind": "active",
		"col": 0,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgl_ray": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_dome",
			"element": "light",
			"self_cast": true,
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 0.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"field_dur": 3.0,
			"dr_pct": 0.2,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_dome",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgl_smite": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.smite",
		"icon": "res://assets/ui/icons/skills/light_smite.png",
		"kind": "active",
		"col": 1,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgl_aegis": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_beam",
			"element": "light",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 16.0,
			"damage_per_rank": 2.9,
			"knockback": 80.0,
			"poise": 8.0,
			"beam_len": 120.0,
			"elite_bonus": 0.5,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_smite",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgl_holyshield": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.holyshield",
		"icon": "res://assets/ui/icons/skills/light_holyshield.png",
		"kind": "passive",
		"col": 2,
		"row": 2,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"mgl_faith": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": 0,
		"cooldown": 0.0,
		"loud": false,
		"passive": {
			"reflect_on_break": 8.0,
		},
	},
	"mgl_rain": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.rain",
		"icon": "res://assets/ui/icons/skills/light_rain.png",
		"kind": "active",
		"col": 0,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgl_dome": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_rain",
			"element": "light",
			"self_cast": true,
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 8.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"rain_count": 5,
			"range": 120.0,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_rain",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgl_field": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.field",
		"icon": "res://assets/ui/icons/skills/light_field.png",
		"kind": "active",
		"col": 1,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgl_smite": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_field",
			"element": "light",
			"self_cast": true,
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 0.0,
			"damage_per_rank": 1.5,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 60.0,
			"field_dur": 4.0,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_field",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"mgl_purge": {
		"family": FAMILY_MAGE_LIGHT,
		"name_key": "mgl.purge",
		"icon": "res://assets/ui/icons/skills/light_purge.png",
		"kind": "active",
		"col": 2,
		"row": 3,
		"level_req": 15,
		"max_rank": 5,
		"prereq": {"mgl_holyshield": 1},
		"learn_cost": [3, 4, 5, 6, 8],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.6, 3.4, 3.2, 3.0, 2.8],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "mage_purge",
			"element": "light",
			"windup": 0.08,
			"active": 0.14,
			"recovery": 0.18,
			"damage": 24.0,
			"damage_per_rank": 4.3,
			"knockback": 80.0,
			"poise": 8.0,
			"wave_radius": 56.0,
			"elite_bonus": 0.5,
			"bless_shield": 10.0,
			"bless_hps": 2.0,
			"bless_time": 3.0,
			"status": "bless",
		},
		"fx": {
			"id": "light_purge",
			"trail_color": Color(1.0, 0.92, 0.55, 1.0),
			"flash_color": Color(1.0, 0.96, 0.7, 0.65),
			"trail_width": 5.0,
			"flash_radius": 28.0,
		},
	},
	"nat_grove": {
		"family": FAMILY_AFFINITY,
		"name_key": "nat.grove",
		"icon": "res://assets/ui/icons/skills/nat_grove.png",
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
		"passive": {"light_dmg": 0.05, "light_dmg_per": 0.035, "hp_regen": 0.4, "companion_hp": 6.0, "companion_dmg": 0.12},
	},
	"nat_leafstep": {
		"family": FAMILY_AFFINITY,
		"name_key": "nat.leafstep",
		"icon": "res://assets/ui/icons/skills/nat_leafstep.png",
		"kind": "active",
		"col": COL_FORCE,
		"row": 0,
		"level_req": 1,
		"max_rank": 5,
		"prereq": {},
		"learn_cost": [0, 1, 2, 2, 3],
		"cast_cost": [10, 11, 12, 13, 14],
		"cooldown": [2.5, 2.4, 2.3, 2.2, 2.1],
		"range": [88.0, 92.0, 96.0, 100.0, 108.0],
		"loud": false,
		"combat": {
			"style": "dash_slash",
			"windup": 0.04,
			"active": 0.16,
			"recovery": 0.08,
			"swing_from": -28.0,
			"swing_to": 42.0,
			"hit_size": Vector2(40, 22),
			"hit_offset": Vector2(18, 0),
			"damage": 9.0,
			"damage_per_rank": 1.8,
			"knockback": 100.0,
			"poise": 7.0,
			"lunge": 88.0,
			"dash_speed": 420.0,
			"dash_duration": 0.16,
		},
		"fx": {
			"id": "dash_trail",
			"trail_color": Color(0.55, 0.92, 0.48, 1.0),
			"flash_color": Color(0.72, 1.0, 0.62, 0.46),
			"trail_width": 6.0,
			"trail_width_per_rank": 0.8,
			"flash_radius": 30.0,
			"ghost": true,
			"camera_shake": 0.04,
		},
	},
	"nat_thorn": {
		"family": FAMILY_AFFINITY,
		"name_key": "nat.thorn",
		"icon": "res://assets/ui/icons/skills/nat_thorn.png",
		"kind": "active",
		"col": COL_SLASH,
		"row": 1,
		"level_req": 5,
		"max_rank": 5,
		"prereq": {"nat_grove": 1},
		"learn_cost": [2, 3, 3, 4, 5],
		"cast_cost": [12, 13, 14, 15, 16],
		"cooldown": [2.8, 2.7, 2.6, 2.5, 2.4],
		"range": [120.0, 128.0, 136.0, 144.0, 156.0],
		"loud": false,
		"combat": {
			"style": "bolt",
			"windup": 0.08,
			"active": 0.12,
			"recovery": 0.14,
			"damage": 14.0,
			"damage_per_rank": 2.5,
			"knockback": 90.0,
			"poise": 6.0,
			"proj_speed": 360.0,
			"proj_range": 120.0,
		},
		"fx": {
			"id": "vine_bolt",
			"trail_color": Color(0.45, 0.88, 0.38, 1.0),
			"flash_color": Color(0.62, 1.0, 0.52, 0.5),
			"trail_width": 5.0,
			"flash_radius": 24.0,
		},
	},
	"nat_whirl": {
		"family": FAMILY_AFFINITY,
		"name_key": "nat.whirl",
		"icon": "res://assets/ui/icons/skills/nat_whirl.png",
		"kind": "active",
		"col": COL_BREAK,
		"row": 1,
		"level_req": 10,
		"max_rank": 5,
		"prereq": {"nat_thorn": 1},
		"learn_cost": [3, 4, 4, 5, 6],
		"cast_cost": [14, 15, 16, 18, 20],
		"cooldown": [3.2, 3.0, 2.8, 2.6, 2.4],
		"range": [72.0, 76.0, 80.0, 84.0, 92.0],
		"loud": false,
		"combat": {
			"style": "whirl",
			"windup": 0.1,
			"active": 0.22,
			"recovery": 0.16,
			"damage": 11.0,
			"damage_per_rank": 2.0,
			"knockback": 70.0,
			"poise": 5.0,
			"wave_radius": 52.0,
		},
		"fx": {
			"id": "leaf_whirl",
			"trail_color": Color(0.5, 0.9, 0.42, 1.0),
			"flash_color": Color(0.68, 1.0, 0.55, 0.48),
			"trail_width": 6.0,
			"flash_radius": 36.0,
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


static func is_affinity_imprint(family: String) -> bool:
	return normalize_imprint(family) == FAMILY_AFFINITY


static func default_held_weapon(family: String) -> String:
	match normalize_imprint(family):
		FAMILY_HOT:
			return HELD_BOW
		FAMILY_MAGE:
			return HELD_ELEMENT
		FAMILY_AFFINITY:
			return HELD_FOCUS
		_:
			return HELD_BLADE


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
		FAMILY_AFFINITY:
			return "nat_leafstep"
		_:
			return "ws_active_dashslash"


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
		FAMILY_AFFINITY:
			keys = ["skill.col.grove", "skill.col.vine", "skill.col.bloom"]
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
		FAMILY_AFFINITY:
			return "skill.panel_title_affinity"
		_:
			return "skill.panel_title"


static func imprint_display_key(family: String = FAMILY_COLD) -> String:
	var imp := normalize_imprint(family)
	match imp:
		FAMILY_HOT:
			return "stat.imprint_hot"
		FAMILY_MAGE:
			return "stat.imprint_mage"
		FAMILY_AFFINITY:
			return "stat.imprint_affinity"
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


static func _rank_pick(value: Variant, rank: int, fallback: Variant = 0) -> Variant:
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
	if migrate_id(skill_id).begins_with("ws_active_"):
		var rank_damage_mult := 1.0 + 0.08 * float(r - 1)
		for key in ["patk_multiplier", "center_patk_multiplier", "edge_patk_multiplier", "end_patk_multiplier"]:
			if base.has(key):
				base[key] = float(base[key]) * rank_damage_mult
	base["damage"] = float(base.get("damage", 10.0)) + float(base.get("damage_per_rank", 0.0)) * float(r - 1)
	var active_damage_scale := 1.0 + 0.08 * float(r - 1)
	for key in ["patk_multiplier", "center_patk_multiplier", "edge_patk_multiplier", "end_patk_multiplier"]:
		if base.has(key):
			base[key] = float(base[key]) * active_damage_scale
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
		"ws_passive_bloodinstinct":
			return "res://assets/runes/rune_s_chain.png"
		"ws_active_groundwave":
			return "res://assets/runes/rune_s_quake.png"
		"ws_active_dashslash":
			return "res://assets/runes/rune_s_cloudstep.png"
		"ws_active_whirlwind":
			return "res://assets/brands/brand_copper.png"
		"ws_active_cataclysm":
			return "res://assets/brands/brand_gold.png"
		"ws_passive_heavyarm":
			return "res://assets/ui/icons/skills/skill_slot_defend.png"
		"ws_passive_battlelust":
			return "res://assets/ui/icons/skills/skill_slot_passive.png"
		"ws_active_riposte":
			return "res://assets/ui/icons/skills/skill_slot_finisher.png"
		"ws_active_chainassault":
			return "res://assets/ui/icons/skills/skill_slot_ultimate.png"
		"ws_active_shieldbreak":
			return "res://assets/ui/icons/skills/skill_slot_dodge.png"
		_:
			return "res://assets/ui/icons/skills/skill_slot_basic.png"
