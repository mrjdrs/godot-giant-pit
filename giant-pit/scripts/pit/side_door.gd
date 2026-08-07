extends Area2D
## 段落出口门。

var dest_id: String = ""
var floor_ref: Node = null
var prompt_key: String = "hud.interact_door"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func can_interact(_player: Node) -> bool:
	return dest_id != ""


func get_prompt() -> String:
	return Loc.t(prompt_key)


func set_focus_highlight(on: bool) -> void:
	modulate = Color(1.3, 1.3, 1.0) if on else Color.WHITE


func interact(_player: Node) -> void:
	if floor_ref and floor_ref.has_method("request_travel"):
		floor_ref.request_travel(dest_id)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_nearby_interactable"):
		body.set_nearby_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("clear_nearby_interactable"):
		body.clear_nearby_interactable(self)
