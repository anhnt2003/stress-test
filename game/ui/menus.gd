class_name Menus
extends Control
## Chứa các menu: menu chính, tạm dừng, cài đặt, vào phòng.

const MAIN := preload("res://game/ui/main_menu.tscn")
const PAUSE := preload("res://game/ui/pause_menu.tscn")
const SETTINGS := preload("res://game/ui/settings_menu.tscn")
const JOIN := preload("res://game/ui/join_dialog.tscn")

var main_menu: Control
var pause_menu: Control
var settings_menu: Control
var join_dialog: Control


func _ready() -> void:
	size = Vector2(800, 450)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_menu = MAIN.instantiate()
	pause_menu = PAUSE.instantiate()
	settings_menu = SETTINGS.instantiate()
	join_dialog = JOIN.instantiate()
	for c in [main_menu, pause_menu, settings_menu, join_dialog]:
		add_child(c)


## Ẩn các mục không dùng được ở bản này: phòng LAN (trình duyệt không có UDP), phòng online (thiếu máy chủ
## mai mối / WebRTC), nút thoát (trang web không tự đóng được).
func configure(lan: bool, online: bool, quit: bool) -> void:
	var b := main_menu.get_node("Buttons")
	(b.get_node("Host") as Control).visible = lan
	(b.get_node("HostOnline") as Control).visible = online
	(b.get_node("Join") as Control).visible = lan or online
	(b.get_node("Quit") as Control).visible = quit
	(b.get_node("Host") as Button).text = "TẠO PHÒNG LAN" if online else "TẠO PHÒNG QUA MẠNG"
	join_dialog.configure(lan, online)


## Có menu con (cài đặt, vào phòng) đang mở: để GUI tự xử lý phím.
func overlay_open() -> bool:
	return settings_menu.visible or join_dialog.visible


func hide_all() -> void:
	for c in [main_menu, pause_menu, settings_menu, join_dialog]:
		c.visible = false
