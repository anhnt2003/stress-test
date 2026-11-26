extends DoorBase
## Cửa BĂNG CHUYỀN: chạy ngược băng chuyền, né thùng hàng. Cuối băng là máy huỷ.

const BELT_L := 9.0
const BELT_W := 4.6
const BELT_TOP := 0.6

var belt_v := 1.3
var cleats: Array[Node3D] = []
var crates: Array[Dictionary] = []
var crate_t := 0.0
var crate_id := 0
var belt_items: Array[Node3D] = []
var shred: Array = []
## Chơi xấu: băng chạy nhanh gấp đôi trong vài giây.
var surge := 0.0


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 5
	title = "BĂNG CHUYỀN"
	rule = "Chạy ngược băng chuyền, né thùng hàng. Cuối băng là máy huỷ"
	sabotage_hint = "BĂNG CHUYỀN TĂNG TỐC"
	keep_corpses = false
	cam_look = Vector3(0.0, 0.5, -0.45)


func _toothed_roller(pos: Vector3, length: float, radius: float) -> Node3D:
	# trục có răng nằm dọc theo trục z
	var r := Node3D.new()
	root.add_child(r)
	r.position = pos
	r.rotation_degrees.x = 90.0
	Build.cyl(r, radius, radius, length, Build.grime(Color(0.30, 0.27, 0.24), 0.6, 0.7, 0.7, 14.0, 0.5), Vector3.ZERO, Vector3.ZERO, 10)
	var tm := Build.mat(Color(0.30, 0.05, 0.04), 0.3, 0.6)
	var n := int(length / 0.5)
	for k in n:
		for j in 4:
			var a := j * TAU / 4.0 + k * 0.5
			Build.box(r, Vector3(0.2, 0.16, 0.34), tm, Vector3(cos(a) * (radius + 0.04), -length / 2.0 + 0.3 + k * (length - 0.6) / maxf(n - 1, 1), sin(a) * (radius + 0.04)), Vector3(0, -rad_to_deg(a), 0))
	return r


func setup(level_root: Node3D) -> void:
	super(level_root)
	var hazard := Build.shader_mat("res://shaders/hazard.gdshader")
	var frame := Build.grime(Color(0.18, 0.17, 0.15), 0.6, 0.8, 0.5, 14.0)
	var steel := Build.grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.5, 14.0)
	Build.box(root, Vector3(BELT_L + 0.4, BELT_TOP - 0.06, BELT_W + 0.5), frame, Vector3(0, (BELT_TOP - 0.06) / 2.0, 0))
	Build.box(root, Vector3(BELT_L, 0.06, BELT_W), Build.mat(Color(0.035, 0.035, 0.035), 0.85), Vector3(0, BELT_TOP - 0.03, 0))
	static_box(root, Vector3(BELT_L + 0.4, BELT_TOP, BELT_W + 0.5), Vector3(0, BELT_TOP / 2.0, 0), LAYER_FLOOR)
	for s in [-1.0, 1.0]:
		Build.box(root, Vector3(BELT_L + 0.4, 0.22, 0.2), hazard, Vector3(0, BELT_TOP + 0.05, s * (BELT_W / 2.0 + 0.2)))
	for i in 12:
		cleats.append(Build.box(root, Vector3(0.08, 0.03, BELT_W - 0.1), Build.mat(Color(0.10, 0.10, 0.10), 0.7), Vector3(-BELT_L / 2.0 + i * 0.75, BELT_TOP + 0.012, 0)))
	# đầu nạp: thùng hàng chui ra từ dưới mái che có rèm cao su
	var fx := -BELT_L / 2.0 - 0.35
	Build.box(root, Vector3(1.1, 1.3, BELT_W + 0.7), steel, Vector3(fx, BELT_TOP + 1.75, 0))
	for s in [-1.0, 1.0]:
		Build.box(root, Vector3(1.1, BELT_TOP + 1.2, 0.25), steel, Vector3(fx, (BELT_TOP + 1.2) / 2.0, s * (BELT_W / 2.0 + 0.25)))
	for k in 7:
		Build.box(root, Vector3(0.03, 1.05, 0.58), Build.mat(Color(0.03, 0.03, 0.03), 0.6), Vector3(-BELT_L / 2.0 + 0.12, BELT_TOP + 0.56, -BELT_W / 2.0 + 0.33 + k * 0.657))
	# đầu ra: máy huỷ hai trục răng
	var sx := BELT_L / 2.0 + 0.3
	shred = [_toothed_roller(Vector3(sx, BELT_TOP - 0.1, 0), BELT_W + 0.3, 0.4), _toothed_roller(Vector3(sx + 0.15, BELT_TOP + 0.85, 0), BELT_W + 0.3, 0.4)]
	Build.box(root, Vector3(1.0, 2.3, BELT_W + 0.8), steel, Vector3(sx + 0.95, 1.15, 0))
	Build.box(root, Vector3(1.4, 0.3, BELT_W + 0.8), hazard, Vector3(sx + 0.3, BELT_TOP + 1.55, 0))
	var stain := Build.box(root, Vector3(0.9, 0.02, BELT_W), m.gore.blood_mat, Vector3(BELT_L / 2.0 - 0.45, BELT_TOP + 0.004, 0))
	stain.visible = m.gore.enabled
	Build.omni(root, Vector3(sx - 0.8, BELT_TOP + 1.0, 0), Color(1.0, 0.1, 0.05), 3.0, 5.5)
	belt_v = 1.3
	crate_t = 1.2
	# cùng khoảng cách tới đầu nạp thùng; làn xuất phát xáo theo seed
	var lanes := shuffled([0, 1, 2, 3])
	for i in 4:
		var s := m.spawn_subject(i, Vector3(-2.3, BELT_TOP, -1.65 + int(lanes[i]) * 1.1))
		s.brain.home_x = -1.6


