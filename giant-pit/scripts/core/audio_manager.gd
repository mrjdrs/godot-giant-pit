extends Node
## 简易音效 / BGM 管理。

var _bgm: AudioStreamPlayer
var _sfx: AudioStreamPlayer


func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = "Master"
	_bgm.volume_db = -12.0
	add_child(_bgm)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "Master"
	_sfx.volume_db = -4.0
	add_child(_sfx)


func play_bgm(path: String = "res://assets/audio/bgm_pit.wav") -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = -1
	_bgm.stream = stream
	if not _bgm.playing:
		_bgm.play()


func stop_bgm() -> void:
	_bgm.stop()


func play_sfx(path: String) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.play()


func sfx_blade() -> void:
	play_sfx("res://assets/audio/sfx_blade.wav")


func sfx_hurt_player() -> void:
	play_sfx("res://assets/audio/sfx_hurt_player.wav")


func sfx_hurt_enemy() -> void:
	play_sfx("res://assets/audio/sfx_hurt_enemy.wav")


func sfx_pickup() -> void:
	play_sfx("res://assets/audio/sfx_pickup.wav")


func sfx_interact() -> void:
	play_sfx("res://assets/audio/sfx_interact.wav")


func sfx_roll() -> void:
	play_sfx("res://assets/audio/sfx_roll.wav")
