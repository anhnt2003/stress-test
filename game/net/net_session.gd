class_name NetSession
extends Node
## Chơi qua mạng (High-level Multiplayer của Godot trên ENet), mô hình host-authoritative:
## - Máy chủ chạy toàn bộ luật chơi. Máy khách gửi input 30 lần/giây (kênh không tin cậy, có thứ tự),
##   nhận ảnh chụp trạng thái 20 lần/giây và nội suy vị trí; nhân vật của chính mình được dự đoán tại chỗ.
## - Sự kiện chết, thả người thay thế, điểm, chuyển cửa, lời Cỗ Máy gửi bằng RPC tin cậy.
## - Vào phòng bằng mã (RoomCode: IP + cổng) hoặc IP. Người rớt mạng thì bot ngồi thay; vào lại bằng cùng máy
##   (token trong cài đặt) thì lấy lại ghế, kể cả giữa trận.
## Nút này phải nằm ở cùng đường dẫn trên mọi máy (/root/Main/Net) để RPC tìm thấy nhau.

const DEFAULT_PORT := 24555
const MAX_CLIENTS := 3
## Slot ENet dư cho kết nối đang chờ: người vào lại khi kết nối cũ chưa bị phát hiện mất, hoặc người thừa
## cần nhận thông báo "phòng đầy" thay vì bị ENet bỏ qua. Ghế thật do c_hello quyết.
const EXTRA_SLOTS := 3
## Kết nối không gửi c_hello trong thời gian này thì bị ngắt (bản build lạ, kết nối treo).
const HELLO_TIMEOUT := 5.0
const SNAP_RATE := 20.0
const INPUT_RATE := 30.0
const INTERP_DELAY := 0.1
const PROTOCOL := "stress-test-net-2"
const MODES := ["", "crush", "grind", "halved", "burst", "headpop", "fry"]
const ACTIONS := ["jump", "shove", "sabotage"]
## Kết nối cũ cùng token im lặng quá lâu thì coi là đã chết (máy khách gửi input 30 lần/giây).
const STALE_AFTER := 1.5

signal status_changed(text: String)
signal left(reason: String)
## Máy khách vừa được máy chủ nhận vào phòng.
signal joined
## Máy chủ: người chơi mạng ở ghế `seat` muốn đổi mũ / màu áo.
signal remote_look(seat: int, dh: int, dc: int)


## Ghế hiển thị phía máy khách (chỉ để hiện nhãn, không điều khiển gì).
class RemoteSeat:
	extends InputSource
	var text := ""

	func _init(t := "") -> void:
		text = t

	func kind() -> String:
		return "remote"

	func label() -> String:
		return text


var mode := ""
var connected := false
var m: MatchManager
var settings: Settings
var peer: ENetMultiplayerPeer
var port := DEFAULT_PORT
var room_code := ""
var player_name := ""
## Giả lập độ trễ một chiều phía máy khách (giây), cho kiểm thử nội suy.
var net_lag := 0.0
## Máy khách tự kiểm tra kết nối rồi thoát (CI).
var autotest := false

# máy chủ
var peers := {}      # peer_id -> {"seat", "name", "token"}
var dropped := {}    # token -> ghế cũ (rớt mạng, chờ vào lại)
var _snap_acc := 0.0
var _links: Array = []
var _pending := {}   # peer_id -> thời điểm kết nối, chưa gửi c_hello
## Máy chủ đang tạm dừng (máy chủ: trạng thái của chính nó; máy khách: theo sự kiện từ máy chủ).
var host_paused := false
## Máy khách: menu đang mở thì không gửi hướng đi (phím dùng để chọn menu không được lái nhân vật).
var input_blocked := false   # [signal, callable] đã nối vào MatchManager

# máy khách
var my_seat := -1
var _bufs: Array[SnapshotBuffer] = []
var _clock := 0.0
var _offset := 0.0
var _have_offset := false
var _input_acc := 0.0
var _counts := [0, 0, 0]
var _lag_q: Array = []
var _local: Array[InputSource] = []
## Ghế bị đánh dấu chết theo ảnh chụp (không qua RPC chết): ảnh chụp sau báo sống thì hồi lại.
var _synced_dead := {}
var _saved_rules := {}
var snaps_received := 0
var loads_received := 0
var kills_received := 0
var _test := {}


