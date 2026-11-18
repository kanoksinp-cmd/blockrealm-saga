"""Original rune-circle textures (white on transparent, tinted in game).
outer.webp: double ring + band of generated runes + tick marks (shared)
inner_<el>.webp: element sigil (star / waves / swirl / squares / bolt / snowflake / sun / moon) + inner rings"""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter
S = 2048            # supersampled
OUT = 512
C = S / 2
out_dir = sys.argv[1]

def new():
    return Image.new("L", (S, S), 0)

def circ(d, r, w, a=255):
    d.ellipse([C - r, C - r, C + r, C + r], outline=a, width=int(w))

def pt(r, ang):
    return (C + math.cos(ang) * r, C + math.sin(ang) * r)

def poly(d, n, r, rot, skip, w, a=255):
    for i in range(n):
        d.line([pt(r, rot + math.tau * i / n), pt(r, rot + math.tau * ((i + skip) % n) / n)], fill=a, width=int(w))

def finish(img, name, glow=True):
    img = img.filter(ImageFilter.MaxFilter(7))      # bolder lines: readable from the game camera
    # soft halo under the crisp lines so the circle glows
    base = img
    if glow:
        halo = img.filter(ImageFilter.GaussianBlur(18)).point(lambda v: int(v * 0.55))
        base = Image.composite(img, halo, img)
        base = Image.eval(Image.merge("L", [img]).point(lambda v: v), lambda v: v)
        base = Image.fromarray(__import__("numpy").maximum(__import__("numpy").array(img), __import__("numpy").array(halo)))
    small = base.resize((OUT, OUT), Image.LANCZOS)
    rgba = Image.merge("RGBA", [Image.new("L", small.size, 255)] * 3 + [small])
    rgba.save(f"{out_dir}/{name}.webp", lossless=True, quality=100)

# ---------------------------------------------------------------- runes
rnd = random.Random(1117)
def rune(d, cx, cy, h, ang, w):
    """a generated glyph: 2-4 strokes on a 3x4 grid, rotated to face outward"""
    grid = [(x, y) for x in (-0.5, 0, 0.5) for y in (-0.5, -0.17, 0.17, 0.5)]
    strokes = rnd.randint(2, 4)
    ca, sa = math.cos(ang), math.sin(ang)
    def tr(p):
        x, y = p[0] * h * 0.62, p[1] * h
        return (cx + x * ca - y * sa, cy + x * sa + y * ca)
    spine = rnd.choice([(-0.5, 0), (0, 0), (0.5, 0)])
    d.line([tr((spine[0], -0.5)), tr((spine[0], 0.5))], fill=255, width=int(w))
    for _ in range(strokes):
        a, b = rnd.sample(grid, 2)
        d.line([tr(a), tr(b)], fill=255, width=int(w))
    if rnd.random() < 0.35:
        p = tr(rnd.choice(grid)); r = h * 0.09
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], outline=255, width=int(w * 0.8))

def outer():
    img = new(); d = ImageDraw.Draw(img)
    R = S * 0.49
    circ(d, R, 14); circ(d, R * 0.965, 5)
    circ(d, R * 0.80, 5); circ(d, R * 0.775, 12)
    n = 44
    for i in range(n):
        ang = math.tau * i / n
        mid = R * 0.883
        x, y = pt(mid, ang)
        rune(d, x, y, R * 0.105, ang + math.pi / 2, 9)
    for i in range(120):        # ticks on the inner rim
        ang = math.tau * i / 120
        l = 0.03 if i % 5 else 0.06
        d.line([pt(R * 0.77, ang), pt(R * (0.77 - l), ang)], fill=255, width=6)
    for i in range(8):          # small knots between runes
        ang = math.tau * i / 8 + math.tau / 88
        x, y = pt(R * 0.985, ang); r = 20
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    finish(img, "rune_outer")

