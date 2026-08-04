extends RefCounted
## 道具品阶：颜色与显示名。

class_name ItemTier

enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const NAME_KEYS := {
	Tier.COMMON: "tier.common",
	Tier.UNCOMMON: "tier.uncommon",
	Tier.RARE: "tier.rare",
	Tier.EPIC: "tier.epic",
	Tier.LEGENDARY: "tier.legendary",
}

const COLORS := {
	Tier.COMMON: Color(0.82, 0.82, 0.78, 1),
	Tier.UNCOMMON: Color(0.45, 0.88, 0.52, 1),
	Tier.RARE: Color(0.42, 0.68, 1.0, 1),
	Tier.EPIC: Color(0.78, 0.48, 1.0, 1),
	Tier.LEGENDARY: Color(1.0, 0.78, 0.28, 1),
}


static func display_name(tier: int) -> String:
	var key: String = str(NAME_KEYS.get(tier, NAME_KEYS[Tier.COMMON]))
	return Loc.t(key) if Loc.has_key(key) else key


static func color_for(tier: int) -> Color:
	return COLORS.get(tier, COLORS[Tier.COMMON])


static func clamp_tier(tier: int) -> int:
	return clampi(tier, Tier.COMMON, Tier.LEGENDARY)
