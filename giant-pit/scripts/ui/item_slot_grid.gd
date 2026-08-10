extends GridContainer
## 材料/符文/道具格子网格：图标 + 右下角数量 + 悬浮介绍。
class_name ItemSlotGrid

const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const ItemCatalog = preload("res://scripts/items/item_catalog.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")

signal slot_pressed(index: int)
signal slot_hovered(index: int, tip: String)

@export var slot_count: int = 10
@export var columns_count: int = 5
@export var slot_size: Vector2 = Vector2(36, 36)
@export var selectable: bool = false
@export var use_chrome: bool = true

var _slots: Array = []
var _selected: int = -1
var _entries: Array = []
var _empty_tex: Texture2D
var _selected_tex: Texture2D


func _ready() -> void:
	columns = columns_count
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)
	if use_chrome:
		_empty_tex = load("res://assets/ui/chrome/ui_slot_empty.png") as Texture2D
		_selected_tex = load("res://assets/ui/chrome/ui_slot_selected.png") as Texture2D
	_rebuild_slots()


func set_slot_count(n: int) -> void:
	if n == slot_count:
		return
	slot_count = n
	_rebuild_slots()
	set_inventory_entries(_entries)


func set_selectable(enabled: bool) -> void:
	if selectable == enabled:
		return
	selectable = enabled
	_rebuild_slots()
	set_inventory_entries(_entries)


func _rebuild_slots() -> void:
	for c in get_children():
		c.queue_free()
	_slots.clear()
	for i in slot_count:
		var panel := Panel.new()
		panel.custom_minimum_size = slot_size
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if use_chrome and _empty_tex != null:
			var style := StyleBoxTexture.new()
			style.texture = _empty_tex
			panel.add_theme_stylebox_override("panel", style)
		else:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.1, 0.09, 0.92)
			style.border_color = Color(0.45, 0.38, 0.3, 1)
			style.set_border_width_all(1)
			panel.add_theme_stylebox_override("panel", style)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 2
		icon.offset_top = 2
		icon.offset_right = -2
		icon.offset_bottom = -10
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)

		var count := Label.new()
		count.name = "Count"
		count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count.offset_left = -28
		count.offset_top = -14
		count.offset_right = -1
		count.offset_bottom = -1
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.add_theme_font_size_override("font_size", 10)
		count.add_theme_color_override("font_color", Color(1, 0.95, 0.8, 1))
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(count)

		var idx := i
		panel.mouse_entered.connect(func(): _on_hover(idx))
		panel.mouse_exited.connect(func(): slot_hovered.emit(-1, ""))
		if selectable:
			panel.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					select_slot(idx)
					slot_pressed.emit(idx)
			)
		add_child(panel)
		_slots.append(panel)
	_selected = -1
	clear_all()


func _on_hover(index: int) -> void:
	var tip := _tooltip_for(index)
	if tip != "":
		slot_hovered.emit(index, tip)


func get_slot_tooltip(index: int) -> String:
	return _tooltip_for(index)


func _tooltip_for(index: int) -> String:
	if index < 0 or index >= _entries.size():
		return ""
	var e: Dictionary = _entries[index]
	var t: String = str(e.get("type", "mat"))
	var id: String = str(e.get("id", ""))
	if t == "core":
		var effect_key := "core.%s.effect" % id.trim_prefix("core_")
		if not Loc.has_key(effect_key):
			effect_key = "rune.%s.effect" % id
		var effect: String = Loc.t(effect_key) if Loc.has_key(effect_key) else ""
		return Loc.t("item.rune_tip", [CrystalCatalog.display_name(id), CrystalCatalog.tier_label(id), effect])
	if t == "rune":
		var effect_key := "rune.%s.effect" % id.trim_prefix("rune_")
		if not Loc.has_key(effect_key):
			effect_key = "rune.%s.effect" % id
		var effect: String = Loc.t(effect_key) if Loc.has_key(effect_key) else ""
		var rune_tier := RuneCatalog.tier_label(id)
		return Loc.t("item.rune_tip", [RuneCatalog.display_name(id), rune_tier, effect])
	if t == "item":
		var desc_key := "item.%s.desc" % id.trim_prefix("item_")
		if not Loc.has_key(desc_key):
			desc_key = str(ItemCatalog.ITEMS.get(id, {}).get("desc_key", ""))
		var desc: String = Loc.t(desc_key) if desc_key != "" and Loc.has_key(desc_key) else ""
		return Loc.t("item.mat_tip", [ItemCatalog.display_name(id), Loc.t("tier.common"), int(e.get("count", 1)), desc]).strip_edges()
	var cnt := int(e.get("count", 1))
	var desc_key2 := "mat.%s.desc" % id
	var desc2: String = Loc.t(desc_key2) if Loc.has_key(desc_key2) else ""
	var tier_txt := MaterialCatalog.tier_label(id)
	return Loc.t("item.mat_tip", [MaterialCatalog.display_name(id), tier_txt, cnt, desc2]).strip_edges()


