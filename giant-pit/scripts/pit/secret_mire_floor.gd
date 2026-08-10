extends Node2D
## 苔渊秘境：独立小地图，洞口返回巨坑第 1 层。

const AtmosphereScript = preload("res://scripts/fx/scene_atmosphere.gd")
const SkillBarScript = preload("res://scripts/ui/skill_bar.gd")
const SheetHostScript = preload("res://scripts/ui/character_sheet_host.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")

const PlayerScene = preload("res://scenes/player/player.tscn")
const EnemyScene = preload("res://scenes/enemy/pit_enemy.tscn")

const TILE := 32
const MAP_W := 24
const MAP_H := 18

@onready var world: Node2D = $World
@onready var rooms_root: Node2D = $World/Rooms
@onready var entities: Node2D = $World/Entities
@onready var hud: CanvasLayer = $HUD

var player: CharacterBody2D = null
var sheet_host: CanvasLayer = null
var erosion = ErosionSystem.new()
var _atmosphere: Node2D
var _skill_bar: Control
var _run_over: bool = false


func _ready() -> void:
	add_to_group("pit_floor")
	if not RunSession.active:
		RunSession.begin_run()
	_ensure_sheet_host()
	PauseMenuScript.install(self)
	erosion.value_changed.connect(_on_erosion_value)
	erosion.tier_changed.connect(_on_erosion_tier)
	AudioManager.play_bgm()
	call_deferred("_boot")


func _ensure_sheet_host() -> void:
	if sheet_host != null:
		return
	sheet_host = CanvasLayer.new()
	sheet_host.set_script(SheetHostScript)
	add_child(sheet_host)
	sheet_host.panel_closed.connect(func():
		if player != null and not _run_over:
			player.input_locked = false
	)


func _boot() -> void:
	_build_room()
	_spawn_player()
	_spawn_contents()
	_setup_hud()


func _process(delta: float) -> void:
	if player == null or _run_over:
		return
	erosion.tick(delta)
	if erosion.has_method("apply_dot"):
		erosion.apply_dot(player, delta)
	player.move_speed_mult = erosion.move_mult()
	if erosion.skill_slots_locked() > 0:
		if str(player.get("_locked_skill_slot")) == "":
			for slot in CrystalCatalog.HOTKEY_SLOTS:
				if MetaProgress.skill_in_slot(slot) != "":
					player.set_erosion_locked_slot(slot)
					break
	else:
		player.set_erosion_locked_slot("")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_bag"):
		if sheet_host:
			sheet_host.toggle_bag()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_stats"):
		if sheet_host:
			sheet_host.toggle_stats()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_skills"):
		if sheet_host:
			sheet_host.toggle_skills()
		get_viewport().set_input_as_handled()


func _build_room() -> void:
	for c in rooms_root.get_children():
		c.queue_free()
	var ground := Node2D.new()
	ground.name = "Ground"
	rooms_root.add_child(ground)
	var walls := Node2D.new()
	walls.name = "Walls"
	rooms_root.add_child(walls)

	var floor_path := "res://assets/tiles/region_a/tile_a_floor_01.png"
	if not ResourceLoader.exists(floor_path):
		floor_path = "res://assets/tiles/shared/tile_border.png"
	var floor_tex: Texture2D = load(floor_path)
	var spr := Sprite2D.new()
	spr.texture = floor_tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.centered = false
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, (MAP_W - 2) * TILE, (MAP_H - 2) * TILE)
	spr.position = Vector2(TILE, TILE)
	spr.z_index = -3
	ground.add_child(spr)

	var wall_tex_path := "res://assets/tiles/region_a/tile_a_wall.png"
	if not ResourceLoader.exists(wall_tex_path):
		wall_tex_path = "res://assets/tiles/pit_wall/tile_wall.png"
	var wall_tex: Texture2D = load(wall_tex_path) if ResourceLoader.exists(wall_tex_path) else null
	var wall_body := StaticBody2D.new()
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0
	walls.add_child(wall_body)
	for y in MAP_H:
		for x in MAP_W:
			var edge := x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1
			if not edge:
				continue
			if wall_tex:
				var ws := Sprite2D.new()
				ws.texture = wall_tex
				ws.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				ws.position = Vector2((x + 0.5) * TILE, (y + 0.5) * TILE)
				walls.add_child(ws)
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(TILE, TILE)
			shape.shape = rect
			shape.position = Vector2((x + 0.5) * TILE, (y + 0.5) * TILE)
			wall_body.add_child(shape)

	_atmosphere = AtmosphereScript.install(world, self, "moss", 0.28, false)


func _tile_world(tx: int, ty: int) -> Vector2:
	return Vector2((float(tx) + 0.5) * TILE, (float(ty) + 0.5) * TILE)


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	entities.add_child(player)
	player.global_position = _tile_world(4, 9)
	player.side_view = false
	player.combat_enabled = true
	player.apply_meta_brand(RunSession.brand_quality)
	player.died.connect(_on_player_died)
	player.toast.connect(_on_toast)
	erosion.set_value(RunSession.erosion_value, true)
	RunSession.restore_explorer(player)
	if player.has_method("set_camera_limits"):
		player.set_camera_limits(0.0, 0.0, float(MAP_W * TILE), float(MAP_H * TILE))


func _spawn_contents() -> void:
	_spawn_exit(_tile_world(4, 9))
	if not RunSession.secret_chest_looted:
		_spawn_chest(_tile_world(18, 8))
	if not RunSession.secret_special_dead:
		_spawn_special(_tile_world(14, 10))


