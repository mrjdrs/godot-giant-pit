extends RefCounted
## 第 1 层三区域 + BOSS 域目录。

const REGION_A := "a"
const REGION_B := "b"
const REGION_C := "c"
const REGION_BOSS := "boss"
const REGION_SPAWN := "spawn"

const NAMES := {
	REGION_A: "region.a",
	REGION_B: "region.b",
	REGION_C: "region.c",
	REGION_BOSS: "region.boss",
	REGION_SPAWN: "region.spawn",
}

const FLOOR_TILES := {
	REGION_A: [
		"res://assets/tiles/region_a/tile_a_floor_01.png",
		"res://assets/tiles/region_a/tile_a_floor_02.png",
		"res://assets/tiles/region_a/tile_a_floor_03.png",
		"res://assets/tiles/region_a/tile_a_floor_04.png",
	],
	REGION_B: [
		"res://assets/tiles/region_b/tile_b_floor_01.png",
		"res://assets/tiles/region_b/tile_b_floor_02.png",
		"res://assets/tiles/region_b/tile_b_floor_03.png",
		"res://assets/tiles/region_b/tile_b_floor_04.png",
	],
	REGION_C: [
		"res://assets/tiles/region_c/tile_c_floor_01.png",
		"res://assets/tiles/region_c/tile_c_floor_02.png",
		"res://assets/tiles/region_c/tile_c_floor_03.png",
		"res://assets/tiles/region_c/tile_c_floor_04.png",
	],
	REGION_BOSS: [
		"res://assets/tiles/region_boss/tile_boss_floor_01.png",
		"res://assets/tiles/region_boss/tile_boss_floor_02.png",
	],
}

const WALL_TILES := {
	REGION_A: "res://assets/tiles/region_a/tile_a_wall.png",
	REGION_B: "res://assets/tiles/region_b/tile_b_wall.png",
	REGION_C: "res://assets/tiles/region_c/tile_c_wall.png",
	REGION_BOSS: "res://assets/tiles/region_boss/tile_boss_wall.png",
}

const DECOR := {
	REGION_A: ["res://assets/tiles/region_a/tile_a_moss.png", "res://assets/tiles/region_a/tile_a_water.png"],
	REGION_B: ["res://assets/tiles/region_b/tile_b_vein.png", "res://assets/tiles/region_b/tile_b_scrap.png"],
	REGION_C: ["res://assets/tiles/region_c/tile_c_lamp.png", "res://assets/tiles/region_c/tile_c_shadow.png"],
	REGION_BOSS: ["res://assets/tiles/region_boss/tile_boss_crack.png"],
}

const ENEMY_POOL := {
	REGION_A: [
		{"id": "a_moss_grub", "icon": "res://assets/enemies/region_a/enemy_a_moss_grub.png", "hp": 40.0, "dmg": 7.0, "armor": 3.0, "drop": "glow_moss", "rune": 0.25},
		{"id": "a_spore", "icon": "res://assets/enemies/region_a/enemy_a_spore_spitter.png", "hp": 36.0, "dmg": 9.0, "armor": 2.0, "drop": "mire_pearl", "rune": 0.3},
		{"id": "a_scale", "icon": "res://assets/enemies/region_a/enemy_a_scale_rock.png", "hp": 58.0, "dmg": 10.0, "armor": 4.0, "drop": "beast_scale", "rune": 0.35, "quest_scale": true},
	],
	REGION_B: [
		{"id": "b_mite", "icon": "res://assets/enemies/region_b/enemy_b_copper_mite.png", "hp": 44.0, "dmg": 8.0, "armor": 3.0, "drop": "fold_copper", "rune": 0.25},
		{"id": "b_beetle", "icon": "res://assets/enemies/region_b/enemy_b_rust_beetle.png", "hp": 52.0, "dmg": 9.0, "armor": 3.0, "drop": "chitin_plate", "rune": 0.3},
		{"id": "b_slag", "icon": "res://assets/enemies/region_b/enemy_b_slag_spitter.png", "hp": 38.0, "dmg": 10.0, "armor": 2.0, "drop": "alchem_slag", "rune": 0.3},
	],
	REGION_C: [
		{"id": "c_wisp", "icon": "res://assets/enemies/region_c/enemy_c_lamp_wisp.png", "hp": 32.0, "dmg": 8.0, "armor": 2.0, "drop": "lamp_oil_crystal", "rune": 0.3},
		{"id": "c_grub", "icon": "res://assets/enemies/region_c/enemy_c_shade_grub.png", "hp": 46.0, "dmg": 9.0, "armor": 3.0, "drop": "blind_wick", "rune": 0.25},
		{"id": "c_shell", "icon": "res://assets/enemies/region_c/enemy_c_lantern_shell.png", "hp": 64.0, "dmg": 12.0, "armor": 4.0, "drop": "chitin_plate", "rune": 0.35},
	],
}

