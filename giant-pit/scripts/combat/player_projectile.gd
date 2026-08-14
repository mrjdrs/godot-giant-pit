extends Area2D
## 弹道视觉语言：
## - crescent：冷兵器刃气月牙
## - tracer：火铳细曳光（短亮、直线、青白芯）
## - flame：焰咒火球（大体积、脉动、余烬拖尾、略摆）
## - shard：冰棱 / acid_blob：酸滴 / shadow_bolt：暗影 / light_beam：圣光

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var knockback_force: float = 80.0
var poise_damage: float = 8.0
var source: Node2D = null
var lifetime: float = 0.9
var pierce_left: int = 1
var _alive: float = 0.0
var _hit_ids: Dictionary = {}
var _col: Color = Color(1.0, 0.92, 0.62, 1.0)
var _shape: String = "crescent"
var _trail: Line2D = null
var _ember_cd: float = 0.0
var _arc_gravity: float = 0.0
var _arc_vel: Vector2 = Vector2.ZERO


func setup(p_velocity: Vector2, p_damage: float, p_source: Node2D, p_knock: float = 80.0, p_pierce: int = 1, p_col: Color = Color(1.0, 0.92, 0.62, 1.0), p_shape: String = "crescent") -> void:
	velocity = p_velocity
	damage = p_damage
	source = p_source
	knockback_force = p_knock
	poise_damage = p_knock * 0.08
	pierce_left = maxi(p_pierce, 1)
	_col = p_col
	_shape = p_shape
	rotation = velocity.angle()
	match _shape:
		"tracer", "light_beam", "arrow":
			lifetime = 0.7 if _shape == "arrow" else (0.55 if _shape == "tracer" else 0.45)
		"flame":
			lifetime = 0.95
		"shard":
			lifetime = 1.05
		"acid_blob", "vine":
			lifetime = 1.15
			_arc_gravity = 420.0 if _shape == "vine" else 520.0
			_arc_vel = p_velocity
		"shadow_bolt":
			lifetime = 0.85
		"orb":
			lifetime = 0.85
		_:
			lifetime = 0.9
	_apply_visual()


func _ready() -> void:
	collision_layer = 8
	collision_mask = 16
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	_apply_visual()
	if not has_node("CollisionShape2D"):
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		match _shape:
			"tracer", "light_beam", "arrow":
				rect.size = Vector2(24 if _shape == "arrow" else (22 if _shape == "tracer" else 28), 5 if _shape == "arrow" else (4 if _shape == "tracer" else 6))
			"flame", "orb", "acid_blob":
				rect.size = Vector2(16, 16)
			"shard", "shadow_bolt":
				rect.size = Vector2(18, 10)
			_:
				rect.size = Vector2(22, 12)
		cs.shape = rect
		add_child(cs)
	if _shape in ["tracer", "arrow"]:
		_trail = Line2D.new()
		_trail.z_index = -1
		_trail.width = 2.2 if _shape == "arrow" else 2.0
		_trail.default_color = Color(0.82, 0.62, 0.32, 0.6) if _shape == "arrow" else Color(0.55, 0.9, 0.95, 0.65)
		_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(_trail)
		_trail.points = PackedVector2Array([
			Vector2(8, 0), Vector2(-6, 0), Vector2(-16, 0), Vector2(-28, 0), Vector2(-40, 0),
		])
	elif _shape in ["flame", "shard", "shadow_bolt", "light_beam", "acid_blob", "vine"]:
		_trail = Line2D.new()
		_trail.z_index = -1
		_trail.width = 7.0 if _shape == "flame" else 4.0
		_trail.default_color = Color(_col.r, _col.g, _col.b, 0.42)
		_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(_trail)
	elif _shape == "orb":
		_trail = Line2D.new()
		_trail.z_index = -1
		_trail.width = 5.0
		_trail.default_color = Color(_col.r, _col.g, _col.b, 0.42)
		_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(_trail)


