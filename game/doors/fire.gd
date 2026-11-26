extends DoorBase
## Cửa VÒNG LỬA (cửa cuối): vùng an toàn co lại và trôi đi. Ngoài vùng là lửa.

var fire_cells: Array[Dictionary] = []
var fire_r := 3.2
var fire_c := Vector2.ZERO
var fire_ring: MeshInstance3D
var fire_light: OmniLight3D
## Chơi xấu: vùng an toàn co thêm trong vài giây.
var squeeze := 0.0


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 9
	title = "VÒNG LỬA"
	rule = "Cửa cuối. Vùng an toàn co lại và trôi đi. Ngoài vùng là lửa"
	sabotage_hint = "VÙNG AN TOÀN CO THÊM"
	separation = 0.85


func setup(level_root: Node3D) -> void:
	super(level_root)
	build_platform(PLATFORM_R)
	var glow_m := Build.mat(Color(1.0, 0.25, 0.03), 0.6, 0.0, 1.6)
	var flame_m := Build.mat(Color(0.5, 0.08, 0.0), 0.5)
	flame_m.emission_enabled = true
	flame_m.emission = Color(1.0, 0.30, 0.03)
	flame_m.emission_energy_multiplier = 1.3
	var core_m := Build.mat(Color(0.6, 0.3, 0.0), 0.5)
	core_m.emission_enabled = true
	core_m.emission = Color(1.0, 0.75, 0.2)
	core_m.emission_energy_multiplier = 1.8
	var step := 0.5
	var nmax := int(PLATFORM_R / step) + 1
	for gx in range(-nmax, nmax + 1):
		for gz in range(-nmax, nmax + 1):
			var q := Vector2(gx * step + (0.25 if gz % 2 != 0 else 0.0), gz * step)
			if q.length() > PLATFORM_R - 0.15:
				continue
			var n := Node3D.new()
			root.add_child(n)
			n.position = Vector3(q.x, PLATFORM_TOP, q.y)
			Build.add_mesh(n, m.gore.disc_mesh, glow_m, Vector3(0, 0.01, 0)).scale = Vector3(0.3, 1, 0.3)
			var fl := Build.cyl(n, 0.0, 0.15, 0.7, flame_m, Vector3(0, 0.35, 0), Vector3.ZERO, 5)
			Build.cyl(fl, 0.0, 0.09, 0.4, core_m, Vector3(0, -0.14, 0.0), Vector3.ZERO, 5).scale = Vector3(1.25, 1, 1.25)
			n.visible = false
			fire_cells.append({"n": n, "p": q, "fl": fl})
	for i in 12:   # vòi ga quanh mép sàn
		var a := i * TAU / 12.0
		Build.cyl(root, 0.07, 0.09, 0.3, Build.grime(Color(0.25, 0.22, 0.18), 0.6, 0.7, 0.6), Vector3(cos(a) * (PLATFORM_R + 0.35), 0.35, sin(a) * (PLATFORM_R + 0.35)), Vector3.ZERO, 6)
	fire_ring = Build.torus(root, 0.965, 1.0, Build.glow(Palette.AMBER, 2.0), Vector3(0, PLATFORM_TOP + 0.02, 0))
	fire_light = Build.omni(root, Vector3(0, 1.3, 0), Color(1.0, 0.45, 0.1), 0.0, 9.0)
	fire_r = 3.2
	fire_c = Vector2.ZERO
	for i in 4:
		var a2 := i * TAU / 4.0 + 0.5
		var s := m.spawn_subject(i, Vector3(cos(a2) * 1.3, PLATFORM_TOP, sin(a2) * 1.3))
		s.brain.off = Vector2(cos(a2), sin(a2))


func _flames(k: float) -> void:
	fire_ring.position = Vector3(fire_c.x, PLATFORM_TOP + 0.02, fire_c.y)
	fire_ring.scale = Vector3(fire_r, 0.3, fire_r)
	for c in fire_cells:
		var vis: bool = (c.p as Vector2).distance_to(fire_c) > fire_r + 0.12
		(c.n as Node3D).visible = vis
		if vis:
			(c.fl as Node3D).scale = Vector3(randf_range(0.7, 1.2), randf_range(0.4, 1.7), randf_range(0.7, 1.2))
			(c.fl as Node3D).position.y = 0.35 * (c.fl as Node3D).scale.y
	fire_light.light_energy = 0.8 + 3.5 * k + randf_range(0.0, 0.8)


func tick(dt: float) -> void:
	var k := k_round()
	# cân bằng lại: vùng nhỏ nhất 0.62 → 0.8 để 4 người còn chỗ đứng khi bị đẩy
	fire_r = lerpf(3.2, 0.8, smoothstep(0.0, 1.0, k))
	if squeeze > 0.0:
		squeeze -= dt
		fire_r = maxf(0.55, fire_r - 0.6 * minf(1.0, squeeze))
	var amp := maxf(PLATFORM_R - 0.3 - fire_r, 0.0)
	fire_c = Vector2(sin(m.lt * 0.55) * amp * 0.9, sin(m.lt * 0.83 + 1.0) * amp * 0.9).limit_length(amp)
	_flames(k)
	for s in subjects():
		if s.out > 0.0:
			continue
		var p := s.position
		var dist := Vector2(p.x, p.z).distance_to(fire_c)
		if dist > fire_r - 0.35:
			s.scared = true
		# đếm cả lúc đang nhảy ngoài vùng (nhảy liên tục không né được lửa); chỉ bốc cháy khi chạm sàn,
		# và chỉ đặt lại khi đã về trong vùng an toàn
		if dist > fire_r + 0.05:
			s.outside_t += dt
			if s.outside_t > 0.3 and s.ground:
				m.kill(s, "fry")
				m.announce("ĐỐI TƯỢNG %s: ĐÃ CHÍN." % m.subj_label(s))
		else:
			s.outside_t = 0.0


func client_tick(_dt: float) -> void:
	_flames(k_round())


func spawn_point() -> Vector3:
	var q9 := fire_c + Build.rand_circle(0.0, fire_r * 0.5)
	return Vector3(q9.x, PLATFORM_TOP, q9.y)


func bot_steer(_s: Subject, b: BotBrain, _dt: float, _arrived: bool, _retarget: bool) -> Variant:
	if b.ai_t <= 0.0:
		b.off = Build.rand_circle(0.0, 1.0)
		b.ai_t = randf_range(0.8, 2.0)
	var tq9 := fire_c + b.off * fire_r * 0.55
	b.target = Vector3(tq9.x, 0, tq9.y)
	return null


func bot_wants_sabotage(s: Subject, _b: BotBrain, dt: float) -> bool:
	# co vùng khi mình đang đứng sát tâm
	return Vector2(s.position.x, s.position.z).distance_to(fire_c) < fire_r * 0.35 and m.lt > 6.0 and randf() < 0.3 * dt


func sabotage(_s: Subject) -> bool:
	if squeeze > 0.0:
		return false
	squeeze = 3.0
	return true


func net_state() -> Dictionary:
	return {"r": fire_r, "c": fire_c}


func apply_net_state(st: Dictionary) -> void:
	fire_r = float(st.get("r", fire_r))
	fire_c = st.get("c", fire_c)
