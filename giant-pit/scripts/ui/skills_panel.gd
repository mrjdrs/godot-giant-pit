extends Control
## 技能学习面板。布局对齐背包/材料仓库：Panel 外壳 + chrome 格子。

const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const SkillBook = preload("res://scripts/player/skill_book.gd")

signal closed
signal learned(rune_id: String)

const PANEL_SIZE := Vector2(560, 440)
const ACCENT_GOLD := Color(0.91, 0.66, 0.22, 1)
const ACCENT_TEAL := Color(0.24, 0.55, 0.48, 1)
const ACCENT_PURPLE := Color(0.55, 0.38, 0.72, 1)
const PANEL_BG := Color(0.12, 0.11, 0.10, 0.97)
const INNER_BG := Color(0.09, 0.08, 0.07, 0.95)

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
var _tab_skill: bool = true
var _selected_rune: String = ""
var _list_entries: Array = []
var _slots_built: bool = false


func _ready() -> void:
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_shell()
	_build_skill_slots()
	if has_node("CloseBtn"):
		$CloseBtn.pressed.connect(close)
	if has_node("TabRow/TabSkill"):
		$TabRow/TabSkill.pressed.connect(func(): _set_tab(true))
	if has_node("TabRow/TabAttr"):
		$TabRow/TabAttr.pressed.connect(func(): _set_tab(false))
	if has_node("Body/RightCol/LearnBtn"):
		$Body/RightCol/LearnBtn.pressed.connect(_on_learn)
	var grid: Node = _rune_grid()
	if grid:
		if grid.has_signal("slot_pressed") and not grid.slot_pressed.is_connected(_on_rune_pressed):
			grid.slot_pressed.connect(_on_rune_pressed)
		if grid.has_signal("slot_hovered") and not grid.slot_hovered.is_connected(_on_hover):
			grid.slot_hovered.connect(_on_hover)


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


func _apply_shell() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -PANEL_SIZE.x * 0.5
	offset_top = -PANEL_SIZE.y * 0.5
	offset_right = PANEL_SIZE.x * 0.5
	offset_bottom = PANEL_SIZE.y * 0.5

	if has_node("PanelBg"):
		$PanelBg.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, ACCENT_TEAL, 2))

	if has_node("Body/RightCol/DetailPanel"):
		$Body/RightCol/DetailPanel.add_theme_stylebox_override("panel", _panel_style(INNER_BG, ACCENT_PURPLE, 1))

	if has_node("Title"):
		$Title.text = Loc.t("skill.panel_title") if Loc.has_key("skill.panel_title") else "技能学习"

	if has_node("CloseBtn"):
		$CloseBtn.ignore_texture_size = true
		$CloseBtn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	if has_node("TabRow/TabSkill"):
		$TabRow/TabSkill.text = Loc.t("skill.tab.skill") if Loc.has_key("skill.tab.skill") else "技能符文"
	if has_node("TabRow/TabAttr"):
		$TabRow/TabAttr.text = Loc.t("skill.tab.attr") if Loc.has_key("skill.tab.attr") else "属性符文"

	var grid: Node = _rune_grid()
	if grid:
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)

	_refresh_tab_style()


func _rune_grid() -> Node:
	if has_node("Body/GridScroll/RuneGrid"):
		return $Body/GridScroll/RuneGrid
	if has_node("RuneGrid"):
		return $RuneGrid
	return null


func _build_skill_slots() -> void:
	if _slots_built or not has_node("SkillSlots"):
		return
	_slots_built = true
	var hb: HBoxContainer = $SkillSlots
	for c in hb.get_children():
		c.queue_free()
	for def in SKILL_SLOT_DEFS:
		var col := VBoxContainer.new()
		col.name = str(def[0])
		col.add_theme_constant_override("separation", 2)
		col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		hb.add_child(col)

		var panel := Panel.new()
		panel.name = "Slot"
		panel.custom_minimum_size = Vector2(44, 44)
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
		panel.add_child(icon)

		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.visible = false
		lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lock.texture = load("res://assets/ui/chrome/ui_lock.png")
		panel.add_child(lock)

		var label := Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72, 1))
		col.add_child(label)
		var captured: String = str(def[1])
		panel.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_slot_clicked(captured)
		)


func bind_player(p: Node, hub_mode: bool = false) -> void:
	_player = p
	_hub_mode = hub_mode


func open() -> void:
	visible = true
	_selected_rune = ""
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
	_selected_rune = ""
	_refresh_tab_style()
	refresh()