func is_online() -> bool:
	return mode != ""


func is_host() -> bool:
	return mode == "host"


func is_client() -> bool:
	return mode == "client"


func room_text() -> String:
	if not is_host():
		return ""
	return "MÃ PHÒNG: %s   ·   IP %s:%d   ·   %d NGƯỜI QUA MẠNG" % [room_code, RoomCode.local_ipv4(), port, peers.size()]


# =====================================================================
#  Mở / vào / rời phòng
# =====================================================================
func host(p: int, match_: MatchManager, s: Settings) -> int:
	close()
	m = match_
	settings = s
	port = p
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(p, MAX_CLIENTS + EXTRA_SLOTS)
	if err != OK:
		peer = null
		return err
	# máy khách chỉ nói chuyện với máy chủ: tắt relay để máy chủ không tự phát thông báo vào / rời phòng
	# cho mọi kết nối (kể cả kết nối đang đóng → ENet báo lỗi gửi gói)
	(multiplayer as SceneMultiplayer).server_relay = false
	multiplayer.multiplayer_peer = peer
	mode = "host"
	connected = true
	_link(multiplayer.peer_disconnected, _on_peer_disconnected)
	_link(multiplayer.peer_connected, func(id): _pending[id] = Time.get_ticks_msec() / 1000.0)
	_link(m.door_loaded, _h_door_loaded)
	_link(m.killed, func(sj, md, dir, pos): _broadcast("s_kill", [sj.idx, md, dir, pos]))
	_link(m.respawned, func(sj): _broadcast("s_respawn", [sj.idx, sj.position, sj.yaw()]))
	_link(m.announced, func(text, dur): _broadcast("s_event", ["ann", [text, dur]]))
	_link(m.sfx_requested, func(n, v, pt): _broadcast("s_event", ["sfx", [n, v, pt]]))
	_link(m.shake_requested, func(a): _broadcast("s_event", ["shake", [a]]))
	_link(m.sabotaged, func(sj, hint): _broadcast("s_event", ["sab", [sj.idx, hint]]))
	_link(m.state_changed, func(st): _broadcast("s_state", [st]))
	_link(m.round_ended, func(rows): _broadcast("s_round", [rows, m.totals, m.total_deaths]))
	_link(m.match_ended, func(rows, best): _broadcast("s_final", [rows, best, m.totals, m.total_deaths]))
	room_code = RoomCode.encode(RoomCode.local_ipv4(), p)
	status_changed.emit("ĐÃ MỞ PHÒNG. MÃ PHÒNG: %s" % room_code)
	return OK


func join(address: String, nm: String, match_: MatchManager, s: Settings) -> int:
	close()
	var a := RoomCode.parse_address(address, DEFAULT_PORT)
	if a.is_empty():
		return ERR_INVALID_PARAMETER
	m = match_
	settings = s
	player_name = nm.substr(0, 16).to_upper()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(String(a.ip), int(a.port))
	if err != OK:
		peer = null
		return err
	(multiplayer as SceneMultiplayer).server_relay = false
	multiplayer.multiplayer_peer = peer
	mode = "client"
	connected = false
	my_seat = -1
	# máy chủ tạo NetSource mới với bộ đếm 0: bộ đếm phía này cũng phải về 0, không thì gói đầu bị coi là bấm nút
	_counts = [0, 0, 0]
	_input_acc = 0.0
	_test = {}
	host_paused = false
	# máy chủ sẽ ghi đè các luật này; giữ lại để khôi phục khi rời phòng
	_saved_rules = {"sab": m.sabotage_enabled, "seed": m.seed_base}
	snaps_received = 0
	loads_received = 0
	kills_received = 0
	m.remote = true
	_local = [KeyboardSource.new(1), KeyboardSource.new(2)]
	for d in 4:
		_local.append(PadSource.new(d))
	_link(multiplayer.connected_to_server, func(): rpc_id(1, "c_hello", player_name, s.token, PROTOCOL))
	_link(multiplayer.connection_failed, func(): _leave("KHÔNG KẾT NỐI ĐƯỢC TỚI %s:%d." % [a.ip, a.port]))
	_link(multiplayer.server_disconnected, func(): _leave("MÁY CHỦ ĐÃ ĐÓNG PHÒNG HOẶC MẤT KẾT NỐI."))
	status_changed.emit("ĐANG KẾT NỐI TỚI %s:%d..." % [a.ip, a.port])
	return OK


