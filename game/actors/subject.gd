class_name Subject
extends CharacterBody3D
## Một đối tượng thử nghiệm: trạng thái luật chơi + hình nhân + hoạt ảnh (scene: subject.tscn).
## Nút gốc (CharacterBody3D, capsule) giữ vị trí và va chạm với người khác / chướng ngại vật qua physics engine;
## `pivot` giữ hướng quay, độ nghiêng khi đổ và tỉ lệ của hình nhân. Mặt sàn tính theo từng cửa (DoorBase.ground_y).

const SCALE := 0.86
const GRAVITY := 22.0
const JUMP_V := 7.6
const BASE_SPEED := 3.3
const LAYER_SUBJECT := 1
## Thời điểm (giây sau khi chết) hình nhân đổ xuống thành xác vật lý, theo kiểu chết.
const RAGDOLL_DELAY := {"halved": 0.05, "headpop": 0.55, "fry": 0.6}

var idx := 0
var look := {}
var phase := 0.0
var vy := 0.0
var ground := true
var knock := Vector3.ZERO
var out := 0.0
var flat := 0.0
var deaths := 0
var score := 0
var moving := false
var scared := false
var hit_cd := 0.0
var speed := BASE_SPEED
var dead_mode := ""
var dead_t := 0.0
var last_tile := -1
var outside_t := 0.0
var doom := -1.0
var first_death := 999.0
var stun := 0.0
var shove_cd := 0.0
var shove_t := 0.0
var sabotage_used := false
var brain: BotBrain
## Xác vật lý của lần chết hiện tại (null nếu chưa đổ hoặc kiểu chết không để lại xác).
var ragdoll: Ragdoll
## Máy khách mạng: vị trí được nội suy từ máy chủ, không tự di chuyển.
var puppet := false

var pivot: Node3D
var lower: Node3D
var upper: Node3D
var hips: Array = []
var sh: Array = []
var head: Node3D
var neck: Node3D
var led: StandardMaterial3D
var tag: Label3D


func setup(i: int, pos: Vector3, look_: Dictionary) -> void:
	idx = i
	look = look_
	name = "Subject%d" % (i + 1)
	phase = randf() * TAU
	brain = BotBrain.new(pos)
	position = pos
	build_model()


## Dựng (lại) hình nhân dưới một pivot mới.
func build_model() -> void:
	pivot = Node3D.new()
	pivot.name = "Pivot"
	add_child(pivot)
	pivot.scale = Vector3.ONE * SCALE
	pivot.rotation.y = randf_range(-0.4, 0.4)
	var parts := SubjectModel.build(pivot, look)
	lower = parts.lower
	upper = parts.upper
	hips = parts.hips
	sh = parts.sh
	head = parts.head
	neck = parts.neck
	led = parts.led
	tag = parts.tag


## Dọn hình nhân cũ trước khi thả đối tượng thay thế. Trả về xác để giữ lại (ragdoll), hoặc null.
func clear_for_respawn(keep_corpse: bool) -> Node3D:
	var corpse: Node3D = ragdoll if keep_corpse else null
	if ragdoll and not keep_corpse:
		ragdoll.queue_free()
	ragdoll = null
	var old := pivot
	remove_child(old)
	old.queue_free()
	return corpse


## Bật / tắt va chạm (người chết không chặn đường người khác).
func set_solid(on: bool) -> void:
	collision_layer = LAYER_SUBJECT if on else 0


## Đi theo `motion` (mặt phẳng ngang), trượt dọc theo vật cản. Không dùng move_and_slide vì nó lấy delta
## của khung hình, còn luật chơi chạy với bước thời gian riêng.
func slide(motion: Vector3) -> void:
	var mv := Vector3(motion.x, 0, motion.z)
	for i in 3:
		if mv.length() < 0.0001:
			return
		var col := move_and_collide(mv)
		if col == null:
			return
		var n := col.get_normal()
		n.y = 0.0
		if n.length() < 0.01:
			return
		mv = col.get_remainder().slide(n.normalized())
		mv.y = 0.0


