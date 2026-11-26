class_name MachineVoice
extends Node
## Giọng Cỗ Máy: lời bình theo diễn biến trận. Có sẵn câu dựng sẵn; nếu bật và có khoá API thì
## thử xin thêm một câu từ LLM (không chờ, mất mạng thì thôi). Đọc thành tiếng bằng TTS của hệ điều hành
## nếu máy có giọng phù hợp, không thì phát tiếng bíp kiểu máy.

signal said(text: String, duration: float)

const Lines := preload("res://game/machine/machine_lines.gd")

var rng := RandomNumberGenerator.new()
var tts_enabled := true
## Âm lượng giọng đọc của hệ điều hành (0..100); TTS không đi qua bus âm thanh của Godot.
var tts_volume := 70
var llm_enabled := false
var llm: LlmClient
var audio: GameAudio
var _queue: Array[Dictionary] = []
var _voice_id := ""
var _streak := {}
var _leader := -1
var _kills_this_door := 0
var _final := false


func _ready() -> void:
	rng.seed = 777
	if DisplayServer.get_name() != "headless" and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		var voices := DisplayServer.tts_get_voices_for_language("vi")
		if voices.size() > 0:
			_voice_id = voices[0]
	llm = LlmClient.new()
	add_child(llm)
	llm.line_ready.connect(func(text): queue_line(text, 0.2))


func has_tts() -> bool:
	return _voice_id != ""


func pick(arr: Array) -> String:
	return String(arr[rng.randi() % arr.size()])


func queue_line(text: String, delay := 0.0, duration := 3.4) -> void:
	if _final:
		duration = 999.0   # màn tổng kết: phụ đề phán quyết ở lại tới khi rời màn
	_queue.append({"t": delay, "text": text, "dur": duration})


## Đọc to một câu (câu thông báo của luật chơi cũng đi qua đây).
func speak(text: String) -> void:
	if tts_enabled and _voice_id != "":
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(text.to_lower(), _voice_id, clampi(tts_volume, 0, 100), 0.55, 1.05)
	elif tts_enabled and audio:
		for k in mini(4, 1 + text.length() / 14):   # không có giọng: vài tiếng bíp kiểu máy
			get_tree().create_timer(0.09 * k).timeout.connect(func(): audio.voice_blip(0.8 + 0.1 * k))


func tick(dt: float) -> void:
	var i := 0
	while i < _queue.size():
		_queue[i].t -= dt
		if _queue[i].t <= 0.0:
			var e: Dictionary = _queue.pop_at(i)
			said.emit(String(e.text), float(e.dur))
			speak(String(e.text))
		else:
			i += 1


## Bỏ hết câu đang chờ và câu LLM đang xin (rời trận, về sảnh, về menu).
func clear() -> void:
	_queue.clear()
	_final = false
	if llm:
		llm.cancel()
	if _voice_id != "" and DisplayServer.get_name() != "headless":
		DisplayServer.tts_stop()


# ---------- phản ứng theo diễn biến ----------
func on_door(m: MatchManager, i: int, door: DoorBase) -> void:
	_kills_this_door = 0
	_final = false
	if i == 0:
		_streak.clear()
		_leader = -1
	queue_line(Lines.door_intro(door.id, rng), 0.6)
	if llm_enabled:
		llm.request(Lines.prompt_door(m, i, door))


func on_kill(m: MatchManager, s: Subject, mode: String) -> void:
	_kills_this_door += 1
	var k := int(_streak.get(s.idx, 0)) + 1
	_streak[s.idx] = k
	for o in m.subjects:
		if o != s:
			_streak[o.idx] = 0
	if k == 3:
		queue_line(Lines.streak(m.subj_label(s), rng), 1.4)
	elif _kills_this_door == 1 and m.lt < 5.0 and m.state == MatchManager.ST_PLAY:
		queue_line(Lines.early_death(m.subj_label(s), mode, rng), 1.4)


func on_round_end(m: MatchManager) -> void:
	var best := 0
	for i in Seats.N:
		if int(m.totals[i]) > int(m.totals[best]):
			best = i
	if best != _leader and m.door_index > 0:
		queue_line(Lines.new_leader(m.subj_label(m.subjects[best]), rng), 2.4)
	elif _kills_this_door == 0 and not m.door.scores_tiles:
		queue_line(Lines.no_deaths(rng), 2.4)
	_leader = best
	if llm_enabled:
		llm.request(Lines.prompt_round(m))


func on_final(m: MatchManager, best: int) -> void:
	_final = true
	queue_line(Lines.final(m.subj_label(m.subjects[best]), rng), 4.0)
	if llm_enabled:
		llm.request(Lines.prompt_final(m, best))


func on_sabotage(m: MatchManager, s: Subject) -> void:
	queue_line(Lines.sabotage(m.subj_label(s), rng), 1.8)
