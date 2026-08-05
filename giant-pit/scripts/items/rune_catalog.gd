extends RefCounted
## v0.4 符文：技能型 4 + 属性型 4。拾取进背包，耗念力学成。

enum RuneKind { SKILL, ATTR }

const DEFS := {
	"rune_s_chain": {
		"kind": RuneKind.SKILL,
		"slot": "basic",
		"name_key": "rune.s_chain",
		"icon": "res://assets/runes/rune_s_chain.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.5,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"rune_s_quake": {
		"kind": RuneKind.SKILL,
		"slot": "finisher",
		"name_key": "rune.s_quake",
		"icon": "res://assets/runes/rune_s_quake.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.5,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"rune_s_cloudstep": {
		"kind": RuneKind.SKILL,
		"slot": "dodge",
		"name_key": "rune.s_cloudstep",
		"icon": "res://assets/runes/rune_s_cloudstep.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.5,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"rune_s_ironwall": {
		"kind": RuneKind.SKILL,
		"slot": "defend",
		"name_key": "rune.s_ironwall",
		"icon": "res://assets/runes/rune_s_ironwall.png",
		"mind_level_req": 2,
		"learn_cost": 35,
		"weight": 1.5,
		"tier": ItemTier.Tier.RARE,
		"placeholder": true,
	},
	"rune_a_toughbone": {
		"kind": RuneKind.ATTR,
		"slot": "passive",
		"name_key": "rune.a_toughbone",
		"icon": "res://assets/runes/rune_a_toughbone.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.0,
		"tier": ItemTier.Tier.UNCOMMON,
		"stat_bonuses": {"vitality": 3.0, "max_hp": 15.0},
	},
	"rune_a_heavyarm": {
		"kind": RuneKind.ATTR,
		"slot": "passive",
		"name_key": "rune.a_heavyarm",
		"icon": "res://assets/runes/rune_a_heavyarm.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.0,
		"tier": ItemTier.Tier.UNCOMMON,
		"stat_bonuses": {"strength": 3.0, "patk": 4.0},
	},
	"rune_a_sharpeye": {
		"kind": RuneKind.ATTR,
		"slot": "passive",
		"name_key": "rune.a_sharpeye",
		"icon": "res://assets/runes/rune_a_sharpeye.png",
		"mind_level_req": 2,
		"learn_cost": 35,
		"weight": 1.0,
		"tier": ItemTier.Tier.RARE,
		"stat_bonuses": {"crit": 0.03},
	},
	"rune_a_cruel": {
		"kind": RuneKind.ATTR,
		"slot": "passive",
		"name_key": "rune.a_cruel",
		"icon": "res://assets/runes/rune_a_cruel.png",
		"mind_level_req": 2,
		"learn_cost": 35,
		"weight": 1.0,
		"tier": ItemTier.Tier.RARE,
		"stat_bonuses": {"critdmg": 0.10},
	},
}

const DROP_POOL := [
	"rune_s_chain", "rune_s_quake", "rune_s_cloudstep", "rune_s_ironwall",
	"rune_a_toughbone", "rune_a_heavyarm", "rune_a_sharpeye", "rune_a_cruel",
]

const DROP_POOL_LOW := [
	"rune_s_chain", "rune_s_quake", "rune_s_cloudstep",
	"rune_a_toughbone", "rune_a_heavyarm",
]


static func display_name(rune_id: String) -> String:
	var def: Dictionary = DEFS.get(rune_id, {})
	if def.is_empty():
		return rune_id
	return Loc.t(str(def.get("name_key", rune_id)))


static func weight(rune_id: String) -> float:
	var def: Dictionary = DEFS.get(rune_id, {})
	return float(def.get("weight", 1.5))


static func learn_cost(rune_id: String) -> int:
	var def: Dictionary = DEFS.get(rune_id, {})
	return int(def.get("learn_cost", 20))


static func mind_level_req(rune_id: String) -> int:
	var def: Dictionary = DEFS.get(rune_id, {})
	return int(def.get("mind_level_req", 1))


static func is_skill(rune_id: String) -> bool:
	var def: Dictionary = DEFS.get(rune_id, {})
	return int(def.get("kind", RuneKind.SKILL)) == RuneKind.SKILL


static func is_attr(rune_id: String) -> bool:
	return not is_skill(rune_id)


static func skill_slot(rune_id: String) -> String:
	var def: Dictionary = DEFS.get(rune_id, {})
	return str(def.get("slot", ""))


static func stat_bonuses(rune_id: String) -> Dictionary:
	var def: Dictionary = DEFS.get(rune_id, {})
	return def.get("stat_bonuses", {})


static func tier(rune_id: String) -> int:
	var def: Dictionary = DEFS.get(rune_id, {})
	return ItemTier.clamp_tier(int(def.get("tier", ItemTier.Tier.UNCOMMON)))


static func tier_label(rune_id: String) -> String:
	return ItemTier.display_name(tier(rune_id))


static func tier_color(rune_id: String) -> Color:
	return ItemTier.color_for(tier(rune_id))


static func display_with_tier(rune_id: String) -> String:
	return Loc.t("item.tier_name", [tier_label(rune_id), display_name(rune_id)])


## 兼容旧调用（body/weapon 装配已废弃）
static func is_body(rune_id: String) -> bool:
	return is_attr(rune_id)