func clear_all() -> void:
	_entries.clear()
	for i in _slots.size():
		_set_slot_visual(i, null, 0)


func select_slot(index: int) -> void:
	_selected = index
	for i in _slots.size():
		var p: Panel = _slots[i]
		if use_chrome and _selected_tex != null and _empty_tex != null:
			var style := StyleBoxTexture.new()
			style.texture = _selected_tex if i == index else _empty_tex
			p.add_theme_stylebox_override("panel", style)
		else:
			p.modulate = Color(1.25, 1.15, 0.7, 1) if i == index else Color.WHITE


func get_selected() -> int:
	return _selected


func set_inventory_entries(entries: Array) -> void:
	_entries = []
	for e in entries:
		_entries.append(e)
	for i in slot_count:
		if i < _entries.size():
			var e: Dictionary = _entries[i]
			_set_slot_visual(i, _icon_for_entry(e), int(e.get("count", 1)))
		else:
			_set_slot_visual(i, null, 0)


func set_stash_dict(stash: Dictionary) -> void:
	_entries.clear()
	var keys: Array = stash.keys()
	keys.sort()
	for mid in keys:
		var sid := str(mid)
		var entry_type := "mat"
		if CrystalCatalog.has_id(sid):
			entry_type = "core"
		elif RuneCatalog.DEFS.has(sid):
			entry_type = "rune"
		elif ItemCatalog.ITEMS.has(sid):
			entry_type = "item"
		_entries.append({"type": entry_type, "id": sid, "count": int(stash[mid])})
	for i in slot_count:
		if i < _entries.size():
			var e: Dictionary = _entries[i]
			_set_slot_visual(i, _icon_for_entry(e), int(e.get("count", 1)))
		else:
			_set_slot_visual(i, null, 0)


func _set_slot_visual(index: int, tex: Texture2D, count: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	var panel: Panel = _slots[index]
	var icon: TextureRect = panel.get_node("Icon")
	var label: Label = panel.get_node("Count")
	icon.texture = tex
	icon.modulate = Color.WHITE if tex != null else Color(1, 1, 1, 0.15)
	if tex != null and count > 1:
		label.text = str(count)
	elif tex != null and count == 1:
		label.text = ""
	else:
		label.text = ""


func _icon_for_entry(e: Dictionary) -> Texture2D:
	var t: String = str(e.get("type", "mat"))
	var id: String = str(e.get("id", ""))
	if t == "rune":
		return _rune_icon(id)
	if t == "core":
		return _core_icon(id)
	if t == "item":
		return _item_icon(id)
	return _mat_icon(id)


func _mat_icon(mat_id: String) -> Texture2D:
	var def: Dictionary = MaterialCatalog.MATERIALS.get(mat_id, {})
	var path: String = str(def.get("icon", ""))
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _core_icon(core_id: String) -> Texture2D:
	var path := CrystalCatalog.icon_path(core_id)
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _rune_icon(rune_id: String) -> Texture2D:
	var def: Dictionary = RuneCatalog.DEFS.get(rune_id, {})
	var path: String = str(def.get("icon", ""))
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _item_icon(item_id: String) -> Texture2D:
	var path := ItemCatalog.icon_path(item_id)
	if path.is_empty():
		return null
	return load(path) as Texture2D
