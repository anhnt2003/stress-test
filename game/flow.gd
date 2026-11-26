class_name Flow
extends Node
## Điều phối các màn: menu chính → sảnh → trận → tổng kết; tạm dừng, cài đặt, chơi qua mạng.

var app: Node
var m: MatchManager
var presenter: Presenter
var menus: Menus
var router: InputRouter
var net: NetSession
var settings: Settings
var paused := false
var _settings_from := ""


func setup(a: Node) -> void:
	app = a
	m = a.m
	presenter = a.presenter
	menus = a.menus
	router = a.router
	net = a.net
	settings = a.settings
	router.pause_pressed.connect(toggle_pause)
	router.start_pressed.connect(_on_start)
	router.back_pressed.connect(_on_back)
	router.restart_pressed.connect(restart)
	router.seat_toggled.connect(_on_seat)
	router.look_cycled.connect(_on_look)
	router.sabotage_toggled.connect(_on_sabotage_toggle)
	router.debug_door.connect(func(i): if not net.is_client(): m.load_door(i, true))
	router.debug_end_round.connect(func(): if not net.is_client(): m.end_round_now())
	router.local_action.connect(func(kind, dev, act): if net.is_client(): net.send_action(kind, dev, act))
	menus.main_menu.chosen.connect(_on_main)
	menus.pause_menu.chosen.connect(_on_pause_choice)
	menus.settings_menu.changed.connect(apply_settings)
	menus.settings_menu.closed.connect(_on_settings_closed)
	menus.join_dialog.connect_requested.connect(join)
	menus.join_dialog.closed.connect(show_menu)
	a.voice.said.connect(func(text, dur): presenter.hud.say(text, dur))
	m.announced.connect(func(text, _dur): a.voice.speak(text))
	net.status_changed.connect(_on_net_status)
	net.left.connect(_on_net_left)


func boot(cli: Dictionary) -> void:
	apply_settings()
	if int(cli.host) >= 0:
		host(int(cli.host))
	elif String(cli.join) != "":
		join(String(cli.join), String(cli.name))
	elif cli.lobby:
		enter_lobby()
	else:
		show_menu()


func apply_settings() -> void:
	settings.apply(app.audio)
	presenter.set_gore(settings.gore)
	presenter.cam.shake_scale = settings.shake
	app.voice.tts_enabled = settings.tts
	app.voice.llm_enabled = settings.llm and app.voice.llm.available()


# ---------- các màn ----------
func show_menu() -> void:
	paused = false
	net.close()
	m.seats = Seats.new()
	router.seats = m.seats
	m.load_lobby()
	menus.hide_all()
	menus.main_menu.open()


func enter_lobby() -> void:
	paused = false
	menus.hide_all()
	if m.state != MatchManager.ST_LOBBY:
		m.load_lobby()
	presenter.lobby.set_room(net.room_text() if net.is_host() else "")


func start_match() -> void:
	paused = false
	menus.hide_all()
	app.voice.clear()
	m.start_match()


func restart() -> void:
	if net.is_client():
		return
	start_match()


func toggle_pause() -> void:
	if m.state == MatchManager.ST_LOBBY or menus.main_menu.visible:
		return
	paused = not paused
	if paused:
		menus.pause_menu.open(net.is_client())
	else:
		menus.hide_all()


## Trận có đang dừng thật không (máy khách mạng tạm dừng thì trận của máy chủ vẫn chạy).
func sim_halted() -> bool:
	return paused and not net.is_client()


func update() -> void:
	presenter.paused = paused
	presenter.menu_open = menus.main_menu.visible or menus.overlay_open()
	if menus.overlay_open():
		router.screen = "overlay"
	elif menus.main_menu.visible:
		router.screen = "menu"
	elif paused:
		router.screen = "pause"
	elif m.state == MatchManager.ST_LOBBY:
		router.screen = "lobby"
	elif m.state == MatchManager.ST_FINAL:
		router.screen = "final"
	else:
		router.screen = "match"


