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
var learned_runes: Dictionary = {} ## 旧存档兼容；新进度用 learned_skills
var learned_skills: Dictionary = {} ## core_id -> rank(int)
var skill_loadout: Dictionary = {"rmb": "", "q": "", "e": "", "r": "", "f": "", "c": ""}
var explorer_xp: int = 0
var explorer_level: int = 1
var active_quest_id: String = ""
var intel: PackedStringArray = []
var unlocked_warps: Array = [] ## ["warp_a", ...]
var game_day: int = 1
var entered_pit_today: bool = false
## 横版 doc/new 扩展
var unlocked_shortcuts: Array = [] ## ["shortcut_moss_extract", ...]
var winch_level: int = 0 ## 绞盘机 0–3
var spotlight_level: int = 0 ## 探照灯 0–3
var awakening_branch: String = "" ## "" | whirl | ironwall
var breath_interval_days: int = 3

const WARP_COST_ENTER := 15
const WARP_COST_TRAVEL := 10
const MIND_VALUE_BASE := 40
const MIND_VALUE_PER_LEVEL := 10
const PAPER_FACE_VALUE := 100 ## 换出时标价（金币→券）
const VOUCHER_SPEND_VALUE := 99 ## 购买/兑回时 1 张金币券折合金币
const GOLD_TO_PAPER_COST := 100
const MIND_POTION_PRICE := 200
const MIND_POTION_RESTORE := 30
const WINCH_UPGRADE_COST := {"alchem_slag": 3, "beast_scale": 2}
const SPOTLIGHT_UPGRADE_COST := {"glow_moss": 2, "mind_shard": 2}
const AWAKEN_WHIRL_COST := {"mat_whirl_edge": 2, "glow_moss": 3}
const AWAKEN_IRON_COST := {"mat_iron_guard": 2, "alchem_slag": 3}


func mind_value_max() -> int:
	return MIND_VALUE_BASE + mind_level * MIND_VALUE_PER_LEVEL


func has_learned(rune_id: String) -> bool:
	return has_learned_skill(rune_id) or bool(learned_runes.get(rune_id, false))


func has_learned_skill(core_id: String) -> bool:
	return int(learned_skills.get(core_id, 0)) > 0 or bool(learned_runes.get(core_id, false))


func skill_rank(core_id: String) -> int:
	if int(learned_skills.get(core_id, 0)) > 0:
		return int(learned_skills[core_id])
	if bool(learned_runes.get(core_id, false)):
		return 1
	return 0


func mark_learned(rune_id: String) -> void:
	learned_runes[rune_id] = true
	if not learned_skills.has(rune_id):
		learned_skills[rune_id] = 1
	changed.emit()
	save_game()


func xp_to_next_level(level: int = -1) -> int:
	var lv := explorer_level if level < 0 else level
	return 40 + lv * 25


func grant_xp(amount: int) -> int:
	if amount <= 0:
		return 0
	explorer_xp += amount
	var gained := 0
	while explorer_level < 30 and explorer_xp >= xp_to_next_level():
		explorer_xp -= xp_to_next_level()
		explorer_level += 1
		gained += 1
	changed.emit()
	save_game()
	return gained


func skill_in_slot(slot: String) -> String:
	return str(skill_loadout.get(slot, ""))


func assign_skill_slot(slot: String, core_id: String) -> String:
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	if not slot in CrystalCatalog.HOTKEY_SLOTS:
		return "bad_slot"
	if core_id != "" and not has_learned_skill(core_id):
		return "unlearned"
	if core_id != "" and not CrystalCatalog.is_active(core_id):
		return "passive"
	for other in CrystalCatalog.HOTKEY_SLOTS:
		if other != slot and str(skill_loadout.get(other, "")) == core_id and core_id != "":
			skill_loadout[other] = ""
	skill_loadout[slot] = core_id
	changed.emit()
	save_game()
	return "ok"


