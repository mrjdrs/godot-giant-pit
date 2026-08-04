extends RefCounted

static var _busy: bool = false


static func freeze(tree: SceneTree, duration: float = 0.06) -> void:
	if _busy or tree == null or duration <= 0.0:
		return
	_busy = true
	var previous := Engine.time_scale
	Engine.time_scale = 0.05
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = previous
	_busy = false
