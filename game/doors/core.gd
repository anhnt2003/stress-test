extends DoorBase
## Cửa LÕI NỔ: chạm để chuyền lõi, hết giờ là nổ.

const FUSE := 10.0

var core: Node3D
var core_mat: StandardMaterial3D
var core_light: OmniLight3D
var core_display: Label3D
var core_holder := 0
var core_timer := FUSE
var core_cd := 0.0
var core_wait := 0.0
var core_phase := 0.0
var _was_on := false
var _shown_holder := -1


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 3
	title = "LÕI NỔ"
	rule = "Chạm để chuyền lõi. Hết giờ là nổ"
	sabotage_hint = "NÉM LÕI CHO NGƯỜI GẦN NHẤT"


func setup(level_root: Node3D) -> void:
	super(level_root)
	build_platform(PLATFORM_R + 0.2)
	core = Node3D.new()
	root.add_child(core)
	Build.cyl(core, 0.17, 0.17, 0.42, Build.mat(Color(0.12, 0.12, 0.11), 0.5, 0.7), Vector3.ZERO, Vector3.ZERO, 10)
	for y in [-0.14, 0.14]:
		Build.cyl(core, 0.185, 0.185, 0.05, Build.mat(Palette.RUST, 0.8, 0.4), Vector3(0, y, 0), Vector3.ZERO, 10)
	core_mat = Build.glow(Color(1.0, 0.12, 0.05), 3.0)
	Build.cyl(core, 0.178, 0.178, 0.12, core_mat, Vector3.ZERO, Vector3.ZERO, 10)
	for k in 3:
		Build.cyl(core, 0.012, 0.012, 0.3, Build.mat(Color(0.5, 0.05, 0.05), 0.5), Vector3(cos(k * 2.1) * 0.19, 0.05, sin(k * 2.1) * 0.19), Vector3(0, 0, 12), 5)
	core_light = Build.omni(core, Vector3(0, 0.1, 0), Color(1.0, 0.15, 0.06), 2.0, 6.0)
	Build.box(root, Vector3(2.7, 2.1, 0.12), Build.mat(Color(0.02, 0.02, 0.02), 0.4), Vector3(-3.9, 2.35, -5.5))
	var cap := Build.label3d(root, "KÍCH NỔ SAU", Vector3(-3.9, 3.13, -5.42), 44, Palette.AMBER, 0.0055)
	cap.shaded = false
	core_display = Build.label3d(root, "10", Vector3(-3.9, 2.17, -5.42), 230, Color(1.0, 0.12, 0.08), 0.0062)
	core_display.shaded = false
	core_timer = FUSE
	core_holder = randi() % 4   # người cầm lõi đầu tiên chọn theo seed, không cố định một ghế
	core_cd = 0.0
	core_wait = 0.0
	spawn_circle(2.5, 0.3)


func _hide() -> void:
	core.visible = false
	core_light.light_energy = 0.0
	core_display.text = "00"


func _visual(dt: float) -> void:
	if core_wait > 0.0:
		_hide()
		return
	var h: Subject = subjects()[core_holder]
	core.visible = true
	core_phase += lerpf(5.0, 34.0, 1.0 - core_timer / FUSE) * dt
	var pulse := 1.0 if sin(core_phase) > 0.2 else 0.0
	if pulse > 0.5 and not _was_on:
		m.play_sfx("beep", -9.0)
	_was_on = pulse > 0.5
	core.position = h.position + Vector3(0, 2.28 * Subject.SCALE, 0)
	if core_holder != _shown_holder:
		_shown_holder = core_holder
		core.reset_physics_interpolation()   # lõi chuyền sang người khác: nhảy, không lướt
	if h.pivot:
		core.rotation.y = h.yaw()
	core_mat.emission_energy_multiplier = 0.4 + 6.0 * pulse
	core_light.light_energy = 0.4 + 3.2 * pulse
	core_display.text = "%02d" % int(ceil(maxf(core_timer, 0.0)))