func _move_belt(dt: float) -> void:
	for c in cleats:
		c.position.x += belt_v * dt
		if c.position.x > BELT_L / 2.0:
			c.position.x -= BELT_L
			c.reset_physics_interpolation()   # quay vòng về đầu băng: không vẽ vệt qua giữa băng
	(shred[0] as Node3D).rotate_object_local(Vector3.UP, dt * 9.0)
	(shred[1] as Node3D).rotate_object_local(Vector3.UP, -dt * 9.0)
	var bi := belt_items.size() - 1
	while bi >= 0:
		var it: Node3D = belt_items[bi]
		if not is_instance_valid(it):
			belt_items.remove_at(bi)
		else:
			it.position.x += belt_v * dt
			if it.position.x > BELT_L / 2.0 - 0.1:
				it.queue_free()
				belt_items.remove_at(bi)
		bi -= 1


func _spawn_crate(cid: int, hw: float, cz: float, x: float) -> void:
	var node := Build.box(root, Vector3(0.7, 0.7, hw * 2.0), Build.grime(Color(0.40, 0.29, 0.16), 0.1, 0.8, 0.0, 16.0, 0.9), Vector3(x, BELT_TOP + 0.35, cz))
	Build.box(node, Vector3(0.72, 0.08, hw * 2.0 + 0.02), Build.mat(Color(0.12, 0.10, 0.07), 0.8), Vector3(0, 0.2, 0))
	moving_body(node, _box_shape(Vector3(0.7, 0.7, hw * 2.0)))
	# mỗi bot có 14% không kịp né thùng này (cờ ngẫu nhiên riêng từng ghế — hàm băm theo số ghế bị lệch)
	var miss := []
	for i in 4:
		miss.append(randf() < 0.14)
	crates.append({"n": node, "x": x, "z": cz, "hw": hw, "id": cid, "miss": miss})


func _crunch(c: Dictionary) -> void:
	for j in 4:   # thùng bị nghiền vụn
		m.gore.chunk(Vector3(c.x, BELT_TOP + 0.4, float(c.z) + randf_range(-0.5, 0.5)), Vector3(randf_range(-4.0, -1.0), randf_range(2.0, 5.0), randf_range(-2.0, 2.0)), Build.mat(Color(0.40, 0.29, 0.16), 0.9), 0.2)
	(c.n as Node3D).queue_free()


func tick(dt: float) -> void:
	var k := k_round()
	belt_v = lerpf(1.3, 2.9, k)
	if surge > 0.0:
		surge -= dt
		belt_v *= 1.9
	_move_belt(dt)
	crate_t -= dt
	if crate_t <= 0.0:
		crate_t = lerpf(1.7, 0.85, k) * randf_range(0.8, 1.2)
		crate_id += 1
		var hw := randf_range(0.55, 1.05)
		var cz := randf_range(-BELT_W / 2.0 + hw + 0.05, BELT_W / 2.0 - hw - 0.05)
		_spawn_crate(crate_id, hw, cz, -BELT_L / 2.0 - 0.2)
	var ci := crates.size() - 1
	while ci >= 0:
		var c: Dictionary = crates[ci]
		c.x += belt_v * dt
		(c.n as Node3D).position.x = c.x
		if c.x > BELT_L / 2.0 - 0.15:
			_crunch(c)
			crates.remove_at(ci)
		ci -= 1
	for s in subjects():
		if s.out > 0.0:
			continue
		var p := s.position
		for c in crates:
			if absf(p.x - float(c.x)) < 0.63 and absf(p.z - float(c.z)) < float(c.hw) + 0.25 and p.y < BELT_TOP + 0.65:
				p.x = float(c.x) + (0.64 if p.x >= float(c.x) - 0.1 else -0.64)
		s.position = p
		s.scared = p.x > 2.6


