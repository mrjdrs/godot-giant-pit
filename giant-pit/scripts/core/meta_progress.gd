extends Node
## 局外进度唯一真源。五档独立存档 user://saves/slot_1..5.json

const Equipment = preload("res://scripts/meta/equipment.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")
const QuestDefs = preload("res://scripts/meta/quest_defs.gd")
const MaterialCatalog = preload("res://scripts/items/material_catalog.gd")

const SLOT_COUNT := 5
const SAVES_DIR := "user://saves"
const INDEX_PATH := "user://saves/index.json"
const LEGACY_SAVE_PATH := "user://meta_save.json"
const SAVE_PATH := "user://meta_save.json" ## 旧单档，仅迁移用

signal changed

var active_slot: int = -1
var last_slot: int = -1

var mind_level: int = 1 ## 旧存档兼容；门槛已改探索等级
var mind_shards_banked: int = 0 ## 静室待吸收也可直接扣 stash
var mind_value: int = 0 ## 放技能 / 传送消耗
var gold: int = 0
var imprint_family: String = "cold_blade"
var mage_element: String = "fire" ## fire|ice|acid|dark|light；仅烙印为 mage 时生效
var affinity_kind: String = "animal" ## animal|plant；仅烙印为 affinity 时生效
var attr_allocated: Dictionary = {"str": 0, "vit": 0, "agi": 0, "int": 0, "spi": 0, "luk": 0}
var unspent_points: int = 0
var quest_kill_progress: int = 0
var stash: Dictionary = {} ## id -> count（材料 / 未学符文 / 特殊道具）
var equipment: Dictionary = {}
var learned_runes: Dictionary = {} ## 旧存档兼容；新进度用 learned_skills
var learned_skills: Dictionary = {} ## core_id -> rank(int)
var skill_loadout: Dictionary = {"rmb": "", "q": "", "e": "", "r": "", "f": "", "c": ""}
## 试刀场沙盒：改等级/装配只动内存，save_game 直接跳过，离场还原。
var _skill_sandbox_active: bool = false
var _skill_sandbox_snap: Dictionary = {}
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
const MIND_VALUE_PER_INT := 4
const MIND_VALUE_PER_LEVEL := 2
const TRAINING_MIND_MAX := 999
const POINTS_PER_LEVEL := 3
const EXPLORER_LEVEL_MAX := 60
const ATTR_KEYS := ["str", "vit", "agi", "int", "spi", "luk"]
const PAPER_FACE_VALUE := 100 ## 换出时标价（金币→券）
const VOUCHER_SPEND_VALUE := 99 ## 购买/兑回时 1 张金币券折合金币
const GOLD_TO_PAPER_COST := 100
const MIND_POTION_PRICE := 200
const MIND_POTION_RESTORE := 30
const EROSION_SALVE_PRICE := 80
const EROSION_SALVE_HEAL := 25.0
const EROSION_WARD_PRICE := 150
const WINCH_UPGRADE_COST := {"alchem_slag": 3, "beast_scale": 2}
const SPOTLIGHT_UPGRADE_COST := {"glow_moss": 2, "mind_shard": 2}
const AWAKEN_WHIRL_COST := {"mat_whirl_edge": 2, "glow_moss": 3}
const AWAKEN_IRON_COST := {"mat_iron_guard": 2, "alchem_slag": 3}


func mind_value_max() -> int:
	if _skill_sandbox_active:
		return TRAINING_MIND_MAX
	var int_pts := int(attr_allocated.get("int", 0))
	return MIND_VALUE_BASE + int_pts * MIND_VALUE_PER_INT + explorer_level * MIND_VALUE_PER_LEVEL


func attr_value(key: String) -> int:
	return int(attr_allocated.get(key, 0))


func spend_attr_point(key: String) -> String:
	if unspent_points <= 0:
		return "none"
	if not ATTR_KEYS.has(key):
		return "bad"
	attr_allocated[key] = int(attr_allocated.get(key, 0)) + 1
	unspent_points -= 1
	changed.emit()
	save_game()
	return "ok"


