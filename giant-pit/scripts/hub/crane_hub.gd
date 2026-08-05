extends Node2D
## 鹤城枢纽。

const PlayerScene = preload("res://scenes/player/player.tscn")
const FacilityScript = preload("res://scripts/hub/hub_facility.gd")
const Equipment = preload("res://scripts/meta/equipment.gd")
const QuestDefs = preload("res://scripts/meta/quest_defs.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const SheetHostScript = preload("res://scripts/ui/character_sheet_host.gd")

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


func _ready() -> void:
	_build_hub()
	_spawn_player()
	_ensure_sheet_host()
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
	_refresh_status()
	MetaProgress.changed.connect(_refresh_status)
	AudioManager.play_bgm()


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
	var floor_tex: Texture2D = load("res://assets/tiles/hub/hub_floor.png")
	for y in 10:
		for x in 14:
			var s := Sprite2D.new()
			s.texture = floor_tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x * 32 - 208, y * 32 - 144)
			s.z_index = -2
			world.add_child(s)
	_wall_box(Vector2(0, -160), Vector2(448, 16))
	_wall_box(Vector2(0, 160), Vector2(448, 16))
	_wall_box(Vector2(-224, 0), Vector2(16, 320))
	_wall_box(Vector2(224, 0), Vector2(16, 320))

	_add_facility("board", Vector2(-120, -40), "res://assets/tiles/hub/hub_board.png")
	_add_facility("alchemy", Vector2(0, -40), "res://assets/tiles/hub/hub_alchemy.png")
	_add_facility("quiet", Vector2(120, -40), "res://assets/tiles/hub/hub_quiet_door.png")
	_add_facility("stash", Vector2(-60, 60), "res://assets/tiles/hub/hub_alchemy.png")
	_add_facility("pit", Vector2(80, 80), "res://assets/tiles/hub/hub_pit_mouth.png")


func _wall_box(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
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
	player.combat_enabled = false
	player.apply_meta_loadout("iron")
	player.toast.connect(func(t): _toast(t))
	if sheet_host:
		sheet_host.bind_player(player, true)


func _refresh_status() -> void:
	hud.get_node("StatusLabel").text = "%s | %s | %s | %s" % [
		Loc.t("hud.mind", [MetaProgress.mind_level]),
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
		"alchemy":
			_open_alchemy()
		"stash":
			_open_stash()
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
	panel_body.text = "\n".join(lines)


func _weight_line(level: int, key: String) -> String:
	var w: Dictionary = MindTable.BRAND_WEIGHTS.get(clampi(level, 1, 5), MindTable.BRAND_WEIGHTS[1])
	return Loc.t(key, [
		int(w.get("iron", 0)),
		int(w.get("copper", 0)),
		int(w.get("silver", 0)),
		int(w.get("gold", 0)),
	])


func _open_quiet() -> void:
	_mode = "quiet"
	_show_text_panel()
	panel_title.text = Loc.t("hub.quiet_title")
	var lvl := MetaProgress.mind_level
	var cost := MindTable.cost_to_next(lvl)
	var lines: PackedStringArray = []
	lines.append(Loc.t("hub.quiet_hint", [lvl, cost]))
	lines.append(Loc.t("hub.mind_value_line", [
		MetaProgress.mind_value, MetaProgress.SHARD_TO_VALUE, MetaProgress.CORE_TO_VALUE
	]))
	lines.append(_weight_line(lvl, "hub.quiet_weights"))
	if lvl < 5:
		lines.append(_weight_line(lvl + 1, "hub.quiet_effect"))
	else:
		lines.append(Loc.t("hub.quiet_max"))
	panel_body.text = "\n".join(lines)
	btn_a.text = Loc.t("hub.quiet_do")
	btn_a.visible = lvl < 5
	btn_b.text = Loc.t("hub.quiet_convert")
	btn_b.visible = true
	btn_c.visible = false


func _open_pit() -> void:
	_mode = "pit"
	_show_text_panel()
	panel_title.text = Loc.t("facility.pit")
	var lines: PackedStringArray = []
	lines.append(Loc.t("hub.enter_pit"))
	lines.append(Loc.t("hud.mind_value", [MetaProgress.mind_value]))
	if MetaProgress.unlocked_warps.is_empty():
		lines.append(Loc.t("hub.warp_locked_none"))
	else:
		lines.append(Loc.t("hub.enter_warp_need"))
		for wid in MetaProgress.unlocked_warps:
			lines.append(" · " + Loc.t("hub.warp_option", [Loc.t("warp.%s" % wid)]))
	panel_body.text = "\n".join(lines)
	btn_a.text = Loc.t("hub.enter")
	btn_a.visible = true
	var can_warp := not MetaProgress.unlocked_warps.is_empty() and MetaProgress.can_afford_mind(MetaProgress.WARP_COST_ENTER)
	btn_b.text = Loc.t("hub.enter_warp", [MetaProgress.WARP_COST_ENTER])
	btn_b.visible = not MetaProgress.unlocked_warps.is_empty()
	btn_b.disabled = not can_warp
	btn_c.visible = false


func _format_cost(costs: Dictionary) -> String:
	var parts: PackedStringArray = []
	for mid in costs.keys():
		var need := int(costs[mid])
		var have := MetaProgress.stash_count(str(mid))
		var name := MaterialCatalog.display_name(str(mid))
		var piece := "%s x%d（有%d）" % [name, need, have]
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


func _equip_text() -> String:
	var lines: PackedStringArray = []
	for slot in [Equipment.SLOT_CHEST, Equipment.SLOT_AMULET]:
		var name_key := "equip.chest" if slot == Equipment.SLOT_CHEST else "equip.amulet"
		var data: Dictionary = MetaProgress.equipment[slot]
		if bool(data.get("owned", false)):
			lines.append("%s：%s" % [Loc.t(name_key), Loc.t("equip.owned", [int(data.get("upgrade", 0)), int(data.get("wear", 0))])])
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
	if stash_grid.has_method("set_stash_dict"):
		stash_grid.set_stash_dict(MetaProgress.stash)
	if panel.has_node("Tooltip"):
		panel.get_node("Tooltip").text = ""
	btn_a.visible = false
	btn_b.visible = false
	btn_c.visible = false


func _on_stash_hover(_index: int, tip: String) -> void:
	if panel.has_node("Tooltip"):
		panel.get_node("Tooltip").text = tip


func _show_text_panel() -> void:
	panel.visible = true
	stash_grid.visible = false
	panel_body.visible = true
	panel_body.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_body.offset_bottom = 280.0
	if panel.has_node("Tooltip"):
		panel.get_node("Tooltip").text = ""
	btn_b.disabled = false


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
		"alchemy":
			_craft(Equipment.SLOT_CHEST)
		"pit":
			_enter_pit("")


func _on_btn_b() -> void:
	match _mode:
		"board":
			_accept_quest_index(1)
		"alchemy":
			_craft(Equipment.SLOT_AMULET)
		"quiet":
			var before := MetaProgress.mind_value
			var cr := MetaProgress.try_convert_to_mind_value(false)
			if cr == "ok":
				_toast(Loc.t("hub.quiet_convert_ok", [MetaProgress.mind_value - before, MetaProgress.mind_value]))
			else:
				_toast(Loc.t("hub.quiet_no"))
			_open_quiet()
		"pit":
			_enter_pit_via_warp()


func _on_btn_c() -> void:
	match _mode:
		"board":
			_accept_quest_index(2)
		"alchemy":
			_upgrade_any()


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


func _close_panel() -> void:
	panel.visible = false
	stash_grid.visible = false
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
