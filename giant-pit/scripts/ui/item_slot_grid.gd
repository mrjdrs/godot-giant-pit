extends GridContainer
## 材料/符文格子网格：图标 + 右下角数量 + 悬浮介绍。
class_name ItemSlotGrid

const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")

signal slot_pressed(index: int)
signal slot_hovered(index: int, tip: String)

@export var slot_count: int = 12
@export var columns_count: int = 4
@export var slot_size: Vector2 = Vector2(56, 56)
@export var selectable: bool = false

var _slots: Array = []
var _selected: int = -1
var _entries: Array = [] ## 当前格子数据（用于 tooltip）


func _ready() -> void:
	columns = columns_count
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 6)
	_rebuild_slots()


func _rebuild_slots() -> void:
	for c in get_children():
		c.queue_free()
	_slots.clear()
	for i in slot_count:
		var panel := Panel.new()
		panel.custom_minimum_size = slot_size
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.1, 0.09, 0.92)
		style.border_color = Color(0.45, 0.38, 0.3, 1)
		style.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", style)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -14
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)

		var count := Label.new()
		count.name = "Count"
		count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count.offset_left = -28
		count.offset_top = -16
		count.offset_right = -2
		count.offset_bottom = -1
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.add_theme_font_size_override("font_size", 11)
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
	clear_all()


func _on_hover(index: int) -> void:
	var tip := _tooltip_for(index)
	if tip != "":
		slot_hovered.emit(index, tip)


func _tooltip_for(index: int) -> String:
	if index < 0 or index >= _entries.size():
		return ""
	var e: Dictionary = _entries[index]
	var t: String = str(e.get("type", "mat"))
	var id: String = str(e.get("id", ""))
	if t == "rune":
		var effect_key := "rune.%s.effect" % id
		var effect := Loc.t(effect_key) if Loc.has_key(effect_key) else ""
		return "%s\n%s" % [RuneCatalog.display_name(id), effect]
	var name := MaterialCatalog.display_name(id)
	var cnt := int(e.get("count", 1))
	var desc_key := "mat.%s.desc" % id
	var desc := Loc.t(desc_key) if Loc.has_key(desc_key) else ""
	return Loc.t("item.mat_tip", [name, cnt, desc]).strip_edges()


func clear_all() -> void:
	_entries.clear()
	for i in _slots.size():
		_set_slot_visual(i, null, 0)


func select_slot(index: int) -> void:
	_selected = index
	for i in _slots.size():
		var p: Panel = _slots[i]
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
		_entries.append({"type": "mat", "id": str(mid), "count": int(stash[mid])})
	for i in slot_count:
		if i < _entries.size():
			var e: Dictionary = _entries[i]
			_set_slot_visual(i, _mat_icon(str(e.get("id"))), int(e.get("count", 1)))
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
		label.text = "1"
	else:
		label.text = ""


func _icon_for_entry(e: Dictionary) -> Texture2D:
	var t: String = str(e.get("type", "mat"))
	var id: String = str(e.get("id", ""))
	if t == "rune":
		return _rune_icon(id)
	return _mat_icon(id)


func _mat_icon(mat_id: String) -> Texture2D:
	var def: Dictionary = MaterialCatalog.MATERIALS.get(mat_id, {})
	var path: String = str(def.get("icon", ""))
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _rune_icon(rune_id: String) -> Texture2D:
	var def: Dictionary = RuneCatalog.DEFS.get(rune_id, {})
	var path: String = str(def.get("icon", ""))
	if path.is_empty():
		return null
	return load(path) as Texture2D
