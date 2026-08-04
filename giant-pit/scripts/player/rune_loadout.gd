extends RefCounted

const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")

signal changed

const BODY_SLOTS := 3
const WEAPON_SLOTS := 3

var body: Dictionary = {}
var weapon: Dictionary = {}


func clear() -> void:
	body.clear()
	weapon.clear()
	changed.emit()


func try_equip(rune_id: String) -> String:
	if not RuneCatalog.DEFS.has(rune_id):
		return "unknown"
	var is_body := RuneCatalog.is_body(rune_id)
	var bag: Dictionary = body if is_body else weapon
	var limit := BODY_SLOTS if is_body else WEAPON_SLOTS
	var max_rank := int(RuneCatalog.DEFS[rune_id].get("max_rank", 3))

	if bag.has(rune_id):
		var rank := int(bag[rune_id])
		if rank >= max_rank:
			return "full"
		bag[rune_id] = rank + 1
		changed.emit()
		return "upgraded"

	if bag.size() >= limit:
		return "full"

	bag[rune_id] = 1
	changed.emit()
	return "ok"


func get_rank(rune_id: String) -> int:
	if body.has(rune_id):
		return int(body[rune_id])
	if weapon.has(rune_id):
		return int(weapon[rune_id])
	return 0


func max_hp_bonus() -> float:
	return 20.0 * get_rank("tough")


func move_speed_mult() -> float:
	return 1.0 + 0.08 * get_rank("swift")


func attack_speed_mult() -> float:
	## 迅斩：缩短前摇/后摇
	return 1.0 + 0.08 * get_rank("slash")


func roll_cd_mult() -> float:
	return maxf(0.7, 1.0 - 0.08 * get_rank("sidestep"))


func damage_mult() -> float:
	return 1.0 + 0.12 * get_rank("edge")


func reach_mult() -> float:
	return 1.0 + 0.08 * get_rank("reach")


func has_burn() -> bool:
	return get_rank("burn") > 0


func burn_dps() -> float:
	return 4.0 * get_rank("burn")


func heavy_damage_mult() -> float:
	return 1.0 + 0.15 * get_rank("quake")


func heavy_knockback_mult() -> float:
	return 1.0 + 0.12 * get_rank("quake")


func describe() -> PackedStringArray:
	var lines: PackedStringArray = []
	for id in body.keys():
		lines.append("%s %d阶" % [RuneCatalog.display_name(id), int(body[id])])
	for id in weapon.keys():
		lines.append("%s %d阶" % [RuneCatalog.display_name(id), int(weapon[id])])
	return lines
