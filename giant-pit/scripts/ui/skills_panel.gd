extends Control
## DNF 式冷兵器技能学习面板。城镇感悟 / 坑内仅查看与装配。

const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
const SkillBook = preload("res://scripts/player/skill_book.gd")
const ItemSlotGridScript = preload("res://scripts/ui/item_slot_grid.gd")
const TreeIconScript = preload("res://scripts/ui/skill_tree_icon.gd")
const HotkeySlotScript = preload("res://scripts/ui/skill_hotkey_slot.gd")

signal closed
signal learned(rune_id: String)

const PANEL_SIZE := Vector2(760, 520)
const ACCENT_GOLD := Color(0.91, 0.66, 0.22, 1)
const ACCENT_TEAL := Color(0.24, 0.55, 0.48, 1)
const ACCENT_PURPLE := Color(0.55, 0.38, 0.72, 1)
const PANEL_BG := Color(0.12, 0.11, 0.10, 0.97)
const INNER_BG := Color(0.09, 0.08, 0.07, 0.95)
const TREE_CELL := Vector2(78, 74)
const TREE_ORIGIN := Vector2(44, 36)

const SKILL_SLOT_DEFS := [
	["Rmb", "rmb", true],
	["Q", "q", true],
	["E", "e", true],
	["R", "r", true],
	["F", "f", true],
	["C", "c", true],
]

var _player: Node = null
var _hub_mode: bool = false
var _training_mode: bool = false
var _tab_skill: bool = true
var _selected_id: String = ""
var _list_entries: Array = []
var _tree_icons: Dictionary = {}
var _tree_lines: Control = null
var _built: bool = false


func _ready() -> void:
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild_shell()


