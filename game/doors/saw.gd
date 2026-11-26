extends DoorBase
## Cửa LƯỠI CƯA: nhảy qua tay cưa quay, tốc độ tăng dần.

var arm_root: Node3D
var saws: Array[Node3D] = []
var arm_angle := 0.0
var arm_speed := 1.5
## Chơi xấu: tay cưa tăng tốc đột ngột trong vài giây.
var surge := 0.0


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 2
	title = "LƯỠI CƯA"
	rule = "Nhảy qua lưỡi cưa. Tốc độ tăng dần"
	sabotage_hint = "TAY CƯA TĂNG TỐC"


func setup(level_root: Node3D) -> void:
	super(level_root)
	build_platform(PLATFORM_R)
	Build.cyl(root, 0.6, 0.72, 1.0, Build.grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.5, 14.0), Vector3(0, PLATFORM_TOP + 0.5, 0), Vector3.ZERO, 12)
	arm_root = Node3D.new()
	root.add_child(arm_root)
	arm_root.position = Vector3(0, PLATFORM_TOP + 0.32, 0)
	var arm_len := PLATFORM_R - 0.2
	var blade := Build.mat(Color(0.62, 0.63, 0.62), 0.22, 0.95)
	for s in [-1.0, 1.0]:
		Build.box(arm_root, Vector3(arm_len, 0.14, 0.14), Build.mat(Palette.STEEL_DARK, 0.5, 0.7), Vector3(s * (0.5 + arm_len / 2.0), 0, 0))
		for k in 4:
			var sw := Node3D.new()
			arm_root.add_child(sw)
			sw.position = Vector3(s * (1.15 + k * 0.72), 0.0, 0)
			sw.rotation_degrees.z = 90.0
			Build.cyl(sw, 0.36, 0.36, 0.025, blade, Vector3.ZERO, Vector3.ZERO, 14)
			for j in 7:   # răng cưa
				var a := j * TAU / 7.0
				Build.box(sw, Vector3(0.12, 0.02, 0.1), blade, Vector3(cos(a) * 0.38, 0, sin(a) * 0.38), Vector3(0, -rad_to_deg(a) + 30.0, 0))
			Build.cyl(sw, 0.37, 0.37, 0.012, Build.mat(Color(0.25, 0.01, 0.01), 0.2), Vector3(0, 0.0, 0), Vector3.ZERO, 7).scale = Vector3(0.55, 1, 0.55)
			saws.append(sw)
	Build.cyl(arm_root, 0.45, 0.45, 0.5, Build.mat(Palette.STEEL, 0.5, 0.75), Vector3(0, 0.75, 0), Vector3.ZERO, 12)
	Build.ball(arm_root, 0.16, Build.glow(Color(1.0, 0.1, 0.05), 4.0), Vector3(0, 1.08, 0))
	Build.omni(arm_root, Vector3(1.2, 0.9, 0), Color(1.0, 0.12, 0.06), 2.5, 5.0)
	arm_angle = 0.0
	spawn_circle(2.3, 1.2)


func bean_angle(p: Vector3) -> float:
	return atan2(-p.z, p.x)


func arm_tta(p: Vector3) -> float:
	return fposmod(bean_angle(p) - arm_angle, PI) / arm_speed


func _advance(dt: float) -> void:
	arm_speed = lerpf(1.5, 3.3, clampf(m.lt / 32.0, 0.0, 1.0))
	if surge > 0.0:
		surge -= dt
		arm_speed *= 1.7
	arm_angle += arm_speed * dt
	arm_root.rotation.y = arm_angle
	for sw in saws:
		sw.rotate_object_local(Vector3.UP, dt * 25.0)


func tick(dt: float) -> void:
	_advance(dt)
	for s in subjects():
		if s.out > 0.0 or s.hit_cd > 0.0:
			continue
		var p := s.position
		var r := Vector2(p.x, p.z).length()
		if r < 0.75 or r > PLATFORM_R + 0.3 or p.y > PLATFORM_TOP + 0.6:
			continue
		var th := bean_angle(p)
		var diff := fposmod(th - arm_angle + PI / 2.0, PI) - PI / 2.0
		if absf(diff) * r < 0.3:
			var tang := Vector3(-sin(th), 0, -cos(th))
			var radial := Vector3(cos(th), 0, -sin(th))
			m.kill(s, "halved", (tang + radial * 0.6).normalized())
			m.announce("ĐỐI TƯỢNG %s: TÁCH LÀM HAI. GHI NHẬN." % m.subj_label(s))


func client_tick(dt: float) -> void:
	arm_root.rotation.y = arm_angle
	for sw in saws:
		sw.rotate_object_local(Vector3.UP, dt * 25.0)


func constrain(_s: Subject, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z).limit_length(PLATFORM_R - 0.45)
	if f.length() < 1.05 and p.y < PLATFORM_TOP + 1.2:
		f = (f.normalized() if f.length() > 0.01 else Vector2(1, 0)) * 1.05
	return Vector3(f.x, p.y, f.y)


func spawn_point() -> Vector3:
	var q2 := Build.rand_circle(1.6, PLATFORM_R - 0.8)
	return Vector3(q2.x, PLATFORM_TOP, q2.y)


func bot_steer(s: Subject, b: BotBrain, _dt: float, _arrived: bool, retarget: bool) -> Variant:
	var p := s.position
	var flat := Vector2(p.x, p.z)
	s.speed = 1.6
	if retarget:
		b.set_target(Build.rand_circle(1.5, PLATFORM_R - 0.7), randf_range(1.5, 3.0))
	var tta := arm_tta(p)
	# thời điểm lưỡi cưa chạm tới phụ thuộc bán kính: đứng càng gần trục thì phải nhảy càng sớm
	var lead := 0.12 + 0.3 / (maxf(flat.length(), 0.8) * arm_speed)
	if tta > 0.9:
		b.decided = false
	elif tta < lead and s.ground and not b.decided:
		b.decided = true
		if randf() > 0.12:
			b.want_jump = true
	s.scared = tta < 0.4 and s.ground
	if tta < 0.7:
		return Vector3.ZERO
	return null


func bot_wants_sabotage(_s: Subject, _b: BotBrain, dt: float) -> bool:
	return m.lt > 8.0 and randf() < 0.08 * dt


func sabotage(_s: Subject) -> bool:
	if surge > 0.0:
		return false
	surge = 2.5
	return true


func net_state() -> Dictionary:
	return {"a": arm_angle, "v": arm_speed}


func apply_net_state(st: Dictionary) -> void:
	arm_angle = float(st.get("a", arm_angle))
	arm_speed = float(st.get("v", arm_speed))
