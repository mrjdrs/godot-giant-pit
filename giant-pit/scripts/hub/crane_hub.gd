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
@onready var btn_a: Button = $HUD/Panel/BtnA
@onready var btn_b: Button = $HUD/Panel/BtnB
@onready var btn_c: Button = $HUD/Panel/BtnC
@onready var btn_close: Button = $HUD/Panel/BtnClose

var player: CharacterBody2D = null
var _mode: String = ""
var _selected_quest: String = ""


func _ready() -> void:
	_build_hub()
	_spawn_player()
	panel.visible = false
	btn_close.pressed.connect(_close_panel)
	btn_a.pressed.connect(_on_btn_a)
	btn_b.pressed.connect(_on_btn_b)
	btn_c.pressed.connect(_on_btn_c)
	btn_close.text = Loc.t("hub.close")
	hud.get_node("HintLabel").text = Loc.t("hint.hub")
	_refresh_status()
	MetaProgress.changed.connect(_refresh_status)


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


func _open_board() -> void:
	_mode = "board"
	panel.visible = true
	panel_title.text = Loc.t("hub.board_title")
	var lines: PackedStringArray = []
	if MetaProgress.active_quest_id != "":
		var cur: Dictionary = QuestDefs.get_def(MetaProgress.active_quest_id)
		lines.append("进行中：%s" % Loc.t(str(cur.get("name_key"))))
		lines.append(Loc.t(str(cur.get("desc_key"))))
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
		btn_a.text = Loc.t("hub.accept") + "①"
		btn_b.text = Loc.t("hub.accept") + "②"
		btn_c.text = Loc.t("hub.accept") + "③"
		btn_a.visible = true
		btn_b.visible = true
		btn_c.visible = true
	panel_body.text = "\n".join(lines)


func _open_quiet() -> void:
	_mode = "quiet"
	panel.visible = true
	panel_title.text = Loc.t("hub.quiet_title")
	var cost := MindTable.cost_to_next(MetaProgress.mind_level)
	panel_body.text = Loc.t("hub.quiet_hint", [MetaProgress.mind_level, cost])
	btn_a.text = Loc.t("hub.quiet_do")
	btn_a.visible = true
	btn_b.visible = false
	btn_c.visible = false


func _open_alchemy() -> void:
	_mode = "alchemy"
	panel.visible = true
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
			lines.append("  生命+%.0f 防御+%.0f 伤害+%.0f%%" % [st.max_hp, st.defense, st.damage * 100.0])
		else:
			lines.append("%s：%s" % [Loc.t(name_key), Loc.t("equip.not_owned")])
	return "\n".join(lines)


func _open_stash() -> void:
	_mode = "stash"
	panel.visible = true
	panel_title.text = Loc.t("hub.stash_title")
	var lines: PackedStringArray = MetaProgress.describe_stash()
	panel_body.text = Loc.t("hub.stash_empty") if lines.is_empty() else "\n".join(lines)
	btn_a.visible = false
	btn_b.visible = false
	btn_c.visible = false


func _open_pit() -> void:
	_mode = "pit"
	panel.visible = true
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
				_toast("已放弃委托")
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
		_toast("已拥有")
	else:
		_toast(Loc.t("hub.no_mats"))
	_open_alchemy()


func _upgrade_any() -> void:
	## 优先强化胸甲，否则挂坠
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
	_mode = ""


func _toast(text: String) -> void:
	var toast: Label = hud.get_node("ToastLabel")
	toast.text = text
	toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
