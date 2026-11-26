class_name KeyboardSource
extends InputSource
## Bàn phím 1 (WASD · Space · F · G) hoặc bàn phím 2 (mũi tên · . · / · ,).

const SCHEMES := {
	1: {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S, "jump": KEY_SPACE, "shove": KEY_F, "sabotage": KEY_G},
	2: {"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN, "jump": KEY_PERIOD, "shove": KEY_SLASH, "sabotage": KEY_COMMA},
}

var scheme := 1


func _init(s := 1) -> void:
	scheme = s


func kind() -> String:
	return "kb%d" % scheme


func label() -> String:
	return "BÀN PHÍM 1  (WASD · SPACE · F · G)" if scheme == 1 else "BÀN PHÍM 2  (MŨI TÊN · . · / · ,)"


func raw_move() -> Vector2:
	var k: Dictionary = SCHEMES[scheme]
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(k.left) or Input.is_key_pressed(k.left): d.x -= 1.0
	if Input.is_physical_key_pressed(k.right) or Input.is_key_pressed(k.right): d.x += 1.0
	if Input.is_physical_key_pressed(k.up) or Input.is_key_pressed(k.up): d.y -= 1.0
	if Input.is_physical_key_pressed(k.down) or Input.is_key_pressed(k.down): d.y += 1.0
	return d


## Phím `keycode` ứng với hành động nào của sơ đồ này ("" nếu không ứng).
static func action_for(sch: int, keycode: int) -> String:
	var k: Dictionary = SCHEMES[sch]
	for a in ["jump", "shove", "sabotage"]:
		if k[a] == keycode:
			return a
	return ""
