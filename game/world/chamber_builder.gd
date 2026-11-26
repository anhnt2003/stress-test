class_name ChamberBuilder
## Dựng buồng thử bằng code. Chỉ dùng trong công cụ `tools/migrate_scenes.gd` để sinh các file
## `game/world/chamber_*.tscn`; lúc chạy game, buồng được nạp từ .tscn (sửa được trong editor).

const VARIANTS := [
	{"id": "09", "file": "chamber_09.tscn", "label": "BUỒNG THỬ 09", "wall": Color(1, 1, 1), "floor": Color(1, 1, 1),
		"ambient": Color(0.56, 0.54, 0.44), "ambient_e": 0.30, "fog": Color(0.13, 0.11, 0.07), "spot": Color(1.0, 0.90, 0.72),
		"spot_e": 11.0, "lamp": Color(1.0, 0.72, 0.38), "beacon_e": 3.5, "extra": ""},
	{"id": "13", "file": "chamber_13.tscn", "label": "BUỒNG THỬ 13", "wall": Color(0.78, 0.92, 0.86), "floor": Color(0.85, 0.92, 0.88),
		"ambient": Color(0.42, 0.55, 0.50), "ambient_e": 0.28, "fog": Color(0.07, 0.11, 0.09), "spot": Color(0.80, 1.0, 0.86),
		"spot_e": 9.5, "lamp": Color(0.70, 1.0, 0.80), "beacon_e": 2.5, "extra": "fluoro"},
	{"id": "21", "file": "chamber_21.tscn", "label": "BUỒNG THỬ 21", "wall": Color(1.0, 0.80, 0.72), "floor": Color(0.95, 0.80, 0.75),
		"ambient": Color(0.55, 0.30, 0.25), "ambient_e": 0.26, "fog": Color(0.14, 0.05, 0.03), "spot": Color(1.0, 0.62, 0.45),
		"spot_e": 8.0, "lamp": Color(1.0, 0.35, 0.18), "beacon_e": 6.0, "extra": "emergency"},
]


static func _uniq(n: Node, nm: String) -> void:
	n.name = nm
	n.unique_name_in_owner = true


static func build(variant: int) -> Node3D:
	var v: Dictionary = VARIANTS[variant]
	var root := Node3D.new()
	root.name = "Chamber%s" % v.id
	root.set_script(load("res://game/world/chamber.gd"))
	_environment(root, v)
	_room(root, v)
	_lights(root, v)
	_props(root, v)
	_dust(root)
	match String(v.extra):
		"fluoro": _fluoro(root)
		"emergency": _emergency(root)
	return root


static func _vent(parent: Node, pos: Vector3, rot_y: float, r: float) -> void:
	# cửa gió tròn có lá chớp
	var vn := Node3D.new()
	parent.add_child(vn)
	vn.position = pos
	vn.rotation_degrees.y = rot_y
	Build.cyl(vn, r + 0.12, r + 0.12, 0.16, Build.grime(Color(0.30, 0.27, 0.21), 0.5, 0.8, 0.3), Vector3.ZERO, Vector3(90, 0, 0), 14)
	Build.cyl(vn, r, r, 0.18, Build.mat(Color(0.01, 0.01, 0.01), 1.0), Vector3.ZERO, Vector3(90, 0, 0), 14)
	var n := 7
	for i in n:
		var y := -r + (i + 0.5) * (2.0 * r / n)
		var w := 2.0 * sqrt(maxf(r * r - y * y, 0.01))
		Build.box(vn, Vector3(w, 0.05, 0.16), Build.grime(Color(0.26, 0.24, 0.19), 0.5, 0.8, 0.4), Vector3(0, y, 0.08), Vector3(-28, 0, 0))


static func _environment(root: Node3D, v: Dictionary) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = v.ambient
	env.ambient_light_energy = v.ambient_e
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
	env.fog_light_color = v.fog
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
	_uniq(we, "WorldEnv")
	root.add_child(we)


