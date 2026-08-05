extends RefCounted

static var _busy: bool = false


static func freeze(tree: SceneTree, duration: float = 0.06) -> void:
	if _busy or tree == null or duration <= 0.0:
		return
	_busy = true
	var previous := Engine.time_scale
	## If somehow invoked mid-physics, still avoid stacking broken scales.
	if previous < 0.99:
		previous = 1.0
	Engine.time_scale = 0.05
	var timer := tree.create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		Engine.time_scale = previous
		_busy = false
	, CONNECT_ONE_SHOT)