func cycle_skill_slot(slot: String) -> String:
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	if not slot in CrystalCatalog.HOTKEY_SLOTS:
		return "bad_slot"
	var actives: Array = []
	for cid in learned_skills.keys():
		if int(learned_skills[cid]) > 0 and CrystalCatalog.is_active(str(cid)):
			actives.append(str(cid))
	actives.sort()
	if actives.is_empty():
		skill_loadout[slot] = ""
		changed.emit()
		save_game()
		return "ok"
	var cur := str(skill_loadout.get(slot, ""))
	var idx := actives.find(cur)
	var next_id := ""
	if idx < 0:
		next_id = str(actives[0])
	elif idx >= actives.size() - 1:
		next_id = ""
	else:
		next_id = str(actives[idx + 1])
	return assign_skill_slot(slot, next_id)


func try_comprehend(core_id: String, inventory = null, from_stash: bool = false) -> String:
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	if not CrystalCatalog.has_id(core_id):
		return "unknown"
	if mind_level < CrystalCatalog.mind_level_req(core_id):
		return "mind_level"
	var already := skill_rank(core_id)
	var cost := CrystalCatalog.learn_cost(core_id)
	if already > 0:
		cost += already * 10
	if not can_afford_mind(cost):
		return "no_mind"
	if from_stash:
		if stash_count(core_id) < 1:
			return "no_rune"
		if not consume_stash({core_id: 1}):
			return "no_rune"
	else:
		if inventory == null or not inventory.has_method("consume_core"):
			return "no_rune"
		if not inventory.consume_core(core_id):
			return "no_rune"
	if not consume_mind_value(cost):
		if from_stash:
			add_stash(core_id, 1)
		elif inventory != null and inventory.has_method("add_core"):
			inventory.add_core(core_id, 1)
		return "no_mind"
	learned_skills[core_id] = already + 1
	learned_runes[core_id] = true
	if CrystalCatalog.is_active(core_id) and already == 0:
		for slot in CrystalCatalog.HOTKEY_SLOTS:
			if str(skill_loadout.get(slot, "")) == "":
				skill_loadout[slot] = core_id
				break
	changed.emit()
	save_game()
	return "ok"


func learned_stat_dict() -> Dictionary:
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	var out: Dictionary = {}
	for cid in learned_skills.keys():
		if int(learned_skills[cid]) <= 0:
			continue
		out[str(cid)] = true
	for rid in learned_runes.keys():
		if bool(learned_runes[rid]):
			out[str(rid)] = true
			## 旧符文 ID 映射到晶核属性
			match str(rid):
				"rune_a_toughbone":
					out["core_a_toughbone"] = true
				"rune_a_heavyarm":
					out["core_a_heavyarm"] = true
				"rune_a_sharpeye":
					out["core_a_sharpeye"] = true
				"rune_a_cruel":
					out["core_a_cruel"] = true
				"rune_s_chain":
					out["core_s_chain"] = true
				"rune_s_quake":
					out["core_s_quake"] = true
	for cid in out.keys():
		if not CrystalCatalog.has_id(str(cid)) and not str(cid).begins_with("rune_"):
			pass
	return out


func grant_arena_skills() -> void:
	## 战斗场临时解锁，不写盘
	if not has_learned_skill("core_s_quake"):
		learned_skills["core_s_quake"] = 1
	if not has_learned_skill("core_s_bolt"):
		learned_skills["core_s_bolt"] = 1
	if str(skill_loadout.get("rmb", "")) == "":
		skill_loadout["rmb"] = "core_s_quake"
	if str(skill_loadout.get("q", "")) == "":
		skill_loadout["q"] = "core_s_bolt"
	changed.emit()


func advance_day() -> void:
	game_day += 1
	mind_value = mind_value_max()
	entered_pit_today = false
	changed.emit()
	save_game()


func mark_entered_pit() -> void:
	## 已取消「每日仅入坑 1 次」限制；保留接口以免旧调用报错。
	changed.emit()


func can_enter_pit_today() -> bool:
	return true


func is_shortcut_unlocked(shortcut_id: String) -> bool:
	return unlocked_shortcuts.has(shortcut_id)


func unlock_shortcut(shortcut_id: String) -> void:
	if shortcut_id == "" or unlocked_shortcuts.has(shortcut_id):
		return
	unlocked_shortcuts.append(shortcut_id)
	changed.emit()
	save_game()


func is_breath_day() -> bool:
	## 简化吐息：每 N 日触发（第 3、6、9… 日）
	return game_day > 0 and game_day % breath_interval_days == 0