static func _room(parent: Node3D, v: Dictionary) -> void:
	# buồng kín, trần thấp: x ±6.4, z từ -5.6 tới 6.6, trần 5.4
	var room := Node3D.new()
	room.name = "Room"
	parent.add_child(room)
	var wall := Build.shader_mat("res://shaders/wall.gdshader", {"tint": v.wall})
	var floor_m := Build.shader_mat("res://shaders/floor.gdshader", {"tint": v.floor})
	var conc := Build.grime(Color(0.38, 0.33, 0.25), 0.25, 0.8, 0.0, 14.0)
	var steel := Build.grime(Color(0.26, 0.25, 0.22), 0.55, 0.7, 0.5)
	var dark := Build.grime(Color(0.11, 0.10, 0.09), 0.4, 0.6, 0.5)
	var rust := Build.grime(Color(0.30, 0.15, 0.07), 0.8, 0.7, 0.3)
	_uniq(Build.box(room, Vector3(13.6, 0.4, 13.0), floor_m, Vector3(0, -0.2, 0.5)), "Floor")
	_uniq(Build.box(room, Vector3(13.6, 5.8, 0.4), wall, Vector3(0, 2.9, -5.8)), "WallBack")
	Build.box(room, Vector3(13.6, 5.8, 0.4), wall, Vector3(0, 2.9, 6.8))
	Build.box(room, Vector3(0.4, 5.8, 13.0), wall, Vector3(-6.6, 2.9, 0.5))
	Build.box(room, Vector3(0.4, 5.8, 13.0), wall, Vector3(6.6, 2.9, 0.5))
	Build.box(room, Vector3(13.6, 0.3, 13.0), conc, Vector3(0, 5.55, 0.5))
	# dầm trần, gờ tường, trụ
	for z in [-3.0, 0.5, 4.0]:
		Build.box(room, Vector3(12.8, 0.4, 0.4), conc, Vector3(0, 5.2, z))
	Build.box(room, Vector3(12.8, 0.22, 0.25), conc, Vector3(0, 3.5, -5.5))
	Build.box(room, Vector3(0.25, 0.22, 12.2), conc, Vector3(-6.3, 3.5, 0.5))
	Build.box(room, Vector3(12.8, 0.3, 0.2), conc, Vector3(0, 0.15, -5.5))
	Build.box(room, Vector3(0.2, 0.3, 12.2), conc, Vector3(-6.3, 0.15, 0.5))
	for x in [-6.25, -2.1, 2.1, 6.25]:
		Build.box(room, Vector3(0.5, 5.4, 0.35), conc, Vector3(x, 2.7, -5.48))
	for z in [-1.6, 2.6]:
		Build.box(room, Vector3(0.35, 5.4, 0.5), conc, Vector3(-6.28, 2.7, z))
	# ống gỉ và cáp chạy dọc tường
	Build.cyl(room, 0.13, 0.13, 12.6, rust, Vector3(0, 4.75, -5.3), Vector3(0, 0, 90), 8)
	Build.cyl(room, 0.07, 0.07, 12.6, steel, Vector3(0, 4.45, -5.38), Vector3(0, 0, 90), 6)
	Build.cyl(room, 0.10, 0.10, 12.0, rust, Vector3(-6.1, 4.8, 0.5), Vector3(90, 0, 0), 8)
	Build.cyl(room, 0.12, 0.12, 5.4, rust, Vector3(5.9, 2.7, -5.2), Vector3.ZERO, 8)
	for i in 4:
		Build.cyl(room, 0.022, 0.022, 12.0, dark, Vector3(-6.32, 4.25 - i * 0.07, 0.5), Vector3(90, 0, 0), 5)
	# cửa thép đã khoá (tường sau, bên phải)
	Build.box(room, Vector3(1.7, 2.7, 0.14), Build.grime(Color(0.20, 0.21, 0.19), 0.6, 0.7, 0.6), Vector3(4.1, 1.35, -5.55))
	Build.box(room, Vector3(1.9, 0.14, 0.2), dark, Vector3(4.1, 2.78, -5.55))
	Build.box(room, Vector3(0.8, 0.1, 0.05), dark, Vector3(4.1, 1.4, -5.46))
	Build.ball(room, 0.06, Build.glow(Color(1.0, 0.08, 0.05), 3.0), Vector3(4.1, 3.05, -5.5))
	# màn hình của Cỗ Máy (tường sau, giữa)
	Build.box(room, Vector3(4.0, 1.9, 0.3), dark, Vector3(-0.2, 2.35, -5.5))
	var scr := Build.mat(Color(0.02, 0.015, 0.005), 0.15)
	scr.emission_enabled = true
	scr.emission = Color(0.9, 0.5, 0.1)
	scr.emission_energy_multiplier = 0.07
	Build.box(room, Vector3(3.7, 1.6, 0.06), scr, Vector3(-0.2, 2.35, -5.33))
	var monitor := Build.label3d(room, "", Vector3(-0.2, 2.35, -5.29), 76, Palette.AMBER, 0.0058)
	monitor.shaded = false
	monitor.line_spacing = 0.0
	_uniq(monitor, "Monitor")
	for k in 3:   # cáp thòng xuống từ màn hình
		Build.cyl(room, 0.025, 0.025, 1.3, dark, Vector3(-1.4 + k * 0.12, 0.75, -5.5), Vector3.ZERO, 5)
	# cửa gió tròn
	_vent(room, Vector3(-4.0, 4.2, -5.52), 0.0, 0.62)
	_vent(room, Vector3(2.6, 4.2, -5.52), 0.0, 0.62)
	_vent(room, Vector3(-6.32, 4.25, 4.4), 90.0, 0.62)
	# cửa kính phòng quan sát (tường trái) với bóng người đứng nhìn
	var ow := Node3D.new()
	ow.name = "ObservationWindow"
	room.add_child(ow)
	ow.position = Vector3(-6.36, 2.45, 0.5)
	ow.rotation_degrees.y = 90.0
	Build.box(ow, Vector3(3.9, 1.5, 0.14), steel, Vector3(0, 0, -0.02))
	var glass := Build.mat(Color(0.03, 0.035, 0.03), 0.05, 0.3)
	glass.emission_enabled = true
	glass.emission = Color(0.55, 0.60, 0.40)
	glass.emission_energy_multiplier = 0.16
	Build.box(ow, Vector3(3.6, 1.2, 0.08), glass, Vector3(0, 0, 0.03))
	for x in [-1.1, 0.2, 1.2]:
		Build.capsule(ow, 0.2, 0.95, Build.mat(Color(0, 0, 0), 1.0), Vector3(x, -0.22, 0.09))
		Build.ball(ow, 0.15, Build.mat(Color(0, 0, 0), 1.0), Vector3(x, 0.36, 0.09))
	Build.box(ow, Vector3(0.06, 1.2, 0.1), steel, Vector3(-0.45, 0, 0.05))
	# chữ sơn khuôn
	var st := Build.label3d(room, String(v.label), Vector3(-6.38, 1.15, -3.2), 120, Color(0.12, 0.10, 0.08, 0.8), 0.0065)
	st.rotation_degrees.y = 90.0
	var st2 := Build.label3d(room, "KHÔNG TIẾP XÚC\nVỚI ĐỐI TƯỢNG", Vector3(-6.38, 1.25, 4.2), 60, Color(0.45, 0.07, 0.05, 0.85), 0.006)
	st2.line_spacing = 0.0
	st2.rotation_degrees.y = 90.0
	# loa (góc tường sau bên phải) + camera giám sát (tường trái)
	var loa := Node3D.new()
	loa.name = "Speaker"
	room.add_child(loa)
	loa.position = Vector3(5.6, 4.3, -5.1)
	var grey := Build.grime(Color(0.24, 0.24, 0.21), 0.5, 0.7, 0.5)
	for side in [-1.0, 1.0]:
		var horn := Node3D.new()
		loa.add_child(horn)
		horn.rotation_degrees = Vector3(-16, 26.0 * side - 30.0, 0)
		horn.position = Vector3(0.25 * side, 0, 0.1)
		Build.cyl(horn, 0.09, 0.42, 0.75, grey, Vector3(0, 0, 0.42), Vector3(-90, 0, 0), 12)
		Build.cyl(horn, 0.36, 0.36, 0.02, Build.mat(Color(0.01, 0.01, 0.01), 0.9), Vector3(0, 0, 0.81), Vector3(-90, 0, 0), 12)
	var camn := Node3D.new()
	camn.name = "SecurityCam"
	room.add_child(camn)
	camn.position = Vector3(-6.0, 4.6, -4.9)
	camn.rotation_degrees = Vector3(-30, -50, 0)
	Build.box(camn, Vector3(0.28, 0.24, 0.62), grey, Vector3(0, 0, 0.28))
	Build.cyl(camn, 0.1, 0.1, 0.12, dark, Vector3(0, 0, 0.62), Vector3(90, 0, 0), 8)
	_uniq(Build.ball(camn, 0.035, Build.glow(Color(1.0, 0.05, 0.03), 4.0), Vector3(0.09, 0.08, 0.6)), "CamLed")


