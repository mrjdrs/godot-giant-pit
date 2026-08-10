extends Node2D
## 第 1 层大地图运行时：三区域 + 迷雾 + 传送/精英/BOSS。

const Floor1Generator = preload("res://scripts/pit/floor1_generator.gd")
const RegionCatalog = preload("res://scripts/pit/region_catalog.gd")
const QuestDefs = preload("res://scripts/meta/quest_defs.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const BiomeRulesScript = preload("res://scripts/pit/biome_rules.gd")
const AtmosphereScript = preload("res://scripts/fx/scene_atmosphere.gd")
const SkillBarScript = preload("res://scripts/ui/skill_bar.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const ST = preload("res://scripts/pit/segment_types.gd")

const PlayerScene = preload("res://scenes/player/player.tscn")
const EnemyScene = preload("res://scenes/enemy/pit_enemy.tscn")
const ExtractScene = preload("res://scenes/pit/extract_beacon.tscn")
const DescentScene = preload("res://scenes/pit/descent_beacon.tscn")
const DistressScene = preload("res://scenes/pit/distress_beacon.tscn")
const ResourceScene = preload("res://scenes/pit/resource_node.tscn")
const WarpScene = preload("res://scenes/pit/warp_beacon.tscn")
const SheetHostScript = preload("res://scripts/ui/character_sheet_host.gd")

@onready var world: Node2D = $World
@onready var rooms_root: Node2D = $World/Rooms
@onready var entities: Node2D = $World/Entities
@onready var fog_root: Node2D = $World/Fog
@onready var hud: CanvasLayer = $HUD
@onready var extract_ui: CanvasLayer = $ExtractUI
@onready var death_ui: CanvasLayer = $DeathUI

var player: CharacterBody2D = null
var sheet_host: CanvasLayer = null
var _map: Dictionary = {}
var _walkable: Dictionary = {}
var _region_of: Dictionary = {}
var _markers: Dictionary = {}
var _explored_chunks: Dictionary = {} ## Vector2i -> true
var _fog_chunks: Dictionary = {} ## Vector2i -> ColorRect/Polygon
var _warps: Dictionary = {} ## warp_id -> node
var _current_region: String = ""
var _run_over: bool = false
var _death_selected: int = -1
var _death_wired: bool = false
var _quest_open: bool = false
var _warp_menu_from: String = ""
var _minimap_dirty: bool = false
var _last_minimap_tile: Vector2i = Vector2i(-99999, -99999)
var erosion = ErosionSystem.new()
var biome_rules: BiomeRules
var _atmosphere: Node2D
var _skill_bar: Control


func _ready() -> void:
	add_to_group("pit_floor")
	if not RunSession.active:
		RunSession.begin_run()
	extract_ui.visible = false
	death_ui.visible = false
	if hud.has_node("QuestPanel"):
		hud.get_node("QuestPanel").visible = false
	if hud.has_node("WarpPanel"):
		hud.get_node("WarpPanel").visible = false
	if hud.has_node("RegionBanner"):
		hud.get_node("RegionBanner").modulate.a = 0.0
	_ensure_sheet_host()
	biome_rules = BiomeRulesScript.new()
	add_child(biome_rules)
	biome_rules.reinforcement_requested.connect(_on_reinforcement)
	erosion.value_changed.connect(_on_erosion_value)
	erosion.tier_changed.connect(_on_erosion_tier)
	AudioManager.play_bgm()
	call_deferred("_deferred_boot")


func _ensure_sheet_host() -> void:
	if sheet_host != null:
		return
	sheet_host = CanvasLayer.new()
	sheet_host.set_script(SheetHostScript)
	add_child(sheet_host)
	sheet_host.panel_closed.connect(_on_sheet_closed)


func _on_sheet_closed() -> void:
	if player != null and not _run_over:
		player.input_locked = false


func _deferred_boot() -> void:
	_build_floor_level()
	_wire_death_ui()
	_wire_bag_ui()
	_wire_quest_ui()
	_wire_warp_ui()
	extract_ui.get_node("Panel/RetryButton").text = Loc.t("extract.back_hub")
	extract_ui.get_node("Panel/ArenaButton").visible = false


func _process(delta: float) -> void:
	if player == null or _run_over:
		return
	erosion.tick(delta)
	_apply_biome_runtime()
	if erosion.has_method("apply_dot"):
		erosion.apply_dot(player, delta)
	_update_exploration()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if player:
				player._cycle_nearby(-1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if player:
				player._cycle_nearby(1)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("toggle_bag"):
		if sheet_host:
			sheet_host.toggle_bag()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_stats"):
		if sheet_host:
			sheet_host.toggle_stats()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_skills"):
		if sheet_host:
			sheet_host.toggle_skills()
		get_viewport().set_input_as_handled()
		return


func _build_floor_level() -> void:
	_fog_chunks.clear()
	_explored_chunks.clear()
	_warps.clear()
	_current_region = ""
	_map = Floor1Generator.generate(0)
	_walkable = _map.get("walkable", {})
	_region_of = _map.get("region_of", {})
	_markers = _map.get("markers", {})
	_build_terrain()
	_build_chunk_fog()
	_spawn_player()
	_spawn_contents()
	_setup_hud()
	_setup_minimap()


func _build_terrain() -> void:
	for c in rooms_root.get_children():
		c.queue_free()
	var ground := Node2D.new()
	ground.name = "Ground"
	rooms_root.add_child(ground)
	var walls := Node2D.new()
	walls.name = "Walls"
	rooms_root.add_child(walls)
	var decor := Node2D.new()
	decor.name = "Decor"
	rooms_root.add_child(decor)

	var tile: int = int(_map.get("tile", 32))
	## 按区域矩形平铺地砖（repeat，不拉伸），只盖本区 bounds，避免把邻区贴图拉进来。
	var bounds: Dictionary = _map.get("region_bounds", {})
	for rid in bounds.keys():
		var rect: Rect2i = bounds[rid]
		var floors: Array = RegionCatalog.FLOOR_TILES.get(rid, RegionCatalog.FLOOR_TILES[RegionCatalog.REGION_A])
		var tex_path: String = str(floors[0])
		var tex: Texture2D = load(tex_path)
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		s.centered = false
		s.region_enabled = true
		s.region_rect = Rect2(0, 0, rect.size.x * tile, rect.size.y * tile)
		s.position = Vector2(rect.position.x * tile, rect.position.y * tile)
		s.z_index = -3
		ground.add_child(s)
		## 装饰点缀
		var dec_list: Array = RegionCatalog.DECOR.get(rid, [])
		if not dec_list.is_empty():
			for i in 6:
				var dx := rect.position.x + 2 + (i * 3) % maxi(rect.size.x - 4, 1)
				var dy := rect.position.y + 2 + ((i * 5) % maxi(rect.size.y - 4, 1))
				var g := Vector2i(dx, dy)
				if not _walkable.has(g):
					continue
				var dtex: Texture2D = load(str(dec_list[i % dec_list.size()]))
				var ds := Sprite2D.new()
				ds.texture = dtex
				ds.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				ds.position = Vector2((dx + 0.5) * tile, (dy + 0.5) * tile)
				ds.z_index = -2
				decor.add_child(ds)

	## 走廊补地
	var corridor_tex: Texture2D = load("res://assets/tiles/shared/tile_border.png")
	for g in _walkable.keys():
		var rid := str(_region_of.get(g, RegionCatalog.REGION_A))
		if bounds.has(rid):
			var r: Rect2i = bounds[rid]
			if r.has_point(g):
				continue
		var cs := Sprite2D.new()
		cs.texture = corridor_tex
		cs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cs.centered = false
		cs.position = Vector2(g.x * tile, g.y * tile)
		cs.scale = Vector2(float(tile) / float(corridor_tex.get_width()), float(tile) / float(corridor_tex.get_height()))
		cs.z_index = -3
		ground.add_child(cs)

	## 墙：不可走邻接。碰撞合并到单个 StaticBody2D + 矩形合并，避免上千独立刚体。
	var dirs := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var wall_done: Dictionary = {}
	for g in _walkable.keys():
		for d in dirs:
			var n: Vector2i = g + d
			if _walkable.has(n):
				continue
			wall_done[n] = true
	var wall_body := StaticBody2D.new()
	wall_body.name = "WallCollision"
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0
	walls.add_child(wall_body)
	var wall_visuals := Node2D.new()
	wall_visuals.name = "WallVisuals"
	walls.add_child(wall_visuals)
	var wall_tex_cache: Dictionary = {}
	for n in wall_done.keys():
		var rid2 := str(_region_of.get(n, _region_of.get(n + Vector2i.LEFT, RegionCatalog.REGION_A)))
		## Prefer region of an adjacent walkable tile for texture choice.
		for d2 in dirs:
			var neighbor: Vector2i = n + d2
			if _walkable.has(neighbor):
				rid2 = str(_region_of.get(neighbor, RegionCatalog.REGION_A))
				break
		var wpath: String = str(RegionCatalog.WALL_TILES.get(rid2, "res://assets/tiles/pit_wall/tile_wall.png"))
		_make_wall_visual(wall_visuals, n, tile, wpath, wall_tex_cache)
	var merged_rects: Array = _merge_wall_rects(wall_done.keys())
	for rect_i in merged_rects:
		var r: Rect2i = rect_i
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(r.size.x * tile, r.size.y * tile)
		shape.shape = rect
		shape.position = Vector2((r.position.x + r.size.x * 0.5) * tile, (r.position.y + r.size.y * 0.5) * tile)
		wall_body.add_child(shape)


func _merge_wall_rects(tiles: Array) -> Array:
	## Greedy row-span merge, then vertical merge of identical spans.
	var by_y: Dictionary = {}
	for t in tiles:
		var p: Vector2i = t
		if not by_y.has(p.y):
			by_y[p.y] = []
		by_y[p.y].append(p.x)
	var row_spans: Array = [] ## {y, x0, x1} inclusive
	var ys: Array = by_y.keys()
	ys.sort()
	for y in ys:
		var xs: Array = by_y[y]
		xs.sort()
		var start: int = xs[0]
		var prev: int = xs[0]
		for i in range(1, xs.size()):
			var x: int = xs[i]
			if x == prev + 1:
				prev = x
				continue
			row_spans.append({"y": y, "x0": start, "x1": prev})
			start = x
			prev = x
		row_spans.append({"y": y, "x0": start, "x1": prev})
	var used: Dictionary = {}
	var out: Array = []
	for i in row_spans.size():
		if used.has(i):
			continue
		var span: Dictionary = row_spans[i]
		var y0: int = int(span.y)
		var y1: int = y0
		var x0: int = int(span.x0)
		var x1: int = int(span.x1)
		used[i] = true
		var grow := true
		while grow:
			grow = false
			var next_y := y1 + 1
			for j in row_spans.size():
				if used.has(j):
					continue
				var s2: Dictionary = row_spans[j]
				if int(s2.y) == next_y and int(s2.x0) == x0 and int(s2.x1) == x1:
					used[j] = true
					y1 = next_y
					grow = true
					break
		out.append(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1))
	return out


func _make_wall_visual(visuals: Node2D, g: Vector2i, tile: int, tex_path: String, tex_cache: Dictionary) -> void:
	var spr := Sprite2D.new()
	if ResourceLoader.exists(tex_path):
		if not tex_cache.has(tex_path):
			tex_cache[tex_path] = load(tex_path)
		spr.texture = tex_cache[tex_path]
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2((g.x + 0.5) * tile, (g.y + 0.5) * tile)
	visuals.add_child(spr)


func _build_chunk_fog() -> void:
	for c in fog_root.get_children():
		c.queue_free()
	_fog_chunks.clear()
	var tile: int = int(_map.get("tile", 32))
	var chunk: int = int(_map.get("chunk", 8))
	var seen: Dictionary = {}
	for g in _walkable.keys():
		var ck := Floor1Generator.chunk_of_tile(g)
		if seen.has(ck):
			continue
		seen[ck] = true
		var poly := Polygon2D.new()
		poly.color = Color(0.04, 0.03, 0.05, 0.92)
		poly.z_index = 20
		var origin := Vector2(ck.x * chunk * tile, ck.y * chunk * tile)
		var sz := float(chunk * tile)
		poly.position = origin
		poly.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(sz, 0), Vector2(sz, sz), Vector2(0, sz)
		])
		fog_root.add_child(poly)
		_fog_chunks[ck] = poly


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	entities.add_child(player)
	var spawn_pos: Vector2 = _markers.get("spawn", Vector2(200, 200))
	var sid := RunSession.spawn_warp_id
	if sid != "" and _markers.has(sid):
		spawn_pos = _markers[sid]
	player.global_position = spawn_pos
	player.side_view = false
	player.combat_enabled = true
	player.apply_meta_brand(RunSession.brand_quality)
	player.died.connect(_on_player_died)
	player.toast.connect(_on_toast)
	if player.has_signal("loud_skill_used") and not player.loud_skill_used.is_connected(_on_loud_skill):
		player.loud_skill_used.connect(_on_loud_skill)
	_atmosphere = AtmosphereScript.install(world, self, "moss", 0.22, false)
	_reveal_around(player.global_position)


