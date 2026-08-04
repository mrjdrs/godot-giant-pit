extends Node2D
## 阶段 C：多层巨坑运行时场景。

const PitGenerator = preload("res://scripts/pit/pit_generator.gd")
const RoomData = preload("res://scripts/pit/room_data.gd")
const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")

const PlayerScene = preload("res://scenes/player/player.tscn")
const EnemyScene = preload("res://scenes/enemy/pit_enemy.tscn")
const ScaleRockScene = preload("res://scenes/enemy/scale_rock.tscn")
const ExtractScene = preload("res://scenes/pit/extract_beacon.tscn")
const DescentScene = preload("res://scenes/pit/descent_beacon.tscn")
const DistressScene = preload("res://scenes/pit/distress_beacon.tscn")
const ResourceScene = preload("res://scenes/pit/resource_node.tscn")

const TILE := 32
const WALL_THICK := 16.0

@onready var world: Node2D = $World
@onready var rooms_root: Node2D = $World/Rooms
@onready var entities: Node2D = $World/Entities
@onready var fog_root: Node2D = $World/Fog
@onready var hud: CanvasLayer = $HUD
@onready var extract_ui: CanvasLayer = $ExtractUI
@onready var death_ui: CanvasLayer = $DeathUI

var rooms: Array = []
var player: CharacterBody2D = null
var _fog_by_room: Dictionary = {}
var _current_room_id: int = -1
var _run_over: bool = false
var _death_selected: int = -1
var _death_wired: bool = false


func _ready() -> void:
	if not RunSession.active:
		RunSession.begin_run()
	extract_ui.visible = false
	death_ui.visible = false
	call_deferred("_deferred_boot")


func _deferred_boot() -> void:
	_build_floor_level()
	_wire_death_ui()
	extract_ui.get_node("Panel/RetryButton").text = Loc.t("extract.back_hub")
	extract_ui.get_node("Panel/ArenaButton").visible = false


func _process(_delta: float) -> void:
	if player == null or _run_over:
		return
	_update_room_exploration()
	_update_hud()


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	## 调试验收快捷键（避开编辑器 F5–F8）
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
	match code:
		KEY_9:
			if player:
				_on_descent(player)
		KEY_0:
			_finish_success()
		KEY_MINUS:
			if player:
				player.inventory.add_material("deep_red_ore", 2)
				player.inventory.add_material("glow_moss", 1)
				player.input_locked = true
				call_deferred("_show_death_keep")
		KEY_EQUAL:
			var cycle := ["", "gather_ore", "kill_scale", "rescue_beacon"]
			var cur := RunSession.quest_id_snapshot
			var idx := cycle.find(cur)
			var next: String = str(cycle[(idx + 1) % cycle.size()])
			MetaProgress.active_quest_id = next
			RunSession.quest_id_snapshot = next
			RunSession.kill_scale = 0
			RunSession.rescue_done = false
			call_deferred("_rebuild_floor_safe")


func _build_floor_level() -> void:
	## 首次启动时子节点为空；下潜/重建请走 _rebuild_floor_safe
	_fog_by_room.clear()
	rooms = PitGenerator.generate(0, RunSession.floor_index)
	_build_rooms()
	_spawn_player()
	_spawn_room_contents()
	_setup_hud()


func _queue_clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _rebuild_floor_safe() -> void:
	_queue_clear(rooms_root)
	_queue_clear(entities)
	_queue_clear(fog_root)
	player = null
	await get_tree().process_frame
	_build_floor_level()


func _on_descent(_by: Node) -> void:
	if player == null:
		return
	RunSession.snapshot_player(player)
	if not RunSession.go_next_floor():
		return
	_run_over = false
	call_deferred("_rebuild_floor_safe")


func _build_rooms() -> void:
	for room in rooms:
		var room_node := Node2D.new()
		room_node.name = "Room_%d" % room.id
		room_node.position = room.rect.position
		rooms_root.add_child(room_node)
		_paint_floor(room_node, room)
		_build_walls(room_node, room)
		_build_fog(room)


func _paint_floor(room_node: Node2D, room) -> void:
	var tex: Texture2D = load("res://assets/tiles/pit_floor/tile_floor_01.png")
	var deep: Texture2D = load("res://assets/tiles/pit_floor/tile_floor_deep.png")
	var use_tex := deep if RunSession.floor_index >= 3 or room.room_type == RoomData.TYPE_ELITE or room.room_type == RoomData.TYPE_EXTRACT else tex
	## 用拉伸地砖代替逐格铺贴，加快生成
	var s := Sprite2D.new()
	s.texture = use_tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.position = Vector2.ZERO
	s.scale = room.rect.size / Vector2(float(use_tex.get_width()), float(use_tex.get_height()))
	s.z_index = -2
	room_node.add_child(s)