func _apply_visual() -> void:
	var vis: Polygon2D = get_node_or_null("Visual")
	if vis == null:
		vis = Polygon2D.new()
		vis.name = "Visual"
		add_child(vis)
	var glow: Polygon2D = get_node_or_null("Glow")
	if glow == null:
		glow = Polygon2D.new()
		glow.name = "Glow"
		add_child(glow)
		move_child(glow, 0)
	var core: Polygon2D = get_node_or_null("Core")
	if core == null:
		core = Polygon2D.new()
		core.name = "Core"
		add_child(core)
	match _shape:
		"arrow":
			vis.color = Color(0.72, 0.48, 0.22, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-10, -1.4), Vector2(8, -1.0), Vector2(14, 0), Vector2(8, 1.0), Vector2(-10, 1.4),
			])
			glow.color = Color(0.9, 0.72, 0.38, 0.32)
			glow.polygon = PackedVector2Array([
				Vector2(-14, -3.2), Vector2(10, -2.2), Vector2(16, 0), Vector2(10, 2.2), Vector2(-14, 3.2),
			])
			core.visible = true
			core.color = Color(0.92, 0.88, 0.7, 1.0)
			core.polygon = PackedVector2Array([
				Vector2(6, -2.2), Vector2(14, 0), Vector2(6, 2.2), Vector2(8, 0),
			])
		"vine":
			vis.color = Color(0.38, 0.78, 0.28, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-8, -3), Vector2(2, -6), Vector2(10, -1), Vector2(8, 4), Vector2(-4, 4), Vector2(-9, 0),
			])
			glow.color = Color(0.55, 0.95, 0.4, 0.35)
			glow.polygon = PackedVector2Array([
				Vector2(-11, -5), Vector2(3, -9), Vector2(13, -2), Vector2(10, 6), Vector2(-6, 6), Vector2(-12, 0),
			])
			core.visible = false
		"tracer":
			## 细长曳光：青白芯 + 琥珀壳
			vis.color = Color(1.0, 0.78, 0.35, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-8, -1.6), Vector2(10, -1.0), Vector2(14, 0), Vector2(10, 1.0), Vector2(-8, 1.6),
			])
			glow.color = Color(0.45, 0.85, 0.95, 0.35)
			glow.polygon = PackedVector2Array([
				Vector2(-18, -3.5), Vector2(12, -2), Vector2(18, 0), Vector2(12, 2), Vector2(-18, 3.5),
			])
			core.visible = true
			core.color = Color(0.9, 1.0, 1.0, 1.0)
			core.polygon = PackedVector2Array([
				Vector2(-2, -0.6), Vector2(11, -0.5), Vector2(13, 0), Vector2(11, 0.5), Vector2(-2, 0.6),
			])
		"flame":
			## 胖火球 + 紫边光晕
			vis.color = Color(1.0, 0.42, 0.16, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-7, -6), Vector2(0, -11), Vector2(8, -7), Vector2(12, 0),
				Vector2(8, 7), Vector2(0, 11), Vector2(-7, 6), Vector2(-3, 0),
			])
			glow.color = Color(0.7, 0.35, 1.0, 0.4)
			glow.polygon = PackedVector2Array([
				Vector2(-11, -11), Vector2(2, -15), Vector2(16, 0), Vector2(2, 15), Vector2(-11, 11),
			])
			core.visible = true
			core.color = Color(1.0, 0.92, 0.45, 0.95)
			core.polygon = PackedVector2Array([
				Vector2(-2, -3), Vector2(4, -4), Vector2(6, 0), Vector2(4, 4), Vector2(-2, 3), Vector2(0, 0),
			])
		"orb":
			vis.color = _col
			vis.polygon = PackedVector2Array([
				Vector2(-6, -6), Vector2(6, -6), Vector2(8, 0), Vector2(6, 6), Vector2(-6, 6), Vector2(-8, 0),
			])
			glow.color = Color(_col.r, _col.g, _col.b, 0.35)
			glow.polygon = PackedVector2Array([
				Vector2(-9, -9), Vector2(9, -9), Vector2(12, 0), Vector2(9, 9), Vector2(-9, 9), Vector2(-12, 0),
			])
			core.visible = true
			core.color = Color(1, 1, 1, 0.85)
			core.polygon = PackedVector2Array([
				Vector2(-2, -2), Vector2(3, -2), Vector2(3, 2), Vector2(-2, 2),
			])
		"shard":
			vis.color = Color(0.65, 0.88, 1.0, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-10, 0), Vector2(4, -7), Vector2(12, 0), Vector2(4, 7),
			])
			glow.color = Color(0.75, 0.95, 1.0, 0.35)
			glow.polygon = PackedVector2Array([
				Vector2(-12, 0), Vector2(2, -9), Vector2(14, 0), Vector2(2, 9),
			])
			core.visible = true
			core.color = Color(1.0, 1.0, 1.0, 0.9)
			core.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(6, 0), Vector2(-2, 2)])
		"acid_blob":
			vis.color = Color(0.5, 0.92, 0.18, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-6, -5), Vector2(2, -8), Vector2(8, -2), Vector2(6, 6), Vector2(-4, 5), Vector2(-8, 0),
			])
			glow.color = Color(0.65, 1.0, 0.25, 0.35)
			glow.polygon = PackedVector2Array([
				Vector2(-9, -7), Vector2(3, -11), Vector2(11, -3), Vector2(8, 8), Vector2(-6, 7), Vector2(-11, 0),
			])
			core.visible = false
		"shadow_bolt":
			vis.color = Color(0.4, 0.12, 0.65, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-12, -2), Vector2(14, -1.5), Vector2(16, 0), Vector2(14, 1.5), Vector2(-12, 2),
			])
			glow.color = Color(0.55, 0.18, 0.85, 0.35)
			glow.polygon = PackedVector2Array([
				Vector2(-16, -4), Vector2(16, -3), Vector2(18, 0), Vector2(16, 3), Vector2(-16, 4),
			])
			core.visible = true
			core.color = Color(0.25, 0.08, 0.4, 0.95)
			core.polygon = PackedVector2Array([Vector2(-4, -1), Vector2(10, 0), Vector2(-4, 1)])
		"light_beam":
			vis.color = Color(1.0, 0.94, 0.55, 1.0)
			vis.polygon = PackedVector2Array([
				Vector2(-6, -2), Vector2(18, -1.2), Vector2(20, 0), Vector2(18, 1.2), Vector2(-6, 2),
			])
			glow.color = Color(1.0, 0.98, 0.75, 0.4)
			glow.polygon = PackedVector2Array([
				Vector2(-8, -4), Vector2(22, -2.5), Vector2(24, 0), Vector2(22, 2.5), Vector2(-8, 4),
			])
			core.visible = true
			core.color = Color(1.0, 1.0, 0.95, 1.0)
			core.polygon = PackedVector2Array([Vector2(0, -0.8), Vector2(16, 0), Vector2(0, 0.8)])
		_:
			vis.color = _col
			vis.polygon = PackedVector2Array([
				Vector2(-12, -9), Vector2(16, 0), Vector2(-12, 9), Vector2(-3, 0),
			])
			glow.color = Color(_col.r, _col.g, _col.b, 0.28)
			glow.polygon = PackedVector2Array([
				Vector2(-14, -12), Vector2(20, 0), Vector2(-14, 12), Vector2(-4, 0),
			])
			core.visible = false


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= lifetime:
		if _shape == "acid_blob":
			set_meta("splash", true)
		queue_free()
		return
	if _shape == "flame":
		var side := Vector2(-velocity.normalized().y, velocity.normalized().x)
		position += velocity * delta + side * sin(_alive * 14.0) * 28.0 * delta
		rotation = velocity.angle() + sin(_alive * 10.0) * 0.25
		scale = Vector2.ONE * (1.0 + 0.14 * sin(_alive * 18.0))
		if _trail:
			var pts := PackedVector2Array()
			for i in 6:
				pts.append(Vector2(-float(i) * 7.0, sin(_alive * 12.0 + float(i)) * 3.5))
			_trail.points = pts
			_trail.default_color = Color(1.0, 0.4, 0.15, 0.5 * (1.0 - _alive / lifetime))
		_ember_cd -= delta
		if _ember_cd <= 0.0:
			_ember_cd = 0.045
			_spawn_ember()
	elif _shape in ["acid_blob", "vine"]:
		_arc_vel.y += _arc_gravity * delta
		position += _arc_vel * delta
		rotation = _arc_vel.angle()
		if _trail:
			_trail.default_color = Color(_col.r, _col.g, _col.b, 0.45 * (1.0 - _alive / lifetime))
	elif _shape == "shard":
		position += velocity * delta
		rotation = velocity.angle()
		scale = Vector2.ONE * (1.0 + 0.06 * sin(_alive * 20.0))
		if _trail:
			_trail.default_color = Color(_col.r, _col.g, _col.b, 0.4 * (1.0 - _alive / lifetime))
	elif _shape == "shadow_bolt":
		position += velocity * delta
		rotation = velocity.angle()
		if _trail:
			var pts2 := PackedVector2Array()
			for i in 5:
				pts2.append(Vector2(-float(i) * 6.0, sin(_alive * 10.0 + float(i)) * 2.0))
			_trail.points = pts2
			_trail.default_color = Color(0.45, 0.12, 0.75, 0.5 * (1.0 - _alive / lifetime))
	elif _shape == "light_beam":
		position += velocity * delta
		rotation = velocity.angle()
		if _trail:
			_trail.default_color = Color(1.0, 0.95, 0.6, 0.55 * (1.0 - _alive / lifetime))
	elif _shape == "orb":
		position += velocity * delta
		rotation = velocity.angle()
		scale = Vector2.ONE * (1.0 + 0.08 * sin(_alive * 16.0))
		if _trail:
			_trail.default_color = Color(_col.r, _col.g, _col.b, 0.45 * (1.0 - _alive / lifetime))
	else:
		position += velocity * delta
		if _shape in ["tracer", "arrow"]:
			rotation = velocity.angle()
			if _trail:
				_trail.default_color = Color(0.55, 0.9, 0.95, 0.55 * (1.0 - _alive / lifetime))


func _spawn_ember() -> void:
	var p := ColorRect.new()
	p.size = Vector2(2, 2)
	p.color = Color(1.0, 0.55, 0.2, 0.9) if randf() > 0.4 else Color(0.85, 0.35, 1.0, 0.85)
	p.position = Vector2(randf_range(-4, 0), randf_range(-5, 5))
	add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "position", p.position + Vector2(randf_range(-10, -2), randf_range(-14, -4)), 0.22)
	tw.parallel().tween_property(p, "modulate:a", 0.0, 0.22)
	tw.tween_callback(p.queue_free)


func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("take_hit"):
		return
	var id := area.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	area.call_deferred("take_hit", self)
	pierce_left -= 1
	if pierce_left <= 0:
		queue_free()
