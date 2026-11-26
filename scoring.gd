class_name Scoring
## Luật tính điểm, viết thành hàm thuần để kiểm thử được mà không cần dựng cảnh.

const POINTS := [4, 3, 2, 1]


## Xếp hạng kiểu thi đấu: metric nhỏ hơn là tốt hơn, đồng hạng thì cùng thứ hạng (1, 1, 3, 4).
static func rank(metric: Array) -> Array:
	var ranks := []
	for i in metric.size():
		var r := 1
		for j in metric.size():
			if float(metric[j]) < float(metric[i]):
				r += 1
		ranks.append(r)
	return ranks


## Chỉ số xếp hạng của một cửa sinh tồn: ít lần chết hơn thì tốt hơn;
## bằng nhau thì ai chết lần đầu muộn hơn tốt hơn.
static func survival_metric(deaths: int, first_death: float, round_time: float) -> float:
	return float(deaths) * 1000.0 - minf(first_death, round_time + 1.0)


## Chỉ số xếp hạng của cửa tính theo số ô chiếm được.
static func tiles_metric(tiles: int) -> float:
	return -float(tiles)


## Chỉ số xếp hạng chung cuộc: điểm cao hơn tốt hơn; bằng điểm thì ai chết ít hơn tốt hơn.
static func final_metric(total_points: int, total_deaths: int) -> float:
	return -float(total_points) * 1000.0 + float(total_deaths)


static func points_for_rank(r: int) -> int:
	return POINTS[clampi(r, 1, POINTS.size()) - 1]
