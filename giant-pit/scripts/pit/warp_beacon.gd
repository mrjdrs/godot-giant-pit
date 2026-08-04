extends "res://scripts/pit/interactable.gd"
## 区域传送点：击杀看守后激活；局内互传耗念力值。

signal warp_menu_requested(warp_id: String, by: Node)

@export var warp_id: String = "warp_a"

var activated: bool = false

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	once = false
	prompt_key = "hud.interact_warp_locked"
	super._ready()
	_refresh_visual()
	## 若本局已激活（例如传送出生），同步状态
	if RunSession.is_warp_active(warp_id):
		set_activated(true)


func setup(p_warp_id: String) -> void:
	warp_id = p_warp_id
	if is_node_ready():
		_refresh_visual()


func set_activated(on: bool) -> void:
	activated = on
	if on:
		RunSession.activate_warp(warp_id)
	_refresh_visual()


func _refresh_visual() -> void:
	prompt_key = "hud.interact_warp" if activated else "hud.interact_warp_locked"
	if sprite == null:
		return
	var path := "res://assets/props/warp/prop_warp_active.png" if activated else "res://assets/props/warp/prop_warp_inactive.png"
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	## 区旗
	var flag_path := "res://assets/props/warp/prop_warp_flag_%s.png" % warp_id.replace("warp_", "")
	if not has_node("Flag"):
		var flag := Sprite2D.new()
		flag.name = "Flag"
		flag.position = Vector2(14, -10)
		flag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(flag)
	var flag_n: Sprite2D = get_node("Flag")
	if ResourceLoader.exists(flag_path):
		flag_n.texture = load(flag_path)


func can_interact(by: Node) -> bool:
	if not super.can_interact(by):
		return false
	return activated


func get_prompt() -> String:
	if not activated:
		return Loc.t("hud.interact_warp_locked")
	return Loc.t("hud.interact_warp")


func _on_interact(by: Node) -> void:
	if not activated:
		if by.has_method("show_toast"):
			by.show_toast(Loc.t("warp.need_guard"))
		return
	warp_menu_requested.emit(warp_id, by)
