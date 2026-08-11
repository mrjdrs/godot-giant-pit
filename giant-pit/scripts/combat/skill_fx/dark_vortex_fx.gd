extends Node2D
## 暗影/元素漩涡：吸聚 + 减益视觉。


var _t: float = 0.0
var _dur: float = 1.5
var _radius: float = 56.0
var _col: Color = Color(0.45, 0.15, 0.75, 0.85)


func setup(pos: Vector2, radius: float, col: Color = Color(0.45, 0.15, 0.75, 0.85), dur: float = 1.5) -> void:
	global_position = pos
	_radius = radius
	_col = col
	_dur = dur
	z_index = 13


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := _col.a * (1.0 - u * 0.5)
	for i in 16:
		var ang := -_t * 3.0 + TAU * float(i) / 16.0
		var dist := _radius * (0.2 + 0.8 * (1.0 - u * 0.5))
		var p := Vector2.from_angle(ang) * dist
		draw_circle(p, 2.0 + float(i % 3), Color(_col.r, _col.g, _col.b, a * 0.7))
	draw_arc(Vector2.ZERO, _radius * (0.5 + 0.3 * sin(_t * 4.0)), _t * 2.0, _t * 2.0 + TAU, 24, Color(_col.r, _col.g, _col.b, a * 0.4), 1.5, true)
	draw_circle(Vector2.ZERO, _radius * 0.15, Color(0.1, 0.03, 0.2, a))
