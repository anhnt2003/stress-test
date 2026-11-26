extends Panel
## Bảng chấm điểm sau mỗi cửa và bảng tổng kết cuối trận.

@onready var title: Label = $Title
@onready var foot: Label = $Foot


## rows: [{idx, rank, detail, pts, total, verdict?}], looks: trang phục từng ghế.
func show_rows(head: String, foot_text: String, rows: Array, looks: Array, final := false) -> void:
	title.text = head
	foot.text = foot_text
	for r in 4:
		var w := get_node("Row%d" % r)
		w.visible = r < rows.size()
		if r >= rows.size():
			continue
		var row: Dictionary = rows[r]
		var lk: Dictionary = looks[int(row.idx)]
		(w.get_node("Chip") as ColorRect).color = (lk.color as Color).lightened(0.15)
		(w.get_node("Rank") as Label).text = "#%d" % int(row.rank)
		(w.get_node("Name") as Label).text = "ĐT-%s" % String(lk.label)
		(w.get_node("Detail") as Label).text = String(row.detail)
		var total := w.get_node("Total") as Label
		if final:
			(w.get_node("Pts") as Label).text = "%d Đ" % int(row.total)
			var vd: String = row.verdict
			total.text = vd
			total.add_theme_color_override("font_color", Palette.AMBER if vd == "ĐƯỢC GIỮ LẠI" else Color(1.0, 0.2, 0.15))
		else:
			(w.get_node("Pts") as Label).text = "+%d" % int(row.pts)
			total.text = "TỔNG %d" % int(row.total)
			total.add_theme_color_override("font_color", Palette.PAPER)
	visible = true
