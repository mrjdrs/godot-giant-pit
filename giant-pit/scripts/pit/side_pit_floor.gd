extends Node2D
## 横版第 1 层：段落链 + 生态法则 + 侵蚀 + 撤离/死亡。

const ST = preload("res://scripts/pit/segment_types.gd")
const SideEnemyScene = preload("res://scenes/enemy/side_enemy.tscn")
const InteractScript = preload("res://scripts/pit/side_interactable.gd")
const BiomeRulesScript = preload("res://scripts/pit/biome_rules.gd")

const SEGMENT_WIDTH := 640.0
const GROUND_Y := 160.0

@onready var world: Node2D = $World
@onready var entities: Node2D = $World/Entities
@onready var terrain: Node2D = $World/Terrain
@onready var player: CharacterBody2D = $World/Player
@onready var hud: CanvasLayer = $HUD
@onready var hp_label: Label = $HUD/HpLabel
@onready var erosion_bar: ProgressBar = $HUD/ErosionBar
@onready var biome_label: Label = $HUD/BiomeLabel
@onready var brand_label: Label = $HUD/BrandLabel
@onready var map_title: Label = $HUD/MapPanel/VBox/MapTitle
@onready var map_row: HBoxContainer = $HUD/MapPanel/VBox/MapScroll/MapRow
@onready var map_scroll: ScrollContainer = $HUD/MapPanel/VBox/MapScroll
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var banner_label: Label = $HUD/BannerLabel
@onready var settle_panel: Control = $HUD/SettlePanel
@onready var settle_title: Label = $HUD/SettlePanel/Title
@onready var settle_body: Label = $HUD/SettlePanel/Body
@onready var btn_keep: Button = $HUD/SettlePanel/BtnKeep
@onready var btn_hub: Button = $HUD/SettlePanel/BtnHub

var graph: Dictionary = {}
var nodes_by_id: Dictionary = {}
var current_node_id: String = ""
var erosion = ErosionSystem.new()
var biome_rules: BiomeRules
var _full_mvp: bool = true
var _settling: bool = false
var _death_keep_index: int = 0
var _mud_zones: Array = []
var _fog_zones: Array = []
var _map_chip_by_id: Dictionary = {}


func _ready() -> void:
	add_to_group("side_pit_floor")
	biome_rules = BiomeRulesScript.new()
	add_child(biome_rules)
	biome_rules.reinforcement_requested.connect(_on_reinforcement)
	erosion.value_changed.connect(_on_erosion_value)
	erosion.tier_changed.connect(_on_erosion_tier)
	player.hp_changed.connect(_on_hp)
	player.died.connect(_on_player_died)
	player.toast.connect(_on_toast)
	player.interact_prompt_changed.connect(func(t): prompt_label.text = t)
	player.loud_skill_used.connect(func(k): biome_rules.on_loud_skill(player, k))
	btn_hub.pressed.connect(_return_hub)
	btn_keep.pressed.connect(_on_keep_pressed)
	settle_panel.visible = false
	banner_label.visible = false
	if map_title:
		map_title.text = Loc.t("hud.map_title")

	## 吐息简化：封锁资源节点一类
	var breath_block: bool = MetaProgress.is_breath_day()

	graph = SegmentGenerator.generate(0, _full_mvp)
	for n in graph["nodes"]:
		nodes_by_id[n["id"]] = n
		if breath_block and n["type"] == ST.NODE_RESOURCE:
			n["blocked_by_breath"] = true

	player.apply_meta_brand(RunSession.brand_quality)
	brand_label.text = Loc.t("hud.brand", [Loc.t("brand." + RunSession.brand_quality)])

	var start_id: String = str(graph.get("start_id", ""))
	if RunSession.spawn_warp_id != "":
		for n in graph["nodes"]:
			if n["type"] == ST.NODE_WARP and str(n.get("warp_id", "")) == RunSession.spawn_warp_id:
				start_id = n["id"]
				break
	_enter_node(start_id, true)
	_refresh_map_ui()
	_on_hp(player.hp, player.max_hp)


