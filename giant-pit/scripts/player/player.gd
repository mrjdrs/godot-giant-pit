extends CharacterBody2D
## 俯视探索者：WASD 走位，左键朝鼠标普攻，右键/QERFC 指向技能。无跳跃、无闪避。

const HitstopUtil = preload("res://scripts/combat/hitstop.gd")
const InventoryScript = preload("res://scripts/player/inventory.gd")
const CharacterStatsScript = preload("res://scripts/player/character_stats.gd")
const SkillBookScript = preload("res://scripts/player/skill_book.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
const ProjectileSceneScript = preload("res://scripts/combat/player_projectile.gd")
const BladeArcFxScript = preload("res://scripts/combat/blade_arc_fx.gd")
const ShockwaveFxScript = preload("res://scripts/combat/skill_fx/shockwave_fx.gd")
const WhirlRingFxScript = preload("res://scripts/combat/skill_fx/whirl_ring_fx.gd")
const GroundCrackFxScript = preload("res://scripts/combat/skill_fx/ground_crack_fx.gd")
const DrawSlashFxScript = preload("res://scripts/combat/skill_fx/draw_slash_fx.gd")
const HitboxScript = preload("res://scripts/combat/hitbox.gd")
const MuzzleFlashFxScript = preload("res://scripts/combat/skill_fx/muzzle_flash_fx.gd")
const CastFlareFxScript = preload("res://scripts/combat/skill_fx/cast_flare_fx.gd")
const FlameArcFxScript = preload("res://scripts/combat/skill_fx/flame_arc_fx.gd")
const GunBlastFxScript = preload("res://scripts/combat/skill_fx/gun_blast_fx.gd")
const FlameBurstFxScript = preload("res://scripts/combat/skill_fx/flame_burst_fx.gd")
const ElementBurstFxScript = preload("res://scripts/combat/skill_fx/element_burst_fx.gd")
const GroundZoneFxScript = preload("res://scripts/combat/skill_fx/ground_zone_fx.gd")
const MageBeamFxScript = preload("res://scripts/combat/skill_fx/mage_beam_fx.gd")
const OrbitOrbsFxScript = preload("res://scripts/combat/skill_fx/orbit_orbs_fx.gd")
const IceWallFxScript = preload("res://scripts/combat/skill_fx/ice_wall_fx.gd")
const DarkVortexFxScript = preload("res://scripts/combat/skill_fx/dark_vortex_fx.gd")
const RuneCastFxScript = preload("res://scripts/combat/skill_fx/rune_cast_fx.gd")
const StatusEffects = preload("res://scripts/combat/status_effects.gd")

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
const VISUAL_SCALE := 0.48
const VISUAL_FLAT := 0.85
const IMPRINT_4DIR_FRAME := Vector2i(64, 88)
const IMPRINT_4DIR_STRIDE := 66
const IMPRINT_FOOT_OFFSET := Vector2(0, -32)
const WEAPON_4DIR := {
	"blade": "res://assets/characters/imprint/weapon/blade_4dir.png",
	"bow": "res://assets/characters/imprint/weapon/bow_4dir.png",
	"element": "res://assets/characters/imprint/weapon/element_4dir.png",
	"focus": "res://assets/characters/imprint/weapon/focus_4dir.png",
	"axe": "res://assets/characters/imprint/weapon/blade_4dir.png",
	"sword": "res://assets/characters/imprint/weapon/blade_4dir.png",
	"hammer": "res://assets/characters/imprint/weapon/blade_4dir.png",
	"crossbow": "res://assets/characters/imprint/weapon/bow_4dir.png",
	"spear": "res://assets/characters/imprint/weapon/bow_4dir.png",
}
const CompanionScene := preload("res://scenes/combat/affinity_companion.tscn")
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
var _pose_recoil: float = 0.0
var _hp_regen_acc: float = 0.0
var _companion: Node2D = null
var _companion_cd: float = 0.0
var held_weapon: String = "blade"
var _ghost_cd: float = 0.0
var _pending_skill: String = ""
var _pending_skill_slot: String = ""
var _skill_cd: Dictionary = {}
var _skill_combat: Dictionary = {}
var _skill_fx_def: Dictionary = {}
var _skill_ticks_total: int = 1
var _skill_tick_index: int = 0
var _skill_invuln_t: float = 0.0
var _skill_jump: float = 0.0
var _skill_hide_blade: bool = false
var _skill_windup_dur: float = 0.16
var _dash_hit_active: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _dash_speed: float = DASH_SPEED
var _mage_light_shots_pending: int = 0
var _mage_light_shot_dir: Vector2 = Vector2.RIGHT
var _mage_dome_t: float = 0.0

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
var statuses = StatusEffects.new()

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
var _tex_4dir: Texture2D
var _view_dirs_4: Array[Vector2] = [
	Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0),
]


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
	_apply_imprint_visual()
	_apply_blade_visual()
	_sync_affinity_companion()
	if has_node("Camera2D"):
		_camera_origin = $Camera2D.offset
	inventory.changed.connect(func(): inventory_changed.emit())
	skills.changed.connect(_on_skills_changed)
	MetaProgress.changed.connect(_on_meta_changed)
	awakening_branch = MetaProgress.awakening_branch
	_refresh_character_stats(false)
	_refresh_metal_load()
	hp_changed.emit(hp, max_hp)


func _body_scale(extra_x: float = 0.0, extra_y: float = 0.0) -> Vector2:
	return Vector2(
		VISUAL_SCALE * (1.0 + extra_x),
		VISUAL_SCALE * VISUAL_FLAT * (1.0 + extra_y)
	)


func _apply_visual_scale() -> void:
	var s := _body_scale()
	if sprite:
		sprite.scale = s
	if blade_sprite:
		blade_sprite.visible = false
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
	_sync_held_weapon()
	_tex_4dir = _load_imprint_4dir()
	if _tex_4dir == null and ResourceLoader.exists("res://assets/characters/player/player_explorer.png"):
		_tex_explorer = load("res://assets/characters/player/player_explorer.png")
	_tex_idle = load("res://assets/characters/player/side/player_idle.png")
	_tex_run = load("res://assets/characters/player/side/player_run.png")
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_apply_pose_texture()


func _load_imprint_4dir() -> Texture2D:
	var weapon := held_weapon if held_weapon != "" else SkillCatalog.default_held_weapon(MetaProgress.imprint_family)
	var path := str(WEAPON_4DIR.get(weapon, WEAPON_4DIR.get("blade", "")))
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func _facing_view_index() -> int:
	var dir := facing
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	if absf(dir.x) >= absf(dir.y):
		return 1 if dir.x >= 0.0 else 3
	return 0 if dir.y >= 0.0 else 2


func _apply_4dir_frame() -> void:
	if _tex_4dir == null:
		return
	var idx := _facing_view_index()
	var fw := float(IMPRINT_4DIR_FRAME.x)
	var fh := float(IMPRINT_4DIR_FRAME.y)
	var stride := float(IMPRINT_4DIR_STRIDE)
	sprite.texture = _tex_4dir
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.region_enabled = true
	sprite.region_rect = Rect2(idx * stride, 0.0, fw, fh)
	sprite.flip_h = false
	sprite.centered = true
	sprite.offset = IMPRINT_FOOT_OFFSET


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
	_tick_player_statuses(delta)
	_tick_attack(delta)
	_tick_mind_regen(delta)
	_tick_hp_regen(delta)
	_tick_companion(delta)
	if _skill_invuln_t > 0.0:
		_skill_invuln_t -= delta
		if _skill_invuln_t <= 0.0 and state != State.DASH:
			invincible = false

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
	var focus_r := MetaProgress.skill_rank("mgf_focus")
	if focus_r > 0:
		rate *= 1.0 + float(SkillCatalog.passive("mgf_focus").get("mind_regen", 0.15)) * float(focus_r)
	_mind_regen_acc += rate * delta
	var pts := int(_mind_regen_acc)
	if pts <= 0:
		return
	_mind_regen_acc -= float(pts)
	MetaProgress.restore_mind_value(pts, false)
	GameBus.pub("mind_changed", {"current": MetaProgress.mind_value, "max": MetaProgress.mind_value_max()})


func _tick_hp_regen(delta: float) -> void:
	var rate := float(stats.hp_regen)
	if rate <= 0.0 or hp >= max_hp:
		_hp_regen_acc = 0.0
		return
	_hp_regen_acc += rate * delta
	if _hp_regen_acc < 1.0:
		return
	var heal := _hp_regen_acc
	_hp_regen_acc = 0.0
	hp = minf(hp + heal, max_hp)
	hp_changed.emit(hp, max_hp)


func _tick_companion(delta: float) -> void:
	if not _is_affinity_imprint():
		if _companion != null and is_instance_valid(_companion):
			_companion.queue_free()
			_companion = null
		return
	if _companion != null and is_instance_valid(_companion):
		return
	_companion_cd = maxf(_companion_cd - delta, 0.0)
	if _companion_cd <= 0.0:
		_spawn_affinity_companion()


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
		elif _attack_phase == AttackPhase.SKILL_WINDUP:
			lunge_spd = float(_skill_combat.get("lunge", 0.0)) * 0.22
		elif _attack_phase == AttackPhase.SKILL_ACTIVE:
			lunge_spd = float(_skill_combat.get("lunge", 18.0))
	velocity = facing * lunge_spd + input_dir * _move_speed() * 0.18 * _brace_move_factor()
	facing = attack_locked_facing


