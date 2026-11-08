"""Realistic 3D models for hats, helmets, body armour/clothes, capes, gloves and
boots, coloured from each item's original pixel icon."""
import math
import numpy as np
from PIL import Image
import colorsys
import bpy
import bmesh
from mathutils import Vector
from hero_models import (lin, link, loft, lathe, tube, sphere, extrude_shape, cut_gem, apply,
                         mat_metal, mat_pbr, mat_leather, mat_gem)


# ------------------------------------------------------------------ palette (dominant colours)
def colors(path, k=5):
    a = np.array(Image.open(path).convert("RGBA")).reshape(-1, 4)
    a = a[a[:, 3] > 128][:, :3].astype(float) / 255
    lum = a @ np.array([0.3, 0.59, 0.11])
    a = a[lum > 0.1]
    if len(a) < 4:
        return [((0.6, 0.6, 0.6), 1.0)]
    rng = np.random.default_rng(0)
    c = a[rng.choice(len(a), k, replace=False)]
    for _ in range(20):
        d = ((a[:, None] - c[None]) ** 2).sum(2)
        lab = d.argmin(1)
        for j in range(k):
            if (lab == j).any():
                c[j] = a[lab == j].mean(0)
    out = []
    for j in range(k):
        n = (lab == j).mean()
        if n > 0.02:
            out.append((tuple(c[j]), n))
    # merge near-duplicates
    merged = []
    for col, n in sorted(out, key=lambda t: -t[1]):
        for i, (mc, mn) in enumerate(merged):
            if sum((x - y) ** 2 for x, y in zip(col, mc)) < 0.012:
                merged[i] = (mc, mn + n)
                break
        else:
            merged.append((col, n))
    return merged


def hsv(c):
    return colorsys.rgb_to_hsv(*c)


def roles(path):
    cs = colors(path)
    main = cs[0][0]
    # main should be the big colour that is not a near-black shadow
    for col, n in cs:
        if hsv(col)[2] > 0.25:
            main = col
            break
    gold = None
    accent = None
    for col, n in cs:
        h, s, v = hsv(col)
        if 0.09 < h < 0.17 and s > 0.45 and v > 0.6 and col != main:
            gold = gold or col
    for col, n in cs:
        h, s, v = hsv(col)
        if col is not main and col != gold and s > 0.35 and v > 0.3 and abs(h - hsv(main)[0]) > 0.06:
            accent = col
            break
    second = None
    for col, n in cs:
        if col != main and col != gold:
            second = col
            break
    return dict(main=main, gold=gold, accent=accent, second=second or tuple(x * 0.6 for x in main),
                metal=(hsv(main)[1] < 0.22 and hsv(main)[2] > 0.5))


def shade(c, k):
    return tuple(min(1.0, x * k) for x in c)