func has_learned(rune_id: String) -> bool:
	return has_learned_skill(rune_id) or bool(learned_runes.get(rune_id, false))


func has_learned_skill(core_id: String) -> bool:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var sid := SkillCatalog.migrate_id(core_id)
	return int(learned_skills.get(sid, 0)) > 0 \
		or int(learned_skills.get(core_id, 0)) > 0 \
		or bool(learned_runes.get(sid, false)) \
		or bool(learned_runes.get(core_id, false))


func skill_rank(core_id: String) -> int:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var sid := SkillCatalog.migrate_id(core_id)
	if int(learned_skills.get(sid, 0)) > 0:
		return int(learned_skills[sid])
	if int(learned_skills.get(core_id, 0)) > 0:
		return int(learned_skills[core_id])
	if bool(learned_runes.get(sid, false)) or bool(learned_runes.get(core_id, false)):
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
	while explorer_level < EXPLORER_LEVEL_MAX and explorer_xp >= xp_to_next_level():
		explorer_xp -= xp_to_next_level()
		explorer_level += 1
		unspent_points += POINTS_PER_LEVEL
		gained += 1
	changed.emit()
	save_game()
	if Engine.get_main_loop() != null and Engine.get_main_loop().root != null:
		GameBus.pub("xp_gained", {"amount": amount, "levels": gained})
	return gained


func skill_in_slot(slot: String) -> String:
	return str(skill_loadout.get(slot, ""))


func assign_skill_slot(slot: String, core_id: String, persist: bool = true) -> String:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not slot in SkillCatalog.HOTKEY_SLOTS:
		return "bad_slot"
	var sid := SkillCatalog.migrate_id(core_id) if core_id != "" else ""
	if sid != "" and not has_learned_skill(sid):
		return "unlearned"
	if sid != "" and not SkillCatalog.is_active(sid):
		return "passive"
	for other in SkillCatalog.HOTKEY_SLOTS:
		if other != slot and str(skill_loadout.get(other, "")) == sid and sid != "":
			skill_loadout[other] = ""
	skill_loadout[slot] = sid
	changed.emit()
	if persist:
		save_game()
	return "ok"


func cycle_skill_slot(slot: String, persist: bool = true) -> String:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not slot in SkillCatalog.HOTKEY_SLOTS:
		return "bad_slot"
	var actives: Array = []
	for cid in learned_skills.keys():
		var sid := SkillCatalog.migrate_id(str(cid))
		if int(learned_skills[cid]) > 0 and SkillCatalog.is_active(sid) and not actives.has(sid):
			actives.append(sid)
	actives.sort()
	if actives.is_empty():
		skill_loadout[slot] = ""
		changed.emit()
		if persist:
			save_game()
		return "ok"
	var cur := SkillCatalog.migrate_id(str(skill_loadout.get(slot, "")))
	var idx := actives.find(cur)
	var next_id := ""
	if idx < 0:
		next_id = str(actives[0])
	elif idx >= actives.size() - 1:
		next_id = ""
	else:
		next_id = str(actives[idx + 1])
	return assign_skill_slot(slot, next_id, persist)


func is_skill_sandbox_active() -> bool:
	return _skill_sandbox_active


func snapshot_skill_state() -> Dictionary:
	return {
		"learned_skills": learned_skills.duplicate(true),
		"skill_loadout": skill_loadout.duplicate(true),
		"mind_value": mind_value,
		"imprint_family": imprint_family,
		"mage_element": mage_element,
		"affinity_kind": affinity_kind,
	}


