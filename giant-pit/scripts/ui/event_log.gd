extends Control
## 右侧事件日志：近 50 条，裁剪在框内，滚轮翻阅；默认贴底跟最新。

class_name PitEventLog

enum Category { KILL, PICKUP, RUNE, SYSTEM, WARN }

const MAX_LINES := 50
const STICK_SLACK := 28.0

const CATEGORY_COLORS := {
	Category.KILL: Color(1.0, 0.55, 0.45, 1),
	Category.PICKUP: Color(0.72, 0.92, 0.62, 1),
	Category.RUNE: Color(0.78, 0.62, 1.0, 1),
	Category.SYSTEM: Color(0.82, 0.86, 0.92, 1),
	Category.WARN: Color(1.0, 0.88, 0.42, 1),
}

var _list: VBoxContainer
var _scroll: ScrollContainer
var _stick_to_bottom: bool = true
var _ignore_scroll_signal: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_ensure_tree()
	if _scroll:
		var bar := _scroll.get_v_scroll_bar()
		if not bar.value_changed.is_connected(_on_user_scrolled):
			bar.value_changed.connect(_on_user_scrolled)
	_fit_list_width()
	resized.connect(_fit_list_width)


func _fit_list_width() -> void:
	if _list == null or _scroll == null:
		return
	_list.custom_minimum_size.x = maxf(_scroll.size.x - 4.0, 80.0)


func _ensure_tree() -> void:
	_list = get_node_or_null("Panel/Margin/Scroll/List") as VBoxContainer
	_scroll = get_node_or_null("Panel/Margin/Scroll") as ScrollContainer
	if _list != null and _scroll != null:
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return
	_build_fallback()


func _build_fallback() -> void:
	for c in get_children():
		c.queue_free()
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)


func push(text: String, category: int = Category.SYSTEM, color_override: Color = Color.TRANSPARENT) -> void:
	if text.strip_edges() == "" or _list == null:
		return
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	var col: Color = color_override if color_override.a > 0.01 else CATEGORY_COLORS.get(category, CATEGORY_COLORS[Category.SYSTEM])
	label.add_theme_color_override("font_color", col)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(label)
	var guard := 0
	while _list.get_child_count() > MAX_LINES and guard < 80:
		var old: Node = _list.get_child(0)
		_list.remove_child(old)
		old.queue_free()
		guard += 1
	if _stick_to_bottom:
		call_deferred("_scroll_to_latest")
		if is_inside_tree() and not get_tree().process_frame.is_connected(_scroll_to_latest):
			get_tree().process_frame.connect(_scroll_to_latest, CONNECT_ONE_SHOT)


func _on_user_scrolled(_v: float) -> void:
	if _ignore_scroll_signal:
		return
	_refresh_stick()


func _refresh_stick() -> void:
	if _scroll == null:
		_stick_to_bottom = true
		return
	var bar := _scroll.get_v_scroll_bar()
	var max_scroll := maxf(0.0, bar.max_value - bar.page)
	_stick_to_bottom = _scroll.scroll_vertical >= max_scroll - STICK_SLACK


func _scroll_to_latest() -> void:
	if _scroll == null or _list == null or _list.get_child_count() == 0:
		return
	_ignore_scroll_signal = true
	var last: Control = _list.get_child(_list.get_child_count() - 1) as Control
	if last:
		_scroll.ensure_control_visible(last)
	var bar := _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = int(round(maxf(0.0, bar.max_value - bar.page)))
	_ignore_scroll_signal = false
	_stick_to_bottom = true
