extends Node2D
## 阶段 A：横版刀手感原型。

@export var run_smoke_test: bool = false

@onready var hint: Label = $Hint/HintLabel


func _ready() -> void:
	if hint:
		hint.text = Loc.t("hint.combat_arena_side")
	var player := $Player
	if player and player.has_method("apply_meta_brand"):
		player.apply_meta_brand("iron")
	if run_smoke_test:
		_smoke()


func _smoke() -> void:
	await get_tree().create_timer(0.5).timeout
	var player := $Player
	var dummy := $DummyEnemy
	if player == null or dummy == null:
		return
	player.global_position = Vector2(20, 80)
	dummy.global_position = Vector2(60, 88)
	player.call("_start_light_attack", Vector2.RIGHT)
	await get_tree().create_timer(0.45).timeout
	print("smoke light hp=", dummy.get("hp"))
	player.call("_start_heavy_attack", Vector2.RIGHT)
	await get_tree().create_timer(0.9).timeout
	print("smoke heavy hp=", dummy.get("hp"))
	player.velocity.y = -320.0
	await get_tree().create_timer(0.12).timeout
	player.call("_start_light_attack", Vector2.RIGHT)
	await get_tree().create_timer(0.5).timeout
	print("smoke done hp=", dummy.get("hp"), " player_y=", player.global_position.y)
