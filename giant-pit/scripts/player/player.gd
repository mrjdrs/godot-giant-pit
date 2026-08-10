extends CharacterBody2D
## 俯视探索者：WASD 走位，左键朝鼠标普攻，右键/QERFC 指向技能。无跳跃、无闪避。

const HitstopUtil = preload("res://scripts/combat/hitstop.gd")
const InventoryScript = preload("res://scripts/player/inventory.gd")
const CharacterStatsScript = preload("res://scripts/player/character_stats.gd")
const SkillBookScript = preload("res://scripts/player/skill_book.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const ProjectileSceneScript = preload("res://scripts/combat/player_projectile.gd")
const BladeArcFxScript = preload("res://scripts/combat/blade_arc_fx.gd")

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
const VISUAL_SCALE := 0.7
const LIGHT_COMBO_MAX := 3
const EASE_IN := 0
const EASE_OUT := 1
const EASE_SMOOTH := 2
## 三段大刀：横斩 → 回撩 → 重劈。判定贴合刀芒扇面（朝向对齐，不跟刀身自旋）。
const LIGHT_COMBO := [
	{
		"windup": 0.11, "active": 0.13, "recovery": 0.11,
		"damage": 8.0, "knockback": 90.0, "poise": 8.0,
		"hit_size": Vector2(28, 20), "hit_offset": Vector2(15, 0),
		"swing_from": -78.0, "swing_to": 62.0, "lunge": 8.0,
		"trail_color": Color(0.96, 0.90, 0.70, 1.0), "trail_width": 5.5,
		"flash_color": Color(1.0, 0.96, 0.78, 0.42), "flash_radius": 28.0,
	},
	{
		"windup": 0.08, "active": 0.12, "recovery": 0.11,
		"damage": 10.0, "knockback": 105.0, "poise": 10.0,
		"hit_size": Vector2(26, 22), "hit_offset": Vector2(14, 0),
		"swing_from": 70.0, "swing_to": -88.0, "lunge": 5.0,
		"trail_color": Color(0.78, 0.93, 1.0, 1.0), "trail_width": 6.0,
		"flash_color": Color(0.85, 0.96, 1.0, 0.46), "flash_radius": 28.0,
	},
	{
		"windup": 0.16, "active": 0.15, "recovery": 0.26,
		"damage": 15.0, "knockback": 150.0, "poise": 14.0,
		"hit_size": Vector2(32, 22), "hit_offset": Vector2(17, 0),
		"swing_from": -118.0, "swing_to": 84.0, "lunge": 12.0,
		"trail_color": Color(1.0, 0.78, 0.36, 1.0), "trail_width": 7.5,
		"flash_color": Color(1.0, 0.84, 0.42, 0.55), "flash_radius": 32.0,
		"impact": true,
	},
]
const BLADE_ART_OFFSET_DEG := 90.0
const DASH_SPEED := 420.0
const DASH_DURATION := 0.16
const MIND_REGEN_DELAY := 3.0
const MIND_REGEN_BASE := 2.0
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
var _swing_from: float = 0.0
var _swing_to: float = 0.0
var _swing_dur: float = 0.0
var _swing_elapsed: float = 0.0
var _swing_ease: int = EASE_SMOOTH
var _blade_fx: Node2D = null
var _ghost_cd: float = 0.0
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
var _out_combat_t: float = 0.0
var _mind_regen_acc: float = 0.0

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
	_apply_visual_scale()
	_setup_blade_fx()
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


func _apply_visual_scale() -> void:
	var s := Vector2(VISUAL_SCALE, VISUAL_SCALE)
	if sprite:
		sprite.scale = s
	if blade_sprite:
		blade_sprite.scale = s
		blade_sprite.position = Vector2(10, 0)


func _setup_blade_fx() -> void:
	if _blade_fx != null or blade_pivot == null:
		return
	_blade_fx = Node2D.new()
	_blade_fx.set_script(BladeArcFxScript)
	_blade_fx.name = "BladeArcFx"
	blade_pivot.add_child(_blade_fx)
	blade_sprite.z_index = 10


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
	_tick_mind_regen(delta)

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


func _tick_mind_regen(delta: float) -> void:
	var in_combat := state == State.ATTACK_LIGHT or state == State.ATTACK_SKILL or state == State.DASH or _hurt_flash > 0.0
	if in_combat:
		_out_combat_t = 0.0
		_mind_regen_acc = 0.0
		return
	_out_combat_t += delta
	if _out_combat_t < MIND_REGEN_DELAY:
		return
	if MetaProgress.mind_value >= MetaProgress.mind_value_max():
		return
	var rate: float = MIND_REGEN_BASE + float(stats.spirit) * 0.15
	_mind_regen_acc += rate * delta
	var pts := int(_mind_regen_acc)
	if pts <= 0:
		return
	_mind_regen_acc -= float(pts)
	MetaProgress.restore_mind_value(pts, false)
	GameBus.pub("mind_changed", {"current": MetaProgress.mind_value, "max": MetaProgress.mind_value_max()})


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
			if _attack_phase in [AttackPhase.LIGHT_WINDUP, AttackPhase.LIGHT_ACTIVE, AttackPhase.LIGHT_RECOVERY]:
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
	var lunge_spd := 0.0
	if not _combo_def.is_empty():
		var lunge := float(_combo_def.get("lunge", 0.0))
		if _attack_phase == AttackPhase.LIGHT_WINDUP:
			lunge_spd = lunge * 0.28
		elif _attack_phase == AttackPhase.LIGHT_ACTIVE:
			var active_dur := maxf(float(_combo_def.get("active", 0.12)) / _attack_spd, 0.001)
			var u := 1.0 - clampf(_attack_timer / active_dur, 0.0, 1.0)
			lunge_spd = lunge * (1.0 - u * 0.72)
		elif _attack_phase == AttackPhase.SKILL_ACTIVE:
			lunge_spd = 18.0
	velocity = facing * lunge_spd + input_dir * _move_speed() * 0.18
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


func set_camera_limits(left: float, top: float, right: float, bottom: float) -> void:
	if not has_node("Camera2D"):
		return
	var cam: Camera2D = $Camera2D
	cam.limit_enabled = true
	cam.limit_left = int(left)
	cam.limit_top = int(top)
	cam.limit_right = int(right)
	cam.limit_bottom = int(bottom)
	cam.limit_smoothed = false


func _update_visuals() -> void:
	blade_pivot.rotation = facing.angle()
	sprite.flip_h = facing.x < 0.0
	if state != State.ATTACK_LIGHT and state != State.ATTACK_SKILL:
		if absf(blade_swing_deg) > 0.6:
			blade_swing_deg = lerpf(blade_swing_deg, 0.0, 0.28)
		else:
			blade_swing_deg = 0.0
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 0.28)
		sprite.scale = sprite.scale.lerp(Vector2(VISUAL_SCALE, VISUAL_SCALE), 0.28)
		hitbox.rotation = 0.0
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
	if state == State.ATTACK_LIGHT and _attack_phase == AttackPhase.LIGHT_ACTIVE:
		var u := 1.0
		if _swing_dur > 0.001:
			u = clampf(_swing_elapsed / _swing_dur, 0.0, 1.0)
		var glow := 1.0 + 0.48 * sin(u * PI)
		blade_sprite.modulate = Color(glow, glow * 0.94, 0.72 + 0.28 * glow, 1.0)
	elif state == State.ATTACK_SKILL and _attack_phase == AttackPhase.SKILL_ACTIVE:
		blade_sprite.modulate = Color(1.28, 1.12, 0.82, 1.0)
	else:
		blade_sprite.modulate = Color.WHITE
	_apply_attack_pose()


