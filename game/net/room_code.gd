class_name RoomCode
## Mã phòng: mã hoá địa chỉ IPv4 + cổng của máy chủ thành 10 ký tự (bảng chữ Crockford base32, bỏ I L O U
## để khỏi đọc nhầm), dạng XXXXX-XXXXX. Không cần máy chủ trung gian; chơi khác mạng thì máy chủ cần mở cổng
## UDP hoặc mọi người cùng vào một VPN LAN (Tailscale, ZeroTier).

const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"


static func encode(ip: String, port: int) -> String:
	var parts := ip.split(".")
	if parts.size() != 4 or port < 1 or port > 65535:
		return ""
	var v := 0
	for p in parts:
		if not p.is_valid_int() or int(p) < 0 or int(p) > 255:
			return ""
		v = (v << 8) | int(p)
	v = (v << 16) | port
	var out := ""
	for i in 10:
		out = ALPHABET[v & 31] + out
		v >>= 5
	return out.substr(0, 5) + "-" + out.substr(5)


## Giải mã. Trả về {"ip": String, "port": int}, hoặc {} nếu mã sai.
static func decode(code: String) -> Dictionary:
	var c := code.strip_edges().to_upper().replace("-", "").replace(" ", "")
	c = c.replace("O", "0").replace("I", "1").replace("L", "1")
	if c.length() != 10:
		return {}
	var v := 0
	for ch in c:
		var d := ALPHABET.find(ch)
		if d < 0:
			return {}
		v = (v << 5) | d
	var port := v & 0xffff
	var ipv := (v >> 16) & 0xffffffff
	if port == 0:
		return {}
	return {"ip": "%d.%d.%d.%d" % [(ipv >> 24) & 255, (ipv >> 16) & 255, (ipv >> 8) & 255, ipv & 255], "port": port}


## Đọc ô nhập của người chơi: mã phòng, "IP", hoặc "IP:cổng". Trả về {} nếu không hợp lệ.
static func parse_address(text: String, default_port: int) -> Dictionary:
	var t := text.strip_edges()
	if t == "":
		return {}
	if t.count(".") == 3 or t.get_slice(":", 0) == "localhost":
		var host := t
		var port := default_port
		if t.contains(":"):
			host = t.get_slice(":", 0)
			var ps := t.get_slice(":", 1)
			if not ps.is_valid_int():
				return {}
			port = int(ps)
		if host == "localhost":
			host = "127.0.0.1"
		if port < 1 or port > 65535 or encode(host, port) == "":
			return {}
		return {"ip": host, "port": port}
	return decode(t)


## Địa chỉ IPv4 trong mạng LAN của máy này (ưu tiên 192.168.x, 10.x, 172.16–31.x, rồi 100.64/10 của Tailscale).
static func local_ipv4() -> String:
	var best := ""
	var best_rank := 99
	for a in IP.get_local_addresses():
		if a.count(".") != 3 or a.begins_with("127.") or a.begins_with("169.254."):
			continue
		var p := a.split(".")
		var rank := 5
		if a.begins_with("192.168."):
			rank = 0
		elif a.begins_with("10."):
			rank = 1
		elif p[0] == "172" and int(p[1]) >= 16 and int(p[1]) <= 31:
			rank = 2
		elif p[0] == "100" and int(p[1]) >= 64 and int(p[1]) <= 127:
			rank = 3
		if rank < best_rank:
			best_rank = rank
			best = a
	return best if best != "" else "127.0.0.1"
