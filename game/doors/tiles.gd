extends DoorBase
## Cửa SÀN NGHIỀN: tấm sàn bị dẫm hai lần sẽ rơi xuống trục nghiền.

const TILE_N := 7
const TILE_S := 1.2
const TILE_TOP := 1.3

var tiles: Array[Dictionary] = []
var rollers: Array[Node3D] = []


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 1
	title = "SÀN NGHIỀN"
	rule = "Tấm sàn bị dẫm hai lần sẽ rơi xuống máy nghiền"
	sabotage_hint = "LÀM NỨT SÀN QUANH MÌNH"
	cam_base = Vector3(5.6, 5.0, 6.1)
	cam_look = Vector3(-0.7, 0.9, -0.6)


func tile_half() -> float:
	return TILE_N * TILE_S / 2.0


func tile_center(ix: int, iz: int) -> Vector3:
	return Vector3(-tile_half() + (ix + 0.5) * TILE_S, TILE_TOP, -tile_half() + (iz + 0.5) * TILE_S)


func tile_at(p: Vector3) -> int:
	var ix := int(floor((p.x + tile_half()) / TILE_S))
	var iz := int(floor((p.z + tile_half()) / TILE_S))
	if ix < 0 or iz < 0 or ix >= TILE_N or iz >= TILE_N:
		return -1
	return iz * TILE_N + ix