func _apply_attack_pose() -> void:
	if state != State.ATTACK_LIGHT and state != State.ATTACK_SKILL:
		return
	var squash := 0.0
	var rot_k := 0.11
	if _attack_phase == AttackPhase.LIGHT_WINDUP or _attack_phase == AttackPhase.SKILL_WINDUP:
		squash = -0.07
		rot_k = 0.07
	elif _attack_phase == AttackPhase.LIGHT_ACTIVE:
		squash = 0.09 if combo_step < 3 else 0.14
		rot_k = 0.14
	elif _attack_phase == AttackPhase.SKILL_ACTIVE:
		squash = 0.10
		rot_k = 0.12
	var target_rot := deg_to_rad(blade_swing_deg * rot_k)
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, 0.42)
	sprite.scale = sprite.scale.lerp(
		Vector2(VISUAL_SCALE * (1.0 + squash), VISUAL_SCALE * (1.0 - squash * 0.55)),
		0.38
	)


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
	_begin_blade_swing(blade_swing_deg, float(_combo_def["swing_from"]), windup, EASE_OUT)
	_apply_blade_visual()
	_attack_phase = AttackPhase.LIGHT_WINDUP
	_attack_timer = windup


func _try_cast_slot(slot: String) -> void:
	if is_skill_slot_locked(slot):
		show_toast(Loc.t("skill.slot_locked"), 2)
		return
	var core_id := skill_in_slot(slot)
	if core_id == "":
		if slot == "rmb":
			show_toast(Loc.t("skill.slot_empty"), 2)
		return
	if float(_skill_cd.get(slot, 0.0)) > 0.0:
		return
	if not _try_spend_cast_mind(core_id):
		return
	_cast_skill(slot, core_id)


