extends RefCounted
## 轻量异常层：灼烧 / 流血 / 减速 / 破甲 / 减攻 / 祝福。挂在敌人、木桩或玩家上 tick。

const KIND_BURN := "burn"
const KIND_CHILL := "chill"
const KIND_CORRODE := "corrode"
const KIND_WEAKEN := "weaken"
const KIND_BLESS := "bless"
const KIND_FREEZE := "freeze"
const KIND_BLEED := "bleed"

var _burn_t: float = 0.0
var _burn_dps: float = 0.0
var _bleed_t: float = 0.0
var _bleed_dps: float = 0.0
var _bleed_stacks: int = 0
var _bleed_max_stacks: int = 1
var _bleed_source = null
var _chill_t: float = 0.0
var _chill_slow: float = 0.0
var _chill_stacks: int = 0
var _freeze_t: float = 0.0
var _corrode_t: float = 0.0
var _corrode_amp: float = 0.0 ## 受伤加深倍率加成（0.2 = +20%）
var _corrode_pdef: float = 0.0 ## 临时减物防
var _weaken_t: float = 0.0
var _weaken_cut: float = 0.0 ## 输出削减 0~1
var _bless_t: float = 0.0
var _bless_shield: float = 0.0
var _bless_hps: float = 0.0


func clear_all() -> void:
	_burn_t = 0.0
	_burn_dps = 0.0
	_bleed_t = 0.0
	_bleed_dps = 0.0
	_bleed_stacks = 0
	_bleed_source = null
	_chill_t = 0.0
	_chill_slow = 0.0
	_chill_stacks = 0
	_freeze_t = 0.0
	_corrode_t = 0.0
	_corrode_amp = 0.0
	_corrode_pdef = 0.0
	_weaken_t = 0.0
	_weaken_cut = 0.0
	_bless_t = 0.0
	_bless_shield = 0.0
	_bless_hps = 0.0


func apply(kind: String, payload: Dictionary = {}) -> void:
	match kind:
		KIND_BURN:
			_burn_dps = maxf(_burn_dps, float(payload.get("dps", 4.0)))
			_burn_t = maxf(_burn_t, float(payload.get("duration", 3.0)))
		KIND_BLEED:
			_bleed_max_stacks = maxi(int(payload.get("max_stacks", 1)), 1)
			_bleed_stacks = mini(_bleed_stacks + int(payload.get("stacks", 1)), _bleed_max_stacks)
			_bleed_dps = maxf(_bleed_dps, float(payload.get("dps", 4.0)))
			_bleed_t = maxf(_bleed_t, float(payload.get("duration", 3.0)))
			if payload.has("source"):
				_bleed_source = payload["source"]
		KIND_CHILL:
			var stacks_add := int(payload.get("stacks", 1))
			_chill_stacks = mini(_chill_stacks + stacks_add, int(payload.get("max_stacks", 3)))
			_chill_slow = maxf(_chill_slow, float(payload.get("slow", 0.25)))
			_chill_t = maxf(_chill_t, float(payload.get("duration", 2.5)))
			if _chill_stacks >= int(payload.get("freeze_at", 3)):
				_freeze_t = maxf(_freeze_t, float(payload.get("freeze_duration", 0.6)))
				_chill_stacks = 0
		KIND_FREEZE:
			_freeze_t = maxf(_freeze_t, float(payload.get("duration", 0.8)))
		KIND_CORRODE:
			_corrode_amp = maxf(_corrode_amp, float(payload.get("amp", 0.2)))
			_corrode_pdef = maxf(_corrode_pdef, float(payload.get("pdef_cut", 0.0)))
			_corrode_t = maxf(_corrode_t, float(payload.get("duration", 4.0)))
		KIND_WEAKEN:
			_weaken_cut = maxf(_weaken_cut, float(payload.get("cut", 0.2)))
			_weaken_t = maxf(_weaken_t, float(payload.get("duration", 4.0)))
		KIND_BLESS:
			_bless_shield = maxf(_bless_shield, float(payload.get("shield", 0.0)))
			_bless_hps = maxf(_bless_hps, float(payload.get("hps", 0.0)))
			_bless_t = maxf(_bless_t, float(payload.get("duration", 3.0)))
			if payload.has("heal"):
				## 立即治疗由宿主读 payload；这里只存持续
				pass
		_:
			pass


