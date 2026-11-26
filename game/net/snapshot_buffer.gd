class_name SnapshotBuffer
extends RefCounted
## Bộ đệm nội suy phía máy khách: lưu các mẫu (thời điểm máy chủ, vị trí, hướng) của một đối tượng
## và trả về vị trí tại thời điểm hiển thị (trễ hơn mẫu mới nhất một chút để luôn có hai mẫu kẹp hai bên).

const MAX_SAMPLES := 32
## Ngoại suy tối đa khi gói tin đến trễ (giây).
const MAX_EXTRAPOLATE := 0.25

var samples: Array = []   # [[t, pos: Vector3, yaw: float], ...] tăng dần theo t


func push(t: float, pos: Vector3, yaw: float) -> void:
	if samples.size() > 0 and t <= float(samples[-1][0]):
		return   # gói đến muộn / trùng: bỏ
	samples.append([t, pos, yaw])
	while samples.size() > MAX_SAMPLES:
		samples.pop_front()


func clear() -> void:
	samples.clear()


func latest_time() -> float:
	return float(samples[-1][0]) if samples.size() > 0 else -INF


## Trả về [vị trí, hướng] tại thời điểm t, hoặc [] nếu chưa có mẫu nào.
func sample(t: float) -> Array:
	var n := samples.size()
	if n == 0:
		return []
	if n == 1 or t <= float(samples[0][0]):
		return [samples[0][1], samples[0][2]] if t <= float(samples[0][0]) else [samples[-1][1], samples[-1][2]]
	for i in range(n - 1, 0, -1):
		var a: Array = samples[i - 1]
		var b: Array = samples[i]
		if t >= float(a[0]):
			var span := float(b[0]) - float(a[0])
			var k := (t - float(a[0])) / span if span > 0.0 else 1.0
			if k > 1.0:   # mới hơn mẫu cuối: ngoại suy có giới hạn
				k = minf(k, 1.0 + MAX_EXTRAPOLATE / maxf(span, 0.001))
			return [(a[1] as Vector3).lerp(b[1], k), lerp_angle(float(a[2]), float(b[2]), clampf(k, 0.0, 1.0))]
	return [samples[0][1], samples[0][2]]
