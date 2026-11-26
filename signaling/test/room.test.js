// Kiểm thử logic phòng mai mối (không cần Cloudflare): node --test test/
import { test } from "node:test";
import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import { RoomCore, normalizeCode, randomCode, iceServers, MAX_JOINERS, JOIN_MSG_LIMIT, ROOM_TTL_MS, JOIN_IDLE_MS, TURN_TTL_S, PING } from "../src/room.js";

function fakeRoom(env = {}) {
  const open = [];
  const data = new Map();
  let alarmAt = null;
  let clock = 1000;
  const storage = {
    get: async (k) => data.get(k),
    put: async (k, v) => void data.set(k, v),
    delete: async (k) => void data.delete(k),
    deleteAll: async () => void data.clear(),
    setAlarm: async (t) => void (alarmAt = t),
  };
  // như Cloudflare: socket đang đóng dở vẫn được liệt kê, chỉ ready() báo không còn OPEN
  const core = new RoomCore({ sockets: () => open.filter((s) => !s.gone), storage, env, now: () => clock });
  const sock = () => {
    const s = {
      sent: [],
      closed: false,
      gone: false,
      a: {},
      ready: () => (s.closed ? 2 : 1),
      att: () => s.a,
      setAtt: (v) => (s.a = v),
      send: (m) => s.sent.push(JSON.parse(m)),
      close: (code, reason) => {
        s.closed = true;
        s.closeCode = code;
        s.closeReason = reason;
      },
      last: () => s.sent[s.sent.length - 1],
    };
    open.push(s);
    return s;
  };
  return { core, sock, data, alarm: () => alarmAt, tick: (ms) => (clock += ms) };
}

test("mã phòng: chuẩn hoá chữ dễ nhầm, bỏ gạch, từ chối sai độ dài / ký tự lạ", () => {
  assert.equal(normalizeCode("k7q-2mx"), "K7Q2MX");
  assert.equal(normalizeCode(" ab0-oil "), "AB0011");
  assert.equal(normalizeCode("ABCDE"), "");
  assert.equal(normalizeCode("ABCDEFG"), "");
  assert.equal(normalizeCode("ABC.DE"), "");
  assert.equal(normalizeCode("ABCDEU"), "");
  assert.equal(normalizeCode(null), "");
  for (let i = 0; i < 200; i++) {
    const c = randomCode();
    assert.equal(normalizeCode(c), c, "mã ngẫu nhiên luôn hợp lệ và không đổi khi chuẩn hoá");
  }
});

test("ICE: STUN miễn phí; TURN chỉ khi cấu hình đủ, mật khẩu tạm thời (không lộ bí mật)", async () => {
  assert.equal((await iceServers({})).length, 1);
  assert.equal((await iceServers({ TURN_URLS: "turn:t.example:3478" })).length, 1, "thiếu TURN_SECRET");
  const now = 1_800_000_000_000;
  const s = await iceServers({ TURN_URLS: "turn:t.example:3478, turns:t.example:443, http://x", TURN_SECRET: "bí-mật" }, now);
  const user = `${now / 1000 + TURN_TTL_S}:stress-test`;
  assert.deepEqual(s[1].urls, ["turn:t.example:3478", "turns:t.example:443"]);
  assert.equal(s[1].username, user);
  assert.equal(s[1].credential, createHmac("sha1", "bí-mật").update(user).digest("base64"));
  assert.ok(!JSON.stringify(s).includes("bí-mật"));
});

test("tạo phòng, người vào nhận id, chủ phòng được báo, trao đổi offer / answer / ICE", async () => {
  const r = fakeRoom();
  const h = r.sock();
  assert.equal(await r.core.createHost(h, "K7Q2MX"), true);
  assert.equal(h.last().t, "room");
  assert.equal(h.last().code, "K7Q2MX");
  assert.ok(h.last().secret.length >= 16);
  const j = r.sock();
  assert.equal(await r.core.join(j), true);
  const id = j.last().id;
  assert.equal(j.last().t, "id");
  assert.ok(id >= 2);
  assert.deepEqual(h.last(), { t: "peer", id, ice: j.last().ice });
  r.core.message(h, JSON.stringify({ t: "offer", to: id, sdp: "v=0 offer" }));
  assert.deepEqual(j.last(), { t: "offer", to: id, sdp: "v=0 offer", from: 1 });
  r.core.message(j, JSON.stringify({ t: "answer", to: 1, sdp: "v=0 answer" }));
  assert.deepEqual(h.last(), { t: "answer", to: 1, sdp: "v=0 answer", from: id });
  r.core.message(j, JSON.stringify({ t: "cand", to: 1, mid: "0", idx: 0, c: "candidate:1" }));
  assert.equal(h.last().c, "candidate:1");
});

test("mã đã có phòng thì không tạo đè", async () => {
  const r = fakeRoom();
  await r.core.createHost(r.sock(), "AAAAAA");
  assert.equal(await r.core.createHost(r.sock(), "AAAAAA"), false);
});

