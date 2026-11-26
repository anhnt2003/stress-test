extends DoorBase
## Cửa TẠ RƠI: vòng đỏ hiện ở đâu, tạ nện xuống ở đó.

const HANG := 4.55
const TOP := 7.0

var weights: Array[Dictionary] = []
var weight_t := 0.0
var weight_id := 0


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 8
	title = "TẠ RƠI"
	rule = "Vòng đỏ hiện ở đâu, tạ nện xuống ở đó"
	sabotage_hint = "THẢ TẠ LÊN ĐẦU NGƯỜI GẦN NHẤT"


func setup(level_root: Node3D) -> void:
	super(level_root)
	build_platform(PLATFORM_R)
	var steel := Build.grime(Color(0.24, 0.23, 0.20), 0.6, 0.8, 0.6, 14.0)
	for i in 6:
		var n := Node3D.new()
		root.add_child(n)
		Build.cyl(n, 0.82, 0.82, 0.8, steel, Vector3(0, 0.4, 0), Vector3.ZERO, 14)
		Build.cyl(n, 0.84, 0.84, 0.1, Build.mat(Color(0.20, 0.01, 0.01), 0.2), Vector3(0, 0.05, 0), Vector3.ZERO, 14)
		Build.cyl(n, 0.3, 0.5, 0.3, steel, Vector3(0, 0.95, 0), Vector3.ZERO, 10)
		Build.cyl(n, 0.045, 0.045, 5.0, Build.mat(Palette.STEEL_DARK, 0.5, 0.7), Vector3(0, 3.6, 0), Vector3.ZERO, 5)
		n.position = Vector3(0, TOP, 0)
		var ring := Node3D.new()
		root.add_child(ring)
		var tr := Build.torus(ring, 0.80, 0.90, Build.glow(Color(1.0, 0.08, 0.04), 2.5), Vector3(0, 0.02, 0))
		tr.scale = Vector3(1, 0.1, 1)
		var sm := Build.mat(Color(0.5, 0.0, 0.0, 0.28), 0.6)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var sd := Build.add_mesh(ring, m.gore.disc_mesh, sm, Vector3(0, 0.014, 0))
		ring.visible = false
		weights.append({"n": n, "ring": ring, "shadow": sd, "state": 0, "timer": 0.0, "pos": Vector2.ZERO, "id": i})
	weight_t = 1.5
	weight_id = 10
	spawn_circle(2.0, 0.9)


func _arm(w: Dictionary, q: Vector2) -> void:
	weight_id += 1
	w.pos = q
	w.id = weight_id
	w.state = 1
	w.timer = 0.95
	(w.ring as Node3D).position = Vector3(q.x, PLATFORM_TOP, q.y)
	(w.ring as Node3D).visible = true
	(w.n as Node3D).position = Vector3(q.x, HANG, q.y)


func _free_weight() -> Dictionary:
	for w in weights:
		if w.state == 0:
			return w
	return {}


## Hình ảnh của quả tạ theo trạng thái (dùng chung cho máy chủ và máy khách).
func _pose(w: Dictionary) -> void:
	var n: Node3D = w.n
	var wp: Vector2 = w.pos
	match int(w.state):
		0:
			n.position.y = TOP
			(w.ring as Node3D).visible = false
		1:
			var g := 1.0 - float(w.timer) / 0.95
			(w.shadow as Node3D).scale = Vector3(0.82 * g, 1, 0.82 * g)
			n.position = Vector3(wp.x + sin(m.t * 40.0) * 0.015, HANG, wp.y)
			(w.ring as Node3D).visible = true
			(w.ring as Node3D).position = Vector3(wp.x, PLATFORM_TOP, wp.y)
		2:
			n.position = Vector3(wp.x, lerpf(PLATFORM_TOP, HANG, clampf(float(w.timer) / 0.1, 0.0, 1.0)), wp.y)
		3:
			n.position = Vector3(wp.x, PLATFORM_TOP, wp.y)
			(w.ring as Node3D).visible = false
		4:
			n.position = Vector3(wp.x, lerpf(TOP, PLATFORM_TOP, clampf(float(w.timer) / 0.7, 0.0, 1.0)), wp.y)
			(w.ring as Node3D).visible = false


