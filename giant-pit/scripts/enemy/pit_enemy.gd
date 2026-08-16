extends CharacterBody2D
## 分区杂兵 / 精英 / 看守 / BOSS。

const PickupScene = preload("res://scenes/items/pickup.tscn")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
const ProjectileScene = preload("res://scenes/combat/enemy_projectile.tscn")
const StatusEffects = preload("res://scripts/combat/status_effects.gd")

signal died_with_id(enemy_id: String, meta: Dictionary)

@export var max_hp: float = 30.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 6.0
@export var armor: float = 0.0
@export var attack_cooldown: float = 0.8
@export var aggro_range: float = 160.0
@export var drop_mat_id: String = "beast_scale"
@export var drop_rune_chance: float = 0.35
@export var enemy_id: String = "grub"
@export var is_boss: bool = false
@export var is_elite: bool = false
@export var is_special: bool = false
@export var max_poise: float = 0.0
@export var warp_unlock_id: String = "" ## 看守绑定的传送点
@export var quest_scale: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var hp_label: Label = $HPLabel

var hp: float = 30.0
var poise: float = 0.0
var _poise_broken: bool = false
var _stun_t: float = 0.0
var flash_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var attack_cd: float = 0.0
var statuses = StatusEffects.new()
var _last_damage_source = null
var _player: Node2D = null
var _hp_bg: Polygon2D = null
var _hp_fill: Polygon2D = null
var _poise_fill: Polygon2D = null
var _dying: bool = false
const HP_BAR_W := 28.0
const HP_BAR_H := 4.0
const POISE_BAR_H := 2.0
const BREAK_STUN := 1.2
const BREAK_DMG_MULT := 1.5


func configure(def: Dictionary) -> void:
	enemy_id = str(def.get("id", enemy_id))
	max_hp = float(def.get("hp", max_hp))
	contact_damage = float(def.get("dmg", contact_damage))
	armor = float(def.get("armor", armor))
	drop_mat_id = str(def.get("drop", drop_mat_id))
	drop_rune_chance = float(def.get("rune", drop_rune_chance))
	quest_scale = bool(def.get("quest_scale", false))
	warp_unlock_id = str(def.get("warp", ""))
	is_boss = bool(def.get("is_boss", false))
	is_elite = bool(def.get("is_elite", enemy_id.begins_with("elite_") or enemy_id.begins_with("guard_")))
	is_special = bool(def.get("is_special", enemy_id.begins_with("special_")))
	if def.has("poise"):
		max_poise = float(def.get("poise", 0.0))
	elif is_boss:
		max_poise = 80.0
	elif is_special:
		max_poise = 50.0
	elif is_elite:
		max_poise = 40.0
	else:
		max_poise = 0.0
	hp = max_hp
	poise = max_poise
	if is_node_ready():
		_apply_icon(str(def.get("icon", "")))
		_apply_visual_scale()
		_update_hp_label()
	else:
		set_meta("_pending_icon", str(def.get("icon", "")))


func _apply_icon(path: String) -> void:
	if path == "" or sprite == null:
		return
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	hp = max_hp
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemy")
	if quest_scale:
		add_to_group("scale_rock")
	if warp_unlock_id != "":
		add_to_group("warp_guard")
	if is_boss:
		add_to_group("floor_boss")
		aggro_range = 220.0
		move_speed = 55.0
	hurtbox.configure_layers(16)
	hurtbox.hurt.connect(_on_hurt)
	_setup_hp_bar()
	if has_meta("_pending_icon"):
		_apply_icon(str(get_meta("_pending_icon")))
		remove_meta("_pending_icon")
	_apply_visual_scale()
	_update_hp_label()
	call_deferred("_find_player")


