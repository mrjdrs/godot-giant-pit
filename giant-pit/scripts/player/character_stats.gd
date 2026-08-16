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
const MATK_PER_INT := 1.4
const BASE_PATK := 8.0
const BASE_MATK := 6.0
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
var matk: float = BASE_MATK
var pdef: float = BASE_PDEF
var crit: float = 0.0
var critdmg: float = 0.5
var carry_cap: float = BASE_CARRY
var agi_enabled: bool = true
var int_enabled: bool = true
var crit_enabled: bool = false
var critdmg_enabled: bool = false
var aoe_mult: float = 1.0
var bolt_mult: float = 1.0
var hp_regen: float = 0.0
var imprint_lifesteal: float = 0.0
var move_mult: float = 1.0
var imprint_dr: float = 0.0

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
	var stance_pct := 0.0

	aoe_mult = 1.0
	bolt_mult = 1.0
	hp_regen = 0.0
	imprint_lifesteal = 0.0
	move_mult = 1.0
	imprint_dr = 0.0
	var hp_mult := 1.0
	var pdef_bonus := 0.0
	var fam := SkillCatalog.normalize_imprint(MetaProgress.imprint_family)
	match fam:
		SkillCatalog.FAMILY_COLD:
			strength += 2.0
			vitality += 2.0
			hp_mult = 1.25
			pdef_bonus = 2.0
			hp_regen = 2.0
			imprint_lifesteal = 0.04
			imprint_dr = 0.08
		SkillCatalog.FAMILY_HOT:
			agility += 2.0
			hp_mult = 0.80
			pdef_bonus = -1.0
			move_mult = 1.12
			bolt_mult = 1.12
			aoe_mult = 0.88
		SkillCatalog.FAMILY_MAGE:
			intellect += 2.0
			hp_mult = 0.80
			pdef_bonus = -1.0
			aoe_mult = 1.15
			bolt_mult = 0.90
		SkillCatalog.FAMILY_AFFINITY:
			spirit += 2.0
			hp_mult = 0.80
			pdef_bonus = -1.0
			bolt_mult = 0.85

	var grove_r := MetaProgress.skill_rank("nat_grove")
	if grove_r > 0:
		hp_regen += float(SkillCatalog.passive("nat_grove").get("hp_regen", 0.4)) * float(grove_r)
	var veteran_r := MetaProgress.skill_rank("ws_passive_veteran")
	if veteran_r > 0:
		var veteran: Dictionary = SkillCatalog.passive("ws_passive_veteran")
		var stat_bonus := float(veteran.get("str_bonus", 3)) + float(veteran.get("stat_per_rank", 1)) * float(veteran_r - 1)
		strength += stat_bonus
		vitality += stat_bonus
		hp_mult *= 1.0 + float(veteran.get("max_hp_bonus", 0.05)) + float(veteran.get("max_hp_per_rank", 0.01)) * float(veteran_r - 1)

	max_hp = (BASE_MAX_HP + vitality * HP_PER_VIT + bonus_hp + float(_equip.get("max_hp", 0.0))) * hp_mult
	patk = (BASE_PATK + strength * PATK_PER_STR + bonus_patk) * brand_dmg * (1.0 + float(_equip.get("damage", 0.0))) * (1.0 + stance_pct)
	matk = (BASE_MATK + intellect * MATK_PER_INT) * brand_dmg * (1.0 + float(_equip.get("damage", 0.0)) * 0.5)
	pdef = BASE_PDEF + float(_equip.get("defense", 0.0)) + vitality * 0.15 + pdef_bonus
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
		"matk": matk,
		"pdef": pdef,
		"crit": crit,
		"critdmg": critdmg,
		"carry_cap": carry_cap,
		"crit_enabled": crit_enabled,
		"critdmg_enabled": critdmg_enabled,
		"agi_enabled": agi_enabled,
		"int_enabled": int_enabled,
	}
