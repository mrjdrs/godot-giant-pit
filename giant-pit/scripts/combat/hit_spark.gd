extends Node2D
## 命中反馈：刀斩弧 / 枪青白星火 / 五元素法术火花。


func setup(pos: Vector2, dir: float = 1.0, style: String = "blade", col: Color = Color(1.0, 0.85, 0.35, 1.0)) -> void:
	global_position = pos
	z_index = 20
	var c1 := col
	var c2 := Color(col.r, col.g * 0.55, col.b * 0.35, 1.0)
	match style:
		"gun":
			c1 = Color(0.85, 0.98, 1.0, 1.0)
			c2 = Color(1.0, 0.75, 0.35, 1.0)
		"mage", "mage_fire":
			c1 = Color(1.0, 0.5, 0.2, 1.0)
			c2 = Color(0.85, 0.4, 1.0, 1.0)
		"mage_ice":
			c1 = Color(0.75, 0.95, 1.0, 1.0)
			c2 = Color(0.45, 0.78, 1.0, 1.0)
		"mage_acid":
			c1 = Color(0.65, 1.0, 0.25, 1.0)
			c2 = Color(0.35, 0.85, 0.15, 1.0)
		"mage_dark":
			c1 = Color(0.55, 0.2, 0.85, 1.0)
			c2 = Color(0.25, 0.08, 0.45, 1.0)
		"mage_light":
			c1 = Color(1.0, 0.95, 0.65, 1.0)
			c2 = Color(1.0, 0.88, 0.35, 1.0)
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
		elif style.begins_with("mage"):
			match style:
				"mage_ice":
					end = Vector2(dir * randf_range(14, 28), randf_range(-18, 18))
				"mage_acid":
					end = Vector2(dir * randf_range(10, 22), randf_range(-14, 14))
				"mage_dark":
					end = Vector2(dir * randf_range(-8, 8), randf_range(8, 24))
				"mage_light":
					end = Vector2(dir * randf_range(4, 12), randf_range(-40, -16))
				_:
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
	elif style == "mage" or style == "mage_fire":
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
	elif style == "mage_ice":
		for i in 4:
			var shard := Line2D.new()
			shard.width = 2.0
			shard.default_color = Color(0.8, 0.95, 1.0, 0.85)
			var ang := TAU * float(i) / 4.0 + randf_range(-0.2, 0.2)
			shard.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(ang) * randf_range(10, 18)])
			add_child(shard)
			var tw2 := create_tween()
			tw2.tween_property(shard, "modulate:a", 0.0, 0.2)
		var tw3 := create_tween()
		tw3.tween_interval(0.22)
		tw3.tween_callback(queue_free)
	elif style == "mage_acid":
		for i in 5:
			var bubble := ColorRect.new()
			bubble.size = Vector2(3, 3)
			bubble.color = Color(0.5, 0.95, 0.2, 0.9)
			bubble.position = Vector2(randf_range(-8, 8), randf_range(-8, 8))
			add_child(bubble)
			var tw2 := create_tween()
			tw2.tween_property(bubble, "position", bubble.position + Vector2(randf_range(-6, 6), randf_range(-10, -2)), 0.18)
			tw2.parallel().tween_property(bubble, "modulate:a", 0.0, 0.18)
		var tw3 := create_tween()
		tw3.tween_interval(0.2)
		tw3.tween_callback(queue_free)
	elif style == "mage_dark":
		for i in 6:
			var shadow := ColorRect.new()
			shadow.size = Vector2(2, 5)
			shadow.color = Color(0.35, 0.1, 0.55, 0.85)
			shadow.position = Vector2(randf_range(-6, 6), randf_range(-4, 4))
			add_child(shadow)
			var tw2 := create_tween()
			tw2.tween_property(shadow, "position", shadow.position + Vector2(randf_range(-4, 4), randf_range(6, 16)), 0.22)
			tw2.parallel().tween_property(shadow, "modulate:a", 0.0, 0.22)
		var tw3 := create_tween()
		tw3.tween_interval(0.24)
		tw3.tween_callback(queue_free)
	elif style == "mage_light":
		var cross_h := Line2D.new()
		cross_h.width = 2.5
		cross_h.default_color = Color(1.0, 0.95, 0.6, 0.95)
		cross_h.points = PackedVector2Array([Vector2(-10, 0), Vector2(10, 0)])
		add_child(cross_h)
		var cross_v := Line2D.new()
		cross_v.width = 2.5
		cross_v.default_color = Color(1.0, 0.95, 0.6, 0.95)
		cross_v.points = PackedVector2Array([Vector2(0, -10), Vector2(0, 10)])
		add_child(cross_v)
		var tw2 := create_tween()
		tw2.tween_property(cross_h, "modulate:a", 0.0, 0.2)
		tw2.parallel().tween_property(cross_v, "modulate:a", 0.0, 0.2)
		tw2.tween_callback(queue_free)
	elif style == "gun":
		var streak := Line2D.new()
		streak.width = 1.8
		streak.default_color = Color(0.8, 0.95, 1.0, 0.95)
		streak.points = PackedVector2Array([Vector2(dir * -8, 0), Vector2(dir * 16, 0)])
		add_child(streak)
		var tw2 := create_tween()
		tw2.tween_property(streak, "modulate:a", 0.0, 0.1)
		tw2.tween_callback(queue_free)
	else:
		var streak2 := Line2D.new()
		streak2.width = 1.8
		streak2.default_color = Color(0.8, 0.95, 1.0, 0.95)
		streak2.points = PackedVector2Array([Vector2(dir * -8, 0), Vector2(dir * 16, 0)])
		add_child(streak2)
		var tw2 := create_tween()
		tw2.tween_property(streak2, "modulate:a", 0.0, 0.1)
		tw2.tween_callback(queue_free)
