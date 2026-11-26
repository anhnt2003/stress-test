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
