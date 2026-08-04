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


func grant_special_mind() -> void:
	special_mind = true


func activate_warp(warp_id: String) -> void:
	if warp_id == "":
		return
	active_warps_this_run[warp_id] = true
	MetaProgress.unlock_warp(warp_id)


func is_warp_active(warp_id: String) -> bool:
	return bool(active_warps_this_run.get(warp_id, false))


func brand_stats() -> Dictionary:
	return MindTable.BRAND_STATS.get(brand_quality, MindTable.BRAND_STATS["iron"])
