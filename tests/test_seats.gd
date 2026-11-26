extends RefCounted
## Ghế ngồi: vào / rời ghế, bot ngồi ghế trống, đổi mũ và màu áo, nhận nút bấm.


func run(t) -> void:
	var s := Seats.new()
	t.check("ban đầu 4 bot", s.humans(), 0)
	t.check("bàn phím 1 vào ghế đầu", s.toggle("kb1"), 0)
	t.check("tay cầm 2 vào ghế kế", s.toggle("pad", 1), 1)
	t.check("tay cầm 1 vào ghế kế", s.toggle("pad", 0), 2)
	t.check("bàn phím 2 vào ghế cuối", s.toggle("kb2"), 3)
	t.check("hết ghế", s.toggle("pad", 3), -1)
	t.check("bàn phím 1 rời ghế", s.toggle("kb1"), 0)
	t.ok("ghế 0 thành bot", s.is_bot(0))
	t.check("tìm ghế theo thiết bị", s.seat_of("pad", 0), 2)
	t.check("nút bấm tới đúng ghế", s.press("pad", 1, "jump"), 1)
	t.ok("ghế 1 nhận nhảy", s.source(1).jump_req)
	s.clear_inputs()
	t.ok("xoá nút bấm", not s.source(1).jump_req)
	t.check("thiết bị không ngồi ghế nào", s.press("kb1", 0, "jump"), -1)
	var hat0: int = s.looks[2].hat
	s.cycle_look(2, 1, 0)
	t.check("đổi mũ", s.looks[2].hat, (hat0 + 1) % SubjectModel.HAT_NAMES.size())
	s.cycle_look(2, -2, 0)
	t.check("đổi mũ lùi vòng", s.looks[2].hat, posmod(hat0 - 1, SubjectModel.HAT_NAMES.size()))
	s.cycle_look(3, 0, 1)
	t.check("đổi màu áo", s.looks[3].color, SubjectModel.COLORS[4])
	s.cycle_look(0, 0, -1)
	t.check("đổi màu áo lùi vòng", s.looks[0].color, SubjectModel.COLORS[SubjectModel.COLORS.size() - 1])
	t.check("nhãn giữ nguyên số", s.looks[0].label, "01")
	t.check("hành động phím bàn phím 2", KeyboardSource.action_for(2, KEY_COMMA), "sabotage")
	t.check("hành động nút tay cầm", PadSource.action_for(JOY_BUTTON_Y), "sabotage")
