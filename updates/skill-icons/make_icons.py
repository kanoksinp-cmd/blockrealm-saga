"""Generate the missing skill icons in the game's icon style.

64x64, bronze frame, coloured radial background, glowing light glyph.
Writes resources/assets/icons/skills_ro/<id>.png (raw PNG, loaded by SkillDB.icon).
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 256          # working size (4x supersampled)
OUT = Path(__file__).parent / 'resources/assets/icons/skills_ro'

HUES = {
    'holy': (255, 214, 90), 'fire': (255, 110, 40), 'ice': (110, 190, 255), 'wind': (110, 230, 140),
    'earth': (200, 150, 80), 'lightning': (255, 235, 90), 'shadow': (170, 100, 255), 'poison': (120, 220, 70),
    'blood': (230, 60, 60), 'steel': (170, 190, 220), 'gold': (255, 190, 60), 'music': (255, 120, 200),
    'spirit': (110, 230, 255), 'nature': (90, 210, 110), 'arcane': (140, 120, 255),
}


# ------------------------------------------------------------------ glyph shapes (white on black mask)
def poly(d, pts, **kw):
    d.polygon([(x * S, y * S) for x, y in pts], **kw)


def g_sword(d):
    poly(d, [(0.47, 0.16), (0.53, 0.16), (0.55, 0.62), (0.45, 0.62)], fill=255)
    poly(d, [(0.47, 0.16), (0.53, 0.16), (0.5, 0.1)], fill=255)
    d.rectangle([0.33 * S, 0.62 * S, 0.67 * S, 0.67 * S], fill=255)
    d.rectangle([0.475 * S, 0.67 * S, 0.525 * S, 0.82 * S], fill=255)
    d.ellipse([0.45 * S, 0.8 * S, 0.55 * S, 0.88 * S], fill=255)


def g_shield(d):
    poly(d, [(0.25, 0.2), (0.75, 0.2), (0.75, 0.5), (0.5, 0.85), (0.25, 0.5)], fill=255)
    poly(d, [(0.32, 0.27), (0.68, 0.27), (0.68, 0.49), (0.5, 0.75), (0.32, 0.49)], fill=120)


def g_cross(d):
    d.rectangle([0.44 * S, 0.14 * S, 0.56 * S, 0.86 * S], fill=255)
    d.rectangle([0.24 * S, 0.32 * S, 0.76 * S, 0.44 * S], fill=255)


def g_xcross(d):
    for a in (45, -45):
        im = Image.new('L', (S, S))
        dd = ImageDraw.Draw(im)
        dd.rectangle([0.44 * S, 0.1 * S, 0.56 * S, 0.9 * S], fill=255)
        im = im.rotate(a, resample=Image.BICUBIC)
        d._image.paste(255, mask=im)


def g_burst_cross(d):
    g_cross(d)
    for i in range(8):
        a = i * math.pi / 4 + math.pi / 8
        x, y = 0.5 + math.cos(a) * 0.36, 0.42 + math.sin(a) * 0.36
        d.ellipse([(x - 0.03) * S, (y - 0.03) * S, (x + 0.03) * S, (y + 0.03) * S], fill=255)


def g_fist(d):
    d.rounded_rectangle([0.28 * S, 0.3 * S, 0.72 * S, 0.66 * S], radius=0.07 * S, fill=255)
    for i in range(4):
        x = 0.3 + i * 0.105
        d.rounded_rectangle([x * S, 0.22 * S, (x + 0.09) * S, 0.36 * S], radius=0.04 * S, fill=255)
    d.rectangle([0.34 * S, 0.66 * S, 0.66 * S, 0.84 * S], fill=255)
    for i in range(3):
        x = 0.395 + i * 0.105
        d.line([x * S, 0.3 * S, x * S, 0.44 * S], fill=110, width=int(0.018 * S))


def g_palm(d):
    d.rounded_rectangle([0.32 * S, 0.42 * S, 0.68 * S, 0.84 * S], radius=0.08 * S, fill=255)
    for i, h in enumerate([0.22, 0.16, 0.18, 0.26]):
        x = 0.33 + i * 0.09
        d.rounded_rectangle([x * S, h * S, (x + 0.07) * S, 0.5 * S], radius=0.035 * S, fill=255)
    poly(d, [(0.68, 0.6), (0.82, 0.44), (0.86, 0.5), (0.72, 0.7)], fill=255)


def g_spheres(d):
    for i in range(5):
        a = -math.pi / 2 + i * 2 * math.pi / 5
        x, y = 0.5 + math.cos(a) * 0.25, 0.52 + math.sin(a) * 0.25
        d.ellipse([(x - 0.09) * S, (y - 0.09) * S, (x + 0.09) * S, (y + 0.09) * S], fill=255)
    d.ellipse([0.42 * S, 0.44 * S, 0.58 * S, 0.6 * S], fill=170)


def g_orb(d):
    d.ellipse([0.26 * S, 0.26 * S, 0.74 * S, 0.74 * S], fill=255)
    d.ellipse([0.34 * S, 0.32 * S, 0.5 * S, 0.46 * S], fill=170)


def g_note(d):
    d.ellipse([0.22 * S, 0.62 * S, 0.42 * S, 0.78 * S], fill=255)
    d.ellipse([0.55 * S, 0.56 * S, 0.75 * S, 0.72 * S], fill=255)
    d.rectangle([0.38 * S, 0.22 * S, 0.43 * S, 0.72 * S], fill=255)
    d.rectangle([0.71 * S, 0.16 * S, 0.76 * S, 0.66 * S], fill=255)
    poly(d, [(0.38, 0.22), (0.76, 0.14), (0.76, 0.26), (0.38, 0.34)], fill=255)


def g_lute(d):
    d.ellipse([0.22 * S, 0.44 * S, 0.62 * S, 0.84 * S], fill=255)
    d.ellipse([0.36 * S, 0.58 * S, 0.48 * S, 0.7 * S], fill=90)
    poly(d, [(0.5, 0.5), (0.74, 0.18), (0.8, 0.24), (0.56, 0.56)], fill=255)
    d.rectangle([0.72 * S, 0.12 * S, 0.84 * S, 0.22 * S], fill=255)


def g_bow(d):
    d.arc([0.18 * S, 0.14 * S, 0.62 * S, 0.86 * S], 270, 90, fill=255, width=int(0.06 * S))
    d.line([0.4 * S, 0.17 * S, 0.4 * S, 0.83 * S], fill=200, width=int(0.015 * S))
    d.line([0.3 * S, 0.5 * S, 0.84 * S, 0.5 * S], fill=255, width=int(0.035 * S))
    poly(d, [(0.84, 0.5), (0.74, 0.43), (0.74, 0.57)], fill=255)


def g_arrows(d):
    for i in range(3):
        y = 0.28 + i * 0.22
        d.line([0.18 * S, (y + 0.12) * S, 0.74 * S, (y - 0.08) * S], fill=255, width=int(0.035 * S))
        poly(d, [(0.8, y - 0.1), (0.68, y - 0.11), (0.72, y - 0.0)], fill=255)


def g_flask(d):
    d.rectangle([0.43 * S, 0.14 * S, 0.57 * S, 0.36 * S], fill=255)
    d.ellipse([0.24 * S, 0.34 * S, 0.76 * S, 0.86 * S], fill=255)
    d.chord([0.3 * S, 0.4 * S, 0.7 * S, 0.8 * S], 10, 170, fill=140)
    d.rectangle([0.4 * S, 0.11 * S, 0.6 * S, 0.16 * S], fill=255)


def g_bomb(d):
    d.ellipse([0.2 * S, 0.3 * S, 0.72 * S, 0.82 * S], fill=255)
    d.rectangle([0.5 * S, 0.24 * S, 0.62 * S, 0.36 * S], fill=255)
    d.line([0.58 * S, 0.25 * S, 0.7 * S, 0.14 * S], fill=255, width=int(0.03 * S))
    for i in range(6):
        a = i * math.pi / 3
        d.line([0.72 * S, 0.12 * S, (0.72 + math.cos(a) * 0.08) * S, (0.12 + math.sin(a) * 0.08) * S], fill=255, width=int(0.02 * S))


def g_book(d):
    poly(d, [(0.18, 0.26), (0.5, 0.32), (0.82, 0.26), (0.82, 0.78), (0.5, 0.84), (0.18, 0.78)], fill=255)
    d.line([0.5 * S, 0.32 * S, 0.5 * S, 0.84 * S], fill=100, width=int(0.02 * S))
    for i in range(3):
        y = 0.42 + i * 0.1
        d.line([0.25 * S, y * S, 0.44 * S, (y + 0.02) * S], fill=150, width=int(0.012 * S))
        d.line([0.56 * S, (y + 0.02) * S, 0.75 * S, y * S], fill=150, width=int(0.012 * S))


def g_spikes(d):
    for x, h in [(0.22, 0.45), (0.36, 0.2), (0.5, 0.3), (0.64, 0.16), (0.78, 0.4)]:
        poly(d, [(x - 0.08, 0.84), (x + 0.08, 0.84), (x, h)], fill=255)


def g_swirl(d):
    for i in range(3):
        r = 0.12 + i * 0.1
        d.arc([(0.5 - r) * S, (0.5 - r) * S, (0.5 + r) * S, (0.5 + r) * S], 20 + i * 70, 290 + i * 70, fill=255, width=int(0.045 * S))


def g_bolt(d):
    poly(d, [(0.58, 0.1), (0.28, 0.54), (0.48, 0.54), (0.4, 0.9), (0.74, 0.42), (0.53, 0.42)], fill=255)


def g_flame(d):
    poly(d, [(0.5, 0.1), (0.7, 0.4), (0.76, 0.62), (0.68, 0.8), (0.5, 0.88), (0.32, 0.8), (0.24, 0.62), (0.32, 0.42), (0.4, 0.52), (0.42, 0.3)], fill=255)
    poly(d, [(0.5, 0.46), (0.6, 0.62), (0.58, 0.76), (0.5, 0.8), (0.42, 0.76), (0.42, 0.62)], fill=140)


def g_ghost(d):
    d.pieslice([0.28 * S, 0.16 * S, 0.72 * S, 0.6 * S], 180, 360, fill=255)
    d.rectangle([0.28 * S, 0.38 * S, 0.72 * S, 0.72 * S], fill=255)
    for i in range(4):
        x = 0.28 + i * 0.11
        poly(d, [(x, 0.72), (x + 0.11, 0.72), (x + 0.055, 0.84)], fill=255)
    d.ellipse([0.36 * S, 0.36 * S, 0.45 * S, 0.47 * S], fill=60)
    d.ellipse([0.55 * S, 0.36 * S, 0.64 * S, 0.47 * S], fill=60)


def g_drop(d):
    poly(d, [(0.5, 0.12), (0.72, 0.5), (0.28, 0.5)], fill=255)
    d.ellipse([0.27 * S, 0.38 * S, 0.73 * S, 0.84 * S], fill=255)


def g_coin(d):
    d.ellipse([0.22 * S, 0.22 * S, 0.78 * S, 0.78 * S], fill=255)
    d.ellipse([0.3 * S, 0.3 * S, 0.7 * S, 0.7 * S], fill=170)
    d.rectangle([0.46 * S, 0.36 * S, 0.54 * S, 0.64 * S], fill=255)


def g_dagger(d):
    poly(d, [(0.5, 0.12), (0.57, 0.3), (0.55, 0.6), (0.45, 0.6), (0.43, 0.3)], fill=255)
    d.rectangle([0.36 * S, 0.6 * S, 0.64 * S, 0.65 * S], fill=255)
    d.rectangle([0.47 * S, 0.65 * S, 0.53 * S, 0.84 * S], fill=255)


def g_daggers(d):
    for a in (35, -35):
        im = Image.new('L', (S, S))
        g_dagger(ImageDraw.Draw(im))
        im = im.rotate(a, resample=Image.BICUBIC)
        d._image.paste(255, mask=im)


def g_smoke(d):
    for x, y, r in [(0.36, 0.56, 0.17), (0.56, 0.48, 0.2), (0.66, 0.64, 0.14), (0.44, 0.7, 0.14)]:
        d.ellipse([(x - r) * S, (y - r) * S, (x + r) * S, (y + r) * S], fill=255)
    d.ellipse([0.42 * S, 0.44 * S, 0.58 * S, 0.56 * S], fill=150)


def g_eye(d):
    d.ellipse([0.16 * S, 0.32 * S, 0.84 * S, 0.68 * S], fill=255)
    d.ellipse([0.38 * S, 0.38 * S, 0.62 * S, 0.62 * S], fill=90)
    d.ellipse([0.45 * S, 0.45 * S, 0.55 * S, 0.55 * S], fill=255)


def g_wings(d):
    for side in (-1, 1):
        pts = [(0.5, 0.5)]
        for i in range(5):
            a = math.radians(200 + i * 25) if side < 0 else math.radians(-20 - i * 25)
            r = 0.36 - i * 0.03
            pts.append((0.5 + side * abs(math.cos(a)) * r, 0.5 - abs(math.sin(a)) * r * 0.9 + i * 0.07))
        poly(d, pts + [(0.5, 0.62)], fill=255)


def g_heart(d):
    d.ellipse([0.2 * S, 0.24 * S, 0.52 * S, 0.56 * S], fill=255)
    d.ellipse([0.48 * S, 0.24 * S, 0.8 * S, 0.56 * S], fill=255)
    poly(d, [(0.22, 0.46), (0.78, 0.46), (0.5, 0.84)], fill=255)


def g_boot(d):
    poly(d, [(0.34, 0.16), (0.56, 0.16), (0.56, 0.6), (0.82, 0.68), (0.82, 0.82), (0.3, 0.82)], fill=255)
    for i in range(3):
        d.line([(0.06 + i * 0.07) * S, (0.4 + i * 0.12) * S, (0.26 + i * 0.03) * S, (0.4 + i * 0.12) * S], fill=200, width=int(0.025 * S))


def g_apple(d):
    d.ellipse([0.22 * S, 0.3 * S, 0.54 * S, 0.84 * S], fill=255)
    d.ellipse([0.46 * S, 0.3 * S, 0.78 * S, 0.84 * S], fill=255)
    d.line([0.5 * S, 0.32 * S, 0.55 * S, 0.16 * S], fill=255, width=int(0.03 * S))
    d.ellipse([0.55 * S, 0.14 * S, 0.74 * S, 0.26 * S], fill=255)


def g_puppet(d):
    d.rectangle([0.2 * S, 0.14 * S, 0.8 * S, 0.19 * S], fill=255)
    for x in (0.3, 0.5, 0.7):
        d.line([x * S, 0.19 * S, x * S, 0.44 * S], fill=200, width=int(0.012 * S))
    d.ellipse([0.42 * S, 0.4 * S, 0.58 * S, 0.54 * S], fill=255)
    d.rectangle([0.44 * S, 0.54 * S, 0.56 * S, 0.72 * S], fill=255)
    d.line([0.3 * S, 0.44 * S, 0.44 * S, 0.58 * S], fill=255, width=int(0.03 * S))
    d.line([0.7 * S, 0.44 * S, 0.56 * S, 0.58 * S], fill=255, width=int(0.03 * S))
    d.line([0.46 * S, 0.72 * S, 0.4 * S, 0.88 * S], fill=255, width=int(0.035 * S))
    d.line([0.54 * S, 0.72 * S, 0.6 * S, 0.88 * S], fill=255, width=int(0.035 * S))


def g_chain(d):
    for i in range(4):
        x, y = 0.24 + i * 0.16, 0.26 + i * 0.16
        d.ellipse([(x - 0.1) * S, (y - 0.07) * S, (x + 0.1) * S, (y + 0.07) * S], outline=255, width=int(0.035 * S))


def g_comet(d):
    d.ellipse([0.52 * S, 0.52 * S, 0.8 * S, 0.8 * S], fill=255)
    poly(d, [(0.56, 0.54), (0.16, 0.2), (0.24, 0.16), (0.74, 0.52)], fill=200)
    poly(d, [(0.54, 0.62), (0.2, 0.42), (0.26, 0.36), (0.62, 0.56)], fill=150)


def g_crystal(d):
    poly(d, [(0.5, 0.12), (0.7, 0.36), (0.62, 0.86), (0.38, 0.86), (0.3, 0.36)], fill=255)
    poly(d, [(0.5, 0.12), (0.5, 0.86), (0.38, 0.86), (0.3, 0.36)], fill=190)


def g_axe(d):
    d.rectangle([0.47 * S, 0.14 * S, 0.53 * S, 0.88 * S], fill=255)
    d.pieslice([0.2 * S, 0.14 * S, 0.62 * S, 0.56 * S], 110, 250, fill=255)
    poly(d, [(0.34, 0.2), (0.5, 0.26), (0.5, 0.44), (0.34, 0.5)], fill=255)


def g_hammer(d):
    d.rectangle([0.47 * S, 0.3 * S, 0.53 * S, 0.88 * S], fill=255)
    d.rounded_rectangle([0.26 * S, 0.16 * S, 0.74 * S, 0.36 * S], radius=0.03 * S, fill=255)


def g_cart(d):
    d.rectangle([0.18 * S, 0.34 * S, 0.74 * S, 0.62 * S], fill=255)
    d.line([0.74 * S, 0.36 * S, 0.88 * S, 0.24 * S], fill=255, width=int(0.035 * S))
    for x in (0.3, 0.62):
        d.ellipse([(x - 0.08) * S, 0.6 * S, (x + 0.08) * S, 0.76 * S], fill=255)


def g_gear(d):
    for i in range(8):
        a = i * math.pi / 4
        x, y = 0.5 + math.cos(a) * 0.3, 0.5 + math.sin(a) * 0.3
        d.ellipse([(x - 0.07) * S, (y - 0.07) * S, (x + 0.07) * S, (y + 0.07) * S], fill=255)
    d.ellipse([0.22 * S, 0.22 * S, 0.78 * S, 0.78 * S], fill=255)
    d.ellipse([0.4 * S, 0.4 * S, 0.6 * S, 0.6 * S], fill=80)


def g_star(d):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 0.36 if i % 2 == 0 else 0.15
        pts.append((0.5 + math.cos(a) * r, 0.52 + math.sin(a) * r))
    poly(d, pts, fill=255)


def g_snow(d):
    for i in range(3):
        a = i * math.pi / 3
        dx, dy = math.cos(a) * 0.34, math.sin(a) * 0.34
        d.line([(0.5 - dx) * S, (0.5 - dy) * S, (0.5 + dx) * S, (0.5 + dy) * S], fill=255, width=int(0.045 * S))
    d.ellipse([0.42 * S, 0.42 * S, 0.58 * S, 0.58 * S], fill=255)


def g_wave(d):
    for i in range(3):
        y = 0.32 + i * 0.16
        d.arc([0.12 * S, (y - 0.08) * S, 0.5 * S, (y + 0.08) * S], 180, 360, fill=255, width=int(0.04 * S))
        d.arc([0.5 * S, (y - 0.08) * S, 0.88 * S, (y + 0.08) * S], 0, 180, fill=255, width=int(0.04 * S))


def g_rune(d):
    d.ellipse([0.18 * S, 0.18 * S, 0.82 * S, 0.82 * S], outline=255, width=int(0.04 * S))
    poly(d, [(0.5, 0.26), (0.68, 0.66), (0.32, 0.66)], outline=255, width=int(0.035 * S))
    d.line([0.5 * S, 0.26 * S, 0.5 * S, 0.74 * S], fill=255, width=int(0.035 * S))


def g_spear(d):
    d.line([0.2 * S, 0.84 * S, 0.7 * S, 0.3 * S], fill=255, width=int(0.045 * S))
    poly(d, [(0.84, 0.14), (0.66, 0.26), (0.74, 0.34)], fill=255)
    poly(d, [(0.84, 0.14), (0.62, 0.2), (0.7, 0.28)], fill=255)


def g_mask(d):
    d.chord([0.2 * S, 0.22 * S, 0.8 * S, 0.82 * S], 160, 380, fill=255)
    d.ellipse([0.3 * S, 0.38 * S, 0.44 * S, 0.5 * S], fill=60)
    d.ellipse([0.56 * S, 0.38 * S, 0.7 * S, 0.5 * S], fill=60)


def g_moon(d):
    d.ellipse([0.2 * S, 0.2 * S, 0.8 * S, 0.8 * S], fill=255)
    d.ellipse([0.34 * S, 0.12 * S, 0.9 * S, 0.68 * S], fill=0)


def g_dice(d):
    d.rounded_rectangle([0.24 * S, 0.24 * S, 0.76 * S, 0.76 * S], radius=0.08 * S, fill=255)
    for x, y in [(0.36, 0.36), (0.64, 0.64), (0.5, 0.5), (0.64, 0.36), (0.36, 0.64)]:
        d.ellipse([(x - 0.05) * S, (y - 0.05) * S, (x + 0.05) * S, (y + 0.05) * S], fill=80)


GLYPHS = {k[2:]: v for k, v in globals().items() if k.startswith('g_')}

# ------------------------------------------------------------------ which glyph and colour each skill gets
SPEC = {
    'napalm_beat': ('ghost', 'shadow'), 'soul_strike': ('orb', 'shadow'), 'fire_wall': ('flame', 'fire'),
    'angelus': ('wings', 'holy'), 'sand_attack': ('smoke', 'earth'), 'basic_training': ('star', 'steel'),
    'field_dressing': ('heart', 'nature'),
    # Crusader / Paladin
    'bulwark_training': ('cross', 'holy'), 'shield_rush': ('shield', 'steel'), 'aegis_vow': ('shield', 'holy'),
    'radiant_cross': ('burst_cross', 'holy'), 'lance_charge': ('xcross', 'holy'), 'holy_bastion': ('shield', 'gold'),
    'judgement_lance': ('chain', 'steel'), 'sanctified_ground': ('note', 'holy'), 'guardian_spirit': ('heart', 'blood'),
    # Bard / Clown
    'resonant_strings': ('lute', 'music'), 'dissonant_chord': ('note', 'lightning'), 'rhythm_of_haste': ('boot', 'music'),
    'briar_lullaby': ('snow', 'ice'), 'stage_presence': ('note', 'wind'), 'crescendo': ('arrows', 'wind'),
    'ballad_of_vigor': ('apple', 'blood'), 'whiplash_volley': ('puppet', 'music'), 'virtuoso_focus': ('lute', 'arcane'),
    # Sage / Professor
    'tome_study': ('book', 'arcane'), 'stone_lance': ('spikes', 'earth'), 'elemental_infusion': ('flame', 'fire'),
    'quicksand_pit': ('spikes', 'earth'), 'spell_ward': ('rune', 'ice'), 'arcane_comet': ('dice', 'arcane'),
    'mana_flow': ('drop', 'spirit'), 'chain_spark': ('bolt', 'arcane'), 'runic_aegis': ('book', 'spirit'),
    # Monk / Champion
    'iron_fist': ('fist', 'steel'), 'palm_strike': ('palm', 'spirit'), 'inner_spheres': ('spheres', 'spirit'),
    'chi_burst': ('orb', 'spirit'), 'steady_breath': ('swirl', 'nature'), 'thousand_palms': ('fist', 'spirit'),
    'rising_dragon_kick': ('fist', 'fire'), 'zen_guard': ('shield', 'gold'), 'sky_resolve': ('palm', 'gold'),
    # Alchemist / Creator
    'potion_lore': ('flask', 'blood'), 'acid_flask': ('flask', 'poison'), 'fire_flask': ('bomb', 'fire'),
    'alloy_coating': ('shield', 'poison'), 'clockwork_sights': ('axe', 'steel'), 'golem_smash': ('flask', 'lightning'),
    'elixir_rush': ('flask', 'fire'), 'shrapnel_bomb': ('bomb', 'spirit'), 'master_alchemy': ('gear', 'nature'),
    # Rogue / Stalker
    'sleight_of_hand': ('coin', 'gold'), 'dirty_trick': ('dagger', 'shadow'), 'smoke_veil': ('smoke', 'shadow'),
    'knife_fan': ('daggers', 'steel'), 'trick_shot': ('bow', 'wind'), 'phantom_blades': ('shield', 'shadow'),
    'shadow_step': ('boot', 'shadow'), 'ambush_combo': ('mask', 'shadow'), 'lucky_charm': ('eye', 'arcane'),
}
# 3rd / 4th jobs: (strike, guard, mastery) glyphs and a colour per job line
ADV = {
    'swordsman_a_4': (('rune', 'fire'), ('shield', 'earth'), ('rune', 'spirit')),
    'swordsman_a_5': (('sword', 'wind'), ('heart', 'blood'), ('sword', 'gold')),
    'swordsman_b_4': (('spikes', 'holy'), ('shield', 'gold'), ('shield', 'blood')),
    'swordsman_b_5': (('spear', 'holy'), ('shield', 'holy'), ('shield', 'steel')),
    'archer_a_4': (('arrows', 'wind'), ('eye', 'nature'), ('gear', 'earth')),
    'archer_a_5': (('swirl', 'wind'), ('wings', 'wind'), ('bow', 'gold')),
    'archer_b_4': (('arrows', 'music'), ('note', 'steel'), ('note', 'spirit')),
    'archer_b_5': (('star', 'music'), ('note', 'arcane'), ('lute', 'gold')),
    'mage_a_4': (('comet', 'fire'), ('rune', 'arcane'), ('swirl', 'arcane')),
    'mage_a_5': (('crystal', 'ice'), ('star', 'arcane'), ('book', 'spirit')),
    'mage_b_4': (('wave', 'arcane'), ('flame', 'earth'), ('drop', 'spirit')),
    'mage_b_5': (('orb', 'fire'), ('rune', 'nature'), ('swirl', 'spirit')),
    'acolyte_a_4': (('cross', 'holy'), ('shield', 'holy'), ('heart', 'holy')),
    'acolyte_a_5': (('swirl', 'holy'), ('eye', 'holy'), ('book', 'gold')),
    'acolyte_b_4': (('spheres', 'spirit'), ('bolt', 'spirit'), ('fist', 'gold')),
    'acolyte_b_5': (('flame', 'holy'), ('shield', 'fire'), ('fist', 'holy')),
    'merchant_a_4': (('axe', 'steel'), ('gear', 'steel'), ('gear', 'gold')),
    'merchant_a_5': (('hammer', 'earth'), ('axe', 'gold'), ('axe', 'fire')),
    'merchant_b_4': (('cart', 'earth'), ('cart', 'wind'), ('book', 'nature')),
    'merchant_b_5': (('bomb', 'fire'), ('spikes', 'nature'), ('flask', 'nature')),
    'thief_a_4': (('daggers', 'blood'), ('boot', 'shadow'), ('flask', 'poison')),
    'thief_a_5': (('spikes', 'shadow'), ('smoke', 'shadow'), ('daggers', 'gold')),
    'thief_b_4': (('daggers', 'shadow'), ('mask', 'shadow'), ('rune', 'shadow')),
    'thief_b_5': (('moon', 'shadow'), ('eye', 'shadow'), ('dagger', 'arcane')),
}
for key, trio in ADV.items():
    for kind, spec in zip(['strike', 'guard', 'mastery'], trio):
        SPEC['%s_%s' % (key, kind)] = spec


# ------------------------------------------------------------------ rendering
def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def render(glyph: str, hue_name: str) -> Image.Image:
    hue = HUES[hue_name]
    img = Image.new('RGB', (S, S))
    px = img.load()
    for y in range(S):
        for x in range(S):
            r = math.hypot(x - S * 0.5, y - S * 0.46) / (S * 0.62)
            c = mix(mix(hue, (255, 255, 255), 0.05), (10, 8, 12), min(1.0, r ** 1.15 * 0.95 + 0.12))
            px[x, y] = c
    mask = Image.new('L', (S, S))
    GLYPHS[glyph](ImageDraw.Draw(mask))
    # coloured glow around the glyph
    glow = mask.filter(ImageFilter.GaussianBlur(S * 0.05))
    glow_col = Image.new('RGB', (S, S), mix(hue, (255, 255, 255), 0.25))
    img = Image.composite(glow_col, img, glow.point(lambda v: int(v * 0.85)))
    # glyph body: light tint of the hue, brighter in the middle
    body = Image.new('RGB', (S, S), mix(hue, (255, 255, 255), 0.72))
    img = Image.composite(body, img, mask)
    inner = mask.filter(ImageFilter.GaussianBlur(S * 0.02))
    core = ImageChops.multiply(mask, inner.point(lambda v: 255 if v > 200 else 0))
    img = Image.composite(Image.new('RGB', (S, S), (255, 255, 250)), img, core.point(lambda v: int(v * 0.55)))
    # bronze frame like the existing icons
    d = ImageDraw.Draw(img)
    f = int(S * 0.045)
    d.rectangle([0, 0, S - 1, S - 1], outline=(52, 36, 22), width=f)
    d.rectangle([f, f, S - 1 - f, S - 1 - f], outline=(176, 128, 62), width=int(S * 0.018))
    d.rectangle([f + int(S * 0.018), f + int(S * 0.018), S - 1 - f - int(S * 0.018), S - 1 - f - int(S * 0.018)],
                outline=(70, 48, 28), width=int(S * 0.012))
    return img.resize((64, 64), Image.LANCZOS)


if __name__ == '__main__':
    import sys
    OUT.mkdir(parents=True, exist_ok=True)
    only = sys.argv[1:]
    for sid, (g, h) in SPEC.items():
        if only and sid not in only:
            continue
        render(g, h).save(OUT / ('%s.png' % sid), optimize=True)
    print(len(SPEC), 'icons')