func _apply_skill_state(snap: Dictionary) -> void:
	learned_skills = snap.get("learned_skills", {}).duplicate(true)
	skill_loadout = snap.get("skill_loadout", {}).duplicate(true)
	if snap.has("mind_value"):
		mind_value = int(snap["mind_value"])
	if snap.has("imprint_family"):
		imprint_family = str(snap["imprint_family"])
		if imprint_family == "":
			imprint_family = "cold_blade"
	if snap.has("mage_element"):
		mage_element = str(snap["mage_element"])
		if mage_element == "":
			mage_element = "fire"
	if snap.has("affinity_kind"):
		affinity_kind = str(snap["affinity_kind"])
		if affinity_kind == "":
			affinity_kind = "animal"


func begin_skill_sandbox() -> void:
	if _skill_sandbox_active:
		return
	_skill_sandbox_snap = snapshot_skill_state()
	_skill_sandbox_active = true


func end_skill_sandbox() -> void:
	if not _skill_sandbox_active:
		return
	_apply_skill_state(_skill_sandbox_snap)
	_skill_sandbox_active = false
	_skill_sandbox_snap.clear()
	changed.emit()


func restore_skill_sandbox_snapshot() -> void:
	if not _skill_sandbox_active or _skill_sandbox_snap.is_empty():
		return
	_apply_skill_state(_skill_sandbox_snap)
	changed.emit()


func set_skill_rank_sandbox(skill_id: String, rank: int) -> String:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not _skill_sandbox_active:
		return "no_sandbox"
	var sid := SkillCatalog.migrate_id(skill_id)
	if not SkillCatalog.has_id(sid):
		return "unknown"
	var r := clampi(rank, 0, SkillCatalog.max_rank(sid))
	if r <= 0:
		learned_skills.erase(sid)
		for slot in SkillCatalog.HOTKEY_SLOTS:
			if str(skill_loadout.get(slot, "")) == sid:
				skill_loadout[slot] = ""
	else:
		learned_skills[sid] = r
		if SkillCatalog.is_active(sid):
			var equipped := false
			for slot in SkillCatalog.HOTKEY_SLOTS:
				if str(skill_loadout.get(slot, "")) == sid:
					equipped = true
					break
			if not equipped:
				for slot in SkillCatalog.HOTKEY_SLOTS:
					if str(skill_loadout.get(slot, "")) == "":
						skill_loadout[slot] = sid
						break
	changed.emit()
	return "ok"


func tree_family() -> String:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	return SkillCatalog.active_tree_family(imprint_family, mage_element)


func fill_all_skills_sandbox() -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not _skill_sandbox_active:
		return
	var fam := tree_family()
	for sid in SkillCatalog.tree_ids(fam):
		learned_skills[str(sid)] = SkillCatalog.max_rank(str(sid))
	var used: Dictionary = {}
	for slot in SkillCatalog.HOTKEY_SLOTS:
		var cur := str(skill_loadout.get(slot, ""))
		if cur != "" and SkillCatalog.family_of(cur) == fam:
			used[cur] = true
		elif cur != "":
			skill_loadout[slot] = ""
	for sid in SkillCatalog.tree_ids(fam):
		var id_str := str(sid)
		if not SkillCatalog.is_active(id_str) or used.has(id_str):
			continue
		for slot in SkillCatalog.HOTKEY_SLOTS:
			if str(skill_loadout.get(slot, "")) == "":
				skill_loadout[slot] = id_str
				used[id_str] = true
				break
	changed.emit()


func set_imprint_family_sandbox(family: String) -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not _skill_sandbox_active:
		return
	var fam := SkillCatalog.normalize_imprint(family)
	if fam not in [SkillCatalog.FAMILY_COLD, SkillCatalog.FAMILY_HOT, SkillCatalog.FAMILY_MAGE, SkillCatalog.FAMILY_AFFINITY]:
		return
	imprint_family = fam
	if not SkillCatalog.is_mage_imprint(fam):
		mage_element = "fire"
	if not SkillCatalog.is_affinity_imprint(fam):
		affinity_kind = "animal"
	var tree := tree_family()
	for slot in SkillCatalog.HOTKEY_SLOTS:
		var sid := str(skill_loadout.get(slot, ""))
		if sid != "" and SkillCatalog.family_of(sid) != tree:
			skill_loadout[slot] = ""
	_ensure_innate_skills(false)
	changed.emit()


