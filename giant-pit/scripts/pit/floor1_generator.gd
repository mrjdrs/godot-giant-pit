extends RefCounted
## 第 1 层大地图生成：三区域 + BOSS 域 + 撤离/下层分置。

const RegionCatalog = preload("res://scripts/pit/region_catalog.gd")

const TILE := 32
const MAP_W := 96
const MAP_H := 64
const CHUNK := 8
const EDGE_INSET := 4


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

	## 区域矩形（tile 坐标，含通道重叠带）
	var bounds := {
		RegionCatalog.REGION_A: Rect2i(2, 10, 30, 40),
		RegionCatalog.REGION_B: Rect2i(34, 10, 28, 40),
		RegionCatalog.REGION_C: Rect2i(64, 4, 28, 26),
		RegionCatalog.REGION_BOSS: Rect2i(66, 36, 26, 22),
		RegionCatalog.REGION_SPAWN: Rect2i(4, 24, 10, 10),
	}

	for rid in [RegionCatalog.REGION_A, RegionCatalog.REGION_B, RegionCatalog.REGION_C, RegionCatalog.REGION_BOSS]:
		_fill_rect(walkable, region_of, bounds[rid], rid, rng)

	## 出生安全邻域覆盖到 A
	_fill_rect(walkable, region_of, bounds[RegionCatalog.REGION_SPAWN], RegionCatalog.REGION_SPAWN, rng)

	## 连通走廊
	_carve_corridor(walkable, region_of, Vector2i(31, 30), Vector2i(34, 30), RegionCatalog.REGION_A) ## A-B
	_carve_corridor(walkable, region_of, Vector2i(48, 10), Vector2i(48, 4), RegionCatalog.REGION_B) ## up toward C
	_carve_corridor(walkable, region_of, Vector2i(48, 4), Vector2i(64, 12), RegionCatalog.REGION_C) ## to C
	_carve_corridor(walkable, region_of, Vector2i(55, 48), Vector2i(66, 48), RegionCatalog.REGION_BOSS) ## B-Boss

	## 撤离区：地图左下，远离 BOSS
	var extract_rect := Rect2i(6, 52, 14, 8)
	_fill_rect(walkable, region_of, extract_rect, RegionCatalog.REGION_A, rng)
	_carve_corridor(walkable, region_of, Vector2i(12, 49), Vector2i(12, 52), RegionCatalog.REGION_A)

	var markers := {}
	markers["spawn"] = _world_center(bounds[RegionCatalog.REGION_SPAWN])
	markers["extract"] = _world_center(extract_rect)
	## 下层入口在 BOSS 域深处；撤离已在对面
	markers["descent"] = _tile_to_world(Vector2i(88, 52))
	markers["boss"] = _world_center(bounds[RegionCatalog.REGION_BOSS])
	markers["boss_altar"] = _tile_to_world(Vector2i(78, 46))

	for rid in [RegionCatalog.REGION_A, RegionCatalog.REGION_B, RegionCatalog.REGION_C]:
		var core := _inset_rect(bounds[rid], EDGE_INSET)
		var warp_id := "warp_%s" % rid
		markers["elite_%s" % rid] = _random_point_in(core, rng)
		markers[warp_id] = _random_point_in(core, rng)
		## 确保精英与传送不重叠
		while markers[warp_id].distance_to(markers["elite_%s" % rid]) < 80.0:
			markers[warp_id] = _random_point_in(core, rng)

		var forage_list: Array = []
		var ore_list: Array = []
		for _i in 4:
			forage_list.append(_random_point_in(core, rng))
		for _j in 3:
			ore_list.append(_random_point_in(core, rng))
		markers["forage_%s" % rid] = forage_list
		markers["ore_%s" % rid] = ore_list

		## 杂兵刷点
		var mob_pts: Array = []
		for _k in 8:
			mob_pts.append(_random_point_in(core, rng))
		markers["mobs_%s" % rid] = mob_pts

	## 救援信标：盲灯廊
	markers["distress"] = _random_point_in(_inset_rect(bounds[RegionCatalog.REGION_C], EDGE_INSET), rng)

	## 鳞岩兽额外点：沉苔沼
	var scale_pts: Array = []
	for _s in 3:
		scale_pts.append(_random_point_in(_inset_rect(bounds[RegionCatalog.REGION_A], EDGE_INSET), rng))
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
			## 边缘挖一点不规则
			var on_edge := (
				x == rect.position.x or y == rect.position.y
				or x == rect.position.x + rect.size.x - 1
				or y == rect.position.y + rect.size.y - 1
			)
			if on_edge and rng.randf() < 0.15:
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


static func _random_point_in(rect: Rect2i, rng: RandomNumberGenerator) -> Vector2:
	var tx := rng.randi_range(rect.position.x, rect.position.x + rect.size.x - 1)
	var ty := rng.randi_range(rect.position.y, rect.position.y + rect.size.y - 1)
	return _tile_to_world(Vector2i(tx, ty))


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
