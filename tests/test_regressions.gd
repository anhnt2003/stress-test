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
	net.close()
	t.ok("rời phòng thì hết chế độ máy khách", not m.remote and not net.is_online())
	net.queue_free()
	m.queue_free()
	await t.process_frame


func run(t) -> void:
	# c_hello lặp lại / vào lại trước khi máy chủ phát hiện mất kết nối
	var seats := Seats.new()
	seats.assign(2, NetSource.new(77, "A"), "A")
	var peers := {77: {"seat": 2, "name": "A", "token": "tok"}}
	t.check("cùng token khi kết nối cũ còn: tiếp quản ghế cũ", NetSession.plan_seat(seats, peers, {}, "tok"), {"seat": 2, "takeover": 77})
	t.check("token khác: ghế bot đầu tiên", NetSession.plan_seat(seats, peers, {}, "khác"), {"seat": 0, "takeover": 0})
	t.check("token rỗng không tiếp quản", NetSession.plan_seat(seats, {77: {"seat": 2, "name": "A", "token": ""}}, {}, ""), {"seat": 0, "takeover": 0})
	t.check("đang chờ vào lại: ghế cũ", NetSession.plan_seat(seats, {}, {"x": 3}, "x"), {"seat": 3, "takeover": 0})
	# Cài đặt: kéo thanh âm lượng không đụng tới cửa sổ
	var st := Settings.new()
	t.ok("lần đầu phải áp cửa sổ", st.window_changed())
	st._window_applied = st.window_key()
	st.music = 0.1
	t.ok("đổi âm lượng không áp lại cửa sổ", not st.window_changed())
	st.resolution = 0
	t.ok("đổi độ phân giải thì áp lại cửa sổ", st.window_changed())
