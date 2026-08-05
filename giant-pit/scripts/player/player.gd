extends CharacterBody2D

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

enum State { IDLE, MOVE, ATTACK_LIGHT, ATTACK_HEAVY, ROLL, DEFEND }
enum AttackPhase { NONE, LIGHT_WINDUP, LIGHT_ACTIVE, LIGHT_RECOVERY, HEAVY_WINDUP, HEAVY_ACTIVE, HEAVY_RECOVERY }

const BASE_MOVE_SPEED := 140.0
const BASE_MAX_HP := 100.0
const ROLL_SPEED := 280.0
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


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	hitbox.configure_layers(8, 16)
	hitbox.hit.connect(_on_hitbox_hit)
	hitbox.disable()
	_set_hitbox_size(Vector2(28, 18), Vector2(20, 0))
	_apply_blade_visual()
	inventory.changed.connect(func(): inventory_changed.emit())
	skills.changed.connect(_on_skills_changed)
	MetaProgress.changed.connect(_on_meta_changed)
	_refresh_character_stats(false)
	hp_changed.emit(hp, max_hp)


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

	_tick_attack(delta)

	match state:
		State.IDLE, State.MOVE:
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
		if state != State.DEFEND:
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
		velocity = Vector2.ZERO
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * _move_speed()
	_update_facing_to_mouse()
	state = State.MOVE if input_dir.length_squared() > 0.01 else State.IDLE


func _process_defend(_delta: float) -> void:
	if input_locked or not Input.is_action_pressed("defend") or not skills.has("rune_s_ironwall"):
		_end_defend()
		return
	_defending = true
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * _move_speed() * DEFEND_MOVE_MULT
	_update_facing_to_mouse()


func _end_defend() -> void:
	_defending = false
	if state == State.DEFEND:
		state = State.IDLE


func _process_attack_move(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * _move_speed() * 0.35
	facing = attack_locked_facing


func _process_roll(delta: float) -> void:
	roll_timer -= delta
	velocity = facing * ROLL_SPEED
	if roll_timer <= ROLL_DURATION - ROLL_IFRAMES:
		invincible = false
	if roll_timer <= 0.0:
		invincible = false
		roll_cd_left = ROLL_COOLDOWN * _roll_cd_mult()
		state = State.IDLE
		velocity = Vector2.ZERO


func _move_speed() -> float:
	return BASE_MOVE_SPEED


func _damage_mult() -> float:
	return 1.0


func _roll_cd_mult() -> float:
	if skills.has("rune_s_cloudstep"):
		return 0.85
	return 1.0


func _light_damage_mult() -> float:
	var m := 1.0
	if skills.has("rune_s_chain"):
		m += 0.10
		if combo_step >= 2:
			m += 0.05
	return m


func _heavy_damage_mult() -> float:
	if skills.has("rune_s_quake"):
		return 1.15
	return 1.0


func _brand_stats() -> Dictionary:
	const MindTable = preload("res://scripts/meta/mind_table.gd")
	return MindTable.BRAND_STATS.get(brand_quality, MindTable.BRAND_STATS["iron"])


func apply_meta_brand(p_brand: String = "iron") -> void:
	brand_quality = p_brand
	equip_bonus = MetaProgress.total_equipment_bonuses()
	_refresh_character_stats(false)


func carry_cap() -> float:
	return stats.carry_cap


func _update_facing_to_mouse() -> void:
	var mouse := get_global_mouse_position()
	var dir := mouse - global_position
	if dir.length_squared() > 4.0:
		facing = dir.normalized()


func _update_visuals() -> void:
	blade_pivot.rotation = facing.angle()
	sprite.flip_h = facing.x < 0.0
	_apply_blade_visual()


func _apply_blade_visual() -> void:
	blade_sprite.rotation_degrees = BLADE_ART_OFFSET_DEG + blade_swing_deg


func _start_roll() -> void:
	_update_facing_to_mouse()
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
		facing = lock_facing.normalized()
	else:
		_update_facing_to_mouse()
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
	_set_hitbox_size(Vector2(36, 20) * _attack_reach, Vector2(26, 0) * _attack_reach)
	blade_swing_deg = -55.0
	_apply_blade_visual()
	_attack_phase = AttackPhase.LIGHT_WINDUP
	_attack_timer = windup


func _start_heavy_attack(lock_facing: Vector2 = Vector2.ZERO) -> void:
	if lock_facing != Vector2.ZERO:
		facing = lock_facing.normalized()
	else:
		_update_facing_to_mouse()
	attack_locked_facing = facing
	state = State.ATTACK_HEAVY
	combo_step = 0
	combo_window = 0.0
	_attack_spd = 1.0
	_attack_reach = float(_brand_stats().get("reach", 1.0))
	_attack_kb = HEAVY_KNOCKBACK * float(_brand_stats().get("heavy_kb", 1.0))
	_set_hitbox_size(Vector2(48, 28) * _attack_reach, Vector2(30, 0) * _attack_reach)
	blade_swing_deg = -75.0
	_apply_blade_visual()
	_attack_phase = AttackPhase.HEAVY_WINDUP
	_attack_timer = HEAVY_WINDUP / _attack_spd


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
		AttackPhase.LIGHT_ACTIVE:
			hitbox.disable()
			var recovery := LIGHT_RECOVERY / _attack_spd
			if combo_step == 2:
				recovery *= 0.85
			_attack_phase = AttackPhase.LIGHT_RECOVERY
			_attack_timer = recovery
		AttackPhase.LIGHT_RECOVERY:
			blade_swing_deg = 0.0
			_apply_blade_visual()
			_attack_phase = AttackPhase.NONE
			if state == State.ATTACK_LIGHT:
				combo_window = 0.28
				state = State.IDLE
		AttackPhase.HEAVY_WINDUP:
			hitbox.enable(_roll_attack_damage(HEAVY_DAMAGE * _heavy_damage_mult() * (stats.patk / CharacterStatsScript.BASE_PATK)), _attack_kb, self)
			blade_swing_deg = 60.0
			blade_sprite.scale = Vector2.ONE
			_apply_blade_visual()
			_attack_phase = AttackPhase.HEAVY_ACTIVE
			_attack_timer = HEAVY_ACTIVE / _attack_spd
		AttackPhase.HEAVY_ACTIVE:
			hitbox.disable()
			_attack_phase = AttackPhase.HEAVY_RECOVERY
			_attack_timer = HEAVY_RECOVERY / _attack_spd
		AttackPhase.HEAVY_RECOVERY:
			blade_swing_deg = 0.0
			_apply_blade_visual()
			_attack_phase = AttackPhase.NONE
			if state == State.ATTACK_HEAVY:
				state = State.IDLE
		_:
			_attack_phase = AttackPhase.NONE


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
	AudioManager.sfx_blade()


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
	var mitigated: float = maxf(incoming - stats.pdef, 1.0)
	hp = maxf(hp - mitigated, 0.0)
	_hurt_flash = 0.2
	hp_changed.emit(hp, max_hp)
	AudioManager.sfx_hurt_player()
	if from_pos != Vector2.ZERO:
		var push := (global_position - from_pos).normalized() * 120.0
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
	_refresh_character_stats(true)


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
