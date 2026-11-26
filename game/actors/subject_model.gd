class_name SubjectModel
## Dựng hình nhân thử nghiệm bằng khối cơ bản: áo liền quần đánh số, đầu trọc, vòng cổ nổ, mũ.
## `look` = {"color": Color, "hat": int, "label": String}.

const HAT_NAMES := ["MŨ CỐI", "NÓN LÁ", "MŨ BẢO HIỂM", "BĂNG ĐẦU", "MŨ LEN", "MẶT NẠ HÀN", "MŨ PHỚT", "XÔ SẮT"]
const COLORS := [
	Color(0.52, 0.13, 0.09), Color(0.62, 0.48, 0.12), Color(0.17, 0.30, 0.46), Color(0.25, 0.40, 0.20),
	Color(0.42, 0.22, 0.40), Color(0.55, 0.30, 0.10), Color(0.20, 0.42, 0.42), Color(0.48, 0.46, 0.40),
]
const COLOR_NAMES := ["ĐỎ GẠCH", "VÀNG ĐẤT", "XANH THÉP", "XANH RÊU", "TÍM THAN", "CAM GỈ", "XANH ĐỒNG", "XÁM TRO"]

static func default_look(i: int) -> Dictionary:
	return {"color": Palette.SUIT[i], "hat": i, "label": Palette.SUBJ[i]}


static func blood() -> StandardMaterial3D:
	return Build.mat(Palette.BLOOD, 0.1)


## Dựng toàn bộ hình nhân dưới `pivot`. Trả về các khớp để làm hoạt ảnh.
static func build(pivot: Node3D, look: Dictionary) -> Dictionary:
	var trousers := Build.grime(Color(0.17, 0.16, 0.13), 0.0, 0.8, 0.0, 26.0, 0.95)
	var lower := Node3D.new()
	lower.name = "Lower"
	pivot.add_child(lower)
	var hips: Array[Node3D] = []
	for sx in [-1.0, 1.0]:
		var hp := Node3D.new()
		lower.add_child(hp)
		hp.position = Vector3(0.115 * sx, 0.8, 0)
		Build.capsule(hp, 0.095, 0.8, trousers, Vector3(0, -0.4, 0))
		Build.box(hp, Vector3(0.15, 0.11, 0.28), Build.mat(Color(0.04, 0.035, 0.03), 0.7), Vector3(0, -0.75, 0.045))
		hips.append(hp)
	var pelvis := Build.ball(lower, 0.2, trousers, Vector3(0, 0.82, 0))
	pelvis.scale = Vector3(1.15, 0.7, 0.82)
	var upper := Node3D.new()
	upper.name = "Upper"
	pivot.add_child(upper)
	upper.position = Vector3(0, 0.82, 0)
	var u := build_upper(upper, look)
	var tag := Build.label3d(pivot, String(look.label), Vector3(0, 2.35, 0), 36, Color(0.92, 0.88, 0.75), 0.006)
	tag.shaded = false
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.outline_size = 10
	tag.outline_modulate = Color(0, 0, 0)
	return {"lower": lower, "upper": upper, "hips": hips, "sh": u.sh, "head": u.head, "neck": u.neck, "led": u.led, "tag": tag}


