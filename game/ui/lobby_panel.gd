extends Panel
## Sảnh chờ: mỗi ghế hiện thiết bị điều khiển, mũ và màu áo.


func refresh(m: MatchManager, room_text := "") -> void:
	for r in Seats.N:
		var row := get_node("Row%d" % r)
		var lk: Dictionary = m.seats.looks[r]
		var human := not m.seats.is_bot(r)
		(row.get_node("Chip") as ColorRect).color = (lk.color as Color).lightened(0.15)
		var dev := row.get_node("Device") as Label
		dev.text = m.seats.label(r)
		dev.add_theme_color_override("font_color", Palette.AMBER if human else Palette.DIM)
		(row.get_node("Hat") as Label).text = "MŨ: " + String(SubjectModel.HAT_NAMES[int(lk.hat)])
		var ci := SubjectModel.COLORS.find(lk.color)
		(row.get_node("Color") as Label).text = "ÁO: " + (String(SubjectModel.COLOR_NAMES[ci]) if ci >= 0 else "?")
	if room_text != "":
		($Room as Label).text = room_text
	($Options as Label).text = "TAB: CHƠI XẤU %s   ·   GHẾ TRỐNG DO BOT NGỒI" % ("BẬT" if m.sabotage_enabled else "TẮT")


func set_room(text: String) -> void:
	($Room as Label).text = text
