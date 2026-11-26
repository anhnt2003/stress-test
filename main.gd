extends Node3D
## STRESS TEST — bản mẫu 5 bài thử, tông kinh dị công nghiệp
## Cảnh dựng hoàn toàn bằng code. Phím 1-5 đổi bài thử, WASD/mũi tên di chuyển đối tượng 01, SPACE nhảy, Esc thoát.
## Không bấm gì 3 giây thì máy tự điều khiển đối tượng 01.

# ---------- Bảng màu ----------
const C_STEEL := Color(0.23, 0.23, 0.22)
const C_STEEL_DARK := Color(0.09, 0.09, 0.09)
const C_RUST := Color(0.30, 0.14, 0.07)
const C_SKIN := Color(0.62, 0.60, 0.55)
const C_FLESH := Color(0.33, 0.03, 0.03)
const C_BLOOD := Color(0.13, 0.004, 0.004)
const C_AMBER := Color(1.0, 0.62, 0.15)
const C_PAPER := Color(0.80, 0.78, 0.70)
const SUIT := [Color(0.52, 0.13, 0.09), Color(0.62, 0.48, 0.12), Color(0.17, 0.30, 0.46), Color(0.25, 0.40, 0.20)]
const SUBJ := ["01", "02", "03", "04"]

# ---------- 10 cửa ----------
# chỉ số loại cửa: 0 máy ép, 1 sàn nghiền, 2 lưỡi cưa, 3 lõi nổ, 4 sàn cảm ứng, 5 băng chuyền, 6 sàn điện, 7 con lắc, 8 tạ rơi, 9 vòng lửa
const LEVEL_NAMES := ["MÁY ÉP", "SÀN NGHIỀN", "LƯỠI CƯA", "LÕI NỔ", "SÀN CẢM ỨNG", "BĂNG CHUYỀN", "SÀN ĐIỆN", "CON LẮC", "TẠ RƠI", "VÒNG LỬA"]
const LEVEL_RULES := [
	"Rời ô đỏ trước khi máy ép dập xuống",
	"Tấm sàn bị dẫm hai lần sẽ rơi xuống máy nghiền",
	"Nhảy qua lưỡi cưa. Tốc độ tăng dần",
	"Chạm để chuyền lõi. Hết giờ là nổ",
	"Chiếm nhiều ô nhất. Ai không đứng đầu thì nổ vòng cổ",
	"Chạy ngược băng chuyền, né thùng hàng. Cuối băng là máy huỷ",
	"Ô nháy vàng sắp phóng điện. Chạy sang ô an toàn hoặc nhảy đúng lúc",
	"Đứng trong vùng sáng. Đừng đứng trên đường rìu",
	"Vòng đỏ hiện ở đâu, tạ nện xuống ở đó",
	"Cửa cuối. Vùng an toàn co lại và trôi đi. Ngoài vùng là lửa",
]
# thứ tự 10 cửa trong một trận
const ORDER := [0, 6, 2, 5, 4, 8, 1, 7, 3, 9]
const ROUND_TIME := 30.0
const POINTS := [4, 3, 2, 1]   # điểm theo hạng trong mỗi cửa; ít lần chết hơn thì hạng cao hơn
const ST_INTRO := 0
const ST_PLAY := 1
const ST_RESULT := 2
const ST_FINAL := 3
const BELT_L := 9.0
const BELT_W := 4.6
const BELT_TOP := 0.6
const EW := 6
const EH := 5
const ES := 1.4
const ELEC_TOP := 0.56
const LANES := [-1.7, 0.0, 1.7]
const PEND_L := 4.2
const PEND_PIVOT := 5.05

const PLATFORM_TOP := 0.5
const PLATFORM_R := 3.5
const GRAVITY := 22.0
const JUMP_V := 7.6
const BEAN_SCALE := 0.86
const PRESS_POS := Vector2(1.55, -0.35)
const PRESS_HIGH := 3.1
const CYCLE := 5.0
const TILE_N := 7
const TILE_S := 1.2
const TILE_TOP := 1.3
const PAINT_W := 9
const PAINT_H := 7
const PAINT_TOP := 0.56

var font: Font
var t := 0.0
var lt := 0.0
var level := 0
var frozen := false
var shot_path := ""
var warmup := 0.0
var idle_time := 99.0
var jump_req := false
var reload_req := false
var door := 0
var state := ST_PLAY
var state_t := 0.0
var totals := [0, 0, 0, 0]
var total_deaths := [0, 0, 0, 0]
var last_rows: Array[Dictionary] = []
var corpses: Array[Node3D] = []
var spark_mat: StandardMaterial3D
var intro_big: Label
var intro_small: Label
var ov_panel: Panel
var ov_title: Label
var ov_foot: Label
var ov_rows: Array[Dictionary] = []
# các cửa mới
var belt_v := 1.3
var cleats: Array[Node3D] = []
var crates: Array[Dictionary] = []
var crate_t := 0.0
var crate_id := 0
var belt_items: Array[Node3D] = []
var shred: Array = []
var elec: Array[Dictionary] = []
var elec_phase := 0
var elec_t := 0.0
var elec_light: OmniLight3D
var pends: Array[Dictionary] = []
var zone_pos := Vector2.ZERO
var zone_t := 0.0
var zone_grace := 0.0
var zone_node: Node3D
var weights: Array[Dictionary] = []
var weight_t := 0.0
var weight_id := 0
var fire_cells: Array[Dictionary] = []
var fire_r := 3.2
var fire_c := Vector2.ZERO
var fire_ring: MeshInstance3D
var fire_light: OmniLight3D

var level_root: Node3D
var beans: Array[Dictionary] = []
var cam: Camera3D
var cam_base: Vector3
var cam_look: Vector3
var post_mat: ShaderMaterial
var fan: Node3D
var bags: Array[Node3D] = []
var flicker_light: OmniLight3D
var flicker_mat: StandardMaterial3D
var beacon: Node3D
var monitor: Label3D
var monitor_t := 0.0
var cam_led: StandardMaterial3D

# hiệu ứng chung
var stamp: Label
var stamp_t := 0.0
var flash := 0.0
var shake := 0.0
var speak_t := 0.0
var hud_title: Label
var hud_rule: Label
var hud_timer: Label
var hud_sub: Label
var hud_cards: Array[Dictionary] = []

# máu me
var blood_mat: StandardMaterial3D
var scorch_mat: StandardMaterial3D
var flesh_mat: StandardMaterial3D
var disc_mesh: CylinderMesh
var drop_mesh: SphereMesh
var gibs: Array[Dictionary] = []
var decal_n := 0

# trạng thái từng bài thử
var press: Node3D
var press_light: OmniLight3D
var beacon_mat: StandardMaterial3D
var press_stage := 0
var tiles: Array[Dictionary] = []
var rollers: Array[Node3D] = []
var arm_root: Node3D
var saws: Array[Node3D] = []
var arm_angle := 0.0
var arm_speed := 1.5
var core: Node3D
var core_mat: StandardMaterial3D
var core_light: OmniLight3D
var core_holder := 0
var core_timer := 10.0
var core_cd := 0.0
var core_wait := 0.0
var core_phase := 0.0
var core_display: Label3D
var paint_owner: PackedInt32Array = PackedInt32Array()
var paint_mats: Array[StandardMaterial3D] = []
var paint_done := false
var paint_kill_t := 0.0


func _ready() -> void:
	font = load("res://fonts/Anton-Regular.ttf")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_path = a.trim_prefix("--shot=")
		elif a.begins_with("--phase="):
			warmup = float(a.trim_prefix("--phase="))
		elif a.begins_with("--door="):
			door = clampi(int(a.trim_prefix("--door=")) - 1, 0, 9)

	blood_mat = mat(C_BLOOD, 0.1)
	scorch_mat = mat(Color(0.02, 0.02, 0.02), 0.95)
	flesh_mat = mat(C_FLESH, 0.35)
	spark_mat = glow(Color(1.0, 0.85, 0.4), 5.0)
	disc_mesh = CylinderMesh.new()
	disc_mesh.top_radius = 1.0
	disc_mesh.bottom_radius = 1.0
	disc_mesh.height = 0.004
	disc_mesh.radial_segments = 10
	disc_mesh.rings = 1
	drop_mesh = SphereMesh.new()
	drop_mesh.radius = 1.0
	drop_mesh.height = 2.0
	drop_mesh.radial_segments = 6
	drop_mesh.rings = 3

	_build_environment()
	_build_room()
	_build_lights()
	_build_props()
	_build_dust()
	cam = Camera3D.new()
	cam.fov = 54.0
	add_child(cam)
	cam.current = true
	_build_post_and_ui()
	if shot_path == "":
		start_match()
	else:
		# chế độ chụp ảnh: --door=N vào thẳng cửa N, --match chạy cả trận từ cửa 1
		if OS.get_cmdline_user_args().has("--match"):
			start_match()
		else:
			load_door(door, false)
		var n := int(warmup * 30.0)
		for i in n:
			_step(1.0 / 30.0)
		frozen = true
		if OS.get_cmdline_user_args().has("--closeup"):
			for i in beans.size():
				var r: Node3D = beans[i].root
				r.visible = true
				r.position = Vector3(-1.5 + 1.0 * i, PLATFORM_TOP, 0.6)
				r.rotation = Vector3(0, 0.25 - 0.17 * i, 0)
			if core:
				core.visible = false
			cam.fov = 32.0
			cam.position = Vector3(0.0, 1.9, 4.6)
			cam.look_at(Vector3(0.0, 1.4, 0.6))
		if DisplayServer.get_name() == "headless":
			get_tree().quit()
		else:
			_capture()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var k: int = e.keycode
		if k >= KEY_1 and k <= KEY_9:
			load_door(k - KEY_1, true)       # nhảy thẳng tới một cửa (để xem thử), điểm giữ nguyên
		elif k == KEY_0:
			load_door(9, true)
		elif k == KEY_N and state == ST_PLAY:
			lt = ROUND_TIME                   # kết thúc cửa hiện tại ngay
		elif (k == KEY_ENTER or k == KEY_KP_ENTER) and state == ST_FINAL:
			start_match()
		elif k == KEY_SPACE:
			jump_req = true
			idle_time = 0.0
		elif k == KEY_ESCAPE:
			get_tree().quit()


func _process(delta: float) -> void:
	if not frozen:
		_step(minf(delta, 0.05))


func _capture() -> void:
	for i in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(shot_path)
	print("saved ", shot_path, " ", img.get_size())
	get_tree().quit()