func _spawn_contents() -> void:
	## 撤离 / 下层 / BOSS
	_spawn_extract(_markers.get("extract", Vector2.ZERO))
	_spawn_descent(_markers.get("descent", Vector2.ZERO))
	_spawn_boss(_markers.get("boss", Vector2.ZERO))

	for rid in [RegionCatalog.REGION_A, RegionCatalog.REGION_B, RegionCatalog.REGION_C]:
		_spawn_elite(rid)
		_spawn_warp_and_guard(rid)
		_spawn_region_resources(rid)
		_spawn_region_mobs(rid)

	## 委托相关
	if RunSession.quest_id_snapshot == "rescue_beacon":
		_spawn_distress(_markers.get("distress", Vector2.ZERO))
	if RunSession.quest_id_snapshot == "kill_scale":
		for p in _markers.get("scale_quest", []):
			_spawn_enemy_at(p, {
				"id": "a_scale",
				"icon": "res://assets/enemies/region_a/enemy_a_scale_rock.png",
				"hp": 42.0,
				"dmg": 8.0,
				"drop": "beast_scale",
				"rune": 0.4,
				"quest_scale": true,
			})


func _spawn_extract(pos: Vector2) -> void:
	var b := ExtractScene.instantiate()
	entities.add_child(b)
	b.global_position = pos
	b.extract_requested.connect(_on_extract)