static func _caged_lamp(parent: Node3D, pos: Vector3, color: Color, energy: float, rng: float) -> Array:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = pos
	var mi := Build.ball(n, 0.1, Build.glow(color, 4.0))
	Build.cyl(n, 0.16, 0.16, 0.05, Build.mat(Palette.STEEL_DARK, 0.6, 0.6), Vector3(0, 0.14, 0), Vector3.ZERO, 8)
	Build.torus(n, 0.12, 0.14, Build.mat(Palette.STEEL_DARK, 0.6, 0.6), Vector3(0, -0.02, 0))
	var l := Build.omni(n, Vector3(0, -0.1, 0.2), color, energy, rng, 0.5)
	return [l, mi]


static func _lights(root: Node3D, v: Dictionary) -> void:
	# chao đèn dây tóc treo giữa buồng
	var hood := Node3D.new()
	hood.name = "HoodLamp"
	root.add_child(hood)
	hood.position = Vector3(0.3, 4.75, 0.4)
	Build.cyl(hood, 0.2, 0.7, 0.4, Build.grime(Color(0.14, 0.15, 0.12), 0.5, 0.6, 0.5), Vector3.ZERO, Vector3.ZERO, 12)
	Build.cyl(hood, 0.62, 0.62, 0.02, Build.glow(Color(v.spot).lerp(Color(1.0, 0.86, 0.55), 0.5), 5.0), Vector3(0, -0.2, 0), Vector3.ZERO, 12)
	Build.cyl(hood, 0.025, 0.025, 0.6, Build.mat(Palette.STEEL_DARK), Vector3(0, 0.5, 0), Vector3.ZERO, 5)
	var sp := SpotLight3D.new()
	sp.light_color = v.spot
	sp.light_energy = v.spot_e
	sp.spot_range = 12.0
	sp.spot_angle = 66.0
	sp.spot_angle_attenuation = 0.9
	sp.spot_attenuation = 0.55
	sp.shadow_enabled = true
	sp.shadow_blur = 1.2
	sp.light_volumetric_fog_energy = 1.0
	_uniq(sp, "MainSpot")
	hood.add_child(sp)
	sp.position = Vector3(0, -0.25, 0)
	sp.rotation_degrees = Vector3(-90, 0, 0)
	# đèn lồng trên tường
	var lamp: Color = v.lamp
	_caged_lamp(root, Vector3(-2.1, 3.9, -5.25), lamp, 1.6, 6.5)
	_caged_lamp(root, Vector3(5.2, 3.3, -5.25), lamp, 1.2, 5.5)
	var fl := _caged_lamp(root, Vector3(-6.05, 3.9, 2.6), lamp.lerp(Color(0.95, 0.85, 0.5), 0.5), 1.6, 6.5)
	_uniq(fl[0], "FlickerLight")
	_uniq(fl[1], "FlickerLamp")
	# đèn báo động xoay cạnh cửa
	var beacon := Node3D.new()
	_uniq(beacon, "Beacon")
	root.add_child(beacon)
	beacon.position = Vector3(4.1, 3.3, -5.3)
	Build.cyl(beacon, 0.11, 0.11, 0.18, Build.glow(Color(1.0, 0.06, 0.03), 3.5), Vector3.ZERO, Vector3.ZERO, 8)
	var bs := SpotLight3D.new()
	bs.light_color = Color(1.0, 0.08, 0.04)
	bs.light_energy = v.beacon_e
	bs.spot_range = 13.0
	bs.spot_angle = 28.0
	bs.light_volumetric_fog_energy = 1.6
	beacon.add_child(bs)
	bs.rotation_degrees = Vector3(-14, 0, 0)
	# ánh hổ phách từ màn hình + đèn phụ ấm phía camera
	Build.omni(root, Vector3(-0.2, 2.4, -4.6), Color(1.0, 0.6, 0.2), 0.5, 4.5, 0.2)
	Build.omni(root, Vector3(4.6, 3.6, 5.2), Color(0.95, 0.92, 0.80), 1.5, 13.0, 0.0)
	# quạt trần quay chậm
	var fan := Node3D.new()
	_uniq(fan, "Fan")
	root.add_child(fan)
	fan.position = Vector3(-3.6, 4.85, 3.4)
	var fm := Build.grime(Color(0.14, 0.13, 0.11), 0.5, 0.6, 0.5)
	Build.cyl(fan, 0.16, 0.2, 0.18, fm, Vector3.ZERO, Vector3.ZERO, 8)
	for i in 4:
		var arm := Node3D.new()
		fan.add_child(arm)
		arm.rotation_degrees.y = i * 90.0
		Build.box(arm, Vector3(1.3, 0.03, 0.3), fm, Vector3(0.8, 0, 0), Vector3(10, 0, 0))


