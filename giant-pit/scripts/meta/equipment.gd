extends RefCounted
## 局外胸甲 / 挂坠。

const SLOT_CHEST := "chest"
const SLOT_AMULET := "amulet"

## 白板属性
const BASE := {
	SLOT_CHEST: {"max_hp": 25.0, "defense": 2.0, "damage": 0.0},
	SLOT_AMULET: {"max_hp": 10.0, "defense": 0.0, "damage": 0.08},
}

const UPGRADE_MAT := "alchem_slag"
const UPGRADE_COST := 2 ## 每次强化消耗


static func make_default_slot(_slot: String) -> Dictionary:
	return {
		"owned": false,
		"upgrade": 0, ## 强化等级，可为负表示磨损层（相对白板）
		"wear": 0,
		"grade": 2, ## 八品
		"quality": ItemTier.Tier.COMMON,
	}


static func ensure_fields(slot_data: Dictionary) -> void:
	if not slot_data.has("grade"):
		slot_data["grade"] = 2
	if not slot_data.has("quality"):
		slot_data["quality"] = ItemTier.Tier.COMMON


static func craft_cost(slot: String) -> Dictionary:
	## 首次打造消耗
	if slot == SLOT_CHEST:
		return {"beast_scale": 3, "alchem_slag": 2}
	return {"glow_moss": 2, "alchem_slag": 2, "mind_shard": 1}


static func effective_stats(slot_data: Dictionary, slot: String) -> Dictionary:
	var base: Dictionary = BASE[slot].duplicate()
	if not bool(slot_data.get("owned", false)):
		return {"max_hp": 0.0, "defense": 0.0, "damage": 0.0}
	var upgrade := int(slot_data.get("upgrade", 0))
	var wear := int(slot_data.get("wear", 0))
	var g_mult := ItemTier.grade_scale(int(slot_data.get("grade", 2)))
	var q_mult := ItemTier.quality_scale(int(slot_data.get("quality", ItemTier.Tier.COMMON)))
	## 有效强化 = upgrade - wear，再 clamp 到使属性 >= 50% 白板
	var net := upgrade - wear
	var out := {}
	for k in base.keys():
		var white: float = float(base[k]) * g_mult * q_mult
		var per_level := white * 0.15
		var raw: float = white + per_level * float(net)
		var floor_v: float = white * 0.5
		out[k] = maxf(raw, floor_v) if white > 0.0 else maxf(raw, 0.0)
	return out


static func apply_death_wear(slot_data: Dictionary) -> void:
	if not bool(slot_data.get("owned", false)):
		return
	var upgrade := int(slot_data.get("upgrade", 0))
	if upgrade > 0:
		slot_data["upgrade"] = upgrade - 1
	else:
		slot_data["wear"] = int(slot_data.get("wear", 0)) + 1
