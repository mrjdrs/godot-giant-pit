extends Control
## 左下角小地图：仅绘制已探索房间。

const RoomData = preload("res://scripts/pit/room_data.gd")

const CELL := 30.0
const GAP := 4.0
const PAD := 8.0
const TITLE_H := 20.0
const GRID := 3

var rooms: Array = []
var current_id: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_apply_size()


func reset() -> void:
	rooms = []
	current_id = -1
	queue_redraw()


func set_rooms(p_rooms: Array) -> void:
	rooms = p_rooms
	current_id = -1
	_apply_size()
	queue_redraw()


func set_current(room_id: int) -> void:
	if current_id == room_id:
		return
	current_id = room_id
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _apply_size() -> void:
	var w := PAD * 2.0 + CELL * float(GRID) + GAP * float(GRID - 1)
	var h := PAD * 2.0 + TITLE_H + CELL * float(GRID) + GAP * float(GRID - 1)
	custom_minimum_size = Vector2(w, h)
	## 锚定布局下直接改 size 会被覆盖；用偏移保证可视区域够画满 3×3
	if anchor_top >= 0.999 and anchor_bottom >= 0.999:
		offset_top = -h - 12.0
		offset_bottom = -12.0
		offset_left = 12.0
		offset_right = 12.0 + w


func _draw() -> void:
	var box := size
	if box.x < 8.0 or box.y < 8.0:
		box = custom_minimum_size
	draw_rect(Rect2(Vector2.ZERO, box), Color(0.04, 0.05, 0.07, 0.88))
	draw_rect(Rect2(Vector2.ZERO, box), Color(0.55, 0.48, 0.35, 0.85), false, 1.5)
	var title := Loc.t("hud.map_title")
	draw_string(ThemeDB.fallback_font, Vector2(PAD, PAD + 13.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.9, 0.75, 1))

	## 走廊（仅已探索两端）
	for room in rooms:
		if room == null or not bool(room.explored):
			continue
		for oid in room.connections:
			if int(oid) <= int(room.id):
				continue
			var other = _room_by_id(int(oid))
			if other == null or not bool(other.explored):
				continue
			draw_line(_cell_center(room.grid), _cell_center(other.grid), Color(0.45, 0.4, 0.32, 0.9), 3.0)

	for room in rooms:
		if room == null or not bool(room.explored):
			continue
		var g: Vector2i = room.grid
		if g.x < 0 or g.x >= GRID or g.y < 0 or g.y >= GRID:
			continue
		var r := _cell_rect(g)
		draw_rect(r, _type_color(int(room.room_type)))
		draw_rect(r, Color(0.15, 0.12, 0.1, 0.9), false, 1.0)
		if int(room.id) == current_id:
			draw_rect(r.grow(1.5), Color(1.0, 0.92, 0.55, 1.0), false, 2.0)
			draw_circle(r.get_center(), 4.0, Color(1.0, 0.95, 0.7, 1.0))


func _room_by_id(id: int):
	for room in rooms:
		if room != null and int(room.id) == id:
			return room
	return null


func _cell_rect(g: Vector2i) -> Rect2:
	var origin := Vector2(PAD, PAD + TITLE_H)
	var p := origin + Vector2(float(g.x) * (CELL + GAP), float(g.y) * (CELL + GAP))
	return Rect2(p, Vector2(CELL, CELL))


func _cell_center(g: Vector2i) -> Vector2:
	return _cell_rect(g).get_center()


func _type_color(room_type: int) -> Color:
	match room_type:
		RoomData.TYPE_START:
			return Color(0.35, 0.38, 0.42, 1)
		RoomData.TYPE_COMBAT:
			return Color(0.55, 0.22, 0.18, 1)
		RoomData.TYPE_RESOURCE:
			return Color(0.22, 0.48, 0.28, 1)
		RoomData.TYPE_ELITE:
			return Color(0.45, 0.28, 0.55, 1)
		RoomData.TYPE_EXTRACT:
			return Color(0.78, 0.62, 0.22, 1)
		RoomData.TYPE_DESCENT:
			return Color(0.25, 0.5, 0.65, 1)
		_:
			return Color(0.3, 0.3, 0.3, 1)
