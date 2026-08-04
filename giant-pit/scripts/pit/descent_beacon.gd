extends "res://scripts/pit/interactable.gd"

signal descent_requested(by: Node)


func _ready() -> void:
	super._ready()
	prompt_key = "hud.interact_descent"
	once = true


func _on_interact(by: Node) -> void:
	descent_requested.emit(by)
