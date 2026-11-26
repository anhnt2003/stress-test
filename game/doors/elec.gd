extends DoorBase
## Cửa SÀN ĐIỆN: ô nháy vàng sắp phóng điện. Chạy sang ô an toàn hoặc nhảy đúng lúc.

const EW := 6
const EH := 5
const ES := 1.4
const ELEC_TOP := 0.56

var elec: Array[Dictionary] = []
var elec_phase := 0
var elec_t := 0.0
var elec_light: OmniLight3D
## Chơi xấu: ô dưới chân người gần nhất bị bật điện ngay đợt tới.
var forced_hot := -1


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 6
	title = "SÀN ĐIỆN"
	rule = "Ô nháy vàng sắp phóng điện. Chạy sang ô an toàn hoặc nhảy đúng lúc"
	sabotage_hint = "PHÓNG ĐIỆN DƯỚI CHÂN ĐỐI THỦ"
	cam_base = Vector3(5.6, 5.0, 6.1)
	cam_look = Vector3(-0.7, 0.3, -0.6)


func elec_center(ix: int, iz: int) -> Vector3:
	return Vector3(-EW * ES / 2.0 + (ix + 0.5) * ES, ELEC_TOP, -EH * ES / 2.0 + (iz + 0.5) * ES)


func elec_at(p: Vector3) -> int:
	var ix := int(floor((p.x + EW * ES / 2.0) / ES))
	var iz := int(floor((p.z + EH * ES / 2.0) / ES))
	if ix < 0 or iz < 0 or ix >= EW or iz >= EH:
		return -1
	return iz * EW + ix


func setup(level_root: Node3D) -> void:
	super(level_root)
	Build.box(root, Vector3(EW * ES + 0.5, 0.5, EH * ES + 0.5), Build.grime(Color(0.14, 0.13, 0.11), 0.5, 0.8, 0.5, 14.0), Vector3(0, 0.25, 0))
	static_box(root, Vector3(EW * ES + 0.5, ELEC_TOP, EH * ES + 0.5), Vector3(0, ELEC_TOP / 2.0, 0), LAYER_FLOOR)
	for iz in EH:
		for ix in EW:
			var mt := Build.grime(Color(0.30, 0.30, 0.27), 0.35, 0.8, 0.7, 12.0, 0.45)
			var c := elec_center(ix, iz)
			Build.box(root, Vector3(ES - 0.12, 0.06, ES - 0.12), mt, Vector3(c.x, 0.53, c.z))
			elec.append({"mat": mt, "hot": false})
	# cột sứ cách điện và cuộn dây ở bốn góc
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var px: float = sx * (EW * ES / 2.0 + 0.55)
			var pz: float = sz * (EH * ES / 2.0 + 0.55)
			Build.cyl(root, 0.16, 0.2, 1.5, Build.grime(Color(0.45, 0.42, 0.34), 0.2, 0.8, 0.0), Vector3(px, 0.75, pz), Vector3.ZERO, 10)
			for k in 4:
				Build.cyl(root, 0.26, 0.26, 0.06, Build.grime(Color(0.35, 0.20, 0.10), 0.5, 0.7, 0.6), Vector3(px, 0.4 + k * 0.3, pz), Vector3.ZERO, 10)
			Build.ball(root, 0.14, Build.glow(Color(0.6, 0.85, 1.0), 1.2), Vector3(px, 1.6, pz))
	elec_light = Build.omni(root, Vector3(0, 1.8, 0), Color(0.6, 0.82, 1.0), 0.0, 10.0)
	elec_phase = 0
	elec_t = 2.0
	var spots := shuffled([Vector2i(1, 3), Vector2i(4, 1), Vector2i(1, 1), Vector2i(4, 3)])
	for i in 4:
		m.spawn_subject(i, elec_center(spots[i].x, spots[i].y))


func _paint(dt_phase: int) -> void:
	match dt_phase:
		0:
			elec_light.light_energy = 0.0
			for e in elec:
				(e.mat as ShaderMaterial).set_shader_parameter("emit_e", 0.0)
		1:
			var blink := 0.7 if fmod(m.t, 0.22) < 0.11 else 0.08
			for e in elec:
				var mt: ShaderMaterial = e.mat
				mt.set_shader_parameter("emit", Color(1.0, 0.6, 0.1))
				mt.set_shader_parameter("emit_e", blink if e.hot else 0.0)
		2:
			for e in elec:
				var m2: ShaderMaterial = e.mat
				m2.set_shader_parameter("emit", Color(0.45, 0.70, 1.0))
				m2.set_shader_parameter("emit_e", randf_range(0.5, 1.5) if e.hot else 0.0)
			elec_light.light_energy = randf_range(1.0, 6.0)


