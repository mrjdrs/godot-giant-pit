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
			return "max_rank"
		bag[rune_id] = rank + 1
		changed.emit()
		return "upgraded"

	if bag.size() >= limit:
		return "full"

	bag[rune_id] = 1
	changed.emit()
	return "ok"


## 用 new_id 替换 bag 中的 old_id（同槽位类型）
func replace_rune(old_id: String, new_id: String) -> String:
	if not RuneCatalog.DEFS.has(new_id):
		return "unknown"
	var is_body := RuneCatalog.is_body(new_id)
	var bag: Dictionary = body if is_body else weapon
	if not bag.has(old_id):
		return "missing"
	if RuneCatalog.is_body(old_id) != is_body:
		return "mismatch"
	bag.erase(old_id)
	if bag.has(new_id):
		var max_rank := int(RuneCatalog.DEFS[new_id].get("max_rank", 3))
		bag[new_id] = mini(int(bag[new_id]) + 1, max_rank)
	else:
		bag[new_id] = 1
	changed.emit()
	return "ok"


func ids_in_same_group(rune_id: String) -> Array:
	var is_body := RuneCatalog.is_body(rune_id)
	var bag: Dictionary = body if is_body else weapon
	return bag.keys()


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
		lines.append(_line(id, int(body[id])))
	for id in weapon.keys():
		lines.append(_line(id, int(weapon[id])))
	return lines


func _line(rune_id: String, rank: int) -> String:
	var effect_key := "rune.%s.effect" % rune_id
	var effect := Loc.t(effect_key) if Loc.has_key(effect_key) else ""
	return Loc.t("hud.rune_line", [RuneCatalog.display_name(rune_id), rank, effect])
