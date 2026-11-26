"""Sinh các file âm thanh .wav bằng tổng hợp số (không dùng sample bên ngoài).
Chạy: python3 tools/gen_sfx.py  → ghi vào thư mục audio/"""
import os, wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(9)


def save(name, x):
    x = np.clip(x / (np.max(np.abs(x)) + 1e-9) * 0.9, -1, 1)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def t(sec):
    return np.arange(int(SR * sec)) / SR


def lowpass(x, k):
    y = np.zeros_like(x); a = 0.0
    for i in range(len(x)):
        a += (x[i] - a) * k; y[i] = a
    return y


def noise(n):
    return rng.uniform(-1, 1, n)


# máy ép / tạ nện xuống: tiếng thụp trầm + tiếng kim loại
x = t(0.7)
slam = np.sin(2 * np.pi * (70 * np.exp(-x * 9) + 38) * x) * np.exp(-x * 7)
slam += lowpass(noise(len(x)), 0.25) * np.exp(-x * 14) * 0.8
slam += np.sin(2 * np.pi * 820 * x) * np.exp(-x * 22) * 0.15
save("slam", slam)

# máu thịt văng: tiếng ướt
x = t(0.45)
splat = lowpass(noise(len(x)), 0.12) * np.exp(-x * 11)
splat += lowpass(noise(len(x)), 0.5) * np.exp(-x * 30) * 0.5
splat *= 1 + 0.6 * np.sin(2 * np.pi * 31 * x)
save("splat", splat)

# phóng điện
x = t(0.6)
zap = np.sign(np.sin(2 * np.pi * 110 * x)) * (0.5 + 0.5 * noise(len(x)))
zap = zap * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 23 * x))) * np.exp(-x * 3.5)
save("zap", zap)

# nổ
x = t(1.0)
boom = lowpass(noise(len(x)), 0.08) * np.exp(-x * 4.5) * 1.4
boom += np.sin(2 * np.pi * (60 * np.exp(-x * 6) + 30) * x) * np.exp(-x * 5)
save("boom", boom)

# tiếng bíp của lõi / cảnh báo
x = t(0.09)
save("beep", np.sin(2 * np.pi * 1320 * x) * np.minimum(1, (0.09 - x) * 60))

# còi bắt đầu cửa và còi hết giờ
x = t(0.55)
save("buzzer", np.sign(np.sin(2 * np.pi * 196 * x)) * 0.6 * np.minimum(1, (0.55 - x) * 25) + np.sin(2 * np.pi * 98 * x) * 0.4)
x = t(0.9)
save("buzzer_end", (np.sign(np.sin(2 * np.pi * 131 * x)) * 0.5 + np.sin(2 * np.pi * 65 * x) * 0.5) * np.minimum(1, (0.9 - x) * 12))

# xô đẩy
x = t(0.22)
save("shove", lowpass(noise(len(x)), 0.3) * np.sin(np.pi * x / 0.22) ** 2 + np.sin(2 * np.pi * 90 * x) * np.exp(-x * 30) * 0.8)

# con dấu "đã loại bỏ"
x = t(0.25)
save("stamp", lowpass(noise(len(x)), 0.4) * np.exp(-x * 35) + np.sin(2 * np.pi * 150 * x) * np.exp(-x * 25))

# tiếng ù nền của buồng máy (lặp)
x = t(4.0)
hum = np.sin(2 * np.pi * 50 * x) * 0.5 + np.sin(2 * np.pi * 100 * x) * 0.2 + np.sin(2 * np.pi * 150.5 * x) * 0.08
hum += lowpass(noise(len(x)), 0.02) * 0.9 * (1 + 0.3 * np.sin(2 * np.pi * 0.25 * x))
save("hum", hum)
# ---------- giai đoạn 5: tiếng chết riêng từng kiểu + nhạc nền ----------
# lưỡi cưa cắt: tiếng rít kim loại trượt tần số + tiếng xé
x = t(0.6)
f = 900 + 1400 * np.exp(-x * 5)
saw = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x * 4) * 0.6
saw += lowpass(noise(len(x)), 0.6) * np.exp(-x * 9) * 0.7
saw *= 1 + 0.5 * np.sign(np.sin(2 * np.pi * 47 * x))
save("saw", saw)

# cháy xèo: nhiễu cao tần, lách tách
x = t(1.2)
sz = (noise(len(x)) - lowpass(noise(len(x)), 0.3)) * np.exp(-x * 2.2)
crack = (rng.uniform(0, 1, len(x)) > 0.997) * rng.uniform(0.5, 1.0, len(x))
sz += lowpass(crack, 0.5) * 6.0
save("sizzle", sz)

