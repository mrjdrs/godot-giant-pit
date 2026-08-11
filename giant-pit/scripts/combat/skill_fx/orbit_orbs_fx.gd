extends Node2D
## 绕身元素球：3 颗按元素形变旋转。


var _t: float = 0.0
var _dur: float = 2.0
var _radius: float = 48.0
var _element: String = "fire"
var _col: Color = Color(1.0, 0.42, 0.18, 0.9)
var _count: int = 3


func setup(radius: float, element: String, col: Color, dur: float = 2.0, count: int = 3) -> void:
	_radius = radius
	_element = element
	_col = col
	_dur = dur
	_count = maxi(count, 1)
	z_index = 12


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - clampf(_t / maxf(_dur, 0.001), 0.0, 1.0) * 0.3
	for i in _count:
		var ang := _t * 3.5 + TAU * float(i) / float(_count)
		var p := Vector2.from_angle(ang) * _radius
		match _element:
			"ice":
				var tip := p + Vector2.from_angle(ang) * 6.0
				var side := Vector2.from_angle(ang + PI * 0.5) * 3.0
				draw_colored_polygon(PackedVector2Array([tip, p + side, p - side]), Color(0.75, 0.95, 1.0, fade))
			"acid":
				draw_circle(p, 5.0 + sin(_t * 6.0 + float(i)) * 1.5, Color(0.55, 0.95, 0.2, fade * 0.85))
			"dark":
				draw_circle(p, 4.5, Color(0.35, 0.1, 0.55, fade * 0.9))
				draw_circle(p, 2.0, Color(0.15, 0.05, 0.25, fade))
			"light":
				draw_circle(p, 5.0, Color(1.0, 0.95, 0.6, fade * 0.7))
				draw_circle(p, 2.5, Color(1.0, 1.0, 0.9, fade))
			_:
				draw_circle(p, 6.0, Color(_col.r, _col.g, _col.b, fade * 0.85))
				draw_circle(p, 3.0, Color(1.0, 0.85, 0.4, fade * 0.9))
