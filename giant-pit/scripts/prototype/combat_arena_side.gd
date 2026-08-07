extends Node2D
## 阶段 A：横版刀手感原型。

const AtmosphereScript = preload("res://scripts/fx/scene_atmosphere.gd")

const TILE_SIZE := 32.0
const GROUND_Y := 120.0
const ARENA_WIDTH := 640.0

@export var run_smoke_test: bool = false

@onready var hint: Label = $Hint/HintLabel
@onready var terrain: Node2D = $Terrain

var _atmosphere: Node2D


func _ready() -> void:
	if hint:
		hint.text = Loc.t("hint.combat_arena_side")
	var player := $Player
	if player and player.has_method("apply_meta_brand"):
		player.apply_meta_brand("iron")
	_atmosphere = AtmosphereScript.install(self, self, "arena")
	_build_arena()
	if run_smoke_test:
		_smoke()


func _build_arena() -> void:
	for c in terrain.get_children():
		c.queue_free()
	var ground_tex: Texture2D = load("res://assets/tiles/side/moss/ground.png")
	var ground_b_tex: Texture2D = load("res://assets/tiles/side/moss/ground_b.png")
	var platform_tex: Texture2D = load("res://assets/tiles/side/moss/platform.png")
	var wall_tex: Texture2D = load("res://assets/tiles/side/moss/wall.png")
	_add_tiled_strip(Vector2(0, GROUND_Y + 16), Vector2(ARENA_WIDTH, TILE_SIZE), ground_tex, ground_b_tex, true)
	_add_tiled_strip(Vector2(80, 40), Vector2(128, 16), platform_tex, null, true)
	_add_tiled_wall(Vector2(-320, 0), Vector2(24, 320), wall_tex)
	_add_tiled_wall(Vector2(320, 0), Vector2(24, 320), wall_tex)


func _add_tiled_strip(pos: Vector2, size: Vector2, tex_a: Texture2D, tex_b: Texture2D, with_collision: bool) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	if with_collision:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
	var holder := Node2D.new()
	body.add_child(holder)
	var cols := int(ceil(size.x / TILE_SIZE))
	var rows := maxi(1, int(ceil(size.y / TILE_SIZE)))
	var origin := Vector2(-size.x * 0.5, -size.y * 0.5)
	for row in rows:
		for col in cols:
			var spr := Sprite2D.new()
			var pick: Texture2D = tex_a
			if tex_b != null and (col + row) % 3 == 0:
				pick = tex_b
			spr.texture = pick
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.centered = false
			spr.position = origin + Vector2(col * TILE_SIZE, row * TILE_SIZE)
			holder.add_child(spr)
	terrain.add_child(body)


func _add_tiled_wall(pos: Vector2, size: Vector2, tex: Texture2D) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var holder := Node2D.new()
	body.add_child(holder)
	var cols := maxi(1, int(ceil(size.x / TILE_SIZE)))
	var rows := int(ceil(size.y / TILE_SIZE))
	var origin := Vector2(-size.x * 0.5, -size.y * 0.5)
	for row in rows:
		for col in cols:
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.centered = false
			spr.position = origin + Vector2(col * TILE_SIZE, row * TILE_SIZE)
			holder.add_child(spr)
	terrain.add_child(body)


func _smoke() -> void:
	await get_tree().create_timer(0.4).timeout
	var player := $Player
	var dummy := $DummyEnemy
	if player == null or dummy == null:
		return
	player.global_position = Vector2(20, 80)
	dummy.global_position = Vector2(60, 88)
	for _i in 3:
		player.set("combo_window", 0.4)
		player.call("_start_light_attack", Vector2.RIGHT)
		await get_tree().create_timer(0.55).timeout
		print("smoke combo step=", player.get("combo_step"), " hp=", dummy.get("hp"))
	print("smoke done hp=", dummy.get("hp"))
