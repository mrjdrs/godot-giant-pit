extends CharacterBody2D
## 阶段 B 简易近战敌人（坑蛆）。

const PickupScene = preload("res://scenes/items/pickup.tscn")

@export var max_hp: float = 30.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 6.0
@export var attack_cooldown: float = 0.8
@export var aggro_range: float = 160.0
@export var drop_mat_id: String = "beast_scale"
@export var drop_rune_chance: float = 0.35

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var hp_label: Label = $HPLabel

var hp: float = 30.0
var flash_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var attack_cd: float = 0.0
var _burn_time: float = 0.0
var _burn_dps: float = 0.0
var _player: Node2D = null
var _hp_bg: Polygon2D = null
var _hp_fill: Polygon2D = null
const HP_BAR_W := 28.0
const HP_BAR_H := 4.0


func _ready() -> void:
	hp = max_hp
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemy")
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	_setup_hp_bar()
	_update_hp_label()
	call_deferred("_find_player")


func _setup_hp_bar() -> void:
	if hp_label:
		hp_label.visible = false
	_hp_bg = Polygon2D.new()
	_hp_bg.color = Color(0.15, 0.05, 0.05, 0.95)
	_hp_bg.polygon = PackedVector2Array([
		Vector2(-HP_BAR_W * 0.5, -22),
		Vector2(HP_BAR_W * 0.5, -22),
		Vector2(HP_BAR_W * 0.5, -22 + HP_BAR_H),
		Vector2(-HP_BAR_W * 0.5, -22 + HP_BAR_H),
	])
	_hp_bg.z_index = 5
	add_child(_hp_bg)
	_hp_fill = Polygon2D.new()
	_hp_fill.color = Color(0.85, 0.15, 0.12, 1)
	_hp_fill.z_index = 6
	add_child(_hp_fill)


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]


func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		sprite.modulate = Color(2, 2, 2) if fmod(flash_timer, 0.08) < 0.04 else Color.WHITE
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE

	if _burn_time > 0.0:
		_burn_time -= delta
		hp = maxf(hp - _burn_dps * delta, 0.0)
		_update_hp_label()
		if hp <= 0.0:
			_die()
			return

	if attack_cd > 0.0:
		attack_cd -= delta

	if _player == null or not is_instance_valid(_player):
		_find_player()

	var wish := Vector2.ZERO
	if _player != null:
		var to_player: Vector2 = _player.global_position - global_position
		var dist := to_player.length()
		if dist < aggro_range and dist > 12.0:
			wish = to_player.normalized() * move_speed
		if dist < 18.0 and attack_cd <= 0.0:
			_try_hit_player()
			attack_cd = attack_cooldown

	velocity = wish + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()


func _try_hit_player() -> void:
	if _player != null and _player.has_method("take_damage"):
		if bool(_player.get("invincible")):
			return
		_player.take_damage(contact_damage, global_position)


func _on_hurt(hitbox: Area2D) -> void:
	var dmg: float = float(hitbox.get("damage"))
	var knock: float = float(hitbox.get("knockback_force"))
	var src = hitbox.get("source")
	hp = maxf(hp - dmg, 0.0)
	flash_timer = 0.15
	_update_hp_label()

	var dir := Vector2.RIGHT
	if src is Node2D:
		dir = (global_position - (src as Node2D).global_position).normalized()
	knockback_velocity = dir * knock

	if src != null and src.get("runes") != null and src.runes.has_burn():
		_burn_time = 2.0
		_burn_dps = src.runes.burn_dps()

	if hp <= 0.0:
		_die()
	else:
		AudioManager.sfx_hurt_enemy()


func _die() -> void:
	if is_in_group("scale_rock"):
		RunSession.kill_scale += 1
	_spawn_drops()
	queue_free()


func _spawn_drops() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var mat := PickupScene.instantiate()
	parent.add_child(mat)
	mat.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	mat.setup(0, drop_mat_id, 1) ## MATERIAL
	if randf() < drop_rune_chance:
		var RuneCatalog = load("res://scripts/items/rune_catalog.gd")
		var pool: Array = RuneCatalog.DROP_POOL
		var rid: String = str(pool[randi() % pool.size()])
		var rune := PickupScene.instantiate()
		parent.add_child(rune)
		rune.global_position = global_position + Vector2(randf_range(-28, 28), randf_range(-28, 28))
		rune.setup(1, rid, 1) ## RUNE


func _update_hp_label() -> void:
	if _hp_fill == null:
		return
	var ratio := clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	var w := HP_BAR_W * ratio
	var x0 := -HP_BAR_W * 0.5
	var y0 := -22.0
	_hp_fill.polygon = PackedVector2Array([
		Vector2(x0, y0),
		Vector2(x0 + w, y0),
		Vector2(x0 + w, y0 + HP_BAR_H),
		Vector2(x0, y0 + HP_BAR_H),
	])
