extends Node2D
## 拔刀：超宽横贯闪光。


var _t: float = 0.0
var _dur: float = 0.22
var _dir: Vector2 = Vector2.RIGHT
var _len: float = 160.0
var _width: float = 18.0
var _col: Color = Color(1.0, 0.96, 0.78, 0.9)


func setup(pos: Vector2, dir: Vector2, length: float, col: Color, width: float = 18.0, dur: float = 0.22) -> void:
	global_position = pos
	_dir = dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT
	_len = length
	_col = col
	_width = width
	_dur = dur
	rotation = _dir.angle()
	z_index = 16


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := _col.a * (1.0 - u * u)
	var w := _width * (1.15 - u * 0.55)
	var pts := PackedVector2Array([
		Vector2(0.0, -w * 0.25),
		Vector2(_len, -w * 0.5),
		Vector2(_len, w * 0.5),
		Vector2(0.0, w * 0.25),
	])
	draw_colored_polygon(pts, Color(_col.r, _col.g, _col.b, a * 0.55))
	draw_line(Vector2(4, 0), Vector2(_len, 0), Color(1, 1, 1, a), 3.2, true)
	draw_line(Vector2(4, 0), Vector2(_len * 0.72, 0), Color(_col.r, _col.g, _col.b, a), 8.0, true)
