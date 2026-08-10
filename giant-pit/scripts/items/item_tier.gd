extends RefCounted
## 品质（稀有度）× 品阶（力量带）。品质 6 档；品阶 1=九品 … 9=一品。

class_name ItemTier

enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }

const NAME_KEYS := {
	Tier.COMMON: "tier.common",
	Tier.UNCOMMON: "tier.uncommon",
	Tier.RARE: "tier.rare",
	Tier.EPIC: "tier.epic",
	Tier.LEGENDARY: "tier.legendary",
	Tier.MYTHIC: "tier.mythic",
}

const COLORS := {
	Tier.COMMON: Color(0.82, 0.82, 0.78, 1),
	Tier.UNCOMMON: Color(0.45, 0.88, 0.52, 1),
	Tier.RARE: Color(0.42, 0.68, 1.0, 1),
	Tier.EPIC: Color(0.78, 0.48, 1.0, 1),
	Tier.LEGENDARY: Color(1.0, 0.78, 0.28, 1),
	Tier.MYTHIC: Color(1.0, 0.35, 0.29, 1),
}


static func display_name(tier: int) -> String:
	var key: String = str(NAME_KEYS.get(tier, NAME_KEYS[Tier.COMMON]))
	return Loc.t(key) if Loc.has_key(key) else key


static func color_for(tier: int) -> Color:
	return COLORS.get(tier, COLORS[Tier.COMMON])


static func clamp_tier(tier: int) -> int:
	return clampi(tier, Tier.COMMON, Tier.MYTHIC)


static func clamp_grade(grade: int) -> int:
	return clampi(grade, 1, 9)


static func grade_display(grade: int) -> String:
	var g := clamp_grade(grade)
	var key := "grade.%d" % g
	return Loc.t(key) if Loc.has_key(key) else key


static func grade_scale(grade: int) -> float:
	## 九品 0.90 → 一品 1.30
	return 0.85 + 0.05 * float(clamp_grade(grade))


static func quality_scale(tier: int) -> float:
	return 1.0 + 0.04 * float(clamp_tier(tier))
