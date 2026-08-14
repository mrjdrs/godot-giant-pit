extends CharacterBody2D
## 亲和烙印召唤物：跟随玩家，自动近战最近敌人。

const HitboxScript = preload("res://scripts/combat/hitbox.gd")

signal died

var owner_player: Node2D = null
var kind: String = "animal"
var max_hp: float = 28.0
var hp: float = 28.0
var _atk_cd: float = 0.0
var _flash: float = 0.0
var _body: Polygon2D = null
var _glow: Polygon2D = null
var _hp_label: Label = null


func setup(player: Node2D, affinity_kind: String = "animal") -> void:
	owner_player = player
	apply_kind(affinity_kind)
	_refresh_stats()
	hp = max_hp
	_update_hp()


func apply_kind(affinity_kind: String) -> void:
	kind = affinity_kind if affinity_kind in ["animal", "plant"] else "animal"
	_rebuild_visual()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("affinity_companion")
	_ensure_visual()
	_rebuild_visual()
	if owner_player != null:
		_refresh_stats()
		hp = max_hp
		_update_hp()


func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return
	_refresh_stats()
	if _flash > 0.0:
		_flash -= delta
		modulate = Color(2.0, 1.4, 1.4) if fmod(_flash, 0.08) < 0.04 else Color.WHITE
		if _flash <= 0.0:
			modulate = Color.WHITE
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	var target := _nearest_enemy()
	var dest := owner_player.global_position + Vector2(-20, 12)
	var speed := 150.0
	if target != null:
		dest = target.global_position
		speed = 170.0
		if global_position.distance_to(target.global_position) <= 22.0 and _atk_cd <= 0.0:
			_strike(target)
	var to := dest - global_position
	if to.length() > 8.0:
		velocity = to.normalized() * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
	move_and_slide()
	_take_contact(delta)


func _refresh_stats() -> void:
	if owner_player == null or not owner_player.get("stats"):
		return
	var st = owner_player.stats
	var grove := 1
	if typeof(MetaProgress) != TYPE_NIL:
		grove = maxi(MetaProgress.skill_rank("nat_grove"), 1)
	max_hp = 22.0 + float(st.spirit) * 0.8 + float(grove) * 6.0
	hp = minf(hp, max_hp)


func _strike_damage() -> float:
	if owner_player == null or not owner_player.get("stats"):
		return 8.0
	var st = owner_player.stats
	var grove := 1
	if typeof(MetaProgress) != TYPE_NIL:
		grove = maxi(MetaProgress.skill_rank("nat_grove"), 1)
	return (6.0 + float(st.matk) * 0.35 + float(st.patk) * 0.15) * (1.0 + 0.12 * float(grove))


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := 140.0 * 140.0
	for n in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		var d: float = global_position.distance_squared_to((n as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = n
	return best


func _strike(target: Node2D) -> void:
	_atk_cd = 0.7
	var hurt := target.get_node_or_null("Hurtbox")
	if hurt == null or not hurt.has_method("take_hit"):
		return
	var fake := Area2D.new()
	fake.set_script(HitboxScript)
	fake.damage = _strike_damage()
	fake.knockback_force = 70.0
	fake.poise_damage = 5.0
	fake.source = owner_player
	hurt.take_hit(fake)
	fake.free()


func _take_contact(delta: float) -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if global_position.distance_to((n as Node2D).global_position) > 18.0:
			continue
		var dmg := 4.0
		if n.get("contact_damage") != null:
			dmg = maxf(float(n.contact_damage) * 0.35, 2.0)
		take_damage(dmg * delta * 2.2, (n as Node2D).global_position)
		break


func take_damage(amount: float, _from_pos: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	_flash = 0.16
	_update_hp()
	if hp <= 0.0:
		died.emit()
		if owner_player != null and owner_player.has_method("_on_companion_died"):
			owner_player._on_companion_died()
		queue_free()


func _ensure_visual() -> void:
	if _glow == null:
		_glow = Polygon2D.new()
		_glow.name = "Glow"
		_glow.z_index = 8
		add_child(_glow)
	if _body == null:
		_body = Polygon2D.new()
		_body.name = "Body"
		_body.z_index = 9
		add_child(_body)
	if _hp_label == null:
		_hp_label = Label.new()
		_hp_label.position = Vector2(-16, -22)
		_hp_label.add_theme_font_size_override("font_size", 9)
		add_child(_hp_label)
	if not has_node("CollisionShape2D"):
		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 7.0
		cs.shape = circle
		add_child(cs)


func _rebuild_visual() -> void:
	_ensure_visual()
	if kind == "plant":
		_body.color = Color(0.42, 0.78, 0.32, 1.0)
		_body.polygon = PackedVector2Array([
			Vector2(-5, 6), Vector2(-2, -2), Vector2(-7, -8), Vector2(0, -11),
			Vector2(7, -7), Vector2(3, -1), Vector2(6, 6), Vector2(0, 8),
		])
		_glow.color = Color(0.55, 0.95, 0.4, 0.4)
		_glow.polygon = PackedVector2Array([
			Vector2(-8, 8), Vector2(-4, -4), Vector2(-9, -10), Vector2(0, -14),
			Vector2(9, -9), Vector2(5, -1), Vector2(8, 8), Vector2(0, 11),
		])
	else:
		_body.color = Color(0.62, 0.48, 0.32, 1.0)
		_body.polygon = PackedVector2Array([
			Vector2(-8, 4), Vector2(-4, -2), Vector2(-6, -7), Vector2(2, -8),
			Vector2(8, -3), Vector2(10, 2), Vector2(4, 7), Vector2(-3, 7),
		])
		_glow.color = Color(0.55, 0.38, 0.78, 0.45)
		_glow.polygon = PackedVector2Array([
			Vector2(-10, 6), Vector2(-6, -3), Vector2(-8, -9), Vector2(3, -10),
			Vector2(10, -4), Vector2(12, 3), Vector2(5, 9), Vector2(-4, 9),
		])


func _update_hp() -> void:
	if _hp_label:
		_hp_label.text = "%d/%d" % [int(hp), int(max_hp)]
