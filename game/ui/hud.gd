extends CanvasLayer
## HUD kiểu màn hình máy cũ: tên cửa, luật, đồng hồ, lời Cỗ Máy, thẻ 4 đối tượng, con dấu "ĐÃ LOẠI BỎ".

@onready var title: Label = $Title
@onready var rule: Label = $Rule
@onready var sab_hint: Label = $SabHint
@onready var esc_hint: Label = $EscHint
@onready var timer: Label = $Timer
@onready var net_info: Label = $NetInfo
@onready var sub_panel: Panel = $SubPanel
@onready var sub: Label = $SubPanel/Sub
@onready var cards: Control = $Cards
@onready var stamp: Label = $Stamp

var speak_t := 0.0
var stamp_t := 0.0


func set_titles(head: String, rule_text: String, sabotage := "") -> void:
	title.text = head
	rule.text = rule_text
	sab_hint.text = ("CHƠI XẤU (G · , · Y, MỘT LẦN): " + sabotage) if sabotage != "" else ""
	speak_t = 0.0
	stamp_t = 0.0


func say(text: String, duration := 3.2) -> void:
	sub.text = "CỖ MÁY:  " + text
	speak_t = duration


func show_stamp() -> void:
	stamp_t = 1.3


func reset_fx() -> void:
	speak_t = 0.0
	stamp_t = 0.0


func decay(dt: float) -> void:
	speak_t = maxf(0.0, speak_t - dt)
	stamp_t = maxf(0.0, stamp_t - dt)


## Cập nhật theo trạng thái trận. `overlay` = đang hiện bảng điểm (ẩn con dấu).
func refresh(m: MatchManager, overlay: bool) -> void:
	var lobby := m.state == MatchManager.ST_LOBBY
	var remain := maxf(0.0, MatchManager.ROUND_TIME - m.lt)
	timer.text = "0:%02d" % int(ceil(remain))
	timer.add_theme_color_override("font_color", Palette.DANGER if remain < 8.0 else Palette.AMBER)
	timer.visible = not lobby
	esc_hint.visible = not lobby
	cards.visible = not lobby
	sab_hint.visible = m.state == MatchManager.ST_PLAY or m.state == MatchManager.ST_INTRO
	for i in m.subjects.size():
		var s: Subject = m.subjects[i]
		var card := cards.get_node("Card%d" % i)
		var v := card.get_node("Val") as Label
		if s.out > 0.0:
			v.text = "CHẾT"
			v.add_theme_color_override("font_color", Palette.DANGER)
		else:
			v.text = "SỐNG"
			v.add_theme_color_override("font_color", Palette.AMBER)
		(card.get_node("Chip") as ColorRect).color = (s.look.color as Color).lightened(0.15)
		(card.get_node("Pts") as Label).text = "%d ĐIỂM" % int(m.totals[i])
		(card.get_node("Dth") as Label).text = ("%d Ô" % s.score) if m.door.scores_tiles else ("CHẾT %d" % s.deaths)
		var tag := "  BOT" if m.seats.is_bot(i) else ("  MẠNG" if m.seats.names[i] != "" else "")
		(card.get_node("Name") as Label).text = "ĐT-%s%s" % [String(s.look.label), tag]
		(card.get_node("Sab") as ColorRect).visible = m.sabotage_enabled and not s.sabotage_used and m.state == MatchManager.ST_PLAY
	sub_panel.visible = speak_t > 0.0
	stamp.visible = stamp_t > 0.0 and not overlay
	if stamp.visible:
		stamp.scale = Vector2.ONE * lerpf(1.0, 1.6, clampf((stamp_t - 1.1) / 0.2, 0.0, 1.0))
