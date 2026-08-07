extends CharacterBody2D
## 横版平台敌人：巡逻 + 近战接触。

const ST = preload("res://scripts/pit/segment_types.gd")

signal died_with_id(enemy_id: String, meta: Dictionary)

@export var max_hp: float = 40.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 8.0
@export var attack_cooldown: float = 1.1
@export var aggro_range: float = 160.0
@export var drop_mat_id: String = "glow_moss"
@export var drop_rune_chance: float = 0.08
@export var enemy_id: String = "mob"
@export var is_boss: bool = false
@export var warp_unlock_id: String = ""
@export var quest_scale: bool = false
@export var awaken_drop: String = ""

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox

var hp: float = 40.0
var _cd: float = 0.0
var _dir: float = 1.0
var _flash: float = 0.0
var _dead: bool = false
var _patrol_origin: Vector2 = Vector2.ZERO
var aggro_mult: float = 1.0
var _hitstun: float = 0.0
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemy")
	if quest_scale:
		add_to_group("scale_rock")
	if warp_unlock_id != "":
		add_to_group("warp_guard")
	if is_boss:
		add_to_group("floor_boss")
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	hp = max_hp
	_patrol_origin = global_position
	_base_scale = scale


func configure(def: Dictionary) -> void:
	enemy_id = str(def.get("id", enemy_id))
	max_hp = float(def.get("hp", max_hp))
	hp = max_hp
	contact_damage = float(def.get("dmg", contact_damage))
	drop_mat_id = str(def.get("drop", drop_mat_id))
	drop_rune_chance = float(def.get("rune", drop_rune_chance))
	quest_scale = bool(def.get("quest_scale", quest_scale))
	warp_unlock_id = str(def.get("warp", warp_unlock_id))
	is_boss = bool(def.get("is_boss", is_boss))
	awaken_drop = str(def.get("awaken", awaken_drop))
	move_speed = float(def.get("speed", move_speed))
	var icon_path := str(def.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		sprite.texture = load(icon_path)
	if is_boss:
		scale = Vector2(1.35, 1.35)
		_base_scale = scale


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _flash > 0.0:
		_flash -= delta
		sprite.modulate = Color(2.4, 2.4, 2.4) if fmod(_flash, 0.06) < 0.03 else Color(1.6, 0.9, 0.9)
		if _flash <= 0.0:
			sprite.modulate = Color.WHITE
	if _hitstun > 0.0:
		_hitstun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if not is_on_floor():
			velocity.y += 980.0 * delta
		move_and_slide()
		return
	if _cd > 0.0:
		_cd -= delta

	if not is_on_floor():
		velocity.y += 980.0 * delta

	var player := _find_player()
	var aggro := aggro_range * aggro_mult
	if player and global_position.distance_to(player.global_position) <= aggro:
		_dir = signf(player.global_position.x - global_position.x)
		if _dir == 0.0:
			_dir = 1.0
		velocity.x = _dir * move_speed * 1.25
		if absf(player.global_position.x - global_position.x) < 28.0 and absf(player.global_position.y - global_position.y) < 36.0:
			_try_hit(player)
	else:
		## 巡逻
		if absf(global_position.x - _patrol_origin.x) > 80.0:
			_dir = -signf(global_position.x - _patrol_origin.x)
		velocity.x = _dir * move_speed * 0.6

	sprite.flip_h = _dir < 0.0
	move_and_slide()
	if is_on_wall():
		_dir *= -1.0


func _try_hit(player: Node) -> void:
	if _cd > 0.0 or _hitstun > 0.0:
		return
	_cd = attack_cooldown
	if player.has_method("take_damage"):
		player.take_damage(contact_damage, global_position)


func _on_hurt(hitbox: Area2D) -> void:
	if _dead:
		return
	var dmg: float = float(hitbox.get("damage"))
	var knock: float = float(hitbox.get("knockback_force"))
	var src = hitbox.get("source")
	hp = maxf(hp - dmg, 0.0)
	_flash = 0.22
	var dir := 1.0
	if src is Node2D:
		dir = signf(global_position.x - (src as Node2D).global_position.x)
		if dir == 0.0:
			dir = 1.0
	## 砍中感：更强击退 + 短暂硬直 + 挤压缩放
	_hitstun = 0.18
	velocity.x = dir * knock * 0.85
	velocity.y = -90.0
	scale = _base_scale * Vector2(1.18, 0.82)
	var tw := create_tween()
	tw.tween_property(self, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hp <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	if quest_scale:
		RunSession.kill_scale += 1
	if is_boss:
		RunSession.grant_special_mind()
	var meta := {"warp": warp_unlock_id, "is_boss": is_boss}
	died_with_id.emit(enemy_id, meta)
	if warp_unlock_id != "":
		var floor_n := get_tree().get_first_node_in_group("side_pit_floor")
		if floor_n and floor_n.has_method("on_warp_guard_killed"):
			floor_n.on_warp_guard_killed(warp_unlock_id)
	_drop_loot()
	queue_free()


func _drop_loot() -> void:
	var player := _find_player()
	if player == null:
		return
	if drop_mat_id != "" and player.has_method("try_add_material"):
		player.try_add_material(drop_mat_id, 1)
	if awaken_drop != "" and player.has_method("try_add_material"):
		player.try_add_material(awaken_drop, 1)
	if randf() < drop_rune_chance and player.has_method("try_add_rune"):
		const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
		var pool: Array = RuneCatalog.DROP_POOL_LOW
		player.try_add_rune(str(pool[randi() % pool.size()]))


func _find_player() -> Node:
	return get_tree().get_first_node_in_group("player")
