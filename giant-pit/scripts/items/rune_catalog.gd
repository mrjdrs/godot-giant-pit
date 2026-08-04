extends RefCounted
## 8 符文定义。

enum RuneKind { BODY, WEAPON }

const DEFS := {
	"tough": {
		"kind": RuneKind.BODY,
		"name_key": "rune.tough",
		"icon": "res://assets/runes/rune_tough.png",
		"max_rank": 3,
	},
	"swift": {
		"kind": RuneKind.BODY,
		"name_key": "rune.swift",
		"icon": "res://assets/runes/rune_swift.png",
		"max_rank": 3,
	},
	"slash": {
		"kind": RuneKind.BODY,
		"name_key": "rune.slash",
		"icon": "res://assets/runes/rune_slash.png",
		"max_rank": 3,
	},
	"sidestep": {
		"kind": RuneKind.BODY,
		"name_key": "rune.sidestep",
		"icon": "res://assets/runes/rune_sidestep.png",
		"max_rank": 3,
	},
	"edge": {
		"kind": RuneKind.WEAPON,
		"name_key": "rune.edge",
		"icon": "res://assets/runes/rune_edge.png",
		"max_rank": 3,
	},
	"reach": {
		"kind": RuneKind.WEAPON,
		"name_key": "rune.reach",
		"icon": "res://assets/runes/rune_reach.png",
		"max_rank": 3,
	},
	"burn": {
		"kind": RuneKind.WEAPON,
		"name_key": "rune.burn",
		"icon": "res://assets/runes/rune_burn.png",
		"max_rank": 3,
	},
	"quake": {
		"kind": RuneKind.WEAPON,
		"name_key": "rune.quake",
		"icon": "res://assets/runes/rune_quake.png",
		"max_rank": 3,
	},
}

const DROP_POOL := ["tough", "swift", "slash", "sidestep", "edge", "reach", "burn", "quake"]


static func display_name(rune_id: String) -> String:
	var def: Dictionary = DEFS.get(rune_id, {})
	if def.is_empty():
		return rune_id
	return Loc.t(str(def.get("name_key", rune_id)))


static func tier(_rune_id: String) -> int:
	return ItemTier.Tier.RARE


static func tier_label(rune_id: String) -> String:
	return ItemTier.display_name(tier(rune_id))


static func tier_color(_rune_id: String) -> Color:
	return ItemTier.color_for(tier(_rune_id))


static func display_with_tier(rune_id: String) -> String:
	return Loc.t("item.tier_name", [tier_label(rune_id), display_name(rune_id)])


static func is_body(rune_id: String) -> bool:
	var def: Dictionary = DEFS.get(rune_id, {})
	return int(def.get("kind", RuneKind.BODY)) == RuneKind.BODY
