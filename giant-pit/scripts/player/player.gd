extends CharacterBody2D
## 横版侧视探索者：走 / 跳 / 大刀普攻·杀招 / 闪避。

const HitstopUtil = preload("res://scripts/combat/hitstop.gd")
const InventoryScript = preload("res://scripts/player/inventory.gd")
const CharacterStatsScript = preload("res://scripts/player/character_stats.gd")
const SkillBookScript = preload("res://scripts/player/skill_book.gd")

signal hp_changed(current: float, maximum: float)
signal died
signal toast(text: String, category: int, color: Color)
signal loadout_changed
signal inventory_changed
signal stats_changed
signal interact_prompt_changed(text: String)
signal loud_skill_used(kind: String)

enum State { IDLE, MOVE, ATTACK_LIGHT, ATTACK_HEAVY, ROLL, DEFEND, JUMP }
enum AttackPhase { NONE, LIGHT_WINDUP, LIGHT_ACTIVE, LIGHT_RECOVERY, HEAVY_WINDUP, HEAVY_ACTIVE, HEAVY_RECOVERY }

const BASE_MOVE_SPEED := 150.0
const BASE_MAX_HP := 100.0
const GRAVITY := 980.0
const JUMP_VELOCITY := -320.0
const ROLL_SPEED := 320.0
const ROLL_DURATION := 0.18
const ROLL_COOLDOWN := 1.0
const ROLL_IFRAMES := 0.16

const LIGHT_WINDUP := 0.06
const LIGHT_ACTIVE := 0.10
const LIGHT_RECOVERY := 0.16
const LIGHT_DAMAGE := 8.0
const LIGHT_KNOCKBACK := 140.0

const HEAVY_WINDUP := 0.28
const HEAVY_ACTIVE := 0.14
const HEAVY_RECOVERY := 0.36
const HEAVY_DAMAGE := 22.0
const HEAVY_KNOCKBACK := 260.0
const BLADE_ART_OFFSET_DEG := 90.0
const DEFEND_DAMAGE_MULT := 0.5
const DEFEND_MOVE_MULT := 0.45
const AIR_GREED_EXTRA_RECOVERY := 0.12
const AIR_GREED_DAMAGE_MULT := 1.25
const FACE_PUNISH_WINDOW := 0.22

@onready var sprite: Sprite2D = $Sprite
@onready var blade_pivot: Node2D = $BladePivot
@onready var blade_sprite: Sprite2D = $BladePivot/BladeSprite
@onready var hitbox: Area2D = $BladePivot/Hitbox
@onready var hitbox_shape: CollisionShape2D = $BladePivot/Hitbox/CollisionShape2D

var state: State = State.IDLE
var facing: Vector2 = Vector2.RIGHT
var roll_timer: float = 0.0
var roll_cd_left: float = 0.0
var invincible: bool = false
var attack_locked_facing: Vector2 = Vector2.RIGHT
var combo_step: int = 0
var combo_window: float = 0.0
var blade_swing_deg: float = 0.0
var _attack_phase: AttackPhase = AttackPhase.NONE
var _attack_timer: float = 0.0
var _attack_spd: float = 1.0
var _attack_kb: float = HEAVY_KNOCKBACK
var _attack_reach: float = 1.0

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
var _defending: bool = false
var _last_prompt: String = ""
var _pending_lifesteal: float = 0.0

## 横版扩展
var side_view: bool = true
var move_speed_mult: float = 1.0
var jump_mult: float = 1.0
var in_mud: bool = false
var in_fog: bool = false
var metal_load: float = 0.0
var _air_attacks: int = 0
var _face_punish_left: float = 0.0
var _was_on_floor: bool = true
var awakening_branch: String = "" ## "" | whirl | ironwall
var _tex_idle: Texture2D
var _tex_run: Texture2D
var _tex_jump: Texture2D
var _tex_light: Texture2D
var _tex_heavy: Texture2D
var _tex_dodge: Texture2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	hitbox.configure_layers(8, 16)
	hitbox.hit.connect(_on_hitbox_hit)
	hitbox.disable()
	_set_hitbox_size(Vector2(28, 22), Vector2(22, -4))
	_load_side_textures()
	_apply_blade_visual()
	inventory.changed.connect(func(): inventory_changed.emit())
	skills.changed.connect(_on_skills_changed)
	MetaProgress.changed.connect(_on_meta_changed)
	awakening_branch = MetaProgress.awakening_branch
	_refresh_character_stats(false)
	_refresh_metal_load()
	hp_changed.emit(hp, max_hp)