func _refresh_tab_style() -> void:
	if not has_node("TabRow/TabSkill") or not has_node("TabRow/TabAttr"):
		return
	var on := _panel_style(INNER_BG, ACCENT_GOLD, 1)
	var off := _panel_style(PANEL_BG, ACCENT_TEAL.darkened(0.3), 1)
	$TabRow/TabSkill.add_theme_stylebox_override("normal", on if _tab_skill else off)
	$TabRow/TabSkill.add_theme_stylebox_override("hover", on)
	$TabRow/TabSkill.add_theme_stylebox_override("pressed", on)
	$TabRow/TabAttr.add_theme_stylebox_override("normal", off if _tab_skill else on)
	$TabRow/TabAttr.add_theme_stylebox_override("hover", on)
	$TabRow/TabAttr.add_theme_stylebox_override("pressed", on)


func refresh() -> void:
	_refresh_skill_slots()
	_refresh_rune_list()
	_refresh_detail()


func _refresh_skill_slots() -> void:
	if not has_node("SkillSlots"):
		return
	for def in SKILL_SLOT_DEFS:
		var node_name: String = str(def[0])
		if not has_node("SkillSlots/%s" % node_name):
			continue
		var col: VBoxContainer = get_node("SkillSlots/%s" % node_name)
		var slot_id: String = str(def[1])
		var mvp_active: bool = bool(def[2])
		var learned_id := ""
		if _player != null:
			learned_id = _player.skills.skill_in_slot(slot_id)
		var icon_path: String = SkillBook.SLOT_ICONS.get(slot_id, "")
		if learned_id != "" and CrystalCatalog.has_id(learned_id):
			icon_path = CrystalCatalog.icon_path(learned_id)
		elif learned_id != "" and RuneCatalog.DEFS.has(learned_id):
			icon_path = str(RuneCatalog.DEFS[learned_id].get("icon", icon_path))
		var panel: Panel = col.get_node("Slot")
		var icon: TextureRect = panel.get_node("Icon")
		if icon_path != "":
			icon.texture = load(icon_path)
		var locked := learned_id == ""
		if _player != null:
			locked = not _player.skills.is_slot_unlocked(slot_id) and learned_id == ""
		elif not mvp_active:
			locked = true
		panel.get_node("Lock").visible = locked
		panel.modulate = Color(0.55, 0.55, 0.55, 1) if locked else Color.WHITE
		panel.add_theme_stylebox_override("panel", _panel_style(INNER_BG, ACCENT_GOLD if learned_id != "" else ACCENT_TEAL, 1))
		var label_key := "skill.slot.%s" % slot_id
		col.get_node("Label").text = Loc.t(label_key) if Loc.has_key(label_key) else slot_id


func _owned_runes() -> Array:
	var out: Array = []
	if _hub_mode or _player == null:
		var kind := "core_skill" if _tab_skill else "core_attr"
		for e in MetaProgress.stash_as_entries(kind):
			out.append(e)
		for e2 in MetaProgress.stash_as_entries("rune_skill" if _tab_skill else "rune_attr"):
			out.append(e2)
	elif _player:
		for e in _player.inventory.slots:
			var t := str(e.get("type"))
			var rid := str(e.get("id"))
			if t == "core":
				if _tab_skill and CrystalCatalog.is_skill(rid):
					out.append(e)
				elif not _tab_skill and CrystalCatalog.is_attr(rid):
					out.append(e)
			elif t == "rune":
				if _tab_skill and RuneCatalog.is_skill(rid):
					out.append(e)
				elif not _tab_skill and RuneCatalog.is_attr(rid):
					out.append(e)
	return out


func _refresh_rune_list() -> void:
	_list_entries = _owned_runes()
	var grid: Node = _rune_grid()
	if grid == null:
		return
	var need: int = maxi(8, _list_entries.size())
	need = int(ceil(float(need) / 4.0) * 4.0)
	if grid.has_method("set_slot_count"):
		grid.call("set_slot_count", need)
	grid.call("set_inventory_entries", _list_entries)
	if _selected_rune != "":
		var idx := _index_of_rune(_selected_rune)
		if idx >= 0 and grid.has_method("select_slot"):
			grid.call("select_slot", idx)
		else:
			_selected_rune = ""


func _index_of_rune(rune_id: String) -> int:
	for i in _list_entries.size():
		if str(_list_entries[i].get("id")) == rune_id:
			return i
	return -1


