extends Control
## 火炬之光 2 式底栏：左血球、中技能槽、右侵蚀球。

const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")

const SLOTS := ["rmb", "q", "e", "r", "f", "c"]
const LABELS := ["RMB", "Q", "E", "R", "F", "C"]
const HUD_W := 680.0
const HUD_H := 168.0
const ORB_R := 48.0

var _player: Node = null
var _slot_nodes: Dictionary = {}
var _hp: float = 1.0
var _max_hp: float = 1.0
var _erosion: float = 0.0
var _erosion_max: float = 100.0
var _erosion_tier: int = 0
var _xp_bar: ProgressBar
var _xp_label: Label
var _mind_text: Label
var _mind_bar: ProgressBar
var _mind_cur: int = 0
var _mind_max: int = 1
var _hp_text: Label
var _res_text: Label
var _status_row: HBoxContainer
var _status_sig: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -HUD_W * 0.5
	offset_right = HUD_W * 0.5
	offset_top = -HUD_H
	offset_bottom = 0.0
	custom_minimum_size = Vector2(HUD_W, HUD_H)
	_build()


func bind_player(p: Node) -> void:
	_player = p
	queue_redraw()


func set_vitals(hp: float, max_hp: float) -> void:
	_hp = hp
	_max_hp = max_hp
	if _hp_text:
		_hp_text.text = "%d\n%d" % [int(round(hp)), int(round(max_hp))]
	queue_redraw()


func set_erosion(value: float, max_value: float, tier: int) -> void:
	_erosion = value
	_erosion_max = max_value
	_erosion_tier = tier
	if _res_text:
		if tier > 0:
			_res_text.text = Loc.t("hud.erosion_tier_short", [tier])
		else:
			_res_text.text = Loc.t("hud.erosion_value", [int(round(value)), int(round(max_value))])
	queue_redraw()


func set_xp(level: int, xp: int, xp_next: int) -> void:
	var next_v := maxi(xp_next, 1)
	var ratio := clampf(float(xp) / float(next_v), 0.0, 1.0)
	var pct := int(round(ratio * 100.0))
	if _xp_bar:
		_xp_bar.max_value = 1.0
		_xp_bar.value = ratio
	if _xp_label:
		_xp_label.text = Loc.t("hud.xp_bar", [level, xp, next_v, pct])


func set_mind_line(text: String) -> void:
	if _mind_text:
		_mind_text.text = text


