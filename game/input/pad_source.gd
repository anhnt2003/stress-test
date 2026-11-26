class_name PadSource
extends InputSource
## Tay cầm: cần trái / D-pad di chuyển, A nhảy, X hoặc B đẩy, Y chơi xấu.

var dev := 0


func _init(d := 0) -> void:
	dev = d


func kind() -> String:
	return "pad"


func device() -> int:
	return dev


func label() -> String:
	return "TAY CẦM %d  (A NHẢY · X ĐẨY · Y CHƠI XẤU)" % (dev + 1)


func raw_move() -> Vector2:
	var d := Vector2.ZERO
	var ax := Vector2(Input.get_joy_axis(dev, JOY_AXIS_LEFT_X), Input.get_joy_axis(dev, JOY_AXIS_LEFT_Y))
	if ax.length() > 0.25:
		d = ax
	if Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_LEFT): d.x -= 1.0
	if Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_RIGHT): d.x += 1.0
	if Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_UP): d.y -= 1.0
	if Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_DOWN): d.y += 1.0
	return d


static func action_for(button: int) -> String:
	match button:
		JOY_BUTTON_A: return "jump"
		JOY_BUTTON_X, JOY_BUTTON_B: return "shove"
		JOY_BUTTON_Y: return "sabotage"
	return ""
