#!/usr/bin/env bash
# Ghi địa chỉ máy chủ mai mối vào game/net/online_config.gd trước khi xuất bản (CI/CD).
# Thứ tự: biến SIGNAL_URL (tên miền riêng) → tính từ tên Worker trong signaling/wrangler.toml và subdomain
# workers.dev của tài khoản Cloudflare (cần CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID). Không có thì để trống:
# bản xuất ra vẫn chơi được một máy / LAN, chỉ ẩn mục phòng online.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="${SIGNAL_URL:-}"
if [ -z "$URL" ] && [ -n "${CLOUDFLARE_API_TOKEN:-}" ] && [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
  NAME="$(sed -n 's/^name = "\(.*\)"$/\1/p' "$ROOT/signaling/wrangler.toml" | head -1)"
  SUB="$(curl -sf -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/subdomain" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["subdomain"])' || true)"
  if [ -n "$NAME" ] && [ -n "$SUB" ]; then
    URL="wss://${NAME}.${SUB}.workers.dev/ws"
  fi
fi
if [ -z "$URL" ]; then
  echo "Chưa có máy chủ mai mối: bản xuất ra không có phòng online." >&2
  exit 0
fi
if ! [[ "$URL" =~ ^wss?://[A-Za-z0-9._:/-]+$ ]]; then
  echo "SIGNAL_URL phải có dạng ws(s)://tên-miền[:cổng]/đường-dẫn: $URL" >&2
  exit 1
fi
sed -i.bak "s|^const SIGNAL_URL := .*|const SIGNAL_URL := \"${URL}\"|" "$ROOT/game/net/online_config.gd"
rm -f "$ROOT/game/net/online_config.gd.bak"
grep -q "^const SIGNAL_URL := \"${URL}\"" "$ROOT/game/net/online_config.gd"
echo "Máy chủ mai mối: ${URL}"