func _panel_style(bg: Color, border: Color, border_w: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _rebuild_shell() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -PANEL_SIZE.x * 0.5
	offset_top = -PANEL_SIZE.y * 0.5
	offset_right = PANEL_SIZE.x * 0.5
	offset_bottom = PANEL_SIZE.y * 0.5
	for c in get_children():
		c.queue_free()
	_built = false
	call_deferred("_build_ui")


func _build_ui() -> void:
	if _built:
		return
	_built = true
	_tree_icons.clear()

	var bg := Panel.new()
	bg.name = "PanelBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, ACCENT_TEAL, 2))
	add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(16, 10)
	title.size = Vector2(420, 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75, 1))
	title.add_theme_font_size_override("font_size", 18)
	title.text = Loc.t("skill.panel_title")
	add_child(title)

	var lv_lab := Label.new()
	lv_lab.name = "LevelLabel"
	lv_lab.position = Vector2(430, 12)
	lv_lab.size = Vector2(140, 24)
	lv_lab.add_theme_font_size_override("font_size", 13)
	lv_lab.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68, 1))
	add_child(lv_lab)

	var crystal_lab := Label.new()
	crystal_lab.name = "CrystalLabel"
	crystal_lab.position = Vector2(560, 12)
	crystal_lab.size = Vector2(140, 24)
	crystal_lab.add_theme_font_size_override("font_size", 13)
	crystal_lab.add_theme_color_override("font_color", ACCENT_GOLD)
	add_child(crystal_lab)

	var close_btn := TextureButton.new()
	close_btn.name = "CloseBtn"
	close_btn.position = Vector2(724, 8)
	close_btn.size = Vector2(28, 28)
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/ui/chrome/ui_btn_close.png"):
		close_btn.texture_normal = load("res://assets/ui/chrome/ui_btn_close.png")
	close_btn.pressed.connect(close)
	add_child(close_btn)

	var tabs := HBoxContainer.new()
	tabs.name = "TabRow"
	tabs.position = Vector2(20, 44)
	tabs.size = Vector2(720, 28)
	tabs.add_theme_constant_override("separation", 8)
	add_child(tabs)
	var tab_skill := Button.new()
	tab_skill.name = "TabSkill"
	tab_skill.custom_minimum_size = Vector2(96, 26)
	tab_skill.add_theme_font_size_override("font_size", 13)
	tab_skill.text = Loc.t("skill.tab.skill")
	tab_skill.pressed.connect(func(): _set_tab(true))
	tabs.add_child(tab_skill)
	var tab_attr := Button.new()
	tab_attr.name = "TabAttr"
	tab_attr.custom_minimum_size = Vector2(96, 26)
	tab_attr.add_theme_font_size_override("font_size", 13)
	tab_attr.text = Loc.t("skill.tab.attr")
	tab_attr.pressed.connect(func(): _set_tab(false))
	tabs.add_child(tab_attr)

	var body := HBoxContainer.new()
	body.name = "Body"
	body.position = Vector2(16, 80)
	body.size = Vector2(728, 330)
	body.add_theme_constant_override("separation", 12)
	add_child(body)

	var tree_wrap := Control.new()
	tree_wrap.name = "TreeWrap"
	tree_wrap.custom_minimum_size = Vector2(300, 0)
	tree_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tree_wrap)

	_tree_lines = Control.new()
	_tree_lines.name = "TreeLines"
	_tree_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tree_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tree_lines.draw.connect(_draw_tree_lines)
	tree_wrap.add_child(_tree_lines)

	for i in 4:
		var row_lab := Label.new()
		row_lab.text = "Lv%d" % SkillCatalog.row_level(i)
		row_lab.position = Vector2(4, TREE_ORIGIN.y + float(i) * TREE_CELL.y + 10.0)
		row_lab.size = Vector2(36, 20)
		row_lab.add_theme_font_size_override("font_size", 11)
		row_lab.add_theme_color_override("font_color", Color(0.7, 0.66, 0.55, 1))
		tree_wrap.add_child(row_lab)
	var col_names := ["skill.col.slash", "skill.col.break", "skill.col.force"]
	for c in 3:
		var col_lab := Label.new()
		col_lab.text = Loc.t(col_names[c])
		col_lab.position = Vector2(TREE_ORIGIN.x + float(c) * TREE_CELL.x + 8.0, 4)
		col_lab.size = Vector2(56, 18)
		col_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col_lab.add_theme_font_size_override("font_size", 12)
		col_lab.add_theme_color_override("font_color", ACCENT_GOLD)
		tree_wrap.add_child(col_lab)

	for sid in SkillCatalog.tree_ids():
		var icon := _make_tree_icon(str(sid))
		tree_wrap.add_child(icon)
		_tree_icons[str(sid)] = icon

	var attr_scroll := ScrollContainer.new()
	attr_scroll.name = "AttrScroll"
	attr_scroll.custom_minimum_size = Vector2(300, 0)
	attr_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attr_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	attr_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	attr_scroll.visible = false
	body.add_child(attr_scroll)
	var grid := GridContainer.new()
	grid.name = "RuneGrid"
	grid.columns = 4
	grid.set_script(ItemSlotGridScript)
	grid.slot_count = 8
	grid.columns_count = 4
	grid.slot_size = Vector2(48, 48)
	grid.selectable = true
	grid.use_chrome = true
	attr_scroll.add_child(grid)
	if grid.has_signal("slot_pressed"):
		grid.slot_pressed.connect(_on_rune_pressed)

	var right := VBoxContainer.new()
	right.name = "RightCol"
	right.custom_minimum_size = Vector2(260, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)

	var detail_panel := Panel.new()
	detail_panel.name = "DetailPanel"
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _panel_style(INNER_BG, ACCENT_PURPLE, 1))
	right.add_child(detail_panel)
	var d_icon := TextureRect.new()
	d_icon.name = "DetailIcon"
	d_icon.position = Vector2(10, 10)
	d_icon.size = Vector2(48, 48)
	d_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	d_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_panel.add_child(d_icon)
	var d_text := Label.new()
	d_text.name = "DetailText"
	d_text.position = Vector2(66, 8)
	d_text.size = Vector2(186, 240)
	d_text.add_theme_font_size_override("font_size", 13)
	d_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_text.text = Loc.t("skill.select_hint")
	detail_panel.add_child(d_text)

	var btn_row := HBoxContainer.new()
	btn_row.name = "BtnRow"
	btn_row.add_theme_constant_override("separation", 8)
	right.add_child(btn_row)
	var learn_btn := Button.new()
	learn_btn.name = "LearnBtn"
	learn_btn.custom_minimum_size = Vector2(0, 36)
	learn_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	learn_btn.add_theme_font_size_override("font_size", 14)
	learn_btn.text = Loc.t("skill.learn")
	learn_btn.pressed.connect(_on_learn)
	btn_row.add_child(learn_btn)
	var forget_btn := Button.new()
	forget_btn.name = "ForgetBtn"
	forget_btn.custom_minimum_size = Vector2(0, 36)
	forget_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forget_btn.add_theme_font_size_override("font_size", 14)
	forget_btn.text = Loc.t("skill.forget")
	forget_btn.pressed.connect(_on_forget)
	btn_row.add_child(forget_btn)

	var train_row := HBoxContainer.new()
	train_row.name = "TrainRow"
	train_row.add_theme_constant_override("separation", 8)
	train_row.visible = false
	right.add_child(train_row)
	var max_all_btn := Button.new()
	max_all_btn.name = "MaxAllBtn"
	max_all_btn.custom_minimum_size = Vector2(0, 32)
	max_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	max_all_btn.add_theme_font_size_override("font_size", 13)
	max_all_btn.text = Loc.t("training.max_all")
	max_all_btn.pressed.connect(_on_train_max_all)
	train_row.add_child(max_all_btn)
	var restore_btn := Button.new()
	restore_btn.name = "RestoreBtn"
	restore_btn.custom_minimum_size = Vector2(0, 32)
	restore_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_btn.add_theme_font_size_override("font_size", 13)
	restore_btn.text = Loc.t("training.restore")
	restore_btn.pressed.connect(_on_train_restore)
	train_row.add_child(restore_btn)

	var slots := HBoxContainer.new()
	slots.name = "SkillSlots"
	slots.position = Vector2(16, 420)
	slots.size = Vector2(728, 88)
	slots.add_theme_constant_override("separation", 10)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(slots)
	_build_skill_slots(slots)
	_refresh_tab_style()
	refresh()