func client_tick(dt: float) -> void:
	_move_belt(dt)
	for c in crates:
		c.x += belt_v * dt
		(c.n as Node3D).position.x = c.x


func ground_y(_p: Vector3) -> float:
	return BELT_TOP


func gib_ground(p: Vector3) -> float:
	return BELT_TOP if absf(p.x) < BELT_L / 2.0 and absf(p.z) < BELT_W / 2.0 + 0.1 else 0.0


func constrain(_s: Subject, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z)
	f.x = maxf(f.x, -BELT_L / 2.0 + 0.35)
	f.y = clampf(f.y, -BELT_W / 2.0 + 0.3, BELT_W / 2.0 - 0.3)
	return Vector3(f.x, p.y, f.y)


func spawn_point() -> Vector3:
	return Vector3(randf_range(-3.6, -1.5), BELT_TOP, randf_range(-1.7, 1.7))


func surface_velocity(_s: Subject) -> Vector3:
	return Vector3(belt_v, 0, 0)


func after_move(s: Subject) -> void:
	if s.position.x > BELT_L / 2.0 - 0.2:
		m.kill(s, "grind", Vector3(-0.8, 0.6, 0))
		m.announce("ĐỐI TƯỢNG %s: ĐÃ QUA MÁY HUỶ." % m.subj_label(s))


func bot_face(_s: Subject, d: Vector3) -> Variant:
	return Vector3(-1, 0, d.z * 0.6)   # bot luôn quay mặt ngược chiều băng chuyền


func on_decal(d: Node3D, gy: float) -> void:
	if gy > 0.1:
		belt_items.append(d)


func carry_rest_gib(n: Node3D, dt: float) -> bool:
	if n.position.y <= 0.3:
		return false
	n.position.x += belt_v * dt
	if n.position.x > BELT_L / 2.0 - 0.1:
		n.queue_free()
		return true
	return false


func bot_steer(s: Subject, b: BotBrain, _dt: float, _arrived: bool, retarget: bool) -> Variant:
	var p := s.position
	if retarget:
		b.lane_z = randf_range(-1.8, 1.8)
		b.home_x = randf_range(-3.3, 0.6)
		b.ai_t = randf_range(2.0, 4.0)
		b.target = Vector3(p.x, 0, p.z + 5.0)   # tránh bị coi là "đã tới nơi"
	var tz: float = b.lane_z
	var best_dx := 3.2
	for c in crates:
		var dx: float = p.x - float(c.x)
		if dx > -0.3 and dx < best_dx and absf(p.z - float(c.z)) < float(c.hw) + 0.55 and not bool(c.miss[s.idx]):
			best_dx = dx
			var side := 1.0 if p.z >= float(c.z) else -1.0
			var zt := float(c.z) + side * (float(c.hw) + 0.8)
			if absf(zt) > BELT_W / 2.0 - 0.35:
				zt = float(c.z) - side * (float(c.hw) + 0.8)
			tz = zt
	var dvec := Vector3(b.home_x - p.x, 0, (tz - p.z) * 2.0).limit_length(1.0)
	return (dvec + Vector3(-belt_v / 3.3, 0, 0)).limit_length(1.0)


func bot_wants_sabotage(s: Subject, _b: BotBrain, dt: float) -> bool:
	# tăng tốc băng khi mình đứng xa máy huỷ hơn mọi người
	for o in subjects():
		if o != s and o.alive() and o.position.x < s.position.x + 1.5:
			return false
	return m.lt > 6.0 and randf() < 0.5 * dt


func sabotage(_s: Subject) -> bool:
	if surge > 0.0:
		return false
	surge = 2.5
	return true


func net_state() -> Dictionary:
	var cs := []
	for c in crates:
		cs.append([int(c.id), float(c.x), float(c.z), float(c.hw)])
	return {"v": belt_v, "c": cs}


func apply_net_state(st: Dictionary) -> void:
	belt_v = float(st.get("v", belt_v))
	var cs: Array = st.get("c", [])
	var seen := {}
	for e in cs:
		seen[int(e[0])] = e
	# thùng không còn trong trạng thái máy chủ: đã vào máy huỷ
	var ci := crates.size() - 1
	while ci >= 0:
		var c: Dictionary = crates[ci]
		if not seen.has(int(c.id)):
			_crunch(c)
			crates.remove_at(ci)
		else:
			c.x = float(seen[int(c.id)][1])
			(c.n as Node3D).position.x = c.x
			seen.erase(int(c.id))
		ci -= 1
	for cid in seen:
		var e: Array = seen[cid]
		_spawn_crate(int(cid), float(e[3]), float(e[2]), float(e[1]))
