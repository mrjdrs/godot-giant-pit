extends CharacterBody2D
## 俯视探索者：WASD 走位，左键朝鼠标普攻，右键/QERFC 指向技能。无跳跃、无闪避。

const HitstopUtil = preload("res://scripts/combat/hitstop.gd")
const InventoryScript = preload("res://scripts/player/inventory.gd")
const CharacterStatsScript = preload("res://scripts/player/character_stats.gd")
const SkillBookScript = preload("res://scripts/player/skill_book.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const ProjectileSceneScript = preload("res://scripts/combat/player_projectile.gd")

signal hp_changed(current: float, maximum: float)
signal died
signal toast(text: String, category: int, color: Color)
signal loadout_changed
signal inventory_changed
signal stats_changed
signal interact_prompt_changed(text: String)
signal loud_skill_used(kind: String)

enum State { IDLE, MOVE, ATTACK_LIGHT, ATTACK_SKILL, DASH }
enum AttackPhase { NONE, LIGHT_WINDUP, LIGHT_ACTIVE, LIGHT_RECOVERY, SKILL_WINDUP, SKILL_ACTIVE, SKILL_RECOVERY }

const BASE_MOVE_SPEED := 150.0
const BASE_MAX_HP := 100.0
const LIGHT_COMBO_MAX := 3
const LIGHT_COMBO := [
	{
		"windup": 0.07, "active": 0.10, "recovery": 0.14,
		"damage": 8.0, "knockback": 130.0, "poise": 10.0,
		"hit_size": Vector2(38, 22), "hit_offset": Vector2(26, 0),
		"swing_from": -48.0, "swing_to": 42.0, "lunge": 28.0,
	},
	{
		"windup": 0.08, "active": 0.11, "recovery": 0.15,
		"damage": 10.0, "knockback": 150.0, "poise": 12.0,
		"hit_size": Vector2(34, 36), "hit_offset": Vector2(22, -10),
		"swing_from": -20.0, "swing_to": 78.0, "lunge": 18.0,
	},
	{
		"windup": 0.14, "active": 0.13, "recovery": 0.28,
		"damage": 14.0, "knockback": 220.0, "poise": 16.0,
		"hit_size": Vector2(44, 34), "hit_offset": Vector2(28, 4),
		"swing_from": -95.0, "swing_to": 70.0, "lunge": 42.0,
	},
]
const BLADE_ART_OFFSET_DEG := 90.0
const DASH_SPEED := 420.0
const DASH_DURATION := 0.16
const SKILL_ACTION := {
	"rmb": "attack_heavy",
	"q": "skill_q",
	"e": "skill_e",
	"r": "skill_r",
	"f": "skill_f",
	"c": "skill_c",
}

@onready var sprite: Sprite2D = $Sprite
@onready var blade_pivot: Node2D = $BladePivot
@onready var blade_sprite: Sprite2D = $BladePivot/BladeSprite
@onready var hitbox: Area2D = $BladePivot/Hitbox
@onready var hitbox_shape: CollisionShape2D = $BladePivot/Hitbox/CollisionShape2D

var state: State = State.IDLE
var facing: Vector2 = Vector2.RIGHT
var invincible: bool = false
var attack_locked_facing: Vector2 = Vector2.RIGHT
var combo_step: int = 0
var combo_window: float = 0.0
var blade_swing_deg: float = 0.0
var _attack_phase: AttackPhase = AttackPhase.NONE
var _attack_timer: float = 0.0
var _attack_spd: float = 1.0
var _attack_kb: float = 260.0 ## 技能默认击退，普攻读 combo 表
var _attack_reach: float = 1.0
var _combo_def: Dictionary = {}
var _light_buffered: bool = false
var _pending_skill: String = ""
var _pending_skill_slot: String = ""
var _skill_cd: Dictionary = {}
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT

var max_hp: float = BASE_MAX_HP
var hp: float = BASE_MAX_HP
var inventory = InventoryScript.new()
var stats = CharacterStatsScript.new()
var skills = SkillBookScript.new()
var nearby_interactable: Node = null
var nearby_interactables: Array = []
var _nearby_focus: int = 0
var input_locked: bool = false
var combat_enabled: bool = true
var brand_quality: String = "iron"
var equip_bonus: Dictionary = {"max_hp": 0.0, "defense": 0.0, "damage": 0.0}
var _hurt_flash: float = 0.0
var _last_prompt: String = ""
var _pending_lifesteal: float = 0.0
var _camera_shake: float = 0.0
var _camera_origin: Vector2 = Vector2.ZERO
var _locked_skill_slot: String = ""

## 俯视扩展（兼容旧场景赋值）
var side_view: bool = false
var move_speed_mult: float = 1.0
var jump_mult: float = 1.0
var skill_cd_mult: float = 1.0
var in_mud: bool = false
var in_fog: bool = false
var metal_load: float = 0.0
var awakening_branch: String = ""
var weapon_family: String = "blade" ## blade=大刀
var _tex_idle: Texture2D
var _tex_run: Texture2D
var _tex_explorer: Texture2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	hitbox.configure_layers(8, 16)
	hitbox.hit.connect(_on_hitbox_hit)
	hitbox.disable()
	_set_hitbox_size(Vector2(28, 22), Vector2(22, -4))
	_load_textures()
	_apply_blade_visual()
	if has_node("Camera2D"):
		_camera_origin = $Camera2D.offset
	inventory.changed.connect(func(): inventory_changed.emit())
	skills.changed.connect(_on_skills_changed)
	MetaProgress.changed.connect(_on_meta_changed)
	awakening_branch = MetaProgress.awakening_branch
	_refresh_character_stats(false)
	_refresh_metal_load()
	hp_changed.emit(hp, max_hp)


func _load_textures() -> void:
	if ResourceLoader.exists("res://assets/characters/player/player_explorer.png"):
		_tex_explorer = load("res://assets/characters/player/player_explorer.png")
	_tex_idle = load("res://assets/characters/player/side/player_idle.png")
	_tex_run = load("res://assets/characters/player/side/player_run.png")
	var tex: Texture2D = _tex_explorer if _tex_explorer else _tex_idle
	if tex:
		sprite.texture = tex
		sprite.centered = true
		sprite.offset = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		sprite.modulate = Color(2.2, 1.2, 1.2) if fmod(_hurt_flash, 0.08) < 0.04 else Color.WHITE
		if _hurt_flash <= 0.0:
			sprite.modulate = Color.WHITE

	if combo_window > 0.0:
		combo_window = maxf(combo_window - delta, 0.0)
		if combo_window <= 0.0:
			combo_step = 0

	_tick_skill_cds(delta)
	_tick_attack(delta)

	match state:
		State.IDLE, State.MOVE:
			_process_free_move(delta)
		State.DASH:
			_process_dash(delta)
		State.ATTACK_LIGHT, State.ATTACK_SKILL:
			_process_attack_move(delta)

	move_and_slide()
	_update_visuals()
	_tick_camera_shake(delta)


func _tick_skill_cds(delta: float) -> void:
	for k in _skill_cd.keys():
		_skill_cd[k] = maxf(float(_skill_cd[k]) - delta, 0.0)


func _tick_camera_shake(delta: float) -> void:
	if not has_node("Camera2D"):
		return
	var cam: Camera2D = $Camera2D
	if _camera_shake > 0.0:
		_camera_shake = maxf(_camera_shake - delta, 0.0)
		var mag := 3.5 * (_camera_shake / 0.12)
		cam.offset = _camera_origin + Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	else:
		cam.offset = _camera_origin


func _process(_delta: float) -> void:
	if input_locked:
		return
	_handle_combat_input()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("cycle_interact"):
		_cycle_nearby(1)


func _handle_combat_input() -> void:
	if not combat_enabled:
		return
	if state == State.DASH:
		return
	if state == State.ATTACK_LIGHT:
		if Input.is_action_just_pressed("attack_light") and combo_step < LIGHT_COMBO_MAX:
			if _attack_phase in [AttackPhase.LIGHT_ACTIVE, AttackPhase.LIGHT_RECOVERY]:
				_light_buffered = true
		return
	if state == State.ATTACK_SKILL:
		return
	if Input.is_action_just_pressed("attack_light"):
		_start_light_attack()
		return
	for slot_id in SKILL_ACTION.keys():
		var action: String = SKILL_ACTION[slot_id]
		if not InputMap.has_action(action):
			continue
		if Input.is_action_just_pressed(action):
			_try_cast_slot(slot_id)
			return


func _process_free_move(_delta: float) -> void:
	if input_locked:
		velocity = Vector2.ZERO
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * _move_speed()
	if input_dir.length_squared() > 0.01:
		facing = input_dir.normalized()
		state = State.MOVE
	else:
		state = State.IDLE


func _process_attack_move(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * _move_speed() * 0.28
	facing = attack_locked_facing


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_dir * DASH_SPEED
	if _dash_timer <= 0.0:
		state = State.IDLE
		velocity = Vector2.ZERO


func _move_speed() -> float:
	var s := BASE_MOVE_SPEED * move_speed_mult
	if in_mud:
		s *= 0.55
	s *= 1.0 + 0.03 * float(MetaProgress.winch_level)
	return s


func _damage_mult() -> float:
	var m := 1.0
	if awakening_branch == "whirl":
		m *= 1.05
	return m


func _light_damage_mult() -> float:
	var m := 1.0 * _damage_mult()
	if skills.has("core_s_chain") or skills.has("rune_s_chain"):
		m += 0.10
		if combo_step >= 2:
			m += 0.05
		if combo_step >= 3:
			m += 0.08
	return m


func _brand_stats() -> Dictionary:
	const MindTable = preload("res://scripts/meta/mind_table.gd")
	return MindTable.BRAND_STATS.get(brand_quality, MindTable.BRAND_STATS["iron"])


func apply_meta_brand(p_brand: String = "iron") -> void:
	brand_quality = p_brand
	equip_bonus = MetaProgress.total_equipment_bonuses()
	awakening_branch = MetaProgress.awakening_branch
	_refresh_character_stats(false)
	_refresh_metal_load()


func _refresh_metal_load() -> void:
	metal_load = 0.0
	if MetaProgress.equipment.get("chest", {}).get("owned", false):
		metal_load += 1.0 + float(MetaProgress.equipment.get("chest", {}).get("level", 1)) * 0.25
	if MetaProgress.equipment.get("amulet", {}).get("owned", false):
		metal_load += 0.5
	for slot in inventory.slots:
		var sid := str(slot.get("id", ""))
		if sid in ["alchem_slag", "beast_scale", "ore_copper", "ore_iron", "fold_copper", "chitin_plate"]:
			metal_load += 0.15 * float(slot.get("count", 1))


func carry_cap() -> float:
	var cap: float = float(stats.carry_cap)
	cap += 4.0 * float(MetaProgress.winch_level)
	return cap


func skill_in_slot(slot: String) -> String:
	return MetaProgress.skill_in_slot(slot)


func skill_cd_ratio(slot: String) -> float:
	var core_id := skill_in_slot(slot)
	if core_id == "":
		return 0.0
	var max_cd := CrystalCatalog.cooldown(core_id) * skill_cd_mult
	if max_cd <= 0.0:
		return 0.0
	return clampf(float(_skill_cd.get(slot, 0.0)) / max_cd, 0.0, 1.0)


func is_skill_slot_locked(slot: String) -> bool:
	return _locked_skill_slot != "" and _locked_skill_slot == slot


func set_erosion_locked_slot(slot: String) -> void:
	_locked_skill_slot = slot


func _update_visuals() -> void:
	blade_pivot.rotation = facing.angle()
	sprite.flip_h = facing.x < 0.0
	_apply_blade_visual()
	_apply_pose_texture()


func _apply_pose_texture() -> void:
	var tex: Texture2D = _tex_explorer if _tex_explorer else _tex_idle
	if state == State.MOVE and _tex_run and _tex_explorer == null:
		tex = _tex_run
	if tex and sprite.texture != tex:
		sprite.texture = tex


func _apply_blade_visual() -> void:
	blade_sprite.rotation_degrees = BLADE_ART_OFFSET_DEG + blade_swing_deg
	blade_sprite.visible = state != State.DASH


func _face_mouse() -> void:
	var mouse := get_global_mouse_position()
	var dir := mouse - global_position
	if dir.length_squared() > 4.0:
		facing = dir.normalized()


func _start_light_attack(_lock_facing: Vector2 = Vector2.ZERO) -> void:
	_face_mouse()
	attack_locked_facing = facing
	state = State.ATTACK_LIGHT
	_light_buffered = false
	if combo_window > 0.0 and combo_step > 0 and combo_step < LIGHT_COMBO_MAX:
		combo_step += 1
	else:
		combo_step = 1
	combo_window = 0.0
	_combo_def = LIGHT_COMBO[clampi(combo_step - 1, 0, LIGHT_COMBO.size() - 1)]
	_attack_spd = 1.0
	_attack_reach = float(_brand_stats().get("reach", 1.0))
	var windup: float = float(_combo_def["windup"]) / _attack_spd
	if combo_step == 2 and (skills.has("core_s_chain") or skills.has("rune_s_chain")):
		windup *= 0.9
	var hit_size: Vector2 = _combo_def["hit_size"] * _attack_reach
	var hit_off: Vector2 = _combo_def["hit_offset"] * _attack_reach
	_set_hitbox_size(hit_size, hit_off)
	blade_swing_deg = float(_combo_def["swing_from"])
	_apply_blade_visual()
	velocity = facing * float(_combo_def.get("lunge", 0.0))
	_attack_phase = AttackPhase.LIGHT_WINDUP
	_attack_timer = windup


func _try_cast_slot(slot: String) -> void:
	if is_skill_slot_locked(slot):
		show_toast(Loc.t("skill.slot_locked"), 2)
		return
	var core_id := skill_in_slot(slot)
	if core_id == "":
		if slot == "rmb":
			_cast_default_heavy()
		return
	if float(_skill_cd.get(slot, 0.0)) > 0.0:
		return
	_cast_skill(slot, core_id)


func _cast_default_heavy() -> void:
	_face_mouse()
	attack_locked_facing = facing
	_pending_skill = "core_s_quake"
	_pending_skill_slot = "rmb"
	state = State.ATTACK_SKILL
	_attack_reach = float(_brand_stats().get("reach", 1.0))
	_set_hitbox_size(Vector2(48, 30) * _attack_reach, Vector2(30, 0) * _attack_reach)
	blade_swing_deg = -75.0
	_attack_phase = AttackPhase.SKILL_WINDUP
	_attack_timer = 0.28
	loud_skill_used.emit("heavy")


func _cast_skill(slot: String, core_id: String) -> void:
	_face_mouse()
	attack_locked_facing = facing
	_pending_skill = core_id
	_pending_skill_slot = slot
	if core_id == "core_s_dash":
		_start_dash()
		_skill_cd[slot] = CrystalCatalog.cooldown(core_id) * skill_cd_mult
		return
	state = State.ATTACK_SKILL
	var windup := 0.18
	if core_id == "core_s_smash":
		windup = 0.32
	elif core_id == "core_s_whirl":
		windup = 0.12
	elif core_id == "core_s_bolt":
		windup = 0.10
	_attack_phase = AttackPhase.SKILL_WINDUP
	_attack_timer = windup
	if CrystalCatalog.is_loud(core_id):
		loud_skill_used.emit(core_id)


func _start_dash() -> void:
	_face_mouse()
	_dash_dir = facing
	_dash_timer = DASH_DURATION
	state = State.DASH
	hitbox.disable()
	AudioManager.sfx_roll()


func _tick_attack(delta: float) -> void:
	if _attack_phase == AttackPhase.NONE:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	match _attack_phase:
		AttackPhase.LIGHT_WINDUP:
			var dmg: float = float(_combo_def["damage"]) * _light_damage_mult() * (stats.patk / CharacterStatsScript.BASE_PATK)
			var kb: float = float(_combo_def["knockback"])
			var poise: float = float(_combo_def.get("poise", kb * 0.08))
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			blade_swing_deg = float(_combo_def["swing_to"])
			_apply_blade_visual()
			_attack_phase = AttackPhase.LIGHT_ACTIVE
			_attack_timer = float(_combo_def["active"]) / _attack_spd
			AudioManager.sfx_weapon_attack(weapon_family)
		AttackPhase.LIGHT_ACTIVE:
			hitbox.disable()
			_attack_phase = AttackPhase.LIGHT_RECOVERY
			_attack_timer = float(_combo_def.get("recovery", 0.16)) / _attack_spd
		AttackPhase.LIGHT_RECOVERY:
			if _light_buffered and combo_step < LIGHT_COMBO_MAX:
				_light_buffered = false
				combo_window = 0.35
				_start_light_attack()
			else:
				_finish_attack_to_idle()
				combo_window = 0.18 if combo_step >= LIGHT_COMBO_MAX else 0.32
				if combo_step >= LIGHT_COMBO_MAX:
					combo_step = 0
		AttackPhase.SKILL_WINDUP:
			_fire_pending_skill()
			_attack_phase = AttackPhase.SKILL_ACTIVE
			_attack_timer = 0.12
		AttackPhase.SKILL_ACTIVE:
			hitbox.disable()
			_attack_phase = AttackPhase.SKILL_RECOVERY
			_attack_timer = 0.18
		AttackPhase.SKILL_RECOVERY:
			_finish_attack_to_idle()
		_:
			_attack_phase = AttackPhase.NONE


func _fire_pending_skill() -> void:
	var core_id := _pending_skill
	var slot := _pending_skill_slot
	var mouse := get_global_mouse_position()
	var dir := (mouse - global_position)
	if dir.length_squared() < 4.0:
		dir = facing
	else:
		dir = dir.normalized()
	facing = dir
	attack_locked_facing = facing
	var patk_m: float = float(stats.patk) / CharacterStatsScript.BASE_PATK
	match core_id:
		"core_s_bolt":
			_spawn_bolt(dir, 12.0 * _damage_mult() * patk_m)
		"core_s_whirl":
			_set_hitbox_size(Vector2(70, 70), Vector2(0, 0))
			hitbox.enable(_roll_attack_damage(16.0 * _damage_mult() * patk_m), 180.0, self, 18.0)
		"core_s_smash":
			var reach := CrystalCatalog.skill_range(core_id)
			var target := global_position + dir * minf(global_position.distance_to(mouse), reach)
			_set_hitbox_size(Vector2(64, 64), blade_pivot.to_local(target))
			hitbox.enable(_roll_attack_damage(28.0 * _damage_mult() * patk_m), 260.0, self, 24.0)
		_:
			## quake / default heavy：朝鼠标方向砸地
			var extra := 1.15 if skills.has("core_s_quake") or skills.has("rune_s_quake") else 1.0
			if awakening_branch == "whirl":
				extra *= 1.1
			_set_hitbox_size(Vector2(52, 36) * _attack_reach, Vector2(32, 0) * _attack_reach)
			hitbox.enable(_roll_attack_damage(22.0 * extra * _damage_mult() * patk_m), _attack_kb, self, 22.0)
	blade_swing_deg = 60.0
	_apply_blade_visual()
	AudioManager.sfx_weapon_attack(weapon_family)
	if slot != "" and CrystalCatalog.has_id(core_id):
		_skill_cd[slot] = CrystalCatalog.cooldown(core_id) * skill_cd_mult


func _spawn_bolt(dir: Vector2, dmg: float) -> void:
	var bolt := Area2D.new()
	bolt.set_script(ProjectileSceneScript)
	var parent_n := get_parent()
	if parent_n == null:
		parent_n = self
	parent_n.add_child(bolt)
	bolt.global_position = global_position + dir * 18.0
	if bolt.has_method("setup"):
		bolt.setup(dir * 320.0, dmg, self, 90.0)


func _finish_attack_to_idle() -> void:
	blade_swing_deg = 0.0
	_light_buffered = false
	_pending_skill = ""
	_pending_skill_slot = ""
	_apply_blade_visual()
	_attack_phase = AttackPhase.NONE
	_attack_timer = 0.0
	if state == State.ATTACK_LIGHT or state == State.ATTACK_SKILL:
		state = State.IDLE


func _set_hitbox_size(size: Vector2, offset: Vector2) -> void:
	var rect := hitbox_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		hitbox_shape.shape = rect
	rect.size = size
	hitbox_shape.position = offset


func _roll_attack_damage(base: float) -> float:
	var dmg := base
	if stats.crit_enabled and randf() < stats.crit:
		dmg *= 1.0 + stats.critdmg
	var ls := float(_brand_stats().get("lifesteal", 0.0))
	if ls > 0.0:
		_pending_lifesteal += dmg * ls
	return dmg


func _on_hitbox_hit(hurtbox: Area2D) -> void:
	call_deferred("_deferred_hit_fx", hurtbox)
	call_deferred("_apply_pending_lifesteal")


func _deferred_hit_fx(hurtbox: Area2D = null) -> void:
	var stop := 0.08
	if combo_step >= 3 or state == State.ATTACK_SKILL:
		stop = 0.12
	elif combo_step == 2:
		stop = 0.095
	HitstopUtil.freeze(get_tree(), stop)
	_camera_shake = maxf(_camera_shake, stop + 0.04)
	AudioManager.sfx_hurt_enemy()
	velocity *= 0.35
	var spark_pos := global_position + facing * 22.0
	if hurtbox != null and is_instance_valid(hurtbox):
		spark_pos = hurtbox.global_position
	_spawn_hit_spark(spark_pos)


func _spawn_hit_spark(pos: Vector2) -> void:
	var spark := Node2D.new()
	spark.set_script(load("res://scripts/combat/hit_spark.gd"))
	var parent_n := get_parent()
	if parent_n == null:
		parent_n = self
	parent_n.add_child(spark)
	if spark.has_method("setup"):
		spark.setup(pos, facing.x)


func _apply_pending_lifesteal() -> void:
	if _pending_lifesteal <= 0.0:
		return
	var heal := _pending_lifesteal
	_pending_lifesteal = 0.0
	hp = minf(hp + heal, max_hp)
	hp_changed.emit(hp, max_hp)


func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO) -> void:
	if invincible or input_locked:
		return
	var incoming := amount
	if awakening_branch == "ironwall":
		incoming *= 0.85
	var mitigated: float = maxf(incoming - stats.pdef, 1.0)
	hp = maxf(hp - mitigated, 0.0)
	_hurt_flash = 0.2
	hp_changed.emit(hp, max_hp)
	AudioManager.sfx_hurt_player()
	if from_pos != Vector2.ZERO:
		var push := (global_position - from_pos).normalized() * 140.0
		velocity += push
	if hp <= 0.0:
		_die()


func _die() -> void:
	input_locked = true
	_attack_phase = AttackPhase.NONE
	_attack_timer = 0.0
	state = State.IDLE
	velocity = Vector2.ZERO
	hitbox.disable()
	died.emit()


func try_add_material(mat_id: String, count: int = 1) -> bool:
	var r := inventory.add_material(mat_id, count, carry_cap())
	if r == "ok":
		_refresh_metal_load()
		return true
	if r == "full":
		show_toast(Loc.t("bag.full"), 2)
	elif r == "overweight":
		show_toast(Loc.t("bag.overweight"), 2)
	return false


func try_add_rune(rune_id: String) -> String:
	if CrystalCatalog.has_id(rune_id):
		return inventory.add_core(rune_id, 1, carry_cap())
	return inventory.add_rune_as_item(rune_id, 1, carry_cap())


func try_add_core(core_id: String, count: int = 1) -> String:
	return inventory.add_core(core_id, count, carry_cap())


func try_learn_rune(core_id: String, from_stash: bool = false) -> String:
	var r := skills.try_comprehend(core_id, inventory if not from_stash else null, from_stash)
	if r == "ok":
		_refresh_character_stats(true)
		loadout_changed.emit()
	return r


func show_toast(text: String, category: int = 3, color: Color = Color.TRANSPARENT) -> void:
	toast.emit(text, category, color)


func _on_skills_changed() -> void:
	_refresh_character_stats(true)
	loadout_changed.emit()


func _on_meta_changed() -> void:
	equip_bonus = MetaProgress.total_equipment_bonuses()
	awakening_branch = MetaProgress.awakening_branch
	_refresh_character_stats(true)
	_refresh_metal_load()


func _refresh_character_stats(keep_ratio: bool) -> void:
	stats.set_context(brand_quality, equip_bonus, MetaProgress.learned_stat_dict())
	var ratio := 1.0
	if keep_ratio and max_hp > 0.0:
		ratio = hp / max_hp
	max_hp = stats.max_hp
	hp = clampf(max_hp * ratio, 1.0, max_hp) if keep_ratio else max_hp
	hp_changed.emit(hp, max_hp)
	stats_changed.emit()


func set_nearby_interactable(node: Node) -> void:
	if node == null:
		return
	if not nearby_interactables.has(node):
		nearby_interactables.append(node)
	_refresh_nearby_focus()


func clear_nearby_interactable(node: Node) -> void:
	nearby_interactables.erase(node)
	_refresh_nearby_focus()


func _refresh_nearby_focus() -> void:
	var focused = nearby_interactable
	var valid: Array = []
	for n in nearby_interactables:
		if is_instance_valid(n) and n.has_method("can_interact") and n.can_interact(self):
			valid.append(n)
	nearby_interactables = valid
	nearby_interactables.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	if nearby_interactables.is_empty():
		_set_focus_node(null)
		_nearby_focus = 0
		_emit_prompt_if_changed("")
		return
	var idx := nearby_interactables.find(focused)
	if idx >= 0:
		_nearby_focus = idx
	else:
		_nearby_focus = clampi(_nearby_focus, 0, nearby_interactables.size() - 1)
	_set_focus_node(nearby_interactables[_nearby_focus])
	_emit_prompt_if_changed(_current_interact_prompt())


func _emit_prompt_if_changed(text: String) -> void:
	if text == _last_prompt:
		return
	_last_prompt = text
	interact_prompt_changed.emit(text)


func _cycle_nearby(delta: int) -> void:
	_refresh_nearby_focus()
	if nearby_interactables.size() <= 1:
		return
	_nearby_focus = (_nearby_focus + delta) % nearby_interactables.size()
	if _nearby_focus < 0:
		_nearby_focus += nearby_interactables.size()
	_set_focus_node(nearby_interactables[_nearby_focus])


func _set_focus_node(node: Node) -> void:
	if nearby_interactable != null and is_instance_valid(nearby_interactable) and nearby_interactable.has_method("set_focus_highlight"):
		nearby_interactable.set_focus_highlight(false)
	nearby_interactable = node
	if nearby_interactable != null and nearby_interactable.has_method("set_focus_highlight"):
		nearby_interactable.set_focus_highlight(true)


func _try_interact() -> void:
	_refresh_nearby_focus()
	if nearby_interactable != null and is_instance_valid(nearby_interactable):
		if nearby_interactable.has_method("interact"):
			nearby_interactable.interact(self)
			AudioManager.sfx_interact()


func get_interact_prompt() -> String:
	_refresh_nearby_focus()
	return _current_interact_prompt()


func _current_interact_prompt() -> String:
	if nearby_interactable == null or not is_instance_valid(nearby_interactable):
		return ""
	if not nearby_interactable.has_method("can_interact") or not nearby_interactable.can_interact(self):
		return ""
	var base := ""
	if nearby_interactable.has_method("get_prompt"):
		base = nearby_interactable.get_prompt()
	if nearby_interactables.size() > 1:
		return Loc.t("hud.interact_multi", [base, _nearby_focus + 1, nearby_interactables.size()])
	return base
