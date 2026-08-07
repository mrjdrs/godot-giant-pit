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
	await get_tree().create_timer(0.4).timeout
	var player := $Player
	var dummy := $DummyEnemy
	if player == null or dummy == null:
		return
	player.global_position = Vector2(20, 80)
	dummy.global_position = Vector2(60, 88)
	## 三段连斩
	for _i in 3:
		player.set("combo_window", 0.4)
		player.call("_start_light_attack", Vector2.RIGHT)
		await get_tree().create_timer(0.55).timeout
		print("smoke combo step=", player.get("combo_step"), " hp=", dummy.get("hp"))
	print("smoke done hp=", dummy.get("hp"))
