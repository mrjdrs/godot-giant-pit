# Art Manifest — 俯视坑内 + Hub 营地（现行 · doc v2.0）

> 规格：俯视角色约 32×32（legacy explorer / 侧视 pose 翻转）；tile 32×32；图标 32×32；整面板 320×240  
> 风格：炼金奇幻 / **俯视卡通像素**（坑内 + Hub）；侧视套归档参考  
> 生成：`tools/gen_sideview_art.py`（侧视 + Hub 质感）｜`tools/gen_mvp_pixel_art.py`（legacy UI）  
> 色板：土石褐 + 炼金青 `#3D8B7A` + 烙印金 `#E8A838`｜轮廓 `#2A1F18`  
> 规范：见 `doc/new/07_美术质感规范.md`

---

## Side-view Characters（坑内现行）

| ID | 名称 | 路径 |
|----|------|------|
| `player_side_*` | 探坑者侧视 pose | `res://assets/characters/player/side/player_{idle,run,jump,light,light1,light2,light3,heavy,dodge}.png` |
| `weapon_blade` | 大刀 | `res://assets/characters/player/weapon_blade.png` |

## Side-view Enemies（坑内现行）

| ID | 模式 | 路径 |
|----|------|------|
| `side_melee` / `side_ranged` / `side_flyer` | 三种普通原型 | `res://assets/enemies/side/side_*.png` |
| `side_elite` | 精英 | `res://assets/enemies/side/side_elite.png` |
| `side_boss` | 层 BOSS | `res://assets/enemies/side/side_boss.png` |
| `proj_spore` / `proj_shock` | 敌弹 | `res://assets/enemies/side/proj_*.png` |
| `{moss,copper,echo}_{mob,elite,guard}` | 旧三区占位（归档） | `res://assets/enemies/side/` |
| `dummy_post` | 木桩 | `res://assets/enemies/side/dummy_post.png` |

## Side-view Tiles & Parallax（坑内现行）

| ID | 名称 | 路径 |
|----|------|------|
| `{biome}/ground` | 地面 | `res://assets/tiles/side/{moss,copper,echo}/ground.png` |
| `{biome}/platform` | 平台顶 | `res://assets/tiles/side/{biome}/platform.png` |
| `{biome}/wall` | 侧墙 | `res://assets/tiles/side/{biome}/wall.png` |
| `{biome}/bg_far` | 视差远层 | `res://assets/tiles/side/{biome}/bg_far.png` |
| `{biome}/bg_mid` | 视差中层 | `res://assets/tiles/side/{biome}/bg_mid.png` |
| `moss/mud`, `moss/fog` | 泥沼/雾 | `res://assets/tiles/side/moss/` |

## Side-view Props & UI（坑内现行）

| ID | 路径 |
|----|------|
| extract, warp, gather, shortcut, descent, winch, spotlight | `res://assets/props/side/` |
| erosion, rule_*, map_* | `res://assets/ui/side/` |

---

## Characters（legacy 俯视 · 归档参考）

| ID | 名称 | 路径 |
|----|------|------|
| `player_explorer` | 探坑者 | `res://assets/characters/player/player_explorer.png` |
| `weapon_blade` | 大刀 | `res://assets/characters/player/weapon_blade.png` |

## Brands（现行）

| ID | 名称 | 路径 |
|----|------|------|
| `brand_iron` | 铁纹烙印 | `res://assets/brands/brand_iron.png` |
| `brand_copper` | 铜纹烙印 | `res://assets/brands/brand_copper.png` |
| `brand_silver` | 银纹烙印 | `res://assets/brands/brand_silver.png` |
| `brand_gold` | 金纹烙印 | `res://assets/brands/brand_gold.png` |

## Runes（现行 · v0.4 技能型/属性型）

