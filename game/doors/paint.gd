extends DoorBase
## Cửa SÀN CẢM ỨNG: chiếm nhiều ô nhất. Ai không đứng đầu thì nổ vòng cổ.

const PAINT_W := 9
const PAINT_H := 7
const PAINT_TOP := 0.56

var paint_owner := PackedInt32Array()
var paint_mats: Array[StandardMaterial3D] = []


func _init(match_: MatchManager) -> void:
	super(match_)
	id = 4
	title = "SÀN CẢM ỨNG"
	rule = "Chiếm nhiều ô nhất. Ai không đứng đầu thì nổ vòng cổ"
	sabotage_hint = "CƯỚP 3×3 Ô QUANH MÌNH"
	scores_tiles = true
	cam_base = Vector3(5.6, 5.0, 6.1)
	cam_look = Vector3(-0.7, 0.3, -0.6)


func setup(level_root: Node3D) -> void:
	super(level_root)
	Build.box(root, Vector3(PAINT_W + 0.5, 0.5, PAINT_H + 0.5), Build.grime(Color(0.16, 0.15, 0.13), 0.5, 0.8, 0.5, 14.0), Vector3(0, 0.25, 0))
	paint_owner = PackedInt32Array()
	for iz in PAINT_H:
		for ix in PAINT_W:
			var mt := Build.mat(Color(0.07, 0.075, 0.075), 0.25, 0.3)
			mt.emission_enabled = true
			mt.emission_energy_multiplier = 0.0
			Build.box(root, Vector3(0.92, 0.06, 0.92), mt, Vector3(ix - PAINT_W / 2.0 + 0.5, 0.53, iz - PAINT_H / 2.0 + 0.5))
			paint_mats.append(mt)
			paint_owner.append(-1)
	var corners := [Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(1, 1)]
	for i in 4:
		m.spawn_subject(i, Vector3(corners[i].x * (PAINT_W / 2.0 - 0.5), PAINT_TOP, corners[i].y * (PAINT_H / 2.0 - 0.5)))


func paint_at(p: Vector3) -> int:
	var ix := int(floor(p.x + PAINT_W / 2.0))
	var iz := int(floor(p.z + PAINT_H / 2.0))
	if ix < 0 or iz < 0 or ix >= PAINT_W or iz >= PAINT_H:
		return -1
	return iz * PAINT_W + ix


func _set_owner(pi: int, who: int) -> void:
	if paint_owner[pi] == who:
		return
	paint_owner[pi] = who
	var c: Color = subjects()[who].look.color if who >= 0 else Color(0.07, 0.075, 0.075)
	paint_mats[pi].albedo_color = c.darkened(0.5) if who >= 0 else c
	paint_mats[pi].emission = c.lightened(0.1)
	paint_mats[pi].emission_energy_multiplier = 1.1 if who >= 0 else 0.0


func tick(_dt: float) -> void:
	for s in subjects():
		if s.ground and s.out <= 0.0:
			var pi := paint_at(s.position)
			if pi >= 0 and paint_owner[pi] != s.idx:
				_set_owner(pi, s.idx)
	_count()


func _count() -> void:
	for s in subjects():
		s.score = 0
	for o in paint_owner:
		if o >= 0:
			subjects()[o].score += 1


func ground_y(_p: Vector3) -> float:
	return PAINT_TOP


func gib_ground(p: Vector3) -> float:
	return PAINT_TOP if absf(p.x) < PAINT_W / 2.0 + 0.25 and absf(p.z) < PAINT_H / 2.0 + 0.25 else 0.0


func constrain(_s: Subject, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z).clamp(Vector2(-PAINT_W / 2.0 + 0.3, -PAINT_H / 2.0 + 0.3), Vector2(PAINT_W / 2.0 - 0.3, PAINT_H / 2.0 - 0.3))
	return Vector3(f.x, p.y, f.y)


func spawn_point() -> Vector3:
	return Vector3(randf_range(-3.5, 3.5), PAINT_TOP, randf_range(-2.5, 2.5))


func bot_steer(s: Subject, b: BotBrain, _dt: float, _arrived: bool, retarget: bool) -> Variant:
	if retarget:
		var flat := Vector2(s.position.x, s.position.z)
		var best := Vector2(randf_range(-4, 4), randf_range(-3, 3))
		var bd2 := 1e9
		for k in 7:
			var ix := randi() % PAINT_W
			var iz := randi() % PAINT_H
			if paint_owner[iz * PAINT_W + ix] != s.idx:
				var c := Vector2(ix - PAINT_W / 2.0 + 0.5, iz - PAINT_H / 2.0 + 0.5)
				if c.distance_to(flat) < bd2:
					bd2 = c.distance_to(flat)
					best = c
		b.set_target(best, 1.6)
	return null


func bot_wants_sabotage(s: Subject, _b: BotBrain, dt: float) -> bool:
	return m.lt > 20.0 and _foreign_around(s) >= 5 and randf() < 1.2 * dt


func _foreign_around(s: Subject) -> int:
	var pi := paint_at(s.position)
	if pi < 0:
		return 0
	var n := 0
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var ix: int = pi % PAINT_W + dx
			var iz: int = pi / PAINT_W + dz
			if ix >= 0 and iz >= 0 and ix < PAINT_W and iz < PAINT_H and paint_owner[iz * PAINT_W + ix] != s.idx:
				n += 1
	return n


func sabotage(s: Subject) -> bool:
	var pi := paint_at(s.position)
	if pi < 0:
		return false
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var ix: int = pi % PAINT_W + dx
			var iz: int = pi / PAINT_W + dz
			if ix >= 0 and iz >= 0 and ix < PAINT_W and iz < PAINT_H:
				_set_owner(iz * PAINT_W + ix, s.idx)
	_count()
	return true


func net_state() -> Dictionary:
	var st := PackedByteArray()
	st.resize(paint_owner.size())
	for i in paint_owner.size():
		st[i] = paint_owner[i] + 1
	return {"p": st}


func apply_net_state(d: Dictionary) -> void:
	var st: PackedByteArray = d.get("p", PackedByteArray())
	if st.size() != paint_owner.size():
		return
	for i in st.size():
		_set_owner(i, int(st[i]) - 1)
	_count()
