class_name MatchManager
extends Node3D
## Máy trạng thái của một trận: sảnh → giới thiệu cửa → thi → chấm điểm → ... → tổng kết.
## Toàn bộ luật chơi chạy ở đây (trên máy chủ). Hình ảnh và âm thanh phản ứng qua signal.

signal state_changed(state: int)
signal door_loaded(door_index: int, door: DoorBase)
signal killed(s: Subject, mode: String, dir: Vector3, pos: Vector3)
signal respawned(s: Subject)
signal announced(text: String, duration: float)
signal sfx_requested(sound: String, vol_db: float, pitch: float)
signal shake_requested(amount: float)
signal round_ended(rows: Array)
signal match_ended(rows: Array, best: int)
signal sabotaged(s: Subject, hint: String)

const ST_INTRO := 0
const ST_PLAY := 1
const ST_RESULT := 2
const ST_FINAL := 3
const ST_LOBBY := 4
const ROUND_TIME := 30.0
const INTRO_TIME := 2.6
const RESULT_TIME := 6.0
const DOORS := 10

## Thứ tự 10 cửa trong một trận.
const ORDER := [
	preload("res://game/doors/press.gd"), preload("res://game/doors/elec.gd"), preload("res://game/doors/saw.gd"),
	preload("res://game/doors/belt.gd"), preload("res://game/doors/paint.gd"), preload("res://game/doors/weights.gd"),
	preload("res://game/doors/tiles.gd"), preload("res://game/doors/pendulum.gd"), preload("res://game/doors/core.gd"),
	preload("res://game/doors/fire.gd"),
]
const LobbyRoom := preload("res://game/doors/lobby_room.gd")
const SUBJECT_SCENE := preload("res://game/actors/subject.tscn")

var seats := Seats.new()
var gore: Gore
var door: DoorBase
var door_index := 0
var state := ST_LOBBY
var t := 0.0
var lt := 0.0
var state_t := 0.0
var totals := [0, 0, 0, 0]
var total_deaths := [0, 0, 0, 0]
var last_rows: Array = []
var subjects: Array[Subject] = []
var corpses: Array[Node3D] = []
var level_root: Node3D
## In nhật ký sự kiện ra stdout (chế độ mô phỏng không màn hình, dùng cho smoke test).
var log_events := false
## Máy khách mạng: không chạy luật, chỉ nhận trạng thái.
var remote := false
## Hướng camera quanh trục đứng (để người trong sảnh quay mặt về camera).
var cam_yaw := 0.0
## Cho phép nút chơi xấu (mỗi người một lần mỗi cửa).
var sabotage_enabled := true
## Đổi seed của cả trận (0 = giống bản mẫu, để smoke test so được kết quả).
var seed_base := 0


func _init() -> void:
	gore = Gore.new(self)


func level_id() -> int:
	return door.id if door else -1


func _new_level_root() -> void:
	if level_root:
		remove_child(level_root)
		level_root.queue_free()
	level_root = Node3D.new()
	level_root.name = "Level"
	add_child(level_root)
	subjects.clear()
	corpses.clear()
	gore.reset(level_root)
	lt = 0.0


func _set_state(s: int) -> void:
	state = s
	state_t = 0.0
	state_changed.emit(s)


# ---------- sảnh, trận, cửa ----------
func load_lobby() -> void:
	door_index = 0
	_new_level_root()
	totals = [0, 0, 0, 0]
	total_deaths = [0, 0, 0, 0]
	seed(1)
	door = LobbyRoom.new(self)
	door.setup(level_root)
	door_loaded.emit(-1, door)
	_set_state(ST_LOBBY)


func start_match() -> void:
	totals = [0, 0, 0, 0]
	total_deaths = [0, 0, 0, 0]
	load_door(0, true)


func load_door(d: int, intro: bool) -> void:
	door_index = clampi(d, 0, DOORS - 1)
	_new_level_root()
	door = ORDER[door_index].new(self)
	seed(door_index * 7 + 3 + seed_base * 7919)
	door.setup(level_root)
	door_loaded.emit(door_index, door)
	_set_state(ST_INTRO if intro else ST_PLAY)


