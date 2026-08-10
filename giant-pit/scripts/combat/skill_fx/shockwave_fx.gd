extends Node2D
## 崩山击 / 坑冠碎：扩散冲击环。


var _t: float = 0.0
var _dur: float = 0.36
var _r0: float = 10.0
var _r1: float = 64.0
var _col: Color = Color(1.0, 0.55, 0.22, 0.75)
var _dust: bool = false


func setup(pos: Vector2, radius: float, col: Color, dur: float = 0.36, dust: bool = true) -> void:
	global_position = pos
	_r1 = radius
	_col = col
	_dur = dur
	_dust = dust
	z_index = 14


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var r := lerpf(_r0, _r1, u)
	var a := _col.a * (1.0 - u * u)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(_col.r, _col.g, _col.b, a), 3.2, true)
	draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 28, Color(_col.r, _col.g, _col.b, a * 0.45), 2.0, true)
	if _dust:
		for i in 8:
			var ang := TAU * float(i) / 8.0 + u * 0.6
			var p := Vector2.from_angle(ang) * r * (0.55 + 0.35 * u)
			draw_circle(p, 2.2 - u * 1.4, Color(_col.r, _col.g * 0.85, _col.b * 0.4, a * 0.7))
