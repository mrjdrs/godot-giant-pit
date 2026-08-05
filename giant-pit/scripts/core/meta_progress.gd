extends Node
## 局外进度唯一真源。user://meta_save.json

const Equipment = preload("res://scripts/meta/equipment.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const QuestDefs = preload("res://scripts/meta/quest_defs.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")

const SAVE_PATH := "user://meta_save.json"

signal changed

var mind_level: int = 1
var mind_shards_banked: int = 0 ## 静室待吸收也可直接扣 stash
var mind_value: int = 0 ## 可消耗念力值（传送 / 学符文）
var gold: int = 0
var stash: Dictionary = {} ## id -> count（材料 / 未学符文 / 特殊道具）
var equipment: Dictionary = {}
var learned_runes: Dictionary = {} ## rune_id -> true
var active_quest_id: String = ""
var intel: PackedStringArray = []
var unlocked_warps: Array = [] ## ["warp_a", ...]

const WARP_COST_ENTER := 15
const WARP_COST_TRAVEL := 10
const SHARD_TO_VALUE := 5
const CORE_TO_VALUE := 25
const MIND_VALUE_BASE := 40
const MIND_VALUE_PER_LEVEL := 10


func mind_value_max() -> int:
	return MIND_VALUE_BASE + mind_level * MIND_VALUE_PER_LEVEL


func has_learned(rune_id: String) -> bool:
	return bool(learned_runes.get(rune_id, false))


func mark_learned(rune_id: String) -> void:
	learned_runes[rune_id] = true
	changed.emit()
	save_game()


func _ready() -> void:
	_ensure_equipment()
	load_game()


func _ensure_equipment() -> void:
	if not equipment.has(Equipment.SLOT_CHEST):
		equipment[Equipment.SLOT_CHEST] = Equipment.make_default_slot(Equipment.SLOT_CHEST)
	if not equipment.has(Equipment.SLOT_AMULET):
		equipment[Equipment.SLOT_AMULET] = Equipment.make_default_slot(Equipment.SLOT_AMULET)


func stash_count(mat_id: String) -> int:
	return int(stash.get(mat_id, 0))


func add_stash(mat_id: String, count: int) -> void:
	if count <= 0:
		return
	stash[mat_id] = stash_count(mat_id) + count
	changed.emit()
	save_game()


func consume_stash(costs: Dictionary) -> bool:
	for mat_id in costs.keys():
		if stash_count(str(mat_id)) < int(costs[mat_id]):
			return false
	for mat_id in costs.keys():
		stash[str(mat_id)] = stash_count(str(mat_id)) - int(costs[mat_id])
		if stash[str(mat_id)] <= 0:
			stash.erase(str(mat_id))
	changed.emit()
	save_game()
	return true


func merge_inventory_into_stash(slots: Array) -> void:
	for entry in slots:
		var t := str(entry.get("type", ""))
		if t != "mat" and t != "rune" and t != "item":
			continue
		add_stash(str(entry.get("id")), int(entry.get("count", 1)))


func stash_as_entries(filter_kind: String = "") -> Array:
	## filter_kind: "" | "mat" | "rune" | "item" | "rune_skill" | "rune_attr"
	const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
	const ItemCatalog = preload("res://scripts/items/item_catalog.gd")
	var out: Array = []
	var keys: Array = stash.keys()
	keys.sort()
	for id in keys:
		var sid := str(id)
		var count := int(stash[id])
		if count <= 0:
			continue
		var entry_type := "mat"
		if RuneCatalog.DEFS.has(sid):
			entry_type = "rune"
		elif ItemCatalog.ITEMS.has(sid):
			entry_type = "item"
		if filter_kind == "mat" and entry_type != "mat":
			continue
		if filter_kind == "item" and entry_type != "item":
			continue
		if filter_kind == "rune" and entry_type != "rune":
			continue
		if filter_kind == "rune_skill" and (entry_type != "rune" or not RuneCatalog.is_skill(sid)):
			continue
		if filter_kind == "rune_attr" and (entry_type != "rune" or not RuneCatalog.is_attr(sid)):
			continue
		out.append({"type": entry_type, "id": sid, "count": count, "rank": 1})
	return out


func total_equipment_bonuses() -> Dictionary:
	_ensure_equipment()
	var total := {"max_hp": 0.0, "defense": 0.0, "damage": 0.0}
	for slot in [Equipment.SLOT_CHEST, Equipment.SLOT_AMULET]:
		var stats: Dictionary = Equipment.effective_stats(equipment[slot], slot)
		for k in total.keys():
			total[k] = float(total[k]) + float(stats.get(k, 0.0))
	return total


func try_craft(slot: String) -> String:
	_ensure_equipment()
	var data: Dictionary = equipment[slot]
	if bool(data.get("owned", false)):
		return "owned"
	var cost: Dictionary = Equipment.craft_cost(slot)
	if not consume_stash(cost):
		return "no_mats"
	data["owned"] = true
	data["upgrade"] = 0
	data["wear"] = 0
	changed.emit()
	save_game()
	return "ok"


func try_upgrade(slot: String) -> String:
	_ensure_equipment()
	var data: Dictionary = equipment[slot]
	if not bool(data.get("owned", false)):
		return "not_owned"
	var cost := {Equipment.UPGRADE_MAT: Equipment.UPGRADE_COST}
	if not consume_stash(cost):
		return "no_mats"
	data["upgrade"] = int(data.get("upgrade", 0)) + 1
	changed.emit()
	save_game()
	return "ok"


func try_absorb_mind() -> String:
	if mind_level >= 5:
		return "max"
	var cost := MindTable.cost_to_next(mind_level)
	if cost <= 0:
		return "max"
	## 优先碎晶，不足可用念核按 3 碎晶换算
	var shards := stash_count("mind_shard")
	var cores := stash_count("mind_core")
	var total_power := shards + cores * 3
	if total_power < cost:
		return "no_mats"
	var need := cost
	var use_shards := mini(shards, need)
	need -= use_shards
	var use_cores := 0
	if need > 0:
		use_cores = int(ceil(float(need) / 3.0))
	var pay := {}
	if use_shards > 0:
		pay["mind_shard"] = use_shards
	if use_cores > 0:
		pay["mind_core"] = use_cores
	if not consume_stash(pay):
		return "no_mats"
	mind_level += 1
	changed.emit()
	save_game()
	return "ok"


func try_convert_to_mind_value(prefer_core: bool = false) -> String:
	## 转化 1 份材料为念力值
	if prefer_core:
		if stash_count("mind_core") >= 1:
			if not consume_stash({"mind_core": 1}):
				return "no_mats"
			mind_value += CORE_TO_VALUE
			changed.emit()
			save_game()
			return "ok"
		return "no_mats"
	if stash_count("mind_shard") >= 1:
		if not consume_stash({"mind_shard": 1}):
			return "no_mats"
		mind_value += SHARD_TO_VALUE
		changed.emit()
		save_game()
		return "ok"
	if stash_count("mind_core") >= 1:
		if not consume_stash({"mind_core": 1}):
			return "no_mats"
		mind_value += CORE_TO_VALUE
		changed.emit()
		save_game()
		return "ok"
	return "no_mats"


func can_afford_mind(n: int) -> bool:
	return mind_value >= n


func consume_mind_value(n: int) -> bool:
	if n <= 0:
		return true
	if mind_value < n:
		return false
	mind_value -= n
	changed.emit()
	save_game()
	return true


func is_warp_unlocked(warp_id: String) -> bool:
	return unlocked_warps.has(warp_id)


func unlock_warp(warp_id: String) -> void:
	if warp_id == "" or unlocked_warps.has(warp_id):
		return
	unlocked_warps.append(warp_id)
	changed.emit()
	save_game()


func accept_quest(quest_id: String) -> String:
	if active_quest_id != "":
		return "busy"
	if not QuestDefs.QUESTS.has(quest_id):
		return "unknown"
	active_quest_id = quest_id
	changed.emit()
	save_game()
	return "ok"


func abandon_quest() -> void:
	active_quest_id = ""
	changed.emit()
	save_game()


func fail_quest() -> void:
	active_quest_id = ""
	changed.emit()
	save_game()


func complete_quest_if_able(run_stats: Dictionary) -> String:
	## run_stats: inventory_slots, kill_scale, rescue_done
	if active_quest_id == "":
		return "none"
	var def: Dictionary = QuestDefs.get_def(active_quest_id)
	var ok := false
	match str(def.get("type")):
		QuestDefs.TYPE_GATHER:
			var need_id := str(def.get("mat_id"))
			var need_n := int(def.get("count", 1))
			var have := 0
			for entry in run_stats.get("inventory_slots", []):
				if entry.get("type") == "mat" and str(entry.get("id")) == need_id:
					have += int(entry.get("count", 0))
			ok = have >= need_n
		QuestDefs.TYPE_KILL:
			ok = int(run_stats.get("kill_scale", 0)) >= int(def.get("count", 1))
		QuestDefs.TYPE_RESCUE:
			ok = bool(run_stats.get("rescue_done", false))
	if not ok:
		return "incomplete"
	gold += int(def.get("reward_gold", 0))
	var reward_mat: Dictionary = def.get("reward_mat", {})
	for mid in reward_mat.keys():
		add_stash(str(mid), int(reward_mat[mid]))
	active_quest_id = ""
	changed.emit()
	save_game()
	return "ok"


func apply_death_wear() -> void:
	if mind_level <= 2:
		return
	_ensure_equipment()
	Equipment.apply_death_wear(equipment[Equipment.SLOT_CHEST])
	Equipment.apply_death_wear(equipment[Equipment.SLOT_AMULET])
	changed.emit()
	save_game()


func add_intel(text: String) -> void:
	intel.append(text)
	if intel.size() > 20:
		intel = intel.slice(intel.size() - 20, intel.size())
	changed.emit()
	save_game()


func describe_stash() -> PackedStringArray:
	const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
	const ItemCatalog = preload("res://scripts/items/item_catalog.gd")
	var lines: PackedStringArray = []
	for mid in stash.keys():
		var sid := str(mid)
		var name := sid
		if MaterialCatalog.MATERIALS.has(sid):
			name = MaterialCatalog.display_name(sid)
		elif RuneCatalog.DEFS.has(sid):
			name = RuneCatalog.display_name(sid)
		elif ItemCatalog.ITEMS.has(sid):
			name = ItemCatalog.display_name(sid)
		lines.append("%s x%d" % [name, int(stash[mid])])
	return lines


func to_dict() -> Dictionary:
	return {
		"mind_level": mind_level,
		"mind_value": mind_value,
		"gold": gold,
		"stash": stash,
		"equipment": equipment,
		"learned_runes": learned_runes,
		"active_quest_id": active_quest_id,
		"intel": Array(intel),
		"unlocked_warps": unlocked_warps.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	mind_level = int(data.get("mind_level", 1))
	mind_value = int(data.get("mind_value", 0))
	gold = int(data.get("gold", 0))
	stash = data.get("stash", {})
	equipment = data.get("equipment", {})
	learned_runes = data.get("learned_runes", {})
	if typeof(learned_runes) != TYPE_DICTIONARY:
		learned_runes = {}
	active_quest_id = str(data.get("active_quest_id", ""))
	intel = PackedStringArray(data.get("intel", []))
	unlocked_warps = data.get("unlocked_warps", [])
	if typeof(unlocked_warps) != TYPE_ARRAY:
		unlocked_warps = []
	_ensure_equipment()


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict(), "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_ensure_equipment()
		## 新手赠礼，方便阶段 C 试玩
		if stash.is_empty():
			stash = {
				"mind_shard": 4,
				"mind_core": 1,
				"alchem_slag": 4,
				"beast_scale": 3,
				"glow_moss": 2,
				"rune_s_chain": 1,
				"item_bag_expand": 1,
			}
			mind_value = mind_value_max()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		from_dict(parsed)
	changed.emit()
