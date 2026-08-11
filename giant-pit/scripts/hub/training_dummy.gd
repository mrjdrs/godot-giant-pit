extends Node2D
## 鹤城试刀场：可放技能、随意改等级，离场还原存档加点。不入坑。

const AtmosphereScript = preload("res://scripts/fx/scene_atmosphere.gd")
const SkillBarScript = preload("res://scripts/ui/skill_bar.gd")
const SheetHostScript = preload("res://scripts/ui/character_sheet_host.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const InteractableScript = preload("res://scripts/pit/interactable.gd")

const HUB_SCENE := "res://scenes/hub/crane_hub.tscn"

@export var floor_texture: Texture2D
@export var arena_size: Vector2i = Vector2i(14, 10)
@export var tile_size: int = 32

@onready var floor_tiles: Node2D = $Floor/FloorTiles

var player: CharacterBody2D = null
var sheet_host: CanvasLayer = null
var _skill_bar: Control = null
var _restored: bool = false


func _ready() -> void:
	MetaProgress.begin_skill_sandbox()
	_build_floor()
	AtmosphereScript.install(self, self, "arena")
	var hint := get_node_or_null("Hint/HintLabel")
	if hint:
		hint.text = Loc.t("hint.training_dummy")
	player = get_node_or_null("Player")
	if player:
		player.side_view = false
		player.combat_enabled = true
		player.skills.persist_slots = false
		MetaProgress.mind_value = MetaProgress.mind_value_max()
		if player.has_method("apply_meta_brand"):
			player.apply_meta_brand("iron")
		if player.has_node("Camera2D"):
			player.get_node("Camera2D").zoom = Vector2(3.0, 3.0)
		if player.has_method("set_camera_limits"):
			player.set_camera_limits(-280.0, -200.0, 280.0, 200.0)
		if not player.hp_changed.is_connected(_on_player_hp_changed):
			player.hp_changed.connect(_on_player_hp_changed)
		if player.has_signal("toast") and not player.toast.is_connected(_on_toast):
			player.toast.connect(_on_toast)
	var dummy := get_node_or_null("DummyEnemy")
	if dummy:
		dummy.max_hp = 400.0
		dummy.hp = 400.0
		if dummy.has_method("_update_hp_label"):
			dummy._update_hp_label()
	_add_return_pad()
	_ensure_skill_bar()
	_ensure_sheet_host()
	_ensure_hud_buttons()
	PauseMenuScript.install(self)
	_sync_skill_bar()
	if not MetaProgress.changed.is_connected(_on_meta_changed):
		MetaProgress.changed.connect(_on_meta_changed)


func _on_meta_changed() -> void:
	_refresh_imprint_buttons()
	_refresh_element_buttons()
	_sync_skill_bar()


func _exit_tree() -> void:
	if MetaProgress.changed.is_connected(_on_meta_changed):
		MetaProgress.changed.disconnect(_on_meta_changed)
	_restore_sandbox()


func return_to_hub() -> void:
	_restore_sandbox()
	get_tree().change_scene_to_file(HUB_SCENE)


func _restore_sandbox() -> void:
	if _restored:
		return
	_restored = true
	MetaProgress.end_skill_sandbox()


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
	_sync_skill_bar()
	var prompt := get_node_or_null("Hint/PromptLabel")
	if prompt == null or player == null:
		return
	if sheet_host and sheet_host.any_open():
		prompt.text = ""
		return
	prompt.text = player.get_interact_prompt() if player.has_method("get_interact_prompt") else ""


func _ensure_skill_bar() -> void:
	var hud := get_node_or_null("Hint")
	if hud == null:
		return
	if hud.has_node("SkillBar"):
		_skill_bar = hud.get_node("SkillBar")
	else:
		_skill_bar = Control.new()
		_skill_bar.name = "SkillBar"
		_skill_bar.set_script(SkillBarScript)
		hud.add_child(_skill_bar)
	if _skill_bar.has_method("bind_player"):
		_skill_bar.bind_player(player)


func _ensure_sheet_host() -> void:
	if sheet_host != null:
		return
	sheet_host = CanvasLayer.new()
	sheet_host.name = "SheetHost"
	sheet_host.set_script(SheetHostScript)
	add_child(sheet_host)
	if player:
		## hub_mode 用城镇同款技能树壳，training_mode 把感悟换成 +/- 且不写盘
		sheet_host.bind_player(player, true, true)
	sheet_host.panel_closed.connect(func():
		if player:
			player.input_locked = false
	)


func _ensure_hud_buttons() -> void:
	var hud := get_node_or_null("Hint")
	if hud == null:
		return
	if not hud.has_node("HudBtns"):
		var row := HBoxContainer.new()
		row.name = "HudBtns"
		row.position = Vector2(12, 108)
		row.add_theme_constant_override("separation", 8)
		hud.add_child(row)
		var skill_btn := Button.new()
		skill_btn.text = Loc.t("training.open_skills")
		skill_btn.custom_minimum_size = Vector2(120, 32)
		skill_btn.add_theme_font_size_override("font_size", 13)
		skill_btn.pressed.connect(func():
			if sheet_host:
				sheet_host.toggle_skills()
		)
		row.add_child(skill_btn)
		var ret_btn := Button.new()
		ret_btn.text = Loc.t("training.return_hub")
		ret_btn.custom_minimum_size = Vector2(120, 32)
		ret_btn.add_theme_font_size_override("font_size", 13)
		ret_btn.pressed.connect(return_to_hub)
		row.add_child(ret_btn)
	_ensure_imprint_switch(hud)


func _ensure_imprint_switch(hud: Node) -> void:
	if hud.has_node("ImprintRow"):
		_ensure_element_switch(hud)
		return
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var row := HBoxContainer.new()
	row.name = "ImprintRow"
	row.position = Vector2(12, 148)
	row.add_theme_constant_override("separation", 6)
	hud.add_child(row)
	var label := Label.new()
	label.text = Loc.t("training.imprint_switch")
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 1))
	row.add_child(label)
	var opts: Array = [
		[SkillCatalog.FAMILY_COLD, "training.imprint_cold"],
		[SkillCatalog.FAMILY_HOT, "training.imprint_hot"],
		[SkillCatalog.FAMILY_MAGE, "training.imprint_mage"],
	]
	for opt in opts:
		var fam: String = opt[0]
		var btn := Button.new()
		btn.name = "Imprint_%s" % fam
		btn.text = Loc.t(str(opt[1]))
		btn.custom_minimum_size = Vector2(44, 28)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(_on_imprint_pressed.bind(fam))
		row.add_child(btn)
	_refresh_imprint_buttons()
	_ensure_element_switch(hud)