static func _props(root: Node3D, v: Dictionary) -> void:
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	var blood := Build.mat(Palette.BLOOD, 0.1)
	var disc := Build.disc_mesh()
	var gore := Node3D.new()   # các vết máu: ẩn đi khi tắt máu me
	_uniq(gore, "GoreProps")
	root.add_child(gore)
	var dark := Build.grime(Color(0.11, 0.10, 0.09), 0.4, 0.6, 0.5)
	var steel := Build.grime(Color(0.30, 0.29, 0.25), 0.5, 0.7, 0.6)
	var bagm := Build.mat(Color(0.035, 0.035, 0.04), 0.3)
	# túi đựng xác chất ở chân tường trái
	for i in 3:
		var c := Node3D.new()
		props.add_child(c)
		var bg := Build.capsule(c, 0.3, 1.9, bagm, Vector3(0, 0.24, 0), Vector3(90, 0, 0))
		bg.scale = Vector3(1.15, 1.0, 0.75)
		Build.box(c, Vector3(0.04, 0.02, 1.5), Build.mat(Color(0.3, 0.3, 0.3), 0.4, 0.8), Vector3(0, 0.47, 0))
		c.position = Vector3(-5.65 + (0.35 if i == 2 else 0.0), 0.02 + (0.42 if i == 2 else 0.0), -1.3 + i * 1.0 - (1.3 if i == 2 else 0.0))
		c.rotation_degrees.y = [4.0, -7.0, 12.0][i]
	# băng ca phủ vải dựa tường sau
	var g := Node3D.new()
	g.name = "Gurney"
	props.add_child(g)
	g.position = Vector3(-4.2, 0, -4.7)
	g.rotation_degrees.y = 82.0
	Build.box(g, Vector3(0.95, 0.06, 2.2), steel, Vector3(0, 0.85, 0))
	for x in [-0.42, 0.42]:
		for z in [-1.0, 1.0]:
			Build.box(g, Vector3(0.05, 0.85, 0.05), steel, Vector3(x, 0.42, z))
			Build.cyl(g, 0.07, 0.07, 0.04, dark, Vector3(x, 0.07, z), Vector3(0, 0, 90), 8)
	var sheet := Build.grime(Color(0.52, 0.50, 0.42), 0.0, 0.9, 0.0, 22.0, 0.95)
	var body := Build.capsule(g, 0.24, 1.75, sheet, Vector3(0, 1.02, 0.05), Vector3(90, 0, 0))
	body.scale = Vector3(1.4, 1.0, 0.75)
	Build.ball(g, 0.2, sheet, Vector3(0, 1.08, -0.85))
	var stain := Build.add_mesh(gore, disc, blood, Vector3(0.05, 1.215, 0.1))
	stain.transform = g.transform * Transform3D(Basis.IDENTITY.scaled(Vector3(0.22, 1, 0.34)), Vector3(0.05, 1.215, 0.1))
	# thùng phuy gỉ, két sắt, xô
	for d in [[5.6, -4.6, Color(0.30, 0.15, 0.07)], [4.9, 5.6, Color(0.16, 0.17, 0.15)], [5.7, -3.6, Color(0.20, 0.22, 0.17)], [-5.6, 5.4, Color(0.28, 0.14, 0.07)]]:
		var drum := Build.cyl(props, 0.42, 0.42, 1.15, Build.grime(d[2], 0.7, 0.8, 0.4), Vector3(d[0], 0.575, d[1]), Vector3.ZERO, 12)
		for y in [-0.3, 0.3]:
			Build.cyl(drum, 0.44, 0.44, 0.05, Build.grime((d[2] as Color).darkened(0.4), 0.7, 0.7, 0.5), Vector3(0, y, 0), Vector3.ZERO, 12)
	Build.box(props, Vector3(1.0, 1.7, 0.6), Build.grime(Color(0.24, 0.26, 0.21), 0.6, 0.8, 0.5), Vector3(2.72, 0.85, -5.25))
	Build.box(props, Vector3(0.9, 0.04, 0.02), dark, Vector3(2.72, 0.9, -4.94))
	Build.cyl(props, 0.2, 0.16, 0.34, Build.grime(Color(0.34, 0.33, 0.30), 0.5, 0.7, 0.6), Vector3(-5.2, 0.17, 3.4), Vector3.ZERO, 10)
	# xích và móc treo
	var hooks := [[-4.4, -3.6, 2.5], [-3.0, -4.6, 3.0], [4.6, -3.0, 2.3], [-5.0, 2.0, 2.8], [5.2, 2.2, 3.2]]
	if String(v.extra) == "emergency":
		hooks += [[-2.2, 4.4, 2.6], [2.8, 4.8, 2.9], [-5.6, -2.4, 2.2]]
	for h in hooks:
		var ln: float = 5.3 - float(h[2])
		Build.cyl(props, 0.022, 0.022, ln, dark, Vector3(h[0], h[2] + ln / 2.0, h[1]), Vector3.ZERO, 5)
		Build.torus(props, 0.09, 0.125, Build.grime(Color(0.30, 0.28, 0.24), 0.6, 0.6, 0.7), Vector3(h[0], h[2] - 0.09, h[1]), Vector3(90, 30, 0))
	# lỗ thoát nước + vũng máu
	Build.cyl(props, 0.32, 0.32, 0.02, dark, Vector3(4.4, 0.01, 3.2), Vector3.ZERO, 10)
	var pool := Build.add_mesh(gore, disc, blood, Vector3(4.0, 0.009, 2.8))
	pool.scale = Vector3(0.9, 1, 0.5)
	pool.rotation_degrees.y = 40.0
	var drag := Build.add_mesh(gore, disc, Build.mat(Color(0.14, 0.012, 0.01), 0.3), Vector3(-4.6, 0.008, 1.0))
	drag.scale = Vector3(0.35, 1, 2.0)
	drag.rotation_degrees.y = 14.0


