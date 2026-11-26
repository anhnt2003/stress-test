class_name UIBuilder
## Dựng các scene giao diện bằng code. Chỉ dùng trong `tools/migrate_scenes.gd` để sinh file .tscn;
## lúc chạy game, giao diện được nạp từ .tscn.


static func label(parent: Node, nm: String, text: String, size: int, color: Color, pos: Vector2, outline_px := 4) -> Label:
	var l := Label.new()
	l.name = nm
	l.text = text
	l.add_theme_font_override("font", Build.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", outline_px)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


static func centered(l: Label, width: float, height: float) -> Label:
	l.size = Vector2(width, height)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func box_style(bg: Color, border: Color, width := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	return sb


static func panel(parent: Node, nm: String, pos: Vector2, size: Vector2, sb: StyleBox) -> Panel:
	var p := Panel.new()
	p.name = nm
	p.add_theme_stylebox_override("panel", sb)
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent:
		parent.add_child(p)
	return p


static func rect(parent: Node, nm: String, color: Color, pos: Vector2, size: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.name = nm
	r.color = color
	r.position = pos
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


static func button(parent: Node, nm: String, text: String, pos: Vector2, size: Vector2, font_size := 18) -> Button:
	var b := Button.new()
	b.name = nm
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_override("font", Build.font())
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Palette.PAPER)
	b.add_theme_color_override("font_focus_color", Palette.AMBER)
	b.add_theme_color_override("font_hover_color", Palette.AMBER)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.add_theme_stylebox_override("normal", box_style(Color(0, 0, 0, 0.75), Color(0.35, 0.33, 0.28)))
	b.add_theme_stylebox_override("hover", box_style(Color(0.12, 0.07, 0.02, 0.9), Palette.AMBER))
	b.add_theme_stylebox_override("focus", box_style(Color(0.16, 0.09, 0.02, 0.9), Palette.AMBER, 2))
	b.add_theme_stylebox_override("pressed", box_style(Color(0.3, 0.15, 0.03, 0.95), Palette.AMBER, 2))
	parent.add_child(b)
	return b


static func _with_script(n: Node, path: String) -> Node:
	n.set_script(load(path))
	return n


# ---------- HUD trong trận ----------
static func hud() -> CanvasLayer:
	var ui := CanvasLayer.new()
	ui.name = "HUD"
	ui.layer = 2
	_with_script(ui, "res://game/ui/hud.gd")
	label(ui, "Title", "", 17, Palette.AMBER, Vector2(14, 6))
	label(ui, "Rule", "", 12, Color(0.80, 0.78, 0.70, 0.8), Vector2(14, 30), 3)
	label(ui, "SabHint", "", 10, Color(0.85, 0.45, 0.25, 0.85), Vector2(14, 47), 3)
	label(ui, "EscHint", "ESC: TẠM DỪNG", 10, Color(0.80, 0.78, 0.70, 0.45), Vector2(716, 8), 3)
	label(ui, "Timer", "0:30", 28, Palette.AMBER, Vector2(372, 2), 6)
	label(ui, "NetInfo", "", 10, Color(0.6, 0.85, 0.6, 0.7), Vector2(14, 432), 3)
	var sbp := box_style(Color(0.0, 0.0, 0.0, 0.85), Color(0.75, 0.08, 0.05))
	sbp.border_width_left = 5
	var sub_panel := panel(ui, "SubPanel", Vector2(150, 368), Vector2(500, 25), sbp)
	label(sub_panel, "Sub", "", 14, Palette.AMBER, Vector2(12, 1), 0)
	sub_panel.visible = false
	# thẻ đối tượng: trạng thái, tổng điểm, số lần chết trong cửa này
	var cards := Control.new()
	cards.name = "Cards"
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(cards)
	for i in 4:
		var card := panel(cards, "Card%d" % i, Vector2(140 + i * 132, 402), Vector2(124, 42), box_style(Color(0.0, 0.0, 0.0, 0.8), Color(0.35, 0.33, 0.28)))
		rect(card, "Chip", Palette.SUIT[i].lightened(0.15), Vector2.ZERO, Vector2(6, 42))
		label(card, "Name", "ĐT-%s" % Palette.SUBJ[i], 13, Palette.PAPER, Vector2(13, 1), 0)
		label(card, "Val", "", 13, Palette.AMBER, Vector2(84, 1), 0)
		label(card, "Pts", "", 13, Palette.PAPER, Vector2(13, 21), 0)
		label(card, "Dth", "", 13, Color(0.9, 0.3, 0.25), Vector2(70, 21), 0)
		var sab := rect(card, "Sab", Color(0.85, 0.45, 0.25), Vector2(116, 4), Vector2(4, 4))
		sab.visible = false
	var stamp := Label.new()
	stamp.name = "Stamp"
	stamp.text = "ĐÃ LOẠI BỎ"
	stamp.add_theme_font_override("font", Build.font())
	stamp.add_theme_font_size_override("font_size", 44)
	stamp.add_theme_color_override("font_color", Color(0.85, 0.06, 0.04))
	var sbs := box_style(Color(0.6, 0.0, 0.0, 0.10), Color(0.85, 0.06, 0.04), 5)
	sbs.content_margin_left = 16
	sbs.content_margin_right = 16
	sbs.content_margin_bottom = 2
	stamp.add_theme_stylebox_override("normal", sbs)
	ui.add_child(stamp)
	stamp.position = Vector2(24, 150)
	stamp.rotation = -0.12
	stamp.visible = false
	return ui


# ---------- chữ giới thiệu cửa ----------
static func intro_banner() -> Control:
	var c := Control.new()
	c.name = "IntroBanner"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = Vector2(800, 450)
	_with_script(c, "res://game/ui/intro_banner.gd")
	centered(label(c, "Big", "", 54, Palette.AMBER, Vector2(0, 150), 10), 800, 70)
	centered(label(c, "Small", "", 16, Palette.PAPER, Vector2(0, 228), 6), 800, 24)
	c.visible = false
	return c


# ---------- bảng chấm điểm sau mỗi cửa và bảng tổng kết ----------
static func result_panel() -> Panel:
	var p := panel(null, "ResultPanel", Vector2(150, 70), Vector2(500, 262), box_style(Color(0.02, 0.02, 0.015, 0.93), Palette.AMBER, 2))
	_with_script(p, "res://game/ui/result_panel.gd")
	centered(label(p, "Title", "", 24, Palette.AMBER, Vector2(0, 8), 0), 500, 32)
	rect(p, "Line", Color(1.0, 0.62, 0.15, 0.6), Vector2(20, 46), Vector2(460, 2))
	for r in 4:
		var y := 58.0 + r * 42.0
		var row := Control.new()
		row.name = "Row%d" % r
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.position = Vector2(0, y)
		p.add_child(row)
		rect(row, "Chip", Color.WHITE, Vector2(20, 4), Vector2(8, 28))
		label(row, "Rank", "", 24, Palette.AMBER, Vector2(38, 0), 0)
		label(row, "Name", "", 22, Palette.PAPER, Vector2(86, 1), 0)
		label(row, "Detail", "", 15, Color(0.75, 0.72, 0.62), Vector2(176, 8), 0)
		label(row, "Pts", "", 22, Palette.AMBER, Vector2(300, 1), 0)
		label(row, "Total", "", 18, Palette.PAPER, Vector2(372, 5), 0)
	centered(label(p, "Foot", "", 13, Color(0.80, 0.78, 0.70, 0.75), Vector2(0, 234), 0), 500, 20)
	p.visible = false
	return p


# ---------- sảnh chờ: 4 ghế, thiết bị, mũ, màu áo ----------
static func lobby_panel() -> Panel:
	var p := panel(null, "LobbyPanel", Vector2(90, 212), Vector2(620, 196), box_style(Color(0.02, 0.02, 0.015, 0.88), Palette.AMBER, 2))
	_with_script(p, "res://game/ui/lobby_panel.gd")
	for r in 4:
		var row := Control.new()
		row.name = "Row%d" % r
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.position = Vector2(0, 8 + r * 27)
		p.add_child(row)
		rect(row, "Chip", Palette.SUIT[r].lightened(0.15), Vector2(14, 3), Vector2(8, 22))
		label(row, "Name", "ĐT-%s" % Palette.SUBJ[r], 17, Palette.PAPER, Vector2(30, -1), 0)
		label(row, "Device", "", 13, Palette.AMBER, Vector2(98, 3), 0)
		label(row, "Hat", "", 13, Palette.PAPER, Vector2(370, 3), 0)
		label(row, "Color", "", 13, Palette.PAPER, Vector2(494, 3), 0)
	centered(label(p, "Room", "", 13, Color(0.6, 0.9, 0.6), Vector2(0, 118), 0), 620, 16)
	centered(label(p, "Hint", "VÀO / RỜI GHẾ: SPACE · DẤU CHẤM · NÚT A     ĐỔI MŨ: TRÁI / PHẢI     ĐỔI MÀU ÁO: LÊN / XUỐNG", 11, Color(0.80, 0.78, 0.70, 0.8), Vector2(0, 138), 0), 620, 16)
	centered(label(p, "Options", "", 12, Color(0.85, 0.55, 0.3), Vector2(0, 155), 0), 620, 16)
	centered(label(p, "Start", "ENTER / START: BẮT ĐẦU      ESC: MENU CHÍNH", 14, Palette.AMBER, Vector2(0, 172), 0), 620, 20)
	p.visible = false
	return p


# ---------- menu dùng chung: tiêu đề + cột nút ----------
static func menu(nm: String, script_path: String, head: String, buttons: Array, top := 120.0) -> Control:
	var c := Control.new()
	c.name = nm
	c.size = Vector2(800, 450)
	_with_script(c, script_path)
	var dim := rect(c, "Dim", Color(0, 0, 0, 0.55), Vector2.ZERO, Vector2(800, 450))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	centered(label(c, "Head", head, 40, Palette.AMBER, Vector2(0, top - 78), 8), 800, 56)
	var col := VBoxContainer.new()
	col.name = "Buttons"
	col.position = Vector2(250, top)
	col.size = Vector2(300, buttons.size() * 40)
	col.add_theme_constant_override("separation", 8)
	c.add_child(col)
	for b in buttons:
		var btn := button(col, String(b[0]), String(b[1]), Vector2.ZERO, Vector2(300, 32))
		btn.custom_minimum_size = Vector2(300, 32)
	centered(label(c, "Foot", "", 11, Color(0.80, 0.78, 0.70, 0.6), Vector2(0, 420), 0), 800, 16)
	c.visible = false
	return c


static func main_menu() -> Control:
	var c := menu("MainMenu", "res://game/ui/main_menu.gd", "STRESS TEST", [
		["Local", "CHƠI CHUNG MỘT MÁY"], ["Host", "TẠO PHÒNG QUA MẠNG"], ["Join", "VÀO PHÒNG QUA MẠNG"],
		["Settings", "CÀI ĐẶT"], ["Quit", "THOÁT"]], 170.0)
	(c.get_node("Foot") as Label).text = "MŨI TÊN / D-PAD: CHỌN   ·   ENTER / A: XÁC NHẬN"
	centered(label(c, "Tag", "BẢN THỬ NGHIỆM 10 CỬA  ·  3–4 ĐỐI TƯỢNG  ·  CÓ CẢNH MÁU ME (TẮT ĐƯỢC TRONG CÀI ĐẶT)", 12, Palette.PAPER, Vector2(0, 140), 3), 800, 18)
	return c


static func pause_menu() -> Control:
	var c := menu("PauseMenu", "res://game/ui/pause_menu.gd", "TẠM DỪNG", [
		["Resume", "CHƠI TIẾP"], ["Restart", "CHƠI LẠI TỪ CỬA 1"], ["Settings", "CÀI ĐẶT"],
		["Lobby", "VỀ SẢNH"], ["MainMenu", "VỀ MENU CHÍNH"]], 150.0)
	(c.get_node("Foot") as Label).text = "ESC / START: CHƠI TIẾP   ·   R: CHƠI LẠI   ·   Q: VỀ SẢNH"
	return c


static func _row_label(parent: Node, text: String, y: float) -> void:
	label(parent, "L_" + text.replace(" ", "_"), text, 15, Palette.PAPER, Vector2(170, y + 2), 3)


static func _slider(parent: Node, nm: String, text: String, y: float) -> HSlider:
	_row_label(parent, text, y)
	var s := HSlider.new()
	s.name = nm
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.position = Vector2(400, y + 6)
	s.size = Vector2(230, 16)
	s.focus_mode = Control.FOCUS_ALL
	s.add_theme_stylebox_override("slider", box_style(Color(0.1, 0.09, 0.07), Color(0.35, 0.33, 0.28)))
	s.add_theme_stylebox_override("grabber_area", box_style(Color(0.6, 0.35, 0.08), Color(0.6, 0.35, 0.08)))
	s.add_theme_stylebox_override("grabber_area_highlight", box_style(Palette.AMBER, Palette.AMBER))
	parent.add_child(s)
	return s


static func _check(parent: Node, nm: String, text: String, y: float) -> CheckButton:
	_row_label(parent, text, y)
	var b := CheckButton.new()
	b.name = nm
	b.position = Vector2(560, y - 2)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("focus", box_style(Color(0, 0, 0, 0), Palette.AMBER, 2))
	parent.add_child(b)
	return b


static func settings_menu() -> Control:
	var c := Control.new()
	c.name = "SettingsMenu"
	c.size = Vector2(800, 450)
	_with_script(c, "res://game/ui/settings_menu.gd")
	var dim := rect(c, "Dim", Color(0, 0, 0, 0.8), Vector2.ZERO, Vector2(800, 450))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	centered(label(c, "Head", "CÀI ĐẶT", 34, Palette.AMBER, Vector2(0, 14), 8), 800, 46)
	var y := 70.0
	for e in [["Master", "ÂM LƯỢNG CHUNG"], ["Music", "NHẠC NỀN"], ["Sfx", "HIỆU ỨNG"], ["Voice", "GIỌNG CỖ MÁY"], ["Shake", "RUNG CAMERA"]]:
		_slider(c, String(e[0]), String(e[1]), y)
		y += 27.0
	_row_label(c, "ĐỘ PHÂN GIẢI", y)
	var res := OptionButton.new()
	res.name = "Resolution"
	res.position = Vector2(400, y)
	res.size = Vector2(230, 24)
	res.add_theme_font_override("font", Build.font())
	res.add_theme_font_size_override("font_size", 14)
	for r in Settings.RESOLUTIONS:
		res.add_item("%d × %d" % [r.x, r.y])
	c.add_child(res)
	y += 29.0
	for e in [["Fullscreen", "TOÀN MÀN HÌNH"], ["Gore", "MÁU ME"], ["Tts", "ĐỌC LỜI CỖ MÁY (GIỌNG HỆ ĐIỀU HÀNH)"], ["Llm", "LỜI BÌNH TỪ CLAUDE (CẦN ANTHROPIC_API_KEY)"]]:
		_check(c, String(e[0]), String(e[1]), y)
		y += 28.0
	label(c, "Note", "", 11, Color(0.8, 0.6, 0.4), Vector2(170, y + 2), 3)
	button(c, "Back", "LƯU VÀ QUAY LẠI", Vector2(300, 404), Vector2(200, 32))
	c.visible = false
	return c


static func join_dialog() -> Control:
	var c := Control.new()
	c.name = "JoinDialog"
	c.size = Vector2(800, 450)
	_with_script(c, "res://game/ui/join_dialog.gd")
	var dim := rect(c, "Dim", Color(0, 0, 0, 0.8), Vector2.ZERO, Vector2(800, 450))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	centered(label(c, "Head", "VÀO PHÒNG", 34, Palette.AMBER, Vector2(0, 50), 8), 800, 46)
	label(c, "LCode", "MÃ PHÒNG HOẶC IP[:CỔNG]", 14, Palette.PAPER, Vector2(200, 130), 3)
	label(c, "LName", "TÊN CỦA BẠN", 14, Palette.PAPER, Vector2(200, 200), 3)
	for e in [["Code", 152.0, 24], ["Name", 222.0, 16]]:
		var le := LineEdit.new()
		le.name = String(e[0])
		le.position = Vector2(200, e[1])
		le.size = Vector2(400, 32)
		le.max_length = e[2]
		le.add_theme_font_override("font", Build.font())
		le.add_theme_font_size_override("font_size", 18)
		le.add_theme_stylebox_override("normal", box_style(Color(0, 0, 0, 0.8), Color(0.35, 0.33, 0.28)))
		le.add_theme_stylebox_override("focus", box_style(Color(0.1, 0.06, 0.02, 0.9), Palette.AMBER, 2))
		c.add_child(le)
	centered(label(c, "Status", "", 13, Color(0.9, 0.6, 0.4), Vector2(0, 270), 3), 800, 18)
	button(c, "Connect", "VÀO", Vector2(200, 310), Vector2(190, 34))
	button(c, "Back", "QUAY LẠI", Vector2(410, 310), Vector2(190, 34))
	centered(label(c, "Help", "MÃ PHÒNG HIỆN Ở SẢNH CỦA MÁY CHỦ. CHƠI KHÁC MẠNG CẦN MỞ CỔNG UDP %d HOẶC DÙNG VPN LAN (TAILSCALE, ZEROTIER)." % 24555, 10, Color(0.8, 0.78, 0.7, 0.6), Vector2(0, 360), 3), 800, 16)
	c.visible = false
	return c
