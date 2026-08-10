extends RefCounted
## 跨系统事件总线（静态）。局部 node signal 可保留；跨模块用 pub / sub。

class_name GameBus

static var _subs: Dictionary = {} ## StringName -> Array[Dictionary{target, method}]


static func pub(event: StringName, payload: Dictionary = {}) -> void:
	var list: Array = _subs.get(event, [])
	var i := 0
	while i < list.size():
		var entry: Dictionary = list[i]
		var t: Object = entry.get("target")
		var m: StringName = entry.get("method")
		if t == null or not is_instance_valid(t):
			list.remove_at(i)
			continue
		if t.has_method(m):
			t.call(m, payload)
		i += 1
	_subs[event] = list


static func sub(event: StringName, target: Object, method: StringName) -> void:
	if target == null:
		return
	if not _subs.has(event):
		_subs[event] = []
	for entry in _subs[event]:
		if entry.get("target") == target and entry.get("method") == method:
			return
	_subs[event].append({"target": target, "method": method})


static func unsub(event: StringName, target: Object, method: StringName) -> void:
	var list: Array = _subs.get(event, [])
	var i := 0
	while i < list.size():
		var entry: Dictionary = list[i]
		if entry.get("target") == target and entry.get("method") == method:
			list.remove_at(i)
			continue
		i += 1
	_subs[event] = list
