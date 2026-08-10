extends Control
## 第 1 层小地图：以玩家为中心，标注撤离 / 秘境 / 传送等。

const Floor1Generator = preload("res://scripts/pit/floor1_generator.gd")
const RegionCatalog = preload("res://scripts/pit/region_catalog.gd")

const PAD := 8.0
const TITLE_H := 18.0
const LEGEND_H := 28.0
const VIEW_TILES := 48.0

var _map: Dictionary = {}
var _explored: Dictionary = {}
var _player_pos: Vector2 = Vector2.ZERO
var _region_id: String = ""
var _map_w: int = 144
var _map_h: int = 96
var _chunk: int = 8
var _poi_flags: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_apply_size()


func setup_floor1(map_data: Dictionary, explored: Dictionary) -> void:
	_map = map_data
	_explored = explored
	_map_w = maxi(int(map_data.get("map_w", 144)), 1)
	_map_h = maxi(int(map_data.get("map_h", 96)), 1)
	_chunk = maxi(int(map_data.get("chunk", 8)), 1)
	_apply_size()
	queue_redraw()


func set_poi_flags(flags: Dictionary) -> void:
	_poi_flags = flags.duplicate()
	queue_redraw()


func update_floor1(explored: Dictionary, player_pos: Vector2, region_id: String) -> void:
	_explored = explored
	_player_pos = player_pos
	_region_id = region_id
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _apply_size() -> void:
	custom_minimum_size = Vector2(256, 256)
	clip_contents = true


func _chunk_explored(world_pos: Vector2) -> bool:
	var ck := Floor1Generator.chunk_of_tile(Floor1Generator.world_to_tile(world_pos))
	return _explored.has(ck)


func _world_to_map(world_pos: Vector2, origin: Vector2, inner: Rect2, sx: float, sy: float) -> Vector2:
	var tile_px := float(maxi(int(_map.get("tile", Floor1Generator.TILE)), 1))
	return Vector2(
		inner.position.x + (world_pos.x / tile_px - origin.x) * sx,
		inner.position.y + (world_pos.y / tile_px - origin.y) * sy
	)


func _draw() -> void:
	var box := size
	if box.x < 8.0 or box.y < 8.0:
		box = custom_minimum_size
	draw_rect(Rect2(Vector2.ZERO, box), Color(0.04, 0.05, 0.07, 0.94))
	draw_rect(Rect2(Vector2.ZERO, box), Color(0.55, 0.48, 0.35, 0.9), false, 1.5)
	var title := Loc.t("hud.map_title")
	if _region_id != "":
		title = "%s · %s" % [title, RegionCatalog.display_name(_region_id)]
	draw_string(ThemeDB.fallback_font, Vector2(PAD, PAD + 12.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.9, 0.75, 1))

	var inner := Rect2(PAD, PAD + TITLE_H, box.x - PAD * 2.0, box.y - PAD * 2.0 - TITLE_H - LEGEND_H)
	if inner.size.x <= 1.0 or inner.size.y <= 1.0:
		return
	draw_rect(inner, Color(0.02, 0.02, 0.03, 0.85))

	var tile_px := float(maxi(int(_map.get("tile", Floor1Generator.TILE)), 1))
	var view := VIEW_TILES
	var px := _player_pos.x / tile_px
	var py := _player_pos.y / tile_px
	var origin := Vector2(px - view * 0.5, py - view * 0.5)
	origin.x = clampf(origin.x, 0.0, maxf(float(_map_w) - view, 0.0))
	origin.y = clampf(origin.y, 0.0, maxf(float(_map_h) - view, 0.0))
	var sx := inner.size.x / view
	var sy := inner.size.y / view
	var region_of: Dictionary = _map.get("region_of", {})
	var walkable: Dictionary = _map.get("walkable", {})

	var x0 := maxi(0, int(floor(origin.x)))
	var y0 := maxi(0, int(floor(origin.y)))
	var x1 := mini(_map_w, int(ceil(origin.x + view)))
	var y1 := mini(_map_h, int(ceil(origin.y + view)))
	for ty in range(y0, y1):
		for tx in range(x0, x1):
			var g := Vector2i(tx, ty)
			if walkable.is_empty():
				if not region_of.has(g):
					continue
			elif not walkable.has(g):
				continue
			var ck := Vector2i(int(floor(float(tx) / float(_chunk))), int(floor(float(ty) / float(_chunk))))
			if not _explored.has(ck):
				continue
			var rid := str(region_of.get(g, RegionCatalog.REGION_A))
			var col: Color = RegionCatalog.MINIMAP_COLORS.get(rid, Color(0.3, 0.3, 0.3, 1))
			var r := Rect2(
				inner.position.x + (float(tx) - origin.x) * sx,
				inner.position.y + (float(ty) - origin.y) * sy,
				sx + 0.5,
				sy + 0.5
			)
			r = r.intersection(inner)
			if r.size.x > 0.2 and r.size.y > 0.2:
				draw_rect(r, col)

	_draw_pois(origin, inner, sx, sy)

	var marker := Vector2(
		inner.position.x + (px - origin.x) * sx,
		inner.position.y + (py - origin.y) * sy
	)
	marker.x = clampf(marker.x, inner.position.x + 4.0, inner.position.x + inner.size.x - 4.0)
	marker.y = clampf(marker.y, inner.position.y + 4.0, inner.position.y + inner.size.y - 4.0)
	draw_circle(marker, 3.4, Color(1.0, 0.95, 0.7, 1.0))
	draw_arc(marker, 5.2, 0.0, TAU, 12, Color(1.0, 0.85, 0.35, 0.75), 1.2)

	var legend_y := inner.position.y + inner.size.y + 8.0
	draw_string(
		ThemeDB.fallback_font,
		Vector2(PAD, legend_y + 10.0),
		"%s %s %s %s %s %s" % [
			Loc.t("map.poi_extract"),
			Loc.t("map.poi_secret"),
			Loc.t("map.poi_warp"),
			Loc.t("map.poi_npc"),
			Loc.t("map.poi_descent"),
			Loc.t("map.poi_boss"),
		],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.82, 0.78, 0.68, 0.95)
	)