func _try_spend_cast_mind(core_id: String) -> bool:
	var cost := CrystalCatalog.cast_cost(core_id)
	if cost <= 0:
		return true
	if not MetaProgress.can_afford_mind(cost):
		show_toast(Loc.t("toast.no_mind"), 2)
		return false
	MetaProgress.consume_mind_value(cost, false)
	GameBus.pub("mind_changed", {"current": MetaProgress.mind_value, "max": MetaProgress.mind_value_max()})
	GameBus.pub("skill_cast", {"skill_id": core_id, "loud": CrystalCatalog.is_loud(core_id)})
	_out_combat_t = 0.0
	return true


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
	_begin_blade_swing(blade_swing_deg, -62.0, windup, EASE_OUT)
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


func _begin_blade_swing(from_deg: float, to_deg: float, duration: float, ease_kind: int) -> void:
	_swing_from = from_deg
	_swing_to = to_deg
	_swing_dur = maxf(duration, 0.001)
	_swing_elapsed = 0.0
	_swing_ease = ease_kind
	blade_swing_deg = from_deg


func _ease_t(t: float, kind: int) -> float:
	var x := clampf(t, 0.0, 1.0)
	match kind:
		EASE_IN:
			return x * x * x
		EASE_OUT:
			return 1.0 - pow(1.0 - x, 3.0)
		_:
			return x * x * (3.0 - 2.0 * x)


func _update_blade_swing(delta: float) -> void:
	if _swing_dur <= 0.0:
		return
	_swing_elapsed = minf(_swing_elapsed + delta, _swing_dur)
	var t := _ease_t(_swing_elapsed / _swing_dur, _swing_ease)
	blade_swing_deg = lerpf(_swing_from, _swing_to, t)
	_apply_blade_visual()
	if _attack_phase == AttackPhase.LIGHT_ACTIVE:
		## 朝向对齐，覆盖刀芒扇面；不跟刀身自旋，避免画面砍到却判空。
		hitbox.rotation = 0.0
		_sample_blade_trail(delta)
	elif _attack_phase == AttackPhase.SKILL_ACTIVE:
		hitbox.rotation = deg_to_rad(blade_swing_deg)
		_sample_blade_trail(delta)
	else:
		hitbox.rotation = lerpf(hitbox.rotation, 0.0, 0.35)


func _sample_blade_trail(delta: float) -> void:
	if _blade_fx == null:
		return
	var tip_g: Vector2 = blade_sprite.to_global(Vector2(0.0, -20.0))
	if _blade_fx.has_method("push_tip_local"):
		_blade_fx.push_tip_local(_blade_fx.to_local(tip_g))
	_ghost_cd -= delta
	if _ghost_cd > 0.0:
		return
	_ghost_cd = 0.028
	if _blade_fx.has_method("spawn_ghost"):
		_blade_fx.spawn_ghost(
			blade_sprite.texture,
			blade_sprite.position,
			blade_sprite.rotation,
			Color(1.0, 0.95, 0.82, 0.38)
		)


func _start_light_slash_fx() -> void:
	if _blade_fx == null or not _blade_fx.has_method("begin_slash"):
		return
	var trail_col: Color = _combo_def.get("trail_color", Color(0.95, 0.9, 0.72, 1.0))
	var flash_col: Color = _combo_def.get("flash_color", Color(1.0, 0.95, 0.78, 0.42))
	var width := float(_combo_def.get("trail_width", 10.0))
	var radius := float(_combo_def.get("flash_radius", 46.0)) * _attack_reach
	_blade_fx.begin_slash(
		trail_col,
		width,
		float(_combo_def["swing_from"]),
		float(_combo_def["swing_to"]),
		radius,
		flash_col
	)
	_ghost_cd = 0.0


