extends RefCounted
## 角色属性：基础 + 已分配属性点 + 装备 + 已学属性晶核 + 烙印。

const RuneCatalog = preload("res://scripts/items/rune_catalog.gd")
const CrystalCatalog = preload("res://scripts/items/crystal_catalog.gd")
const SkillCatalog = preload("res://scripts/skills/skill_catalog.gd")
const MindTable = preload("res://scripts/meta/mind_table.gd")

signal changed

const BASE_VITALITY := 10.0
const BASE_STRENGTH := 10.0
const BASE_AGI := 10.0
const BASE_INT := 10.0
const BASE_SPI := 10.0
const BASE_LUK := 10.0
const BASE_MAX_HP := 80.0
const HP_PER_VIT := 4.0
const PATK_PER_STR := 1.2
const BASE_PATK := 8.0
const BASE_PDEF := 2.0
const BASE_CARRY := 20.0
const CARRY_PER_VIT := 1.5

var vitality: float = BASE_VITALITY
var strength: float = BASE_STRENGTH
var agility: float = BASE_AGI
var intellect: float = BASE_INT
var spirit: float = BASE_SPI
var luck: float = BASE_LUK
var max_hp: float = BASE_MAX_HP
var patk: float = BASE_PATK
var pdef: float = BASE_PDEF
var crit: float = 0.0
var critdmg: float = 0.5
var carry_cap: float = BASE_CARRY
var agi_enabled: bool = true
var int_enabled: bool = true
var crit_enabled: bool = false
var critdmg_enabled: bool = false

var _brand: String = "iron"
var _equip: Dictionary = {"max_hp": 0.0, "defense": 0.0, "damage": 0.0}
var _learned: Dictionary = {}


func set_context(brand: String, equip_bonus: Dictionary, learned: Dictionary) -> void:
	_brand = brand
	_equip = equip_bonus
	_learned = learned
	recompute()


func recompute() -> void:
	vitality = BASE_VITALITY + float(MetaProgress.attr_value("vit"))
	strength = BASE_STRENGTH + float(MetaProgress.attr_value("str"))
	agility = BASE_AGI + float(MetaProgress.attr_value("agi"))
	intellect = BASE_INT + float(MetaProgress.attr_value("int"))
	spirit = BASE_SPI + float(MetaProgress.attr_value("spi"))
	luck = BASE_LUK + float(MetaProgress.attr_value("luk"))
	var bonus_hp := 0.0
	var bonus_patk := 0.0
	crit = 0.0 + agility * 0.002
	critdmg = 0.5
	crit_enabled = agility > BASE_AGI or false
	critdmg_enabled = false
	agi_enabled = true
	int_enabled = true

	for rune_id in _learned.keys():
		if not bool(_learned[rune_id]):
			continue
		var bonuses: Dictionary = {}
		if CrystalCatalog.has_id(str(rune_id)):
			bonuses = CrystalCatalog.stat_bonuses(str(rune_id))
		else:
			bonuses = RuneCatalog.stat_bonuses(str(rune_id))
		vitality += float(bonuses.get("vitality", 0.0))
		strength += float(bonuses.get("strength", 0.0))
		bonus_hp += float(bonuses.get("max_hp", 0.0))
		bonus_patk += float(bonuses.get("patk", 0.0))
		if bonuses.has("crit"):
			crit += float(bonuses.get("crit", 0.0))
			crit_enabled = true
		if bonuses.has("critdmg"):
			critdmg += float(bonuses.get("critdmg", 0.0))
			critdmg_enabled = true

	if crit > 0.0:
		crit_enabled = true

	var brand: Dictionary = MindTable.BRAND_STATS.get(_brand, MindTable.BRAND_STATS["iron"])
	var brand_dmg := float(brand.get("dmg", 1.0))
	var stance_rank := MetaProgress.skill_rank("sk_stance")
	var stance_pct := 0.0
	if stance_rank > 0:
		stance_pct = float(SkillCatalog.passive("sk_stance").get("patk_pct", 0.03)) * float(stance_rank)

	max_hp = BASE_MAX_HP + vitality * HP_PER_VIT + bonus_hp + float(_equip.get("max_hp", 0.0))
	patk = (BASE_PATK + strength * PATK_PER_STR + bonus_patk) * brand_dmg * (1.0 + float(_equip.get("damage", 0.0))) * (1.0 + stance_pct)
	pdef = BASE_PDEF + float(_equip.get("defense", 0.0)) + vitality * 0.15
	carry_cap = BASE_CARRY + vitality * CARRY_PER_VIT
	changed.emit()


func snapshot() -> Dictionary:
	return {
		"vitality": vitality,
		"strength": strength,
		"agility": agility,
		"intellect": intellect,
		"spirit": spirit,
		"luck": luck,
		"max_hp": max_hp,
		"patk": patk,
		"pdef": pdef,
		"crit": crit,
		"critdmg": critdmg,
		"carry_cap": carry_cap,
		"crit_enabled": crit_enabled,
		"critdmg_enabled": critdmg_enabled,
		"agi_enabled": agi_enabled,
		"int_enabled": int_enabled,
	}
