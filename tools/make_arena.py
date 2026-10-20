"""Paints the Scrapfall arena floor: wasteland dirt, worn lanes, a toxic
sludge river, riveted bridges, tower pads and scattered scrap.

Usage: python3 tools/make_arena.py   (writes art/arena.png)

Positions match scripts/arena.gd. The image covers the playing field only
(y = Arena.TOP .. Arena.BOTTOM), so y here is offset by TOP.
"""

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
W, TOP, BOTTOM = 720, 60, 1020
H = BOTTOM - TOP
RIVER_Y = 540 - TOP
RIVER_HALF = 22
BRIDGE_HALF = 34
LANES = [160, 560]
SCALE = 2  # paint at 2x, then downsample for smooth edges

rng = np.random.default_rng(7)


def noise(w: int, h: int, cell: int) -> np.ndarray:
    g = rng.random((h // cell + 2, w // cell + 2))
    img = Image.fromarray((g * 255).astype(np.uint8)).resize(
        ((w // cell + 2) * cell, (h // cell + 2) * cell), Image.Resampling.BICUBIC)
    return np.asarray(img, dtype=np.float64)[:h, :w] / 255.0


def fbm(w: int, h: int) -> np.ndarray:
    total = np.zeros((h, w))
    amp = 1.0
    for cell in (160, 80, 40, 20, 10, 5):
        total += noise(w, h, cell) * amp
        amp *= 0.55
    return total / total.max()


def main() -> None:
    w, h = W * SCALE, H * SCALE
    yy, xx = np.mgrid[0:h, 0:w] / SCALE

    # Dirt: warm brown with rusty and ashy patches.
    n = fbm(w, h)
    n2 = fbm(w, h)
    dirt = np.array([112, 88, 62], float)
    rust = np.array([128, 74, 44], float)
    ash = np.array([86, 82, 76], float)
    col = dirt * (0.75 + 0.45 * n[..., None])
    col = col * (1 - 0.45 * (n2[..., None] > 0.62)) + rust * 0.45 * (n2[..., None] > 0.62)
    col = col * (1 - 0.35 * (n[..., None] < 0.32)) + ash * 0.35 * (n[..., None] < 0.32)
    # Fine grit.
    col *= (0.9 + 0.2 * rng.random((h, w)))[..., None]

    # Worn, packed-earth lanes.
    for lx in LANES:
        d = np.abs(xx - lx)
        lane = np.clip(1 - (d - 24) / 18, 0, 1)
        col = col * (1 - 0.35 * lane[..., None]) + np.array([150, 124, 92]) * 0.35 * lane[..., None]
    # Tyre ruts along each lane.
    for lx in LANES:
        for off in (-14, 14):
            d = np.abs(xx - lx - off + 3 * np.sin(yy / 37.0))
            rut = np.clip(1 - d / 3.0, 0, 1) * 0.25
            col *= (1 - rut)[..., None]

    # Toxic sludge river with a glowing core.
    dr = np.abs(yy - RIVER_Y + 3 * np.sin(xx / 23.0))
    river = np.clip((RIVER_HALF + 2 - dr) / 3, 0, 1)
    flow = fbm(w, h)
    sludge = np.array([46, 92, 34]) * (0.7 + 0.6 * flow[..., None])
    glow = np.clip(1 - dr / RIVER_HALF, 0, 1) ** 2
    sludge = sludge + np.array([90, 170, 30]) * glow[..., None] * 0.45
    col = col * (1 - river[..., None]) + sludge * river[..., None]
    # Dark wet banks.
    bank = np.clip(1 - np.abs(dr - RIVER_HALF - 4) / 8, 0, 1) * 0.55
    col *= (1 - bank)[..., None]

    # Tower pads (player side, then mirrored).
    pads = [(160, 850, 46), (560, 850, 46), (360, 950, 60)]
    for px, py, r in pads:
        for y in (py - TOP, (TOP + BOTTOM - py) - TOP):
            d = np.maximum(np.abs(xx - px), np.abs(yy - y))
            pad = np.clip((r - d) / 2, 0, 1)
            plate = np.array([92, 90, 88]) * (0.85 + 0.3 * n[..., None])
            col = col * (1 - pad[..., None]) + plate * pad[..., None]
            rim = np.clip(1 - np.abs(d - r) / 3, 0, 1) * 0.6
            col *= (1 - rim)[..., None]
            ring = np.clip(1 - np.abs(d - r + 9) / 1.5, 0, 1) * 0.25
            col *= (1 - ring)[..., None]

    # Vignette.
    vx = (xx - W / 2) / (W / 2)
    vy = (yy - H / 2) / (H / 2)
    vig = np.clip(1 - 0.28 * (vx ** 2 + vy ** 2), 0.55, 1)
    col *= vig[..., None]

    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)
    s = SCALE

    # Scattered scrap: plates, pipes, gears and tyres, kept off the lanes.
    for _ in range(140):
        x = rng.uniform(10, W - 10)
        y = rng.uniform(10, H - 10)
        if abs(y - RIVER_Y) < 50 or any(abs(x - lx) < 48 for lx in LANES):
            continue
        if any(abs(x - px) < r + 14 and (abs(y - (py - TOP)) < r + 14 or abs(y - (TOP + BOTTOM - py - TOP)) < r + 14) for px, py, r in pads):
            continue
        kind = rng.integers(0, 4)
        tones = [(70, 66, 64), (96, 62, 40), (120, 116, 110), (60, 44, 34)]
        tone = tones[rng.integers(0, len(tones))]
        shade = tuple(int(c * 0.6) for c in tone)
        sz = rng.uniform(4, 10)
        cx, cy = x * s, y * s
        if kind == 0:
            a = rng.uniform(0, np.pi)
            pts = [(cx + np.cos(a + k * np.pi / 2 + 0.3 * (k % 2)) * sz * s, cy + np.sin(a + k * np.pi / 2) * sz * s * 0.7) for k in range(4)]
            d.polygon([(px + 2 * s, py + 2 * s) for px, py in pts], fill=(0, 0, 0, 70))
            d.polygon(pts, fill=tone + (255,), outline=shade + (255,))
        elif kind == 1:
            a = rng.uniform(0, np.pi)
            dx, dy = np.cos(a) * sz * 1.6 * s, np.sin(a) * sz * 1.6 * s
            d.line([(cx - dx + 2 * s, cy - dy + 2 * s), (cx + dx + 2 * s, cy + dy + 2 * s)], fill=(0, 0, 0, 70), width=int(3 * s))
            d.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], fill=tone + (255,), width=int(3 * s))
        elif kind == 2:
            r = sz * s
            d.ellipse([cx - r + 2 * s, cy - r * 0.8 + 2 * s, cx + r + 2 * s, cy + r * 0.8 + 2 * s], fill=(0, 0, 0, 70))
            d.ellipse([cx - r, cy - r * 0.8, cx + r, cy + r * 0.8], fill=(34, 32, 32, 255))
            d.ellipse([cx - r * 0.45, cy - r * 0.36, cx + r * 0.45, cy + r * 0.36], fill=(90, 70, 50, 255))
        else:
            r = sz * s * 0.9
            for k in range(8):
                a = k * np.pi / 4
                d.ellipse([cx + np.cos(a) * r - r * 0.25, cy + np.sin(a) * r * 0.8 - r * 0.25,
                           cx + np.cos(a) * r + r * 0.25, cy + np.sin(a) * r * 0.8 + r * 0.25], fill=shade + (255,))
            d.ellipse([cx - r, cy - r * 0.8, cx + r, cy + r * 0.8], fill=tone + (255,))
            d.ellipse([cx - r * 0.35, cy - r * 0.28, cx + r * 0.35, cy + r * 0.28], fill=(40, 34, 30, 255))

    # Riveted steel bridges with hazard-striped edges.
    for lx in LANES:
        x0, x1 = (lx - BRIDGE_HALF) * s, (lx + BRIDGE_HALF) * s
        y0, y1 = (RIVER_Y - RIVER_HALF - 10) * s, (RIVER_Y + RIVER_HALF + 10) * s
        d.rectangle([x0 + 4 * s, y0 + 5 * s, x1 + 4 * s, y1 + 5 * s], fill=(0, 0, 0, 110))
        d.rectangle([x0, y0, x1, y1], fill=(88, 90, 94, 255), outline=(30, 30, 32, 255), width=3 * s)
        for k in range(6):
            py = y0 + (k + 0.5) * (y1 - y0) / 6
            d.line([(x0 + 10 * s, py), (x1 - 10 * s, py)], fill=(64, 66, 70, 255), width=2 * s)
            d.line([(x0 + 10 * s, py + 2 * s), (x1 - 10 * s, py + 2 * s)], fill=(120, 122, 126, 255), width=1 * s)
        for side in (x0, x1 - 8 * s):
            for k in range(int((y1 - y0) / (8 * s))):
                c = (230, 180, 40, 255) if k % 2 == 0 else (30, 30, 30, 255)
                d.rectangle([side, y0 + k * 8 * s, side + 8 * s, y0 + (k + 1) * 8 * s], fill=c)
        for py in (y0 + 6 * s, y1 - 6 * s):
            for px in np.linspace(x0 + 14 * s, x1 - 14 * s, 5):
                d.ellipse([px - 2 * s, py - 2 * s, px + 2 * s, py + 2 * s], fill=(150, 150, 150, 255))
        # Rust streaks.
        for _ in range(6):
            px = rng.uniform(x0 + 12 * s, x1 - 12 * s)
            py = rng.uniform(y0, y1 - 20 * s)
            d.line([(px, py), (px + rng.uniform(-3, 3) * s, py + rng.uniform(8, 18) * s)], fill=(120, 70, 40, 120), width=2 * s)

    img = img.filter(ImageFilter.SMOOTH_MORE)
    img = img.resize((W, H), Image.Resampling.LANCZOS).convert("RGB")
    out = ROOT / "art" / "arena.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)
    print(out, img.size)


if __name__ == "__main__":
    main()
