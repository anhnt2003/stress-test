extends Control
## Hộp thoại vào phòng: nhập mã phòng (hoặc IP) và tên.

signal connect_requested(address: String, player_name: String)
signal closed


func _ready() -> void:
	($Connect as Button).pressed.connect(_go)
	($Back as Button).pressed.connect(close)
	($Code as LineEdit).text_submitted.connect(func(_t): _go())
	($Name as LineEdit).text_submitted.connect(func(_t): _go())


func open(last_code: String, player_name: String) -> void:
	($Code as LineEdit).text = last_code
	($Name as LineEdit).text = player_name
	set_status("")
	visible = true
	($Code as LineEdit).grab_focus()


## Chữ hướng dẫn theo cách vào phòng bản này hỗ trợ (online 6 ký tự / LAN).
func configure(lan: bool, online: bool) -> void:
	if online and not lan:
		($LCode as Label).text = "MÃ PHÒNG (6 KÝ TỰ)"
		($Help as Label).text = "MÃ PHÒNG HIỆN Ở SẢNH CỦA CHỦ PHÒNG. CHỦ PHÒNG CẦN GIỮ TAB GAME MỞ TRONG LÚC CHƠI."
	elif online:
		($LCode as Label).text = "MÃ PHÒNG ONLINE / LAN HOẶC IP[:CỔNG]"
		($Help as Label).text = "MÃ ONLINE (6 KÝ TỰ) VÀO ĐƯỢC TỪ MỌI MẠNG. MÃ LAN / IP CHỈ TRONG CÙNG MẠNG (HOẶC MỞ CỔNG UDP 24555)."
	else:
		($LCode as Label).text = "MÃ PHÒNG HOẶC IP[:CỔNG]"
		($Help as Label).text = "MÃ PHÒNG HIỆN Ở SẢNH CỦA MÁY CHỦ. CHƠI KHÁC MẠNG CẦN MỞ CỔNG UDP 24555 HOẶC DÙNG VPN LAN (TAILSCALE, ZEROTIER)."


func set_status(text: String) -> void:
	($Status as Label).text = text


func _go() -> void:
	var code := ($Code as LineEdit).text.strip_edges()
	if code == "":
		set_status("NHẬP MÃ PHÒNG HOẶC ĐỊA CHỈ IP.")
		return
	connect_requested.emit(code, ($Name as LineEdit).text.strip_edges())


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