| ID | 名称 | 类型 | 路径 |
|----|------|------|------|
| `rune_s_chain` | 连环斩 | 技能 | `res://assets/runes/rune_s_chain.png` |
| `rune_s_quake` | 崩山击 | 技能 | `res://assets/runes/rune_s_quake.png` |
| `rune_s_cloudstep` | 踏云 | 技能 | `res://assets/runes/rune_s_cloudstep.png` |
| `rune_s_ironwall` | 铁壁 | 技能 | `res://assets/runes/rune_s_ironwall.png` |
| `rune_a_toughbone` | 韧骨 | 属性 | `res://assets/runes/rune_a_toughbone.png` |
| `rune_a_heavyarm` | 沉臂 | 属性 | `res://assets/runes/rune_a_heavyarm.png` |
| `rune_a_sharpeye` | 锐眼 | 属性 | `res://assets/runes/rune_a_sharpeye.png` |
| `rune_a_cruel` | 狠劲 | 属性 | `res://assets/runes/rune_a_cruel.png` |

## Hub（现行 · 俯视营地）

| ID | 名称 | 路径 |
|----|------|------|
| `hub_floor` | 石砖地 | `res://assets/tiles/hub/hub_floor.png` |
| `hub_wall` | 营地墙 | `res://assets/tiles/hub/hub_wall.png` |
| `hub_board` | 告示板 | `res://assets/tiles/hub/hub_board.png` |
| `hub_alchemy` | 炼金台 | `res://assets/tiles/hub/hub_alchemy.png` |
| `hub_quiet_door` | 静室门 | `res://assets/tiles/hub/hub_quiet_door.png` |
| `hub_pit_mouth` | 坑口 | `res://assets/tiles/hub/hub_pit_mouth.png` |

---

## Enemies — 沉苔沼（区域 A · 归档俯视）

| ID | 名称 | 职司 | 路径 |
|----|------|------|------|
| `enemy_a_moss_grub` | 苔蛆 | 近战 | `res://assets/enemies/region_a/enemy_a_moss_grub.png` |
| `enemy_a_spore_spitter` | 沼孢虫 | 远程 | `res://assets/enemies/region_a/enemy_a_spore_spitter.png` |
| `enemy_a_scale_rock` | 鳞岩兽 | 硬壳/委托 | `res://assets/enemies/region_a/enemy_a_scale_rock.png` |

## Enemies — 折铜谷（区域 B）

| ID | 名称 | 职司 | 路径 |
|----|------|------|------|
| `enemy_b_copper_mite` | 铜螨 | 近战 | `res://assets/enemies/region_b/enemy_b_copper_mite.png` |
| `enemy_b_slag_spitter` | 炼渣喷虫 | 远程 | `res://assets/enemies/region_b/enemy_b_slag_spitter.png` |
| `enemy_b_rust_beetle` | 锈甲虫 | 硬壳 | `res://assets/enemies/region_b/enemy_b_rust_beetle.png` |

## Enemies — 盲灯廊（区域 C）

| ID | 名称 | 职司 | 路径 |
|----|------|------|------|
| `enemy_c_lamp_wisp` | 盲灯游灵 | 机动 | `res://assets/enemies/region_c/enemy_c_lamp_wisp.png` |
| `enemy_c_shade_grub` | 廊影蛆 | 近战 | `res://assets/enemies/region_c/enemy_c_shade_grub.png` |
| `enemy_c_lantern_shell` | 灯壳卫 | 硬壳 | `res://assets/enemies/region_c/enemy_c_lantern_shell.png` |

## Elites

| ID | 名称 | 作用 | 路径 |
|----|------|------|------|
| `elite_a_mire_lord` | 沼主 | 沉苔沼精英 | `res://assets/enemies/elites/elite_a_mire_lord.png` |
| `elite_b_copper_warden` | 折铜守 | 折铜谷精英 | `res://assets/enemies/elites/elite_b_copper_warden.png` |
| `elite_c_blind_keeper` | 盲廊司灯 | 盲灯廊精英 | `res://assets/enemies/elites/elite_c_blind_keeper.png` |

## Warp Guards

| ID | 名称 | 作用 | 路径 |
|----|------|------|------|
| `guard_a_warp` | 沼心看守 | 传送点 A | `res://assets/enemies/guards/guard_a_warp.png` |
| `guard_b_warp` | 铜心看守 | 传送点 B | `res://assets/enemies/guards/guard_b_warp.png` |
| `guard_c_warp` | 廊心看守 | 传送点 C | `res://assets/enemies/guards/guard_c_warp.png` |

