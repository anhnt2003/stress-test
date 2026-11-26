class_name Settings
extends RefCounted
## Cài đặt người chơi, lưu ở user://settings.cfg.

const PATH := "user://settings.cfg"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]

var master := 0.9
var music := 0.7
var sfx := 0.9
var voice := 0.8
var resolution := 1
var fullscreen := false
var gore := true
var tts := true
var llm := false
var shake := 1.0
var player_name := ""
var last_join := ""
var token := ""


static func load_or_default(path := PATH) -> Settings:
	var s := Settings.new()
	var cf := ConfigFile.new()
	if cf.load(path) == OK:
		for k in s.keys():
			s.set(k, cf.get_value("settings", k, s.get(k)))
	s.resolution = clampi(s.resolution, 0, RESOLUTIONS.size() - 1)
	for k in ["master", "music", "sfx", "voice", "shake"]:
		s.set(k, clampf(float(s.get(k)), 0.0, 1.0))
	if s.token == "":
		s.token = "%08x%08x" % [randi(), Time.get_ticks_usec() & 0xffffffff]
	return s


func keys() -> Array:
	return ["master", "music", "sfx", "voice", "resolution", "fullscreen", "gore", "tts", "llm", "shake", "player_name", "last_join", "token"]


func save(path := PATH) -> int:
	var cf := ConfigFile.new()
	for k in keys():
		cf.set_value("settings", k, get(k))
	return cf.save(path)


## Áp dụng âm lượng và cửa sổ.
func apply(audio: GameAudio) -> void:
	audio.set_volume("Master", master)
	audio.set_volume("Music", music)
	audio.set_volume("SFX", sfx)
	audio.set_volume("Voice", voice)
	if DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(RESOLUTIONS[resolution])
