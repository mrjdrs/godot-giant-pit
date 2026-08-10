extends CanvasLayer
## ESC 暂停菜单：继续 / 回主界面 / 退出。

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

var _host: Node = null
var _open: bool = false
var _root: Control = null
var _confirm: Control = null
var _confirm_text: Label = null
var _confirm_yes: Button = null
var _btn_continue: Button = null


static func install(host: Node) -> CanvasLayer:
	if host == null:
		return null
	if host.has_node("PauseMenu"):
		return host.get_node("PauseMenu")
	var pm := CanvasLayer.new()
	pm.name = "PauseMenu"
	pm.layer = 80
	pm.process_mode = Node.PROCESS_MODE_ALWAYS
	pm.set_script(load("res://scripts/ui/pause_menu.gd"))
	host.add_child(pm)
	if pm.has_method("setup"):
		pm.setup(host)
	return pm


func setup(host: Node) -> void:
	_host = host


func is_open() -> bool:
	return _open


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false
	_confirm.visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if _settling():
		return
	if _confirm != null and _confirm.visible:
		_confirm.visible = false
		get_viewport().set_input_as_handled()
		return
	if _open:
		close_menu()
		get_viewport().set_input_as_handled()
		return
	if _try_close_blocking_ui():
		get_viewport().set_input_as_handled()
		return
	open_menu()
	get_viewport().set_input_as_handled()


func open_menu() -> void:
	if _open or _settling() or _blocking_ui():
		return
	_open = true
	_confirm.visible = false
	_root.visible = true
	get_tree().paused = true
	_lock_player(true)
	if _btn_continue:
		_btn_continue.grab_focus()


func close_menu() -> void:
	if not _open:
		return
	_open = false
	_confirm.visible = false
	_root.visible = false
	get_tree().paused = false
	_lock_player(false)


func _blocking_ui() -> bool:
	if _host == null:
		return false
	var sh = _host.get("sheet_host")
	if sh != null and sh.has_method("any_open") and sh.any_open():
		return true
	var hub_panel = _host.get("panel")
	if hub_panel is Control and hub_panel.visible:
		return true
	if _host.has_node("HUD/WarpPanel") and _host.get_node("HUD/WarpPanel").visible:
		return true
	if _host.has_node("HUD/QuestPanel") and _host.get_node("HUD/QuestPanel").visible:
		return true
	return false


func _try_close_blocking_ui() -> bool:
	if _host == null:
		return false
	var sh = _host.get("sheet_host")
	if sh != null and sh.has_method("any_open") and sh.any_open():
		if sh.has_method("close_all"):
			sh.close_all()
		return true
	if _host.has_method("_close_panel"):
		var hub_panel = _host.get("panel")
		if hub_panel is Control and hub_panel.visible:
			_host.call("_close_panel")
			return true
	if _host.has_method("_close_warp_menu") and _host.has_node("HUD/WarpPanel") \
			and _host.get_node("HUD/WarpPanel").visible:
		_host.call("_close_warp_menu")
		return true
	if _host.has_method("_close_quest_panel"):
		var quest_open := bool(_host.get("_quest_open")) if "_quest_open" in _host else false
		if quest_open or (_host.has_node("HUD/QuestPanel") and _host.get_node("HUD/QuestPanel").visible):
			_host.call("_close_quest_panel")
			return true
	return false


func _settling() -> bool:
	if _host == null:
		return false
	for n in ["ExtractUI", "DeathUI"]:
		if _host.has_node(n) and _host.get_node(n).visible:
			return true
	if "_run_over" in _host and bool(_host.get("_run_over")):
		return true
	return false


func _lock_player(on: bool) -> void:
	var p = _host.get("player") if _host else null
	if p == null or not is_instance_valid(p):
		return
	if on:
		p.input_locked = true
		return
	if _settling():
		return
	p.input_locked = false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.03, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(320, 0)
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	var title := Label.new()
	title.text = Loc.t("pause.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05, 1))
	title.add_theme_constant_override("outline_size", 6)
	col.add_child(title)

	_btn_continue = _make_btn(Loc.t("pause.continue"), close_menu)
	col.add_child(_btn_continue)
	col.add_child(_make_btn(Loc.t("pause.main_menu"), _on_main_menu))
	col.add_child(_make_btn(Loc.t("pause.quit"), _on_quit))

	_confirm = Control.new()
	_confirm.visible = false
	_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_confirm)
	var cdim := ColorRect.new()
	cdim.set_anchors_preset(Control.PRESET_FULL_RECT)
	cdim.color = Color(0, 0, 0, 0.45)
	_confirm.add_child(cdim)
	var box := Panel.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -200
	box.offset_right = 200
	box.offset_top = -88
	box.offset_bottom = 88
	_confirm.add_child(box)
	_confirm_text = Label.new()
	_confirm_text.position = Vector2(18, 16)
	_confirm_text.size = Vector2(364, 78)
	_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_text.add_theme_font_size_override("font_size", 15)
	box.add_child(_confirm_text)
	_confirm_yes = Button.new()
	_confirm_yes.text = Loc.t("menu.confirm_yes")
	_confirm_yes.position = Vector2(36, 100)
	_confirm_yes.size = Vector2(140, 36)
	box.add_child(_confirm_yes)
	var no := Button.new()
	no.text = Loc.t("menu.confirm_no")
	no.position = Vector2(210, 100)
	no.size = Vector2(140, 36)
	no.pressed.connect(func(): _confirm.visible = false)
	box.add_child(no)


func _make_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 42)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	return b


func _on_main_menu() -> void:
	if RunSession.active:
		_ask_confirm(Loc.t("pause.confirm_leave_run"), _go_main_menu)
		return
	_go_main_menu()


func _on_quit() -> void:
	_ask_confirm(Loc.t("pause.confirm_quit"), func():
		get_tree().paused = false
		get_tree().quit()
	)


func _ask_confirm(text: String, on_yes: Callable) -> void:
	_confirm_text.text = text
	for c in _confirm_yes.pressed.get_connections():
		_confirm_yes.pressed.disconnect(c.callable)
	_confirm_yes.pressed.connect(func():
		_confirm.visible = false
		on_yes.call()
	)
	_confirm.visible = true


func _go_main_menu() -> void:
	get_tree().paused = false
	_open = false
	RunSession.clear()
	MetaProgress.save_game()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
