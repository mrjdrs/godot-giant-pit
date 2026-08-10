extends "res://scripts/pit/interactable.gd"
## 秘境出口：返回巨坑大地图。

signal exit_requested(by: Node)


func _ready() -> void:
	once = false
	prompt_key = "secret.exit_prompt"
	super._ready()


func get_prompt() -> String:
	if not enabled:
		return ""
	return Loc.t("secret.exit_prompt")


func _on_interact(by: Node) -> void:
	exit_requested.emit(by)
