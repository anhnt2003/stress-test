extends DoorBase
## Cửa MÁY ÉP: rời ô đỏ trước khi máy ép dập xuống.

const PRESS_POS := Vector2(1.55, -0.35)
const PRESS_HIGH := 3.1
const CYCLE := 5.0

var press: Node3D
var press_light: OmniLight3D
var beacon_mat: StandardMaterial3D
var press_stage := 0
## Chơi xấu: lần dập tiếp theo đến sớm (rút ngắn chu kỳ hiện tại).
var cycle_offset := 0.0


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 0
	title = "MÁY ÉP"
	rule = "Rời ô đỏ trước khi máy ép dập xuống"
	sabotage_hint = "MÁY ÉP DẬP SỚM"


func setup(level_root: Node3D) -> void:
	super(level_root)
	build_platform(PLATFORM_R)
	var hazard := Build.shader_mat("res://shaders/hazard.gdshader")
	Build.box(root, Vector3(2.6, 0.012, 2.6), Build.mat(Color(0.40, 0.04, 0.03), 0.6), Vector3(PRESS_POS.x, PLATFORM_TOP + 0.006, PRESS_POS.y))
	Build.box(root, Vector3(2.2, 0.014, 2.2), Build.mat(Color(0.10, 0.03, 0.03), 0.3, 0.4), Vector3(PRESS_POS.x, PLATFORM_TOP + 0.008, PRESS_POS.y))
	press = Node3D.new()
	root.add_child(press)
	Build.box(press, Vector3(2.3, 1.1, 2.3), Build.grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.5, 14.0), Vector3(0, 0.75, 0))
	Build.box(press, Vector3(2.4, 0.22, 2.4), hazard, Vector3(0, 0.11, 0))
	Build.box(press, Vector3(2.32, 0.12, 2.32), Build.mat(Color(0.18, 0.01, 0.01), 0.2), Vector3(0, 0.03, 0))
	Build.cyl(press, 0.42, 0.42, 7.0, Build.mat(Color(0.55, 0.56, 0.54), 0.2, 0.95), Vector3(0, 4.8, 0))
	Build.cyl(press, 0.6, 0.6, 0.3, Build.mat(Palette.STEEL, 0.5, 0.75), Vector3(0, 1.45, 0))
	for k in 5:  # vệt máu chảy trên thân máy
		Build.box(press, Vector3(randf_range(0.06, 0.2), randf_range(0.3, 0.8), 0.01), m.gore.blood_mat, Vector3(randf_range(-0.9, 0.9), 0.5, 1.156))
	beacon_mat = Build.mat(Color(1.0, 0.1, 0.05), 0.3, 0.0, 2.0)
	Build.ball(press, 0.12, beacon_mat, Vector3(0.85, 1.4, 0.85))
	Build.ball(press, 0.12, beacon_mat, Vector3(-0.85, 1.4, 0.85))
	press_light = Build.omni(press, Vector3(0, -0.3, 1.6), Color(1.0, 0.1, 0.05), 0.0, 7.0)
	Build.box(root, Vector3(2.0, 0.7, 2.0), Build.grime(Color(0.16, 0.15, 0.13), 0.5, 0.7, 0.5), Vector3(PRESS_POS.x, 5.05, PRESS_POS.y))
	press.position = Vector3(PRESS_POS.x, PRESS_HIGH, PRESS_POS.y)
	press_stage = 0
	var spots := [Vector2(-1.5, 1.6), Vector2(-0.4, -1.9), Vector2(-2.5, -0.4), Vector2(2.3, 1.9)]
	for i in 4:
		m.spawn_subject(i, Vector3(spots[i].x, PLATFORM_TOP, spots[i].y))


func press_height(p: float) -> float:
	var low := PLATFORM_TOP + 0.06
	if p < 2.0:
		return PRESS_HIGH
	if p < 2.6:
		return PRESS_HIGH + sin(p * 70.0) * 0.03
	if p < 2.74:
		var k := (p - 2.6) / 0.14
		return lerpf(PRESS_HIGH, low, k * k)
	if p < 3.9:
		return low
	return lerpf(low, PRESS_HIGH, smoothstep(0.0, 1.0, (p - 3.9) / (CYCLE - 3.9)))


func in_press_zone(p: Vector3, half: float) -> bool:
	return absf(p.x - PRESS_POS.x) < half and absf(p.z - PRESS_POS.y) < half