func _make_tree_icon(sid: String) -> Panel:
	var p := Panel.new()
	p.name = sid
	p.set_script(TreeIconScript)
	p.set("skill_id", sid)
	p.set("host", self)
	p.custom_minimum_size = Vector2(48, 48)
	p.size = Vector2(48, 48)
	p.position = Vector2(
		TREE_ORIGIN.x + float(SkillCatalog.tree_col(sid)) * TREE_CELL.x,
		TREE_ORIGIN.y + float(SkillCatalog.tree_row(sid)) * TREE_CELL.y
	)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(icon)
	var rank_lab := Label.new()
	rank_lab.name = "Rank"
	rank_lab.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	rank_lab.offset_left = -28
	rank_lab.offset_top = -16
	rank_lab.offset_right = -2
	rank_lab.offset_bottom = -1
	rank_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank_lab.add_theme_font_size_override("font_size", 10)
	rank_lab.add_theme_color_override("font_color", Color(1, 0.92, 0.7, 1))
	rank_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(rank_lab)
	return p


func _build_skill_slots(hb: HBoxContainer) -> void:
	for def in SKILL_SLOT_DEFS:
		var col := VBoxContainer.new()
		col.name = str(def[0])
		col.add_theme_constant_override("separation", 2)
		col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		hb.add_child(col)
		var panel := Panel.new()
		panel.name = "Slot"
		panel.set_script(HotkeySlotScript)
		panel.set("slot_id", str(def[1]))
		panel.set("host", self)
		panel.custom_minimum_size = Vector2(48, 48)
		panel.add_theme_stylebox_override("panel", _panel_style(INNER_BG, ACCENT_GOLD, 1))
		col.add_child(panel)
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
		var label := Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72, 1))
		var label_key := "skill.slot.%s" % str(def[1])
		label.text = Loc.t(label_key) if Loc.has_key(label_key) else str(def[1])
		col.add_child(label)


