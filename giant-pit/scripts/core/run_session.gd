extends Node
## 一局深潜会话（不持久化；进坑时由枢纽写入）。

const MindTable = preload("res://scripts/meta/mind_table.gd")

signal floor_changed

var active: bool = false
var floor_index: int = 1
var brand_quality: String = "iron"
var kill_scale: int = 0
var rescue_done: bool = false
var quest_id_snapshot: String = ""

## 跨层保留的局内状态（序列化简表）
var carried_inventory: Array = []
var carried_runes_body: Dictionary = {}
var carried_runes_weapon: Dictionary = {}
var carried_hp_ratio: float = 1.0


func begin_run() -> void:
	active = true
	floor_index = 1
	kill_scale = 0
	rescue_done = false
	quest_id_snapshot = MetaProgress.active_quest_id
	carried_inventory.clear()
	carried_runes_body.clear()
	carried_runes_weapon.clear()
	carried_hp_ratio = 1.0
	brand_quality = MindTable.roll_brand(MetaProgress.mind_level)
	floor_changed.emit()


func clear() -> void:
	active = false
	floor_index = 1
	brand_quality = "iron"
	kill_scale = 0
	rescue_done = false
	quest_id_snapshot = ""
	carried_inventory.clear()
	carried_runes_body.clear()
	carried_runes_weapon.clear()


func snapshot_player(player: Node) -> void:
	if player == null:
		return
	carried_inventory = []
	for e in player.inventory.slots:
		carried_inventory.append(e.duplicate(true))
	carried_runes_body = player.runes.body.duplicate()
	carried_runes_weapon = player.runes.weapon.duplicate()
	if player.max_hp > 0.0:
		carried_hp_ratio = player.hp / player.max_hp


func apply_to_player(player: Node) -> void:
	if player == null:
		return
	player.inventory.clear()
	for e in carried_inventory:
		player.inventory.slots.append(e.duplicate(true))
	player.inventory.changed.emit()
	player.runes.body = carried_runes_body.duplicate()
	player.runes.weapon = carried_runes_weapon.duplicate()
	player.runes.changed.emit()


func go_next_floor() -> bool:
	if floor_index >= 4:
		return false
	floor_index += 1
	floor_changed.emit()
	return true


func brand_stats() -> Dictionary:
	return MindTable.BRAND_STATS.get(brand_quality, MindTable.BRAND_STATS["iron"])
