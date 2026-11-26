class_name InputSource
extends RefCounted
## Nguồn điều khiển của một ghế. Nhân vật chỉ nhận một khung input (move, jump, shove, sabotage),
## không biết nguồn là bàn phím, tay cầm, bot hay người chơi qua mạng.

var jump_req := false
var shove_req := false
var sabotage_req := false
## Hướng xoay của camera quanh trục đứng, để đổi hướng cần/phím sang hướng trên màn hình.
static var cam_yaw := 0.0


## "kb1", "kb2", "pad", "bot", "net"
func kind() -> String:
	return "bot"


func device() -> int:
	return 0


func is_bot() -> bool:
	return false


## Tên hiển thị ở sảnh.
func label() -> String:
	return "MÁY ĐIỀU KHIỂN"


## Hướng di chuyển thô trong mặt phẳng màn hình (x sang phải, y xuống dưới), độ dài tối đa 1.
func raw_move() -> Vector2:
	return Vector2.ZERO


## Đọc một khung input cho đối tượng `s`. Kết quả: {"move": Vector2 (toạ độ thế giới x,z),
## "jump": bool, "shove": bool, "sabotage": bool, "face": Vector3 hoặc null}.
func poll(_s: Subject, _m: MatchManager, _dt: float) -> Dictionary:
	var mv := raw_move().limit_length(1.0)
	var w := Vector3(mv.x, 0, mv.y).rotated(Vector3.UP, cam_yaw)
	return {"move": Vector2(w.x, w.z), "jump": jump_req, "shove": shove_req, "sabotage": sabotage_req, "face": null}


func press(action: String) -> void:
	match action:
		"jump": jump_req = true
		"shove": shove_req = true
		"sabotage": sabotage_req = true


func clear() -> void:
	jump_req = false
	shove_req = false
	sabotage_req = false
