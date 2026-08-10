extends Panel
## 技能树节点：左键选中，已学主动技可拖到快捷栏。

var skill_id: String = ""
var host: Control = null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if host and host.has_method("_select_skill"):
			host._select_skill(skill_id)


func _get_drag_data(_at_position: Vector2):
	if host == null or not host.has_method("_begin_skill_drag"):
		return null
	var data = host._begin_skill_drag(skill_id)
	if data == null:
		return null
	var preview := TextureRect.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(40, 40)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var icon: TextureRect = get_node_or_null("Icon")
	if icon:
		preview.texture = icon.texture
	set_drag_preview(preview)
	return data
