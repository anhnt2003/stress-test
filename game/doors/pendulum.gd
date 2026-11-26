extends DoorBase
## Cửa CON LẮC: ba lưỡi rìu đung đưa, phải đứng trong vùng sáng và tránh đường rìu.

const LANES := [-1.7, 0.0, 1.7]
const PEND_L := 4.2
const PEND_PIVOT := 5.05

var pends: Array[Dictionary] = []
var zone_pos := Vector2.ZERO
var zone_t := 0.0
var zone_grace := 0.0
var zone_node: Node3D


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 7
	title = "CON LẮC"
	rule = "Đứng trong vùng sáng. Đừng đứng trên đường rìu"
	sabotage_hint = "DỜI VÙNG SÁNG NGAY LẬP TỨC"


func pend_pos(pd: Dictionary, time: float) -> Vector2:
	var th := 0.9 * sin(float(pd.w) * time + float(pd.ph))
	return Vector2(PEND_L * sin(th), PEND_PIVOT - PEND_L * cos(th))


func setup(level_root: Node3D) -> void:
	super(level_root)
	build_platform(PLATFORM_R)
	var steel := Build.grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.6, 14.0)
	var blade := Build.mat(Color(0.60, 0.61, 0.58), 0.25, 0.95)
	var ws := [1.7, 2.05, 1.5]
	var phs := [0.0, 2.1, 4.0]
	for li in 3:
		var lane: float = LANES[li]
		var n := Node3D.new()
		root.add_child(n)
		n.position = Vector3(0, PEND_PIVOT, lane)
		Build.cyl(n, 0.05, 0.05, PEND_L - 0.6, steel, Vector3(0, -(PEND_L - 0.6) / 2.0, 0), Vector3.ZERO, 6)
		Build.box(n, Vector3(0.5, 0.5, 0.16), steel, Vector3(0, -PEND_L + 1.0, 0))
		Build.cyl(n, 0.85, 0.85, 0.05, blade, Vector3(0, -PEND_L + 0.85, 0), Vector3(90, 0, 0), 20)
		Build.cyl(n, 0.86, 0.86, 0.03, Build.mat(Color(0.22, 0.01, 0.01), 0.2), Vector3(0, -PEND_L + 0.85, 0), Vector3(90, 0, 0), 9).scale = Vector3(1.0, 1.0, 1.0)
		Build.box(root, Vector3(0.4, 0.3, 0.4), steel, Vector3(0, PEND_PIVOT + 0.1, lane))
		var half := sqrt(PLATFORM_R * PLATFORM_R - lane * lane) - 0.1
		Build.box(root, Vector3(half * 2.0, 0.008, 0.1), Build.mat(Color(0.35, 0.04, 0.03), 0.6), Vector3(0, PLATFORM_TOP + 0.006, lane))
		pends.append({"n": n, "lane": lane, "w": ws[li], "ph": phs[li]})
	zone_node = Node3D.new()
	root.add_child(zone_node)
	var ring := Build.torus(zone_node, 1.14, 1.24, Build.glow(Palette.AMBER, 2.2), Vector3(0, 0.02, 0))
	ring.scale = Vector3(1, 0.12, 1)
	var fill := Build.mat(Color(1.0, 0.62, 0.15, 0.10), 0.6)
	fill.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Build.add_mesh(zone_node, m.gore.disc_mesh, fill, Vector3(0, 0.012, 0)).scale = Vector3(1.14, 1, 1.14)
	zone_pos = Vector2(-0.9, 0.85)
	zone_node.position = Vector3(zone_pos.x, PLATFORM_TOP, zone_pos.y)
	zone_t = 5.0
	zone_grace = 2.5
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		m.spawn_subject(i, Vector3(zone_pos.x + cos(a) * 0.6, PLATFORM_TOP, zone_pos.y + sin(a) * 0.6))


func _swing() -> void:
	for pd in pends:
		(pd.n as Node3D).rotation.z = 0.9 * sin(float(pd.w) * m.lt + float(pd.ph))
	zone_node.position = Vector3(zone_pos.x, PLATFORM_TOP, zone_pos.y)


