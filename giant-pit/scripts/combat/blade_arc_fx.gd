extends Node2D
## 大刀刀芒：挥砍拖尾 + 斩击扇面闪光 + 残影。


var _glow: Line2D
var _core: Line2D
var _points: PackedVector2Array = PackedVector2Array()
var _trailing: bool = false
var _fade: float = 0.0
var _flash_t: float = 0.0
var _flash_max: float = 0.20
var _flash_from: float = 0.0
var _flash_to: float = 0.0
var _flash_r: float = 46.0
var _flash_col: Color = Color(1.0, 0.95, 0.75, 0.5)
var _trail_col: Color = Color(1.0, 0.92, 0.7, 1.0)
var _trail_width: float = 10.0


func _ready() -> void:
	z_index = 12
	_glow = Line2D.new()
	_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	_glow.antialiased = true
	add_child(_glow)
	_core = Line2D.new()
	_core.joint_mode = Line2D.LINE_JOINT_ROUND
	_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_core.end_cap_mode = Line2D.LINE_CAP_ROUND
	_core.antialiased = true
	add_child(_core)
	_apply_gradients()


func begin_slash(trail_col: Color, width: float, from_deg: float, to_deg: float, radius: float, flash_col: Color) -> void:
	_trailing = true
	_fade = 1.0
	_points = PackedVector2Array()
	_trail_col = trail_col
	_trail_width = width
	_flash_from = from_deg
	_flash_to = to_deg
	_flash_r = radius
	_flash_col = flash_col
	_flash_t = _flash_max
	_glow.modulate.a = 1.0
	_core.modulate.a = 1.0
	_apply_gradients()
	queue_redraw()


func push_tip_local(p: Vector2) -> void:
	if not _trailing:
		return
	if _points.size() > 0 and _points[_points.size() - 1].distance_squared_to(p) < 1.4:
		return
	_points.append(p)
	if _points.size() > 30:
		var trimmed := PackedVector2Array()
		for i in range(_points.size() - 30, _points.size()):
			trimmed.append(_points[i])
		_points = trimmed
	_sync_lines()


func end_slash() -> void:
	_trailing = false


func spawn_ghost(tex: Texture2D, local_pos: Vector2, rot: float, col: Color) -> void:
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = local_pos
	s.rotation = rot
	s.modulate = col
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = 9
	add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(s.queue_free)


func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t = maxf(_flash_t - delta, 0.0)
		queue_redraw()
	if _trailing:
		_glow.modulate.a = 1.0
		_core.modulate.a = 1.0
		return
	if _fade <= 0.0:
		return
	_fade = maxf(_fade - delta * 3.8, 0.0)
	_glow.modulate.a = _fade
	_core.modulate.a = _fade
	if _fade <= 0.0:
		_points = PackedVector2Array()
		_sync_lines()


func _draw() -> void:
	if _flash_t <= 0.01:
		return
	var a := clampf(_flash_t / _flash_max, 0.0, 1.0)
	var col := Color(_flash_col.r, _flash_col.g, _flash_col.b, _flash_col.a * a)
	var steps := 18
	var fan := PackedVector2Array()
	fan.append(Vector2.ZERO)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var ang := deg_to_rad(lerpf(_flash_from, _flash_to, t))
		fan.append(Vector2.from_angle(ang) * _flash_r)
	draw_colored_polygon(fan, col)
	var rim := PackedVector2Array()
	for i in steps + 1:
		var t2 := float(i) / float(steps)
		var ang2 := deg_to_rad(lerpf(_flash_from, _flash_to, t2))
		rim.append(Vector2.from_angle(ang2) * (_flash_r + 5.0))
	draw_polyline(rim, Color(1.0, 1.0, 0.92, col.a * 0.85), 2.4, true)
	## 刃心高光弧
	var inner := PackedVector2Array()
	for i in steps + 1:
		var t3 := float(i) / float(steps)
		var ang3 := deg_to_rad(lerpf(_flash_from, _flash_to, t3))
		inner.append(Vector2.from_angle(ang3) * (_flash_r * 0.62))
	draw_polyline(inner, Color(1.0, 0.98, 0.88, col.a * 0.9), 1.6, true)


func _apply_gradients() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.28, 1.0])
	g.colors = PackedColorArray([
		Color(_trail_col.r, _trail_col.g, _trail_col.b, 0.0),
		Color(_trail_col.r, _trail_col.g, _trail_col.b, 0.42),
		Color(1.0, 0.98, 0.9, 0.95),
	])
	_glow.gradient = g
	_glow.width = _trail_width * 1.7
	_glow.default_color = Color(_trail_col.r, _trail_col.g, _trail_col.b, 0.35)
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g2.colors = PackedColorArray([
		Color(1.0, 1.0, 0.9, 0.0),
		Color(1.0, 0.97, 0.82, 0.75),
		Color(1.0, 1.0, 1.0, 1.0),
	])
	_core.gradient = g2
	_core.width = maxf(_trail_width * 0.34, 2.4)


func _sync_lines() -> void:
	_glow.points = _points
	_core.points = _points
