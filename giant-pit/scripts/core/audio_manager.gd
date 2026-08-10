extends Node
## 简易音效 / BGM 管理。武器族走对应挥击声。

const SFX_VOICES := 8

var _bgm: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _chop_stream: AudioStreamWAV


func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = "Master"
	_bgm.volume_db = -12.0
	add_child(_bgm)
	for _i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -4.0
		add_child(p)
		_sfx_players.append(p)


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
	_play_stream_now(stream)


func play_stream(stream: AudioStream) -> void:
	_play_stream_now(stream)


func _ensure_sfx_pool() -> void:
	if not _sfx_players.is_empty():
		return
	for _i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -4.0
		add_child(p)
		_sfx_players.append(p)


func _play_stream_now(stream: AudioStream) -> void:
	if stream == null:
		return
	_ensure_sfx_pool()
	if _sfx_players.is_empty():
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	p.stream = stream
	p.play()


func sfx_blade() -> void:
	sfx_weapon_attack("blade")


func sfx_weapon_attack(weapon_family: String = "blade") -> void:
	match weapon_family:
		"blade", "greatsword", "cleaver", "cleave":
			if ResourceLoader.exists("res://assets/audio/sfx_blade_chop.wav"):
				play_sfx("res://assets/audio/sfx_blade_chop.wav")
			else:
				play_stream(_get_chop_stream())
		_:
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


func _get_chop_stream() -> AudioStreamWAV:
	if _chop_stream != null:
		return _chop_stream
	_chop_stream = _make_chop_stream()
	return _chop_stream


func _make_chop_stream() -> AudioStreamWAV:
	## 大刀砍击：下劈呼啸 + 低沉着刃 + 短金属余音。
	var rate := 44100
	var duration := 0.32
	var n := int(float(rate) * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var seed_v := 2463534242
	for i in n:
		var t := float(i) / float(rate)
		seed_v = (seed_v ^ (seed_v << 13)) & 0xFFFFFFFF
		seed_v = (seed_v ^ (seed_v >> 17)) & 0xFFFFFFFF
		seed_v = (seed_v ^ (seed_v << 5)) & 0xFFFFFFFF
		var noise := (float(seed_v & 0x7FFFFFFF) / 2147483647.0) * 2.0 - 1.0
		var whoosh := noise * exp(-t * 16.0) * (1.0 - t / duration) * 0.38
		var freq := 380.0 * exp(-t * 9.0) + 70.0
		var blade := sin(TAU * freq * t) * exp(-t * 12.0) * 0.62
		var thump := sin(TAU * 62.0 * t) * exp(-t * 20.0) * 0.78
		var click := sin(TAU * 1650.0 * t) * exp(-t * 55.0) * 0.22
		var s := clampf(whoosh + blade + thump + click, -1.0, 1.0)
		var v := int(round(s * 32767.0))
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