## Boss

| ID | 名称 | 作用 | 路径 |
|----|------|------|------|
| `boss_floor1_pit_crown` | 坑冠兽 | 第 1 层层 BOSS | `res://assets/enemies/bosses/boss_floor1_pit_crown.png` |

---

## Materials（通用现行）

| ID | 名称 | 类型 | 路径 |
|----|------|------|------|
| `mat_glow_moss` | 荧苔 | 采集 | `res://assets/materials/mat_glow_moss.png` |
| `mat_bitter_root` | 苦根 | 采集 | `res://assets/materials/mat_bitter_root.png` |
| `mat_deep_red_ore` | 深赤矿 | 矿物 | `res://assets/materials/mat_deep_red_ore.png` |
| `mat_copper_vein` | 铜纹矿 | 矿物 | `res://assets/materials/mat_copper_vein.png` |
| `mat_silver_dust` | 银屑晶 | 矿物 | `res://assets/materials/mat_silver_dust.png` |
| `mat_beast_scale` | 兽鳞片 | 兽材 | `res://assets/materials/mat_beast_scale.png` |
| `mat_chitin_plate` | 甲壳碎片 | 兽材 | `res://assets/materials/mat_chitin_plate.png` |
| `mat_ember_gland` | 灼腺 | 兽材 | `res://assets/materials/mat_ember_gland.png` |
| `mat_mind_shard` | 念力碎晶 | 念力 | `res://assets/materials/mat_mind_shard.png` |
| `mat_mind_core` | 念核残片 | 念力稀有 | `res://assets/materials/mat_mind_core.png` |
| `mat_alchem_slag` | 炼渣锭 | 打造 | `res://assets/materials/mat_alchem_slag.png` |
| `mat_rune_ash` | 符灰 | 辅材 | `res://assets/materials/mat_rune_ash.png` |

## Materials — 区绑增量

| ID | 名称 | 区域 | 路径 |
|----|------|------|------|
| `mat_mire_pearl` | 沼珠 | 沉苔沼 | `res://assets/materials/mat_mire_pearl.png` |
| `mat_fold_copper` | 折铜片 | 折铜谷 | `res://assets/materials/mat_fold_copper.png` |
| `mat_lamp_oil_crystal` | 灯油晶 | 盲灯廊 | `res://assets/materials/mat_lamp_oil_crystal.png` |
| `mat_blind_wick` | 盲芯 | 盲灯廊 | `res://assets/materials/mat_blind_wick.png` |

## Items — 局内特殊

| ID | 名称 | 说明 | 路径 |
|----|------|------|------|
| `item_special_mind_floor1` | 坑冠念力 | 局内钥匙，不带出 | `res://assets/materials/item_special_mind_floor1.png` |

---

## Tiles — 沉苔沼

| ID | 名称 | 路径 |
|----|------|------|
| `tile_a_floor_01` | 沼地 A | `res://assets/tiles/region_a/tile_a_floor_01.png` |
| `tile_a_floor_02` | 沼地 B | `res://assets/tiles/region_a/tile_a_floor_02.png` |
| `tile_a_floor_03` | 沼地 C | `res://assets/tiles/region_a/tile_a_floor_03.png` |
| `tile_a_floor_04` | 沼地 D | `res://assets/tiles/region_a/tile_a_floor_04.png` |
| `tile_a_water` | 浅水渍 | `res://assets/tiles/region_a/tile_a_water.png` |
| `tile_a_moss` | 苔毯 | `res://assets/tiles/region_a/tile_a_moss.png` |
| `tile_a_wall` | 沼壁 | `res://assets/tiles/region_a/tile_a_wall.png` |
| `tile_a_wall_corner` | 沼壁转角 | `res://assets/tiles/region_a/tile_a_wall_corner.png` |

## Tiles — 折铜谷

