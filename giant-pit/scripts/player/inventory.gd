extends RefCounted

const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")
const ItemCatalog = preload("res://scripts/items/item_catalog.gd")

signal changed

const BASE_SLOTS := 10
const EXPAND_PER_USE := 2
const DEFAULT_MAT_WEIGHT := 1.0
const GOLD_WEIGHT_PER := 0.01

## Each entry: { "type": "mat"|"rune"|"item", "id": String, "count": int, "rank": int }
var slots: Array = []
var extra_slots: int = 0


func clear() -> void:
	slots.clear()
	extra_slots = 0
	changed.emit()


func max_slots() -> int:
	return BASE_SLOTS + extra_slots


func used_count() -> int:
	return slots.size()


func is_full() -> bool:
	return slots.size() >= max_slots()


func entry_weight(entry: Dictionary) -> float:
	var t := str(entry.get("type", "mat"))
	var id := str(entry.get("id", ""))
	var count := int(entry.get("count", 1))
	match t:
		"rune":
			return RuneCatalog.weight(id) * float(count)
		"item":
			return ItemCatalog.weight(id) * float(count)
		_:
			return DEFAULT_MAT_WEIGHT * float(count)


func items_weight() -> float:
	var total := 0.0
	for entry in slots:
		total += entry_weight(entry)
	return total


func gold_weight(gold: int = -1) -> float:
	var g := gold if gold >= 0 else MetaProgress.gold
	return float(g) * GOLD_WEIGHT_PER


func current_weight(gold: int = -1) -> float:
	return items_weight() + gold_weight(gold)


func can_add_weight(extra: float, carry_cap: float, gold: int = -1) -> bool:
	return current_weight(gold) + extra <= carry_cap + 0.001


func add_material(mat_id: String, count: int = 1, carry_cap: float = 9999.0) -> String:
	if count <= 0:
		return "ok"
	var add_w := DEFAULT_MAT_WEIGHT * float(count)
	for entry in slots:
		if entry.get("type") == "mat" and entry.get("id") == mat_id:
			if not can_add_weight(add_w, carry_cap):
				return "overweight"
			entry["count"] = int(entry["count"]) + count
			changed.emit()
			return "ok"
	if is_full():
		return "full"
	if not can_add_weight(add_w, carry_cap):
		return "overweight"
	slots.append({"type": "mat", "id": mat_id, "count": count, "rank": 1})
	changed.emit()
	return "ok"


func add_rune_as_item(rune_id: String, rank: int = 1, carry_cap: float = 9999.0) -> String:
	if is_full():
		return "full"
	var w := RuneCatalog.weight(rune_id)
	if not can_add_weight(w, carry_cap):
		return "overweight"
	slots.append({"type": "rune", "id": rune_id, "count": 1, "rank": rank})
	changed.emit()
	return "ok"


func add_item(item_id: String, count: int = 1, carry_cap: float = 9999.0) -> String:
	if count <= 0:
		return "ok"
	var add_w := ItemCatalog.weight(item_id) * float(count)
	for entry in slots:
		if entry.get("type") == "item" and entry.get("id") == item_id:
			if not can_add_weight(add_w, carry_cap):
				return "overweight"
			entry["count"] = int(entry["count"]) + count
			changed.emit()
			return "ok"
	if is_full():
		return "full"
	if not can_add_weight(add_w, carry_cap):
		return "overweight"
	slots.append({"type": "item", "id": item_id, "count": count, "rank": 1})
	changed.emit()
	return "ok"


func find_rune_index(rune_id: String) -> int:
	for i in slots.size():
		var e: Dictionary = slots[i]
		if e.get("type") == "rune" and str(e.get("id")) == rune_id:
			return i
	return -1


func remove_at(index: int, count: int = 1) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var entry: Dictionary = slots[index]
	var have := int(entry.get("count", 1))
	if count >= have:
		slots.remove_at(index)
	else:
		entry["count"] = have - count
	changed.emit()
	return true


func consume_rune(rune_id: String) -> bool:
	var idx := find_rune_index(rune_id)
	if idx < 0:
		return false
	return remove_at(idx, 1)


func use_bag_expand_at(index: int) -> String:
	if index < 0 or index >= slots.size():
		return "none"
	var entry: Dictionary = slots[index]
	if entry.get("type") != "item" or str(entry.get("id")) != "item_bag_expand":
		return "wrong"
	if not remove_at(index, 1):
		return "none"
	extra_slots += EXPAND_PER_USE
	changed.emit()
	return "ok"


func use_mind_potion_at(index: int) -> String:
	if index < 0 or index >= slots.size():
		return "none"
	var entry: Dictionary = slots[index]
	if entry.get("type") != "item" or str(entry.get("id")) != "item_mind_potion":
		return "wrong"
	if not remove_at(index, 1):
		return "none"
	MetaProgress.restore_mind_value(MetaProgress.MIND_POTION_RESTORE)
	changed.emit()
	return "ok"


func paper_note_count() -> int:
	var total := 0
	for entry in slots:
		if entry.get("type") == "item" and str(entry.get("id")) == "item_paper_note":
			total += int(entry.get("count", 1))
	return total


func snapshot_materials() -> Array:
	var out: Array = []
	for entry in slots:
		if entry.get("type") == "mat":
			out.append(entry.duplicate(true))
	return out


func describe_contents() -> PackedStringArray:
	var lines: PackedStringArray = []
	for entry in slots:
		var t := str(entry.get("type"))
		match t:
			"mat":
				lines.append("%s x%d" % [MaterialCatalog.display_name(str(entry.get("id"))), int(entry.get("count", 1))])
			"rune":
				lines.append("%s" % RuneCatalog.display_name(str(entry.get("id"))))
			"item":
				lines.append("%s x%d" % [ItemCatalog.display_name(str(entry.get("id"))), int(entry.get("count", 1))])
	return lines


func describe_slot(index: int) -> String:
	if index < 0 or index >= slots.size():
		return ""
	var entry: Dictionary = slots[index]
	match str(entry.get("type")):
		"mat":
			return "%s x%d" % [MaterialCatalog.display_name(str(entry.get("id"))), int(entry.get("count", 1))]
		"rune":
			return RuneCatalog.display_name(str(entry.get("id")))
		"item":
			return "%s x%d" % [ItemCatalog.display_name(str(entry.get("id"))), int(entry.get("count", 1))]
	return str(entry.get("id"))


func keep_only_index(index: int) -> Array:
	var kept: Array = []
	if index >= 0 and index < slots.size():
		kept.append(slots[index].duplicate(true))
	slots.clear()
	changed.emit()
	return kept
