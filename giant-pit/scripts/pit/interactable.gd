extends Area2D
## 可交互物基类。玩家靠近后按 E 触发。

signal interacted(by: Node)

@export var prompt_key: String = "hud.interact_pickup"
@export var once: bool = true

var _done: bool = false
var enabled: bool = true


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 2 ## player body
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("interactable")


func get_prompt() -> String:
	return Loc.t(prompt_key)


func can_interact(_by: Node) -> bool:
	return enabled and not _done


func interact(by: Node) -> void:
	if not can_interact(by):
		return
	_on_interact(by)
	interacted.emit(by)
	if once:
		_done = true
		enabled = false


func _on_interact(_by: Node) -> void:
	pass


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_nearby_interactable"):
		body.set_nearby_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("clear_nearby_interactable"):
		body.clear_nearby_interactable(self)
