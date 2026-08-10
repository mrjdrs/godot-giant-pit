extends Node2D
## 鹤城枢纽。

const PlayerScene = preload("res://scenes/player/player.tscn")
const FacilityScript = preload("res://scripts/hub/hub_facility.gd")
const AtmosphereScript = preload("res://scripts/fx/scene_atmosphere.gd")
const Equipment = preload("res://scripts/meta/equipment.gd")
const QuestDefs = preload("res://scripts/meta/quest_defs.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const RegionCatalog = preload("res://scripts/pit/region_catalog.gd")
const SheetHostScript = preload("res://scripts/ui/character_sheet_host.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")

@onready var world: Node2D = $World
@onready var entities: Node2D = $World/Entities
@onready var hud: CanvasLayer = $HUD
@onready var panel: Panel = $HUD/Panel
@onready var panel_title: Label = $HUD/Panel/Title
@onready var panel_body: RichTextLabel = $HUD/Panel/Body
@onready var stash_grid: GridContainer = $HUD/Panel/StashGrid
@onready var btn_a: Button = $HUD/Panel/BtnA
@onready var btn_b: Button = $HUD/Panel/BtnB
@onready var btn_c: Button = $HUD/Panel/BtnC
@onready var btn_close: Button = $HUD/Panel/BtnClose
@onready var prompt_label: Label = $HUD/PromptLabel

var player: CharacterBody2D = null
var sheet_host: CanvasLayer = null
var _mode: String = ""
var _selected_quest: String = ""
var _atmosphere: Node2D

const PANEL_BTN_LEFT := 20.0
const PANEL_BTN_RIGHT := 540.0
const PANEL_BTN_ROW_Y := 288.0
const PANEL_BTN_H := 34.0
const PANEL_BTN_GAP := 8.0
const PANEL_BTN_CLOSE_Y := 332.0
const PANEL_BODY_BOTTOM := 268.0
const STASH_GRID_TOP := 56.0
const STASH_GRID_LEFT := 24.0
const STASH_GRID_RIGHT := 536.0
const STASH_SLOT := 48.0
const STASH_GAP := 6.0
const STASH_COLS := 6


func _ready() -> void:
	if RunSession.active:
		RunSession.clear()
	if not MetaProgress.ensure_session_loaded():
		MetaProgress.new_game(1)
	_build_hub()
	_spawn_player()
	_ensure_sheet_host()
	PauseMenuScript.install(self)
	panel.visible = false
	stash_grid.visible = false
	btn_close.pressed.connect(_close_panel)
	btn_a.pressed.connect(_on_btn_a)
	btn_b.pressed.connect(_on_btn_b)
	btn_c.pressed.connect(_on_btn_c)
	btn_close.text = Loc.t("hub.close")
	hud.get_node("HintLabel").text = Loc.t("hint.hub")
	if stash_grid.has_signal("slot_hovered") and not stash_grid.slot_hovered.is_connected(_on_stash_hover):
		stash_grid.slot_hovered.connect(_on_stash_hover)
	if stash_grid.has_signal("slot_pressed") and not stash_grid.slot_pressed.is_connected(_on_stash_slot_pressed):
		stash_grid.slot_pressed.connect(_on_stash_slot_pressed)
	_style_hub_buttons()
	_refresh_status()
	MetaProgress.changed.connect(_refresh_status)
	AudioManager.play_bgm()


func _style_hub_buttons() -> void:
	var disabled_col := Color(0.68, 0.64, 0.58, 1)
	for b in [btn_a, btn_b, btn_c, btn_close]:
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_disabled_color", disabled_col)


func _layout_panel_buttons(show_a: bool, show_b: bool, show_c: bool) -> void:
	btn_a.visible = show_a
	btn_b.visible = show_b
	btn_c.visible = show_c
	var row: Array[Button] = []
	if show_a:
		row.append(btn_a)
	if show_b:
		row.append(btn_b)
	if show_c:
		row.append(btn_c)
	var width := PANEL_BTN_RIGHT - PANEL_BTN_LEFT
	var count := row.size()
	if count > 0:
		var gap_total := PANEL_BTN_GAP * float(count - 1)
		var btn_w := (width - gap_total) / float(count)
		var x := PANEL_BTN_LEFT
		for b in row:
			b.position = Vector2(x, PANEL_BTN_ROW_Y)
			b.size = Vector2(btn_w, PANEL_BTN_H)
			x += btn_w + PANEL_BTN_GAP
	btn_close.position = Vector2(200.0, PANEL_BTN_CLOSE_Y)
	btn_close.size = Vector2(160.0, PANEL_BTN_H)


func _layout_stash_panel(slot_count: int) -> void:
	var rows := int(ceil(float(maxi(slot_count, 1)) / float(STASH_COLS)))
	var grid_h := rows * STASH_SLOT + maxi(rows - 1, 0) * STASH_GAP
	stash_grid.position = Vector2(STASH_GRID_LEFT, STASH_GRID_TOP)
	stash_grid.size = Vector2(STASH_GRID_RIGHT - STASH_GRID_LEFT, grid_h)
	var hint_y := STASH_GRID_TOP + grid_h + 10.0
	var hint_h := 22.0
	if panel.has_node("Tooltip"):
		var tip: Label = panel.get_node("Tooltip")
		tip.position = Vector2(PANEL_BTN_LEFT, hint_y)
		tip.size = Vector2(PANEL_BTN_RIGHT - PANEL_BTN_LEFT, hint_h)
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tip.text = Loc.t("hub.stash_sell_hint")
	var btn_y := hint_y + hint_h + 8.0
	btn_a.position = Vector2(PANEL_BTN_LEFT, btn_y)
	btn_a.size = Vector2(200.0, PANEL_BTN_H)
	btn_a.visible = true
	btn_b.visible = false
	btn_c.visible = false
	btn_close.position = Vector2(200.0, btn_y + PANEL_BTN_H + 10.0)
	btn_close.size = Vector2(160.0, PANEL_BTN_H)


func _ensure_sheet_host() -> void:
	if sheet_host != null:
		return
	sheet_host = CanvasLayer.new()
	sheet_host.set_script(SheetHostScript)
	add_child(sheet_host)
	if player:
		sheet_host.bind_player(player, true)
	sheet_host.panel_closed.connect(func():
		if player:
			player.input_locked = false
	)


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


func _process(_delta: float) -> void:
	if player == null:
		return
	if panel.visible or (sheet_host and sheet_host.any_open()):
		prompt_label.text = ""
		return
	prompt_label.text = player.get_interact_prompt()


func _build_hub() -> void:
	_add_hub_backdrop()
	_atmosphere = AtmosphereScript.install(world, self, "hub", 0.18, false)
	var floor_tex: Texture2D = load("res://assets/tiles/hub/hub_floor.png")
	const HUB_COLS := 20
	const HUB_ROWS := 16
	var origin := Vector2(-float(HUB_COLS) * 16.0, -float(HUB_ROWS) * 16.0)
	for y in HUB_ROWS:
		for x in HUB_COLS:
			var s := Sprite2D.new()
			s.texture = floor_tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = origin + Vector2(x * 32 + 16, y * 32 + 16)
			s.z_index = -2
			world.add_child(s)
	var floor_w := float(HUB_COLS * 32)
	var floor_h := float(HUB_ROWS * 32)
	_wall_box(Vector2(0, -floor_h * 0.5 - 8.0), Vector2(floor_w + 16.0, 16))
	_wall_box(Vector2(0, floor_h * 0.5 + 8.0), Vector2(floor_w + 16.0, 16))
	_wall_box(Vector2(-floor_w * 0.5 - 8.0, 0), Vector2(16, floor_h + 16.0))
	_wall_box(Vector2(floor_w * 0.5 + 8.0, 0), Vector2(16, floor_h + 16.0))

	_add_facility("board", Vector2(-120, -40), "res://assets/tiles/hub/hub_board.png")
	_add_facility("alchemy", Vector2(0, -40), "res://assets/tiles/hub/hub_alchemy.png")
	_add_facility("quiet", Vector2(120, -40), "res://assets/tiles/hub/hub_quiet_door.png")
	_add_facility("inn", Vector2(160, 0), "res://assets/tiles/hub/hub_quiet_door.png")
	_add_facility("exchange", Vector2(-120, 60), "res://assets/tiles/hub/hub_alchemy.png")
	_add_facility("stash", Vector2(-60, 60), "res://assets/tiles/hub/hub_alchemy.png")
	_add_facility("winch", Vector2(40, 40), "res://assets/props/side/winch.png")
	_add_facility("spotlight", Vector2(120, 60), "res://assets/props/side/spotlight.png")
	_add_facility("awaken", Vector2(0, 80), "res://assets/tiles/hub/hub_alchemy.png")
	_add_facility("comprehend", Vector2(-160, 40), "res://assets/tiles/hub/hub_quiet_door.png")
	_add_facility("dummy", Vector2(-80, 80), "res://assets/enemies/side/dummy_post.png")
	_add_facility("pit", Vector2(80, 80), "res://assets/tiles/hub/hub_pit_mouth.png")

	if _atmosphere and _atmosphere.has_method("add_glow"):
		_atmosphere.add_glow(Vector2(80, 80), Color(1.0, 0.85, 0.55, 1.0), 0.28, 100.0)
		_atmosphere.add_glow(Vector2(120, 60), Color(0.9, 0.95, 1.0, 1.0), 0.18, 80.0)


func _add_hub_backdrop() -> void:
	var bg := Polygon2D.new()
	bg.name = "HubBackdrop"
	bg.z_index = -50
	bg.color = Color(0.10, 0.10, 0.12, 1)
	var s := 2800.0
	bg.polygon = PackedVector2Array([
		Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
	])
	world.add_child(bg)
	world.move_child(bg, 0)


func _wall_box(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var wall_tex: Texture2D = load("res://assets/tiles/hub/hub_wall.png")
	if wall_tex:
		var holder := Node2D.new()
		body.add_child(holder)
		var cols := maxi(1, int(ceil(size.x / 32.0)))
		var rows := maxi(1, int(ceil(size.y / 32.0)))
		var origin := Vector2(-size.x * 0.5, -size.y * 0.5)
		for row in rows:
			for col in cols:
				var spr := Sprite2D.new()
				spr.texture = wall_tex
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				spr.centered = false
				spr.position = origin + Vector2(col * 32, row * 32)
				holder.add_child(spr)
	else:
		var vis := Polygon2D.new()
		vis.color = Color(0.35, 0.32, 0.28, 1)
		var hx := size.x * 0.5
		var hy := size.y * 0.5
		vis.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
		body.add_child(vis)
	world.add_child(body)


func _add_facility(id: String, pos: Vector2, icon: String) -> void:
	var area := Area2D.new()
	area.set_script(FacilityScript)
	area.facility_id = id
	area.position = pos
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.texture = load(icon)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if id == "dummy":
		spr.scale = Vector2(0.85, 0.85)
	area.add_child(spr)
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	cs.shape = circle
	area.add_child(cs)
	entities.add_child(area)
	area.facility_used.connect(_on_facility)


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	entities.add_child(player)
	player.global_position = Vector2(0, 40)
	player.side_view = false
	player.combat_enabled = false
	player.apply_meta_brand("iron")
	player.toast.connect(func(t, _cat = 0, _col = Color.TRANSPARENT): _toast(t))
	if player.has_node("Camera2D"):
		player.get_node("Camera2D").zoom = Vector2(3.0, 3.0)
	if player.has_method("set_camera_limits"):
		player.set_camera_limits(-336.0, -272.0, 336.0, 272.0)
	if sheet_host:
		sheet_host.bind_player(player, true)


func _refresh_status() -> void:
	var day_txt := Loc.t("hud.game_day", [MetaProgress.game_day])
	hud.get_node("StatusLabel").text = "%s | %s | %s | %s | %s | %s" % [
		day_txt,
		Loc.t("hud.pit_open"),
		Loc.t("hud.xp", [MetaProgress.explorer_level, MetaProgress.explorer_xp, MetaProgress.xp_to_next_level()]),
		Loc.t("hud.mind_value_cap", [MetaProgress.mind_value, MetaProgress.mind_value_max()]),
		Loc.t("hud.gold", [MetaProgress.gold]),
		_quest_status_text(),
	]
	if sheet_host and sheet_host.any_open():
		if sheet_host.stats_panel.visible:
			sheet_host.stats_panel.refresh()
		if sheet_host.bag_panel.visible:
			sheet_host.bag_panel.refresh()
		if sheet_host.skills_panel.visible:
			sheet_host.skills_panel.refresh()


func _quest_status_text() -> String:
	if MetaProgress.active_quest_id == "":
		return Loc.t("hud.quest_none")
	var def: Dictionary = QuestDefs.get_def(MetaProgress.active_quest_id)
	return Loc.t("hud.quest", [Loc.t(str(def.get("name_key", "")))])


func _on_facility(facility_id: String, _by: Node) -> void:
	match facility_id:
		"board":
			_open_board()
		"quiet":
			_open_quiet()
		"inn":
			_open_inn()
		"exchange":
			_open_exchange()
		"alchemy":
			_open_alchemy()
		"stash":
			_open_stash()
		"winch":
			_open_winch()
		"spotlight":
			_open_spotlight()
		"awaken":
			_open_awaken()
		"comprehend":
			_open_comprehend()
		"dummy":
			_open_dummy()
		"pit":
			_open_pit()


func _quest_reward_line(def: Dictionary) -> String:
	var gold := int(def.get("reward_gold", 0))
	var mats: Dictionary = def.get("reward_mat", {})
	var mat_parts: PackedStringArray = []
	for mid in mats.keys():
		mat_parts.append("%s x%d" % [MaterialCatalog.display_name(str(mid)), int(mats[mid])])
	var mat_text: String = Loc.t("quest.reward_mats_none") if mat_parts.is_empty() else ", ".join(mat_parts)
	return Loc.t("quest.reward", [gold, mat_text])


func _open_board() -> void:
	_mode = "board"
	_show_text_panel()
	panel_title.text = Loc.t("hub.board_title")
	var lines: PackedStringArray = []
	if MetaProgress.active_quest_id != "":
		var cur: Dictionary = QuestDefs.get_def(MetaProgress.active_quest_id)
		var info: Dictionary = QuestDefs.run_progress(
			MetaProgress.active_quest_id, [], 0, false
		)
		lines.append(Loc.t("hub.quest_active", [Loc.t(str(cur.get("name_key")))]))
		if not info.is_empty():
			lines.append(Loc.t("hub.quest_target", [str(info.get("progress_text"))]))
		lines.append(Loc.t(str(cur.get("desc_key"))))
		lines.append(_quest_reward_line(cur))
		lines.append("")
		lines.append(Loc.t("hub.quest_progress_hint"))
		btn_a.text = Loc.t("hub.abandon")
		btn_a.visible = true
		btn_b.visible = false
		btn_c.visible = false
		_layout_panel_buttons(true, false, false)
	else:
		var ids: Array = QuestDefs.all_ids()
		_selected_quest = str(ids[0])
		for i in ids.size():
			var qid: String = str(ids[i])
			var d: Dictionary = QuestDefs.get_def(qid)
			var tgt := int(d.get("count", 1))
			if str(d.get("type")) == QuestDefs.TYPE_RESCUE:
				tgt = 1
			lines.append("%d) %s — 目标 %d" % [i + 1, Loc.t(str(d.get("name_key"))), tgt])
			lines.append("   %s" % Loc.t(str(d.get("desc_key"))))
			lines.append("   %s" % _quest_reward_line(d))
		btn_a.text = Loc.t("hub.accept") + "①"
		btn_b.text = Loc.t("hub.accept") + "②"
		btn_c.text = Loc.t("hub.accept") + "③"
		btn_a.visible = true
		btn_b.visible = true
		btn_c.visible = true
		_layout_panel_buttons(true, true, true)
	_set_panel_body("\n".join(lines))


func _weight_line(level: int, key: String) -> String:
	var w: Dictionary = MindTable.BRAND_WEIGHTS.get(clampi(level, 1, 5), MindTable.BRAND_WEIGHTS[1])
	return Loc.t(key, [
		int(w.get("iron", 0)),
		int(w.get("copper", 0)),
		int(w.get("silver", 0)),
		int(w.get("gold", 0)),
	])


func _set_panel_body(text: String) -> void:
	panel_body.bbcode_enabled = false
	panel_body.text = text
	if panel_body.get_line_count() > 0:
		panel_body.scroll_to_line(0)


func _stash_entry_at(index: int) -> Dictionary:
	if not stash_grid.has_method("get_slot_tooltip"):
		return {}
	var keys: Array = MetaProgress.stash.keys()
	keys.sort()
	if index < 0 or index >= keys.size():
		return {}
	var sid := str(keys[index])
	var entry_type := "mat"
	const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
	const ItemCatalog = preload("res://scripts/items/item_catalog.gd")
	if RuneCatalog.DEFS.has(sid):
		entry_type = "rune"
	elif ItemCatalog.ITEMS.has(sid):
		entry_type = "item"
	return {"type": entry_type, "id": sid, "count": MetaProgress.stash_count(sid)}


func _open_quiet() -> void:
	_mode = "quiet"
	_show_text_panel()
	panel_title.text = Loc.t("hub.quiet_title")
	var lvl := MetaProgress.mind_level
	var cost := MindTable.cost_to_next(lvl)
	var shard_have := MetaProgress.stash_count("mind_shard")
	var core_have := MetaProgress.stash_count("mind_core")
	var equiv := shard_have + core_have * 3
	var lines: PackedStringArray = []
	lines.append(Loc.t("hub.quiet_level", [lvl]))
	lines.append(Loc.t("hub.quiet_value_cap", [MetaProgress.mind_value, MetaProgress.mind_value_max()]))
	if lvl < 5:
		lines.append("")
		lines.append(Loc.t("hub.quiet_cost", [cost, shard_have, core_have, equiv]))
		lines.append(Loc.t("hub.quiet_effect_desc", [MetaProgress.MIND_VALUE_PER_LEVEL]))
		lines.append(_weight_line(lvl, "hub.quiet_weights_now"))
		lines.append(_weight_line(lvl + 1, "hub.quiet_weights_next"))
	else:
		lines.append("")
		lines.append(Loc.t("hub.quiet_max"))
		lines.append(_weight_line(lvl, "hub.quiet_weights_now"))
	_set_panel_body("\n".join(lines))
	btn_a.text = Loc.t("hub.quiet_do", [lvl + 1]) if lvl < 5 else Loc.t("hub.quiet_max")
	btn_a.visible = lvl < 5
	btn_a.disabled = lvl >= 5 or equiv < cost
	btn_b.visible = false
	btn_c.visible = false
	_layout_panel_buttons(lvl < 5, false, false)


func _open_inn() -> void:
	_mode = "inn"
	_show_text_panel()
	panel_title.text = Loc.t("hub.inn_title")
	_set_panel_body("%s\n\n%s" % [
		Loc.t("hub.inn_body", [
			MetaProgress.game_day,
			MetaProgress.mind_value,
			MetaProgress.mind_value_max(),
		]),
		Loc.t("hub.inn_shop_line", [
			MetaProgress.EROSION_SALVE_PRICE,
			MetaProgress.EROSION_WARD_PRICE,
		]),
	])
	btn_a.text = Loc.t("hub.inn_rest")
	btn_b.text = Loc.t("hub.inn_buy_salve", [MetaProgress.EROSION_SALVE_PRICE])
	btn_c.text = Loc.t("hub.inn_buy_ward", [MetaProgress.EROSION_WARD_PRICE])
	btn_a.disabled = false
	btn_b.disabled = not MetaProgress.can_afford_gold(MetaProgress.EROSION_SALVE_PRICE)
	btn_c.disabled = not MetaProgress.can_afford_gold(MetaProgress.EROSION_WARD_PRICE)
	_layout_panel_buttons(true, true, true)


func _open_exchange() -> void:
	_mode = "exchange"
	_show_text_panel()
	panel_title.text = Loc.t("hub.exchange_title")
	var voucher_gold := MetaProgress.VOUCHER_SPEND_VALUE
	var lines: PackedStringArray = []
	lines.append(Loc.t("hub.exchange_hint", [
		MetaProgress.GOLD_TO_PAPER_COST,
		voucher_gold,
	]))
	lines.append(Loc.t("hud.gold", [MetaProgress.gold]))
	lines.append(Loc.t("hud.paper_notes", [MetaProgress.paper_note_count()]))
	lines.append(Loc.t("hub.spendable_gold", [MetaProgress.spendable_gold()]))
	lines.append(Loc.t("hub.exchange_potion_line", [MetaProgress.MIND_POTION_PRICE, MetaProgress.MIND_POTION_RESTORE]))
	_set_panel_body("\n".join(lines))
	var gold_cost := MetaProgress.GOLD_TO_PAPER_COST
	btn_a.text = Loc.t("hub.exchange_gold_to_paper", [gold_cost])
	btn_b.text = Loc.t("hub.exchange_paper_to_gold", [voucher_gold])
	btn_c.text = Loc.t("hub.buy_mind_potion", [MetaProgress.MIND_POTION_PRICE])
	btn_a.disabled = MetaProgress.gold < gold_cost
	btn_b.disabled = MetaProgress.paper_note_count() < 1
	btn_c.disabled = not MetaProgress.can_afford_gold(MetaProgress.MIND_POTION_PRICE)
	_layout_panel_buttons(true, true, true)


func _open_dummy() -> void:
	_mode = "dummy"
	_show_text_panel()
	panel_title.text = Loc.t("facility.dummy")
	panel_body.text = Loc.t("hub.enter_dummy")
	btn_a.text = Loc.t("hub.enter_training")
	btn_a.visible = true
	btn_a.disabled = false
	btn_b.visible = false
	btn_c.visible = false
	_layout_panel_buttons(true, false, false)


func _open_pit() -> void:
	_mode = "pit"
	_show_text_panel()
	panel_title.text = Loc.t("facility.pit")
	var lines: PackedStringArray = []
	lines.append(Loc.t("hub.enter_pit"))
	lines.append(Loc.t("hud.mind_value_cap", [MetaProgress.mind_value, MetaProgress.mind_value_max()]))
	lines.append(Loc.t("hub.enter_pit_free"))
	if MetaProgress.unlocked_warps.is_empty():
		lines.append(Loc.t("hub.warp_locked_none"))
	else:
		lines.append(Loc.t("hub.enter_warp_need"))
		for wid in MetaProgress.unlocked_warps:
			lines.append(" · " + Loc.t("hub.warp_option", [RegionCatalog.warp_display_name(str(wid))]))
	panel_body.text = "\n".join(lines)
	btn_a.text = Loc.t("hub.enter")
	btn_a.visible = true
	btn_a.disabled = false
	var can_warp := not MetaProgress.unlocked_warps.is_empty() and MetaProgress.can_afford_mind(MetaProgress.WARP_COST_ENTER)
	btn_b.text = Loc.t("hub.enter_warp", [MetaProgress.WARP_COST_ENTER])
	btn_b.visible = not MetaProgress.unlocked_warps.is_empty()
	btn_b.disabled = not can_warp
	btn_c.visible = false
	_layout_panel_buttons(true, not MetaProgress.unlocked_warps.is_empty(), false)


func _format_cost(costs: Dictionary) -> String:
	var parts: PackedStringArray = []
	for mid in costs.keys():
		var need := int(costs[mid])
		var have := MetaProgress.stash_count(str(mid))
		var mat_name := MaterialCatalog.display_name(str(mid))
		var piece := "%s x%d（有%d）" % [mat_name, need, have]
		if have < need:
			piece += Loc.t("hub.cost_lack")
		parts.append(piece)
	return "、".join(parts)


func _open_alchemy() -> void:
	_mode = "alchemy"
	_show_text_panel()
	panel_title.text = Loc.t("hub.alchemy_title")
	panel_body.text = _equip_text()
	btn_a.text = Loc.t("hub.craft") + "·" + Loc.t("equip.chest")
	btn_b.text = Loc.t("hub.craft") + "·" + Loc.t("equip.amulet")
	btn_c.text = Loc.t("hub.upgrade")
	btn_a.visible = true
	btn_b.visible = true
	btn_c.visible = true
	btn_a.disabled = false
	btn_b.disabled = false
	btn_c.disabled = false
	_layout_panel_buttons(true, true, true)


func _equip_text() -> String:
	var lines: PackedStringArray = []
	for slot in [Equipment.SLOT_CHEST, Equipment.SLOT_AMULET]:
		var name_key := "equip.chest" if slot == Equipment.SLOT_CHEST else "equip.amulet"
		var data: Dictionary = MetaProgress.equipment[slot]
		if bool(data.get("owned", false)):
			var gq := "%s·%s" % [
				ItemTier.grade_display(int(data.get("grade", 2))),
				ItemTier.display_name(int(data.get("quality", ItemTier.Tier.COMMON))),
			]
			lines.append("%s：%s  %s" % [Loc.t(name_key), gq, Loc.t("equip.owned", [int(data.get("upgrade", 0)), int(data.get("wear", 0))])])
			var st: Dictionary = Equipment.effective_stats(data, slot)
			lines.append("  " + Loc.t("equip.stats", [st.max_hp, st.defense, st.damage * 100.0]))
			lines.append("  " + Loc.t("hub.upgrade_cost", [_format_cost({Equipment.UPGRADE_MAT: Equipment.UPGRADE_COST})]))
		else:
			lines.append("%s：%s" % [Loc.t(name_key), Loc.t("equip.not_owned")])
			lines.append("  " + Loc.t("hub.craft_cost", [_format_cost(Equipment.craft_cost(slot))]))
	return "\n".join(lines)


func _open_stash() -> void:
	_mode = "stash"
	panel.visible = true
	panel_title.text = Loc.t("hub.stash_title")
	var empty := MetaProgress.stash.is_empty()
	panel_body.visible = empty
	panel_body.text = Loc.t("hub.stash_empty") if empty else ""
	panel_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_body.offset_bottom = 80.0
	stash_grid.visible = true
	if stash_grid.has_method("set_selectable"):
		stash_grid.set_selectable(true)
	elif stash_grid.get("selectable") != null:
		stash_grid.selectable = true
		if stash_grid.has_method("set_slot_count"):
			stash_grid.set_slot_count(stash_grid.slot_count)
	var stash_need := maxi(24, MetaProgress.stash.size())
	stash_need = int(ceil(float(stash_need) / 6.0) * 6.0)
	if stash_grid.has_method("set_slot_count"):
		stash_grid.set_slot_count(stash_need)
	if stash_grid.has_method("set_stash_dict"):
		stash_grid.set_stash_dict(MetaProgress.stash)
	_layout_stash_panel(stash_need)
	btn_a.text = Loc.t("hub.sell_one")
	btn_a.disabled = false


func _open_winch() -> void:
	_mode = "winch"
	_show_text_panel()
	panel_title.text = Loc.t("hub.winch_title")
	panel_body.text = Loc.t("hub.winch_body", [MetaProgress.winch_level, _format_cost(MetaProgress.WINCH_UPGRADE_COST)])
	btn_a.text = Loc.t("hub.upgrade")
	btn_a.visible = true
	btn_b.visible = false
	btn_c.visible = false
	_layout_panel_buttons(true, false, false)


func _open_spotlight() -> void:
	_mode = "spotlight"
	_show_text_panel()
	panel_title.text = Loc.t("hub.spotlight_title")
	var breath: String = Loc.t("hub.breath_active") if MetaProgress.is_breath_day() else Loc.t("hub.breath_idle")
	panel_body.text = Loc.t("hub.spotlight_body", [MetaProgress.spotlight_level, _format_cost(MetaProgress.SPOTLIGHT_UPGRADE_COST), breath])
	btn_a.text = Loc.t("hub.upgrade")
	btn_a.visible = true
	btn_b.visible = false
	btn_c.visible = false
	_layout_panel_buttons(true, false, false)


func _open_awaken() -> void:
	_mode = "awaken"
	_show_text_panel()
	panel_title.text = Loc.t("hub.awaken_title")
	var cur: String = MetaProgress.awakening_branch
	var cur_name: String = Loc.t("awaken.none") if cur == "" else Loc.t("awaken." + cur)
	panel_body.text = Loc.t("hub.awaken_body", [
		cur_name,
		_format_cost(MetaProgress.AWAKEN_WHIRL_COST),
		_format_cost(MetaProgress.AWAKEN_IRON_COST),
	])
	btn_a.text = Loc.t("awaken.whirl")
	btn_b.text = Loc.t("awaken.ironwall")
	btn_a.visible = true
	btn_b.visible = true
	btn_c.visible = false
	_layout_panel_buttons(true, true, false)


func _on_stash_hover(_index: int, tip: String) -> void:
	if panel.has_node("Tooltip") and tip != "":
		panel.get_node("Tooltip").text = tip


func _on_stash_slot_pressed(index: int) -> void:
	if _mode != "stash":
		return
	if stash_grid.has_method("get_slot_tooltip"):
		var tip := str(stash_grid.get_slot_tooltip(index))
		if panel.has_node("Tooltip"):
			panel.get_node("Tooltip").text = tip if tip != "" else Loc.t("hub.stash_sell_hint")


func _show_text_panel() -> void:
	panel.visible = true
	stash_grid.visible = false
	panel_body.visible = true
	panel_body.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_body.offset_bottom = PANEL_BODY_BOTTOM
	if panel.has_node("Tooltip"):
		panel.get_node("Tooltip").text = ""
	btn_a.disabled = false
	btn_b.disabled = false
	btn_c.disabled = false


func _on_btn_a() -> void:
	match _mode:
		"board":
			if MetaProgress.active_quest_id != "":
				MetaProgress.abandon_quest()
				_toast(Loc.t("hub.abandon_toast"))
				_open_board()
			else:
				_accept_quest_index(0)
		"quiet":
			var r := MetaProgress.try_absorb_mind()
			match r:
				"ok":
					_toast(Loc.t("hub.quiet_ok", [MetaProgress.mind_level]))
				"max":
					_toast(Loc.t("hub.quiet_max"))
				_:
					_toast(Loc.t("hub.quiet_no"))
			_open_quiet()
		"inn":
			MetaProgress.advance_day()
			_toast(Loc.t("hub.inn_ok", [MetaProgress.game_day]))
			if MetaProgress.is_breath_day():
				_toast(Loc.t("hub.breath_active"))
			_open_inn()
		"exchange":
			var ex := MetaProgress.exchange_gold_to_paper(1)
			if ex == "ok":
				_toast(Loc.t("hub.exchange_gold_ok"))
			else:
				_toast(Loc.t("hub.no_gold"))
			_open_exchange()
		"stash":
			_sell_selected_stash()
		"alchemy":
			_craft(Equipment.SLOT_CHEST)
		"winch":
			var wr := MetaProgress.try_upgrade_winch()
			match wr:
				"ok":
					_toast(Loc.t("hub.winch_ok", [MetaProgress.winch_level]))
				"max":
					_toast(Loc.t("hub.infra_max"))
				_:
					_toast(Loc.t("hub.no_mats"))
			_open_winch()
		"spotlight":
			var sr := MetaProgress.try_upgrade_spotlight()
			match sr:
				"ok":
					_toast(Loc.t("hub.spotlight_ok", [MetaProgress.spotlight_level]))
				"max":
					_toast(Loc.t("hub.infra_max"))
				_:
					_toast(Loc.t("hub.no_mats"))
			_open_spotlight()
		"awaken":
			var ar := MetaProgress.try_awaken("whirl")
			_toast_awaken(ar)
			_open_awaken()
		"dummy":
			_enter_dummy()
		"pit":
			_enter_pit("")


func _toast_awaken(r: String) -> void:
	match r:
		"ok":
			_toast(Loc.t("hub.awaken_ok", [Loc.t("awaken." + MetaProgress.awakening_branch)]))
		"owned":
			_toast(Loc.t("hub.awaken_owned"))
		"locked_other":
			_toast(Loc.t("hub.awaken_locked"))
		_:
			_toast(Loc.t("hub.no_mats"))


func _on_btn_b() -> void:
	match _mode:
		"board":
			_accept_quest_index(1)
		"alchemy":
			_craft(Equipment.SLOT_AMULET)
		"exchange":
			var ex := MetaProgress.exchange_paper_to_gold(1)
			if ex == "ok":
				_toast(Loc.t("hub.exchange_paper_ok"))
			else:
				_toast(Loc.t("hub.no_paper"))
			_open_exchange()
		"inn":
			var ir := MetaProgress.buy_erosion_salve(1)
			if ir == "ok":
				_toast(Loc.t("hub.buy_salve_ok"))
			else:
				_toast(Loc.t("hub.no_gold"))
			_open_inn()
		"awaken":
			var ar := MetaProgress.try_awaken("ironwall")
			_toast_awaken(ar)
			_open_awaken()
		"pit":
			_enter_pit_via_warp()


func _on_btn_c() -> void:
	match _mode:
		"board":
			_accept_quest_index(2)
		"alchemy":
			_upgrade_any()
		"exchange":
			var ex := MetaProgress.buy_mind_potion(1)
			if ex == "ok":
				_toast(Loc.t("hub.buy_potion_ok"))
			else:
				_toast(Loc.t("hub.no_gold"))
			_open_exchange()
		"inn":
			var ir := MetaProgress.buy_erosion_ward(1)
			if ir == "ok":
				_toast(Loc.t("hub.buy_ward_ok"))
			else:
				_toast(Loc.t("hub.no_gold"))
			_open_inn()


func _accept_quest_index(i: int) -> void:
	var ids: Array = QuestDefs.all_ids()
	if i < 0 or i >= ids.size():
		return
	var qid: String = str(ids[i])
	var r := MetaProgress.accept_quest(qid)
	if r == "ok":
		_toast(Loc.t("hub.quest_accepted", [Loc.t(str(QuestDefs.get_def(qid).get("name_key")))]))
	elif r == "busy":
		_toast(Loc.t("hub.quest_busy"))
	_open_board()


func _craft(slot: String) -> void:
	var r := MetaProgress.try_craft(slot)
	var name_key := "equip.chest" if slot == Equipment.SLOT_CHEST else "equip.amulet"
	if r == "ok":
		_toast(Loc.t("hub.craft_ok", [Loc.t(name_key)]))
	elif r == "owned":
		_toast(Loc.t("hub.owned_toast"))
	else:
		_toast(Loc.t("hub.no_mats"))
	_open_alchemy()


func _upgrade_any() -> void:
	for slot in [Equipment.SLOT_CHEST, Equipment.SLOT_AMULET]:
		if bool(MetaProgress.equipment[slot].get("owned", false)):
			var r := MetaProgress.try_upgrade(slot)
			var name_key := "equip.chest" if slot == Equipment.SLOT_CHEST else "equip.amulet"
			if r == "ok":
				_toast(Loc.t("hub.upgrade_ok", [Loc.t(name_key)]))
			else:
				_toast(Loc.t("hub.no_mats"))
			_open_alchemy()
			return
	_toast(Loc.t("hub.no_mats"))
	_open_alchemy()


func _open_comprehend() -> void:
	if sheet_host:
		sheet_host.toggle_skills()


func _enter_dummy() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/training_dummy.tscn")


func _enter_pit(spawn_id: String = "") -> void:
	RunSession.begin_run(spawn_id)
	get_tree().change_scene_to_file("res://scenes/pit/pit_floor_01.tscn")


func _enter_pit_via_warp() -> void:
	if MetaProgress.unlocked_warps.is_empty():
		_toast(Loc.t("hub.warp_locked_none"))
		return
	if not MetaProgress.can_afford_mind(MetaProgress.WARP_COST_ENTER):
		_toast(Loc.t("warp.no_mind"))
		return
	## 默认选第一个已解锁；后续可做列表
	var wid := str(MetaProgress.unlocked_warps[0])
	if not MetaProgress.consume_mind_value(MetaProgress.WARP_COST_ENTER):
		_toast(Loc.t("warp.no_mind"))
		return
	_enter_pit(wid)


func _sell_selected_stash() -> void:
	if not stash_grid.has_method("get_selected"):
		_toast(Loc.t("hub.sell_none"))
		return
	var idx := int(stash_grid.get_selected())
	if idx < 0:
		_toast(Loc.t("hub.sell_none"))
		return
	var entry := _stash_entry_at(idx)
	if entry.is_empty():
		_toast(Loc.t("hub.sell_none"))
		return
	var item_id := str(entry.get("id"))
	var item_type := str(entry.get("type"))
	if item_type != "mat":
		_toast(Loc.t("hub.sell_not_material"))
		return
	var r := MetaProgress.sell_stash_material(item_id, 1)
	if r == "ok":
		_toast(Loc.t("hub.sell_ok", [MaterialCatalog.display_name(item_id), MaterialCatalog.sell_price(item_id)]))
	elif r == "locked":
		_toast(Loc.t("hub.sell_crystal_locked") if Loc.has_key("hub.sell_crystal_locked") else "晶核不能出售，请到感悟台学习技能")
	elif r == "no_item":
		_toast(Loc.t("hub.sell_none"))
	else:
		_toast(Loc.t("hub.sell_fail"))
	_open_stash()


func _close_panel() -> void:
	panel.visible = false
	stash_grid.visible = false
	if stash_grid.has_method("set_selectable"):
		stash_grid.set_selectable(false)
	elif stash_grid.get("selectable") != null:
		stash_grid.selectable = false
	if panel.has_node("Tooltip"):
		panel.get_node("Tooltip").text = ""
	_mode = ""


func _toast(text: String) -> void:
	var toast: Label = hud.get_node("ToastLabel")
	toast.text = text
	toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