func _build_walls(room_node: Node2D, room) -> void:
	var size: Vector2 = room.rect.size
	var door_half := 28.0
	var connected_dirs: Dictionary = {}
	for other_id in room.connections:
		var other = rooms[other_id]
		var delta: Vector2i = other.grid - room.grid
		connected_dirs[delta] = true
	_add_wall_segment(room_node, Vector2(size.x * 0.5, 0), Vector2(size.x, WALL_THICK), connected_dirs.has(Vector2i(0, -1)), door_half, true)
	_add_wall_segment(room_node, Vector2(size.x * 0.5, size.y), Vector2(size.x, WALL_THICK), connected_dirs.has(Vector2i(0, 1)), door_half, true)
	_add_wall_segment(room_node, Vector2(0, size.y * 0.5), Vector2(WALL_THICK, size.y), connected_dirs.has(Vector2i(-1, 0)), door_half, false)
	_add_wall_segment(room_node, Vector2(size.x, size.y * 0.5), Vector2(WALL_THICK, size.y), connected_dirs.has(Vector2i(1, 0)), door_half, false)
	for other_id in room.connections:
		var other2 = rooms[other_id]
		if other2.id < room.id:
			continue
		_build_corridor(room, other2)


func _add_wall_segment(parent: Node2D, center: Vector2, full_size: Vector2, has_door: bool, door_half: float, horizontal: bool) -> void:
	if not has_door:
		_make_wall(parent, center, full_size)
		return
	if horizontal:
		var remain := (full_size.x - door_half * 2.0) * 0.5
		if remain > 4.0:
			_make_wall(parent, Vector2(center.x - door_half - remain * 0.5, center.y), Vector2(remain, full_size.y))
			_make_wall(parent, Vector2(center.x + door_half + remain * 0.5, center.y), Vector2(remain, full_size.y))
	else:
		var remain_v := (full_size.y - door_half * 2.0) * 0.5
		if remain_v > 4.0:
			_make_wall(parent, Vector2(center.x, center.y - door_half - remain_v * 0.5), Vector2(full_size.x, remain_v))
			_make_wall(parent, Vector2(center.x, center.y + door_half + remain_v * 0.5), Vector2(full_size.x, remain_v))


func _make_wall(parent: Node2D, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.color = Color(0.42, 0.325, 0.267, 1)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	visual.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	body.add_child(visual)
	parent.add_child(body)


func _build_corridor(a, b) -> void:
	var ac: Vector2 = a.center()
	var bc: Vector2 = b.center()
	var mid := (ac + bc) * 0.5
	var along := bc - ac
	var horizontal := absf(along.x) > absf(along.y)
	var corridor := Node2D.new()
	corridor.z_index = -3
	rooms_root.add_child(corridor)
	var tex: Texture2D = load("res://assets/tiles/pit_floor/tile_floor_02.png")
	if horizontal:
		var width: float = absf(along.x) - float(a.rect.size.x) * 0.5 - float(b.rect.size.x) * 0.5
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.centered = true
		s.position = mid
		s.scale = Vector2(maxf(width, 32.0) / float(tex.get_width()), 32.0 / float(tex.get_height()))
		corridor.add_child(s)
		_make_wall(corridor, Vector2(mid.x, mid.y - 24), Vector2(maxf(width, 32.0), 12.0))
		_make_wall(corridor, Vector2(mid.x, mid.y + 24), Vector2(maxf(width, 32.0), 12.0))
	else:
		var height: float = absf(along.y) - float(a.rect.size.y) * 0.5 - float(b.rect.size.y) * 0.5
		var s2 := Sprite2D.new()
		s2.texture = tex
		s2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s2.centered = true
		s2.position = mid
		s2.scale = Vector2(32.0 / float(tex.get_width()), maxf(height, 32.0) / float(tex.get_height()))
		corridor.add_child(s2)
		_make_wall(corridor, Vector2(mid.x - 24, mid.y), Vector2(12.0, maxf(height, 32.0)))
		_make_wall(corridor, Vector2(mid.x + 24, mid.y), Vector2(12.0, maxf(height, 32.0)))


func _build_fog(room) -> void:
	var poly := Polygon2D.new()
	poly.color = Color(0.05, 0.04, 0.06, 0.92)
	poly.position = room.rect.position
	poly.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(room.rect.size.x, 0),
		Vector2(room.rect.size.x, room.rect.size.y),
		Vector2(0, room.rect.size.y),
	])
	poly.z_index = 20
	poly.visible = not room.explored
	fog_root.add_child(poly)
	_fog_by_room[room.id] = poly