func try_upgrade_winch() -> String:
	if winch_level >= 3:
		return "max"
	if not consume_stash(WINCH_UPGRADE_COST):
		return "no_mats"
	winch_level += 1
	changed.emit()
	save_game()
	return "ok"


func try_upgrade_spotlight() -> String:
	if spotlight_level >= 3:
		return "max"
	if not consume_stash(SPOTLIGHT_UPGRADE_COST):
		return "no_mats"
	spotlight_level += 1
	changed.emit()
	save_game()
	return "ok"


func try_awaken(branch: String) -> String:
	if awakening_branch != "" and awakening_branch != branch:
		return "locked_other"
	if awakening_branch == branch:
		return "owned"
	var cost: Dictionary = AWAKEN_WHIRL_COST if branch == "whirl" else AWAKEN_IRON_COST
	if branch != "whirl" and branch != "ironwall":
		return "bad_branch"
	if not consume_stash(cost):
		return "no_mats"
	awakening_branch = branch
	changed.emit()
	save_game()
	return "ok"


func restore_mind_value(amount: int) -> int:
	var before := mind_value
	mind_value = mini(mind_value + amount, mind_value_max())
	if mind_value != before:
		changed.emit()
		save_game()
	return mind_value - before


func paper_note_count(from_stash: bool = true) -> int:
	if from_stash:
		return stash_count("item_paper_note")
	return 0


func spendable_gold() -> int:
	## 金币 + 金币券按 VOUCHER_SPEND_VALUE 折算，购买时可不先兑成金币。
	return gold + paper_note_count() * VOUCHER_SPEND_VALUE


func can_afford_gold(cost: int) -> bool:
	return cost <= 0 or spendable_gold() >= cost


## 优先扣金币，不足再自动消耗金币券（每张折 99）。券超额部分退回金币。
func try_spend_gold(cost: int) -> String:
	if cost <= 0:
		return "ok"
	if not can_afford_gold(cost):
		return "no_gold"
	var remaining := cost
	var take_gold := mini(gold, remaining)
	gold -= take_gold
	remaining -= take_gold
	while remaining > 0:
		if stash_count("item_paper_note") < 1:
			## 理论上 can_afford 已保证，防御回滚
			gold += take_gold
			return "no_gold"
		if not consume_stash({"item_paper_note": 1}):
			gold += take_gold
			return "no_gold"
		remaining -= VOUCHER_SPEND_VALUE
	if remaining < 0:
		gold += -remaining
	changed.emit()
	save_game()
	return "ok"


func exchange_gold_to_paper(count: int = 1) -> String:
	var cost := GOLD_TO_PAPER_COST * count
	if gold < cost:
		return "no_gold"
	gold -= cost
	add_stash("item_paper_note", count)
	return "ok"


func exchange_paper_to_gold(count: int = 1) -> String:
	if stash_count("item_paper_note") < count:
		return "no_paper"
	if not consume_stash({"item_paper_note": count}):
		return "no_paper"
	gold += VOUCHER_SPEND_VALUE * count
	changed.emit()
	save_game()
	return "ok"


func buy_mind_potion(count: int = 1) -> String:
	var cost := MIND_POTION_PRICE * count
	var r := try_spend_gold(cost)
	if r != "ok":
		return r
	add_stash("item_mind_potion", count)
	return "ok"


func sell_stash_material(mat_id: String, count: int = 1) -> String:
	if not MaterialCatalog.MATERIALS.has(mat_id):
		return "unknown"
	if stash_count(mat_id) < count:
		return "no_item"
	var price := MaterialCatalog.sell_price(mat_id) * count
	if not consume_stash({mat_id: count}):
		return "no_item"
	gold += price
	changed.emit()
	save_game()
	return "ok"


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
		if t != "mat" and t != "rune" and t != "item" and t != "core":
			continue
		add_stash(str(entry.get("id")), int(entry.get("count", 1)))


