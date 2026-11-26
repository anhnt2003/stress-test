class_name Cli
## Đọc tham số dòng lệnh (sau dấu `--`).
##   --shot=PATH       chụp ảnh màn hình rồi thoát (không màn hình thì chỉ chạy mô phỏng)
##   --phase=SEC       chạy trước SEC giây mô phỏng trước khi chụp
##   --door=N          vào thẳng cửa N (1..10)
##   --match           chạy cả trận từ cửa 1 bằng bot
##   --lobby / --menu  chụp sảnh / menu chính
##   --closeup         camera cận cảnh 4 đối tượng
##   --seed=N          đổi seed của trận (mặc định cố định để smoke test lặp lại được)
##   --no-sabotage     tắt nút chơi xấu (bot không dùng)
##   --host[=PORT]     mở phòng mạng ngay khi chạy;  --join=ADDR  vào phòng (mã phòng hoặc IP[:cổng])
##   --name=TÊN        tên người chơi khi vào phòng
##   --autostart=SEC   (máy chủ) tự bắt đầu trận sau SEC giây — dùng cho kiểm thử mạng
##   --quit-after=SEC  tự thoát sau SEC giây thời gian thực
##   --net-lag=MS      giả lập độ trễ mạng phía máy khách (kiểm thử nội suy)
##   --balance=N       chạy N trận bằng bot với seed khác nhau, in thống kê số lần chết từng cửa


static func parse(args: PackedStringArray) -> Dictionary:
	var o := {"shot": "", "phase": 0.0, "door": -1, "match": false, "lobby": false, "menu": false, "closeup": false,
		"seed": 0, "sabotage": true, "host": -1, "join": "", "name": "", "autostart": -1.0, "quit_after": -1.0,
		"net_lag": 0, "balance": 0}
	for a in args:
		var kv := a.split("=", true, 1)
		var k := kv[0]
		var v := kv[1] if kv.size() > 1 else ""
		match k:
			"--shot": o.shot = v
			"--phase": o.phase = float(v)
			"--door": o.door = clampi(int(v) - 1, 0, 9)
			"--match": o.match = true
			"--lobby": o.lobby = true
			"--menu": o.menu = true
			"--closeup": o.closeup = true
			"--seed": o.seed = int(v)
			"--no-sabotage": o.sabotage = false
			"--host": o.host = int(v) if v != "" else NetSession.DEFAULT_PORT
			"--join": o.join = v
			"--name": o.name = v
			"--autostart": o.autostart = float(v)
			"--quit-after": o.quit_after = float(v)
			"--net-lag": o.net_lag = int(v)
			"--balance": o.balance = int(v)
	return o
