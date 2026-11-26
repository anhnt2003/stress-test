class_name Seats
extends RefCounted
## 4 ghế: mỗi ghế một nguồn điều khiển (bàn phím 1/2, tay cầm, bot, người chơi mạng) và một bộ trang phục.

const N := 4

var sources: Array[InputSource] = []
var looks: Array[Dictionary] = []
## Tên người chơi mạng (rỗng nếu là người ngồi tại máy hoặc bot).
var names: Array[String] = []


func _init() -> void:
	for i in N:
		sources.append(BotSource.new())
		looks.append(SubjectModel.default_look(i))
		names.append("")


func source(i: int) -> InputSource:
	return sources[i]


func is_bot(i: int) -> bool:
	return sources[i].is_bot()


func seat_of(kind: String, dev := 0) -> int:
	for i in N:
		if sources[i].kind() == kind and sources[i].device() == dev:
			return i
	return -1


func first_bot() -> int:
	for i in N:
		if sources[i].is_bot():
			return i
	return -1


func humans() -> int:
	var n := 0
	for s in sources:
		if not s.is_bot():
			n += 1
	return n


static func make_source(kind: String, dev := 0) -> InputSource:
	match kind:
		"kb1": return KeyboardSource.new(1)
		"kb2": return KeyboardSource.new(2)
		"pad": return PadSource.new(dev)
	return BotSource.new()


## Ở sảnh: bấm để vào ghế trống đầu tiên, bấm lần nữa để rời ghế (bot ngồi thay). Trả về ghế bị đổi, -1 nếu không đổi.
func toggle(kind: String, dev := 0) -> int:
	var i := seat_of(kind, dev)
	if i >= 0:
		sources[i] = BotSource.new()
		names[i] = ""
		return i
	i = first_bot()
	if i < 0:
		return -1
	sources[i] = make_source(kind, dev)
	return i


func assign(i: int, src: InputSource, player_name := "") -> void:
	sources[i] = src
	names[i] = player_name


func release(i: int) -> void:
	sources[i] = BotSource.new()
	names[i] = ""


## Gửi một lần bấm nút tới ghế đang dùng thiết bị này. Trả về ghế nhận, -1 nếu không có.
func press(kind: String, dev: int, action: String) -> int:
	var i := seat_of(kind, dev)
	if i >= 0:
		sources[i].press(action)
	return i


func clear_inputs() -> void:
	for s in sources:
		s.clear()


## Đổi mũ (dh) hoặc màu áo (dc) của ghế i.
func cycle_look(i: int, dh: int, dc: int) -> void:
	var lk := looks[i].duplicate()
	if dh != 0:
		lk.hat = posmod(int(lk.hat) + dh, SubjectModel.HAT_NAMES.size())
	if dc != 0:
		var ci := SubjectModel.COLORS.find(lk.color)
		if ci < 0:
			ci = Palette.SUIT.find(lk.color)
		var n := SubjectModel.COLORS.size()
		var taken: Array = []
		for j in N:
			if j != i:
				taken.append(looks[j].color)
		for _k in n:   # bỏ qua màu ghế khác đang mặc: cửa sơn ô tô theo màu áo, trùng màu thì không phân biệt được
			ci = posmod(ci + signi(dc), n)
			if not taken.has(SubjectModel.COLORS[ci]):
				break
		lk.color = SubjectModel.COLORS[ci]
	looks[i] = lk


func label(i: int) -> String:
	if sources[i].kind() == "remote":
		return sources[i].label()   # máy khách: nhãn do máy chủ gửi (có dấu "← BẠN")
	if names[i] != "":
		return "%s  (QUA MẠNG)" % names[i]
	return sources[i].label()
