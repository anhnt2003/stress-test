extends Control
## Chữ lớn giữa màn hình: tên cửa khi giới thiệu, tên game ở sảnh.

@onready var big: Label = $Big
@onready var small: Label = $Small


func show_text(title: String, sub: String, top := false) -> void:
	big.text = title
	small.text = sub
	big.position.y = 44.0 if top else 150.0
	small.position.y = 118.0 if top else 228.0
	visible = true