func tick(dt: float) -> void:
	var k := k_round()
	weight_t -= dt
	if weight_t <= 0.0:
		weight_t = lerpf(1.25, 0.5, k)
		for w in weights:
			if w.state == 0:
				var q := Build.rand_circle(0.0, PLATFORM_R - 0.9)
				if randf() < 0.7:
					var tb: Subject = subjects()[randi() % 4]
					if tb.out <= 0.0:
						var tp := tb.position
						q = (Vector2(tp.x, tp.z) + Build.rand_circle(0.0, 0.45)).limit_length(PLATFORM_R - 0.9)
				_arm(w, q)
				break
	for w in weights:
		var n: Node3D = w.n
		var wp: Vector2 = w.pos
		match w.state:
			1:
				w.timer -= dt
				var g := 1.0 - float(w.timer) / 0.95
				(w.shadow as Node3D).scale = Vector3(0.82 * g, 1, 0.82 * g)
				n.position = Vector3(wp.x + sin(m.t * 40.0) * 0.015, HANG, wp.y)
				if w.timer <= 0.0:
					w.state = 2
					w.timer = 0.1
			2:
				w.timer -= dt
				n.position.y = lerpf(PLATFORM_TOP, HANG, clampf(float(w.timer) / 0.1, 0.0, 1.0))
				if w.timer <= 0.0:
					w.state = 3
					w.timer = 0.55
					m.shake(0.6)
					m.play_sfx("slam", -4.0, 1.15)
					(w.ring as Node3D).visible = false
					for s in subjects():
						if s.out > 0.0:
							continue
						var p := s.position
						if Vector2(p.x, p.z).distance_to(wp) < 0.9:
							m.kill(s, "crush")
							m.announce("ĐỐI TƯỢNG %s: CHỊU TẢI KÉM." % m.subj_label(s))
			3:
				w.timer -= dt
				if w.timer <= 0.0:
					w.state = 4
					w.timer = 0.7
			4:
				w.timer -= dt
				n.position.y = lerpf(TOP, PLATFORM_TOP, clampf(float(w.timer) / 0.7, 0.0, 1.0))
				if w.timer <= 0.0:
					w.state = 0
		if w.state == 1 or w.state == 2:
			for s in subjects():
				if s.out <= 0.0:
					var p2 := s.position
					if Vector2(p2.x, p2.z).distance_to(wp) < 1.0:
						s.scared = true
	# tạ đang nằm trên sàn thì chắn đường
	for s in subjects():
		if s.out > 0.0:
			continue
		for w in weights:
			if w.state == 3 or (w.state == 4 and w.timer > 0.55):
				var dv := Vector2(s.position.x, s.position.z) - (w.pos as Vector2)
				if dv.length() < 1.1 and dv.length() > 0.01:
					var q2 := (w.pos as Vector2) + dv.normalized() * 1.1
					s.position = Vector3(q2.x, s.position.y, q2.y)


func client_tick(dt: float) -> void:
	for w in weights:
		w.timer = maxf(0.0, float(w.timer) - dt)
		_pose(w)


func bot_steer(s: Subject, b: BotBrain, _dt: float, _arrived: bool, retarget: bool) -> Variant:
	var flat := Vector2(s.position.x, s.position.z)
	var fleeing := false
	for w in weights:
		if (w.state == 1 or w.state == 2) and flat.distance_to(w.pos) < 1.3 and Build.hash1(float(w.id) * 1.3 + float(s.idx) * 7.7) > 0.17:
			var away8: Vector2 = flat - (w.pos as Vector2)
			if away8.length() < 0.05:
				away8 = Vector2(1, 0).rotated(float(s.idx) * 1.7)
			b.set_target(((w.pos as Vector2) + away8.normalized() * 2.0).limit_length(PLATFORM_R - 0.6), 0.5)
			fleeing = true
	if retarget and not fleeing:
		b.set_target(Build.rand_circle(0.3, PLATFORM_R - 0.7), randf_range(1.0, 2.5))
	return null


func _nearest_other(s: Subject) -> Subject:
	var best: Subject = null
	var bd := 1e9
	for o in subjects():
		if o != s and o.alive():
			var d := o.position.distance_to(s.position)
			if d < bd:
				bd = d
				best = o
	return best


func bot_wants_sabotage(_s: Subject, _b: BotBrain, dt: float) -> bool:
	return m.lt > 3.0 and randf() < 0.1 * dt


func sabotage(s: Subject) -> bool:
	var o := _nearest_other(s)
	var w := _free_weight()
	if o == null or w.is_empty():
		return false
	_arm(w, Vector2(o.position.x, o.position.z).limit_length(PLATFORM_R - 0.9))
	w.timer = 0.75   # rơi nhanh hơn tạ thường
	return true


func net_state() -> Dictionary:
	var ws := []
	for w in weights:
		ws.append([int(w.state), float(w.timer), w.pos, int(w.id)])
	return {"w": ws}


func apply_net_state(st: Dictionary) -> void:
	var ws: Array = st.get("w", [])
	if ws.size() != weights.size():
		return
	for i in ws.size():
		var w: Dictionary = weights[i]
		var e: Array = ws[i]
		if int(e[0]) == 3 and int(w.state) == 2:
			m.shake(0.6)
		w.state = int(e[0])
		w.timer = float(e[1])
		w.pos = e[2]
		w.id = int(e[3])
