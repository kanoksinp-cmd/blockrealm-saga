"""Procedural realistic models for weapons/shields/jewellery, coloured from the
original pixel icon's palette."""
import math
import numpy as np
from PIL import Image
import colorsys
import bpy
import bmesh
from mathutils import Vector, Matrix


def lin(c):
    return tuple(max(0.0, x) ** 2.2 for x in c)


# ------------------------------------------------------------------ palette
def palette(path):
    a = np.array(Image.open(path).convert("RGBA")).reshape(-1, 4)
    a = a[a[:, 3] > 128][:, :3].astype(float) / 255
    lum = a @ np.array([0.3, 0.59, 0.11])
    a = a[lum > 0.12]                       # drop outline
    if len(a) == 0:
        a = np.array([[0.7, 0.7, 0.7]])
    hsv = np.array([colorsys.rgb_to_hsv(*c) for c in a])
    sat, val = hsv[:, 1], hsv[:, 2]
    hue = hsv[:, 0] * 360

    def pick(mask, default):
        if mask.sum() < 3:
            return default
        sel = a[mask]
        return tuple(np.median(sel, 0))

    metal_m = (sat < 0.25) & (val > 0.45)
    gold_m = (hue > 35) & (hue < 60) & (sat > 0.45) & (val > 0.55)
    wood_m = (hue > 8) & (hue < 40) & (sat > 0.3) & (val < 0.62) & (val > 0.2)
    acc_m = (sat > 0.45) & (val > 0.4) & ~gold_m & ~wood_m
    pal = {
        "metal": pick(metal_m, (0.78, 0.8, 0.83)),
        "gold": pick(gold_m, (1.0, 0.78, 0.3)),
        "wood": pick(wood_m, (0.45, 0.28, 0.16)),
        "accent": pick(acc_m, (0.85, 0.2, 0.2)),
        "has_gold": gold_m.mean() > 0.06,
        "has_accent": acc_m.mean() > 0.05,
        "metal_frac": metal_m.mean(),
    }
    # accent: most common saturated hue
    if acc_m.sum() > 3:
        hh = hue[acc_m]
        hist, edges = np.histogram(hh, bins=12, range=(0, 360))
        k = hist.argmax()
        sel = acc_m & (hue >= edges[k]) & (hue < edges[k + 1])
        pal["accent"] = tuple(np.median(a[sel], 0) if sel.sum() else pal["accent"])
    return pal


# ------------------------------------------------------------------ materials
def mat_metal(col, rough=0.18, name="Metal", aniso=True):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    c = tuple(min(1, x * 1.05) for x in col)
    b.inputs["Base Color"].default_value = (*lin(c), 1)
    b.inputs["Metallic"].default_value = 1.0
    b.inputs["Roughness"].default_value = rough
    if aniso:
        try:
            b.inputs["Anisotropic"].default_value = 0.5
        except Exception:
            pass
    # fine scratches
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (1, 1, 40)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    n = nt.nodes.new("ShaderNodeTexNoise"); n.inputs["Scale"].default_value = 25; n.inputs["Detail"].default_value = 6
    nt.links.new(mp.outputs["Vector"], n.inputs["Vector"])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["To Min"].default_value = rough * 0.6
    mr.inputs["To Max"].default_value = rough * 1.6
    nt.links.new(n.outputs["Fac"], mr.inputs["Value"])
    nt.links.new(mr.outputs["Result"], b.inputs["Roughness"])
    return m