# =====================================================================
#  Tiện ích dựng hình
# =====================================================================
func mat(color: Color, rough := 0.8, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	return m


func shader_mat(path: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


func add_mesh(parent: Node, mesh: Mesh, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	parent.add_child(mi)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


func box(parent: Node, size: Vector3, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return add_mesh(parent, b, material, pos, rot_deg)


func cyl(parent: Node, r_top: float, r_bot: float, h: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, segs := 16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return add_mesh(parent, c, material, pos, rot_deg)


func ball(parent: Node, r: float, material: Material, pos := Vector3.ZERO, hemi := false) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r if hemi else r * 2.0
	s.is_hemisphere = hemi
	s.radial_segments = 12
	s.rings = 6
	return add_mesh(parent, s, material, pos)


func capsule(parent: Node, r: float, h: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 10
	c.rings = 3
	return add_mesh(parent, c, material, pos, rot_deg)


func torus(parent: Node, r_in: float, r_out: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = r_in
	tm.outer_radius = r_out
	tm.rings = 14
	tm.ring_segments = 6
	return add_mesh(parent, tm, material, pos, rot_deg)


func glow(color: Color, energy := 3.0) -> StandardMaterial3D:
	return mat(color, 0.3, 0.0, energy)


func label3d(parent: Node, text: String, pos: Vector3, size: int, color: Color, px := 0.006) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font
	l.font_size = size
	l.pixel_size = px
	l.modulate = color
	l.outline_size = 0
	l.shaded = true
	l.line_spacing = -6.0
	parent.add_child(l)
	l.position = pos
	return l


func omni(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, fog := 1.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.light_volumetric_fog_energy = fog
	parent.add_child(l)
	l.position = pos
	return l


# =====================================================================
#  Buồng thử: môi trường, tường, đèn, đạo cụ
# =====================================================================
func grime(base: Color, rust := 0.3, dirt := 0.6, metal := 0.0, texel := 18.0, rough := 0.85) -> ShaderMaterial:
	return shader_mat("res://shaders/grime.gdshader", {"base": base, "rust": rust, "dirt": dirt, "metal": metal,
		"texel": texel, "rough": rough, "seed": randf() * 40.0})


func _vent(parent: Node, pos: Vector3, rot_y: float, r: float) -> void:
	# cửa gió tròn có lá chớp
	var v := Node3D.new()
	parent.add_child(v)
	v.position = pos
	v.rotation_degrees.y = rot_y
	cyl(v, r + 0.12, r + 0.12, 0.16, grime(Color(0.30, 0.27, 0.21), 0.5, 0.8, 0.3), Vector3.ZERO, Vector3(90, 0, 0), 14)
	cyl(v, r, r, 0.18, mat(Color(0.01, 0.01, 0.01), 1.0), Vector3.ZERO, Vector3(90, 0, 0), 14)
	var n := 7
	for i in n:
		var y := -r + (i + 0.5) * (2.0 * r / n)
		var w := 2.0 * sqrt(maxf(r * r - y * y, 0.01))
		box(v, Vector3(w, 0.05, 0.16), grime(Color(0.26, 0.24, 0.19), 0.5, 0.8, 0.4), Vector3(0, y, 0.08), Vector3(-28, 0, 0))


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.56, 0.54, 0.44)
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.ssao_enabled = true
	env.ssao_intensity = 4.0
	env.ssao_radius = 1.4
	env.fog_enabled = true
	env.fog_light_color = Color(0.13, 0.11, 0.07)
	env.fog_density = 0.014
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.028
	env.volumetric_fog_albedo = Color(0.85, 0.82, 0.70)
	env.volumetric_fog_length = 30.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_room() -> void:
	# buồng kín, trần thấp: x ±6.4, z từ -5.6 tới 6.6, trần 5.4
	var room := Node3D.new()
	add_child(room)
	var wall := shader_mat("res://shaders/wall.gdshader")
	var floor_m := shader_mat("res://shaders/floor.gdshader")
	var conc := grime(Color(0.38, 0.33, 0.25), 0.25, 0.8, 0.0, 14.0)
	var steel := grime(Color(0.26, 0.25, 0.22), 0.55, 0.7, 0.5)
	var dark := grime(Color(0.11, 0.10, 0.09), 0.4, 0.6, 0.5)
	var rust := grime(Color(0.30, 0.15, 0.07), 0.8, 0.7, 0.3)
	box(room, Vector3(13.6, 0.4, 13.0), floor_m, Vector3(0, -0.2, 0.5))
	box(room, Vector3(13.6, 5.8, 0.4), wall, Vector3(0, 2.9, -5.8))
	box(room, Vector3(13.6, 5.8, 0.4), wall, Vector3(0, 2.9, 6.8))
	box(room, Vector3(0.4, 5.8, 13.0), wall, Vector3(-6.6, 2.9, 0.5))
	box(room, Vector3(0.4, 5.8, 13.0), wall, Vector3(6.6, 2.9, 0.5))
	box(room, Vector3(13.6, 0.3, 13.0), conc, Vector3(0, 5.55, 0.5))
	# dầm trần, gờ tường, trụ
	for z in [-3.0, 0.5, 4.0]:
		box(room, Vector3(12.8, 0.4, 0.4), conc, Vector3(0, 5.2, z))
	box(room, Vector3(12.8, 0.22, 0.25), conc, Vector3(0, 3.5, -5.5))
	box(room, Vector3(0.25, 0.22, 12.2), conc, Vector3(-6.3, 3.5, 0.5))
	box(room, Vector3(12.8, 0.3, 0.2), conc, Vector3(0, 0.15, -5.5))
	box(room, Vector3(0.2, 0.3, 12.2), conc, Vector3(-6.3, 0.15, 0.5))
	for x in [-6.25, -2.1, 2.1, 6.25]:
		box(room, Vector3(0.5, 5.4, 0.35), conc, Vector3(x, 2.7, -5.48))
	for z in [-1.6, 2.6]:
		box(room, Vector3(0.35, 5.4, 0.5), conc, Vector3(-6.28, 2.7, z))
	# ống gỉ và cáp chạy dọc tường
	cyl(room, 0.13, 0.13, 12.6, rust, Vector3(0, 4.75, -5.3), Vector3(0, 0, 90), 8)
	cyl(room, 0.07, 0.07, 12.6, steel, Vector3(0, 4.45, -5.38), Vector3(0, 0, 90), 6)
	cyl(room, 0.10, 0.10, 12.0, rust, Vector3(-6.1, 4.8, 0.5), Vector3(90, 0, 0), 8)
	cyl(room, 0.12, 0.12, 5.4, rust, Vector3(5.9, 2.7, -5.2), Vector3.ZERO, 8)
	for i in 4:
		cyl(room, 0.022, 0.022, 12.0, dark, Vector3(-6.32, 4.25 - i * 0.07, 0.5), Vector3(90, 0, 0), 5)
	# cửa thép đã khoá (tường sau, bên phải)
	box(room, Vector3(1.7, 2.7, 0.14), grime(Color(0.20, 0.21, 0.19), 0.6, 0.7, 0.6), Vector3(4.1, 1.35, -5.55))
	box(room, Vector3(1.9, 0.14, 0.2), dark, Vector3(4.1, 2.78, -5.55))
	box(room, Vector3(0.8, 0.1, 0.05), dark, Vector3(4.1, 1.4, -5.46))
	ball(room, 0.06, glow(Color(1.0, 0.08, 0.05), 3.0), Vector3(4.1, 3.05, -5.5))
	# màn hình của Cỗ Máy (tường sau, giữa)
	box(room, Vector3(4.0, 1.9, 0.3), dark, Vector3(-0.2, 2.35, -5.5))
	var scr := mat(Color(0.02, 0.015, 0.005), 0.15)
	scr.emission_enabled = true
	scr.emission = Color(0.9, 0.5, 0.1)
	scr.emission_energy_multiplier = 0.07
	box(room, Vector3(3.7, 1.6, 0.06), scr, Vector3(-0.2, 2.35, -5.33))
	monitor = label3d(room, "", Vector3(-0.2, 2.35, -5.29), 76, C_AMBER, 0.0058)
	monitor.shaded = false
	monitor.line_spacing = 0.0
	for k in 3:   # cáp thòng xuống từ màn hình
		cyl(room, 0.025, 0.025, 1.3, dark, Vector3(-1.4 + k * 0.12, 0.75, -5.5), Vector3.ZERO, 5)
	# cửa gió tròn
	_vent(room, Vector3(-4.0, 4.2, -5.52), 0.0, 0.62)
	_vent(room, Vector3(2.6, 4.2, -5.52), 0.0, 0.62)
	_vent(room, Vector3(-6.32, 4.25, 4.4), 90.0, 0.62)
	# cửa kính phòng quan sát (tường trái) với bóng người đứng nhìn
	var ow := Node3D.new()
	room.add_child(ow)
	ow.position = Vector3(-6.36, 2.45, 0.5)
	ow.rotation_degrees.y = 90.0
	box(ow, Vector3(3.9, 1.5, 0.14), steel, Vector3(0, 0, -0.02))
	var glass := mat(Color(0.03, 0.035, 0.03), 0.05, 0.3)
	glass.emission_enabled = true
	glass.emission = Color(0.55, 0.60, 0.40)
	glass.emission_energy_multiplier = 0.16
	box(ow, Vector3(3.6, 1.2, 0.08), glass, Vector3(0, 0, 0.03))
	for x in [-1.1, 0.2, 1.2]:
		capsule(ow, 0.2, 0.95, mat(Color(0, 0, 0), 1.0), Vector3(x, -0.22, 0.09))
		ball(ow, 0.15, mat(Color(0, 0, 0), 1.0), Vector3(x, 0.36, 0.09))
	box(ow, Vector3(0.06, 1.2, 0.1), steel, Vector3(-0.45, 0, 0.05))
	# chữ sơn khuôn
	var st := label3d(room, "BUỒNG THỬ 09", Vector3(-6.38, 1.15, -3.2), 120, Color(0.12, 0.10, 0.08, 0.8), 0.0065)
	st.rotation_degrees.y = 90.0
	var st2 := label3d(room, "KHÔNG TIẾP XÚC\nVỚI ĐỐI TƯỢNG", Vector3(-6.38, 1.25, 4.2), 60, Color(0.45, 0.07, 0.05, 0.85), 0.006)
	st2.line_spacing = 0.0
	st2.rotation_degrees.y = 90.0
	# loa (góc tường sau bên phải) + camera giám sát (tường trái)
	var loa := Node3D.new()
	room.add_child(loa)
	loa.position = Vector3(5.6, 4.3, -5.1)
	var grey := grime(Color(0.24, 0.24, 0.21), 0.5, 0.7, 0.5)
	for side in [-1.0, 1.0]:
		var horn := Node3D.new()
		loa.add_child(horn)
		horn.rotation_degrees = Vector3(-16, 26.0 * side - 30.0, 0)
		horn.position = Vector3(0.25 * side, 0, 0.1)
		cyl(horn, 0.09, 0.42, 0.75, grey, Vector3(0, 0, 0.42), Vector3(-90, 0, 0), 12)
		cyl(horn, 0.36, 0.36, 0.02, mat(Color(0.01, 0.01, 0.01), 0.9), Vector3(0, 0, 0.81), Vector3(-90, 0, 0), 12)
	var camn := Node3D.new()
	room.add_child(camn)
	camn.position = Vector3(-6.0, 4.6, -4.9)
	camn.rotation_degrees = Vector3(-30, -50, 0)
	box(camn, Vector3(0.28, 0.24, 0.62), grey, Vector3(0, 0, 0.28))
	cyl(camn, 0.1, 0.1, 0.12, dark, Vector3(0, 0, 0.62), Vector3(90, 0, 0), 8)
	cam_led = glow(Color(1.0, 0.05, 0.03), 4.0)
	ball(camn, 0.035, cam_led, Vector3(0.09, 0.08, 0.6))


func _caged_lamp(pos: Vector3, color: Color, energy: float, rng: float) -> Array:
	var n := Node3D.new()
	add_child(n)
	n.position = pos
	var m := glow(color, 4.0)
	ball(n, 0.1, m)
	cyl(n, 0.16, 0.16, 0.05, mat(C_STEEL_DARK, 0.6, 0.6), Vector3(0, 0.14, 0), Vector3.ZERO, 8)
	torus(n, 0.12, 0.14, mat(C_STEEL_DARK, 0.6, 0.6), Vector3(0, -0.02, 0))
	var l := omni(n, Vector3(0, -0.1, 0.2), color, energy, rng, 0.5)
	return [l, m]


func _build_lights() -> void:
	# chao đèn dây tóc treo giữa buồng
	var hood := Node3D.new()
	add_child(hood)
	hood.position = Vector3(0.3, 4.75, 0.4)
	cyl(hood, 0.2, 0.7, 0.4, grime(Color(0.14, 0.15, 0.12), 0.5, 0.6, 0.5), Vector3.ZERO, Vector3.ZERO, 12)
	cyl(hood, 0.62, 0.62, 0.02, glow(Color(1.0, 0.86, 0.55), 5.0), Vector3(0, -0.2, 0), Vector3.ZERO, 12)
	cyl(hood, 0.025, 0.025, 0.6, mat(C_STEEL_DARK), Vector3(0, 0.5, 0), Vector3.ZERO, 5)
	var sp := SpotLight3D.new()
	sp.light_color = Color(1.0, 0.90, 0.72)
	sp.light_energy = 11.0
	sp.spot_range = 12.0
	sp.spot_angle = 66.0
	sp.spot_angle_attenuation = 0.9
	sp.spot_attenuation = 0.55
	sp.shadow_enabled = true
	sp.shadow_blur = 1.2
	sp.light_volumetric_fog_energy = 1.0
	hood.add_child(sp)
	sp.position = Vector3(0, -0.25, 0)
	sp.rotation_degrees = Vector3(-90, 0, 0)
	# đèn lồng trên tường
	_caged_lamp(Vector3(-2.1, 3.9, -5.25), Color(1.0, 0.72, 0.38), 1.6, 6.5)
	_caged_lamp(Vector3(5.2, 3.3, -5.25), Color(1.0, 0.72, 0.38), 1.2, 5.5)
	var fl := _caged_lamp(Vector3(-6.05, 3.9, 2.6), Color(0.95, 0.85, 0.5), 1.6, 6.5)
	flicker_light = fl[0]
	flicker_mat = fl[1]
	# đèn báo động xoay cạnh cửa
	beacon = Node3D.new()
	add_child(beacon)
	beacon.position = Vector3(4.1, 3.3, -5.3)
	cyl(beacon, 0.11, 0.11, 0.18, glow(Color(1.0, 0.06, 0.03), 3.5), Vector3.ZERO, Vector3.ZERO, 8)
	var bs := SpotLight3D.new()
	bs.light_color = Color(1.0, 0.08, 0.04)
	bs.light_energy = 3.5
	bs.spot_range = 13.0
	bs.spot_angle = 28.0
	bs.light_volumetric_fog_energy = 1.6
	beacon.add_child(bs)
	bs.rotation_degrees = Vector3(-14, 0, 0)
	# ánh hổ phách từ màn hình + đèn phụ ấm phía camera
	omni(self, Vector3(-0.2, 2.4, -4.6), Color(1.0, 0.6, 0.2), 0.5, 4.5, 0.2)
	omni(self, Vector3(4.6, 3.6, 5.2), Color(0.95, 0.92, 0.80), 1.5, 13.0, 0.0)
	# quạt trần quay chậm
	fan = Node3D.new()
	add_child(fan)
	fan.position = Vector3(-3.6, 4.85, 3.4)
	var fm := grime(Color(0.14, 0.13, 0.11), 0.5, 0.6, 0.5)
	cyl(fan, 0.16, 0.2, 0.18, fm, Vector3.ZERO, Vector3.ZERO, 8)
	for i in 4:
		var arm := Node3D.new()
		fan.add_child(arm)
		arm.rotation_degrees.y = i * 90.0
		box(arm, Vector3(1.3, 0.03, 0.3), fm, Vector3(0.8, 0, 0), Vector3(10, 0, 0))


func _build_props() -> void:
	var dark := grime(Color(0.11, 0.10, 0.09), 0.4, 0.6, 0.5)
	var steel := grime(Color(0.30, 0.29, 0.25), 0.5, 0.7, 0.6)
	var bagm := mat(Color(0.035, 0.035, 0.04), 0.3)
	# túi đựng xác chất ở chân tường trái
	for i in 3:
		var c := Node3D.new()
		add_child(c)
		var bg := capsule(c, 0.3, 1.9, bagm, Vector3(0, 0.24, 0), Vector3(90, 0, 0))
		bg.scale = Vector3(1.15, 1.0, 0.75)
		box(c, Vector3(0.04, 0.02, 1.5), mat(Color(0.3, 0.3, 0.3), 0.4, 0.8), Vector3(0, 0.47, 0))
		c.position = Vector3(-5.65 + (0.35 if i == 2 else 0.0), 0.02 + (0.42 if i == 2 else 0.0), -1.3 + i * 1.0 - (1.3 if i == 2 else 0.0))
		c.rotation_degrees.y = [4.0, -7.0, 12.0][i]
	# băng ca phủ vải dựa tường sau
	var g := Node3D.new()
	add_child(g)
	g.position = Vector3(-4.2, 0, -4.7)
	g.rotation_degrees.y = 82.0
	box(g, Vector3(0.95, 0.06, 2.2), steel, Vector3(0, 0.85, 0))
	for x in [-0.42, 0.42]:
		for z in [-1.0, 1.0]:
			box(g, Vector3(0.05, 0.85, 0.05), steel, Vector3(x, 0.42, z))
			cyl(g, 0.07, 0.07, 0.04, dark, Vector3(x, 0.07, z), Vector3(0, 0, 90), 8)
	var sheet := grime(Color(0.52, 0.50, 0.42), 0.0, 0.9, 0.0, 22.0, 0.95)
	var body := capsule(g, 0.24, 1.75, sheet, Vector3(0, 1.02, 0.05), Vector3(90, 0, 0))
	body.scale = Vector3(1.4, 1.0, 0.75)
	ball(g, 0.2, sheet, Vector3(0, 1.08, -0.85))
	var stain := add_mesh(g, disc_mesh, blood_mat, Vector3(0.05, 1.215, 0.1))
	stain.scale = Vector3(0.22, 1, 0.34)
	# thùng phuy gỉ, két sắt, xô
	for d in [[5.6, -4.6, Color(0.30, 0.15, 0.07)], [4.9, 5.6, Color(0.16, 0.17, 0.15)], [5.7, -3.6, Color(0.20, 0.22, 0.17)], [-5.6, 5.4, Color(0.28, 0.14, 0.07)]]:
		var drum := cyl(self, 0.42, 0.42, 1.15, grime(d[2], 0.7, 0.8, 0.4), Vector3(d[0], 0.575, d[1]), Vector3.ZERO, 12)
		for y in [-0.3, 0.3]:
			cyl(drum, 0.44, 0.44, 0.05, grime((d[2] as Color).darkened(0.4), 0.7, 0.7, 0.5), Vector3(0, y, 0), Vector3.ZERO, 12)
	box(self, Vector3(1.0, 1.7, 0.6), grime(Color(0.24, 0.26, 0.21), 0.6, 0.8, 0.5), Vector3(2.72, 0.85, -5.25))
	box(self, Vector3(0.9, 0.04, 0.02), dark, Vector3(2.72, 0.9, -4.94))
	cyl(self, 0.2, 0.16, 0.34, grime(Color(0.34, 0.33, 0.30), 0.5, 0.7, 0.6), Vector3(-5.2, 0.17, 3.4), Vector3.ZERO, 10)
	# xích và móc treo
	for h in [[-4.4, -3.6, 2.5], [-3.0, -4.6, 3.0], [4.6, -3.0, 2.3], [-5.0, 2.0, 2.8], [5.2, 2.2, 3.2]]:
		var ln: float = 5.3 - float(h[2])
		cyl(self, 0.022, 0.022, ln, dark, Vector3(h[0], h[2] + ln / 2.0, h[1]), Vector3.ZERO, 5)
		torus(self, 0.09, 0.125, grime(Color(0.30, 0.28, 0.24), 0.6, 0.6, 0.7), Vector3(h[0], h[2] - 0.09, h[1]), Vector3(90, 30, 0))
	# lỗ thoát nước + vũng máu
	cyl(self, 0.32, 0.32, 0.02, dark, Vector3(4.4, 0.01, 3.2), Vector3.ZERO, 10)
	var pool := add_mesh(self, disc_mesh, blood_mat, Vector3(4.0, 0.009, 2.8))
	pool.scale = Vector3(0.9, 1, 0.5)
	pool.rotation_degrees.y = 40.0
	var drag := add_mesh(self, disc_mesh, mat(Color(0.14, 0.012, 0.01), 0.3), Vector3(-4.6, 0.008, 1.0))
	drag.scale = Vector3(0.35, 1, 2.0)
	drag.rotation_degrees.y = 14.0


func _build_dust() -> void:
	var p := GPUParticles3D.new()
	p.amount = 70
	p.lifetime = 9.0
	p.preprocess = 9.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3.0, 1.8, 3.0)
	pm.gravity = Vector3(0, -0.015, 0)
	pm.direction = Vector3(1, 0.2, 0.3)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.03
	pm.initial_velocity_max = 0.12
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.018, 0.018)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(1.0, 0.9, 0.7, 0.25)
	q.material = dm
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-7, -3, -6), Vector3(14, 6, 13))
	add_child(p)
	p.position = Vector3(0, 2.8, 0.4)


# =====================================================================
#  ĐỐI TƯỢNG THỬ NGHIỆM — hình nhân gầy, áo liền quần đánh số, vòng cổ nổ
# =====================================================================
func _build_upper(parent: Node3D, i: int) -> Dictionary:
	# thân trên: áo khoác lao động bạc màu, đầu trọc xám, vòng cổ nổ, mũ riêng từng người
	var jacket := grime(SUIT[i], 0.0, 0.85, 0.0, 26.0, 0.95)
	var skin := grime(Color(0.60, 0.55, 0.46), 0.0, 0.5, 0.0, 30.0, 0.75)
	var skin_d := mat(Color(0.33, 0.29, 0.24), 0.8)
	var dark := mat(Color(0.03, 0.03, 0.03), 0.6)
	var torso := capsule(parent, 0.2, 0.72, jacket, Vector3(0, 0.35, 0))
	torso.scale = Vector3(1.3, 1.0, 0.85)
	capsule(parent, 0.105, 0.68, jacket, Vector3(0, 0.61, 0), Vector3(0, 0, 90))   # vai
	var hem := cyl(parent, 0.235, 0.255, 0.16, jacket, Vector3(0, 0.07, 0), Vector3.ZERO, 10)
	hem.scale = Vector3(1.12, 1, 0.82)
	box(parent, Vector3(0.03, 0.5, 0.012), dark, Vector3(0, 0.36, 0.176))        # hàng khuy
	box(parent, Vector3(0.17, 0.12, 0.012), mat(Color(0.62, 0.58, 0.48), 0.9), Vector3(-0.13, 0.47, 0.172))
	label3d(parent, SUBJ[i], Vector3(-0.13, 0.47, 0.181), 30, Color(0.05, 0.05, 0.05), 0.0042).shaded = true
	var n2 := label3d(parent, SUBJ[i], Vector3(0, 0.40, -0.176), 76, Color(0.07, 0.06, 0.05, 0.85), 0.0042)
	n2.rotation_degrees.y = 180.0
	var sh: Array[Node3D] = []
	for sx in [-1.0, 1.0]:
		var p := Node3D.new()
		parent.add_child(p)
		p.position = Vector3(0.33 * sx, 0.6, 0)
		capsule(p, 0.07, 0.6, jacket, Vector3(0, -0.25, 0))
		cyl(p, 0.078, 0.078, 0.06, jacket, Vector3(0, -0.5, 0), Vector3.ZERO, 8)
		ball(p, 0.07, skin, Vector3(0, -0.58, 0))
		sh.append(p)
	# vòng cổ nổ + đèn LED
	torus(parent, 0.085, 0.13, mat(Color(0.10, 0.10, 0.10), 0.4, 0.8), Vector3(0, 0.77, 0))
	var led := glow(SUIT[i].lightened(0.3), 4.0)
	box(parent, Vector3(0.09, 0.07, 0.05), dark, Vector3(0, 0.77, 0.13))
	ball(parent, 0.026, led, Vector3(0, 0.77, 0.16))
	var neck := Node3D.new()
	parent.add_child(neck)
	neck.position = Vector3(0, 0.82, 0)
	cyl(parent, 0.06, 0.07, 0.14, skin, Vector3(0, 0.80, 0), Vector3.ZERO, 8)
	var head := Node3D.new()
	parent.add_child(head)
	head.position = Vector3(0, 0.99, 0)
	var skull := ball(head, 0.18, skin)
	skull.scale = Vector3(0.9, 1.08, 0.98)
	var jaw := ball(head, 0.13, skin, Vector3(0, -0.095, 0.025))
	jaw.scale = Vector3(0.98, 0.85, 0.95)
	box(head, Vector3(0.21, 0.035, 0.06), skin_d, Vector3(0, 0.055, 0.145))            # gờ mày
	box(head, Vector3(0.045, 0.09, 0.07), skin, Vector3(0, -0.015, 0.175), Vector3(-18, 0, 0))  # mũi
	for sx in [-1.0, 1.0]:
		var eye := ball(head, 0.034, dark, Vector3(0.062 * sx, 0.022, 0.152))
		eye.scale = Vector3(1.2, 0.9, 0.6)
		ball(head, 0.035, skin, Vector3(0.165 * sx, -0.01, 0.0))                       # tai
	box(head, Vector3(0.095, 0.012, 0.02), dark, Vector3(0, -0.115, 0.14))             # miệng
	match i:
		0:  # mũ cối
			var hm := grime(Color(0.30, 0.33, 0.20), 0.0, 0.8, 0.0, 26.0)
			var dome := ball(head, 0.2, hm, Vector3(0, 0.06, 0), true)
			dome.scale = Vector3(1.0, 1.15, 1.08)
			var brim := cyl(head, 0.28, 0.3, 0.03, hm, Vector3(0, 0.06, 0.01), Vector3.ZERO, 12)
			brim.scale = Vector3(0.95, 1, 1.12)
		1:  # nón lá sờn
			cyl(head, 0.0, 0.42, 0.2, grime(Color(0.62, 0.52, 0.32), 0.0, 0.8, 0.0, 26.0), Vector3(0, 0.2, 0), Vector3.ZERO, 12)
			box(head, Vector3(0.015, 0.2, 0.3), dark, Vector3(0, -0.02, 0.0))
		2:  # mũ bảo hiểm nửa đầu
			var hm2 := grime(Color(0.20, 0.22, 0.26), 0.3, 0.6, 0.3, 26.0, 0.45)
			var dome2 := ball(head, 0.205, hm2, Vector3(0, 0.035, -0.005), true)
			dome2.scale = Vector3(1.0, 1.12, 1.06)
			box(head, Vector3(0.24, 0.02, 0.1), hm2, Vector3(0, 0.05, 0.2), Vector3(12, 0, 0))
			for sx in [-1.0, 1.0]:
				box(head, Vector3(0.012, 0.2, 0.03), dark, Vector3(0.158 * sx, -0.06, 0.03))
		3:  # băng quấn đầu che một mắt
			var bd := grime(Color(0.62, 0.58, 0.48), 0.0, 0.9, 0.0, 30.0, 0.95)
			var band := cyl(head, 0.172, 0.175, 0.11, bd, Vector3(0, 0.075, 0.0), Vector3(0, 0, -10), 12)
			band.scale = Vector3(1.0, 1, 1.07)
			box(head, Vector3(0.1, 0.09, 0.03), bd, Vector3(0.065, 0.02, 0.158), Vector3(0, 0, -10))
			box(head, Vector3(0.05, 0.04, 0.012), blood_mat, Vector3(0.07, 0.02, 0.176))
	return {"sh": sh, "head": head, "neck": neck, "led": led}


func make_bean(i: int, pos: Vector3) -> Dictionary:
	var b := {
		"idx": i, "phase": randf() * TAU, "vy": 0.0, "ground": true, "knock": Vector3.ZERO, "target": pos,
		"ai_t": 0.0, "out": 0.0, "flat": 0.0, "deaths": 0, "score": 0, "moving": false, "scared": false,
		"flee": true, "decided": false, "hit_cd": 0.0, "speed": 3.3, "dead_mode": "", "dead_t": 0.0, "last_tile": -1,
		"react": 0.0, "outside_t": 0.0, "doom": -1.0, "first_death": 999.0, "home_x": -1.5, "lane_z": pos.z, "off": Vector2.ZERO,
	}
	_build_bean_nodes(b, pos)
	beans.append(b)
	return b


# =====================================================================
#  MÁU ME: giọt máu, mảnh vụn, vết loang
# =====================================================================
func _gib_ground(p: Vector3) -> float:
	var f := Vector2(p.x, p.z)
	match level:
		1:
			var h := _tile_half() + 0.1
			if absf(p.x) > h + 0.5 or absf(p.z) > h + 0.5:
				return 0.0
			var ti := _tile_at(p)
			return TILE_TOP if ti >= 0 and tiles[ti].state <= 1 else -INF
		4:
			return PAINT_TOP if absf(p.x) < PAINT_W / 2.0 + 0.25 and absf(p.z) < PAINT_H / 2.0 + 0.25 else 0.0
		5:
			return BELT_TOP if absf(p.x) < BELT_L / 2.0 and absf(p.z) < BELT_W / 2.0 + 0.1 else 0.0
		6:
			return ELEC_TOP if absf(p.x) < EW * ES / 2.0 + 0.25 and absf(p.z) < EH * ES / 2.0 + 0.25 else 0.0
	return PLATFORM_TOP if f.length() < PLATFORM_R + 0.2 else 0.0


func _decal(pos: Vector3, r: float, m: Material = null) -> void:
	if decal_n > 190:
		return
	decal_n += 1
	var parent: Node = level_root
	var gy := _gib_ground(pos)
	var p := Vector3(pos.x, gy + 0.012 + decal_n * 0.0003, pos.z)
	if p.y < -10.0:
		return
	if level == 1:
		var ti := _tile_at(pos)
		if ti >= 0 and tiles[ti].state <= 1 and absf(pos.x) < _tile_half() and absf(pos.z) < _tile_half():
			parent = tiles[ti].mi
			p -= (tiles[ti].mi as Node3D).position
	var on_belt := level == 5 and gy > 0.1
	var d := add_mesh(parent, disc_mesh, m if m else blood_mat, p)
	d.scale = Vector3(r * randf_range(0.7, 1.4), 1.0, r * randf_range(0.7, 1.4))
	d.rotation.y = randf() * TAU
	if on_belt:
		belt_items.append(d)
	if r > 0.14:   # vệt loang không tròn đều: thêm vài đốm vệ tinh
		for k in 2:
			var a := randf() * TAU
			var d2 := add_mesh(parent, disc_mesh, m if m else blood_mat, p + Vector3(cos(a), 0, sin(a)) * r * randf_range(0.6, 1.2) + Vector3(0, 0.0002 * (k + 1), 0))
			d2.scale = Vector3(r * randf_range(0.25, 0.6), 1.0, r * randf_range(0.2, 0.5))
			d2.rotation.y = randf() * TAU
			if on_belt:
				belt_items.append(d2)


func _drop(pos: Vector3, vel: Vector3, m: Material = null, stain := true) -> void:
	if gibs.size() > 280:
		return
	var mi := add_mesh(level_root, drop_mesh, m if m else blood_mat, pos)
	mi.scale = Vector3.ONE * randf_range(0.025, 0.06)
	gibs.append({"n": mi, "v": vel, "chunk": false, "rest": false, "b": 0, "spin": Vector3.ZERO, "stain": stain})


func _chunk(pos: Vector3, vel: Vector3, m: Material, size: float) -> void:
	var mi: MeshInstance3D
	if randf() < 0.5:
		mi = box(level_root, Vector3(size, size * randf_range(0.5, 0.9), size * randf_range(0.6, 1.3)), m, pos)
	else:
		mi = ball(level_root, size * 0.6, m, pos)
	_chunk_node(mi, vel, size * 0.35)


func _chunk_node(n: Node3D, vel: Vector3, rest_h: float) -> void:
	gibs.append({"n": n, "v": vel, "chunk": true, "rest": false, "b": 0, "h": rest_h,
		"spin": Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))})


func _spray(pos: Vector3, count: int, dir: Vector3, speed: float, spread: float) -> void:
	for i in count:
		var v := dir * speed * randf_range(0.4, 1.1) + Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)) * spread
		_drop(pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)), v)


