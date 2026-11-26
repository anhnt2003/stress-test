class_name DoorBase
extends RefCounted
## Giao diện chung của một cửa. Mỗi cửa một file, ghi đè các hàm cần thiết.
## Luật của cửa chạy trên máy chủ (host) trong `tick`; máy khách chỉ dựng hình (`setup`) và nhận trạng thái
## qua `net_state` / `apply_net_state`, rồi chạy `client_tick` cho phần hoạt ảnh thuần hình ảnh.

const PLATFORM_TOP := 0.5
const PLATFORM_R := 3.5
## Lớp va chạm: 1 đối tượng, 2 chướng ngại vật (chặn đối tượng), 3 mặt sàn (cho xác vật lý), 4 xác.
const LAYER_OBSTACLE := 2
const LAYER_FLOOR := 4

## Mã loại cửa (0..9), dùng cho nhật ký và bảng tên.
var id := -1
var title := ""
var rule := ""
## Khoảng cách tối thiểu giữa hai đối tượng.
var separation := 0.6
## Xác người chết có nằm lại trên sàn không.
var keep_corpses := true
## Cửa xếp hạng theo số ô chiếm được thay vì số lần chết.
var scores_tiles := false
var cam_base := CameraFX.DEFAULT_BASE
var cam_look := CameraFX.DEFAULT_LOOK
## Mô tả nút chơi xấu của cửa này (hiện ở HUD).
var sabotage_hint := ""

var m: MatchManager
var root: Node3D


func _init(match_: MatchManager) -> void:
	m = match_


## Dựng hình và trạng thái ban đầu, rồi thả 4 đối tượng vào cửa.
func setup(level_root: Node3D) -> void:
	root = level_root
	# sàn bê tông của buồng: xác văng khỏi bục thì rơi xuống đây
	static_box(root, Vector3(13.6, 0.4, 13.0), Vector3(0, -0.2, 0.5), LAYER_FLOOR)


## Luật của cửa, chạy mỗi bước trong lúc thi.
func tick(_dt: float) -> void:
	pass


## Hoạt ảnh thuần hình ảnh trên máy khách (không đổi luật).
func client_tick(_dt: float) -> void:
	pass


## Độ cao mặt sàn tại điểm p. -INF nghĩa là không có sàn (rơi xuống).
func ground_y(_p: Vector3) -> float:
	return PLATFORM_TOP


## Độ cao chỗ giọt máu, mảnh vụn rơi xuống.
func gib_ground(p: Vector3) -> float:
	return PLATFORM_TOP if Vector2(p.x, p.z).length() < PLATFORM_R + 0.2 else 0.0


## Chỗ thả đối tượng thay thế.
func spawn_point() -> Vector3:
	var q := Build.rand_circle(0.3, PLATFORM_R - 0.8)
	return Vector3(q.x, PLATFORM_TOP, q.y)


## Giữ đối tượng trong vùng chơi.
func constrain(_s: Subject, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z).limit_length(PLATFORM_R - 0.45)
	return Vector3(f.x, p.y, f.y)


## Vận tốc mặt sàn kéo đối tượng đang đứng trên đó (băng chuyền).
func surface_velocity(_s: Subject) -> Vector3:
	return Vector3.ZERO


## Kiểm tra chết do vị trí sau khi di chuyển (rơi xuống trục nghiền, vào máy huỷ).
func after_move(_s: Subject) -> void:
	pass


## Gợi ý hướng mặt cho bot (null = quay theo hướng đi).
func bot_face(_s: Subject, _d: Vector3) -> Variant:
	return null


## Kiến thức riêng của cửa cho bot. Trả về Vector3 để ép hướng đi, hoặc null để đi tới `brain.target`.
func bot_steer(_s: Subject, _b: BotBrain, _dt: float, _arrived: bool, _retarget: bool) -> Variant:
	return null


## Bot có muốn dùng nút chơi xấu bây giờ không.
func bot_wants_sabotage(_s: Subject, _b: BotBrain, _dt: float) -> bool:
	return false


## Nút chơi xấu: mỗi người một lần mỗi cửa. Trả về true nếu đã kích hoạt.
func sabotage(_s: Subject) -> bool:
	return false


## Đèn vòng cổ nháy nhanh (đang cầm lõi nổ...).
func led_alarm(_s: Subject) -> bool:
	return false


## Chỉ số xếp hạng cuối cửa: nhỏ hơn là tốt hơn.
func metric(s: Subject, round_time: float) -> float:
	if scores_tiles:
		return Scoring.tiles_metric(s.score)
	return Scoring.survival_metric(s.deaths, s.first_death, round_time)


func detail(s: Subject) -> String:
	return ("%d Ô" % s.score) if scores_tiles else ("CHẾT %d LẦN" % s.deaths)


## Gắn vết máu vào vật đang chuyển động (tấm sàn, băng chuyền). Trả về [parent, vị trí cục bộ].
func decal_parent(_pos: Vector3, p: Vector3) -> Array:
	return [root, p]


