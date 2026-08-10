extends RefCounted
## 冷兵器·刀职业技能树。晶核加点，释放耗念力。

const HOTKEY_SLOTS := ["rmb", "q", "e", "r", "f", "c"]
const CRYSTAL_ID := "crystal_core"
const COL_SLASH := 0 ## 斩
const COL_BREAK := 1 ## 破
const COL_FORCE := 2 ## 势
const ROW_LEVELS := [1, 5, 10, 15]
const INNATE_IDS := ["sk_chain", "sk_dash"]
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
}

const DEFS := {
	"sk_chain": {
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


static func tree_ids() -> Array:
	var ids: Array = DEFS.keys()
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
	return migrate_id(skill_id) in INNATE_IDS


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
	if row < 0 or row >= ROW_LEVELS.size():
		return 1
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
	for other in DEFS.keys():
		if other == sid:
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
