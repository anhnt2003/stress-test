# Stress Test — party game kinh dị 10 cửa (Godot 4.4)

3–4 "đối tượng thử nghiệm" đi qua 10 cửa máy móc chết người. Chết thì đối tượng thay thế được thả xuống,
nhưng bị tính một lần chết. Hết 10 cửa, Cỗ Máy giữ lại một người. Có cảnh máu me (tắt được trong Cài đặt).

## Chạy
1. Tải Godot 4.4.1 trở lên (bản Standard) tại https://godotengine.org/download
2. Mở Godot → Import → chọn `project.godot` → bấm F5.
3. Hoặc tải bản build sẵn ở mục Releases (Windows / macOS / Linux).
   macOS: bản build chưa ký với Apple, lần đầu mở bằng chuột phải → Open.

## Chơi
- **Chơi chung một máy**: tối đa 4 người (2 bàn phím + tay cầm), ghế trống do bot ngồi.
- **Tạo phòng qua mạng**: sảnh hiện mã phòng 10 ký tự (mã hoá IP + cổng). Người khác chọn **Vào phòng**, nhập mã.
  Cùng mạng LAN thì vào được ngay; khác mạng thì máy chủ mở cổng UDP 24555 hoặc mọi người vào chung một VPN LAN
  (Tailscale, ZeroTier). Ghế người rớt mạng do bot ngồi thay; vào lại từ cùng máy thì lấy lại ghế, kể cả giữa trận.

| Thiết bị | Di chuyển | Nhảy | Đẩy | Chơi xấu |
|---|---|---|---|---|
| Bàn phím 1 | WASD | Space | F | G |
| Bàn phím 2 | Phím mũi tên | `.` | `/` | `,` |
| Tay cầm (1–4) | Cần trái / D-pad | A | X hoặc B | Y |

- Sảnh: bấm nút nhảy để vào ghế / rời ghế; trái–phải đổi mũ (8 kiểu), lên–xuống đổi màu áo (8 màu);
  TAB / Y bật tắt nút chơi xấu; Enter / Start bắt đầu; Esc về menu.
- Trong trận: Esc / Start tạm dừng (chơi tiếp, chơi lại từ cửa 1, cài đặt, về sảnh, về menu chính).
- **Đẩy**: xô người đứng trước mặt văng ra khoảng 2 mét, hồi chiêu 1,3 giây.
- **Chơi xấu**: mỗi người một lần mỗi cửa, mỗi cửa một kiểu (máy ép dập sớm, phóng điện dưới chân đối thủ,
  tay cưa tăng tốc, băng chuyền tăng tốc, cướp 3×3 ô, thả tạ lên đầu người gần nhất, làm nứt sàn quanh mình,
  dời vùng sáng, ném lõi nổ, co vùng an toàn).
- Phím gỡ lỗi (chỉ máy chủ / chơi một máy): F1–F10 nhảy tới cửa 1–10, F12 kết thúc cửa hiện tại.

## Một trận
10 cửa nối tiếp, mỗi cửa 30 giây. Buồng thử đổi giữa 3 biến thể (buồng 09 đèn dây tóc, buồng 13 đèn huỳnh quang,
buồng 21 đèn khẩn cấp).

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
- Sau mỗi cửa: xếp hạng theo số lần chết (ít hơn xếp trên); bằng nhau thì ai chết lần đầu muộn hơn xếp trên.
  Riêng Sàn cảm ứng xếp theo số ô chiếm được.
- Hạng 1 / 2 / 3 / 4 được +4 / +3 / +2 / +1 điểm; đồng hạng thì cùng điểm.
- Hết 10 cửa: bằng điểm thì ai chết ít hơn xếp trên. Hạng 1 "được giữ lại", những người còn lại bị "loại bỏ".

## Cài đặt
Âm lượng (chung, nhạc, hiệu ứng, giọng Cỗ Máy), rung camera, độ phân giải, toàn màn hình, bật/tắt máu me,
đọc lời Cỗ Máy bằng giọng tiếng Việt của hệ điều hành (không có giọng thì phát tiếng bíp), lời bình từ Claude.
Lưu ở `user://settings.cfg`.

