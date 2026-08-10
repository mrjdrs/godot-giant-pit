extends "res://scripts/pit/interactable.gd"
## 秘境宝箱：材料 + 金币 + 通用晶核。

const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")

var looted: bool = false


func _ready() -> void:
	once = true
	prompt_key = "secret.chest_prompt"
	super._ready()


func get_prompt() -> String:
	if looted:
		return ""
	return Loc.t("secret.chest_prompt")


func _on_interact(by: Node) -> void:
	if looted:
		return
	looted = true
	RunSession.secret_chest_looted = true
	var got: PackedStringArray = []
	if by.has_method("try_add_material") and by.try_add_material("glow_moss", 2):
		got.append(Loc.t("pickup.mat", [MaterialCatalog.display_with_tier("glow_moss"), 2]))
	if by.has_method("try_add_material") and by.try_add_material("mire_pearl", 1):
		got.append(Loc.t("pickup.mat", [MaterialCatalog.display_with_tier("mire_pearl"), 1]))
	MetaProgress.add_gold(30)
	got.append(Loc.t("secret.chest_gold", [30]))
	var n := 4
	if by.has_method("try_add_material") and by.try_add_material(SkillCatalog.CRYSTAL_ID, n):
		got.append(Loc.t("pickup.mat", [MaterialCatalog.display_with_tier(SkillCatalog.CRYSTAL_ID), n]))
	if by.has_method("show_toast"):
		by.show_toast(Loc.t("secret.chest_loot", ["；".join(got)]), PitEventLog.Category.PICKUP)
	AudioManager.sfx_pickup()
