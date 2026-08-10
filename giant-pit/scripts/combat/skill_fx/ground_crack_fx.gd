extends Node2D
## 坑冠碎：落点裂地。


var _t: float = 0.0
var _dur: float = 0.55
var _radius: float = 70.0
var _col: Color = Color(0.92, 0.62, 0.22, 0.9)
var _rays: PackedVector2Array = PackedVector2Array()


func setup(pos: Vector2, radius: float, col: Color, dur: float = 0.55) -> void:
	global_position = pos
	_radius = radius
	_col = col
	_dur = dur
	z_index = 6
	_rays.clear()
	for i in 7:
		var ang := TAU * float(i) / 7.0 + randf_range(-0.18, 0.18)
		var len := _radius * randf_range(0.55, 1.05)
		_rays.append(Vector2.from_angle(ang) * len)


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := _col.a * (1.0 - u)
	var grow := 0.45 + 0.55 * minf(u * 2.4, 1.0)
	for p in _rays:
		draw_line(Vector2.ZERO, p * grow, Color(_col.r, _col.g, _col.b, a), 2.6, true)
		draw_line(p * grow * 0.55, p * grow, Color(_col.r * 0.5, _col.g * 0.35, 0.12, a * 0.8), 4.0, true)
	draw_arc(Vector2.ZERO, _radius * grow * 0.42, 0.0, TAU, 24, Color(_col.r, _col.g, _col.b, a * 0.5), 2.0, true)