| ID | 名称 | 路径 |
|----|------|------|
| `tile_b_floor_01` | 谷地 A | `res://assets/tiles/region_b/tile_b_floor_01.png` |
| `tile_b_floor_02` | 谷地 B | `res://assets/tiles/region_b/tile_b_floor_02.png` |
| `tile_b_floor_03` | 谷地 C | `res://assets/tiles/region_b/tile_b_floor_03.png` |
| `tile_b_floor_04` | 谷地 D | `res://assets/tiles/region_b/tile_b_floor_04.png` |
| `tile_b_vein` | 铜纹矿脉地 | `res://assets/tiles/region_b/tile_b_vein.png` |
| `tile_b_scrap` | 机关碎件地 | `res://assets/tiles/region_b/tile_b_scrap.png` |
| `tile_b_wall` | 谷壁 | `res://assets/tiles/region_b/tile_b_wall.png` |
| `tile_b_wall_corner` | 谷壁转角 | `res://assets/tiles/region_b/tile_b_wall_corner.png` |

## Tiles — 盲灯廊

| ID | 名称 | 路径 |
|----|------|------|
| `tile_c_floor_01` | 廊砖 A | `res://assets/tiles/region_c/tile_c_floor_01.png` |
| `tile_c_floor_02` | 廊砖 B | `res://assets/tiles/region_c/tile_c_floor_02.png` |
| `tile_c_floor_03` | 廊砖 C | `res://assets/tiles/region_c/tile_c_floor_03.png` |
| `tile_c_floor_04` | 廊砖 D | `res://assets/tiles/region_c/tile_c_floor_04.png` |
| `tile_c_lamp` | 灯影砖 | `res://assets/tiles/region_c/tile_c_lamp.png` |
| `tile_c_shadow` | 阴影缝 | `res://assets/tiles/region_c/tile_c_shadow.png` |
| `tile_c_wall` | 廊壁 | `res://assets/tiles/region_c/tile_c_wall.png` |
| `tile_c_wall_corner` | 廊壁转角 | `res://assets/tiles/region_c/tile_c_wall_corner.png` |

## Tiles — BOSS 域

| ID | 名称 | 路径 |
|----|------|------|
| `tile_boss_floor_01` | BOSS 地 A | `res://assets/tiles/region_boss/tile_boss_floor_01.png` |
| `tile_boss_floor_02` | BOSS 地 B | `res://assets/tiles/region_boss/tile_boss_floor_02.png` |
| `tile_boss_crack` | 裂隙地 | `res://assets/tiles/region_boss/tile_boss_crack.png` |
| `tile_boss_wall` | BOSS 壁 | `res://assets/tiles/region_boss/tile_boss_wall.png` |

## Tiles — Shared

| ID | 名称 | 路径 |
|----|------|------|
| `tile_border` | 区域接壤过渡砖 | `res://assets/tiles/shared/tile_border.png` |

---

## Props — Warp

| ID | 名称 | 路径 |
|----|------|------|
| `prop_warp_inactive` | 传送点未激活 | `res://assets/props/warp/prop_warp_inactive.png` |
| `prop_warp_active` | 传送点已激活 | `res://assets/props/warp/prop_warp_active.png` |
| `prop_warp_flag_a` | 传送点区色边 A | `res://assets/props/warp/prop_warp_flag_a.png` |
| `prop_warp_flag_b` | 传送点区色边 B | `res://assets/props/warp/prop_warp_flag_b.png` |
| `prop_warp_flag_c` | 传送点区色边 C | `res://assets/props/warp/prop_warp_flag_c.png` |

## Props — Extract / Descent / Boss / Distress

| ID | 名称 | 路径 |
|----|------|------|
| `prop_extract` | 撤离点 | `res://assets/props/extract/prop_extract.png` |
| `prop_descent_locked` | 下层入口灰态 | `res://assets/props/descent/prop_descent_locked.png` |
| `prop_boss_altar` | BOSS 域祭坛 | `res://assets/props/boss/prop_boss_altar.png` |
| `prop_distress` | 求救信标 | `res://assets/props/extract/prop_distress.png` |

## Props — Gather（区特色）