func bind_player(p: Node, hub_mode: bool = false, training_mode: bool = false) -> void:
	_player = p
	_hub_mode = hub_mode
	_training_mode = training_mode


func open() -> void:
	visible = true
	_selected_id = ""
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _set_tab(skill: bool) -> void:
	_tab_skill = skill
	_selected_id = ""
	_refresh_tab_style()
	refresh()


func _refresh_tab_style() -> void:
	if not has_node("TabRow/TabSkill"):
		return
	var on := _panel_style(INNER_BG, ACCENT_GOLD, 1)
	var off := _panel_style(PANEL_BG, ACCENT_TEAL.darkened(0.3), 1)
	$TabRow/TabSkill.add_theme_stylebox_override("normal", on if _tab_skill else off)
	$TabRow/TabSkill.add_theme_stylebox_override("hover", on)
	$TabRow/TabSkill.add_theme_stylebox_override("pressed", on)
	$TabRow/TabAttr.add_theme_stylebox_override("normal", off if _tab_skill else on)
	$TabRow/TabAttr.add_theme_stylebox_override("hover", on)
	$TabRow/TabAttr.add_theme_stylebox_override("pressed", on)
	if has_node("Body/TreeWrap"):
		$Body/TreeWrap.visible = _tab_skill
	if has_node("Body/AttrScroll"):
		$Body/AttrScroll.visible = not _tab_skill


func refresh() -> void:
	if not _built:
		return
	_refresh_header()
	_refresh_skill_slots()
	_refresh_tree()
	_refresh_attr_list()
	_refresh_detail()


func _refresh_header() -> void:
	if has_node("LevelLabel"):
		$LevelLabel.text = Loc.t("skill.explorer_lv", [MetaProgress.explorer_level])
	if has_node("CrystalLabel"):
		if _training_mode:
			$CrystalLabel.text = Loc.t("training.sandbox_hint")
		else:
			$CrystalLabel.text = Loc.t("skill.crystal_count", [MetaProgress.stash_count(SkillCatalog.CRYSTAL_ID)])
	if has_node("Title"):
		$Title.text = Loc.t("skill.panel_title")
	if has_node("Body/RightCol/TrainRow"):
		$Body/RightCol/TrainRow.visible = _training_mode


func _refresh_skill_slots() -> void:
	if not has_node("SkillSlots"):
		return
	for def in SKILL_SLOT_DEFS:
		var node_name: String = str(def[0])
		if not has_node("SkillSlots/%s" % node_name):
			continue
		var col: VBoxContainer = get_node("SkillSlots/%s" % node_name)
		var slot_id: String = str(def[1])
		var learned_id := ""
		if _player != null:
			learned_id = _player.skills.skill_in_slot(slot_id)
		var icon_path := ""
		if learned_id != "" and SkillCatalog.has_id(learned_id):
			icon_path = SkillCatalog.fallback_icon(learned_id)
		elif learned_id != "" and CrystalCatalog.has_id(learned_id):
			icon_path = CrystalCatalog.icon_path(learned_id)
		var panel: Panel = col.get_node("Slot")
		var icon: TextureRect = panel.get_node("Icon")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		else:
			icon.texture = null
		panel.add_theme_stylebox_override("panel", _panel_style(INNER_BG, ACCENT_GOLD if learned_id != "" else ACCENT_TEAL, 1))