# ------------------------------------------------------------------ materials
def mat_fabric(col, name="Fabric", sheen=0.6, scale=160, rough=0.75, velvet=False):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    w1 = nt.nodes.new("ShaderNodeTexWave"); w1.wave_type = "BANDS"; w1.bands_direction = "X"
    w2 = nt.nodes.new("ShaderNodeTexWave"); w2.wave_type = "BANDS"; w2.bands_direction = "Z"
    for w in (w1, w2):
        w.inputs["Scale"].default_value = scale
        nt.links.new(tc.outputs["Object"], w.inputs["Vector"])
    mx = nt.nodes.new("ShaderNodeMath"); mx.operation = "MAXIMUM"
    nt.links.new(w1.outputs["Fac"], mx.inputs[0]); nt.links.new(w2.outputs["Fac"], mx.inputs[1])
    nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 6; nz.inputs["Detail"].default_value = 4
    nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    mix.inputs["A"].default_value = (*lin(col), 1)
    mix.inputs["B"].default_value = (*lin(shade(col, 0.78)), 1)
    nt.links.new(nz.outputs["Fac"], mix.inputs["Factor"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = rough
    b.inputs["Sheen Weight"].default_value = sheen if not velvet else 1.0
    b.inputs["Sheen Tint"].default_value = (*lin(shade(col, 1.4)), 1)
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.18; bump.inputs["Distance"].default_value = 0.005
    nt.links.new(mx.outputs[0], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def mat_fur(col, name="Fur"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 140; nz.inputs["Detail"].default_value = 10
    nz.inputs["Distortion"].default_value = 2
    nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    mix.inputs["A"].default_value = (*lin(shade(col, 0.6)), 1)
    mix.inputs["B"].default_value = (*lin(shade(col, 1.15)), 1)
    nt.links.new(nz.outputs["Fac"], mix.inputs["Factor"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.9
    b.inputs["Sheen Weight"].default_value = 1.0
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.8
    nt.links.new(nz.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def mat_straw(col, name="Straw"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    w = nt.nodes.new("ShaderNodeTexWave"); w.wave_type = "RINGS"; w.inputs["Scale"].default_value = 30
    w.inputs["Distortion"].default_value = 0.3
    nt.links.new(tc.outputs["Object"], w.inputs["Vector"])
    w2 = nt.nodes.new("ShaderNodeTexWave"); w2.wave_type = "BANDS"; w2.bands_direction = "Z"; w2.inputs["Scale"].default_value = 70
    nt.links.new(tc.outputs["Object"], w2.inputs["Vector"])
    mx = nt.nodes.new("ShaderNodeMath"); mx.operation = "MULTIPLY"
    nt.links.new(w.outputs["Fac"], mx.inputs[0]); nt.links.new(w2.outputs["Fac"], mx.inputs[1])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    mix.inputs["A"].default_value = (*lin(shade(col, 0.7)), 1)
    mix.inputs["B"].default_value = (*lin(shade(col, 1.1)), 1)
    nt.links.new(w.outputs["Fac"], mix.inputs["Factor"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.6
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.5
    nt.links.new(mx.outputs[0], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def mat_plastic(col, rough=0.25, name="Plastic"):
    return mat_pbr(col, rough, 0, 0.8, name)


# ------------------------------------------------------------------ helpers
def superellipse(a, b, n=2.6, k=32, cx=0.0, cy=0.0):
    pts = []
    for i in range(k):
        t = 2 * math.pi * i / k
        c, s = math.cos(t), math.sin(t)
        pts.append((cx + a * math.copysign(abs(c) ** (2 / n), c), cy + b * math.copysign(abs(s) ** (2 / n), s)))
    return pts


def to_mesh(o):
    bpy.context.view_layer.objects.active = o
    for x in bpy.context.selected_objects:
        x.select_set(False)
    o.select_set(True)
    bpy.ops.object.convert(target="MESH")
    o = bpy.context.active_object
    o.select_set(False)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def taper_tube(points, radii, name="T", res=16):
    o = tube(points, 1.0, name, res)
    sp = o.data.splines[0]
    for p, r in zip(sp.points, radii):
        p.radius = r
    return to_mesh(o)


def subsurf(o, lv=2):
    m = o.modifiers.new("ss", "SUBSURF"); m.levels = lv; m.render_levels = lv
    return o


def wrinkle(o, strength=0.025, scale=0.25):
    d = o.modifiers.new("wr", "DISPLACE")
    t = bpy.data.textures.new("wr", "CLOUDS"); t.noise_scale = scale; t.noise_depth = 2
    d.texture = t; d.strength = strength; d.mid_level = 0.5
    return o


def rounded_box(size, loc, bev=0.08, name="Box"):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    b = o.modifiers.new("b", "BEVEL"); b.width = bev; b.segments = 5; b.limit_method = "NONE"
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def torus(R, r, loc=(0, 0, 0), rot=(0, 0, 0), name="Tor", scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=64, minor_segments=16, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def dome(r, loc=(0, 0, 0), zscale=1.0, cut=0.0, name="Dome", seg=48, thick=0.03):
    """upper hemisphere shell"""
    prof = []
    N = 16
    for i in range(N + 1):
        a = (math.pi / 2) * i / N
        prof.append((r * math.cos(a), r * math.sin(a) * zscale))
    o = lathe(prof, name, seg)
    o.location = loc
    if thick:
        s = o.modifiers.new("s", "SOLIDIFY"); s.thickness = thick; s.offset = -1
    return o


def disk(r_in, r_out, loc=(0, 0, 0), name="Brim", droop=0.0, seg=64, thick=0.025):
    prof = []
    N = 8
    for i in range(N + 1):
        t = i / N
        r = r_in + (r_out - r_in) * t
        prof.append((r, -droop * t * t))
    o = lathe(prof, name, seg)
    o.location = loc
    s = o.modifiers.new("s", "SOLIDIFY"); s.thickness = thick
    return o


def feather(length, width, col, loc, rot, name="Feather"):
    pts = []
    N = 18
    for i in range(N + 1):
        t = i / N
        w = width * math.sin(math.pi * min(1, t * 1.05)) ** 0.7
        pts.append((w, t * length))
    outline = [(x, z) for x, z in pts] + [(-x * 0.8, z) for x, z in reversed(pts)]
    f = extrude_shape(outline, 0.008, 0.004, name)
    # notch barbs
    for v in f.data.vertices:
        v.co.y += 0.02 * math.sin(v.co.z * 40) * abs(v.co.x) / max(width, 1e-3)
    apply(f, mat_fabric(col, "FeatherMat", 0.8, 300, 0.6))
    r = taper_tube([(0, 0, -0.08), (0, -0.005, length * 0.5), (0, 0, length)], [0.008, 0.006, 0.002], "Rachis")
    apply(r, mat_pbr(shade(col, 1.3), 0.4))
    piv = bpy.data.objects.new(name + "P", None)
    bpy.context.scene.collection.objects.link(piv)
    f.parent = piv; r.parent = piv
    piv.location = loc
    piv.rotation_euler = rot
    return [f, r]


def group(obs, rot, loc=(0, 0, 0)):
    piv = bpy.data.objects.new("Pivot", None)
    bpy.context.scene.collection.objects.link(piv)
    for o in obs:
        if o.parent is None:
            o.parent = piv
    piv.rotation_euler = tuple(math.radians(x) for x in rot)
    piv.location = loc
    return obs


# ------------------------------------------------------------------ body wear
def torso(kind, R):
    """kind: plate | robe | tunic | vest | coat"""
    main = R["main"]
    hem = {"robe": (-1.15, 0.62, 0.36), "coat": (-0.95, 0.55, 0.34), "plate": (-0.75, 0.46, 0.3), "vest": (-0.72, 0.46, 0.3), "tunic": (-0.85, 0.52, 0.31)}[kind]
    secs = [hem,
            (-0.45 if kind != "robe" else -0.6, 0.44 if kind != "robe" else 0.5, 0.28),
            (-0.15, 0.4, 0.26),
            (0.2, 0.47, 0.29),
            (0.45, 0.5, 0.28),
            (0.62, 0.47, 0.24),
            (0.72, 0.3, 0.19),
            (0.76, 0.17, 0.14)]
    o = loft([(z, superellipse(a, b, 2.4, 40)) for z, a, b in secs], "Torso", cap=False)
    s = o.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.03
    subsurf(o, 1)
    obs = [o]
    if kind == "plate":
        m = mat_metal(main, 0.16)
        apply(o, m)
        # breastplate ridge and abdomen lames
        for i, z in enumerate((-0.12, -0.3, -0.48, -0.64)):
            band = loft([(z - 0.035, superellipse(0.43 + 0.01 * i + 0.012, 0.29, 2.4, 40)), (z, superellipse(0.45 + 0.01 * i + 0.012, 0.3, 2.4, 40)), (z + 0.035, superellipse(0.43 + 0.01 * i + 0.012, 0.29, 2.4, 40))], "Lame")
            apply(band, m); obs.append(band)
        ridge = taper_tube([(0, -0.3, -0.05), (0, -0.33, 0.25), (0, -0.3, 0.55)], [0.025, 0.03, 0.02], "Ridge")
        apply(ridge, m); obs.append(ridge)
        trim = R["gold"] or shade(main, 0.75)
        for sx in (-1, 1):
            for j in range(3):
                p = dome(0.3 - j * 0.04, (sx * (0.5 + j * 0.05), 0, 0.5 - j * 0.11), 0.75, name="Pauldron", thick=0.02)
                p.rotation_euler = (0, sx * math.radians(38 + j * 6), 0)
                p.scale = (1, 0.95, 1)
                apply(p, m); obs.append(p)
            edge = torus(0.3, 0.022, (sx * 0.5, 0, 0.5), (0, sx * math.radians(38), 0), "PEdge")
            apply(edge, mat_metal(trim, 0.2)); obs.append(edge)
            for k in range(3):
                rv = sphere(0.022, (sx * 0.3, -0.29, 0.38 - k * 0.32), "Rivet", 12); apply(rv, mat_metal(trim, 0.2)); obs.append(rv)
        col = torus(0.2, 0.04, (0, 0, 0.74), (0, 0, 0), "Gorget", (1, 0.75, 1)); apply(col, mat_metal(trim, 0.2)); obs.append(col)
        if R["accent"]:
            obs.append(cut_gem(0.06, (0, -0.33, 0.3), R["accent"]))
        return obs
    if kind == "vest":
        m = mat_leather(main)
        apply(o, m)
        for z in (0.4, 0.15, -0.1, -0.35):
            b = sphere(0.03, (0.0, -0.3, z), "Button", 16); apply(b, mat_metal(R["gold"] or (0.85, 0.7, 0.35), 0.25)); obs.append(b)
        seam = taper_tube([(0, -0.29, -0.7), (0, -0.31, 0.0), (0, -0.27, 0.68)], [0.012, 0.012, 0.01], "Seam")
        apply(seam, mat_leather(shade(main, 0.6))); obs.append(seam)
        col = torus(0.19, 0.035, (0, 0, 0.74), (math.radians(-10), 0, 0), "Collar", (1, 0.8, 1))
        apply(col, mat_leather(shade(main, 0.75))); obs.append(col)
        wrinkle(o, 0.015, 0.3)
    else:
        velvet = kind == "robe"
        m = mat_fur(main) if kind == "coat" else mat_fabric(main, "Cloth", 0.7, 170, 0.8, velvet)
        apply(o, m)
        wrinkle(o, 0.03, 0.22)
        # sleeves
        sl = {"robe": 0.62, "coat": 0.7, "tunic": 0.45}[kind]
        for sx in (-1, 1):
            p0 = (sx * 0.42, 0, 0.58); p1 = (sx * 0.7, -0.02, 0.38); p2 = (sx * (0.72 + sl * 0.35), -0.03, 0.55 - sl)
            sv = taper_tube([p0, p1, p2], [0.19, 0.2, 0.17 if kind != "robe" else 0.25], "Sleeve")
            apply(sv, m); wrinkle(sv, 0.02, 0.2); obs.append(sv)
            cuffc = R["gold"] or R["second"]
            cf = torus(0.17 if kind != "robe" else 0.24, 0.035, p2, (0, 0, 0), "Cuff")
            d = Vector(p2) - Vector(p1)
            cf.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
            apply(cf, mat_fur((0.95, 0.94, 0.9)) if kind == "coat" else mat_fabric(cuffc, "Trim", 0.5, 200, 0.6)); obs.append(cf)
        trimc = R["gold"] or R["accent"] or R["second"]
        collar = torus(0.2, 0.05, (0, 0, 0.74), (math.radians(-10), 0, 0), "Collar", (1, 0.8, 1))
        apply(collar, mat_fur((0.95, 0.94, 0.9)) if kind == "coat" else mat_fabric(trimc, "Collar", 0.5, 200, 0.55)); obs.append(collar)
        # belt
        bz = -0.2 if kind != "robe" else -0.3
        beltc = R["accent"] if R["accent"] and kind != "tunic" else (0.35, 0.22, 0.13)
        belt = loft([(bz - 0.05, superellipse(0.425, 0.272, 2.4, 40)), (bz + 0.05, superellipse(0.415, 0.268, 2.4, 40))], "Belt")
        s2 = belt.modifiers.new("s", "SOLIDIFY"); s2.thickness = 0.02
        apply(belt, mat_leather(beltc) if kind != "robe" else mat_fabric(beltc, "Sash", 0.6)); obs.append(belt)
        bk = rounded_box((0.11, 0.03, 0.09), (0, -0.285, bz), 0.012, "Buckle")
        apply(bk, mat_metal(R["gold"] or (0.85, 0.72, 0.4), 0.2)); obs.append(bk)
        if kind == "robe":
            strip = loft([(z, superellipse(0.07, 0.01, 2, 12, 0, -(0.28 + 0.08 * max(0, -z)))) for z in np.linspace(-1.12, 0.7, 10)], "Stole")
            apply(strip, mat_fabric(trimc, "Stole", 0.6, 220, 0.55)); obs.append(strip)
    return obs


def cape(R, kind="cape"):
    main = R["main"]
    obs = []
    W0, W1, H = 0.42, 0.95, 1.9
    nx, nz = 40, 50
    bm = bmesh.new()
    grid = []
    for j in range(nz + 1):
        t = j / nz
        z = 0.9 - H * t
        w = W0 + (W1 - W0) * t ** 0.8
        row = []
        for i in range(nx + 1):
            u = i / nx * 2 - 1
            x = u * w
            fold = (0.05 + 0.13 * t) * math.sin(u * math.pi * 3.5 + 0.6) * (0.4 + t)
            y = 0.35 * (1 - u * u) * (0.3 + 0.7 * (1 - t)) + fold
            row.append(bm.verts.new((x, y, z)))
        grid.append(row)
    for j in range(nz):
        for i in range(nx):
            bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
    me = bpy.data.meshes.new("Cape")
    bm.to_mesh(me)
    o = link(me, "Cape")
    s = o.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.025
    lining = R["second"] if kind != "mantle" else shade(main, 0.5)
    apply(o, mat_fabric(main, "CapeCloth", 0.9, 180, 0.7, velvet=True))
    obs.append(o)
    # hood-like collar roll
    col = taper_tube([(-0.45, 0.25, 0.88), (-0.25, -0.05, 0.98), (0.0, -0.12, 1.0), (0.25, -0.05, 0.98), (0.45, 0.25, 0.88)], [0.07, 0.1, 0.11, 0.1, 0.07], "Collar")
    apply(col, mat_fabric(shade(main, 0.85), "Collar", 0.9, 180, 0.7, True)); obs.append(col)
    clasp = R["gold"] or (0.95, 0.78, 0.32)
    for sx in (-1, 1):
        c = sphere(0.07, (sx * 0.3, -0.1, 0.9), "Clasp", 24); c.scale = (1, 0.6, 1)
        apply(c, mat_metal(clasp, 0.15)); obs.append(c)
    ch = taper_tube([(-0.3, -0.14, 0.88), (0, -0.2, 0.82), (0.3, -0.14, 0.88)], [0.012, 0.012, 0.012], "Chain")
    apply(ch, mat_metal(clasp, 0.15)); obs.append(ch)
    return obs


def muffler(R):
    main = R["main"]
    obs = []
    pts = [(0.55 * math.cos(a), 0.3 * math.sin(a), 0.35 + 0.06 * math.sin(2 * a)) for a in np.linspace(0, 2 * math.pi, 14)]
    ring = taper_tube(pts + [pts[1]], [0.17] * 15, "Loop")
    m = mat_fur(main)
    apply(ring, m); obs.append(ring)
    for sx, dz in ((0.18, 0.0), (0.32, 0.12)):
        tail = loft([(z, superellipse(0.15 - 0.01 * k, 0.04, 3, 16, sx + 0.08 * math.sin(k), -0.32)) for k, z in enumerate(np.linspace(-0.85 + dz, 0.25, 8))], "Tail")
        apply(tail, m); obs.append(tail)
        for k in range(6):
            fr = taper_tube([(sx - 0.12 + k * 0.05, -0.32, -0.85 + dz), (sx - 0.12 + k * 0.05, -0.32, -0.97 + dz)], [0.012, 0.006], "Fringe")
            apply(fr, m); obs.append(fr)
    return obs


def bandage_roll(R):
    main = R["main"]
    obs = []
    roll = lathe([(0.0, -0.45), (0.45, -0.45), (0.47, -0.4), (0.47, 0.4), (0.45, 0.45), (0.0, 0.45)], "Roll", 48)
    roll.rotation_euler = (0, math.radians(90), 0)
    m = mat_fabric(main, "Gauze", 0.4, 90, 0.9)
    apply(roll, m); obs.append(roll)
    for k in range(7):
        r = torus(0.475, 0.008, (-0.4 + k * 0.13, 0, 0), (0, math.radians(90), 0), "Wrap"); apply(r, m); obs.append(r)
    bm = bmesh.new()
    rows = []
    for j in range(25):
        t = j / 24
        z = -0.47 - t * 0.55
        y = -0.45 * math.cos(t * 2.2) - 0.1
        rows.append([bm.verts.new((x, y + 0.05 * math.sin(t * 8 + x * 4), z + 0.06 * math.sin(x * 5))) for x in np.linspace(-0.38, 0.38, 12)])
    for a, b in zip(rows[:-1], rows[1:]):
        for i in range(11):
            bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
    me = bpy.data.meshes.new("Strip"); bm.to_mesh(me)
    st = link(me, "Strip"); sm = st.modifiers.new("s", "SOLIDIFY"); sm.thickness = 0.01
    apply(st, m); obs.append(st)
    return obs


# ------------------------------------------------------------------ gloves
def glove(R, metal=False, fingerless=False):
    main = R["main"]
    m = mat_metal(main, 0.18) if metal else mat_leather(main)
    obs = []
    palm = rounded_box((0.62, 0.26, 0.6), (0, 0, 0.12), 0.11, "Palm")
    subsurf(palm, 2)
    apply(palm, m); obs.append(palm)
    fx = [-0.24, -0.08, 0.08, 0.24]
    fl = [0.38, 0.47, 0.44, 0.34]
    for x, L in zip(fx, fl):
        if fingerless:
            L *= 0.45
        pts = [(x * 1.0, 0.0, 0.38), (x * 1.04, -0.02, 0.38 + L * 0.5), (x * 1.08, -0.06, 0.38 + L)]
        f = taper_tube(pts, [0.078, 0.075, 0.068], "Finger")
        apply(f, m); obs.append(f)
        tip = sphere(0.068, pts[-1], "Tip", 20); apply(tip, m); obs.append(tip)
        if metal:
            for k in range(3):
                z = 0.42 + L * (0.15 + 0.3 * k)
                rr = torus(0.078, 0.016, (x * 1.04, -0.02, z), (0, 0, 0), "Joint"); apply(rr, m); obs.append(rr)
    th = taper_tube([(0.28, -0.02, 0.05), (0.42, -0.06, 0.2), (0.5, -0.1, 0.38)], [0.09, 0.085, 0.075], "Thumb")
    apply(th, m); obs.append(th)
    tt = sphere(0.075, (0.5, -0.1, 0.38), "ThumbTip", 20); apply(tt, m); obs.append(tt)
    cuff = lathe([(0.0, -0.75), (0.39, -0.75), (0.41, -0.7), (0.36, -0.35), (0.3, -0.12), (0.0, -0.12)], "Cuff", 40)
    cuff.scale = (1, 0.62, 1)
    apply(cuff, m); obs.append(cuff)
    trim = R["gold"] or (shade(main, 0.75) if not metal else (0.82, 0.68, 0.35))
    band = torus(0.385, 0.03, (0, 0, -0.68), (0, 0, 0), "CuffBand", (1, 0.63, 1))
    apply(band, mat_metal(trim, 0.2) if metal or R["gold"] else mat_leather(shade(main, 0.6))); obs.append(band)
    if metal:
        kp = rounded_box((0.64, 0.1, 0.12), (0, -0.14, 0.34), 0.04, "KnucklePlate")
        apply(kp, m); obs.append(kp)
        for x in fx:
            sp = sphere(0.035, (x, -0.2, 0.34), "Stud", 12); apply(sp, mat_metal(trim, 0.2)); obs.append(sp)
    else:
        st = taper_tube([(-0.28, -0.135, -0.05), (0, -0.14, -0.02), (0.28, -0.135, -0.05)], [0.01] * 3, "Stitch")
        apply(st, mat_leather(shade(main, 0.5))); obs.append(st)
        strap = rounded_box((0.68, 0.06, 0.1), (0, -0.12, -0.2), 0.02, "Strap")
        apply(strap, mat_leather(shade(main, 0.7))); obs.append(strap)
        bk = rounded_box((0.08, 0.03, 0.12), (0.22, -0.16, -0.2), 0.01, "Buckle"); apply(bk, mat_metal((0.8, 0.8, 0.82), 0.2)); obs.append(bk)
    return obs


def knuckles(R):
    main = R["main"]
    mcol = (0.75, 0.76, 0.78) if not R["gold"] else R["gold"]
    m = mat_metal(mcol, 0.18)
    obs = []
    for i in range(4):
        x = -0.45 + i * 0.3
        r = torus(0.13, 0.045, (x, 0, 0.15), (math.radians(90), 0, 0), "Ring"); apply(r, m); obs.append(r)
        sp = taper_tube([(x, 0, 0.32), (x, 0, 0.55)], [0.06, 0.005], "Spike")
        apply(sp, m); obs.append(sp)
    bar = rounded_box((1.24, 0.12, 0.12), (0, 0, 0.3), 0.05, "Bar"); apply(bar, m); obs.append(bar)
    grip = taper_tube([(-0.5, 0, -0.05), (-0.1, 0, -0.18), (0.4, 0, -0.1)], [0.08, 0.09, 0.08], "Grip")
    apply(grip, mat_leather(main if hsv(main)[1] > 0.2 else (0.4, 0.25, 0.15))); obs.append(grip)
    return obs


# ------------------------------------------------------------------ boots
def boot(R, metal=False, sandal=False, winged=False):
    main = R["main"]
    m = mat_metal(main, 0.18) if metal else mat_leather(main)
    obs = []
    sole_m = mat_pbr((0.12, 0.09, 0.07), 0.6, 0, 0, "Sole")
    sole = rounded_box((1.15, 0.5, 0.08), (0.12, 0, -0.62), 0.035, "Sole")
    apply(sole, sole_m); obs.append(sole)
    heel = rounded_box((0.32, 0.46, 0.14), (-0.27, 0, -0.69), 0.03, "Heel"); apply(heel, sole_m); obs.append(heel)
    if sandal:
        apply(sole, mat_leather(main))
        sm = mat_leather(shade(main, 0.75))
        for k, x in enumerate((0.5, 0.25, 0.0)):
            st = taper_tube([(x, -0.24, -0.58), (x + 0.03, -0.12, -0.4), (x + 0.04, 0.0, -0.36), (x + 0.03, 0.12, -0.4), (x, 0.24, -0.58)], [0.035, 0.035, 0.035, 0.035, 0.035], "Strap")
            apply(st, sm); obs.append(st)
        for z in (-0.3,):
            st = torus(0.15, 0.028, (-0.25, 0, z), (0, 0, 0), "Ankle", (1, 1.15, 1)); apply(st, sm); obs.append(st)
        hs = taper_tube([(-0.38, 0, -0.58), (-0.4, 0, -0.3), (-0.39, 0, -0.3)], [0.035] * 3, "HeelStrap"); apply(hs, sm); obs.append(hs)
        bk = rounded_box((0.06, 0.03, 0.06), (-0.12, -0.15, -0.3), 0.01, "Buckle"); apply(bk, mat_metal((0.85, 0.72, 0.4), 0.2)); obs.append(bk)
        return obs
    shaft = lathe([(0.0, -0.55), (0.24, -0.55), (0.23, -0.2), (0.21, 0.2), (0.25, 0.55), (0.27, 0.62), (0.0, 0.62)], "Shaft", 40)
    shaft.location = (-0.2, 0, 0)
    shaft.scale = (1.05, 0.9, 1)
    apply(shaft, m); obs.append(shaft)
    foot = sphere(1.0, (0.12, 0, -0.47), "Foot", 48)
    for v in foot.data.vertices:
        x, y, z = v.co
        xn = (x + 1) / 2
        v.co = (x * 0.56, y * 0.235 * (1 + 0.15 * xn), z * 0.2 * (1.25 - 0.55 * xn) + (0.06 * (1 - xn) if z > 0 else 0))
    subsurf(foot, 1)
    apply(foot, m); obs.append(foot)
    if metal:
        knee = sphere(0.2, (-0.18, -0.12, 0.55), "Knee", 32); knee.scale = (1, 0.7, 0.9); apply(knee, m); obs.append(knee)
        for z in (0.0, -0.3):
            b = torus(0.235, 0.025, (-0.2, 0, z), (0, 0, 0), "Band", (1.05, 0.9, 1)); apply(b, mat_metal(R["gold"] or shade(main, 0.8), 0.2)); obs.append(b)
        for k in range(3):
            p = sphere(1.0, (0.12 + 0.13 * k, 0, -0.47 + 0.005), "Lame", 32)
            for v in p.data.vertices:
                x, y, z = v.co
                v.co = (x * 0.2, y * 0.25, max(z, -0.1) * 0.19)
            apply(p, m); obs.append(p)
    else:
        cuffc = shade(main, 0.75)
        cf = torus(0.27, 0.06, (-0.2, 0, 0.6), (0, 0, 0), "Fold", (1.02, 0.9, 1)); apply(cf, mat_leather(cuffc)); obs.append(cf)
        for k in range(4):
            z = 0.1 - 0.17 * k
            lc = taper_tube([(0.0, -0.1, z), (0.05, 0.0, z - 0.03), (0.0, 0.1, z)], [0.014] * 3, "Lace")
            apply(lc, mat_pbr((0.15, 0.1, 0.07), 0.6)); obs.append(lc)
        st = taper_tube([(-0.45, -0.05, -0.5), (0.1, -0.2, -0.48), (0.7, -0.05, -0.5)], [0.008] * 3, "Welt")
        apply(st, mat_leather(shade(main, 0.55))); obs.append(st)
    if winged:
        for k in range(5):
            obs += feather(0.42 - 0.05 * k, 0.07, (0.97, 0.97, 1.0), (-0.42, 0.0, 0.4 - 0.08 * k), (math.radians(-90 + 0), math.radians(-60 - 14 * k), 0))
    return obs


# ------------------------------------------------------------------ head wear
def helm(R, horns=False, visor_eyes=None):
    main = R["main"]
    m = mat_metal(main, 0.18) if R["metal"] or not visor_eyes is None or hsv(main)[1] < 0.5 else mat_pbr(main, 0.25, 0.7, 0.6, "Lacquer")
    if hsv(main)[1] > 0.35:
        m = mat_pbr(main, 0.22, 0.65, 1.0, "Lacquer")
    obs = []
    d = dome(0.62, (0, 0, 0), 1.05, name="Skull", thick=0.04)
    subsurf(d, 1); apply(d, m); obs.append(d)
    rim = torus(0.62, 0.04, (0, 0, 0.0), name="Rim"); apply(rim, m); obs.append(rim)
    crest = taper_tube([(0, 0.62, 0.05), (0, 0.4, 0.55), (0, 0.0, 0.7), (0, -0.4, 0.55), (0, -0.64, 0.05)], [0.03, 0.04, 0.045, 0.04, 0.03], "Crest")
    trim = R["gold"] or shade(main, 0.8)
    apply(crest, mat_metal(trim, 0.18)); obs.append(crest)
    for sx in (-1, 1):
        ch = loft([(z, superellipse(0.05, 0.16, 3, 16, sx * 0.58, 0.05)) for z in np.linspace(-0.55, 0.02, 6)], "Cheek")
        apply(ch, m); obs.append(ch)
        for k in range(3):
            rv = sphere(0.025, (sx * 0.62 * math.cos(math.radians(60 + 25 * k)), -0.62 * math.sin(math.radians(60 + 25 * k)) * 0.99, 0.05), "Rivet", 10)
            apply(rv, mat_metal(trim, 0.2)); obs.append(rv)
    nose = loft([(z, superellipse(0.045, 0.025, 2, 12, 0, -0.64)) for z in np.linspace(-0.42, 0.05, 5)], "Nasal")
    apply(nose, m); obs.append(nose)
    if visor_eyes:
        for sx in (-1, 1):
            e = sphere(0.07, (sx * 0.2, -0.6, -0.1), "Eye", 16); e.scale = (1.3, 0.4, 0.6)
            apply(e, mat_pbr(visor_eyes, 0.3, 0, 0, "Glow", emit=12)); obs.append(e)
        face = dome(0.6, (0, 0, -0.02), 1.0, name="Face", thick=0.03)
        face.rotation_euler = (math.radians(180), 0, 0)
        face.scale = (1, 1, 0.9)
        apply(face, m); obs.append(face)
    if horns:
        hc = (0.93, 0.89, 0.78) if not visor_eyes else (0.2, 0.18, 0.22)
        for sx in (-1, 1):
            h = taper_tube([(sx * 0.5, 0, 0.35), (sx * 0.85, -0.05, 0.55), (sx * 0.98, -0.1, 0.95), (sx * 0.85, -0.12, 1.2)], [0.13, 0.1, 0.06, 0.008], "Horn")
            hm = mat_pbr(hc, 0.35, 0, 0.6, "Horn")
            apply(h, hm); obs.append(h)
            for k in range(3):
                r = torus(0.12 - 0.02 * k, 0.012, (sx * (0.6 + 0.1 * k), -0.03, 0.42 + 0.1 * k), (0, sx * math.radians(50), 0), "HornRing"); apply(r, hm); obs.append(r)
    return obs


def cap(R, kind):
    """captain | sailor | leather | hardhat | beret | chef"""
    main = R["main"]
    obs = []
    if kind == "beret":
        b = sphere(0.62, (0, 0, 0.12), "Beret", 48); b.scale = (1, 1, 0.32)
        b.rotation_euler = (0, math.radians(-12), 0)
        apply(b, mat_fabric(main, "Felt", 0.8, 260, 0.85, True)); obs.append(b)
        band = torus(0.47, 0.04, (0, 0, 0.02), name="Band"); apply(band, mat_fabric(shade(main, 0.7), "Band", 0.6)); obs.append(band)
        st = taper_tube([(0.1, 0, 0.3), (0.1, 0, 0.42)], [0.035, 0.02], "Stalk"); apply(st, mat_fabric(main, "Felt2", 0.8)); obs.append(st)
        return obs
    if kind == "chef":
        band = lathe([(0.0, 0.0), (0.42, 0.0), (0.43, 0.3), (0.0, 0.3)], "Band", 48)
        mw = mat_fabric((0.97, 0.97, 0.96), "Cotton", 0.5, 140, 0.8)
        apply(band, mw); obs.append(band)
        for k in range(7):
            a = 2 * math.pi * k / 7
            p = sphere(0.28, (0.27 * math.cos(a), 0.27 * math.sin(a), 0.48), "Puff", 32); apply(p, mw); obs.append(p)
        top = sphere(0.38, (0, 0, 0.58), "PuffTop", 32); top.scale = (1, 1, 0.7); apply(top, mw); obs.append(top)
        for o in obs:
            wrinkle(o, 0.02, 0.15)
        return obs
    if kind == "hardhat":
        m = mat_plastic((1.0, 0.76, 0.18), rough=0.22)
        d = dome(0.6, (0, 0, 0), 0.85, name="Shell", thick=0.04); apply(d, m); obs.append(d)
        ridge = taper_tube([(0, 0.55, 0.15), (0, 0, 0.56), (0, -0.55, 0.15)], [0.06, 0.07, 0.06], "Ridge"); apply(ridge, m); obs.append(ridge)
        brim = disk(0.58, 0.78, (0, 0, 0.0), "Brim", 0.04, thick=0.03); apply(brim, m); obs.append(brim)
        return obs
    if kind == "leather":
        m = mat_leather(main)
        d = dome(0.6, (0, 0, 0), 0.75, name="Crown", thick=0.03); apply(d, m); obs.append(d)
        for k in range(6):
            a = math.pi * k / 6
            sm = taper_tube([(0.6 * math.cos(a), 0.6 * math.sin(a), 0.0), (0.42 * math.cos(a), 0.42 * math.sin(a), 0.32), (0, 0, 0.45)], [0.008] * 3, "Seam")
            apply(sm, mat_leather(shade(main, 0.6))); obs.append(sm)
            sm2 = taper_tube([(-0.6 * math.cos(a), -0.6 * math.sin(a), 0.0), (-0.42 * math.cos(a), -0.42 * math.sin(a), 0.32), (0, 0, 0.45)], [0.008] * 3, "Seam")
            apply(sm2, mat_leather(shade(main, 0.6))); obs.append(sm2)
        brim = disk(0.58, 0.72, (0, 0, 0.0), "Brim", 0.03, thick=0.03); apply(brim, m); obs.append(brim)
        btn = sphere(0.05, (0, 0, 0.45), "Button", 16); apply(btn, m); obs.append(btn)
        return obs
    # peaked caps
    white = main
    crown_c = white
    body = lathe([(0.0, 0.0), (0.5, 0.0), (0.52, 0.18), (0.66, 0.32), (0.66, 0.36), (0.0, 0.38)], "CapCrown", 64)
    apply(body, mat_fabric(crown_c, "CapCloth", 0.5, 200, 0.6)); obs.append(body)
    bandc = (0.08, 0.08, 0.1)
    band = lathe([(0.505, 0.0), (0.515, 0.17), (0.0, 0.17)], "CapBand", 64)
    band = loft([(z, superellipse(0.51 + z * 0.08, 0.51 + z * 0.08, 2, 64)) for z in (0.0, 0.17)], "CapBand", cap=False)
    s = band.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.015
    apply(band, mat_pbr(bandc if kind == "captain" else shade(R["second"], 1.0), 0.3, 0, 0.5, "Band")); obs.append(band)
    vis = []
    for i in range(17):
        a = math.pi + math.pi * i / 16
        vis.append((0.52 * math.cos(a), 0.52 * math.sin(a)))
    outline = vis + [(0.5 * math.cos(math.pi * 2 - math.pi * i / 16) * 1.0, -0.25 + 0.0 * i) for i in range(0)]
    pts = [(0.52 * math.cos(a), 0.52 * math.sin(a)) for a in np.linspace(math.pi * 1.05, math.pi * 1.95, 14)]
    pts += [(0.62 * math.cos(a), 0.62 * math.sin(a) - 0.18) for a in np.linspace(math.pi * 1.95, math.pi * 1.05, 14)]
    v = extrude_shape(pts, 0.02, 0.008, "Visor")
    v.rotation_euler = (0, 0, 0)
    for vv in v.data.vertices:
        vv.co.z += -0.05 - 0.25 * max(0, -vv.co.y - 0.45)
    apply(v, mat_pbr((0.05, 0.05, 0.06), 0.15, 0, 1.0, "Patent")); obs.append(v)
    if kind == "captain":
        gold = R["gold"] or (0.95, 0.78, 0.3)
        cord = taper_tube([(-0.45, -0.27, 0.12), (0, -0.53, 0.1), (0.45, -0.27, 0.12)], [0.018] * 3, "Cord"); apply(cord, mat_metal(gold, 0.2)); obs.append(cord)
        em = sphere(0.09, (0, -0.52, 0.27), "Emblem", 24); em.scale = (1, 0.3, 0.8); apply(em, mat_metal(gold, 0.15)); obs.append(em)
        for sx in (-1, 1):
            leaf = sphere(0.06, (sx * 0.13, -0.5, 0.25), "Laurel", 16); leaf.scale = (1.3, 0.3, 0.6); apply(leaf, mat_metal(gold, 0.15)); obs.append(leaf)
    else:
        acc = R["accent"] or (0.1, 0.2, 0.6)
        for sx in (-1, 1):
            rb = loft([(z, superellipse(0.05, 0.01, 2, 8, 0.3 * sx + 0.05 * z * sx, 0.5 + 0.0)) for z in np.linspace(-0.45, 0.1, 6)], "Ribbon")
            apply(rb, mat_fabric(acc, "Ribbon", 0.6)); obs.append(rb)
    return obs


def brimmed(R, kind):
    """top | fedora | boater | rice | wizard"""
    main = R["main"]
    obs = []
    if kind == "rice":
        m = mat_straw(main)
        cone = lathe([(0.0, 0.62), (0.08, 0.57), (0.9, 0.0), (0.0, 0.0)], "Cone", 64)
        s = cone.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.02
        apply(cone, m); obs.append(cone)
        rim = torus(0.95, 0.018, name="Rim"); apply(rim, mat_straw(shade(main, 0.8))); obs.append(rim)
        knob = sphere(0.05, (0, 0, 0.62), "Knob", 16); apply(knob, m); obs.append(knob)
        return obs
    if kind == "wizard":
        m = mat_fabric(main, "Felt", 0.9, 220, 0.8, True)
        brim = disk(0.28, 0.95, (0, 0, 0), "Brim", 0.1, thick=0.03); wrinkle(brim, 0.04, 0.3); apply(brim, m); obs.append(brim)
        cone = taper_tube([(0, 0, 0.0), (0, 0, 0.45), (0.05, 0.05, 0.85), (0.3, 0.15, 1.15), (0.55, 0.2, 1.12)], [0.42, 0.3, 0.17, 0.07, 0.01], "Cone")
        wrinkle(cone, 0.03, 0.2)
        apply(cone, m); obs.append(cone)
        bc = R["gold"] or R["accent"] or (0.95, 0.78, 0.3)
        band = torus(0.39, 0.05, (0, 0, 0.1), name="Band", scale=(1, 1, 1.4)); apply(band, mat_fabric(shade(main, 0.6), "Band", 0.7)); obs.append(band)
        star = extrude_shape([((0.11 if k % 2 == 0 else 0.045) * math.sin(math.pi * k / 5), (0.11 if k % 2 == 0 else 0.045) * math.cos(math.pi * k / 5)) for k in range(10)], 0.03, 0.01, "Star")
        star.location = (0, -0.38, 0.38)
        apply(star, mat_metal(bc, 0.15)); obs.append(star)
        return obs
    if kind == "top":
        m = mat_fabric(main, "Silk", 1.0, 400, 0.35, True)
        crown = lathe([(0.0, 0.0), (0.4, 0.0), (0.38, 0.4), (0.42, 0.78), (0.0, 0.78)], "Crown", 64)
        apply(crown, m); obs.append(crown)
        brim = disk(0.38, 0.72, (0, 0, 0.0), "Brim", -0.06, thick=0.03)
        for v in brim.data.vertices:
            r = math.hypot(v.co.x, v.co.y)
            v.co.z += 0.12 * (abs(v.co.x) / max(r, 1e-3)) ** 2 * max(0, r - 0.45) / 0.27
        apply(brim, m); obs.append(brim)
        band = loft([(z, superellipse(0.395, 0.395, 2, 64)) for z in (0.03, 0.17)], "Ribbon", cap=False)
        apply(band, mat_fabric(R["accent"] or (0.6, 0.05, 0.08), "Ribbon", 0.9, 400, 0.4)); obs.append(band)
        return obs
    if kind == "fedora":
        main = (0.5, 0.33, 0.2)
        m = mat_leather(main)
        crown = lathe([(0.0, 0.42), (0.18, 0.38), (0.36, 0.42), (0.42, 0.25), (0.44, 0.0), (0.0, 0.0)], "Crown", 64)
        for v in crown.data.vertices:
            if v.co.z > 0.3:
                v.co.z -= 0.1 * max(0, 1 - abs(v.co.x) / 0.35) * (1 if v.co.y > -0.1 else 0.5)
        apply(crown, m); obs.append(crown)
        brim = disk(0.43, 0.82, (0, 0, 0.0), "Brim", 0.0, thick=0.03)
        for v in brim.data.vertices:
            r = math.hypot(v.co.x, v.co.y)
            v.co.z += 0.12 * (abs(v.co.x) / max(r, 1e-3)) ** 2 * max(0, r - 0.5) / 0.32 - 0.08 * max(0, -v.co.y / max(r, 1e-3)) * max(0, r - 0.5) / 0.32
        apply(brim, m); obs.append(brim)
        band = loft([(z, superellipse(0.442, 0.442, 2, 64)) for z in (0.02, 0.12)], "Band", cap=False)
        apply(band, mat_fabric(shade(main, 0.4), "Band", 0.7)); obs.append(band)
        return obs
    # boater
    m = mat_straw(main)
    crown = lathe([(0.0, 0.3), (0.44, 0.3), (0.45, 0.0), (0.0, 0.0)], "Crown", 64); apply(crown, m); obs.append(crown)
    brim = disk(0.44, 0.85, (0, 0, 0.0), "Brim", 0.0, thick=0.03); apply(brim, m); obs.append(brim)
    band = loft([(z, superellipse(0.455, 0.455, 2, 64)) for z in (0.03, 0.14)], "Ribbon", cap=False)
    apply(band, mat_fabric(R["accent"] or (0.75, 0.08, 0.1), "Ribbon", 0.8, 300, 0.45)); obs.append(band)
    bow = sphere(0.07, (0.33, -0.33, 0.09), "Bow", 16); bow.scale = (1.5, 0.5, 1); apply(bow, mat_fabric(R["accent"] or (0.75, 0.08, 0.1), "Ribbon2")); obs.append(bow)
    return obs


def bandana(R, tails=True):
    main = R["main"]
    m = mat_fabric(main, "Cotton", 0.5, 200, 0.75)
    obs = []
    band = loft([(z, superellipse(0.52, 0.48, 2, 64)) for z in (-0.12, 0.0, 0.12)], "Band", cap=False)
    for v in band.data.vertices:
        v.co.x *= 1 + 0.03 * math.sin(v.co.z * 30)
    s = band.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.04
    wrinkle(band, 0.02, 0.1)
    apply(band, m); obs.append(band)
    if R["accent"] or True:
        for k in range(10):
            a = 2 * math.pi * k / 10
            if math.sin(a) > -0.2:
                continue
            dot = sphere(0.025, (0.535 * math.cos(a), 0.495 * math.sin(a), 0.0), "Dot", 10); dot.scale = (1, 0.3, 1)
            apply(dot, mat_fabric((0.96, 0.96, 0.95), "Print", 0.3)); obs.append(dot)
    knot = sphere(0.1, (0.0, 0.5, 0.0), "Knot", 24); apply(knot, m); obs.append(knot)
    if tails:
        for sx in (-1, 1):
            t = loft([(z, superellipse(0.07 - 0.1 * abs(z) * 0.3, 0.015, 2, 12, sx * (0.06 + 0.25 * -z), 0.56 - 0.05 * z)) for z in np.linspace(-0.45, 0.0, 6)], "Tail")
            wrinkle(t, 0.02, 0.1)
            apply(t, m); obs.append(t)
    return obs


def headphones(R):
    main = R["main"]
    metal = R["metal"]
    m = mat_metal(main, 0.2) if metal else mat_plastic(main, 0.3)
    obs = []
    arc = taper_tube([(-0.55, 0, -0.1), (-0.5, 0, 0.35), (0, 0, 0.62), (0.5, 0, 0.35), (0.55, 0, -0.1)], [0.05] * 5, "Arc")
    apply(arc, m); obs.append(arc)
    pad = taper_tube([(-0.35, 0, 0.5), (0, 0, 0.6), (0.35, 0, 0.5)], [0.06, 0.07, 0.06], "Pad"); apply(pad, mat_leather((0.1, 0.1, 0.11))); obs.append(pad)
    acc = R["accent"] or (0.85, 0.15, 0.15)
    for sx in (-1, 1):
        cup = lathe([(0.0, -0.08), (0.24, -0.08), (0.26, 0.0), (0.24, 0.08), (0.0, 0.08)], "Cup", 48)
        cup.rotation_euler = (0, math.radians(90), 0); cup.location = (sx * 0.58, 0, -0.18)
        apply(cup, m); obs.append(cup)
        cush = torus(0.19, 0.06, (sx * 0.5, 0, -0.18), (0, math.radians(90), 0), "Cushion"); apply(cush, mat_leather((0.08, 0.08, 0.09))); obs.append(cush)
        ring = torus(0.2, 0.018, (sx * 0.665, 0, -0.18), (0, math.radians(90), 0), "Accent"); apply(ring, mat_pbr(acc, 0.2, 0.4, 1.0, "Acc", emit=1.5)); obs.append(ring)
    return obs


def bunny(R):
    main = R["main"]
    obs = []
    band = taper_tube([(-0.5, 0, -0.1), (-0.45, 0, 0.3), (0, 0, 0.5), (0.45, 0, 0.3), (0.5, 0, -0.1)], [0.04] * 5, "Band")
    apply(band, mat_plastic((0.12, 0.12, 0.14), 0.3)); obs.append(band)
    for sx in (-1, 1):
        e = loft([(z, superellipse(0.13 * math.sin(math.pi * (0.1 + 0.9 * z / 0.75)) + 0.02, 0.045, 2.2, 24)) for z in np.linspace(0, 0.75, 12)], "Ear")
        e.location = (sx * 0.2, 0, 0.45); e.rotation_euler = (math.radians(-8), sx * math.radians(12), 0)
        apply(e, mat_fur((0.97, 0.96, 0.96))); obs.append(e)
        inner = loft([(z, superellipse(0.08 * math.sin(math.pi * (0.1 + 0.9 * z / 0.6)) + 0.01, 0.01, 2.2, 24, 0, -0.04)) for z in np.linspace(0.06, 0.66, 10)], "Inner")
        inner.location = (sx * 0.2, 0, 0.45); inner.rotation_euler = e.rotation_euler
        apply(inner, mat_fabric((1.0, 0.68, 0.75), "Pink", 1.0, 300, 0.7, True)); obs.append(inner)
    return obs


def robot_visor(R):
    main = R["main"]
    obs = []
    band = loft([(z, superellipse(0.55, 0.5, 2.2, 64)) for z in (-0.18, 0.18)], "Band", cap=False)
    s = band.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.05
    apply(band, mat_metal((0.7, 0.72, 0.75), 0.2)); obs.append(band)
    vis = loft([(z, [(0.58 * math.cos(a), 0.53 * math.sin(a)) for a in np.linspace(math.pi * 1.15, math.pi * 1.85, 24)]) for z in (-0.13, 0.13)], "Visor", cap=False)
    s2 = vis.modifiers.new("s", "SOLIDIFY"); s2.thickness = 0.03
    vc = R["accent"] or (0.2, 0.9, 1.0)
    m = mat_pbr((0.05, 0.08, 0.1), 0.05, 0, 1.0, "VisorGlass")
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Emission Color"].default_value = (*lin(vc), 1); b.inputs["Emission Strength"].default_value = 0.6
    apply(vis, m); obs.append(vis)
    for k in range(4):
        x = -0.3 + 0.2 * k
        led = rounded_box((0.07, 0.02, 0.06), (x * 1.0, -0.6, 0.0), 0.01, "Led"); apply(led, mat_pbr((1.0, 0.8, 0.2), 0.3, 0, 0, "LED", emit=10)); obs.append(led)
    ant = taper_tube([(0.45, 0, 0.15), (0.48, 0, 0.6)], [0.015, 0.012], "Antenna"); apply(ant, mat_metal((0.6, 0.6, 0.62), 0.2)); obs.append(ant)
    tip = sphere(0.05, (0.48, 0, 0.62), "AntTip", 16); apply(tip, mat_pbr((1.0, 0.15, 0.1), 0.2, 0, 0.5, "Red", emit=6)); obs.append(tip)
    for sx in (-1, 1):
        ear = lathe([(0.0, -0.05), (0.15, -0.05), (0.15, 0.05), (0.0, 0.05)], "Ear", 32)
        ear.rotation_euler = (0, math.radians(90), 0); ear.location = (sx * 0.56, 0.0, 0.0); apply(ear, mat_metal((0.55, 0.57, 0.6), 0.25)); obs.append(ear)
    return obs


def ushanka(R):
    main = R["main"]
    fur = mat_fur((0.93, 0.9, 0.85) if hsv(main)[2] > 0.6 else shade(main, 1.2))
    cloth = mat_fabric(main, "Wool", 0.6, 160, 0.8)
    obs = []
    d = dome(0.58, (0, 0, 0.05), 0.85, name="Crown", thick=0.03); apply(d, cloth); obs.append(d)
    front = taper_tube([(-0.55, -0.1, 0.12), (0, -0.62, 0.22), (0.55, -0.1, 0.12)], [0.13, 0.17, 0.13], "FrontFlap"); apply(front, fur); obs.append(front)
    back = taper_tube([(-0.55, 0.1, 0.08), (0, 0.6, 0.1), (0.55, 0.1, 0.08)], [0.12, 0.13, 0.12], "BackFlap"); apply(back, fur); obs.append(back)
    for sx in (-1, 1):
        f = loft([(z, superellipse(0.06, 0.24 - 0.08 * abs(z + 0.15), 2.4, 24, sx * 0.6, 0)) for z in np.linspace(-0.45, 0.12, 6)], "EarFlap")
        apply(f, fur); obs.append(f)
    return obs


def hood_cap(R):
    """Robin-hood style cap with feather"""
    main = R["main"]
    m = mat_fabric(main, "Felt", 0.8, 220, 0.8, True)
    obs = []
    d = sphere(0.6, (0, 0, 0), "Cap", 48)
    for v in d.data.vertices:
        if v.co.z < 0:
            v.co.z *= 0.1
        v.co.y *= 1.25
        v.co.z *= 0.8
        v.co.z += 0.18 * max(0, v.co.y) ** 2
        v.co.y += 0.22 * max(0, v.co.z) * (v.co.y > 0)
    wrinkle(d, 0.02, 0.2)
    apply(d, m); obs.append(d)
    brim = taper_tube([(-0.62, -0.05, 0.02), (-0.4, -0.6, 0.06), (0.0, -0.78, 0.12), (0.4, -0.6, 0.06), (0.62, -0.05, 0.02)], [0.05, 0.06, 0.07, 0.06, 0.05], "Fold")
    apply(brim, mat_fabric(shade(main, 0.8), "Fold", 0.8, 220, 0.8, True)); obs.append(brim)
    obs += feather(0.95, 0.09, (0.95, 0.92, 0.82), (0.35, 0.05, 0.25), (math.radians(-20), math.radians(55), 0))
    return obs


def wings(R, glow=False):
    main = R["main"]
    obs = []
    for sx in (-1, 1):
        rows = [(10, 1.0, 0.12, shade(main, 0.7), 0.0), (9, 0.6, 0.12, main, -0.03), (7, 0.34, 0.11, shade(main, 1.25), -0.06)]
        for n, L, w, col, dy in rows:
            for k in range(n):
                t = k / (n - 1)
                theta = math.radians(165 - 125 * t)
                base = (sx * (0.1 + 0.8 * t), dy, 0.25 + 0.5 * math.sin(math.pi * 0.5 * t) - 0.15 * t * t)
                ln = L * (0.65 + 0.45 * t) if L > 0.9 else L * (0.8 + 0.3 * t)
                fs = feather(ln, w * (1 + 0.3 * t), col, base, (0, sx * theta, 0))
                for f in fs:
                    if glow and f.name.startswith("Feather"):
                        b = f.data.materials[0].node_tree.nodes["Principled BSDF"]
                        b.inputs["Emission Color"].default_value = (*lin(col), 1)
                        b.inputs["Emission Strength"].default_value = 1.2
                obs += fs
        arm = taper_tube([(sx * 0.05, -0.08, 0.22), (sx * 0.45, -0.09, 0.62), (sx * 0.92, -0.09, 0.62)], [0.06, 0.045, 0.02], "Arm")
        apply(arm, mat_fabric(shade(main, 1.1), "Arm", 0.8)); obs.append(arm)
    return obs


# ------------------------------------------------------------------ dispatcher
BODY = {"knight_plate": "plate", "mithril_plate": "plate", "obsidian_plate": "plate", "arcane_armor": "plate",
        "leather_vest": "vest", "mage_robe": "robe", "priest_vestment": "robe", "desert_robe": "robe",
        "traveler_clothes": "tunic", "shadow_garb": "tunic", "yeti_coat": "coat", "wool_cloak": "tunic"}
CAPES = {"moss_cloak": "cape", "shadow_mantle": "mantle", "travel_cape": "cape"}


def build_wear(item_id, src):
    R = roles(src)
    if item_id in BODY:
        obs = torso(BODY[item_id], R); return group(obs, (5, 0, -20))
    if item_id in CAPES:
        obs = cape(R, CAPES[item_id]); return group(obs, (5, 0, -25))
    if item_id == "wool_muffler":
        return group(muffler(R), (15, 0, -15))
    if item_id == "mummy_wrap":
        return group(bandage_roll(R), (10, 0, -25))
    if item_id in ("iron_gauntlets", "frost_gauntlets"):
        return group(glove(R, metal=True), (8, 0, -20))
    if item_id in ("leather_gloves", "thief_gloves"):
        return group(glove(R, fingerless=item_id == "thief_gloves"), (8, 0, -20))
    if item_id.endswith("_knuckles"):
        return group(knuckles(R), (15, 30, -15))
    if item_id in ("leather_boots", "sand_boots", "wind_boots", "iron_greaves", "sandals"):
        obs = boot(R, metal=item_id == "iron_greaves", sandal=item_id == "sandals", winged=item_id == "wind_boots")
        return group(obs, (12, 0, -28))
    if item_id.startswith("wings_"):
        return group(wings(R, glow=item_id in ("wings_fire", "wings_lightning", "wings_frozen")), (10, 0, 0))
    head = None
    if item_id in ("iron_helm",):
        head = helm(R)
    elif item_id in ("drake_helm", "hat_horned_helm"):
        head = helm(R, horns=True)
    elif item_id == "hat_dragon_mask":
        head = helm(R, horns=True, visor_eyes=(0.75, 0.3, 1.0))
    elif "bandana" in item_id or "headband" in item_id:
        head = bandana(R, tails=True)
    elif "headphones" in item_id:
        head = headphones(R)
    elif item_id == "hat_bunny_ears":
        head = bunny(R)
    elif item_id == "hat_robot_visor":
        head = robot_visor(R)
    elif item_id == "hat_winter_ushanka":
        head = ushanka(R)
    elif item_id in ("ranger_hood", "feather_bonnet"):
        head = hood_cap(R)
    elif item_id == "hat_captain_cap":
        head = cap(R, "captain")
    elif item_id == "hat_sailor_cap":
        head = cap(R, "sailor")
    elif item_id == "leather_cap":
        head = cap(R, "leather")
    elif item_id == "hat_gold_hardhat":
        head = cap(R, "hardhat")
    elif item_id == "hat_red_beret":
        head = cap(R, "beret")
    elif item_id == "hat_chef_hat":
        head = cap(R, "chef")
    elif item_id == "hat_black_top_hat":
        head = brimmed(R, "top")
    elif item_id == "hat_leather_fedora":
        head = brimmed(R, "fedora")
    elif item_id == "hat_straw_boater":
        head = brimmed(R, "boater")
    elif item_id == "hat_rice_straw_hat":
        head = brimmed(R, "rice")
    elif item_id in ("wizard_hat", "hat_indigo_wizard_hat"):
        head = brimmed(R, "wizard")
    if head is not None:
        return group(head, (24, 0, -22))
    return None
