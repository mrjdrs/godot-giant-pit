extends Node2D
## 焰咒爆发：先符文几何感，再上窜火舌 + 紫火星（法术语言）。


var _t: float = 0.0
var _dur: float = 0.45
var _r1: float = 56.0
var _col: Color = Color(1.0, 0.42, 0.14, 0.9)


func setup(pos: Vector2, radius: float, col: Color = Color(1.0, 0.42, 0.14, 0.9), dur: float = 0.45) -> void:
	global_position = pos
	_r1 = radius
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
	## 早期紫色符文环
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
	## 上窜火舌（法术核心可读）
	for i in 8:
		var ang := -1.0 + float(i) * 0.28
		var tip := Vector2.from_angle(ang - PI * 0.5) * r * (0.5 + 0.5 * (1.0 - u))
		var side := 8.0 * (1.0 - u * 0.45)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-side * 0.4, 6.0),
			tip,
			Vector2(side * 0.4, 6.0),
		]), Color(_col.r, _col.g, _col.b, a * (0.5 + 0.08 * float(i % 2))))
	## 紫/橙火星上飘
	for i in 10:
		var ang2 := TAU * float(i) / 10.0 + u * 1.6
		var p2 := Vector2.from_angle(ang2) * r * (0.4 + 0.5 * u) + Vector2(0, -u * 18.0)
		var ember_col := Color(1.0, 0.7, 0.25, a) if i % 2 == 0 else Color(0.85, 0.4, 1.0, a)
		draw_circle(p2, 2.6 - u * 1.5, ember_col)
	draw_circle(Vector2.ZERO, r * 0.22, Color(1.0, 0.85, 0.4, a * 0.55))
