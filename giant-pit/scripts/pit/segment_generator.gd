extends RefCounted
class_name SegmentGenerator
## 生成第 1 层三区段侧视节点链（可含 1 条捷径）。

const ST = preload("res://scripts/pit/segment_types.gd")


static func generate(seed_value: int = 0, full_mvp: bool = true) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	var nodes: Array = []
	var edges: Array = [] ## {from, to}
	var idx := 0

	var biomes: Array = [ST.BIOME_MOSS]
	if full_mvp:
		biomes = ST.BIOME_ORDER.duplicate()

	var first_id := ""
	var prev_tail := ""
	var shortcut_from := ""
	var extract_id := ""

	for bi in biomes.size():
		var biome: String = biomes[bi]
		var segment_nodes: Array = _build_biome_segment(rng, biome, bi, full_mvp)
		for n in segment_nodes:
			n["index"] = idx
			if first_id == "" and n["type"] == ST.NODE_COMBAT:
				first_id = n["id"]
			if n["type"] == ST.NODE_EXTRACT:
				extract_id = n["id"]
			if n["type"] == ST.NODE_SHORTCUT:
				shortcut_from = n["id"]
			nodes.append(n)
			idx += 1
		## 链内边
		for i in range(segment_nodes.size() - 1):
			edges.append({"from": segment_nodes[i]["id"], "to": segment_nodes[i + 1]["id"]})
		## 区段衔接
		if prev_tail != "" and not segment_nodes.is_empty():
			edges.append({"from": prev_tail, "to": segment_nodes[0]["id"]})
		if not segment_nodes.is_empty():
			prev_tail = segment_nodes[segment_nodes.size() - 1]["id"]

	## 捷径：沉苔沼中段 → 撤离邻域（若解锁则生成边）
	if full_mvp and shortcut_from != "" and extract_id != "":
		if MetaProgress.is_shortcut_unlocked("shortcut_moss_extract"):
			edges.append({"from": shortcut_from, "to": extract_id, "shortcut": true})

	if first_id == "" and not nodes.is_empty():
		first_id = nodes[0]["id"]

	return {
		"nodes": nodes,
		"edges": edges,
		"start_id": first_id,
		"seed": rng.seed,
	}


static func _build_biome_segment(rng: RandomNumberGenerator, biome: String, bi: int, full_mvp: bool) -> Array:
	var out: Array = []
	var prefix := "%s_" % biome
	out.append(_node(prefix + "c0", ST.NODE_COMBAT, biome, {"mobs": 2}))
	out.append(_node(prefix + "r0", ST.NODE_RESOURCE, biome, {}))
	## 中段核心：传送锚点（非边缘）
	if full_mvp:
		var warp_id: String = ST.BIOME_INFO[biome]["warp"]
		out.append(_node(prefix + "w0", ST.NODE_WARP, biome, {"warp_id": warp_id}))
	out.append(_node(prefix + "c1", ST.NODE_COMBAT, biome, {"mobs": 3}))
	if full_mvp or biome == ST.BIOME_MOSS:
		out.append(_node(prefix + "e0", ST.NODE_ELITE, biome, {}))
	if biome == ST.BIOME_MOSS and full_mvp:
		out.append(_node(prefix + "sc", ST.NODE_SHORTCUT, biome, {"shortcut_id": "shortcut_moss_extract"}))
	if bi == 0:
		out.append(_node(prefix + "q0", ST.NODE_QUEST, biome, {}))
	## 末区段后接撤离 / BOSS / 下层
	if biome == biomes_last(full_mvp):
		out.append(_node("extract_0", ST.NODE_EXTRACT, biome, {}))
		if full_mvp:
			out.append(_node("boss_0", ST.NODE_BOSS, biome, {}))
			out.append(_node("descent_0", ST.NODE_DESCENT, biome, {}))
	elif rng.randf() < 0.35:
		out.append(_node(prefix + "ev", ST.NODE_EVENT, biome, {}))
	return out


static func biomes_last(full_mvp: bool) -> String:
	return ST.BIOME_ECHO if full_mvp else ST.BIOME_MOSS


static func _node(id: String, type: String, biome: String, extra: Dictionary) -> Dictionary:
	var d := {
		"id": id,
		"type": type,
		"biome": biome,
		"revealed": false,
		"cleared": false,
		"blocked_by_breath": false,
	}
	for k in extra.keys():
		d[k] = extra[k]
	return d
