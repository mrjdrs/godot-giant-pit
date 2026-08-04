extends Area2D
## 地上可走过去自动拾取的掉落物。

const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")

enum DropType { MATERIAL, RUNE }

@export var drop_type: int = DropType.MATERIAL
@export var drop_id: String = "beast_scale"
@export var drop_count: int = 1

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_apply_icon()


func setup(p_type: int, p_id: String, p_count: int = 1) -> void:
	drop_type = p_type
	drop_id = p_id
	drop_count = p_count
	if is_node_ready():
		_apply_icon()


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


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if drop_type == DropType.MATERIAL:
		if body.has_method("try_add_material") and body.try_add_material(drop_id, drop_count):
			if body.has_method("show_toast"):
				body.show_toast(Loc.t("pickup.mat", [MaterialCatalog.display_name(drop_id), drop_count]))
			queue_free()
	elif drop_type == DropType.RUNE:
		if body.has_method("try_add_rune"):
			var result: String = body.try_add_rune(drop_id)
			var rune_name := RuneCatalog.display_name(drop_id)
			if result == "ok" and body.has_method("show_toast"):
				body.show_toast(Loc.t("pickup.rune", [rune_name]))
			elif result == "upgraded" and body.has_method("show_toast"):
				body.show_toast(Loc.t("rune.upgraded", [rune_name, body.runes.get_rank(drop_id)]))
			elif result == "full" and body.has_method("show_toast"):
				body.show_toast(Loc.t("rune.slots_full"))
				return
			if result == "ok" or result == "upgraded":
				queue_free()
