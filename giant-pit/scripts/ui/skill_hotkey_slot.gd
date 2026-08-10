extends Panel
## 快捷栏槽：左键循环，可接收技能树拖放。

var slot_id: String = ""
var host: Control = null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if host and host.has_method("_cycle_hotkey"):
			host._cycle_hotkey(slot_id)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and str(data.get("type")) == "skill"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if host and host.has_method("_assign_hotkey"):
		host._assign_hotkey(slot_id, str(data.get("id")))