func yaw() -> float:
	return pivot.rotation.y


func forward() -> Vector3:
	return Vector3(sin(pivot.rotation.y), 0, cos(pivot.rotation.y))


func alive() -> bool:
	return out <= 0.0


## Hoạt ảnh giật cục kiểu stop-motion: lượng tử hoá thời gian ở 10 khung/giây.
func animate(t: float, alarm: bool) -> void:
	var tq := floorf(t * 10.0) / 10.0
	var ph := phase
	var hl := 0.0
	var hr := 0.0
	var sl := 0.0
	var sr := 0.0
	var arm_z := 0.0
	if out > 0.0 and ragdoll == null and RAGDOLL_DELAY.has(dead_mode) and dead_t >= float(RAGDOLL_DELAY[dead_mode]) and pivot.visible and is_inside_tree():
		_fall()
	if ragdoll:
		return
	upper.position.x = 0.0
	upper.rotation = Vector3.ZERO
	if out > 0.0:
		var k := clampf(dead_t / 0.5, 0.0, 1.0)
		match dead_mode:
			"halved":
				lower.rotation.x = lerpf(0.0, 1.5, k * k)
			"headpop":
				var kk := clampf((dead_t - 0.5) / 0.6, 0.0, 1.0)
				pivot.rotation.x = lerpf(0.0, -1.5, kk * kk)
				sl = -0.3
				sr = 0.3
			"fry":
				var kf := clampf((dead_t - 0.6) / 0.6, 0.0, 1.0)
				pivot.rotation.x = lerpf(0.0, -1.5, kf * kf)
				if dead_t < 0.6:   # giật cứng người trước khi đổ
					sl = -2.2 + (Build.hash1(tq * 31.0) - 0.5) * 1.2
					sr = -2.2 + (Build.hash1(tq * 37.0) - 0.5) * 1.2
					upper.position.x = (Build.hash1(tq * 41.0) - 0.5) * 0.08
	elif not ground:
		sl = -2.8
		sr = -2.6
		hl = 0.4
		hr = -0.3
	elif moving:
		var sw := sin(tq * 11.0 + ph) * 0.75
		hl = sw
		hr = -sw
		sl = -sw * 0.7
		sr = sw * 0.7
		upper.rotation.x = 0.16
	if out <= 0.0 and shove_t > 0.0:
		sl = -1.5
		sr = -1.5
	elif out <= 0.0 and scared:
		sl = -2.75 + (Build.hash1(tq * 7.0 + ph) - 0.5) * 0.3
		sr = -2.75 + (Build.hash1(tq * 9.0 + ph) - 0.5) * 0.3
		arm_z = 0.25
		upper.position.x = (Build.hash1(tq * 13.0 + ph) - 0.5) * 0.04
	(hips[0] as Node3D).rotation.x = hl
	(hips[1] as Node3D).rotation.x = hr
	(sh[0] as Node3D).rotation = Vector3(sl, 0, arm_z)
	(sh[1] as Node3D).rotation = Vector3(sr, 0, -arm_z)
	# đầu thỉnh thoảng giật
	var hq := floorf(t * 2.5 + ph)
	head.rotation.z = (Build.hash1(hq + ph) - 0.5) * 0.35 if Build.hash1(hq * 3.1) > 0.55 else 0.0
	head.rotation.y = (Build.hash1(hq * 1.7 + ph) - 0.5) * 0.9
	var fast := scared or doom > 0.0 or alarm
	led.emission_energy_multiplier = (6.0 if sin(t * 30.0) > 0.0 else 0.3) if fast else (4.0 if fmod(t + ph, 1.6) < 1.3 else 0.5)


## Đổ xuống thành xác vật lý.
func _fall() -> void:
	var push := -forward() * 1.2 + Vector3(0, 0.3, 0)
	if dead_mode == "halved":
		push = forward() * 0.6
	ragdoll = Ragdoll.from_subject(self, get_parent() as Node3D, push)
