class_name OnlineLink
extends Node
## Chơi online qua WebRTC: kết nối WebSocket tới máy chủ mai mối (signaling/, Cloudflare Worker) chỉ để trao đổi
## lời mời / trả lời / ICE giữa chủ phòng (peer 1) và người vào phòng. Dữ liệu trận đấu đi thẳng giữa các máy
## qua WebRTCMultiplayerPeer, nên NetSession dùng lại toàn bộ RPC như khi chơi LAN bằng ENet.
## Bản web dùng WebRTC có sẵn của trình duyệt; bản desktop cần plugin webrtc-native (tools/fetch_webrtc.sh).

## Kênh 1 (input, ảnh chụp) không tin cậy, có thứ tự — giống kênh 1 của ENet mà các RPC đang dùng.
const CHANNELS := [MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED]
const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const CODE_LEN := 6
const CONNECT_TIMEOUT := 10.0   # mở WebSocket tới máy chủ mai mối
const JOIN_TIMEOUT := 25.0      # người vào: từ lúc có id tới lúc nối WebRTC xong
const PENDING_TIMEOUT := 30.0   # chủ phòng: kết nối WebRTC chưa xong sau ngần này thì bỏ
const DEFAULT_ICE := [{"urls": ["stun:stun.cloudflare.com:3478", "stun:stun.l.google.com:19302"]}]

## Chủ phòng: máy chủ mai mối đã cấp mã phòng (cả khi nối lại sau lúc mất mạng).
signal room_ready(code: String)
## Người vào: đã tạo WebRTCMultiplayerPeer với id của mình, có thể gắn vào SceneMultiplayer.
signal client_ready
## Thông báo trạng thái (mất kết nối mai mối, đang nối lại...).
signal note(text: String)
## Lỗi không tự phục hồi được (người vào: rời phòng; chủ phòng chưa có mã: đóng phòng).
signal failed(reason: String)

var role := ""
var url := ""
var code := ""
var secret := ""
var rtc: WebRTCMultiplayerPeer
var ice: Array = DEFAULT_ICE
var max_peers := 6
## peer id -> {"pc": WebRTCPeerConnection, "t": thời điểm tạo}
var conns := {}
var my_id := 0

var _ws: WebSocketPeer
var _ws_state := WebSocketPeer.STATE_CLOSED
var _t := 0.0
var _opened_at := 0.0
var _id_at := 0.0
var _retry_at := -1.0
var _retry_wait := 2.0
var _done := false
var _failed := false


## Có dùng được WebRTC không: trình duyệt luôn có; desktop cần plugin webrtc-native.
static func available() -> bool:
	return OS.has_feature("web") or ClassDB.class_exists("WebRTCLibPeerConnection")


## Mã phòng online người chơi gõ: bỏ gạch / khoảng trắng, chữ hoa, O→0, I/L→1. "" nếu không phải mã online.
static func normalize_code(text: String) -> String:
	var t := text.strip_edges().to_upper().replace("-", "").replace(" ", "")
	t = t.replace("O", "0").replace("I", "1").replace("L", "1")
	if t.length() != CODE_LEN:
		return ""
	for ch in t:
		if not ALPHABET.contains(ch):
			return ""
	return t


## Mã hiển thị: K7Q-2MX.
static func pretty(c: String) -> String:
	return "%s-%s" % [c.substr(0, 3), c.substr(3)] if c.length() == CODE_LEN else c


static func reason_text(r: String, c := "") -> String:
	match r:
		"no_room": return "KHÔNG CÓ PHÒNG NÀO MÃ %s." % pretty(c)
		"host_away": return "CHỦ PHÒNG ĐÃ ĐÓNG PHÒNG HOẶC MẤT KẾT NỐI."
		"busy": return "PHÒNG ĐANG CÓ NHIỀU NGƯỜI VÀO CÙNG LÚC. THỬ LẠI SAU ÍT GIÂY."
		"bad_secret": return "PHÒNG ONLINE ĐÃ BỊ THAY THẾ."
	return "MÁY CHỦ MAI MỐI TỪ CHỐI (%s)." % r


func start_host(signal_url: String, peer: WebRTCMultiplayerPeer) -> int:
	role = "host"
	url = signal_url
	rtc = peer
	return _open("%s?role=host" % url)


