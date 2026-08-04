extends RefCounted
## 念力升级消耗与烙印品质权重（策划 §14.2）。

## 升到下一等级所需念力碎晶数量（从 level -> level+1）
const UPGRADE_COST := {
	1: 3,
	2: 5,
	3: 8,
	4: 12,
}

## mind_level -> { iron, copper, silver, gold } 权重百分比
const BRAND_WEIGHTS := {
	1: {"iron": 70, "copper": 25, "silver": 5, "gold": 0},
	2: {"iron": 55, "copper": 35, "silver": 9, "gold": 1},
	3: {"iron": 40, "copper": 40, "silver": 16, "gold": 4},
	4: {"iron": 28, "copper": 42, "silver": 22, "gold": 8},
	5: {"iron": 18, "copper": 40, "silver": 30, "gold": 12},
}

const BRAND_STATS := {
	"iron": {"dmg": 1.0, "reach": 1.0, "heavy_kb": 1.0, "name_key": "brand.iron"},
	"copper": {"dmg": 1.12, "reach": 1.05, "heavy_kb": 1.1, "name_key": "brand.copper"},
	"silver": {"dmg": 1.22, "reach": 1.1, "heavy_kb": 1.15, "name_key": "brand.silver", "lifesteal": 0.05},
	"gold": {"dmg": 1.35, "reach": 1.15, "heavy_kb": 1.35, "name_key": "brand.gold"},
}


static func cost_to_next(level: int) -> int:
	return int(UPGRADE_COST.get(level, 0))


static func roll_brand(mind_level: int, rng: RandomNumberGenerator = null) -> String:
	var lvl := clampi(mind_level, 1, 5)
	var weights: Dictionary = BRAND_WEIGHTS[lvl]
	var r := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		r.randomize()
	var roll := r.randi_range(1, 100)
	var acc := 0
	for key in ["iron", "copper", "silver", "gold"]:
		acc += int(weights.get(key, 0))
		if roll <= acc:
			return key
	return "iron"