func _brace_move_factor() -> float:
	var r := MetaProgress.skill_rank("hw_brace")
	if r <= 0 or state != State.ATTACK_SKILL:
		return 1.0
	var cut := float(SkillCatalog.passive("hw_brace").get("move_cut", 0.35))
	return maxf(1.0 - cut, 0.35)


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_dir * _dash_speed
	if _dash_timer <= 0.0:
		if _dash_hit_active:
			hitbox.disable()
			_dash_hit_active = false
			if _blade_fx and _blade_fx.has_method("end_slash"):
				_blade_fx.end_slash()
		if _skill_invuln_t <= 0.0:
			invincible = false
		_skill_combat = {}
		state = State.IDLE
		velocity = Vector2.ZERO


func _move_speed() -> float:
	var s := BASE_MOVE_SPEED * move_speed_mult * float(stats.move_mult)
	if in_mud:
		s *= 0.55
	s *= 1.0 + 0.03 * float(MetaProgress.winch_level)
	return s


func _light_damage_mult() -> float:
	var m := 1.0 * _damage_mult()
	for pid in ["sk_chain", "hw_caliber", "mgf_ember", "mgi_frostmark", "mga_stain", "mgd_shadowbite", "mgl_grace", "nat_grove"]:
		var r := MetaProgress.skill_rank(pid)
		if r <= 0:
			continue
		var p: Dictionary = SkillCatalog.passive(pid)
		if p.has("light_dmg"):
			m += float(p.get("light_dmg", 0.06)) + float(p.get("light_dmg_per", 0.04)) * float(maxi(r - 1, 0))
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_COLD or MetaProgress.imprint_family == "cold_blade":
		if combo_step >= 2:
			m += 0.05
		if combo_step >= 3:
			m += 0.08
	return m


func _is_mage_imprint() -> bool:
	return SkillCatalog.is_mage_imprint(MetaProgress.imprint_family)


func _is_affinity_imprint() -> bool:
	return SkillCatalog.is_affinity_imprint(MetaProgress.imprint_family)


func _is_caster_imprint() -> bool:
	return _is_mage_imprint() or _is_affinity_imprint()


func _attack_stat_mult() -> float:
	if _is_caster_imprint():
		return float(stats.matk) / CharacterStatsScript.BASE_MATK
	return float(stats.patk) / CharacterStatsScript.BASE_PATK


func _mage_hit_spark_style() -> String:
	return "mage_%s" % _mage_element()


func _style_uses_cast_anim() -> bool:
	return _is_caster_imprint()


func _begin_cast_anim(windup: float) -> void:
	_begin_blade_swing(-14.0, 24.0, maxf(windup * 0.55, 0.04), EASE_OUT)
	_pose_recoil = 0.08


func _mage_element() -> String:
	if MetaProgress.mage_element in SkillCatalog.MAGE_ELEMENTS:
		return MetaProgress.mage_element
	return "fire"


func _mage_innate_passive_id() -> String:
	match _mage_element():
		"ice":
			return "mgi_frostmark"
		"acid":
			return "mga_stain"
		"dark":
			return "mgd_shadowbite"
		"light":
			return "mgl_grace"
		_:
			return "mgf_ember"


func _mage_element_fx() -> Dictionary:
	match _mage_element():
		"ice":
			return {
				"trail": Color(0.55, 0.85, 1.0, 1.0),
				"flash": Color(0.75, 0.95, 1.0, 0.75),
				"spark": Color(0.7, 0.95, 1.0, 1.0),
			}
		"acid":
			return {
				"trail": Color(0.55, 0.92, 0.22, 1.0),
				"flash": Color(0.7, 1.0, 0.3, 0.65),
				"spark": Color(0.65, 1.0, 0.25, 1.0),
			}
		"dark":
			return {
				"trail": Color(0.45, 0.18, 0.72, 1.0),
				"flash": Color(0.35, 0.12, 0.55, 0.7),
				"spark": Color(0.5, 0.2, 0.85, 1.0),
			}
		"light":
			return {
				"trail": Color(1.0, 0.92, 0.55, 1.0),
				"flash": Color(1.0, 0.96, 0.7, 0.65),
				"spark": Color(1.0, 0.95, 0.65, 1.0),
			}
		_:
			return {
				"trail": Color(1.0, 0.42, 0.18, 1.0),
				"flash": Color(0.75, 0.4, 1.0, 0.75),
				"spark": Color(1.0, 0.45, 0.2, 1.0),
			}


func on_hit_apply_status(host, _hitbox) -> void:
	if host == self:
		return
	var payload := _status_payload_from_combat(_skill_combat)
	if payload.is_empty():
		payload = _innate_status_payload()
	if payload.is_empty():
		return
	if host.has_method("apply_status"):
		host.apply_status(payload["kind"], payload.get("data", {}))


func _innate_status_payload() -> Dictionary:
	if not _is_mage_imprint():
		return {}
	var pid := _mage_innate_passive_id()
	var r := MetaProgress.skill_rank(pid)
	if r <= 0:
		return {}
	var p: Dictionary = SkillCatalog.passive(pid)
	match _mage_element():
		"ice":
			return {
				"kind": StatusEffects.KIND_CHILL,
				"data": {
					"slow": float(p.get("chill_slow", 0.22)) + float(p.get("chill_slow_per", 0.04)) * float(maxi(r - 1, 0)),
					"duration": float(p.get("chill_time", 2.4)),
					"stacks": 1,
				},
			}
		"acid":
			return {
				"kind": StatusEffects.KIND_CORRODE,
				"data": {
					"amp": float(p.get("corrode_amp", 0.12)) + float(p.get("corrode_amp_per", 0.03)) * float(maxi(r - 1, 0)),
					"duration": float(p.get("corrode_time", 3.5)),
					"pdef_cut": float(p.get("pdef_cut", 2.0)) + float(p.get("pdef_cut_per", 0.8)) * float(maxi(r - 1, 0)),
				},
			}
		"dark":
			return {
				"kind": StatusEffects.KIND_WEAKEN,
				"data": {
					"cut": float(p.get("weaken_cut", 0.12)) + float(p.get("weaken_cut_per", 0.03)) * float(maxi(r - 1, 0)),
					"duration": float(p.get("weaken_time", 3.5)),
				},
			}
		"light":
			return {}
		_:
			return {
				"kind": StatusEffects.KIND_BURN,
				"data": {
					"dps": float(p.get("burn_dps", 2.0)) + float(p.get("burn_dps_per", 1.0)) * float(maxi(r - 1, 0)),
					"duration": float(p.get("burn_time", 2.2)),
				},
			}


func _status_payload_from_combat(combat: Dictionary) -> Dictionary:
	if combat.is_empty():
		return {}
	var status := str(combat.get("status", ""))
	if status == "" and combat.has("burn_dps"):
		status = "burn"
	match status:
		"burn":
			return {
				"kind": StatusEffects.KIND_BURN,
				"data": {
					"dps": float(combat.get("burn_dps", 4.0)),
					"duration": float(combat.get("burn_time", 2.5)),
				},
			}
		"chill":
			return {
				"kind": StatusEffects.KIND_CHILL,
				"data": {
					"slow": float(combat.get("chill_slow", 0.25)),
					"duration": float(combat.get("chill_time", 2.5)),
					"stacks": int(combat.get("chill_stacks", 1)),
				},
			}
		"corrode":
			return {
				"kind": StatusEffects.KIND_CORRODE,
				"data": {
					"amp": float(combat.get("corrode_amp", 0.15)),
					"duration": float(combat.get("corrode_time", 3.5)),
					"pdef_cut": float(combat.get("pdef_cut", 0.0)),
				},
			}
		"weaken":
			return {
				"kind": StatusEffects.KIND_WEAKEN,
				"data": {
					"cut": float(combat.get("weaken_cut", 0.15)),
					"duration": float(combat.get("weaken_time", 3.5)),
				},
			}
		"bless":
			return {}
		_:
			return {}


func _attach_status_meta(obj: Object, combat: Dictionary = {}) -> void:
	var payload := _status_payload_from_combat(combat)
	if payload.is_empty():
		payload = _innate_status_payload()
	if payload.is_empty():
		return
	obj.set_meta("status_kind", payload["kind"])
	obj.set_meta("status_payload", payload.get("data", {}))


func _apply_self_bless(combat: Dictionary) -> void:
	if combat.is_empty():
		return
	var heal := float(combat.get("bless_heal", 0.0))
	if heal > 0.0:
		hp = minf(hp + heal, max_hp)
		hp_changed.emit(hp, max_hp)
	statuses.apply(StatusEffects.KIND_BLESS, {
		"shield": float(combat.get("bless_shield", 0.0)),
		"hps": float(combat.get("bless_hps", 0.0)),
		"duration": float(combat.get("bless_time", 3.0)),
	})


func _tick_player_statuses(delta: float) -> void:
	var st: Dictionary = statuses.tick(delta)
	if float(st.get("heal", 0.0)) > 0.0:
		hp = minf(hp + float(st["heal"]), max_hp)
		hp_changed.emit(hp, max_hp)


func _skill_atk_spd() -> float:
	var bonus := 0.0
	var stance_r := MetaProgress.skill_rank("sk_stance")
	if stance_r > 0:
		bonus += float(SkillCatalog.passive("sk_stance").get("atk_spd", 0.03)) * float(stance_r)
	var reload_r := MetaProgress.skill_rank("hw_reload")
	if reload_r > 0:
		bonus += float(SkillCatalog.passive("hw_reload").get("atk_spd", 0.03)) * float(reload_r)
	return 1.0 + bonus


