extends RefCounted
class_name ErosionSystem
## 深渊侵蚀：时间推进分档，可调表。

signal tier_changed(tier: int)
signal value_changed(value: float, max_value: float)

## 秒 → 侵蚀值增速；满条约对应一局中后段压力
const MAX_VALUE := 100.0
const RATES := {
	0: 1.2, ## 甜头档：轻加速采集？由 floor 读 tier
	1: 1.6,
	2: 2.2,
	3: 3.0,
}

## 阈值
const TIER_THRESHOLDS := [0.0, 25.0, 50.0, 75.0]

var value: float = 0.0
var tier: int = 0
var paused: bool = false


func reset() -> void:
	value = 0.0
	tier = 0
	paused = false
	value_changed.emit(value, MAX_VALUE)
	tier_changed.emit(tier)


func tick(delta: float) -> void:
	if paused:
		return
	var rate: float = float(RATES.get(tier, 2.0))
	value = minf(value + rate * delta, MAX_VALUE)
	var new_tier := _calc_tier()
	value_changed.emit(value, MAX_VALUE)
	if new_tier != tier:
		tier = new_tier
		tier_changed.emit(tier)


func _calc_tier() -> int:
	var t := 0
	for i in TIER_THRESHOLDS.size():
		if value >= float(TIER_THRESHOLDS[i]):
			t = i
	return t


func damage_mult() -> float:
	## 低档甜头：轻微增伤；高档惩罚
	match tier:
		0:
			return 1.05
		1:
			return 1.0
		2:
			return 0.95
		_:
			return 0.9


func move_mult() -> float:
	match tier:
		2:
			return 0.92
		3:
			return 0.85
		_:
			return 1.0


func skill_slots_locked() -> int:
	## 高档锁定技能槽数量（由 skill book / player 读取）
	if tier >= 3:
		return 1
	return 0


func weight_mult() -> float:
	if tier >= 2:
		return 1.15
	return 1.0


func apply_dot(player: Node, delta: float) -> void:
	if tier < 3 or player == null or not player.has_method("take_damage"):
		return
	## 轻微持续伤害
	if fmod(Time.get_ticks_msec() / 1000.0, 2.0) < delta:
		player.take_damage(1.5, player.global_position)
