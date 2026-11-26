class_name Ragdoll
extends Node3D
## Xác đổ theo vật lý: tách hình nhân thành các khối cứng (hông, thân, đầu, 2 tay, 2 chân) nối bằng khớp.
## Chỉ là hình ảnh: nằm ở lớp va chạm riêng, không chặn đường người chơi, không ảnh hưởng luật chơi.

const LAYER_OBSTACLE := 2
const LAYER_FLOOR := 4
const LAYER_RAGDOLL := 8
const SETTLE_TIME := 4.0

var bodies: Array[RigidBody3D] = []
var _t := 0.0


static func _body(parent: Node3D, at: Transform3D, shape: Shape3D, offset: Vector3, mass: float) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.collision_layer = LAYER_RAGDOLL
	# không va chạm với xác khác (kể cả các khối của chính nó): khớp nối đã giữ hình, đỡ tải cho Jolt
	b.collision_mask = LAYER_FLOOR | LAYER_OBSTACLE
	b.mass = mass
	b.linear_damp = 0.4
	b.angular_damp = 1.5
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	b.add_child(cs)
	parent.add_child(b)
	b.global_transform = Transform3D(at.basis.orthonormalized(), at.origin)
	return b


static func _capsule(r: float, h: float) -> CapsuleShape3D:
	var c := CapsuleShape3D.new()
	c.radius = r
	c.height = maxf(h, r * 2.0 + 0.01)
	return c


static func _joint(parent: Node3D, a: RigidBody3D, b: RigidBody3D, at: Vector3, swing_deg: float, twist_deg: float) -> void:
	var j := ConeTwistJoint3D.new()
	parent.add_child(j)
	j.global_position = at
	j.node_a = j.get_path_to(a)
	j.node_b = j.get_path_to(b)
	j.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(swing_deg))
	j.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(twist_deg))


static func _move(n: Node3D, into: Node3D) -> void:
	if n and n.get_parent():
		n.reparent(into, true)


## Tạo xác từ hình nhân hiện tại của `s`, đặt vào `parent`. `push` là vận tốc ban đầu của thân.
static func from_subject(s: Subject, parent: Node3D, push: Vector3) -> Ragdoll:
	var rd := Ragdoll.new()
	rd.name = "Ragdoll%d" % (s.idx + 1)
	parent.add_child(rd)
	var k := Subject.SCALE
	var pv := s.pivot
	var has_upper := s.upper.visible
	var has_head := has_upper and s.head.visible
	# hông + 2 chân
	var pelvis := _body(rd, pv.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)), _capsule(0.17 * k, 0.4 * k), Vector3.ZERO, 8.0)
	rd.bodies.append(pelvis)
	var legs: Array[RigidBody3D] = []
	for hp in s.hips:
		var h: Node3D = hp
		var leg := _body(rd, h.global_transform, _capsule(0.095 * k, 0.8 * k), Vector3(0, -0.4 * k, 0), 5.0)
		legs.append(leg)
		rd.bodies.append(leg)
	_move(s.lower, pelvis)
	for i in legs.size():
		_move(s.hips[i], legs[i])
		_joint(rd, pelvis, legs[i], (s.hips[i] as Node3D).global_position, 55.0, 15.0)
	if has_upper:
		var torso := _body(rd, s.upper.global_transform, _capsule(0.2 * k, 0.72 * k), Vector3(0, 0.38 * k, 0), 14.0)
		rd.bodies.append(torso)
		_joint(rd, pelvis, torso, s.upper.global_position, 25.0, 15.0)
		var arms: Array[RigidBody3D] = []
		for sp in s.sh:
			var sn: Node3D = sp
			var arm := _body(rd, sn.global_transform, _capsule(0.07 * k, 0.6 * k), Vector3(0, -0.28 * k, 0), 3.0)
			arms.append(arm)
			rd.bodies.append(arm)
		var head_body: RigidBody3D = null
		if has_head:
			var sph := SphereShape3D.new()
			sph.radius = 0.18 * k
			head_body = _body(rd, s.head.global_transform, sph, Vector3.ZERO, 4.0)
			rd.bodies.append(head_body)
		_move(s.upper, torso)
		for i in arms.size():
			_move(s.sh[i], arms[i])
			_joint(rd, torso, arms[i], (s.sh[i] as Node3D).global_position, 80.0, 30.0)
		if head_body:
			_move(s.head, head_body)
			_joint(rd, torso, head_body, (s.neck as Node3D).global_position, 35.0, 25.0)
		torso.linear_velocity = push
		torso.angular_velocity = Vector3(push.z, 0, -push.x) * 0.8
	else:
		pelvis.linear_velocity = push * 0.5
		pelvis.angular_velocity = Vector3(push.z, 0, -push.x) * 0.6
	for b in rd.bodies:
		if b != pelvis:
			b.linear_velocity += push * 0.6
	return rd


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= SETTLE_TIME:
		# xác đã nằm yên: đóng băng để đỡ tốn CPU
		for b in bodies:
			if is_instance_valid(b):
				b.freeze = true
		set_physics_process(false)
