extends RefCounted
## Kiểm thử hồi quy cho các lỗi tìm thấy khi review code (/code-review).

const MAIN := preload("res://main.tscn")


func run_async(t) -> void:
	# Mở phòng ngay lúc khởi động (--host / --lobby): sảnh phải được nạp dù MatchManager đã ở ST_LOBBY
	var app = MAIN.instantiate()
	t.root.add_child(app)
	await t.process_frame
	app.m.door = null
	app.flow.enter_lobby()
	t.ok("vào sảnh khi chưa nạp sảnh thì nạp sảnh", app.m.door != null and app.m.subjects.size() == 4)
	app.flow.change_look(0, 1, 0)
	t.check("đổi mũ ở sảnh dựng lại hình nhân", app.m.subjects[0].look.hat, 1)
	# Menu tạm dừng mở khi máy chủ đưa về sảnh: vẫn đóng được
	app.flow.paused = true
	app.menus.pause_menu.open(true)
	app.flow.toggle_pause()
	t.ok("ở sảnh vẫn đóng được menu tạm dừng đang mở", not app.flow.paused and not app.menus.pause_menu.visible)
	app.flow.toggle_pause()
	t.ok("ở sảnh không mở menu tạm dừng mới", not app.flow.paused)
	# Tổng kết: bấm A / Enter ngay khi hết trận không bỏ qua bảng xếp hạng
	app.m._set_state(MatchManager.ST_FINAL)
	app.flow._on_start()
	t.check("vừa vào tổng kết: chưa cho chơi lại", app.m.state, MatchManager.ST_FINAL)
	app.flow._on_back()
	t.check("vừa vào tổng kết: B / Esc chưa về sảnh", app.m.state, MatchManager.ST_FINAL)
	app.m.state_t = 5.0
	app.flow._on_start()
	t.check("bảng đã hiện: chơi lại được", app.m.state, MatchManager.ST_INTRO)
	# Máy chủ rời menu tạm dừng bằng "Chơi lại" / "Về sảnh": máy khách phải được báo chơi tiếp
	app.net.mode = "host"
	app.net.m = app.m
	app.flow.paused = true
	app.net.host_paused = true
	app.flow.start_match()
	t.ok("chơi lại từ menu tạm dừng: hết tạm dừng ở máy chủ và máy khách", not app.flow.paused and not app.net.host_paused)
	app.flow.paused = true
	app.net.host_paused = true
	app.flow.enter_lobby()
	t.ok("về sảnh từ menu tạm dừng: hết tạm dừng ở máy chủ và máy khách", not app.flow.paused and not app.net.host_paused)
	app.net.mode = ""
	# Mỗi trận một seed mới (trừ khi chạy với --seed)
	app.flow.fixed_seed = false
	app.flow.start_match()
	var s1: int = app.m.seed_base
	app.flow.start_match()
	t.ok("hai trận liên tiếp khác seed", app.m.seed_base != s1 and s1 != 0)
	app.flow.fixed_seed = true
	app.m.seed_base = 42
	app.flow.start_match()
	t.check("có --seed thì giữ nguyên seed", app.m.seed_base, 42)
	# Máy khách về sảnh (không qua Flow): lời bình cũ và câu tổng kết 999 giây bị bỏ
	app.voice._queue.append({"t": 0.0, "text": "CÂU CŨ", "dur": 3.0})
	app.voice._final = true
	app.m.load_lobby()
	t.ok("nạp sảnh: bỏ lời bình cũ và cờ tổng kết", app.voice._queue.is_empty() and not app.voice._final)
	app.queue_free()
	await t.process_frame

	# Vòng lửa: nhảy liên tục ngoài vùng an toàn vẫn bị cháy
	var m := MatchManager.new()
	t.root.add_child(m)
	m.load_door(9, false)
	var d := m.door
	var s: Subject = m.subjects[0]
	m.lt = 25.0   # cuối cửa: vùng an toàn đã co nhỏ
	var killed := false
	for k in 180:
		s.position = Vector3(3.0, DoorBase.PLATFORM_TOP, 0.0)   # luôn ngoài vùng (vùng an toàn ở giữa)
		s.ground = k % 40 == 0                                  # chạm sàn 1 khung, bay 39 khung
		d.tick(1.0 / 60.0)
		if s.out > 0.0:
			killed = true
			break
	t.ok("nhảy liên tục ngoài vòng lửa vẫn cháy", killed)

	# Người được giữ lại lưu trên MatchManager (gửi đúng cho người vào lúc tổng kết)
	m.totals = [10, 30, 30, 5]
	m.total_deaths = [0, 0, 0, 0]
	m._enter_final()
	t.check("người thắng khi đồng điểm: ghế cuối cùng có hạng 1, giống câu công bố", m.best, 2)
	# Máy khách vào giữa trận: ảnh chụp báo đã chết thì đánh dấu chết, không chờ RPC đã lỡ
	var net := NetSession.new()
	t.root.add_child(net)
	net.m = m
	m.load_door(0, false)
	var s2: Subject = m.subjects[1]
	net._sync_dead(s2, 2.9, NetSession.MODES.find("crush"))
	t.ok("vừa chết (RPC sắp tới): chưa đánh dấu", s2.out <= 0.0)
	net._sync_dead(s2, 1.5, NetSession.MODES.find("crush"))
	t.ok("chết đã lâu: đánh dấu chết, ẩn hình nhân", s2.out > 0.0 and not s2.pivot.visible and s2.dead_mode == "crush")
	m.subjects[2].out = 1.2
	m.subjects[2].dead_mode = "fry"
	var e: Array = net.snapshot().s[2]
	t.check("ảnh chụp có trạng thái chết và kiểu chết", [e[6], e[7]], [1.2, NetSession.MODES.find("fry")])
	# Vào phòng lại: bộ đếm nút bấm về 0 (máy chủ tạo NetSource mới)
	net._counts = [12, 3, 1]
	var err := net.join("127.0.0.1:24999", "x", m, Settings.new())
	t.check("vào phòng thành công (đang kết nối)", err, OK)
	t.check("bộ đếm nút bấm về 0 khi vào phòng", net._counts, [0, 0, 0])
	# Máy chủ tạm dừng: máy khách đứng hình, không tự chạy đồng hồ
	net._apply_load(0, 0, [0, 0, 0, 0], [0, 0, 0, 0])
	m._set_state(MatchManager.ST_PLAY)
	# Máy chủ tạm dừng: người vào lúc đó vẫn được đặt về vị trí của ảnh chụp
	var snap0 := net.snapshot()
	snap0.t = 50.0
	snap0.s[0][0] = Vector3(1.5, DoorBase.PLATFORM_TOP, -1.0)
	net._apply_snap(snap0)
	net.host_paused = true
	net.client_step(0.016)
	t.ok("máy chủ dừng: vị trí theo ảnh chụp mới nhất", m.subjects[0].position.is_equal_approx(Vector3(1.5, DoorBase.PLATFORM_TOP, -1.0)))
	net.host_paused = false
	net.host_paused = true
	var t0 := m.t
	net.client_step(0.5)
	t.check("máy chủ dừng: đồng hồ máy khách không chạy", m.t, t0)
	net.host_paused = false
	net.client_step(0.5)
	t.ok("máy chủ chơi tiếp: đồng hồ chạy lại", m.t > t0)
	# Máy chủ dừng: lần bấm nút không được đếm (khỏi nổ ra khi chơi tiếp)
	net.host_paused = true
	net.send_action("kb1", 0, "sabotage")
	t.check("máy chủ dừng: không đếm nút bấm", net._counts, [0, 0, 0])
	net.host_paused = false
	net.send_action("kb1", 0, "sabotage")
	t.check("máy chủ chạy: đếm nút bấm", net._counts, [0, 0, 1])
	# Ảnh chụp cũ đến sau lệnh thả người làm "chết" nhầm: ảnh chụp mới báo sống thì hồi lại
	var s3: Subject = m.subjects[3]
	net._sync_dead(s3, 0.05, NetSession.MODES.find("fry"))
	t.ok("ảnh chụp cũ đánh dấu chết", s3.out > 0.0 and not s3.pivot.visible)
	s3.animate(1.0, false)   # tư thế ngã của kiểu chết "fry" (ngả người ra sau)
	t.ok("lúc bị coi là chết: tư thế ngã", s3.pivot.rotation.x < -1.0)
	var snap := net.snapshot()
	snap.s[3][6] = 0.0
	net._apply_snap(snap)
	t.ok("ảnh chụp mới báo sống: hồi lại", s3.out <= 0.0 and s3.pivot.visible)
	t.ok("hồi lại: đứng thẳng, không nằm ngửa", is_zero_approx(s3.pivot.rotation.x) and is_zero_approx(s3.lower.rotation.x))
	# Menu đang mở: không gửi hướng đi
	net._test.move = Vector2(1, 0)
	net.input_blocked = true
	t.check("menu mở: không lái nhân vật", net.local_move(), Vector2.ZERO)
	net.input_blocked = false
	t.ok("menu đóng: lái được", net.local_move().length() > 0.9)
	net._test.erase("move")
	# Rời phòng: luật của máy chủ (chơi xấu, seed) không còn dính lại
	net._apply_lobby({"looks": m.seats.looks, "labels": ["", "", "", ""], "bots": [true, true, true, true], "names": ["", "", "", ""], "sab": false})
	net._apply_load(0, 777, [0, 0, 0, 0], [0, 0, 0, 0])
	net.close()
	t.ok("rời phòng thì hết chế độ máy khách", not m.remote and not net.is_online())
	t.ok("rời phòng: chơi xấu và seed trở về như trước khi vào", m.sabotage_enabled and m.seed_base == 0)
	# Lưỡi cưa trên máy khách quay tiếp giữa hai ảnh chụp
	m.load_door(2, false)
	var saw := m.door
	saw.arm_speed = 2.0
	var a0: float = saw.arm_angle
	saw.client_tick(0.05)
	t.ok("tay cưa máy khách quay giữa hai ảnh chụp", is_equal_approx(saw.arm_angle, a0 + 0.1))
	# Máy khách: ngoài lúc thi máy móc đứng yên như máy chủ (không rung theo ảnh chụp)
	var net2 := NetSession.new()
	t.root.add_child(net2)
	net2.m = m
	net2.mode = "client"
	net2._apply_load(2, 0, [0, 0, 0, 0], [0, 0, 0, 0])
	m._set_state(MatchManager.ST_INTRO)
	m.door.arm_speed = 2.0
	var a1: float = m.door.arm_angle
	net2.client_step(0.1)
	t.check("giới thiệu cửa: tay cưa máy khách đứng yên", m.door.arm_angle, a1)
	net2.mode = ""
	net2.queue_free()
	m.remote = false
	# Người vào lúc chấm điểm ở sàn nghiền thấy đúng các ô đã rơi
	m.load_door(6, false)
	var net3 := NetSession.new()
	t.root.add_child(net3)
	net3.m = m
	net3.mode = "client"
	net3._apply_load(6, 0, [0, 0, 0, 0], [0, 0, 0, 0])
	m._set_state(MatchManager.ST_RESULT)
	var st0 := PackedByteArray()
	st0.resize(m.door.tiles.size())
	st0[10] = 3 * 4   # ô 10 đã rơi hẳn trên máy chủ
	st0[11] = 2 * 4   # ô 11 rơi trên máy chủ ngay trước khi hết vòng, máy khách vẫn đang thấy rung
	m.door.tiles[11].state = 1
	m.door.tiles[11].hp = 0
	m.door.tiles[11].timer = 0.5
	var sn := {"t": 5.0, "lt": 30.0, "stt": 1.0, "d": 6, "s": [], "x": {"t": st0}}
	net3._apply_snap(sn)
	t.ok("ô đã rơi trên máy chủ thì ẩn ngay ở máy khách", not (m.door.tiles[10].mi as Node3D).visible)
	t.ok("ô đang rung khi đã hết vòng: ẩn luôn (không đứng yên giữa sàn)", not (m.door.tiles[11].mi as Node3D).visible)
	net3.mode = ""
	net3.queue_free()
	m.remote = false
	# Máy khách: quả tạ được treo ở chỗ mới thì đặt ngay vào chỗ đó (không lướt từ chỗ cũ)
	m.load_door(5, false)
	var wd = m.door
	var w0: Dictionary = wd.weights[0]
	var ent := []
	for w in wd.weights:
		ent.append([int(w.state), float(w.timer), w.pos, int(w.id)])
	ent[0] = [1, 0.9, Vector2(1.2, -0.8), int(w0.id) + 1]
	wd.apply_net_state({"w": ent})
	var wn: Node3D = w0.n
	t.ok("quả tạ treo lại: đặt ngay ở chỗ mới", absf(wn.position.x - 1.2) < 0.05 and absf(wn.position.z + 0.8) < 0.05 and (w0.ring as Node3D).visible)
	# Collider của máy ép đi theo máy ép (không nằm lại giữa sàn)
	m.load_door(0, false)
	for i in 4:
		await t.physics_frame
	var q := PhysicsPointQueryParameters3D.new()
	q.collision_mask = DoorBase.LAYER_OBSTACLE
	q.position = m.door.press.global_position + Vector3(0, 0.65, 0)
	t.ok("có collider tại vị trí máy ép", m.get_world_3d().direct_space_state.intersect_point(q).size() > 0)
	q.position = Vector3(0, 0.65, 0)
	t.ok("không còn hộp vô hình giữa sàn", m.get_world_3d().direct_space_state.intersect_point(q).size() == 0)
	# Hết giờ đúng lúc rơi qua lỗ ở sàn nghiền: rơi tiếp vào máy, không treo giữa không trung
	m.load_door(6, false)
	var tl = m.door
	var sf: Subject = m.subjects[0]
	var ti: int = tl.tile_at(sf.position)
	tl.tiles[ti].state = 3
	sf.position.y = 1.0
	m._set_state(MatchManager.ST_RESULT)
	for k in 30:
		m._update_subject(sf, 1.0 / 60.0)
	t.ok("rơi qua lỗ lúc chấm điểm: rơi vào máy nghiền", sf.out > 0.0 and sf.dead_mode == "grind")
	net.queue_free()
	m.queue_free()
	await t.process_frame