func _ensure_element_switch(hud: Node) -> void:
	if hud.has_node("ElementRow"):
		_refresh_element_buttons()
		return
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var row := HBoxContainer.new()
	row.name = "ElementRow"
	row.position = Vector2(12, 182)
	row.add_theme_constant_override("separation", 6)
	hud.add_child(row)
	var label := Label.new()
	label.text = Loc.t("training.element_switch")
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1))
	row.add_child(label)
	for elem in SkillCatalog.MAGE_ELEMENTS:
		var btn := Button.new()
		btn.name = "Element_%s" % elem
		btn.text = Loc.t("training.element_%s" % elem)
		btn.custom_minimum_size = Vector2(36, 28)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(_on_element_pressed.bind(str(elem)))
		row.add_child(btn)
	_refresh_element_buttons()


func _on_imprint_pressed(family: String) -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var fam := SkillCatalog.normalize_imprint(family)
	if MetaProgress.imprint_family == fam and not SkillCatalog.is_mage_imprint(fam):
		return
	if MetaProgress.imprint_family == fam and SkillCatalog.is_mage_imprint(fam):
		_refresh_element_buttons()
		return
	MetaProgress.set_imprint_family_sandbox(fam)
	MetaProgress.fill_all_skills_sandbox()
	MetaProgress.mind_value = MetaProgress.mind_value_max()
	_after_sandbox_switch()
	_refresh_imprint_buttons()
	_refresh_element_buttons()
	_on_toast(Loc.t("training.imprint_switched", [Loc.t(_imprint_loc_key(fam))]), 0)


func _on_element_pressed(element: String) -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not SkillCatalog.is_mage_imprint(MetaProgress.imprint_family):
		return
	if MetaProgress.mage_element == element:
		return
	MetaProgress.set_mage_element_sandbox(element)
	MetaProgress.fill_all_skills_sandbox()
	MetaProgress.mind_value = MetaProgress.mind_value_max()
	_after_sandbox_switch()
	_refresh_element_buttons()
	_on_toast(Loc.t("training.element_switched", [Loc.t("training.element_%s" % element)]), 0)


