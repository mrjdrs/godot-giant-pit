extends Node
## 一局深潜会话（不持久化；进坑时由枢纽写入）。

const MindTable = preload("res://scripts/meta/mind_table.gd")

signal floor_changed

var active: bool = false
var floor_index: int = 1 ## MVP 固定第 1 层
var brand_quality: String = "iron"
var kill_scale: int = 0
var rescue_done: bool = false
var quest_id_snapshot: String = ""
var special_mind: bool = false ## 层 BOSS 特殊念力（不占背包）
var spawn_warp_id: String = "" ## "" = 默认出生；warp_a/b/c
var active_warps_this_run: Dictionary = {} ## warp_id -> true（本局已激活）
var floor_seed: int = 0
var explored_chunks: Dictionary = {}
var elite_a_dead: bool = false
var secret_chest_looted: bool = false
var secret_special_dead: bool = false
var pit_return_pos: Vector2 = Vector2.ZERO
var erosion_value: float = 0.0
var player_hp: float = -1.0
var inventory_snapshot: Array = []
var inventory_extra_slots: int = 0
var returning_from_secret: bool = false
var erosion_ward_active: bool = false


func begin_run(spawn_id: String = "") -> void:
	active = true
	floor_index = 1
	kill_scale = 0
	rescue_done = false
	special_mind = false
	spawn_warp_id = spawn_id
	active_warps_this_run.clear()
	## 跨局已解锁的传送点，本局开局即视为可用（仍需本局激活才可互传？策划：跨局记住已激活；本局未激活则本局不可用）
	## 解读：跨局记住 → 入坑可选出生；局内互传需本局击杀看守激活。出生点若选已解锁 warp，开局即激活该点。
	if spawn_id != "" and MetaProgress.is_warp_unlocked(spawn_id):
		active_warps_this_run[spawn_id] = true
	quest_id_snapshot = MetaProgress.active_quest_id
	brand_quality = MindTable.roll_brand(MetaProgress.mind_level)
	floor_seed = randi()
	if floor_seed == 0:
		floor_seed = 1
	explored_chunks.clear()
	elite_a_dead = false
	secret_chest_looted = false
	secret_special_dead = false
	pit_return_pos = Vector2.ZERO
	erosion_value = 0.0
	player_hp = -1.0
	inventory_snapshot.clear()
	inventory_extra_slots = 0
	returning_from_secret = false
	erosion_ward_active = false
	floor_changed.emit()


func clear() -> void:
	active = false
	floor_index = 1
	brand_quality = "iron"
	kill_scale = 0
	rescue_done = false
	quest_id_snapshot = ""
	special_mind = false
	spawn_warp_id = ""
	active_warps_this_run.clear()
	floor_seed = 0
	explored_chunks.clear()
	elite_a_dead = false
	secret_chest_looted = false
	secret_special_dead = false
	pit_return_pos = Vector2.ZERO
	erosion_value = 0.0
	player_hp = -1.0
	inventory_snapshot.clear()
	inventory_extra_slots = 0
	returning_from_secret = false
	erosion_ward_active = false


func grant_special_mind() -> void:
	special_mind = true


func activate_warp(warp_id: String) -> void:
	if warp_id == "":
		return
	active_warps_this_run[warp_id] = true
	MetaProgress.unlock_warp(warp_id)


func is_warp_active(warp_id: String) -> bool:
	return bool(active_warps_this_run.get(warp_id, false))


func erosion_rate_mult() -> float:
	return 0.5 if erosion_ward_active else 1.0


func snapshot_explorer(p: Node, explored: Dictionary, elite_dead: bool, erosion_v: float, update_return_pos: bool = true) -> void:
	if p == null:
		return
	if update_return_pos:
		pit_return_pos = p.global_position
	explored_chunks = explored.duplicate()
	elite_a_dead = elite_dead
	erosion_value = erosion_v
	player_hp = float(p.hp)
	if p.inventory != null:
		inventory_snapshot = p.inventory.slots.duplicate(true)
		inventory_extra_slots = int(p.inventory.extra_slots)


func restore_explorer(p: Node) -> void:
	if p == null:
		return
	if player_hp > 0.0:
		p.hp = minf(player_hp, float(p.max_hp))
	if p.inventory != null:
		p.inventory.slots = inventory_snapshot.duplicate(true)
		p.inventory.extra_slots = inventory_extra_slots
		p.inventory.changed.emit()


func brand_stats() -> Dictionary:
	return MindTable.BRAND_STATS.get(brand_quality, MindTable.BRAND_STATS["iron"])