func _refresh_tree() -> void:
	for sid in _tree_icons.keys():
		var p: Panel = _tree_icons[sid]
		if p == null:
			continue
		var rank := MetaProgress.skill_rank(str(sid))
		var max_r := SkillCatalog.max_rank(str(sid))
		var lv_ok := _training_mode or MetaProgress.explorer_level >= SkillCatalog.level_req(str(sid))
		var pre_ok := _training_mode or SkillCatalog.prereqs_met(str(sid), MetaProgress.skill_rank)
		var selected := _selected_id == str(sid)
		var border := ACCENT_TEAL
		var mod := Color(0.45, 0.45, 0.45, 1)
		if rank > 0:
			border = ACCENT_GOLD
			mod = Color.WHITE
		elif lv_ok and pre_ok:
			border = Color(0.72, 0.82, 0.45, 1)
			mod = Color(0.85, 0.85, 0.8, 1)
		if selected:
			border = Color(1.0, 0.88, 0.42, 1)
		p.add_theme_stylebox_override("panel", _panel_style(INNER_BG, border, 2 if selected else 1))
		p.modulate = mod
		var icon: TextureRect = p.get_node("Icon")
		var path := SkillCatalog.fallback_icon(str(sid))
		if path != "" and ResourceLoader.exists(path):
			icon.texture = load(path)
		var rank_lab: Label = p.get_node("Rank")
		rank_lab.text = "%d/%d" % [rank, max_r] if rank > 0 or selected else ""
	if _tree_lines:
		_tree_lines.queue_redraw()


func _draw_tree_lines() -> void:
	if _tree_lines == null:
		return
	for sid in SkillCatalog.tree_ids():
		var pre: Dictionary = SkillCatalog.prereq(str(sid))
		if pre.is_empty():
			continue
		var to_p: Panel = _tree_icons.get(str(sid))
		if to_p == null:
			continue
		var to_c: Vector2 = to_p.position + to_p.size * 0.5
		for pid in pre.keys():
			var from_p: Panel = _tree_icons.get(str(pid))
			if from_p == null:
				continue
			var from_c: Vector2 = from_p.position + from_p.size * 0.5
			var ok := MetaProgress.skill_rank(str(pid)) >= int(pre[pid])
			var col := ACCENT_GOLD if ok else Color(0.35, 0.33, 0.30, 1)
			_tree_lines.draw_line(from_c, to_c, col, 2.0)


func _owned_runes() -> Array:
	var out: Array = []
	if _hub_mode or _player == null:
		for e in MetaProgress.stash_as_entries("core_attr"):
			out.append(e)
		for e2 in MetaProgress.stash_as_entries("rune_attr"):
			out.append(e2)
	elif _player:
		for e in _player.inventory.slots:
			var t := str(e.get("type"))
			var rid := str(e.get("id"))
			if t == "core" and CrystalCatalog.is_attr(rid):
				out.append(e)
			elif t == "rune" and RuneCatalog.is_attr(rid):
				out.append(e)
	return out


func _refresh_attr_list() -> void:
	if _tab_skill or not has_node("Body/AttrScroll/RuneGrid"):
		return
	_list_entries = _owned_runes()
	var grid: Node = $Body/AttrScroll/RuneGrid
	var need: int = maxi(8, _list_entries.size())
	need = int(ceil(float(need) / 4.0) * 4.0)
	if grid.has_method("set_slot_count"):
		grid.call("set_slot_count", need)
	grid.call("set_inventory_entries", _list_entries)


func _refresh_detail() -> void:
	if not has_node("Body/RightCol/DetailPanel/DetailText"):
		return
	var detail: Label = $Body/RightCol/DetailPanel/DetailText
	var d_icon: TextureRect = $Body/RightCol/DetailPanel/DetailIcon
	var learn_btn: Button = $Body/RightCol/BtnRow/LearnBtn
	var forget_btn: Button = $Body/RightCol/BtnRow/ForgetBtn
	if _selected_id == "":
		detail.text = Loc.t("skill.select_hint")
		d_icon.texture = null
		learn_btn.disabled = true
		forget_btn.disabled = true
		learn_btn.text = Loc.t("skill.learn")
		return
	if SkillCatalog.has_id(_selected_id):
		_refresh_skill_detail(detail, d_icon, learn_btn, forget_btn)
	else:
		_refresh_attr_detail(detail, d_icon, learn_btn, forget_btn)


