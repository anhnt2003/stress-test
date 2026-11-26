extends RefCounted
## Mạng: mã phòng, đọc địa chỉ, bộ đệm nội suy, chọn ghế khi vào / vào lại, input qua mạng.


func run(t) -> void:
	# mã phòng
	var code := RoomCode.encode("192.168.1.23", 24555)
	t.check("mã phòng dài 11 ký tự", code.length(), 11)
	t.check("giải mã đúng IP", RoomCode.decode(code), {"ip": "192.168.1.23", "port": 24555})
	t.check("không phân biệt hoa thường, bỏ gạch", RoomCode.decode(code.to_lower().replace("-", "")), {"ip": "192.168.1.23", "port": 24555})
	t.check("đọc nhầm O/0, I/1 vẫn đúng", RoomCode.decode(code.replace("0", "O").replace("1", "I")), {"ip": "192.168.1.23", "port": 24555})
	t.check("mã sai độ dài", RoomCode.decode("ABC"), {})
	t.check("mã có ký tự lạ", RoomCode.decode("ABCDE-FGH#J"), {})
	t.check("IP hỏng không mã hoá", RoomCode.encode("300.1.1.1", 80), "")
	t.check("cổng hỏng không mã hoá", RoomCode.encode("10.0.0.1", 0), "")
	t.check("biên: 255.255.255.255:65535", RoomCode.decode(RoomCode.encode("255.255.255.255", 65535)), {"ip": "255.255.255.255", "port": 65535})
	t.check("địa chỉ IP trần", RoomCode.parse_address("10.0.0.7", 24555), {"ip": "10.0.0.7", "port": 24555})
	t.check("địa chỉ IP:cổng", RoomCode.parse_address("10.0.0.7:9000", 24555), {"ip": "10.0.0.7", "port": 9000})
	t.check("localhost", RoomCode.parse_address("localhost", 24555), {"ip": "127.0.0.1", "port": 24555})
	t.check("địa chỉ là mã phòng", RoomCode.parse_address(code, 1), {"ip": "192.168.1.23", "port": 24555})
	t.check("địa chỉ rỗng", RoomCode.parse_address("  ", 1), {})
	t.check("cổng không phải số", RoomCode.parse_address("10.0.0.1:abc", 1), {})
	t.ok("IP LAN có dạng IPv4", RoomCode.local_ipv4().count(".") == 3)
	# nội suy
	var b := SnapshotBuffer.new()
	t.check("chưa có mẫu", b.sample(1.0), [])
	b.push(1.0, Vector3(0, 0, 0), 0.0)
	b.push(1.1, Vector3(1, 0, 0), 1.0)
	b.push(1.05, Vector3(9, 9, 9), 0.0)   # đến muộn: bỏ
	var mid := b.sample(1.05)
	t.ok("nội suy giữa hai mẫu", (mid[0] as Vector3).is_equal_approx(Vector3(0.5, 0, 0)))
	t.ok("nội suy hướng", is_equal_approx(float(mid[1]), 0.5))
	t.ok("trước mẫu đầu thì giữ mẫu đầu", (b.sample(0.5)[0] as Vector3).is_equal_approx(Vector3.ZERO))
	var ext: Vector3 = b.sample(2.0)[0]
	t.ok("ngoại suy có giới hạn", ext.x > 1.0 and ext.x <= 1.0 + SnapshotBuffer.MAX_EXTRAPOLATE / 0.1 + 0.01)
	for i in 40:
		b.push(2.0 + i * 0.05, Vector3(i, 0, 0), 0.0)
	t.ok("giới hạn số mẫu", b.samples.size() <= SnapshotBuffer.MAX_SAMPLES)
	# chọn ghế
	var seats := Seats.new()
	seats.assign(0, KeyboardSource.new(1))
	t.check("người mới vào ghế bot đầu tiên", NetSession.assign_seat(seats, {}, "abc"), 1)
	t.check("vào lại thì lấy ghế cũ", NetSession.assign_seat(seats, {"abc": 3}, "abc"), 3)
	seats.assign(3, PadSource.new(0))
	t.check("ghế cũ đã có người thì lấy ghế bot khác", NetSession.assign_seat(seats, {"abc": 3}, "abc"), 1)
	seats.assign(1, PadSource.new(1))
	seats.assign(2, PadSource.new(2))
	t.check("hết ghế", NetSession.assign_seat(seats, {}, "x"), -1)
	# input qua mạng: bộ đếm nút bấm
	var ns := NetSource.new(5, "A")
	t.ok("lần đầu không có bấm", not ns.receive(Vector2(2, 0), [0, 0, 0], 0.0))
	t.check("hướng đi bị giới hạn độ dài", ns.move, Vector2(1, 0))
	t.ok("đếm tăng là có bấm", ns.receive(Vector2.ZERO, [1, 0, 0], 0.1))
	t.ok("nhận nhảy", ns.jump_req and not ns.shove_req)
	ns.clear()
	t.ok("gói lặp lại không bấm thêm", not ns.receive(Vector2.ZERO, [1, 0, 0], 0.2))
	t.ok("mất gói vẫn nhận bấm", ns.receive(Vector2.ZERO, [1, 3, 1], 0.3) and ns.shove_req and ns.sabotage_req)
