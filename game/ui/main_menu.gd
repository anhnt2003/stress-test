extends Control
## Menu chính.

signal chosen(action: String)


func _ready() -> void:
	for b in $Buttons.get_children():
		(b as Button).pressed.connect(func(): chosen.emit(String(b.name)))


func open() -> void:
	visible = true
	($Buttons.get_child(0) as Button).grab_focus()
