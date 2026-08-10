extends RefCounted
## 晶核：技能 / 属性。仅营地感悟可学习。

enum CoreKind { SKILL, ATTR }

const DEFS := {
	"core_s_chain": {
		"kind": CoreKind.SKILL,
		"active": false,
		"name_key": "core.s_chain",
		"icon": "res://assets/runes/rune_s_chain.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.5,
		"tier": ItemTier.Tier.UNCOMMON,
		"loud": false,
		"stat_bonuses": {},
	},
	"core_s_quake": {
		"kind": CoreKind.SKILL,
		"active": true,
		"name_key": "core.s_quake",
		"icon": "res://assets/runes/rune_s_quake.png",
		"mind_level_req": 2,
		"learn_cost": 35,
		"weight": 1.5,
		"tier": ItemTier.Tier.UNCOMMON,
		"loud": true,
		"cooldown": 3.2,
		"range": 96.0,
	},
	"core_s_dash": {
		"kind": CoreKind.SKILL,
		"active": true,
		"name_key": "core.s_dash",
		"icon": "res://assets/runes/rune_s_cloudstep.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.5,
		"tier": ItemTier.Tier.UNCOMMON,
		"loud": false,
		"cooldown": 2.4,
		"range": 88.0,
	},
	"core_s_bolt": {
		"kind": CoreKind.SKILL,
		"active": true,
		"name_key": "core.s_bolt",
		"icon": "res://assets/runes/rune_s_ironwall.png",
		"mind_level_req": 2,
		"learn_cost": 35,
		"weight": 1.5,
		"tier": ItemTier.Tier.UNCOMMON,
		"loud": false,
		"cooldown": 2.0,
		"range": 220.0,
	},
	"core_s_whirl": {
		"kind": CoreKind.SKILL,
		"active": true,
		"name_key": "core.s_whirl",
		"icon": "res://assets/brands/brand_copper.png",
		"mind_level_req": 3,
		"learn_cost": 50,
		"weight": 1.8,
		"tier": ItemTier.Tier.RARE,
		"loud": true,
		"cooldown": 5.0,
		"range": 56.0,
	},
	"core_s_smash": {
		"kind": CoreKind.SKILL,
		"active": true,
		"name_key": "core.s_smash",
		"icon": "res://assets/brands/brand_gold.png",
		"mind_level_req": 3,
		"learn_cost": 50,
		"weight": 2.0,
		"tier": ItemTier.Tier.EPIC,
		"loud": true,
		"cooldown": 6.0,
		"range": 140.0,
	},
	"core_a_toughbone": {
		"kind": CoreKind.ATTR,
		"active": false,
		"name_key": "core.a_toughbone",
		"icon": "res://assets/runes/rune_a_toughbone.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.0,
		"tier": ItemTier.Tier.UNCOMMON,
		"stat_bonuses": {"vitality": 3.0, "max_hp": 15.0},
	},
	"core_a_heavyarm": {
		"kind": CoreKind.ATTR,
		"active": false,
		"name_key": "core.a_heavyarm",
		"icon": "res://assets/runes/rune_a_heavyarm.png",
		"mind_level_req": 1,
		"learn_cost": 20,
		"weight": 1.0,
		"tier": ItemTier.Tier.UNCOMMON,
		"stat_bonuses": {"strength": 3.0, "patk": 4.0},
	},
	"core_a_sharpeye": {
		"kind": CoreKind.ATTR,
		"active": false,
		"name_key": "core.a_sharpeye",
		"icon": "res://assets/runes/rune_a_sharpeye.png",
		"mind_level_req": 2,
		"learn_cost": 35,
		"weight": 1.0,
		"tier": ItemTier.Tier.RARE,
		"stat_bonuses": {"crit": 0.03},
	},
	"core_a_cruel": {
		"kind": CoreKind.ATTR,
		"active": false,
		"name_key": "core.a_cruel",
		"icon": "res://assets/runes/rune_a_cruel.png",
		"mind_level_req": 2,
		"learn_cost": 35,
		"weight": 1.0,
		"tier": ItemTier.Tier.RARE,
		"stat_bonuses": {"critdmg": 0.10},
	},
}