func _body_chunks(b: Dictionary, pos: Vector3, count: int, speed: float, up: float) -> void:
	var suit := mat(SUIT[b.idx], 0.9)
	var skin := mat(C_SKIN, 0.7)
	for i in count:
		var a := randf() * TAU
		var v := Vector3(cos(a), 0, sin(a)) * speed * randf_range(0.3, 1.0) + Vector3(0, up * randf_range(0.5, 1.2), 0)
		var m: Material = flesh_mat
		var r := randf()
		if r < 0.4:
			m = suit
		elif r < 0.55:
			m = skin
		_chunk(pos + Vector3(0, randf_range(0.2, 1.2), 0), v, m, randf_range(0.1, 0.24))


func _update_gibs(dt: float) -> void:
	var i := gibs.size() - 1
	while i >= 0:
		var g: Dictionary = gibs[i]
		i -= 1
		var n: Node3D = g.n
		if g.rest:
			if level == 5 and state == ST_PLAY and n.position.y > 0.3:   # nằm trên băng chuyền thì trôi theo
				n.position.x += belt_v * dt
				if n.position.x > BELT_L / 2.0 - 0.1:
					n.queue_free()
					gibs.remove_at(i + 1)
			continue
		var v: Vector3 = g.v
		v.y -= GRAVITY * dt
		n.position += v * dt
		g.v = v
		if g.chunk:
			n.rotation += (g.spin as Vector3) * dt
		var gy := _gib_ground(n.position)
		if n.position.y < 0.45 and gy == -INF:
			n.queue_free()
			gibs.remove_at(i + 1)
		elif n.position.y <= gy + 0.03 and v.y < 0.0:
			if not g.chunk:
				if g.get("stain", true):
					_decal(n.position, randf_range(0.05, 0.19))
				n.queue_free()
				gibs.remove_at(i + 1)
			else:
				g.b += 1
				_decal(n.position, randf_range(0.12, 0.3))
				if g.b >= 2 or v.length() < 2.5:
					g.rest = true
					n.position.y = gy + float(g.h)
				else:
					n.position.y = gy + 0.04
					g.v = Vector3(v.x * 0.5, -v.y * 0.3, v.z * 0.5)


func kill(b: Dictionary, mode: String, dir := Vector3.ZERO, count := true) -> void:
	if b.out > 0.0:
		return
	var root: Node3D = b.root
	var pos := root.position
	b.out = 3.0
	if count and state == ST_PLAY:
		b.deaths += 1
		if b.deaths == 1:
			b.first_death = lt
	b.dead_mode = mode
	b.dead_t = 0.0
	b.flat = 0.0
	b.doom = -1.0
	(b.tag as Node3D).visible = false
	var mid := pos + Vector3(0, 0.8, 0)
	match mode:
		"crush":
			root.visible = false
			_decal(pos, 1.0)
			_decal(pos + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)), 0.7)
			for k in 46:
				var a := randf() * TAU
				_drop(pos + Vector3(cos(a), 0.15, sin(a)) * 0.9, Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 7.5) + Vector3(0, randf_range(0.5, 2.5), 0))
			_body_chunks(b, pos + Vector3(0, -0.6, 0), 7, 5.5, 1.5)
		"grind":
			root.visible = false
			var sd := dir if dir != Vector3.ZERO else Vector3.UP
			_spray(pos + Vector3(0, 0.3, 0), 60, sd.normalized(), 9.0, 2.6)
			_body_chunks(b, pos, 8, 3.0, 8.0 if dir == Vector3.ZERO else 5.0)
		"halved":
			(b.upper as Node3D).visible = false
			var u := Node3D.new()
			level_root.add_child(u)
			u.position = pos + Vector3(0, 0.85, 0)
			u.rotation = root.rotation
			u.scale = Vector3.ONE * BEAN_SCALE
			_build_upper(u, b.idx)
			_chunk_node(u, dir * 5.5 + Vector3(0, 4.5, 0), 0.16)
			_spray(mid, 46, dir, 6.0, 2.2)
			_spray(mid, 14, Vector3.UP, 4.0, 1.0)
			_decal(pos, 0.6)
		"burst":
			root.visible = false
			_decal(pos, 1.5, scorch_mat)
			_decal(pos, 0.8)
			for k in 70:
				var a2 := randf() * TAU
				_drop(mid, Vector3(cos(a2), 0, sin(a2)) * randf_range(1.5, 8.5) + Vector3(0, randf_range(1.0, 7.0), 0))
			_body_chunks(b, pos, 14, 7.0, 6.0)
		"headpop":
			(b.head as Node3D).visible = false
			var np := pos + Vector3(0, 1.55, 0)
			_spray(np, 26, Vector3.UP, 5.0, 2.2)
			for k in 6:
				var a3 := randf() * TAU
				_chunk(np, Vector3(cos(a3), 0, sin(a3)) * randf_range(1.0, 4.0) + Vector3(0, randf_range(3.0, 6.0), 0), flesh_mat if k % 2 == 0 else mat(C_SKIN, 0.7), randf_range(0.07, 0.13))
		"fry":
			_char(root)
			_decal(pos, 0.7, scorch_mat)
			for k in 22:
				var a4 := randf() * TAU
				_drop(mid + Vector3(0, randf_range(-0.5, 0.6), 0), Vector3(cos(a4), 0, sin(a4)) * randf_range(1.0, 4.5) + Vector3(0, randf_range(1.0, 5.0), 0), spark_mat, false)
	stamp_t = 1.3
	flash = 1.0
	shake = 1.0
	monitor_t = 2.6
	monitor.text = "ĐỐI TƯỢNG %s\nĐÃ LOẠI BỎ" % SUBJ[b.idx]
	monitor.modulate = Color(1.0, 0.15, 0.1)


# =====================================================================
#  NẠP BÀI THỬ
# =====================================================================
func _build_bean_nodes(b: Dictionary, pos: Vector3) -> void:
	var i: int = b.idx
	var root := Node3D.new()
	level_root.add_child(root)
	root.position = pos
	root.scale = Vector3.ONE * BEAN_SCALE
	root.rotation.y = randf_range(-0.4, 0.4)
	var trousers := grime(Color(0.17, 0.16, 0.13), 0.0, 0.8, 0.0, 26.0, 0.95)
	var lower := Node3D.new()
	root.add_child(lower)
	var hips: Array[Node3D] = []
	for sx in [-1.0, 1.0]:
		var hp := Node3D.new()
		lower.add_child(hp)
		hp.position = Vector3(0.115 * sx, 0.8, 0)
		capsule(hp, 0.095, 0.8, trousers, Vector3(0, -0.4, 0))
		box(hp, Vector3(0.15, 0.11, 0.28), mat(Color(0.04, 0.035, 0.03), 0.7), Vector3(0, -0.75, 0.045))
		hips.append(hp)
	var pelvis := ball(lower, 0.2, trousers, Vector3(0, 0.82, 0))
	pelvis.scale = Vector3(1.15, 0.7, 0.82)
	var upper := Node3D.new()
	root.add_child(upper)
	upper.position = Vector3(0, 0.82, 0)
	var u := _build_upper(upper, i)
	var tag := label3d(root, SUBJ[i], Vector3(0, 2.35, 0), 36, Color(0.92, 0.88, 0.75), 0.006)
	tag.shaded = false
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.outline_size = 10
	tag.outline_modulate = Color(0, 0, 0)
	b["root"] = root
	b["lower"] = lower
	b["upper"] = upper
	b["hips"] = hips
	b["sh"] = u.sh
	b["head"] = u.head
	b["neck"] = u.neck
	b["led"] = u.led
	b["tag"] = tag

func _char(n: Node) -> void:
	# cháy đen toàn thân
	for c in n.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).material_override = scorch_mat
		elif c is Label3D:
			(c as Label3D).visible = false
		_char(c)

# =====================================================================
#  TRẬN ĐẤU: 10 cửa, chấm điểm sau mỗi cửa, chốt điểm ở cuối
# =====================================================================
func start_match() -> void:
	totals = [0, 0, 0, 0]
	total_deaths = [0, 0, 0, 0]
	load_door(0, true)

func _set_state(s: int) -> void:
	state = s
	state_t = 0.0

func load_door(d: int, intro: bool) -> void:
	door = clampi(d, 0, 9)
	level = ORDER[door]
	if level_root:
		remove_child(level_root)
		level_root.queue_free()
	level_root = Node3D.new()
	add_child(level_root)
	beans.clear()
	tiles.clear()
	rollers.clear()
	saws.clear()
	paint_mats.clear()
	gibs.clear()
	corpses.clear()
	cleats.clear()
	crates.clear()
	belt_items.clear()
	elec.clear()
	pends.clear()
	weights.clear()
	fire_cells.clear()
	decal_n = 0
	core = null
	lt = 0.0
	stamp_t = 0.0
	flash = 0.0
	shake = 0.0
	speak_t = 0.0
	monitor_t = 0.0
	seed(door * 7 + 3)
	cam_base = Vector3(5.2, 4.95, 5.7)
	cam_look = Vector3(-0.6, 0.5, -0.5)
	match level:
		0: _build_level_press()
		1: _build_level_tiles()
		2: _build_level_arm()
		3: _build_level_core()
		4: _build_level_paint()
		5: _build_level_belt()
		6: _build_level_elec()
		7: _build_level_pend()
		8: _build_level_weights()
		9: _build_level_fire()
	cam.position = cam_base
	cam.look_at(cam_look)
	hud_title.text = "CỬA %d/10  ·  %s" % [door + 1, LEVEL_NAMES[level]]
	hud_rule.text = LEVEL_RULES[level]
	hud_sub.get_parent().visible = false
	_set_state(ST_INTRO if intro else ST_PLAY)