# ---------- phản hồi input ----------
func _on_start() -> void:
	if net.is_client():
		return
	if m.state == MatchManager.ST_LOBBY or m.state == MatchManager.ST_FINAL:
		start_match()


func _on_back() -> void:
	if paused:
		_on_pause_choice("Lobby")
	elif m.state == MatchManager.ST_LOBBY:
		show_menu()
	elif m.state == MatchManager.ST_FINAL:
		if net.is_client():
			show_menu()
		else:
			enter_lobby()


func _on_seat(kind: String, dev: int) -> void:
	if net.is_client():
		net.send_action(kind, dev, "seat")
		return
	if m.seats.toggle(kind, dev) >= 0:
		app.audio.sfx("beep", -6.0)
		net.broadcast_lobby()


func _on_look(kind: String, dev: int, dh: int, dc: int) -> void:
	if net.is_client():
		net.send_look(dh, dc)
		return
	var i := m.seats.seat_of(kind, dev)
	if i < 0:
		return
	change_look(i, dh, dc)


func change_look(i: int, dh: int, dc: int) -> void:
	m.seats.cycle_look(i, dh, dc)
	if m.state == MatchManager.ST_LOBBY and m.door.has_method("refresh_look"):
		m.door.refresh_look(i)
	app.audio.sfx("beep", -10.0, 1.4)
	net.broadcast_lobby()


func _on_sabotage_toggle() -> void:
	if net.is_client():
		return
	m.sabotage_enabled = not m.sabotage_enabled
	app.audio.sfx("beep", -8.0, 0.8)
	net.broadcast_lobby()


func _on_main(action: String) -> void:
	match action:
		"Local":
			enter_lobby()
		"Host":
			host(NetSession.DEFAULT_PORT)
		"Join":
			menus.main_menu.visible = false
			menus.join_dialog.open(settings.last_join, settings.player_name)
		"Settings":
			_open_settings("menu")
		"Quit":
			get_tree().quit()


func _on_pause_choice(action: String) -> void:
	match action:
		"Resume":
			toggle_pause()
		"Restart":
			restart()
		"Settings":
			_open_settings("pause")
		"Lobby":
			if net.is_client():
				show_menu()
			else:
				enter_lobby()
				net.broadcast_lobby()
		"MainMenu":
			show_menu()


func _open_settings(from: String) -> void:
	_settings_from = from
	menus.main_menu.visible = false
	menus.pause_menu.visible = false
	menus.settings_menu.open(settings, app.voice.llm.available(), app.voice.has_tts())


func _on_settings_closed() -> void:
	apply_settings()
	if _settings_from == "pause":
		menus.pause_menu.open(net.is_client())
	else:
		menus.main_menu.open()


# ---------- mạng ----------
func host(port: int) -> void:
	paused = false
	m.seats = Seats.new()
	router.seats = m.seats
	var err := net.host(port, m, settings)
	if err != OK:
		show_menu()
		presenter.hud.say("KHÔNG MỞ ĐƯỢC PHÒNG (CỔNG %d ĐANG BẬN?)" % port, 4.0)
		return
	enter_lobby()


func join(address: String, player_name: String) -> void:
	settings.last_join = address
	settings.player_name = player_name
	settings.save()
	var err := net.join(address, player_name if player_name != "" else "KHÁCH", m, settings)
	if err != OK:
		menus.join_dialog.open(address, player_name)
		menus.join_dialog.set_status("MÃ PHÒNG / ĐỊA CHỈ KHÔNG HỢP LỆ.")
		return
	menus.join_dialog.set_status("ĐANG KẾT NỐI...")


func _on_net_status(text: String) -> void:
	if menus.join_dialog.visible:
		menus.join_dialog.set_status(text)
	if net.is_client() and net.connected:
		menus.hide_all()
		paused = false
	presenter.hud.say(text, 3.0)


func _on_net_left(reason: String) -> void:
	show_menu()
	presenter.hud.say(reason, 4.0)
