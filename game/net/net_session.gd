class_name NetSession
extends Node
## (tạm) Phiên chơi mạng — sẽ được hoàn thiện ở giai đoạn 4.

const DEFAULT_PORT := 24555

signal status_changed(text: String)
signal left(reason: String)

var mode := ""
var connected := false


func is_online() -> bool:
	return mode != ""


func is_host() -> bool:
	return mode == "host"


func is_client() -> bool:
	return mode == "client"


func host(_port: int, _m: MatchManager, _s: Settings) -> int:
	return ERR_UNAVAILABLE


func join(_addr: String, _name: String, _m: MatchManager, _s: Settings) -> int:
	return ERR_UNAVAILABLE


func close() -> void:
	mode = ""
	connected = false


func room_text() -> String:
	return ""


func send_action(_kind: String, _dev: int, _act: String) -> void:
	pass


func send_look(_dh: int, _dc: int) -> void:
	pass


func broadcast_lobby() -> void:
	pass


func client_step(_dt: float) -> void:
	pass


func host_step(_dt: float) -> void:
	pass
