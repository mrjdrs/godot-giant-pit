extends Node
class_name BiomeRules
## 生态法则运行时：潮腐 / 磁累 / 回声。

const ST = preload("res://scripts/pit/segment_types.gd")

signal reinforcement_requested(at: Vector2, biome: String)

var current_biome: String = ST.BIOME_MOSS
var _loud_cd: float = 0.0


func set_biome(biome: String) -> void:
	current_biome = biome


func _process(delta: float) -> void:
	if _loud_cd > 0.0:
		_loud_cd = maxf(_loud_cd - delta, 0.0)


func apply_to_player(player: Node, in_mud: bool, in_fog: bool) -> void:
	if player == null:
		return
	player.in_mud = false
	player.in_fog = false
	player.move_speed_mult = 1.0
	player.jump_mult = 1.0
	player.skill_cd_mult = 1.0
	match current_biome:
		ST.BIOME_MOSS:
			player.in_mud = in_mud
			player.in_fog = in_fog
		ST.BIOME_COPPER:
			var load_v: float = float(player.get("metal_load"))
			player.move_speed_mult = clampf(1.0 - load_v * 0.08, 0.55, 1.0)
			player.skill_cd_mult = 1.0 + load_v * 0.10
		ST.BIOME_ECHO:
			pass


func on_loud_skill(player: Node, _kind: String) -> void:
	if current_biome != ST.BIOME_ECHO:
		return
	if _loud_cd > 0.0:
		return
	_loud_cd = 8.0
	if player:
		reinforcement_requested.emit(player.global_position, current_biome)


func fog_aggro_mult(player: Node) -> float:
	if current_biome == ST.BIOME_MOSS and player != null and player.in_fog:
		return 0.45
	return 1.0
