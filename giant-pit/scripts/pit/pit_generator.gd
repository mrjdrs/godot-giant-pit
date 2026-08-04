extends RefCounted

const RoomDataScript = preload("res://scripts/pit/room_data.gd")

const TILE := 32
const ROOM_TILES := Vector2i(11, 9)
const ROOM_GAP := Vector2i(3, 3)


static func generate(p_seed: int = 0, floor_index: int = 1) -> Array:
	var rng := RandomNumberGenerator.new()
	if p_seed == 0:
		rng.randomize()
	else:
		rng.seed = p_seed + floor_index * 9973

	var candidates: Array = []
	for y in 3:
		for x in 3:
			candidates.append(Vector2i(x, y))
	candidates.shuffle()

	var selected: Array = [Vector2i(1, 1)]
	for c in candidates:
		if c == Vector2i(1, 1):
			continue
		selected.append(c)
		if selected.size() >= 6:
			break

	var rooms: Array = []
	var index_of: Dictionary = {}
	for i in selected.size():
		var g: Vector2i = selected[i]
		var room = RoomDataScript.new()
		room.id = i
		room.grid = g
		room.rect = _grid_to_rect(g)
		rooms.append(room)
		index_of[g] = i

	var dirs: Array = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for room in rooms:
		for d in dirs:
			var ng: Vector2i = room.grid + d
			if index_of.has(ng):
				var other_id: int = int(index_of[ng])
				if not other_id in room.connections:
					room.connections.append(other_id)

	var order: Array = rooms.duplicate()
	order.shuffle()
	var start = order[0]
	start.room_type = RoomDataScript.TYPE_START
	start.explored = true

	## 撤离点：深层选更远的房间
	var extract = null
	for r in order:
		if r == start:
			continue
		if extract == null or _manhattan(r.grid, start.grid) > _manhattan(extract.grid, start.grid):
			extract = r
	extract.room_type = RoomDataScript.TYPE_EXTRACT

	var descent = null
	if floor_index < 4:
		for r in order:
			if r == start or r == extract:
				continue
			if descent == null or _manhattan(r.grid, start.grid) >= _manhattan(descent.grid, start.grid):
				## 下潜与撤离分房；尽量另选一间
				if r != extract:
					descent = r
		if descent != null:
			descent.room_type = RoomDataScript.TYPE_DESCENT

	var elite_set := false
	for r in order:
		if r == start or r == extract or r == descent:
			continue
		if not elite_set:
			r.room_type = RoomDataScript.TYPE_ELITE
			elite_set = true
		elif rng.randf() < 0.45:
			r.room_type = RoomDataScript.TYPE_RESOURCE
		else:
			r.room_type = RoomDataScript.TYPE_COMBAT

	return rooms


static func _grid_to_rect(g: Vector2i) -> Rect2:
	var pitch := Vector2(
		(ROOM_TILES.x + ROOM_GAP.x) * TILE,
		(ROOM_TILES.y + ROOM_GAP.y) * TILE
	)
	var size := Vector2(ROOM_TILES.x * TILE, ROOM_TILES.y * TILE)
	var pos := Vector2(g.x * pitch.x, g.y * pitch.y)
	return Rect2(pos, size)


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