static func _dust(root: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.name = "Dust"
	p.amount = 70
	p.lifetime = 9.0
	p.preprocess = 9.0
	# seed cố định: nếu không, hạt bụi lấy seed từ RNG chung khi nạp buồng và làm lệch chuỗi ngẫu nhiên của luật chơi
	p.use_fixed_seed = true
	p.seed = 9091
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
	root.add_child(p)
	p.position = Vector3(0, 2.8, 0.4)


## Buồng 13: đèn tuýp huỳnh quang lạnh, gạch men ố dưới chân tường.
static func _fluoro(root: Node3D) -> void:
	var extra := Node3D.new()
	extra.name = "Fluorescent"
	root.add_child(extra)
	var tile := Build.grime(Color(0.62, 0.66, 0.60), 0.15, 0.9, 0.1, 10.0, 0.4)
	Build.box(extra, Vector3(12.8, 1.3, 0.05), tile, Vector3(0, 0.65, -5.58))
	Build.box(extra, Vector3(0.05, 1.3, 12.2), tile, Vector3(-6.38, 0.65, 0.5))
	for k in 12:   # ron gạch
		Build.box(extra, Vector3(0.02, 1.3, 0.06), Build.mat(Color(0.12, 0.13, 0.11), 0.9), Vector3(-6.0 + k * 1.05, 0.65, -5.57))
	var tubes := Node3D.new()
	_uniq(tubes, "Tubes")
	extra.add_child(tubes)
	for x in [-3.2, 3.4]:
		var t := Node3D.new()
		tubes.add_child(t)
		t.position = Vector3(x, 5.0, 0.6)
		Build.box(t, Vector3(0.25, 0.06, 2.2), Build.grime(Color(0.30, 0.31, 0.28), 0.4, 0.7, 0.5), Vector3(0, 0.05, 0))
		Build.capsule(t, 0.035, 2.0, Build.glow(Color(0.80, 1.0, 0.88), 4.5), Vector3(0, -0.02, 0), Vector3(90, 0, 0))
		var l := OmniLight3D.new()
		l.light_color = Color(0.80, 1.0, 0.88)
		l.light_energy = 1.4
		l.omni_range = 7.0
		l.light_volumetric_fog_energy = 0.4
		t.add_child(l)
		l.position = Vector3(0, -0.3, 0)


## Buồng 21: đèn khẩn cấp đỏ, vệt gỉ chảy, cảnh báo sơn tay.
static func _emergency(root: Node3D) -> void:
	var extra := Node3D.new()
	extra.name = "Emergency"
	root.add_child(extra)
	var red := Build.glow(Color(1.0, 0.08, 0.03), 4.0)
	for p in [Vector3(-6.3, 4.6, -2.6), Vector3(-6.3, 4.6, 3.6), Vector3(-3.5, 4.9, -5.4), Vector3(1.2, 4.9, -5.4)]:
		var n := Node3D.new()
		extra.add_child(n)
		n.position = p
		Build.box(n, Vector3(0.22, 0.12, 0.22), red)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.1, 0.05)
		l.light_energy = 1.1
		l.omni_range = 5.5
		l.light_volumetric_fog_energy = 1.2
		n.add_child(l)
		l.position = Vector3(0, -0.2, 0.2)
	var rust := Build.grime(Color(0.32, 0.12, 0.05), 1.0, 0.8, 0.2)
	for k in 9:
		Build.box(extra, Vector3(0.12 + 0.05 * (k % 3), 2.4 + 0.3 * (k % 4), 0.02), rust, Vector3(-5.8 + k * 1.35, 3.0, -5.57))
	var warn := Build.label3d(extra, "ĐỪNG TIN\nCỖ MÁY", Vector3(5.2, 1.7, -5.55), 70, Color(0.55, 0.05, 0.04, 0.9), 0.006)
	warn.line_spacing = 0.0
	warn.rotation_degrees.z = -6.0
