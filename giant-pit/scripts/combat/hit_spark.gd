extends Node2D
## 命中反馈：刀斩弧 / 枪青白星火 / 焰咒紫橙上飘火星。


func setup(pos: Vector2, dir: float = 1.0, style: String = "blade", col: Color = Color(1.0, 0.85, 0.35, 1.0)) -> void:
	global_position = pos
	z_index = 20
	var c1 := col
	var c2 := Color(col.r, col.g * 0.55, col.b * 0.35, 1.0)
	match style:
		"gun":
			c1 = Color(0.85, 0.98, 1.0, 1.0)
			c2 = Color(1.0, 0.75, 0.35, 1.0)
		"mage":
			c1 = Color(1.0, 0.5, 0.2, 1.0)
			c2 = Color(0.85, 0.4, 1.0, 1.0)
	for i in 7:
		var p := ColorRect.new()
		p.size = Vector2(2, 2) if style != "blade" else Vector2(3, 3)
		p.color = c1 if i % 2 == 0 else c2
		p.position = Vector2(randf_range(-2, 2), randf_range(-6, 6))
		add_child(p)
		var tw := create_tween()
		var end := Vector2(dir * randf_range(18, 36), randf_range(-28, 8))
		if style == "gun":
			end = Vector2(dir * randf_range(24, 42), randf_range(-8, 8))
		elif style == "mage":
			end = Vector2(dir * randf_range(6, 16), randf_range(-36, -12))
		tw.tween_property(p, "position", p.position + end, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.2)
	if style == "blade":
		var arc := Line2D.new()
		arc.width = 3.0
		arc.default_color = Color(1.0, 0.95, 0.7, 0.9)
		arc.points = PackedVector2Array([
			Vector2(dir * -4, -12), Vector2(dir * 10, -2), Vector2(dir * 16, 10),
		])
		add_child(arc)
		var tw2 := create_tween()
		tw2.tween_property(arc, "modulate:a", 0.0, 0.16)
		tw2.tween_callback(queue_free)
	elif style == "mage":
		var ring := Line2D.new()
		ring.width = 2.0
		ring.default_color = Color(0.8, 0.45, 1.0, 0.9)
		var pts := PackedVector2Array()
		for i in 8:
			pts.append(Vector2.from_angle(TAU * float(i) / 7.0) * 9.0)
		ring.points = pts
		add_child(ring)
		var tw2 := create_tween()
		tw2.tween_property(ring, "modulate:a", 0.0, 0.18)
		tw2.tween_callback(queue_free)
	else:
		var streak := Line2D.new()
		streak.width = 1.8
		streak.default_color = Color(0.8, 0.95, 1.0, 0.95)
		streak.points = PackedVector2Array([Vector2(dir * -8, 0), Vector2(dir * 16, 0)])
		add_child(streak)
		var tw2 := create_tween()
		tw2.tween_property(streak, "modulate:a", 0.0, 0.1)
		tw2.tween_callback(queue_free)
