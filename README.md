# Stress Test — bản mẫu 10 cửa, tông kinh dị (Godot 4.4+)

Bản mẫu để xem chất hình, nhịp chơi và cách tính điểm. Chưa phải game hoàn chỉnh. Có cảnh máu me.

## Chạy
1. Tải Godot 4.4 trở lên (bản Standard) tại https://godotengine.org/download
2. Mở Godot → Import → chọn file `project.godot` trong thư mục này.
3. Bấm F5 để chạy.

## Điều khiển
- WASD / mũi tên: di chuyển đối tượng 01 — SPACE: nhảy — Esc: thoát
- N: kết thúc cửa hiện tại ngay (để xem nhanh) — phím 1–9 và 0: nhảy tới cửa 1–10
- ENTER ở màn tổng kết: chơi lại từ cửa 1
- Không bấm gì 3 giây thì máy tự điều khiển đối tượng 01.

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
- Đổi cách cho điểm: sửa `POINTS`, `ROUND_TIME`, `ORDER` ở đầu `main.gd`, và hàm `_end_round()`.

## Cấu trúc
- `main.gd` — toàn bộ cảnh, nhân vật, 10 cửa, bot, trận đấu và tính điểm, hệ máu/mảnh vụn, HUD.
  Cảnh dựng bằng code nên mở editor sẽ thấy scene trống.
- `shaders/` — tường bê tông, sàn bẩn, bề mặt gỉ kiểu texture độ phân giải thấp, sọc cảnh báo, hậu kỳ.
- `fonts/Anton-Regular.ttf` — font Anton (giấy phép OFL).

## Giới hạn hiện tại
- Chỉ đối tượng 01 do người điều khiển, 3 đối tượng còn lại là bot đơn giản; chưa có chơi mạng hay nhiều tay cầm.
- Va chạm tự viết đơn giản, chưa dùng physics engine. Chưa có âm thanh.
- Model đều là khối cơ bản ghép lại.
