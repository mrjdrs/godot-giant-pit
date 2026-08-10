extends "res://scripts/pit/interactable.gd"

signal extract_requested(by: Node)


func _ready() -> void:
	super._ready()
	prompt_key = "hud.interact_extract"
	once = true
	_ensure_name_label()


func _ensure_name_label() -> void:
	if has_node("NameLabel"):
		return
	var lbl := Label.new()
	lbl.name = "NameLabel"
	lbl.text = Loc.t("hud.extract_world")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.7, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08, 0.95))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.z_index = 8
	add_child(lbl)
	var ms := lbl.get_minimum_size()
	lbl.position = Vector2(-ms.x * 0.5, -38.0)


func _on_interact(by: Node) -> void:
	extract_requested.emit(by)