func spawn_subject(i: int, pos: Vector3) -> Subject:
	var s: Subject = SUBJECT_SCENE.instantiate()
	level_root.add_child(s)
	s.setup(i, pos, seats.looks[i])
	subjects.append(s)
	return s


# ---------- sự kiện ----------
func announce(text: String, duration := 3.2) -> void:
	if log_events:
		print("ann L%d t=%.2f %s" % [level_id() + 1, lt, text])
	announced.emit(text, duration)


## Âm thanh / rung camera do luật chơi phát ra. Trên máy khách, phần hình ảnh của cửa cũng gọi các hàm này
## nhưng bị bỏ qua: máy chủ gửi sự kiện xuống để khỏi phát hai lần.
func play_sfx(sound: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not remote:
		sfx_requested.emit(sound, vol_db, pitch)


func shake(amount: float) -> void:
	if not remote:
		shake_requested.emit(amount)


func subj_label(s: Subject) -> String:
	return String(s.look.label)


func kill(s: Subject, mode: String, dir := Vector3.ZERO, count := true) -> void:
	if s.out > 0.0:
		return
	var pos := s.position
	s.out = 3.0
	if count and state == ST_PLAY:
		s.deaths += 1
		if s.deaths == 1:
			s.first_death = lt
	s.doom = -1.0
	kill_fx(s, mode, dir, pos)


## Phần hình ảnh của một lần chết (máy chủ và máy khách cùng chạy).
func kill_fx(s: Subject, mode: String, dir: Vector3, pos: Vector3) -> void:
	if s.pivot:
		s.pivot.visible = true   # máy khách có thể đã ẩn hình nhân theo ảnh chụp trước khi RPC chết tới
	s.out = maxf(s.out, 3.0)
	s.dead_mode = mode
	s.dead_t = 0.0
	s.flat = 0.0
	s.tag.visible = false
	s.set_solid(false)
	gore.death(s, mode, dir, pos)
	killed.emit(s, mode, dir, pos)


# ---------- chấm điểm ----------
func _end_round() -> void:
	var metric := []
	for s in subjects:
		metric.append(door.metric(s, ROUND_TIME))
	var ranks := Scoring.rank(metric)
	last_rows.clear()
	for i in Seats.N:
		var pts: int = Scoring.points_for_rank(int(ranks[i]))
		totals[i] += pts
		total_deaths[i] += subjects[i].deaths
		last_rows.append({"idx": i, "rank": int(ranks[i]), "detail": door.detail(subjects[i]), "pts": pts, "total": int(totals[i])})
	last_rows.sort_custom(func(a, c): return a.rank < c.rank or (a.rank == c.rank and a.idx < c.idx))
	_set_state(ST_RESULT)
	if door.scores_tiles:   # sàn cảm ứng: ai không đứng đầu thì nổ vòng cổ
		var kth := 0
		for i in Seats.N:
			if int(ranks[i]) > 1:
				subjects[i].doom = 0.7 + 0.45 * kth
				kth += 1
	announce("CỬA %d KẾT THÚC. ĐANG CHẤM ĐIỂM." % (door_index + 1))
	if log_events:
		print("RESULT door=%d totals=%s" % [door_index + 1, str(totals)])
	round_ended.emit(last_rows)


func _enter_final() -> void:
	_set_state(ST_FINAL)
	var metric := []
	for i in Seats.N:
		metric.append(Scoring.final_metric(int(totals[i]), int(total_deaths[i])))
	var ranks := Scoring.rank(metric)
	last_rows.clear()
	var best := 0
	var kth := 0
	for i in Seats.N:
		var verdict := "ĐƯỢC GIỮ LẠI" if int(ranks[i]) == 1 else "LOẠI BỎ"
		last_rows.append({"idx": i, "rank": int(ranks[i]), "detail": "CHẾT %d LẦN" % int(total_deaths[i]), "pts": int(totals[i]), "total": int(totals[i]), "verdict": verdict})
		if int(ranks[i]) == 1:
			best = i
		elif subjects[i].out <= 0.0:
			subjects[i].doom = 1.2 + 0.6 * kth
			kth += 1
	last_rows.sort_custom(func(a, c): return a.rank < c.rank or (a.rank == c.rank and a.idx < c.idx))
	announce("ĐÃ QUA 10 CỬA. GIỮ LẠI ĐỐI TƯỢNG %s. LOẠI BỎ PHẦN CÒN LẠI." % subj_label(subjects[best]), 999.0)
	if log_events:
		print("FINAL totals=%s deaths=%s best=%d" % [str(totals), str(total_deaths), best + 1])
	match_ended.emit(last_rows, best)


func _run_executions() -> void:
	for s in subjects:
		if s.doom > 0.0 and s.out <= 0.0:
			s.scared = true
			if state_t >= s.doom:
				kill(s, "headpop", Vector3.ZERO, false)


# ---------- nhân vật ----------
func _do_shove(s: Subject) -> void:
	# đẩy người đứng trước mặt: văng ra khoảng 2 mét, khựng lại một nhịp
	var fwd := s.forward()
	s.shove_cd = 1.3
	s.shove_t = 0.25
	play_sfx("shove", -4.0)
	for o in subjects:
		if o.idx == s.idx or o.out > 0.0:
			continue
		var dv := o.position - s.position
		dv.y = 0.0
		if dv.length() < 1.35 and dv.length() > 0.01 and fwd.dot(dv.normalized()) > 0.25:
			o.knock = dv.normalized() * 8.0
			o.stun = 0.3


func _try_sabotage(s: Subject) -> void:
	if not sabotage_enabled or s.sabotage_used or door == null:
		return
	if door.sabotage(s):
		s.sabotage_used = true
		play_sfx("buzzer", -8.0, 1.6)
		announce("ĐỐI TƯỢNG %s CAN THIỆP VÀO MÁY: %s" % [subj_label(s), door.sabotage_hint])
		sabotaged.emit(s, door.sabotage_hint)


func respawn(s: Subject) -> void:
	# đối tượng thay thế được thả xuống từ ống trên trần; xác cũ nằm lại
	var sp := door.spawn_point()
	_place_respawn(s, sp + Vector3(0, 4.0, 0))
	s.pivot.rotation = Vector3(0, randf() * TAU, 0)
	s.brain.target = sp
	respawned.emit(s)


## Máy khách: thả đối tượng thay thế theo vị trí máy chủ gửi xuống.
func respawn_fx(s: Subject, pos: Vector3, yaw: float) -> void:
	_place_respawn(s, pos)
	s.pivot.rotation = Vector3(0, yaw, 0)
	respawned.emit(s)


func _place_respawn(s: Subject, pos: Vector3) -> void:
	var corpse := s.clear_for_respawn(door.keep_corpses)
	if corpse:
		corpses.append(corpse)
		if corpses.size() > 7:
			(corpses.pop_front() as Node3D).queue_free()
	s.position = pos
	s.build_model()
	s.out = 0.0
	s.knock = Vector3.ZERO
	s.vy = 0.0
	s.dead_mode = ""
	s.last_tile = -1
	s.outside_t = 0.0
	s.ground = false
	s.hit_cd = 1.2
	s.set_solid(true)


func _update_subject(s: Subject, dt: float) -> void:
	if s.out > 0.0:
		s.out -= dt
		s.dead_t += dt
		gore.bleed(s)
		if s.out <= 0.0:
			if state == ST_PLAY:
				respawn(s)
			else:
				s.out = 0.01   # hết cửa rồi: nằm lại đó
		return
	var p := s.position
	if state != ST_PLAY:
		# ngoài giờ thi: đứng yên, chỉ rơi xuống đất nếu đang lơ lửng
		var g0 := door.ground_y(p)
		if g0 > -1000.0 and p.y > g0:
			s.vy -= Subject.GRAVITY * dt
			p.y = maxf(g0, p.y + s.vy * dt)
			s.position = p
		s.ground = true
		s.moving = false
		return
	s.shove_cd = maxf(0.0, s.shove_cd - dt)
	s.shove_t = maxf(0.0, s.shove_t - dt)
	var f := seats.source(s.idx).poll(s, self, dt)
	var mv: Vector2 = f.move
	var d := Vector3(mv.x, 0, mv.y)
	if f.jump and s.ground:
		s.vy = Subject.JUMP_V
	if f.shove and s.shove_cd <= 0.0 and s.ground and s.flat <= 0.0:
		_do_shove(s)
	if f.sabotage:
		_try_sabotage(s)
	if s.flat > 0.0:
		s.flat -= dt
		d = Vector3.ZERO
	if s.stun > 0.0:
		s.stun -= dt
		d = Vector3.ZERO
	var kn := s.knock
	var motion := d * s.speed * dt + kn * dt
	s.knock = kn.move_toward(Vector3.ZERO, 16.0 * dt)
	if s.ground:
		motion += door.surface_velocity(s) * dt
	# va chạm ngang với người khác và chướng ngại vật qua physics engine; mặt sàn tính theo cửa
	s.slide(motion)
	p = door.constrain(s, Vector3(s.position.x, p.y, s.position.z))
	var g := door.ground_y(p)
	var vy := s.vy
	vy -= Subject.GRAVITY * dt
	p.y += vy * dt
	if p.y <= g:
		p.y = g
		vy = 0.0
		s.ground = true
	else:
		s.ground = false
	s.vy = vy
	s.position = p
	s.moving = d.length() > 0.1
	if s.moving:
		var face: Vector3 = d if f.face == null else f.face
		s.pivot.rotation.y = lerp_angle(s.pivot.rotation.y, atan2(face.x, face.z), 1.0 - exp(-12.0 * dt))
	door.after_move(s)


func _separate() -> void:
	var sep := door.separation
	for i in subjects.size():
		for j in range(i + 1, subjects.size()):
			var a := subjects[i]
			var c := subjects[j]
			if a.out > 0.0 or c.out > 0.0:
				continue
			if absf(a.position.y - c.position.y) > 0.9:
				continue
			var dv := Vector2(c.position.x - a.position.x, c.position.z - a.position.z)
			var dist := dv.length()
			if dist < sep and dist > 0.001:
				var push := dv / dist * (sep - dist) * 0.5
				a.position -= Vector3(push.x, 0, push.y)
				c.position += Vector3(push.x, 0, push.y)


# ---------- vòng lặp ----------
func step(dt: float) -> void:
	t += dt
	state_t += dt
	for s in subjects:
		s.scared = false
		s.speed = Subject.BASE_SPEED
		s.hit_cd = maxf(0.0, s.hit_cd - dt)
	match state:
		ST_INTRO:
			if state_t >= INTRO_TIME:
				_set_state(ST_PLAY)
				play_sfx("buzzer", -5.0)
		ST_LOBBY:
			for s in subjects:
				s.scared = not seats.is_bot(s.idx)   # người đã vào ghế thì giơ tay
		ST_PLAY:
			lt += dt
			door.tick(dt)
		ST_RESULT, ST_FINAL:
			_run_executions()
	for s in subjects:
		_update_subject(s, dt)
	if state == ST_PLAY:
		_separate()
	gore.update(dt)
	for s in subjects:
		s.animate(t, door.led_alarm(s))
	seats.clear_inputs()
	if state == ST_PLAY and lt >= ROUND_TIME:
		play_sfx("buzzer_end", -4.0)
		_end_round()
	elif state == ST_RESULT and state_t >= RESULT_TIME:
		if door_index >= DOORS - 1:
			_enter_final()
		else:
			load_door(door_index + 1, true)


## Kết thúc cửa đang thi ngay lập tức (phím gỡ lỗi).
func end_round_now() -> void:
	if state == ST_PLAY:
		lt = ROUND_TIME
