extends "res://scripts/pit/interactable.gd"
## 秘境宝箱：材料 + 金币 + 高一档晶核。

const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")

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
	var core_id := "core_s_whirl"
	var g := mini(CrystalCatalog.grade(core_id) + 1, 9)
	var q := ItemTier.Tier.RARE
	if by.has_method("try_add_core"):
		var r: String = by.try_add_core(core_id, 1, g, q)
		if r == "ok":
			got.append(Loc.t("pickup.core_skill", [CrystalCatalog.display_with_tier(core_id, g, q), 1]))
	if by.has_method("show_toast"):
		by.show_toast(Loc.t("secret.chest_loot", ["；".join(got)]), PitEventLog.Category.PICKUP)
	AudioManager.sfx_pickup()