func _spawn_player() -> void:
	var start = rooms[0]
	for r in rooms:
		if r.room_type == RoomData.TYPE_START:
			start = r
			break
	player = PlayerScene.instantiate()
	entities.add_child(player)
	player.global_position = start.center()
	player.combat_enabled = true
	player.apply_meta_loadout(RunSession.brand_quality)
	if RunSession.floor_index > 1:
		RunSession.apply_to_player(player)
		player.hp = clampf(player.max_hp * RunSession.carried_hp_ratio, 1.0, player.max_hp)
		player.hp_changed.emit(player.hp, player.max_hp)
	player.died.connect(_on_player_died)
	player.toast.connect(_on_toast)
	_reveal_room(start)
	_current_room_id = start.id


func _floor_enemy_hp() -> float:
	return 28.0 + float(RunSession.floor_index - 1) * 12.0


func _spawn_room_contents() -> void:
	var need_scale := RunSession.quest_id_snapshot == "kill_scale" and RunSession.kill_scale < 2
	var need_rescue := RunSession.quest_id_snapshot == "rescue_beacon" and not RunSession.rescue_done
	var scale_spawned := 0
	for room in rooms:
		match room.room_type:
			RoomData.TYPE_COMBAT:
				@warning_ignore("integer_division")
				var n: int = 1 + RunSession.floor_index / 2
				_spawn_enemies(room, n, _floor_enemy_hp())
				if need_scale and scale_spawned < 2 and randf() < 0.7:
					_spawn_scale(room)
					scale_spawned += 1
			RoomData.TYPE_ELITE:
				_spawn_enemies(room, 1, _floor_enemy_hp() * 2.2, 0.75)
				_spawn_chest(room)
			RoomData.TYPE_RESOURCE:
				_spawn_resource(room, "glow_moss", "hud.interact_forage", "res://assets/tiles/pit_props/prop_forage.png")
				var ore := "deep_red_ore" if RunSession.floor_index <= 2 else "copper_vein"
				_spawn_resource(room, ore, "hud.interact_ore", "res://assets/tiles/pit_props/prop_ore_node.png", Vector2(24, 16))
				if randf() < 0.4:
					_spawn_resource(room, "mind_shard", "hud.interact_forage", "res://assets/materials/mat_mind_shard.png", Vector2(-10, 28))
			RoomData.TYPE_EXTRACT:
				_spawn_extract(room)
				if RunSession.floor_index >= 3:
					_spawn_enemies(room, 1, _floor_enemy_hp() * 1.5, 0.2)
			RoomData.TYPE_DESCENT:
				_spawn_descent(room)
			RoomData.TYPE_START:
				if need_rescue and RunSession.floor_index == 1:
					_spawn_distress(room)
	if need_scale and scale_spawned == 0:
		for room in rooms:
			if room.room_type == RoomData.TYPE_COMBAT:
				_spawn_scale(room)
				break
	if need_rescue and RunSession.floor_index > 1:
		for room in rooms:
			if room.room_type == RoomData.TYPE_RESOURCE or room.room_type == RoomData.TYPE_COMBAT:
				_spawn_distress(room)
				break


func _spawn_enemies(room, count: int, hp: float, rune_chance: float = 0.35) -> void:
	for i in count:
		var e := EnemyScene.instantiate()
		entities.add_child(e)
		e.max_hp = hp
		e.hp = hp
		e.drop_rune_chance = rune_chance
		e.global_position = room.center() + Vector2(randf_range(-40, 40), randf_range(-30, 30))


func _spawn_scale(room) -> void:
	var e := ScaleRockScene.instantiate()
	entities.add_child(e)
	e.add_to_group("scale_rock")
	e.max_hp = _floor_enemy_hp() * 1.6
	e.hp = e.max_hp
	e.global_position = room.center() + Vector2(randf_range(-20, 20), randf_range(-20, 20))


func _spawn_resource(room, mat_id: String, prompt_key: String, icon_path: String, offset: Vector2 = Vector2(-20, 10)) -> void:
	var node := ResourceScene.instantiate()
	entities.add_child(node)
	node.global_position = room.center() + offset
	node.configure(0, mat_id, 1, prompt_key)
	if node.has_node("Sprite"):
		node.get_node("Sprite").texture = load(icon_path)


func _spawn_chest(room) -> void:
	var node := ResourceScene.instantiate()
	entities.add_child(node)
	node.global_position = room.center() + Vector2(0, -20)
	var rid: String = str(RuneCatalog.DROP_POOL[randi() % RuneCatalog.DROP_POOL.size()])
	node.configure(1, rid, 1, "hud.interact_chest")
	if node.has_node("Sprite"):
		node.get_node("Sprite").texture = load("res://assets/tiles/pit_props/prop_alchem_chest.png")


