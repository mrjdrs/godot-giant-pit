extends Node2D
## 命中火花：短时粒子块。


func setup(pos: Vector2, dir: float = 1.0) -> void:
	global_position = pos
	z_index = 20
	for i in 6:
		var p := ColorRect.new()
		p.size = Vector2(3, 3)
		p.color = Color(1.0, 0.85, 0.35, 1.0) if i % 2 == 0 else Color(1.0, 0.45, 0.2, 1.0)
		p.position = Vector2(randf_range(-2, 2), randf_range(-6, 6))
		add_child(p)
		var tw := create_tween()
		var end := Vector2(dir * randf_range(18, 36), randf_range(-28, 8))
		tw.tween_property(p, "position", p.position + end, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.18)
	## 斩击弧线
	var arc := Line2D.new()
	arc.width = 3.0
	arc.default_color = Color(1.0, 0.95, 0.7, 0.9)
	arc.points = PackedVector2Array([
		Vector2(dir * -4, -12),
		Vector2(dir * 10, -2),
		Vector2(dir * 16, 10),
	])
	add_child(arc)
	var tw2 := create_tween()
	tw2.tween_property(arc, "modulate:a", 0.0, 0.16)
	tw2.tween_callback(queue_free)
