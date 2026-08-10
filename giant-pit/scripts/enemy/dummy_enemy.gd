extends CharacterBody2D

const MAX_HP := 100.0

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var hp_label: Label = $HPLabel

var hp: float = MAX_HP
var flash_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	if sprite:
		sprite.scale = Vector2(0.7, 0.7)
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	_update_hp_label()


func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		sprite.modulate = Color(2.0, 2.0, 2.0) if fmod(flash_timer, 0.08) < 0.04 else Color.WHITE
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE

	velocity = knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()


func _on_hurt(hitbox: Area2D) -> void:
	var dmg: float = float(hitbox.get("damage"))
	var knock: float = float(hitbox.get("knockback_force"))
	var src = hitbox.get("source")

	hp = maxf(hp - dmg, 0.0)
	flash_timer = 0.18
	_update_hp_label()

	var dir := Vector2.RIGHT
	if src is Node2D:
		dir = (global_position - (src as Node2D).global_position).normalized()
	elif hitbox.get_parent() is Node2D:
		dir = Vector2.from_angle((hitbox.get_parent() as Node2D).global_rotation)
	knockback_velocity = dir * knock

	print(Loc.t("dummy.hit", [dmg, hp]))

	if hp <= 0.0:
		_reset_dummy()


func _reset_dummy() -> void:
	hp = MAX_HP
	flash_timer = 0.0
	sprite.modulate = Color.WHITE
	knockback_velocity = Vector2.ZERO
	_update_hp_label()
	print(Loc.t("dummy.reset"))


func _update_hp_label() -> void:
	hp_label.text = "%d/%d" % [int(hp), int(MAX_HP)]
