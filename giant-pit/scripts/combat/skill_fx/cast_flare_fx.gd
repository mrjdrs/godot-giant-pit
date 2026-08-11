extends Node2D
## 焰咒施法焰：落点/身前短时火环与火星。


var _t: float = 0.0
var _dur: float = 0.22
var _col: Color = Color(1.0, 0.45, 0.18, 0.9)
var _r: float = 18.0


func setup(pos: Vector2, col: Color = Color(1.0, 0.45, 0.18, 0.9), radius: float = 18.0, dur: float = 0.22) -> void:
	global_position = pos
	_col = col
	_r = radius
	_dur = dur
	z_index = 17


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := _col.a * (1.0 - u * 0.85)
	var r := _r * (0.55 + 0.7 * u)
	draw_circle(Vector2.ZERO, r * 0.35, Color(_col.r, _col.g * 0.7, _col.b * 0.35, a * 0.55))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(_col.r, _col.g, _col.b, a), 2.4, true)
	for i in 6:
		var ang := TAU * float(i) / 6.0 + u * 1.2
		var p := Vector2.from_angle(ang) * r * (0.4 + 0.5 * u)
		draw_circle(p, 2.2 - u * 1.2, Color(1.0, 0.72, 0.28, a * 0.9))
