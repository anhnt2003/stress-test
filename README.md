# Stress Test — bản mẫu 10 cửa, tông kinh dị (Godot 4.4+)

Bản mẫu để xem chất hình, nhịp chơi và cách tính điểm. Chưa phải game hoàn chỉnh. Có cảnh máu me.

## Chạy
1. Tải Godot 4.4 trở lên (bản Standard) tại https://godotengine.org/download
2. Mở Godot → Import → chọn file `project.godot` trong thư mục này.
3. Bấm F5 để chạy.

## Điều khiển
Tối đa 4 người trên một máy; ghế trống do bot ngồi.

| Thiết bị | Di chuyển | Nhảy | Đẩy |
|---|---|---|---|
| Bàn phím 1 | WASD | Space | F |
| Bàn phím 2 | Phím mũi tên | Dấu chấm `.` | Dấu `/` |
| Tay cầm (1–4) | Cần trái / D-pad | A | X hoặc B |

- Ở sảnh: bấm nút nhảy để vào ghế, bấm lần nữa để rời. Enter / Start để bắt đầu.
- Trong trận: Esc / Start tạm dừng, Q (khi tạm dừng) về sảnh.
- Đẩy: xô người đứng trước mặt văng ra khoảng 2 mét, hồi chiêu 1,3 giây.
- Phím gỡ lỗi: F1–F10 nhảy tới cửa 1–10, F12 kết thúc cửa hiện tại.

## Một trận
10 cửa nối tiếp nhau, mỗi cửa 30 giây. Chết thì đối tượng thay thế được thả xuống, nhưng bị tính một lần chết.

| Cửa | Tên | Luật | Kiểu chết |
|---|---|---|---|
| 1 | Máy ép | Rời ô đỏ trước khi máy dập | Ép nát |
| 2 | Sàn điện | Ô nháy vàng sắp phóng điện | Cháy đen |
| 3 | Lưỡi cưa | Nhảy qua tay cưa quay | Cắt đôi |
| 4 | Băng chuyền | Chạy ngược băng, né thùng hàng | Vào máy huỷ |
| 5 | Sàn cảm ứng | Chiếm nhiều ô nhất | Nổ vòng cổ (ai không đứng đầu) |
| 6 | Tạ rơi | Tránh vòng đỏ | Ép nát |
| 7 | Sàn nghiền | Tấm sàn dẫm hai lần thì sập | Rơi vào trục nghiền |
| 8 | Con lắc | Đứng trong vùng sáng, tránh đường rìu | Cắt đôi / nổ vòng cổ |
| 9 | Lõi nổ | Chuyền lõi trước khi nổ | Nổ tung |
| 10 | Vòng lửa | Ở trong vùng an toàn đang co lại | Cháy đen |

## Tính điểm
- Sau mỗi cửa: xếp hạng theo số lần chết (ít hơn xếp trên). Bằng nhau thì ai chết lần đầu muộn hơn xếp trên.
  Riêng cửa Sàn cảm ứng xếp theo số ô chiếm được.
- Hạng 1 / 2 / 3 / 4 được +4 / +3 / +2 / +1 điểm. Đồng hạng thì cùng điểm.
- Hết 10 cửa: chốt tổng điểm. Bằng điểm thì ai chết ít hơn xếp trên. Hạng 1 "được giữ lại", những người còn lại bị "loại bỏ".
- Luật tính điểm nằm trong `scoring.gd` (có kiểm thử ở `tests/test_scoring.gd`). Thời lượng và thứ tự cửa: `ROUND_TIME`, `ORDER` ở đầu `main.gd`.

## Cấu trúc
- `main.gd` — cảnh, nhân vật, 10 cửa, bot, trận đấu, sảnh, điều khiển, hệ máu/mảnh vụn, HUD.
  Cảnh dựng bằng code nên mở editor sẽ thấy scene trống.
- `scoring.gd` — luật xếp hạng và cho điểm, hàm thuần.
- `tests/test_scoring.gd` — kiểm thử tính điểm: `godot --headless --path . --script res://tests/test_scoring.gd`
- `audio/` — hiệu ứng âm thanh, sinh bằng `tools/gen_sfx.py` (tổng hợp số, không dùng sample ngoài).
- `shaders/` — tường bê tông, sàn bẩn, bề mặt gỉ kiểu texture độ phân giải thấp, sọc cảnh báo, hậu kỳ.
- `fonts/Anton-Regular.ttf` — font Anton (giấy phép OFL).
- `.github/workflows/ci.yml` — kiểm tra cú pháp, chạy kiểm thử, chạy thử cả trận 10 cửa bằng bot.
- `docs/PLAN.md` — kế hoạch và tiến độ.

## Giới hạn hiện tại
- Chưa có chơi qua mạng.
- Va chạm tự viết đơn giản, chưa dùng physics engine, chưa có ragdoll.
- Âm thanh là âm tổng hợp cơ bản, chưa có nhạc nền. Model là khối cơ bản ghép lại.
- `main.gd` vẫn là một file lớn; việc tách thành module chưa làm xong.
