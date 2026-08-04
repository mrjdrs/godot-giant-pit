extends RefCounted

const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")

signal changed

const MAX_SLOTS := 12

## Each entry: { "type": "mat"|"rune", "id": String, "count": int, "rank": int }
var slots: Array = []


func clear() -> void:
	slots.clear()
	changed.emit()


func used_count() -> int:
	return slots.size()


func is_full() -> bool:
	return slots.size() >= MAX_SLOTS


func add_material(mat_id: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	for entry in slots:
		if entry.get("type") == "mat" and entry.get("id") == mat_id:
			entry["count"] = int(entry["count"]) + count
			changed.emit()
			return true
	if is_full():
		return false
	slots.append({"type": "mat", "id": mat_id, "count": count, "rank": 1})
	changed.emit()
	return true


func add_rune_as_item(rune_id: String, rank: int = 1) -> bool:
	## 阶段 B：符文直接进装配，不占背包；此接口留给后续。
	if is_full():
		return false
	slots.append({"type": "rune", "id": rune_id, "count": 1, "rank": rank})
	changed.emit()
	return true


func snapshot_materials() -> Array:
	var out: Array = []
	for entry in slots:
		if entry.get("type") == "mat":
			out.append(entry.duplicate(true))
	return out


func describe_contents() -> PackedStringArray:
	var lines: PackedStringArray = []
	for entry in slots:
		if entry.get("type") == "mat":
			var mat_name := MaterialCatalog.display_name(str(entry.get("id")))
			lines.append("%s x%d" % [mat_name, int(entry.get("count", 1))])
		elif entry.get("type") == "rune":
			var rname := RuneCatalog.display_name(str(entry.get("id")))
			lines.append("%s（%d阶）" % [rname, int(entry.get("rank", 1))])
	return lines


func describe_slot(index: int) -> String:
	if index < 0 or index >= slots.size():
		return ""
	var entry: Dictionary = slots[index]
	if entry.get("type") == "mat":
		return "%s x%d" % [MaterialCatalog.display_name(str(entry.get("id"))), int(entry.get("count", 1))]
	return str(entry.get("id"))


func keep_only_index(index: int) -> Array:
	var kept: Array = []
	if index >= 0 and index < slots.size():
		kept.append(slots[index].duplicate(true))
	slots.clear()
	changed.emit()
	return kept
