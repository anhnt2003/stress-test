class_name InputRouter
extends Node
## Nhận phím / nút tay cầm và chuyển thành hành động theo màn hình đang mở.
## Trong trận: chuyển nút nhảy / đẩy / chơi xấu tới ghế đang dùng thiết bị đó.

signal pause_pressed
signal start_pressed
signal back_pressed
signal restart_pressed
signal seat_toggled(kind: String, dev: int)
signal look_cycled(kind: String, dev: int, dh: int, dc: int)
signal sabotage_toggled
signal debug_door(i: int)
signal debug_end_round
## Thiết bị điều khiển của máy khách mạng vừa bấm (để gửi lên máy chủ).
signal local_action(kind: String, dev: int, action: String)

## "menu", "lobby", "match", "pause", "final", "overlay" (menu con đang mở, để GUI tự xử lý)
var screen := "menu"
var seats: Seats
## Phím gỡ lỗi F1–F10 / F12: chỉ bật khi chạy từ editor / bản debug, hoặc với --debug-keys.
var debug_keys := OS.is_debug_build()
var _stick := {}


func _unhandled_input(e: InputEvent) -> void:
	if screen == "overlay":
		return
	if e is InputEventKey and e.pressed and not e.echo:
		_key(e.keycode)
	elif e is InputEventJoypadButton and e.pressed:
		_pad(e.device, e.button_index)
	elif e is InputEventJoypadMotion and screen == "lobby":
		_stick_motion(e)


func _key(k: int) -> void:
	match screen:
		"lobby":
			match k:
				KEY_ESCAPE: back_pressed.emit()
				KEY_ENTER, KEY_KP_ENTER: start_pressed.emit()
				KEY_TAB: sabotage_toggled.emit()
				KEY_SPACE: seat_toggled.emit("kb1", 0)
				KEY_PERIOD: seat_toggled.emit("kb2", 0)
				KEY_A: look_cycled.emit("kb1", 0, -1, 0)
				KEY_D: look_cycled.emit("kb1", 0, 1, 0)
				KEY_W: look_cycled.emit("kb1", 0, 0, -1)
				KEY_S: look_cycled.emit("kb1", 0, 0, 1)
				KEY_LEFT: look_cycled.emit("kb2", 0, -1, 0)
				KEY_RIGHT: look_cycled.emit("kb2", 0, 1, 0)
				KEY_UP: look_cycled.emit("kb2", 0, 0, -1)
				KEY_DOWN: look_cycled.emit("kb2", 0, 0, 1)
		"pause":
			match k:
				KEY_ESCAPE: pause_pressed.emit()
				KEY_Q: back_pressed.emit()
				KEY_R: restart_pressed.emit()
		"final":
			match k:
				KEY_ENTER, KEY_KP_ENTER: start_pressed.emit()
				KEY_ESCAPE: back_pressed.emit()
		"match":
			if k == KEY_ESCAPE:
				pause_pressed.emit()
				return
			for sch in [1, 2]:
				var act := KeyboardSource.action_for(sch, k)
				if act != "":
					_action("kb%d" % sch, 0, act)
			if debug_keys:
				if k == KEY_F12:
					debug_end_round.emit()
				elif k >= KEY_F1 and k <= KEY_F10:
					debug_door.emit(k - KEY_F1)
		"menu":
			if k == KEY_ESCAPE:
				back_pressed.emit()


func _pad(dev: int, btn: int) -> void:
	match screen:
		"lobby":
			match btn:
				JOY_BUTTON_START: start_pressed.emit()
				JOY_BUTTON_BACK: back_pressed.emit()
				JOY_BUTTON_A: seat_toggled.emit("pad", dev)
				JOY_BUTTON_Y: sabotage_toggled.emit()
				JOY_BUTTON_DPAD_LEFT: look_cycled.emit("pad", dev, -1, 0)
				JOY_BUTTON_DPAD_RIGHT: look_cycled.emit("pad", dev, 1, 0)
				JOY_BUTTON_DPAD_UP: look_cycled.emit("pad", dev, 0, -1)
				JOY_BUTTON_DPAD_DOWN: look_cycled.emit("pad", dev, 0, 1)
		"pause":
			match btn:
				JOY_BUTTON_START: pause_pressed.emit()
				JOY_BUTTON_BACK: back_pressed.emit()
		"final":
			match btn:
				JOY_BUTTON_START, JOY_BUTTON_A: start_pressed.emit()
				JOY_BUTTON_BACK, JOY_BUTTON_B: back_pressed.emit()
		"match":
			if btn == JOY_BUTTON_START:
				pause_pressed.emit()
				return
			var act := PadSource.action_for(btn)
			if act != "":
				_action("pad", dev, act)


func _action(kind: String, dev: int, act: String) -> void:
	if seats:
		seats.press(kind, dev, act)
	local_action.emit(kind, dev, act)


## Ở sảnh: gạt cần trái để đổi mũ / màu áo (chỉ tính lần gạt qua ngưỡng).
func _stick_motion(e: InputEventJoypadMotion) -> void:
	if e.axis != JOY_AXIS_LEFT_X and e.axis != JOY_AXIS_LEFT_Y:
		return
	var key := "%d:%d" % [e.device, e.axis]
	var was: int = _stick.get(key, 0)
	var now := 1 if e.axis_value > 0.6 else (-1 if e.axis_value < -0.6 else 0)
	if absf(e.axis_value) < 0.3:
		now = 0
	elif now == 0:
		now = was
	_stick[key] = now
	if now != 0 and was == 0:
		if e.axis == JOY_AXIS_LEFT_X:
			look_cycled.emit("pad", e.device, now, 0)
		else:
			look_cycled.emit("pad", e.device, 0, now)