test("người vào không gửi được cho người vào khác, gói lạ bị bỏ, gói hỏng bị ngắt", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "BBBBBB");
  const a = r.sock();
  const b = r.sock();
  await r.core.join(a);
  await r.core.join(b);
  const before = b.sent.length;
  r.core.message(a, JSON.stringify({ t: "offer", to: b.a.id, sdp: "x" }));
  assert.equal(b.sent.length, before, "không chuyển cho người vào khác");
  r.core.message(a, JSON.stringify({ t: "room", to: 1 }));
  assert.equal(h.last().t, "peer", "loại gói không được phép thì bỏ");
  r.core.message(a, "{hỏng");
  assert.equal(a.closed, true);
  assert.equal(a.sent[a.sent.length - 1].r, "bad");
});

test("chủ phòng gửi tới người đã đi thì được báo gone", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "CCCCCC");
  r.core.message(h, JSON.stringify({ t: "offer", to: 12345, sdp: "x" }));
  assert.deepEqual(h.last(), { t: "gone", id: 12345 });
});

test("không có phòng / chủ phòng vắng / quá đông", async () => {
  const r = fakeRoom();
  const j = r.sock();
  assert.equal(await r.core.join(j), false);
  assert.equal(j.last().r, "no_room");
  const h = r.sock();
  await r.core.createHost(h, "DDDDDD");
  for (let i = 0; i < MAX_JOINERS; i++) assert.equal(await r.core.join(r.sock()), true);
  const extra = r.sock();
  assert.equal(await r.core.join(extra), false);
  assert.equal(extra.last().r, "busy");
  h.closed = true;
  await r.core.closed(h);
  const late = r.sock();
  assert.equal(await r.core.join(late), false);
  assert.equal(late.last().r, "host_away");
});

test("chủ phòng rời: người đang mai mối bị báo, người vào rời thì chủ phòng được báo", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "EEEEEE");
  const j = r.sock();
  await r.core.join(j);
  const k = r.sock();
  await r.core.join(k);
  k.closed = true;
  await r.core.closed(k);
  assert.deepEqual(h.last(), { t: "gone", id: k.a.id });
  h.closed = true;
  await r.core.closed(h);
  assert.equal(j.closed, true);
  assert.equal(j.last().r, "host_away");
  assert.ok(r.alarm() > 0);
});

test("chủ phòng nối lại bằng mật khẩu phòng; sai mật khẩu bị từ chối; quá hạn thì xoá phòng", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "FFFFFF");
  const secret = h.last().secret;
  h.closed = true;
  await r.core.closed(h);
  const bad = r.sock();
  assert.equal(await r.core.reclaimHost(bad, "FFFFFF", "sai"), false);
  assert.equal(bad.last().r, "bad_secret");
  const h2 = r.sock();
  assert.equal(await r.core.reclaimHost(h2, "FFFFFF", secret), true);
  assert.equal(h2.last().t, "room");
  const j = r.sock();
  assert.equal(await r.core.join(j), true, "vào được sau khi chủ phòng nối lại");
  h2.closed = true;
  j.closed = true;
  await r.core.closed(h2);
  r.tick(ROOM_TTL_MS + 1);
  await r.core.alarm();
  assert.equal(r.data.size, 0, "phòng bị xoá");
  const h3 = r.sock();
  assert.equal(await r.core.reclaimHost(h3, "FFFFFF", secret), false);
  assert.equal(h3.last().r, "no_room");
});

test("người vào gửi quá nhiều gói thì bị ngắt", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "GGGGGG");
  const j = r.sock();
  await r.core.join(j);
  for (let i = 0; i <= JOIN_MSG_LIMIT; i++) r.core.message(j, JSON.stringify({ t: "cand", to: 1, c: "x" }));
  assert.equal(j.closed, true);
  assert.equal(j.last().r, "rate");
});

test("chủ phòng nối lại khi socket cũ còn treo: người vào mới được chuyển tới socket mới", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "HHHHHH");
  const secret = h.last().secret;
  const h2 = r.sock(); // socket cũ chưa đóng (mạng đổi, máy chủ chưa thấy)
  assert.equal(await r.core.reclaimHost(h2, "HHHHHH", secret), true);
  assert.equal(h.closed, true, "socket cũ bị đóng");
  const j = r.sock();
  assert.equal(await r.core.join(j), true);
  assert.equal(h2.last().t, "peer", "báo cho socket mới");
  assert.equal(h2.last().id, j.a.id);
  r.core.message(j, JSON.stringify({ t: "answer", to: 1, sdp: "x" }));
  assert.equal(h2.last().t, "answer");
  await r.core.closed(h); // socket cũ đóng hẳn sau đó: không làm hỏng phòng
  assert.equal(j.closed, false);
});

test("ping được trả pong, không tính là gói chuyển tiếp", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "IIIII1");
  r.core.message(h, PING);
  assert.deepEqual(h.last(), { t: "pong" });
});

test("người vào treo quá lâu bị đóng, nhường chỗ cho người mới", async () => {
  const r = fakeRoom();
  const h = r.sock();
  await r.core.createHost(h, "JJJJJJ");
  const parked = [];
  for (let i = 0; i < MAX_JOINERS; i++) {
    const j = r.sock();
    await r.core.join(j);
    parked.push(j);
  }
  const early = r.sock();
  assert.equal(await r.core.join(early), false, "đầy");
  r.tick(JOIN_IDLE_MS + 1);
  const late = r.sock();
  assert.equal(await r.core.join(late), true, "chỗ treo được giải phóng");
  assert.ok(parked.every((j) => j.closed && j.last().r === "timeout"));
});