func cycle_pos() -> float:
	return fmod(m.lt + cycle_offset, CYCLE)


func _visual(pp: float) -> void:
	press.position = Vector3(PRESS_POS.x, press_height(pp), PRESS_POS.y)
	var warn := pp > 1.4 and pp < 2.74
	var blink := 0.5 + 0.5 * sin(m.t * 22.0)
	press_light.light_energy = (4.0 * blink) if warn else (1.5 if pp >= 2.74 and pp < 3.9 else 0.0)
	beacon_mat.emission_energy_multiplier = (1.0 + 6.0 * blink) if warn else 1.2


func tick(_dt: float) -> void:
	var pp := cycle_pos()
	_visual(pp)
	var warn := pp > 1.4 and pp < 2.74
	if pp < 1.4:
		press_stage = 0
	if press_stage == 0 and pp >= 1.4:
		press_stage = 1
		for s in subjects():
			s.brain.flee = randf() < 0.45
	if press_stage == 1 and pp >= 2.6:
		press_stage = 2
		for s in subjects():
			if s.out <= 0.0 and in_press_zone(s.position, 1.3):
				s.flat = 0.3   # đứng chết trân
	if press_stage == 2 and pp >= 2.74:
		press_stage = 3
		m.shake(1.0)
		m.play_sfx("slam", -2.0)
		for s in subjects():
			if s.flat > 0.0 and s.out <= 0.0:
				m.kill(s, "crush")
				m.announce("ĐỐI TƯỢNG %s: ĐỘ DÀY KHÔNG ĐẠT." % m.subj_label(s))
	for s in subjects():
		if warn and in_press_zone(s.position, 1.5):
			s.scared = true


func client_tick(_dt: float) -> void:
	_visual(cycle_pos())


func constrain(s: Subject, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z).limit_length(PLATFORM_R - 0.45)
	if press.position.y < PLATFORM_TOP + 1.7 and s.flat <= 0.0:
		var rel := f - PRESS_POS
		if absf(rel.x) < 1.55 and absf(rel.y) < 1.55:
			if absf(rel.x) > absf(rel.y):
				rel.x = 1.55 if rel.x >= 0.0 else -1.55
			else:
				rel.y = 1.55 if rel.y >= 0.0 else -1.55
			f = (PRESS_POS + rel).limit_length(PLATFORM_R - 0.45)
	return Vector3(f.x, p.y, f.y)


func spawn_point() -> Vector3:
	for k in 20:
		var q := Build.rand_circle(0.3, PLATFORM_R - 0.7)
		if not in_press_zone(Vector3(q.x, 0, q.y), 1.7):
			return Vector3(q.x, PLATFORM_TOP, q.y)
	return super()


func bot_steer(s: Subject, b: BotBrain, _dt: float, _arrived: bool, retarget: bool) -> Variant:
	var p := s.position
	var flat := Vector2(p.x, p.z)
	var pp := cycle_pos()
	if in_press_zone(p, 1.5) and pp > 1.4 and pp < 2.74 and b.flee:
		var away := flat - PRESS_POS
		if away.length() < 0.05:
			away = Vector2(-1, 0.3)
		b.set_target((flat + away.normalized() * 2.5).limit_length(PLATFORM_R - 0.6), 1.0)
	elif retarget:
		if randf() < 0.3:
			b.set_target(PRESS_POS + Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8)), randf_range(1.5, 3.0))
		else:
			b.set_target(Build.rand_circle(0.3, PLATFORM_R - 0.6), randf_range(1.0, 2.5))
	return null


func bot_wants_sabotage(s: Subject, _b: BotBrain, dt: float) -> bool:
	# dập sớm khi có người khác đang đứng trong ô đỏ còn mình thì ở ngoài
	if in_press_zone(s.position, 1.8) or cycle_pos() > 1.0:
		return false
	for o in subjects():
		if o != s and o.alive() and in_press_zone(o.position, 1.1):
			return randf() < 0.6 * dt
	return false


func sabotage(_s: Subject) -> bool:
	var pp := cycle_pos()
	if pp >= 1.4:
		return false   # máy đang cảnh báo hoặc đang dập: không rút ngắn được nữa
	cycle_offset += 1.4 - pp + 0.01   # nhảy thẳng tới pha cảnh báo
	return true


func net_state() -> Dictionary:
	return {"off": cycle_offset}


func apply_net_state(st: Dictionary) -> void:
	cycle_offset = float(st.get("off", 0.0))
