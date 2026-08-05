extends "res://scripts/pit/interactable.gd"

const Inventory = preload("res://scripts/player/inventory.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")

enum ContentType { MATERIAL, RUNE }

@export var content_type: int = ContentType.MATERIAL
@export var content_id: String = "glow_moss"
@export var content_count: int = 1


func _ready() -> void:
	super._ready()
	match content_type:
		ContentType.MATERIAL:
			prompt_key = "hud.interact_forage" if content_id == "glow_moss" else "hud.interact_ore"
		ContentType.RUNE:
			prompt_key = "hud.interact_chest"


func configure(p_type: int, p_id: String, p_count: int = 1, p_prompt: String = "") -> void:
	content_type = p_type
	content_id = p_id
	content_count = p_count
	if p_prompt != "":
		prompt_key = p_prompt


func _on_interact(by: Node) -> void:
	if content_type == ContentType.MATERIAL:
		if by.has_method("try_add_material"):
			var ok: bool = by.try_add_material(content_id, content_count)
			if ok:
				_toast(
					by,
					Loc.t("pickup.mat", [MaterialCatalog.display_with_tier(content_id), content_count]),
					PitEventLog.Category.PICKUP,
					MaterialCatalog.tier_color(content_id)
				)
				call_deferred("queue_free")
			else:
				_done = false
				enabled = true
				## 满格/超重 toast 已由 player.try_add_material 发出
	elif content_type == ContentType.RUNE:
		if by.has_method("try_add_rune"):
			var result: String = by.try_add_rune(content_id)
			_handle_rune_result(by, result)
			if result == "ok":
				call_deferred("queue_free")
			else:
				_done = false
				enabled = true


func _handle_rune_result(by: Node, result: String) -> void:
	match result:
		"ok":
			_toast(
				by,
				Loc.t("pickup.rune", [RuneCatalog.display_with_tier(content_id)]),
				PitEventLog.Category.RUNE,
				RuneCatalog.tier_color(content_id)
			)
		"full":
			_toast(by, Loc.t("bag.full"), PitEventLog.Category.WARN)
		"overweight":
			_toast(by, Loc.t("bag.overweight"), PitEventLog.Category.WARN)
		_:
			pass


func _toast(by: Node, text: String, category: int = PitEventLog.Category.SYSTEM, color: Color = Color.TRANSPARENT) -> void:
	if by.has_method("show_toast"):
		by.show_toast(text, category, color)