func _load_side_textures() -> void:
	_tex_idle = load("res://assets/characters/player/side/player_idle.png")
	_tex_run = load("res://assets/characters/player/side/player_run.png")
	_tex_jump = load("res://assets/characters/player/side/player_jump.png")
	_tex_light = load("res://assets/characters/player/side/player_light.png")
	_tex_heavy = load("res://assets/characters/player/side/player_heavy.png")
	_tex_dodge = load("res://assets/characters/player/side/player_dodge.png")
	if _tex_idle:
		sprite.texture = _tex_idle
		sprite.centered = true
		sprite.offset = Vector2(0, -8)


func _physics_process(delta: float) -> void:
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		sprite.modulate = Color(2.2, 1.2, 1.2) if fmod(_hurt_flash, 0.08) < 0.04 else Color.WHITE
		if _hurt_flash <= 0.0:
			sprite.modulate = Color.WHITE

	if roll_cd_left > 0.0:
		roll_cd_left = maxf(roll_cd_left - delta, 0.0)
	if combo_window > 0.0:
		combo_window = maxf(combo_window - delta, 0.0)
		if combo_window <= 0.0:
			combo_step = 0
	if _face_punish_left > 0.0:
		_face_punish_left = maxf(_face_punish_left - delta, 0.0)

	var on_floor := is_on_floor()
	if side_view:
		if on_floor and not _was_on_floor:
			_air_attacks = 0
		_was_on_floor = on_floor
		if not on_floor and state != State.ROLL:
			velocity.y += GRAVITY * delta
	else:
		_was_on_floor = true

	_tick_attack(delta)

	match state:
		State.IDLE, State.MOVE, State.JUMP:
			_process_free_move(delta)
		State.ROLL:
			_process_roll(delta)
		State.DEFEND:
			_process_defend(delta)
		State.ATTACK_LIGHT, State.ATTACK_HEAVY:
			_process_attack_move(delta)

	move_and_slide()
	_update_visuals()


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
	if state == State.ROLL:
		return
	if state == State.ATTACK_LIGHT or state == State.ATTACK_HEAVY:
		return
	if skills.has("rune_s_ironwall") and Input.is_action_pressed("defend"):
		if (not side_view or is_on_floor()) and state != State.DEFEND:
			state = State.DEFEND
			_defending = true
			hitbox.disable()
		return
	if state == State.DEFEND:
		_end_defend()
	if Input.is_action_just_pressed("roll") and roll_cd_left <= 0.0:
		_start_roll()
		return
	if Input.is_action_just_pressed("attack_light"):
		_start_light_attack()
		return
	if Input.is_action_just_pressed("attack_heavy"):
		_start_heavy_attack()
		return


func _process_free_move(_delta: float) -> void:
	if input_locked:
		velocity = Vector2.ZERO if not side_view else Vector2(0, velocity.y)
		if not side_view:
			velocity = Vector2.ZERO
		return
	if not side_view:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_dir * _move_speed()
		if input_dir.length_squared() > 0.01:
			facing = input_dir.normalized()
		state = State.MOVE if input_dir.length_squared() > 0.01 else State.IDLE
		return
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = axis * _move_speed()
	if absf(axis) > 0.01:
		facing = Vector2.RIGHT if axis > 0.0 else Vector2.LEFT

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY * _jump_mult()
		state = State.JUMP
		return

	if not is_on_floor():
		state = State.JUMP
	elif absf(axis) > 0.01:
		state = State.MOVE
	else:
		state = State.IDLE


