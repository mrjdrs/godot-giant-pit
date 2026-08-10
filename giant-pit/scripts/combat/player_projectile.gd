extends Area2D
## 玩家刃气：直线飞向鼠标方向，命中敌人 hurtbox。

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var knockback_force: float = 80.0
var poise_damage: float = 8.0
var source: Node2D = null
var lifetime: float = 0.9
var _alive: float = 0.0
var _hit_ids: Dictionary = {}


func setup(p_velocity: Vector2, p_damage: float, p_source: Node2D, p_knock: float = 80.0) -> void:
	velocity = p_velocity
	damage = p_damage
	source = p_source
	knockback_force = p_knock
	poise_damage = p_knock * 0.08
	rotation = velocity.angle()


func _ready() -> void:
	collision_layer = 8
	collision_mask = 16
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	if not has_node("Visual"):
		var vis := Polygon2D.new()
		vis.name = "Visual"
		vis.color = Color(0.95, 0.78, 0.28, 1)
		vis.polygon = PackedVector2Array([
			Vector2(-8, -3), Vector2(10, 0), Vector2(-8, 3),
		])
		add_child(vis)
	if not has_node("CollisionShape2D"):
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 8)
		cs.shape = rect
		add_child(cs)


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
	queue_free()
