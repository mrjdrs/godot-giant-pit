extends CharacterBody2D

const HitstopUtil = preload("res://scripts/combat/hitstop.gd")
const InventoryScript = preload("res://scripts/player/inventory.gd")
const RuneLoadoutScript = preload("res://scripts/player/rune_loadout.gd")

signal hp_changed(current: float, maximum: float)
signal died
signal toast(text: String)
signal loadout_changed
signal inventory_changed
signal rune_replace_requested(rune_id: String, candidates: Array)

enum State { IDLE, MOVE, ATTACK_LIGHT, ATTACK_HEAVY, ROLL }

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

var max_hp: float = BASE_MAX_HP
var hp: float = BASE_MAX_HP
var inventory = InventoryScript.new()
var runes = RuneLoadoutScript.new()
var nearby_interactable: Node = null
var nearby_interactables: Array = []
var _nearby_focus: int = 0
var input_locked: bool = false
var combat_enabled: bool = true
var brand_quality: String = "iron"
var equip_bonus: Dictionary = {"max_hp": 0.0, "defense": 0.0, "damage": 0.0}
var _hurt_flash: float = 0.0
var _pending_rune_pickup: Node = null
var _pending_rune_id: String = ""


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	hitbox.configure_layers(8, 16)
	hitbox.hit.connect(_on_hitbox_hit)
	hitbox.disable()
	_set_hitbox_size(Vector2(28, 18), Vector2(20, 0))
	_apply_blade_visual()
	runes.changed.connect(_on_runes_changed)
	inventory.changed.connect(func(): inventory_changed.emit())
	_refresh_stats_from_runes(false)
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

	if not input_locked:
		_handle_combat_input()
		if Input.is_action_just_pressed("interact"):
			_try_interact()
		if Input.is_action_just_pressed("cycle_interact"):
			_cycle_nearby(1)
		if Input.is_action_just_pressed("toggle_bag"):
			## 由场景 HUD 监听；这里也发 toast 提示留给 pit_floor
			pass

	match state:
		State.IDLE, State.MOVE:
			_process_free_move(delta)
		State.ROLL:
			_process_roll(delta)
		State.ATTACK_LIGHT, State.ATTACK_HEAVY:
			_process_attack_move(delta)

	move_and_slide()
	_update_visuals()


func _handle_combat_input() -> void:
	if not combat_enabled:
		return
	if state == State.ROLL:
		return
	if state == State.ATTACK_LIGHT or state == State.ATTACK_HEAVY:
		return
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
		roll_cd_left = ROLL_COOLDOWN * runes.roll_cd_mult()
		state = State.IDLE
		velocity = Vector2.ZERO


func _move_speed() -> float:
	return BASE_MOVE_SPEED * runes.move_speed_mult()


func _damage_mult() -> float:
	var brand: Dictionary = _brand_stats()
	return runes.damage_mult() * float(brand.get("dmg", 1.0)) * (1.0 + float(equip_bonus.get("damage", 0.0)))


func _brand_stats() -> Dictionary:
	const MindTable = preload("res://scripts/meta/mind_table.gd")
	return MindTable.BRAND_STATS.get(brand_quality, MindTable.BRAND_STATS["iron"])


func apply_meta_loadout(p_brand: String = "iron") -> void:
	brand_quality = p_brand
	equip_bonus = MetaProgress.total_equipment_bonuses()
	_refresh_stats_from_runes(false)


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
	_play_light_attack()


func _start_heavy_attack(lock_facing: Vector2 = Vector2.ZERO) -> void:
	if lock_facing != Vector2.ZERO:
		facing = lock_facing.normalized()
	else:
		_update_facing_to_mouse()
	attack_locked_facing = facing
	state = State.ATTACK_HEAVY
	_play_heavy_attack()


func _play_light_attack() -> void:
	combo_step = mini(combo_step + 1, 2)
	var spd := runes.attack_speed_mult()
	var windup := LIGHT_WINDUP / spd
	var recovery := LIGHT_RECOVERY / spd
	if combo_step == 2:
		windup *= 0.75
		recovery *= 0.85

	var reach := runes.reach_mult() * float(_brand_stats().get("reach", 1.0))
	_set_hitbox_size(Vector2(36, 20) * reach, Vector2(26, 0) * reach)
	blade_swing_deg = -55.0
	_apply_blade_visual()
	await get_tree().create_timer(windup).timeout
	if state != State.ATTACK_LIGHT:
		return

	hitbox.enable(LIGHT_DAMAGE * _damage_mult(), LIGHT_KNOCKBACK, self)
	blade_swing_deg = 45.0
	_apply_blade_visual()
	await get_tree().create_timer(LIGHT_ACTIVE / spd).timeout
	hitbox.disable()
	if state != State.ATTACK_LIGHT:
		return

	await get_tree().create_timer(recovery).timeout
	blade_swing_deg = 0.0
	_apply_blade_visual()
	if state == State.ATTACK_LIGHT:
		combo_window = 0.28
		state = State.IDLE