func _spawn_descent(pos: Vector2) -> void:
	var b := DescentScene.instantiate()
	entities.add_child(b)
	b.global_position = pos


func _spawn_distress(pos: Vector2) -> void:
	var b := DistressScene.instantiate()
	entities.add_child(b)
	b.global_position = pos


func _spawn_boss(pos: Vector2) -> void:
	var def: Dictionary = RegionCatalog.BOSS.duplicate()
	def["is_boss"] = true
	_spawn_enemy_at(pos, def)
	## 祭坛装饰
	var altar := Sprite2D.new()
	altar.texture = load("res://assets/props/boss/prop_boss_altar.png")
	altar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	altar.global_position = _markers.get("boss_altar", pos + Vector2(40, 0))
	altar.z_index = -1
	rooms_root.add_child(altar)


func _spawn_elite(rid: String) -> void:
	var def: Dictionary = RegionCatalog.ELITES[rid].duplicate()
	_spawn_enemy_at(_markers.get("elite_%s" % rid, Vector2.ZERO), def)


func _spawn_warp_and_guard(rid: String) -> void:
	var warp_id := "warp_%s" % rid
	var pos: Vector2 = _markers.get(warp_id, Vector2.ZERO)
	var warp := WarpScene.instantiate()
	entities.add_child(warp)
	warp.global_position = pos
	warp.setup(warp_id)
	warp.warp_menu_requested.connect(_on_warp_menu)
	_warps[warp_id] = warp
	if RunSession.is_warp_active(warp_id):
		warp.set_activated(true)
	else:
		var gdef: Dictionary = RegionCatalog.GUARDS[warp_id].duplicate()
		_spawn_enemy_at(pos + Vector2(36, 0), gdef)


