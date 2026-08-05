extends Control
## 右下角事件日志：击杀、拾取、系统等，按类别着色。

class_name PitEventLog

enum Category { KILL, PICKUP, RUNE, SYSTEM, WARN }

const MAX_LINES := 10
const FADE_SEC := 8.0

const CATEGORY_COLORS := {
	Category.KILL: Color(1.0, 0.55, 0.45, 1),
	Category.PICKUP: Color(0.72, 0.92, 0.62, 1),
	Category.RUNE: Color(0.78, 0.62, 1.0, 1),
	Category.SYSTEM: Color(0.82, 0.86, 0.92, 1),
	Category.WARN: Color(1.0, 0.88, 0.42, 1),
}

@onready var _list: VBoxContainer = $Panel/Margin/List


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _list == null:
		_build_fallback()


func _build_fallback() -> void:
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_list)


func push(text: String, category: int = Category.SYSTEM, color_override: Color = Color.TRANSPARENT) -> void:
	if text.strip_edges() == "" or _list == null:
		return
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = size.x - 16.0 if size.x > 32.0 else 220.0
	label.add_theme_font_size_override("font_size", 13)
	var col: Color = color_override if color_override.a > 0.01 else CATEGORY_COLORS.get(category, CATEGORY_COLORS[Category.SYSTEM])
	label.add_theme_color_override("font_color", col)
	label.modulate.a = 0.0
	_list.add_child(label)
	## remove_child first: queue_free alone does not lower get_child_count until frame end.
	var guard := 0
	while _list.get_child_count() > MAX_LINES and guard < 64:
		var old: Node = _list.get_child(0)
		_list.remove_child(old)
		old.queue_free()
		guard += 1
	var tw := label.create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.12)
	tw.tween_interval(FADE_SEC)
	tw.tween_property(label, "modulate:a", 0.35, 0.8)
