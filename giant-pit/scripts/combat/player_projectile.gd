extends Area2D
## 玩家刃气：月牙弹，可穿透。

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


func setup(p_velocity: Vector2, p_damage: float, p_source: Node2D, p_knock: float = 80.0, p_pierce: int = 1, p_col: Color = Color(1.0, 0.92, 0.62, 1.0)) -> void:
	velocity = p_velocity
	damage = p_damage
	source = p_source
	knockback_force = p_knock
	poise_damage = p_knock * 0.08
	pierce_left = maxi(p_pierce, 1)
	_col = p_col
	rotation = velocity.angle()
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
		rect.size = Vector2(22, 12)
		cs.shape = rect
		add_child(cs)


func _apply_visual() -> void:
	var vis: Polygon2D = get_node_or_null("Visual")
	if vis == null:
		vis = Polygon2D.new()
		vis.name = "Visual"
		add_child(vis)
	vis.color = _col
	vis.polygon = PackedVector2Array([
		Vector2(-12, -9),
		Vector2(16, 0),
		Vector2(-12, 9),
		Vector2(-3, 0),
	])
	var glow: Polygon2D = get_node_or_null("Glow")
	if glow == null:
		glow = Polygon2D.new()
		glow.name = "Glow"
		add_child(glow)
		move_child(glow, 0)
	glow.color = Color(_col.r, _col.g, _col.b, 0.28)
	glow.polygon = PackedVector2Array([
		Vector2(-14, -12),
		Vector2(20, 0),
		Vector2(-14, 12),
		Vector2(-4, 0),
	])


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= lifetime:
		queue_free()
		return
	position += velocity * delta


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