func _skill_cd_factor() -> float:
	var cut := 0.0
	var reload_r := MetaProgress.skill_rank("hw_reload")
	if reload_r > 0:
		cut += float(SkillCatalog.passive("hw_reload").get("cd_cut", 0.02)) * float(reload_r)
	return maxf(1.0 - cut, 0.7)


func _passive_dr() -> float:
	var dr := float(stats.imprint_dr)
	for pid in ["sk_ironwall", "hw_brace", "mgf_ward"]:
		var r := MetaProgress.skill_rank(pid)
		if r > 0:
			dr += float(SkillCatalog.passive(pid).get("dr", 0.04)) * float(r)
	return clampf(dr, 0.0, 0.6)


func _brace_skill_dmg() -> float:
	var r := MetaProgress.skill_rank("hw_brace")
	if r <= 0:
		return 1.0
	return 1.0 + float(SkillCatalog.passive("hw_brace").get("skill_dmg", 0.03)) * float(r)


func has_burn() -> bool:
	return _is_mage_imprint() and _mage_element() == "fire" and burn_dps() > 0.0


func burn_dps() -> float:
	var r := MetaProgress.skill_rank("mgf_ember")
	if r <= 0:
		return 0.0
	var p: Dictionary = SkillCatalog.passive("mgf_ember")
	return float(p.get("burn_dps", 2.0)) + float(p.get("burn_dps_per", 1.0)) * float(maxi(r - 1, 0))


func burn_time() -> float:
	var r := MetaProgress.skill_rank("mgf_ember")
	if r <= 0:
		return 0.0
	return float(SkillCatalog.passive("mgf_ember").get("burn_time", 2.2))


func _damage_mult() -> float:
	var m := 1.0
	if awakening_branch == "whirl":
		m *= 1.05
	return m


func _brand_stats() -> Dictionary:
	const MindTable = preload("res://scripts/meta/mind_table.gd")
	return MindTable.BRAND_STATS.get(brand_quality, MindTable.BRAND_STATS["iron"])


func apply_meta_brand(p_brand: String = "iron") -> void:
	brand_quality = p_brand
	equip_bonus = MetaProgress.total_equipment_bonuses()
	awakening_branch = MetaProgress.awakening_branch
	_apply_imprint_visual()
	_refresh_character_stats(false)
	_refresh_metal_load()
	_sync_affinity_companion()


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
	var rank := MetaProgress.skill_rank(core_id)
	var max_cd := 0.0
	if SkillCatalog.has_id(core_id):
		max_cd = SkillCatalog.cooldown(core_id, rank) * skill_cd_mult
	else:
		max_cd = CrystalCatalog.cooldown(core_id) * skill_cd_mult
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
	if _tex_4dir == null:
		sprite.flip_h = facing.x < 0.0
	if state != State.ATTACK_LIGHT and state != State.ATTACK_SKILL:
		if absf(blade_swing_deg) > 0.6:
			blade_swing_deg = lerpf(blade_swing_deg, 0.0, 0.28)
		else:
			blade_swing_deg = 0.0
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 0.28)
		sprite.scale = sprite.scale.lerp(_body_scale(), 0.28)
		sprite.position.x = lerpf(sprite.position.x, 0.0, 0.28)
		sprite.position.y = lerpf(sprite.position.y, 0.0, 0.28)
		_pose_recoil = maxf(_pose_recoil - 0.15, 0.0)
		hitbox.rotation = 0.0
	_apply_blade_visual()
	_apply_pose_texture()


func _apply_pose_texture() -> void:
	if _tex_4dir:
		_apply_4dir_frame()
		return
	var tex: Texture2D = _tex_explorer if _tex_explorer else _tex_idle
	if state == State.MOVE and _tex_run and _tex_explorer == null:
		tex = _tex_run
	if tex:
		sprite.region_enabled = false
		if sprite.texture != tex:
			sprite.texture = tex


func _apply_blade_visual() -> void:
	if blade_sprite:
		blade_sprite.visible = false
	_apply_attack_pose()


func _apply_attack_pose() -> void:
	if state != State.ATTACK_LIGHT and state != State.ATTACK_SKILL:
		_pose_recoil = maxf(_pose_recoil - 0.2, 0.0)
		return
	var squash := 0.0
	var rot_k := 0.11
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		if _attack_phase == AttackPhase.LIGHT_WINDUP or _attack_phase == AttackPhase.SKILL_WINDUP:
			squash = -0.04
			rot_k = 0.02
		elif _attack_phase == AttackPhase.LIGHT_ACTIVE or _attack_phase == AttackPhase.SKILL_ACTIVE:
			squash = 0.08
			rot_k = -0.08
			_pose_recoil = 1.0
		## 火铳后坐：身体略向后仰
		sprite.rotation = lerp_angle(sprite.rotation, -attack_locked_facing.x * 0.12 * _pose_recoil, 0.35)
		sprite.scale = sprite.scale.lerp(_body_scale(squash, -squash * 0.4), 0.4)
		sprite.position.x = lerpf(sprite.position.x, -attack_locked_facing.x * 3.0 * _pose_recoil, 0.35)
		sprite.position.y = lerpf(sprite.position.y, 0.0, 0.4)
		return
	if _is_mage_imprint():
		if _attack_phase == AttackPhase.LIGHT_WINDUP or _attack_phase == AttackPhase.SKILL_WINDUP:
			squash = -0.06
			rot_k = 0.04
		elif _attack_phase == AttackPhase.LIGHT_ACTIVE or _attack_phase == AttackPhase.SKILL_ACTIVE:
			squash = 0.06
			rot_k = 0.1
		sprite.rotation = lerp_angle(sprite.rotation, deg_to_rad(blade_swing_deg * rot_k) * 0.5, 0.4)
		sprite.scale = sprite.scale.lerp(_body_scale(squash * 0.6, squash * 0.35), 0.38)
		if _skill_jump > 0.0 and state == State.ATTACK_SKILL and _attack_phase == AttackPhase.SKILL_WINDUP and _skill_windup_dur > 0.001:
			var u := 1.0 - clampf(_attack_timer / _skill_windup_dur, 0.0, 1.0)
			sprite.position.y = -_skill_jump * sin(u * PI * 0.85)
		else:
			sprite.position.y = lerpf(sprite.position.y, -2.0 if _attack_phase == AttackPhase.SKILL_ACTIVE else 0.0, 0.35)
		sprite.position.x = lerpf(sprite.position.x, 0.0, 0.3)
		return
	if _attack_phase == AttackPhase.LIGHT_WINDUP or _attack_phase == AttackPhase.SKILL_WINDUP:
		squash = -0.07
		rot_k = 0.07
	elif _attack_phase == AttackPhase.LIGHT_ACTIVE:
		squash = 0.09 if combo_step < 3 else 0.14
		rot_k = 0.14
	elif _attack_phase == AttackPhase.SKILL_ACTIVE:
		squash = 0.12
		rot_k = 0.14
	var target_rot := deg_to_rad(blade_swing_deg * rot_k)
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, 0.42)
	sprite.scale = sprite.scale.lerp(_body_scale(squash, -squash * 0.55), 0.38)
	if _skill_jump > 0.0 and state == State.ATTACK_SKILL:
		if _attack_phase == AttackPhase.SKILL_WINDUP and _skill_windup_dur > 0.001:
			var u2 := 1.0 - clampf(_attack_timer / _skill_windup_dur, 0.0, 1.0)
			sprite.position.y = -_skill_jump * sin(u2 * PI * 0.85)
		elif _attack_phase == AttackPhase.SKILL_ACTIVE:
			sprite.position.y = lerpf(sprite.position.y, 0.0, 0.55)
		else:
			sprite.position.y = lerpf(sprite.position.y, 0.0, 0.4)
	elif absf(sprite.position.y) > 0.2:
		sprite.position.y = lerpf(sprite.position.y, 0.0, 0.35)
	sprite.position.x = lerpf(sprite.position.x, 0.0, 0.35)


func _face_mouse() -> void:
	var mouse := get_global_mouse_position()
	var dir := mouse - global_position
	if dir.length_squared() > 4.0:
		facing = dir.normalized()


func _start_light_attack(_lock_facing: Vector2 = Vector2.ZERO) -> void:
	_face_mouse()
	attack_locked_facing = facing
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT or _is_caster_imprint():
		_start_ranged_light()
		return
	state = State.ATTACK_LIGHT
	_light_buffered = false
	if combo_window > 0.0 and combo_step > 0 and combo_step < LIGHT_COMBO_MAX:
		combo_step += 1
	else:
		combo_step = 1
	combo_window = 0.0
	_combo_def = LIGHT_COMBO[clampi(combo_step - 1, 0, LIGHT_COMBO.size() - 1)]
	_attack_spd = _skill_atk_spd()
	_attack_reach = float(_brand_stats().get("reach", 1.0))
	var windup: float = float(_combo_def["windup"]) / _attack_spd
	if combo_step == 2 and MetaProgress.skill_rank("sk_chain") > 0:
		windup *= float(SkillCatalog.passive("sk_chain").get("combo2_windup", 0.9))
	var hit_size: Vector2 = _combo_def["hit_size"] * _attack_reach
	var hit_off: Vector2 = _combo_def["hit_offset"] * _attack_reach
	_set_hitbox_size(hit_size, hit_off)
	_begin_blade_swing(blade_swing_deg, float(_combo_def["swing_from"]), windup, EASE_OUT)
	_apply_blade_visual()
	_attack_phase = AttackPhase.LIGHT_WINDUP
	_attack_timer = windup


