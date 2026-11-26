# Kế hoạch triển khai — Stress Test

Party game 3D kinh dị cho 3–4 người: 10 cửa, chấm điểm sau mỗi cửa, chốt điểm từng người cuối trận.
Engine: Godot 4.4 (GDScript).

## Tiến độ

| Giai đoạn | Trạng thái |
|---|---|
| 0 — Repo và CI | Xong (trừ giấy phép: chờ chủ dự án chọn) |
| 1 — Tách kiến trúc | Xong: `main.gd` 143 dòng, 10 cửa mỗi cửa một file, buồng thử và HUD là `.tscn`; trận mô phỏng khớp bản mẫu |
| 2 — Chơi chung một máy | Xong phần code: menu chính, sảnh chọn mũ / màu áo, tạm dừng, chơi lại. Chưa chơi thử 4 người thật |
| 3 — Vật lý và tương tác | Xong phần code: CharacterBody3D, ragdoll, chơi xấu từng cửa, cân bằng lại bằng bot. Dùng GodotPhysics3D thay Jolt (xem dưới). Chưa chơi thử với người thật |
| 4 — Chơi qua mạng | Xong phần code: host-authoritative trên ENet, mã phòng, nội suy, dự đoán, rớt mạng thì bot thay, vào lại được. Đã chạy máy chủ + máy khách trên cùng máy (trễ giả lập 100 ms). Chưa thử 4 máy khác mạng; chưa có Steam lobby / relay |
| 5 — Hình ảnh và âm thanh | Phần lớn: 8 mũ, 3 biến thể buồng, tiếng chết riêng từng kiểu, nhạc nền, giọng Cỗ Máy (TTS), lời bình LLM. Chưa có model Blender, chưa bake ánh sáng |
| 6 — Đóng gói | Phần lớn: workflow xuất bản 3 nền tảng + Release, màn cài đặt, bản nháp trang itch.io. Chưa tạo trang itch.io / Steam |

Những việc chỉ người làm được (chơi thử với người thật, chọn giấy phép, quyết định Steam hay itch.io, làm model
trong Blender, tạo trang cửa hàng) được ghi rõ là "chưa" ở từng giai đoạn bên dưới.

## Nguyên tắc

1. Mỗi giai đoạn kết thúc bằng một bản chơi được.
2. Tách code trước khi thêm tính năng: thêm mạng vào file 2.800 dòng sẽ rất khó gỡ.
3. Luật chơi chạy ở một nơi (host). Máy khách chỉ gửi input và vẽ lại trạng thái.

## Giai đoạn 0 — Dựng repo

- [x] Đẩy bản mẫu lên GitHub, nhánh `main`.
- [x] `README.md`, `.gitignore`.
- [ ] Giấy phép — **cần chủ dự án quyết định** (MIT / tự giữ bản quyền nếu định bán trên Steam). Font Anton đã có giấy phép OFL riêng.
- [x] GitHub Actions: import + kiểm tra cú pháp mọi script, chạy kiểm thử, chạy cả trận bằng bot, chạy thử mạng.
- [x] Chạy mô phỏng cả trận không cần màn hình (`--fixed-fps 60 -- --shot=… --match --phase=400`) làm smoke test.

## Giai đoạn 1 — Tách kiến trúc

```
main.gd                       bootstrap + CLI + vòng lặp (143 dòng)
game/flow.gd                  điều phối màn
game/match/   match_manager.gd, scoring.gd, balance.gd
game/doors/   door_base.gd (setup, tick, ground_y, spawn_point, constrain, bot_steer, sabotage, net_state…) + 10 cửa
game/actors/  subject.tscn + subject.gd, subject_model.gd, bot_brain.gd, ragdoll.gd
game/fx/      gore.gd, camera_fx.gd
game/world/   chamber_09.tscn, chamber_13.tscn, chamber_21.tscn, chamber.gd
game/ui/      hud.tscn, result_panel.tscn, intro_banner.tscn, lobby_panel.tscn, menu…
game/input/   input_source.gd (+ bàn phím, tay cầm, bot), seats.gd, input_router.gd; game/net/net_source.gd
```

