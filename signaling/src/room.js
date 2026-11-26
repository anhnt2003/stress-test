// Logic phòng "mai mối" (signaling) cho chơi online qua WebRTC, tách khỏi Durable Object để kiểm thử bằng Node.
//
// Máy chủ mai mối chỉ chuyển lời mời / trả lời / ICE giữa chủ phòng (peer id 1) và người vào phòng.
// Dữ liệu trận đấu đi thẳng giữa các trình duyệt qua WebRTC, không qua đây.
//
// Giao thức (JSON, mỗi gói một đối tượng có trường "t"):
//   chủ phòng → máy chủ:  mở WebSocket ?role=host (phòng mới) hoặc ?role=host&code=X&secret=Y (nối lại)
//   người vào → máy chủ:  mở WebSocket ?role=join&code=X
//   máy chủ → chủ phòng:  {t:"room", code, secret, ice}   {t:"peer", id}   {t:"gone", id}
//   máy chủ → người vào:  {t:"id", id, ice}
//   hai chiều (qua máy chủ, thêm trường from): {t:"offer"|"answer"|"cand"|"bye", to, ...}
//   lỗi: {t:"error", r:"no_room"|"host_away"|"busy"|"bad_secret"|"bad"|"rate"} rồi đóng kết nối

export const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
export const CODE_LEN = 6;
export const MAX_JOINERS = 8; // người đang mai mối cùng lúc (ghế thật do game quyết)
export const MAX_MSG_BYTES = 65536;
export const JOIN_MSG_LIMIT = 400; // người vào chỉ cần vài chục gói (offer/answer/ICE)
export const HOST_MSG_LIMIT = 200000;
export const ROOM_TTL_MS = 10 * 60 * 1000; // chủ phòng mất kết nối quá 10 phút thì xoá phòng
export const JOIN_IDLE_MS = 60 * 1000; // người vào mai mối quá 60 giây (kết nối treo) thì bị đóng
export const TURN_TTL_S = 4 * 3600; // mật khẩu TURN tạm thời hết hạn sau 4 giờ
export const PING = '{"t":"ping"}';
export const PONG = '{"t":"pong"}';
export const RELAY_TYPES = new Set(["offer", "answer", "cand", "bye"]);

// Hai bản bọc có thể cùng trỏ tới một WebSocket thật (Durable Object bọc lại mỗi lần lấy danh sách).
export function same(a, b) {
  return (a.raw ?? a) === (b.raw ?? b);
}

export function randomCode(rand = cryptoRandom) {
  let s = "";
  for (let i = 0; i < CODE_LEN; i++) s += ALPHABET[rand(32)];
  return s;
}

export function randomSecret(rand = cryptoRandom) {
  let s = "";
  for (let i = 0; i < 24; i++) s += ALPHABET[rand(32)];
  return s;
}

// Số nguyên ngẫu nhiên trong [0, n) từ crypto (n ≤ 2^32).
export function cryptoRandom(n) {
  const a = new Uint32Array(1);
  crypto.getRandomValues(a);
  return a[0] % n;
}

// Chuẩn hoá mã người chơi gõ: bỏ gạch / khoảng trắng, chữ hoa, O→0, I/L→1. Trả về "" nếu không hợp lệ.
export function normalizeCode(text) {
  if (typeof text !== "string") return "";
  const t = text.toUpperCase().replace(/[\s-]/g, "").replace(/O/g, "0").replace(/[IL]/g, "1");
  if (t.length !== CODE_LEN) return "";
  for (const ch of t) if (!ALPHABET.includes(ch)) return "";
  return t;
}

// Danh sách máy chủ ICE gửi cho game: STUN miễn phí, cộng TURN nếu đã cấu hình (biến môi trường của Worker).
// TURN dùng mật khẩu tạm thời theo chuẩn "TURN REST API" (coturn use-auth-secret): tên = "<hết hạn>:stress-test",
// mật khẩu = base64(HMAC-SHA1(TURN_SECRET, tên)). Không bao giờ gửi bí mật dài hạn cho người chơi.
export async function iceServers(env = {}, nowMs = Date.now()) {
  const list = [{ urls: ["stun:stun.cloudflare.com:3478", "stun:stun.l.google.com:19302"] }];
  const urls = String(env.TURN_URLS || "")
    .split(",")
    .map((u) => u.trim())
    .filter((u) => /^turns?:/.test(u));
  if (urls.length > 0 && env.TURN_SECRET) {
    const username = `${Math.floor(nowMs / 1000) + TURN_TTL_S}:stress-test`;
    list.push({ urls, username, credential: await hmacSha1Base64(String(env.TURN_SECRET), username) });
  }
  return list;
}

export async function hmacSha1Base64(secret, text) {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-1" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", key, enc.encode(text)));
  let bin = "";
  for (const b of sig) bin += String.fromCharCode(b);
  return btoa(bin);
}

// Một phòng. `sockets()` trả về các WebSocket của phòng (mỗi cái có attachment {role, id, n, at}; có thể gồm cả
// socket đang đóng dở: Cloudflare vẫn liệt kê tới khi phía kia trả lời khung đóng, nên chỉ dùng socket OPEN),
// `storage` có get/put/delete/deleteAll/setAlarm (Durable Object storage hoặc bản giả trong kiểm thử).
export class RoomCore {
  constructor({ sockets, storage, env = {}, now = () => Date.now(), rand = cryptoRandom }) {
    this.sockets = sockets;
    this.storage = storage;
    this.env = env;
    this.now = now;
    this.rand = rand;
  }