func _spawn_region_resources(rid: String) -> void:
	var forage: Dictionary = RegionCatalog.FORAGE[rid]
	var ore: Dictionary = RegionCatalog.ORE[rid]
	for p in _markers.get("forage_%s" % rid, []):
		_spawn_resource(p, str(forage.mat), "hud.interact_forage", str(forage.icon))
	for p2 in _markers.get("ore_%s" % rid, []):
		_spawn_resource(p2, str(ore.mat), "hud.interact_ore", str(ore.icon))


func _spawn_region_mobs(rid: String) -> void:
	var pool: Array = RegionCatalog.ENEMY_POOL[rid]
	var pts: Array = _markers.get("mobs_%s" % rid, [])
	for i in pts.size():
		var def: Dictionary = pool[i % pool.size()].duplicate()
		_spawn_enemy_at(pts[i], def)


func _spawn_enemy_at(pos: Vector2, def: Dictionary) -> void:
	var e := EnemyScene.instantiate()
	entities.add_child(e)
	e.global_position = pos
	e.configure(def)
	if e.has_signal("died_with_id") and not e.died_with_id.is_connected(_on_enemy_killed):
		e.died_with_id.connect(_on_enemy_killed)


func _spawn_resource(pos: Vector2, mat_id: String, prompt: String, icon: String) -> void:
	var node := ResourceScene.instantiate()
	entities.add_child(node)
	node.global_position = pos
	node.configure(0, mat_id, 1, prompt)
	if node.has_node("Sprite") and ResourceLoader.exists(icon):
		node.get_node("Sprite").texture = load(icon)


func on_warp_guard_killed(warp_id: String) -> void:
	if _warps.has(warp_id):
		_warps[warp_id].set_activated(true)
	if player:
		player.show_toast(
			Loc.t("warp.unlocked", [Loc.t("warp.%s" % warp_id)]),
			PitEventLog.Category.SYSTEM
		)


func _on_enemy_killed(enemy_id: String, meta: Dictionary) -> void:
	var display := EnemyCatalog.display_name(enemy_id)
	var text: String = Loc.t("feed.kill", [display])
	var category := PitEventLog.Category.KILL
	if bool(meta.get("is_boss", false)):
		text = Loc.t("feed.kill_boss", [display])
	elif enemy_id.begins_with("elite_") or enemy_id.begins_with("guard_"):
		text = Loc.t("feed.kill_elite", [display])
	_push_feed(text, category)
	_update_quest_hud()


func _update_exploration() -> void:
	_reveal_around(player.global_position)
	var g := Floor1Generator.world_to_tile(player.global_position)
	var rid := str(_region_of.get(g, ""))
	if rid == RegionCatalog.REGION_SPAWN:
		rid = RegionCatalog.REGION_A
	if rid != "" and rid != _current_region:
		_current_region = rid
		_show_region_banner(rid)
		_update_hud()
		_minimap_dirty = true
	_flush_minimap_if_needed(g)


func _reveal_around(pos: Vector2) -> void:
	var g := Floor1Generator.world_to_tile(pos)
	var chunk := Floor1Generator.chunk_of_tile(g)
	var radius := 1 + MetaProgress.spotlight_level
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			_reveal_chunk(chunk + Vector2i(ox, oy))


func _reveal_chunk(ck: Vector2i) -> void:
	var max_cx := ceili(float(Floor1Generator.MAP_W) / float(Floor1Generator.CHUNK))
	var max_cy := ceili(float(Floor1Generator.MAP_H) / float(Floor1Generator.CHUNK))
	if ck.x < 0 or ck.y < 0 or ck.x >= max_cx or ck.y >= max_cy:
		return
	if _explored_chunks.has(ck):
		return
	_explored_chunks[ck] = true
	if _fog_chunks.has(ck):
		var fog: Polygon2D = _fog_chunks[ck]
		_fog_chunks.erase(ck)
		if is_instance_valid(fog):
			fog.queue_free()
	_minimap_dirty = true