# máy nghiền: tiếng ầm có răng cưa đều nhịp
x = t(1.0)
gr = np.sign(np.sin(2 * np.pi * 38 * x)) * 0.5 + lowpass(noise(len(x)), 0.15) * 0.8
gr *= (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 9 * x))) * np.exp(-x * 2.0)
save("grind", gr)

# vòng cổ nổ đầu: tiếng bụp ngắn + ướt
x = t(0.35)
pop = np.sin(2 * np.pi * (180 * np.exp(-x * 25) + 60) * x) * np.exp(-x * 18)
pop += lowpass(noise(len(x)), 0.3) * np.exp(-x * 14) * 0.8
save("pop", pop)

# thùng gỗ vỡ
x = t(0.5)
cr = lowpass(noise(len(x)), 0.45) * np.exp(-x * 10)
for k in range(5):
    o = int(SR * rng.uniform(0.0, 0.25))
    seg = lowpass(noise(len(x) - o), 0.7) * np.exp(-np.arange(len(x) - o) / SR * 40) * 0.6
    cr[o:] += seg
save("crunch", cr)

# tiếng bíp "giọng" Cỗ Máy khi không có TTS
x = t(0.07)
save("blip", np.sign(np.sin(2 * np.pi * 440 * x)) * 0.5 * np.minimum(1, (0.07 - x) * 80) + np.sin(2 * np.pi * 880 * x) * 0.3)

# nhạc nền công nghiệp lặp: 100 BPM, 16 ô nhịp (38,4 giây), nối vòng liền mạch
BPM = 100.0
beat = 60.0 / BPM
bars = 16
L = int(SR * beat * 4 * bars)
x = np.arange(L) / SR
mus = np.zeros(L)
# nền: tiếng ù trầm hai nốt quãng năm, mở dần đóng dần theo ô nhịp
T = L / SR
q = lambda f: round(f * T) / T   # làm tròn tần số để mỗi sóng có số chu kỳ nguyên trong vòng lặp (khỏi lách tách chỗ nối)
pad = np.sin(2 * np.pi * q(55) * x) * 0.35 + np.sin(2 * np.pi * q(82.4) * x) * 0.18 + np.sin(2 * np.pi * q(110.3) * x) * 0.08
mus += pad * (0.7 + 0.3 * np.sin(2 * np.pi * x / (beat * 8)))
# nhịp búa máy: mỗi phách một tiếng nện trầm, phách 3 thêm tiếng kim loại
def hit(at, dur, f0, decay, amp, metal=0.0):
    n = int(SR * dur)
    o = int(SR * at) % L
    xx = np.arange(n) / SR
    sig = np.sin(2 * np.pi * (f0 * np.exp(-xx * 12) + f0 * 0.5) * xx) * np.exp(-xx * decay) * amp
    if metal > 0:
        sig += np.sin(2 * np.pi * 1230 * xx) * np.exp(-xx * 30) * metal + np.sin(2 * np.pi * 1870 * xx) * np.exp(-xx * 40) * metal * 0.6
    idx = (o + np.arange(n)) % L
    np.add.at(mus, idx, sig)
nb = int(bars * 4)
for b in range(nb):
    hit(b * beat, 0.5, 90, 9, 0.9 if b % 2 == 0 else 0.55)
    if b % 4 == 2:
        hit(b * beat, 0.4, 300, 14, 0.15, metal=0.35)
    if b % 8 == 7:
        hit((b + 0.5) * beat, 0.3, 140, 12, 0.4)
# tiếng hơi xì định kỳ (nhiễu lọc, mỗi 2 ô nhịp)
hiss_n = int(SR * beat * 1.5)
hs = (noise(hiss_n) - lowpass(noise(hiss_n), 0.2)) * np.sin(np.pi * np.arange(hiss_n) / hiss_n) ** 2 * 0.25
for b in range(0, bars, 2):
    o = int(SR * beat * 4 * b + SR * beat * 2)
    idx = (o + np.arange(hiss_n)) % L
    np.add.at(mus, idx, hs)
# giai điệu xa xăm (chuông méo) ở nửa sau
notes = [220.0, 207.7, 196.0, 174.6]
for b in range(bars // 2, bars):
    f0 = notes[(b // 2) % 4]
    n = int(SR * beat * 3)
    o = int(SR * beat * 4 * b)
    xx = np.arange(n) / SR
    bell = (np.sin(2 * np.pi * f0 * xx) + 0.4 * np.sin(2 * np.pi * f0 * 2.76 * xx)) * np.exp(-xx * 1.6) * 0.12
    idx = (o + np.arange(n)) % L
    np.add.at(mus, idx, bell)
save("music_loop", mus)
print("ok")
