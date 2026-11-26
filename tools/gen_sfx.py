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
print("ok")
