extends CharacterBody2D
## 横版木桩。

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
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	_update_hp_label()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 980.0 * delta
	if flash_timer > 0.0:
		flash_timer -= delta
		sprite.modulate = Color(2.0, 2.0, 2.0) if fmod(flash_timer, 0.08) < 0.04 else Color.WHITE
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE
	velocity.x = knockback_velocity.x
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()


func _on_hurt(hitbox: Area2D) -> void:
	var dmg: float = float(hitbox.get("damage"))
	var knock: float = float(hitbox.get("knockback_force"))
	var src = hitbox.get("source")
	hp = maxf(hp - dmg, 0.0)
	flash_timer = 0.18
	_update_hp_label()
	var dir := 1.0
	if src is Node2D:
		dir = signf(global_position.x - (src as Node2D).global_position.x)
	knockback_velocity = Vector2(dir * knock, -30.0)
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
