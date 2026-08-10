extends RefCounted
## 特殊道具（金币券 / 扩容 / 药剂等）。

const ITEMS := {
	"item_paper_note": {
		"name_key": "item.paper_note",
		"icon": "res://assets/ui/icons/bag/item_paper_note.png",
		"stack": 99,
		"weight": 0.2,
		"face_value": 100,
		"desc_key": "item.paper_note.desc",
	},
	"item_bag_expand": {
		"name_key": "item.bag_expand",
		"icon": "res://assets/ui/icons/bag/item_bag_expand.png",
		"stack": 5,
		"weight": 1.0,
		"usable": true,
		"desc_key": "item.bag_expand.desc",
	},
	"item_mind_potion": {
		"name_key": "item.mind_potion",
		"icon": "res://assets/ui/icons/bag/item_mind_potion.png",
		"stack": 10,
		"weight": 0.5,
		"usable": true,
		"mind_restore": 30,
		"desc_key": "item.mind_potion.desc",
	},
	"item_erosion_salve": {
		"name_key": "item.erosion_salve",
		"icon": "res://assets/ui/icons/bag/item_mind_potion.png",
		"stack": 10,
		"weight": 0.4,
		"usable": true,
		"erosion_heal": 25,
		"desc_key": "item.erosion_salve.desc",
	},
	"item_erosion_ward": {
		"name_key": "item.erosion_ward",
		"icon": "res://assets/ui/icons/bag/item_bag_expand.png",
		"stack": 5,
		"weight": 0.3,
		"usable": true,
		"desc_key": "item.erosion_ward.desc",
	},
}


static func display_name(item_id: String) -> String:
	var def: Dictionary = ITEMS.get(item_id, {})
	if def.is_empty():
		return item_id
	return Loc.t(str(def.get("name_key", item_id)))


static func weight(item_id: String) -> float:
	var def: Dictionary = ITEMS.get(item_id, {})
	return float(def.get("weight", 1.0))


static func icon_path(item_id: String) -> String:
	var def: Dictionary = ITEMS.get(item_id, {})
	return str(def.get("icon", ""))


static func is_usable(item_id: String) -> bool:
	var def: Dictionary = ITEMS.get(item_id, {})
	return bool(def.get("usable", false))
