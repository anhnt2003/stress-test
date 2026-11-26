class_name BotSource
extends InputSource
## Ghế trống: bot điều khiển qua BotBrain của đối tượng.


func kind() -> String:
	return "bot"


func is_bot() -> bool:
	return true


func label() -> String:
	return "MÁY ĐIỀU KHIỂN"


func poll(s: Subject, m: MatchManager, dt: float) -> Dictionary:
	var b := s.brain
	b.want_jump = false
	var d := b.steer(s, m.door, dt)
	var shove := b.wants_shove(s, m.subjects, dt)
	var sab := m.sabotage_enabled and not s.sabotage_used and m.door.bot_wants_sabotage(s, b, dt)
	return {"move": Vector2(d.x, d.z), "jump": b.want_jump, "shove": shove, "sabotage": sab, "face": m.door.bot_face(s, d)}
