extends CharacterBody2D
## 横版木桩（含韧性测试）。

const MAX_HP := 100.0
const MAX_POISE := 50.0
const BREAK_STUN := 1.2
const BREAK_DMG_MULT := 1.5

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var hp_label: Label = $HPLabel

var hp: float = MAX_HP
var poise: float = MAX_POISE
var flash_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var _poise_broken: bool = false
var _hitstun: float = 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	_update_hp_label()


func _physics_process(delta: float) -> void:
	if _hitstun > 0.0:
		_hitstun -= delta
		if _hitstun <= 0.0 and _poise_broken:
			_poise_broken = false
			poise = MAX_POISE
			_update_hp_label()
	if not is_on_floor():
		velocity.y += 980.0 * delta
	if flash_timer > 0.0:
		flash_timer -= delta
		if _poise_broken:
			sprite.modulate = Color(2.0, 2.0, 2.5) if fmod(flash_timer, 0.08) < 0.04 else Color(1.2, 1.1, 1.6)
		else:
			sprite.modulate = Color(2.0, 2.0, 2.0) if fmod(flash_timer, 0.08) < 0.04 else Color.WHITE
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE
	velocity.x = knockback_velocity.x
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()


func _on_hurt(hitbox: Area2D) -> void:
	var dmg: float = float(hitbox.get("damage"))
	var knock: float = float(hitbox.get("knockback_force"))
	var poise_dmg: float = float(hitbox.get("poise_damage")) if hitbox.get("poise_damage") != null else knock * 0.08
	var src = hitbox.get("source")
	var mult := BREAK_DMG_MULT if _poise_broken else 1.0
	hp = maxf(hp - dmg * mult, 0.0)
	flash_timer = 0.22
	if not _poise_broken:
		poise = maxf(poise - poise_dmg, 0.0)
		if poise <= 0.0:
			_poise_broken = true
			poise = 0.0
			_hitstun = BREAK_STUN
			flash_timer = BREAK_STUN
	_update_hp_label()
	var dir := 1.0
	if src is Node2D:
		dir = signf(global_position.x - (src as Node2D).global_position.x)
		if dir == 0.0:
			dir = 1.0
	knockback_velocity = Vector2(dir * knock * 0.9, -50.0)
	scale = Vector2(1.15, 0.85)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	print(Loc.t("dummy.hit", [dmg * mult, hp]))
	if hp <= 0.0:
		_reset_dummy()


func _reset_dummy() -> void:
	hp = MAX_HP
	poise = MAX_POISE
	_poise_broken = false
	_hitstun = 0.0
	flash_timer = 0.0
	sprite.modulate = Color.WHITE
	knockback_velocity = Vector2.ZERO
	_update_hp_label()
	print(Loc.t("dummy.reset"))


func _update_hp_label() -> void:
	var poise_tag := " [破]" if _poise_broken else ""
	hp_label.text = "%d/%d 韧%d/%d%s" % [int(hp), int(MAX_HP), int(poise), int(MAX_POISE), poise_tag]
