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


## Tên card mạng ảo / máy ảo / container / đường hầm: địa chỉ của chúng không ai ở máy khác vào được.
const VIRTUAL_HINTS := ["bridge", "vbox", "virtualbox", "vmnet", "vmware", "docker", "veth", "virbr", "vethernet",
	"hyper-v", "default switch", "br-", "lxc", "lxd", "llw", "awdl", "anpi", "ap1", "lo", "gif", "stf", "p2p"]
## Tên VPN LAN dùng để chơi khác mạng (vẫn hợp lệ, nhưng xếp sau LAN thật).
const VPN_HINTS := ["tailscale", "zerotier", "zt", "utun", "wg", "tun", "tap"]


static func _is_private(a: String) -> bool:
	var p := a.split(".")
	return a.begins_with("192.168.") or a.begins_with("10.") or (p[0] == "172" and int(p[1]) >= 16 and int(p[1]) <= 31)


static func _is_cgnat(a: String) -> bool:   # 100.64.0.0/10: Tailscale
	var p := a.split(".")
	return p[0] == "100" and int(p[1]) >= 64 and int(p[1]) <= 127


static func _name_has(name: String, hints: Array) -> bool:
	var n := name.to_lower()
	for h in hints:
		if n.begins_with(h) or (h.length() > 3 and n.contains(h)):
			return true
	return false


## Xếp hạng địa chỉ IPv4 của các card mạng (dữ liệu dạng IP.get_local_interfaces()). Trả về danh sách
## tốt nhất trước: LAN thật (Wi-Fi / Ethernet) → VPN LAN → các địa chỉ khác; card ảo chỉ dùng khi không còn gì.
static func rank_candidates(ifaces: Array) -> Array[String]:
	var scored: Array = []
	for it in ifaces:
		var nm := "%s %s" % [String(it.get("name", "")), String(it.get("friendly", ""))]
		for a in it.get("addresses", []):
			var ip := String(a)
			if ip.count(".") != 3 or ip.begins_with("127.") or ip.begins_with("169.254."):
				continue
			if ip.ends_with(".0") or ip.ends_with(".255"):
				continue   # địa chỉ mạng / broadcast, không phải địa chỉ máy
			var rank := 4
			if _name_has(nm, VIRTUAL_HINTS):
				rank = 9
			elif _is_cgnat(ip) or _name_has(nm, VPN_HINTS):
				rank = 2
			elif _is_private(ip):
				rank = 0 if ip.begins_with("192.168.") or ip.begins_with("10.") else 1
			scored.append([rank, ip])
	scored.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and String(x[1]) < String(y[1])))
	var out: Array[String] = []
	for e in scored:
		if not out.has(String(e[1])):
			out.append(String(e[1]))
	return out


## Các địa chỉ IPv4 người khác có thể dùng để vào phòng, tốt nhất trước.
static func candidates() -> Array[String]:
	return rank_candidates(IP.get_local_interfaces())


## Địa chỉ IPv4 trong mạng LAN của máy này (dùng để tạo mã phòng).
static func local_ipv4() -> String:
	var c := candidates()
	return c[0] if c.size() > 0 else "127.0.0.1"