func set_mage_element_sandbox(element: String) -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not _skill_sandbox_active:
		return
	if not SkillCatalog.is_mage_imprint(imprint_family):
		return
	if element not in SkillCatalog.MAGE_ELEMENTS:
		return
	if mage_element == element:
		return
	mage_element = element
	var tree := tree_family()
	for slot in SkillCatalog.HOTKEY_SLOTS:
		var sid := str(skill_loadout.get(slot, ""))
		if sid != "" and SkillCatalog.family_of(sid) != tree:
			skill_loadout[slot] = ""
	_ensure_innate_skills(false)
	changed.emit()


func set_affinity_kind_sandbox(kind: String) -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	if not _skill_sandbox_active:
		return
	if not SkillCatalog.is_affinity_imprint(imprint_family):
		return
	if kind not in SkillCatalog.AFFINITY_KINDS:
		return
	if affinity_kind == kind:
		return
	affinity_kind = kind
	changed.emit()


func try_comprehend(core_id: String, inventory = null, from_stash: bool = false) -> String:
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	## 属性晶核仍可在背包/仓库消耗感悟。
	if CrystalCatalog.is_attr(core_id):
		return _try_comprehend_attr(core_id, inventory, from_stash)
	if not from_stash:
		return "pit_blocked"
	var sid := SkillCatalog.migrate_id(core_id)
	if not SkillCatalog.has_id(sid):
		return "unknown"
	if SkillCatalog.family_of(sid) != tree_family():
		return "wrong_family"
	if explorer_level < SkillCatalog.level_req(sid):
		return "level"
	var already := skill_rank(sid)
	if already >= SkillCatalog.max_rank(sid):
		return "learned"
	if not SkillCatalog.prereqs_met(sid, skill_rank):
		return "prereq"
	var cost := SkillCatalog.learn_cost_for_rank(sid, already + 1)
	if cost > 0 and stash_count(SkillCatalog.CRYSTAL_ID) < cost:
		return "no_crystal"
	if cost > 0 and not consume_stash({SkillCatalog.CRYSTAL_ID: cost}):
		return "no_crystal"
	learned_skills[sid] = already + 1
	learned_runes[sid] = true
	if SkillCatalog.is_active(sid) and already == 0:
		for slot in SkillCatalog.HOTKEY_SLOTS:
			if str(skill_loadout.get(slot, "")) == "":
				skill_loadout[slot] = sid
				break
	changed.emit()
	save_game()
	return "ok"


func _try_comprehend_attr(core_id: String, inventory = null, from_stash: bool = false) -> String:
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	if not CrystalCatalog.has_id(core_id):
		return "unknown"
	if explorer_level < CrystalCatalog.level_req(core_id):
		return "level"
	var need_grade := CrystalCatalog.grade(core_id)
	var already := skill_rank(core_id)
	if from_stash:
		if stash_count(core_id) < 1:
			return "no_rune"
		if not consume_stash({core_id: 1}):
			return "no_rune"
	else:
		if inventory == null:
			return "no_rune"
		if inventory.has_method("consume_core_min_grade"):
			if not inventory.consume_core_min_grade(core_id, need_grade):
				if inventory.has_method("find_core_index") and inventory.find_core_index(core_id) >= 0:
					return "grade"
				return "no_rune"
		elif not inventory.has_method("consume_core") or not inventory.consume_core(core_id):
			return "no_rune"
	learned_skills[core_id] = already + 1
	learned_runes[core_id] = true
	changed.emit()
	save_game()
	return "ok"


