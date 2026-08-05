extends Control
## 随身背包面板。布局对齐材料仓库：Panel 外壳 + chrome 格子网格。

signal closed
signal request_refresh

const PANEL_SIZE := Vector2(560, 440)
const ACCENT_GOLD := Color(0.91, 0.66, 0.22, 1)
const ACCENT_TEAL := Color(0.24, 0.55, 0.48, 1)
const PANEL_BG := Color(0.12, 0.11, 0.10, 0.97)
const INNER_BG := Color(0.09, 0.08, 0.07, 0.95)

var _player: Node = null
var _hub_mode: bool = false ## 枢纽：显示 stash
var _selected: int = -1


func _ready() -> void:
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_shell()
	if has_node("CloseBtn"):
		$CloseBtn.pressed.connect(close)
	if has_node("UseBtn"):
		$UseBtn.pressed.connect(_on_use_pressed)
	var grid: Node = _grid()
	if grid:
		if grid.has_signal("slot_hovered") and not grid.slot_hovered.is_connected(_on_hover):
			grid.slot_hovered.connect(_on_hover)
		if grid.has_signal("slot_pressed") and not grid.slot_pressed.is_connected(_on_slot_pressed):
			grid.slot_pressed.connect(_on_slot_pressed)


func _grid() -> Node:
	if has_node("GridScroll/BagGrid"):
		return $GridScroll/BagGrid
	if has_node("BagGrid"):
		return $BagGrid
	return null


func _panel_style(bg: Color, border: Color, border_w: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
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

	if has_node("WeightTrack"):
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.08, 0.07, 0.06, 1)
		track.border_color = ACCENT_GOLD.darkened(0.25)
		track.set_border_width_all(1)
		$WeightTrack.add_theme_stylebox_override("panel", track)

	if has_node("DetailPanel"):
		$DetailPanel.add_theme_stylebox_override("panel", _panel_style(INNER_BG, ACCENT_TEAL, 1))

	if has_node("CloseBtn"):
		$CloseBtn.ignore_texture_size = true
		$CloseBtn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	if has_node("BagGrid") or has_node("GridScroll/BagGrid"):
		var g: Node = _grid()
		if g:
			g.add_theme_constant_override("h_separation", 6)
			g.add_theme_constant_override("v_separation", 6)


func bind_player(p: Node, hub_mode: bool = false) -> void:
	_player = p
	_hub_mode = hub_mode


func open() -> void:
	visible = true
	_selected = -1
	if has_node("UseBtn"):
		$UseBtn.visible = false
	_clear_detail()
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
	if has_node("Title"):
		$Title.text = Loc.t("hud.bag_title")
	if has_node("GoldLabel"):
		$GoldLabel.text = Loc.t("hud.gold", [MetaProgress.gold])
	_refresh_grid()
	_refresh_weight()
	if _selected >= 0:
		_show_detail(_selected)
		if has_node("UseBtn"):
			$UseBtn.visible = _can_use(_selected)


func _refresh_grid() -> void:
	var grid: Node = _grid()
	if grid == null:
		return
	if _hub_mode or _player == null:
		var entries: Array = MetaProgress.stash_as_entries()
		var need: int = maxi(12, entries.size())
		## 凑满整行，和材料仓库一样整齐
		need = int(ceil(float(need) / 6.0) * 6.0)
		if grid.has_method("set_slot_count"):
			grid.call("set_slot_count", need)
		grid.call("set_inventory_entries", entries)
	else:
		var inv = _player.inventory
		var need2: int = inv.max_slots()
		need2 = int(ceil(float(need2) / 6.0) * 6.0)
		if grid.has_method("set_slot_count"):
			grid.call("set_slot_count", maxi(12, need2))
		grid.call("set_inventory_entries", inv.slots)


func _refresh_weight() -> void:
	if not has_node("WeightLabel"):
		return
	var fill: ColorRect = $WeightTrack/WeightFill if has_node("WeightTrack/WeightFill") else null
	if _hub_mode or _player == null:
		$WeightLabel.text = Loc.t("bag.weight_hub")
		if has_node("WeightTrack"):
			$WeightTrack.visible = false
		if fill:
			fill.visible = false
		return
	if has_node("WeightTrack"):
		$WeightTrack.visible = true
	var cur: float = _player.inventory.current_weight()
	var cap: float = _player.carry_cap()
	$WeightLabel.text = Loc.t("bag.weight", [cur, cap])
	if fill and has_node("WeightTrack"):
		fill.visible = true
		var track_w: float = maxf($WeightTrack.size.x - 2.0, 1.0)
		var ratio := clampf(cur / maxf(cap, 0.01), 0.0, 1.0)
		fill.position = Vector2(1, 1)
		fill.size = Vector2(track_w * ratio, maxf($WeightTrack.size.y - 2.0, 1.0))
		fill.color = Color(0.9, 0.35, 0.25) if ratio > 0.95 else ACCENT_GOLD


func _on_hover(index: int, tip: String) -> void:
	if tip == "" and index < 0:
		return
	if index >= 0:
		_show_detail(index)


func _on_slot_pressed(index: int) -> void:
	_selected = index
	_show_detail(index)
	if has_node("UseBtn"):
		$UseBtn.visible = _can_use(index)


func _clear_detail() -> void:
	if has_node("DetailPanel/DetailIcon"):
		$DetailPanel/DetailIcon.texture = null
	if has_node("DetailPanel/DetailText"):
		$DetailPanel/DetailText.text = ""


func _show_detail(index: int) -> void:
	var grid: Node = _grid()
	if grid == null:
		return
	var tip: String = ""
	if grid.has_method("get_slot_tooltip"):
		tip = str(grid.call("get_slot_tooltip", index))
	if tip == "":
		_clear_detail()
		return
	if has_node("DetailPanel/DetailText"):
		$DetailPanel/DetailText.text = tip
	if grid.get_child_count() > index:
		var slot: Node = grid.get_child(index)
		if slot.has_node("Icon"):
			$DetailPanel/DetailIcon.texture = slot.get_node("Icon").texture
			$DetailPanel/DetailIcon.modulate = slot.get_node("Icon").modulate


func _can_use(index: int) -> bool:
	if _hub_mode or _player == null:
		return false
	var inv = _player.inventory
	if index < 0 or index >= inv.slots.size():
		return false
	var e: Dictionary = inv.slots[index]
	return e.get("type") == "item" and str(e.get("id")) == "item_bag_expand"


func _on_use_pressed() -> void:
	var grid: Node = _grid()
	if _hub_mode or _player == null or grid == null:
		return
	var idx: int = int(grid.call("get_selected"))
	var r: String = _player.inventory.use_bag_expand_at(idx)
	if r == "ok":
		_player.show_toast(Loc.t("bag.expand_ok", [_player.inventory.max_slots()]))
		refresh()
		request_refresh.emit()
	else:
		_player.show_toast(Loc.t("bag.expand_fail"))