func _process(delta: float) -> void:
	if _settling:
		if btn_keep.visible and player.inventory.slots.size() > 1:
			if Input.is_action_just_pressed("move_left"):
				_death_keep_index = (_death_keep_index - 1 + player.inventory.slots.size()) % player.inventory.slots.size()
				_refresh_death_keep_label()
			elif Input.is_action_just_pressed("move_right"):
				_death_keep_index = (_death_keep_index + 1) % player.inventory.slots.size()
				_refresh_death_keep_label()
		return
	erosion.tick(delta)
	erosion.apply_dot(player, delta)
	player.move_speed_mult = erosion.move_mult()
	var in_mud := _player_in_zones(_mud_zones)
	var in_fog := _player_in_zones(_fog_zones)
	biome_rules.apply_to_player(player, in_mud, in_fog)


func _player_in_zones(zones: Array) -> bool:
	for z in zones:
		if z is Rect2 and (z as Rect2).has_point(player.global_position):
			return true
	return false


func _enter_node(node_id: String, teleport: bool = false) -> void:
	if not nodes_by_id.has(node_id):
		return
	var node: Dictionary = nodes_by_id[node_id]
	if bool(node.get("blocked_by_breath", false)):
		player.show_toast(Loc.t("toast.breath_blocked"))
		return
	current_node_id = node_id
	node["revealed"] = true
	## 探照灯揭示相邻
	if MetaProgress.spotlight_level > 0:
		for e in graph["edges"]:
			if e["from"] == node_id or e["to"] == node_id:
				var oid: String = e["to"] if e["from"] == node_id else e["from"]
				if nodes_by_id.has(oid):
					nodes_by_id[oid]["peeked"] = true

	_clear_entities()
	_build_segment_terrain(node)
	biome_rules.set_biome(str(node["biome"]))
	_show_biome_banner(str(node["biome"]))
	_spawn_node_content(node)
	if teleport:
		player.global_position = Vector2(80, GROUND_Y - 40)
		player.velocity = Vector2.ZERO
	_refresh_map_ui()
	## 自动揭示后尝试前进按钮：靠近右门
	_spawn_exits(node)


func _clear_entities() -> void:
	for c in entities.get_children():
		c.queue_free()
	for c in terrain.get_children():
		c.queue_free()
	_mud_zones.clear()
	_fog_zones.clear()


func _build_segment_terrain(node: Dictionary) -> void:
	var biome: String = str(node["biome"])
	var ground_tex = load("res://assets/tiles/side/%s/ground.png" % biome)
	var bg_tex = load("res://assets/tiles/side/%s/bg.png" % biome)
	var bg := Sprite2D.new()
	bg.texture = bg_tex
	bg.centered = true
	bg.position = Vector2(SEGMENT_WIDTH * 0.5, 40)
	bg.scale = Vector2(22, 14)
	bg.z_index = -2
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain.add_child(bg)

	_add_static_box(Vector2(SEGMENT_WIDTH * 0.5, GROUND_Y + 16), Vector2(SEGMENT_WIDTH + 40, 32), ground_tex)
	_add_static_box(Vector2(-16, 40), Vector2(32, 280), null)
	_add_static_box(Vector2(SEGMENT_WIDTH + 16, 40), Vector2(32, 280), null)
	## 平台
	_add_static_box(Vector2(220, 70), Vector2(120, 14), ground_tex)
	_add_static_box(Vector2(420, 30), Vector2(100, 14), ground_tex)

	if biome == ST.BIOME_MOSS:
		_mud_zones.append(Rect2(160, GROUND_Y - 20, 140, 40))
		var mud := ColorRect.new()
		mud.color = Color(0.2, 0.35, 0.28, 0.55)
		mud.position = Vector2(160, GROUND_Y - 10)
		mud.size = Vector2(140, 20)
		mud.z_index = -1
		terrain.add_child(mud)
		_fog_zones.append(Rect2(300, GROUND_Y - 100, 160, 90))
		var fog := ColorRect.new()
		fog.color = Color(0.7, 0.85, 0.8, 0.28)
		fog.position = Vector2(300, GROUND_Y - 100)
		fog.size = Vector2(160, 90)
		fog.z_index = 5
		terrain.add_child(fog)