func _flush_minimap_if_needed(player_tile: Vector2i) -> void:
	if not _minimap_dirty and player_tile == _last_minimap_tile:
		return
	_last_minimap_tile = player_tile
	_minimap_dirty = false
	_refresh_minimap()


func _show_region_banner(rid: String) -> void:
	if not hud.has_node("RegionBanner"):
		return
	var banner: Label = hud.get_node("RegionBanner")
	banner.text = Loc.t("hud.region_enter", [RegionCatalog.display_name(rid)])
	banner.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)


func _setup_hud() -> void:
	if hud.has_node("TopLeft/HintLabel"):
		hud.get_node("TopLeft/HintLabel").text = Loc.t("hint.pit_floor")
	elif hud.has_node("HintLabel"):
		hud.get_node("HintLabel").text = Loc.t("hint.pit_floor")
	if hud.has_node("BagBtn"):
		hud.get_node("BagBtn").text = Loc.t("hud.bag_btn")
	_ensure_sheet_host()
	if sheet_host and player:
		sheet_host.bind_player(player, false)
	if player and not player.hp_changed.is_connected(_on_player_hp_changed):
		player.hp_changed.connect(_on_player_hp_changed)
	if player and player.inventory and not player.inventory.changed.is_connected(_on_inventory_changed):
		player.inventory.changed.connect(_on_inventory_changed)
	if player and player.skills and not player.skills.changed.is_connected(_on_skills_changed):
		player.skills.changed.connect(_on_skills_changed)
	if player and not player.interact_prompt_changed.is_connected(_on_interact_prompt_changed):
		player.interact_prompt_changed.connect(_on_interact_prompt_changed)
	if not MetaProgress.changed.is_connected(_on_meta_progress_changed):
		MetaProgress.changed.connect(_on_meta_progress_changed)
	_ensure_runtime_hud()
	_update_hud()
	_on_interact_prompt_changed(player.get_interact_prompt())


func _on_inventory_changed() -> void:
	if sheet_host and sheet_host.bag_panel and sheet_host.bag_panel.visible:
		sheet_host.bag_panel.refresh()
	_update_hud()


func _on_skills_changed() -> void:
	if sheet_host and sheet_host.skills_panel and sheet_host.skills_panel.visible:
		sheet_host.skills_panel.refresh()
	if sheet_host and sheet_host.stats_panel and sheet_host.stats_panel.visible:
		sheet_host.stats_panel.refresh()
	_update_hud()


func _on_player_hp_changed(_current: float, _maximum: float) -> void:
	_update_hud()


func _on_meta_progress_changed() -> void:
	_update_hud()


func _on_interact_prompt_changed(text: String) -> void:
	if hud.has_node("PromptLabel"):
		hud.get_node("PromptLabel").text = text


func _wire_bag_ui() -> void:
	if hud.has_node("BagBtn") and not hud.get_node("BagBtn").pressed.is_connected(_toggle_bag):
		hud.get_node("BagBtn").pressed.connect(_toggle_bag)


func _toggle_bag() -> void:
	if sheet_host:
		sheet_host.toggle_bag()


func _on_death_hover(_index: int, tip: String) -> void:
	if death_ui.has_node("Panel/Tooltip"):
		death_ui.get_node("Panel/Tooltip").text = tip


func _wire_quest_ui() -> void:
	if hud.has_node("QuestBtn"):
		var btn: Button = hud.get_node("QuestBtn")
		btn.text = Loc.t("hud.quest_btn")
		if not btn.pressed.is_connected(_toggle_quest_panel):
			btn.pressed.connect(_toggle_quest_panel)
	if hud.has_node("QuestPanel/CloseBtn"):
		var close: Button = hud.get_node("QuestPanel/CloseBtn")
		close.text = Loc.t("hub.close")
		if not close.pressed.is_connected(_close_quest_panel):
			close.pressed.connect(_close_quest_panel)
	if hud.has_node("QuestPanel/Title"):
		hud.get_node("QuestPanel/Title").text = Loc.t("hud.quest_panel_title")
	_update_quest_hud()


func _toggle_quest_panel() -> void:
	_quest_open = not _quest_open
	if hud.has_node("QuestPanel"):
		hud.get_node("QuestPanel").visible = _quest_open
	if _quest_open:
		_refresh_quest_panel()


func _close_quest_panel() -> void:
	_quest_open = false
	if hud.has_node("QuestPanel"):
		hud.get_node("QuestPanel").visible = false


func _quest_progress() -> Dictionary:
	var slots: Array = player.inventory.slots if player else []
	return QuestDefs.run_progress(RunSession.quest_id_snapshot, slots, RunSession.kill_scale, RunSession.rescue_done)


func _update_quest_hud() -> void:
	var info: Dictionary = _quest_progress()
	if hud.has_node("QuestSummary"):
		if info.is_empty():
			hud.get_node("QuestSummary").text = Loc.t("hud.quest_none")
		else:
			var line: String = Loc.t("hud.quest_progress", [str(info.get("name")), str(info.get("progress_text"))])
			if bool(info.get("complete", false)):
				line += " " + Loc.t("hud.quest_done")
			hud.get_node("QuestSummary").text = line
	if _quest_open:
		_refresh_quest_panel()