func _apply_visual_scale() -> void:
	if sprite == null:
		return
	if is_boss or is_elite or is_special:
		sprite.scale = Vector2.ONE
	else:
		sprite.scale = Vector2(0.7, 0.7)


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
	_poise_fill = Polygon2D.new()
	_poise_fill.color = Color(0.85, 0.72, 0.18, 1)
	_poise_fill.z_index = 6
	add_child(_poise_fill)


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

	var st: Dictionary = statuses.tick(delta)
	if flash_timer <= 0.0:
		sprite.modulate = statuses.visual_tint()
	if float(st.get("dot_damage", 0.0)) > 0.0:
		if st.get("dot_source") != null:
			_last_damage_source = st.get("dot_source")
		hp = maxf(hp - float(st["dot_damage"]), 0.0)
		_update_hp_label()
		if hp <= 0.0:
			_die()
			return

	if attack_cd > 0.0:
		attack_cd -= delta
	if _stun_t > 0.0:
		_stun_t -= delta
		if _stun_t <= 0.0:
			_poise_broken = false
			poise = max_poise
			_update_hp_label()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	if bool(st.get("frozen", false)):
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	if _player == null or not is_instance_valid(_player):
		_find_player()

	var wish := Vector2.ZERO
	var move_m := float(st.get("move_mult", 1.0))
	if _player != null:
		var to_player: Vector2 = _player.global_position - global_position
		var dist := to_player.length()
		if dist < aggro_range and dist > 12.0:
			wish = to_player.normalized() * move_speed * move_m
		if _is_ranged() and dist < aggro_range and dist > 70.0 and attack_cd <= 0.0:
			_try_shoot_player(to_player)
			attack_cd = attack_cooldown * 1.4
		elif dist < 18.0 and attack_cd <= 0.0:
			_try_hit_player()
			attack_cd = attack_cooldown

	velocity = wish + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()


func _is_ranged() -> bool:
	return enemy_id in ["a_spore", "b_slag", "c_wisp"]


func _try_shoot_player(to_player: Vector2) -> void:
	if _player == null:
		return
	var dir := to_player.normalized()
	var proj := ProjectileScene.instantiate()
	var parent := get_parent()
	if parent == null:
		return
	parent.add_child(proj)
	proj.global_position = global_position + dir * 14.0
	if proj.has_method("setup"):
		proj.setup(dir * 220.0, contact_damage, 0.0, 2.4)


func _try_hit_player() -> void:
	if _player != null and _player.has_method("take_damage"):
		if bool(_player.get("invincible")):
			return
		_player.take_damage(contact_damage * statuses.outgoing_mult(), global_position)


func _on_hurt(hitbox: Area2D) -> void:
	var dmg: float = _hit_float(hitbox, "damage")
	var knock: float = _hit_float(hitbox, "knockback_force")
	var src = hitbox.get("source")
	_last_damage_source = src
	var hit_mod := {"damage_mult": 1.0, "poise_mult": 1.0}
	if src != null and src.has_method("combat_hit_modifiers"):
		hit_mod = src.combat_hit_modifiers(self, hitbox)
	dmg *= float(hit_mod.get("damage_mult", 1.0))
	if _poise_broken:
		dmg *= BREAK_DMG_MULT
	dmg *= statuses.damage_taken_mult()
	var eff_armor := maxf(armor - statuses.pdef_cut(), 0.0)
	if eff_armor > 0.0 and dmg > 0.0:
		dmg = maxf(dmg - eff_armor, dmg * 0.35)
	if max_poise > 0.0 and not _poise_broken:
		var pdmg: float = _hit_float(hitbox, "poise_damage")
		if pdmg <= 0.0:
			pdmg = knock * 0.08
		pdmg *= float(hit_mod.get("poise_mult", 1.0))
		poise = maxf(poise - pdmg, 0.0)
		if poise <= 0.0:
			_poise_broken = true
			_stun_t = BREAK_STUN
			poise = 0.0
	hp = maxf(hp - dmg, 0.0)
	flash_timer = 0.15
	_update_hp_label()

	var dir := Vector2.RIGHT
	if src is Node2D:
		dir = (global_position - (src as Node2D).global_position).normalized()
	knockback_velocity = dir * knock

	_apply_hit_statuses(hitbox, src)
	if src != null and src.has_method("on_combat_hit"):
		src.on_combat_hit(self, hitbox, dmg)

	if hp <= 0.0:
		_die()
	else:
		AudioManager.sfx_hurt_enemy()


func apply_status(kind: String, payload: Dictionary = {}) -> void:
	statuses.apply(kind, payload)


func apply_burn(dps: float, duration: float = 1.6) -> void:
	statuses.apply(StatusEffects.KIND_BURN, {"dps": dps, "duration": duration})


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
	if src != null and src.get("runes") != null and src.runes.has_burn():
		statuses.apply(StatusEffects.KIND_BURN, {"dps": src.runes.burn_dps(), "duration": 2.0})
	elif src != null and src.has_method("has_burn") and src.has_burn():
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