func _add_static_box(pos: Vector2, size: Vector2, tex) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2(size.x / 32.0, maxf(size.y / 32.0, 0.4))
		body.add_child(spr)
	terrain.add_child(body)


func _spawn_node_content(node: Dictionary) -> void:
	var biome: String = str(node["biome"])
	var pool: Dictionary = ST.ENEMY_POOL.get(biome, ST.ENEMY_POOL[ST.BIOME_MOSS])
	match str(node["type"]):
		ST.NODE_COMBAT:
			var n_mobs := int(node.get("mobs", 2))
			for i in n_mobs:
				_spawn_enemy({
					"id": pool["mob"],
					"hp": 32.0,
					"dmg": 7.0,
					"drop": pool["drop"],
					"icon": "res://assets/enemies/side/%s.png" % pool["mob"],
				}, Vector2(280 + i * 90, GROUND_Y - 40))
		ST.NODE_ELITE:
			var awaken := ST.AWAKEN_MAT_WHIRL if biome == ST.BIOME_MOSS else ST.AWAKEN_MAT_IRON
			if biome == ST.BIOME_ECHO:
				awaken = ST.AWAKEN_MAT_WHIRL
			_spawn_enemy({
				"id": pool["elite"],
				"hp": 90.0,
				"dmg": 12.0,
				"drop": pool["drop"],
				"awaken": awaken,
				"rune": 0.25,
				"icon": "res://assets/enemies/side/%s.png" % pool["elite"],
				"speed": 85.0,
			}, Vector2(320, GROUND_Y - 40))
			## 吐息日额外精英
			if MetaProgress.is_breath_day():
				_spawn_enemy({
					"id": "breath_elite",
					"hp": 70.0,
					"dmg": 10.0,
					"drop": "mind_core",
					"icon": "res://assets/enemies/side/%s.png" % pool["elite"],
				}, Vector2(400, GROUND_Y - 40))
		ST.NODE_RESOURCE:
			_spawn_interactable(ST.NODE_RESOURCE, Vector2(300, GROUND_Y - 24), {"mat_id": pool["drop"]})
		ST.NODE_WARP:
			var wid := str(node.get("warp_id", ""))
			_spawn_interactable(ST.NODE_WARP, Vector2(280, GROUND_Y - 24), {"warp_id": wid})
			if not RunSession.is_warp_active(wid):
				_spawn_enemy({
					"id": pool["guard"],
					"hp": 60.0,
					"dmg": 10.0,
					"drop": pool["drop"],
					"warp": wid,
					"icon": "res://assets/enemies/side/%s.png" % pool["guard"],
				}, Vector2(340, GROUND_Y - 40))
		ST.NODE_SHORTCUT:
			_spawn_interactable(ST.NODE_SHORTCUT, Vector2(300, GROUND_Y - 24), {"shortcut_id": str(node.get("shortcut_id", ""))})
		ST.NODE_EXTRACT:
			_spawn_interactable(ST.NODE_EXTRACT, Vector2(300, GROUND_Y - 24), {})
		ST.NODE_BOSS:
			_spawn_enemy({
				"id": "floor_boss",
				"hp": 220.0,
				"dmg": 16.0,
				"drop": "mind_core",
				"awaken": ST.AWAKEN_MAT_IRON,
				"is_boss": true,
				"rune": 0.5,
				"icon": "res://assets/enemies/side/floor_boss.png",
				"speed": 60.0,
			}, Vector2(360, GROUND_Y - 48))
		ST.NODE_DESCENT:
			_spawn_interactable(ST.NODE_DESCENT, Vector2(300, GROUND_Y - 24), {})
		ST.NODE_QUEST:
			_spawn_interactable(ST.NODE_QUEST, Vector2(300, GROUND_Y - 24), {})
			_spawn_enemy({
				"id": "scale_rock",
				"hp": 45.0,
				"dmg": 8.0,
				"drop": pool["drop"],
				"quest_scale": true,
				"icon": "res://assets/enemies/side/%s.png" % pool["mob"],
			}, Vector2(380, GROUND_Y - 40))
		ST.NODE_EVENT:
			player.show_toast(Loc.t("toast.event_minor"))
		_:
			pass
	## 敌人警戒受雾影响
	await get_tree().process_frame
	for e in entities.get_children():
		if e is CharacterBody2D and e.has_method("configure"):
			e.aggro_mult = biome_rules.fog_aggro_mult(player)


