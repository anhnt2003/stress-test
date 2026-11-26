extends Node3D
## STRESS TEST — party game kinh dị 10 cửa cho 3–4 người (Godot 4.4).
## Điểm vào: dựng các thành phần, đọc tham số dòng lệnh (xem game/core/cli.gd), chạy vòng lặp chính.
## Luật chơi: game/match · cửa: game/doors · nhân vật + bot: game/actors · input: game/input
## Hình ảnh: game/world, game/ui, game/fx · âm thanh: game/audio · Cỗ Máy: game/machine · mạng: game/net

## Luật chơi chạy trong _physics_process (60 bước/giây) để truy vấn va chạm luôn thấy trạng thái mới nhất.
## Chạy không màn hình nhanh hơn thời gian thực: thêm `--fixed-fps 60` trước dấu `--`.

var cli := {}
var settings: Settings
var audio: GameAudio
var voice: MachineVoice
var m: MatchManager
var presenter: Presenter
var menus: Menus
var router: InputRouter
var net: NetSession
var flow: Flow
var frozen := false
var _quit_t := -1.0
var _shot_until := -1.0


func _ready() -> void:
	cli = Cli.parse(OS.get_cmdline_user_args())
	var shot: bool = cli.shot != ""
	settings = Settings.new() if shot else Settings.load_or_default()
	audio = GameAudio.new()
	audio.muted = shot or cli.balance > 0
	add_child(audio)
	voice = MachineVoice.new()
	voice.audio = audio
	add_child(voice)
	m = MatchManager.new()
	m.name = "Match"
	m.sabotage_enabled = cli.sabotage
	m.seed_base = int(cli.seed)
	add_child(m)
	presenter = Presenter.new()
	add_child(presenter)
	presenter.setup(m, audio, voice)
	menus = Menus.new()
	presenter.overlay_layer.add_child(menus)
	router = InputRouter.new()
	router.seats = m.seats
	router.debug_keys = router.debug_keys or cli.debug_keys
	add_child(router)
	net = NetSession.new()
	net.name = "Net"
	add_child(net)
	flow = Flow.new()
	add_child(flow)
	flow.setup(self)
	_quit_t = float(cli.quit_after)
	if cli.balance > 0:
		frozen = true
		voice.tts_enabled = false
		await Balance.run(self, int(cli.balance))
		get_tree().quit()
	elif shot:
		voice.tts_enabled = false
		_run_shot()
	else:
		flow.boot(cli)


func step(dt: float) -> void:
	presenter.pre_step(dt)
	if net.is_client():
		net.client_step(dt)
	else:
		if not flow.sim_halted():
			m.step(dt)
		net.host_step(dt)   # cả khi tạm dừng: người vào lúc đó vẫn nhận ảnh chụp, kết nối treo vẫn bị ngắt
	voice.tick(dt)
	presenter.post_step(dt)
	flow.update()


func _process(delta: float) -> void:
	if _quit_t > 0.0:
		_quit_t -= delta
		if _quit_t <= 0.0:
			get_tree().quit()


func _physics_process(delta: float) -> void:
	if frozen:
		return
	step(delta)
	if _shot_until >= 0.0 and m.t >= _shot_until - 0.0001:
		_finish_shot()


# ---------- chế độ chụp ảnh / mô phỏng không màn hình ----------
func _run_shot() -> void:
	m.log_events = true
	presenter.set_gore(cli.gore)
	if cli.settings:
		flow.show_menu()
		flow._on_main("Settings")
	elif cli.menu:
		flow.show_menu()
	elif cli.lobby:
		m.load_lobby()
		m.seats.assign(0, KeyboardSource.new(1))
		m.seats.assign(2, PadSource.new(0))
	elif cli.match:
		m.start_match()
	else:
		m.load_door(maxi(int(cli.door), 0), false)
	_shot_until = float(cli.phase)
	if _shot_until <= 0.0:
		_finish_shot()


func _finish_shot() -> void:
	_shot_until = -1.0
	frozen = true
	m.log_events = false
	if cli.closeup:
		for i in m.subjects.size():
			var s := m.subjects[i]
			s.pivot.visible = true
			s.position = Vector3(-1.5 + 1.0 * i, DoorBase.PLATFORM_TOP, 0.6)
			s.pivot.rotation = Vector3(0, 0.25 - 0.17 * i, 0)
		m.door.hide_for_closeup()
		presenter.cam.fov = 32.0
		presenter.cam.position = Vector3(0.0, 1.9, 4.6)
		presenter.cam.look_at(Vector3(0.0, 1.4, 0.6))
		presenter.cam.reset_physics_interpolation()
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
	else:
		_capture()


func _capture() -> void:
	for i in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()   # đã ở độ phân giải thật của cửa sổ
	img.save_png(String(cli.shot))
	print("saved ", cli.shot, " ", img.get_size())
	get_tree().quit()