def mat_pbr(col, rough=0.5, metal=0.0, coat=0.0, name="M", emit=0.0, sss=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*lin(col), 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Coat Weight"].default_value = coat
    if emit:
        b.inputs["Emission Color"].default_value = (*lin(col), 1)
        b.inputs["Emission Strength"].default_value = emit
    if sss:
        b.inputs["Subsurface Weight"].default_value = sss
    return m


def mat_wood(col, name="Wood"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (12, 12, 0.8)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    w = nt.nodes.new("ShaderNodeTexWave"); w.wave_type = "RINGS"; w.inputs["Scale"].default_value = 2.0
    w.inputs["Distortion"].default_value = 6; w.inputs["Detail"].default_value = 4
    nt.links.new(mp.outputs["Vector"], w.inputs["Vector"])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    mix.inputs["A"].default_value = (*lin(col), 1)
    mix.inputs["B"].default_value = (*lin(tuple(x * 0.55 for x in col)), 1)
    nt.links.new(w.outputs["Fac"], mix.inputs["Factor"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.45
    b.inputs["Coat Weight"].default_value = 0.4
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.15
    nt.links.new(w.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def mat_leather(col, name="Leather"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*lin(col), 1)
    b.inputs["Roughness"].default_value = 0.55
    b.inputs["Sheen Weight"].default_value = 0.3
    tc = nt.nodes.new("ShaderNodeTexCoord")
    v = nt.nodes.new("ShaderNodeTexVoronoi"); v.inputs["Scale"].default_value = 90
    nt.links.new(tc.outputs["Object"], v.inputs["Vector"])
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.25
    nt.links.new(v.outputs["Distance"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def mat_gem(col, name="Gem"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*lin(col), 1)
    b.inputs["Transmission Weight"].default_value = 1.0
    b.inputs["IOR"].default_value = 1.77
    b.inputs["Roughness"].default_value = 0.0
    b.inputs["Emission Color"].default_value = (*lin(col), 1)
    b.inputs["Emission Strength"].default_value = 1.2
    return m


# ------------------------------------------------------------------ mesh helpers
def link(me, name="Part", smooth=True):
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    return o


def loft(sections, name="Loft", cap=True, smooth=True):
    """sections: list of (z, [(x,y),...]) all same point count -> closed loft along Z"""
    bm = bmesh.new()
    rings = [[bm.verts.new((x, y, z)) for (x, y) in pts] for z, pts in sections]
    k = len(rings[0])
    for a, b in zip(rings[:-1], rings[1:]):
        for i in range(k):
            bm.faces.new((a[i], a[(i + 1) % k], b[(i + 1) % k], b[i]))
    if cap:
        for r in (rings[0], rings[-1]):
            try:
                bm.faces.new(r)
            except ValueError:
                pass
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return link(me, name, smooth)


def lathe(profile, name="Lathe", segs=40):
    secs = []
    for (r, z) in profile:
        secs.append((z, [(max(r, 1e-4) * math.cos(2 * math.pi * i / segs), max(r, 1e-4) * math.sin(2 * math.pi * i / segs)) for i in range(segs)]))
    return loft(secs, name)


def extrude_shape(pts2d, depth, bevel=0.03, name="Ext"):
    """2D outline in XZ plane, extruded along Y with a rounded bevel"""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "2D"
    sp = cu.splines.new("POLY")
    sp.points.add(len(pts2d) - 1)
    for p, (x, z) in zip(sp.points, pts2d):
        p.co = (x, z, 0, 1)
    sp.use_cyclic_u = True
    cu.extrude = depth / 2
    cu.bevel_depth = bevel
    cu.bevel_resolution = 4
    cu.fill_mode = "BOTH"
    o = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(o)
    o.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.convert(target="MESH")
    o = bpy.context.active_object
    o.select_set(False)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def tube(points, radius, name="Tube", res=12):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    sp = cu.splines.new("NURBS")
    sp.points.add(len(points) - 1)
    for p, c in zip(sp.points, points):
        p.co = (*c, 1)
    sp.use_endpoint_u = True
    sp.order_u = min(4, len(points))
    cu.bevel_depth = radius
    cu.bevel_resolution = res // 4
    cu.use_fill_caps = True
    o = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(o)
    return o


def sphere(r, loc, name="Sph", seg=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def cut_gem(r, loc, col, name="Gem"):
    bm = bmesh.new()
    seg = 16
    table = [bm.verts.new((r * 0.58 * math.cos(2 * math.pi * i / 8 + math.pi / 8), -r * 0.42, r * 0.58 * math.sin(2 * math.pi * i / 8 + math.pi / 8))) for i in range(8)]
    gird = [bm.verts.new((r * math.cos(2 * math.pi * i / seg), 0, r * math.sin(2 * math.pi * i / seg))) for i in range(seg)]
    culet = bm.verts.new((0, r * 0.9, 0))
    bm.faces.new(table)
    for i in range(8):
        t0, t1 = table[i], table[(i + 1) % 8]
        g0, g1, g2 = gird[(2 * i + 1) % seg], gird[(2 * i + 2) % seg], gird[(2 * i + 3) % seg]
        bm.faces.new((t0, g0, g1)); bm.faces.new((t0, g1, t1)); bm.faces.new((t1, g1, g2))
    for i in range(seg):
        bm.faces.new((gird[i], culet, gird[(i + 1) % seg]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    o = link(me, name, smooth=False)
    o.location = loc
    o.data.materials.append(mat_gem(col))
    return o


def apply(o, m):
    o.data.materials.clear()
    o.data.materials.append(m)
    return o


# ------------------------------------------------------------------ weapons (built along +Z, centred later)
def blade(length, width, thick, tip=0.25, curve=0.0, name="Blade", ridge=True, fuller=True):
    secs = []
    N = 28
    for i in range(N + 1):
        t = i / N
        z = t * length
        w = width * (1 - max(0, (t - (1 - tip)) / tip) ** 1.3) if t < 1 else 0.0005
        w = max(w, 0.0006)
        w *= 1 - 0.08 * t
        th = thick * (w / width) ** 0.6
        off = curve * (t ** 2) * length
        if ridge:
            pts = [(-w + off, 0), (-w * 0.55 + off, -th * 0.55), (off, -th), (w * 0.55 + off, -th * 0.55), (w + off, 0), (w * 0.55 + off, th * 0.55), (off, th), (-w * 0.55 + off, th * 0.55)]
        else:
            pts = [(-w + off, 0), (-w * 0.7 + off, -th), (w * 0.7 + off, -th), (w + off, 0), (w * 0.7 + off, th), (-w * 0.7 + off, th)]
            pts = pts + [pts[0]] * 0
            pts = [(-w + off, 0), (-w * 0.8 + off, -th), (0 + off, -th), (w * 0.8 + off, -th), (w + off, 0), (w * 0.8 + off, th), (off, th), (-w * 0.8 + off, th)]
        if fuller and 0.04 < t < 0.6:
            pts[2] = (off, -th * 0.45)
            pts[6] = (off, th * 0.45)
        secs.append((z, [(x, y) for x, y in pts]))
    o = loft(secs, name)
    o.data.polygons.foreach_set("use_smooth", [False] * len(o.data.polygons))
    bev = o.modifiers.new("bev", "BEVEL"); bev.width = 0.004; bev.segments = 2
    return o


def sword_parts(pal, kind="sword", wid=None):
    L = {"sword": 1.55, "greatsword": 1.75, "dagger": 0.95, "katar": 0.9, "scimitar": 1.5}[kind]
    W = {"sword": 0.12, "greatsword": 0.2, "dagger": 0.1, "katar": 0.14, "scimitar": 0.13}[kind]
    if wid:
        W = wid
    curve = 0.12 if kind == "scimitar" else 0.0
    bm_col = pal["metal"] if pal["metal_frac"] > 0.12 else (0.8, 0.82, 0.86)
    blade_col = pal["accent"] if (not pal["metal_frac"] > 0.12 and pal["has_accent"]) else bm_col
    is_tinted = blade_col is pal["accent"]
    if any(k in CUR_ID for k in ("crystal", "jade", "frost", "ice", "violetshard")):
        gc = pal["accent"] if pal["has_accent"] else (0.6, 0.9, 1.0)
        b = blade(L, W, W * 0.13, tip=0.2, curve=curve)
        gm_ = mat_gem(gc, "CrystalBlade")
        gm_.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.6
        apply(b, gm_)
        obs = [b]
        return obs + _hilt(pal, kind, W)
    obs = []
    b = blade(L, W, W * 0.13, tip=0.2 if kind != "katar" else 0.35, curve=curve)
    if is_tinted:
        m = mat_pbr(blade_col, 0.08, 0.6, 1.0, "TintBlade", emit=0.4)
    else:
        m = mat_metal(blade_col, 0.12)
    apply(b, m)
    obs.append(b)
    return obs + _hilt(pal, kind, W)


def _hilt(pal, kind, W):
    obs = []
    guard_col = pal["gold"] if pal["has_gold"] else (pal["accent"] if pal["has_accent"] else (0.6, 0.6, 0.62))
    gm = mat_metal(guard_col, 0.22) if pal["has_gold"] or not pal["has_accent"] else mat_pbr(guard_col, 0.25, 0.85, 0.6, "Guard")
    gw = W * (3.4 if kind != "katar" else 2.0)
    guard = loft([(z, [(x, y) for x, y in pts]) for z, pts in [
        (-0.07, [(-gw * 0.8, -0.03), (gw * 0.8, -0.03), (gw * 0.8, 0.03), (-gw * 0.8, 0.03)]),
        (-0.03, [(-gw, -0.045), (gw, -0.045), (gw, 0.045), (-gw, 0.045)]),
        (0.0, [(-gw * 0.85, -0.035), (gw * 0.85, -0.035), (gw * 0.85, 0.035), (-gw * 0.85, 0.035)]),
    ]], "Guard")
    bev = guard.modifiers.new("b", "BEVEL"); bev.width = 0.015; bev.segments = 3
    apply(guard, gm)
    obs.append(guard)
    for sx in (-1, 1):
        s = sphere(0.04, (sx * gw, 0, -0.035), "GuardEnd", 16)
        apply(s, gm); obs.append(s)
    gl = {"sword": 0.38, "greatsword": 0.55, "dagger": 0.28, "katar": 0.26, "scimitar": 0.36}[kind]
    grip = lathe([(0.0, -0.07), (0.042, -0.07)] + [(0.038 + 0.006 * (i % 2), -0.07 - gl * i / 16) for i in range(17)] + [(0.0, -0.07 - gl)], "Grip", 24)
    grip_col = pal["wood"] if pal["wood"] else (0.35, 0.22, 0.14)
    apply(grip, mat_leather(grip_col))
    obs.append(grip)
    pom = sphere(0.065, (0, 0, -0.07 - gl - 0.05), "Pommel", 24)
    pom.scale = (1, 1, 0.85)
    apply(pom, gm)
    obs.append(pom)
    if pal["has_accent"]:
        obs.append(cut_gem(0.05, (0, -0.045, -0.035), pal["accent"]))
    return obs


def axe_parts(pal, hammer=False, mace=False):
    obs = []
    hl = 1.6
    handle = lathe([(0.0, -0.9), (0.05, -0.9), (0.045, -0.4), (0.04, 0.3), (0.045, 0.62), (0.0, 0.62)], "Handle", 24)
    apply(handle, mat_wood(pal["wood"]))
    obs.append(handle)
    head_col = pal["metal"] if pal["metal_frac"] > 0.1 else (0.72, 0.74, 0.78)
    hm = mat_metal(head_col, 0.2)
    if mace:
        h = sphere(0.22, (0, 0, 0.6), "Head", 32)
        apply(h, hm); obs.append(h)
        for i in range(14):
            phi = math.acos(1 - 2 * (i + 0.5) / 14); th = math.pi * (1 + 5 ** 0.5) * i
            d = Vector((math.sin(phi) * math.cos(th), math.sin(phi) * math.sin(th), math.cos(phi)))
            bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.06, depth=0.16, location=Vector((0, 0, 0.6)) + d * 0.25)
            c = bpy.context.active_object
            c.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
            apply(c, hm); obs.append(c)
    elif hammer:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.55))
        h = bpy.context.active_object
        h.scale = (0.62, 0.26, 0.28)
        bev = h.modifiers.new("b", "BEVEL"); bev.width = 0.04; bev.segments = 3
        apply(h, hm); obs.append(h)
        for sx in (-1, 1):
            bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.15, depth=0.06, location=(sx * 0.33, 0, 0.55), rotation=(0, math.radians(90), 0))
            c = bpy.context.active_object
            apply(c, mat_metal(pal["gold"] if pal["has_gold"] else head_col, 0.25)); obs.append(c)
    else:
        pts = [(0.03, 0.75), (0.25, 0.85), (0.5, 0.98), (0.6, 0.75), (0.62, 0.5), (0.58, 0.25), (0.48, 0.1), (0.25, 0.25), (0.03, 0.35)]
        h = extrude_shape(pts, 0.06, 0.018, "AxeHead")
        apply(h, hm); obs.append(h)
        pts2 = [(-0.03, 0.75), (-0.18, 0.68), (-0.3, 0.55), (-0.18, 0.42), (-0.03, 0.38)]
        h2 = extrude_shape(pts2, 0.05, 0.015, "AxeBack")
        apply(h2, hm); obs.append(h2)
    for z in (-0.88, 0.25):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.05, minor_radius=0.015, location=(0, 0, z))
        t = bpy.context.active_object
        apply(t, mat_metal(pal["gold"] if pal["has_gold"] else (0.55, 0.55, 0.58), 0.25)); obs.append(t)
    if pal["has_accent"]:
        obs.append(cut_gem(0.06, (0, -0.08, 0.55 if not mace else 0.6), pal["accent"]))
    return obs


def staff_parts(pal):
    obs = []
    shaft = tube([(0, 0, -1.0), (0.03, 0, -0.4), (-0.02, 0, 0.2), (0.02, 0, 0.62)], 0.045, "Shaft")
    bpy.context.view_layer.objects.active = shaft
    shaft.select_set(True); bpy.ops.object.convert(target="MESH"); shaft = bpy.context.active_object; shaft.select_set(False)
    apply(shaft, mat_wood(pal["wood"]))
    obs.append(shaft)
    claw_m = mat_metal(pal["gold"] if pal["has_gold"] else (0.75, 0.77, 0.8), 0.2)
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        pts = [(0.02 * math.cos(a), 0.02 * math.sin(a), 0.6), (0.14 * math.cos(a), 0.14 * math.sin(a), 0.72), (0.15 * math.cos(a), 0.15 * math.sin(a), 0.86), (0.06 * math.cos(a), 0.06 * math.sin(a), 0.98)]
        c = tube(pts, 0.018, "Claw")
        c.data.materials.append(claw_m)
        obs.append(c)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.06, minor_radius=0.025, location=(0, 0, 0.6))
    t = bpy.context.active_object; apply(t, claw_m); obs.append(t)
    oc = pal["accent"] if pal["has_accent"] else (0.4, 0.7, 1.0)
    orb = sphere(0.13, (0, 0, 0.83), "Orb", 48)
    m = mat_pbr(oc, 0.02, 0, 1.0, "Orb", emit=2.5)
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Transmission Weight"].default_value = 0.8
    b.inputs["IOR"].default_value = 1.5
    apply(orb, m)
    obs.append(orb)
    core = sphere(0.06, (0, 0, 0.83), "Core", 24)
    apply(core, mat_pbr(tuple(min(1, x * 1.3 + 0.2) for x in oc), 0.3, 0, 0, "Core", emit=8))
    obs.append(core)
    return obs


def bow_parts(pal):
    obs = []
    limb_pts = [(0.0, 0, -1.0), (0.18, 0, -0.75), (0.32, 0, -0.35), (0.34, 0, 0.0), (0.32, 0, 0.35), (0.18, 0, 0.75), (0.0, 0, 1.0)]
    limb = tube(limb_pts, 0.04, "Limb")
    limb.data.taper_radius_mode = "MULTIPLY" if hasattr(limb.data, "taper_radius_mode") else None
    sp = limb.data.splines[0]
    for i, p in enumerate(sp.points):
        p.radius = 0.55 + 0.8 * (1 - abs(i - 3) / 3)
    bpy.context.view_layer.objects.active = limb
    limb.select_set(True); bpy.ops.object.convert(target="MESH"); limb = bpy.context.active_object; limb.select_set(False)
    use_wood = not (pal["metal_frac"] > 0.3 and not pal["wood"])
    apply(limb, mat_wood(pal["wood"]) if use_wood else mat_metal(pal["metal"], 0.2))
    obs.append(limb)
    s = tube([(0.0, 0, -1.0), (-0.02, 0, 0.0), (0.0, 0, 1.0)], 0.006, "String")
    s.data.materials.append(mat_pbr((0.9, 0.88, 0.8), 0.6, 0, 0, "Str"))
    obs.append(s)
    grip = lathe([(0, -0.16), (0.06, -0.16), (0.065, 0.0), (0.06, 0.16), (0, 0.16)], "BowGrip", 20)
    grip.location = (0.34, 0, 0)
    apply(grip, mat_leather((0.3, 0.17, 0.1)))
    obs.append(grip)
    acc_m = mat_metal(pal["gold"] if pal["has_gold"] else (0.75, 0.77, 0.8), 0.2)
    for z in (-1, 1):
        t = sphere(0.045, (0.0, 0, z), "Tip", 16)
        apply(t, acc_m); obs.append(t)
        bpy.ops.mesh.primitive_torus_add(major_radius=0.055, minor_radius=0.014, location=(0.335, 0, 0.17 * z))
        tt = bpy.context.active_object; apply(tt, acc_m); obs.append(tt)
    if pal["has_accent"]:
        obs.append(cut_gem(0.055, (0.37, -0.05, 0), pal["accent"]))
    return obs


def shield_parts(pal, shape="kite"):
    obs = []
    if shape == "kite":
        pts = [(math.sin(a) * 0.62, 0.55 + math.cos(a) * 0.25) for a in np.linspace(-math.pi / 2, math.pi / 2, 14)]
        pts = [(0.62, 0.55)] + [(0.6 - 0.6 * t ** 1.4, 0.55 - 1.55 * t) for t in np.linspace(0.05, 1, 12)]
        pts = pts + [(-x, z) for x, z in reversed(pts[1:-1])] + [(-0.62, 0.55)]
        top = [(math.cos(a) * 0.62, 0.55 + math.sin(a) * 0.3) for a in np.linspace(math.pi, 0, 16)]
        pts = top[:-1] + pts[:-1]
        pts = top + [(0.6 - 0.6 * t ** 1.4, 0.55 - 1.55 * t) for t in np.linspace(0.05, 1, 12)] + [(-(0.6 - 0.6 * t ** 1.4), 0.55 - 1.55 * t) for t in np.linspace(1, 0.05, 12)][1:]
    elif shape == "round":
        pts = [(math.cos(a) * 0.8, math.sin(a) * 0.8) for a in np.linspace(0, 2 * math.pi, 48, endpoint=False)]
    else:
        pts = [(-0.6, 0.8), (0.6, 0.8), (0.6, -0.5), (0.0, -0.95), (-0.6, -0.5)]
    face_col = pal["accent"] if pal["has_accent"] else pal["metal"]
    body = extrude_shape(pts, 0.1, 0.02, "ShieldBody")
    for v in body.data.vertices:          # dome
        r2 = (v.co.x ** 2 + v.co.y ** 2)
        v.co.z += 0.18 * (1 - min(1, r2 / 0.9)) * (1 if v.co.z > 0 else 0.6)
    m = mat_pbr(face_col, 0.35, 0.0, 0.7, "Paint")
    apply(body, m)
    body.rotation_euler = (math.radians(90), 0, 0)
    body.scale = (1, 1, 1)
    obs.append(body)
    rim_col = pal["gold"] if pal["has_gold"] else pal["metal"]
    rim = tube([(x, -0.06, z) for x, z in pts + [pts[0], pts[1]]], 0.04, "Rim", 12)
    rim.data.splines[0].order_u = 3
    rim.data.materials.append(mat_metal(rim_col, 0.2))
    obs.append(rim)
    boss = sphere(0.16, (0, -0.16, 0.1 if shape == "kite" else 0), "Boss", 32)
    boss.scale = (1, 0.5, 1)
    apply(boss, mat_metal(rim_col, 0.15))
    obs.append(boss)
    for (x, z) in [(0.4, 0.55), (-0.4, 0.55), (0.3, -0.4), (-0.3, -0.4)] if shape == "kite" else []:
        r = sphere(0.035, (x, -0.13, z), "Rivet", 12); apply(r, mat_metal(rim_col, 0.2)); obs.append(r)
    return obs


def ring_parts(pal):
    obs = []
    bpy.ops.mesh.primitive_torus_add(major_radius=0.5, minor_radius=0.09, major_segments=64, minor_segments=24)
    t = bpy.context.active_object
    for p in t.data.polygons:
        p.use_smooth = True
    band = pal["gold"] if pal["has_gold"] else pal["metal"]
    apply(t, mat_metal(band, 0.12))
    t.rotation_euler = (math.radians(70), 0, 0)
    obs.append(t)
    setting = lathe([(0.0, 0.0), (0.12, 0.0), (0.16, 0.1), (0.0, 0.1)], "Setting", 24)
    setting.location = (0, 0.15, 0.5)
    apply(setting, mat_metal(band, 0.15))
    obs.append(setting)
    g = cut_gem(0.17, (0, 0.0, 0.66), pal["accent"] if pal["has_accent"] else (0.6, 0.85, 1.0))
    g.rotation_euler = (math.radians(-70), 0, 0)
    g.location = (0, -0.02, 0.68)
    obs.append(g)
    return obs


def necklace_parts(pal, pearls=False):
    obs = []
    chain_col = pal["gold"] if pal["has_gold"] else pal["metal"]
    n = 26 if not pearls else 22
    for i in range(n):
        a = math.pi * 1.04 + (math.pi * 0.92) * i / (n - 1)
        x = math.cos(a) * 0.62; z = 0.62 + math.sin(a) * 0.78
        if pearls:
            s = sphere(0.075, (x, 0, z), "Pearl", 20)
            m = mat_pbr((0.95, 0.93, 0.9), 0.12, 0, 1.0, "Pearl")
            m.node_tree.nodes["Principled BSDF"].inputs["Sheen Weight"].default_value = 1.0
            m.node_tree.nodes["Principled BSDF"].inputs["Sheen Tint"].default_value = (1.0, 0.85, 0.95, 1)
            apply(s, m)
        else:
            bpy.ops.mesh.primitive_torus_add(major_radius=0.045, minor_radius=0.013, location=(x, 0, z), rotation=(0 if i % 2 else math.radians(90), -a, 0))
            s = bpy.context.active_object
            apply(s, mat_metal(chain_col, 0.15))
        obs.append(s)
    frame = lathe([(0.0, -0.03), (0.22, -0.03), (0.24, 0.03), (0.0, 0.03)], "Frame", 32)
    frame.rotation_euler = (math.radians(90), 0, 0)
    frame.location = (0, 0, -0.42)
    apply(frame, mat_metal(chain_col, 0.15))
    obs.append(frame)
    g = cut_gem(0.2, (0, -0.04, -0.42), pal["accent"] if pal["has_accent"] else (0.9, 0.15, 0.2))
    obs.append(g)
    # chain links down to the pendant
    for i in range(3):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.035, minor_radius=0.011, location=(0, 0, -0.12 - 0.05 * i), rotation=(0, math.radians(90 * (i % 2)), 0))
        s = bpy.context.active_object; apply(s, mat_metal(chain_col, 0.15)); obs.append(s)
    return obs


def crown_parts(pal):
    obs = []
    gold = pal["gold"] if pal["has_gold"] else (1.0, 0.8, 0.3)
    gm = mat_metal(gold, 0.14)
    band = lathe([(0.62, -0.3), (0.66, -0.3), (0.66, 0.05), (0.62, 0.05)], "Band", 64)
    apply(band, gm); obs.append(band)
    # points
    bm = bmesh.new()
    N = 8
    for i in range(N):
        a0 = 2 * math.pi * i / N; a1 = 2 * math.pi * (i + 1) / N; am = (a0 + a1) / 2
        v = [bm.verts.new((0.64 * math.cos(a0), 0.64 * math.sin(a0), 0.04)), bm.verts.new((0.64 * math.cos(am), 0.64 * math.sin(am), 0.42)), bm.verts.new((0.64 * math.cos(a1), 0.64 * math.sin(a1), 0.04))]
        bm.faces.new(v)
    me = bpy.data.meshes.new("Pts"); bm.to_mesh(me)
    p = link(me, "Points")
    s = p.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.04
    apply(p, gm); obs.append(p)
    for i in range(N):
        am = 2 * math.pi * (i + 0.5) / N
        b = sphere(0.045, (0.64 * math.cos(am), 0.64 * math.sin(am), 0.45), "Ball", 16); apply(b, gm); obs.append(b)
    cols = [pal["accent"] if pal["has_accent"] else (0.9, 0.1, 0.2), (0.15, 0.35, 0.95), (0.1, 0.75, 0.3)]
    for i in range(5):
        a = -math.pi / 2 + (i - 2) * 0.5
        g = cut_gem(0.07, (0.68 * math.cos(a), 0.68 * math.sin(a), -0.12), cols[i % 3])
        g.rotation_euler = (0, 0, a + math.pi / 2)
        obs.append(g)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.6, location=(0, 0, -0.05))
    vel = bpy.context.active_object
    vel.scale = (1, 1, 0.55)
    for pp in vel.data.polygons:
        pp.use_smooth = True
    vm = mat_pbr((0.55, 0.05, 0.1), 0.8, 0, 0, "Velvet")
    vm.node_tree.nodes["Principled BSDF"].inputs["Sheen Weight"].default_value = 1.0
    apply(vel, vm); obs.append(vel)
    for o in obs:
        o.rotation_euler.x += math.radians(18)
    return obs


# ------------------------------------------------------------------ dispatcher
CUR_ID = ""
KIND_KEYS = [
    ("greatsword", "greatsword"), ("broadsword", "greatsword"), ("lionheart", "greatsword"),
    ("scimitar", "scimitar"), ("katar", "katar"), ("dagger", "dagger"), ("knife", "dagger"),
    ("sword", "sword"), ("blade", "sword"),
    ("crossbow", "bow"), ("bow", "bow"),
    ("staff", "staff"), ("wand", "staff"),
    ("hammer", "hammer"), ("maul", "hammer"), ("mace", "mace"), ("axe", "axe"), ("halberd", "axe"),
    ("tower_shield", "shield_tower"), ("buckler", "shield_round"), ("shield", "shield_kite"),
    ("royal_crown", "crown"), ("pharaoh_mask", "crown"), ("ring", "ring"), ("pearl_necklace", "pearls"), ("amulet", "necklace"), ("rosary", "pearls"),
]


def kind_of(item_id):
    if item_id.startswith("hat_") and item_id != "hat_royal_crown":
        return None
    for key, kind in KIND_KEYS:
        if key in item_id:
            return kind
    return None


def build_hero(item_id, src_path):
    global CUR_ID
    CUR_ID = item_id
    kind = kind_of(item_id)
    if kind is None:
        return None
    pal = palette(src_path)
    if kind in ("sword", "greatsword", "dagger", "katar", "scimitar"):
        obs = sword_parts(pal, kind); diag = True
    elif kind == "axe":
        obs = axe_parts(pal); diag = True
    elif kind == "hammer":
        obs = axe_parts(pal, hammer=True); diag = True
    elif kind == "mace":
        obs = axe_parts(pal, mace=True); diag = True
    elif kind == "staff":
        obs = staff_parts(pal); diag = True
    elif kind == "bow":
        obs = bow_parts(pal); diag = True
    elif kind.startswith("shield"):
        obs = shield_parts(pal, kind.split("_")[1]); diag = False
    elif kind == "ring":
        obs = ring_parts(pal); diag = False
    elif kind == "necklace":
        obs = necklace_parts(pal); diag = False
    elif kind == "pearls":
        obs = necklace_parts(pal, pearls=True); diag = False
    elif kind == "crown":
        obs = crown_parts(pal); diag = False
    else:
        return None
    # group under a pivot and pose it
    piv = bpy.data.objects.new("Pivot", None)
    bpy.context.scene.collection.objects.link(piv)
    for o in obs:
        o.parent = piv
    if diag:
        piv.rotation_euler = (math.radians(-18), math.radians(45 if kind != "bow" else 35), math.radians(-12))
    else:
        piv.rotation_euler = (math.radians(-6), 0, math.radians(-14))
    return obs