def inner(el):
    img = new(); d = ImageDraw.Draw(img)
    R = S * 0.37
    circ(d, R, 10); circ(d, R * 0.94, 4)
    w = 11
    if el == "fire":
        poly(d, 6, R * 0.94, -math.pi / 2, 2, w)       # hexagram
        circ(d, R * 0.47, 6)
        poly(d, 3, R * 0.47, -math.pi / 2, 1, 8)
    elif el == "water":
        for k in range(5):
            circ(d, R * (0.25 + 0.16 * k), 5 + (k % 2) * 4)
        for i in range(6):
            a = math.tau * i / 6
            d.arc([C - R * 0.9, C - R * 0.9, C + R * 0.9, C + R * 0.9], math.degrees(a), math.degrees(a) + 30, fill=255, width=16)
    elif el == "wind":
        for i in range(4):
            a0 = math.tau * i / 4
            pts = [pt(R * (0.12 + 0.82 * t), a0 + t * 2.4) for t in [j / 40 for j in range(41)]]
            d.line(pts, fill=255, width=w)
        circ(d, R * 0.2, 6)
    elif el == "earth":
        poly(d, 4, R * 0.94, math.pi / 4, 1, w)
        poly(d, 4, R * 0.94, 0, 1, w)
        poly(d, 8, R * 0.62, 0, 3, 6)
        circ(d, R * 0.3, 6)
    elif el == "lightning":
        poly(d, 5, R * 0.94, -math.pi / 2, 2, w)
        for i in range(5):
            a = -math.pi / 2 + math.tau * i / 5
            p0, p1, p2 = pt(R * 0.2, a), pt(R * 0.55, a + 0.18), pt(R * 0.92, a - 0.05)
            d.line([p0, p1, p2], fill=255, width=8)
    elif el == "ice":
        for i in range(6):
            a = math.tau * i / 6
            d.line([pt(R * 0.1, a), pt(R * 0.94, a)], fill=255, width=w)
            for t in (0.45, 0.7):
                b = pt(R * t, a)
                for s in (-1, 1):
                    d.line([b, pt(R * (t + 0.18), a + s * 0.32)], fill=255, width=7)
        poly(d, 6, R * 0.3, 0, 1, 6)
    elif el == "holy":
        for i in range(16):
            a = math.tau * i / 16
            d.line([pt(R * 0.35, a), pt(R * (0.94 if i % 2 == 0 else 0.7), a)], fill=255, width=8 if i % 2 == 0 else 5)
        circ(d, R * 0.35, 9); circ(d, R * 0.2, 5)
        d.line([pt(R * 0.3, -math.pi / 2), pt(R * 0.3, math.pi / 2)], fill=255, width=10)
        d.line([pt(R * 0.3, 0), pt(R * 0.3, math.pi)], fill=255, width=10)
    elif el == "shadow":
        poly(d, 5, R * 0.94, math.pi / 2, 2, w)
        circ(d, R * 0.38, 7)
        d.arc([C - R * 0.3, C - R * 0.3, C + R * 0.3, C + R * 0.3], 110, 310, fill=255, width=14)
        d.arc([C - R * 0.2, C - R * 0.34, C + R * 0.32, C + R * 0.26], 120, 300, fill=255, width=8)
    else:   # physical / support: compass
        poly(d, 8, R * 0.94, 0, 3, 8)
        for i in range(4):
            a = math.tau * i / 4
            d.polygon([pt(R * 0.94, a), pt(R * 0.2, a + 0.25), pt(R * 0.2, a - 0.25)], outline=255, width=8)
        circ(d, R * 0.2, 7)
    # small orbs where the sigil meets the ring
    for i in range(6 if el in ("fire", "ice", "water") else (5 if el in ("lightning", "shadow") else 8)):
        n = 6 if el in ("fire", "ice", "water") else (5 if el in ("lightning", "shadow") else 8)
        a = (-math.pi / 2 if el in ("fire", "lightning") else (math.pi / 2 if el == "shadow" else 0)) + math.tau * i / n
        x, y = pt(R * 1.06, a); r = 24
        d.ellipse([x - r, y - r, x + r, y + r], outline=255, width=7)
    finish(img, "rune_inner_" + el)

outer()
for el in ["fire", "water", "wind", "earth", "lightning", "ice", "holy", "shadow", "physical"]:
    inner(el)
print("ok")
