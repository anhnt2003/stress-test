class_name GameAudio
extends Node
## Âm thanh: các bus Music / SFX / Voice, bể phát hiệu ứng, tiếng ù nền và nhạc nền lặp.
## Dùng RNG riêng để âm thanh không ảnh hưởng chuỗi ngẫu nhiên của luật chơi.

const SOUNDS := ["slam", "splat", "zap", "boom", "beep", "buzzer", "buzzer_end", "shove", "stamp", "hum",
	"saw", "sizzle", "grind", "pop", "crunch", "blip"]
const MUSIC := "res://audio/music_loop.wav"

var muted := false
var sounds := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music: AudioStreamPlayer
var hum_player: AudioStreamPlayer
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 12345
	for bus in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	if muted:
		return
	for n in SOUNDS:
		var path := "res://audio/%s.wav" % n
		if ResourceLoader.exists(path):
			sounds[n] = load(path)
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	if sounds.has("hum"):
		var hum: AudioStreamWAV = (sounds["hum"] as AudioStreamWAV).duplicate()
		hum.loop_mode = AudioStreamWAV.LOOP_FORWARD
		hum.loop_end = int(hum.get_length() * hum.mix_rate)
		hum_player = AudioStreamPlayer.new()
		hum_player.stream = hum
		hum_player.volume_db = -14.0
		hum_player.bus = "SFX"
		add_child(hum_player)
		hum_player.play()
	if ResourceLoader.exists(MUSIC):
		var st: AudioStreamWAV = (load(MUSIC) as AudioStreamWAV).duplicate()
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = int(st.get_length() * st.mix_rate)
		music = AudioStreamPlayer.new()
		music.stream = st
		music.bus = "Music"
		music.volume_db = -9.0
		add_child(music)
		music.play()


func sfx(sound: String, vol_db := 0.0, pitch := 1.0) -> void:
	if muted or not sounds.has(sound):
		return
	var p: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = sounds[sound]
	p.volume_db = vol_db
	p.pitch_scale = pitch * rng.randf_range(0.94, 1.06)
	p.play()


## Âm thanh riêng cho từng kiểu chết.
func death(mode: String) -> void:
	match mode:
		"fry":
			sfx("zap", -3.0)
			sfx("sizzle", -6.0)
		"burst":
			sfx("boom", 0.0)
		"crush":
			sfx("slam", 0.0)
			sfx("splat", -2.0)
		"halved":
			sfx("saw", -3.0)
			sfx("splat", -2.0)
		"grind":
			sfx("grind", -2.0)
			sfx("splat", -4.0)
		"headpop":
			sfx("pop", -2.0)
			sfx("splat", -3.0)
		_:
			sfx("splat", 0.0)
	sfx("stamp", -8.0)


## Nhạc nền to hơn khi đang thi, nhỏ lại ở sảnh và bảng điểm.
func set_intensity(playing: bool) -> void:
	if music:
		music.volume_db = -7.0 if playing else -13.0


## Âm lượng 0..1 cho từng bus.
func set_volume(bus: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(i, linear <= 0.001)


func _exit_tree() -> void:
	# dừng hết trước khi thoát để không rò AudioStreamPlayback
	for p in players:
		p.stop()
	if music:
		music.stop()
	if hum_player:
		hum_player.stop()