func _start_ranged_light() -> void:
	state = State.ATTACK_LIGHT
	_light_buffered = false
	combo_step = 1
	combo_window = 0.0
	_combo_def = {"windup": 0.08, "active": 0.06, "recovery": 0.18, "lunge": 0.0, "damage": 8.0, "knockback": 70.0, "poise": 6.0, "hit_size": Vector2(8, 8), "hit_offset": Vector2(0, 0), "swing_from": -6.0, "swing_to": 10.0}
	_attack_spd = _skill_atk_spd()
	_attack_phase = AttackPhase.LIGHT_WINDUP
	_attack_timer = float(_combo_def["windup"]) / _attack_spd
	if _is_mage_imprint():
		var elem_fx := _mage_element_fx()
		_skill_fx_def = {
			"trail_color": elem_fx["trail"],
			"flash_color": elem_fx["flash"],
		}
		_begin_cast_anim(_attack_timer)
	elif _is_affinity_imprint():
		_skill_fx_def = {
			"trail_color": Color(0.55, 0.92, 0.42, 1.0),
			"flash_color": Color(0.72, 1.0, 0.58, 0.62),
		}
		_begin_cast_anim(_attack_timer)
	else:
		_skill_fx_def = {
			"trail_color": Color(0.55, 0.9, 0.95, 1.0),
			"flash_color": Color(1.0, 0.85, 0.4, 0.7),
		}
		_begin_blade_swing(blade_swing_deg, 8.0, _attack_timer, EASE_OUT)
	hitbox.disable()
	_apply_blade_visual()


func _fire_ranged_light_shot() -> void:
	var dir := attack_locked_facing
	var stat_m := _attack_stat_mult()
	var dmg := 8.0 * _light_damage_mult() * stat_m
	var speed := 340.0
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		var cr := MetaProgress.skill_rank("hw_caliber")
		if cr > 0:
			speed *= 1.0 + float(SkillCatalog.passive("hw_caliber").get("proj_speed_pct", 0.04)) * float(cr)
		_begin_blade_swing(blade_swing_deg, -12.0, 0.06, EASE_IN)
	elif _is_mage_imprint():
		_fire_mage_ranged_light(dir, dmg, speed)
		return
	elif _is_affinity_imprint():
		_begin_cast_anim(0.06)
		_spawn_bolt(dir, _roll_attack_damage(dmg), 1, 300.0, {"spawn_zone": true, "zone_radius": 16.0, "zone_dur": 1.8})
		_play_imprint_cast_fx("", dir)
		AudioManager.sfx_weapon_attack(weapon_family)
		return
	else:
		_begin_blade_swing(blade_swing_deg, 16.0, 0.06, EASE_IN)
	_spawn_bolt(dir, _roll_attack_damage(dmg), 1, speed, {})
	_play_imprint_cast_fx("", dir)
	AudioManager.sfx_weapon_attack(weapon_family)


func _fire_mage_ranged_light(dir: Vector2, dmg: float, speed: float) -> void:
	_begin_cast_anim(0.06)
	match _mage_element():
		"ice":
			var fan := deg_to_rad(22.0)
			for i in 3:
				var ang := -fan * 0.5 + fan * float(i) / 2.0
				_spawn_bolt(dir.rotated(ang), _roll_attack_damage(dmg * 0.75), 1, 260.0, {})
			_play_imprint_cast_fx("", dir)
			AudioManager.sfx_weapon_attack(weapon_family)
		"acid":
			_spawn_bolt(dir, _roll_attack_damage(dmg), 1, 240.0, {"spawn_zone": true, "zone_radius": 20.0, "zone_dur": 2.0})
			_play_imprint_cast_fx("", dir)
			AudioManager.sfx_weapon_attack(weapon_family)
		"dark":
			_spawn_bolt(dir, _roll_attack_damage(dmg), 2, speed, {})
			_play_imprint_cast_fx("", dir)
			AudioManager.sfx_weapon_attack(weapon_family)
		"light":
			var light_dmg := dmg * 0.85
			_spawn_bolt(dir, _roll_attack_damage(light_dmg), 1, 420.0, {})
			_apply_self_bless({"bless_hps": 1.0, "bless_shield": 4.0, "bless_time": 2.0})
			_play_imprint_cast_fx("", dir)
			AudioManager.sfx_weapon_attack(weapon_family)
		_:
			_spawn_bolt(dir, _roll_attack_damage(dmg), 1, speed, {})
			_play_imprint_cast_fx("", dir)
			AudioManager.sfx_weapon_attack(weapon_family)


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
	var rank := MetaProgress.skill_rank(core_id)
	var cost := SkillCatalog.cast_cost(core_id, rank) if SkillCatalog.has_id(core_id) else CrystalCatalog.cast_cost(core_id)
	var focus_r := MetaProgress.skill_rank("mgf_focus")
	if focus_r > 0 and cost > 0:
		var cut := float(SkillCatalog.passive("mgf_focus").get("mind_cut", 0.04)) * float(focus_r)
		cost = maxi(int(round(float(cost) * (1.0 - cut))), 1)
	if cost <= 0:
		return true
	if not MetaProgress.can_afford_mind(cost):
		show_toast(Loc.t("toast.no_mind"), 2)
		return false
	MetaProgress.consume_mind_value(cost, false)
	GameBus.pub("mind_changed", {"current": MetaProgress.mind_value, "max": MetaProgress.mind_value_max()})
	var loud := SkillCatalog.is_loud(core_id, rank) if SkillCatalog.has_id(core_id) else CrystalCatalog.is_loud(core_id)
	GameBus.pub("skill_cast", {"skill_id": core_id, "loud": loud})
	_out_combat_t = 0.0
	return true


func _cast_skill(slot: String, core_id: String) -> void:
	_face_mouse()
	attack_locked_facing = facing
	_pending_skill = core_id
	_pending_skill_slot = slot
	var rank := maxi(MetaProgress.skill_rank(core_id), 1)
	_skill_combat = SkillCatalog.combat(core_id, rank) if SkillCatalog.has_id(core_id) else {}
	_skill_fx_def = SkillCatalog.fx(core_id, rank) if SkillCatalog.has_id(core_id) else {}
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		_skill_fx_def["trail_color"] = Color(0.55, 0.9, 0.95, 1.0)
		_skill_fx_def["flash_color"] = Color(1.0, 0.82, 0.4, 0.75)
		_skill_fx_def["dust"] = false
	elif _is_mage_imprint():
		var elem_fx := _mage_element_fx()
		if not _skill_fx_def.has("trail_color"):
			_skill_fx_def["trail_color"] = elem_fx["trail"]
		if not _skill_fx_def.has("flash_color"):
			_skill_fx_def["flash_color"] = elem_fx["flash"]
		_skill_fx_def["dust"] = false
	_skill_ticks_total = int(_skill_combat.get("ticks", 1))
	_skill_tick_index = 0
	_skill_hide_blade = bool(_skill_combat.get("hide_blade", false))
	_skill_jump = float(_skill_combat.get("jump", 0.0))
	_attack_reach = float(_brand_stats().get("reach", 1.0))
	if (str(_skill_combat.get("style", "")) in ["dash_slash", "dash_shot", "mage_blink"]
			or _pending_skill.ends_with("_blink") or _pending_skill.ends_with("step") or _pending_skill.ends_with("flash")):
		_start_dash_slash()
		var cd := (SkillCatalog.cooldown(core_id, rank) if SkillCatalog.has_id(core_id) else CrystalCatalog.cooldown(core_id))
		_skill_cd[slot] = cd * skill_cd_mult * _skill_cd_factor()
		if SkillCatalog.has_id(core_id) and SkillCatalog.is_loud(core_id, rank):
			loud_skill_used.emit(core_id)
		return
	state = State.ATTACK_SKILL
	var windup := float(_skill_combat.get("windup", 0.18))
	_skill_windup_dur = windup
	var swing_from := float(_skill_combat.get("swing_from", -62.0))
	if not _is_blade_imprint():
		if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
			swing_from = float(_skill_combat.get("swing_from", 10.0)) * 0.2
			_skill_hide_blade = true
		elif _style_uses_cast_anim():
			_begin_cast_anim(windup)
			swing_from = -14.0
			_skill_hide_blade = true
		else:
			swing_from = float(_skill_combat.get("swing_from", -28.0)) * 0.45
			_skill_hide_blade = true
	if not _style_uses_cast_anim() or MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		_begin_blade_swing(blade_swing_deg, swing_from, windup, EASE_OUT)
	_attack_phase = AttackPhase.SKILL_WINDUP
	_attack_timer = windup
	if (SkillCatalog.has_id(core_id) and SkillCatalog.is_loud(core_id, rank)) or CrystalCatalog.is_loud(core_id):
		loud_skill_used.emit(core_id)


func _start_dash() -> void:
	_face_mouse()
	_dash_dir = facing
	_dash_timer = DASH_DURATION
	_dash_speed = DASH_SPEED
	_dash_hit_active = false
	state = State.DASH
	hitbox.disable()
	AudioManager.sfx_roll()