func start_join(signal_url: String, room: String, peer: WebRTCMultiplayerPeer) -> int:
	role = "join"
	url = signal_url
	code = room
	rtc = peer
	return _open("%s?role=join&code=%s" % [url, code])


func stop() -> void:
	_done = true
	if _ws:
		_ws.close(1000, "bye")
	conns.clear()


func is_connected_to_host() -> bool:
	return role == "join" and rtc != null and rtc.has_peer(1) and bool(rtc.get_peer(1).get("connected", false))


func _open(full: String) -> int:
	_ws = WebSocketPeer.new()
	_ws_state = WebSocketPeer.STATE_CONNECTING
	_opened_at = _t
	var err := _ws.connect_to_url(full)
	if err != OK:
		_ws_state = WebSocketPeer.STATE_CLOSED
	return err


func _process(dt: float) -> void:
	_t += dt
	if _ws:
		_ws.poll()
		var st := _ws.get_ready_state()
		while _ws.get_available_packet_count() > 0:
			_on_text(_ws.get_packet().get_string_from_utf8())
		if st == WebSocketPeer.STATE_CONNECTING and _t - _opened_at > CONNECT_TIMEOUT:
			_ws.close()
			st = WebSocketPeer.STATE_CLOSED
		if st == WebSocketPeer.STATE_CLOSED and _ws_state != WebSocketPeer.STATE_CLOSED:
			_ws_state = st
			_on_ws_closed()
		_ws_state = st
	if _retry_at >= 0.0 and _t >= _retry_at:
		_retry_at = -1.0
		_open("%s?role=host&code=%s&secret=%s" % [url, code, secret.uri_encode()])
	_check_peers()


func _on_ws_closed() -> void:
	if _done or _failed:
		return
	# máy chủ mai mối báo lỗi rồi đóng ngay: gói lỗi có thể không kịp đọc, lý do nằm trong mã đóng 4001
	if _ws.get_close_code() == 4001 and _ws.get_close_reason() != "":
		if role == "host" and code != "":
			note.emit(reason_text(_ws.get_close_reason(), code))   # mất phòng (hết hạn...): người đã vào chơi tiếp
			_done = true
		else:
			_fail(reason_text(_ws.get_close_reason(), code))
		return
	if role == "join":
		if not is_connected_to_host():
			_fail("KHÔNG KẾT NỐI ĐƯỢC MÁY CHỦ MAI MỐI.")
	elif code == "":
		_fail("KHÔNG KẾT NỐI ĐƯỢC MÁY CHỦ MAI MỐI. KIỂM TRA MẠNG RỒI THỬ LẠI.")
	else:
		# trận vẫn chạy với người đã vào; chỉ người mới tạm thời chưa vào được
		note.emit("MẤT KẾT NỐI MÁY CHỦ MAI MỐI, ĐANG NỐI LẠI...")
		_retry_at = _t + _retry_wait
		_retry_wait = minf(_retry_wait * 2.0, 30.0)


func _fail(reason: String) -> void:
	if _failed:
		return
	_failed = true
	if _ws:
		_ws.close()
	failed.emit(reason)


func _send(d: Dictionary) -> void:
	if _ws and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(d))