func stash_as_entries(filter_kind: String = "") -> Array:
	## filter_kind: "" | "mat" | "rune" | "item" | "core" | "core_skill" | "core_attr" | "rune_skill" | "rune_attr"
	const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
	const ItemCatalog = preload("res://scripts/items/item_catalog.gd")
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	var out: Array = []
	var keys: Array = stash.keys()
	keys.sort()
	for id in keys:
		var sid := str(id)
		var count := int(stash[id])
		if count <= 0:
			continue
		var entry_type := "mat"
		if CrystalCatalog.has_id(sid):
			entry_type = "core"
		elif RuneCatalog.DEFS.has(sid):
			entry_type = "rune"
		elif ItemCatalog.ITEMS.has(sid):
			entry_type = "item"
		if filter_kind == "mat" and entry_type != "mat":
			continue
		if filter_kind == "item" and entry_type != "item":
			continue
		if filter_kind == "rune" and entry_type != "rune" and entry_type != "core":
			continue
		if filter_kind == "core" and entry_type != "core":
			continue
		if filter_kind == "core_skill" and (entry_type != "core" or not CrystalCatalog.is_skill(sid)):
			continue
		if filter_kind == "core_attr" and (entry_type != "core" or not CrystalCatalog.is_attr(sid)):
			continue
		if filter_kind == "rune_skill" and not (
			(entry_type == "core" and CrystalCatalog.is_skill(sid))
			or (entry_type == "rune" and RuneCatalog.is_skill(sid))
		):
			continue
		if filter_kind == "rune_attr" and not (
			(entry_type == "core" and CrystalCatalog.is_attr(sid))
			or (entry_type == "rune" and RuneCatalog.is_attr(sid))
		):
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
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	var lines: PackedStringArray = []
	for mid in stash.keys():
		var sid := str(mid)
		var disp_name := sid
		if MaterialCatalog.MATERIALS.has(sid):
			disp_name = MaterialCatalog.display_name(sid)
		elif CrystalCatalog.has_id(sid):
			disp_name = CrystalCatalog.display_name(sid)
		elif RuneCatalog.DEFS.has(sid):
			disp_name = RuneCatalog.display_name(sid)
		elif ItemCatalog.ITEMS.has(sid):
			disp_name = ItemCatalog.display_name(sid)
		lines.append("%s x%d" % [disp_name, int(stash[mid])])
	return lines


func to_dict() -> Dictionary:
	return {
		"mind_level": mind_level,
		"mind_value": mind_value,
		"gold": gold,
		"stash": stash,
		"equipment": equipment,
		"learned_runes": learned_runes,
		"learned_skills": learned_skills,
		"skill_loadout": skill_loadout,
		"explorer_xp": explorer_xp,
		"explorer_level": explorer_level,
		"active_quest_id": active_quest_id,
		"intel": Array(intel),
		"unlocked_warps": unlocked_warps.duplicate(),
		"game_day": game_day,
		"entered_pit_today": entered_pit_today,
		"unlocked_shortcuts": unlocked_shortcuts.duplicate(),
		"winch_level": winch_level,
		"spotlight_level": spotlight_level,
		"awakening_branch": awakening_branch,
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
	learned_skills = data.get("learned_skills", {})
	if typeof(learned_skills) != TYPE_DICTIONARY:
		learned_skills = {}
	skill_loadout = data.get("skill_loadout", {"rmb": "", "q": "", "e": "", "r": "", "f": "", "c": ""})
	if typeof(skill_loadout) != TYPE_DICTIONARY:
		skill_loadout = {"rmb": "", "q": "", "e": "", "r": "", "f": "", "c": ""}
	for k in ["rmb", "q", "e", "r", "f", "c"]:
		if not skill_loadout.has(k):
			skill_loadout[k] = ""
	explorer_xp = int(data.get("explorer_xp", 0))
	explorer_level = maxi(1, int(data.get("explorer_level", 1)))
	active_quest_id = str(data.get("active_quest_id", ""))
	intel = PackedStringArray(data.get("intel", []))
	unlocked_warps = data.get("unlocked_warps", [])
	if typeof(unlocked_warps) != TYPE_ARRAY:
		unlocked_warps = []
	game_day = int(data.get("game_day", 1))
	entered_pit_today = bool(data.get("entered_pit_today", false))
	unlocked_shortcuts = data.get("unlocked_shortcuts", [])
	if typeof(unlocked_shortcuts) != TYPE_ARRAY:
		unlocked_shortcuts = []
	winch_level = int(data.get("winch_level", 0))
	spotlight_level = int(data.get("spotlight_level", 0))
	awakening_branch = str(data.get("awakening_branch", ""))
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
				"core_s_chain": 1,
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