## Thân trên: áo khoác lao động bạc màu, đầu trọc xám, vòng cổ nổ, mũ.
static func build_upper(parent: Node3D, look: Dictionary) -> Dictionary:
	var suit: Color = look.color
	var jacket := Build.grime(suit, 0.0, 0.85, 0.0, 26.0, 0.95)
	var skin := Build.grime(Color(0.60, 0.55, 0.46), 0.0, 0.5, 0.0, 30.0, 0.75)
	var skin_d := Build.mat(Color(0.33, 0.29, 0.24), 0.8)
	var dark := Build.mat(Color(0.03, 0.03, 0.03), 0.6)
	var torso := Build.capsule(parent, 0.2, 0.72, jacket, Vector3(0, 0.35, 0))
	torso.scale = Vector3(1.3, 1.0, 0.85)
	Build.capsule(parent, 0.105, 0.68, jacket, Vector3(0, 0.61, 0), Vector3(0, 0, 90))   # vai
	var hem := Build.cyl(parent, 0.235, 0.255, 0.16, jacket, Vector3(0, 0.07, 0), Vector3.ZERO, 10)
	hem.scale = Vector3(1.12, 1, 0.82)
	Build.box(parent, Vector3(0.03, 0.5, 0.012), dark, Vector3(0, 0.36, 0.176))        # hàng khuy
	Build.box(parent, Vector3(0.17, 0.12, 0.012), Build.mat(Color(0.62, 0.58, 0.48), 0.9), Vector3(-0.13, 0.47, 0.172))
	var label := String(look.label)
	Build.label3d(parent, label, Vector3(-0.13, 0.47, 0.181), 30, Color(0.05, 0.05, 0.05), 0.0042).shaded = true
	var n2 := Build.label3d(parent, label, Vector3(0, 0.40, -0.176), 76, Color(0.07, 0.06, 0.05, 0.85), 0.0042)
	n2.rotation_degrees.y = 180.0
	var sh: Array[Node3D] = []
	for sx in [-1.0, 1.0]:
		var p := Node3D.new()
		parent.add_child(p)
		p.position = Vector3(0.33 * sx, 0.6, 0)
		Build.capsule(p, 0.07, 0.6, jacket, Vector3(0, -0.25, 0))
		Build.cyl(p, 0.078, 0.078, 0.06, jacket, Vector3(0, -0.5, 0), Vector3.ZERO, 8)
		Build.ball(p, 0.07, skin, Vector3(0, -0.58, 0))
		sh.append(p)
	# vòng cổ nổ + đèn LED
	Build.torus(parent, 0.085, 0.13, Build.mat(Color(0.10, 0.10, 0.10), 0.4, 0.8), Vector3(0, 0.77, 0))
	var led := Build.glow(suit.lightened(0.3), 4.0)
	Build.box(parent, Vector3(0.09, 0.07, 0.05), dark, Vector3(0, 0.77, 0.13))
	Build.ball(parent, 0.026, led, Vector3(0, 0.77, 0.16))
	var neck := Node3D.new()
	parent.add_child(neck)
	neck.position = Vector3(0, 0.82, 0)
	Build.cyl(parent, 0.06, 0.07, 0.14, skin, Vector3(0, 0.80, 0), Vector3.ZERO, 8)
	var head := Node3D.new()
	head.name = "Head"
	parent.add_child(head)
	head.position = Vector3(0, 0.99, 0)
	var skull := Build.ball(head, 0.18, skin)
	skull.scale = Vector3(0.9, 1.08, 0.98)
	var jaw := Build.ball(head, 0.13, skin, Vector3(0, -0.095, 0.025))
	jaw.scale = Vector3(0.98, 0.85, 0.95)
	Build.box(head, Vector3(0.21, 0.035, 0.06), skin_d, Vector3(0, 0.055, 0.145))            # gờ mày
	Build.box(head, Vector3(0.045, 0.09, 0.07), skin, Vector3(0, -0.015, 0.175), Vector3(-18, 0, 0))  # mũi
	for sx in [-1.0, 1.0]:
		var eye := Build.ball(head, 0.034, dark, Vector3(0.062 * sx, 0.022, 0.152))
		eye.scale = Vector3(1.2, 0.9, 0.6)
		Build.ball(head, 0.035, skin, Vector3(0.165 * sx, -0.01, 0.0))                       # tai
	Build.box(head, Vector3(0.095, 0.012, 0.02), dark, Vector3(0, -0.115, 0.14))             # miệng
	build_hat(head, int(look.hat), dark)
	return {"sh": sh, "head": head, "neck": neck, "led": led}


