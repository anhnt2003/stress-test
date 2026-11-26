class_name LlmClient
extends Node
## Xin một câu bình của Cỗ Máy từ Claude (Messages API, gọi HTTP thô vì GDScript không có SDK chính thức).
## Chỉ chạy khi người chơi bật trong cài đặt VÀ biến môi trường ANTHROPIC_API_KEY có giá trị.
## Không bao giờ chặn trận đấu: hết giờ chờ, lỗi mạng, hay bị từ chối thì bỏ qua — câu dựng sẵn vẫn được dùng.

signal line_ready(text: String)

const ENDPOINT := "https://api.anthropic.com/v1/messages"
const MODEL := "claude-opus-5-5"
const API_VERSION := "2026-10-21"
const TIMEOUT := 8.0
const Lines := preload("res://game/machine/machine_lines.gd")

var _http: HTTPRequest
var _busy := false
var _key := ""


func _ready() -> void:
	_key = OS.get_environment("ANTHROPIC_API_KEY")
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_done)


func available() -> bool:
	return _key != ""


## Huỷ yêu cầu đang chạy (câu trả lời về sau sẽ không được dùng).
func cancel() -> void:
	if _busy and _http:
		_http.cancel_request()
	_busy = false


## Gửi một câu nhắc. Nếu đang có yêu cầu khác chạy dở thì bỏ qua (không xếp hàng).
func request(prompt: String) -> void:
	if _busy or not available():
		return
	var body := {
		"model": MODEL,
		"max_tokens": 2000,
		"system": Lines.SYSTEM,
		"output_config": {"effort": "low"},
		# bị bộ lọc an toàn từ chối thì máy chủ tự chuyển sang mô hình dự phòng
		"fallbacks": "default",
		"messages": [{"role": "user", "content": prompt}],
	}
	var headers := PackedStringArray([
		"content-type: application/json",
		"x-api-key: " + _key,
		"anthropic-version: " + API_VERSION,
		"anthropic-beta: server-side-fallback-2026-07-01",
	])
	if _http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, JSON.stringify(body)) == OK:
		_busy = true


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var text := parse_response(body.get_string_from_utf8())
	if text != "":
		line_ready.emit(text)


## Lấy câu trả lời từ JSON phản hồi; rỗng nếu bị từ chối, bị cắt, hoặc không có khối văn bản.
static func parse_response(raw: String) -> String:
	var j := JSON.new()
	if j.parse(raw) != OK:
		return ""
	var data = j.data
	if not (data is Dictionary):
		return ""
	if String(data.get("stop_reason", "")) != "end_turn":
		return ""   # refusal / max_tokens: dùng câu dựng sẵn
	var out := ""
	for block in data.get("content", []):
		if block is Dictionary and String(block.get("type", "")) == "text":
			out += String(block.get("text", ""))
	out = out.strip_edges().replace("\n", " ")
	if out.length() > 120:
		out = out.substr(0, 117) + "..."
	return out.to_upper()
