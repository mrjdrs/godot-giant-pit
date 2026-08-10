extends Node2D
## 旋风斩：绕身旋转刀环。


var _t: float = 0.0
var _dur: float = 0.45
var _radius: float = 40.0
var _col: Color = Color(0.42, 0.92, 0.72, 0.85)
var _spin: float = 0.0
var _follow: Node2D = null


func setup(follow: Node2D, radius: float, col: Color, dur: float = 0.45) -> void:
	_follow = follow
	_radius = radius
	_col = col
	_dur = dur
	z_index = 13
	if follow:
		global_position = follow.global_position


func _process(delta: float) -> void:
	_t += delta
	_spin += delta * 14.0
	if is_instance_valid(_follow):
		global_position = _follow.global_position
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := _col.a * (1.0 - u * 0.35)
	for i in 6:
		var ang := _spin + TAU * float(i) / 6.0
		var p0 := Vector2.from_angle(ang) * (_radius * 0.35)
		var p1 := Vector2.from_angle(ang + 0.55) * _radius
		draw_line(p0, p1, Color(_col.r, _col.g, _col.b, a), 3.0, true)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 36, Color(_col.r, _col.g, _col.b, a * 0.55), 2.4, true)