func _refresh_quest_panel() -> void:
	if not hud.has_node("QuestPanel/Body"):
		return
	var body: Label = hud.get_node("QuestPanel/Body")
	var info: Dictionary = _quest_progress()
	if info.is_empty():
		body.text = Loc.t("hud.quest_none_detail")
		return
	var mats: Dictionary = info.get("reward_mat", {})
	var mat_parts: PackedStringArray = []
	for mid in mats.keys():
		mat_parts.append("%s x%d" % [MaterialCatalog.display_name(str(mid)), int(mats[mid])])
	var mat_text: String = Loc.t("quest.reward_mats_none") if mat_parts.is_empty() else ", ".join(mat_parts)
	var reward: String = Loc.t("quest.reward", [int(info.get("reward_gold", 0)), mat_text])
	var done_mark: String = " " + Loc.t("hud.quest_done") if bool(info.get("complete", false)) else ""
	body.text = Loc.t("hud.quest_detail", [
		str(info.get("name")), str(info.get("progress_text")), done_mark, str(info.get("desc")), reward,
	])


func _wire_warp_ui() -> void:
	if hud.has_node("WarpPanel/CloseBtn"):
		var btn: Button = hud.get_node("WarpPanel/CloseBtn")
		if not btn.pressed.is_connected(_close_warp_menu):
			btn.pressed.connect(_close_warp_menu)


func _on_warp_menu(from_id: String, _by: Node) -> void:
	_warp_menu_from = from_id
	if not hud.has_node("WarpPanel"):
		## 无面板则直接找另一点
		_warp_to_other(from_id)
		return
	var panel: Panel = hud.get_node("WarpPanel")
	panel.visible = true
	if hud.has_node("WarpPanel/Title"):
		hud.get_node("WarpPanel/Title").text = Loc.t("warp.menu_title")
	var list: VBoxContainer = hud.get_node("WarpPanel/List")
	for c in list.get_children():
		c.queue_free()
	var cost := MetaProgress.WARP_COST_TRAVEL
	var afford := MetaProgress.can_afford_mind(cost)
	if hud.has_node("WarpPanel/Hint"):
		hud.get_node("WarpPanel/Hint").text = Loc.t("warp.menu_hint", [cost, MetaProgress.mind_value])
	for wid in ["warp_a", "warp_b", "warp_c"]:
		if wid == from_id:
			continue
		if not RunSession.is_warp_active(wid):
			continue
		var b := Button.new()
		b.text = Loc.t("warp.travel_to", [Loc.t("warp.%s" % wid)])
		b.disabled = not afford
		var captured: String = str(wid)
		b.pressed.connect(func(): _confirm_warp_travel(captured))
		list.add_child(b)
	if list.get_child_count() == 0:
		var tip := Label.new()
		tip.text = Loc.t("warp.no_other")
		list.add_child(tip)


func _confirm_warp_travel(to_id: String) -> void:
	if not MetaProgress.consume_mind_value(MetaProgress.WARP_COST_TRAVEL):
		if player:
			player.show_toast(Loc.t("warp.no_mind"), PitEventLog.Category.WARN)
		_close_warp_menu()
		return
	if _markers.has(to_id) and player:
		player.global_position = _markers[to_id]
		_reveal_around(player.global_position)
		_minimap_dirty = true
		_last_minimap_tile = Vector2i(-99999, -99999)
		_flush_minimap_if_needed(Floor1Generator.world_to_tile(player.global_position))
		player.show_toast(Loc.t("warp.traveled", [Loc.t("warp.%s" % to_id)]), PitEventLog.Category.SYSTEM)
	_close_warp_menu()


func _warp_to_other(from_id: String) -> void:
	for wid in ["warp_a", "warp_b", "warp_c"]:
		if wid == from_id:
			continue
		if RunSession.is_warp_active(wid):
			_confirm_warp_travel(wid)
			return
	if player:
		player.show_toast(Loc.t("warp.no_other"), PitEventLog.Category.WARN)


func _close_warp_menu() -> void:
	_warp_menu_from = ""
	if hud.has_node("WarpPanel"):
		hud.get_node("WarpPanel").visible = false


func _setup_minimap() -> void:
	if not hud.has_node("Minimap"):
		return
	var mm = hud.get_node("Minimap")
	if mm.has_method("setup_floor1"):
		mm.setup_floor1(_map, _explored_chunks)
	_refresh_minimap()


func _refresh_minimap() -> void:
	if not hud.has_node("Minimap"):
		return
	var mm = hud.get_node("Minimap")
	var pos := player.global_position if player else Vector2.ZERO
	if mm.has_method("update_floor1"):
		mm.update_floor1(_explored_chunks, pos, _current_region)
	elif mm.has_method("refresh"):
		mm.refresh()