func _start_dash_slash() -> void:
	_face_mouse()
	_dash_dir = facing
	attack_locked_facing = facing
	_dash_timer = float(_skill_combat.get("dash_duration", DASH_DURATION))
	_dash_speed = float(_skill_combat.get("dash_speed", DASH_SPEED))
	state = State.DASH
	var style := str(_skill_combat.get("style", "dash_slash"))
	var patk_m: float = _attack_stat_mult()
	var dmg := float(_skill_combat.get("damage", 10.0)) * _damage_mult() * _brace_skill_dmg() * patk_m
	if style == "dash_shot":
		_dash_hit_active = false
		hitbox.disable()
		invincible = true
		_skill_invuln_t = maxf(_skill_invuln_t, float(_skill_combat.get("invuln", 0.12)))
		_spawn_bolt(_dash_dir, _roll_attack_damage(dmg), int(_skill_combat.get("pierce", 1)), float(_skill_combat.get("proj_speed", 380.0)))
		_play_imprint_cast_fx(style, _dash_dir)
	elif style == "mage_blink":
		_dash_hit_active = false
		hitbox.disable()
		invincible = true
		var dist := float(_skill_combat.get("lunge", 88.0))
		_play_imprint_cast_fx(style, _dash_dir)
		global_position += _dash_dir * dist
		_dash_timer = 0.08
		_dash_speed = 0.0
		var inv := float(_skill_combat.get("invuln", 0.12))
		_skill_invuln_t = maxf(_skill_invuln_t, inv)
		var rad := float(_skill_combat.get("wave_radius", 36.0))
		if bool(_skill_combat.get("self_cast", false)):
			_apply_self_bless(_skill_combat)
		else:
			_spawn_element_cast_fx(global_position, rad)
			_spawn_element_burst(global_position, rad)
			if bool(_skill_combat.get("spawn_zone", false)):
				_spawn_ground_zone(global_position, rad, float(_skill_combat.get("zone_dur", 3.0)))
			_aoe_damage_at(global_position, rad, dmg, float(_skill_combat.get("knockback", 80.0)), float(_skill_combat.get("poise", 6.0)))
	else:
		_dash_hit_active = true
		var hit_size: Vector2 = _skill_combat.get("hit_size", Vector2(42, 22)) * _attack_reach
		var hit_off: Vector2 = _skill_combat.get("hit_offset", Vector2(18, 0)) * _attack_reach
		_set_hitbox_size(hit_size, hit_off)
		hitbox.enable(
			_roll_attack_damage(dmg),
			float(_skill_combat.get("knockback", 110.0)),
			self,
			float(_skill_combat.get("poise", 8.0))
		)
		_attach_status_meta(hitbox, _skill_combat)
		_start_skill_slash_fx()
	AudioManager.sfx_roll()
	AudioManager.sfx_weapon_attack(weapon_family)
	_camera_shake = maxf(_camera_shake, float(_skill_fx_def.get("camera_shake", 0.04)))


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
		hitbox.rotation = 0.0
		if _is_blade_imprint():
			_sample_blade_trail(delta)
	elif _attack_phase == AttackPhase.SKILL_ACTIVE:
		if _is_blade_imprint():
			hitbox.rotation = deg_to_rad(blade_swing_deg)
			_sample_blade_trail(delta)
		else:
			hitbox.rotation = 0.0
	else:
		hitbox.rotation = lerpf(hitbox.rotation, 0.0, 0.35)


func _sample_blade_trail(delta: float) -> void:
	if _blade_fx == null or not _is_blade_imprint():
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
			var active_dur: float = float(_combo_def["active"]) / _attack_spd
			if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT or _is_caster_imprint():
				_fire_ranged_light_shot()
				_attack_phase = AttackPhase.LIGHT_ACTIVE
				_attack_timer = active_dur
			else:
				var dmg: float = float(_combo_def["damage"]) * _light_damage_mult() * _attack_stat_mult()
				var kb: float = float(_combo_def["knockback"])
				var poise: float = float(_combo_def.get("poise", kb * 0.08))
				hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
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
			_fire_skill_tick()
			var active_dur := float(_skill_combat.get("active", 0.12))
			var pair := _tick_swing_pair()
			_begin_blade_swing(pair.x, pair.y, active_dur, EASE_IN)
			_skill_tick_index += 1
			_attack_phase = AttackPhase.SKILL_ACTIVE
			_attack_timer = active_dur
			var invuln := float(_skill_combat.get("invuln", 0.0))
			if invuln > 0.0:
				invincible = true
				_skill_invuln_t = invuln
		AttackPhase.SKILL_ACTIVE:
			hitbox.disable()
			hitbox.rotation = 0.0
			if _skill_tick_index < _skill_ticks_total:
				_fire_skill_tick()
				var next_dur := float(_skill_combat.get("active", 0.12))
				var pair2 := _tick_swing_pair()
				_begin_blade_swing(pair2.x, pair2.y, next_dur, EASE_IN)
				_skill_tick_index += 1
				_attack_timer = next_dur
			else:
				if _blade_fx and _blade_fx.has_method("end_slash"):
					_blade_fx.end_slash()
				if float(_skill_combat.get("invuln", 0.0)) > 0.0:
					invincible = false
					_skill_invuln_t = 0.0
				var rec := float(_skill_combat.get("recovery", 0.18))
				_begin_blade_swing(blade_swing_deg, 0.0, rec, EASE_OUT)
				_attack_phase = AttackPhase.SKILL_RECOVERY
				_attack_timer = rec
		AttackPhase.SKILL_RECOVERY:
			_finish_attack_to_idle()
		_:
			_attack_phase = AttackPhase.NONE


func _tick_swing_pair() -> Vector2:
	var swings = _skill_combat.get("swings", [])
	if typeof(swings) == TYPE_ARRAY and _skill_tick_index < swings.size():
		var s: Dictionary = swings[_skill_tick_index]
		var pair := Vector2(float(s.get("from", -70.0)), float(s.get("to", 70.0)))
		return _family_swing_scale(pair)
	return _family_swing_scale(Vector2(
		float(_skill_combat.get("swing_from", -62.0)),
		float(_skill_combat.get("swing_to", 70.0))
	))


func _family_swing_scale(pair: Vector2) -> Vector2:
	if _is_blade_imprint():
		return pair
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		return Vector2(clampf(pair.x * 0.15, -14.0, 14.0), clampf(pair.y * 0.12, -18.0, 18.0))
	if _style_uses_cast_anim():
		return Vector2(-14.0, 20.0)
	return Vector2(pair.x * 0.4, pair.y * 0.4)


func _fire_pending_skill() -> void:
	_fire_skill_tick()


