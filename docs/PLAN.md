# Kế hoạch triển khai — Stress Test

Party game 3D kinh dị cho 3–4 người: 10 cửa, chấm điểm sau mỗi cửa, chốt điểm từng người cuối trận.
Engine: Godot 4.4 (GDScript). Trạng thái hiện tại: bản mẫu một file `main.gd` (~2.800 dòng), 1 người + 3 bot.

## Hiện có gì

- 10 cửa chạy nối tiếp, mỗi cửa 30 giây, có màn mở đầu, bảng kết quả, bảng tổng kết.
- Tính điểm: hạng theo số lần chết (+4/+3/+2/+1), hoà thì xét lần chết đầu muộn hơn.
- Hình ảnh: buồng bê tông, shader texel bẩn, hậu kỳ sepia + dither, hệ máu và mảnh vụn.
- Bot đơn giản cho từng cửa. Va chạm tự viết, không dùng physics engine.

## Còn thiếu gì

- Chỉ một người chơi thật. Chưa có nhiều tay cầm, chưa có mạng.
- Toàn bộ nằm trong một file, cảnh dựng bằng code nên không sửa được trong editor.
- Chưa có âm thanh, chưa có menu.
- Model là khối cơ bản. Chưa có tương tác giữa người chơi (húc, đẩy, phá nhau).

## Nguyên tắc

1. Mỗi giai đoạn kết thúc bằng một bản chơi được.
2. Tách code trước khi thêm tính năng: thêm mạng vào file 2.800 dòng sẽ rất khó gỡ.
3. Luật chơi chạy ở một nơi (host). Máy khách chỉ gửi input và vẽ lại trạng thái.

## Giai đoạn 0 — Dựng repo (0,5 ngày)

- [ ] Đẩy bản mẫu lên GitHub, nhánh `main`.
- [ ] `README.md`, `.gitignore`, giấy phép.
- [ ] GitHub Actions: kiểm tra parse GDScript bằng Godot headless ở mỗi lần đẩy.
- [ ] Lệnh chạy mô phỏng cả trận không cần màn hình (`--match --phase=400`) làm smoke test.

Xong khi: CI xanh trên `main`.

## Giai đoạn 1 — Tách kiến trúc (3–4 ngày)

Mục tiêu: hành vi giữ nguyên, code chia theo trách nhiệm.

```
game/
  match/        match_manager.gd   — máy trạng thái INTRO/PLAY/RESULT/FINAL, thứ tự cửa
                scoring.gd         — xếp hạng, cộng điểm, hoà (hàm thuần, có unit test)
  doors/        door_base.gd       — giao diện chung: setup(), tick(dt), ground_y(), spawn_point()
                press.gd, saw.gd, belt.gd, ...   — mỗi cửa một file
  actors/       subject.tscn + subject.gd        — nhân vật, hoạt ảnh, các kiểu chết
                bot_brain.gd                     — AI, tách khỏi nhân vật
  fx/           gore.gd (giọt máu, mảnh vụn, vết loang), camera_fx.gd
  world/        chamber.tscn                     — buồng thử, sửa được trong editor
  ui/           hud.tscn, result_panel.tscn, intro_banner.tscn
  input/        input_source.gd                  — bàn phím / tay cầm / bot / mạng cùng một giao diện
shaders/  fonts/  tests/
```

- [ ] `door_base.gd` và chuyển 10 cửa sang, mỗi cửa một commit.
- [ ] `InputSource`: mọi nhân vật nhận `move: Vector2` và `jump: bool`, không biết nguồn là người hay bot.
- [ ] `scoring.gd` có unit test (GUT): đồng hạng, hoà, cửa tính theo ô.
- [ ] Chuyển buồng thử và HUD sang scene `.tscn`.
- [ ] Smoke test: trận mô phỏng với seed cố định cho ra tổng điểm giống bản mẫu.

Xong khi: `main.gd` còn dưới 150 dòng và smoke test trùng kết quả cũ.

## Giai đoạn 2 — Chơi chung một máy (2–3 ngày)

