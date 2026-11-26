extends DoorBase
## Sảnh chờ: bục tròn, 4 đối tượng đứng thành hàng quay mặt về camera.


func _init(match_: MatchManager) -> void:
	super(match_)
	id = -1
	title = "STRESS TEST"
	rule = "10 cửa. Chết ít nhất thì thắng."


func setup(level_root: Node3D) -> void:
	super(level_root)
	build_platform(PLATFORM_R)
	for i in 4:
		var s := m.spawn_subject(i, Vector3(-1.65 + 1.1 * i, PLATFORM_TOP, 0.5 - 0.35 * i))
		s.pivot.rotation.y = m.cam_yaw


## Dựng lại hình nhân của ghế i sau khi đổi mũ / màu áo.
func refresh_look(i: int) -> void:
	var s: Subject = m.subjects[i]
	s.look = m.seats.looks[i]
	var old := s.pivot
	s.remove_child(old)
	old.queue_free()
	s.build_model()
	s.pivot.rotation.y = m.cam_yaw