func set_mind(current: int, maximum: int) -> void:
	_mind_cur = current
	_mind_max = maxi(maximum, 1)
	var ratio := clampf(float(current) / float(_mind_max), 0.0, 1.0)
	if _mind_bar:
		_mind_bar.max_value = 1.0
		_mind_bar.value = ratio
	if _mind_text:
		_mind_text.text = Loc.t("hud.mind_value_cap", [current, _mind_max])


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_slot_nodes.clear()

	_status_row = HBoxContainer.new()
	_status_row.name = "StatusRow"
	_status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_status_row.position = Vector2(88, 4)
	_status_row.size = Vector2(HUD_W - 176, 28)
	_status_row.add_theme_constant_override("separation", 6)
	_status_row.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_status_row)

	var tray := Panel.new()
	tray.name = "Tray"
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.position = Vector2(88, 36)
	tray.size = Vector2(HUD_W - 176, 108)
	var tray_style := StyleBoxFlat.new()
	tray_style.bg_color = Color(0.10, 0.07, 0.05, 0.94)
	tray_style.border_color = Color(0.58, 0.44, 0.22, 1)
	tray_style.set_border_width_all(2)
	tray_style.corner_radius_top_left = 6
	tray_style.corner_radius_top_right = 6
	tray_style.corner_radius_bottom_left = 6
	tray_style.corner_radius_bottom_right = 6
	tray_style.shadow_color = Color(0, 0, 0, 0.45)
	tray_style.shadow_size = 6
	tray.add_theme_stylebox_override("panel", tray_style)
	add_child(tray)

	_xp_bar = ProgressBar.new()
	_xp_bar.name = "XpBar"
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 1.0
	_xp_bar.value = 0.0
	_xp_bar.position = Vector2(10, 4)
	_xp_bar.size = Vector2(tray.size.x - 20, 16)
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.08, 0.06, 0.04, 1)
	xp_bg.corner_radius_top_left = 3
	xp_bg.corner_radius_top_right = 3
	xp_bg.corner_radius_bottom_left = 3
	xp_bg.corner_radius_bottom_right = 3
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.86, 0.68, 0.22, 1)
	xp_fill.corner_radius_top_left = 3
	xp_fill.corner_radius_top_right = 3
	xp_fill.corner_radius_bottom_left = 3
	xp_fill.corner_radius_bottom_right = 3
	_xp_bar.add_theme_stylebox_override("background", xp_bg)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	tray.add_child(_xp_bar)
	_xp_label = Label.new()
	_xp_label.name = "XpLabel"
	_xp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_xp_label.add_theme_font_size_override("font_size", 11)
	_xp_label.add_theme_color_override("font_color", Color(1, 0.96, 0.82, 1))
	_xp_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02, 0.9))
	_xp_label.add_theme_constant_override("outline_size", 4)
	_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.add_child(_xp_label)

	var row := HBoxContainer.new()
	row.name = "Slots"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.position = Vector2(8, 24)
	row.size = Vector2(tray.size.x - 16, 52)
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(row)

	for i in SLOTS.size():
		var slot_id: String = SLOTS[i]
		var slot_wrap := Control.new()
		slot_wrap.custom_minimum_size = Vector2(52, 52)
		slot_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(slot_wrap)
		var panel := Panel.new()
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.07, 0.06, 0.05, 0.96)
		style.border_color = Color(0.70, 0.56, 0.28, 1)
		style.set_border_width_all(2)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", style)
		slot_wrap.add_child(panel)
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
		var cd := ColorRect.new()
		cd.name = "Cd"
		cd.color = Color(0.04, 0.04, 0.08, 0.62)
		cd.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(cd)
		var key := Label.new()
		key.name = "Key"
		key.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		key.offset_top = -16
		key.offset_bottom = -1
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.add_theme_font_size_override("font_size", 11)
		key.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62, 1))
		key.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		key.add_theme_constant_override("outline_size", 4)
		key.text = LABELS[i]
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(key)
		_slot_nodes[slot_id] = panel

	_mind_bar = ProgressBar.new()
	_mind_bar.name = "MindBar"
	_mind_bar.show_percentage = false
	_mind_bar.max_value = 1.0
	_mind_bar.value = 1.0
	_mind_bar.position = Vector2(10, 80)
	_mind_bar.size = Vector2(tray.size.x - 20, 14)
	_mind_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mind_bg := StyleBoxFlat.new()
	mind_bg.bg_color = Color(0.06, 0.08, 0.12, 1)
	mind_bg.corner_radius_top_left = 3
	mind_bg.corner_radius_top_right = 3
	mind_bg.corner_radius_bottom_left = 3
	mind_bg.corner_radius_bottom_right = 3
	var mind_fill := StyleBoxFlat.new()
	mind_fill.bg_color = Color(0.32, 0.58, 0.92, 1)
	mind_fill.corner_radius_top_left = 3
	mind_fill.corner_radius_top_right = 3
	mind_fill.corner_radius_bottom_left = 3
	mind_fill.corner_radius_bottom_right = 3
	_mind_bar.add_theme_stylebox_override("background", mind_bg)
	_mind_bar.add_theme_stylebox_override("fill", mind_fill)
	tray.add_child(_mind_bar)
	_mind_text = Label.new()
	_mind_text.name = "MindText"
	_mind_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mind_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mind_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mind_text.add_theme_font_size_override("font_size", 11)
	_mind_text.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0, 1))
	_mind_text.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.12, 0.9))
	_mind_text.add_theme_constant_override("outline_size", 4)
	_mind_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mind_bar.add_child(_mind_text)

	_hp_text = Label.new()
	_hp_text.name = "HpText"
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_text.position = Vector2(8, HUD_H - 78)
	_hp_text.size = Vector2(88, 40)
	_hp_text.add_theme_font_size_override("font_size", 13)
	_hp_text.add_theme_color_override("font_color", Color(1, 0.92, 0.88, 1))
	_hp_text.add_theme_color_override("font_outline_color", Color(0.15, 0.02, 0.02, 0.9))
	_hp_text.add_theme_constant_override("outline_size", 5)
	_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_text)

	_res_text = Label.new()
	_res_text.name = "ResText"
	_res_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_res_text.position = Vector2(HUD_W - 96, HUD_H - 70)
	_res_text.size = Vector2(88, 28)
	_res_text.add_theme_font_size_override("font_size", 12)
	_res_text.add_theme_color_override("font_color", Color(0.92, 0.84, 1.0, 1))
	_res_text.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.12, 0.9))
	_res_text.add_theme_constant_override("outline_size", 5)
	_res_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_res_text)


