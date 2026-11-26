class_name BotBrain
extends RefCounted
## Trí khôn của bot, tách khỏi nhân vật. Phần chung (chọn đích, đi tới đích, có nên đẩy không) nằm ở đây;
## kiến thức riêng từng cửa (né máy ép, nhảy lưỡi cưa...) nằm ở hàm `bot_steer` của cửa đó.

var target := Vector3.ZERO
var ai_t := 0.0
var flee := true
var decided := false
var react := 0.0
var home_x := -1.5
var lane_z := 0.0
var off := Vector2.ZERO
var want_jump := false


func _init(spawn: Vector3) -> void:
	target = spawn
	lane_z = spawn.z


func set_target(q: Vector2, hold: float) -> void:
	target = Vector3(q.x, 0, q.y)
	ai_t = hold


## Hướng đi (toạ độ thế giới) cho đối tượng `s` trong cửa `door`.
func steer(s: Subject, door: DoorBase, dt: float) -> Vector3:
	var p := s.position
	ai_t -= dt
	var tgt := target
	var arrived := Vector2(tgt.x - p.x, tgt.z - p.z).length() < 0.2
	var retarget := arrived or ai_t <= 0.0
	var override = door.bot_steer(s, self, dt, arrived, retarget)
	if override is Vector3:
		return override
	tgt = target
	var d := Vector3(tgt.x - p.x, 0, tgt.z - p.z)
	return d.normalized() if d.length() > 0.2 else Vector3.ZERO


## Đẩy người đứng ngay trước mặt, xác suất theo thời gian.
func wants_shove(s: Subject, subjects: Array, dt: float) -> bool:
	if s.shove_cd > 0.0:
		return false
	var fwd := s.forward()
	for o: Subject in subjects:
		if o.idx == s.idx or o.out > 0.0:
			continue
		var dv := o.position - s.position
		dv.y = 0.0
		if dv.length() < 1.1 and dv.length() > 0.01 and fwd.dot(dv.normalized()) > 0.4:
			return randf() < 0.9 * dt
	return false
