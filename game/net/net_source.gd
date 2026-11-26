class_name NetSource
extends InputSource
## Ghế của người chơi qua mạng: hướng đi và số lần bấm nút do máy khách gửi lên (30 lần/giây).
## Nút bấm gửi dạng bộ đếm tăng dần nên mất gói tin cũng không mất lần bấm.

var peer := 0
var player_name := ""
var move := Vector2.ZERO
var counts := [0, 0, 0]
var last_seen := -1.0


func _init(peer_id := 0, nm := "") -> void:
	peer = peer_id
	player_name = nm


func kind() -> String:
	return "net"


func device() -> int:
	return peer


func label() -> String:
	return "%s  (QUA MẠNG)" % player_name


## Nhận một gói input. Trả về true nếu có lần bấm mới.
func receive(mv: Vector2, c: Array, now: float) -> bool:
	move = mv.limit_length(1.0)
	last_seen = now
	var pressed := false
	var names := ["jump", "shove", "sabotage"]
	for i in 3:
		var nc := int(c[i]) if i < c.size() else 0
		if nc != int(counts[i]):
			if nc > int(counts[i]) or nc < int(counts[i]) - 1000:   # tăng (hoặc quay vòng)
				press(names[i])
				pressed = true
			counts[i] = nc
	return pressed


func poll(_s: Subject, _m: MatchManager, _dt: float) -> Dictionary:
	return {"move": move, "jump": jump_req, "shove": shove_req, "sabotage": sabotage_req, "face": null}