func try_forget(skill_id: String) -> String:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var sid := SkillCatalog.migrate_id(skill_id)
	if not SkillCatalog.has_id(sid):
		return "unknown"
	var rank := skill_rank(sid)
	if rank <= 0:
		return "unlearned"
	if SkillCatalog.is_innate(sid) and rank <= 1:
		return "innate"
	var after_rank := 0
	if SkillCatalog.is_innate(sid):
		after_rank = 1
	if SkillCatalog.is_required_by_others(sid, after_rank, skill_rank):
		return "prereq"
	var refund := SkillCatalog.spent_cost(sid, rank) - SkillCatalog.spent_cost(sid, after_rank)
	if after_rank > 0:
		learned_skills[sid] = after_rank
	else:
		learned_skills.erase(sid)
		learned_runes.erase(sid)
		for slot in SkillCatalog.HOTKEY_SLOTS:
			if str(skill_loadout.get(slot, "")) == sid:
				skill_loadout[slot] = ""
	if refund > 0:
		add_stash(SkillCatalog.CRYSTAL_ID, refund)
	changed.emit()
	save_game()
	return "ok"


func learned_stat_dict() -> Dictionary:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var out: Dictionary = {}
	for cid in learned_skills.keys():
		if int(learned_skills[cid]) <= 0:
			continue
		var sid := SkillCatalog.migrate_id(str(cid))
		out[sid] = true
		out[str(cid)] = true
	for rid in learned_runes.keys():
		if bool(learned_runes[rid]):
			out[str(rid)] = true
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
					out["ws_passive_bloodinstinct"] = true
				"rune_s_quake":
					out["ws_active_groundwave"] = true
				"rune_s_cloudstep":
					out["ws_active_dashslash"] = true
				"rune_s_ironwall":
					out["ws_passive_heavyarm"] = true
	return out


func grant_arena_skills() -> void:
	## 战斗场临时解锁，不写盘
	_ensure_innate_skills(false)
	for sid in ["ws_active_dashslash", "ws_active_groundwave", "ws_active_whirlwind"]:
		if skill_rank(sid) < 1:
			learned_skills[sid] = 1
	if str(skill_loadout.get("rmb", "")) == "":
		skill_loadout["rmb"] = "ws_active_dashslash"
	if str(skill_loadout.get("q", "")) == "":
		skill_loadout["q"] = "ws_active_groundwave"
	if str(skill_loadout.get("e", "")) == "":
		skill_loadout["e"] = "ws_active_whirlwind"
	changed.emit()


func _ensure_innate_skills(persist: bool = true) -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	var dirty := false
	imprint_family = SkillCatalog.normalize_imprint(imprint_family)
	if mage_element not in SkillCatalog.MAGE_ELEMENTS:
		mage_element = "fire"
	if affinity_kind not in SkillCatalog.AFFINITY_KINDS:
		affinity_kind = "animal"
	var innates: Array = SkillCatalog.innate_ids_for_tree(tree_family())
	for sid in innates:
		if skill_rank(str(sid)) < 1:
			learned_skills[str(sid)] = 1
			dirty = true
	var dash_id := SkillCatalog.dash_skill_for(imprint_family, mage_element)
	if str(skill_loadout.get("rmb", "")) == "" and skill_rank(dash_id) > 0:
		skill_loadout["rmb"] = dash_id
		dirty = true
	if dirty and persist:
		save_game()


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


func restore_mind_value(amount: int, persist: bool = true) -> int:
	var before := mind_value
	mind_value = mini(mind_value + amount, mind_value_max())
	if mind_value != before:
		changed.emit()
		if persist:
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


func buy_erosion_salve(count: int = 1) -> String:
	var cost := EROSION_SALVE_PRICE * count
	var r := try_spend_gold(cost)
	if r != "ok":
		return r
	add_stash("item_erosion_salve", count)
	return "ok"


func buy_erosion_ward(count: int = 1) -> String:
	var cost := EROSION_WARD_PRICE * count
	var r := try_spend_gold(cost)
	if r != "ok":
		return r
	add_stash("item_erosion_ward", count)
	return "ok"