func _draw_pois(origin: Vector2, inner: Rect2, sx: float, sy: float) -> void:
	var markers: Dictionary = _map.get("markers", {})
	if markers.is_empty():
		return
	_draw_poi(markers.get("extract_a", markers.get("extract", Vector2.ZERO)), origin, inner, sx, sy, Color(0.45, 1.0, 0.55), Loc.t("map.poi_extract"), true)
	_draw_poi(markers.get("extract_b", Vector2.ZERO), origin, inner, sx, sy, Color(0.45, 1.0, 0.55), Loc.t("map.poi_extract"), true)
	_draw_poi(markers.get("extract_c", Vector2.ZERO), origin, inner, sx, sy, Color(0.45, 1.0, 0.55), Loc.t("map.poi_extract"), true)
	_draw_poi(markers.get("secret_mouth", Vector2.ZERO), origin, inner, sx, sy, Color(0.55, 0.85, 1.0), Loc.t("map.poi_secret"), true)
	for wid in RegionCatalog.ALL_WARPS:
		_draw_poi(markers.get(wid, Vector2.ZERO), origin, inner, sx, sy, Color(0.95, 0.78, 0.35), Loc.t("map.poi_warp"), true)
	_draw_poi(markers.get("descent", Vector2.ZERO), origin, inner, sx, sy, Color(0.85, 0.55, 1.0), Loc.t("map.poi_descent"), false)
	_draw_poi(markers.get("boss", Vector2.ZERO), origin, inner, sx, sy, Color(1.0, 0.35, 0.35), Loc.t("map.poi_boss"), false)
	if bool(_poi_flags.get("distress", false)):
		_draw_poi(markers.get("distress", Vector2.ZERO), origin, inner, sx, sy, Color(1.0, 0.82, 0.45), Loc.t("map.poi_npc"), true)


func _draw_poi(world_pos: Vector2, origin: Vector2, inner: Rect2, sx: float, sy: float, color: Color, label: String, always_hint: bool) -> void:
	if world_pos == Vector2.ZERO:
		return
	var explored := _chunk_explored(world_pos)
	if not explored and not always_hint:
		return
	var pt := _world_to_map(world_pos, origin, inner, sx, sy)
	var pad_inner := inner.grow(-6.0)
	if not pad_inner.has_point(pt):
		if always_hint or explored:
			_draw_edge_pip(inner, pt, color)
		return
	var col := color if explored else Color(color.r, color.g, color.b, 0.5)
	draw_circle(pt, 4.2, col)
	draw_arc(pt, 6.0, 0.0, TAU, 10, Color(col.r, col.g, col.b, 0.7), 1.1)
	draw_string(ThemeDB.fallback_font, pt + Vector2(6, 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)


func _draw_edge_pip(inner: Rect2, target: Vector2, color: Color) -> void:
	var c := inner.get_center()
	var dir := (target - c)
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()
	var edge := c + dir * (minf(inner.size.x, inner.size.y) * 0.42)
	edge = Vector2(
		clampf(edge.x, inner.position.x + 8.0, inner.position.x + inner.size.x - 8.0),
		clampf(edge.y, inner.position.y + 8.0, inner.position.y + inner.size.y - 8.0)
	)
	draw_circle(edge, 4.0, color)
	draw_circle(edge, 2.0, Color(1, 1, 1, 0.9))
