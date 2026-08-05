extends Control
## 角色属性面板。外壳用素材；内容按底图青/金框内边 2× 落位。

const Equipment = preload("res://scripts/meta/equipment.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")

signal closed

const ART_SIZE := Vector2(320, 240)
const SCALE := 2.0
const PANEL_SIZE := ART_SIZE * SCALE ## 640×480

## 底图实测（320×240）：
## 外描边在 x0/x319；左青框 x12–191 y32–227；右金框 x200–307 y32–227
## 关闭钮烤在图上约 x300–315 y4–19。内容再内收 5px，避免贴线。
const SRC_LEFT := Rect2(17, 37, 169, 185)
const SRC_RIGHT := Rect2(205, 37, 97, 185)
## 顶栏约 y3–20；标题整栏水平居中
const SRC_HEADER := Rect2(0, 3, 320, 17)
const SRC_CLOSE := Rect2(300, 4, 16, 16)

const ACCENT_TEAL := Color(0.24, 0.55, 0.48, 1)
const ACCENT_GOLD := Color(0.91, 0.66, 0.22, 1)
const ROW_BG := Color(0.11, 0.10, 0.09, 0.97)
const ROW_BG_DIM := Color(0.09, 0.08, 0.07, 0.88)

var _player: Node = null
var _row_nodes: Dictionary = {}
var _built: bool = false


func _ready() -> void:
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_shell()
	_build_layout()
	if has_node("CloseBtn"):
		$CloseBtn.pressed.connect(close)


func _s(v: float) -> float:
	return v * SCALE


func _place(ctrl: Control, src: Rect2) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = src.position * SCALE
	ctrl.size = src.size * SCALE
	ctrl.custom_minimum_size = src.size * SCALE


func _apply_shell() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -PANEL_SIZE.x * 0.5
	offset_top = -PANEL_SIZE.y * 0.5
	offset_right = PANEL_SIZE.x * 0.5
	offset_bottom = PANEL_SIZE.y * 0.5

	if has_node("Bg"):
		var bg: TextureRect = $Bg
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if has_node("Title"):
		var t: Label = $Title
		_place(t, SRC_HEADER)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.add_theme_font_size_override("font_size", int(round(12 * SCALE)))
		t.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75, 1))
		t.text = Loc.t("stat.panel_title") if Loc.has_key("stat.panel_title") else "属性"
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if has_node("CloseBtn"):
		_place($CloseBtn, SRC_CLOSE)
		$CloseBtn.ignore_texture_size = true
		$CloseBtn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		# 底图已烤关闭钮，按钮只做点击热区
		$CloseBtn.modulate = Color(1, 1, 1, 0)


func _build_layout() -> void:
	if _built:
		return
	_built = true
	_free_child_named("LeftClip")
	_free_child_named("RightClip")
	_free_child_named("Rows")
	_free_child_named("Equip")

	var keys := [
		"Hp", "MindVal", "MindLv", "Vit", "Str", "Patk", "Pdef", "Agi", "Int", "Crit", "CritDmg",
	]
	var ekeys := ["Weapon", "Chest", "Pendant"]

	var left_clip := Control.new()
	left_clip.name = "LeftClip"
	_place(left_clip, SRC_LEFT)
	left_clip.clip_contents = true
	left_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_clip)

	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rows.add_theme_constant_override("separation", 1)
	left_clip.add_child(rows)

	for k in keys:
		var row := _make_stat_row(k)
		_row_nodes[k] = row
		rows.add_child(row)

	var right_clip := Control.new()
	right_clip.name = "RightClip"
	_place(right_clip, SRC_RIGHT)
	right_clip.clip_contents = true
	right_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_clip)

	var equip := VBoxContainer.new()
	equip.name = "Equip"
	equip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	equip.add_theme_constant_override("separation", 4)
	right_clip.add_child(equip)

	for ek in ekeys:
		var slot := _make_equip_slot(ek)
		_row_nodes[ek] = slot
		equip.add_child(slot)


func _free_child_named(child_name: String) -> void:
	if not has_node(child_name):
		return
	var n: Node = get_node(child_name)
	remove_child(n)
	n.free()


func _row_style(accent: Color, dim: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ROW_BG_DIM if dim else ROW_BG
	style.border_color = accent.darkened(0.2) if dim else accent
	style.set_border_width_all(1)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _make_stat_row(key: String) -> Panel:
	var panel := Panel.new()
	panel.name = key
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _row_style(ACCENT_TEAL))

	var margin := MarginContainer.new()
	margin.name = "Pad"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 1)
	margin.add_theme_constant_override("margin_bottom", 1)
	panel.add_child(margin)

	var hb := HBoxContainer.new()
	hb.name = "Content"
	hb.add_theme_constant_override("separation", 4)
	margin.add_child(hb)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(14, 14)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(icon)

	var line := Label.new()
	line.name = "Line"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_theme_font_size_override("font_size", 14)
	line.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1))
	line.text = key
	hb.add_child(line)
	return panel


