extends Node2D
## 元素爆发分派：按 element 绘制不同 AoE 视觉。


var _t: float = 0.0
var _dur: float = 0.45
var _r1: float = 56.0
var _col: Color = Color(1.0, 0.42, 0.14, 0.9)
var _element: String = "fire"


func setup(pos: Vector2, radius: float, element: String = "fire", col: Color = Color(1.0, 0.42, 0.14, 0.9), dur: float = 0.45) -> void:
	global_position = pos
	_r1 = radius
	_element = element
	_col = col
	_dur = dur
	z_index = 15


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := _col.a * (1.0 - u * 0.85)
	var r := lerpf(8.0, _r1, u)
	match _element:
		"ice":
			_draw_ice(u, a, r)
		"acid":
			_draw_acid(u, a, r)
		"dark":
			_draw_dark(u, a, r)
		"light":
			_draw_light(u, a, r)
		_:
			_draw_fire(u, a, r)


func _draw_fire(u: float, a: float, r: float) -> void:
	if u < 0.45:
		var ra := a * (1.0 - u / 0.45)
		draw_arc(Vector2.ZERO, r * 0.55, u * 3.0, u * 3.0 + TAU, 36, Color(0.7, 0.4, 1.0, ra), 2.4, true)
		for i in 5:
			var ang := u * 2.0 + TAU * float(i) / 5.0
			var p := Vector2.from_angle(ang) * r * 0.55
			draw_colored_polygon(PackedVector2Array([
				p + Vector2.from_angle(ang) * 4.0,
				p + Vector2.from_angle(ang + 2.1) * 2.8,
				p + Vector2.from_angle(ang - 2.1) * 2.8,
			]), Color(0.85, 0.55, 1.0, ra))
	for i in 8:
		var ang := -1.0 + float(i) * 0.28
		var tip := Vector2.from_angle(ang - PI * 0.5) * r * (0.5 + 0.5 * (1.0 - u))
		var side := 8.0 * (1.0 - u * 0.45)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-side * 0.4, 6.0), tip, Vector2(side * 0.4, 6.0),
		]), Color(_col.r, _col.g, _col.b, a * (0.5 + 0.08 * float(i % 2))))
	for i in 10:
		var ang2 := TAU * float(i) / 10.0 + u * 1.6
		var p2 := Vector2.from_angle(ang2) * r * (0.4 + 0.5 * u) + Vector2(0, -u * 18.0)
		var ember_col := Color(1.0, 0.7, 0.25, a) if i % 2 == 0 else Color(0.85, 0.4, 1.0, a)
		draw_circle(p2, 2.6 - u * 1.5, ember_col)
	draw_circle(Vector2.ZERO, r * 0.22, Color(1.0, 0.85, 0.4, a * 0.55))


func _draw_ice(u: float, a: float, r: float) -> void:
	draw_arc(Vector2.ZERO, r * u, 0.0, TAU, 32, Color(0.7, 0.92, 1.0, a * 0.6), 2.0, true)
	for i in 6:
		var ang := TAU * float(i) / 6.0 + u * 0.5
		var ray_length := r * (0.3 + 0.7 * u)
		var tip := Vector2.from_angle(ang) * ray_length
		var side := Vector2.from_angle(ang + PI * 0.5) * 4.0
		draw_colored_polygon(PackedVector2Array([
			tip, tip * 0.3 + side, tip * 0.3 - side,
		]), Color(0.85, 0.97, 1.0, a * 0.8))
	draw_circle(Vector2.ZERO, r * 0.15 * u, Color(1.0, 1.0, 1.0, a * 0.7))


func _draw_acid(u: float, a: float, r: float) -> void:
	draw_circle(Vector2.ZERO, r * u * 0.85, Color(0.4, 0.85, 0.15, a * 0.35))
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var p := Vector2.from_angle(ang) * r * u * 0.7
		draw_circle(p, 3.0 + sin(u * 20.0 + float(i)) * 1.5, Color(0.55, 0.95, 0.2, a * 0.7))
	draw_arc(Vector2.ZERO, r * u, 0.0, TAU, 24, Color(0.65, 1.0, 0.25, a), 2.5, true)


func _draw_dark(u: float, a: float, r: float) -> void:
	for i in 12:
		var ang := TAU * float(i) / 12.0 + u * 2.0
		var dist := r * (1.0 - u * 0.7) * 0.5
		var p := Vector2.from_angle(ang) * dist
		draw_circle(p, 2.5, Color(0.4, 0.12, 0.65, a))
	draw_arc(Vector2.ZERO, r * u * 0.6, u * 4.0, u * 4.0 + TAU, 28, Color(0.55, 0.18, 0.85, a * 0.7), 2.0, true)
	draw_circle(Vector2.ZERO, r * 0.12, Color(0.15, 0.05, 0.25, a))


func _draw_light(u: float, a: float, r: float) -> void:
	draw_circle(Vector2.ZERO, r * u * 0.4, Color(1.0, 0.96, 0.7, a * 0.6))
	draw_line(Vector2(-r * u, 0), Vector2(r * u, 0), Color(1.0, 0.95, 0.55, a), 2.5)
	draw_line(Vector2(0, -r * u), Vector2(0, r * u), Color(1.0, 0.95, 0.55, a), 2.5)
	draw_arc(Vector2.ZERO, r * u * 0.75, 0.0, TAU, 24, Color(1.0, 0.92, 0.5, a * 0.5), 1.8, true)
	for i in 6:
		var ang := TAU * float(i) / 6.0
		var p := Vector2.from_angle(ang) * r * 0.5 * u + Vector2(0, -u * 12.0)
		draw_circle(p, 2.0, Color(1.0, 0.98, 0.75, a * 0.9))
