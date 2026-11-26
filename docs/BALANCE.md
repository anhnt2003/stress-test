# Cân bằng 10 cửa (giai đoạn 3)

Đo bằng bot: `godot --headless --fixed-fps 60 --path . -- --balance=32` (32 trận, seed 1..32, có đẩy nhau và chơi xấu).
Bot chưa phải người thật: số liệu dùng để phát hiện cửa quá dễ / quá khó và thiên lệch theo ghế, chưa thay được buổi chơi thử.

## Kết quả sau khi chỉnh (26/11/2026)

```
BALANCE matches=32
CỬA             chết/ng   0 chết    chênh chơi xấu
MÁY ÉP             1.26       0%     1.94     2.06   điểm/ghế [93, 80, 83, 81]
SÀN ĐIỆN           1.48       0%     2.16     4.00   điểm/ghế [85, 77, 85, 82]
LƯỠI CƯA           2.72       0%     2.34     2.50   điểm/ghế [87, 86, 77, 71]
BĂNG CHUYỀN        1.30       0%     1.28     1.53   điểm/ghế [82, 84, 90, 74]
SÀN CẢM ỨNG        0.00     100%     0.00     3.97   điểm/ghế [79, 81, 87, 78]
TẠ RƠI             1.05       3%     1.84     3.59   điểm/ghế [83, 84, 83, 98]
SÀN NGHIỀN         1.61       0%     1.78     3.44   điểm/ghế [67, 91, 84, 80]
CON LẮC            2.52       0%     2.53     2.75   điểm/ghế [79, 78, 82, 81]
LÕI NỔ             0.50       0%     1.12     3.31   điểm/ghế [89, 95, 83, 93]
VÒNG LỬA           2.83       0%     2.19     2.94   điểm/ghế [67, 86, 86, 82]
thắng theo ghế: [8, 10, 8, 6]   tổng điểm theo ghế: [811, 842, 840, 820]
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