func close() -> void:
	for l in _links:
		var sig: Signal = l[0]
		if sig.is_connected(l[1]):
			sig.disconnect(l[1])
	_links.clear()
	if peer:
		peer.close()
	peer = null
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer = null
	if m:
		m.remote = false
		if not _saved_rules.is_empty():
			m.sabotage_enabled = bool(_saved_rules.sab)
			m.seed_base = int(_saved_rules.seed)
	_saved_rules = {}
	mode = ""
	connected = false
	peers.clear()
	dropped.clear()
	_pending.clear()
	_lag_q.clear()
	_bufs.clear()
	_have_offset = false
	my_seat = -1
	host_paused = false


func _leave(reason: String) -> void:
	print("NET rời phòng: ", reason)
	close()
	left.emit(reason)


func _ready() -> void:
	status_changed.connect(func(text): print("NET ", text))   # nhật ký cho máy chủ không màn hình


func _link(sig: Signal, c: Callable) -> void:
	sig.connect(c)
	_links.append([sig, c])


# =====================================================================
#  Máy chủ
# =====================================================================
@rpc("any_peer", "call_remote", "reliable")
func c_hello(nm: String, token: String, protocol: String) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	_pending.erase(id)
	if protocol != PROTOCOL:
		_reject(id, "MÁY CHỦ CHẠY PHIÊN BẢN KHÁC (%s)." % PROTOCOL)
		return
	if peers.has(id):
		rpc_id(id, "s_welcome", int(peers[id].seat))   # chào lại: không cấp thêm ghế
		return
	var now := Time.get_ticks_msec() / 1000.0
	var plan := plan_seat(m.seats, peers, dropped, token, now)
	var seat := int(plan.seat)
	if seat < 0:
		_reject(id, "PHÒNG ĐÃ ĐỦ 4 NGƯỜI.")
		return
	var old := int(plan.takeover)
	if old != 0:
		# cùng máy vào lại trước khi máy chủ nhận ra kết nối cũ đã chết: tiếp quản ghế, ngắt kết nối cũ
		peers.erase(old)
		_drop_peer(old)
	var clean := nm.strip_edges().substr(0, 16).to_upper()
	if clean == "":
		clean = "KHÁCH %d" % (seat + 1)
	dropped.erase(token)
	m.seats.assign(seat, NetSource.new(id, clean), clean)
	peers[id] = {"seat": seat, "name": clean, "token": token, "seen": now}
	rpc_id(id, "s_welcome", seat)
	_send_lobby()
	# đưa máy khách vào đúng cảnh đang chạy
	rpc_id(id, "s_load", -1 if m.state == MatchManager.ST_LOBBY else m.door_index, m.seed_base, m.totals, m.total_deaths)
	rpc_id(id, "s_state", m.state)
	if m.state == MatchManager.ST_RESULT:
		rpc_id(id, "s_round", m.last_rows, m.totals, m.total_deaths)
	elif m.state == MatchManager.ST_FINAL:
		rpc_id(id, "s_final", m.last_rows, m.best, m.totals, m.total_deaths)
	if host_paused:
		rpc_id(id, "s_event", "pause", [true])
	if m.state != MatchManager.ST_LOBBY:
		m.announce("%s VÀO THAY ĐỐI TƯỢNG %s." % [clean, m.seats.looks[seat].label])
	status_changed.emit("%s ĐÃ VÀO PHÒNG (ĐỐI TƯỢNG %s)." % [clean, m.seats.looks[seat].label])


