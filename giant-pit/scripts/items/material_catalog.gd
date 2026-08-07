extends RefCounted
## 材料目录。

const MATERIALS := {
	"glow_moss": {
		"name_key": "mat.glow_moss",
		"icon": "res://assets/materials/mat_glow_moss.png",
		"stack": 99,
		"tier": ItemTier.Tier.COMMON,
	},
	"bitter_root": {
		"name_key": "mat.bitter_root",
		"icon": "res://assets/materials/mat_bitter_root.png",
		"stack": 99,
		"tier": ItemTier.Tier.COMMON,
	},
	"deep_red_ore": {
		"name_key": "mat.deep_red_ore",
		"icon": "res://assets/materials/mat_deep_red_ore.png",
		"stack": 99,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"copper_vein": {
		"name_key": "mat.copper_vein",
		"icon": "res://assets/materials/mat_copper_vein.png",
		"stack": 99,
		"tier": ItemTier.Tier.COMMON,
	},
	"mind_shard": {
		"name_key": "mat.mind_shard",
		"icon": "res://assets/materials/mat_mind_shard.png",
		"stack": 99,
		"tier": ItemTier.Tier.RARE,
	},
	"mind_core": {
		"name_key": "mat.mind_core",
		"icon": "res://assets/materials/mat_mind_core.png",
		"stack": 99,
		"tier": ItemTier.Tier.LEGENDARY,
	},
	"beast_scale": {
		"name_key": "mat.beast_scale",
		"icon": "res://assets/materials/mat_beast_scale.png",
		"stack": 99,
		"tier": ItemTier.Tier.COMMON,
	},
	"chitin_plate": {
		"name_key": "mat.chitin_plate",
		"icon": "res://assets/materials/mat_chitin_plate.png",
		"stack": 99,
		"tier": ItemTier.Tier.COMMON,
	},
	"alchem_slag": {
		"name_key": "mat.alchem_slag",
		"icon": "res://assets/materials/mat_alchem_slag.png",
		"stack": 99,
		"tier": ItemTier.Tier.COMMON,
	},
	"ember_gland": {
		"name_key": "mat.ember_gland",
		"icon": "res://assets/materials/mat_ember_gland.png",
		"stack": 99,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"mire_pearl": {
		"name_key": "mat.mire_pearl",
		"icon": "res://assets/materials/mat_mire_pearl.png",
		"stack": 99,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"fold_copper": {
		"name_key": "mat.fold_copper",
		"icon": "res://assets/materials/mat_fold_copper.png",
		"stack": 99,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"blind_wick": {
		"name_key": "mat.blind_wick",
		"icon": "res://assets/materials/mat_blind_wick.png",
		"stack": 99,
		"tier": ItemTier.Tier.UNCOMMON,
	},
	"lamp_oil_crystal": {
		"name_key": "mat.lamp_oil_crystal",
		"icon": "res://assets/materials/mat_lamp_oil_crystal.png",
		"stack": 99,
		"tier": ItemTier.Tier.RARE,
	},
	"mat_whirl_edge": {
		"name_key": "mat.whirl_edge",
		"icon": "res://assets/materials/mat_ember_gland.png",
		"stack": 99,
		"tier": ItemTier.Tier.RARE,
	},
	"mat_iron_guard": {
		"name_key": "mat.iron_guard",
		"icon": "res://assets/materials/mat_chitin_plate.png",
		"stack": 99,
		"tier": ItemTier.Tier.RARE,
	},
}


static func display_name(mat_id: String) -> String:
	var def: Dictionary = MATERIALS.get(mat_id, {})
	if def.is_empty():
		return mat_id
	return Loc.t(str(def.get("name_key", mat_id)))


static func tier(mat_id: String) -> int:
	var def: Dictionary = MATERIALS.get(mat_id, {})
	return ItemTier.clamp_tier(int(def.get("tier", ItemTier.Tier.COMMON)))


static func tier_label(mat_id: String) -> String:
	return ItemTier.display_name(tier(mat_id))


static func tier_color(mat_id: String) -> Color:
	return ItemTier.color_for(tier(mat_id))


static func display_with_tier(mat_id: String) -> String:
	return Loc.t("item.tier_name", [tier_label(mat_id), display_name(mat_id)])


static func sell_price(mat_id: String) -> int:
	match tier(mat_id):
		ItemTier.Tier.UNCOMMON:
			return 12
		ItemTier.Tier.RARE:
			return 25
		ItemTier.Tier.EPIC:
			return 40
		ItemTier.Tier.LEGENDARY:
			return 50
		_:
			return 5