func _make_equip_slot(key: String) -> Panel:
	var panel := Panel.new()
	panel.name = key
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _row_style(ACCENT_GOLD))

	var margin := MarginContainer.new()
	margin.name = "Pad"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var hb := HBoxContainer.new()
	hb.name = "Content"
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 6)
	margin.add_child(hb)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(icon)

	var line := Label.new()
	line.name = "Line"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_theme_font_size_override("font_size", 15)
	line.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1))
	line.text = key
	hb.add_child(line)
	return panel


func bind_player(p: Node) -> void:
	_player = p


func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func refresh() -> void:
	if _player == null:
		return
	if not _built:
		_build_layout()
	var st = _player.stats
	_set_row("Hp", "icon_hp", Loc.t("stat.hp"), "%d/%d" % [int(_player.hp), int(_player.max_hp)], true)
	_set_row("MindVal", "icon_mind", Loc.t("stat.mind_value"), "%d/%d" % [MetaProgress.mind_value, MetaProgress.mind_value_max()], true)
	_set_row("MindLv", "icon_mind_lv", Loc.t("stat.mind_level"), str(MetaProgress.mind_level), true)
	_set_row("Vit", "icon_vitality", Loc.t("stat.vitality"), "%.0f" % st.vitality, true)
	_set_row("Str", "icon_str", Loc.t("stat.strength"), "%.0f" % st.strength, true)
	_set_row("Patk", "icon_patk", Loc.t("stat.patk"), "%.1f" % st.patk, true)
	_set_row("Pdef", "icon_pdef", Loc.t("stat.pdef"), "%.1f" % st.pdef, true)
	_set_row("Agi", "icon_agi", Loc.t("stat.agi"), "—", false)
	_set_row("Int", "icon_int", Loc.t("stat.int"), "—", false)
	_set_row("Crit", "icon_crit", Loc.t("stat.crit"), ("%.0f%%" % (st.crit * 100.0)) if st.crit_enabled else "—", st.crit_enabled)
	_set_row("CritDmg", "icon_critdmg", Loc.t("stat.critdmg"), ("%.0f%%" % (st.critdmg * 100.0)) if st.critdmg_enabled else "—", st.critdmg_enabled)

	_set_equip_weapon()
	_set_equip_slot("Chest", Equipment.SLOT_CHEST, "res://assets/ui/icons/stats/equip_chest.png", "res://assets/ui/icons/stats/slot_chest.png")
	_set_equip_slot("Pendant", Equipment.SLOT_AMULET, "res://assets/ui/icons/stats/equip_pendant.png", "res://assets/ui/icons/stats/slot_pendant.png")


func _set_row(key: String, icon_name: String, label: String, value: String, enabled: bool) -> void:
	if not _row_nodes.has(key):
		return
	var row: Panel = _row_nodes[key]
	var icon: TextureRect = row.get_node("Pad/Content/Icon")
	var line: Label = row.get_node("Pad/Content/Line")
	icon.texture = load("res://assets/ui/icons/stats/%s.png" % icon_name) as Texture2D
	line.text = "%s：%s" % [label, value]
	var col := Color.WHITE if enabled else Color(0.55, 0.5, 0.45, 1)
	line.modulate = col
	icon.modulate = col if enabled else Color(0.55, 0.5, 0.45, 1)
	row.add_theme_stylebox_override("panel", _row_style(ACCENT_TEAL, not enabled))


func _set_equip_weapon() -> void:
	if not _row_nodes.has("Weapon"):
		return
	var slot: Panel = _row_nodes["Weapon"]
	var brand: String = str(_player.brand_quality) if _player else "iron"
	var brand_name: String = Loc.t(str(MindTable.BRAND_STATS.get(brand, {}).get("name_key", "brand.iron")))
	var icon: TextureRect = slot.get_node("Pad/Content/Icon")
	var path := "res://assets/brands/brand_%s.png" % brand
	if ResourceLoader.exists(path):
		icon.texture = load(path)
	else:
		icon.texture = load("res://assets/ui/icons/stats/slot_weapon.png")
	slot.get_node("Pad/Content/Line").text = "%s·%s" % [Loc.t("stat.weapon"), brand_name]


func _set_equip_slot(key: String, slot_id: String, owned_icon: String, empty_icon: String) -> void:
	if not _row_nodes.has(key):
		return
	var slot: Panel = _row_nodes[key]
	var data: Dictionary = MetaProgress.equipment.get(slot_id, {})
	var owned := bool(data.get("owned", false))
	slot.get_node("Pad/Content/Icon").texture = load(owned_icon if owned else empty_icon)
	var eq_name: String = Loc.t("equip.chest" if slot_id == Equipment.SLOT_CHEST else "equip.amulet")
	var eline: String
	if owned:
		eline = "%s %+d" % [eq_name, int(data.get("upgrade", 0))]
	else:
		eline = "%s·%s" % [eq_name, Loc.t("equip.not_owned")]
	slot.get_node("Pad/Content/Line").text = eline