## Gửi RPC tới mọi người đã vào phòng mà kết nối còn sống. Không phát cho cả SceneMultiplayer (rpc()) vì
## như vậy sẽ gửi cả cho kết nối đang chờ c_hello, đang bị từ chối hoặc đang rời đi (ENet báo lỗi gửi gói).
func _broadcast(method: String, args: Array) -> void:
	for id in peers:
		var pp := peer.get_peer(id) if peer else null
		if pp and pp.get_state() == ENetPacketPeer.STATE_CONNECTED:
			callv("rpc_id", [id, method] + args)


## Từ chối có thông báo, rồi ngắt sau một chút để thông báo kịp tới (máy khách cũng tự rời khi nhận).
func _reject(id: int, reason: String) -> void:
	rpc_id(id, "s_reject", reason)
	get_tree().create_timer(0.5).timeout.connect(func(): _drop_peer(id))


## Ngắt một peer qua SceneMultiplayer (bỏ khỏi danh sách peer, không còn bị gửi RPC).
func _drop_peer(id: int) -> void:
	if is_host() and multiplayer.get_peers().has(id):
		multiplayer.disconnect_peer(id)


## Chọn ghế cho người vừa vào. Trả về {"seat": ghế (-1 nếu đầy), "takeover": peer cũ cần ngắt (0 nếu không)}.
## Thứ tự: ghế của kết nối cũ cùng token đã im lặng quá STALE_AFTER giây (máy chủ chưa kịp phát hiện mất)
## → ghế cũ đang chờ vào lại → ghế bot đầu tiên. Kết nối cùng token mà vẫn đang gửi input (hai bản game
## trên cùng một máy dùng chung file cài đặt) thì không bị đá: người mới nhận ghế khác.
static func plan_seat(seats: Seats, peers_: Dictionary, dropped_: Dictionary, token: String, now: float) -> Dictionary:
	if token != "":
		for pid in peers_:
			var p: Dictionary = peers_[pid]
			if String(p.token) == token and now - float(p.get("seen", -INF)) > STALE_AFTER:
				return {"seat": int(p.seat), "takeover": int(pid)}
	return {"seat": assign_seat(seats, dropped_, token), "takeover": 0}


## Ghế cũ nếu đang chờ vào lại (và vẫn do bot ngồi), không thì ghế bot đầu tiên.
static func assign_seat(seats: Seats, dropped_: Dictionary, token: String) -> int:
	if dropped_.has(token):
		var old := int(dropped_[token])
		if old >= 0 and old < Seats.N and seats.is_bot(old):
			return old
	return seats.first_bot()


func _on_peer_disconnected(id: int) -> void:
	if not peers.has(id):
		return
	var info: Dictionary = peers[id]
	peers.erase(id)
	var seat := int(info.seat)
	var src := m.seats.source(seat)
	if src is NetSource and (src as NetSource).peer == id:
		m.seats.release(seat)
		dropped[String(info.token)] = seat
	if m.state != MatchManager.ST_LOBBY:
		m.announce("%s MẤT KẾT NỐI. MÁY ĐIỀU KHIỂN ĐỐI TƯỢNG %s." % [info.name, m.seats.looks[seat].label])
	status_changed.emit("%s ĐÃ RỜI PHÒNG." % info.name)
	_send_lobby()


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func c_input(mv: Vector2, counts: Array) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if not peers.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	peers[id].seen = now
	var src := m.seats.source(int(peers[id].seat))
	if src is NetSource and (src as NetSource).peer == id:
		(src as NetSource).receive(mv, counts, now)


@rpc("any_peer", "call_remote", "reliable")
func c_look(dh: int, dc: int) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if peers.has(id) and (m.state == MatchManager.ST_LOBBY or m.state == MatchManager.ST_FINAL):
		remote_look.emit(int(peers[id].seat), clampi(dh, -1, 1), clampi(dc, -1, 1))


func _h_door_loaded(i: int, _door: DoorBase) -> void:
	_broadcast("s_load", [i, m.seed_base, m.totals, m.total_deaths])
	_snap_acc = 1.0   # gửi ảnh chụp ngay khung sau