func _fire_skill_tick() -> void:
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
	var stat_m: float = _attack_stat_mult()
	var style := str(_skill_combat.get("style", ""))
	var dmg := float(_skill_combat.get("damage", 16.0)) * _damage_mult() * _brace_skill_dmg() * stat_m
	if awakening_branch == "whirl" and style in ["smash_wave", "whirl", "ground_slam", "draw_slash", "gun_artillery", "mage_meteor", "mage_cataclysm", "gun_overclock"]:
		dmg *= 1.1
	var kb := float(_skill_combat.get("knockback", 160.0))
	var poise := float(_skill_combat.get("poise", 12.0))
	match style:
		"bolt", "gun_pierce", "mage_bolt":
			_spawn_bolt(dir, dmg, int(_skill_combat.get("pierce", 1)), float(_skill_combat.get("proj_speed", 320.0)))
		"gun_burst":
			_spawn_bolt(dir, dmg, int(_skill_combat.get("pierce", 1)), float(_skill_combat.get("proj_speed", 400.0)))
		"gun_overclock":
			var fan := deg_to_rad(float(_skill_combat.get("fan_deg", 48.0)))
			var n := maxi(_skill_ticks_total, 3)
			var t := 0.0 if n <= 1 else float(_skill_tick_index) / float(n - 1)
			var ang := -fan * 0.5 + fan * t
			_spawn_bolt(dir.rotated(ang), dmg, 1, float(_skill_combat.get("proj_speed", 360.0)))
		"gun_grenade", "gun_artillery", "mage_meteor":
			var reach := float(_skill_combat.get("range", 140.0))
			var target := global_position + dir * minf(global_position.distance_to(mouse), reach)
			if style == "gun_grenade" or style == "mage_meteor" or style == "gun_artillery":
				_schedule_aoe(target, float(_skill_combat.get("wave_radius", 60.0)), dmg, kb, poise, float(_skill_combat.get("fuse", 0.25)), style == "gun_artillery" or style == "mage_meteor")
				if style == "mage_meteor":
					_spawn_cast_flare(target, 20.0)
				elif style == "gun_grenade":
					_spawn_muzzle_flash(dir)
		"gun_mine":
			_schedule_aoe(global_position, float(_skill_combat.get("wave_radius", 60.0)), dmg, kb, poise, float(_skill_combat.get("fuse", 0.85)), true)
		"mage_nova":
			_set_hitbox_size(Vector2(float(_skill_combat.get("wave_radius", 56.0)) * 2.0, float(_skill_combat.get("wave_radius", 56.0)) * 2.0), Vector2.ZERO)
			if not bool(_skill_combat.get("self_cast", false)):
				hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			else:
				_apply_self_bless(_skill_combat)
			_spawn_element_burst(global_position, float(_skill_combat.get("wave_radius", 56.0)))
			_spawn_element_cast_fx(global_position, float(_skill_combat.get("wave_radius", 56.0)) * 0.45)
		"mage_beam":
			var beam_len := float(_skill_combat.get("beam_len", 110.0))
			_set_hitbox_size(Vector2(beam_len, 16.0), Vector2(beam_len * 0.5, 0.0))
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_attach_status_meta(hitbox, _skill_combat)
			_spawn_mage_beam(dir, beam_len)
		"mage_orbit":
			_skill_ticks_total = int(_skill_combat.get("ticks", 4))
			var orbit_r := float(_skill_combat.get("orbit_radius", 52.0))
			if _skill_tick_index == 0:
				_spawn_orbit_orbs(orbit_r)
			_set_hitbox_size(Vector2(orbit_r * 2.2, orbit_r * 2.2), Vector2.ZERO)
			hitbox.enable(_roll_attack_damage(dmg * 0.65), kb * 0.6, self, poise * 0.7)
			_attach_status_meta(hitbox, _skill_combat)
		"mage_rain":
			var reach_r := float(_skill_combat.get("range", 130.0))
			var target_r := global_position + dir * minf(global_position.distance_to(mouse), reach_r)
			var count := int(_skill_combat.get("rain_count", 5))
			for i in count:
				var offset := Vector2(randf_range(-reach_r * 0.35, reach_r * 0.35), randf_range(-reach_r * 0.25, reach_r * 0.25))
				var landing := target_r + offset
				var delay := 0.08 * float(i)
				_schedule_rain_drop(landing, delay, dmg * 0.7, kb * 0.5, poise * 0.6)
			if bool(_skill_combat.get("self_cast", false)):
				_apply_self_bless(_skill_combat)
		"mage_field":
			var reach_f := float(_skill_combat.get("range", 120.0))
			var target_f := global_position + dir * minf(global_position.distance_to(mouse), reach_f)
			var field_r := float(_skill_combat.get("wave_radius", 64.0))
			var field_d := float(_skill_combat.get("field_dur", 3.5))
			_spawn_ground_zone(target_f, field_r, field_d)
			_schedule_field_ticks(target_f, field_r, field_d, dmg, kb, poise)
			if bool(_skill_combat.get("self_cast", false)):
				_apply_self_bless(_skill_combat)
		"mage_wall":
			var wall_len := float(_skill_combat.get("wall_len", 72.0))
			var wall_pos := global_position + dir * 36.0
			_spawn_ice_wall(wall_pos, dir, wall_len)
			_set_hitbox_size(Vector2(wall_len, 18.0), dir * wall_len * 0.5)
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_attach_status_meta(hitbox, _skill_combat)
		"mage_vortex":
			var reach_v := float(_skill_combat.get("range", 120.0))
			var target_v := global_position + dir * minf(global_position.distance_to(mouse), reach_v)
			var vr := float(_skill_combat.get("wave_radius", 56.0))
			var vd := float(_skill_combat.get("field_dur", 1.5))
			_spawn_dark_vortex(target_v, vr, vd)
			_schedule_field_ticks(target_v, vr, vd, dmg * 0.55, kb * 0.4, poise * 0.5)
		"mage_cloud":
			var cloud_r := float(_skill_combat.get("wave_radius", 64.0))
			var cloud_d := float(_skill_combat.get("field_dur", 3.0))
			var cloud_target := global_position + dir * 40.0
			_spawn_ground_zone(cloud_target, cloud_r, cloud_d)
			_schedule_field_ticks(cloud_target, cloud_r, cloud_d, dmg * 0.5, kb * 0.35, poise * 0.45)
		"mage_chain":
			var chain_n := int(_skill_combat.get("chain_count", 3))
			var chain_dir := dir
			for i in chain_n:
				_spawn_bolt(chain_dir, dmg * (1.0 - float(i) * 0.12), 1, float(_skill_combat.get("proj_speed", 340.0)), _skill_combat)
				chain_dir = chain_dir.rotated(deg_to_rad(28.0))
		"mage_pulse":
			_set_hitbox_size(Vector2(float(_skill_combat.get("wave_radius", 64.0)) * 2.0, float(_skill_combat.get("wave_radius", 64.0)) * 2.0), Vector2.ZERO)
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_attach_status_meta(hitbox, _skill_combat)
			_spawn_element_burst(global_position, float(_skill_combat.get("wave_radius", 64.0)))
		"mage_shatter", "mage_drain", "mage_purge":
			var shatter_r := float(_skill_combat.get("wave_radius", 48.0))
			var bonus := _conditional_mage_bonus(dmg, style)
			_aoe_damage_at(global_position + dir * 24.0, shatter_r, bonus, kb, poise)
			_spawn_element_burst(global_position + dir * 24.0, shatter_r)
			if style == "mage_drain":
				_pending_lifesteal += bonus * float(_skill_combat.get("lifesteal", 0.25))
		"mage_dome":
			_mage_dome_t = float(_skill_combat.get("field_dur", 3.0))
			_apply_self_bless(_skill_combat)
			_spawn_element_cast_fx(global_position, float(_skill_combat.get("wave_radius", 40.0)))
		"mage_ring", "mage_cataclysm":
			_set_hitbox_size(
				_skill_combat.get("hit_size", Vector2(74, 74)),
				_skill_combat.get("hit_offset", Vector2.ZERO)
			)
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			if _skill_tick_index == 0:
				_spawn_orbit_orbs(float(_skill_combat.get("range", 60.0)))
				_spawn_element_cast_fx(global_position, 24.0)
		"mage_lash", "mage_cascade":
			var beam_len2 := float(_skill_combat.get("beam_len", 100.0))
			_set_hitbox_size(Vector2(beam_len2, 16.0), Vector2(beam_len2 * 0.5, 0.0))
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_attach_status_meta(hitbox, _skill_combat)
			_spawn_mage_beam(dir, beam_len2)
		"mage_ward":
			if bool(_skill_combat.get("self_cast", false)):
				_apply_self_bless(_skill_combat)
				_spawn_cast_flare(global_position, float(_skill_combat.get("wave_radius", 48.0)))
			else:
				_set_hitbox_size(
					_skill_combat.get("hit_size", Vector2(48, 48)),
					_skill_combat.get("hit_offset", Vector2.ZERO)
				)
				hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
				_attach_status_meta(hitbox, _skill_combat)
		"gun_rail":
			var slash_len := float(_skill_combat.get("slash_len", 200.0))
			_set_hitbox_size(Vector2(slash_len, 18.0), Vector2(slash_len * 0.5, 0.0))
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_spawn_gun_beam(dir, slash_len)
		"ground_slam":
			var reach2 := float(_skill_combat.get("range", 140.0))
			var target2 := global_position + dir * minf(global_position.distance_to(mouse), reach2)
			_set_hitbox_size(
				_skill_combat.get("hit_size", Vector2(64, 64)),
				blade_pivot.to_local(target2)
			)
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_spawn_ground_crack(target2, float(_skill_combat.get("wave_radius", 70.0)))
			_spawn_shockwave(target2, float(_skill_combat.get("wave_radius", 70.0)))
		"smash_wave":
			_set_hitbox_size(
				_skill_combat.get("hit_size", Vector2(52, 36)) * _attack_reach,
				_skill_combat.get("hit_offset", Vector2(32, 0)) * _attack_reach
			)
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_spawn_shockwave(global_position + dir * 30.0, float(_skill_combat.get("wave_radius", 48.0)))
		"whirl":
			_set_hitbox_size(
				_skill_combat.get("hit_size", Vector2(70, 70)),
				_skill_combat.get("hit_offset", Vector2.ZERO)
			)
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			if _skill_tick_index == 0:
				_spawn_whirl_ring(float(_skill_combat.get("range", 56.0)))
		"draw_slash":
			var slash_len2 := float(_skill_combat.get("slash_len", 150.0))
			_set_hitbox_size(Vector2(slash_len2, 28.0), Vector2(slash_len2 * 0.5, 0.0))
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
			_spawn_draw_slash(dir, slash_len2)
		_:
			_set_hitbox_size(
				_skill_combat.get("hit_size", Vector2(48, 28)) * _attack_reach,
				_skill_combat.get("hit_offset", Vector2(22, 0)) * _attack_reach
			)
			hitbox.enable(_roll_attack_damage(dmg), kb, self, poise)
	if _style_uses_blade_slash(style):
		_start_skill_slash_fx()
	else:
		_play_imprint_cast_fx(style, dir)
	_apply_blade_visual()
	AudioManager.sfx_weapon_attack(weapon_family)
	_camera_shake = maxf(_camera_shake, float(_skill_fx_def.get("camera_shake", 0.08)))
	if style == "myriad" or style == "mage_cascade":
		HitstopUtil.freeze(get_tree(), float(_skill_fx_def.get("hitstop", 0.08)))
	if slot != "" and _skill_tick_index == 0:
		var rank := maxi(MetaProgress.skill_rank(core_id), 1)
		var cd := SkillCatalog.cooldown(core_id, rank) if SkillCatalog.has_id(core_id) else CrystalCatalog.cooldown(core_id)
		_skill_cd[slot] = cd * skill_cd_mult * _skill_cd_factor()


func _schedule_aoe(pos: Vector2, radius: float, dmg: float, knock: float, poise: float, fuse: float, crack: bool) -> void:
	var tree := get_tree()
	if tree == null:
		_aoe_damage_at(pos, radius, dmg, knock, poise)
		_spawn_family_blast(pos, radius)
		return
	## 落地预警：枪=灰烟小圈，咒=符文点
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		_spawn_muzzle_flash((pos - global_position).normalized() if pos.distance_squared_to(global_position) > 4.0 else facing)
	elif _is_mage_imprint():
		if _mage_element() == "fire":
			_spawn_rune_cast(pos, 12.0)
		else:
			_spawn_cast_flare(pos, radius * 0.35)
	tree.create_timer(maxf(fuse, 0.01)).timeout.connect(func():
		if not is_instance_valid(self):
			return
		_aoe_damage_at(pos, radius, dmg, knock, poise)
		_spawn_family_blast(pos, radius)
		if crack:
			_spawn_ground_crack(pos, radius)
	)