func _refresh_detail() -> void:
	var detail: Label = null
	if has_node("Body/RightCol/DetailPanel/DetailText"):
		detail = $Body/RightCol/DetailPanel/DetailText
	elif has_node("Detail"):
		detail = $Detail
	if detail:
		if _selected_rune == "":
			detail.text = Loc.t("skill.select_hint")
			if has_node("Body/RightCol/DetailPanel/DetailIcon"):
				$Body/RightCol/DetailPanel/DetailIcon.texture = null
		else:
			var cost := CrystalCatalog.learn_cost(_selected_rune) if CrystalCatalog.has_id(_selected_rune) else RuneCatalog.learn_cost(_selected_rune)
			var req := CrystalCatalog.mind_level_req(_selected_rune) if CrystalCatalog.has_id(_selected_rune) else RuneCatalog.mind_level_req(_selected_rune)
			var effect_key := "core.%s.effect" % _selected_rune.trim_prefix("core_")
			if not Loc.has_key(effect_key):
				effect_key = "rune.%s.effect" % _selected_rune.trim_prefix("rune_")
			if not Loc.has_key(effect_key):
				effect_key = "rune.%s.effect" % _selected_rune
			var effect: String = Loc.t(effect_key) if Loc.has_key(effect_key) else ""
			var disp := CrystalCatalog.display_name(_selected_rune) if CrystalCatalog.has_id(_selected_rune) else RuneCatalog.display_name(_selected_rune)
			detail.text = Loc.t("skill.detail", [
				disp,
				effect,
				req,
				cost,
				MetaProgress.mind_level,
				MetaProgress.mind_value,
			])
			if has_node("Body/RightCol/DetailPanel/DetailIcon"):
				var path := CrystalCatalog.icon_path(_selected_rune) if CrystalCatalog.has_id(_selected_rune) else str(RuneCatalog.DEFS.get(_selected_rune, {}).get("icon", ""))
				if path != "":
					$Body/RightCol/DetailPanel/DetailIcon.texture = load(path)
	var learn_btn: Button = null
	if has_node("Body/RightCol/LearnBtn"):
		learn_btn = $Body/RightCol/LearnBtn
	elif has_node("LearnBtn"):
		learn_btn = $LearnBtn
	if learn_btn:
		var req := CrystalCatalog.mind_level_req(_selected_rune) if CrystalCatalog.has_id(_selected_rune) else RuneCatalog.mind_level_req(_selected_rune)
		var cost := CrystalCatalog.learn_cost(_selected_rune) if CrystalCatalog.has_id(_selected_rune) else RuneCatalog.learn_cost(_selected_rune)
		var can := _hub_mode and _selected_rune != "" \
			and MetaProgress.mind_level >= req \
			and MetaProgress.can_afford_mind(cost)
		learn_btn.disabled = not can
		learn_btn.text = Loc.t("skill.learn") if _hub_mode else Loc.t("skill.pit_blocked")


func _on_rune_pressed(index: int) -> void:
	if index < 0 or index >= _list_entries.size():
		_selected_rune = ""
	else:
		_selected_rune = str(_list_entries[index].get("id"))
	_refresh_detail()


func _on_hover(index: int, tip: String) -> void:
	if index < 0 or tip == "":
		return
	if _selected_rune != "":
		return
	var detail: Label = null
	if has_node("Body/RightCol/DetailPanel/DetailText"):
		detail = $Body/RightCol/DetailPanel/DetailText
	if detail:
		detail.text = tip
	if has_node("Body/RightCol/DetailPanel/DetailIcon") and index >= 0:
		var grid: Node = _rune_grid()
		if grid and grid.get_child_count() > index:
			var slot: Node = grid.get_child(index)
			if slot.has_node("Icon"):
				$Body/RightCol/DetailPanel/DetailIcon.texture = slot.get_node("Icon").texture


func _on_slot_clicked(slot_id: String) -> void:
	if _player == null:
		return
	if _player.skills.has_method("cycle_slot"):
		_player.skills.cycle_slot(slot_id)
	refresh()
	learned.emit(slot_id)


func _on_learn() -> void:
	if _selected_rune == "" or _player == null:
		return
	if not _hub_mode:
		_toast(Loc.t("skill.pit_blocked"))
		return
	var rid := _selected_rune
	var r: String = _player.try_learn_rune(rid, true)
	var disp := CrystalCatalog.display_name(rid) if CrystalCatalog.has_id(rid) else RuneCatalog.display_name(rid)
	match r:
		"ok":
			if _player.has_method("show_toast"):
				_player.show_toast(Loc.t("skill.learn_ok", [disp]))
			AudioManager.sfx_pickup()
			_selected_rune = ""
			refresh()
			learned.emit(rid)
		"mind_level":
			_toast(Loc.t("skill.need_level", [CrystalCatalog.mind_level_req(rid) if CrystalCatalog.has_id(rid) else RuneCatalog.mind_level_req(rid)]))
		"no_mind":
			_toast(Loc.t("skill.need_mind"))
		"no_rune":
			_toast(Loc.t("skill.need_rune"))
		"learned":
			_toast(Loc.t("skill.already"))
		_:
			_toast(Loc.t("skill.learn_fail"))


func _toast(text: String) -> void:
	if _player != null and _player.has_method("show_toast"):
		_player.show_toast(text, 2)
