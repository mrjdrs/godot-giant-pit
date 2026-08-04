extends "res://scripts/pit/interactable.gd"

signal facility_used(facility_id: String, by: Node)

@export var facility_id: String = "board"


func _ready() -> void:
	super._ready()
	once = false
	prompt_key = "hud.interact_e"


func get_prompt() -> String:
	var name_key := "facility.%s" % facility_id
	return Loc.t("hud.interact_e", [Loc.t(name_key)])


func _on_interact(by: Node) -> void:
	facility_used.emit(facility_id, by)