func _update_hud() -> void:
	if player == null:
		return
	var mind_txt: String = Loc.t("hud.mind", [MetaProgress.mind_level])
	var value_txt: String = Loc.t("hud.mind_value", [MetaProgress.mind_value])
	var special_txt: String = Loc.t("hud.special_mind_yes") if RunSession.special_mind else Loc.t("hud.special_mind_no")
	var mind_line := "%s | %s | %s" % [mind_txt, value_txt, special_txt]
	if _skill_bar:
		if _skill_bar.has_method("set_vitals"):
			_skill_bar.set_vitals(player.hp, player.max_hp)
		if _skill_bar.has_method("set_erosion"):
			_skill_bar.set_erosion(erosion.value, ErosionSystem.MAX_VALUE, erosion.tier)
		if _skill_bar.has_method("set_xp"):
			_skill_bar.set_xp(MetaProgress.explorer_level, MetaProgress.explorer_xp, MetaProgress.xp_to_next_level())
		if _skill_bar.has_method("set_mind_line"):
			_skill_bar.set_mind_line(mind_line)
	if hud.has_node("StatsBar/HpBarBg/HpBarFill"):
		var fill: ColorRect = hud.get_node("StatsBar/HpBarBg/HpBarFill")
		var bg: ColorRect = hud.get_node("StatsBar/HpBarBg")
		var ratio := clampf(player.hp / player.max_hp, 0.0, 1.0) if player.max_hp > 0.0 else 0.0
		fill.size.x = bg.size.x * ratio
	elif hud.has_node("HpBarBg/HpBarFill"):
		var fill: ColorRect = hud.get_node("HpBarBg/HpBarFill")
		var bg: ColorRect = hud.get_node("HpBarBg")
		var ratio := clampf(player.hp / player.max_hp, 0.0, 1.0) if player.max_hp > 0.0 else 0.0
		fill.size.x = bg.size.x * ratio
	if hud.has_node("StatsBar/HpText"):
		hud.get_node("StatsBar/HpText").text = Loc.t("hud.hp", [int(round(player.hp)), int(round(player.max_hp))])
	if hud.has_node("StatsBar/AttrText"):
		hud.get_node("StatsBar/AttrText").text = mind_line
	if hud.has_node("BagCountLabel"):
		hud.get_node("BagCountLabel").text = Loc.t("hud.bag", [player.inventory.used_count(), player.inventory.max_slots()])
	if hud.has_node("SkillsHudLabel"):
		hud.get_node("SkillsHudLabel").visible = false
	var bname: String = Loc.t(str(MindTable.BRAND_STATS[RunSession.brand_quality].get("name_key", "brand.iron")))
	var rname := RegionCatalog.display_name(_current_region) if _current_region != "" else "—"
	if hud.has_node("TopLeft/FloorLabel"):
		hud.get_node("TopLeft/FloorLabel").text = "%s | %s | %s" % [
			Loc.t("hud.floor", [1]),
			Loc.t("hud.region", [rname]),
			Loc.t("hud.brand", [bname]),
		]
	elif hud.has_node("FloorLabel"):
		hud.get_node("FloorLabel").text = "%s | %s | %s" % [
			Loc.t("hud.floor", [1]),
			Loc.t("hud.region", [rname]),
			Loc.t("hud.brand", [bname]),
		]
	_update_quest_hud()
	if hud.has_node("TopLeft/XpLabel"):
		hud.get_node("TopLeft/XpLabel").visible = false


func _ensure_runtime_hud() -> void:
	if hud and hud.has_node("StatsBar"):
		hud.get_node("StatsBar").visible = false
	if hud and hud.has_node("SkillsHudLabel"):
		hud.get_node("SkillsHudLabel").visible = false
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
	if hud.has_node("TopLeft/XpLabel"):
		hud.get_node("TopLeft/XpLabel").visible = false


func _region_biome(rid: String) -> String:
	match rid:
		RegionCatalog.REGION_B:
			return ST.BIOME_COPPER
		RegionCatalog.REGION_C, RegionCatalog.REGION_BOSS:
			return ST.BIOME_ECHO
		_:
			return ST.BIOME_MOSS


func _apply_biome_runtime() -> void:
	if player == null or biome_rules == null:
		return
	var biome := _region_biome(_current_region)
	biome_rules.set_biome(biome)
	if _atmosphere and _atmosphere.has_method("set_biome"):
		_atmosphere.call("set_biome", biome)
	var in_mud := biome == ST.BIOME_MOSS and fmod(player.global_position.x + player.global_position.y, 96.0) < 30.0
	var in_fog := biome == ST.BIOME_MOSS
	biome_rules.apply_to_player(player, in_mud, in_fog)
	player.move_speed_mult *= erosion.move_mult()
	if erosion.skill_slots_locked() > 0:
		var locked := str(player.get("_locked_skill_slot"))
		if locked == "":
			for slot in CrystalCatalog.HOTKEY_SLOTS:
				if MetaProgress.skill_in_slot(slot) != "":
					player.set_erosion_locked_slot(slot)
					break
	else:
		player.set_erosion_locked_slot("")


func _on_loud_skill(kind: String) -> void:
	if biome_rules:
		biome_rules.on_loud_skill(player, kind)


