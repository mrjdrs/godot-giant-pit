extends RefCounted
class_name SegmentTypes
## 横版段落节点类型与生态定义。

const BIOME_MOSS := "moss"
const BIOME_COPPER := "copper"
const BIOME_ECHO := "echo"

const NODE_COMBAT := "combat"
const NODE_RESOURCE := "resource"
const NODE_ELITE := "elite"
const NODE_EVENT := "event"
const NODE_EXTRACT := "extract"
const NODE_BOSS := "boss"
const NODE_WARP := "warp"
const NODE_SHORTCUT := "shortcut"
const NODE_QUEST := "quest"
const NODE_DESCENT := "descent"

const BIOME_ORDER := [BIOME_MOSS, BIOME_COPPER, BIOME_ECHO]

const BIOME_INFO := {
	BIOME_MOSS: {"name_key": "biome.moss", "rule_key": "biome.rule.moss", "warp": "warp_a"},
	BIOME_COPPER: {"name_key": "biome.copper", "rule_key": "biome.rule.copper", "warp": "warp_b"},
	BIOME_ECHO: {"name_key": "biome.echo", "rule_key": "biome.rule.echo", "warp": "warp_c"},
}

const ENEMY_POOL := {
	BIOME_MOSS: {"mob": "moss_mob", "elite": "moss_elite", "guard": "moss_guard", "drop": "glow_moss"},
	BIOME_COPPER: {"mob": "copper_mob", "elite": "copper_elite", "guard": "copper_guard", "drop": "alchem_slag"},
	BIOME_ECHO: {"mob": "echo_mob", "elite": "echo_elite", "guard": "echo_guard", "drop": "mind_shard"},
}

const ARCHETYPE_MELEE := "melee"
const ARCHETYPE_RANGED := "ranged"
const ARCHETYPE_FLYER := "flyer"
const ARCHETYPE_ELITE := "elite"
const ARCHETYPE_BOSS := "boss"

const COMBAT_ARCHETYPES := [ARCHETYPE_MELEE, ARCHETYPE_RANGED, ARCHETYPE_FLYER]

const ENEMY_DEFS := {
	"side_melee": {
		"id": "side_melee",
		"archetype": ARCHETYPE_MELEE,
		"hp": 58.0,
		"dmg": 12.0,
		"armor": 3.0,
		"poise": 30.0,
		"speed": 75.0,
		"icon": "res://assets/enemies/side/side_melee.png",
	},
	"side_ranged": {
		"id": "side_ranged",
		"archetype": ARCHETYPE_RANGED,
		"hp": 46.0,
		"dmg": 9.0,
		"armor": 2.0,
		"poise": 22.0,
		"speed": 65.0,
		"icon": "res://assets/enemies/side/side_ranged.png",
	},
	"side_flyer": {
		"id": "side_flyer",
		"archetype": ARCHETYPE_FLYER,
		"hp": 40.0,
		"dmg": 10.0,
		"armor": 2.0,
		"poise": 18.0,
		"speed": 80.0,
		"icon": "res://assets/enemies/side/side_flyer.png",
	},
	"side_elite": {
		"id": "side_elite",
		"archetype": ARCHETYPE_ELITE,
		"hp": 175.0,
		"dmg": 19.0,
		"armor": 6.0,
		"poise": 80.0,
		"speed": 70.0,
		"icon": "res://assets/enemies/side/side_elite.png",
		"rune": 0.25,
	},
	"side_boss": {
		"id": "side_boss",
		"archetype": ARCHETYPE_BOSS,
		"hp": 384.0,
		"dmg": 21.0,
		"armor": 8.0,
		"poise": 140.0,
		"speed": 55.0,
		"icon": "res://assets/enemies/side/side_boss.png",
		"is_boss": true,
		"rune": 0.5,
	},
}

const ARCHETYPE_TO_ID := {
	ARCHETYPE_MELEE: "side_melee",
	ARCHETYPE_RANGED: "side_ranged",
	ARCHETYPE_FLYER: "side_flyer",
	ARCHETYPE_ELITE: "side_elite",
	ARCHETYPE_BOSS: "side_boss",
}


static func enemy_def(enemy_key: String, drop_mat: String = "", overrides: Dictionary = {}) -> Dictionary:
	var def: Dictionary = ENEMY_DEFS.get(enemy_key, ENEMY_DEFS["side_melee"]).duplicate(true)
	if drop_mat != "":
		def["drop"] = drop_mat
	def.merge(overrides, true)
	return def


static func combat_archetype_def(archetype: String, drop_mat: String = "", overrides: Dictionary = {}) -> Dictionary:
	var key: String = str(ARCHETYPE_TO_ID.get(archetype, "side_melee"))
	return enemy_def(key, drop_mat, overrides)

const AWAKEN_MAT_WHIRL := "mat_whirl_edge"
const AWAKEN_MAT_IRON := "mat_iron_guard"