const HOTKEY_SLOTS := ["rmb", "q", "e", "r", "f", "c"]

const ENEMY_CORE := {
	"a_moss_grub": "core_s_chain",
	"a_spore": "core_s_quake",
	"a_scale": "core_s_chain",
	"b_mite": "core_s_dash",
	"b_beetle": "core_s_dash",
	"b_slag": "core_s_quake",
	"c_wisp": "core_s_bolt",
	"c_grub": "core_s_bolt",
	"c_shell": "core_s_bolt",
	"elite_a": "core_s_whirl",
	"elite_b": "core_s_whirl",
	"elite_c": "core_s_whirl",
	"guard_a": "core_s_chain",
	"guard_b": "core_s_dash",
	"guard_c": "core_s_bolt",
	"boss_floor1": "core_s_smash",
}

const ATTR_POOL_LOW := ["core_a_toughbone", "core_a_heavyarm"]
const ATTR_POOL_HIGH := ["core_a_sharpeye", "core_a_cruel"]


static func def(core_id: String) -> Dictionary:
	return DEFS.get(core_id, {})


static func has_id(core_id: String) -> bool:
	return DEFS.has(core_id)


static func display_name(core_id: String) -> String:
	var d: Dictionary = def(core_id)
	if d.is_empty():
		return core_id
	return Loc.t(str(d.get("name_key", core_id)))


static func icon_path(core_id: String) -> String:
	return str(def(core_id).get("icon", ""))


static func weight(core_id: String) -> float:
	return float(def(core_id).get("weight", 1.5))


static func learn_cost(core_id: String) -> int:
	return int(def(core_id).get("learn_cost", 20))


static func mind_level_req(core_id: String) -> int:
	return int(def(core_id).get("mind_level_req", 1))


static func is_skill(core_id: String) -> bool:
	return int(def(core_id).get("kind", CoreKind.SKILL)) == CoreKind.SKILL


static func is_attr(core_id: String) -> bool:
	return int(def(core_id).get("kind", CoreKind.SKILL)) == CoreKind.ATTR


static func is_active(core_id: String) -> bool:
	return bool(def(core_id).get("active", false))


static func is_loud(core_id: String) -> bool:
	return bool(def(core_id).get("loud", false))


static func cooldown(core_id: String) -> float:
	return float(def(core_id).get("cooldown", 2.5))


static func skill_range(core_id: String) -> float:
	return float(def(core_id).get("range", 80.0))


static func stat_bonuses(core_id: String) -> Dictionary:
	return def(core_id).get("stat_bonuses", {})


static func tier(core_id: String) -> int:
	return ItemTier.clamp_tier(int(def(core_id).get("tier", ItemTier.Tier.UNCOMMON)))


static func tier_label(core_id: String) -> String:
	return ItemTier.display_name(tier(core_id))


static func tier_color(core_id: String) -> Color:
	return ItemTier.color_for(tier(core_id))


static func display_with_tier(core_id: String) -> String:
	return Loc.t("item.tier_name", [tier_label(core_id), display_name(core_id)])


static func drop_skill_core(enemy_id: String, is_boss: bool = false) -> String:
	if is_boss or enemy_id == "boss_floor1":
		return "core_s_smash"
	return str(ENEMY_CORE.get(enemy_id, "core_s_chain"))


static func roll_attr_core(high: bool) -> String:
	var pool: Array = ATTR_POOL_HIGH if high else ATTR_POOL_LOW
	return str(pool[randi() % pool.size()])


static func xp_for_kill(enemy_id: String, is_boss: bool = false) -> int:
	if is_boss or enemy_id == "boss_floor1":
		return 48
	if enemy_id.begins_with("elite_"):
		return 22
	if enemy_id.begins_with("guard_"):
		return 14
	return 8