func _process_defend(_delta: float) -> void:
	if input_locked or not Input.is_action_pressed("defend") or not skills.has("rune_s_ironwall"):
		_end_defend()
		return
	_defending = true
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = axis * _move_speed() * DEFEND_MOVE_MULT
	if not is_on_floor():
		_end_defend()


func _end_defend() -> void:
	_defending = false
	if state == State.DEFEND:
		state = State.IDLE


func _process_attack_move(_delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = axis * _move_speed() * 0.28
	facing = attack_locked_facing
	## 空中斩击后可微跳衔接
	if is_on_floor() and Input.is_action_just_pressed("jump") and _attack_phase in [AttackPhase.LIGHT_RECOVERY, AttackPhase.HEAVY_RECOVERY]:
		velocity.y = JUMP_VELOCITY * _jump_mult() * 0.85
		_finish_attack_to_idle()


func _process_roll(delta: float) -> void:
	roll_timer -= delta
	if side_view:
		velocity.x = facing.x * ROLL_SPEED
		velocity.y = minf(velocity.y, 0.0)
	else:
		velocity = facing * ROLL_SPEED
	if roll_timer <= ROLL_DURATION - ROLL_IFRAMES:
		invincible = false
	if roll_timer <= 0.0:
		invincible = false
		roll_cd_left = ROLL_COOLDOWN * _roll_cd_mult()
		state = State.IDLE
		velocity = Vector2.ZERO if not side_view else Vector2(0, velocity.y)


func _move_speed() -> float:
	var s := BASE_MOVE_SPEED * move_speed_mult
	if in_mud:
		s *= 0.55
	return s


func _jump_mult() -> float:
	var m := jump_mult
	## 磁累：金属件越多跳跃越差
	m *= clampf(1.0 - metal_load * 0.12, 0.45, 1.0)
	## 绞盘基建：略减负重对跳的惩罚
	m *= 1.0 + 0.04 * MetaProgress.winch_level
	return m


func _damage_mult() -> float:
	var m := 1.0
	if awakening_branch == "whirl":
		m *= 1.05
	return m


func _roll_cd_mult() -> float:
	if skills.has("rune_s_cloudstep"):
		return 0.85
	return 1.0


func _light_damage_mult() -> float:
	var m := 1.0 * _damage_mult()
	if skills.has("rune_s_chain"):
		m += 0.10
		if combo_step >= 2:
			m += 0.05
	return m


func _heavy_damage_mult() -> float:
	var m := _damage_mult()
	if skills.has("rune_s_quake"):
		m *= 1.15
	if awakening_branch == "whirl":
		m *= 1.1
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
	## 胸甲/挂坠视为金属件；背包金属材料也计入（简化）
	if MetaProgress.equipment.get("chest", {}).get("owned", false):
		metal_load += 1.0 + float(MetaProgress.equipment.get("chest", {}).get("level", 1)) * 0.25
	if MetaProgress.equipment.get("amulet", {}).get("owned", false):
		metal_load += 0.5
	for slot in inventory.slots:
		var sid := str(slot.get("id", ""))
		if sid in ["alchem_slag", "beast_scale", "ore_copper", "ore_iron"]:
			metal_load += 0.15 * float(slot.get("count", 1))


func carry_cap() -> float:
	var cap: float = float(stats.carry_cap)
	cap += 4.0 * float(MetaProgress.winch_level)
	return cap


func _update_visuals() -> void:
	blade_pivot.rotation = facing.angle()
	sprite.flip_h = facing.x < 0.0
	_apply_blade_visual()
	_apply_pose_texture()


func _apply_pose_texture() -> void:
	var tex: Texture2D = _tex_idle
	match state:
		State.MOVE:
			tex = _tex_run
		State.JUMP:
			tex = _tex_jump
		State.ROLL:
			tex = _tex_dodge
		State.ATTACK_LIGHT:
			tex = _tex_light
		State.ATTACK_HEAVY:
			tex = _tex_heavy
		_:
			tex = _tex_idle
	if tex and sprite.texture != tex:
		sprite.texture = tex


func _apply_blade_visual() -> void:
	blade_sprite.rotation_degrees = BLADE_ART_OFFSET_DEG + blade_swing_deg
	blade_sprite.visible = state in [State.ATTACK_LIGHT, State.ATTACK_HEAVY, State.IDLE, State.MOVE, State.JUMP, State.DEFEND]


func _start_roll() -> void:
	if side_view:
		var axis := Input.get_axis("move_left", "move_right")
		if absf(axis) > 0.01:
			facing = Vector2.RIGHT if axis > 0.0 else Vector2.LEFT
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_dir.length_squared() > 0.01:
			facing = input_dir.normalized()
	_attack_phase = AttackPhase.NONE
	_attack_timer = 0.0
	state = State.ROLL
	roll_timer = ROLL_DURATION
	invincible = true
	hitbox.disable()
	AudioManager.sfx_roll()


func _start_light_attack(lock_facing: Vector2 = Vector2.ZERO) -> void:
	if lock_facing != Vector2.ZERO:
		facing = Vector2.RIGHT if lock_facing.x >= 0.0 else Vector2.LEFT
	else:
		_lock_facing_from_input_or_mouse()
	attack_locked_facing = facing
	state = State.ATTACK_LIGHT
	combo_step = mini(combo_step + 1, 2)
	_attack_spd = 1.0
	_attack_reach = float(_brand_stats().get("reach", 1.0))
	var windup := LIGHT_WINDUP / _attack_spd
	if combo_step == 2:
		windup *= 0.75
		if skills.has("rune_s_chain"):
			windup *= 0.9
	if not is_on_floor():
		_air_attacks += 1
		if _air_attacks >= 2:
			windup += 0.04
	_set_hitbox_size(Vector2(36, 24) * _attack_reach, Vector2(26, -2) * _attack_reach)
	blade_swing_deg = -55.0
	_apply_blade_visual()
	_attack_phase = AttackPhase.LIGHT_WINDUP
	_attack_timer = windup
	_face_punish_left = FACE_PUNISH_WINDOW


func _start_heavy_attack(lock_facing: Vector2 = Vector2.ZERO) -> void:
	if lock_facing != Vector2.ZERO:
		facing = Vector2.RIGHT if lock_facing.x >= 0.0 else Vector2.LEFT
	else:
		_lock_facing_from_input_or_mouse()
	attack_locked_facing = facing
	state = State.ATTACK_HEAVY
	combo_step = 0
	combo_window = 0.0
	_attack_spd = 1.0
	_attack_reach = float(_brand_stats().get("reach", 1.0))
	_attack_kb = HEAVY_KNOCKBACK * float(_brand_stats().get("heavy_kb", 1.0))
	var reach_box := Vector2(48, 30)
	if awakening_branch == "whirl":
		reach_box = Vector2(56, 36)
		_attack_reach *= 1.15
	_set_hitbox_size(reach_box * _attack_reach, Vector2(30, -4) * _attack_reach)
	blade_swing_deg = -75.0
	_apply_blade_visual()
	_attack_phase = AttackPhase.HEAVY_WINDUP
	_attack_timer = HEAVY_WINDUP / _attack_spd
	_face_punish_left = FACE_PUNISH_WINDOW * 1.4
	if not is_on_floor():
		_air_attacks += 1
	loud_skill_used.emit("heavy")


func _lock_facing_from_input_or_mouse() -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.01:
		facing = Vector2.RIGHT if axis > 0.0 else Vector2.LEFT
		return
	var mouse := get_global_mouse_position()
	if mouse.x < global_position.x - 4.0:
		facing = Vector2.LEFT
	elif mouse.x > global_position.x + 4.0:
		facing = Vector2.RIGHT


func _tick_attack(delta: float) -> void:
	if _attack_phase == AttackPhase.NONE:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	match _attack_phase:
		AttackPhase.LIGHT_WINDUP:
			hitbox.enable(_roll_attack_damage(LIGHT_DAMAGE * _light_damage_mult() * (stats.patk / CharacterStatsScript.BASE_PATK)), LIGHT_KNOCKBACK, self)
			blade_swing_deg = 45.0
			_apply_blade_visual()
			_attack_phase = AttackPhase.LIGHT_ACTIVE
			_attack_timer = LIGHT_ACTIVE / _attack_spd
			AudioManager.sfx_blade()
		AttackPhase.LIGHT_ACTIVE:
			hitbox.disable()
			var recovery := LIGHT_RECOVERY / _attack_spd
			if combo_step == 2:
				recovery *= 0.85
			if _air_attacks >= 2:
				recovery += AIR_GREED_EXTRA_RECOVERY
			_attack_phase = AttackPhase.LIGHT_RECOVERY
			_attack_timer = recovery
		AttackPhase.LIGHT_RECOVERY:
			_finish_attack_to_idle()
			combo_window = 0.28
		AttackPhase.HEAVY_WINDUP:
			hitbox.enable(_roll_attack_damage(HEAVY_DAMAGE * _heavy_damage_mult() * (stats.patk / CharacterStatsScript.BASE_PATK)), _attack_kb, self)
			blade_swing_deg = 60.0
			blade_sprite.scale = Vector2.ONE
			_apply_blade_visual()
			_attack_phase = AttackPhase.HEAVY_ACTIVE
			_attack_timer = HEAVY_ACTIVE / _attack_spd
			AudioManager.sfx_blade()
		AttackPhase.HEAVY_ACTIVE:
			hitbox.disable()
			var recovery := HEAVY_RECOVERY / _attack_spd
			if _air_attacks >= 2:
				recovery += AIR_GREED_EXTRA_RECOVERY
			_attack_phase = AttackPhase.HEAVY_RECOVERY
			_attack_timer = recovery
		AttackPhase.HEAVY_RECOVERY:
			_finish_attack_to_idle()
		_:
			_attack_phase = AttackPhase.NONE


func _finish_attack_to_idle() -> void:
	blade_swing_deg = 0.0
	_apply_blade_visual()
	_attack_phase = AttackPhase.NONE
	_attack_timer = 0.0
	if state == State.ATTACK_LIGHT or state == State.ATTACK_HEAVY:
		state = State.IDLE if is_on_floor() else State.JUMP


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


func _on_hitbox_hit(_hurtbox: Area2D) -> void:
	call_deferred("_deferred_hit_fx")
	call_deferred("_apply_pending_lifesteal")


func _deferred_hit_fx() -> void:
	HitstopUtil.freeze(get_tree(), 0.055)


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
	if _defending and skills.has("rune_s_ironwall"):
		incoming *= DEFEND_DAMAGE_MULT
		if awakening_branch == "ironwall":
			incoming *= 0.7
	## 贴脸受击惩罚窗：攻击前摇中挨打伤害更高
	if _face_punish_left > 0.0 and _attack_phase in [AttackPhase.LIGHT_WINDUP, AttackPhase.HEAVY_WINDUP]:
		incoming *= AIR_GREED_DAMAGE_MULT
	if _air_attacks >= 2 and not is_on_floor():
		incoming *= 1.1
	var mitigated: float = maxf(incoming - stats.pdef, 1.0)
	hp = maxf(hp - mitigated, 0.0)
	_hurt_flash = 0.2
	hp_changed.emit(hp, max_hp)
	AudioManager.sfx_hurt_player()
	if from_pos != Vector2.ZERO:
		var push := Vector2(signf(global_position.x - from_pos.x) * 140.0, -40.0)
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
	return inventory.add_rune_as_item(rune_id, 1, carry_cap())


func try_learn_rune(rune_id: String, from_stash: bool = false) -> String:
	var r := skills.try_learn(rune_id, inventory if not from_stash else null, from_stash, brand_quality)
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
	stats.set_context(brand_quality, equip_bonus, MetaProgress.learned_runes)
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
