// Máy chủ mai mối (signaling) cho chơi online qua WebRTC: Cloudflare Worker + Durable Object (mỗi phòng một object).
// Xem room.js cho giao thức. Chạy thử trên máy: `npm run dev` (ws://127.0.0.1:28787/ws).

import { DurableObject } from "cloudflare:workers";
import { RoomCore, normalizeCode, randomCode } from "./room.js";

const MAX_CREATE_TRIES = 6;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/" || url.pathname === "/health") {
      return new Response("stress-test signaling OK\n", { headers: { "content-type": "text/plain; charset=utf-8" } });
    }
    if (url.pathname !== "/ws") return new Response("not found\n", { status: 404 });
    if (request.headers.get("Upgrade") !== "websocket") return new Response("expected websocket\n", { status: 426 });

    const role = url.searchParams.get("role");
    if (role === "host" && !url.searchParams.get("code")) {
      // phòng mới: chọn mã ngẫu nhiên, trùng với phòng đang có thì thử mã khác
      for (let i = 0; i < MAX_CREATE_TRIES; i++) {
        const code = randomCode();
        const resp = await roomStub(env, code).fetch(forward(request, url, { role: "host", code, new: "1" }));
        if (resp.status !== 409) return resp;
      }
      return errorSocket("busy");
    }
    const code = normalizeCode(url.searchParams.get("code") || "");
    if (!code || (role !== "host" && role !== "join")) return errorSocket(code ? "bad" : "no_room");
    const params = { role, code };
    if (role === "host") params.secret = url.searchParams.get("secret") || "";
    return roomStub(env, code).fetch(forward(request, url, params));
  },
};

function roomStub(env, code) {
  return env.ROOMS.get(env.ROOMS.idFromName(code));
}

function forward(request, url, params) {
  const u = new URL(url.origin + "/room");
  for (const [k, v] of Object.entries(params)) u.searchParams.set(k, v);
  return new Request(u.toString(), request);
}

// Trả lỗi qua WebSocket (trình duyệt không đọc được nội dung phản hồi HTTP khi bắt tay WebSocket thất bại).
function errorSocket(reason) {
  const pair = new WebSocketPair();
  const [client, server] = Object.values(pair);
  server.accept();
  server.send(JSON.stringify({ t: "error", r: reason }));
  server.close(4001, reason);
  return new Response(null, { status: 101, webSocket: client });
}

export class Room extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.core = new RoomCore({
      sockets: () => this.ctx.getWebSockets().map(wrap),
      storage: this.ctx.storage,
      env,
    });
  }

  async fetch(request) {
    const url = new URL(request.url);
    const role = url.searchParams.get("role");
    const code = url.searchParams.get("code");
    if (role === "host" && url.searchParams.get("new") === "1" && (await this.ctx.storage.get("secret"))) {
      return new Response("taken\n", { status: 409 });
    }
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.ctx.acceptWebSocket(server);
    const ws = wrap(server);
    if (role === "host" && url.searchParams.get("new") === "1") {
      if (!(await this.core.createHost(ws, code))) {
        server.close(4001, "taken");
        return new Response("taken\n", { status: 409 });
      }
    } else if (role === "host") {
      await this.core.reclaimHost(ws, code, url.searchParams.get("secret") || "");
    } else {
      await this.core.join(ws);
    }
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws, message) {
    this.core.message(wrap(ws), typeof message === "string" ? message : null);
  }

  async webSocketClose(ws, code, reason) {
    await this.core.closed(wrap(ws));
    try {
      ws.close(code === 1005 ? 1000 : code, reason);
    } catch {
      // đã đóng
    }
  }

  async webSocketError(ws) {
    await this.core.closed(wrap(ws));
  }

  async alarm() {
    await this.core.alarm();
  }
}

// Bọc WebSocket của Durable Object thành giao diện RoomCore dùng (attachment sống qua lúc object ngủ đông).
function wrap(ws) {
  return {
    raw: ws,
    att: () => ws.deserializeAttachment() || {},
    setAtt: (a) => ws.serializeAttachment(a),
    send: (s) => ws.send(s),
    close: (c, r) => ws.close(c, r),
  };
}
