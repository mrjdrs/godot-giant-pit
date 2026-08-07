extends RefCounted
class_name SegmentTypes
## 横版段落节点类型与生态定义。

const BIOME_MOSS := "moss"
const BIOME_COPPER := "copper"
const BIOME_ECHO := "echo"

const NODE_COMBAT := "combat"
const NODE_RESOURCE := "resource"
const NODE_ELITE := "elite"
const NODE_EVENT := "event"
const NODE_EXTRACT := "extract"
const NODE_BOSS := "boss"
const NODE_WARP := "warp"
const NODE_SHORTCUT := "shortcut"
const NODE_QUEST := "quest"
const NODE_DESCENT := "descent"

const BIOME_ORDER := [BIOME_MOSS, BIOME_COPPER, BIOME_ECHO]

const BIOME_INFO := {
	BIOME_MOSS: {"name_key": "biome.moss", "rule_key": "biome.rule.moss", "warp": "warp_a"},
	BIOME_COPPER: {"name_key": "biome.copper", "rule_key": "biome.rule.copper", "warp": "warp_b"},
	BIOME_ECHO: {"name_key": "biome.echo", "rule_key": "biome.rule.echo", "warp": "warp_c"},
}

const ENEMY_POOL := {
	BIOME_MOSS: {"mob": "moss_mob", "elite": "moss_elite", "guard": "moss_guard", "drop": "glow_moss"},
	BIOME_COPPER: {"mob": "copper_mob", "elite": "copper_elite", "guard": "copper_guard", "drop": "alchem_slag"},
	BIOME_ECHO: {"mob": "echo_mob", "elite": "echo_elite", "guard": "echo_guard", "drop": "mind_shard"},
}

const AWAKEN_MAT_WHIRL := "mat_whirl_edge"
const AWAKEN_MAT_IRON := "mat_iron_guard"