func _lobby_data() -> Dictionary:
	var labels := []
	var bots := []
	for i in Seats.N:
		var l := m.seats.label(i)
		if not m.seats.is_bot(i) and m.seats.names[i] == "":
			l += "  (MÁY CHỦ)"
		labels.append(l)
		bots.append(m.seats.is_bot(i))
	return {"looks": m.seats.looks, "labels": labels, "bots": bots, "names": m.seats.names, "sab": m.sabotage_enabled, "room": room_code}


func _send_lobby() -> void:
	if is_host():
		_broadcast("s_lobby", [_lobby_data()])


func broadcast_lobby() -> void:
	_send_lobby()


func notify_pause(paused: bool) -> void:
	if not is_host():
		return
	host_paused = paused
	if not paused:
		m.seats.clear_inputs()   # nút máy khách bấm trong lúc dừng không được nổ ra khi chơi tiếp
	_broadcast("s_event", ["pause", [paused]])


static func pack_flags(s: Subject) -> int:
	return int(s.ground) | int(s.moving) << 1 | int(s.scared) << 2 | int(s.shove_t > 0.0) << 3 | int(s.sabotage_used) << 4 \
		| int(s.stun > 0.0 or s.flat > 0.0 or s.knock.length() > 0.5) << 5


func snapshot() -> Dictionary:
	var subs := []
	for s in m.subjects:
		subs.append([s.position, s.yaw() if s.pivot else 0.0, pack_flags(s), s.deaths, s.score, s.doom, s.out, maxi(0, MODES.find(s.dead_mode))])
	return {"t": m.t, "lt": m.lt, "stt": m.state_t, "d": -1 if m.state == MatchManager.ST_LOBBY else m.door_index,
		"s": subs, "x": m.door.net_state() if m.door else {}}


func host_step(dt: float) -> void:
	if not is_host():
		return
	var now := Time.get_ticks_msec() / 1000.0
	for id in _pending.keys():
		if now - float(_pending[id]) > HELLO_TIMEOUT:
			_pending.erase(id)
			_drop_peer(id)
	if peers.is_empty():
		return
	_snap_acc += dt
	if _snap_acc >= 1.0 / SNAP_RATE:
		_snap_acc = 0.0
		_broadcast("s_snap", [snapshot()])


# =====================================================================
#  Máy khách: nhận từ máy chủ
# =====================================================================
func _recv(c: Callable) -> void:
	if net_lag > 0.0:
		_lag_q.append([_clock + net_lag, c])
	else:
		c.call()


@rpc("authority", "call_remote", "reliable")
func s_welcome(seat: int) -> void:
	var first := not connected
	my_seat = seat
	connected = true
	if first:
		joined.emit()
	status_changed.emit("ĐÃ VÀO PHÒNG. BẠN LÀ ĐỐI TƯỢNG %02d." % (seat + 1))


@rpc("authority", "call_remote", "reliable")
func s_reject(reason: String) -> void:
	_leave(reason)


@rpc("authority", "call_remote", "reliable")
func s_lobby(data: Dictionary) -> void:
	_recv(func(): _apply_lobby(data))


func _apply_lobby(data: Dictionary) -> void:
	var looks: Array = data.get("looks", [])
	var labels: Array = data.get("labels", [])
	var bots: Array = data.get("bots", [])
	var names: Array = data.get("names", [])
	for i in mini(Seats.N, looks.size()):
		var changed := str(m.seats.looks[i]) != str(looks[i])
		m.seats.looks[i] = looks[i]
		m.seats.sources[i] = BotSource.new() if bool(bots[i]) else RemoteSeat.new(String(labels[i]) + ("  ← BẠN" if i == my_seat else ""))
		m.seats.names[i] = String(names[i]) if i < names.size() else ""
		if changed and m.state == MatchManager.ST_LOBBY and m.door and m.door.has_method("refresh_look") and i < m.subjects.size():
			m.door.refresh_look(i)
	m.sabotage_enabled = bool(data.get("sab", true))
	room_code = String(data.get("room", ""))


@rpc("authority", "call_remote", "reliable")
func s_load(i: int, seed_base: int, totals: Array, deaths: Array) -> void:
	_recv(func(): _apply_load(i, seed_base, totals, deaths))