func _rank(metric: Array) -> Array:
	# xếp hạng kiểu thi đấu: đồng hạng thì cùng thứ hạng (1, 1, 3, 4). metric nhỏ hơn là tốt hơn.
	var ranks := [1, 1, 1, 1]
	for i in 4:
		for j in 4:
			if float(metric[j]) < float(metric[i]):
				ranks[i] += 1
	return ranks

func _end_round() -> void:
	var metric := []
	for b in beans:
		# ít lần chết hơn thì xếp trên; bằng nhau thì ai chết lần đầu muộn hơn xếp trên
		metric.append(-float(b.score) if level == 4 else float(b.deaths) * 1000.0 - minf(float(b.first_death), ROUND_TIME + 1.0))
	var ranks := _rank(metric)
	last_rows.clear()
	for i in 4:
		var pts: int = POINTS[int(ranks[i]) - 1]
		totals[i] += pts
		total_deaths[i] += int(beans[i].deaths)
		var detail := ("%d Ô" % int(beans[i].score)) if level == 4 else ("CHẾT %d LẦN" % int(beans[i].deaths))
		last_rows.append({"idx": i, "rank": int(ranks[i]), "detail": detail, "pts": pts, "total": int(totals[i])})
	last_rows.sort_custom(func(a, c): return a.rank < c.rank or (a.rank == c.rank and a.idx < c.idx))
	_set_state(ST_RESULT)
	if level == 4:   # sàn cảm ứng: ai không đứng đầu thì nổ vòng cổ
		var kth := 0
		for i in 4:
			if int(ranks[i]) > 1:
				beans[i].doom = 0.7 + 0.45 * kth
				kth += 1
	announce("CỬA %d KẾT THÚC. ĐANG CHẤM ĐIỂM." % (door + 1))
	if shot_path != "" and not frozen:
		print("RESULT door=%d totals=%s" % [door + 1, str(totals)])

func _enter_final() -> void:
	_set_state(ST_FINAL)
	var metric := []
	for i in 4:
		metric.append(-float(totals[i]) * 1000.0 + float(total_deaths[i]))   # bằng điểm thì ai chết ít hơn xếp trên
	var ranks := _rank(metric)
	last_rows.clear()
	var best := 0
	var kth := 0
	for i in 4:
		var verdict := "ĐƯỢC GIỮ LẠI" if int(ranks[i]) == 1 else "LOẠI BỎ"
		last_rows.append({"idx": i, "rank": int(ranks[i]), "detail": "CHẾT %d LẦN" % int(total_deaths[i]), "pts": int(totals[i]), "total": int(totals[i]), "verdict": verdict})
		if int(ranks[i]) == 1:
			best = i
		elif beans[i].out <= 0.0:
			beans[i].doom = 1.2 + 0.6 * kth
			kth += 1
	last_rows.sort_custom(func(a, c): return a.rank < c.rank or (a.rank == c.rank and a.idx < c.idx))
	announce("ĐÃ QUA 10 CỬA. GIỮ LẠI ĐỐI TƯỢNG %s. LOẠI BỎ PHẦN CÒN LẠI." % SUBJ[best])
	speak_t = 999.0

func _run_executions() -> void:
	for b in beans:
		var doom: float = b.doom
		if doom > 0.0 and b.out <= 0.0:
			b.scared = true
			if state_t >= doom:
				kill(b, "headpop", Vector3.ZERO, false)


func _build_platform(r: float) -> void:
	var hazard := shader_mat("res://shaders/hazard.gdshader")
	var plate := grime(Color(0.26, 0.24, 0.20), 0.55, 0.8, 0.5, 14.0, 0.6)
	cyl(level_root, r + 0.18, r + 0.3, PLATFORM_TOP - 0.06, hazard, Vector3(0, (PLATFORM_TOP - 0.06) / 2.0, 0), Vector3.ZERO, 40)
	cyl(level_root, r, r, PLATFORM_TOP, plate, Vector3(0, PLATFORM_TOP / 2.0, 0), Vector3.ZERO, 40)
	cyl(level_root, 0.4, 0.4, 0.02, mat(Color(0.02, 0.02, 0.02), 0.8, 0.5), Vector3(0, PLATFORM_TOP + 0.005, 0), Vector3.ZERO, 10)
	for i in 10:
		var a := i * TAU / 10.0
		cyl(level_root, 0.09, 0.09, 0.03, mat(C_STEEL_DARK, 0.4, 0.8), Vector3(cos(a) * (r - 0.25), PLATFORM_TOP + 0.01, sin(a) * (r - 0.25)), Vector3.ZERO, 6)
	# máu cũ từ những lượt thử trước
	for i in 9:
		var q := _rand_circle(0.3, r - 0.4)
		var d := add_mesh(level_root, disc_mesh, mat(Color(0.12, 0.012, 0.01), 0.35), Vector3(q.x, PLATFORM_TOP + 0.004 + i * 0.0004, q.y))
		d.scale = Vector3(randf_range(0.2, 0.7), 1, randf_range(0.2, 0.6))
		d.rotation.y = randf() * TAU


func _spawn_circle(radius: float, offset := 0.6) -> void:
	for i in 4:
		var a := i * TAU / 4.0 + offset
		make_bean(i, Vector3(cos(a) * radius, PLATFORM_TOP, sin(a) * radius))


func _rand_circle(rmin: float, rmax: float) -> Vector2:
	var a := randf() * TAU
	var r := sqrt(randf_range(rmin * rmin, rmax * rmax))
	return Vector2(cos(a) * r, sin(a) * r)


# ---------- BÀI 1: MÁY ÉP ----------
func _build_level_press() -> void:
	_build_platform(PLATFORM_R)
	var hazard := shader_mat("res://shaders/hazard.gdshader")
	box(level_root, Vector3(2.6, 0.012, 2.6), mat(Color(0.40, 0.04, 0.03), 0.6), Vector3(PRESS_POS.x, PLATFORM_TOP + 0.006, PRESS_POS.y))
	box(level_root, Vector3(2.2, 0.014, 2.2), mat(Color(0.10, 0.03, 0.03), 0.3, 0.4), Vector3(PRESS_POS.x, PLATFORM_TOP + 0.008, PRESS_POS.y))
	press = Node3D.new()
	level_root.add_child(press)
	box(press, Vector3(2.3, 1.1, 2.3), grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.5, 14.0), Vector3(0, 0.75, 0))
	box(press, Vector3(2.4, 0.22, 2.4), hazard, Vector3(0, 0.11, 0))
	box(press, Vector3(2.32, 0.12, 2.32), mat(Color(0.18, 0.01, 0.01), 0.2), Vector3(0, 0.03, 0))
	cyl(press, 0.42, 0.42, 7.0, mat(Color(0.55, 0.56, 0.54), 0.2, 0.95), Vector3(0, 4.8, 0))
	cyl(press, 0.6, 0.6, 0.3, mat(C_STEEL, 0.5, 0.75), Vector3(0, 1.45, 0))
	for k in 5:  # vệt máu chảy trên thân máy
		box(press, Vector3(randf_range(0.06, 0.2), randf_range(0.3, 0.8), 0.01), blood_mat, Vector3(randf_range(-0.9, 0.9), 0.5, 1.156))
	beacon_mat = mat(Color(1.0, 0.1, 0.05), 0.3, 0.0, 2.0)
	ball(press, 0.12, beacon_mat, Vector3(0.85, 1.4, 0.85))
	ball(press, 0.12, beacon_mat, Vector3(-0.85, 1.4, 0.85))
	press_light = omni(press, Vector3(0, -0.3, 1.6), Color(1.0, 0.1, 0.05), 0.0, 7.0)
	box(level_root, Vector3(2.0, 0.7, 2.0), grime(Color(0.16, 0.15, 0.13), 0.5, 0.7, 0.5), Vector3(PRESS_POS.x, 5.05, PRESS_POS.y))
	press.position = Vector3(PRESS_POS.x, PRESS_HIGH, PRESS_POS.y)
	press_stage = 0
	var spots := [Vector2(-1.5, 1.6), Vector2(-0.4, -1.9), Vector2(-2.5, -0.4), Vector2(2.3, 1.9)]
	for i in 4:
		make_bean(i, Vector3(spots[i].x, PLATFORM_TOP, spots[i].y))


func _press_height(p: float) -> float:
	var low := PLATFORM_TOP + 0.06
	if p < 2.0:
		return PRESS_HIGH
	if p < 2.6:
		return PRESS_HIGH + sin(p * 70.0) * 0.03
	if p < 2.74:
		var k := (p - 2.6) / 0.14
		return lerpf(PRESS_HIGH, low, k * k)
	if p < 3.9:
		return low
	return lerpf(low, PRESS_HIGH, smoothstep(0.0, 1.0, (p - 3.9) / (CYCLE - 3.9)))


func _in_press_zone(p: Vector3, half: float) -> bool:
	return absf(p.x - PRESS_POS.x) < half and absf(p.z - PRESS_POS.y) < half


func _update_press(_dt: float) -> void:
	var pp := fmod(lt, CYCLE)
	press.position = Vector3(PRESS_POS.x, _press_height(pp), PRESS_POS.y)
	var warn := pp > 1.4 and pp < 2.74
	var blink := 0.5 + 0.5 * sin(t * 22.0)
	press_light.light_energy = (4.0 * blink) if warn else (1.5 if pp >= 2.74 and pp < 3.9 else 0.0)
	beacon_mat.emission_energy_multiplier = (1.0 + 6.0 * blink) if warn else 1.2
	if pp < 1.4:
		press_stage = 0
	if press_stage == 0 and pp >= 1.4:
		press_stage = 1
		for b in beans:
			b.flee = randf() < 0.45
	if press_stage == 1 and pp >= 2.6:
		press_stage = 2
		for b in beans:
			if b.out <= 0.0 and _in_press_zone((b.root as Node3D).position, 1.3):
				b.flat = 0.3   # đứng chết trân
	if press_stage == 2 and pp >= 2.74:
		press_stage = 3
		shake = 1.0
		for b in beans:
			if b.flat > 0.0 and b.out <= 0.0:
				kill(b, "crush")
				announce("ĐỐI TƯỢNG %s: ĐỘ DÀY KHÔNG ĐẠT." % SUBJ[b.idx])
	for b in beans:
		if warn and _in_press_zone((b.root as Node3D).position, 1.5):
			b.scared = true


# ---------- BÀI 2: SÀN NGHIỀN ----------
func _tile_half() -> float:
	return TILE_N * TILE_S / 2.0


func _tile_center(ix: int, iz: int) -> Vector3:
	return Vector3(-_tile_half() + (ix + 0.5) * TILE_S, TILE_TOP, -_tile_half() + (iz + 0.5) * TILE_S)


func _tile_at(p: Vector3) -> int:
	var ix := int(floor((p.x + _tile_half()) / TILE_S))
	var iz := int(floor((p.z + _tile_half()) / TILE_S))
	if ix < 0 or iz < 0 or ix >= TILE_N or iz >= TILE_N:
		return -1
	return iz * TILE_N + ix


