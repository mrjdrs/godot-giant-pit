extends "res://scripts/pit/interactable.gd"

signal extract_requested(by: Node)


func _ready() -> void:
	super._ready()
	prompt_key = "hud.interact_extract"
	once = true


func _on_interact(by: Node) -> void:
	extract_requested.emit(by)
