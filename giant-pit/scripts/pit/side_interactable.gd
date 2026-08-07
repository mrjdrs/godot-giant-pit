extends Area2D
## 横版可交互点：撤离 / 传送 / 采集 / 捷径 / 下层 / 委托标记。

const ST = preload("res://scripts/pit/segment_types.gd")

@export var interact_type: String = ST.NODE_RESOURCE
@export var prompt_key: String = "hud.interact_generic"
@export var warp_id: String = ""
@export var shortcut_id: String = ""
@export var mat_id: String = "glow_moss"

var _focused: bool = false
var _used: bool = false
var floor_ref: Node = null

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_visual()


func _apply_visual() -> void:
	var path := "res://assets/props/side/gather.png"
	match interact_type:
		ST.NODE_EXTRACT:
			path = "res://assets/props/side/extract.png"
			prompt_key = "hud.interact_extract"
		ST.NODE_WARP:
			path = "res://assets/props/side/warp.png"
			prompt_key = "hud.interact_warp"
		ST.NODE_SHORTCUT:
			path = "res://assets/props/side/shortcut.png"
			prompt_key = "hud.interact_shortcut"
		ST.NODE_DESCENT:
			path = "res://assets/props/side/descent.png"
			prompt_key = "hud.interact_descent"
		ST.NODE_QUEST:
			prompt_key = "hud.interact_rescue"
		_:
			prompt_key = "hud.interact_gather"
	if ResourceLoader.exists(path):
		sprite.texture = load(path)


func can_interact(_player: Node) -> bool:
	if _used and interact_type in [ST.NODE_RESOURCE, ST.NODE_SHORTCUT, ST.NODE_QUEST]:
		return false
	return true


func get_prompt() -> String:
	if interact_type == ST.NODE_EXTRACT:
		return Loc.t("hud.interact_extract")
	if interact_type == ST.NODE_WARP:
		if warp_id != "" and RunSession.is_warp_active(warp_id):
			return Loc.t("hud.interact_warp")
		return Loc.t("hud.interact_warp_locked")
	if interact_type == ST.NODE_DESCENT:
		if RunSession.special_mind:
			return Loc.t("hud.interact_descent_ready")
		return Loc.t("hud.interact_descent_locked")
	return Loc.t(prompt_key)


func set_focus_highlight(on: bool) -> void:
	_focused = on
	modulate = Color(1.3, 1.3, 1.0) if on else Color.WHITE


func interact(player: Node) -> void:
	if not can_interact(player):
		return
	match interact_type:
		ST.NODE_RESOURCE:
			if player.has_method("try_add_material"):
				player.try_add_material(mat_id, 1)
			_used = true
			visible = false
		ST.NODE_EXTRACT:
			if floor_ref and floor_ref.has_method("request_extract"):
				floor_ref.request_extract()
		ST.NODE_WARP:
			if floor_ref and floor_ref.has_method("request_warp_menu"):
				floor_ref.request_warp_menu(warp_id)
		ST.NODE_SHORTCUT:
			if shortcut_id != "":
				MetaProgress.unlock_shortcut(shortcut_id)
				if player.has_method("show_toast"):
					player.show_toast(Loc.t("toast.shortcut_armed"))
			_used = true
		ST.NODE_DESCENT:
			if player.has_method("show_toast"):
				if RunSession.special_mind:
					player.show_toast(Loc.t("toast.descent_locked_mvp"))
				else:
					player.show_toast(Loc.t("toast.need_special_mind"))
		ST.NODE_QUEST:
			RunSession.rescue_done = true
			_used = true
			if player.has_method("show_toast"):
				player.show_toast(Loc.t("toast.rescue_done"))
		_:
			pass


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_nearby_interactable"):
		body.set_nearby_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("clear_nearby_interactable"):
		body.clear_nearby_interactable(self)