func _move_zone() -> void:
	var q := zone_pos
	for tries in 12:
		q = Build.rand_circle(0.0, 2.2)
		if q.distance_to(zone_pos) > 1.6:
			break
	zone_pos = q
	zone_node.position = Vector3(q.x, PLATFORM_TOP, q.y)
	zone_t = lerpf(5.5, 4.0, k_round())
	zone_grace = 1.7
	for s in subjects():
		s.brain.flee = randf() < 0.85
		s.brain.ai_t = 0.0


func tick(dt: float) -> void:
	for pd in pends:
		var th := 0.9 * sin(float(pd.w) * m.lt + float(pd.ph))
		(pd.n as Node3D).rotation.z = th
		var bp := pend_pos(pd, m.lt)
		var vx := cos(float(pd.w) * m.lt + float(pd.ph))
		for s in subjects():
			if s.out > 0.0 or s.hit_cd > 0.0:
				continue
			var p := s.position
			if absf(p.z - float(pd.lane)) < 0.4 and absf(p.x - bp.x) < 0.6 and bp.y - 0.85 < p.y + 1.45 and p.y < bp.y + 0.3:
				m.kill(s, "halved", Vector3(1.0 if vx >= 0.0 else -1.0, 0.2, 0).normalized())
				m.announce("ĐỐI TƯỢNG %s: CẮT NGANG THÂN." % m.subj_label(s))
	zone_t -= dt
	zone_grace -= dt
	if zone_t <= 0.0:
		_move_zone()
	for s in subjects():
		if s.out > 0.0:
			continue
		var p2 := s.position
		if Vector2(p2.x, p2.z).distance_to(zone_pos) > 1.22:
			s.scared = true
			if zone_grace <= 0.0:
				s.outside_t += dt
				if s.outside_t > 1.2:
					m.kill(s, "headpop")
					m.announce("ĐỐI TƯỢNG %s: RỜI VÙNG CHỈ ĐỊNH." % m.subj_label(s))
		else:
			s.outside_t = 0.0


func client_tick(_dt: float) -> void:
	_swing()


func spawn_point() -> Vector3:
	var q7 := (zone_pos + Build.rand_circle(0.0, 0.7)).limit_length(PLATFORM_R - 0.7)
	return Vector3(q7.x, PLATFORM_TOP, q7.y)


func bot_steer(s: Subject, b: BotBrain, _dt: float, _arrived: bool, retarget: bool) -> Variant:
	var p := s.position
	var tgt := b.target
	if retarget or Vector2(tgt.x, tgt.z).distance_to(zone_pos) > 0.95:
		b.set_target((zone_pos + Build.rand_circle(0.0, 0.8)).limit_length(PLATFORM_R - 0.6), randf_range(1.0, 2.2))
	if b.flee:
		for pd in pends:
			var lane: float = pd.lane
			var now := pend_pos(pd, m.lt)
			var fut := pend_pos(pd, m.lt + 0.3)
			var near := minf(absf(p.x - fut.x), absf(p.x - now.x)) < 1.3 and minf(fut.y, now.y) < PLATFORM_TOP + 2.6
			var dz := p.z - lane
			if near and absf(dz) < 0.75:
				return Vector3(0, 0, 1.0 if dz >= 0.0 else -1.0)
			if near and absf(dz) < 1.05 and (b.target.z - lane) * dz < 0.0:
				return Vector3.ZERO
	return null


func bot_wants_sabotage(s: Subject, _b: BotBrain, dt: float) -> bool:
	# dời vùng khi mình đang ở mép vùng mới... đơn giản: khi mình ở trong vùng và có người khác cũng ở trong vùng
	if zone_grace > 0.0 or m.lt < 4.0:
		return false
	if Vector2(s.position.x, s.position.z).distance_to(zone_pos) > 1.0:
		return false
	return randf() < 0.12 * dt


func sabotage(_s: Subject) -> bool:
	if zone_grace > 0.0:
		return false
	_move_zone()
	zone_grace = 1.1   # ít thời gian chạy hơn bình thường
	return true


func net_state() -> Dictionary:
	return {"z": zone_pos}


func apply_net_state(st: Dictionary) -> void:
	zone_pos = st.get("z", zone_pos)
