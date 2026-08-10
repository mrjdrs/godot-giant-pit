extends CanvasLayer
## 属性 / 背包 / 技能三面板宿主，坑内与枢纽共用。

const StatsScene = preload("res://scenes/ui/stats_panel.tscn")
const BagScene = preload("res://scenes/ui/bag_panel.tscn")
const SkillsScene = preload("res://scenes/ui/skills_panel.tscn")

signal panel_opened(which: String)
signal panel_closed

var hub_mode: bool = false
var training_mode: bool = false
var _player: Node = null
var stats_panel: Control
var bag_panel: Control
var skills_panel: Control
var _blocking: bool = false


func _ready() -> void:
	layer = 20
	stats_panel = StatsScene.instantiate()
	bag_panel = BagScene.instantiate()
	skills_panel = SkillsScene.instantiate()
	add_child(stats_panel)
	add_child(bag_panel)
	add_child(skills_panel)
	stats_panel.closed.connect(_on_any_closed)
	bag_panel.closed.connect(_on_any_closed)
	skills_panel.closed.connect(_on_any_closed)
	if skills_panel.has_signal("learned"):
		skills_panel.learned.connect(func(_id): _refresh_all())
	if bag_panel.has_signal("request_refresh"):
		bag_panel.request_refresh.connect(_refresh_all)


func bind_player(p: Node, p_hub_mode: bool = false, p_training: bool = false) -> void:
	_player = p
	hub_mode = p_hub_mode
	training_mode = p_training
	stats_panel.bind_player(p)
	bag_panel.bind_player(p, hub_mode)
	skills_panel.bind_player(p, hub_mode, training_mode)


func is_blocking() -> bool:
	return _blocking


func any_open() -> bool:
	return stats_panel.visible or bag_panel.visible or skills_panel.visible


func close_all() -> void:
	stats_panel.visible = false
	bag_panel.visible = false
	skills_panel.visible = false
	_blocking = false
	panel_closed.emit()


func toggle_stats() -> void:
	_toggle(stats_panel, "stats")


func toggle_bag() -> void:
	_toggle(bag_panel, "bag")


func toggle_skills() -> void:
	_toggle(skills_panel, "skills")


func _toggle(panel: Control, which: String) -> void:
	var was := panel.visible
	close_all()
	if was:
		return
	panel.open()
	_blocking = true
	if _player != null:
		_player.input_locked = true
	panel_opened.emit(which)


func _on_any_closed() -> void:
	if not any_open():
		_blocking = false
		if _player != null and is_instance_valid(_player):
			## 死亡/撤离时可能已锁定，勿强行解开；由宿主场景负责
			if not _player_is_settling():
				_player.input_locked = false
		panel_closed.emit()


func _player_is_settling() -> bool:
	## 粗略：宿主可在死亡 UI 时保持锁定
	return false


func _refresh_all() -> void:
	if stats_panel.visible:
		stats_panel.refresh()
	if bag_panel.visible:
		bag_panel.refresh()
	if skills_panel.visible:
		skills_panel.refresh()