func tick(delta: float) -> Dictionary:
	## 返回本帧应施加的效果：dot_damage, heal, move_mult, frozen, damage_taken_mult, outgoing_mult, shield_absorb
	var out := {
		"dot_damage": 0.0,
		"dot_source": null,
		"heal": 0.0,
		"move_mult": 1.0,
		"frozen": false,
		"damage_taken_mult": 1.0,
		"outgoing_mult": 1.0,
		"pdef_cut": 0.0,
		"shield": 0.0,
	}
	if _burn_t > 0.0:
		_burn_t -= delta
		out["dot_damage"] = _burn_dps * delta
		if _burn_t <= 0.0:
			_burn_dps = 0.0
	if _bleed_t > 0.0:
		_bleed_t -= delta
		out["dot_damage"] = float(out["dot_damage"]) + _bleed_dps * float(_bleed_stacks) * delta
		out["dot_source"] = _bleed_source
		if _bleed_t <= 0.0:
			_bleed_dps = 0.0
			_bleed_stacks = 0
			_bleed_source = null
	if _freeze_t > 0.0:
		_freeze_t -= delta
		out["frozen"] = true
		out["move_mult"] = 0.0
	elif _chill_t > 0.0:
		_chill_t -= delta
		out["move_mult"] = clampf(1.0 - _chill_slow, 0.15, 1.0)
		if _chill_t <= 0.0:
			_chill_slow = 0.0
			_chill_stacks = 0
	if _corrode_t > 0.0:
		_corrode_t -= delta
		out["damage_taken_mult"] = 1.0 + _corrode_amp
		out["pdef_cut"] = _corrode_pdef
		if _corrode_t <= 0.0:
			_corrode_amp = 0.0
			_corrode_pdef = 0.0
	if _weaken_t > 0.0:
		_weaken_t -= delta
		out["outgoing_mult"] = clampf(1.0 - _weaken_cut, 0.1, 1.0)
		if _weaken_t <= 0.0:
			_weaken_cut = 0.0
	if _bless_t > 0.0:
		_bless_t -= delta
		out["heal"] = _bless_hps * delta
		out["shield"] = _bless_shield
		if _bless_t <= 0.0:
			_bless_hps = 0.0
			_bless_shield = 0.0
	return out


func absorb_damage(amount: float) -> float:
	## 护盾吸收，返回剩余伤害
	if _bless_shield <= 0.0 or amount <= 0.0:
		return amount
	var used := minf(_bless_shield, amount)
	_bless_shield -= used
	return amount - used


func has_burn() -> bool:
	return _burn_t > 0.0


func damage_taken_mult() -> float:
	return 1.0 + (_corrode_amp if _corrode_t > 0.0 else 0.0)


func pdef_cut() -> float:
	return _corrode_pdef if _corrode_t > 0.0 else 0.0


func outgoing_mult() -> float:
	return clampf(1.0 - _weaken_cut, 0.1, 1.0) if _weaken_t > 0.0 else 1.0


func move_mult() -> float:
	if _freeze_t > 0.0:
		return 0.0
	if _chill_t > 0.0:
		return clampf(1.0 - _chill_slow, 0.15, 1.0)
	return 1.0


func visual_tint() -> Color:
	if _freeze_t > 0.0:
		return Color(0.65, 0.88, 1.0)
	if _chill_t > 0.0:
		return Color(0.78, 0.92, 1.0)
	if _burn_t > 0.0:
		return Color(1.0, 0.72, 0.55)
	if _bleed_t > 0.0:
		return Color(0.82, 0.22, 0.18)
	if _corrode_t > 0.0:
		return Color(0.75, 1.0, 0.55)
	if _weaken_t > 0.0:
		return Color(0.72, 0.55, 0.95)
	return Color.WHITE