func _apply_load(i: int, seed_base: int, totals: Array, deaths: Array) -> void:
	loads_received += 1
	m.seed_base = seed_base
	if i < 0:
		m.load_lobby()
	else:
		m.load_door(i, true)
	m.totals = totals.duplicate()
	m.total_deaths = deaths.duplicate()
	_bufs.clear()
	_synced_dead.clear()
	for k in Seats.N:
		_bufs.append(SnapshotBuffer.new())
	for s in m.subjects:
		s.puppet = true
		s.set_solid(false)


@rpc("authority", "call_remote", "reliable")
func s_state(st: int) -> void:
	_recv(func():
		if st != m.state:
			m._set_state(st))


@rpc("authority", "call_remote", "reliable")
func s_kill(idx: int, md: String, dir: Vector3, pos: Vector3) -> void:
	_recv(func():
		kills_received += 1
		_synced_dead.erase(idx)
		if idx >= 0 and idx < m.subjects.size():
			m.kill_fx(m.subjects[idx], md, dir, pos))


@rpc("authority", "call_remote", "reliable")
func s_respawn(idx: int, pos: Vector3, yaw: float) -> void:
	_recv(func():
		_synced_dead.erase(idx)
		if idx >= 0 and idx < m.subjects.size():
			var s := m.subjects[idx]
			m.respawn_fx(s, pos, yaw)
			s.puppet = true
			s.set_solid(false)
			if idx < _bufs.size():
				_bufs[idx].clear())


@rpc("authority", "call_remote", "reliable")
func s_event(kind: String, args: Array) -> void:
	_recv(func(): _apply_event(kind, args))


func _apply_event(kind: String, args: Array) -> void:
	match kind:
		"ann":
			m.announced.emit(String(args[0]), float(args[1]))
		"sfx":
			m.sfx_requested.emit(String(args[0]), float(args[1]), float(args[2]))
		"shake":
			m.shake_requested.emit(float(args[0]))
		"sab":
			var idx := int(args[0])
			if idx < m.subjects.size():
				m.subjects[idx].sabotage_used = true
				m.sabotaged.emit(m.subjects[idx], String(args[1]))
		"pause":
			host_paused = bool(args[0])
			if not host_paused:
				_have_offset = false   # đồng hồ máy chủ đã đứng trong lúc dừng: lấy lại mốc ở ảnh chụp kế
			status_changed.emit("MÁY CHỦ ĐÃ TẠM DỪNG." if host_paused else "MÁY CHỦ CHƠI TIẾP.")


@rpc("authority", "call_remote", "reliable")
func s_round(rows: Array, totals: Array, deaths: Array) -> void:
	_recv(func():
		m.last_rows = rows
		m.totals = totals.duplicate()
		m.total_deaths = deaths.duplicate()
		m.round_ended.emit(rows))


@rpc("authority", "call_remote", "reliable")
func s_final(rows: Array, best: int, totals: Array, deaths: Array) -> void:
	_recv(func():
		m.last_rows = rows
		m.totals = totals.duplicate()
		m.total_deaths = deaths.duplicate()
		m.match_ended.emit(rows, best))


@rpc("authority", "call_remote", "unreliable_ordered", 1)
func s_snap(d: Dictionary) -> void:
	_recv(func(): _apply_snap(d))


