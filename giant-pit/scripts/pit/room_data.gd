extends RefCounted

const TYPE_START := 0
const TYPE_COMBAT := 1
const TYPE_RESOURCE := 2
const TYPE_ELITE := 3
const TYPE_EXTRACT := 4
const TYPE_DESCENT := 5

var id: int = 0
var room_type: int = TYPE_COMBAT
var grid: Vector2i = Vector2i.ZERO
var rect: Rect2 = Rect2()
var connections: Array = []
var explored: bool = false


func type_name_key() -> String:
	match room_type:
		TYPE_START:
			return "hud.room_start"
		TYPE_COMBAT:
			return "hud.room_combat"
		TYPE_RESOURCE:
			return "hud.room_resource"
		TYPE_ELITE:
			return "hud.room_elite"
		TYPE_EXTRACT:
			return "hud.room_extract"
		TYPE_DESCENT:
			return "hud.room_descent"
		_:
			return "hud.room_combat"


func center() -> Vector2:
	return rect.get_center()
