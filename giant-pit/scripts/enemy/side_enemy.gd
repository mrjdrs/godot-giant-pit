extends CharacterBody2D
## 横版敌人：原型状态机 + 韧性破盾 + 头顶血条。

const ST = preload("res://scripts/pit/segment_types.gd")
const AttackPatterns = preload("res://scripts/enemy/enemy_attack_patterns.gd")
const EnemyCatalog = preload("res://scripts/enemy/enemy_catalog.gd")

signal died_with_id(enemy_id: String, meta: Dictionary)
signal stats_changed(hp: float, max_hp: float, poise: float, max_poise: float)
signal poise_broken()

enum AiState { PATROL, CHASE, WINDUP, ATTACK, RECOVER }

const HP_BAR_W := 28.0
const HP_BAR_H := 3.0
const POISE_BAR_H := 2.0
const BREAK_STUN := 1.2
const BREAK_DMG_MULT := 1.5
const GRAVITY := 980.0

@export var max_hp: float = 40.0
@export var max_poise: float = 30.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 8.0
@export var attack_cooldown: float = 1.1
@export var aggro_range: float = 160.0
@export var drop_mat_id: String = "glow_moss"
@export var drop_rune_chance: float = 0.08
@export var enemy_id: String = "mob"
@export var archetype: String = "melee"
@export var is_boss: bool = false
@export var is_elite: bool = false
@export var warp_unlock_id: String = ""
@export var quest_scale: bool = false
@export var awaken_drop: String = ""

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox

var hp: float = 40.0
var poise: float = 30.0
var _cd: float = 0.0
var _dir: float = 1.0
var _flash: float = 0.0
var _dead: bool = false
var _patrol_origin: Vector2 = Vector2.ZERO
var aggro_mult: float = 1.0
var _hitstun: float = 0.0
var _poise_broken: bool = false
var _base_scale: Vector2 = Vector2.ONE
var _ai_state: AiState = AiState.PATROL
var _state_timer: float = 0.0
var _attack_kind: String = ""
var _boss_pattern: int = 0
var _hover_y: float = 0.0
var _hp_bg: Polygon2D
var _hp_fill: Polygon2D
var _poise_fill: Polygon2D
var _contact_window: float = 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemy")
	if quest_scale:
		add_to_group("scale_rock")
	if warp_unlock_id != "":
		add_to_group("warp_guard")
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	hp = max_hp
	poise = max_poise
	_patrol_origin = global_position
	_base_scale = scale
	_hover_y = global_position.y