func _spawn_enemy(def: Dictionary, pos: Vector2) -> void:
	var e = SideEnemyScene.instantiate()
	entities.add_child(e)
	e.global_position = pos
	e.configure(def)


func _spawn_interactable(itype: String, pos: Vector2, extra: Dictionary) -> void:
	var area := Area2D.new()
	area.set_script(InteractScript)
	area.interact_type = itype
	area.floor_ref = self
	if extra.has("warp_id"):
		area.warp_id = str(extra["warp_id"])
	if extra.has("shortcut_id"):
		area.shortcut_id = str(extra["shortcut_id"])
	if extra.has("mat_id"):
		area.mat_id = str(extra["mat_id"])
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.position = Vector2(0, -8)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	area.add_child(spr)
	var lbl := Label.new()
	lbl.name = "Label"
	lbl.position = Vector2(-20, -40)
	area.add_child(lbl)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 40)
	cs.shape = shape
	cs.position = Vector2(0, -8)
	area.add_child(cs)
	entities.add_child(area)
	area.global_position = pos


func _spawn_exits(node: Dictionary) -> void:
	var outs: Array = []
	for e in graph["edges"]:
		if e["from"] == node["id"]:
			outs.append(e["to"])
		elif e["to"] == node["id"]:
			outs.append(e["from"])
	var seen := {}
	var i := 0
	var DoorScript = load("res://scripts/pit/side_door.gd")
	for oid in outs:
		if seen.has(oid):
			continue
		seen[oid] = true
		var door := Area2D.new()
		door.set_script(DoorScript)
		var spr := Sprite2D.new()
		spr.name = "Sprite"
		spr.modulate = Color(0.9, 0.85, 0.5)
		if ResourceLoader.exists("res://assets/props/side/warp.png"):
			spr.texture = load("res://assets/props/side/warp.png")
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		door.add_child(spr)
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(24, 48)
		cs.shape = shape
		door.add_child(cs)
		entities.add_child(door)
		door.dest_id = str(oid)
		door.floor_ref = self
		door.global_position = Vector2(SEGMENT_WIDTH - 60 - i * 50, GROUND_Y - 28)
		i += 1


func request_travel(dest_id: String) -> void:
	_enter_node(dest_id, true)


func on_warp_guard_killed(warp_id: String) -> void:
	RunSession.activate_warp(warp_id)
	player.show_toast(Loc.t("toast.warp_unlocked"))


func request_warp_menu(warp_id: String) -> void:
	if not RunSession.is_warp_active(warp_id):
		player.show_toast(Loc.t("toast.warp_need_guard"))
		return
	## 局内互传到其它已激活锚点
	var targets: Array = []
	for wid in RunSession.active_warps_this_run.keys():
		if str(wid) != warp_id:
			targets.append(str(wid))
	if targets.is_empty():
		player.show_toast(Loc.t("toast.warp_only_one"))
		return
	if not MetaProgress.consume_mind_value(MetaProgress.WARP_COST_TRAVEL):
		player.show_toast(Loc.t("toast.no_mind"))
		return
	var target: String = targets[0]
	for n in graph["nodes"]:
		if n["type"] == ST.NODE_WARP and str(n.get("warp_id", "")) == target:
			_enter_node(n["id"], true)
			return


func request_extract() -> void:
	_finish_success()


func _finish_success() -> void:
	if _settling:
		return
	_settling = true
	erosion.paused = true
	player.input_locked = true
	var quest_r := MetaProgress.complete_quest_if_able({
		"inventory_slots": player.inventory.slots,
		"kill_scale": RunSession.kill_scale,
		"rescue_done": RunSession.rescue_done,
	})
	MetaProgress.merge_inventory_into_stash(player.inventory.slots)
	player.inventory.clear()
	settle_panel.visible = true
	btn_keep.visible = false
	settle_title.text = Loc.t("settle.success_title")
	settle_body.text = Loc.t("settle.success_body", [quest_r])
	RunSession.clear()