func _build_level_tiles() -> void:
	cam_base = Vector3(5.6, 5.0, 6.1)
	cam_look = Vector3(-0.7, 0.9, -0.6)
	var h := _tile_half()
	var wall_m := grime(Color(0.20, 0.19, 0.16), 0.6, 0.8, 0.5, 14.0)
	var hazard := shader_mat("res://shaders/hazard.gdshader")
	for s in [-1.0, 1.0]:
		box(level_root, Vector3(h * 2 + 0.9, 1.0, 0.35), wall_m, Vector3(0, 0.5, s * (h + 0.28)))
		box(level_root, Vector3(0.35, 1.0, h * 2 + 0.9), wall_m, Vector3(s * (h + 0.28), 0.5, 0))
		box(level_root, Vector3(h * 2 + 0.95, 0.12, 0.4), hazard, Vector3(0, 1.06, s * (h + 0.28)))
		box(level_root, Vector3(0.4, 0.12, h * 2 + 0.95), hazard, Vector3(s * (h + 0.28), 1.06, 0))
	box(level_root, Vector3(h * 2 + 0.3, 0.05, h * 2 + 0.3), mat(Color(0.10, 0.008, 0.008), 0.15), Vector3(0, 0.03, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(level_root, Vector3(0.22, TILE_TOP, 0.22), wall_m, Vector3(sx * (h + 0.28), TILE_TOP / 2.0, sz * (h + 0.28)))
	# trục nghiền có răng
	var rm := grime(Color(0.30, 0.27, 0.24), 0.6, 0.7, 0.7, 14.0, 0.5)
	var tm := mat(Color(0.30, 0.05, 0.04), 0.3, 0.6)
	for ri in 6:
		var roller := Node3D.new()
		level_root.add_child(roller)
		roller.position = Vector3(0, 0.55, -h + 0.7 + ri * (h * 2 - 1.4) / 5.0)
		roller.rotation_degrees.z = 90.0
		cyl(roller, 0.36, 0.36, h * 2, rm, Vector3.ZERO, Vector3.ZERO, 10)
		for k in 9:
			for j in 4:
				var a := j * TAU / 4.0 + k * 0.5
				box(roller, Vector3(0.2, 0.16, 0.34), tm, Vector3(cos(a) * 0.4, -h + 0.5 + k * (h * 2 - 1.0) / 8.0, sin(a) * 0.4), Vector3(0, -rad_to_deg(a), 0))
		roller.set_meta("dir", 1.0 if ri % 2 == 0 else -1.0)
		rollers.append(roller)
	for pos in [Vector3(-2.2, 1.0, -1.5), Vector3(2.2, 1.0, 1.5)]:
		omni(level_root, pos, Color(1.0, 0.08, 0.04), 4.5, 7.0)
	for iz in TILE_N:
		for ix in TILE_N:
			var v := randf_range(0.8, 1.1)
			var base_col := Color(0.30 * v, 0.28 * v, 0.23 * v)
			var m := grime(base_col, 0.5, 0.8, 0.5, 12.0, 0.6)
			var c := _tile_center(ix, iz)
			var mi := box(level_root, Vector3(TILE_S - 0.17, 0.12, TILE_S - 0.17), m, Vector3(c.x, TILE_TOP - 0.06, c.z))
			tiles.append({"mi": mi, "mat": m, "col": base_col, "state": 0, "hp": 2, "timer": 0.0, "vy": 0.0, "base": mi.position, "home": mi.position})
	var spots := [Vector2i(1, 5), Vector2i(5, 1), Vector2i(1, 1), Vector2i(5, 5)]
	for i in 4:
		make_bean(i, _tile_center(spots[i].x, spots[i].y))


func _update_tiles(dt: float) -> void:
	for r in rollers:
		r.rotate_object_local(Vector3.UP, dt * 3.0 * float(r.get_meta("dir")))
	for b in beans:
		if b.out <= 0.0 and b.ground:
			var ti := _tile_at((b.root as Node3D).position)
			if ti >= 0 and ti != b.last_tile and lt > 1.0:
				b.last_tile = ti
				if tiles[ti].state == 0:
					tiles[ti].hp -= 1
					var tm: ShaderMaterial = tiles[ti].mat
					if tiles[ti].hp <= 0:
						tiles[ti].state = 1
						tiles[ti].timer = 1.4
					else:
						# lần dẫm đầu: tấm sàn võng xuống, đèn cảnh báo đỏ mờ
						tm.set_shader_parameter("base", Color(0.20, 0.09, 0.06))
						tm.set_shader_parameter("emit_e", 0.10)
						(tiles[ti].mi as Node3D).position.y -= 0.035
						tiles[ti].base = (tiles[ti].mi as Node3D).position
	var solid := 0
	for tl in tiles:
		var mi: MeshInstance3D = tl.mi
		var m: ShaderMaterial = tl.mat
		match tl.state:
			0:
				solid += 1
			1:
				tl.timer -= dt
				var k := 1.0 - float(tl.timer) / 1.4
				mi.position = (tl.base as Vector3) + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.025 + Vector3(0, -0.05 * k, 0)
				m.set_shader_parameter("emit_e", 0.10 + k * 1.1)
				if tl.timer <= 0.0:
					tl.state = 2
					tl.vy = 0.0
			2:
				tl.vy -= GRAVITY * dt
				mi.position.y += float(tl.vy) * dt
				mi.rotation.x += dt * 2.0
				mi.rotation.z += dt * 1.3
				if mi.position.y < 0.6:
					tl.state = 3
					mi.visible = false
	if solid < 8:
		_reset_tiles()


func _tile_neighbor_target(p: Vector3) -> Vector3:
	var ti := _tile_at(p)
	if ti < 0:
		return Vector3.ZERO
	var ix := ti % TILE_N
	var iz := ti / TILE_N
	var good: Array[Vector3] = []
	var ok: Array[Vector3] = []
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue
			var nx: int = ix + dx
			var nz: int = iz + dz
			if nx < 0 or nz < 0 or nx >= TILE_N or nz >= TILE_N:
				continue
			var st: int = tiles[nz * TILE_N + nx].state
			if dx != 0 and dz != 0 and (tiles[iz * TILE_N + nx].state > 1 or tiles[nz * TILE_N + ix].state > 1):
				continue
			if st == 0 and tiles[nz * TILE_N + nx].hp == 2:
				good.append(_tile_center(nx, nz))
			elif st == 0:
				ok.append(_tile_center(nx, nz))
	if good.size() > 0 and (ok.size() == 0 or randf() < 0.75):
		return good[randi() % good.size()]
	if ok.size() > 0:
		return ok[randi() % ok.size()]
	return p


# ---------- BÀI 3: LƯỠI CƯA ----------
func _build_level_arm() -> void:
	_build_platform(PLATFORM_R)
	cyl(level_root, 0.6, 0.72, 1.0, grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.5, 14.0), Vector3(0, PLATFORM_TOP + 0.5, 0), Vector3.ZERO, 12)
	arm_root = Node3D.new()
	level_root.add_child(arm_root)
	arm_root.position = Vector3(0, PLATFORM_TOP + 0.32, 0)
	var arm_len := PLATFORM_R - 0.2
	var blade := mat(Color(0.62, 0.63, 0.62), 0.22, 0.95)
	for s in [-1.0, 1.0]:
		box(arm_root, Vector3(arm_len, 0.14, 0.14), mat(C_STEEL_DARK, 0.5, 0.7), Vector3(s * (0.5 + arm_len / 2.0), 0, 0))
		for k in 4:
			var sw := Node3D.new()
			arm_root.add_child(sw)
			sw.position = Vector3(s * (1.15 + k * 0.72), 0.0, 0)
			sw.rotation_degrees.z = 90.0
			cyl(sw, 0.36, 0.36, 0.025, blade, Vector3.ZERO, Vector3.ZERO, 14)
			for j in 7:   # răng cưa
				var a := j * TAU / 7.0
				box(sw, Vector3(0.12, 0.02, 0.1), blade, Vector3(cos(a) * 0.38, 0, sin(a) * 0.38), Vector3(0, -rad_to_deg(a) + 30.0, 0))
			cyl(sw, 0.37, 0.37, 0.012, mat(Color(0.25, 0.01, 0.01), 0.2), Vector3(0, 0.0, 0), Vector3.ZERO, 7).scale = Vector3(0.55, 1, 0.55)
			saws.append(sw)
	cyl(arm_root, 0.45, 0.45, 0.5, mat(C_STEEL, 0.5, 0.75), Vector3(0, 0.75, 0), Vector3.ZERO, 12)
	ball(arm_root, 0.16, glow(Color(1.0, 0.1, 0.05), 4.0), Vector3(0, 1.08, 0))
	omni(arm_root, Vector3(1.2, 0.9, 0), Color(1.0, 0.12, 0.06), 2.5, 5.0)
	arm_angle = 0.0
	_spawn_circle(2.3, 1.2)


func _bean_angle(p: Vector3) -> float:
	return atan2(-p.z, p.x)


func _arm_tta(p: Vector3) -> float:
	return fposmod(_bean_angle(p) - arm_angle, PI) / arm_speed


func _update_arm(dt: float) -> void:
	arm_speed = lerpf(1.5, 3.3, clampf(lt / 32.0, 0.0, 1.0))
	arm_angle += arm_speed * dt
	arm_root.rotation.y = arm_angle
	for sw in saws:
		sw.rotate_object_local(Vector3.UP, dt * 25.0)
	for b in beans:
		if b.out > 0.0 or b.hit_cd > 0.0:
			continue
		var p: Vector3 = (b.root as Node3D).position
		var r := Vector2(p.x, p.z).length()
		if r < 0.75 or r > PLATFORM_R + 0.3 or p.y > PLATFORM_TOP + 0.6:
			continue
		var th := _bean_angle(p)
		var diff := fposmod(th - arm_angle + PI / 2.0, PI) - PI / 2.0
		if absf(diff) * r < 0.3:
			var tang := Vector3(-sin(th), 0, -cos(th))
			var radial := Vector3(cos(th), 0, -sin(th))
			kill(b, "halved", (tang + radial * 0.6).normalized())
			announce("ĐỐI TƯỢNG %s: TÁCH LÀM HAI. GHI NHẬN." % SUBJ[b.idx])


# ---------- BÀI 4: LÕI NỔ ----------
func _build_level_core() -> void:
	_build_platform(PLATFORM_R + 0.2)
	core = Node3D.new()
	level_root.add_child(core)
	cyl(core, 0.17, 0.17, 0.42, mat(Color(0.12, 0.12, 0.11), 0.5, 0.7), Vector3.ZERO, Vector3.ZERO, 10)
	for y in [-0.14, 0.14]:
		cyl(core, 0.185, 0.185, 0.05, mat(C_RUST, 0.8, 0.4), Vector3(0, y, 0), Vector3.ZERO, 10)
	core_mat = glow(Color(1.0, 0.12, 0.05), 3.0)
	cyl(core, 0.178, 0.178, 0.12, core_mat, Vector3.ZERO, Vector3.ZERO, 10)
	for k in 3:
		cyl(core, 0.012, 0.012, 0.3, mat(Color(0.5, 0.05, 0.05), 0.5), Vector3(cos(k * 2.1) * 0.19, 0.05, sin(k * 2.1) * 0.19), Vector3(0, 0, 12), 5)
	core_light = omni(core, Vector3(0, 0.1, 0), Color(1.0, 0.15, 0.06), 2.0, 6.0)
	box(level_root, Vector3(2.7, 2.1, 0.12), mat(Color(0.02, 0.02, 0.02), 0.4), Vector3(-3.9, 2.35, -5.5))
	var cap := label3d(level_root, "KÍCH NỔ SAU", Vector3(-3.9, 3.13, -5.42), 44, C_AMBER, 0.0055)
	cap.shaded = false
	core_display = label3d(level_root, "10", Vector3(-3.9, 2.17, -5.42), 230, Color(1.0, 0.12, 0.08), 0.0062)
	core_display.shaded = false
	core_timer = 10.0
	core_holder = 1
	core_cd = 0.0
	core_wait = 0.0
	_spawn_circle(2.5, 0.3)


func _update_core(dt: float) -> void:
	core_cd = maxf(0.0, core_cd - dt)
	if core_wait > 0.0:
		core_wait -= dt
		core.visible = false
		core_light.light_energy = 0.0
		core_display.text = "00"
		if core_wait <= 0.0:
			core_timer = 10.0
			core_holder = (core_holder + 1 + randi() % 3) % 4
		return
	core_timer -= dt
	var h: Dictionary = beans[core_holder]
	var hp: Vector3 = (h.root as Node3D).position
	core.visible = true
	core_phase += lerpf(5.0, 34.0, 1.0 - core_timer / 10.0) * dt
	var pulse := 1.0 if sin(core_phase) > 0.2 else 0.0
	core.position = hp + Vector3(0, 2.28 * BEAN_SCALE, 0)
	core.rotation.y = (h.root as Node3D).rotation.y
	core_mat.emission_energy_multiplier = 0.4 + 6.0 * pulse
	core_light.light_energy = 0.4 + 3.2 * pulse
	core_display.text = "%02d" % int(ceil(maxf(core_timer, 0.0)))
	h.scared = true   # hai tay giơ cao ôm lõi
	h.speed = 4.1
	if core_cd <= 0.0:
		for o in beans:
			if o.idx != core_holder and o.out <= 0.0 and hp.distance_to((o.root as Node3D).position) < 0.95:
				core_holder = o.idx
				core_cd = 0.9
				break
	if core_timer <= 0.0:
		var v: Dictionary = beans[core_holder]
		kill(v, "burst")
		core_wait = 3.0
		announce("ĐỐI TƯỢNG %s: PHÂN TÁN TRÊN DIỆN RỘNG." % SUBJ[v.idx])


# ---------- BÀI 5: SÀN CẢM ỨNG ----------
func _build_level_paint() -> void:
	cam_base = Vector3(5.6, 5.0, 6.1)
	cam_look = Vector3(-0.7, 0.3, -0.6)
	box(level_root, Vector3(PAINT_W + 0.5, 0.5, PAINT_H + 0.5), grime(Color(0.16, 0.15, 0.13), 0.5, 0.8, 0.5, 14.0), Vector3(0, 0.25, 0))
	paint_owner = PackedInt32Array()
	for iz in PAINT_H:
		for ix in PAINT_W:
			var m := mat(Color(0.07, 0.075, 0.075), 0.25, 0.3)
			m.emission_enabled = true
			m.emission_energy_multiplier = 0.0
			box(level_root, Vector3(0.92, 0.06, 0.92), m, Vector3(ix - PAINT_W / 2.0 + 0.5, 0.53, iz - PAINT_H / 2.0 + 0.5))
			paint_mats.append(m)
			paint_owner.append(-1)
	var corners := [Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(1, 1)]
	for i in 4:
		make_bean(i, Vector3(corners[i].x * (PAINT_W / 2.0 - 0.5), PAINT_TOP, corners[i].y * (PAINT_H / 2.0 - 0.5)))
	paint_done = false
	paint_kill_t = 0.0


func _paint_at(p: Vector3) -> int:
	var ix := int(floor(p.x + PAINT_W / 2.0))
	var iz := int(floor(p.z + PAINT_H / 2.0))
	if ix < 0 or iz < 0 or ix >= PAINT_W or iz >= PAINT_H:
		return -1
	return iz * PAINT_W + ix


func _update_paint(_dt: float) -> void:
	for b in beans:
		if b.ground and b.out <= 0.0:
			var pi := _paint_at((b.root as Node3D).position)
			if pi >= 0 and paint_owner[pi] != b.idx:
				paint_owner[pi] = b.idx
				var c: Color = SUIT[b.idx]
				paint_mats[pi].albedo_color = c.darkened(0.5)
				paint_mats[pi].emission = c.lightened(0.1)
				paint_mats[pi].emission_energy_multiplier = 1.1
	for b in beans:
		b.score = 0
	for o in paint_owner:
		if o >= 0:
			beans[o].score += 1


# =====================================================================
#  ĐIỀU KHIỂN + VẬT LÝ ĐƠN GIẢN
# =====================================================================
func _input_dir() -> Vector3:
	var d := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): d.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): d.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): d.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): d.z += 1.0
	if d != Vector3.ZERO:
		idle_time = 0.0
	return d.normalized()


func _set_target(b: Dictionary, q: Vector2, hold: float) -> void:
	b.target = Vector3(q.x, 0, q.y)
	b.ai_t = hold


func _ai_dir(b: Dictionary, dt: float) -> Vector3:
	var p: Vector3 = (b.root as Node3D).position
	var flat := Vector2(p.x, p.z)
	b.ai_t -= dt
	var tgt: Vector3 = b.target
	var arrived := Vector2(tgt.x - p.x, tgt.z - p.z).length() < 0.2
	var retarget: bool = arrived or b.ai_t <= 0.0
	match level:
		0:
			var pp := fmod(lt, CYCLE)
			if _in_press_zone(p, 1.5) and pp > 1.4 and pp < 2.74 and b.flee:
				var away := flat - PRESS_POS
				if away.length() < 0.05:
					away = Vector2(-1, 0.3)
				_set_target(b, (flat + away.normalized() * 2.5).limit_length(PLATFORM_R - 0.6), 1.0)
			elif retarget:
				if randf() < 0.3:
					_set_target(b, PRESS_POS + Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8)), randf_range(1.5, 3.0))
				else:
					_set_target(b, _rand_circle(0.3, PLATFORM_R - 0.6), randf_range(1.0, 2.5))
		1:
			b.speed = 2.6
			if arrived and b.ai_t > 0.3:
				b.ai_t = 0.3
			if b.ai_t <= 0.0:
				var nt := _tile_neighbor_target(p)
				_set_target(b, Vector2(nt.x, nt.z), 1.6)
		2:
			b.speed = 1.6
			if retarget:
				_set_target(b, _rand_circle(1.5, PLATFORM_R - 0.7), randf_range(1.5, 3.0))
			var tta := _arm_tta(p)
			# thời điểm lưỡi cưa chạm tới phụ thuộc bán kính: đứng càng gần trục thì phải nhảy càng sớm
			var lead := 0.12 + 0.3 / (maxf(flat.length(), 0.8) * arm_speed)
			if tta > 0.9:
				b.decided = false
			elif tta < lead and b.ground and not b.decided:
				b.decided = true
				if randf() > 0.12:
					b.vy = JUMP_V
			b.scared = tta < 0.4 and b.ground
			if tta < 0.7:
				return Vector3.ZERO
		3:
			var lim := PLATFORM_R - 0.3
			if core_wait <= 0.0 and b.idx == core_holder:
				var bd := 1e9
				for o in beans:
					if o.idx != b.idx and o.out <= 0.0:
						var op: Vector3 = (o.root as Node3D).position
						if p.distance_to(op) < bd:
							bd = p.distance_to(op)
							b.target = op
			elif core_wait <= 0.0 and flat.distance_to(Vector2(beans[core_holder].root.position.x, beans[core_holder].root.position.z)) < 3.4:
				var hp: Vector3 = beans[core_holder].root.position
				var away2 := flat - Vector2(hp.x, hp.z)
				var side := 1.0 if b.idx % 2 == 0 else -1.0
				var tang := Vector2(-away2.y, away2.x).normalized() * side
				var edge := clampf(flat.length() / lim, 0.0, 1.0)
				var dir2 := away2.normalized() * (1.0 - 0.75 * edge) + tang * (0.3 + 0.9 * edge)
				_set_target(b, (flat + dir2.normalized() * 1.5).limit_length(lim), 0.5)
			elif retarget:
				_set_target(b, _rand_circle(0.3, lim), randf_range(1.0, 2.0))
		4:
			if retarget:
				var best := Vector2(randf_range(-4, 4), randf_range(-3, 3))
				var bd2 := 1e9
				for k in 7:
					var ix := randi() % PAINT_W
					var iz := randi() % PAINT_H
					if paint_owner[iz * PAINT_W + ix] != b.idx:
						var c := Vector2(ix - PAINT_W / 2.0 + 0.5, iz - PAINT_H / 2.0 + 0.5)
						if c.distance_to(flat) < bd2:
							bd2 = c.distance_to(flat)
							best = c
				_set_target(b, best, 1.6)
		5:
			if retarget:
				b.lane_z = randf_range(-1.8, 1.8)
				b.home_x = randf_range(-3.3, 0.6)
				b.ai_t = randf_range(2.0, 4.0)
				b.target = Vector3(p.x, 0, p.z + 5.0)   # tránh bị coi là "đã tới nơi"
			var tz: float = b.lane_z
			var best_dx := 3.2
			for c in crates:
				var dx: float = p.x - float(c.x)
				if dx > -0.3 and dx < best_dx and absf(p.z - float(c.z)) < float(c.hw) + 0.55 and _hash1(float(c.id) * 3.7 + float(b.idx)) > 0.14:
					best_dx = dx
					var side := 1.0 if p.z >= float(c.z) else -1.0
					var zt := float(c.z) + side * (float(c.hw) + 0.8)
					if absf(zt) > BELT_W / 2.0 - 0.35:
						zt = float(c.z) - side * (float(c.hw) + 0.8)
					tz = zt
			var dvec := Vector3(float(b.home_x) - p.x, 0, (tz - p.z) * 2.0).limit_length(1.0)
			return (dvec + Vector3(-belt_v / 3.3, 0, 0)).limit_length(1.0)
		6:
			var ei := _elec_at(p)
			if elec_phase >= 1 and ei >= 0 and elec[ei].hot:
				b.react = float(b.react) - dt
				if b.react > 0.0:
					return Vector3.ZERO
				var bestc := Vector2(p.x, p.z)
				var bdd := 1e9
				for i in elec.size():
					if not elec[i].hot:
						var c6 := _elec_center(i % EW, i / EW)
						var dd := Vector2(c6.x, c6.z).distance_to(flat)
						if dd < bdd:
							bdd = dd
							bestc = Vector2(c6.x, c6.z)
				_set_target(b, bestc, 0.5)
			elif elec_phase >= 1:
				if ei >= 0:
					var c7 := _elec_center(ei % EW, ei / EW)
					_set_target(b, Vector2(c7.x, c7.z), 0.5)
			elif retarget:
				var c8 := _elec_center(randi() % EW, randi() % EH)
				_set_target(b, Vector2(c8.x, c8.z), randf_range(1.0, 2.0))
		7:
			if retarget or Vector2(tgt.x, tgt.z).distance_to(zone_pos) > 0.95:
				_set_target(b, (zone_pos + _rand_circle(0.0, 0.8)).limit_length(PLATFORM_R - 0.6), randf_range(1.0, 2.2))
			if b.flee:
				for pd in pends:
					var lane: float = pd.lane
					var now := _pend_pos(pd, lt)
					var fut := _pend_pos(pd, lt + 0.3)
					var near := minf(absf(p.x - fut.x), absf(p.x - now.x)) < 1.3 and minf(fut.y, now.y) < PLATFORM_TOP + 2.6
					var dz := p.z - lane
					if near and absf(dz) < 0.75:
						return Vector3(0, 0, 1.0 if dz >= 0.0 else -1.0)
					if near and absf(dz) < 1.05 and (float(b.target.z) - lane) * dz < 0.0:
						return Vector3.ZERO
		8:
			var fleeing := false
			for w in weights:
				if (w.state == 1 or w.state == 2) and flat.distance_to(w.pos) < 1.3 and _hash1(float(w.id) * 1.3 + float(b.idx) * 7.7) > 0.17:
					var away8: Vector2 = flat - (w.pos as Vector2)
					if away8.length() < 0.05:
						away8 = Vector2(1, 0).rotated(float(b.idx) * 1.7)
					_set_target(b, ((w.pos as Vector2) + away8.normalized() * 2.0).limit_length(PLATFORM_R - 0.6), 0.5)
					fleeing = true
			if retarget and not fleeing:
				_set_target(b, _rand_circle(0.3, PLATFORM_R - 0.7), randf_range(1.0, 2.5))
		9:
			if b.ai_t <= 0.0:
				b.off = _rand_circle(0.0, 1.0)
				b.ai_t = randf_range(0.8, 2.0)
			var tq9 := fire_c + (b.off as Vector2) * fire_r * 0.55
			b.target = Vector3(tq9.x, 0, tq9.y)
	tgt = b.target
	var d := Vector3(tgt.x - p.x, 0, tgt.z - p.z)
	return d.normalized() if d.length() > 0.2 else Vector3.ZERO