func _tick_attack(delta: float) -> void:
	if _attack_phase == AttackPhase.NONE:
		return
	_update_blade_swing(delta)
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	match _attack_phase:
		AttackPhase.LIGHT_WINDUP:
			var dmg: float = float(_combo_def["damage"]) * _light_damage_mult() * (stats.patk / CharacterStatsScript.BASE_PATK)
			var kb: float = float(_combo_def["knockback"])
			var poise: float = float(_combo_def.get("poise", kb * 0.08))
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			var active_dur: float = float(_combo_def["active"]) / _attack_spd
			_begin_blade_swing(float(_combo_def["swing_from"]), float(_combo_def["swing_to"]), active_dur, EASE_IN)
			_start_light_slash_fx()
			_attack_phase = AttackPhase.LIGHT_ACTIVE
			_attack_timer = active_dur
			AudioManager.sfx_weapon_attack(weapon_family)
			if bool(_combo_def.get("impact", false)):
				_camera_shake = maxf(_camera_shake, 0.10)
		AttackPhase.LIGHT_ACTIVE:
			hitbox.disable()
			hitbox.rotation = 0.0
			if _blade_fx and _blade_fx.has_method("end_slash"):
				_blade_fx.end_slash()
			var rec: float = float(_combo_def.get("recovery", 0.16)) / _attack_spd
			_begin_blade_swing(blade_swing_deg, blade_swing_deg * 0.72, rec, EASE_OUT)
			_attack_phase = AttackPhase.LIGHT_RECOVERY
			_attack_timer = rec
		AttackPhase.LIGHT_RECOVERY:
			if _light_buffered and combo_step < LIGHT_COMBO_MAX:
				_light_buffered = false
				combo_window = 0.38
				_start_light_attack()
			else:
				_finish_attack_to_idle()
				combo_window = 0.18 if combo_step >= LIGHT_COMBO_MAX else 0.34
				if combo_step >= LIGHT_COMBO_MAX:
					combo_step = 0
		AttackPhase.SKILL_WINDUP:
			_fire_pending_skill()
			_begin_blade_swing(blade_swing_deg, 70.0, 0.12, EASE_IN)
			_attack_phase = AttackPhase.SKILL_ACTIVE
			_attack_timer = 0.12
		AttackPhase.SKILL_ACTIVE:
			hitbox.disable()
			hitbox.rotation = 0.0
			if _blade_fx and _blade_fx.has_method("end_slash"):
				_blade_fx.end_slash()
			_begin_blade_swing(blade_swing_deg, 0.0, 0.18, EASE_OUT)
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
	if _blade_fx and _blade_fx.has_method("begin_slash"):
		_blade_fx.begin_slash(
			Color(1.0, 0.86, 0.45, 1.0), 12.0, blade_swing_deg, 70.0, 50.0,
			Color(1.0, 0.88, 0.5, 0.4)
		)
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
	_light_buffered = false
	_pending_skill = ""
	_pending_skill_slot = ""
	_attack_phase = AttackPhase.NONE
	_attack_timer = 0.0
	_swing_dur = 0.0
	hitbox.rotation = 0.0
	if _blade_fx and _blade_fx.has_method("end_slash"):
		_blade_fx.end_slash()
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
	_out_combat_t = 0.0
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
	_swing_dur = 0.0
	state = State.IDLE
	velocity = Vector2.ZERO
	hitbox.disable()
	if _blade_fx and _blade_fx.has_method("end_slash"):
		_blade_fx.end_slash()
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


func try_add_core(core_id: String, count: int = 1, grade: int = -1, quality: int = -1) -> String:
	return inventory.add_core(core_id, count, carry_cap(), grade, quality)


func try_add_item(item_id: String, count: int = 1) -> String:
	var r := inventory.add_item(item_id, count, carry_cap())
	if r == "full":
		show_toast(Loc.t("bag.full"), 2)
	elif r == "overweight":
		show_toast(Loc.t("bag.overweight"), 2)
	return r


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
