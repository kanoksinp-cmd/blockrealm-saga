#!/usr/bin/env python3
"""Blockrealm Saga app icon: a voxel grass block pierced by a hero's sword,
framed by golden angel wings (the level-up wings) on a starry night sky,
inside a gold-rimmed rounded tile.  Drawn at 4x and downsampled."""
import math, random
from PIL import Image, ImageDraw, ImageFilter

S = 2048
random.seed(7)


def lerp(a, b, t):
    return a + (b - a) * t


def lerpc(c0, c1, t):
    return tuple(int(lerp(c0[i], c1[i], t)) for i in range(len(c0)))


def radial(size, center, r, c_in, c_out):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(0, size, 2):
        for x in range(0, size, 2):
            d = math.hypot(x - center[0], y - center[1]) / r
            c = lerpc(c_in, c_out, min(1.0, d))
            px[x, y] = c
            if x + 1 < size: px[x + 1, y] = c
            if y + 1 < size:
                px[x, y + 1] = c
                if x + 1 < size: px[x + 1, y + 1] = c
    return img


def rounded_mask(size, radius, inset=0):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle((inset, inset, size - 1 - inset, size - 1 - inset), radius=radius, fill=255)
    return m


def make(size_out, rounded=True, bleed=False):
    # ---- background: night sky with a warm glow behind the emblem
    bg = radial(S, (S * 0.5, S * 0.46), S * 0.78, (58, 46, 128, 255), (9, 10, 30, 255))
    d = ImageDraw.Draw(bg)
    for _ in range(140):
        x, y = random.uniform(0, S), random.uniform(0, S * 0.75)
        r = random.choice([3, 4, 5, 7])
        a = random.randint(90, 230)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 245, 220, a))
    glow = radial(S, (S * 0.5, S * 0.5), S * 0.42, (255, 205, 110, 210), (255, 160, 60, 0))
    bg = Image.alpha_composite(bg, glow)

    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    cx, cy = S * 0.5, S * 0.585

    # ---- angel wings (three feather tiers each side)
    wing = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wing)
    for side in (-1, 1):
        root = (cx + side * S * 0.06, cy - S * 0.08)
        tiers = [(11, S * 0.25, S * 0.042, 12, 82), (9, S * 0.175, S * 0.04, 20, 78), (7, S * 0.105, S * 0.038, 28, 74)]
        for ti, (n, length, width, a0, a1) in enumerate(tiers):
            for i in range(n):
                k = i / (n - 1)
                ang = math.radians(lerp(a0, a1, k))
                arm = (S * (0.05 + k * 0.13), S * (0.06 * math.sin(k * math.pi * 0.8)) - k * S * 0.025)
                base = (root[0] + side * arm[0], root[1] - arm[1])
                L = length * (0.82 + 0.25 * math.sin(k * math.pi * 0.9))
                dx, dy = side * math.sin(ang), -math.cos(ang)
                tip = (base[0] + dx * L, base[1] + dy * L)
                nx, ny = -dy, dx
                w = width
                pts = []
                for j in range(0, 21):
                    t = j / 20
                    ww = w * math.sin(min(1.0, t * 1.15) * math.pi) * (1 - t * 0.35) + w * 0.12
                    px = base[0] + dx * L * t
                    py = base[1] + dy * L * t
                    pts.append((px + nx * ww, py + ny * ww))
                for j in range(20, -1, -1):
                    t = j / 20
                    ww = w * math.sin(min(1.0, t * 1.15) * math.pi) * (1 - t * 0.35) + w * 0.12
                    px = base[0] + dx * L * t
                    py = base[1] + dy * L * t
                    pts.append((px - nx * ww, py - ny * ww))
                shade = lerpc((255, 255, 250), (255, 226, 160), ti * 0.35 + k * 0.25)
                wd.polygon(pts, fill=(196, 140, 54, 255))
                inner = [(p[0] * 0.985 + (base[0] + dx * L * 0.5) * 0.015, p[1] * 0.985 + (base[1] + dy * L * 0.5) * 0.015) for p in pts]
                wd.polygon(inner, fill=shade + (255,))
                wd.line([base, (base[0] + dx * L * 0.85, base[1] + dy * L * 0.85)], fill=(226, 180, 96, 255), width=6)
    wing_glow = wing.filter(ImageFilter.GaussianBlur(28))
    wg = Image.new("RGBA", (S, S), (255, 210, 120, 0))
    wg.putalpha(wing_glow.getchannel("A").point(lambda a: int(a * 0.55)))
    layer = Image.alpha_composite(layer, wg)
    layer = Image.alpha_composite(layer, wing)
    ld = ImageDraw.Draw(layer)

    # ---- isometric voxel grass block
    a = S * 0.2
    top = [(cx, cy - a * 0.55), (cx + a, cy), (cx, cy + a * 0.55), (cx - a, cy)]
    h = a * 1.05
    left = [(cx - a, cy), (cx, cy + a * 0.55), (cx, cy + a * 0.55 + h), (cx - a, cy + h)]
    right = [(cx + a, cy), (cx, cy + a * 0.55), (cx, cy + a * 0.55 + h), (cx + a, cy + h)]

    def face_grid(poly, n, m, colfn):
        # bilinear subdivision of a quad into n x m pixels
        p0, p1, p2, p3 = poly
        for i in range(n):
            for j in range(m):
                def P(u, v):
                    x = lerp(lerp(p0[0], p1[0], u), lerp(p3[0], p2[0], u), v)
                    y = lerp(lerp(p0[1], p1[1], u), lerp(p3[1], p2[1], u), v)
                    return (x, y)
                q = [P(i / n, j / m), P((i + 1) / n, j / m), P((i + 1) / n, (j + 1) / m), P(i / n, (j + 1) / m)]
                ld.polygon(q, fill=colfn(i, j))

    def grass(i, j):
        base = random.choice([(98, 190, 70), (88, 176, 62), (110, 204, 80), (80, 160, 58)])
        return base + (255,)
    face_grid(top, 8, 8, grass)

    def side_face(dark):
        def f(i, j):
            if j <= 1 or (j == 2 and random.random() < 0.45):
                c = random.choice([(84, 166, 60), (74, 150, 54), (96, 180, 66)])
            else:
                c = random.choice([(134, 92, 56), (120, 82, 50), (146, 102, 62), (110, 76, 46)])
                if random.random() < 0.08:
                    c = (150, 150, 150)
            c = tuple(int(v * dark) for v in c)
            return c + (255,)
        return f
    face_grid([left[0], left[1], left[2], left[3]], 8, 8, side_face(0.92))
    face_grid([right[1], right[0], right[3], right[2]], 8, 8, side_face(0.7))
    # crisp outline + top rim light
    for poly in (top, left, right):
        ld.line(poly + [poly[0]], fill=(30, 22, 18, 255), width=10)
    ld.line([top[3], top[0], top[1]], fill=(190, 255, 150, 255), width=6)

    # ---- the sword, plunged into the block top
    sx, sy = cx, cy + a * 0.02
    guard_y = sy - S * 0.27
    blade_w = S * 0.06
    # blade plunged tip-first into the block: from the guard down into the grass
    ld.rectangle((sx - blade_w / 2, guard_y, sx, sy), fill=(236, 243, 255, 255))
    ld.rectangle((sx, guard_y, sx + blade_w / 2, sy), fill=(150, 166, 198, 255))
    ld.line([(sx, guard_y + 20), (sx, sy - 10)], fill=(110, 126, 162, 255), width=8)
    ld.rectangle((sx - blade_w / 2, guard_y, sx + blade_w / 2, sy), outline=(28, 26, 40, 255), width=12)
    # where the blade enters the block
    ld.polygon([(sx - blade_w * 0.75, sy), (sx, sy + a * 0.12), (sx + blade_w * 0.75, sy), (sx, sy - a * 0.1)], fill=(40, 30, 22, 255))
    gx0, gx1 = sx - S * 0.13, sx + S * 0.13
    ld.rounded_rectangle((gx0, guard_y - S * 0.03, gx1, guard_y + S * 0.03), radius=S * 0.025, fill=(236, 178, 52, 255), outline=(70, 40, 10, 255), width=12)
    ld.rectangle((gx0 + 16, guard_y - S * 0.03 + 14, gx1 - 16, guard_y - S * 0.006), fill=(255, 222, 120, 255))
    # grip + pommel
    ld.rectangle((sx - S * 0.024, guard_y - S * 0.17, sx + S * 0.024, guard_y - S * 0.03), fill=(96, 52, 30, 255), outline=(40, 22, 12, 255), width=10)
    for k in range(4):
        yy = guard_y - S * 0.155 + k * S * 0.032
        ld.line([(sx - S * 0.024, yy), (sx + S * 0.024, yy + S * 0.012)], fill=(150, 90, 50, 255), width=10)
    ld.ellipse((sx - S * 0.042, guard_y - S * 0.235, sx + S * 0.042, guard_y - S * 0.15), fill=(236, 178, 52, 255), outline=(70, 40, 10, 255), width=12)
    ld.ellipse((sx - S * 0.02, guard_y - S * 0.215, sx + S * 0.02, guard_y - S * 0.175), fill=(255, 90, 120, 255))
    # gem in the guard
    ld.ellipse((sx - S * 0.028, guard_y - S * 0.026, sx + S * 0.028, guard_y + S * 0.026), fill=(90, 210, 255, 255), outline=(20, 40, 80, 255), width=10)
    ld.ellipse((sx - S * 0.012, guard_y - S * 0.018, sx + S * 0.002, guard_y - S * 0.004), fill=(230, 250, 255, 255))
    # sparkle at the blade tip-in point
    for ang in range(0, 360, 45):
        r = S * (0.07 if ang % 90 == 0 else 0.04)
        ld.line([(sx, sy - S * 0.012), (sx + math.cos(math.radians(ang)) * r, sy - S * 0.012 + math.sin(math.radians(ang)) * r)], fill=(255, 250, 210, 230), width=10)

    # the blade must start below the guard: paint blade over hilt region? (guard drawn after blade -> correct order)
    out = Image.alpha_composite(bg, layer)

    # ---- frame
    if rounded:
        radius = int(S * 0.2)
        mask = rounded_mask(S, radius)
        framed = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        framed.paste(out, (0, 0), mask)
        fd = ImageDraw.Draw(framed)
        fd.rounded_rectangle((14, 14, S - 15, S - 15), radius=radius - 14, outline=(120, 74, 20, 255), width=40)
        fd.rounded_rectangle((26, 26, S - 27, S - 27), radius=radius - 26, outline=(246, 196, 84, 255), width=18)
        fd.rounded_rectangle((60, 60, S - 61, S - 61), radius=radius - 60, outline=(255, 236, 170, 120), width=6)
        out = framed
    elif not bleed:
        pass
    return out.resize((size_out, size_out), Image.LANCZOS)


if __name__ == "__main__":
    big = make(1024, rounded=True)
    big.save("/root/icon/icon_1024.png")
    for s in (512, 192, 180, 128, 64, 32):
        big.resize((s, s), Image.LANCZOS).save("/root/icon/icon_%d.png" % s)
    # square full-bleed version for iOS (it rounds corners itself) and maskable PWA icons
    full = make(1024, rounded=False)
    full.resize((180, 180), Image.LANCZOS).save("/root/icon/apple_180.png")
    full.resize((512, 512), Image.LANCZOS).save("/root/icon/maskable_512.png")
    print("ok")
