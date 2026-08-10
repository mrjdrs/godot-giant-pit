extends Control
## 主界面：继续 / 新游戏 / 读取 / 退出；五档独立存档。

const HUB_SCENE := "res://scenes/hub/crane_hub.tscn"

enum View { ROOT, NEW, LOAD }

var _view: View = View.ROOT
var _confirm: Panel = null
var _slot_list: VBoxContainer = null
var _hint: Label = null
var _btn_continue: Button = null
var _btn_new: Button = null
var _btn_load: Button = null
var _btn_quit: Button = null
var _btn_back: Button = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	AudioManager.play_bgm()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.05, 0.06, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0, 0, 0, 0)
	if ResourceLoader.exists("res://shaders/vignette.gdshader"):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/vignette.gdshader")
		mat.set_shader_parameter("intensity", 0.42)
		mat.set_shader_parameter("softness", 0.5)
		vignette.material = mat
	add_child(vignette)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(420, 0)
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	var title := Label.new()
	title.text = Loc.t("menu.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05, 1))
	title.add_theme_constant_override("outline_size", 8)
	col.add_child(title)

	var sub := Label.new()
	sub.text = Loc.t("menu.subtitle")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.72, 0.66, 0.55, 1))
	col.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	col.add_child(spacer)

	_btn_continue = _make_btn(Loc.t("menu.continue"), _on_continue)
	_btn_new = _make_btn(Loc.t("menu.new"), func(): _set_view(View.NEW))
	_btn_load = _make_btn(Loc.t("menu.load"), func(): _set_view(View.LOAD))
	_btn_quit = _make_btn(Loc.t("menu.quit"), func(): get_tree().quit())
	col.add_child(_btn_continue)
	col.add_child(_btn_new)
	col.add_child(_btn_load)
	col.add_child(_btn_quit)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(0.78, 0.72, 0.6, 1))
	col.add_child(_hint)

	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 8)
	col.add_child(_slot_list)

	_btn_back = _make_btn(Loc.t("menu.back"), func(): _set_view(View.ROOT))
	col.add_child(_btn_back)

	_confirm = Panel.new()
	_confirm.visible = false
	_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	_confirm.add_child(dim)
	var box := Panel.new()
	box.name = "Box"
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -210
	box.offset_right = 210
	box.offset_top = -90
	box.offset_bottom = 90
	_confirm.add_child(box)
	var ctext := Label.new()
	ctext.name = "Text"
	ctext.position = Vector2(20, 18)
	ctext.size = Vector2(380, 70)
	ctext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ctext.add_theme_font_size_override("font_size", 15)
	box.add_child(ctext)
	var yes := Button.new()
	yes.name = "Yes"
	yes.text = Loc.t("menu.confirm_yes")
	yes.position = Vector2(40, 100)
	yes.size = Vector2(140, 36)
	box.add_child(yes)
	var no := Button.new()
	no.name = "No"
	no.text = Loc.t("menu.confirm_no")
	no.position = Vector2(220, 100)
	no.size = Vector2(140, 36)
	no.pressed.connect(func(): _confirm.visible = false)
	box.add_child(no)

	_set_view(View.ROOT)


func _make_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	return b


func _set_view(v: View) -> void:
	_view = v
	_confirm.visible = false
	var show_root := v == View.ROOT
	_btn_continue.visible = show_root
	_btn_new.visible = show_root
	_btn_load.visible = show_root
	_btn_quit.visible = show_root
	_btn_continue.disabled = not MetaProgress.has_any_save()
	_btn_back.visible = not show_root
	_slot_list.visible = not show_root
	match v:
		View.ROOT:
			_hint.text = ""
			_clear_slots()
		View.NEW:
			_hint.text = Loc.t("menu.pick_new")
			_rebuild_slots(true)
		View.LOAD:
			_hint.text = Loc.t("menu.pick_load")
			_rebuild_slots(false)


func _clear_slots() -> void:
	for c in _slot_list.get_children():
		c.queue_free()


func _rebuild_slots(for_new: bool) -> void:
	_clear_slots()
	for i in range(1, MetaProgress.SLOT_COUNT + 1):
		_slot_list.add_child(_make_slot_row(i, for_new))


func _make_slot_row(slot: int, for_new: bool) -> Control:
	var info: Dictionary = MetaProgress.slot_summary(slot)
	var empty: bool = bool(info.get("empty", true))
	var row := PanelContainer.new()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	row.add_child(inner)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	inner.add_child(pad)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	pad.add_child(body)

	var title := Label.new()
	title.text = Loc.t("menu.slot_title", [slot])
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.93, 0.86, 0.68, 1))
	body.add_child(title)

	var detail := Label.new()
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6, 1))
	if empty:
		detail.text = Loc.t("menu.slot_empty")
	else:
		detail.text = Loc.t("menu.slot_summary", [
			int(info.get("game_day", 1)),
			int(info.get("explorer_level", 1)),
			int(info.get("gold", 0)),
		])
		var t := str(info.get("saved_at", ""))
		if t != "":
			detail.text += "\n" + Loc.t("menu.slot_time", [t])
	body.add_child(detail)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	body.add_child(btns)
	if for_new:
		var start := Button.new()
		start.text = Loc.t("menu.overwrite") if not empty else Loc.t("menu.use_slot")
		start.custom_minimum_size = Vector2(120, 30)
		var captured := slot
		var occ := not empty
		start.pressed.connect(func(): _on_new_slot(captured, occ))
		btns.add_child(start)
	else:
		var load_b := Button.new()
		load_b.text = Loc.t("menu.load_slot")
		load_b.disabled = empty
		load_b.custom_minimum_size = Vector2(90, 30)
		var s1 := slot
		load_b.pressed.connect(func(): _enter_slot(s1, false))
		btns.add_child(load_b)
		var del_b := Button.new()
		del_b.text = Loc.t("menu.delete_slot")
		del_b.disabled = empty
		del_b.custom_minimum_size = Vector2(90, 30)
		var s2 := slot
		del_b.pressed.connect(func(): _ask_delete(s2))
		btns.add_child(del_b)
	return row


func _on_continue() -> void:
	if not MetaProgress.has_any_save():
		_hint.text = Loc.t("menu.no_save")
		return
	var s := MetaProgress.last_played_slot()
	if s < 1:
		_set_view(View.LOAD)
		return
	_enter_slot(s, false)


func _on_new_slot(slot: int, occupied: bool) -> void:
	if occupied:
		_ask_confirm(Loc.t("menu.confirm_overwrite", [slot]), func(): _enter_slot(slot, true))
	else:
		_enter_slot(slot, true)


func _ask_delete(slot: int) -> void:
	_ask_confirm(Loc.t("menu.confirm_delete", [slot]), func():
		MetaProgress.delete_slot(slot)
		_rebuild_slots(_view == View.NEW)
		_btn_continue.disabled = not MetaProgress.has_any_save()
	)


func _ask_confirm(text: String, on_yes: Callable) -> void:
	var box: Panel = _confirm.get_node("Box")
	box.get_node("Text").text = text
	var yes: Button = box.get_node("Yes")
	for c in yes.pressed.get_connections():
		yes.pressed.disconnect(c.callable)
	yes.pressed.connect(func():
		_confirm.visible = false
		on_yes.call()
	)
	_confirm.visible = true


func _enter_slot(slot: int, is_new: bool) -> void:
	if is_new:
		if not MetaProgress.new_game(slot):
			return
	elif not MetaProgress.load_slot(slot):
		return
	get_tree().change_scene_to_file(HUB_SCENE)
