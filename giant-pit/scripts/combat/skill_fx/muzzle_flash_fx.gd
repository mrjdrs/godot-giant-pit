extends Node2D
## 火铳枪口：极短高对比闪光（射击手感），青白芯 + 琥珀锥。


var _t: float = 0.0
var _dur: float = 0.08
var _col: Color = Color(1.0, 0.82, 0.35, 0.95)
var _len: float = 26.0


func setup(pos: Vector2, dir: Vector2, col: Color = Color(1.0, 0.82, 0.35, 0.95), length: float = 26.0, dur: float = 0.08) -> void:
	global_position = pos
	_col = col
	_len = length
	_dur = dur
	rotation = dir.angle() if dir.length_squared() > 0.001 else 0.0
	z_index = 18


func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var u := clampf(_t / maxf(_dur, 0.001), 0.0, 1.0)
	var a := (1.0 - u * u)
	var tip := _len * (1.1 - u * 0.5)
	var half := 9.0 * (1.0 - u * 0.55)
	## 外琥珀锥
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -2.5), Vector2(tip, -half), Vector2(tip * 1.08, 0.0), Vector2(tip, half), Vector2(0.0, 2.5),
	]), Color(_col.r, _col.g, _col.b, a * 0.7))
	## 青白芯线（枪械可读性）
	draw_line(Vector2(0, 0), Vector2(tip * 0.9, 0), Color(0.85, 0.98, 1.0, a), 2.8, true)
	draw_circle(Vector2(2, 0), 3.5 * (1.0 - u), Color(1.0, 1.0, 1.0, a))
	for i in 3:
		var ang := -0.4 + 0.4 * float(i)
		draw_circle(Vector2.from_angle(ang) * tip * 0.55, 1.4 - u, Color(1.0, 0.85, 0.4, a * 0.8))