func _ground_y(p: Vector3) -> float:
	match level:
		1:
			var ti := _tile_at(p)
			return TILE_TOP if ti >= 0 and tiles[ti].state <= 1 else -INF
		4:
			return PAINT_TOP
		5:
			return BELT_TOP
		6:
			return ELEC_TOP
	return PLATFORM_TOP


func _constrain(b: Dictionary, p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z)
	match level:
		0:
			f = f.limit_length(PLATFORM_R - 0.45)
			if press.position.y < PLATFORM_TOP + 1.7 and b.flat <= 0.0:
				var rel := f - PRESS_POS
				if absf(rel.x) < 1.55 and absf(rel.y) < 1.55:
					if absf(rel.x) > absf(rel.y):
						rel.x = 1.55 if rel.x >= 0.0 else -1.55
					else:
						rel.y = 1.55 if rel.y >= 0.0 else -1.55
					f = (PRESS_POS + rel).limit_length(PLATFORM_R - 0.45)
		1:
			var h := _tile_half() - 0.3
			f = f.clamp(Vector2(-h, -h), Vector2(h, h))
		2:
			f = f.limit_length(PLATFORM_R - 0.45)
			if f.length() < 1.05 and p.y < PLATFORM_TOP + 1.2:
				f = (f.normalized() if f.length() > 0.01 else Vector2(1, 0)) * 1.05
		3:
			f = f.limit_length(PLATFORM_R - 0.25)
		4:
			f = f.clamp(Vector2(-PAINT_W / 2.0 + 0.3, -PAINT_H / 2.0 + 0.3), Vector2(PAINT_W / 2.0 - 0.3, PAINT_H / 2.0 - 0.3))
		5:
			f.x = maxf(f.x, -BELT_L / 2.0 + 0.35)
			f.y = clampf(f.y, -BELT_W / 2.0 + 0.3, BELT_W / 2.0 - 0.3)
		6:
			f = f.clamp(Vector2(-EW * ES / 2.0 + 0.3, -EH * ES / 2.0 + 0.3), Vector2(EW * ES / 2.0 - 0.3, EH * ES / 2.0 - 0.3))
		_:
			f = f.limit_length(PLATFORM_R - 0.45)
	return Vector3(f.x, p.y, f.y)


func _spawn_point() -> Vector3:
	match level:
		0:
			for k in 20:
				var q := _rand_circle(0.3, PLATFORM_R - 0.7)
				if not _in_press_zone(Vector3(q.x, 0, q.y), 1.7):
					return Vector3(q.x, PLATFORM_TOP, q.y)
		1:
			var solid: Array[int] = []
			for i in tiles.size():
				if tiles[i].state == 0:
					solid.append(i)
			if solid.size() > 0:
				var ti := solid[randi() % solid.size()]
				return _tile_center(ti % TILE_N, ti / TILE_N)
			return _tile_center(3, 3)
		2:
			var q2 := _rand_circle(1.6, PLATFORM_R - 0.8)
			return Vector3(q2.x, PLATFORM_TOP, q2.y)
		4:
			return Vector3(randf_range(-3.5, 3.5), PAINT_TOP, randf_range(-2.5, 2.5))
		5:
			return Vector3(randf_range(-3.6, -1.5), BELT_TOP, randf_range(-1.7, 1.7))
		6:
			return _elec_center(randi() % EW, randi() % EH)
		7:
			var q7 := (zone_pos + _rand_circle(0.0, 0.7)).limit_length(PLATFORM_R - 0.7)
			return Vector3(q7.x, PLATFORM_TOP, q7.y)
		9:
			var q9 := fire_c + _rand_circle(0.0, fire_r * 0.5)
			return Vector3(q9.x, PLATFORM_TOP, q9.y)
	var q3 := _rand_circle(0.3, PLATFORM_R - 0.8)
	return Vector3(q3.x, PLATFORM_TOP, q3.y)


func _respawn(b: Dictionary) -> void:
	# đối tượng thay thế được thả xuống từ ống trên trần; xác cũ nằm lại
	var old: Node3D = b.root
	if old.visible and level != 5 and (b.dead_mode == "halved" or b.dead_mode == "headpop" or b.dead_mode == "fry"):
		corpses.append(old)
		if corpses.size() > 7:
			(corpses.pop_front() as Node3D).queue_free()
	else:
		old.queue_free()
	var sp := _spawn_point()
	_build_bean_nodes(b, sp + Vector3(0, 4.0, 0))
	(b.root as Node3D).rotation = Vector3(0, randf() * TAU, 0)
	b.out = 0.0
	b.knock = Vector3.ZERO
	b.vy = 0.0
	b.dead_mode = ""
	b.last_tile = -1
	b.outside_t = 0.0
	b.target = sp
	b.ground = false
	b.hit_cd = 1.2


func _update_bean(b: Dictionary, dt: float) -> void:
	var root: Node3D = b.root
	if b.out > 0.0:
		b.out -= dt
		b.dead_t += dt
		if b.dead_mode == "headpop" and b.dead_t < 1.3 and randf() < 0.7:
			var np: Vector3 = (b.neck as Node3D).global_position
			_drop(np, Vector3(randf_range(-0.8, 0.8), randf_range(3.0, 5.5) * (1.0 - float(b.dead_t) / 1.6), randf_range(-0.8, 0.8)))
		if b.dead_mode == "halved" and b.dead_t < 0.8 and randf() < 0.6:
			_drop(root.position + Vector3(0, 0.75, 0), Vector3(randf_range(-1.2, 1.2), randf_range(1.5, 3.5), randf_range(-1.2, 1.2)))
		if b.out <= 0.0:
			if state == ST_PLAY:
				_respawn(b)
			else:
				b.out = 0.01   # hết cửa rồi: nằm lại đó
		return
	var p := root.position
	if state != ST_PLAY:
		# ngoài giờ thi: đứng yên, chỉ rơi xuống đất nếu đang lơ lửng
		var g0 := _ground_y(p)
		if g0 > -1000.0 and p.y > g0:
			b.vy = float(b.vy) - GRAVITY * dt
			p.y = maxf(g0, p.y + float(b.vy) * dt)
			root.position = p
		b.ground = true
		b.moving = false
		return
	var d := Vector3.ZERO
	var human: bool = false
	if b.idx == 0:
		var inp := _input_dir()
		human = idle_time < 3.0
		if human:
			d = inp
			if jump_req and b.ground:
				b.vy = JUMP_V
	if not human:
		d = _ai_dir(b, dt)
	if b.flat > 0.0:
		b.flat -= dt
		d = Vector3.ZERO
	p += d * float(b.speed) * dt
	if level == 5 and b.ground:
		p.x += belt_v * dt
	p = _constrain(b, p)
	var g := _ground_y(p)
	var vy: float = b.vy
	vy -= GRAVITY * dt
	p.y += vy * dt
	if p.y <= g:
		p.y = g
		vy = 0.0
		b.ground = true
	else:
		b.ground = false
	b.vy = vy
	root.position = p
	b.moving = d.length() > 0.1
	if b.moving:
		var face := d
		if level == 5:
			face = Vector3(-1, 0, d.z * 0.6)   # luôn quay mặt ngược chiều băng chuyền
		root.rotation.y = lerp_angle(root.rotation.y, atan2(face.x, face.z), 1.0 - exp(-12.0 * dt))
	if level == 1 and p.y < 0.85:
		kill(b, "grind")
		announce("ĐỐI TƯỢNG %s: ĐÃ ĐƯỢC TÁI CHẾ." % SUBJ[b.idx])
	elif level == 5 and p.x > BELT_L / 2.0 - 0.2:
		kill(b, "grind", Vector3(-0.8, 0.6, 0))
		announce("ĐỐI TƯỢNG %s: ĐÃ QUA MÁY HUỶ." % SUBJ[b.idx])


func _separate() -> void:
	var sep := 0.85 if level == 9 else 0.6
	for i in beans.size():
		for j in range(i + 1, beans.size()):
			var a: Dictionary = beans[i]
			var c: Dictionary = beans[j]
			if a.out > 0.0 or c.out > 0.0:
				continue
			var ra: Node3D = a.root
			var rc: Node3D = c.root
			if absf(ra.position.y - rc.position.y) > 0.9:
				continue
			var dv := Vector2(rc.position.x - ra.position.x, rc.position.z - ra.position.z)
			var dist := dv.length()
			if dist < sep and dist > 0.001:
				var push := dv / dist * (sep - dist) * 0.5
				ra.position -= Vector3(push.x, 0, push.y)
				rc.position += Vector3(push.x, 0, push.y)


func _hash1(x: float) -> float:
	return fposmod(sin(x * 127.1) * 43758.5453, 1.0)


func _bean_visual(b: Dictionary) -> void:
	# chuyển động giật cục kiểu stop-motion: lượng tử hoá thời gian ở 10 khung/giây
	var tq := floorf(t * 10.0) / 10.0
	var ph: float = b.phase
	var hips: Array = b.hips
	var sh: Array = b.sh
	var head: Node3D = b.head
	var upper: Node3D = b.upper
	var lower: Node3D = b.lower
	var root: Node3D = b.root
	var hl := 0.0
	var hr := 0.0
	var sl := 0.0
	var sr := 0.0
	var arm_z := 0.0
	upper.position.x = 0.0
	upper.rotation = Vector3.ZERO
	if b.out > 0.0:
		var k := clampf(float(b.dead_t) / 0.5, 0.0, 1.0)
		match b.dead_mode:
			"halved":
				lower.rotation.x = lerpf(0.0, 1.5, k * k)
			"headpop":
				var kk := clampf((float(b.dead_t) - 0.5) / 0.6, 0.0, 1.0)
				root.rotation.x = lerpf(0.0, -1.5, kk * kk)
				sl = -0.3
				sr = 0.3
			"fry":
				var kf := clampf((float(b.dead_t) - 0.6) / 0.6, 0.0, 1.0)
				root.rotation.x = lerpf(0.0, -1.5, kf * kf)
				if b.dead_t < 0.6:   # giật cứng người trước khi đổ
					sl = -2.2 + (_hash1(tq * 31.0) - 0.5) * 1.2
					sr = -2.2 + (_hash1(tq * 37.0) - 0.5) * 1.2
					upper.position.x = (_hash1(tq * 41.0) - 0.5) * 0.08
	elif not b.ground:
		sl = -2.8
		sr = -2.6
		hl = 0.4
		hr = -0.3
	elif b.moving:
		var sw := sin(tq * 11.0 + ph) * 0.75
		hl = sw
		hr = -sw
		sl = -sw * 0.7
		sr = sw * 0.7
		upper.rotation.x = 0.16
	if b.out <= 0.0 and b.scared:
		sl = -2.75 + (_hash1(tq * 7.0 + ph) - 0.5) * 0.3
		sr = -2.75 + (_hash1(tq * 9.0 + ph) - 0.5) * 0.3
		arm_z = 0.25
		upper.position.x = (_hash1(tq * 13.0 + ph) - 0.5) * 0.04
	(hips[0] as Node3D).rotation.x = hl
	(hips[1] as Node3D).rotation.x = hr
	(sh[0] as Node3D).rotation = Vector3(sl, 0, arm_z)
	(sh[1] as Node3D).rotation = Vector3(sr, 0, -arm_z)
	# đầu thỉnh thoảng giật
	var hq := floorf(t * 2.5 + ph)
	head.rotation.z = (_hash1(hq + ph) - 0.5) * 0.35 if _hash1(hq * 3.1) > 0.55 else 0.0
	head.rotation.y = (_hash1(hq * 1.7 + ph) - 0.5) * 0.9
	var led: StandardMaterial3D = b.led
	var fast: bool = b.scared or float(b.doom) > 0.0 or (level == 3 and b.idx == core_holder and core_wait <= 0.0)
	led.emission_energy_multiplier = (6.0 if sin(t * 30.0) > 0.0 else 0.3) if fast else (4.0 if fmod(t + ph, 1.6) < 1.3 else 0.5)


# =====================================================================
#  VÒNG LẶP CHÍNH
# =====================================================================
func _step(dt: float) -> void:
	t += dt
	idle_time += dt
	state_t += dt
	fan.rotation.y += dt * 1.6
	beacon.rotation.y += dt * 2.4
	var on := not (fmod(t, 2.9) < 0.12 or (fmod(t, 6.1) > 2.0 and fmod(t, 6.1) < 2.5 and fmod(t, 0.16) < 0.08))
	flicker_light.light_energy = 1.6 if on else 0.05
	flicker_mat.emission_energy_multiplier = 4.0 if on else 0.2
	cam_led.emission_energy_multiplier = 4.0 if fmod(t, 1.2) < 0.6 else 0.2
	stamp_t = maxf(0.0, stamp_t - dt)
	flash = maxf(0.0, flash - dt * 2.5)
	shake = maxf(0.0, shake - dt * 2.5)
	speak_t = maxf(0.0, speak_t - dt)
	monitor_t = maxf(0.0, monitor_t - dt)
	for b in beans:
		b.scared = false
		b.speed = 3.3
		b.hit_cd = maxf(0.0, float(b.hit_cd) - dt)
	match state:
		ST_INTRO:
			if state_t >= 2.6:
				_set_state(ST_PLAY)
		ST_PLAY:
			lt += dt
			match level:
				0: _update_press(dt)
				1: _update_tiles(dt)
				2: _update_arm(dt)
				3: _update_core(dt)
				4: _update_paint(dt)
				5: _update_belt(dt)
				6: _update_elec(dt)
				7: _update_pend(dt)
				8: _update_weights(dt)
				9: _update_fire(dt)
		ST_RESULT:
			_run_executions()
		ST_FINAL:
			_run_executions()
	for b in beans:
		_update_bean(b, dt)
	if state == ST_PLAY:
		_separate()
	_update_gibs(dt)
	for b in beans:
		_bean_visual(b)
	_update_fx()
	_update_hud()
	jump_req = false
	if state == ST_PLAY and lt >= ROUND_TIME:
		_end_round()
	elif state == ST_RESULT and state_t >= 6.0:
		if door >= 9:
			_enter_final()
		else:
			load_door(door + 1, true)


func announce(text: String) -> void:
	if shot_path != "" and not frozen:
		print("ann L%d t=%.2f %s" % [level + 1, lt, text])
	hud_sub.text = "CỖ MÁY:  " + text
	speak_t = 3.2


func _update_fx() -> void:
	stamp.visible = stamp_t > 0.0
	if stamp.visible:
		stamp.scale = Vector2.ONE * lerpf(1.0, 1.6, clampf((stamp_t - 1.1) / 0.2, 0.0, 1.0))
	post_mat.set_shader_parameter("flash", flash)
	cam.position = cam_base + Vector3(sin(t * 0.25) * 0.08, sin(t * 90.0) * 0.1 * shake, 0)
	hud_sub.get_parent().visible = speak_t > 0.0
	if monitor_t <= 0.0:
		var cur := "_" if fmod(t, 1.0) < 0.5 else " "
		monitor.text = "CỬA %d/10\n%s%s" % [door + 1, LEVEL_NAMES[level], cur]
		monitor.modulate = C_AMBER
	else:
		monitor.visible = fmod(monitor_t, 0.5) > 0.12
		return
	monitor.visible = true


# =====================================================================
#  HẬU KỲ + HUD kiểu màn hình máy cũ
# =====================================================================
func _mk_label(parent: Node, text: String, size: int, color: Color, pos: Vector2, outline_px := 4) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", outline_px)
	l.position = pos
	parent.add_child(l)
	return l


