extends Control
## Menu tạm dừng.

signal chosen(action: String)


func _ready() -> void:
	for b in $Buttons.get_children():
		(b as Button).pressed.connect(func(): chosen.emit(String(b.name)))


func open(online_client := false) -> void:
	visible = true
	# máy khách mạng không được chơi lại / dừng trận của máy chủ
	($Buttons/Restart as Button).visible = not online_client
	($Buttons/Lobby as Button).visible = not online_client
	($Foot as Label).text = "ESC / START: CHƠI TIẾP   ·   Q: RỜI PHÒNG (TRẬN CỦA MÁY CHỦ VẪN CHẠY)" if online_client \
		else "ESC / START: CHƠI TIẾP   ·   R: CHƠI LẠI   ·   Q: VỀ SẢNH"
	($Buttons/Resume as Button).grab_focus()
