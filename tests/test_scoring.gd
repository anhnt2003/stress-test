extends RefCounted
## Luật tính điểm: đồng hạng, hoà, cửa tính theo ô, chung cuộc.


func run(t) -> void:
	var S := Scoring
	t.check("rank: khác nhau hoàn toàn", S.rank([3.0, 1.0, 2.0, 4.0]), [3, 1, 2, 4])
	t.check("rank: đồng hạng nhất", S.rank([0.0, 0.0, 5.0, 9.0]), [1, 1, 3, 4])
	t.check("rank: tất cả bằng nhau", S.rank([2.0, 2.0, 2.0, 2.0]), [1, 1, 1, 1])
	t.check("rank: đồng hạng giữa", S.rank([1.0, 5.0, 5.0, 9.0]), [1, 2, 2, 4])
	t.check("điểm theo hạng", [S.points_for_rank(1), S.points_for_rank(2), S.points_for_rank(3), S.points_for_rank(4)], [4, 3, 2, 1])
	t.check("điểm: hạng ngoài khoảng bị kẹp", [S.points_for_rank(0), S.points_for_rank(9)], [4, 1])
	var m := [S.survival_metric(2, 5.0, 30.0), S.survival_metric(0, 999.0, 30.0), S.survival_metric(1, 3.0, 30.0), S.survival_metric(1, 20.0, 30.0)]
	t.check("sinh tồn: ít chết hơn xếp trên, hoà thì chết muộn hơn xếp trên", S.rank(m), [4, 1, 3, 2])
	t.check("sinh tồn: không ai chết thì cùng hạng nhất", S.rank([S.survival_metric(0, 999.0, 30.0), S.survival_metric(0, 999.0, 30.0)]), [1, 1])
	t.check("chiếm ô: nhiều ô hơn xếp trên", S.rank([S.tiles_metric(10), S.tiles_metric(19), S.tiles_metric(19), S.tiles_metric(15)]), [4, 1, 1, 3])
	t.check("chung cuộc: bằng điểm thì ít chết hơn xếp trên", S.rank([S.final_metric(26, 9), S.final_metric(28, 8), S.final_metric(26, 7), S.final_metric(25, 10)]), [3, 1, 2, 4])