Lời bình từ Claude (mặc định tắt): đặt biến môi trường `ANTHROPIC_API_KEY` rồi bật trong Cài đặt. Game gửi bảng điểm
ngắn gọn (số đối tượng, điểm, số lần chết) tới Messages API để xin một câu bình; không chờ, lỗi mạng hay bị từ chối
thì dùng câu dựng sẵn.

## Cấu trúc
```
main.gd            điểm vào: dựng các thành phần, đọc tham số dòng lệnh, vòng lặp chính (143 dòng)
game/flow.gd       điều phối màn: menu → sảnh → trận → tổng kết, tạm dừng, cài đặt, mạng
game/match/        match_manager.gd (máy trạng thái, luật chung), scoring.gd (hàm thuần), balance.gd
game/doors/        door_base.gd + 10 cửa, mỗi cửa một file (luật, bot, mặt sàn, chơi xấu, trạng thái mạng)
game/actors/       subject.tscn/.gd (CharacterBody3D), subject_model.gd (hình nhân, mũ), bot_brain.gd, ragdoll.gd
game/input/        input_source.gd + bàn phím / tay cầm / bot, seats.gd, input_router.gd
game/net/          net_session.gd (ENet, host-authoritative), room_code.gd, snapshot_buffer.gd, net_source.gd
game/world/        chamber_09/13/21.tscn (buồng thử, sửa trong editor), chamber.gd
game/ui/           hud, result_panel, intro_banner, lobby_panel, main_menu, pause_menu, settings_menu, join_dialog (.tscn)
game/fx/           gore.gd (máu me, RNG riêng), camera_fx.gd
game/audio/        game_audio.gd (bus Music / SFX / Voice)
game/machine/      machine_voice.gd (lời bình, TTS), machine_lines.gd (câu dựng sẵn), llm_client.gd
audio/             âm thanh tổng hợp bằng tools/gen_sfx.py (không dùng sample ngoài), có nhạc nền lặp
shaders/ fonts/    shader bề mặt bẩn, hậu kỳ sepia + dither; font Anton (OFL)
tests/             run_all.gd + test_*.gd
tools/             gen_sfx.py, migrate_scenes.gd (công cụ chuyển một lần từ code sang .tscn)
docs/              PLAN.md (kế hoạch, tiến độ), BALANCE.md, STORE_PAGE.md
```

## Lệnh cho người phát triển
```sh
godot --headless --path . --import                                   # import tài nguyên
godot --headless --path . --script res://tests/run_all.gd            # kiểm thử (thêm "-- net" để chạy một file)
godot --headless --fixed-fps 60 --path . -- --shot=/tmp/x.png --match --phase=400   # cả trận bằng bot
godot --headless --fixed-fps 60 --path . -- --balance=32             # thống kê cân bằng 10 cửa
godot --fixed-fps 60 --path . -- --shot=out.png --door=3 --phase=8   # chụp ảnh cửa 3 ở giây thứ 8
godot --path . -- --host --autostart=3                               # mở phòng, tự bắt đầu sau 3 giây
godot --path . -- --join=MÃ-PHÒNG --name=TÊN --net-lag=100           # vào phòng, giả lập trễ 100 ms
python3 tools/gen_sfx.py                                             # sinh lại âm thanh (cần numpy)
```
Mọi tham số: xem đầu file `game/core/cli.gd`. Chạy không màn hình nên thêm `--fixed-fps 60` (trước dấu `--`)
để mô phỏng chạy nhanh hơn thời gian thực.

Phát hành: đẩy tag `vX.Y.Z` → workflow `release.yml` xuất bản Windows / macOS / Linux và gắn vào GitHub Release;
có `BUTLER_API_KEY` (secret) và `ITCH_TARGET` (biến, dạng `user/game`) thì đẩy lên itch.io luôn.

## Giới hạn hiện tại
- Chưa chơi thử với người thật: điều khiển, cảm giác đẩy nhau, độ khó mới đo bằng bot (docs/BALANCE.md).
- Chơi khác mạng cần mở cổng hoặc VPN LAN; chưa có Steam lobby hay máy chủ relay.
- Hình nhân ghép từ khối cơ bản (chưa có model Blender có xương); ánh sáng chưa bake.
- Dùng GodotPhysics3D thay Jolt vì Jolt trên Godot 4.4.1 bị treo khi nhiều xác vật lý (xem docs/PLAN.md).
