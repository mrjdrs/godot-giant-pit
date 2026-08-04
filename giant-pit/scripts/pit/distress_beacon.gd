extends "res://scripts/pit/interactable.gd"


func _ready() -> void:
	super._ready()
	prompt_key = "hud.interact_distress"
	once = true


func _on_interact(by: Node) -> void:
	RunSession.rescue_done = true
	if by.has_method("show_toast"):
		by.show_toast(Loc.t("quest.rescue.name") + "：已启动")
