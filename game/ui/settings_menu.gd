extends Control
## Màn cài đặt: âm lượng, độ phân giải, toàn màn hình, máu me, giọng đọc, lời bình LLM.

signal changed
signal closed

var s: Settings
var _loading := false


func _ready() -> void:
	for nm in ["Master", "Music", "Sfx", "Voice", "Shake"]:
		(get_node(nm) as HSlider).value_changed.connect(func(_v): _store())
	for nm in ["Fullscreen", "Gore", "Tts", "Llm"]:
		(get_node(nm) as CheckButton).toggled.connect(func(_on): _store())
	($Resolution as OptionButton).item_selected.connect(func(_i): _store())
	($Back as Button).pressed.connect(close)


func open(settings: Settings, llm_available: bool, tts_available: bool) -> void:
	s = settings
	_loading = true
	($Master as HSlider).value = s.master
	($Music as HSlider).value = s.music
	($Sfx as HSlider).value = s.sfx
	($Voice as HSlider).value = s.voice
	($Shake as HSlider).value = s.shake
	($Resolution as OptionButton).select(s.resolution)
	($Fullscreen as CheckButton).button_pressed = s.fullscreen
	($Gore as CheckButton).button_pressed = s.gore
	($Tts as CheckButton).button_pressed = s.tts
	($Llm as CheckButton).button_pressed = s.llm
	($Llm as CheckButton).disabled = not llm_available
	var notes := []
	if not llm_available:
		notes.append("LỜI BÌNH CLAUDE: CHƯA CÓ BIẾN MÔI TRƯỜNG ANTHROPIC_API_KEY.")
	if not tts_available:
		notes.append("MÁY NÀY KHÔNG CÓ GIỌNG TIẾNG VIỆT: CỖ MÁY SẼ PHÁT TIẾNG BÍP.")
	($Note as Label).text = "\n".join(notes)
	_loading = false
	visible = true
	($Master as HSlider).grab_focus()


func _store() -> void:
	if _loading or s == null:
		return
	s.master = ($Master as HSlider).value
	s.music = ($Music as HSlider).value
	s.sfx = ($Sfx as HSlider).value
	s.voice = ($Voice as HSlider).value
	s.shake = ($Shake as HSlider).value
	s.resolution = ($Resolution as OptionButton).selected
	s.fullscreen = ($Fullscreen as CheckButton).button_pressed
	s.gore = ($Gore as CheckButton).button_pressed
	s.tts = ($Tts as CheckButton).button_pressed
	s.llm = ($Llm as CheckButton).button_pressed
	changed.emit()


func close() -> void:
	if s:
		s.save()
	visible = false
	closed.emit()


func _unhandled_input(e: InputEvent) -> void:
	if visible and (e.is_action_pressed("ui_cancel") or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B)):
		get_viewport().set_input_as_handled()
		close()
