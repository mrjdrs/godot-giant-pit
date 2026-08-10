extends Node2D

const AtmosphereScript = preload("res://scripts/fx/scene_atmosphere.gd")
const SkillBarScript = preload("res://scripts/ui/skill_bar.gd")

@export var floor_texture: Texture2D
@export var arena_size: Vector2i = Vector2i(12, 10)
@export var tile_size: int = 32
@export var run_smoke_test: bool = false

@onready var floor_tiles: Node2D = $Floor/FloorTiles


func _ready() -> void:
	_build_floor()
	AtmosphereScript.install(self, self, "arena")
	var hint := get_node_or_null("Hint/HintLabel")
	if hint:
		hint.text = Loc.t("hint.combat_arena")
	var player := get_node_or_null("Player")
	if player:
		player.side_view = false
		player.combat_enabled = true
		MetaProgress.grant_arena_skills()
		MetaProgress.mind_value = MetaProgress.mind_value_max()
		if player.has_method("apply_meta_brand"):
			player.apply_meta_brand("iron")
	_ensure_skill_bar(player)
	if run_smoke_test:
		_smoke_test_attack()


func _ensure_skill_bar(player: Node) -> void:
	var hud := get_node_or_null("Hint")
	if hud == null:
		return
	if hud.has_node("SkillBar"):
		return
	var bar := Control.new()
	bar.name = "SkillBar"
	bar.set_script(SkillBarScript)
	hud.add_child(bar)
	if bar.has_method("bind_player"):
		bar.bind_player(player)


func _build_floor() -> void:
	if floor_texture == null:
		floor_texture = load("res://assets/tiles/pit_floor/tile_floor_01.png")
	for child in floor_tiles.get_children():
		child.queue_free()

	var origin := Vector2(
		-arena_size.x * tile_size * 0.5 + tile_size * 0.5,
		-arena_size.y * tile_size * 0.5 + tile_size * 0.5
	)
	for y in arena_size.y:
		for x in arena_size.x:
			var sprite := Sprite2D.new()
			sprite.texture = floor_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = origin + Vector2(x * tile_size, y * tile_size)
			floor_tiles.add_child(sprite)


func _smoke_test_attack() -> void:
	await get_tree().create_timer(0.4).timeout
	var player := $Player
	if player and player.has_method("_start_light_attack"):
		player.call("_start_light_attack")
		await get_tree().create_timer(0.5).timeout
		var dummy := $DummyEnemy
		if dummy:
			print(Loc.t("smoke.hp_light", [str(dummy.get("hp"))]))
		if player.has_method("_try_cast_slot"):
			player.call("_try_cast_slot", "rmb")
		await get_tree().create_timer(1.0).timeout
		if dummy:
			print(Loc.t("smoke.hp_heavy", [str(dummy.get("hp"))]))