func _die() -> void:
	## Never add_child/queue_free physics bodies inside a physics/area callback —
	## that can infinite-loop the physics flush and balloon memory (~40MB/s).
	if _dying:
		return
	_dying = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	if hurtbox != null:
		hurtbox.invincible = true
		hurtbox.set_deferred("monitorable", false)
	call_deferred("_finish_die")


func _finish_die() -> void:
	if not is_instance_valid(self):
		return
	if quest_scale or is_in_group("scale_rock"):
		RunSession.kill_scale += 1
		MetaProgress.quest_kill_progress += 1
	if is_boss:
		RunSession.grant_special_mind()
	var meta := {"warp": warp_unlock_id, "is_boss": is_boss, "is_elite": is_elite, "is_special": is_special}
	if _last_damage_source != null and is_instance_valid(_last_damage_source) and _last_damage_source.has_method("on_enemy_killed"):
		_last_damage_source.on_enemy_killed(self)
	died_with_id.emit(enemy_id, meta)
	GameBus.pub("enemy_died", {"id": enemy_id, "rank": _rank_name(), "pos": global_position, "meta": meta})
	if warp_unlock_id != "":
		var tree := get_tree()
		if tree != null:
			tree.call_group("pit_floor", "on_warp_guard_killed", warp_unlock_id)
	_spawn_drops()
	queue_free()


func _spawn_drops() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var xp := CrystalCatalog.xp_for_kill(enemy_id, is_boss)
	if _player != null:
		var gained := MetaProgress.grant_xp(xp)
		if _player.has_method("show_toast"):
			_player.show_toast(Loc.t("toast.xp", [xp]), 0)
			if gained > 0:
				_player.show_toast(Loc.t("toast.levelup", [MetaProgress.explorer_level]), 0)
	var mat := PickupScene.instantiate()
	parent.add_child(mat)
	mat.global_position = global_position + Vector2(randf_range(-14, 14), randf_range(-10, 10))
	mat.setup(0, drop_mat_id, 1) ## MATERIAL
	var luck_bonus := 0.0
	if Engine.get_main_loop() != null:
		luck_bonus = float(MetaProgress.attr_value("luk")) * 0.005
	if randf() < SkillCatalog.crystal_drop_chance(enemy_id, is_boss) + luck_bonus:
		var n := SkillCatalog.crystal_drop_count(enemy_id, is_boss)
		if n > 0:
			var crystal := PickupScene.instantiate()
			parent.add_child(crystal)
			crystal.global_position = global_position + Vector2(randf_range(-18, 18), randf_range(-14, 14))
			crystal.setup(0, SkillCatalog.CRYSTAL_ID, n) ## MATERIAL 通用晶核
			GameBus.pub("core_dropped", {"core_id": SkillCatalog.CRYSTAL_ID, "count": n, "pos": crystal.global_position})
	if randf() < CrystalCatalog.attr_drop_chance(enemy_id, is_boss) + luck_bonus:
		var attr_id := CrystalCatalog.roll_attr_core(is_elite or is_boss or is_special)
		if attr_id != "":
			var ac := PickupScene.instantiate()
			parent.add_child(ac)
			ac.global_position = global_position + Vector2(randf_range(-18, 18), randf_range(-14, 14))
			ac.setup(
				2, attr_id, 1,
				CrystalCatalog.roll_drop_grade(enemy_id, is_boss),
				CrystalCatalog.roll_drop_quality(enemy_id, is_boss)
			)


func _rank_name() -> String:
	if is_boss:
		return "lord"
	if is_special:
		return "special"
	if is_elite:
		return "elite"
	return "trash"


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
	if _poise_fill == null:
		return
	if max_poise <= 0.0:
		_poise_fill.visible = false
		return
	_poise_fill.visible = true
	var pr := clampf(poise / max_poise, 0.0, 1.0)
	var pw := HP_BAR_W * pr
	var py := y0 + HP_BAR_H + 1.0
	_poise_fill.polygon = PackedVector2Array([
		Vector2(x0, py),
		Vector2(x0 + pw, py),
		Vector2(x0 + pw, py + POISE_BAR_H),
		Vector2(x0, py + POISE_BAR_H),
	])