func tick(dt: float) -> void:
	var k := k_round()
	elec_t -= dt
	match elec_phase:
		0:
			elec_light.light_energy = 0.0
			if elec_t <= 0.0:
				var pat := randi() % 5
				var par := randi() % 2
				var safe := 0
				for i in elec.size():
					var ix := i % EW
					var iz := i / EW
					var hot := false
					match pat:
						0: hot = randf() < 0.55
						1: hot = (ix + iz) % 2 == par
						2: hot = iz % 2 == par
						3: hot = ix % 2 == par
						4: hot = randf() < 0.78
					elec[i].hot = hot
					if not hot:
						safe += 1
				while safe < 4:
					var ri := randi() % elec.size()
					if elec[ri].hot:
						elec[ri].hot = false
						safe += 1
				if forced_hot >= 0:
					elec[forced_hot].hot = true
					forced_hot = -1
				elec_phase = 1
				elec_t = lerpf(1.25, 0.8, k)
				for s in subjects():
					s.brain.react = randf_range(0.08, 0.5) if randf() > 0.1 else 9.0
		1:
			_paint(1)
			if elec_t <= 0.0:
				elec_phase = 2
				elec_t = 0.7
				m.shake(0.4)
				m.play_sfx("zap", -8.0, 1.2)
		2:
			_paint(2)
			for i in 3:   # tia lửa
				var ri2 := randi() % elec.size()
				if elec[ri2].hot:
					var c := elec_center(ri2 % EW, ri2 / EW)
					m.gore.drop(c + Vector3(randf_range(-0.5, 0.5), 0.1, randf_range(-0.5, 0.5)), Vector3(randf_range(-1.5, 1.5), randf_range(2.0, 5.0), randf_range(-1.5, 1.5)), m.gore.spark_mat, false)
			for s in subjects():
				if s.out > 0.0:
					continue
				var p := s.position
				var ei := elec_at(p)
				if ei >= 0 and elec[ei].hot and p.y < ELEC_TOP + 0.25:
					m.kill(s, "fry")
					m.announce("ĐỐI TƯỢNG %s: DẪN ĐIỆN TỐT. GHI NHẬN." % m.subj_label(s))
			if elec_t <= 0.0:
				elec_phase = 0
				elec_t = lerpf(1.5, 0.6, k)
				for e in elec:
					e.hot = false
					(e.mat as ShaderMaterial).set_shader_parameter("emit_e", 0.0)
	if elec_phase == 1:
		for s in subjects():
			var ei2 := elec_at(s.position)
			if ei2 >= 0 and elec[ei2].hot:
				s.scared = true


func client_tick(dt: float) -> void:
	if dt <= 0.0:
		_paint_static()   # chỉ dựng tư thế (ngoài lúc thi): không nhấp nháy, không tia lửa
		return
	_paint(elec_phase)
	if elec_phase == 2 and randf() < 0.5:
		var ri := randi() % elec.size()
		if elec[ri].hot:
			var c := elec_center(ri % EW, ri / EW)
			m.gore.drop(c + Vector3(randf_range(-0.5, 0.5), 0.1, randf_range(-0.5, 0.5)), Vector3(randf_range(-1.5, 1.5), randf_range(2.0, 5.0), randf_range(-1.5, 1.5)), m.gore.spark_mat, false)


func _paint_static() -> void:
	elec_light.light_energy = 3.0 if elec_phase == 2 else 0.0
	for e in elec:
		var mt: ShaderMaterial = e.mat
		mt.set_shader_parameter("emit", Color(0.45, 0.70, 1.0) if elec_phase == 2 else Color(1.0, 0.6, 0.1))
		mt.set_shader_parameter("emit_e", (1.0 if elec_phase == 2 else 0.4) if e.hot and elec_phase > 0 else 0.0)


func ground_y(_p: Vector3) -> float:
	return ELEC_TOP


func gib_ground(p: Vector3) -> float:
	return ELEC_TOP if absf(p.x) < EW * ES / 2.0 + 0.25 and absf(p.z) < EH * ES / 2.0 + 0.25 else 0.0


func constrain(_s: Subject, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z).clamp(Vector2(-EW * ES / 2.0 + 0.3, -EH * ES / 2.0 + 0.3), Vector2(EW * ES / 2.0 - 0.3, EH * ES / 2.0 - 0.3))
	return Vector3(f.x, p.y, f.y)


func spawn_point() -> Vector3:
	return elec_center(randi() % EW, randi() % EH)


func bot_steer(s: Subject, b: BotBrain, dt: float, _arrived: bool, retarget: bool) -> Variant:
	var p := s.position
	var flat := Vector2(p.x, p.z)
	var ei := elec_at(p)
	if elec_phase >= 1 and ei >= 0 and elec[ei].hot:
		b.react -= dt
		if b.react > 0.0:
			return Vector3.ZERO
		var bestc := Vector2(p.x, p.z)
		var bdd := 1e9
		for i in elec.size():
			if not elec[i].hot:
				var c6 := elec_center(i % EW, i / EW)
				var dd := Vector2(c6.x, c6.z).distance_to(flat)
				if dd < bdd:
					bdd = dd
					bestc = Vector2(c6.x, c6.z)
		b.set_target(bestc, 0.5)
	elif elec_phase >= 1:
		if ei >= 0:
			var c7 := elec_center(ei % EW, ei / EW)
			b.set_target(Vector2(c7.x, c7.z), 0.5)
	elif retarget:
		var c8 := elec_center(randi() % EW, randi() % EH)
		b.set_target(Vector2(c8.x, c8.z), randf_range(1.0, 2.0))
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
	return elec_phase == 0 and elec_t < 0.4 and randf() < 0.25 * dt * 10.0


func sabotage(s: Subject) -> bool:
	if elec_phase != 0:
		return false
	var o := _nearest_other(s)
	if o == null:
		return false
	var ei := elec_at(o.position)
	if ei < 0:
		return false
	forced_hot = ei
	elec_t = minf(elec_t, 0.15)
	return true


func net_state() -> Dictionary:
	var hot := PackedByteArray()
	hot.resize(elec.size())
	for i in elec.size():
		hot[i] = 1 if elec[i].hot else 0
	return {"ph": elec_phase, "h": hot}


func apply_net_state(st: Dictionary) -> void:
	var ph := int(st.get("ph", elec_phase))
	if ph == 2 and elec_phase != 2:
		m.shake(0.4)
	elec_phase = ph
	var hot: PackedByteArray = st.get("h", PackedByteArray())
	if hot.size() == elec.size():
		for i in elec.size():
			elec[i].hot = hot[i] == 1
