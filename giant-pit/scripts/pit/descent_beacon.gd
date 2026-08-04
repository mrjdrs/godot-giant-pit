extends "res://scripts/pit/interactable.gd"
## 下层入口（MVP 灰态接口）：需特殊念力，交互仅提示不换层。

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	super._ready()
	prompt_key = "hud.interact_descent"
	once = false
	if sprite:
		sprite.texture = load("res://assets/props/descent/prop_descent_locked.png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func get_prompt() -> String:
	if RunSession.special_mind:
		return Loc.t("hud.interact_descent_ready")
	return Loc.t("hud.interact_descent_locked")


func _on_interact(by: Node) -> void:
	if not RunSession.special_mind:
		if by.has_method("show_toast"):
			by.show_toast(Loc.t("descent.need_mind"))
		return
	if by.has_method("show_toast"):
		by.show_toast(Loc.t("descent.locked_mvp"))