func _spawn_extract(room) -> void:
	var beacon := ExtractScene.instantiate()
	entities.add_child(beacon)
	beacon.global_position = room.center()
	beacon.extract_requested.connect(_on_extract)


func _spawn_descent(room) -> void:
	var beacon := DescentScene.instantiate()
	entities.add_child(beacon)
	beacon.global_position = room.center()
	beacon.descent_requested.connect(_on_descent)


func _spawn_distress(room) -> void:
	var b := DistressScene.instantiate()
	entities.add_child(b)
	b.global_position = room.center() + Vector2(30, -10)


func _update_room_exploration() -> void:
	var pos := player.global_position
	for room in rooms:
		if room.rect.grow(8.0).has_point(pos):
			if not room.explored:
				_reveal_room(room)
			_current_room_id = room.id
			return


func _reveal_room(room) -> void:
	room.explored = true
	if _fog_by_room.has(room.id):
		var fog: Polygon2D = _fog_by_room[room.id]
		var tw := create_tween()
		tw.tween_property(fog, "modulate:a", 0.0, 0.25)
		tw.finished.connect(func():
			if is_instance_valid(fog):
				fog.visible = false
		)


func _setup_hud() -> void:
	hud.get_node("HintLabel").text = Loc.t("hint.pit_floor")
	_update_hud()


func _update_hud() -> void:
	if player == null:
		return
	hud.get_node("HpLabel").text = Loc.t("hud.hp", [int(player.hp), int(player.max_hp)])
	hud.get_node("BagLabel").text = Loc.t("hud.bag", [player.inventory.used_count(), player.inventory.MAX_SLOTS])
	var rune_lines: PackedStringArray = player.runes.describe()
	var rune_text := Loc.t("hud.runes") + "："
	rune_text += "无" if rune_lines.is_empty() else ", ".join(rune_lines)
	hud.get_node("RuneLabel").text = rune_text
	hud.get_node("PromptLabel").text = player.get_interact_prompt()
	if hud.has_node("FloorLabel"):
		var bname := Loc.t(str(MindTable.BRAND_STATS[RunSession.brand_quality].get("name_key", "brand.iron")))
		hud.get_node("FloorLabel").text = "%s | %s" % [Loc.t("hud.floor", [RunSession.floor_index]), Loc.t("hud.brand", [bname])]
	if _current_room_id >= 0 and _current_room_id < rooms.size():
		hud.get_node("RoomLabel").text = Loc.t(rooms[_current_room_id].type_name_key())


func _on_extract(_by: Node) -> void:
	_finish_success()


func _on_player_died() -> void:
	_show_death_keep()


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
	MetaProgress.add_intel(Loc.t("intel.floor_cleared", [RunSession.floor_index]))
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
	for i in 12:
		var path := "Panel/Slots/Slot%d" % i
		if death_ui.has_node(path):
			var btn: Button = death_ui.get_node(path)
			var idx := i
			btn.pressed.connect(func(): _select_death_slot(idx))


func _show_death_keep() -> void:
	if _run_over:
		return
	_run_over = true
	if player:
		player.input_locked = true
	death_ui.visible = true
	death_ui.get_node("Panel/Title").text = Loc.t("extract.fail_title")
	death_ui.get_node("Panel/Hint").text = Loc.t("extract.keep_one")
	_death_selected = -1
	for i in 12:
		var path := "Panel/Slots/Slot%d" % i
		if not death_ui.has_node(path):
			continue
		var btn: Button = death_ui.get_node(path)
		if i < player.inventory.slots.size():
			btn.visible = true
			btn.text = player.inventory.describe_slot(i)
			btn.disabled = false
		else:
			btn.visible = false


func _select_death_slot(idx: int) -> void:
	_death_selected = idx
	for i in 12:
		var path := "Panel/Slots/Slot%d" % i
		if death_ui.has_node(path):
			death_ui.get_node(path).modulate = Color(1.2, 1.1, 0.6) if i == idx else Color.WHITE


func _confirm_death_keep() -> void:
	var kept: Array = player.inventory.keep_only_index(_death_selected)
	MetaProgress.merge_inventory_into_stash(kept)
	MetaProgress.apply_death_wear()
	if RunSession.quest_id_snapshot != "":
		MetaProgress.fail_quest()
	player.runes.clear()
	RunSession.clear()
	get_tree().change_scene_to_file("res://scenes/hub/crane_hub.tscn")


func _on_toast(text: String) -> void:
	var toast: Label = hud.get_node("ToastLabel")
	toast.text = text
	toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)


func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/crane_hub.tscn")


func _on_arena_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/crane_hub.tscn")
