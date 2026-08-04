extends RefCounted
## 材料目录。

const MATERIALS := {
	"glow_moss": {
		"name_key": "mat.glow_moss",
		"icon": "res://assets/materials/mat_glow_moss.png",
		"stack": 99,
	},
	"bitter_root": {
		"name_key": "mat.bitter_root",
		"icon": "res://assets/materials/mat_bitter_root.png",
		"stack": 99,
	},
	"deep_red_ore": {
		"name_key": "mat.deep_red_ore",
		"icon": "res://assets/materials/mat_deep_red_ore.png",
		"stack": 99,
	},
	"copper_vein": {
		"name_key": "mat.copper_vein",
		"icon": "res://assets/materials/mat_copper_vein.png",
		"stack": 99,
	},
	"mind_shard": {
		"name_key": "mat.mind_shard",
		"icon": "res://assets/materials/mat_mind_shard.png",
		"stack": 99,
	},
	"mind_core": {
		"name_key": "mat.mind_core",
		"icon": "res://assets/materials/mat_mind_core.png",
		"stack": 99,
	},
	"beast_scale": {
		"name_key": "mat.beast_scale",
		"icon": "res://assets/materials/mat_beast_scale.png",
		"stack": 99,
	},
	"chitin_plate": {
		"name_key": "mat.chitin_plate",
		"icon": "res://assets/materials/mat_chitin_plate.png",
		"stack": 99,
	},
	"alchem_slag": {
		"name_key": "mat.alchem_slag",
		"icon": "res://assets/materials/mat_alchem_slag.png",
		"stack": 99,
	},
	"ember_gland": {
		"name_key": "mat.ember_gland",
		"icon": "res://assets/materials/mat_ember_gland.png",
		"stack": 99,
	},
}


static func display_name(mat_id: String) -> String:
	var def: Dictionary = MATERIALS.get(mat_id, {})
	if def.is_empty():
		return mat_id
	return Loc.t(str(def.get("name_key", mat_id)))
