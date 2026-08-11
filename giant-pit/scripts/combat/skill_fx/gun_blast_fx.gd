extends Node2D
## 火铳爆炸：烟环 + 碎屑方块 + 白芯闪光（机械/炼金，非火舌）。


var _t: float = 0.0
var _dur: float = 0.4
var _r1: float = 56.0
var _col: Color = Color(1.0, 0.72, 0.35, 0.8)


func setup(pos: Vector2, radius: float, col: Color = Color(1.0, 0.72, 0.35, 0.8), dur: float = 0.4) -> void:
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
	var a := _col.a * (1.0 - u * 0.92)
	var r := lerpf(6.0, _r1, u)
	## 灰烟外环
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(0.55, 0.52, 0.48, a * 0.75), 5.0, true)
	draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 32, Color(0.4, 0.78, 0.82, a * 0.4), 2.0, true)
	draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 28, Color(_col.r, _col.g, _col.b, a * 0.5), 2.4, true)
	## 方碎屑（枪感）
	for i in 12:
		var ang := TAU * float(i) / 12.0 + u * 0.9
		var p := Vector2.from_angle(ang) * r * (0.3 + 0.6 * u)
		var s := 3.2 - u * 2.0
		draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), Color(0.9, 0.75, 0.45, a))
	## 白芯
	draw_circle(Vector2.ZERO, 8.0 * (1.0 - u), Color(0.95, 0.98, 1.0, a))
