extends RefCounted

const RoomDataScript = preload("res://scripts/pit/room_data.gd")

const TILE := 32
const ROOM_TILES := Vector2i(11, 9)
const ROOM_GAP := Vector2i(3, 3)
const DIRS: Array = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]


static func generate(p_seed: int = 0, floor_index: int = 1) -> Array:
	var rng := RandomNumberGenerator.new()
	if p_seed == 0:
		rng.randomize()
	else:
		rng.seed = p_seed + floor_index * 9973

	## 从中心生长，保证正交连通
	var selected: Array = _pick_connected_rooms(rng, 6)

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

	for room in rooms:
		for d in DIRS:
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

	## 仅在从 start 可达的房间中选撤离 / 下潜
	var reachable: Array = _reachable_from(start, rooms)
	var extract = null
	for r in reachable:
		if r == start:
			continue
		if extract == null or _manhattan(r.grid, start.grid) > _manhattan(extract.grid, start.grid):
			extract = r
	if extract == null:
		## 兜底：任选非入口
		for r in rooms:
			if r != start:
				extract = r
				break
	extract.room_type = RoomDataScript.TYPE_EXTRACT

	var descent = null
	if floor_index < 4:
		for r in reachable:
			if r == start or r == extract:
				continue
			if descent == null or _manhattan(r.grid, start.grid) >= _manhattan(descent.grid, start.grid):
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

	## 兜底：任意层（含第 4 层）必须有且仅有一个撤离房
	_ensure_extract(rooms, start)
	return rooms


static func _ensure_extract(rooms: Array, start) -> void:
	var extract = null
	for r in rooms:
		if r.room_type == RoomDataScript.TYPE_EXTRACT:
			extract = r
			break
	if extract != null:
		return
	var best = null
	for r in rooms:
		if r == start:
			continue
		if best == null or _manhattan(r.grid, start.grid) > _manhattan(best.grid, start.grid):
			best = r
	if best == null and rooms.size() > 0:
		best = rooms[0]
	if best != null:
		best.room_type = RoomDataScript.TYPE_EXTRACT


## 在 3×3 上从中心生长 count 个正交连通房间
static func _pick_connected_rooms(rng: RandomNumberGenerator, count: int) -> Array:
	var selected: Dictionary = {} ## Vector2i -> true
	var center := Vector2i(1, 1)
	selected[center] = true
	while selected.size() < count:
		var frontier: Array = []
		for g in selected.keys():
			for d in DIRS:
				var ng: Vector2i = g + d
				if ng.x < 0 or ng.x > 2 or ng.y < 0 or ng.y > 2:
					continue
				if selected.has(ng):
					continue
				frontier.append(ng)
		if frontier.is_empty():
			break
		var pick: Vector2i = frontier[rng.randi_range(0, frontier.size() - 1)]
		selected[pick] = true
	var out: Array = []
	for g in selected.keys():
		out.append(g)
	return out


static func _reachable_from(start, rooms: Array) -> Array:
	var by_id: Dictionary = {}
	for r in rooms:
		by_id[r.id] = r
	var seen: Dictionary = {}
	var queue: Array = [start]
	seen[start.id] = true
	var out: Array = []
	while not queue.is_empty():
		var cur = queue.pop_front()
		out.append(cur)
		for oid in cur.connections:
			if seen.has(oid):
				continue
			seen[oid] = true
			if by_id.has(oid):
				queue.append(by_id[oid])
	return out


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