func _on_reinforcement(at: Vector2, _biome: String) -> void:
	var rid := _current_region if _current_region != "" else RegionCatalog.REGION_A
	var pool: Array = RegionCatalog.ENEMY_POOL.get(rid, RegionCatalog.ENEMY_POOL[RegionCatalog.REGION_A])
	if pool.is_empty():
		return
	var def: Dictionary = pool[randi() % pool.size()].duplicate()
	_spawn_enemy_at(at + Vector2(randf_range(-40, 40), randf_range(-40, 40)), def)
	if player:
		player.show_toast(Loc.t("toast.echo_reinforce"), PitEventLog.Category.WARN)


func _on_erosion_value(value: float, max_value: float) -> void:
	if _skill_bar and _skill_bar.has_method("set_erosion"):
		_skill_bar.set_erosion(value, max_value, erosion.tier)


func _on_erosion_tier(tier: int) -> void:
	if player:
		player.show_toast(Loc.t("toast.erosion_tier", [tier]), PitEventLog.Category.SYSTEM)


func _on_extract(_by: Node) -> void:
	_finish_success()


func _on_player_died() -> void:
	_show_death_keep()


func _on_toast(text: String, category: int = PitEventLog.Category.SYSTEM, color: Color = Color.TRANSPARENT) -> void:
	_push_feed(text, category, color)
	_update_quest_hud()


func _push_feed(text: String, category: int = PitEventLog.Category.SYSTEM, color: Color = Color.TRANSPARENT) -> void:
	if hud.has_node("EventLog") and hud.get_node("EventLog").has_method("push"):
		hud.get_node("EventLog").push(text, category, color)


func _finish_success() -> void:
	if _run_over:
		return
	_run_over = true
	if player:
		player.input_locked = true
	var q := MetaProgress.complete_quest_if_able({
		"inventory_slots": player.inventory.slots,
		"kill_scale": RunSession.kill_scale,
		"rescue_done": RunSession.rescue_done,
	})
	MetaProgress.merge_inventory_into_stash(player.inventory.slots)
	MetaProgress.add_intel(Loc.t("intel.floor_cleared", [1]))
	extract_ui.visible = true
	var title: Label = extract_ui.get_node("Panel/Title")
	var body: Label = extract_ui.get_node("Panel/Body")
	title.text = Loc.t("extract.title")
	var lines: PackedStringArray = []
	lines.append(Loc.t("extract.materials"))
	var mats: PackedStringArray = player.inventory.describe_contents()
	lines.append_array(mats if not mats.is_empty() else PackedStringArray([Loc.t("extract.empty")]))
	lines.append("")
	lines.append(Loc.t("extract.brand_lost"))
	if RunSession.special_mind:
		lines.append(Loc.t("extract.special_mind_lost"))
	if q == "ok":
		lines.append(Loc.t("extract.quest_ok"))
	elif RunSession.quest_id_snapshot != "" and q != "ok":
		MetaProgress.fail_quest()
		lines.append(Loc.t("extract.quest_fail"))
	body.text = "\n".join(lines)
	player.inventory.clear()
	RunSession.clear()


func _wire_death_ui() -> void:
	if _death_wired:
		return
	if not death_ui.has_node("Panel/ConfirmButton"):
		return
	_death_wired = true
	death_ui.get_node("Panel/ConfirmButton").text = Loc.t("extract.confirm_keep")
	death_ui.get_node("Panel/ConfirmButton").pressed.connect(_confirm_death_keep)
	if death_ui.has_node("Panel/DeathGrid"):
		var grid = death_ui.get_node("Panel/DeathGrid")
		if grid.has_signal("slot_pressed"):
			grid.slot_pressed.connect(_select_death_slot)
		if grid.has_signal("slot_hovered") and not grid.slot_hovered.is_connected(_on_death_hover):
			grid.slot_hovered.connect(_on_death_hover)
	if extract_ui.has_node("Panel/RetryButton"):
		extract_ui.get_node("Panel/RetryButton").pressed.connect(_back_to_hub)


func _show_death_keep() -> void:
	if _run_over:
		return
	_run_over = true
	MetaProgress.apply_death_wear()
	if RunSession.quest_id_snapshot != "":
		MetaProgress.fail_quest()
	death_ui.visible = true
	death_ui.get_node("Panel/Title").text = Loc.t("extract.fail_title")
	death_ui.get_node("Panel/Hint").text = Loc.t("extract.keep_one")
	_death_selected = -1
	if death_ui.has_node("Panel/Tooltip"):
		death_ui.get_node("Panel/Tooltip").text = ""
	if death_ui.has_node("Panel/DeathGrid") and player:
		var grid = death_ui.get_node("Panel/DeathGrid")
		if grid.has_method("set_inventory_entries"):
			grid.set_inventory_entries(player.inventory.slots)
			if grid.get("selectable") != null:
				grid.selectable = true


func _select_death_slot(index: int) -> void:
	_death_selected = index


func _confirm_death_keep() -> void:
	var kept: Array = []
	if player and _death_selected >= 0 and _death_selected < player.inventory.slots.size():
		kept.append(player.inventory.slots[_death_selected].duplicate(true))
	MetaProgress.merge_inventory_into_stash(kept)
	if player:
		player.inventory.clear()
	RunSession.clear()
	_back_to_hub()


func _back_to_hub() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/crane_hub.tscn")