func _build_post_and_ui() -> void:
	var post_layer := CanvasLayer.new()
	post_layer.layer = 1
	add_child(post_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = shader_mat("res://shaders/post.gdshader")
	rect.material = post_mat
	post_layer.add_child(rect)

	var ui := CanvasLayer.new()
	ui.layer = 2
	add_child(ui)
	hud_title = _mk_label(ui, "", 17, C_AMBER, Vector2(14, 6))
	hud_rule = _mk_label(ui, "", 12, Color(0.80, 0.78, 0.70, 0.8), Vector2(14, 30), 3)
	_mk_label(ui, "WASD: ĐI   SPACE: NHẢY   N: QUA CỬA   1-0: CHỌN CỬA", 10, Color(0.80, 0.78, 0.70, 0.45), Vector2(560, 8), 3)
	hud_timer = _mk_label(ui, "0:30", 28, C_AMBER, Vector2(372, 2), 6)

	var sub_panel := Panel.new()
	var sbp := StyleBoxFlat.new()
	sbp.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	sbp.border_color = Color(0.75, 0.08, 0.05)
	sbp.set_border_width_all(1)
	sbp.border_width_left = 5
	sub_panel.add_theme_stylebox_override("panel", sbp)
	sub_panel.position = Vector2(150, 368)
	sub_panel.size = Vector2(500, 25)
	ui.add_child(sub_panel)
	hud_sub = _mk_label(sub_panel, "", 14, C_AMBER, Vector2(12, 1), 0)

	# thẻ đối tượng: trạng thái, tổng điểm, số lần chết trong cửa này
	for i in 4:
		var card := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.8)
		sb.border_color = Color(0.35, 0.33, 0.28)
		sb.set_border_width_all(1)
		card.add_theme_stylebox_override("panel", sb)
		card.position = Vector2(140 + i * 132, 402)
		card.size = Vector2(124, 42)
		ui.add_child(card)
		var chip := ColorRect.new()
		chip.color = SUIT[i].lightened(0.15)
		chip.size = Vector2(6, 42)
		card.add_child(chip)
		_mk_label(card, "ĐT-%s" % SUBJ[i], 14, C_PAPER, Vector2(13, 0), 0)
		var val := _mk_label(card, "", 13, C_AMBER, Vector2(64, 1), 0)
		var pts := _mk_label(card, "", 13, C_PAPER, Vector2(13, 21), 0)
		var dth := _mk_label(card, "", 13, Color(0.9, 0.3, 0.25), Vector2(70, 21), 0)
		hud_cards.append({"val": val, "pts": pts, "dth": dth})

	# chữ giới thiệu cửa
	intro_big = _mk_label(ui, "", 54, C_AMBER, Vector2(0, 150), 10)
	intro_big.size = Vector2(800, 70)
	intro_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_small = _mk_label(ui, "", 16, C_PAPER, Vector2(0, 228), 6)
	intro_small.size = Vector2(800, 24)
	intro_small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# bảng chấm điểm
	ov_panel = Panel.new()
	var sbo := StyleBoxFlat.new()
	sbo.bg_color = Color(0.02, 0.02, 0.015, 0.93)
	sbo.border_color = C_AMBER
	sbo.set_border_width_all(2)
	ov_panel.add_theme_stylebox_override("panel", sbo)
	ov_panel.position = Vector2(150, 70)
	ov_panel.size = Vector2(500, 262)
	ui.add_child(ov_panel)
	ov_title = _mk_label(ov_panel, "", 24, C_AMBER, Vector2(0, 8), 0)
	ov_title.size = Vector2(500, 32)
	ov_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var line := ColorRect.new()
	line.color = Color(1.0, 0.62, 0.15, 0.6)
	line.position = Vector2(20, 46)
	line.size = Vector2(460, 2)
	ov_panel.add_child(line)
	for r in 4:
		var y := 58.0 + r * 42.0
		var chip2 := ColorRect.new()
		chip2.position = Vector2(20, y + 4)
		chip2.size = Vector2(8, 28)
		ov_panel.add_child(chip2)
		ov_rows.append({
			"chip": chip2,
			"rank": _mk_label(ov_panel, "", 24, C_AMBER, Vector2(38, y), 0),
			"name": _mk_label(ov_panel, "", 22, C_PAPER, Vector2(86, y + 1), 0),
			"detail": _mk_label(ov_panel, "", 15, Color(0.75, 0.72, 0.62), Vector2(176, y + 8), 0),
			"pts": _mk_label(ov_panel, "", 22, C_AMBER, Vector2(300, y + 1), 0),
			"total": _mk_label(ov_panel, "", 18, C_PAPER, Vector2(372, y + 5), 0),
		})
	ov_foot = _mk_label(ov_panel, "", 13, Color(0.80, 0.78, 0.70, 0.75), Vector2(0, 234), 0)
	ov_foot.size = Vector2(500, 20)
	ov_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov_panel.visible = false

	stamp = Label.new()
	stamp.text = "ĐÃ LOẠI BỎ"
	stamp.add_theme_font_override("font", font)
	stamp.add_theme_font_size_override("font_size", 44)
	stamp.add_theme_color_override("font_color", Color(0.85, 0.06, 0.04))
	var sbs := StyleBoxFlat.new()
	sbs.bg_color = Color(0.6, 0.0, 0.0, 0.10)
	sbs.border_color = Color(0.85, 0.06, 0.04)
	sbs.set_border_width_all(5)
	sbs.content_margin_left = 16
	sbs.content_margin_right = 16
	sbs.content_margin_bottom = 2
	stamp.add_theme_stylebox_override("normal", sbs)
	ui.add_child(stamp)
	stamp.position = Vector2(24, 150)
	stamp.rotation = -0.12
	stamp.visible = false


func _update_hud() -> void:
	var remain := maxf(0.0, ROUND_TIME - lt)
	hud_timer.text = "0:%02d" % int(ceil(remain))
	hud_timer.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1) if remain < 8.0 else C_AMBER)
	for i in beans.size():
		var b: Dictionary = beans[i]
		var card: Dictionary = hud_cards[i]
		var v: Label = card.val
		if b.out > 0.0:
			v.text = "ĐÃ CHẾT"
			v.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1))
		else:
			v.text = "SỐNG"
			v.add_theme_color_override("font_color", C_AMBER)
		(card.pts as Label).text = "%d ĐIỂM" % int(totals[i])
		(card.dth as Label).text = ("%d Ô" % int(b.score)) if level == 4 else ("CHẾT %d" % int(b.deaths))
	# giới thiệu cửa
	var intro := state == ST_INTRO
	intro_big.visible = intro
	intro_small.visible = intro
	if intro:
		intro_big.text = "CỬA %d/10  ·  %s" % [door + 1, LEVEL_NAMES[level]]
		intro_small.text = LEVEL_RULES[level]
	# bảng chấm điểm sau mỗi cửa và bảng tổng kết
	var show := (state == ST_RESULT and state_t > 0.8) or (state == ST_FINAL and state_t > 3.4)
	ov_panel.visible = show
	stamp.visible = stamp.visible and not show
	if show:
		var fin := state == ST_FINAL
		ov_title.text = "TỔNG KẾT 10 CỬA" if fin else ("KẾT QUẢ CỬA %d/10  ·  %s" % [door + 1, LEVEL_NAMES[level]])
		ov_foot.text = "ENTER: CHƠI LẠI TỪ CỬA 1" if fin else ("HẠNG 1-4: +4 +3 +2 +1   ·   BẰNG SỐ LẦN CHẾT THÌ XÉT AI CHẾT LẦN ĐẦU MUỘN HƠN")
		for r in last_rows.size():
			var row: Dictionary = last_rows[r]
			var w: Dictionary = ov_rows[r]
			(w.chip as ColorRect).color = SUIT[row.idx].lightened(0.15)
			(w.rank as Label).text = "#%d" % int(row.rank)
			(w.name as Label).text = "ĐT-%s" % SUBJ[row.idx]
			(w.detail as Label).text = row.detail
			if fin:
				(w.pts as Label).text = "%d Đ" % int(row.total)
				var vd: String = row.verdict
				(w.total as Label).text = vd
				(w.total as Label).add_theme_color_override("font_color", C_AMBER if vd == "ĐƯỢC GIỮ LẠI" else Color(1.0, 0.2, 0.15))
			else:
				(w.pts as Label).text = "+%d" % int(row.pts)
				(w.total as Label).text = "TỔNG %d" % int(row.total)
				(w.total as Label).add_theme_color_override("font_color", C_PAPER)


# =====================================================================
#  5 CỬA MỚI
# =====================================================================
# ---------- BĂNG CHUYỀN: chạy ngược băng chuyền, né thùng hàng, cuối băng là máy huỷ ----------
func _toothed_roller(parent: Node, pos: Vector3, length: float, radius: float) -> Node3D:
	# trục có răng nằm dọc theo trục z
	var r := Node3D.new()
	parent.add_child(r)
	r.position = pos
	r.rotation_degrees.x = 90.0
	cyl(r, radius, radius, length, grime(Color(0.30, 0.27, 0.24), 0.6, 0.7, 0.7, 14.0, 0.5), Vector3.ZERO, Vector3.ZERO, 10)
	var tm := mat(Color(0.30, 0.05, 0.04), 0.3, 0.6)
	var n := int(length / 0.5)
	for k in n:
		for j in 4:
			var a := j * TAU / 4.0 + k * 0.5
			box(r, Vector3(0.2, 0.16, 0.34), tm, Vector3(cos(a) * (radius + 0.04), -length / 2.0 + 0.3 + k * (length - 0.6) / maxf(n - 1, 1), sin(a) * (radius + 0.04)), Vector3(0, -rad_to_deg(a), 0))
	return r


func _build_level_belt() -> void:
	cam_look = Vector3(-0.2, 0.5, -0.4)
	var hazard := shader_mat("res://shaders/hazard.gdshader")
	var frame := grime(Color(0.18, 0.17, 0.15), 0.6, 0.8, 0.5, 14.0)
	var steel := grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.5, 14.0)
	box(level_root, Vector3(BELT_L + 0.4, BELT_TOP - 0.06, BELT_W + 0.5), frame, Vector3(0, (BELT_TOP - 0.06) / 2.0, 0))
	box(level_root, Vector3(BELT_L, 0.06, BELT_W), mat(Color(0.035, 0.035, 0.035), 0.85), Vector3(0, BELT_TOP - 0.03, 0))
	for s in [-1.0, 1.0]:
		box(level_root, Vector3(BELT_L + 0.4, 0.22, 0.2), hazard, Vector3(0, BELT_TOP + 0.05, s * (BELT_W / 2.0 + 0.2)))
	for i in 12:
		cleats.append(box(level_root, Vector3(0.08, 0.03, BELT_W - 0.1), mat(Color(0.10, 0.10, 0.10), 0.7), Vector3(-BELT_L / 2.0 + i * 0.75, BELT_TOP + 0.012, 0)))
	# đầu nạp: thùng hàng chui ra từ dưới mái che có rèm cao su
	var fx := -BELT_L / 2.0 - 0.35
	box(level_root, Vector3(1.1, 1.3, BELT_W + 0.7), steel, Vector3(fx, BELT_TOP + 1.75, 0))
	for s in [-1.0, 1.0]:
		box(level_root, Vector3(1.1, BELT_TOP + 1.2, 0.25), steel, Vector3(fx, (BELT_TOP + 1.2) / 2.0, s * (BELT_W / 2.0 + 0.25)))
	for k in 7:
		box(level_root, Vector3(0.03, 1.05, 0.58), mat(Color(0.03, 0.03, 0.03), 0.6), Vector3(-BELT_L / 2.0 + 0.12, BELT_TOP + 0.56, -BELT_W / 2.0 + 0.33 + k * 0.657))
	# đầu ra: máy huỷ hai trục răng
	var sx := BELT_L / 2.0 + 0.3
	shred = [_toothed_roller(level_root, Vector3(sx, BELT_TOP - 0.1, 0), BELT_W + 0.3, 0.4), _toothed_roller(level_root, Vector3(sx + 0.15, BELT_TOP + 0.85, 0), BELT_W + 0.3, 0.4)]
	box(level_root, Vector3(1.0, 2.3, BELT_W + 0.8), steel, Vector3(sx + 0.95, 1.15, 0))
	box(level_root, Vector3(1.4, 0.3, BELT_W + 0.8), hazard, Vector3(sx + 0.3, BELT_TOP + 1.55, 0))
	box(level_root, Vector3(0.9, 0.02, BELT_W), blood_mat, Vector3(BELT_L / 2.0 - 0.45, BELT_TOP + 0.004, 0))
	omni(level_root, Vector3(sx - 0.8, BELT_TOP + 1.0, 0), Color(1.0, 0.1, 0.05), 3.0, 5.5)
	belt_v = 1.3
	crate_t = 1.2
	for i in 4:
		var b := make_bean(i, Vector3(-2.6 + 0.5 * (i % 2), BELT_TOP, -1.65 + i * 1.1))
		b.home_x = -2.2 + 0.6 * i


func _update_belt(dt: float) -> void:
	var k := clampf(lt / ROUND_TIME, 0.0, 1.0)
	belt_v = lerpf(1.3, 2.9, k)
	for c in cleats:
		c.position.x += belt_v * dt
		if c.position.x > BELT_L / 2.0:
			c.position.x -= BELT_L
	(shred[0] as Node3D).rotate_object_local(Vector3.UP, dt * 9.0)
	(shred[1] as Node3D).rotate_object_local(Vector3.UP, -dt * 9.0)
	var bi := belt_items.size() - 1
	while bi >= 0:
		var it: Node3D = belt_items[bi]
		it.position.x += belt_v * dt
		if it.position.x > BELT_L / 2.0 - 0.1:
			it.queue_free()
			belt_items.remove_at(bi)
		bi -= 1
	crate_t -= dt
	if crate_t <= 0.0:
		crate_t = lerpf(1.7, 0.85, k) * randf_range(0.8, 1.2)
		crate_id += 1
		var hw := randf_range(0.55, 1.05)
		var cz := randf_range(-BELT_W / 2.0 + hw + 0.05, BELT_W / 2.0 - hw - 0.05)
		var node := box(level_root, Vector3(0.7, 0.7, hw * 2.0), grime(Color(0.40, 0.29, 0.16), 0.1, 0.8, 0.0, 16.0, 0.9), Vector3(-BELT_L / 2.0 - 0.2, BELT_TOP + 0.35, cz))
		box(node, Vector3(0.72, 0.08, hw * 2.0 + 0.02), mat(Color(0.12, 0.10, 0.07), 0.8), Vector3(0, 0.2, 0))
		crates.append({"n": node, "x": -BELT_L / 2.0 - 0.2, "z": cz, "hw": hw, "id": crate_id})
	var ci := crates.size() - 1
	while ci >= 0:
		var c: Dictionary = crates[ci]
		c.x += belt_v * dt
		(c.n as Node3D).position.x = c.x
		if c.x > BELT_L / 2.0 - 0.15:
			for j in 4:   # thùng bị nghiền vụn
				_chunk(Vector3(c.x, BELT_TOP + 0.4, float(c.z) + randf_range(-0.5, 0.5)), Vector3(randf_range(-4.0, -1.0), randf_range(2.0, 5.0), randf_range(-2.0, 2.0)), mat(Color(0.40, 0.29, 0.16), 0.9), 0.2)
			(c.n as Node3D).queue_free()
			crates.remove_at(ci)
		ci -= 1
	for b in beans:
		if b.out > 0.0:
			continue
		var root: Node3D = b.root
		var p := root.position
		for c in crates:
			if absf(p.x - float(c.x)) < 0.63 and absf(p.z - float(c.z)) < float(c.hw) + 0.25 and p.y < BELT_TOP + 0.65:
				p.x = float(c.x) + (0.64 if p.x >= float(c.x) - 0.1 else -0.64)
		root.position = p
		b.scared = p.x > 2.6


# ---------- SÀN ĐIỆN: ô nháy vàng sẽ phóng điện, chạy sang ô an toàn ----------
func _elec_center(ix: int, iz: int) -> Vector3:
	return Vector3(-EW * ES / 2.0 + (ix + 0.5) * ES, ELEC_TOP, -EH * ES / 2.0 + (iz + 0.5) * ES)


func _elec_at(p: Vector3) -> int:
	var ix := int(floor((p.x + EW * ES / 2.0) / ES))
	var iz := int(floor((p.z + EH * ES / 2.0) / ES))
	if ix < 0 or iz < 0 or ix >= EW or iz >= EH:
		return -1
	return iz * EW + ix


func _build_level_elec() -> void:
	cam_base = Vector3(5.6, 5.0, 6.1)
	cam_look = Vector3(-0.7, 0.3, -0.6)
	box(level_root, Vector3(EW * ES + 0.5, 0.5, EH * ES + 0.5), grime(Color(0.14, 0.13, 0.11), 0.5, 0.8, 0.5, 14.0), Vector3(0, 0.25, 0))
	for iz in EH:
		for ix in EW:
			var m := grime(Color(0.30, 0.30, 0.27), 0.35, 0.8, 0.7, 12.0, 0.45)
			var c := _elec_center(ix, iz)
			box(level_root, Vector3(ES - 0.12, 0.06, ES - 0.12), m, Vector3(c.x, 0.53, c.z))
			elec.append({"mat": m, "hot": false})
	# cột sứ cách điện và cuộn dây ở bốn góc
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var px: float = sx * (EW * ES / 2.0 + 0.55)
			var pz: float = sz * (EH * ES / 2.0 + 0.55)
			cyl(level_root, 0.16, 0.2, 1.5, grime(Color(0.45, 0.42, 0.34), 0.2, 0.8, 0.0), Vector3(px, 0.75, pz), Vector3.ZERO, 10)
			for k in 4:
				cyl(level_root, 0.26, 0.26, 0.06, grime(Color(0.35, 0.20, 0.10), 0.5, 0.7, 0.6), Vector3(px, 0.4 + k * 0.3, pz), Vector3.ZERO, 10)
			ball(level_root, 0.14, glow(Color(0.6, 0.85, 1.0), 1.2), Vector3(px, 1.6, pz))
	elec_light = omni(level_root, Vector3(0, 1.8, 0), Color(0.6, 0.82, 1.0), 0.0, 10.0)
	elec_phase = 0
	elec_t = 2.0
	var spots := [Vector2i(1, 3), Vector2i(4, 1), Vector2i(1, 1), Vector2i(4, 3)]
	for i in 4:
		make_bean(i, _elec_center(spots[i].x, spots[i].y))


