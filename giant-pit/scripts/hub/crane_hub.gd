extends Node2D
## 鹤城枢纽。

const PlayerScene = preload("res://scenes/player/player.tscn")
const FacilityScript = preload("res://scripts/hub/hub_facility.gd")
const Equipment = preload("res://scripts/meta/equipment.gd")
const QuestDefs = preload("res://scripts/meta/quest_defs.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")

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
var _mode: String = ""
var _selected_quest: String = ""


func _ready() -> void:
	_build_hub()
	_spawn_player()
	panel.visible = false
	stash_grid.visible = false
	btn_close.pressed.connect(_close_panel)
	btn_a.pressed.connect(_on_btn_a)
	btn_b.pressed.connect(_on_btn_b)
	btn_c.pressed.connect(_on_btn_c)
	btn_close.text = Loc.t("hub.close")
	hud.get_node("HintLabel").text = Loc.t("hint.hub")
	_refresh_status()
	MetaProgress.changed.connect(_refresh_status)
	AudioManager.play_bgm()


func _process(_delta: float) -> void:
	if player == null:
		return
	if panel.visible:
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
	player.toast.connect(func(t): _toast(t))


func _refresh_status() -> void:
	hud.get_node("StatusLabel").text = "%s | %s | %s" % [
		Loc.t("hud.mind", [MetaProgress.mind_level]),
		Loc.t("hud.gold", [MetaProgress.gold]),
		_quest_status_text(),
	]


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
	var mat_text := Loc.t("quest.reward_mats_none") if mat_parts.is_empty() else ", ".join(mat_parts)
	return Loc.t("quest.reward", [gold, mat_text])


func _open_board() -> void:
	_mode = "board"
	_show_text_panel()
	panel_title.text = Loc.t("hub.board_title")
	var lines: PackedStringArray = []
	if MetaProgress.active_quest_id != "":
		var cur: Dictionary = QuestDefs.get_def(MetaProgress.active_quest_id)
		lines.append(Loc.t("hub.quest_active", [Loc.t(str(cur.get("name_key")))]))
		lines.append(Loc.t(str(cur.get("desc_key"))))
		lines.append(_quest_reward_line(cur))
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
			lines.append("%d) %s — %s" % [i + 1, Loc.t(str(d.get("name_key"))), Loc.t(str(d.get("desc_key")))])
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
	lines.append(_weight_line(lvl, "hub.quiet_weights"))
	if lvl < 5:
		lines.append(_weight_line(lvl + 1, "hub.quiet_effect"))
	else:
		lines.append(Loc.t("hub.quiet_max"))
	panel_body.text = "\n".join(lines)
	btn_a.text = Loc.t("hub.quiet_do")
	btn_a.visible = lvl < 5
	btn_b.visible = false
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
	panel_body.visible = true
	panel_body.text = Loc.t("hub.stash_hint") if not MetaProgress.stash.is_empty() else Loc.t("hub.stash_empty")
	panel_body.offset_bottom = 80.0
	stash_grid.visible = true
	if stash_grid.has_method("set_stash_dict"):
		stash_grid.set_stash_dict(MetaProgress.stash)
	btn_a.visible = false
	btn_b.visible = false
	btn_c.visible = false


func _show_text_panel() -> void:
	panel.visible = true
	stash_grid.visible = false
	panel_body.visible = true
	panel_body.offset_bottom = 280.0


func _open_pit() -> void:
	_mode = "pit"
	_show_text_panel()
	panel_title.text = Loc.t("hub.enter")
	panel_body.text = Loc.t("hub.enter_pit")
	btn_a.text = Loc.t("hub.enter")
	btn_a.visible = true
	btn_b.visible = false
	btn_c.visible = false


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
			_enter_pit()


func _on_btn_b() -> void:
	match _mode:
		"board":
			_accept_quest_index(1)
		"alchemy":
			_craft(Equipment.SLOT_AMULET)


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


func _enter_pit() -> void:
	RunSession.begin_run()
	get_tree().change_scene_to_file("res://scenes/pit/pit_floor_01.tscn")


func _close_panel() -> void:
	panel.visible = false
	stash_grid.visible = false
	_mode = ""


func _toast(text: String) -> void:
	var toast: Label = hud.get_node("ToastLabel")
	toast.text = text
	toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