func _draw() -> void:
	var hp_c := Vector2(52, HUD_H - 58)
	var res_c := Vector2(HUD_W - 52, HUD_H - 58)
	var hp_ratio := clampf(_hp / maxf(_max_hp, 1.0), 0.0, 1.0)
	var er_ratio := clampf(_erosion / maxf(_erosion_max, 1.0), 0.0, 1.0)
	_draw_orb(hp_c, ORB_R, hp_ratio, Color(0.72, 0.10, 0.10), Color(0.95, 0.38, 0.28))
	_draw_orb(res_c, ORB_R, er_ratio, Color(0.28, 0.10, 0.42), Color(0.70, 0.42, 0.92))


func _draw_orb(center: Vector2, radius: float, ratio: float, fill: Color, highlight: Color) -> void:
	draw_circle(center, radius + 5.0, Color(0.18, 0.12, 0.06, 1))
	draw_circle(center, radius + 3.0, Color(0.68, 0.52, 0.24, 1))
	draw_circle(center, radius, Color(0.05, 0.04, 0.04, 1))
	var r := clampf(ratio, 0.0, 1.0)
	if r > 0.001:
		var water_y := center.y + radius - 2.0 * radius * r
		var pts := PackedVector2Array()
		var steps := 48
		for i in steps + 1:
			var a := -PI * 0.5 + TAU * float(i) / float(steps)
			var p := center + Vector2(cos(a), sin(a)) * (radius - 2.5)
			if p.y >= water_y - 0.05:
				pts.append(p)
		if pts.size() >= 3:
			draw_colored_polygon(pts, fill)
			if pts.size() >= 2:
				draw_line(pts[0], pts[pts.size() - 1], Color(highlight.r, highlight.g, highlight.b, 0.45), 2.0)
	draw_arc(center, radius - 1.0, 0.0, TAU, 52, Color(0.92, 0.78, 0.42, 0.5), 1.6)
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.34), radius * 0.16, Color(1, 1, 1, 0.16))


func _collect_statuses() -> Array:
	var items: Array = []
	if _erosion_tier >= 1:
		var ekey := "hud.status.erosion.tip%d" % mini(_erosion_tier, 3)
		items.append({
			"id": "erosion",
			"text": Loc.t("hud.status.erosion", [_erosion_tier]),
			"tip": Loc.t(ekey) if Loc.has_key(ekey) else Loc.t("hud.status.erosion.tip1"),
			"abnormal": true,
		})
	if _player == null:
		return items
	if bool(_player.get("in_mud")):
		items.append({
			"id": "mud",
			"text": Loc.t("hud.status.mud"),
			"tip": Loc.t("hud.status.mud.tip"),
			"abnormal": true,
		})
	if bool(_player.get("in_fog")):
		items.append({
			"id": "fog",
			"text": Loc.t("hud.status.fog"),
			"tip": Loc.t("hud.status.fog.tip"),
			"abnormal": false,
		})
	if float(_player.get("skill_cd_mult")) > 1.04:
		items.append({
			"id": "metal",
			"text": Loc.t("hud.status.metal"),
			"tip": Loc.t("hud.status.metal.tip"),
			"abnormal": true,
		})
	if _player.has_method("is_skill_slot_locked"):
		for slot in SLOTS:
			if bool(_player.is_skill_slot_locked(slot)):
				items.append({
					"id": "lock",
					"text": Loc.t("hud.status.lock"),
					"tip": Loc.t("hud.status.lock.tip"),
					"abnormal": true,
				})
				break
	if _player.has_method("carry_cap") and _player.get("inventory") != null:
		var inv = _player.inventory
		if inv != null and inv.has_method("current_weight"):
			if float(inv.current_weight()) > float(_player.carry_cap()) + 0.01:
				items.append({
					"id": "heavy",
					"text": Loc.t("hud.status.heavy"),
					"tip": Loc.t("hud.status.heavy.tip"),
					"abnormal": true,
				})
	return items


