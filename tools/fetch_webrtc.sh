#!/usr/bin/env bash
# Tải plugin WebRTC chính thức cho Godot bản desktop (godotengine/webrtc-native) vào <thư mục dự án>/addons/webrtc_native.
# Bản web dùng WebRTC có sẵn của trình duyệt nên không cần plugin này. Plugin không được commit vào repo
# (37 MB thư viện cho mọi nền tảng): CI và quy trình phát hành chạy script này trên bản checkout tạm của chúng
# trước khi kiểm thử / xuất bản, để bản desktop cũng tạo / vào được phòng online.
#   Dùng: tools/fetch_webrtc.sh [thư mục dự án, mặc định là thư mục chứa tools/]
set -euo pipefail
VER="1.2.2-stable"
SHA256="98e9446921740d995bd9ca1be48798dc3c2ceed51e044a25ce18b3cff11f56e5"
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
if [ -f "$ROOT/addons/webrtc_native/webrtc_native.gdextension" ]; then
  echo "webrtc-native đã có sẵn"
  exit 0
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -sSL -o "$TMP/w.zip" "https://github.com/godotengine/webrtc-native/releases/download/${VER}/godot-extension-webrtc_native.zip"
if command -v sha256sum >/dev/null; then SUM="$(sha256sum "$TMP/w.zip" | cut -d' ' -f1)"; else SUM="$(shasum -a 256 "$TMP/w.zip" | cut -d' ' -f1)"; fi
if [ "$SUM" != "$SHA256" ]; then
  echo "sai checksum webrtc-native: $SUM" >&2
  exit 1
fi
unzip -q "$TMP/w.zip" -d "$TMP/x"
mkdir -p "$ROOT/addons"
mv "$TMP/x/addons/webrtc_native" "$ROOT/addons/webrtc_native"
echo "đã cài webrtc-native ${VER} vào $ROOT/addons/webrtc_native"
