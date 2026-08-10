extends "res://scripts/pit/interactable.gd"
## 沉苔沼秘境洞口：进入独立秘境地图。

signal enter_requested(by: Node)


func _ready() -> void:
	once = false
	prompt_key = "secret.mouth_prompt"
	super._ready()


func get_prompt() -> String:
	if not enabled:
		return ""
	return Loc.t("secret.mouth_prompt")


func can_interact(by: Node) -> bool:
	return enabled and super.can_interact(by)


func _on_interact(by: Node) -> void:
	enter_requested.emit(by)