func _spawn_family_blast(pos: Vector2, radius: float) -> void:
	var col: Color = _skill_fx_def.get("flash_color", Color(1.0, 0.55, 0.25, 0.8))
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		var fx := _spawn_world_fx(GunBlastFxScript)
		if fx.has_method("setup"):
			fx.setup(pos, radius, col, 0.4)
	elif _is_mage_imprint():
		var fx2 := _spawn_world_fx(ElementBurstFxScript)
		if fx2.has_method("setup"):
			var elem := str(_skill_combat.get("element", _mage_element()))
			fx2.setup(pos, radius, elem, col, 0.4)
	else:
		_spawn_shockwave(pos, radius)


func _aoe_damage_at(pos: Vector2, radius: float, dmg: float, knock: float, poise: float) -> void:
	var space := get_world_2d().direct_space_state
	if space == null:
		return
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	q.shape = circle
	q.transform = Transform2D(0.0, pos)
	q.collision_mask = 16 ## hurtboxes
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hits := space.intersect_shape(q, 32)
	var rolled := _roll_attack_damage(dmg * float(stats.aoe_mult))
	for h in hits:
		var area = h.get("collider")
		if area == null or not area.has_method("take_hit"):
			continue
		var fake := Area2D.new()
		fake.set_script(HitboxScript)
		fake.damage = rolled
		fake.knockback_force = knock
		fake.poise_damage = poise
		fake.source = self
		_attach_status_meta(fake, _skill_combat)
		area.take_hit(fake)
		fake.free()


func _start_skill_slash_fx() -> void:
	if _blade_fx == null or not _blade_fx.has_method("begin_slash"):
		return
	var pair := _tick_swing_pair()
	var trail: Color = _skill_fx_def.get("trail_color", Color(1.0, 0.86, 0.45, 1.0))
	var flash: Color = _skill_fx_def.get("flash_color", Color(1.0, 0.88, 0.5, 0.4))
	var width := float(_skill_fx_def.get("trail_width", 10.0))
	var radius := float(_skill_fx_def.get("flash_radius", 46.0)) * _attack_reach
	_blade_fx.begin_slash(trail, width, pair.x, pair.y, radius, flash)
	_ghost_cd = 0.0


func _spawn_bolt(dir: Vector2, dmg: float, pierce: int = 1, speed: float = 320.0, combat = null) -> void:
	var bolt := Area2D.new()
	bolt.set_script(ProjectileSceneScript)
	var parent_n := get_parent()
	if parent_n == null:
		parent_n = self
	parent_n.add_child(bolt)
	bolt.global_position = global_position + dir * 18.0
	var col: Color = _skill_fx_def.get("trail_color", Color(1.0, 0.92, 0.62, 1.0))
	var shape := _proj_shape_for_imprint()
	if bolt.has_method("setup"):
		bolt.setup(dir * speed, dmg * float(stats.bolt_mult), self, 90.0, pierce, col, shape)
	var payload_combat: Dictionary = _skill_combat if combat == null else combat
	_attach_status_meta(bolt, payload_combat)
	if bool(payload_combat.get("spawn_zone", false)):
		var tree := get_tree()
		if tree:
			var zone_r := float(payload_combat.get("zone_radius", 20.0))
			var zone_d := float(payload_combat.get("zone_dur", 2.0))
			var landing := bolt.global_position + dir.normalized() * 80.0
			tree.create_timer(0.55).timeout.connect(func():
				if is_instance_valid(self):
					_spawn_ground_zone(landing, zone_r, zone_d)
					_aoe_damage_at(landing, zone_r, dmg * 0.4, 40.0, 4.0)
			)


func _play_imprint_cast_fx(style: String, dir: Vector2) -> void:
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		if style in ["mage_lash", "mage_cascade", "mage_nova", "mage_ring", "mage_cataclysm", "mage_meteor", "mage_blink", "gun_rail"]:
			return
		_spawn_muzzle_flash(dir)
		if style in ["", "gun_burst", "gun_pierce", "gun_overclock", "dash_shot"]:
			var side := Vector2(-dir.y, dir.x) * 8.0
			var puff := _spawn_world_fx(GunBlastFxScript)
			if puff.has_method("setup"):
				puff.setup(global_position + side - dir * 4.0, 14.0, Color(0.75, 0.65, 0.45, 0.55), 0.18)
	elif _is_mage_imprint():
		if style in ["gun_pierce", "gun_burst", "gun_overclock", "gun_rail", "gun_grenade", "gun_mine", "gun_artillery", "dash_shot", "mage_lash", "mage_cascade"]:
			return
		if _mage_element() == "fire":
			_spawn_rune_cast(global_position + dir * 12.0, 18.0 if style != "mage_nova" else 30.0)
		if style in ["mage_nova", "mage_blink", ""]:
			_spawn_cast_flare(global_position + dir * 10.0, 14.0)
	elif _is_affinity_imprint():
		_spawn_cast_flare(global_position + dir * 10.0, 12.0)


func _spawn_muzzle_flash(dir: Vector2) -> void:
	var fx := _spawn_world_fx(MuzzleFlashFxScript)
	var col: Color = _skill_fx_def.get("flash_color", Color(1.0, 0.82, 0.35, 0.95))
	if fx.has_method("setup"):
		fx.setup(global_position + dir * 16.0, dir, col, 22.0, 0.11)


func _spawn_cast_flare(pos: Vector2, radius: float = 18.0) -> void:
	var fx := _spawn_world_fx(CastFlareFxScript)
	var col: Color = _skill_fx_def.get("flash_color", Color(1.0, 0.45, 0.18, 0.9))
	if fx.has_method("setup"):
		fx.setup(pos, col, radius, 0.2)


func _spawn_rune_cast(pos: Vector2, radius: float = 20.0) -> void:
	var fx := _spawn_world_fx(RuneCastFxScript)
	var col: Color = _skill_fx_def.get("trail_color", Color(1.0, 0.45, 0.18, 0.9))
	if fx.has_method("setup"):
		fx.setup(pos, col, radius, 0.26)


func _spawn_flame_arc(dir: Vector2) -> void:
	var fx := _spawn_world_fx(FlameArcFxScript)
	var pair := _tick_swing_pair()
	var col: Color = _skill_fx_def.get("trail_color", Color(1.0, 0.42, 0.16, 0.85))
	var radius := float(_skill_fx_def.get("flash_radius", 56.0)) * _attack_reach
	if fx.has_method("setup"):
		fx.setup(global_position, dir.angle(), pair.x, pair.y, radius, col, 0.2)


func _spawn_gun_beam(dir: Vector2, length: float) -> void:
	var fx := _spawn_world_fx(DrawSlashFxScript)
	## 贯矛：木褐锋线而非刀芒金黄
	var col := Color(0.82, 0.62, 0.32, 0.95)
	var width := float(_skill_fx_def.get("trail_width", 8.0)) * 0.45
	if fx.has_method("setup"):
		fx.setup(global_position + dir * 8.0, dir, length, col, width, 0.14)
	_spawn_muzzle_flash(dir)


func _spawn_world_fx(script: Script) -> Node2D:
	var fx := Node2D.new()
	fx.set_script(script)
	var parent_n := get_parent()
	if parent_n == null:
		parent_n = self
	parent_n.add_child(fx)
	return fx


func _spawn_element_burst(pos: Vector2, radius: float) -> void:
	var col: Color = _skill_fx_def.get("flash_color", _mage_element_fx()["flash"])
	var fx := _spawn_world_fx(ElementBurstFxScript)
	if fx.has_method("setup"):
		fx.setup(pos, radius, _mage_element(), col, 0.42)


func _spawn_element_cast_fx(pos: Vector2, radius: float) -> void:
	var col: Color = _skill_fx_def.get("flash_color", _mage_element_fx()["flash"])
	if _mage_element() == "fire":
		_spawn_rune_cast(pos, radius * 0.55)
	_spawn_cast_flare(pos, radius)


func _spawn_ground_zone(pos: Vector2, radius: float, dur: float) -> void:
	var col: Color = _skill_fx_def.get("trail_color", _mage_element_fx()["trail"])
	var fx := _spawn_world_fx(GroundZoneFxScript)
	if fx.has_method("setup"):
		fx.setup(pos, radius, _mage_element(), col, dur)


func _spawn_mage_beam(direction: Vector2, length: float) -> void:
	var col: Color = _skill_fx_def.get("trail_color", _mage_element_fx()["trail"])
	var fx := _spawn_world_fx(MageBeamFxScript)
	if fx.has_method("setup"):
		fx.setup(global_position + direction * 16.0, direction, length, col)


func _spawn_orbit_orbs(radius: float) -> void:
	var col: Color = _skill_fx_def.get("trail_color", _mage_element_fx()["trail"])
	var fx := _spawn_world_fx(OrbitOrbsFxScript)
	if fx.has_method("setup"):
		fx.setup(radius, _mage_element(), col, float(_skill_combat.get("field_dur", 2.0)))


func _spawn_ice_wall(pos: Vector2, direction: Vector2, length: float) -> void:
	var fx := _spawn_world_fx(IceWallFxScript)
	if fx.has_method("setup"):
		fx.setup(pos, direction, length, 2.0)