func tick(dt: float) -> void:
	core_cd = maxf(0.0, core_cd - dt)
	if core_wait > 0.0:
		core_wait -= dt
		_hide()
		if core_wait <= 0.0:
			core_timer = FUSE
			core_holder = (core_holder + 1 + randi() % 3) % 4
		return
	core_timer -= dt
	var h: Subject = subjects()[core_holder]
	var hp := h.position
	_visual(dt)
	h.scared = true   # hai tay giơ cao ôm lõi
	h.speed = 4.1
	if core_cd <= 0.0:
		for o in subjects():
			if o.idx != core_holder and o.out <= 0.0 and hp.distance_to(o.position) < 0.95:
				core_holder = o.idx
				core_cd = 0.9
				break
	if core_timer <= 0.0:
		var v: Subject = subjects()[core_holder]
		m.kill(v, "burst")
		core_wait = 3.0
		m.announce("ĐỐI TƯỢNG %s: PHÂN TÁN TRÊN DIỆN RỘNG." % m.subj_label(v))


func client_tick(dt: float) -> void:
	_visual(dt)


func led_alarm(s: Subject) -> bool:
	return s.idx == core_holder and core_wait <= 0.0


func constrain(_s: Subject, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z).limit_length(PLATFORM_R - 0.25)
	return Vector3(f.x, p.y, f.y)


func hide_for_closeup() -> void:
	core.visible = false


func bot_steer(s: Subject, b: BotBrain, _dt: float, _arrived: bool, retarget: bool) -> Variant:
	var p := s.position
	var flat := Vector2(p.x, p.z)
	var lim := PLATFORM_R - 0.3
	var holder: Subject = subjects()[core_holder]
	if core_wait <= 0.0 and s.idx == core_holder:
		var bd := 1e9
		for o in subjects():
			if o.idx != s.idx and o.out <= 0.0:
				var op := o.position
				if p.distance_to(op) < bd:
					bd = p.distance_to(op)
					b.target = op
	elif core_wait <= 0.0 and flat.distance_to(Vector2(holder.position.x, holder.position.z)) < 3.4:
		var hp := holder.position
		var away2 := flat - Vector2(hp.x, hp.z)
		var side := 1.0 if s.idx % 2 == 0 else -1.0
		var tang := Vector2(-away2.y, away2.x).normalized() * side
		var edge := clampf(flat.length() / lim, 0.0, 1.0)
		var dir2 := away2.normalized() * (1.0 - 0.75 * edge) + tang * (0.3 + 0.9 * edge)
		b.set_target((flat + dir2.normalized() * 1.5).limit_length(lim), 0.5)
	elif retarget:
		b.set_target(Build.rand_circle(0.3, lim), randf_range(1.0, 2.0))
	return null


func _nearest_other(s: Subject, max_d: float) -> Subject:
	var best: Subject = null
	var bd := max_d
	for o in subjects():
		if o != s and o.alive():
			var d := o.position.distance_to(s.position)
			if d < bd:
				bd = d
				best = o
	return best


func bot_wants_sabotage(s: Subject, _b: BotBrain, dt: float) -> bool:
	return s.idx == core_holder and core_wait <= 0.0 and core_timer < 4.0 and randf() < 1.5 * dt


func sabotage(s: Subject) -> bool:
	# chỉ người đang cầm lõi mới ném được: lõi bay sang người gần nhất trong 4 m
	if s.idx != core_holder or core_wait > 0.0:
		return false
	var o := _nearest_other(s, 4.0)
	if o == null:
		return false
	core_holder = o.idx
	core_cd = 1.2
	return true


func net_state() -> Dictionary:
	return {"h": core_holder, "tm": core_timer, "w": core_wait}


func apply_net_state(st: Dictionary) -> void:
	core_holder = int(st.get("h", core_holder))
	core_timer = float(st.get("tm", core_timer))
	core_wait = float(st.get("w", core_wait))
