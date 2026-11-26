class_name Balance
## Chạy nhiều trận bằng bot (không màn hình) với seed khác nhau, in thống kê để cân bằng cửa:
## số lần chết trung bình mỗi người mỗi cửa, tỉ lệ cửa không ai chết, chênh lệch điểm.
## Chạy: godot --headless --path . -- --balance=20

const DT := 1.0 / 30.0


static func run(app: Node, n: int) -> void:
	var m: MatchManager = app.m
	m.log_events = false
	var deaths := {}      # tên cửa -> tổng số lần chết
	var zero := {}        # tên cửa -> số trận không ai chết
	var spread := {}      # tên cửa -> tổng chênh lệch số lần chết giữa người nhiều nhất và ít nhất
	var sabot := {}       # tên cửa -> số lần chơi xấu
	var wins := [0, 0, 0, 0]
	var order: Array[String] = []
	var counter := {"sab": 0}
	m.sabotaged.connect(func(_s, _h): counter.sab += 1)
	for k in n:
		m.seed_base = k + 1
		m.start_match()
		var guard := 0
		var cur := -1
		while m.state != MatchManager.ST_FINAL and guard < 40000:
			if m.door_index != cur and m.state == MatchManager.ST_INTRO:
				cur = m.door_index
				counter.sab = 0
			var prev := m.state
			m.step(DT)
			guard += 1
			if m.state == MatchManager.ST_RESULT and prev == MatchManager.ST_PLAY:
				var nm := m.door.title
				if not order.has(nm):
					order.append(nm)
				var tot := 0
				var lo := 999
				var hi := 0
				for s in m.subjects:
					tot += s.deaths
					lo = mini(lo, s.deaths)
					hi = maxi(hi, s.deaths)
				deaths[nm] = int(deaths.get(nm, 0)) + tot
				zero[nm] = int(zero.get(nm, 0)) + (1 if tot == 0 else 0)
				spread[nm] = int(spread.get(nm, 0)) + (hi - lo)
				sabot[nm] = int(sabot.get(nm, 0)) + int(counter.sab)
		for r in m.last_rows:
			if int(r.rank) == 1:
				wins[int(r.idx)] += 1
	print("BALANCE matches=%d" % n)
	print("%-14s %8s %8s %8s %8s" % ["CỬA", "chết/ng", "0 chết", "chênh", "chơi xấu"])
	for nm in order:
		print("%-14s %8.2f %7d%% %8.2f %8.2f" % [nm, float(deaths[nm]) / (4.0 * n), int(100.0 * zero[nm] / n), float(spread[nm]) / n, float(sabot[nm]) / n])
	print("thắng theo ghế: %s" % str(wins))