| ID | 名称 | 路径 |
|----|------|------|
| `prop_ore_a` | 沉苔沼矿脉 | `res://assets/props/gather/prop_ore_a.png` |
| `prop_ore_b` | 折铜谷矿脉 | `res://assets/props/gather/prop_ore_b.png` |
| `prop_ore_c` | 盲灯廊矿脉 | `res://assets/props/gather/prop_ore_c.png` |
| `prop_forage_a` | 沉苔沼采集点 | `res://assets/props/gather/prop_forage_a.png` |
| `prop_forage_b` | 折铜谷采集点 | `res://assets/props/gather/prop_forage_b.png` |
| `prop_forage_c` | 盲灯廊采集点 | `res://assets/props/gather/prop_forage_c.png` |

---

## UI — 整面板（320×240）

| ID | 名称 | 路径 |
|----|------|------|
| `panel_stats` | 属性面板 | `res://assets/ui/panels/panel_stats.png` |
| `panel_bag` | 背包面板 | `res://assets/ui/panels/panel_bag.png` |
| `panel_skills` | 技能学习面板 | `res://assets/ui/panels/panel_skills.png` |

## UI — Chrome

| ID | 名称 | 路径 |
|----|------|------|
| `ui_frame_edge` | 边框边 | `res://assets/ui/chrome/ui_frame_edge.png` |
| `ui_frame_corner` | 边框角 | `res://assets/ui/chrome/ui_frame_corner.png` |
| `ui_btn_normal` | 按钮常态 | `res://assets/ui/chrome/ui_btn_normal.png` |
| `ui_btn_disabled` | 按钮禁用 | `res://assets/ui/chrome/ui_btn_disabled.png` |
| `ui_btn_close` | 关闭按钮 | `res://assets/ui/chrome/ui_btn_close.png` |
| `ui_slot_empty` | 空槽 | `res://assets/ui/chrome/ui_slot_empty.png` |
| `ui_slot_selected` | 选中槽 | `res://assets/ui/chrome/ui_slot_selected.png` |
| `ui_lock` | 锁定 | `res://assets/ui/chrome/ui_lock.png` |
| `ui_tab_skill` | 技能型 Tab | `res://assets/ui/chrome/ui_tab_skill.png` |
| `ui_tab_attr` | 属性型 Tab | `res://assets/ui/chrome/ui_tab_attr.png` |

## UI — 属性图标

| ID | 名称 | 路径 |
|----|------|------|
| `icon_hp` | 生命 | `res://assets/ui/icons/stats/icon_hp.png` |
| `icon_mind` | 念力值 | `res://assets/ui/icons/stats/icon_mind.png` |
| `icon_mind_lv` | 念力等级 | `res://assets/ui/icons/stats/icon_mind_lv.png` |
| `icon_vitality` | 体力 | `res://assets/ui/icons/stats/icon_vitality.png` |
| `icon_str` | 力量 | `res://assets/ui/icons/stats/icon_str.png` |
| `icon_patk` | 物攻 | `res://assets/ui/icons/stats/icon_patk.png` |
| `icon_pdef` | 物防 | `res://assets/ui/icons/stats/icon_pdef.png` |
| `icon_agi` | 敏捷（占位） | `res://assets/ui/icons/stats/icon_agi.png` |
| `icon_int` | 智力（占位） | `res://assets/ui/icons/stats/icon_int.png` |
| `icon_crit` | 暴击（占位） | `res://assets/ui/icons/stats/icon_crit.png` |
| `icon_critdmg` | 爆伤（占位） | `res://assets/ui/icons/stats/icon_critdmg.png` |
| `slot_weapon` | 武器槽标 | `res://assets/ui/icons/stats/slot_weapon.png` |
| `slot_chest` | 胸甲槽标 | `res://assets/ui/icons/stats/slot_chest.png` |
| `slot_pendant` | 挂坠槽标 | `res://assets/ui/icons/stats/slot_pendant.png` |
| `equip_chest` | 胸甲 | `res://assets/ui/icons/stats/equip_chest.png` |
| `equip_pendant` | 挂坠 | `res://assets/ui/icons/stats/equip_pendant.png` |

