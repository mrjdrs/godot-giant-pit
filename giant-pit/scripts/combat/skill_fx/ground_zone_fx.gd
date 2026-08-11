extends Node2D
## 持续地面区域：火池 / 霜迹 / 酸池 / 暗影 / 光域。


var _t: float = 0.0
var _dur: float = 3.0
var _radius: float = 36.0
var _element: String = "fire"
var _col: Color = Color(1.0, 0.42, 0.14, 0.5)


func setup(pos: Vector2, radius: float, element: String, col: Color, dur: float = 3.0) -> void:
	global_position = pos
	_radius = radius
	_element = element
	_col = col
	_dur = dur
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var fade := 1.0 - u * 0.85
	var a := _col.a * fade
	match _element:
		"ice":
			draw_circle(Vector2.ZERO, _radius, Color(0.55, 0.85, 1.0, a * 0.35))
			draw_arc(Vector2.ZERO, _radius * 0.85, _t * 0.5, _t * 0.5 + TAU, 24, Color(0.75, 0.95, 1.0, a * 0.5), 1.5, true)
		"acid":
			draw_circle(Vector2.ZERO, _radius, Color(0.45, 0.9, 0.15, a * 0.4))
			for i in 5:
				var ang := TAU * float(i) / 5.0 + _t * 1.2
				draw_circle(Vector2.from_angle(ang) * _radius * 0.5, 2.5 + sin(_t * 8.0 + float(i)), Color(0.6, 1.0, 0.25, a * 0.7))
		"dark":
			draw_circle(Vector2.ZERO, _radius, Color(0.25, 0.08, 0.45, a * 0.45))
			draw_arc(Vector2.ZERO, _radius * 0.7, -_t * 2.0, -_t * 2.0 + TAU, 20, Color(0.45, 0.15, 0.75, a * 0.4), 1.2, true)
		"light":
			draw_circle(Vector2.ZERO, _radius, Color(1.0, 0.95, 0.6, a * 0.25))
			draw_arc(Vector2.ZERO, _radius * 0.9, 0.0, TAU, 20, Color(1.0, 0.92, 0.5, a * 0.35), 1.0, true)
		_:
			draw_circle(Vector2.ZERO, _radius, Color(_col.r, _col.g, _col.b, a * 0.45))
			for i in 4:
				var ang := TAU * float(i) / 4.0 + _t
				draw_circle(Vector2.from_angle(ang) * _radius * 0.4, 3.0, Color(1.0, 0.55, 0.2, a * 0.6))