func _update_elec(dt: float) -> void:
	var k := clampf(lt / ROUND_TIME, 0.0, 1.0)
	elec_t -= dt
	match elec_phase:
		0:
			elec_light.light_energy = 0.0
			if elec_t <= 0.0:
				var pat := randi() % 5
				var par := randi() % 2
				var safe := 0
				for i in elec.size():
					var ix := i % EW
					var iz := i / EW
					var hot := false
					match pat:
						0: hot = randf() < 0.55
						1: hot = (ix + iz) % 2 == par
						2: hot = iz % 2 == par
						3: hot = ix % 2 == par
						4: hot = randf() < 0.78
					elec[i].hot = hot
					if not hot:
						safe += 1
				while safe < 4:
					var ri := randi() % elec.size()
					if elec[ri].hot:
						elec[ri].hot = false
						safe += 1
				elec_phase = 1
				elec_t = lerpf(1.25, 0.8, k)
				for b in beans:
					b.react = randf_range(0.08, 0.5) if randf() > 0.1 else 9.0
		1:
			var blink := 0.7 if fmod(t, 0.22) < 0.11 else 0.08
			for e in elec:
				var m: ShaderMaterial = e.mat
				m.set_shader_parameter("emit", Color(1.0, 0.6, 0.1))
				m.set_shader_parameter("emit_e", blink if e.hot else 0.0)
			if elec_t <= 0.0:
				elec_phase = 2
				elec_t = 0.7
				shake = 0.4
		2:
			for e in elec:
				var m2: ShaderMaterial = e.mat
				m2.set_shader_parameter("emit", Color(0.45, 0.70, 1.0))
				m2.set_shader_parameter("emit_e", randf_range(0.5, 1.5) if e.hot else 0.0)
			elec_light.light_energy = randf_range(1.0, 6.0)
			for i in 3:   # tia lửa
				var ri2 := randi() % elec.size()
				if elec[ri2].hot:
					var c := _elec_center(ri2 % EW, ri2 / EW)
					_drop(c + Vector3(randf_range(-0.5, 0.5), 0.1, randf_range(-0.5, 0.5)), Vector3(randf_range(-1.5, 1.5), randf_range(2.0, 5.0), randf_range(-1.5, 1.5)), spark_mat, false)
			for b in beans:
				if b.out > 0.0:
					continue
				var p: Vector3 = (b.root as Node3D).position
				var ei := _elec_at(p)
				if ei >= 0 and elec[ei].hot and p.y < ELEC_TOP + 0.25:
					kill(b, "fry")
					announce("ĐỐI TƯỢNG %s: DẪN ĐIỆN TỐT. GHI NHẬN." % SUBJ[b.idx])
			if elec_t <= 0.0:
				elec_phase = 0
				elec_t = lerpf(1.5, 0.6, k)
				for e in elec:
					e.hot = false
					(e.mat as ShaderMaterial).set_shader_parameter("emit_e", 0.0)
	if elec_phase == 1:
		for b in beans:
			var ei2 := _elec_at((b.root as Node3D).position)
			if ei2 >= 0 and elec[ei2].hot:
				b.scared = true


# ---------- CON LẮC: ba lưỡi rìu đung đưa, phải đứng trong vùng sáng ----------
func _pend_pos(pd: Dictionary, time: float) -> Vector2:
	var th := 0.9 * sin(float(pd.w) * time + float(pd.ph))
	return Vector2(PEND_L * sin(th), PEND_PIVOT - PEND_L * cos(th))


func _build_level_pend() -> void:
	_build_platform(PLATFORM_R)
	var steel := grime(Color(0.30, 0.29, 0.25), 0.6, 0.8, 0.6, 14.0)
	var blade := mat(Color(0.60, 0.61, 0.58), 0.25, 0.95)
	var ws := [1.7, 2.05, 1.5]
	var phs := [0.0, 2.1, 4.0]
	for li in 3:
		var lane: float = LANES[li]
		var n := Node3D.new()
		level_root.add_child(n)
		n.position = Vector3(0, PEND_PIVOT, lane)
		cyl(n, 0.05, 0.05, PEND_L - 0.6, steel, Vector3(0, -(PEND_L - 0.6) / 2.0, 0), Vector3.ZERO, 6)
		box(n, Vector3(0.5, 0.5, 0.16), steel, Vector3(0, -PEND_L + 1.0, 0))
		cyl(n, 0.85, 0.85, 0.05, blade, Vector3(0, -PEND_L + 0.85, 0), Vector3(90, 0, 0), 20)
		cyl(n, 0.86, 0.86, 0.03, mat(Color(0.22, 0.01, 0.01), 0.2), Vector3(0, -PEND_L + 0.85, 0), Vector3(90, 0, 0), 9).scale = Vector3(1.0, 1.0, 1.0)
		box(level_root, Vector3(0.4, 0.3, 0.4), steel, Vector3(0, PEND_PIVOT + 0.1, lane))
		var half := sqrt(PLATFORM_R * PLATFORM_R - lane * lane) - 0.1
		box(level_root, Vector3(half * 2.0, 0.008, 0.1), mat(Color(0.35, 0.04, 0.03), 0.6), Vector3(0, PLATFORM_TOP + 0.006, lane))
		pends.append({"n": n, "lane": lane, "w": ws[li], "ph": phs[li]})
	zone_node = Node3D.new()
	level_root.add_child(zone_node)
	var ring := torus(zone_node, 1.14, 1.24, glow(C_AMBER, 2.2), Vector3(0, 0.02, 0))
	ring.scale = Vector3(1, 0.12, 1)
	var fill := mat(Color(1.0, 0.62, 0.15, 0.10), 0.6)
	fill.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_mesh(zone_node, disc_mesh, fill, Vector3(0, 0.012, 0)).scale = Vector3(1.14, 1, 1.14)
	zone_pos = Vector2(-0.9, 0.85)
	zone_node.position = Vector3(zone_pos.x, PLATFORM_TOP, zone_pos.y)
	zone_t = 5.0
	zone_grace = 2.5
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		make_bean(i, Vector3(zone_pos.x + cos(a) * 0.6, PLATFORM_TOP, zone_pos.y + sin(a) * 0.6))


func _update_pend(dt: float) -> void:
	var k := clampf(lt / ROUND_TIME, 0.0, 1.0)
	for pd in pends:
		var th := 0.9 * sin(float(pd.w) * lt + float(pd.ph))
		(pd.n as Node3D).rotation.z = th
		var bp := _pend_pos(pd, lt)
		var vx := cos(float(pd.w) * lt + float(pd.ph))
		for b in beans:
			if b.out > 0.0 or b.hit_cd > 0.0:
				continue
			var p: Vector3 = (b.root as Node3D).position
			if absf(p.z - float(pd.lane)) < 0.4 and absf(p.x - bp.x) < 0.6 and bp.y - 0.85 < p.y + 1.45 and p.y < bp.y + 0.3:
				kill(b, "halved", Vector3(1.0 if vx >= 0.0 else -1.0, 0.2, 0).normalized())
				announce("ĐỐI TƯỢNG %s: CẮT NGANG THÂN." % SUBJ[b.idx])
	zone_t -= dt
	zone_grace -= dt
	if zone_t <= 0.0:
		var q := zone_pos
		for tries in 12:
			q = _rand_circle(0.0, 2.2)
			if q.distance_to(zone_pos) > 1.6:
				break
		zone_pos = q
		zone_node.position = Vector3(q.x, PLATFORM_TOP, q.y)
		zone_t = lerpf(5.5, 3.6, k)
		zone_grace = 1.7
		for b in beans:
			b.flee = randf() < 0.85
			b.ai_t = 0.0
	for b in beans:
		if b.out > 0.0:
			continue
		var p2: Vector3 = (b.root as Node3D).position
		if Vector2(p2.x, p2.z).distance_to(zone_pos) > 1.22:
			b.scared = true
			if zone_grace <= 0.0:
				b.outside_t = float(b.outside_t) + dt
				if b.outside_t > 0.9:
					kill(b, "headpop")
					announce("ĐỐI TƯỢNG %s: RỜI VÙNG CHỈ ĐỊNH." % SUBJ[b.idx])
		else:
			b.outside_t = 0.0


# ---------- TẠ RƠI: vòng đỏ hiện ở đâu, tạ nện xuống ở đó ----------
func _build_level_weights() -> void:
	_build_platform(PLATFORM_R)
	var steel := grime(Color(0.24, 0.23, 0.20), 0.6, 0.8, 0.6, 14.0)
	for i in 6:
		var n := Node3D.new()
		level_root.add_child(n)
		cyl(n, 0.82, 0.82, 0.8, steel, Vector3(0, 0.4, 0), Vector3.ZERO, 14)
		cyl(n, 0.84, 0.84, 0.1, mat(Color(0.20, 0.01, 0.01), 0.2), Vector3(0, 0.05, 0), Vector3.ZERO, 14)
		cyl(n, 0.3, 0.5, 0.3, steel, Vector3(0, 0.95, 0), Vector3.ZERO, 10)
		cyl(n, 0.045, 0.045, 5.0, mat(C_STEEL_DARK, 0.5, 0.7), Vector3(0, 3.6, 0), Vector3.ZERO, 5)
		n.position = Vector3(0, 7.0, 0)
		var ring := Node3D.new()
		level_root.add_child(ring)
		var tr := torus(ring, 0.80, 0.90, glow(Color(1.0, 0.08, 0.04), 2.5), Vector3(0, 0.02, 0))
		tr.scale = Vector3(1, 0.1, 1)
		var sm := mat(Color(0.5, 0.0, 0.0, 0.28), 0.6)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var sd := add_mesh(ring, disc_mesh, sm, Vector3(0, 0.014, 0))
		ring.visible = false
		weights.append({"n": n, "ring": ring, "shadow": sd, "state": 0, "timer": 0.0, "pos": Vector2.ZERO, "id": i})
	weight_t = 1.5
	weight_id = 10
	_spawn_circle(2.0, 0.9)


func _update_weights(dt: float) -> void:
	var k := clampf(lt / ROUND_TIME, 0.0, 1.0)
	weight_t -= dt
	if weight_t <= 0.0:
		weight_t = lerpf(1.25, 0.5, k)
		for w in weights:
			if w.state == 0:
				var q := _rand_circle(0.0, PLATFORM_R - 0.9)
				if randf() < 0.7:
					var tb: Dictionary = beans[randi() % 4]
					if tb.out <= 0.0:
						var tp: Vector3 = (tb.root as Node3D).position
						q = (Vector2(tp.x, tp.z) + _rand_circle(0.0, 0.45)).limit_length(PLATFORM_R - 0.9)
				weight_id += 1
				w.pos = q
				w.id = weight_id
				w.state = 1
				w.timer = 0.95
				(w.ring as Node3D).position = Vector3(q.x, PLATFORM_TOP, q.y)
				(w.ring as Node3D).visible = true
				(w.n as Node3D).position = Vector3(q.x, 4.55, q.y)
				break
	for w in weights:
		var n: Node3D = w.n
		var wp: Vector2 = w.pos
		match w.state:
			1:
				w.timer -= dt
				var g := 1.0 - float(w.timer) / 0.95
				(w.shadow as Node3D).scale = Vector3(0.82 * g, 1, 0.82 * g)
				n.position = Vector3(wp.x + sin(t * 40.0) * 0.015, 4.55, wp.y)
				if w.timer <= 0.0:
					w.state = 2
					w.timer = 0.1
			2:
				w.timer -= dt
				n.position.y = lerpf(PLATFORM_TOP, 4.55, clampf(float(w.timer) / 0.1, 0.0, 1.0))
				if w.timer <= 0.0:
					w.state = 3
					w.timer = 0.55
					shake = maxf(shake, 0.6)
					(w.ring as Node3D).visible = false
					for b in beans:
						if b.out > 0.0:
							continue
						var p: Vector3 = (b.root as Node3D).position
						if Vector2(p.x, p.z).distance_to(wp) < 0.9:
							kill(b, "crush")
							announce("ĐỐI TƯỢNG %s: CHỊU TẢI KÉM." % SUBJ[b.idx])
			3:
				w.timer -= dt
				if w.timer <= 0.0:
					w.state = 4
					w.timer = 0.7
			4:
				w.timer -= dt
				n.position.y = lerpf(7.0, PLATFORM_TOP, clampf(float(w.timer) / 0.7, 0.0, 1.0))
				if w.timer <= 0.0:
					w.state = 0
		if w.state == 1 or w.state == 2:
			for b in beans:
				if b.out <= 0.0:
					var p2: Vector3 = (b.root as Node3D).position
					if Vector2(p2.x, p2.z).distance_to(wp) < 1.0:
						b.scared = true
	# tạ đang nằm trên sàn thì chắn đường
	for b in beans:
		if b.out > 0.0:
			continue
		var root: Node3D = b.root
		for w in weights:
			if w.state == 3 or (w.state == 4 and w.timer > 0.55):
				var dv := Vector2(root.position.x, root.position.z) - (w.pos as Vector2)
				if dv.length() < 1.1 and dv.length() > 0.01:
					var q2 := (w.pos as Vector2) + dv.normalized() * 1.1
					root.position = Vector3(q2.x, root.position.y, q2.y)


# ---------- VÒNG LỬA (cửa cuối): vùng an toàn co lại và trôi đi, ngoài vùng là lửa ----------
func _build_level_fire() -> void:
	_build_platform(PLATFORM_R)
	var glow_m := mat(Color(1.0, 0.25, 0.03), 0.6, 0.0, 1.6)
	var flame_m := mat(Color(0.5, 0.08, 0.0), 0.5)
	flame_m.emission_enabled = true
	flame_m.emission = Color(1.0, 0.30, 0.03)
	flame_m.emission_energy_multiplier = 1.3
	var core_m := mat(Color(0.6, 0.3, 0.0), 0.5)
	core_m.emission_enabled = true
	core_m.emission = Color(1.0, 0.75, 0.2)
	core_m.emission_energy_multiplier = 1.8
	var step := 0.5
	var nmax := int(PLATFORM_R / step) + 1
	for gx in range(-nmax, nmax + 1):
		for gz in range(-nmax, nmax + 1):
			var q := Vector2(gx * step + (0.25 if gz % 2 != 0 else 0.0), gz * step)
			if q.length() > PLATFORM_R - 0.15:
				continue
			var n := Node3D.new()
			level_root.add_child(n)
			n.position = Vector3(q.x, PLATFORM_TOP, q.y)
			add_mesh(n, disc_mesh, glow_m, Vector3(0, 0.01, 0)).scale = Vector3(0.3, 1, 0.3)
			var fl := cyl(n, 0.0, 0.15, 0.7, flame_m, Vector3(0, 0.35, 0), Vector3.ZERO, 5)
			cyl(fl, 0.0, 0.09, 0.4, core_m, Vector3(0, -0.14, 0.0), Vector3.ZERO, 5).scale = Vector3(1.25, 1, 1.25)
			n.visible = false
			fire_cells.append({"n": n, "p": q, "fl": fl})
	for i in 12:   # vòi ga quanh mép sàn
		var a := i * TAU / 12.0
		cyl(level_root, 0.07, 0.09, 0.3, grime(Color(0.25, 0.22, 0.18), 0.6, 0.7, 0.6), Vector3(cos(a) * (PLATFORM_R + 0.35), 0.35, sin(a) * (PLATFORM_R + 0.35)), Vector3.ZERO, 6)
	fire_ring = torus(level_root, 0.965, 1.0, glow(C_AMBER, 2.0), Vector3(0, PLATFORM_TOP + 0.02, 0))
	fire_light = omni(level_root, Vector3(0, 1.3, 0), Color(1.0, 0.45, 0.1), 0.0, 9.0)
	fire_r = 3.2
	fire_c = Vector2.ZERO
	for i in 4:
		var a2 := i * TAU / 4.0 + 0.5
		var b := make_bean(i, Vector3(cos(a2) * 1.3, PLATFORM_TOP, sin(a2) * 1.3))
		b.off = Vector2(cos(a2), sin(a2))


func _update_fire(dt: float) -> void:
	var k := clampf(lt / ROUND_TIME, 0.0, 1.0)
	fire_r = lerpf(3.2, 0.62, smoothstep(0.0, 1.0, k))
	var amp := maxf(PLATFORM_R - 0.3 - fire_r, 0.0)
	fire_c = Vector2(sin(lt * 0.55) * amp * 0.9, sin(lt * 0.83 + 1.0) * amp * 0.9).limit_length(amp)
	fire_ring.position = Vector3(fire_c.x, PLATFORM_TOP + 0.02, fire_c.y)
	fire_ring.scale = Vector3(fire_r, 0.3, fire_r)
	for c in fire_cells:
		var vis: bool = (c.p as Vector2).distance_to(fire_c) > fire_r + 0.12
		(c.n as Node3D).visible = vis
		if vis:
			(c.fl as Node3D).scale = Vector3(randf_range(0.7, 1.2), randf_range(0.4, 1.7), randf_range(0.7, 1.2))
			(c.fl as Node3D).position.y = 0.35 * (c.fl as Node3D).scale.y
	fire_light.light_energy = 0.8 + 3.5 * k + randf_range(0.0, 0.8)
	for b in beans:
		if b.out > 0.0:
			continue
		var p: Vector3 = (b.root as Node3D).position
		var dist := Vector2(p.x, p.z).distance_to(fire_c)
		if dist > fire_r - 0.35:
			b.scared = true
		if dist > fire_r + 0.05 and b.ground:
			b.outside_t = float(b.outside_t) + dt
			if b.outside_t > 0.3:
				kill(b, "fry")
				announce("ĐỐI TƯỢNG %s: ĐÃ CHÍN." % SUBJ[b.idx])
		else:
			b.outside_t = 0.0


func _reset_tiles() -> void:
	# hết sàn thì lắp lại sàn mới, điểm số trong cửa vẫn giữ
	for tl in tiles:
		var mi: MeshInstance3D = tl.mi
		tl.state = 0
		tl.hp = 2
		mi.visible = true
		mi.position = tl.home
		mi.rotation = Vector3.ZERO
		tl.base = tl.home
		(tl.mat as ShaderMaterial).set_shader_parameter("base", tl.col)
		(tl.mat as ShaderMaterial).set_shader_parameter("emit_e", 0.0)
	for b in beans:
		b.last_tile = -1
