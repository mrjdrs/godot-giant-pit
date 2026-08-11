extends Node2D
## 冰墙：竖向冰晶条，阻挡视觉。


var _t: float = 0.0
var _dur: float = 2.0
var _length: float = 72.0
var _dir: Vector2 = Vector2.RIGHT


func setup(origin: Vector2, direction: Vector2, length: float, dur: float = 2.0) -> void:
	global_position = origin
	_dir = direction.normalized()
	rotation = _dir.angle()
	_length = length
	_dur = dur
	z_index = 8


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - clampf(_t / maxf(_dur, 0.001), 0.0, 1.0) * 0.85
	for i in 3:
		var x := -_length * 0.5 + float(i) * _length * 0.5
		var h := 28.0 + float(i % 2) * 6.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 4, h * 0.5), Vector2(x + 2, -h * 0.5), Vector2(x + 6, h * 0.4), Vector2(x, h * 0.5),
		]), Color(0.7, 0.92, 1.0, fade * 0.75))
		draw_line(Vector2(x, -h * 0.5), Vector2(x + 2, h * 0.5), Color(1.0, 1.0, 1.0, fade * 0.5), 1.0)
