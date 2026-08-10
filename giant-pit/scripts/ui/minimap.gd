extends Control
## 第 1 层大地图小地图：已探索 chunk + 区域色，严格裁剪在框内。

const Floor1Generator = preload("res://scripts/pit/floor1_generator.gd")
const RegionCatalog = preload("res://scripts/pit/region_catalog.gd")

const PAD := 8.0
const TITLE_H := 20.0

var _map: Dictionary = {}
var _explored: Dictionary = {}
var _player_pos: Vector2 = Vector2.ZERO
var _region_id: String = ""
var _map_w: int = 96
var _map_h: int = 64
var _chunk: int = 8


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_apply_size()


func setup_floor1(map_data: Dictionary, explored: Dictionary) -> void:
	_map = map_data
	_explored = explored
	_map_w = maxi(int(map_data.get("map_w", 96)), 1)
	_map_h = maxi(int(map_data.get("map_h", 64)), 1)
	_chunk = maxi(int(map_data.get("chunk", 8)), 1)
	_apply_size()
	queue_redraw()


func update_floor1(explored: Dictionary, player_pos: Vector2, region_id: String) -> void:
	_explored = explored
	_player_pos = player_pos
	_region_id = region_id
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _apply_size() -> void:
	custom_minimum_size = Vector2(148, 148)
	clip_contents = true


func _draw() -> void:
	var box := size
	if box.x < 8.0 or box.y < 8.0:
		box = custom_minimum_size
	draw_rect(Rect2(Vector2.ZERO, box), Color(0.04, 0.05, 0.07, 0.94))
	draw_rect(Rect2(Vector2.ZERO, box), Color(0.55, 0.48, 0.35, 0.9), false, 1.5)
	var title := Loc.t("hud.map_title")
	if _region_id != "":
		title = "%s · %s" % [title, RegionCatalog.display_name(_region_id)]
	draw_string(ThemeDB.fallback_font, Vector2(PAD, PAD + 13.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.9, 0.75, 1))

	var inner := Rect2(PAD, PAD + TITLE_H, box.x - PAD * 2.0, box.y - PAD * 2.0 - TITLE_H)
	if inner.size.x <= 1.0 or inner.size.y <= 1.0:
		return
	draw_rect(inner, Color(0.02, 0.02, 0.03, 0.85))
	var sx := inner.size.x / float(_map_w)
	var sy := inner.size.y / float(_map_h)
	var chunk_sx := maxf(sx * float(_chunk), 1.0)
	var chunk_sy := maxf(sy * float(_chunk), 1.0)

	var region_of: Dictionary = _map.get("region_of", {})
	for ck in _explored.keys():
		var cx := int(ck.x)
		var cy := int(ck.y)
		var origin := Vector2i(cx * _chunk, cy * _chunk)
		if origin.x + _chunk <= 0 or origin.y + _chunk <= 0:
			continue
		if origin.x >= _map_w or origin.y >= _map_h:
			continue
		var rid := str(region_of.get(origin, RegionCatalog.REGION_A))
		var col: Color = RegionCatalog.MINIMAP_COLORS.get(rid, Color(0.3, 0.3, 0.3, 1))
		var r := Rect2(
			inner.position.x + float(origin.x) * sx,
			inner.position.y + float(origin.y) * sy,
			chunk_sx,
			chunk_sy
		)
		r = r.intersection(inner)
		if r.size.x > 0.5 and r.size.y > 0.5:
			draw_rect(r, col)

	var pg := Floor1Generator.world_to_tile(_player_pos)
	pg.x = clampi(pg.x, 0, _map_w - 1)
	pg.y = clampi(pg.y, 0, _map_h - 1)
	var px := clampf(inner.position.x + (float(pg.x) + 0.5) * sx, inner.position.x + 2.0, inner.end.x - 2.0)
	var py := clampf(inner.position.y + (float(pg.y) + 0.5) * sy, inner.position.y + 2.0, inner.end.y - 2.0)
	draw_circle(Vector2(px, py), 3.0, Color(1.0, 0.95, 0.7, 1.0))
