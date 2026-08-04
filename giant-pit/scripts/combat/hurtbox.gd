extends Area2D

signal hurt(hitbox: Area2D)

@export var invincible: bool = false


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 0
	collision_mask = 0


func configure_layers(layer_bit: int) -> void:
	collision_layer = layer_bit
	collision_mask = 0


func take_hit(hitbox: Area2D) -> void:
	if invincible:
		return
	hurt.emit(hitbox)
