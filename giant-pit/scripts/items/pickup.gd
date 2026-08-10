extends "res://scripts/pit/interactable.gd"
## 地上掉落：需靠近按空格拾取；堆叠时可由滚轮切换目标。

const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")

enum DropType { MATERIAL, RUNE, CORE }

@export var drop_type: int = DropType.MATERIAL
@export var drop_id: String = "beast_scale"
@export var drop_count: int = 1
@export var drop_grade: int = -1
@export var drop_quality: int = -1

@onready var sprite: Sprite2D = $Sprite

var _bob_t: float = 0.0
var _base_sprite_y: float = 0.0


func _ready() -> void:
	once = false
	prompt_key = "hud.interact_pickup"
	z_index = 8
	super._ready()
	if sprite:
		_base_sprite_y = sprite.position.y
	_apply_icon()


func _process(delta: float) -> void:
	_bob_t += delta
	if sprite:
		sprite.position.y = _base_sprite_y + sin(_bob_t * 4.0) * 2.5


func setup(p_type: int, p_id: String, p_count: int = 1, p_grade: int = -1, p_quality: int = -1) -> void:
	drop_type = p_type
	drop_id = p_id
	drop_count = p_count
	drop_grade = p_grade
	drop_quality = p_quality
	if is_node_ready():
		_apply_icon()


func get_prompt() -> String:
	return Loc.t("hud.interact_pickup_named", [_display_name()])


func get_display_name() -> String:
	return _display_name()


func _display_name() -> String:
	if drop_type == DropType.MATERIAL:
		return MaterialCatalog.display_name(drop_id)
	if drop_type == DropType.CORE:
		return CrystalCatalog.display_name(drop_id)
	return RuneCatalog.display_name(drop_id)


func _apply_icon() -> void:
	if sprite == null:
		return
	var path := ""
	if drop_type == DropType.MATERIAL and MaterialCatalog.MATERIALS.has(drop_id):
		path = str(MaterialCatalog.MATERIALS[drop_id].get("icon", ""))
	elif drop_type == DropType.CORE and CrystalCatalog.has_id(drop_id):
		path = CrystalCatalog.icon_path(drop_id)
	elif drop_type == DropType.RUNE and RuneCatalog.DEFS.has(drop_id):
		path = str(RuneCatalog.DEFS[drop_id].get("icon", ""))
	if path != "":
		sprite.texture = load(path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if drop_type == DropType.CORE:
		sprite.scale = Vector2(1.45, 1.45)
		modulate = Color(1.08, 1.02, 0.88, 1)
	else:
		sprite.scale = Vector2.ONE
		modulate = Color.WHITE


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
	elif drop_type == DropType.CORE:
		if not by.has_method("try_add_core"):
			return
		var result: String = by.try_add_core(drop_id, drop_count, drop_grade, drop_quality)
		if result == "ok":
			if by.has_method("show_toast"):
				var key := "pickup.core_skill" if CrystalCatalog.is_skill(drop_id) else "pickup.core_attr"
				if not Loc.has_key(key):
					key = "pickup.core"
				by.show_toast(
					Loc.t(key, [CrystalCatalog.display_with_tier(drop_id, drop_grade, drop_quality), drop_count]),
					PitEventLog.Category.RUNE,
					CrystalCatalog.tier_color(drop_id)
				)
			AudioManager.sfx_pickup()
			call_deferred("queue_free")
		elif by.has_method("show_toast"):
			if result == "full":
				by.show_toast(Loc.t("bag.full"), PitEventLog.Category.WARN)
			elif result == "overweight":
				by.show_toast(Loc.t("bag.overweight"), PitEventLog.Category.WARN)
	elif drop_type == DropType.RUNE:
		if not by.has_method("try_add_rune"):
			return
		var result: String = by.try_add_rune(drop_id)
		if result == "ok":
			if by.has_method("show_toast"):
				by.show_toast(
					Loc.t("pickup.rune", [RuneCatalog.display_with_tier(drop_id)]),
					PitEventLog.Category.RUNE,
					RuneCatalog.tier_color(drop_id)
				)
			AudioManager.sfx_pickup()
			call_deferred("queue_free")
		elif by.has_method("show_toast"):
			if result == "full":
				by.show_toast(Loc.t("bag.full"), PitEventLog.Category.WARN)
			elif result == "overweight":
				by.show_toast(Loc.t("bag.overweight"), PitEventLog.Category.WARN)
