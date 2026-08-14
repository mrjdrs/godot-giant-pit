extends CharacterBody2D

const StatusEffects = preload("res://scripts/combat/status_effects.gd")

@export var max_hp: float = 100.0
@export var armor: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var hp_label: Label = $HPLabel

var hp: float = 100.0
var flash_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var statuses = StatusEffects.new()


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemy")
	hp = max_hp
	if sprite:
		sprite.scale = Vector2(0.7, 0.7)
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	_update_hp_label()


func _physics_process(delta: float) -> void:
	var st: Dictionary = statuses.tick(delta)
	if float(st.get("dot_damage", 0.0)) > 0.0:
		hp = maxf(hp - float(st["dot_damage"]), 0.0)
		_update_hp_label()
		if hp <= 0.0:
			_reset_dummy()
			return
	if flash_timer > 0.0:
		flash_timer -= delta
		sprite.modulate = Color(2.0, 2.0, 2.0) if fmod(flash_timer, 0.08) < 0.04 else Color.WHITE
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE

	var move_m := float(st.get("move_mult", 1.0))
	if bool(st.get("frozen", false)):
		move_m = 0.0
	velocity = knockback_velocity * move_m
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()


func _on_hurt(hitbox: Area2D) -> void:
	var dmg: float = _hit_float(hitbox, "damage")
	var knock: float = _hit_float(hitbox, "knockback_force")
	var src = hitbox.get("source")

	dmg *= statuses.damage_taken_mult()
	var eff_armor := maxf(armor - statuses.pdef_cut(), 0.0)
	if eff_armor > 0.0 and dmg > 0.0:
		dmg = maxf(dmg - eff_armor, dmg * 0.35)

	hp = maxf(hp - dmg, 0.0)
	flash_timer = 0.18
	_update_hp_label()

	var dir := Vector2.RIGHT
	if src is Node2D:
		dir = (global_position - (src as Node2D).global_position).normalized()
	elif hitbox.get_parent() is Node2D:
		dir = Vector2.from_angle((hitbox.get_parent() as Node2D).global_rotation)
	knockback_velocity = dir * knock

	_apply_hit_statuses(hitbox, src)

	print(Loc.t("dummy.hit", [dmg, hp]))

	if hp <= 0.0:
		_reset_dummy()


func _apply_hit_statuses(hitbox: Object, src) -> void:
	if hitbox != null and hitbox.has_meta("status_kind"):
		var kind := str(hitbox.get_meta("status_kind"))
		var payload: Dictionary = {}
		if hitbox.has_meta("status_payload"):
			payload = hitbox.get_meta("status_payload")
		statuses.apply(kind, payload)
		return
	if src != null and src.has_method("on_hit_apply_status"):
		src.on_hit_apply_status(self, hitbox)
		return
	if src != null and src.has_method("has_burn") and src.has_burn():
		var dur: float = float(src.burn_time()) if src.has_method("burn_time") else 2.2
		statuses.apply(StatusEffects.KIND_BURN, {"dps": float(src.burn_dps()), "duration": dur})


func _hit_float(hitbox: Object, prop: String, fallback: float = 0.0) -> float:
	if hitbox == null:
		return fallback
	var v = hitbox.get(prop)
	match typeof(v):
		TYPE_FLOAT, TYPE_INT:
			return float(v)
		_:
			return fallback


func apply_status(kind: String, payload: Dictionary = {}) -> void:
	statuses.apply(kind, payload)


func apply_burn(dps: float, duration: float = 1.6) -> void:
	statuses.apply(StatusEffects.KIND_BURN, {"dps": dps, "duration": duration})


func _reset_dummy() -> void:
	hp = max_hp
	flash_timer = 0.0
	statuses.clear_all()
	sprite.modulate = Color.WHITE
	knockback_velocity = Vector2.ZERO
	_update_hp_label()
	print(Loc.t("dummy.reset"))


func _update_hp_label() -> void:
	hp_label.text = "%d/%d" % [int(hp), int(max_hp)]