- [x] `door_base.gd` và chuyển 10 cửa sang, mỗi cửa một file.
- [x] `InputSource`: mọi nhân vật nhận một khung input (move, jump, shove, sabotage), không biết nguồn là người, bot hay mạng.
- [x] `scoring.gd` có unit test: đồng hạng, hoà, cửa tính theo ô. Dùng bộ chạy kiểm thử tự viết `tests/run_all.gd`
      thay cho GUT (không cần cài addon, chạy được ngay trong CI).
- [x] Chuyển buồng thử và HUD sang scene `.tscn` (sinh một lần bằng `tools/migrate_scenes.gd`, sau đó sửa trong editor).
- [x] Smoke test: trận mô phỏng seed cố định cho ra đúng từng dòng nhật ký như bản mẫu (82 dòng, cả 10 cửa) —
      kiểm ở commit tách kiến trúc. Từ giai đoạn 3 kết quả đổi vì vật lý mới nên bỏ file mẫu.

Ghi chú: `GPUParticles3D` rút số từ RNG chung ngay trong hàm khởi tạo, nên buồng thử được tạo sẵn lúc khởi động;
máu me dùng RNG riêng để bật / tắt máu me không đổi diễn biến trận.

## Giai đoạn 2 — Chơi chung một máy

- [x] Màn sảnh: mỗi người bấm nút để vào, chọn mũ (8 kiểu) và màu áo (8 màu).
- [x] 2–4 tay cầm, cộng hai người dùng bàn phím. Ghế trống thì bot ngồi.
- [x] Menu chính, tạm dừng, chơi lại.
- [ ] Chơi thử 4 người thật trọn 10 cửa trên một máy — **cần người chơi**.

## Giai đoạn 3 — Vật lý và tương tác

- [x] Nhân vật là `CharacterBody3D`, va chạm với người khác và chướng ngại vật qua physics engine.
      Luật chạy trong `_physics_process` vì truy vấn va chạm ngoài bước vật lý thấy trạng thái cũ.
- [~] Jolt: đã thử, **đang dùng GodotPhysics3D**. Trên Godot 4.4.1, Jolt báo
      "job system exceeded the maximum number of jobs" khi có nhiều xác vật lý và một lần treo hẳn. Code không phụ thuộc
      engine; khi lên Godot 4.5 thử lại bằng cách đổi `physics/3d/physics_engine` trong `project.godot`.
- [x] Húc/đẩy người khác (nút thứ hai, hồi chiêu 1,3 giây).
- [x] Ragdoll khi chết (cắt đôi, nổ đầu, cháy) thay cho đổ người bằng xoay.
- [x] Mỗi cửa một nút "chơi xấu" dùng một lần (bot cũng dùng; tắt được ở sảnh).
- [x] Cân bằng lại 10 cửa sau khi có đẩy nhau — đo bằng bot, xem `docs/BALANCE.md`.
- [ ] Chơi thử 3 trận với người thật, ghi lại cửa nào chán — **cần người chơi**.

## Giai đoạn 4 — Chơi qua mạng

Mô hình: host-authoritative, High-level Multiplayer của Godot trên ENet.

- [x] Host chạy toàn bộ luật chơi. Khách gửi input 30 lần/giây, nhận snapshot 20 lần/giây.
- [x] Nội suy vị trí phía khách. Dự đoán phía khách chỉ cho nhân vật của chính mình.
- [x] Sự kiện chết, điểm, chuyển cửa gửi bằng RPC tin cậy.
- [x] Vào phòng bằng mã (mã hoá IP + cổng, không cần máy chủ trung gian).
- [ ] Steam lobby (GodotSteam) hoặc server relay nhỏ — **chờ quyết định phát hành qua Steam hay gửi bản build**.
      Hiện tại chơi khác mạng cần mở cổng UDP 24555 hoặc VPN LAN (Tailscale, ZeroTier).