func _on_player_died() -> void:
	if _settling:
		return
	_settling = true
	erosion.paused = true
	MetaProgress.apply_death_wear()
	settle_panel.visible = true
	btn_keep.visible = true
	settle_title.text = Loc.t("settle.death_title")
	settle_body.text = Loc.t("settle.death_body")
	_death_keep_index = 0
	_refresh_death_keep_label()


func _on_keep_pressed() -> void:
	_confirm_death_keep()


func _refresh_death_keep_label() -> void:
	var slots: Array = player.inventory.slots
	if slots.is_empty():
		settle_body.text = Loc.t("settle.death_empty")
		btn_keep.visible = false
		return
	_death_keep_index = clampi(_death_keep_index, 0, slots.size() - 1)
	var s: Dictionary = slots[_death_keep_index]
	settle_body.text = Loc.t("settle.death_pick", [_death_keep_index + 1, slots.size(), str(s.get("id", "")), int(s.get("count", 1))]) + "\n" + Loc.t("settle.death_hint")
	btn_keep.text = Loc.t("settle.confirm_keep")


func _confirm_death_keep() -> void:
	var kept: Array = player.inventory.keep_only_index(_death_keep_index)
	MetaProgress.merge_inventory_into_stash(kept)
	player.inventory.clear()
	RunSession.clear()
	_return_hub()


func _return_hub() -> void:
	if not _settling:
		RunSession.clear()
	get_tree().change_scene_to_file("res://scenes/hub/crane_hub.tscn")


func _on_hp(cur: float, mx: float) -> void:
	hp_label.text = Loc.t("hud.hp", [int(cur), int(mx)])


func _on_erosion_value(v: float, mx: float) -> void:
	erosion_bar.max_value = mx
	erosion_bar.value = v


func _on_erosion_tier(t: int) -> void:
	player.show_toast(Loc.t("toast.erosion_tier", [t]))


func _on_toast(text: String, _cat: int, _color: Color) -> void:
	prompt_label.text = text


func _show_biome_banner(biome: String) -> void:
	var info: Dictionary = ST.BIOME_INFO.get(biome, {})
	biome_label.text = Loc.t(str(info.get("name_key", biome))) + "  ·  " + Loc.t(str(info.get("rule_key", "")))
	banner_label.text = Loc.t("hud.region_enter", [Loc.t(str(info.get("name_key", biome)))])
	banner_label.visible = true
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(func(): banner_label.visible = false)


