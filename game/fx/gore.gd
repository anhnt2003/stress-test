class_name Gore
extends RefCounted
## Máu me: giọt máu, mảnh vụn, vết loang, và hình ảnh của từng kiểu chết.
## Chỉ là hình ảnh — không ảnh hưởng luật chơi.

const GRAVITY := 22.0

var m: MatchManager
var root: Node3D
var enabled := true
var blood_mat: StandardMaterial3D
var scorch_mat: StandardMaterial3D
var flesh_mat: StandardMaterial3D
var spark_mat: StandardMaterial3D
var smoke_mat: StandardMaterial3D
var disc_mesh: CylinderMesh
var drop_mesh: SphereMesh
var gibs: Array[Dictionary] = []
var decal_n := 0
## RNG riêng: máu me chỉ là hình ảnh, không được làm lệch chuỗi ngẫu nhiên của luật chơi
## (bật / tắt máu me không đổi diễn biến trận).
var rng := RandomNumberGenerator.new()


func _init(match_: MatchManager) -> void:
	m = match_
	blood_mat = Build.mat(Palette.BLOOD, 0.1)
	scorch_mat = Build.mat(Color(0.02, 0.02, 0.02), 0.95)
	flesh_mat = Build.mat(Palette.FLESH, 0.35)
	spark_mat = Build.glow(Color(1.0, 0.85, 0.4), 5.0)
	smoke_mat = Build.mat(Color(0.16, 0.15, 0.14), 1.0)
	disc_mesh = Build.disc_mesh()
	drop_mesh = SphereMesh.new()
	drop_mesh.radius = 1.0
	drop_mesh.height = 2.0
	drop_mesh.radial_segments = 6
	drop_mesh.rings = 3


func reset(level_root: Node3D) -> void:
	root = level_root
	gibs.clear()
	decal_n = 0


func _door() -> DoorBase:
	return m.door


func ground_at(p: Vector3) -> float:
	var d := _door()
	return d.gib_ground(p) if d else DoorBase.PLATFORM_TOP


func decal(pos: Vector3, r: float, mt: Material = null) -> void:
	if decal_n > 190:
		return
	decal_n += 1
	var gy := ground_at(pos)
	var p := Vector3(pos.x, gy + 0.012 + decal_n * 0.0003, pos.z)
	if p.y < -10.0:
		return
	var parent: Node = root
	var d0 := _door()
	if d0:
		var pp := d0.decal_parent(pos, p)
		parent = pp[0]
		p = pp[1]
	var use := mt if mt else blood_mat
	var d := Build.add_mesh(parent, disc_mesh, use, p)
	d.scale = Vector3(r * rng.randf_range(0.7, 1.4), 1.0, r * rng.randf_range(0.7, 1.4))
	d.rotation.y = rng.randf() * TAU
	if not enabled and use != scorch_mat:
		d.visible = false
	if d0:
		d0.on_decal(d, gy)
	if r > 0.14:   # vệt loang không tròn đều: thêm vài đốm vệ tinh
		for k in 2:
			var a := rng.randf() * TAU
			var d2 := Build.add_mesh(parent, disc_mesh, use, p + Vector3(cos(a), 0, sin(a)) * r * rng.randf_range(0.6, 1.2) + Vector3(0, 0.0002 * (k + 1), 0))
			d2.scale = Vector3(r * rng.randf_range(0.25, 0.6), 1.0, r * rng.randf_range(0.2, 0.5))
			d2.rotation.y = rng.randf() * TAU
			if not enabled and use != scorch_mat:
				d2.visible = false
			if d0:
				d0.on_decal(d2, gy)


func drop(pos: Vector3, vel: Vector3, mt: Material = null, stain := true) -> void:
	if gibs.size() > 280:
		return
	var use := mt if mt else blood_mat
	if not enabled and use == blood_mat:
		use = smoke_mat
	var mi := Build.add_mesh(root, drop_mesh, use, pos)
	mi.scale = Vector3.ONE * rng.randf_range(0.025, 0.06)
	gibs.append({"n": mi, "v": vel, "chunk": false, "rest": false, "b": 0, "spin": Vector3.ZERO, "stain": stain})


func chunk(pos: Vector3, vel: Vector3, mt: Material, size: float) -> void:
	var mi: MeshInstance3D
	var use := mt
	if not enabled and (mt == flesh_mat or mt == blood_mat):
		use = smoke_mat
	if rng.randf() < 0.5:
		mi = Build.box(root, Vector3(size, size * rng.randf_range(0.5, 0.9), size * rng.randf_range(0.6, 1.3)), use, pos)
	else:
		mi = Build.ball(root, size * 0.6, use, pos)
	chunk_node(mi, vel, size * 0.35)