const ELITES := {
	REGION_A: {"id": "elite_a", "icon": "res://assets/enemies/elites/elite_a_mire_lord.png", "hp": 150.0, "dmg": 14.0, "armor": 6.0, "drop": "mire_pearl", "rune": 0.9},
	REGION_B: {"id": "elite_b", "icon": "res://assets/enemies/elites/elite_b_copper_warden.png", "hp": 162.0, "dmg": 16.0, "armor": 6.0, "drop": "fold_copper", "rune": 0.9},
	REGION_C: {"id": "elite_c", "icon": "res://assets/enemies/elites/elite_c_blind_keeper.png", "hp": 156.0, "dmg": 17.0, "armor": 6.0, "drop": "blind_wick", "rune": 0.9},
}

const GUARDS := {
	"warp_a": {"id": "guard_a", "icon": "res://assets/enemies/guards/guard_a_warp.png", "hp": 90.0, "dmg": 12.0, "armor": 5.0, "drop": "mind_shard", "rune": 0.5, "warp": "warp_a"},
	"warp_b": {"id": "guard_b", "icon": "res://assets/enemies/guards/guard_b_warp.png", "hp": 98.0, "dmg": 12.0, "armor": 5.0, "drop": "mind_shard", "rune": 0.5, "warp": "warp_b"},
	"warp_c": {"id": "guard_c", "icon": "res://assets/enemies/guards/guard_c_warp.png", "hp": 104.0, "dmg": 13.0, "armor": 5.0, "drop": "mind_shard", "rune": 0.5, "warp": "warp_c"},
}

const ALL_WARPS := ["warp_a", "warp_a2", "warp_b", "warp_b2", "warp_c", "warp_c2"]

const BOSS := {
	"id": "boss_floor1",
	"icon": "res://assets/enemies/bosses/boss_floor1_pit_crown.png",
	"hp": 336.0,
	"dmg": 18.0,
	"armor": 8.0,
	"drop": "mind_core",
	"rune": 1.0,
}

const FORAGE := {
	REGION_A: {"mat": "glow_moss", "icon": "res://assets/props/gather/prop_forage_a.png"},
	REGION_B: {"mat": "fold_copper", "icon": "res://assets/props/gather/prop_forage_b.png"},
	REGION_C: {"mat": "blind_wick", "icon": "res://assets/props/gather/prop_forage_c.png"},
}

const ORE := {
	REGION_A: {"mat": "deep_red_ore", "icon": "res://assets/props/gather/prop_ore_a.png"},
	REGION_B: {"mat": "copper_vein", "icon": "res://assets/props/gather/prop_ore_b.png"},
	REGION_C: {"mat": "lamp_oil_crystal", "icon": "res://assets/props/gather/prop_ore_c.png"},
}

const MINIMAP_COLORS := {
	REGION_A: Color(0.22, 0.48, 0.28, 1),
	REGION_B: Color(0.55, 0.4, 0.2, 1),
	REGION_C: Color(0.35, 0.32, 0.55, 1),
	REGION_BOSS: Color(0.55, 0.18, 0.2, 1),
	REGION_SPAWN: Color(0.4, 0.42, 0.45, 1),
}


static func display_name(region_id: String) -> String:
	var key: String = str(NAMES.get(region_id, ""))
	if key == "":
		return region_id
	return Loc.t(key)


static func region_of_warp(warp_id: String) -> String:
	if warp_id.begins_with("warp_a"):
		return REGION_A
	if warp_id.begins_with("warp_b"):
		return REGION_B
	if warp_id.begins_with("warp_c"):
		return REGION_C
	return ""


static func warps_of_region(rid: String) -> Array:
	return ["warp_%s" % rid, "warp_%s2" % rid]


static func guard_def(warp_id: String) -> Dictionary:
	if GUARDS.has(warp_id):
		return GUARDS[warp_id].duplicate()
	var rid := region_of_warp(warp_id)
	if rid == "" or not GUARDS.has("warp_%s" % rid):
		return {}
	var d: Dictionary = GUARDS["warp_%s" % rid].duplicate()
	d["warp"] = warp_id
	return d


static func warp_display_name(warp_id: String) -> String:
	var suffix := warp_id.replace("warp_", "")
	var key := "warp.%s" % suffix
	if Loc.has_key(key):
		return Loc.t(key)
	var rid := region_of_warp(warp_id)
	if rid != "" and Loc.has_key("warp.%s" % rid):
		return Loc.t("warp.%s" % rid)
	return Loc.t("map.type_warp")
