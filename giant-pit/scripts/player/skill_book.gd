extends RefCounted
## 已学技能/属性符文。真源在 MetaProgress.learned_runes。

const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")

signal changed

const SLOT_BASIC := "basic"
const SLOT_FINISHER := "finisher"
const SLOT_DODGE := "dodge"
const SLOT_DEFEND := "defend"
const SLOT_ULTIMATE := "ultimate"
const SLOT_PASSIVE := "passive"

const SLOT_ICONS := {
	SLOT_BASIC: "res://assets/ui/icons/skills/skill_slot_basic.png",
	SLOT_FINISHER: "res://assets/ui/icons/skills/skill_slot_finisher.png",
	SLOT_DODGE: "res://assets/ui/icons/skills/skill_slot_dodge.png",
	SLOT_DEFEND: "res://assets/ui/icons/skills/skill_slot_defend.png",
	SLOT_ULTIMATE: "res://assets/ui/icons/skills/skill_slot_ultimate.png",
	SLOT_PASSIVE: "res://assets/ui/icons/skills/skill_slot_passive.png",
}

const MVP_ACTIVE_SLOTS := [SLOT_BASIC, SLOT_FINISHER, SLOT_DODGE]


func has(rune_id: String) -> bool:
	return MetaProgress.has_learned(rune_id)


func learned_dict() -> Dictionary:
	return MetaProgress.learned_runes.duplicate()


func rune_for_slot(slot: String) -> String:
	for rune_id in MetaProgress.learned_runes.keys():
		if not bool(MetaProgress.learned_runes[rune_id]):
			continue
		if RuneCatalog.skill_slot(str(rune_id)) == slot:
			return str(rune_id)
	return ""


func is_slot_unlocked(slot: String) -> bool:
	if slot == SLOT_DEFEND:
		return has("rune_s_ironwall")
	if slot == SLOT_ULTIMATE:
		return false
	return slot in MVP_ACTIVE_SLOTS or rune_for_slot(slot) != ""


## source: Inventory（坑内）或 null+stash（枢纽）
## 返回 "ok" | "unknown" | "learned" | "no_rune" | "mind_level" | "no_mind" | "brand" | "stash"
func try_learn(rune_id: String, inventory = null, from_stash: bool = false, brand_quality: String = "iron") -> String:
	if not RuneCatalog.DEFS.has(rune_id):
		return "unknown"
	if not RuneCatalog.matches_brand(rune_id, brand_quality):
		return "brand"
	if has(rune_id):
		return "learned"
	var req := RuneCatalog.mind_level_req(rune_id)
	if MetaProgress.mind_level < req:
		return "mind_level"
	var cost := RuneCatalog.learn_cost(rune_id)
	if not MetaProgress.can_afford_mind(cost):
		return "no_mind"
	if from_stash:
		if MetaProgress.stash_count(rune_id) < 1:
			return "no_rune"
		if not MetaProgress.consume_stash({rune_id: 1}):
			return "no_rune"
	else:
		if inventory == null or not inventory.consume_rune(rune_id):
			return "no_rune"
	if not MetaProgress.consume_mind_value(cost):
		## 念力已检查过；若失败则尽量回滚道具
		if from_stash:
			MetaProgress.add_stash(rune_id, 1)
		elif inventory != null:
			inventory.add_rune_as_item(rune_id)
		return "no_mind"
	MetaProgress.mark_learned(rune_id)
	changed.emit()
	return "ok"
