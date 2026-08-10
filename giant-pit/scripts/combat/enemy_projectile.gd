extends Area2D
## 敌人弹丸：直线或抛物线，命中玩家后销毁。

@export var speed: float = 220.0
@export var fall_gravity: float = 0.0
@export var lifetime: float = 3.0
@export var damage: float = 7.0

var velocity: Vector2 = Vector2.ZERO
var _alive: float = 0.0
var _hit: bool = false


func setup(p_velocity: Vector2, p_damage: float, p_gravity: float = 0.0, p_lifetime: float = 3.0) -> void:
	velocity = p_velocity
	damage = p_damage
	fall_gravity = p_gravity
	lifetime = p_lifetime
	_alive = 0.0
	rotation = velocity.angle()


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _hit:
		return
	_alive += delta
	if _alive >= lifetime:
		queue_free()
		return
	velocity.y += fall_gravity * delta
	position += velocity * delta


func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		_hit = true
		body.take_damage(damage, global_position)
		queue_free()
