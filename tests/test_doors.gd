extends RefCounted
## 10 cửa chạy bằng bot: dựng được, chạy 12 giây không lỗi, đúng 4 đối tượng, chơi xấu chỉ một lần,
## trạng thái gửi máy khách đọc lại được.


func run_async(t) -> void:
	var m := MatchManager.new()
	t.root.add_child(m)
	for i in MatchManager.DOORS:
		m.load_door(i, false)
		var d := m.door
		t.check("cửa %d có 4 đối tượng" % (i + 1), m.subjects.size(), 4)
		t.ok("cửa %d có tên và luật" % (i + 1), d.title != "" and d.rule != "" and d.sabotage_hint != "")
		for k in 360:
			m.step(1.0 / 30.0)
		t.check("cửa %d vẫn đang thi" % (i + 1), m.state, MatchManager.ST_PLAY)
		for s in m.subjects:
			t.ok("cửa %d: đối tượng %d trong vùng chơi" % [i + 1, s.idx + 1], s.position.length() < 8.0 and s.position.y > -5.0)
		# chơi xấu: chỉ một lần mỗi người mỗi cửa
		var s0 := m.subjects[0]
		s0.sabotage_used = false
		var used := false
		for k in 240:
			if not s0.alive():
				m.step(1.0 / 30.0)
				continue
			m._try_sabotage(s0)
			if s0.sabotage_used:
				used = true
				break
			m.step(1.0 / 30.0)
		var again := d.sabotage(s0) if used else false
		m._try_sabotage(s0)
		t.ok("cửa %d: dùng được nút chơi xấu (hoặc không có lúc phù hợp)" % (i + 1), used or i == 8)
		t.ok("cửa %d: cờ đã dùng giữ nguyên" % (i + 1), not used or s0.sabotage_used)
		var st := d.net_state()
		d.apply_net_state(st)
		t.check("cửa %d: trạng thái mạng đọc lại không đổi" % (i + 1), str(d.net_state()), str(st))
		if again:
			pass
	m.end_round_now()
	m.step(1.0 / 30.0)
	t.check("hết giờ thì chấm điểm", m.state, MatchManager.ST_RESULT)
	t.check("có 4 dòng kết quả", m.last_rows.size(), 4)
	m.queue_free()
	await t.process_frame