func setup(level_root: Node3D) -> void:
	super(level_root)
	var h := tile_half()
	var wall_m := Build.grime(Color(0.20, 0.19, 0.16), 0.6, 0.8, 0.5, 14.0)
	var hazard := Build.shader_mat("res://shaders/hazard.gdshader")
	for s in [-1.0, 1.0]:
		Build.box(root, Vector3(h * 2 + 0.9, 1.0, 0.35), wall_m, Vector3(0, 0.5, s * (h + 0.28)))
		Build.box(root, Vector3(0.35, 1.0, h * 2 + 0.9), wall_m, Vector3(s * (h + 0.28), 0.5, 0))
		Build.box(root, Vector3(h * 2 + 0.95, 0.12, 0.4), hazard, Vector3(0, 1.06, s * (h + 0.28)))
		Build.box(root, Vector3(0.4, 0.12, h * 2 + 0.95), hazard, Vector3(s * (h + 0.28), 1.06, 0))
	Build.box(root, Vector3(h * 2 + 0.3, 0.05, h * 2 + 0.3), Build.mat(Color(0.10, 0.008, 0.008), 0.15), Vector3(0, 0.03, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.box(root, Vector3(0.22, TILE_TOP, 0.22), wall_m, Vector3(sx * (h + 0.28), TILE_TOP / 2.0, sz * (h + 0.28)))
	# trục nghiền có răng
	var rm := Build.grime(Color(0.30, 0.27, 0.24), 0.6, 0.7, 0.7, 14.0, 0.5)
	var tm := Build.mat(Color(0.30, 0.05, 0.04), 0.3, 0.6)
	for ri in 6:
		var roller := Node3D.new()
		root.add_child(roller)
		roller.position = Vector3(0, 0.55, -h + 0.7 + ri * (h * 2 - 1.4) / 5.0)
		roller.rotation_degrees.z = 90.0
		Build.cyl(roller, 0.36, 0.36, h * 2, rm, Vector3.ZERO, Vector3.ZERO, 10)
		for k in 9:
			for j in 4:
				var a := j * TAU / 4.0 + k * 0.5
				Build.box(roller, Vector3(0.2, 0.16, 0.34), tm, Vector3(cos(a) * 0.4, -h + 0.5 + k * (h * 2 - 1.0) / 8.0, sin(a) * 0.4), Vector3(0, -rad_to_deg(a), 0))
		roller.set_meta("dir", 1.0 if ri % 2 == 0 else -1.0)
		rollers.append(roller)
	for pos in [Vector3(-2.2, 1.0, -1.5), Vector3(2.2, 1.0, 1.5)]:
		Build.omni(root, pos, Color(1.0, 0.08, 0.04), 4.5, 7.0)
	for iz in TILE_N:
		for ix in TILE_N:
			var v := randf_range(0.8, 1.1)
			var base_col := Color(0.30 * v, 0.28 * v, 0.23 * v)
			var mt := Build.grime(base_col, 0.5, 0.8, 0.5, 12.0, 0.6)
			var c := tile_center(ix, iz)
			var mi := Build.box(root, Vector3(TILE_S - 0.17, 0.12, TILE_S - 0.17), mt, Vector3(c.x, TILE_TOP - 0.06, c.z))
			tiles.append({"mi": mi, "mat": mt, "col": base_col, "state": 0, "hp": 2, "timer": 0.0, "vy": 0.0, "base": mi.position, "home": mi.position})
	var spots := [Vector2i(1, 5), Vector2i(5, 1), Vector2i(1, 1), Vector2i(5, 5)]
	for i in 4:
		m.spawn_subject(i, tile_center(spots[i].x, spots[i].y))


func _damage(ti: int) -> void:
	if tiles[ti].state != 0:
		return
	tiles[ti].hp -= 1
	var tm: ShaderMaterial = tiles[ti].mat
	if tiles[ti].hp <= 0:
		tiles[ti].state = 1
		tiles[ti].timer = 1.4
	else:
		# lần dẫm đầu: tấm sàn võng xuống, đèn cảnh báo đỏ mờ
		tm.set_shader_parameter("base", Color(0.20, 0.09, 0.06))
		tm.set_shader_parameter("emit_e", 0.10)
		(tiles[ti].mi as Node3D).position.y -= 0.035
		tiles[ti].base = (tiles[ti].mi as Node3D).position


func _spin(dt: float) -> void:
	for r in rollers:
		r.rotate_object_local(Vector3.UP, dt * 3.0 * float(r.get_meta("dir")))


func tick(dt: float) -> void:
	_spin(dt)
	for s in subjects():
		if s.out <= 0.0 and s.ground:
			var ti := tile_at(s.position)
			if ti >= 0 and ti != s.last_tile and m.lt > 1.0:
				s.last_tile = ti
				_damage(ti)
	var solid := _animate_tiles(dt)
	if solid < 8:
		_reset_tiles()


func _animate_tiles(dt: float) -> int:
	var solid := 0
	for tl in tiles:
		var mi: MeshInstance3D = tl.mi
		var mt: ShaderMaterial = tl.mat
		match tl.state:
			0:
				solid += 1
			1:
				tl.timer -= dt
				var k := 1.0 - float(tl.timer) / 1.4
				mi.position = (tl.base as Vector3) + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.025 + Vector3(0, -0.05 * k, 0)
				mt.set_shader_parameter("emit_e", 0.10 + k * 1.1)
				if tl.timer <= 0.0:
					tl.state = 2
					tl.vy = 0.0
			2:
				tl.vy -= Subject.GRAVITY * dt
				mi.position.y += float(tl.vy) * dt
				mi.rotation.x += dt * 2.0
				mi.rotation.z += dt * 1.3
				if mi.position.y < 0.6:
					tl.state = 3
					mi.visible = false
	return solid


func _reset_tiles() -> void:
	# hết sàn thì lắp lại sàn mới, điểm số trong cửa vẫn giữ
	for tl in tiles:
		var mi: MeshInstance3D = tl.mi
		tl.state = 0
		tl.hp = 2
		mi.visible = true
		mi.position = tl.home
		mi.rotation = Vector3.ZERO
		tl.base = tl.home
		(tl.mat as ShaderMaterial).set_shader_parameter("base", tl.col)
		(tl.mat as ShaderMaterial).set_shader_parameter("emit_e", 0.0)
	for s in subjects():
		s.last_tile = -1


func ground_y(p: Vector3) -> float:
	var ti := tile_at(p)
	return TILE_TOP if ti >= 0 and tiles[ti].state <= 1 else -INF


func gib_ground(p: Vector3) -> float:
	var h := tile_half() + 0.1
	if absf(p.x) > h + 0.5 or absf(p.z) > h + 0.5:
		return 0.0
	var ti := tile_at(p)
	return TILE_TOP if ti >= 0 and tiles[ti].state <= 1 else -INF


func decal_parent(pos: Vector3, p: Vector3) -> Array:
	var ti := tile_at(pos)
	if ti >= 0 and tiles[ti].state <= 1 and absf(pos.x) < tile_half() and absf(pos.z) < tile_half():
		var mi: Node3D = tiles[ti].mi
		return [mi, p - mi.position]
	return [root, p]


func constrain(_s: Subject, p: Vector3) -> Vector3:
	var h := tile_half() - 0.3
	var f := Vector2(p.x, p.z).clamp(Vector2(-h, -h), Vector2(h, h))
	return Vector3(f.x, p.y, f.y)


func spawn_point() -> Vector3:
	var solid: Array[int] = []
	for i in tiles.size():
		if tiles[i].state == 0:
			solid.append(i)
	if solid.size() > 0:
		var ti := solid[randi() % solid.size()]
		return tile_center(ti % TILE_N, ti / TILE_N)
	return tile_center(3, 3)


func after_move(s: Subject) -> void:
	if s.position.y < 0.85:
		m.kill(s, "grind")
		m.announce("ĐỐI TƯỢNG %s: ĐÃ ĐƯỢC TÁI CHẾ." % m.subj_label(s))


func _neighbor_target(p: Vector3) -> Vector3:
	var ti := tile_at(p)
	if ti < 0:
		return Vector3.ZERO
	var ix := ti % TILE_N
	var iz := ti / TILE_N
	var good: Array[Vector3] = []
	var ok: Array[Vector3] = []
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue
			var nx: int = ix + dx
			var nz: int = iz + dz
			if nx < 0 or nz < 0 or nx >= TILE_N or nz >= TILE_N:
				continue
			var st: int = tiles[nz * TILE_N + nx].state
			if dx != 0 and dz != 0 and (tiles[iz * TILE_N + nx].state > 1 or tiles[nz * TILE_N + ix].state > 1):
				continue
			if st == 0 and tiles[nz * TILE_N + nx].hp == 2:
				good.append(tile_center(nx, nz))
			elif st == 0:
				ok.append(tile_center(nx, nz))
	if good.size() > 0 and (ok.size() == 0 or randf() < 0.75):
		return good[randi() % good.size()]
	if ok.size() > 0:
		return ok[randi() % ok.size()]
	return p


func bot_steer(s: Subject, b: BotBrain, _dt: float, arrived: bool, _retarget: bool) -> Variant:
	s.speed = 2.6
	if arrived and b.ai_t > 0.3:
		b.ai_t = 0.3
	if b.ai_t <= 0.0:
		var nt := _neighbor_target(s.position)
		b.set_target(Vector2(nt.x, nt.z), 1.6)
	return null


func bot_wants_sabotage(s: Subject, _b: BotBrain, dt: float) -> bool:
	for o in subjects():
		if o != s and o.alive() and o.position.distance_to(s.position) < 1.8:
			return randf() < 0.35 * dt
	return false


func sabotage(s: Subject) -> bool:
	# làm nứt 8 tấm sàn quanh mình (tấm mình đang đứng thì không)
	var ti := tile_at(s.position)
	if ti < 0:
		return false
	var ix := ti % TILE_N
	var iz := ti / TILE_N
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var nx: int = ix + dx
			var nz: int = iz + dz
			if (dx == 0 and dz == 0) or nx < 0 or nz < 0 or nx >= TILE_N or nz >= TILE_N:
				continue
			_damage(nz * TILE_N + nx)
	return true


func client_tick(dt: float) -> void:
	_spin(dt)
	_animate_tiles(dt)


func net_state() -> Dictionary:
	var st := PackedByteArray()
	st.resize(tiles.size())
	for i in tiles.size():
		st[i] = int(tiles[i].state) * 4 + int(tiles[i].hp)
	return {"t": st}


func apply_net_state(d: Dictionary) -> void:
	var st: PackedByteArray = d.get("t", PackedByteArray())
	if st.size() != tiles.size():
		return
	for i in tiles.size():
		if st[i] / 4 == 0 and int(tiles[i].state) != 0:
			_reset_tiles()   # máy chủ vừa lắp sàn mới
			break
	for i in tiles.size():
		var ns := st[i] / 4
		var nh := st[i] % 4
		var tl: Dictionary = tiles[i]
		if ns == 0 and nh == 1 and int(tl.hp) == 2:
			_damage(i)
		elif ns >= 1 and int(tl.state) == 0:
			tl.state = 1
			tl.hp = 0
			tl.timer = 1.4