func _refresh_skill_detail(detail: Label, d_icon: TextureRect, learn_btn: Button, forget_btn: Button) -> void:
	var sid := _selected_id
	var rank := MetaProgress.skill_rank(sid)
	var max_r := SkillCatalog.max_rank(sid)
	var kind_key := "skill.kind.passive" if SkillCatalog.is_passive(sid) else "skill.kind.active"
	var effect_key := "%s.effect" % str(SkillCatalog.def(sid).get("name_key", ""))
	var effect := Loc.t(effect_key) if Loc.has_key(effect_key) else ""
	effect += "\n" + _rank_preview(sid, rank)
	var pre_txt := _prereq_text(sid)
	var mind_txt := "—"
	var cd_txt := Loc.t("skill.cd_none")
	if SkillCatalog.is_active(sid):
		var r_show := maxi(rank, 1)
		mind_txt = str(SkillCatalog.cast_cost(sid, r_show))
		cd_txt = "%.1fs" % SkillCatalog.cooldown(sid, r_show)
	detail.text = Loc.t("skill.detail_tree", [
		SkillCatalog.display_name(sid),
		rank,
		max_r,
		Loc.t(kind_key),
		mind_txt,
		cd_txt,
		pre_txt,
		effect,
	])
	var path := SkillCatalog.fallback_icon(sid)
	d_icon.texture = load(path) if path != "" and ResourceLoader.exists(path) else null
	var next_cost := SkillCatalog.learn_cost_for_rank(sid, rank + 1) if rank < max_r else 0
	if _training_mode:
		learn_btn.disabled = rank >= max_r
		learn_btn.text = Loc.t("skill.max_rank") if rank >= max_r else Loc.t("training.rank_plus")
		forget_btn.disabled = rank <= 0
		forget_btn.text = Loc.t("training.rank_minus")
		forget_btn.visible = true
		return
	var can_learn := _hub_mode and rank < max_r and MetaProgress.explorer_level >= SkillCatalog.level_req(sid) \
		and SkillCatalog.prereqs_met(sid, MetaProgress.skill_rank) \
		and MetaProgress.stash_count(SkillCatalog.CRYSTAL_ID) >= next_cost
	learn_btn.disabled = not can_learn
	if not _hub_mode:
		learn_btn.text = Loc.t("skill.pit_blocked")
	elif rank >= max_r:
		learn_btn.text = Loc.t("skill.max_rank")
	else:
		learn_btn.text = Loc.t("skill.next_cost", [next_cost]) if next_cost > 0 else Loc.t("skill.learn")
	var can_forget := _hub_mode and rank > 0 and not (SkillCatalog.is_innate(sid) and rank <= 1)
	forget_btn.disabled = not can_forget
	forget_btn.text = Loc.t("skill.forget")
	forget_btn.visible = true


func _refresh_attr_detail(detail: Label, d_icon: TextureRect, learn_btn: Button, forget_btn: Button) -> void:
	var req := CrystalCatalog.level_req(_selected_id) if CrystalCatalog.has_id(_selected_id) else RuneCatalog.mind_level_req(_selected_id)
	var gname := ItemTier.grade_display(CrystalCatalog.grade(_selected_id)) if CrystalCatalog.has_id(_selected_id) else ItemTier.grade_display(2)
	var effect_key := "core.%s.effect" % _selected_id.trim_prefix("core_")
	if not Loc.has_key(effect_key):
		effect_key = "rune.%s.effect" % _selected_id.trim_prefix("rune_")
	var effect: String = Loc.t(effect_key) if Loc.has_key(effect_key) else ""
	var disp := CrystalCatalog.display_name(_selected_id) if CrystalCatalog.has_id(_selected_id) else RuneCatalog.display_name(_selected_id)
	detail.text = Loc.t("skill.detail", [disp, effect, req, gname, MetaProgress.explorer_level])
	var path := CrystalCatalog.icon_path(_selected_id) if CrystalCatalog.has_id(_selected_id) else str(RuneCatalog.DEFS.get(_selected_id, {}).get("icon", ""))
	d_icon.texture = load(path) if path != "" and ResourceLoader.exists(path) else null
	var can := _player != null and MetaProgress.explorer_level >= req
	learn_btn.disabled = not can
	learn_btn.text = Loc.t("skill.learn")
	forget_btn.visible = false