func _apply_snap(d: Dictionary) -> void:
	if m.door == null or _bufs.size() < Seats.N:
		return
	var cur := -1 if m.state == MatchManager.ST_LOBBY or m.door.id < 0 else m.door_index
	if int(d.get("d", -2)) != cur:
		return   # ảnh chụp của cảnh cũ / cảnh mới chưa nạp xong
	snaps_received += 1
	var ht := float(d.t)
	var target := ht - _clock
	if not _have_offset or absf(target - _offset) > 1.0:
		_offset = target
		_have_offset = true
	else:
		_offset = lerpf(_offset, target, 0.05)
	m.lt = float(d.lt)
	m.state_t = float(d.stt)
	var subs: Array = d.s
	for i in mini(subs.size(), m.subjects.size()):
		var e: Array = subs[i]
		var s := m.subjects[i]
		_bufs[i].push(ht, e[0], float(e[1]))
		var f := int(e[2])
		s.ground = f & 1 != 0
		s.moving = f & 2 != 0
		s.scared = f & 4 != 0
		s.shove_t = 0.25 if f & 8 != 0 else 0.0
		s.sabotage_used = f & 16 != 0
		s.stun = 0.1 if f & 32 != 0 else 0.0   # máy khách chỉ dùng để tạm dừng dự đoán
		s.deaths = int(e[3])
		s.score = int(e[4])
		s.doom = float(e[5])
		if e.size() > 7:
			if float(e[6]) <= 0.0 and _synced_dead.has(i) and s.out > 0.0:
				_unsync_dead(s)   # ảnh chụp cũ (đến sau lệnh thả người) đã làm nó "chết" nhầm
			else:
				_sync_dead(s, float(e[6]), int(e[7]))
	m.door.apply_net_state(d.get("x", {}))
	if m.state != MatchManager.ST_PLAY:
		m.door.client_tick(0.0)   # chỉ dựng tư thế (người vào lúc chấm điểm thấy đúng sàn vỡ, máy ép...)


## Người vào giữa trận đã lỡ sự kiện chết (RPC chỉ gửi một lần): máy chủ báo đã chết ít nhất 0,3 giây
## (đủ lâu để RPC tin cậy đáng lẽ đã tới) mà máy này vẫn thấy sống thì đánh dấu chết, ẩn hình nhân, không phát hiệu ứng.
func _sync_dead(s: Subject, server_out: float, mode_code: int) -> void:
	if server_out <= 0.0 or server_out > 2.7 or s.out > 0.0:
		return
	s.out = server_out
	s.dead_mode = String(MODES[clampi(mode_code, 0, MODES.size() - 1)])
	s.dead_t = 3.0
	s.tag.visible = false
	s.set_solid(false)
	if s.pivot:
		s.pivot.visible = false
	_synced_dead[s.idx] = true


func _unsync_dead(s: Subject) -> void:
	_synced_dead.erase(s.idx)
	s.out = 0.0
	s.dead_mode = ""
	s.dead_t = 0.0
	if s.pivot:
		s.pivot.visible = true
	s.tag.visible = true


# =====================================================================
#  Máy khách: mỗi bước
# =====================================================================
func client_step(dt: float) -> void:
	_clock += dt
	while _lag_q.size() > 0 and float(_lag_q[0][0]) <= _clock:
		(_lag_q.pop_front()[1] as Callable).call()
	if not is_client() or m == null or m.door == null or _bufs.size() < Seats.N:
		return
	_input_acc += dt
	if _input_acc >= 1.0 / INPUT_RATE and connected:
		_input_acc = 0.0
		# vẫn gửi khi máy chủ dừng (hướng đi rỗng) để máy chủ biết kết nối còn sống
		rpc_id(1, "c_input", Vector2.ZERO if host_paused else local_move(), _counts)
	if host_paused:
		return   # máy chủ dừng: đứng hình, không tự chạy đồng hồ / máy móc / dự đoán
	m.t += dt
	m.state_t += dt
	if m.state == MatchManager.ST_PLAY:
		m.lt += dt
	var rt := _clock + _offset - INTERP_DELAY
	for s in m.subjects:
		if s.out > 0.0:
			s.dead_t += dt
			s.out = maxf(0.01, s.out - dt)
		if s.idx == my_seat and s.out <= 0.0 and m.state == MatchManager.ST_PLAY:
			_predict(s, dt)
		else:
			var smp := _bufs[s.idx].sample(rt)
			if smp.size() == 2:
				s.position = smp[0]
				if s.pivot and s.ragdoll == null:
					s.pivot.rotation.y = float(smp[1])
	if m.state == MatchManager.ST_PLAY:   # máy chủ chỉ chạy máy móc lúc đang thi
		m.door.client_tick(dt)
	m.gore.update(dt)
	for s in m.subjects:
		s.animate(m.t, m.door.led_alarm(s))
	if autotest:
		_autotest_step(dt)