func _play_heavy_attack() -> void:
	combo_step = 0
	combo_window = 0.0
	var spd := runes.attack_speed_mult()
	var reach := runes.reach_mult() * float(_brand_stats().get("reach", 1.0))
	var kb := HEAVY_KNOCKBACK * float(_brand_stats().get("heavy_kb", 1.0)) * runes.heavy_knockback_mult()
	_set_hitbox_size(Vector2(48, 28) * reach, Vector2(30, 0) * reach)
	blade_swing_deg = -75.0
	_apply_blade_visual()
	var tween := create_tween()
	tween.tween_property(blade_sprite, "scale", Vector2(1.15, 1.15), HEAVY_WINDUP / spd)
	await get_tree().create_timer(HEAVY_WINDUP / spd).timeout
	if state != State.ATTACK_HEAVY:
		return

	hitbox.enable(HEAVY_DAMAGE * _damage_mult() * runes.heavy_damage_mult(), kb, self)
	blade_swing_deg = 60.0
	blade_sprite.scale = Vector2.ONE
	_apply_blade_visual()
	await get_tree().create_timer(HEAVY_ACTIVE / spd).timeout
	hitbox.disable()
	if state != State.ATTACK_HEAVY:
		return

	await get_tree().create_timer(HEAVY_RECOVERY / spd).timeout
	blade_swing_deg = 0.0
	_apply_blade_visual()
	if state == State.ATTACK_HEAVY:
		state = State.IDLE


func _set_hitbox_size(size: Vector2, offset: Vector2) -> void:
	var rect := hitbox_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		hitbox_shape.shape = rect
	rect.size = size
	hitbox_shape.position = offset


func _on_hitbox_hit(_hurtbox: Area2D) -> void:
	HitstopUtil.freeze(get_tree(), 0.055)
	AudioManager.sfx_blade()
	print(Loc.t("sfx.blade_hit"))


func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO) -> void:
	if invincible or input_locked:
		return
	var mitigated: float = maxf(amount - float(equip_bonus.get("defense", 0.0)), 1.0)
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
	state = State.IDLE
	velocity = Vector2.ZERO
	hitbox.disable()
	died.emit()


func try_add_material(mat_id: String, count: int = 1) -> bool:
	return inventory.add_material(mat_id, count)


func try_add_rune(rune_id: String) -> String:
	return runes.try_equip(rune_id)


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
		return
	var idx := nearby_interactables.find(focused)
	if idx >= 0:
		_nearby_focus = idx
	else:
		_nearby_focus = clampi(_nearby_focus, 0, nearby_interactables.size() - 1)
	_set_focus_node(nearby_interactables[_nearby_focus])


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


func show_toast(text: String) -> void:
	toast.emit(text)


func request_rune_replace(pickup: Node, rune_id: String) -> void:
	_pending_rune_pickup = pickup
	_pending_rune_id = rune_id
	var candidates: Array = runes.ids_in_same_group(rune_id)
	rune_replace_requested.emit(rune_id, candidates)
	show_toast(Loc.t("rune.replace_hint"))


func confirm_rune_replace(old_id: String) -> void:
	if _pending_rune_id == "":
		return
	var r := runes.replace_rune(old_id, _pending_rune_id)
	if r == "ok":
		const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
		show_toast(Loc.t("rune.replaced", [RuneCatalog.display_name(_pending_rune_id)]))
		AudioManager.sfx_pickup()
		if is_instance_valid(_pending_rune_pickup):
			_pending_rune_pickup.queue_free()
	_pending_rune_pickup = null
	_pending_rune_id = ""


func cancel_rune_replace() -> void:
	_pending_rune_pickup = null
	_pending_rune_id = ""


func _on_runes_changed() -> void:
	_refresh_stats_from_runes(true)
	loadout_changed.emit()


func _refresh_stats_from_runes(keep_ratio: bool) -> void:
	var ratio := 1.0
	if keep_ratio and max_hp > 0.0:
		ratio = hp / max_hp
	max_hp = BASE_MAX_HP + runes.max_hp_bonus() + float(equip_bonus.get("max_hp", 0.0))
	hp = clampf(max_hp * ratio, 1.0, max_hp) if keep_ratio else max_hp
	hp_changed.emit(hp, max_hp)