func sell_stash_material(mat_id: String, count: int = 1) -> String:
	if not MaterialCatalog.MATERIALS.has(mat_id):
		return "unknown"
	if mat_id == "crystal_core":
		return "locked"
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
	_ensure_saves_dir()
	_migrate_legacy_save()
	_load_index()
	_ensure_equipment()


func add_gold(amount: int) -> void:
	if amount == 0:
		return
	gold = maxi(0, gold + amount)
	changed.emit()
	save_game()


func _ensure_equipment() -> void:
	if not equipment.has(Equipment.SLOT_CHEST):
		equipment[Equipment.SLOT_CHEST] = Equipment.make_default_slot(Equipment.SLOT_CHEST)
	if not equipment.has(Equipment.SLOT_AMULET):
		equipment[Equipment.SLOT_AMULET] = Equipment.make_default_slot(Equipment.SLOT_AMULET)
	Equipment.ensure_fields(equipment[Equipment.SLOT_CHEST])
	Equipment.ensure_fields(equipment[Equipment.SLOT_AMULET])


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
	data["grade"] = int(data.get("grade", 2))
	data["quality"] = int(data.get("quality", ItemTier.Tier.COMMON))
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
	if _skill_sandbox_active:
		return true
	return mind_value >= n


func consume_mind_value(n: int, persist: bool = true) -> bool:
	if _skill_sandbox_active:
		return true
	if n <= 0:
		return true
	if mind_value < n:
		return false
	mind_value -= n
	changed.emit()
	if persist:
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
			ok = maxi(int(run_stats.get("kill_scale", 0)), quest_kill_progress) >= int(def.get("count", 1))
		QuestDefs.TYPE_RESCUE:
			ok = bool(run_stats.get("rescue_done", false))
	if not ok:
		return "incomplete"
	gold += int(def.get("reward_gold", 0))
	var reward_mat: Dictionary = def.get("reward_mat", {})
	for mid in reward_mat.keys():
		add_stash(str(mid), int(reward_mat[mid]))
	var xp_reward := int(def.get("reward_xp", 0))
	if xp_reward > 0:
		grant_xp(xp_reward)
	quest_kill_progress = 0
	active_quest_id = ""
	changed.emit()
	save_game()
	return "ok"


func apply_death_wear() -> void:
	if explorer_level <= 2:
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
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"saved_unix": Time.get_unix_time_from_system(),
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
		"imprint_family": imprint_family,
		"mage_element": mage_element,
		"affinity_kind": affinity_kind,
		"attr_allocated": attr_allocated.duplicate(),
		"unspent_points": unspent_points,
		"quest_kill_progress": quest_kill_progress,
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
	explorer_level = clampi(int(data.get("explorer_level", 1)), 1, EXPLORER_LEVEL_MAX)
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
	imprint_family = str(data.get("imprint_family", "cold_blade"))
	if imprint_family == "":
		imprint_family = "cold_blade"
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	imprint_family = SkillCatalog.normalize_imprint(imprint_family)
	mage_element = str(data.get("mage_element", "fire"))
	if mage_element not in SkillCatalog.MAGE_ELEMENTS:
		mage_element = "fire"
	affinity_kind = str(data.get("affinity_kind", "animal"))
	if affinity_kind not in SkillCatalog.AFFINITY_KINDS:
		affinity_kind = "animal"
	attr_allocated = data.get("attr_allocated", {"str": 0, "vit": 0, "agi": 0, "int": 0, "spi": 0, "luk": 0})
	if typeof(attr_allocated) != TYPE_DICTIONARY:
		attr_allocated = {"str": 0, "vit": 0, "agi": 0, "int": 0, "spi": 0, "luk": 0}
	for k in ATTR_KEYS:
		if not attr_allocated.has(k):
			attr_allocated[k] = 0
	unspent_points = maxi(0, int(data.get("unspent_points", 0)))
	quest_kill_progress = maxi(0, int(data.get("quest_kill_progress", 0)))
	_ensure_equipment()
	_migrate_skill_progress()


