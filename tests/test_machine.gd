extends RefCounted
## Lời Cỗ Máy: câu dựng sẵn và đọc phản hồi của Messages API.

const Lines := preload("res://game/machine/machine_lines.gd")


func run(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for id in 10:
		t.ok("có câu mở màn cửa %d" % id, Lines.door_intro(id, rng).length() > 5)
	t.ok("câu chuỗi chết có số đối tượng", Lines.streak("03", rng).contains("03"))
	t.ok("câu chung cuộc có số đối tượng", Lines.final("02", rng).contains("02"))
	var ok_resp := JSON.stringify({"stop_reason": "end_turn", "content": [{"type": "thinking", "thinking": ""}, {"type": "text", "text": "Đối tượng 03 vẫn thở.\n"}]})
	t.check("đọc khối văn bản, bỏ khối thinking", LlmClient.parse_response(ok_resp), "ĐỐI TƯỢNG 03 VẪN THỞ.")
	var refusal := JSON.stringify({"stop_reason": "refusal", "content": [{"type": "text", "text": "x"}]})
	t.check("bị từ chối thì bỏ", LlmClient.parse_response(refusal), "")
	var cut := JSON.stringify({"stop_reason": "max_tokens", "content": [{"type": "text", "text": "dở dang"}]})
	t.check("bị cắt thì bỏ", LlmClient.parse_response(cut), "")
	t.check("JSON hỏng thì bỏ", LlmClient.parse_response("{oops"), "")
	var long := JSON.stringify({"stop_reason": "end_turn", "content": [{"type": "text", "text": "a".repeat(300)}]})
	t.check("câu quá dài bị cắt", LlmClient.parse_response(long).length(), 120)