func _prereq_text(sid: String) -> String:
	var pre: Dictionary = SkillCatalog.prereq(sid)
	if pre.is_empty():
		return Loc.t("skill.prereq_none")
	var parts: PackedStringArray = []
	for pid in pre.keys():
		parts.append(Loc.t("skill.prereq_item", [SkillCatalog.display_name(str(pid)), int(pre[pid])]))
	return "、".join(parts)


func _rank_preview(sid: String, rank: int) -> String:
	var lines: PackedStringArray = []
	if sid == "sk_chain":
		var p: Dictionary = SkillCatalog.passive(sid)
		var pct := (float(p.get("light_dmg", 0.06)) + float(p.get("light_dmg_per", 0.04)) * float(maxi(rank - 1, 0))) * 100.0
		if rank > 0:
			lines.append(Loc.t("sk.chain.rank", [int(round(pct))]))
	elif sid == "sk_stance":
		var p2: Dictionary = SkillCatalog.passive(sid)
		var pct2 := int(round(float(p2.get("patk_pct", 0.03)) * float(maxi(rank, 1)) * 100.0))
		if rank > 0:
			lines.append(Loc.t("sk.stance.rank", [pct2, pct2]))
	elif sid == "sk_ironwall":
		var p3: Dictionary = SkillCatalog.passive(sid)
		var dr := int(round(float(p3.get("dr", 0.04)) * float(maxi(rank, 1)) * 100.0))
		if rank > 0:
			lines.append(Loc.t("sk.ironwall.rank", [dr]))
	elif SkillCatalog.is_active(sid) and rank > 0:
		var c: Dictionary = SkillCatalog.combat(sid, rank)
		lines.append("伤害 %.0f" % float(c.get("damage", 0.0)))
	if rank > 0 and rank < SkillCatalog.max_rank(sid) and SkillCatalog.is_active(sid):
		var c2: Dictionary = SkillCatalog.combat(sid, rank + 1)
		lines.append("下级伤害 %.0f" % float(c2.get("damage", 0.0)))
	return "\n".join(lines)


func _select_skill(sid: String) -> void:
	_selected_id = sid
	_refresh_tree()
	_refresh_detail()


func _begin_skill_drag(sid: String):
	if not SkillCatalog.is_active(sid) or MetaProgress.skill_rank(sid) <= 0:
		return null
	return {"type": "skill", "id": sid}


func _assign_hotkey(slot_id: String, skill_id: String) -> void:
	if _player == null:
		return
	_player.skills.assign_slot(slot_id, skill_id)
	refresh()
	learned.emit(skill_id)


func _cycle_hotkey(slot_id: String) -> void:
	if _player == null:
		return
	_player.skills.cycle_slot(slot_id)
	refresh()
	learned.emit(slot_id)


func _on_rune_pressed(index: int) -> void:
	if index < 0 or index >= _list_entries.size():
		_selected_id = ""
	else:
		_selected_id = str(_list_entries[index].get("id"))
	_refresh_detail()