func chunk_node(n: Node3D, vel: Vector3, rest_h: float) -> void:
	gibs.append({"n": n, "v": vel, "chunk": true, "rest": false, "b": 0, "h": rest_h,
		"spin": Vector3(rng.randf_range(-9, 9), rng.randf_range(-9, 9), rng.randf_range(-9, 9))})


func spray(pos: Vector3, count: int, dir: Vector3, speed: float, spread: float) -> void:
	for i in count:
		var v := dir * speed * rng.randf_range(0.4, 1.1) + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 1)) * spread
		drop(pos + Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1)), v)


func body_chunks(s: Subject, pos: Vector3, count: int, speed: float, up: float) -> void:
	var suit := Build.mat(s.look.color, 0.9)
	var skin := Build.mat(Palette.SKIN, 0.7)
	for i in count:
		var a := rng.randf() * TAU
		var v := Vector3(cos(a), 0, sin(a)) * speed * rng.randf_range(0.3, 1.0) + Vector3(0, up * rng.randf_range(0.5, 1.2), 0)
		var mt: Material = flesh_mat
		var r := rng.randf()
		if r < 0.4:
			mt = suit
		elif r < 0.55:
			mt = skin
		chunk(pos + Vector3(0, rng.randf_range(0.2, 1.2), 0), v, mt, rng.randf_range(0.1, 0.24))


func update(dt: float) -> void:
	var i := gibs.size() - 1
	while i >= 0:
		var g: Dictionary = gibs[i]
		i -= 1
		var n: Node3D = g.n
		if not is_instance_valid(n):
			gibs.remove_at(i + 1)
			continue
		if g.rest:
			var d := _door()
			if d and m.state == MatchManager.ST_PLAY and d.carry_rest_gib(n, dt):
				gibs.remove_at(i + 1)
			continue
		var v: Vector3 = g.v
		v.y -= GRAVITY * dt
		n.position += v * dt
		g.v = v
		if g.chunk:
			n.rotation += (g.spin as Vector3) * dt
		var gy := ground_at(n.position)
		if n.position.y < 0.45 and gy == -INF:
			n.queue_free()
			gibs.remove_at(i + 1)
		elif n.position.y <= gy + 0.03 and v.y < 0.0:
			if not g.chunk:
				if g.get("stain", true):
					decal(n.position, rng.randf_range(0.05, 0.19))
				n.queue_free()
				gibs.remove_at(i + 1)
			else:
				g.b += 1
				decal(n.position, rng.randf_range(0.12, 0.3))
				if g.b >= 2 or v.length() < 2.5:
					g.rest = true
					n.position.y = gy + float(g.h)
				else:
					n.position.y = gy + 0.04
					g.v = Vector3(v.x * 0.5, -v.y * 0.3, v.z * 0.5)


## Hình ảnh của một lần chết. pos = vị trí chân đối tượng lúc chết.
func death(s: Subject, mode: String, dir: Vector3, pos: Vector3) -> void:
	if not enabled:
		_clean_death(s, mode, dir, pos)
		return
	var mid := pos + Vector3(0, 0.8, 0)
	match mode:
		"crush":
			s.pivot.visible = false
			decal(pos, 1.0)
			decal(pos + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)), 0.7)
			for k in 46:
				var a := rng.randf() * TAU
				drop(pos + Vector3(cos(a), 0.15, sin(a)) * 0.9, Vector3(cos(a), 0, sin(a)) * rng.randf_range(2.0, 7.5) + Vector3(0, rng.randf_range(0.5, 2.5), 0))
			body_chunks(s, pos + Vector3(0, -0.6, 0), 7, 5.5, 1.5)
		"grind":
			s.pivot.visible = false
			var sd := dir if dir != Vector3.ZERO else Vector3.UP
			spray(pos + Vector3(0, 0.3, 0), 60, sd.normalized(), 9.0, 2.6)
			body_chunks(s, pos, 8, 3.0, 8.0 if dir == Vector3.ZERO else 5.0)
		"halved":
			s.upper.visible = false
			var u := Node3D.new()
			root.add_child(u)
			u.position = pos + Vector3(0, 0.85, 0)
			u.rotation = s.pivot.rotation
			u.scale = Vector3.ONE * Subject.SCALE
			SubjectModel.build_upper(u, s.look)
			chunk_node(u, dir * 5.5 + Vector3(0, 4.5, 0), 0.16)
			spray(mid, 46, dir, 6.0, 2.2)
			spray(mid, 14, Vector3.UP, 4.0, 1.0)
			decal(pos, 0.6)
		"burst":
			s.pivot.visible = false
			decal(pos, 1.5, scorch_mat)
			decal(pos, 0.8)
			for k in 70:
				var a2 := rng.randf() * TAU
				drop(mid, Vector3(cos(a2), 0, sin(a2)) * rng.randf_range(1.5, 8.5) + Vector3(0, rng.randf_range(1.0, 7.0), 0))
			body_chunks(s, pos, 14, 7.0, 6.0)
		"headpop":
			s.head.visible = false
			var np := pos + Vector3(0, 1.55, 0)
			spray(np, 26, Vector3.UP, 5.0, 2.2)
			for k in 6:
				var a3 := rng.randf() * TAU
				chunk(np, Vector3(cos(a3), 0, sin(a3)) * rng.randf_range(1.0, 4.0) + Vector3(0, rng.randf_range(3.0, 6.0), 0), flesh_mat if k % 2 == 0 else Build.mat(Palette.SKIN, 0.7), rng.randf_range(0.07, 0.13))
		"fry":
			SubjectModel.char_node(s.pivot, scorch_mat)
			decal(pos, 0.7, scorch_mat)
			for k in 22:
				var a4 := rng.randf() * TAU
				drop(mid + Vector3(0, rng.randf_range(-0.5, 0.6), 0), Vector3(cos(a4), 0, sin(a4)) * rng.randf_range(1.0, 4.5) + Vector3(0, rng.randf_range(1.0, 5.0), 0), spark_mat, false)