func configure(def: Dictionary) -> void:
	enemy_id = str(def.get("id", enemy_id))
	archetype = str(def.get("archetype", ST.ARCHETYPE_MELEE))
	max_hp = float(def.get("hp", max_hp))
	hp = max_hp
	max_poise = float(def.get("poise", def.get("max_poise", max_poise)))
	poise = max_poise
	contact_damage = float(def.get("dmg", contact_damage))
	drop_mat_id = str(def.get("drop", drop_mat_id))
	drop_rune_chance = float(def.get("rune", drop_rune_chance))
	quest_scale = bool(def.get("quest_scale", quest_scale))
	warp_unlock_id = str(def.get("warp", warp_unlock_id))
	is_boss = bool(def.get("is_boss", is_boss))
	is_elite = archetype == ST.ARCHETYPE_ELITE or bool(def.get("is_elite", false))
	awaken_drop = str(def.get("awaken", awaken_drop))
	move_speed = float(def.get("speed", move_speed))
	var icon_path := str(def.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		sprite.texture = load(icon_path)
	if is_boss:
		scale = Vector2(1.35, 1.35)
		_base_scale = scale
		add_to_group("floor_boss")
	elif is_elite:
		scale = Vector2(1.15, 1.15)
		_base_scale = scale
	if not is_boss:
		_setup_bars()
	_emit_stats()


func _setup_bars() -> void:
	_hp_bg = Polygon2D.new()
	_hp_bg.color = Color(0.12, 0.05, 0.05, 0.92)
	_hp_bg.z_index = 8
	add_child(_hp_bg)
	_hp_fill = Polygon2D.new()
	_hp_fill.color = Color(0.85, 0.18, 0.14, 1)
	_hp_fill.z_index = 9
	add_child(_hp_fill)
	_poise_fill = Polygon2D.new()
	_poise_fill.color = Color(0.95, 0.82, 0.28, 1)
	_poise_fill.z_index = 9
	add_child(_poise_fill)
	_refresh_bars()


func _refresh_bars() -> void:
	if _hp_fill == null:
		return
	var y_off := -34.0 if not is_elite else -38.0
	var hp_ratio := clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var poise_ratio := clampf(poise / maxf(max_poise, 1.0), 0.0, 1.0)
	var hw := HP_BAR_W * 0.5
	_hp_bg.polygon = PackedVector2Array([
		Vector2(-hw, y_off), Vector2(hw, y_off),
		Vector2(hw, y_off + HP_BAR_H), Vector2(-hw, y_off + HP_BAR_H),
	])
	_hp_fill.polygon = PackedVector2Array([
		Vector2(-hw, y_off), Vector2(-hw + HP_BAR_W * hp_ratio, y_off),
		Vector2(-hw + HP_BAR_W * hp_ratio, y_off + HP_BAR_H), Vector2(-hw, y_off + HP_BAR_H),
	])
	var py := y_off - POISE_BAR_H - 1.0
	_poise_fill.polygon = PackedVector2Array([
		Vector2(-hw, py), Vector2(-hw + HP_BAR_W * poise_ratio, py),
		Vector2(-hw + HP_BAR_W * poise_ratio, py + POISE_BAR_H), Vector2(-hw, py + POISE_BAR_H),
	])


func _emit_stats() -> void:
	stats_changed.emit(hp, max_hp, poise, max_poise)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_tick_flash(delta)
	if _hitstun > 0.0:
		_hitstun -= delta
		if _hitstun <= 0.0 and _poise_broken:
			_poise_broken = false
			poise = max_poise
			_emit_stats()
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if archetype != ST.ARCHETYPE_FLYER and not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return
	if _cd > 0.0:
		_cd -= delta
	if _contact_window > 0.0:
		_contact_window -= delta
		var player := _find_player()
		if player and _overlap_player(player):
			_try_hit(player)
	_tick_ai(delta)
	sprite.flip_h = _dir < 0.0
	move_and_slide()
	if is_on_wall() and archetype != ST.ARCHETYPE_FLYER:
		_dir *= -1.0


func _tick_flash(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash -= delta
	if _poise_broken:
		sprite.modulate = Color(2.2, 2.2, 2.8) if fmod(_flash, 0.08) < 0.04 else Color(1.4, 1.2, 1.8)
	elif _flash > 0.0:
		sprite.modulate = Color(2.4, 2.4, 2.4) if fmod(_flash, 0.06) < 0.03 else Color(1.6, 0.9, 0.9)
	if _flash <= 0.0:
		sprite.modulate = Color.WHITE


func _tick_ai(delta: float) -> void:
	var player := _find_player()
	var aggro := aggro_range * aggro_mult
	var has_player := player != null and global_position.distance_to(player.global_position) <= aggro
	match _ai_state:
		AiState.PATROL:
			_do_patrol(delta)
			if has_player:
				_ai_state = AiState.CHASE
		AiState.CHASE:
			if not has_player:
				_ai_state = AiState.PATROL
				return
			_chase_player(player, delta)
			if _should_start_attack(player):
				_begin_windup(player)
		AiState.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if archetype == ST.ARCHETYPE_FLYER:
				velocity.y = move_toward(velocity.y, 0.0, 400.0 * delta)
			elif not is_on_floor():
				velocity.y += GRAVITY * delta
			_state_timer -= delta
			if _state_timer <= 0.0:
				_execute_attack(player)
		AiState.ATTACK:
			_tick_attack(delta, player)
		AiState.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if archetype != ST.ARCHETYPE_FLYER and not is_on_floor():
				velocity.y += GRAVITY * delta
			_state_timer -= delta
			if _state_timer <= 0.0:
				_ai_state = AiState.CHASE if has_player else AiState.PATROL


func _do_patrol(delta: float) -> void:
	if archetype == ST.ARCHETYPE_FLYER:
		velocity.x = _dir * move_speed * 0.5
		velocity.y = sin(Time.get_ticks_msec() * 0.004) * 20.0
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if absf(global_position.x - _patrol_origin.x) > 80.0:
		_dir = -signf(global_position.x - _patrol_origin.x)
	velocity.x = _dir * move_speed * 0.6


func _chase_player(player: Node, delta: float) -> void:
	_dir = signf(player.global_position.x - global_position.x)
	if _dir == 0.0:
		_dir = 1.0
	var dx: float = player.global_position.x - global_position.x
	var dy: float = player.global_position.y - global_position.y
	match archetype:
		ST.ARCHETYPE_RANGED:
			if absf(dx) < 70.0:
				velocity.x = -_dir * move_speed * 0.9
			elif absf(dx) > 130.0:
				velocity.x = _dir * move_speed * 1.1
			else:
				velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if not is_on_floor():
				velocity.y += GRAVITY * delta
		ST.ARCHETYPE_FLYER:
			var target_y: float = player.global_position.y - 56.0
			velocity.x = _dir * move_speed * 1.05
			velocity.y = clampf((target_y - global_position.y) * 2.0, -120.0, 120.0)
		ST.ARCHETYPE_BOSS, ST.ARCHETYPE_ELITE, ST.ARCHETYPE_MELEE:
			velocity.x = _dir * move_speed * (1.15 if is_elite else 1.25)
			if not is_on_floor():
				velocity.y += GRAVITY * delta
		_:
			velocity.x = _dir * move_speed * 1.25
			if not is_on_floor():
				velocity.y += GRAVITY * delta


func _should_start_attack(player: Node) -> bool:
	if _cd > 0.0:
		return false
	var dx: float = absf(player.global_position.x - global_position.x)
	var dy: float = absf(player.global_position.y - global_position.y)
	match archetype:
		ST.ARCHETYPE_MELEE:
			return dx < 52.0 and dy < 40.0
		ST.ARCHETYPE_RANGED:
			return dx > 50.0 and dx < 180.0 and dy < 48.0
		ST.ARCHETYPE_FLYER:
			return dx < 160.0 and dy < 80.0
		ST.ARCHETYPE_ELITE:
			return dx < 90.0 and dy < 44.0
		ST.ARCHETYPE_BOSS:
			return dx < 140.0 and dy < 56.0
	return dx < 40.0 and dy < 36.0


func _begin_windup(player: Node) -> void:
	_ai_state = AiState.WINDUP
	_dir = signf(player.global_position.x - global_position.x)
	if _dir == 0.0:
		_dir = 1.0
	sprite.modulate = Color(1.3, 1.2, 1.1)
	_state_timer = 0.42 if is_boss else (0.36 if is_elite else 0.32)
	if archetype == ST.ARCHETYPE_BOSS:
		_attack_kind = ["slam", "barrage", "leap"][_boss_pattern % 3]
		_boss_pattern += 1
	elif archetype == ST.ARCHETYPE_ELITE:
		_attack_kind = "charge" if randf() > 0.45 else "slam"
	elif archetype == ST.ARCHETYPE_RANGED:
		_attack_kind = "shoot"
	elif archetype == ST.ARCHETYPE_FLYER:
		_attack_kind = "dive" if randf() > 0.5 else "shot"
	else:
		_attack_kind = "dash"


func _execute_attack(player: Node) -> void:
	sprite.modulate = Color.WHITE
	_ai_state = AiState.ATTACK
	match _attack_kind:
		"dash":
			_state_timer = 0.22
			velocity.x = _dir * move_speed * 2.6
			_contact_window = 0.22
		"shoot":
			_state_timer = 0.35
			if player:
				AttackPatterns.spawn_arc_shot(self, global_position + Vector2(_dir * 8, -8), player.global_position, contact_damage)
		"dive":
			_state_timer = 0.45
			if player:
				var to: Vector2 = player.global_position - global_position
				velocity = to.normalized() * move_speed * 2.2
				_contact_window = 0.35
		"shot":
			_state_timer = 0.3
			AttackPatterns.spawn_projectile(
				self, global_position + Vector2(_dir * 10, -6),
				Vector2(_dir * 260.0, 0.0), contact_damage,
			)
		"charge":
			_state_timer = 0.35
			velocity.x = _dir * move_speed * 2.8
			_contact_window = 0.35
		"slam":
			_state_timer = 0.28
			velocity.x = 0.0
			AttackPatterns.spawn_shockwave(self, global_position, _dir, contact_damage * 1.2, 100.0)
		"leap":
			_state_timer = 0.55
			velocity = Vector2(_dir * move_speed * 1.6, -320.0)
			_contact_window = 0.25
		"barrage":
			_state_timer = 0.5
			if player:
				AttackPatterns.spawn_barrage(self, global_position + Vector2(0, -10), player.global_position, contact_damage * 0.9, 3, 36.0)
		_:
			_state_timer = 0.2
	_cd = attack_cooldown


func _tick_attack(delta: float, player: Node) -> void:
	if _attack_kind == "leap" and is_on_floor() and _state_timer < 0.35:
		AttackPatterns.spawn_shockwave(self, global_position, _dir, contact_damage * 1.4, 130.0)
		_state_timer = 0.15
	if archetype != ST.ARCHETYPE_FLYER and not is_on_floor():
		velocity.y += GRAVITY * delta
	_state_timer -= delta
	if player and _contact_window > 0.0 and _overlap_player(player):
		_try_hit(player)
	if _state_timer <= 0.0:
		_ai_state = AiState.RECOVER
		_state_timer = 0.35 if is_boss else 0.28
		velocity.x *= 0.3


func _overlap_player(player: Node) -> bool:
	return absf(player.global_position.x - global_position.x) < 30.0 and absf(player.global_position.y - global_position.y) < 36.0


func _try_hit(player: Node) -> void:
	if _cd > 0.0 or _hitstun > 0.0:
		return
	_cd = attack_cooldown * 0.5
	if player.has_method("take_damage"):
		player.take_damage(contact_damage, global_position)


func _on_hurt(hitbox: Area2D) -> void:
	if _dead:
		return
	var raw_dmg: float = float(hitbox.get("damage"))
	var knock: float = float(hitbox.get("knockback_force"))
	var poise_dmg: float = float(hitbox.get("poise_damage")) if hitbox.get("poise_damage") != null else knock * 0.08
	var src = hitbox.get("source")
	var dmg_mult := BREAK_DMG_MULT if _poise_broken else 1.0
	hp = maxf(hp - raw_dmg * dmg_mult, 0.0)
	_flash = 0.22
	var dir := 1.0
	if src is Node2D:
		dir = signf(global_position.x - (src as Node2D).global_position.x)
		if dir == 0.0:
			dir = 1.0
	if not _poise_broken:
		poise = maxf(poise - poise_dmg, 0.0)
		if poise <= 0.0:
			_enter_poise_break()
		else:
			_hitstun = 0.12
	else:
		_hitstun = maxf(_hitstun, 0.08)
	velocity.x = dir * knock * 0.85
	if archetype != ST.ARCHETYPE_FLYER:
		velocity.y = -90.0
	scale = _base_scale * Vector2(1.18, 0.82)
	var tw := create_tween()
	tw.tween_property(self, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ai_state = AiState.RECOVER
	_state_timer = 0.1
	_refresh_bars()
	_emit_stats()
	if hp <= 0.0:
		_die()


func _enter_poise_break() -> void:
	_poise_broken = true
	poise = 0.0
	_hitstun = BREAK_STUN
	_flash = BREAK_STUN
	_ai_state = AiState.RECOVER
	_state_timer = BREAK_STUN
	poise_broken.emit()
	_refresh_bars()
	_emit_stats()


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


func get_display_name() -> String:
	return EnemyCatalog.display_name(enemy_id)


func _find_player() -> Node:
	return get_tree().get_first_node_in_group("player")