func _migrate_skill_progress() -> void:
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
	var converted := {}
	for old_id in learned_skills.keys():
		var sid := SkillCatalog.migrate_id(str(old_id))
		var rk := int(learned_skills[old_id])
		if sid == str(old_id):
			converted[sid] = maxi(int(converted.get(sid, 0)), rk)
			continue
		converted[sid] = maxi(int(converted.get(sid, 0)), rk)
	for old_id in learned_runes.keys():
		if not bool(learned_runes[old_id]):
			continue
		var sid := SkillCatalog.migrate_id(str(old_id))
		if SkillCatalog.has_id(sid):
			converted[sid] = maxi(int(converted.get(sid, 0)), 1)
	learned_skills = converted
	var new_loadout := {"rmb": "", "q": "", "e": "", "r": "", "f": "", "c": ""}
	for slot in SkillCatalog.HOTKEY_SLOTS:
		var sid := SkillCatalog.migrate_id(str(skill_loadout.get(slot, "")))
		if sid != "" and SkillCatalog.is_active(sid) and skill_rank(sid) > 0:
			new_loadout[slot] = sid
	skill_loadout = new_loadout
	var crystal_add := 0
	var stash_keys: Array = stash.keys()
	for mid in stash_keys:
		var sid := str(mid)
		if CrystalCatalog.is_skill(sid) or SkillCatalog.LEGACY_SKILL_MAP.has(sid):
			crystal_add += int(stash[mid]) * 2
			stash.erase(mid)
	if crystal_add > 0:
		stash[SkillCatalog.CRYSTAL_ID] = stash_count(SkillCatalog.CRYSTAL_ID) + crystal_add
	_ensure_innate_skills(false)


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVES_DIR, slot]


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func is_slot_empty(slot: int) -> bool:
	if not is_valid_slot(slot):
		return true
	return not FileAccess.file_exists(slot_path(slot))


func has_any_save() -> bool:
	for i in range(1, SLOT_COUNT + 1):
		if not is_slot_empty(i):
			return true
	return false


func last_played_slot() -> int:
	if is_valid_slot(last_slot) and not is_slot_empty(last_slot):
		return last_slot
	var best := -1
	var best_t := -1.0
	for i in range(1, SLOT_COUNT + 1):
		var info := slot_summary(i)
		if bool(info.get("empty", true)):
			continue
		var t := float(info.get("saved_unix", 0.0))
		if t >= best_t:
			best_t = t
			best = i
	return best


func slot_summary(slot: int) -> Dictionary:
	if not is_valid_slot(slot) or is_slot_empty(slot):
		return {"slot": slot, "empty": true}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {"slot": slot, "empty": true}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"slot": slot, "empty": true}
	var d: Dictionary = parsed
	return {
		"slot": slot,
		"empty": false,
		"game_day": int(d.get("game_day", 1)),
		"explorer_level": maxi(1, int(d.get("explorer_level", 1))),
		"gold": int(d.get("gold", 0)),
		"saved_at": str(d.get("saved_at", "")),
		"saved_unix": float(d.get("saved_unix", 0.0)),
	}


func reset_progress(with_starter: bool = true) -> void:
	mind_level = 1
	mind_shards_banked = 0
	mind_value = 0
	gold = 0
	imprint_family = "cold_blade"
	mage_element = "fire"
	affinity_kind = "animal"
	attr_allocated = {"str": 0, "vit": 0, "agi": 0, "int": 0, "spi": 0, "luk": 0}
	unspent_points = 0
	quest_kill_progress = 0
	stash = {}
	equipment = {}
	learned_runes = {}
	learned_skills = {}
	skill_loadout = {"rmb": "", "q": "", "e": "", "r": "", "f": "", "c": ""}
	explorer_xp = 0
	explorer_level = 1
	active_quest_id = ""
	intel = PackedStringArray()
	unlocked_warps = []
	game_day = 1
	entered_pit_today = false
	unlocked_shortcuts = []
	winch_level = 0
	spotlight_level = 0
	awakening_branch = ""
	_ensure_equipment()
	if with_starter:
		stash = {
			"mind_shard": 4,
			"mind_core": 1,
			"alchem_slag": 4,
			"beast_scale": 3,
			"glow_moss": 2,
			"crystal_core": 8,
			"item_bag_expand": 1,
		}
		mind_value = mind_value_max()
		_ensure_innate_skills(false)