## Máu phun tiếp trong lúc đang chết (cổ, thân bị cắt).
func bleed(s: Subject) -> void:
	if not enabled:
		return
	if s.dead_mode == "headpop" and s.dead_t < 1.3 and rng.randf() < 0.7:
		var np: Vector3 = s.neck.global_position
		drop(np, Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(3.0, 5.5) * (1.0 - s.dead_t / 1.6), rng.randf_range(-0.8, 0.8)))
	if s.dead_mode == "halved" and s.dead_t < 0.8 and rng.randf() < 0.6:
		drop(s.position + Vector3(0, 0.75, 0), Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(1.5, 3.5), rng.randf_range(-1.2, 1.2)))


## Khi tắt máu me: không máu, không mảnh thịt. Người bị ép / nghiền / nổ biến mất trong làn khói và tia lửa,
## nổ vòng cổ thì chỉ loé điện, đầu vẫn còn.
func _clean_death(s: Subject, mode: String, dir: Vector3, pos: Vector3) -> void:
	var mid := pos + Vector3(0, 0.8, 0)
	match mode:
		"crush", "grind", "burst":
			s.pivot.visible = false
			decal(pos, 0.8 if mode == "burst" else 0.5, scorch_mat)
			for k in 30:
				var a := rng.randf() * TAU
				drop(mid + Vector3(0, rng.randf_range(-0.6, 0.6), 0), Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.5, 3.0) + Vector3(0, rng.randf_range(0.5, 3.5), 0), smoke_mat, false)
			for k in 14:
				var a2 := rng.randf() * TAU
				drop(mid, Vector3(cos(a2), 0, sin(a2)) * rng.randf_range(1.0, 5.0) + Vector3(0, rng.randf_range(1.0, 5.0), 0), spark_mat, false)
		"halved":
			s.upper.visible = false
			var u := Node3D.new()
			root.add_child(u)
			u.position = pos + Vector3(0, 0.85, 0)
			u.rotation = s.pivot.rotation
			u.scale = Vector3.ONE * Subject.SCALE
			SubjectModel.build_upper(u, s.look)
			chunk_node(u, dir * 5.5 + Vector3(0, 4.5, 0), 0.16)
			for k in 16:
				drop(mid, dir * rng.randf_range(1.0, 4.0) + Vector3(rng.randf_range(-1, 1), rng.randf_range(0.5, 3.0), rng.randf_range(-1, 1)), spark_mat, false)
		"headpop":
			var np := pos + Vector3(0, 1.45, 0)
			for k in 18:
				var a3 := rng.randf() * TAU
				drop(np, Vector3(cos(a3), 0, sin(a3)) * rng.randf_range(0.5, 2.5) + Vector3(0, rng.randf_range(1.0, 3.5), 0), spark_mat, false)
		"fry":
			SubjectModel.char_node(s.pivot, scorch_mat)
			decal(pos, 0.7, scorch_mat)
			for k in 22:
				var a4 := rng.randf() * TAU
				drop(mid + Vector3(0, rng.randf_range(-0.5, 0.6), 0), Vector3(cos(a4), 0, sin(a4)) * rng.randf_range(1.0, 4.5) + Vector3(0, rng.randf_range(1.0, 5.0), 0), spark_mat, false)