## Vết máu vừa tạo ở độ cao gy (để băng chuyền kéo đi).
func on_decal(_d: Node3D, _gy: float) -> void:
	pass


## Mảnh vụn đã nằm yên: trả về true nếu cửa đã xoá nó (bị băng chuyền kéo vào máy huỷ).
func carry_rest_gib(_n: Node3D, _dt: float) -> bool:
	return false


## Trạng thái gửi cho máy khách.
func net_state() -> Dictionary:
	return {}


func apply_net_state(_st: Dictionary) -> void:
	pass


## Ẩn đạo cụ che mặt khi chụp ảnh cận cảnh.
func hide_for_closeup() -> void:
	pass


# ---------- vật thể va chạm ----------
static func _shape_node(body: CollisionObject3D, shape: Shape3D, offset := Vector3.ZERO) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	body.add_child(cs)
	return cs


static func _box_shape(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


static func _cyl_shape(r: float, h: float) -> CylinderShape3D:
	var c := CylinderShape3D.new()
	c.radius = r
	c.height = h
	return c


## Khối tĩnh (sàn hoặc chướng ngại vật).
func static_box(parent: Node3D, size: Vector3, pos: Vector3, layer := LAYER_OBSTACLE) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = layer
	b.collision_mask = 0
	_shape_node(b, _box_shape(size))
	parent.add_child(b)
	b.position = pos
	return b


func static_cyl(parent: Node3D, r: float, h: float, pos: Vector3, layer := LAYER_OBSTACLE) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = layer
	b.collision_mask = 0
	_shape_node(b, _cyl_shape(r, h))
	parent.add_child(b)
	b.position = pos
	return b


## Khối chuyển động theo nút cha (máy ép, thùng hàng, quả tạ): chặn đối tượng và đẩy xác.
func moving_body(parent: Node3D, shape: Shape3D, offset := Vector3.ZERO, layer := LAYER_OBSTACLE | LAYER_FLOOR) -> AnimatableBody3D:
	var b := AnimatableBody3D.new()
	# sync_to_physics = true (mặc định) bỏ qua việc nút cha di chuyển: collider sẽ nằm lại chỗ lúc tạo
	b.sync_to_physics = false
	b.collision_layer = layer
	b.collision_mask = 0
	_shape_node(b, shape, offset)
	parent.add_child(b)
	return b


# ---------- tiện ích chung cho các cửa ----------
func k_round() -> float:
	return clampf(m.lt / MatchManager.ROUND_TIME, 0.0, 1.0)


func build_platform(r: float) -> void:
	var hazard := Build.shader_mat("res://shaders/hazard.gdshader")
	var plate := Build.grime(Color(0.26, 0.24, 0.20), 0.55, 0.8, 0.5, 14.0, 0.6)
	Build.cyl(root, r + 0.18, r + 0.3, PLATFORM_TOP - 0.06, hazard, Vector3(0, (PLATFORM_TOP - 0.06) / 2.0, 0), Vector3.ZERO, 40)
	Build.cyl(root, r, r, PLATFORM_TOP, plate, Vector3(0, PLATFORM_TOP / 2.0, 0), Vector3.ZERO, 40)
	static_cyl(root, r, PLATFORM_TOP, Vector3(0, PLATFORM_TOP / 2.0, 0), LAYER_FLOOR)
	Build.cyl(root, 0.4, 0.4, 0.02, Build.mat(Color(0.02, 0.02, 0.02), 0.8, 0.5), Vector3(0, PLATFORM_TOP + 0.005, 0), Vector3.ZERO, 10)
	for i in 10:
		var a := i * TAU / 10.0
		Build.cyl(root, 0.09, 0.09, 0.03, Build.mat(Palette.STEEL_DARK, 0.4, 0.8), Vector3(cos(a) * (r - 0.25), PLATFORM_TOP + 0.01, sin(a) * (r - 0.25)), Vector3.ZERO, 6)
	# máu cũ từ những lượt thử trước
	for i in 9:
		var q := Build.rand_circle(0.3, r - 0.4)
		var d := Build.add_mesh(root, m.gore.disc_mesh, Build.mat(Color(0.12, 0.012, 0.01), 0.35), Vector3(q.x, PLATFORM_TOP + 0.004 + i * 0.0004, q.y))
		d.scale = Vector3(randf_range(0.2, 0.7), 1, randf_range(0.2, 0.6))
		d.rotation.y = randf() * TAU
		if not m.gore.enabled:
			d.visible = false


func spawn_circle(radius: float, offset := 0.6) -> void:
	var slots := shuffled([0, 1, 2, 3])
	for i in 4:
		var a := int(slots[i]) * TAU / 4.0 + offset
		m.spawn_subject(i, Vector3(cos(a) * radius, PLATFORM_TOP, sin(a) * radius))


## Xáo thứ tự (theo seed của cửa) để không ghế nào luôn được chỗ xuất phát tốt hơn.
func shuffled(arr: Array) -> Array:
	var out := arr.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


func subjects() -> Array[Subject]:
	return m.subjects
