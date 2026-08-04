extends Area2D

signal hit(hurtbox: Area2D)

var damage: float = 1.0
var knockback_force: float = 120.0
var source: Node2D = null

var _active: bool = false
var _hit_ids: Dictionary = {}


func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	area_entered.connect(_on_area_entered)


func configure_layers(layer_bit: int, mask_bit: int) -> void:
	collision_layer = layer_bit
	collision_mask = mask_bit


func enable(p_damage: float, p_knockback: float, p_source: Node2D = null) -> void:
	damage = p_damage
	knockback_force = p_knockback
	source = p_source
	_hit_ids.clear()
	_active = true
	monitoring = true


func disable() -> void:
	_active = false
	monitoring = false
	_hit_ids.clear()


func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	if area.has_method("take_hit"):
		var id := area.get_instance_id()
		if _hit_ids.has(id):
			return
		_hit_ids[id] = true
		area.call("take_hit", self)
		hit.emit(area)
