extends Node2D
## 共享视差、生态调色与轻暗角。

const VignetteShader = preload("res://shaders/vignette.gdshader")

const BIOME_COLORS := {
	"moss": Color(0.88, 0.96, 0.90, 1.0),
	"copper": Color(0.98, 0.90, 0.82, 1.0),
	"echo": Color(0.82, 0.86, 1.0, 1.0),
	"hub": Color(1.0, 0.96, 0.88, 1.0),
	"arena": Color(0.88, 0.96, 0.90, 1.0),
}

const SCROLL_FAR := Vector2(0.12, 0.0)
const SCROLL_MID := Vector2(0.35, 0.0)
const BG_SCALE := 4.0

var _world: Node2D
var _overlay_root: Node
var _parallax: ParallaxBackground
var _modulate: CanvasModulate
var _vignette_layer: CanvasLayer
var _current_biome: String = ""
var _use_parallax: bool = true


static func install(world: Node2D, overlay_root: Node, biome: String = "moss", vignette_strength: float = 0.22, use_parallax: bool = true) -> Node2D:
	var script_res: Script = load("res://scripts/fx/scene_atmosphere.gd")
	var atm: Node2D = Node2D.new()
	atm.set_script(script_res)
	atm.name = "Atmosphere"
	world.add_child(atm)
	atm.call("_setup", world, overlay_root, biome, vignette_strength, use_parallax)
	return atm


func _setup(world: Node2D, overlay_root: Node, biome: String, vignette_strength: float, use_parallax: bool = true) -> void:
	_world = world
	_overlay_root = overlay_root
	_use_parallax = use_parallax
	z_index = -20

	_modulate = CanvasModulate.new()
	_modulate.name = "BiomeModulate"
	world.add_child(_modulate)
	world.move_child(_modulate, 0)

	if _use_parallax:
		_parallax = ParallaxBackground.new()
		_parallax.name = "ParallaxBackground"
		_parallax.scroll_ignore_camera_zoom = true
		world.add_child(_parallax)
		world.move_child(_parallax, 1)
	else:
		_parallax = null

	_vignette_layer = CanvasLayer.new()
	_vignette_layer.name = "VignetteLayer"
	_vignette_layer.layer = 5
	overlay_root.add_child(_vignette_layer)
	var vig := ColorRect.new()
	vig.name = "Vignette"
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VignetteShader
	mat.set_shader_parameter("intensity", vignette_strength)
	mat.set_shader_parameter("softness", 0.45)
	vig.material = mat
	_vignette_layer.add_child(vig)

	set_biome(biome)


func set_biome(biome: String) -> void:
	var changed := biome != _current_biome
	_current_biome = biome
	if _modulate:
		_modulate.color = BIOME_COLORS.get(biome, Color.WHITE)
	if _use_parallax and changed:
		_rebuild_parallax()


func add_glow(pos: Vector2, color: Color = Color(1.0, 0.92, 0.72, 1.0), energy: float = 0.35, radius: float = 120.0) -> PointLight2D:
	var light := PointLight2D.new()
	light.position = pos
	light.color = color
	light.energy = energy
	light.texture_scale = radius / 64.0
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	add_child(light)
	return light


func _rebuild_parallax() -> void:
	if _parallax == null or not _use_parallax:
		return
	for c in _parallax.get_children():
		c.queue_free()
	var far_tex := _load_bg_tex("bg_far")
	var mid_tex := _load_bg_tex("bg_mid")
	if far_tex == null and mid_tex == null:
		far_tex = load("res://assets/tiles/side/moss/bg_far.png")
		mid_tex = load("res://assets/tiles/side/moss/bg_mid.png")
	_add_parallax_layer("Far", far_tex, SCROLL_FAR, -30)
	_add_parallax_layer("Mid", mid_tex, SCROLL_MID, -20)


func _load_bg_tex(suffix: String) -> Texture2D:
	var path := "res://assets/tiles/side/%s/%s.png" % [_current_biome, suffix]
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _add_parallax_layer(layer_name: String, tex: Texture2D, scroll: Vector2, z: int) -> void:
	if tex == null:
		return
	var layer := ParallaxLayer.new()
	layer.name = layer_name
	layer.motion_scale = scroll
	layer.z_index = z
	_parallax.add_child(layer)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(BG_SCALE, BG_SCALE)
	spr.centered = false
	spr.position = Vector2(-320, -200)
	layer.add_child(spr)
	var spr2 := Sprite2D.new()
	spr2.texture = tex
	spr2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr2.scale = Vector2(BG_SCALE, BG_SCALE)
	spr2.centered = false
	spr2.position = Vector2(-320 + tex.get_width() * BG_SCALE, -200)
	layer.add_child(spr2)


func cleanup() -> void:
	if _modulate and is_instance_valid(_modulate):
		_modulate.queue_free()
	if _parallax and is_instance_valid(_parallax):
		_parallax.queue_free()
	if _vignette_layer and is_instance_valid(_vignette_layer):
		_vignette_layer.queue_free()
	queue_free()
