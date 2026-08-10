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
		"region": "b",
		"count": 3,
		"reward_gold": 30,
		"reward_xp": 40,
		"reward_mat": {"mind_shard": 1},
	},
	"kill_scale": {
		"type": TYPE_KILL,
		"name_key": "quest.kill_scale.name",
		"desc_key": "quest.kill_scale.desc",
		"enemy_id": "a_scale",
		"region": "a",
		"count": 2,
		"reward_gold": 40,
		"reward_xp": 50,
		"reward_mat": {"mind_shard": 2},
	},
	"rescue_beacon": {
		"type": TYPE_RESCUE,
		"name_key": "quest.rescue.name",
		"desc_key": "quest.rescue.desc",
		"region": "c",
		"reward_gold": 35,
		"reward_xp": 45,
		"reward_mat": {"mind_core": 1},
	},
}


static func all_ids() -> Array:
	return QUESTS.keys()


static func get_def(quest_id: String) -> Dictionary:
	return QUESTS.get(quest_id, {})


## 局内进度：{name, desc, current, target, progress_text, complete, reward}
static func run_progress(quest_id: String, inventory_slots: Array, kill_scale: int, rescue_done: bool) -> Dictionary:
	if quest_id == "" or not QUESTS.has(quest_id):
		return {}
	var def: Dictionary = get_def(quest_id)
	var current := 0
	var target := 1
	match str(def.get("type")):
		TYPE_GATHER:
			target = int(def.get("count", 1))
			var need_id := str(def.get("mat_id"))
			for entry in inventory_slots:
				if entry.get("type") == "mat" and str(entry.get("id")) == need_id:
					current += int(entry.get("count", 0))
			current = mini(current, target)
		TYPE_KILL:
			target = int(def.get("count", 1))
			current = mini(kill_scale, target)
		TYPE_RESCUE:
			target = 1
			current = 1 if rescue_done else 0
	var progress_text := "%d/%d" % [current, target]
	return {
		"id": quest_id,
		"name": Loc.t(str(def.get("name_key", ""))),
		"desc": Loc.t(str(def.get("desc_key", ""))),
		"current": current,
		"target": target,
		"progress_text": progress_text,
		"complete": current >= target,
		"reward_gold": int(def.get("reward_gold", 0)),
		"reward_mat": def.get("reward_mat", {}),
	}
