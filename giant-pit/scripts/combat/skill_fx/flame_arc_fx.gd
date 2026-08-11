extends Node2D
## 焰咒炎鞭/炎瀑：扇形火焰扫过，无刀身残影。


var _t: float = 0.0
var _dur: float = 0.2
var _from: float = -50.0
var _to: float = 55.0
var _r: float = 56.0
var _col: Color = Color(1.0, 0.42, 0.16, 0.85)


func setup(pos: Vector2, facing_angle: float, from_deg: float, to_deg: float, radius: float, col: Color, dur: float = 0.2) -> void:
	global_position = pos
	rotation = facing_angle
	_from = from_deg
	_to = to_deg
	_r = radius
	_col = col
	_dur = dur
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
	var ang := deg_to_rad(lerpf(_from, _to, u))
	var tip := Vector2.from_angle(ang) * _r
	var mid := Vector2.from_angle(deg_to_rad(lerpf(_from, _to, u * 0.7))) * (_r * 0.62)
	draw_colored_polygon(PackedVector2Array([
		Vector2.ZERO,
		Vector2.from_angle(deg_to_rad(_from)) * (_r * 0.35),
		tip,
		Vector2.from_angle(deg_to_rad(_to)) * (_r * 0.35),
	]), Color(_col.r, _col.g, _col.b, a * 0.4))
	draw_line(Vector2.ZERO, tip, Color(1.0, 0.78, 0.35, a), 4.0, true)
	draw_line(Vector2.ZERO, mid, Color(_col.r, _col.g, _col.b, a * 0.85), 7.0, true)
	for i in 5:
		var t := float(i) / 4.0
		var p := Vector2.from_angle(deg_to_rad(lerpf(_from, _to, t))) * (_r * (0.45 + 0.4 * u))
		draw_circle(p, 2.4 - u, Color(1.0, 0.55, 0.18, a * 0.8))