## UI — 背包

| ID | 名称 | 路径 |
|----|------|------|
| `icon_gold` | 金币 | `res://assets/ui/icons/bag/icon_gold.png` |
| `ui_gold_bar` | 金币分栏条 | `res://assets/ui/icons/bag/ui_gold_bar.png` |
| `ui_weight_bar_bg` | 承重条底 | `res://assets/ui/icons/bag/ui_weight_bar_bg.png` |
| `ui_weight_bar_fill` | 承重条填充 | `res://assets/ui/icons/bag/ui_weight_bar_fill.png` |
| `item_paper_note` | 纸券 | `res://assets/ui/icons/bag/item_paper_note.png` |
| `item_bag_expand` | 空间扩容 | `res://assets/ui/icons/bag/item_bag_expand.png` |
| `item_mind_potion` | 念力药剂 | `res://assets/ui/icons/bag/item_mind_potion.png` |

## UI — 技能槽标

| ID | 名称 | 路径 |
|----|------|------|
| `skill_slot_basic` | 普攻 | `res://assets/ui/icons/skills/skill_slot_basic.png` |
| `skill_slot_finisher` | 杀招 | `res://assets/ui/icons/skills/skill_slot_finisher.png` |
| `skill_slot_dodge` | 闪避 | `res://assets/ui/icons/skills/skill_slot_dodge.png` |
| `skill_slot_defend` | 防御（灰） | `res://assets/ui/icons/skills/skill_slot_defend.png` |
| `skill_slot_ultimate` | 绝技（灰） | `res://assets/ui/icons/skills/skill_slot_ultimate.png` |
| `skill_slot_passive` | 被动（灰） | `res://assets/ui/icons/skills/skill_slot_passive.png` |

---

## Deprecated（v0.2 通用坑砖/旧怪/旧符文，文件保留兼容）

> 新内容请用上方分区与 v0.4 UI/符文资源。下列路径仍存在，勿作现行主素材。

| ID | 名称 | 路径 |
|----|------|------|
| `rune_tough` | 韧皮 | `res://assets/runes/rune_tough.png` |
| `rune_swift` | 疾步 | `res://assets/runes/rune_swift.png` |
| `rune_slash` | 迅斩 | `res://assets/runes/rune_slash.png` |
| `rune_sidestep` | 侧身 | `res://assets/runes/rune_sidestep.png` |
| `rune_edge` | 锋刃 | `res://assets/runes/rune_edge.png` |
| `rune_reach` | 延斩 | `res://assets/runes/rune_reach.png` |
| `rune_burn` | 灼痕 | `res://assets/runes/rune_burn.png` |
| `rune_quake` | 崩山 | `res://assets/runes/rune_quake.png` |
| `enemy_pit_grub` | 坑蛆 | `res://assets/enemies/enemy_pit_grub.png` |
| `enemy_spore_spitter` | 孢喷虫 | `res://assets/enemies/enemy_spore_spitter.png` |
| `enemy_shell_beetle` | 甲壳甲虫 | `res://assets/enemies/enemy_shell_beetle.png` |
| `enemy_scale_rock` | 鳞岩兽 | `res://assets/enemies/enemy_scale_rock.png` |
| `enemy_rune_wisp` | 符火游灵 | `res://assets/enemies/enemy_rune_wisp.png` |
| `enemy_alchemy_golem` | 残炼魔像 | `res://assets/enemies/enemy_alchemy_golem.png` |
| `enemy_depth_lurker` | 深蚀潜伏者 | `res://assets/enemies/enemy_depth_lurker.png` |
| `enemy_crystal_guardian` | 晶脉卫 | `res://assets/enemies/enemy_crystal_guardian.png` |
| `tile_floor_01`～`04` / crack / vein / deep | 旧通用地砖 | `res://assets/tiles/pit_floor/` |
| `tile_wall` / corner / door | 旧通用墙 | `res://assets/tiles/pit_wall/` |
| `prop_ore_node` 等 | 旧通用道具 | `res://assets/tiles/pit_props/` |
