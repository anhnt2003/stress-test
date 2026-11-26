class_name Build
## Tiện ích dựng hình bằng code: vật liệu, khối cơ bản, đèn, chữ 3D.
## Hàm tĩnh để mọi module (cửa, nhân vật, buồng thử, công cụ bake) dùng chung.

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://fonts/Anton-Regular.ttf")
	return _font


static func mat(color: Color, rough := 0.8, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	return m


static func glow(color: Color, energy := 3.0) -> StandardMaterial3D:
	return mat(color, 0.3, 0.0, energy)


static func shader_mat(path: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## Bề mặt bẩn, gỉ kiểu texture độ phân giải thấp. Mỗi lần gọi lấy một seed ngẫu nhiên.
static func grime(base: Color, rust := 0.3, dirt := 0.6, metal := 0.0, texel := 18.0, rough := 0.85) -> ShaderMaterial:
	return shader_mat("res://shaders/grime.gdshader", {"base": base, "rust": rust, "dirt": dirt, "metal": metal,
		"texel": texel, "rough": rough, "seed": randf() * 40.0})


static func add_mesh(parent: Node, mesh: Mesh, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	parent.add_child(mi)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func box(parent: Node, size: Vector3, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return add_mesh(parent, b, material, pos, rot_deg)


static func cyl(parent: Node, r_top: float, r_bot: float, h: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, segs := 16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return add_mesh(parent, c, material, pos, rot_deg)


static func ball(parent: Node, r: float, material: Material, pos := Vector3.ZERO, hemi := false) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r if hemi else r * 2.0
	s.is_hemisphere = hemi
	s.radial_segments = 12
	s.rings = 6
	return add_mesh(parent, s, material, pos)


static func capsule(parent: Node, r: float, h: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 10
	c.rings = 3
	return add_mesh(parent, c, material, pos, rot_deg)


static func torus(parent: Node, r_in: float, r_out: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = r_in
	tm.outer_radius = r_out
	tm.rings = 14
	tm.ring_segments = 6
	return add_mesh(parent, tm, material, pos, rot_deg)


static func label3d(parent: Node, text: String, pos: Vector3, size: int, color: Color, px := 0.006) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font()
	l.font_size = size
	l.pixel_size = px
	l.modulate = color
	l.outline_size = 0
	l.shaded = true
	l.line_spacing = -6.0
	parent.add_child(l)
	l.position = pos
	return l


static func omni(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, fog := 1.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.light_volumetric_fog_energy = fog
	parent.add_child(l)
	l.position = pos
	return l


## Đĩa mỏng dùng cho vết máu, vết cháy, vùng đánh dấu trên sàn.
static func disc_mesh() -> CylinderMesh:
	var d := CylinderMesh.new()
	d.top_radius = 1.0
	d.bottom_radius = 1.0
	d.height = 0.004
	d.radial_segments = 10
	d.rings = 1
	return d


static func rand_circle(rmin: float, rmax: float) -> Vector2:
	var a := randf() * TAU
	var r := sqrt(randf_range(rmin * rmin, rmax * rmax))
	return Vector2(cos(a) * r, sin(a) * r)


static func hash1(x: float) -> float:
	return fposmod(sin(x * 127.1) * 43758.5453, 1.0)