func _spawn_dark_vortex(pos: Vector2, radius: float, dur: float) -> void:
	var col: Color = _skill_fx_def.get("flash_color", _mage_element_fx()["flash"])
	var fx := _spawn_world_fx(DarkVortexFxScript)
	if fx.has_method("setup"):
		fx.setup(pos, radius, col, dur)


func _schedule_rain_drop(pos: Vector2, delay: float, dmg: float, knock: float, poise: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(maxf(delay, 0.01)).timeout.connect(func():
		if not is_instance_valid(self):
			return
		_spawn_element_cast_fx(pos, 14.0)
		_aoe_damage_at(pos, 22.0, dmg, knock, poise)
		if bool(_skill_combat.get("spawn_zone", true)):
			_spawn_ground_zone(pos, 18.0, float(_skill_combat.get("zone_dur", 2.5)))
	)


func _schedule_field_ticks(pos: Vector2, radius: float, dur: float, dmg: float, knock: float, poise: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var ticks := maxi(int(dur / 0.5), 1)
	for i in ticks:
		var t_delay := 0.35 + float(i) * 0.5
		tree.create_timer(t_delay).timeout.connect(func():
			if not is_instance_valid(self):
				return
			_aoe_damage_at(pos, radius, dmg, knock, poise)
			var ls := float(_skill_combat.get("lifesteal", 0.0))
			if ls > 0.0:
				_pending_lifesteal += dmg * ls
		)


func _conditional_mage_bonus(base_dmg: float, style: String) -> float:
	var bonus := base_dmg
	if _mage_element() == "ice" and style == "mage_shatter":
		bonus *= 1.5
	if _mage_element() == "acid" and style == "mage_shatter":
		bonus *= 1.35
	return bonus


func _spawn_shockwave(pos: Vector2, radius: float) -> void:
	## 刀系冲击环；枪/咒走专属爆炸，避免三系同款圆环
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT or _is_caster_imprint():
		_spawn_family_blast(pos, radius)
		return
	var fx := _spawn_world_fx(ShockwaveFxScript)
	var col: Color = _skill_fx_def.get("flash_color", Color(1.0, 0.62, 0.28, 0.7))
	if fx.has_method("setup"):
		fx.setup(pos, radius, col, 0.36, bool(_skill_fx_def.get("dust", true)))


func _spawn_whirl_ring(radius: float) -> void:
	var fx := _spawn_world_fx(WhirlRingFxScript)
	var col: Color = _skill_fx_def.get("trail_color", Color(0.42, 0.92, 0.72, 0.85))
	var dur := float(_skill_combat.get("active", 0.16)) * float(_skill_ticks_total) + 0.12
	if fx.has_method("setup"):
		fx.setup(self, radius, col, dur)


func _spawn_ground_crack(pos: Vector2, radius: float) -> void:
	var fx := _spawn_world_fx(GroundCrackFxScript)
	var col: Color = _skill_fx_def.get("trail_color", Color(0.92, 0.62, 0.22, 0.9))
	if fx.has_method("setup"):
		fx.setup(pos, radius, col, 0.55)


func _spawn_draw_slash(dir: Vector2, length: float) -> void:
	var fx := _spawn_world_fx(DrawSlashFxScript)
	var col: Color = _skill_fx_def.get("flash_color", Color(1.0, 0.96, 0.78, 0.9))
	var width := float(_skill_fx_def.get("trail_width", 16.0))
	if fx.has_method("setup"):
		fx.setup(global_position + dir * 8.0, dir, length, col, width, 0.22)


func _finish_attack_to_idle() -> void:
	_light_buffered = false
	_pending_skill = ""
	_pending_skill_slot = ""
	_skill_combat = {}
	_skill_fx_def = {}
	_skill_hide_blade = false
	_skill_jump = 0.0
	_skill_tick_index = 0
	_skill_ticks_total = 1
	_attack_phase = AttackPhase.NONE
	_attack_timer = 0.0
	_swing_dur = 0.0
	hitbox.rotation = 0.0
	sprite.position.y = 0.0
	sprite.position.x = 0.0
	_pose_recoil = 0.0
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
	var ls := float(_brand_stats().get("lifesteal", 0.0)) + float(stats.imprint_lifesteal)
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
	var style := "blade"
	var col := Color(1.0, 0.85, 0.35, 1.0)
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		style = "gun"
		col = Color(0.82, 0.62, 0.32, 1.0)
	elif _is_affinity_imprint():
		style = "nature"
		col = Color(0.55, 0.88, 0.42, 1.0) if MetaProgress.affinity_kind != "plant" else Color(0.62, 0.92, 0.38, 1.0)
	elif _is_mage_imprint():
		style = _mage_hit_spark_style()
		col = _mage_element_fx()["spark"]
	if spark.has_method("setup"):
		spark.setup(pos, facing.x, style, col)


func _apply_pending_lifesteal() -> void:
	if _pending_lifesteal <= 0.0:
		return
	var heal := _pending_lifesteal
	_pending_lifesteal = 0.0
	hp = minf(hp + heal, max_hp)
	hp_changed.emit(hp, max_hp)


func _reflect_ward_burn(from_pos: Vector2, ward_r: int) -> void:
	var p: Dictionary = SkillCatalog.passive("mgf_ward")
	var dps := float(p.get("reflect_burn", 1.5)) * float(ward_r)
	var space := get_world_2d().direct_space_state
	if space == null:
		return
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 48.0
	q.shape = circle
	q.transform = Transform2D(0.0, from_pos)
	q.collision_mask = 16
	q.collide_with_areas = true
	q.collide_with_bodies = false
	for h in space.intersect_shape(q, 16):
		var area = h.get("collider")
		if area == null:
			continue
		var host = area.get_parent()
		if host != null and host.has_method("apply_status"):
			host.apply_status(StatusEffects.KIND_BURN, {"dps": dps, "duration": 1.6})
		elif host != null and host.has_method("apply_burn"):
			host.apply_burn(dps, 1.6)


func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO) -> void:
	if invincible or input_locked:
		return
	var incoming := amount
	incoming *= 1.0 - _passive_dr()
	if awakening_branch == "ironwall":
		incoming *= 0.85
	incoming = statuses.absorb_damage(incoming)
	var mitigated: float = maxf(incoming - stats.pdef, 1.0) if incoming > 0.0 else 0.0
	if mitigated <= 0.0:
		return
	hp = maxf(hp - mitigated, 0.0)
	_hurt_flash = 0.2
	_out_combat_t = 0.0
	hp_changed.emit(hp, max_hp)
	AudioManager.sfx_hurt_player()
	var ward_r := MetaProgress.skill_rank("mgf_ward")
	if ward_r > 0 and from_pos != Vector2.ZERO:
		_reflect_ward_burn(from_pos, ward_r)
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
	_apply_imprint_visual()
	_refresh_character_stats(true)
	_refresh_metal_load()
	_sync_affinity_companion()


func _apply_imprint_visual() -> void:
	_sync_held_weapon()
	_sync_weapon_family()
	_tex_4dir = _load_imprint_4dir()
	_apply_pose_texture()
	if blade_sprite:
		blade_sprite.visible = false


func _sync_held_weapon() -> void:
	held_weapon = SkillCatalog.default_held_weapon(MetaProgress.imprint_family)


func _sync_weapon_family() -> void:
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		weapon_family = "bow"
	elif _is_mage_imprint():
		weapon_family = "mage"
	elif _is_affinity_imprint():
		weapon_family = "nature"
	else:
		weapon_family = "blade"


func _is_blade_imprint() -> bool:
	return MetaProgress.imprint_family == SkillCatalog.FAMILY_COLD or MetaProgress.imprint_family == "cold_blade"


func _proj_shape_for_imprint() -> String:
	if MetaProgress.imprint_family == SkillCatalog.FAMILY_HOT:
		return "arrow"
	if _is_affinity_imprint():
		return "vine"
	if _is_mage_imprint():
		match _mage_element():
			"ice":
				return "shard"
			"acid":
				return "acid_blob"
			"dark":
				return "shadow_bolt"
			"light":
				return "light_beam"
			_:
				return "flame"
	return "crescent"


func _style_uses_blade_slash(style: String) -> bool:
	if not _is_blade_imprint():
		return false
	return style in ["", "dash_slash", "smash_wave", "whirl", "riposte", "myriad", "draw_slash", "ground_slam", "bolt"]


func _sync_affinity_companion() -> void:
	if not _is_affinity_imprint():
		if _companion != null and is_instance_valid(_companion):
			_companion.queue_free()
		_companion = null
		return
	if _companion != null and is_instance_valid(_companion):
		if _companion.has_method("apply_kind"):
			_companion.apply_kind(MetaProgress.affinity_kind)
		return
	_companion_cd = 0.0
	_spawn_affinity_companion()


func _spawn_affinity_companion() -> void:
	if not _is_affinity_imprint() or CompanionScene == null:
		return
	if _companion != null and is_instance_valid(_companion):
		return
	var parent_n := get_parent()
	if parent_n == null:
		return
	_companion = CompanionScene.instantiate()
	parent_n.add_child(_companion)
	_companion.global_position = global_position + Vector2(-18, 10)
	if _companion.has_method("setup"):
		_companion.setup(self, MetaProgress.affinity_kind)
	_companion_cd = 6.0


func _on_companion_died() -> void:
	_companion = null
	_companion_cd = 6.0


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