func new_game(slot: int) -> bool:
	return new_game_with_imprint(slot, "cold_blade", "fire", "animal")


func new_game_with_imprint(slot: int, imprint: String, element: String = "fire", kind: String = "animal") -> bool:
	if not is_valid_slot(slot):
		return false
	const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
	active_slot = slot
	last_slot = slot
	reset_progress(true)
	imprint_family = SkillCatalog.normalize_imprint(imprint)
	if imprint_family not in [SkillCatalog.FAMILY_COLD, SkillCatalog.FAMILY_HOT, SkillCatalog.FAMILY_MAGE, SkillCatalog.FAMILY_AFFINITY]:
		imprint_family = SkillCatalog.FAMILY_COLD
	if SkillCatalog.is_mage_imprint(imprint_family):
		mage_element = element if element in SkillCatalog.MAGE_ELEMENTS else "fire"
	if SkillCatalog.is_affinity_imprint(imprint_family):
		affinity_kind = kind if kind in SkillCatalog.AFFINITY_KINDS else "animal"
	_ensure_innate_skills(false)
	save_game()
	_save_index()
	changed.emit()
	return true


func load_slot(slot: int) -> bool:
	if not is_valid_slot(slot) or is_slot_empty(slot):
		return false
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	from_dict(parsed)
	active_slot = slot
	last_slot = slot
	_save_index()
	changed.emit()
	return true


func delete_slot(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	var path := slot_path(slot)
	var dir := DirAccess.open(SAVES_DIR)
	if dir != null and FileAccess.file_exists(path):
		dir.remove("slot_%d.json" % slot)
	if active_slot == slot:
		active_slot = -1
		reset_progress(false)
	if last_slot == slot:
		last_slot = last_played_slot()
	_save_index()
	changed.emit()
	return true


func ensure_session_loaded() -> bool:
	if is_valid_slot(active_slot) and not is_slot_empty(active_slot):
		return true
	var s := last_played_slot()
	if s >= 1:
		return load_slot(s)
	return false


func save_game() -> void:
	if _skill_sandbox_active:
		return
	if not is_valid_slot(active_slot):
		return
	_ensure_saves_dir()
	var f := FileAccess.open(slot_path(active_slot), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict(), "\t"))
	last_slot = active_slot
	_save_index()


func load_game() -> void:
	## 兼容旧调用：若已有活动档则重载，否则尝试最近一档。
	if is_valid_slot(active_slot):
		load_slot(active_slot)
		return
	var s := last_played_slot()
	if s >= 1:
		load_slot(s)


func _ensure_saves_dir() -> void:
	var d := DirAccess.open("user://")
	if d == null:
		return
	if not d.dir_exists("saves"):
		d.make_dir_recursive("saves")


func _load_index() -> void:
	if not FileAccess.file_exists(INDEX_PATH):
		return
	var f := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	last_slot = int(parsed.get("last_slot", -1))


func _save_index() -> void:
	_ensure_saves_dir()
	var f := FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"last_slot": last_slot}, "\t"))


func _migrate_legacy_save() -> void:
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	if not is_slot_empty(1):
		return
	var src := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if src == null:
		return
	_ensure_saves_dir()
	var dst := FileAccess.open(slot_path(1), FileAccess.WRITE)
	if dst == null:
		return
	dst.store_string(src.get_as_text())
	last_slot = 1
	_save_index()