func _rebuild_status_chips(items: Array) -> void:
	if _status_row == null:
		return
	for c in _status_row.get_children():
		c.queue_free()
	for it in items:
		var abnormal: bool = bool(it.get("abnormal", false))
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.tooltip_text = str(it.get("tip", it.get("text", "")))
		var style := StyleBoxFlat.new()
		if abnormal:
			style.bg_color = Color(0.28, 0.06, 0.06, 0.92)
			style.border_color = Color(0.95, 0.22, 0.18, 1)
		else:
			style.bg_color = Color(0.12, 0.10, 0.08, 0.88)
			style.border_color = Color(0.72, 0.58, 0.28, 1)
		style.set_border_width_all(2)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		chip.add_theme_stylebox_override("panel", style)
		var lab := Label.new()
		lab.text = str(it.get("text", ""))
		lab.add_theme_font_size_override("font_size", 12)
		lab.add_theme_color_override("font_color", Color(1, 0.86, 0.82, 1) if abnormal else Color(0.95, 0.90, 0.78, 1))
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(lab)
		_status_row.add_child(chip)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var statuses := _collect_statuses()
	var sig := str(statuses)
	if sig != _status_sig:
		_status_sig = sig
		_rebuild_status_chips(statuses)
	if "hp" in _player and "max_hp" in _player:
		var hp_v: float = float(_player.hp)
		var max_v: float = float(_player.max_hp)
		if absf(hp_v - _hp) > 0.05 or absf(max_v - _max_hp) > 0.05:
			set_vitals(hp_v, max_v)
	set_mind(MetaProgress.mind_value, MetaProgress.mind_value_max())
	for slot_id in SLOTS:
		var panel: Panel = _slot_nodes.get(slot_id)
		if panel == null:
			continue
		var core_id := ""
		if _player.has_method("skill_in_slot"):
			core_id = str(_player.skill_in_slot(slot_id))
		var icon: TextureRect = panel.get_node("Icon")
		var path := ""
		if SkillCatalog.has_id(core_id):
			path = SkillCatalog.fallback_icon(core_id)
		else:
			path = CrystalCatalog.icon_path(core_id)
		if path != "" and ResourceLoader.exists(path):
			icon.texture = load(path)
			icon.modulate = Color.WHITE
		else:
			icon.texture = null
			icon.modulate = Color(1, 1, 1, 0.22)
		var cd_rect: ColorRect = panel.get_node("Cd")
		var ratio := 0.0
		if _player.has_method("skill_cd_ratio"):
			ratio = float(_player.skill_cd_ratio(slot_id))
		cd_rect.anchor_top = 1.0 - clampf(ratio, 0.0, 1.0)
		cd_rect.visible = ratio > 0.01
		var locked := false
		if _player.has_method("is_skill_slot_locked"):
			locked = bool(_player.is_skill_slot_locked(slot_id))
		var cost := 0
		if core_id != "":
			if SkillCatalog.has_id(core_id):
				cost = SkillCatalog.cast_cost(core_id, MetaProgress.skill_rank(core_id))
			else:
				cost = CrystalCatalog.cast_cost(core_id)
		var no_mind := cost > 0 and not MetaProgress.is_skill_sandbox_active() and MetaProgress.mind_value < cost
		if locked:
			panel.modulate = Color(0.45, 0.42, 0.4, 1)
		elif no_mind:
			panel.modulate = Color(0.45, 0.52, 0.72, 1)
		else:
			panel.modulate = Color.WHITE
