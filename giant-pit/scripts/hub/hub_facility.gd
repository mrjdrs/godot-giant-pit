extends "res://scripts/pit/interactable.gd"

signal facility_used(facility_id: String, by: Node)

@export var facility_id: String = "board"


func _ready() -> void:
	super._ready()
	once = false
	match facility_id:
		"board":
			prompt_key = "hud.interact_board"
		"alchemy":
			prompt_key = "hud.interact_alchemy"
		"quiet":
			prompt_key = "hud.interact_quiet"
		"pit":
			prompt_key = "hud.interact_pit"
		"stash":
			prompt_key = "hud.interact_stash"


func _on_interact(by: Node) -> void:
	facility_used.emit(facility_id, by)
