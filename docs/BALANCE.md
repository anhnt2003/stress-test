# Cân bằng 10 cửa (giai đoạn 3)

Đo bằng bot: `godot --headless --fixed-fps 60 --path . -- --balance=32` (32 trận, seed 1..32, có đẩy nhau và chơi xấu).
Bot chưa phải người thật: số liệu dùng để phát hiện cửa quá dễ / quá khó và thiên lệch theo ghế, chưa thay được buổi chơi thử.

## Kết quả sau khi chỉnh (26/11/2026)

Đo lại sau khi sửa collider của máy ép / thùng hàng / quả tạ (trước đó collider nằm lại chỗ lúc tạo).

```
BALANCE matches=32
CỬA             chết/ng   0 chết    chênh chơi xấu
MÁY ÉP             1.38       3%     1.94     1.81   điểm/ghế [80, 78, 89, 96]
SÀN ĐIỆN           1.52       0%     2.03     4.00   điểm/ghế [89, 80, 77, 82]
LƯỠI CƯA           2.62       0%     1.84     2.41   điểm/ghế [91, 73, 82, 75]
BĂNG CHUYỀN        1.34       0%     1.41     1.75   điểm/ghế [69, 85, 80, 96]
SÀN CẢM ỨNG        0.00     100%     0.00     3.97   điểm/ghế [79, 81, 87, 78]
TẠ RƠI             1.01       0%     1.91     3.53   điểm/ghế [90, 86, 79, 80]
SÀN NGHIỀN         1.65       0%     1.72     3.41   điểm/ghế [79, 89, 72, 83]
CON LẮC            2.51       0%     2.19     2.56   điểm/ghế [81, 76, 79, 84]
LÕI NỔ             0.50       0%     1.19     3.25   điểm/ghế [91, 87, 89, 97]
VÒNG LỬA           2.87       0%     2.12     2.75   điểm/ghế [80, 84, 85, 71]
thắng theo ghế: [8, 8, 9, 9]   tổng điểm theo ghế: [829, 819, 819, 842]
```

- `chết/ng`: số lần chết trung bình mỗi người mỗi cửa. `chênh`: người chết nhiều nhất trừ người chết ít nhất.
- Sàn cảm ứng xếp theo số ô nên không tính lần chết trong cửa (người thua nổ vòng cổ sau khi chấm điểm).

## Đã chỉnh

| Vấn đề | Trước | Sửa |
|---|---|---|
| Lưỡi cưa quá khó sau khi có đẩy nhau | 3,7 lần chết/người | Tốc độ tay cưa 1,5→3,3 thành 1,4→2,8; chơi xấu tăng tốc ×1,7 thành ×1,35 |
| Vòng lửa: 4 người không đủ chỗ đứng cuối cửa | 3,1 | Bán kính nhỏ nhất 0,62 → 0,8 |
| Con lắc: bị đẩy ra khỏi vùng sáng là chết ngay | 2,8 | Được ở ngoài vùng 0,9 → 1,2 giây; vùng dời chậm hơn ở cuối cửa |
| Băng chuyền thiên lệch ghế 1 (24 điểm so với 56) | | Bot né thùng theo cờ ngẫu nhiên từng ghế thay vì hàm băm theo số ghế; mọi người xuất phát cùng khoảng cách tới đầu nạp |
| Lõi nổ: ghế 2 luôn cầm lõi đầu tiên | | Người cầm lõi đầu chọn theo seed |
| Máy ép, sàn điện, sàn nghiền, sàn cảm ứng: chỗ xuất phát cố định theo ghế | | Xáo chỗ xuất phát theo seed |
