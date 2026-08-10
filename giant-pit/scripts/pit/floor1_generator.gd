extends RefCounted
## 第 1 层大地图生成：三区域 + BOSS 域 + 撤离/下层分置。

const RegionCatalog = preload("res://scripts/pit/region_catalog.gd")

const TILE := 32
const MAP_W := 144
const MAP_H := 96
const CHUNK := 8
const EDGE_INSET := 5
const SECRET_A_MOUTH := Vector2i(18, 22)


## 返回 Dictionary:
## walkable: Dictionary Vector2i -> true
## region_of: Dictionary Vector2i -> String
## markers: Dictionary
## region_bounds: Dictionary region_id -> Rect2i (tile space)
static func generate(p_seed: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if p_seed == 0:
		rng.randomize()
	else:
		rng.seed = p_seed

	var walkable: Dictionary = {}
	var region_of: Dictionary = {}

	var bounds := {
		RegionCatalog.REGION_A: Rect2i(3, 14, 46, 58),
		RegionCatalog.REGION_B: Rect2i(52, 14, 42, 58),
		RegionCatalog.REGION_C: Rect2i(98, 6, 40, 38),
		RegionCatalog.REGION_BOSS: Rect2i(100, 54, 38, 34),
		RegionCatalog.REGION_SPAWN: Rect2i(6, 36, 14, 14),
	}

	for rid in [RegionCatalog.REGION_A, RegionCatalog.REGION_B, RegionCatalog.REGION_C, RegionCatalog.REGION_BOSS]:
		_fill_rect(walkable, region_of, bounds[rid], rid, rng)

	_fill_rect(walkable, region_of, bounds[RegionCatalog.REGION_SPAWN], RegionCatalog.REGION_SPAWN, rng)

	_carve_corridor(walkable, region_of, Vector2i(48, 44), Vector2i(52, 44), RegionCatalog.REGION_A)
	_carve_corridor(walkable, region_of, Vector2i(72, 14), Vector2i(72, 6), RegionCatalog.REGION_B)
	_carve_corridor(walkable, region_of, Vector2i(72, 6), Vector2i(98, 18), RegionCatalog.REGION_C)
	_carve_corridor(walkable, region_of, Vector2i(82, 72), Vector2i(100, 72), RegionCatalog.REGION_BOSS)

	## 每区一个撤离厅，传送点紧挨撤离点。
	var extract_rects := {
		RegionCatalog.REGION_A: Rect2i(8, 64, 18, 12),
		RegionCatalog.REGION_B: Rect2i(70, 62, 16, 10),
		RegionCatalog.REGION_C: Rect2i(120, 32, 16, 10),
	}
	_fill_rect(walkable, region_of, extract_rects[RegionCatalog.REGION_A], RegionCatalog.REGION_A, rng)
	_carve_corridor(walkable, region_of, Vector2i(16, 58), Vector2i(16, 64), RegionCatalog.REGION_A)
	_carve_corridor(walkable, region_of, Vector2i(13, 50), Vector2i(16, 58), RegionCatalog.REGION_A)
	_fill_rect(walkable, region_of, extract_rects[RegionCatalog.REGION_B], RegionCatalog.REGION_B, rng)
	_carve_corridor(walkable, region_of, Vector2i(78, 58), Vector2i(78, 62), RegionCatalog.REGION_B)
	_fill_rect(walkable, region_of, extract_rects[RegionCatalog.REGION_C], RegionCatalog.REGION_C, rng)
	_carve_corridor(walkable, region_of, Vector2i(118, 28), Vector2i(120, 36), RegionCatalog.REGION_C)

	var keepouts: Array = extract_rects.values()
	var markers := {}
	markers["spawn"] = _world_center(bounds[RegionCatalog.REGION_SPAWN])
	markers["extract_a"] = _world_center(extract_rects[RegionCatalog.REGION_A])
	markers["extract_b"] = _world_center(extract_rects[RegionCatalog.REGION_B])
	markers["extract_c"] = _world_center(extract_rects[RegionCatalog.REGION_C])
	markers["extract"] = markers["extract_a"]
	## 撤离点旁传送 + 区内随机野外传送。
	markers["warp_a"] = markers["extract_a"] + Vector2(float(TILE * 2), 0.0)
	markers["warp_b"] = markers["extract_b"] + Vector2(float(TILE * 2), 0.0)
	markers["warp_c"] = markers["extract_c"] + Vector2(float(TILE * 2), 0.0)
	markers["descent"] = _tile_to_world(Vector2i(132, 80))
	markers["boss"] = _world_center(bounds[RegionCatalog.REGION_BOSS])
	markers["boss_altar"] = _tile_to_world(Vector2i(118, 70))
	markers["secret_mouth"] = _tile_to_world(SECRET_A_MOUTH)

	for rid in [RegionCatalog.REGION_A, RegionCatalog.REGION_B, RegionCatalog.REGION_C]:
		var core := _inset_rect(bounds[rid], EDGE_INSET)
		var avoid: bool = rid == RegionCatalog.REGION_A
		var elite_key := "elite_%s" % rid
		var extract_warp: Vector2 = markers["warp_%s" % rid]
		markers[elite_key] = _random_point_in(core, rng, avoid, keepouts)
		var elite_tries := 0
		while markers[elite_key].distance_to(extract_warp) < 96.0 and elite_tries < 16:
			markers[elite_key] = _random_point_in(core, rng, avoid, keepouts)
			elite_tries += 1
		var field_id := "warp_%s2" % rid
		markers[field_id] = _random_point_in(core, rng, avoid, keepouts)
		var field_tries := 0
		while field_tries < 24 and (
			markers[field_id].distance_to(extract_warp) < 176.0
			or markers[field_id].distance_to(markers[elite_key]) < 96.0
		):
			markers[field_id] = _random_point_in(core, rng, avoid, keepouts)
			field_tries += 1

		var forage_list: Array = []
		var ore_list: Array = []
		for _i in 6:
			forage_list.append(_random_point_in(core, rng, avoid, keepouts))
		for _j in 4:
			ore_list.append(_random_point_in(core, rng, avoid, keepouts))
		markers["forage_%s" % rid] = forage_list
		markers["ore_%s" % rid] = ore_list

		var mob_pts: Array = []
		for _k in 12:
			mob_pts.append(_random_point_in(core, rng, avoid, keepouts))
		markers["mobs_%s" % rid] = mob_pts

	markers["distress"] = _random_point_in(_inset_rect(bounds[RegionCatalog.REGION_C], EDGE_INSET), rng, false, keepouts)

	var scale_pts: Array = []
	for _s in 3:
		scale_pts.append(_random_point_in(_inset_rect(bounds[RegionCatalog.REGION_A], EDGE_INSET), rng, true, keepouts))
	markers["scale_quest"] = scale_pts

	return {
		"walkable": walkable,
		"region_of": region_of,
		"markers": markers,
		"region_bounds": bounds,
		"map_w": MAP_W,
		"map_h": MAP_H,
		"tile": TILE,
		"chunk": CHUNK,
	}


static func _fill_rect(walkable: Dictionary, region_of: Dictionary, rect: Rect2i, rid: String, rng: RandomNumberGenerator) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x < 0 or y < 0 or x >= MAP_W or y >= MAP_H:
				continue
			var on_edge := (
				x == rect.position.x or y == rect.position.y
				or x == rect.position.x + rect.size.x - 1
				or y == rect.position.y + rect.size.y - 1
			)
			if on_edge and rng.randf() < 0.12:
				continue
			var g := Vector2i(x, y)
			walkable[g] = true
			if not region_of.has(g) or rid == RegionCatalog.REGION_SPAWN or rid == RegionCatalog.REGION_BOSS:
				region_of[g] = rid
			elif rid != RegionCatalog.REGION_SPAWN and str(region_of[g]) != RegionCatalog.REGION_BOSS:
				region_of[g] = rid


static func _carve_corridor(walkable: Dictionary, region_of: Dictionary, a: Vector2i, b: Vector2i, rid: String) -> void:
	var cur := a
	walkable[cur] = true
	if not region_of.has(cur):
		region_of[cur] = rid
	while cur != b:
		if cur.x != b.x:
			cur.x += 1 if b.x > cur.x else -1
		elif cur.y != b.y:
			cur.y += 1 if b.y > cur.y else -1
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				var g := cur + Vector2i(ox, oy)
				if g.x < 0 or g.y < 0 or g.x >= MAP_W or g.y >= MAP_H:
					continue
				walkable[g] = true
				if not region_of.has(g):
					region_of[g] = rid


static func _inset_rect(rect: Rect2i, inset: int) -> Rect2i:
	return Rect2i(
		rect.position.x + inset,
		rect.position.y + inset,
		maxi(rect.size.x - inset * 2, 2),
		maxi(rect.size.y - inset * 2, 2)
	)


static func _is_secret_mouth_zone(g: Vector2i) -> bool:
	return absi(g.x - SECRET_A_MOUTH.x) <= 2 and absi(g.y - SECRET_A_MOUTH.y) <= 2


static func _random_point_in(rect: Rect2i, rng: RandomNumberGenerator, avoid_secret: bool = false, keepouts: Array = []) -> Vector2:
	for _i in 32:
		var tx := rng.randi_range(rect.position.x, rect.position.x + rect.size.x - 1)
		var ty := rng.randi_range(rect.position.y, rect.position.y + rect.size.y - 1)
		var g := Vector2i(tx, ty)
		if avoid_secret and _is_secret_mouth_zone(g):
			continue
		var blocked := false
		for k in keepouts:
			var kr: Rect2i = k
			if kr.has_point(g):
				blocked = true
				break
		if blocked:
			continue
		return _tile_to_world(g)
	return _world_center(rect)


static func _world_center(rect: Rect2i) -> Vector2:
	@warning_ignore("integer_division")
	var c := Vector2i(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
	return _tile_to_world(c)


static func _tile_to_world(g: Vector2i) -> Vector2:
	return Vector2((float(g.x) + 0.5) * TILE, (float(g.y) + 0.5) * TILE)


static func world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / float(TILE))), int(floor(pos.y / float(TILE))))


static func chunk_of_tile(g: Vector2i) -> Vector2i:
	return Vector2i(int(floor(float(g.x) / float(CHUNK))), int(floor(float(g.y) / float(CHUNK))))
