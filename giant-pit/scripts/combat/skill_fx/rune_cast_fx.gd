extends Node2D
## 焰咒起手：紫色几何符文环（Forspoken 式「先魔力几何，再转火焰」）。


var _t: float = 0.0
var _dur: float = 0.3
var _col: Color = Color(0.75, 0.45, 1.0, 0.95)
var _r: float = 22.0


func setup(pos: Vector2, col: Color = Color(0.75, 0.45, 1.0, 0.95), radius: float = 22.0, dur: float = 0.3) -> void:
	global_position = pos
	## 强制偏紫，避免和枪口琥珀混淆
	_col = Color(maxf(col.r * 0.55, 0.55), maxf(col.g * 0.45, 0.35), maxf(col.b, 0.9), col.a)
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
	var a := _col.a * (1.0 - u * 0.75)
	var r := _r * (0.65 + 0.5 * u)
	var rot := u * 2.8
	draw_arc(Vector2.ZERO, r, rot, rot + TAU, 48, Color(_col.r, _col.g, _col.b, a), 2.8, true)
	draw_arc(Vector2.ZERO, r * 0.68, -rot * 1.2, -rot * 1.2 + TAU, 36, Color(1.0, 0.55, 0.25, a * 0.55), 1.8, true)
	## 六角符文
	for i in 6:
		var ang := rot + TAU * float(i) / 6.0
		var p := Vector2.from_angle(ang) * r
		draw_colored_polygon(PackedVector2Array([
			p + Vector2.from_angle(ang) * 4.0,
			p + Vector2.from_angle(ang + 2.094) * 3.0,
			p + Vector2.from_angle(ang - 2.094) * 3.0,
		]), Color(0.95, 0.75, 1.0, a))
	draw_circle(Vector2.ZERO, 4.0 * (1.0 - u * 0.4), Color(1.0, 0.9, 0.55, a))
