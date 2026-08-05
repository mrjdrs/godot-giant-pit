extends "res://scripts/pit/interactable.gd"
## 地上掉落：需靠近按 E 拾取；堆叠时可由玩家 Q 切换目标。

const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")

enum DropType { MATERIAL, RUNE }

@export var drop_type: int = DropType.MATERIAL
@export var drop_id: String = "beast_scale"
@export var drop_count: int = 1

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	once = false
	prompt_key = "hud.interact_pickup"
	super._ready()
	_apply_icon()


func setup(p_type: int, p_id: String, p_count: int = 1) -> void:
	drop_type = p_type
	drop_id = p_id
	drop_count = p_count
	if is_node_ready():
		_apply_icon()


func get_prompt() -> String:
	return Loc.t("hud.interact_pickup_named", [_display_name()])


func get_display_name() -> String:
	return _display_name()


func _display_name() -> String:
	if drop_type == DropType.MATERIAL:
		return MaterialCatalog.display_name(drop_id)
	return RuneCatalog.display_name(drop_id)


func _apply_icon() -> void:
	if sprite == null:
		return
	var path := ""
	if drop_type == DropType.MATERIAL and MaterialCatalog.MATERIALS.has(drop_id):
		path = str(MaterialCatalog.MATERIALS[drop_id].get("icon", ""))
	elif drop_type == DropType.RUNE and RuneCatalog.DEFS.has(drop_id):
		path = str(RuneCatalog.DEFS[drop_id].get("icon", ""))
	if path != "":
		sprite.texture = load(path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func interact(by: Node) -> void:
	if not can_interact(by):
		return
	_on_interact(by)
	interacted.emit(by)


func _on_interact(by: Node) -> void:
	if drop_type == DropType.MATERIAL:
		if by.has_method("try_add_material") and by.try_add_material(drop_id, drop_count):
			if by.has_method("show_toast"):
				by.show_toast(
					Loc.t("pickup.mat", [MaterialCatalog.display_with_tier(drop_id), drop_count]),
					PitEventLog.Category.PICKUP,
					MaterialCatalog.tier_color(drop_id)
				)
			AudioManager.sfx_pickup()
			call_deferred("queue_free")
		elif by.has_method("show_toast"):
			by.show_toast(Loc.t("bag.full"), PitEventLog.Category.WARN)
	elif drop_type == DropType.RUNE:
		if not by.has_method("try_add_rune"):
			return
		var result: String = by.try_add_rune(drop_id)
		var rune_name := RuneCatalog.display_name(drop_id)
		if result == "ok":
			if by.has_method("show_toast"):
				by.show_toast(
					Loc.t("pickup.rune", [RuneCatalog.display_with_tier(drop_id)]),
					PitEventLog.Category.RUNE,
					RuneCatalog.tier_color(drop_id)
				)
			AudioManager.sfx_pickup()
			call_deferred("queue_free")
		elif result == "upgraded":
			if by.has_method("show_toast"):
				by.show_toast(
					Loc.t("rune.upgraded", [rune_name, by.runes.get_rank(drop_id)]),
					PitEventLog.Category.RUNE,
					RuneCatalog.tier_color(drop_id)
				)
			AudioManager.sfx_pickup()
			call_deferred("queue_free")
		elif result == "full" or result == "max_rank":
			if by.has_method("request_rune_replace"):
				by.request_rune_replace(self, drop_id)
			elif by.has_method("show_toast"):
				by.show_toast(Loc.t("rune.slots_full"), PitEventLog.Category.WARN)
