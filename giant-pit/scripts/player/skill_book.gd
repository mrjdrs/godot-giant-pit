extends RefCounted
## 已感悟技能。真源在 MetaProgress.learned_skills + skill_loadout。

const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")

signal changed

const SLOT_RMB := "rmb"
const SLOT_Q := "q"
const SLOT_E := "e"
const SLOT_R := "r"
const SLOT_F := "f"
const SLOT_C := "c"
const HOTKEYS := ["rmb", "q", "e", "r", "f", "c"]

const SLOT_ICONS := {
	"rmb": "res://assets/ui/icons/skills/skill_slot_finisher.png",
	"q": "res://assets/ui/icons/skills/skill_slot_basic.png",
	"e": "res://assets/ui/icons/skills/skill_slot_ultimate.png",
	"r": "res://assets/ui/icons/skills/skill_slot_defend.png",
	"f": "res://assets/ui/icons/skills/skill_slot_dodge.png",
	"c": "res://assets/ui/icons/skills/skill_slot_passive.png",
}


func has(core_id: String) -> bool:
	return MetaProgress.has_learned_skill(core_id)


func learned_dict() -> Dictionary:
	return MetaProgress.learned_skills.duplicate()


func skill_in_slot(slot: String) -> String:
	return MetaProgress.skill_in_slot(slot)


func rune_for_slot(slot: String) -> String:
	## 兼容旧面板命名
	return skill_in_slot(slot)


func is_slot_unlocked(_slot: String) -> bool:
	return true


func try_comprehend(core_id: String, inventory = null, from_stash: bool = false) -> String:
	var r := MetaProgress.try_comprehend(core_id, inventory, from_stash)
	if r == "ok":
		changed.emit()
	return r


func try_learn(core_id: String, inventory = null, from_stash: bool = false, _brand_quality: String = "iron") -> String:
	return try_comprehend(core_id, inventory, from_stash)


func assign_slot(slot: String, core_id: String) -> String:
	var r := MetaProgress.assign_skill_slot(slot, core_id)
	if r == "ok":
		changed.emit()
	return r


func cycle_slot(slot: String) -> String:
	var r := MetaProgress.cycle_skill_slot(slot)
	if r == "ok":
		changed.emit()
	return r