func _refresh_map_ui() -> void:
	if map_row == null:
		return
	## 首次构建芯片；之后只刷新文案与样式
	if _map_chip_by_id.is_empty():
		for c in map_row.get_children():
			c.queue_free()
		_map_chip_by_id.clear()
		var first := true
		for n in graph["nodes"]:
			if not first:
				var sep := Label.new()
				sep.text = "›"
				sep.modulate = Color(0.7, 0.7, 0.65, 0.8)
				sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				map_row.add_child(sep)
			first = false
			var chip := Button.new()
			chip.custom_minimum_size = Vector2(56, 40)
			chip.focus_mode = Control.FOCUS_NONE
			chip.disabled = true
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			map_row.add_child(chip)
			_map_chip_by_id[str(n["id"])] = chip

	var current_chip: Control = null
	for n in graph["nodes"]:
		var nid: String = str(n["id"])
		var chip: Button = _map_chip_by_id.get(nid) as Button
		if chip == null:
			continue
		var revealed: bool = bool(n.get("revealed", false))
		var peeked: bool = bool(n.get("peeked", false)) and MetaProgress.spotlight_level > 0
		var blocked: bool = bool(n.get("blocked_by_breath", false))
		var here: bool = nid == current_node_id
		var label_text := Loc.t("map.node_hidden")
		var bg := Color(0.22, 0.22, 0.24, 0.92)
		var fg := Color(0.75, 0.75, 0.78, 1.0)
		if blocked and not revealed:
			label_text = Loc.t("map.node_blocked")
			bg = Color(0.35, 0.18, 0.2, 0.95)
			fg = Color(1.0, 0.7, 0.7, 1.0)
		elif revealed:
			label_text = _node_type_label(str(n["type"]))
			bg = _node_type_color(str(n["type"]))
			fg = Color(0.95, 0.95, 0.92, 1.0)
		elif peeked:
			label_text = _node_type_label(str(n["type"]))
			bg = _node_type_color(str(n["type"])).darkened(0.35)
			fg = Color(0.85, 0.85, 0.8, 0.9)
			chip.tooltip_text = Loc.t("map.peek_hint")
		if here:
			label_text = "◆ " + label_text
			bg = bg.lightened(0.2)
			chip.modulate = Color(1.15, 1.1, 0.85, 1.0)
			current_chip = chip
		else:
			chip.modulate = Color.WHITE
		chip.text = label_text
		chip.add_theme_color_override("font_color", fg)
		chip.add_theme_color_override("font_disabled_color", fg)
		var style := StyleBoxFlat.new()
		style.bg_color = bg
		style.set_corner_radius_all(4)
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		if here:
			style.border_color = Color(0.95, 0.85, 0.35, 1.0)
			style.set_border_width_all(2)
		chip.add_theme_stylebox_override("disabled", style)
		chip.add_theme_stylebox_override("normal", style)

	if current_chip and map_scroll:
		map_scroll.call_deferred("ensure_control_visible", current_chip)


func _node_type_label(t: String) -> String:
	match t:
		ST.NODE_COMBAT:
			return Loc.t("map.type_combat")
		ST.NODE_RESOURCE:
			return Loc.t("map.type_resource")
		ST.NODE_ELITE:
			return Loc.t("map.type_elite")
		ST.NODE_EVENT:
			return Loc.t("map.type_event")
		ST.NODE_EXTRACT:
			return Loc.t("map.type_extract")
		ST.NODE_BOSS:
			return Loc.t("map.type_boss")
		ST.NODE_WARP:
			return Loc.t("map.type_warp")
		ST.NODE_SHORTCUT:
			return Loc.t("map.type_shortcut")
		ST.NODE_QUEST:
			return Loc.t("map.type_quest")
		ST.NODE_DESCENT:
			return Loc.t("map.type_descent")
		_:
			return t


func _node_type_color(t: String) -> Color:
	match t:
		ST.NODE_COMBAT:
			return Color(0.32, 0.38, 0.28, 0.95)
		ST.NODE_RESOURCE:
			return Color(0.28, 0.42, 0.36, 0.95)
		ST.NODE_ELITE:
			return Color(0.45, 0.28, 0.22, 0.95)
		ST.NODE_EVENT:
			return Color(0.30, 0.30, 0.42, 0.95)
		ST.NODE_EXTRACT:
			return Color(0.22, 0.45, 0.40, 0.95)
		ST.NODE_BOSS:
			return Color(0.48, 0.20, 0.28, 0.95)
		ST.NODE_WARP:
			return Color(0.35, 0.28, 0.48, 0.95)
		ST.NODE_SHORTCUT:
			return Color(0.25, 0.40, 0.48, 0.95)
		ST.NODE_QUEST:
			return Color(0.42, 0.38, 0.22, 0.95)
		ST.NODE_DESCENT:
			return Color(0.20, 0.20, 0.28, 0.95)
		_:
			return Color(0.30, 0.30, 0.32, 0.95)


func _on_reinforcement(at: Vector2, biome: String) -> void:
	var pool: Dictionary = ST.ENEMY_POOL.get(biome, ST.ENEMY_POOL[ST.BIOME_MOSS])
	player.show_toast(Loc.t("toast.echo_reinforce"))
	_spawn_enemy({
		"id": pool["mob"],
		"hp": 28.0,
		"dmg": 6.0,
		"drop": pool["drop"],
		"icon": "res://assets/enemies/side/%s.png" % pool["mob"],
	}, at + Vector2(80, 0))