## Hướng đi của người chơi tại máy này (mọi bàn phím / tay cầm đều điều khiển cùng một ghế), toạ độ thế giới.
func local_move() -> Vector2:
	if input_blocked:
		return Vector2.ZERO
	var mv := Vector2.ZERO
	for src in _local:
		mv += src.raw_move()
	if _test.has("move"):
		mv = _test.move
	var w := Vector3(mv.x, 0, mv.y).limit_length(1.0).rotated(Vector3.UP, InputSource.cam_yaw)
	return Vector2(w.x, w.z)


## Dự đoán nhân vật của chính mình: đi ngay theo input, rồi kéo dần về vị trí máy chủ nếu lệch nhiều.
func _predict(s: Subject, dt: float) -> void:
	var mv := local_move() if s.stun <= 0.0 else Vector2.ZERO   # bị xô / khựng: để máy chủ dẫn
	var d := Vector3(mv.x, 0, mv.y)
	var spd := 4.1 if m.door.led_alarm(s) else Subject.BASE_SPEED   # người giữ lõi nổ đi nhanh hơn
	var p := s.position + d * spd * dt
	if s.ground:
		p += m.door.surface_velocity(s) * dt
	p = m.door.constrain(s, p)
	var smp := _bufs[s.idx].sample(_clock + _offset)
	if smp.size() == 2:
		var server: Vector3 = smp[0]
		p.y = server.y
		var err := Vector3(server.x - p.x, 0, server.z - p.z)
		if err.length() > 1.6:
			p = server   # lệch quá xa (bị đẩy, băng chuyền...): nhảy về vị trí máy chủ
		elif err.length() > 0.35:
			p += err * minf(1.0, 4.0 * dt)
		if d.length() < 0.1 and s.pivot:
			s.pivot.rotation.y = lerp_angle(s.pivot.rotation.y, float(smp[1]), minf(1.0, 10.0 * dt))
	s.position = p
	if d.length() > 0.1 and s.pivot:
		s.pivot.rotation.y = lerp_angle(s.pivot.rotation.y, atan2(d.x, d.z), 1.0 - exp(-12.0 * dt))


func send_action(_kind: String, _dev: int, act: String) -> void:
	if host_paused or input_blocked:
		return   # máy chủ dừng / đang mở menu: lần bấm này không được nổ ra sau đó
	var i := ACTIONS.find(act)
	if i >= 0:
		_counts[i] = int(_counts[i]) + 1


func send_look(dh: int, dc: int) -> void:
	if is_client() and connected:
		rpc_id(1, "c_look", dh, dc)


# ---------- tự kiểm tra (CI): đi sang phải 3 giây, xem máy chủ có thấy mình di chuyển không ----------
func _autotest_step(dt: float) -> void:
	if my_seat < 0 or m.state != MatchManager.ST_PLAY:
		return
	_test.t = float(_test.get("t", 0.0)) + dt
	var s := m.subjects[my_seat]
	var server := _bufs[my_seat].sample(_clock + _offset)
	if server.size() != 2:
		return
	if not _test.has("start"):
		_test.start = server[0]
		_test.move = Vector2(1, 0)
	if float(_test.t) > 1.5 and int(_test.get("jumps", 0)) == 0:
		_test.jumps = 1
		send_action("", 0, "jump")
	if float(_test.t) >= 3.0 and not _test.has("done"):
		_test.done = true
		_test.erase("move")
		var moved := Vector3(server[0] - _test.start).length()
		# loads >= 1: máy khách có thể vào phòng khi trận đã bắt đầu (chỉ nhận lần nạp cửa hiện tại)
		var ok := snaps_received > 30 and loads_received >= 1 and moved > 1.0
		print("NETTEST seat=%d snaps=%d loads=%d kills=%d moved=%.2f alive=%s" % [my_seat, snaps_received, loads_received, kills_received, moved, s.alive()])
		print("NETTEST OK" if ok else "NETTEST FAIL")
		get_tree().quit(0 if ok else 1)
