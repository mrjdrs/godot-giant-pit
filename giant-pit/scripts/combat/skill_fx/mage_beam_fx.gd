extends Node2D
## 法术光束：线形渐变，按元素着色。


var _t: float = 0.0
var _dur: float = 0.32
var _length: float = 120.0
var _width: float = 14.0
var _col: Color = Color(1.0, 0.45, 0.18, 0.9)
var _dir: Vector2 = Vector2.RIGHT


func setup(origin: Vector2, direction: Vector2, length: float, col: Color, width: float = 14.0, dur: float = 0.32) -> void:
	global_position = origin
	_dir = direction.normalized()
	rotation = _dir.angle()
	_length = length
	_width = width
	_col = col
	_dur = dur
	z_index = 14


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := _col.a * (1.0 - u * 0.9)
	var len := _length * (0.4 + 0.6 * minf(u * 2.0, 1.0))
	var w := _width * (1.0 - u * 0.4)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -w * 0.5), Vector2(len, -w * 0.25), Vector2(len, w * 0.25), Vector2(0, w * 0.5),
	]), Color(_col.r, _col.g, _col.b, a * 0.55))
	draw_line(Vector2(0, 0), Vector2(len, 0), Color(_col.r, _col.g * 0.9, _col.b * 0.8, a), w * 0.35)
	draw_circle(Vector2(len * 0.85, 0), w * 0.3, Color(1.0, 1.0, 1.0, a * 0.7))
