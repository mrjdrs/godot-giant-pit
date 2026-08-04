extends Node2D
## 第 1 层大地图运行时：三区域 + 迷雾 + 传送/精英/BOSS。

const Floor1Generator = preload("res://scripts/pit/floor1_generator.gd")
const RegionCatalog = preload("res://scripts/pit/region_catalog.gd")
const QuestDefs = preload("res://scripts/meta/quest_defs.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")

const PlayerScene = preload("res://scenes/player/player.tscn")
const EnemyScene = preload("res://scenes/enemy/pit_enemy.tscn")
const ExtractScene = preload("res://scenes/pit/extract_beacon.tscn")
const DescentScene = preload("res://scenes/pit/descent_beacon.tscn")
const DistressScene = preload("res://scenes/pit/distress_beacon.tscn")
const ResourceScene = preload("res://scenes/pit/resource_node.tscn")
const WarpScene = preload("res://scenes/pit/warp_beacon.tscn")

@onready var world: Node2D = $World
@onready var rooms_root: Node2D = $World/Rooms
@onready var entities: Node2D = $World/Entities
@onready var fog_root: Node2D = $World/Fog
@onready var hud: CanvasLayer = $HUD
@onready var extract_ui: CanvasLayer = $ExtractUI
@onready var death_ui: CanvasLayer = $DeathUI

var player: CharacterBody2D = null
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
var _bag_open: bool = false
var _quest_open: bool = false
var _warp_menu_from: String = ""


func _ready() -> void:
	add_to_group("pit_floor")
	if not RunSession.active:
		RunSession.begin_run()
	extract_ui.visible = false
	death_ui.visible = false
	if hud.has_node("BagPanel"):
		hud.get_node("BagPanel").visible = false
	if hud.has_node("RuneReplace"):
		hud.get_node("RuneReplace").visible = false
	if hud.has_node("QuestPanel"):
		hud.get_node("QuestPanel").visible = false
	if hud.has_node("WarpPanel"):
		hud.get_node("WarpPanel").visible = false
	if hud.has_node("RegionBanner"):
		hud.get_node("RegionBanner").modulate.a = 0.0
	AudioManager.play_bgm()
	call_deferred("_deferred_boot")


func _deferred_boot() -> void:
	_build_floor_level()
	_wire_death_ui()
	_wire_bag_ui()
	_wire_rune_replace_ui()
	_wire_quest_ui()
	_wire_warp_ui()
	extract_ui.get_node("Panel/RetryButton").text = Loc.t("extract.back_hub")
	extract_ui.get_node("Panel/ArenaButton").visible = false


func _process(_delta: float) -> void:
	if player == null or _run_over:
		return
	_update_exploration()
	_update_hud()


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
		_toggle_bag()
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
	## 按区域大块铺地（性能）
	var bounds: Dictionary = _map.get("region_bounds", {})
	for rid in bounds.keys():
		var rect: Rect2i = bounds[rid]
		var floors: Array = RegionCatalog.FLOOR_TILES.get(rid, RegionCatalog.FLOOR_TILES[RegionCatalog.REGION_A])
		var tex_path: String = str(floors[0])
		var tex: Texture2D = load(tex_path)
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.centered = false
		s.position = Vector2(rect.position.x * tile, rect.position.y * tile)
		s.scale = Vector2(float(rect.size.x * tile) / float(tex.get_width()), float(rect.size.y * tile) / float(tex.get_height()))
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

	## 墙：不可走邻接
	var dirs := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var wall_done: Dictionary = {}
	for g in _walkable.keys():
		for d in dirs:
			var n: Vector2i = g + d
			if _walkable.has(n):
				continue
			if wall_done.has(n):
				continue
			wall_done[n] = true
			var rid2 := str(_region_of.get(g, RegionCatalog.REGION_A))
			var wpath: String = str(RegionCatalog.WALL_TILES.get(rid2, "res://assets/tiles/pit_wall/tile_wall.png"))
			_make_wall_tile(walls, n, tile, wpath)