func _on_text(s: String) -> void:
	var msg = JSON.parse_string(s)
	if not msg is Dictionary:
		return
	var from := int(msg.get("from", 0))
	match String(msg.get("t", "")):
		"room":
			if role != "host":
				return
			code = String(msg.get("code", ""))
			secret = String(msg.get("secret", ""))
			_set_ice(msg.get("ice"))
			_retry_wait = 2.0
			room_ready.emit(code)
		"id":
			if role != "join" or my_id != 0:
				return
			my_id = int(msg.get("id", 0))
			_set_ice(msg.get("ice"))
			if my_id < 2 or rtc.create_client(my_id, CHANNELS) != OK:
				_fail("KHÔNG KHỞI TẠO ĐƯỢC KẾT NỐI WEBRTC.")
				return
			_id_at = _t
			client_ready.emit()
		"peer":
			if role == "host":
				_host_add(int(msg.get("id", 0)))
		"offer":
			if role == "join" and from == 1 and not conns.has(1):
				var pc := _new_pc(1)
				if pc:
					rtc.add_peer(pc, 1)
					pc.set_remote_description("offer", String(msg.get("sdp", "")))   # tự tạo answer
		"answer":
			if role == "host" and conns.has(from):
				(conns[from].pc as WebRTCPeerConnection).set_remote_description("answer", String(msg.get("sdp", "")))
		"cand":
			if conns.has(from):
				(conns[from].pc as WebRTCPeerConnection).add_ice_candidate(String(msg.get("mid", "")), int(msg.get("idx", 0)), String(msg.get("c", "")))
		"gone":
			if role == "host":
				_drop_pending(int(msg.get("id", 0)))
		"bye":
			if role == "join" and from == 1:
				_fail(String(msg.get("r", "CHỦ PHÒNG TỪ CHỐI.")).substr(0, 120))
		"error":
			var r := String(msg.get("r", ""))
			if role == "host" and code != "":
				note.emit(reason_text(r, code))   # mất phòng: người đã vào vẫn chơi tiếp
				_done = true
			else:
				_fail(reason_text(r, code))


func _set_ice(v) -> void:
	if v is Array and not (v as Array).is_empty():
		ice = v


func _host_add(id: int) -> void:
	if id < 2 or conns.has(id) or rtc.has_peer(id):
		return
	if conns.size() >= max_peers:
		_send({"t": "bye", "to": id, "r": "PHÒNG ĐÃ ĐỦ NGƯỜI."})
		return
	var pc := _new_pc(id)
	if pc == null:
		return
	rtc.add_peer(pc, id)
	pc.create_offer()


func _new_pc(id: int) -> WebRTCPeerConnection:
	var pc := WebRTCPeerConnection.new()
	if pc.initialize({"iceServers": ice}) != OK:
		if role == "join":
			_fail("KHÔNG KHỞI TẠO ĐƯỢC KẾT NỐI WEBRTC.")
		return null
	pc.session_description_created.connect(_on_sdp.bind(id))
	pc.ice_candidate_created.connect(_on_cand.bind(id))
	conns[id] = {"pc": pc, "t": _t}
	return pc


func _on_sdp(type: String, sdp: String, id: int) -> void:
	if not conns.has(id):
		return
	(conns[id].pc as WebRTCPeerConnection).set_local_description(type, sdp)
	_send({"t": type, "to": id, "sdp": sdp})


func _on_cand(mid: String, idx: int, cand: String, id: int) -> void:
	if conns.has(id):
		_send({"t": "cand", "to": id, "mid": mid, "idx": idx, "c": cand})


func _drop_pending(id: int) -> void:
	if not conns.has(id):
		return
	if rtc.has_peer(id) and bool(rtc.get_peer(id).get("connected", false)):
		return   # người đó đóng WebSocket sau khi đã nối WebRTC xong: bình thường
	conns.erase(id)
	if rtc.has_peer(id):
		rtc.remove_peer(id)


func _check_peers() -> void:
	if rtc == null:
		return
	if role == "join":
		if _done or _failed or my_id == 0:
			return
		if is_connected_to_host():
			_done = true
			_ws.close(1000, "connected")   # không cần máy chủ mai mối nữa
			return
		var pc: WebRTCPeerConnection = conns[1].pc if conns.has(1) else null
		if (pc and pc.get_connection_state() == WebRTCPeerConnection.STATE_FAILED) or _t - _id_at > JOIN_TIMEOUT:
			_fail("KHÔNG NỐI ĐƯỢC TỚI CHỦ PHÒNG: MẠNG CỦA MỘT TRONG HAI BÊN CHẶN KẾT NỐI TRỰC TIẾP.")
		return
	for id in conns.keys():
		if not rtc.has_peer(id):
			conns.erase(id)   # đã rời (WebRTCMultiplayerPeer tự bỏ peer mất kết nối)
			continue
		if bool(rtc.get_peer(id).get("connected", false)):
			continue
		var pc: WebRTCPeerConnection = conns[id].pc
		if pc.get_connection_state() == WebRTCPeerConnection.STATE_FAILED or _t - float(conns[id].t) > PENDING_TIMEOUT:
			conns.erase(id)
			rtc.remove_peer(id)
