extends RefCounted
## Chơi online (WebRTC qua máy chủ mai mối): mã phòng online, chọn đường truyền khi vào phòng, menu theo bản.
## Kết nối thật giữa hai máy được kiểm thử ở CI (bước "Chơi online"), cần plugin webrtc-native và signaling/.

const MAIN := preload("res://main.tscn")


func run(t) -> void:
	# mã phòng online 6 ký tự: không nhầm với mã LAN (11 ký tự) hay địa chỉ IP
	t.check("mã online: bỏ gạch, chữ thường", OnlineLink.normalize_code("k7q-2mx"), "K7Q2MX")
	t.check("mã online: O/I/L đọc nhầm", OnlineLink.normalize_code(" ab0 oil "), "AB0011")
	t.check("mã online: sai độ dài", OnlineLink.normalize_code("K7Q2M"), "")
	t.check("mã online: ký tự lạ", OnlineLink.normalize_code("K7Q.MX"), "")
	t.check("mã online: chữ U không có trong bảng", OnlineLink.normalize_code("K7Q2MU"), "")
	t.check("mã LAN không bị coi là mã online", OnlineLink.normalize_code(RoomCode.encode("192.168.1.23", 24555)), "")
	t.check("IP không bị coi là mã online", OnlineLink.normalize_code("10.0.0.7"), "")
	t.check("hiển thị có gạch", OnlineLink.pretty("K7Q2MX"), "K7Q-2MX")
	t.check("lý do: không có phòng", OnlineLink.reason_text("no_room", "K7Q2MX"), "KHÔNG CÓ PHÒNG NÀO MÃ K7Q-2MX.")
	t.ok("lý do lạ vẫn có chữ", OnlineLink.reason_text("xyz").contains("XYZ") or OnlineLink.reason_text("xyz").contains("xyz"))
	t.check("bản trong repo chưa cấu hình máy chủ mai mối", OnlineConfig.signal_url(), OnlineConfig.SIGNAL_URL)
	t.check("--signal ghi đè", OnlineConfig.signal_url("ws://127.0.0.1:28787/ws"), "ws://127.0.0.1:28787/ws")
	t.check("mỗi mã lỗi có thông báo riêng", [Flow.online_error(ERR_UNCONFIGURED) != Flow.online_error(ERR_UNAVAILABLE),
		Flow.online_error(ERR_CANT_CONNECT).contains("LỖI")], [true, true])


func run_async(t) -> void:
	var app = MAIN.instantiate()
	t.root.add_child(app)
	await t.process_frame
	var net: NetSession = app.net
	# vào phòng online khi bản này không có máy chủ mai mối: báo lỗi, không đổi trạng thái
	t.check("mã online mà chưa cấu hình máy chủ mai mối", net.join("K7Q-2MX", "AN", app.m, app.settings, ""), ERR_UNCONFIGURED)
	t.ok("không vào chế độ máy khách", not net.is_online() and not app.m.remote)
	t.check("mở phòng online khi chưa cấu hình", net.host_online("", app.m, app.settings), ERR_UNCONFIGURED)
	t.ok("không mở phòng", not net.is_online())
	if not OnlineLink.available():
		t.check("thiếu WebRTC: báo lỗi riêng", net.join("K7Q-2MX", "AN", app.m, app.settings, "ws://127.0.0.1:1/ws"), ERR_UNAVAILABLE)
	# đường truyền WebRTC: peer chưa có / chưa nối xong thì không gửi RPC tới
	net.peer = WebRTCMultiplayerPeer.new()
	t.ok("WebRTC: peer không tồn tại thì không gửi", not net._peer_ok(5))
	net.peer = null
	# menu theo bản: web ẩn phòng LAN và nút thoát, bản có máy chủ mai mối hiện phòng online
	var b: Node = app.menus.main_menu.get_node("Buttons")
	app.menus.configure(false, true, false)
	t.check("bản web: chỉ phòng online", [b.get_node("Host").visible, b.get_node("HostOnline").visible, b.get_node("Join").visible, b.get_node("Quit").visible], [false, true, true, false])
	t.check("bản web: hướng dẫn vào phòng 6 ký tự", app.menus.join_dialog.get_node("LCode").text, "MÃ PHÒNG (6 KÝ TỰ)")
	app.menus.configure(true, true, true)
	t.check("desktop có online: phòng LAN đổi tên", b.get_node("Host").text, "TẠO PHÒNG LAN")
	app.menus.configure(true, false, true)
	t.check("desktop không có online: như cũ", [b.get_node("Host").visible, b.get_node("HostOnline").visible, b.get_node("Host").text], [true, false, "TẠO PHÒNG QUA MẠNG"])
	t.check("desktop không có online: hướng dẫn LAN như cũ", app.menus.join_dialog.get_node("LCode").text, "MÃ PHÒNG HOẶC IP[:CỔNG]")
	# phòng online: dòng mã phòng ở sảnh
	net.online = OnlineLink.new()
	net.mode = "host"
	net.room_code = ""
	t.check("đang chờ mã phòng", net.room_text(), "ĐANG TẠO PHÒNG ONLINE...")
	net.room_code = "K7Q2MX"
	t.ok("có mã phòng", net.room_text().begins_with("PHÒNG ONLINE  ·  MÃ PHÒNG: K7Q-2MX"))
	net.online.free()
	net.online = null
	net.mode = ""
	app.queue_free()
	await t.process_frame