func _spawn_exit(pos: Vector2) -> void:
	var hole := Polygon2D.new()
	hole.color = Color(0.03, 0.05, 0.04, 1)
	hole.z_index = -1
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		pts.append(Vector2(cos(a) * 20.0, sin(a) * 14.0))
	hole.polygon = pts
	rooms_root.add_child(hole)
	hole.global_position = pos

	var exit_n := Area2D.new()
	exit_n.set_script(preload("res://scripts/pit/secret_exit.gd"))
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 22.0
	shape.shape = circ
	exit_n.add_child(shape)
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	if ResourceLoader.exists("res://assets/tiles/hub/hub_pit_mouth.png"):
		spr.texture = load("res://assets/tiles/hub/hub_pit_mouth.png")
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	exit_n.add_child(spr)
	entities.add_child(exit_n)
	exit_n.global_position = pos
	if exit_n.has_signal("exit_requested"):
		exit_n.exit_requested.connect(_on_exit)


func _spawn_chest(pos: Vector2) -> void:
	var chest := Area2D.new()
	chest.set_script(preload("res://scripts/pit/secret_chest.gd"))
	var cshape := CollisionShape2D.new()
	var ccirc := CircleShape2D.new()
	ccirc.radius = 18.0
	cshape.shape = ccirc
	chest.add_child(cshape)
	var cspr := Sprite2D.new()
	if ResourceLoader.exists("res://assets/tiles/pit_props/prop_alchem_chest.png"):
		cspr.texture = load("res://assets/tiles/pit_props/prop_alchem_chest.png")
		cspr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chest.add_child(cspr)
	entities.add_child(chest)
	chest.global_position = pos


func _spawn_special(pos: Vector2) -> void:
	var e := EnemyScene.instantiate()
	entities.add_child(e)
	e.global_position = pos
	e.configure({
		"id": "special_a",
		"icon": "res://assets/enemies/elites/elite_a_mire_lord.png",
		"hp": 120.0,
		"dmg": 13.0,
		"armor": 5.0,
		"drop": "mire_pearl",
		"rune": 0.55,
		"is_special": true,
	})
	if e.has_signal("died_with_id") and not e.died_with_id.is_connected(_on_enemy_killed):
		e.died_with_id.connect(_on_enemy_killed)


func _on_enemy_killed(enemy_id: String, _meta: Dictionary) -> void:
	if enemy_id == "special_a":
		RunSession.secret_special_dead = true
	if player:
		player.show_toast(Loc.t("feed.kill_elite", [EnemyCatalog.display_name(enemy_id)]), PitEventLog.Category.KILL)


func _on_exit(_by: Node) -> void:
	if _run_over:
		return
	RunSession.snapshot_explorer(player, RunSession.explored_chunks, RunSession.elite_a_dead, erosion.value, false)
	RunSession.returning_from_secret = true
	get_tree().change_scene_to_file("res://scenes/pit/pit_floor_01.tscn")


func apply_erosion_salve(amount: float = 25.0) -> void:
	erosion.set_value(erosion.value - amount)


func _setup_hud() -> void:
	if hud.has_node("HintLabel"):
		hud.get_node("HintLabel").text = Loc.t("secret.mire_hint")
	if hud.has_node("FloorLabel"):
		hud.get_node("FloorLabel").text = Loc.t("secret.mire_title")
	_ensure_sheet_host()
	if sheet_host and player:
		sheet_host.bind_player(player, false)
	if player and not player.interact_prompt_changed.is_connected(_on_prompt):
		player.interact_prompt_changed.connect(_on_prompt)
	if hud and not hud.has_node("SkillBar"):
		_skill_bar = Control.new()
		_skill_bar.name = "SkillBar"
		_skill_bar.set_script(SkillBarScript)
		hud.add_child(_skill_bar)
		if _skill_bar.has_method("bind_player"):
			_skill_bar.bind_player(player)
	elif hud and hud.has_node("SkillBar"):
		_skill_bar = hud.get_node("SkillBar")
		if _skill_bar.has_method("bind_player"):
			_skill_bar.bind_player(player)
	_refresh_vitals()


func _on_prompt(text: String) -> void:
	if hud.has_node("PromptLabel"):
		hud.get_node("PromptLabel").text = text


func _refresh_vitals() -> void:
	if player == null or _skill_bar == null:
		return
	if _skill_bar.has_method("set_vitals"):
		_skill_bar.set_vitals(player.hp, player.max_hp)
	if _skill_bar.has_method("set_erosion"):
		_skill_bar.set_erosion(erosion.value, ErosionSystem.MAX_VALUE, erosion.tier)
	if _skill_bar.has_method("set_mind"):
		_skill_bar.set_mind(MetaProgress.mind_value, MetaProgress.mind_value_max())


func _on_erosion_value(value: float, max_value: float) -> void:
	if _skill_bar and _skill_bar.has_method("set_erosion"):
		_skill_bar.set_erosion(value, max_value, erosion.tier)


func _on_erosion_tier(tier: int) -> void:
	if player:
		player.show_toast(Loc.t("toast.erosion_tier", [tier]), PitEventLog.Category.SYSTEM)


func _on_toast(text: String, category: int = PitEventLog.Category.SYSTEM, color: Color = Color.TRANSPARENT) -> void:
	if hud.has_node("EventLog") and hud.get_node("EventLog").has_method("push"):
		hud.get_node("EventLog").push(text, category, color)
	_refresh_vitals()


func _on_player_died() -> void:
	if _run_over:
		return
	_run_over = true
	MetaProgress.apply_death_wear()
	if player:
		MetaProgress.merge_inventory_into_stash(player.inventory.slots)
		player.inventory.clear()
	RunSession.clear()
	get_tree().change_scene_to_file("res://scenes/hub/crane_hub.tscn")
