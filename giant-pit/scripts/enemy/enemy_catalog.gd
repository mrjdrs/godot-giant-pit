extends RefCounted
## 敌人显示名目录。

class_name EnemyCatalog

const NAME_KEYS := {
	"a_moss_grub": "enemy.a_moss_grub",
	"a_spore": "enemy.a_spore",
	"a_scale": "enemy.a_scale",
	"b_mite": "enemy.b_mite",
	"b_beetle": "enemy.b_beetle",
	"b_slag": "enemy.b_slag",
	"c_wisp": "enemy.c_wisp",
	"c_grub": "enemy.c_grub",
	"c_shell": "enemy.c_shell",
	"elite_a": "enemy.elite_a",
	"elite_b": "enemy.elite_b",
	"elite_c": "enemy.elite_c",
	"special_a": "enemy.special_a",
	"guard_a": "enemy.guard_a",
	"guard_b": "enemy.guard_b",
	"guard_c": "enemy.guard_c",
	"boss_floor1": "enemy.boss_floor1",
	"side_melee": "enemy.side_melee",
	"side_ranged": "enemy.side_ranged",
	"side_flyer": "enemy.side_flyer",
	"side_elite": "enemy.side_elite",
	"side_boss": "enemy.side_boss",
	"floor_boss": "enemy.side_boss",
}


static func display_name(enemy_id: String) -> String:
	var key: String = str(NAME_KEYS.get(enemy_id, ""))
	if key != "" and Loc.has_key(key):
		return Loc.t(key)
	return enemy_id
