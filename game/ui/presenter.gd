class_name Presenter
extends Node
## Phần hình ảnh và âm thanh của trận: buồng thử, camera, HUD, bảng điểm, sảnh, âm thanh.
## Phản ứng với signal của MatchManager; không đổi luật chơi.

const HUD_SCENE := preload("res://game/ui/hud.tscn")
const INTRO_SCENE := preload("res://game/ui/intro_banner.tscn")
const RESULT_SCENE := preload("res://game/ui/result_panel.tscn")
const LOBBY_SCENE := preload("res://game/ui/lobby_panel.tscn")

var m: MatchManager
var chamber: Chamber
var chamber_variant := -1
## Cả 3 buồng được tạo sẵn lúc khởi động: tạo GPUParticles3D giữa trận sẽ rút số từ RNG chung
## (hàm khởi tạo của nó gọi Math::rand) và làm lệch chuỗi ngẫu nhiên của luật chơi.
var _chambers: Array[Chamber] = []
var cam: CameraFX
var hud: Node
var intro: Control
var result: Panel
var lobby: Control
var audio: GameAudio
var voice: MachineVoice
var overlay_layer: CanvasLayer
var paused := false
## Menu chính đang mở (ẩn chữ lớn và tiêu đề HUD để khỏi chồng lên menu).
var menu_open := false
## Đổi biến thể buồng theo cửa (giai đoạn 5).
var rotate_chambers := true


func setup(match_: MatchManager, audio_: GameAudio, voice_: MachineVoice) -> void:
	m = match_
	audio = audio_
	voice = voice_
	cam = CameraFX.new()
	add_child(cam)
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 3
	add_child(overlay_layer)
	intro = INTRO_SCENE.instantiate()
	hud.add_child(intro)
	result = RESULT_SCENE.instantiate()
	hud.add_child(result)
	lobby = LOBBY_SCENE.instantiate()
	hud.add_child(lobby)
	_use_chamber(0)
	m.cam_yaw = CameraFX.yaw()
	InputSource.cam_yaw = m.cam_yaw
	m.door_loaded.connect(_on_door_loaded)
	m.killed.connect(_on_killed)
	m.announced.connect(_on_announced)
	m.sfx_requested.connect(func(n, v, p): audio.sfx(n, v, p))
	m.shake_requested.connect(func(a): cam.kick(a))
	m.state_changed.connect(_on_state)
	m.round_ended.connect(func(_rows): voice.on_round_end(m))
	m.match_ended.connect(func(_rows, best): voice.on_final(m, best))
	m.sabotaged.connect(func(s, _hint): voice.on_sabotage(m, s))


func _use_chamber(v: int) -> void:
	if v == chamber_variant:
		return
	if _chambers.is_empty():
		for i in Chamber.SCENES.size():
			_chambers.append(Chamber.create(i))
	if chamber:
		remove_child(chamber)
	chamber = _chambers[v]
	add_child(chamber)
	move_child(chamber, 0)
	chamber_variant = v
	chamber.set_gore(m.gore.enabled)


func set_gore(on: bool) -> void:
	m.gore.enabled = on
	for c in _chambers:
		c.set_gore(on)


func _exit_tree() -> void:
	for c in _chambers:
		if is_instance_valid(c) and not c.is_inside_tree():
			c.free()


func _on_door_loaded(i: int, door: DoorBase) -> void:
	if rotate_chambers:
		_use_chamber(0 if i < 0 else [0, 1, 2][i % 3])
	cam.frame(door.cam_base, door.cam_look)
	cam.reset_fx()
	hud.reset_fx()
	chamber.clear_alert()
	result.visible = false
	if i <= 0:
		voice.clear()   # về sảnh / trận mới: máy khách không qua Flow nên lời bình (và câu LLM) cũ phải bỏ ở đây
	if i < 0:
		hud.set_titles("STRESS TEST", door.rule)
		chamber.set_idle("STRESS TEST\nCHỜ ĐỐI TƯỢNG")
		lobby.refresh(m)
	else:
		hud.set_titles("CỬA %d/10  ·  %s" % [i + 1, door.title], door.rule, door.sabotage_hint if m.sabotage_enabled else "")
		chamber.set_idle("CỬA %d/10\n%s" % [i + 1, door.title])
		voice.on_door(m, i, door)


func _on_state(st: int) -> void:
	audio.set_intensity(st == MatchManager.ST_PLAY)


func _on_killed(s: Subject, mode: String, _dir: Vector3, _pos: Vector3) -> void:
	audio.death(mode)
	hud.show_stamp()
	cam.blink(1.0)
	cam.kick(1.0)
	chamber.alert("ĐỐI TƯỢNG %s\nĐÃ LOẠI BỎ" % m.subj_label(s))
	voice.on_kill(m, s, mode)


func _on_announced(text: String, duration: float) -> void:
	hud.say(text, duration)


## Gọi mỗi khung trước khi luật chạy.
func pre_step(dt: float) -> void:
	cam.decay(dt)
	hud.decay(dt)


## Gọi mỗi khung sau khi luật chạy.
func post_step(dt: float) -> void:
	chamber.animate(m.t, dt)
	cam.update(m.t)
	refresh()


func refresh() -> void:
	var st := m.state
	var show := (st == MatchManager.ST_RESULT and m.state_t > 0.8) or (st == MatchManager.ST_FINAL and m.state_t > 3.4)
	hud.refresh(m, show)
	hud.title.visible = st != MatchManager.ST_LOBBY and not menu_open
	hud.rule.visible = hud.title.visible
	lobby.visible = st == MatchManager.ST_LOBBY and not paused and not menu_open
	if lobby.visible:
		lobby.refresh(m)
	if menu_open or paused:
		intro.visible = false
	elif st == MatchManager.ST_LOBBY:
		intro.show_text("STRESS TEST", "10 CỬA  ·  CHẾT ÍT NHẤT THÌ THẮNG", true)
	elif st == MatchManager.ST_INTRO:
		intro.show_text("CỬA %d/10  ·  %s" % [m.door_index + 1, m.door.title], m.door.rule)
	else:
		intro.visible = false
	if show and not result.visible:
		var fin := st == MatchManager.ST_FINAL
		var head := "TỔNG KẾT 10 CỬA" if fin else ("KẾT QUẢ CỬA %d/10  ·  %s" % [m.door_index + 1, m.door.title])
		var foot := ("ESC: RỜI PHÒNG   ·   CHỜ MÁY CHỦ CHƠI LẠI" if m.remote else "ENTER / START: CHƠI LẠI   ·   ESC: VỀ SẢNH") if fin else "HẠNG 1-4: +4 +3 +2 +1   ·   BẰNG SỐ LẦN CHẾT THÌ XÉT AI CHẾT LẦN ĐẦU MUỘN HƠN"
		result.show_rows(head, foot, m.last_rows, m.seats.looks, fin)
	elif not show:
		result.visible = false