- [x] Xử lý rớt mạng: người rớt thì bot thay, vào lại được giữa trận (nhận ra bằng token lưu trong cài đặt).
- [ ] 4 máy khác mạng chơi trọn một trận ở độ trễ 100 ms — **cần 4 máy**. Đã kiểm: máy chủ + máy khách trên cùng máy,
      trễ giả lập 100 ms (`--net-lag=100`), chạy trong CI.

## Giai đoạn 5 — Hình ảnh và âm thanh

- [ ] Model nhân vật low-poly có xương, làm trong Blender — **cần người làm model**. Hiện vẫn ghép từ khối cơ bản.
- [x] 6–8 mũ: 8 mũ dựng bằng code (mũ cối, nón lá, mũ bảo hiểm, băng đầu, mũ len, mặt nạ hàn, mũ phớt, xô sắt).
- [ ] Bake ánh sáng cho buồng thử — cần bake trong editor có GPU.
- [x] 2–3 biến thể buồng để đỡ lặp: buồng 09 (đèn dây tóc), 13 (huỳnh quang lạnh, gạch men), 21 (đèn khẩn cấp đỏ).
- [x] Âm thanh: tiếng máy, tiếng chết riêng từng kiểu, nhạc nền công nghiệp lặp 38 giây (tổng hợp số).
- [x] Giọng Cỗ Máy: đọc bằng TTS tiếng Việt của hệ điều hành; máy không có giọng thì phát tiếng bíp.
- [x] Lời Cỗ Máy theo diễn biến trận: câu dựng sẵn; tuỳ chọn gọi Claude (Messages API, cần `ANTHROPIC_API_KEY`),
      không chờ, lỗi thì dùng câu dựng sẵn.

## Giai đoạn 6 — Đóng gói

- [x] Export Windows / macOS / Linux bằng GitHub Actions, gắn vào Release (`.github/workflows/release.yml`, chạy khi đẩy tag `v*`).
      Bản macOS ký ad-hoc, chưa notarize.
- [x] Màn cài đặt: âm lượng, độ phân giải, toàn màn hình, bật/tắt máu me, rung camera, giọng đọc, lời bình LLM.
- [ ] Trang itch.io hoặc Steam — **cần tài khoản của chủ dự án**. Đã có bản nháp nội dung `docs/STORE_PAGE.md`
      và bước đẩy bản build lên itch.io bằng butler (bật khi có secret `BUTLER_API_KEY`).

## Rủi ro

| Rủi ro | Cách giảm |
|---|---|
| Đồng bộ mạng cho game vật lý nhiều va chạm rất khó | Host quyết định hết; xác vật lý và máu me phía khách chỉ để hiển thị |
| Game không vui với người thật | Chơi thử 4 người trên một máy trước khi đầu tư thêm (giai đoạn 2, 3 còn mở) |
| Giống Machine Party quá mức | Giữ nhân vật, cửa và bối cảnh riêng; không dùng tên hay tài sản của họ |
| Jolt chưa ổn định trên 4.4.1 | Dùng GodotPhysics3D; code không phụ thuộc engine |
| Làm một mình, phạm vi phình to | Mỗi giai đoạn có mốc "xong khi"; cắt giai đoạn 5 nếu thiếu thời gian |

## Việc tiếp theo

1. Chơi thử 4 người trên một máy, rồi qua mạng LAN; ghi lại cửa nào chán, điều khiển nào khó.
2. Quyết định Steam hay itch.io → làm Steam lobby hoặc relay, tạo trang cửa hàng, chọn giấy phép.
3. Model nhân vật có xương và bake ánh sáng khi đã chốt hình ảnh.
