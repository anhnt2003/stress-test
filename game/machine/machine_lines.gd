extends RefCounted
## Câu dựng sẵn của Cỗ Máy và câu nhắc gửi LLM. Hàm thuần để kiểm thử được.

const DOOR_INTRO := {
	0: ["MÁY ÉP ĐÃ ĐƯỢC TRA DẦU. CHÚC MAY MẮN.", "ĐỘ DÀY TIÊU CHUẨN: MỘT MILIMÉT."],
	1: ["MỖI TẤM SÀN CHỊU ĐƯỢC HAI BƯỚC CHÂN. TÔI ĐÃ ĐẾM.", "TRỤC NGHIỀN ĐANG ĐÓI."],
	2: ["NHẢY. HOẶC TÁCH LÀM HAI. CẢ HAI ĐỀU CÓ ÍCH CHO DỮ LIỆU.", "LƯỠI CƯA ĐƯỢC MÀI SÁNG NAY."],
	3: ["LÕI NỔ KHÔNG THÍCH BỊ GIỮ LÂU.", "HÃY CHIA SẺ. ĐÓ LÀ ĐIỀU TỬ TẾ."],
	4: ["CHIẾM SÀN. KẺ THUA SẼ ĐƯỢC THÁO VÒNG CỔ. THEO CÁCH CỦA TÔI.", "MÀU CỦA BẠN. SÀN CỦA BẠN. ĐẦU CỦA BẠN."],
	5: ["BĂNG CHUYỀN CHỈ CHẠY MỘT CHIỀU.", "MÁY HUỶ ĐANG CHỜ HÀNG."],
	6: ["DÒNG ĐIỆN LÀ BẠN. MỘT NGƯỜI BẠN HƠI NÓNG TÍNH.", "ĐỪNG ĐỨNG TRÊN Ô VÀNG."],
	7: ["ĐỨNG TRONG ÁNH SÁNG. ĐÓ LÀ NƠI TÔI NHÌN THẤY BẠN.", "CON LẮC KHÔNG BAO GIỜ MỆT."],
	8: ["TẠ NẶNG MỘT TẤN. BẠN NHẸ HƠN NHIỀU.", "HÃY NHÌN XUỐNG SÀN. VÒNG ĐỎ LÀ LỜI MỜI."],
	9: ["CỬA CUỐI. LỬA KHÔNG PHÂN BIỆT AI.", "VÙNG AN TOÀN ĐANG CO LẠI. GIỐNG NHƯ CƠ HỘI CỦA BẠN."],
}
const STREAK := ["ĐỐI TƯỢNG %s CHẾT BA LẦN LIÊN TIẾP. RẤT NHẤT QUÁN.", "ĐỐI TƯỢNG %s: TÔI BẮT ĐẦU QUÝ BẠN."]
const EARLY := ["ĐỐI TƯỢNG %s KHÔNG ĐỢI ĐƯỢC.", "ĐỐI TƯỢNG %s: KỶ LỤC MỚI VỀ ĐỘ VỘI VÀNG."]
const LEADER := ["ĐỐI TƯỢNG %s ĐANG DẪN ĐẦU. ĐỪNG QUEN VỚI ĐIỀU ĐÓ.", "ĐỐI TƯỢNG %s LÊN ĐẦU BẢNG. TÔI ĐÃ GHI CHÚ."]
const NO_DEATHS := ["KHÔNG AI CHẾT. THẬT ĐÁNG THẤT VỌNG.", "CỬA NÀY QUÁ DỄ. TÔI SẼ SỬA."]
const FINAL := ["ĐỐI TƯỢNG %s SẼ ĐƯỢC GIỮ LẠI. CHO ĐỢT THỬ TIẾP THEO.", "CHÚC MỪNG ĐỐI TƯỢNG %s. PHẦN THƯỞNG LÀ ĐƯỢC SỐNG THÊM."]
const SABOTAGE := ["ĐỐI TƯỢNG %s ĐÃ CHẠM VÀO MÁY CỦA TÔI. TÔI SẼ NHỚ.", "ĐỐI TƯỢNG %s CHƠI XẤU. RẤT TỐT CHO DỮ LIỆU."]

const SYSTEM := "Bạn là Cỗ Máy, giọng thông báo lạnh lùng, mỉa mai trong một trò chơi kinh dị công nghiệp. " \
	+ "Các 'đối tượng thử nghiệm' được gọi bằng số (ví dụ ĐỐI TƯỢNG 03). Trả lời đúng MỘT câu tiếng Việt, " \
	+ "VIẾT HOA, tối đa 14 từ, không dùng emoji, không giải thích."


static func _pick(arr: Array, rng: RandomNumberGenerator) -> String:
	return String(arr[rng.randi() % arr.size()])


static func door_intro(door_id: int, rng: RandomNumberGenerator) -> String:
	return _pick(DOOR_INTRO.get(door_id, ["BẮT ĐẦU."]), rng)


static func streak(who: String, rng: RandomNumberGenerator) -> String:
	return _pick(STREAK, rng) % who


static func early_death(who: String, _mode: String, rng: RandomNumberGenerator) -> String:
	return _pick(EARLY, rng) % who


static func new_leader(who: String, rng: RandomNumberGenerator) -> String:
	return _pick(LEADER, rng) % who


static func no_deaths(rng: RandomNumberGenerator) -> String:
	return _pick(NO_DEATHS, rng)


static func final(who: String, rng: RandomNumberGenerator) -> String:
	return _pick(FINAL, rng) % who


static func sabotage(who: String, rng: RandomNumberGenerator) -> String:
	return _pick(SABOTAGE, rng) % who


static func _standings(m: MatchManager) -> String:
	var parts := []
	for i in Seats.N:
		parts.append("ĐỐI TƯỢNG %s: %d điểm, chết %d lần" % [String(m.seats.looks[i].label), int(m.totals[i]), int(m.total_deaths[i]) + (m.subjects[i].deaths if i < m.subjects.size() and m.state == MatchManager.ST_PLAY else 0)])
	return "; ".join(parts)


static func prompt_door(m: MatchManager, i: int, door: DoorBase) -> String:
	return "Sắp bắt đầu cửa %d/10: %s (%s). Bảng điểm: %s. Nói một câu mở màn." % [i + 1, door.title, door.rule, _standings(m)]


static func prompt_round(m: MatchManager) -> String:
	return "Vừa xong cửa %d/10: %s. Bảng điểm: %s. Bình luận một câu về kết quả." % [m.door_index + 1, m.door.title, _standings(m)]


static func prompt_final(m: MatchManager, best: int) -> String:
	return "Trận đã kết thúc. Người thắng: ĐỐI TƯỢNG %s. Bảng điểm: %s. Nói một câu kết." % [String(m.seats.looks[best].label), _standings(m)]
