class_name OnlineConfig
## Địa chỉ máy chủ mai mối cho chơi online (signaling/, Cloudflare Worker).
## Quy trình triển khai (.github/workflows/deploy.yml) ghi địa chỉ thật vào SIGNAL_URL trước khi xuất bản;
## bản trong repo để trống (chạy thử trên máy thì dùng --signal=ws://127.0.0.1:28787/ws).

const SIGNAL_URL := ""


## Địa chỉ đang dùng: --signal=... (kiểm thử) → ?signal=... trên trang web (chỉ bản debug) → SIGNAL_URL.
static func signal_url(cli_value := "") -> String:
	if cli_value != "":
		return cli_value
	if OS.has_feature("web") and OS.is_debug_build():
		var q = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('signal') || ''", true)
		if q is String and String(q).begins_with("ws"):
			return String(q)
	return SIGNAL_URL
