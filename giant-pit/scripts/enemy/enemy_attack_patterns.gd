extends RefCounted

const ProjectileScene = preload("res://scenes/combat/enemy_projectile.tscn")


static func spawn_projectile(
	parent: Node,
	global_pos: Vector2,
	velocity: Vector2,
	damage: float,
	tex_path: String = "res://assets/enemies/side/proj_spore.png",
	gravity: float = 0.0,
	lifetime: float = 3.0,
) -> Area2D:
	var proj: Area2D = ProjectileScene.instantiate()
	parent.get_tree().current_scene.add_child(proj)
	proj.global_position = global_pos
	if ResourceLoader.exists(tex_path):
		var spr: Sprite2D = proj.get_node_or_null("Sprite")
		if spr:
			spr.texture = load(tex_path)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if proj.has_method("setup"):
		proj.setup(velocity, damage, gravity, lifetime)
	return proj


static func spawn_arc_shot(
	parent: Node,
	from: Vector2,
	target: Vector2,
	damage: float,
	speed: float = 240.0,
) -> Area2D:
	var dir := (target - from)
	var dist := maxf(dir.length(), 1.0)
	dir /= dist
	var vel := dir * speed
	vel.y -= clampf(dist * 0.35, 80.0, 220.0)
	return spawn_projectile(parent, from, vel, damage, "res://assets/enemies/side/proj_spore.png", 520.0)


static func spawn_shockwave(
	parent: Node,
	center: Vector2,
	dir: float,
	damage: float,
	width: float = 120.0,
) -> void:
	var area := Area2D.new()
	area.global_position = center + Vector2(dir * 24.0, 0)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 28)
	cs.shape = shape
	area.add_child(cs)
	var spr := Sprite2D.new()
	if ResourceLoader.exists("res://assets/enemies/side/proj_shock.png"):
		spr.texture = load("res://assets/enemies/side/proj_shock.png")
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2(width / 16.0, 1.6)
		spr.modulate = Color(1, 1, 1, 0.85)
	area.add_child(spr)
	parent.get_tree().current_scene.add_child(area)
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, area.global_position)
	)
	var tw := area.create_tween()
	tw.tween_property(spr, "modulate:a", 0.0, 0.35)
	tw.tween_callback(area.queue_free)


static func spawn_barrage(
	parent: Node,
	from: Vector2,
	target: Vector2,
	damage: float,
	count: int = 3,
	spread: float = 40.0,
) -> void:
	for i in count:
		var off := (float(i) - float(count - 1) * 0.5) * spread
		spawn_arc_shot(parent, from + Vector2(off, 0), target + Vector2(off * 0.5, 0), damage * 0.85, 210.0)