- [ ] Màn sảnh: mỗi người bấm nút để vào, chọn mũ và màu áo.
- [ ] 2–4 tay cầm, cộng một người dùng bàn phím. Ghế trống thì bot ngồi.
- [ ] Menu chính, tạm dừng, chơi lại.

Xong khi: 4 người thật chơi trọn 10 cửa trên một máy. Đây là mốc để thử xem game có vui không.

## Giai đoạn 3 — Vật lý và tương tác (4–5 ngày)

- [ ] Chuyển nhân vật sang `CharacterBody3D`, va chạm bằng physics engine (Jolt).
- [ ] Húc/đẩy người khác (nút thứ hai, có hồi chiêu). Đây là thứ tạo ra kịch tính giữa người chơi.
- [ ] Ragdoll khi chết thay cho đổ người bằng xoay.
- [ ] Mỗi cửa một nút "chơi xấu" dùng một lần.
- [ ] Cân bằng lại 10 cửa sau khi có đẩy nhau.

Xong khi: chơi thử 3 trận với người thật, ghi lại cửa nào chán để sửa hoặc thay.

## Giai đoạn 4 — Chơi qua mạng (6–8 ngày)

Mô hình: host-authoritative, dùng High-level Multiplayer của Godot trên ENet.

- [ ] Host chạy toàn bộ luật chơi. Khách gửi input 30 lần/giây, nhận snapshot 20 lần/giây.
- [ ] Nội suy vị trí phía khách. Dự đoán phía khách chỉ cho nhân vật của chính mình.
- [ ] Sự kiện chết, điểm, chuyển cửa gửi bằng RPC tin cậy.
- [ ] Vào phòng bằng mã. Ưu tiên Steam lobby (GodotSteam); phương án dự phòng: server relay nhỏ.
- [ ] Xử lý rớt mạng: người rớt thì bot thay, vào lại được giữa trận.

Việc cần quyết trước giai đoạn này: phát hành qua Steam hay chỉ gửi bản build cho bạn bè (ảnh hưởng cách tạo phòng).

Xong khi: 4 máy khác mạng chơi trọn một trận, độ trễ 100 ms vẫn chơi được.

## Giai đoạn 5 — Hình ảnh và âm thanh (làm song song từ giai đoạn 2)

- [ ] Model nhân vật low-poly có xương, làm trong Blender. 6–8 mũ.
- [ ] Bake ánh sáng cho buồng thử. Thêm 2–3 biến thể buồng để đỡ lặp.
- [ ] Âm thanh: tiếng máy, tiếng chết riêng từng kiểu, nhạc nền công nghiệp, giọng Cỗ Máy.
- [ ] Lời Cỗ Máy sinh theo diễn biến trận (gọi LLM, có câu dựng sẵn khi mất mạng).

## Giai đoạn 6 — Đóng gói

- [ ] Export Windows / macOS / Linux bằng GitHub Actions, gắn vào Release.
- [ ] Màn cài đặt: âm lượng, độ phân giải, bật/tắt máu me.
- [ ] Trang itch.io hoặc Steam.

## Rủi ro

| Rủi ro | Cách giảm |
|---|---|
| Đồng bộ mạng cho game vật lý nhiều va chạm rất khó | Host quyết định hết; vật lý phía khách chỉ để hiển thị |
| Game không vui với người thật | Giai đoạn 2 phải có bản 4 người thử sớm, trước khi đầu tư mạng |
| Giống Machine Party quá mức | Giữ nhân vật, cửa và bối cảnh riêng; không dùng tên hay tài sản của họ |
| Làm một mình, phạm vi phình to | Mỗi giai đoạn có mốc "xong khi"; cắt giai đoạn 5 nếu thiếu thời gian |

## Thứ tự đề xuất

0 → 1 → 2 → (chơi thử, quyết định có làm tiếp) → 3 → 4 → 6, giai đoạn 5 xen kẽ.
Ước lượng tới mốc 4 người chơi chung một máy: khoảng 1 tuần làm buổi tối.