static func build_hat(head: Node3D, hat: int, dark: Material) -> void:
	match hat:
		0:  # mũ cối
			var hm := Build.grime(Color(0.30, 0.33, 0.20), 0.0, 0.8, 0.0, 26.0)
			var dome := Build.ball(head, 0.2, hm, Vector3(0, 0.06, 0), true)
			dome.scale = Vector3(1.0, 1.15, 1.08)
			var brim := Build.cyl(head, 0.28, 0.3, 0.03, hm, Vector3(0, 0.06, 0.01), Vector3.ZERO, 12)
			brim.scale = Vector3(0.95, 1, 1.12)
		1:  # nón lá sờn
			Build.cyl(head, 0.0, 0.42, 0.2, Build.grime(Color(0.62, 0.52, 0.32), 0.0, 0.8, 0.0, 26.0), Vector3(0, 0.2, 0), Vector3.ZERO, 12)
			Build.box(head, Vector3(0.015, 0.2, 0.3), dark, Vector3(0, -0.02, 0.0))
		2:  # mũ bảo hiểm nửa đầu
			var hm2 := Build.grime(Color(0.20, 0.22, 0.26), 0.3, 0.6, 0.3, 26.0, 0.45)
			var dome2 := Build.ball(head, 0.205, hm2, Vector3(0, 0.035, -0.005), true)
			dome2.scale = Vector3(1.0, 1.12, 1.06)
			Build.box(head, Vector3(0.24, 0.02, 0.1), hm2, Vector3(0, 0.05, 0.2), Vector3(12, 0, 0))
			for sx in [-1.0, 1.0]:
				Build.box(head, Vector3(0.012, 0.2, 0.03), dark, Vector3(0.158 * sx, -0.06, 0.03))
		3:  # băng quấn đầu che một mắt
			var bd := Build.grime(Color(0.62, 0.58, 0.48), 0.0, 0.9, 0.0, 30.0, 0.95)
			var band := Build.cyl(head, 0.172, 0.175, 0.11, bd, Vector3(0, 0.075, 0.0), Vector3(0, 0, -10), 12)
			band.scale = Vector3(1.0, 1, 1.07)
			Build.box(head, Vector3(0.1, 0.09, 0.03), bd, Vector3(0.065, 0.02, 0.158), Vector3(0, 0, -10))
			Build.box(head, Vector3(0.05, 0.04, 0.012), blood(), Vector3(0.07, 0.02, 0.176))
		4:  # mũ len sờn, có quả bông
			var wool := Build.grime(Color(0.28, 0.10, 0.08), 0.0, 0.9, 0.0, 34.0, 1.0)
			var cap := Build.ball(head, 0.195, wool, Vector3(0, 0.045, -0.005), true)
			cap.scale = Vector3(1.0, 1.25, 1.06)
			Build.cyl(head, 0.19, 0.19, 0.07, wool, Vector3(0, 0.05, -0.005), Vector3.ZERO, 12).scale = Vector3(1.0, 1, 1.06)
			Build.ball(head, 0.06, wool, Vector3(0, 0.3, -0.01))
		5:  # mặt nạ hàn lật lên
			var steel := Build.grime(Color(0.16, 0.16, 0.15), 0.4, 0.7, 0.5, 26.0, 0.5)
			Build.cyl(head, 0.19, 0.19, 0.04, steel, Vector3(0, 0.14, 0), Vector3.ZERO, 12)
			var visor := Build.box(head, Vector3(0.3, 0.32, 0.04), steel, Vector3(0, 0.27, 0.12), Vector3(-62, 0, 0))
			Build.box(visor, Vector3(0.16, 0.06, 0.012), Build.glow(Color(0.1, 0.35, 0.1), 0.6), Vector3(0, 0.04, 0.025))
		6:  # mũ phớt cũ
			var felt := Build.grime(Color(0.10, 0.09, 0.08), 0.0, 0.7, 0.0, 26.0, 0.9)
			Build.cyl(head, 0.33, 0.33, 0.025, felt, Vector3(0, 0.1, 0), Vector3.ZERO, 14)
			Build.cyl(head, 0.15, 0.18, 0.2, felt, Vector3(0, 0.21, 0), Vector3.ZERO, 12)
			Build.cyl(head, 0.181, 0.181, 0.04, Build.mat(Color(0.25, 0.04, 0.03), 0.8), Vector3(0, 0.13, 0), Vector3.ZERO, 12)
		7:  # xô sắt móp úp lên đầu
			var pail := Build.grime(Color(0.34, 0.33, 0.30), 0.7, 0.8, 0.6, 22.0, 0.6)
			var bucket := Build.cyl(head, 0.2, 0.25, 0.3, pail, Vector3(0, 0.16, 0), Vector3(0, 0, 8), 12)
			bucket.scale = Vector3(1.0, 1, 0.95)
			Build.torus(head, 0.22, 0.24, Build.mat(Palette.STEEL_DARK, 0.6, 0.6), Vector3(0, 0.02, 0), Vector3(0, 0, 8))


## Cháy đen toàn thân.
static func char_node(n: Node, scorch: Material) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).material_override = scorch
		elif c is Label3D:
			(c as Label3D).visible = false
		char_node(c, scorch)