  live() {
    return this.sockets().filter((ws) => (ws.ready ? ws.ready() === 1 : true) && ws.att().role !== "old");
  }

  host() {
    return this.live().find((ws) => ws.att().role === "host") || null;
  }

  joiners() {
    return this.live().filter((ws) => ws.att().role === "join");
  }

  find(id) {
    return this.live().find((ws) => ws.att().id === id) || null;
  }

  // Phòng mới: trả về false nếu mã đã có người dùng (Worker sẽ thử mã khác).
  async createHost(ws, code) {
    if (await this.storage.get("secret")) return false;
    const secret = randomSecret(this.rand);
    await this.storage.put("secret", secret);
    await this.storage.put("code", code);
    await this.storage.delete("gone_at");
    ws.setAtt({ role: "host", id: 1, n: 0, at: this.now() });
    send(ws, { t: "room", code, secret, ice: await iceServers(this.env, this.now()) });
    return true;
  }

  // Chủ phòng nối lại (mất mạng chốc lát) bằng mã + mật khẩu phòng.
  async reclaimHost(ws, code, secret) {
    const saved = await this.storage.get("secret");
    if (!saved || saved !== secret) return fail(ws, saved ? "bad_secret" : "no_room");
    for (const old of this.sockets()) {
      if (!same(old, ws) && old.att().role === "host") {
        // socket cũ (mạng đổi, kết nối treo) có thể còn được liệt kê một lúc: đánh dấu để không chuyển gói tới nó
        old.setAtt({ ...old.att(), role: "old", id: 0 });
        old.close(4000, "replaced");
      }
    }
    await this.storage.delete("gone_at");
    ws.setAtt({ role: "host", id: 1, n: 0, at: this.now() });
    send(ws, { t: "room", code, secret, ice: await iceServers(this.env, this.now()) });
    return true;
  }

  async join(ws) {
    if (!(await this.storage.get("secret"))) return fail(ws, "no_room");
    const host = this.host();
    if (!host) return fail(ws, "host_away");
    // người mai mối quá lâu (kết nối treo, cố tình chiếm chỗ) bị đóng trước khi đếm chỗ
    for (const j of this.joiners()) {
      if (!same(j, ws) && this.now() - (j.att().at || 0) > JOIN_IDLE_MS) fail(j, "timeout");
    }
    if (this.joiners().filter((j) => !same(j, ws)).length >= MAX_JOINERS) return fail(ws, "busy");
    let id = 0;
    while (id < 2 || this.find(id)) id = 2 + this.rand(0x7ffffff0);
    ws.setAtt({ role: "join", id, n: 0, at: this.now() });
    const ice = await iceServers(this.env, this.now());
    send(ws, { t: "id", id, ice });
    send(host, { t: "peer", id, ice }); // mật khẩu TURN mới cho cả chủ phòng (phòng mở lâu hơn hạn 4 giờ)
    return true;
  }

  message(ws, data) {
    const att = ws.att();
    if (!att.role || att.role === "old") return;
    if (data === PING) return send(ws, { t: "pong" }); // dự phòng khi chưa đặt tự trả lời ping
    if (typeof data !== "string" || data.length > MAX_MSG_BYTES) return fail(ws, "bad");
    att.n = (att.n || 0) + 1;
    ws.setAtt(att);
    if (att.n > (att.role === "host" ? HOST_MSG_LIMIT : JOIN_MSG_LIMIT)) return fail(ws, "rate");
    let msg;
    try {
      msg = JSON.parse(data);
    } catch {
      return fail(ws, "bad");
    }
    if (!msg || typeof msg !== "object" || !RELAY_TYPES.has(msg.t)) return;
    const to = Number(msg.to);
    // người vào chỉ được nói với chủ phòng; chủ phòng nói với người vào bất kỳ (không tự gửi cho mình)
    if (att.role === "join" ? to !== 1 : !(to >= 2)) return;
    const target = this.find(to);
    if (!target) {
      if (att.role === "host") send(ws, { t: "gone", id: to });
      return;
    }
    send(target, { ...msg, from: att.id });
  }

  async closed(ws) {
    const att = ws.att();
    if (att.role === "old") return;
    if (att.role === "join") {
      const host = this.host();
      if (host) send(host, { t: "gone", id: att.id });
    } else if (att.role === "host" && !this.sockets().some((o) => !same(o, ws) && o.att().role === "host")) {
      // người đang mai mối dở không thể vào được nữa; người đã nối WebRTC xong không bị ảnh hưởng
      for (const j of this.joiners()) if (!same(j, ws)) fail(j, "host_away");
      await this.storage.put("gone_at", this.now());
      await this.storage.setAlarm(this.now() + ROOM_TTL_MS);
    }
  }

  // Hẹn giờ: chủ phòng không quay lại trong ROOM_TTL_MS thì xoá phòng (mã được dùng lại cho phòng khác).
  async alarm() {
    if (this.host()) return;
    const gone = await this.storage.get("gone_at");
    if (gone !== undefined && this.now() - gone >= ROOM_TTL_MS) {
      await this.storage.deleteAll();
    } else if (gone !== undefined) {
      await this.storage.setAlarm(gone + ROOM_TTL_MS);
    }
  }
}

export function send(ws, obj) {
  try {
    ws.send(JSON.stringify(obj));
  } catch {
    // kết nối đã đóng
  }
}

export function fail(ws, reason) {
  send(ws, { t: "error", r: reason });
  try {
    ws.close(4001, reason);
  } catch {
    // đã đóng
  }
  return false;
}
