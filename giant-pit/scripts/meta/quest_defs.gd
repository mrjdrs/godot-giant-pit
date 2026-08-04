extends RefCounted
## 三类委托模板。

const TYPE_GATHER := "gather"
const TYPE_KILL := "kill"
const TYPE_RESCUE := "rescue"

const QUESTS := {
	"gather_ore": {
		"type": TYPE_GATHER,
		"name_key": "quest.gather_ore.name",
		"desc_key": "quest.gather_ore.desc",
		"mat_id": "deep_red_ore",
		"count": 3,
		"reward_gold": 30,
		"reward_mat": {"mind_shard": 1},
	},
	"kill_scale": {
		"type": TYPE_KILL,
		"name_key": "quest.kill_scale.name",
		"desc_key": "quest.kill_scale.desc",
		"enemy_id": "scale_rock",
		"count": 2,
		"reward_gold": 40,
		"reward_mat": {"mind_shard": 2},
	},
	"rescue_beacon": {
		"type": TYPE_RESCUE,
		"name_key": "quest.rescue.name",
		"desc_key": "quest.rescue.desc",
		"reward_gold": 35,
		"reward_mat": {"mind_core": 1},
	},
}


static func all_ids() -> Array:
	return QUESTS.keys()


static func get_def(quest_id: String) -> Dictionary:
	return QUESTS.get(quest_id, {})