func _after_sandbox_switch() -> void:
	if player:
		if player.has_method("_refresh_character_stats"):
			player._refresh_character_stats(true)
		if player.get("_skill_cd") is Dictionary:
			(player.get("_skill_cd") as Dictionary).clear()
		if player.has_signal("loadout_changed"):
			player.loadout_changed.emit()
	if sheet_host and sheet_host.has_method("_refresh_all"):
		sheet_host._refresh_all()
	_sync_skill_bar()


func _imprint_loc_key(family: String) -> String:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	match SkillCatalog.normalize_imprint(family):
		SkillCatalog.FAMILY_HOT:
			return "training.imprint_hot"
		SkillCatalog.FAMILY_MAGE:
			return "training.imprint_mage"
		_:
			return "training.imprint_cold"


func _refresh_imprint_buttons() -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var hud := get_node_or_null("Hint")
	if hud == null or not hud.has_node("ImprintRow"):
		return
	var row: HBoxContainer = hud.get_node("ImprintRow")
	var cur := SkillCatalog.normalize_imprint(MetaProgress.imprint_family)
	for child in row.get_children():
		if child is Button:
			var btn := child as Button
			var fam := SkillCatalog.normalize_imprint(str(btn.name).replace("Imprint_", ""))
			btn.disabled = fam == cur
			btn.modulate = Color(1.15, 1.05, 0.75, 1) if fam == cur else Color.WHITE


func _refresh_element_buttons() -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var hud := get_node_or_null("Hint")
	if hud == null or not hud.has_node("ElementRow"):
		return
	var row: HBoxContainer = hud.get_node("ElementRow")
	var mage := SkillCatalog.is_mage_imprint(MetaProgress.imprint_family)
	row.visible = mage
	if not mage:
		return
	var cur := MetaProgress.mage_element
	for child in row.get_children():
		if child is Button:
			var btn := child as Button
			var elem := str(btn.name).replace("Element_", "")
			btn.disabled = elem == cur
			btn.modulate = Color(1.1, 1.15, 1.25, 1) if elem == cur else Color.WHITE


func _add_return_pad() -> void:
	var area := Area2D.new()
	area.name = "ReturnPad"
	area.set_script(InteractableScript)
	area.prompt_key = "hud.interact_return_hub"
	area.once = false
	area.position = Vector2(-160, 80)
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	if ResourceLoader.exists("res://assets/tiles/hub/hub_quiet_door.png"):
		spr.texture = load("res://assets/tiles/hub/hub_quiet_door.png")
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	area.add_child(spr)
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	cs.shape = circle
	area.add_child(cs)
	var lab := Label.new()
	lab.position = Vector2(-36, -30)
	lab.size = Vector2(72, 18)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 11)
	lab.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75, 1))
	lab.text = Loc.t("training.return_hub")
	area.add_child(lab)
	add_child(area)
	area.interacted.connect(func(_by): return_to_hub())


func _sync_skill_bar() -> void:
	if _skill_bar == null or player == null:
		return
	if _skill_bar.has_method("set_vitals"):
		_skill_bar.set_vitals(player.hp, player.max_hp)
	if _skill_bar.has_method("set_erosion"):
		_skill_bar.set_erosion(0.0, 100.0, 0)
	if _skill_bar.has_method("set_xp"):
		_skill_bar.set_xp(MetaProgress.explorer_level, MetaProgress.explorer_xp, MetaProgress.xp_to_next_level())
	if _skill_bar.has_method("set_mind"):
		_skill_bar.set_mind(MetaProgress.mind_value, MetaProgress.mind_value_max())


func _on_player_hp_changed(_current: float, _maximum: float) -> void:
	_sync_skill_bar()


func _on_toast(text: String, _cat: int = 0, _col: Color = Color.TRANSPARENT) -> void:
	var toast := get_node_or_null("Hint/ToastLabel")
	if toast:
		toast.text = text


func _build_floor() -> void:
	if floor_tiles == null:
		return
	if floor_texture == null:
		floor_texture = load("res://assets/tiles/pit_floor/tile_floor_01.png")
	for child in floor_tiles.get_children():
		child.queue_free()
	var origin := Vector2(
		-arena_size.x * tile_size * 0.5 + tile_size * 0.5,
		-arena_size.y * tile_size * 0.5 + tile_size * 0.5
	)
	for y in arena_size.y:
		for x in arena_size.x:
			var sprite := Sprite2D.new()
			sprite.texture = floor_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = origin + Vector2(x * tile_size, y * tile_size)
			floor_tiles.add_child(sprite)