func run(t) -> void:
	# c_hello lặp lại / vào lại trước khi máy chủ phát hiện mất kết nối / hai bản game cùng máy (cùng token)
	var seats := Seats.new()
	seats.assign(2, NetSource.new(77, "A"), "A")
	var now := 100.0
	var stale := {77: {"seat": 2, "name": "A", "token": "tok", "seen": now - 5.0}}
	var live := {77: {"seat": 2, "name": "A", "token": "tok", "seen": now - 0.2}}
	t.check("cùng token, kết nối cũ đã im lặng: tiếp quản ghế cũ", NetSession.plan_seat(seats, stale, {}, "tok", now), {"seat": 2, "takeover": 77})
	t.check("cùng token, kết nối cũ vẫn gửi input: không đá, cấp ghế khác", NetSession.plan_seat(seats, live, {}, "tok", now), {"seat": 0, "takeover": 0})
	t.check("token khác: ghế bot đầu tiên", NetSession.plan_seat(seats, stale, {}, "khác", now), {"seat": 0, "takeover": 0})
	t.check("token rỗng không tiếp quản", NetSession.plan_seat(seats, {77: {"seat": 2, "name": "A", "token": "", "seen": 0.0}}, {}, "", now), {"seat": 0, "takeover": 0})
	t.check("đang chờ vào lại: ghế cũ", NetSession.plan_seat(seats, {}, {"x": 3}, "x", now), {"seat": 3, "takeover": 0})
	# Cài đặt: kéo thanh âm lượng không đụng tới cửa sổ
	var st := Settings.new()
	t.ok("lần đầu phải áp cửa sổ", st.window_changed())
	st._window_applied = st.window_key()
	st.music = 0.1
	t.ok("đổi âm lượng không áp lại cửa sổ", not st.window_changed())
	st.resolution = 0
	t.ok("đổi độ phân giải thì áp lại cửa sổ", st.window_changed())
	# Người chơi mạng im lặng (rớt mạng chưa bị phát hiện) thì đứng lại
	var ns := NetSource.new(9, "B")
	ns.receive(Vector2(1, 0), [0, 0, 0], 10.0)
	t.check("vừa nhận input: đi theo", ns.current_move(10.2), Vector2(1, 0))
	t.check("im lặng quá lâu: đứng lại", ns.current_move(11.0), Vector2.ZERO)
	# Máy khách: nhãn ghế của mình có dấu "← BẠN"
	var cs := Seats.new()
	cs.sources[1] = NetSession.RemoteSeat.new("AN  (QUA MẠNG)  ← BẠN")
	cs.names[1] = "AN"
	t.check("nhãn ghế máy khách giữ dấu của mình", cs.label(1), "AN  (QUA MẠNG)  ← BẠN")
	# Gói input độc hại / hỏng bị bỏ qua
	var bad := NetSource.new(3, "X")
	t.ok("hướng đi INF bị bỏ", not bad.receive(Vector2(INF, 0), [0, 0, 0], 1.0) and bad.move == Vector2.ZERO)
	t.ok("hướng đi NaN bị bỏ", not bad.receive(Vector2(NAN, 0), [0, 0, 0], 1.0) and bad.move == Vector2.ZERO)
	t.ok("bộ đếm sai kiểu bị bỏ", not bad.receive(Vector2(1, 0), ["a", 0, 0], 1.0) and bad.move == Vector2.ZERO)
	t.ok("bộ đếm sai độ dài bị bỏ", not bad.receive(Vector2(1, 0), [1], 1.0) and bad.move == Vector2.ZERO)
	# Mã phòng chọn đúng IP LAN thật, bỏ card ảo / bridge / địa chỉ mạng
	var mac := [
		{"name": "bridge102", "friendly": "bridge102", "addresses": ["192.168.155.0"]},
		{"name": "bridge100", "friendly": "bridge100", "addresses": ["192.168.139.3"]},
		{"name": "utun3", "friendly": "utun3", "addresses": ["fe80::1"]},
		{"name": "en0", "friendly": "en0", "addresses": ["fe80::2", "192.168.134.27"]},
	]
	t.check("macOS: Wi-Fi thật đứng đầu, bỏ bridge ảo", RoomCode.rank_candidates(mac)[0], "192.168.134.27")
	t.ok("macOS: không chọn địa chỉ mạng .0", not RoomCode.rank_candidates(mac).has("192.168.155.0"))
	var win := [
		{"name": "{A1}", "friendly": "VirtualBox Host-Only Network", "addresses": ["192.168.56.1"]},
		{"name": "{B2}", "friendly": "Ethernet", "addresses": ["10.0.0.42"]},
		{"name": "{C3}", "friendly": "vEthernet (Default Switch)", "addresses": ["172.20.144.1"]},
		{"name": "{D4}", "friendly": "Tailscale", "addresses": ["100.101.102.103"]},
	]
	var wr := RoomCode.rank_candidates(win)
	t.check("Windows: Ethernet thật đứng đầu, rồi VPN LAN", [wr[0], wr[1]], ["10.0.0.42", "100.101.102.103"])
	t.check("Windows: card ảo xếp cuối", wr.slice(2), ["172.20.144.1", "192.168.56.1"])
	t.ok("máy này: IP mã phòng không phải địa chỉ mạng", not RoomCode.local_ipv4().ends_with(".0"))
	# Tên người chơi từ máy khách: bỏ ký tự điều khiển
	t.check("tên có xuống dòng", NetSession.sanitize_name("a\n\nb\tc"), "A  B C")
	t.check("tên dài bị cắt", NetSession.sanitize_name("x".repeat(40)).length(), 16)
	t.ok("tên quá dài bị từ chối trước khi xử lý", not NetSession.hello_ok("x".repeat(65), "tok") and NetSession.hello_ok("x".repeat(40), "tok"))
	t.ok("mã máy quá dài bị từ chối", not NetSession.hello_ok("AN", "t".repeat(65)))
	# Đổi màu áo bỏ qua màu ghế khác đang mặc (cửa sơn ô tô theo màu áo)
	var cl := Seats.new()
	cl.cycle_look(0, 0, 1)
	t.check("đổi màu: bỏ qua 3 màu ghế khác đang mặc", cl.looks[0].color, SubjectModel.COLORS[4])
	for k in 20:
		cl.cycle_look(k % 4, 0, 1 if k % 3 else -1)
	var used := {}
	for j in 4:
		used[cl.looks[j].color] = true
	t.check("đổi màu liên tục: 4 ghế vẫn 4 màu khác nhau", used.size(), 4)
	# Mã phòng: Wi-Fi nhà đứng trước VPN 10.x (OpenVPN / WireGuard trên Windows, tên hệ thống là GUID)
	var vpn := [
		{"name": "{E5}", "friendly": "OpenVPN TAP-Windows6", "addresses": ["10.8.0.2"]},
		{"name": "{F6}", "friendly": "wg0", "addresses": ["10.6.0.3"]},
		{"name": "{G7}", "friendly": "Wi-Fi", "addresses": ["192.168.1.5"]},
	]
	t.check("Windows: Wi-Fi 192.168 trước VPN 10.x", RoomCode.rank_candidates(vpn)[0], "192.168.1.5")
	var corp := [
		{"name": "{H8}", "friendly": "Local Area Connection", "addresses": ["10.20.30.40"]},
		{"name": "{I9}", "friendly": "ExpressVPN Adapter", "addresses": ["10.99.0.5"]},
	]
	t.check("\"Local Area Connection\" không bị coi là loopback, VPN xếp sau", RoomCode.rank_candidates(corp), ["10.20.30.40", "10.99.0.5"])
	var lin := [
		{"name": "lxcbr0", "friendly": "lxcbr0", "addresses": ["10.0.3.1"]},
		{"name": "ztks5abcde", "friendly": "ztks5abcde", "addresses": ["10.147.17.9"]},
		{"name": "eth0", "friendly": "eth0", "addresses": ["10.1.1.20"]},
	]
	t.check("Linux: eth0 trước ZeroTier, bridge LXC cuối", RoomCode.rank_candidates(lin), ["10.1.1.20", "10.147.17.9", "10.0.3.1"])
	var ics := [
		{"name": "{J1}", "friendly": "Local Area Connection* 12", "addresses": ["192.168.137.1"]},
		{"name": "{K2}", "friendly": "Ethernet", "addresses": ["10.0.0.7"]},
	]
	t.check("Windows: điểm phát Wi-Fi 192.168.137.x xếp sau LAN 10.x", RoomCode.rank_candidates(ics), ["10.0.0.7", "192.168.137.1"])
	# Ô vào phòng: localhost kèm cổng
	t.check("localhost:cổng", RoomCode.parse_address("localhost:9000", 24555), {"ip": "127.0.0.1", "port": 9000})