func _make_wall_tile(parent: Node2D, g: Vector2i, tile: int, tex_path: String) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2((g.x + 0.5) * tile, (g.y + 0.5) * tile)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tile, tile)
	shape.shape = rect
	body.add_child(shape)
	var spr := Sprite2D.new()
	if ResourceLoader.exists(tex_path):
		spr.texture = load(tex_path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(spr)
	parent.add_child(body)


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
	player.combat_enabled = true
	player.apply_meta_loadout(RunSession.brand_quality)
	player.died.connect(_on_player_died)
	player.toast.connect(_on_toast)
	if not player.rune_replace_requested.is_connected(_on_rune_replace_requested):
		player.rune_replace_requested.connect(_on_rune_replace_requested)
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
	var text := Loc.t("feed.kill", [display])
	var category := PitEventLog.Category.KILL
	if bool(meta.get("is_boss", false)):
		text = Loc.t("feed.kill_boss", [display])
	elif enemy_id.begins_with("elite_") or enemy_id.begins_with("guard_"):
		text = Loc.t("feed.kill_elite", [display])
	_push_feed(text, category)


func _update_exploration() -> void:
	_reveal_around(player.global_position)
	var g := Floor1Generator.world_to_tile(player.global_position)
	var rid := str(_region_of.get(g, ""))
	if rid == RegionCatalog.REGION_SPAWN:
		rid = RegionCatalog.REGION_A
	if rid != "" and rid != _current_region:
		_current_region = rid
		_show_region_banner(rid)
		_refresh_minimap()


func _reveal_around(pos: Vector2) -> void:
	var g := Floor1Generator.world_to_tile(pos)
	var chunk := Floor1Generator.chunk_of_tile(g)
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			_reveal_chunk(chunk + Vector2i(ox, oy))


func _reveal_chunk(ck: Vector2i) -> void:
	if _explored_chunks.has(ck):
		return
	_explored_chunks[ck] = true
	if _fog_chunks.has(ck):
		var fog: Polygon2D = _fog_chunks[ck]
		var tw := create_tween()
		tw.tween_property(fog, "modulate:a", 0.0, 0.2)
		tw.finished.connect(func():
			if is_instance_valid(fog):
				fog.visible = false
		)
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
	if player and player.inventory and not player.inventory.changed.is_connected(_on_inventory_changed):
		player.inventory.changed.connect(_on_inventory_changed)
	if player and player.runes and not player.runes.changed.is_connected(_on_runes_changed):
		player.runes.changed.connect(_on_runes_changed)
	_refresh_bag_grid()
	_update_hud()


func _on_inventory_changed() -> void:
	_refresh_bag_grid()
	_update_hud()


func _on_runes_changed() -> void:
	_update_hud()


func _refresh_bag_grid() -> void:
	if player == null:
		return
	if not hud.has_node("BagPanel/BagGrid"):
		return
	var grid = hud.get_node("BagPanel/BagGrid")
	if grid.has_method("set_inventory_entries"):
		grid.set_inventory_entries(player.inventory.slots)


func _wire_bag_ui() -> void:
	if hud.has_node("BagBtn") and not hud.get_node("BagBtn").pressed.is_connected(_toggle_bag):
		hud.get_node("BagBtn").pressed.connect(_toggle_bag)
	if hud.has_node("BagPanel/CloseBtn"):
		var close: Button = hud.get_node("BagPanel/CloseBtn")
		close.text = Loc.t("hud.bag_close")
		if not close.pressed.is_connected(_close_bag):
			close.pressed.connect(_close_bag)
	if hud.has_node("BagPanel/Title"):
		hud.get_node("BagPanel/Title").text = Loc.t("hud.bag_title")
	if hud.has_node("BagPanel/BagGrid"):
		var grid = hud.get_node("BagPanel/BagGrid")
		if grid.has_signal("slot_hovered") and not grid.slot_hovered.is_connected(_on_bag_hover):
			grid.slot_hovered.connect(_on_bag_hover)


func _toggle_bag() -> void:
	_bag_open = not _bag_open
	if hud.has_node("BagPanel"):
		hud.get_node("BagPanel").visible = _bag_open
	if _bag_open:
		_refresh_bag_grid()


func _close_bag() -> void:
	_bag_open = false
	if hud.has_node("BagPanel"):
		hud.get_node("BagPanel").visible = false


func _on_bag_hover(_index: int, tip: String) -> void:
	if hud.has_node("BagPanel/Tooltip"):
		hud.get_node("BagPanel/Tooltip").text = tip


func _on_death_hover(_index: int, tip: String) -> void:
	if death_ui.has_node("Panel/Tooltip"):
		death_ui.get_node("Panel/Tooltip").text = tip


func _wire_rune_replace_ui() -> void:
	if hud.has_node("RuneReplace/CancelBtn"):
		var btn: Button = hud.get_node("RuneReplace/CancelBtn")
		if not btn.pressed.is_connected(_cancel_rune_replace):
			btn.pressed.connect(_cancel_rune_replace)
	if hud.has_node("RuneReplace/Title"):
		hud.get_node("RuneReplace/Title").text = Loc.t("rune.replace_title")


func _on_rune_replace_requested(rune_id: String, candidates: Array) -> void:
	if not hud.has_node("RuneReplace"):
		return
	var panel: Panel = hud.get_node("RuneReplace")
	panel.visible = true
	if hud.has_node("RuneReplace/Hint"):
		hud.get_node("RuneReplace/Hint").text = Loc.t("rune.replace_hint") + " → " + Loc.t("rune.%s" % rune_id)
	var list: VBoxContainer = hud.get_node("RuneReplace/List")
	for c in list.get_children():
		c.queue_free()
	const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
	for cid in candidates:
		var id_str := str(cid)
		var b := Button.new()
		var rank: int = int(player.runes.get_rank(id_str))
		var effect_key := "rune.%s.effect" % id_str
		var effect := Loc.t(effect_key) if Loc.has_key(effect_key) else ""
		b.text = "%s %d阶 — %s" % [RuneCatalog.display_name(id_str), rank, effect]
		var captured: String = id_str
		b.pressed.connect(func(): _confirm_rune_replace(captured))
		list.add_child(b)


func _confirm_rune_replace(old_id: String) -> void:
	if player:
		player.confirm_rune_replace(old_id)
	if hud.has_node("RuneReplace"):
		hud.get_node("RuneReplace").visible = false


func _cancel_rune_replace() -> void:
	if player:
		player.cancel_rune_replace()
	if hud.has_node("RuneReplace"):
		hud.get_node("RuneReplace").visible = false


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
			var line := Loc.t("hud.quest_progress", [str(info.get("name")), str(info.get("progress_text"))])
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
	var mat_text := Loc.t("quest.reward_mats_none") if mat_parts.is_empty() else ", ".join(mat_parts)
	var reward := Loc.t("quest.reward", [int(info.get("reward_gold", 0)), mat_text])
	var done_mark := " " + Loc.t("hud.quest_done") if bool(info.get("complete", false)) else ""
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
		var mind_txt := Loc.t("hud.mind", [MetaProgress.mind_level])
		var value_txt := Loc.t("hud.mind_value", [MetaProgress.mind_value])
		var special_txt := Loc.t("hud.special_mind_yes") if RunSession.special_mind else Loc.t("hud.special_mind_no")
		hud.get_node("StatsBar/AttrText").text = "%s | %s | %s" % [mind_txt, value_txt, special_txt]
	if hud.has_node("BagCountLabel"):
		hud.get_node("BagCountLabel").text = Loc.t("hud.bag", [player.inventory.used_count(), player.inventory.MAX_SLOTS])
	var rune_lines: PackedStringArray = player.runes.describe()
	var rune_text := Loc.t("hud.runes_none") if rune_lines.is_empty() else "\n".join(rune_lines)
	if hud.has_node("RunePanel/RuneScroll/RuneLabel"):
		hud.get_node("RunePanel/RuneScroll/RuneLabel").text = rune_text
		if hud.has_node("RunePanel/RuneTitle"):
			hud.get_node("RunePanel/RuneTitle").text = Loc.t("hud.runes")
	elif hud.has_node("RuneLabel"):
		hud.get_node("RuneLabel").text = Loc.t("hud.runes") + "：\n" + rune_text
	hud.get_node("PromptLabel").text = player.get_interact_prompt()
	var bname := Loc.t(str(MindTable.BRAND_STATS[RunSession.brand_quality].get("name_key", "brand.iron")))
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
	_refresh_minimap()


func _on_extract(_by: Node) -> void:
	_finish_success()


func _on_player_died() -> void:
	_show_death_keep()


func _on_toast(text: String, category: int = PitEventLog.Category.SYSTEM, color: Color = Color.TRANSPARENT) -> void:
	_push_feed(text, category, color)


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
	lines.append(Loc.t("extract.runes_lost"))
	if RunSession.special_mind:
		lines.append(Loc.t("extract.special_mind_lost"))
	if q == "ok":
		lines.append(Loc.t("extract.quest_ok"))
	elif RunSession.quest_id_snapshot != "" and q != "ok":
		MetaProgress.fail_quest()
		lines.append(Loc.t("extract.quest_fail"))
	body.text = "\n".join(lines)
	player.inventory.clear()
	player.runes.clear()
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
		player.runes.clear()
	RunSession.clear()
	_back_to_hub()


func _back_to_hub() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/crane_hub.tscn")