func _on_learn() -> void:
	if _selected_id == "" or _player == null:
		return
	if _training_mode and SkillCatalog.has_id(_selected_id):
		var next_r := MetaProgress.skill_rank(_selected_id) + 1
		if _player.skills.set_rank_sandbox(_selected_id, next_r) == "ok":
			_player._refresh_character_stats(true)
			_player.loadout_changed.emit()
			refresh()
			learned.emit(_selected_id)
		return
	if SkillCatalog.has_id(_selected_id) and not _hub_mode:
		_toast(Loc.t("skill.pit_blocked"))
		return
	var rid := _selected_id
	var r: String = _player.try_learn_rune(rid, true if SkillCatalog.has_id(rid) else _hub_mode)
	var disp := SkillCatalog.display_name(rid) if SkillCatalog.has_id(rid) else (
		CrystalCatalog.display_name(rid) if CrystalCatalog.has_id(rid) else RuneCatalog.display_name(rid)
	)
	match r:
		"ok":
			if _player.has_method("show_toast"):
				_player.show_toast(Loc.t("skill.learn_ok", [disp]))
			AudioManager.sfx_pickup()
			refresh()
			learned.emit(rid)
		"level", "mind_level":
			_toast(Loc.t("skill.need_level", [
				SkillCatalog.level_req(rid) if SkillCatalog.has_id(rid) else CrystalCatalog.level_req(rid)
			]))
		"grade":
			_toast(Loc.t("skill.need_grade", [ItemTier.grade_display(CrystalCatalog.grade(rid)) if CrystalCatalog.has_id(rid) else ""]))
		"no_crystal":
			_toast(Loc.t("skill.need_crystal", [SkillCatalog.learn_cost_for_rank(rid, MetaProgress.skill_rank(rid) + 1)]))
		"prereq":
			_toast(Loc.t("skill.need_prereq"))
		"pit_blocked":
			_toast(Loc.t("skill.pit_blocked"))
		"learned":
			_toast(Loc.t("skill.max_rank") if SkillCatalog.has_id(rid) else Loc.t("skill.already"))
		"no_rune":
			_toast(Loc.t("skill.need_rune"))
		_:
			_toast(Loc.t("skill.learn_fail"))


func _on_forget() -> void:
	if _selected_id == "" or _player == null:
		return
	if _training_mode and SkillCatalog.has_id(_selected_id):
		var next_r := MetaProgress.skill_rank(_selected_id) - 1
		if _player.skills.set_rank_sandbox(_selected_id, next_r) == "ok":
			_player._refresh_character_stats(true)
			_player.loadout_changed.emit()
			refresh()
			learned.emit(_selected_id)
		return
	if not _hub_mode:
		return
	if not SkillCatalog.has_id(_selected_id):
		return
	var before := MetaProgress.skill_rank(_selected_id)
	var r: String = _player.skills.try_forget(_selected_id)
	match r:
		"ok":
			var after := MetaProgress.skill_rank(_selected_id)
			var refund := SkillCatalog.spent_cost(_selected_id, before) - SkillCatalog.spent_cost(_selected_id, after)
			if _player.has_method("show_toast"):
				_player.show_toast(Loc.t("skill.forget_ok", [SkillCatalog.display_name(_selected_id), refund]))
			_player._refresh_character_stats(true)
			_player.loadout_changed.emit()
			refresh()
			learned.emit(_selected_id)
		"innate":
			_toast(Loc.t("skill.forget_innate"))
		"prereq":
			_toast(Loc.t("skill.forget_prereq"))
		_:
			_toast(Loc.t("skill.learn_fail"))


func _on_train_max_all() -> void:
	if not _training_mode:
		return
	MetaProgress.fill_all_skills_sandbox()
	if _player:
		_player._refresh_character_stats(true)
		_player.loadout_changed.emit()
	refresh()
	learned.emit("all")


func _on_train_restore() -> void:
	if not _training_mode:
		return
	MetaProgress.restore_skill_sandbox_snapshot()
	if _player:
		_player._refresh_character_stats(true)
		_player.loadout_changed.emit()
	refresh()
	learned.emit("restore")


func _toast(text: String) -> void:
	if _player != null and _player.has_method("show_toast"):
		_player.show_toast(text, 2)
