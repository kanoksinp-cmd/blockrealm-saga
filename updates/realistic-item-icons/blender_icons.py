#!/usr/bin/env python3
"""Realistic item icons rendered with Blender Cycles.

Every pixel-art icon becomes a real 3D object (smoothed silhouette, bevelled
thickness, relief) with PBR materials worked out per pixel (polished metal,
gold, gems, wood, leather, cloth), lit by a studio light rig with an
environment for reflections.  Gems, potions, crystals, ores and gels get
hand-built procedural models.  Output: transparent PNG per item."""
import sys, os, math, json
import numpy as np
from PIL import Image
from scipy import ndimage
import bpy
import bmesh
from mathutils import Vector, Euler, Matrix

SRC = "/tmp/icons_src"
OUT = "/tmp/icons_real"
RES = 256
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(5)


# ------------------------------------------------------------------ pixel art -> maps
def scale2x(a):
    h, w = a.shape[:2]
    p = np.pad(a, ((1, 1), (1, 1), (0, 0)), mode="edge")
    B = p[0:h, 1:w + 1]; D = p[1:h + 1, 0:w]; E = p[1:h + 1, 1:w + 1]; F = p[1:h + 1, 2:w + 2]; H = p[2:h + 2, 1:w + 1]
    eq = lambda x, y: np.all(x == y, axis=2)
    c = (~eq(B, H)) & (~eq(D, F))
    out = np.zeros((h * 2, w * 2, a.shape[2]), a.dtype)
    out[0::2, 0::2] = np.where((c & eq(D, B))[..., None], D, E)
    out[0::2, 1::2] = np.where((c & eq(B, F))[..., None], F, E)
    out[1::2, 0::2] = np.where((c & eq(D, H))[..., None], D, E)
    out[1::2, 1::2] = np.where((c & eq(H, F))[..., None], F, E)
    return out


def strip_outline(a):
    rgb = a[..., :3].astype(float) / 255
    alpha = a[..., 3] > 0
    lum = rgb @ np.array([0.3, 0.59, 0.11])
    edge = alpha & ~ndimage.binary_erosion(alpha, border_value=0)
    kill = edge & (lum < 0.2)
    out = a.copy()
    if kill.sum() > 0.45 * max(1, edge.sum()):
        out[kill, 3] = 0
    return out


def load_maps(path, W=288):
    """-> rgb (W,W,3) float, alpha (W,W) float smooth mask, dist (px)"""
    src = np.array(Image.open(path).convert("RGBA"))
    src[src[..., 3] < 128] = 0
    src[src[..., 3] >= 128, 3] = 255
    src = strip_outline(src)
    ys, xs = np.nonzero(src[..., 3])
    if len(xs) == 0:
        return None
    src = src[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    fit = int(W * 0.9)
    blk = fit / max(src.shape[:2])
    a = src
    while max(a.shape[:2]) < fit:
        a = scale2x(a)
    s = fit / max(a.shape[:2])
    im = Image.fromarray(a).resize((max(1, round(a.shape[1] * s)), max(1, round(a.shape[0] * s))), Image.BOX)
    a = np.array(im)
    canvas = np.zeros((W, W, 4), np.uint8)
    oy, ox = (W - a.shape[0]) // 2, (W - a.shape[1]) // 2
    canvas[oy:oy + a.shape[0], ox:ox + a.shape[1]] = a
    a = canvas
    alpha = (a[..., 3] > 127).astype(float)
    alpha = (ndimage.gaussian_filter(alpha, max(1.5, blk * 0.6)) > 0.5).astype(float)
    rgb = a[..., :3].astype(float) / 255
    if alpha.sum() > 0:
        idx = ndimage.distance_transform_edt(a[..., 3] < 128, return_distances=False, return_indices=True)
        rgb = rgb[idx[0], idx[1]]
    for ch in range(3):
        rgb[..., ch] = ndimage.median_filter(rgb[..., ch], size=int(max(3, blk * 0.8)) | 1)
    dist = ndimage.distance_transform_edt(alpha)
    return rgb, alpha, dist, blk


def classify(rgb, alpha):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(2); mn = rgb.min(2); d = np.maximum(mx - mn, 1e-4)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-4), 0)
    lum = rgb @ np.array([0.3, 0.59, 0.11])
    hue = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    metal = np.clip((0.3 - sat) / 0.2, 0, 1) * np.clip((lum - 0.28) / 0.25, 0, 1)
    gold = ((hue > 30) & (hue < 62) & (sat > 0.4) & (lum > 0.42)).astype(float)
    wood = ((hue > 10) & (hue < 45) & (sat > 0.22) & (lum < 0.5)).astype(float) * (1 - gold)
    gem = np.clip((sat - 0.45) / 0.3, 0, 1) * np.clip((mx - 0.5) / 0.3, 0, 1) * (1 - gold)
    return dict(metal=metal, gold=gold, wood=wood, gem=gem, lum=lum, sat=sat)


# ------------------------------------------------------------------ scene
def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 96
    sc.cycles.use_denoising = True
    try:
        sc.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    sc.cycles.max_bounces = 8
    sc.cycles.transmission_bounces = 8
    sc.cycles.glossy_bounces = 6
    sc.render.film_transparent = True
    sc.render.resolution_x = RES
    sc.render.resolution_y = RES
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Punchy"
    sc.view_settings.exposure = 0.35
    # world: studio gradient for reflections (warm top, dark floor)
    w = bpy.data.worlds.new("Studio")
    sc.world = w
    w.use_nodes = True
    nt = w.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    mp = nt.nodes.new("ShaderNodeMapRange")
    nt.links.new(tc.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], mp.inputs["Value"])
    mp.inputs["From Min"].default_value = 0.35
    mp.inputs["From Max"].default_value = 0.75
    nt.links.new(mp.outputs["Result"], ramp.inputs["Fac"])
    cr = ramp.color_ramp
    cr.elements[0].position = 0.0; cr.elements[0].color = (0.18, 0.16, 0.15, 1)
    cr.elements[1].position = 0.55; cr.elements[1].color = (0.55, 0.55, 0.58, 1)
    e = cr.elements.new(0.5); e.color = (1.4, 1.35, 1.25, 1)      # bright horizon band
    e2 = cr.elements.new(1.0); e2.color = (0.75, 0.82, 1.0, 1)
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.6
    nt.links.new(bg.outputs[0], out.inputs[0])
    # camera
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = 2.25
    cam = bpy.data.objects.new("Cam", cam_d)
    sc.collection.objects.link(cam)
    cam.location = (0, -10, 0)
    cam.rotation_euler = (math.radians(90), 0, 0)
    sc.camera = cam
    # lights: key (top-left, warm), rim (back-right, cool), fill
    def area(name, loc, energy, size, color):
        ld = bpy.data.lights.new(name, "AREA")
        ld.energy = energy
        ld.size = size
        ld.color = color
        lo = bpy.data.objects.new(name, ld)
        sc.collection.objects.link(lo)
        lo.location = loc
        d = -Vector(loc).normalized()
        lo.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        return lo
    area("Key", (-3.2, -4.0, 3.6), 700, 3.0, (1.0, 0.95, 0.86))
    area("Rim", (3.5, 3.0, 2.2), 600, 2.0, (0.75, 0.85, 1.0))
    area("Fill", (3.0, -4.0, -1.5), 150, 4.0, (0.95, 0.9, 1.0))
    # visible softboxes so polished metal/gems reflect a studio, not a void
    def softbox(name, loc, size, strength, color=(1, 1, 1)):
        bpy.ops.mesh.primitive_plane_add(size=1, location=loc)
        p = bpy.context.active_object
        p.name = name
        p.scale = (size[0], size[1], 1)
        d = -Vector(loc).normalized()
        p.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        nt = m.node_tree
        nt.nodes.clear()
        o = nt.nodes.new("ShaderNodeOutputMaterial")
        e = nt.nodes.new("ShaderNodeEmission")
        e.inputs["Color"].default_value = (*color, 1)
        e.inputs["Strength"].default_value = strength
        nt.links.new(e.outputs[0], o.inputs[0])
        p.data.materials.append(m)
        p.visible_camera = False
        p.visible_shadow = False
        return p
    softbox("SB_top", (-1.5, -3.5, 4.5), (6, 2.0), 6.0, (1.0, 0.97, 0.92))
    softbox("SB_left", (-5.0, -3.0, 0.5), (1.6, 6), 4.0, (1.0, 0.95, 0.88))
    softbox("SB_right", (5.0, -2.5, 0.0), (1.2, 6), 3.0, (0.8, 0.88, 1.0))
    softbox("SB_front", (0.5, -6.0, -2.0), (5, 1.2), 1.6, (1.0, 1.0, 1.0))
    return sc


def image_from_np(name, arr):
    h, w = arr.shape[:2]
    img = bpy.data.images.new(name, w, h, alpha=True, float_buffer=True)
    if arr.ndim == 2:
        arr = np.dstack([arr, arr, arr, np.ones_like(arr)])
    elif arr.shape[2] == 3:
        arr = np.dstack([arr, np.ones(arr.shape[:2])])
    img.colorspace_settings.name = "Non-Color"
    img.pixels.foreach_set(np.flipud(arr).astype(np.float32).ravel())
    img.pack()
    return img


def tex_node(nt, img, srgb=False):
    n = nt.nodes.new("ShaderNodeTexImage")
    n.image = img
    n.interpolation = "Cubic"
    if srgb:
        img.colorspace_settings.name = "sRGB"
    return n


# ------------------------------------------------------------------ generic relief model
def relief_object(maps, kind=""):
    rgb, alpha, dist, blk = maps
    W = rgb.shape[0]
    cl = classify(rgb, alpha)
    size = 2.0
    px = size / W
    hard = np.clip(cl["metal"] + cl["gold"], 0, 1)
    hard = ndimage.gaussian_filter(hard, 2.0)
    # soft rounded pillow for cloth/leather/wood, ground ridge (linear) for metal
    R = max(8.0, min(26.0, dist.max() * 0.9))
    t = np.clip(dist / R, 0, 1)
    round_p = np.sqrt(1 - (1 - t) ** 2)
    ridge = np.clip(dist / max(4.0, dist.max()), 0, 1) ** 0.85
    prof = round_p * (1 - hard) + (0.25 * round_p + 0.75 * ridge) * hard
    thick = 0.16 * size * min(1.0, dist.max() / 30.0 + 0.3)
    # colour-region relief: regions bulge, borders between colours become grooves
    lum = cl["lum"]
    lum_s = ndimage.gaussian_filter(lum, 2.5)
    edges = np.hypot(ndimage.sobel(lum_s, 0), ndimage.sobel(lum_s, 1))
    groove = ndimage.gaussian_filter(np.clip(edges * 3, 0, 1), 1.5)
    h = prof * thick * 0.5 - groove * 0.006 * size + (lum_s - 0.5) * 0.01 * size * prof
    gem = ndimage.gaussian_filter(cl["gem"], 1.5)
    gd = ndimage.distance_transform_edt(gem > 0.5)
    h += np.sqrt(np.clip(gd / 6.0, 0, 1)) * 0.03 * size * (gem > 0.5)
    h = ndimage.gaussian_filter(h, 1.0)
    inside = alpha > 0.5
    ids = -np.ones((W, W), int)
    ys, xs = np.nonzero(inside)
    ids[ys, xs] = np.arange(len(xs))
    n = len(xs)
    X = (xs + 0.5) * px - size / 2
    Z = size / 2 - (ys + 0.5) * px
    verts = np.vstack([np.stack([X, -h[ys, xs] - 0.003, Z], 1), np.stack([X, h[ys, xs] * 0.7 + 0.003, Z], 1)])
    a_ = ids[:-1, :-1]; b_ = ids[:-1, 1:]; c_ = ids[1:, 1:]; d_ = ids[1:, :-1]
    ok = (a_ >= 0) & (b_ >= 0) & (c_ >= 0) & (d_ >= 0)
    A, B, C, D = a_[ok], b_[ok], c_[ok], d_[ok]
    top = np.stack([A, D, C, B], 1)
    bot = np.stack([A, B, C, D], 1) + n
    edges_d = {}
    for q in top:
        for i in range(4):
            e = (int(q[i]), int(q[(i + 1) % 4]))
            k = (min(e), max(e))
            edges_d[k] = None if k in edges_d else e
    side = [(e[1], e[0], e[0] + n, e[1] + n) for e in edges_d.values() if e is not None]
    me = bpy.data.meshes.new("relief")
    me.from_pydata(verts.tolist(), [], np.vstack([top, bot]).tolist() + [list(x) for x in side])
    me.update()
    uv = me.uv_layers.new(name="UV")
    uvs = np.vstack([np.stack([(xs + 0.5) / W, 1 - (ys + 0.5) / W], 1)] * 2)
    loop_v = np.zeros(len(me.loops), int)
    me.loops.foreach_get("vertex_index", loop_v)
    uv.data.foreach_set("uv", uvs[loop_v].ravel())
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("Item", me)
    bpy.context.scene.collection.objects.link(ob)
    # smooth the jagged silhouette walls
    sm = ob.modifiers.new("sm", "CORRECTIVE_SMOOTH")
    sm.factor = 0.6; sm.iterations = 6; sm.smooth_type = "LENGTH_WEIGHTED"
    sm.use_only_smooth = True if hasattr(sm, "use_only_smooth") else False
    # ---------- material
    m = bpy.data.materials.new("Mat")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    base = rgb.copy()
    # flatten pixel noise inside colour regions, keep borders crisp
    for ch in range(3):
        base[..., ch] = ndimage.gaussian_filter(base[..., ch], 1.2) * 0.6 + base[..., ch] * 0.4
    g = cl["gold"][..., None]
    base = base * (1 - g * 0.25) + np.array([1.0, 0.76, 0.33]) * g * 0.25
    hm = hard[..., None]
    grey = base.mean(2, keepdims=True)
    base = base * (1 - hm * (1 - cl["gold"][..., None]) * 0.3) + grey * hm * (1 - cl["gold"][..., None]) * 0.3
    base = np.clip(base * (1 + hm * 0.25), 0, 1)
    tcol = tex_node(nt, image_from_np("col", base ** 2.2))
    metallic = np.clip(hard * 1.1, 0, 1)
    rough = 0.62 - 0.42 * hard - 0.5 * gem + 0.15 * cl["wood"]
    rough = np.clip(ndimage.gaussian_filter(rough, 1.5), 0.07, 0.85)
    tmet = tex_node(nt, image_from_np("met", metallic))
    trou = tex_node(nt, image_from_np("rou", rough))
    tcoat = tex_node(nt, image_from_np("coat", np.clip(gem + cl["wood"] * 0.3, 0, 1)))
    nt.links.new(tcol.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tmet.outputs["Color"], bsdf.inputs["Metallic"])
    nt.links.new(tcoat.outputs["Color"], bsdf.inputs["Coat Weight"])
    bsdf.inputs["Coat Roughness"].default_value = 0.03
    # micro detail: brushed metal streaks + fabric/leather noise via bump & roughness
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mapn = nt.nodes.new("ShaderNodeMapping")
    mapn.inputs["Scale"].default_value = (2.0, 2.0, 60.0)
    nt.links.new(tc.outputs["Object"], mapn.inputs["Vector"])
    brush = nt.nodes.new("ShaderNodeTexNoise"); brush.inputs["Scale"].default_value = 30; brush.inputs["Detail"].default_value = 4
    nt.links.new(mapn.outputs["Vector"], brush.inputs["Vector"])
    cloth = nt.nodes.new("ShaderNodeTexNoise"); cloth.inputs["Scale"].default_value = 120; cloth.inputs["Detail"].default_value = 2
    nt.links.new(tc.outputs["Object"], cloth.inputs["Vector"])
    mixh = nt.nodes.new("ShaderNodeMix"); mixh.data_type = "FLOAT"
    nt.links.new(tmet.outputs["Color"], mixh.inputs["Factor"])
    nt.links.new(cloth.outputs["Fac"], mixh.inputs["A"])
    nt.links.new(brush.outputs["Fac"], mixh.inputs["B"])
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.12; bump.inputs["Distance"].default_value = 0.01
    nt.links.new(mixh.outputs["Result"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    rmix = nt.nodes.new("ShaderNodeMath"); rmix.operation = "MULTIPLY_ADD"
    nt.links.new(mixh.outputs["Result"], rmix.inputs[0]); rmix.inputs[1].default_value = 0.18
    nt.links.new(trou.outputs["Color"], rmix.inputs[2])
    nt.links.new(rmix.outputs[0], bsdf.inputs["Roughness"])
    em = np.clip(gem * 0.7, 0, 1)[..., None] * np.clip(base, 0, 1)
    tem = tex_node(nt, image_from_np("em", em ** 2.2))
    nt.links.new(tem.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = 0.8
    ob.data.materials.append(m)
    return ob


# ------------------------------------------------------------------ procedural hero models
def glass_mat(color, ior=1.5, rough=0.02, name="Glass", absorb=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Transmission Weight"].default_value = 1.0
    b.inputs["IOR"].default_value = ior
    b.inputs["Roughness"].default_value = rough
    return m


def pbr(color, metal=0.0, rough=0.5, name="M", emit=None, coat=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    b.inputs["Coat Weight"].default_value = coat
    if emit:
        b.inputs["Emission Color"].default_value = (*emit[0], 1)
        b.inputs["Emission Strength"].default_value = emit[1]
    return m


def lin(c):
    return tuple(max(0.0, x) ** 2.2 for x in c)


def gem_object(color):
    """brilliant cut: table, 8 crown facets, girdle, 8 pavilion facets to a culet"""
    bm = bmesh.new()
    seg = 16
    r_g, r_t = 0.9, 0.52
    z_t, z_g, z_c = 0.38, 0.0, -0.95
    table = [bm.verts.new((r_t * math.cos(2 * math.pi * i / 8 + math.pi / 8), r_t * math.sin(2 * math.pi * i / 8 + math.pi / 8), z_t)) for i in range(8)]
    gird = [bm.verts.new((r_g * math.cos(2 * math.pi * i / seg), r_g * math.sin(2 * math.pi * i / seg), z_g)) for i in range(seg)]
    gird2 = [bm.verts.new((r_g * math.cos(2 * math.pi * i / seg), r_g * math.sin(2 * math.pi * i / seg), z_g - 0.06)) for i in range(seg)]
    culet = bm.verts.new((0, 0, z_c))
    bm.faces.new(table)
    for i in range(8):
        t0, t1 = table[i], table[(i + 1) % 8]
        g0, g1, g2 = gird[(2 * i + 1) % seg], gird[(2 * i + 2) % seg], gird[(2 * i + 3) % seg]
        bm.faces.new((t0, g0, g1))
        bm.faces.new((t0, g1, t1))
        bm.faces.new((t1, g1, g2))
    for i in range(seg):
        bm.faces.new((gird[i], gird2[i], gird2[(i + 1) % seg], gird[(i + 1) % seg]))
        bm.faces.new((gird2[i], culet, gird2[(i + 1) % seg]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("gem")
    bm.to_mesh(me)
    ob = bpy.data.objects.new("Item", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(glass_mat(lin(color), ior=1.76, rough=0.0, name="Gem"))
    ob.rotation_euler = (math.radians(68), 0, math.radians(14))
    ob.scale = (0.95, 0.95, 0.95)
    return [ob]


def crystal_object(color):
    obs = []
    m = glass_mat(lin(color), ior=1.55, rough=0.04, name="Crystal")
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Emission Color"].default_value = (*lin(color), 1)
    b.inputs["Emission Strength"].default_value = 0.8
    specs = [(0, 0, 0, 1.0, 0.32), (-0.35, 0.05, -18, 0.7, 0.22), (0.33, -0.05, 20, 0.62, 0.2), (0.12, 0.25, 8, 0.5, 0.16)]
    for (x, y, tilt, hgt, rad) in specs:
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=rad, depth=hgt * 1.4, location=(0, 0, 0))
        o = bpy.context.active_object
        # point the top
        me = o.data
        for v in me.vertices:
            if v.co.z > 0:
                v.co.x *= 0.0 if False else 1.0
        bm = bmesh.new(); bm.from_mesh(me)
        top = [v for v in bm.verts if v.co.z > 0]
        c = bmesh.ops.poke(bm, faces=[f for f in bm.faces if all(v.co.z > 0 for v in f.verts)])
        for v in bm.verts:
            if abs(v.co.x) < 1e-5 and abs(v.co.y) < 1e-5 and v.co.z > 0:
                v.co.z += rad * 1.6
        bm.to_mesh(me); bm.free()
        o.location = (x, y * 0.3, -0.45 + hgt * 0.7 * 0.5)
        o.rotation_euler = (math.radians(-90 + 90), math.radians(tilt), 0)
        o.rotation_euler = (0, math.radians(tilt), 0)
        o.data.materials.append(m)
        obs.append(o)
    base = pbr(lin((0.35, 0.3, 0.28)), 0, 0.9, "Rock")
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.45, location=(0, 0.1, -0.75))
    r = bpy.context.active_object
    r.scale = (1.3, 0.8, 0.45)
    d = r.modifiers.new("d", "DISPLACE")
    t = bpy.data.textures.new("n", "CLOUDS"); t.noise_scale = 0.35
    d.texture = t; d.strength = 0.15
    r.data.materials.append(base)
    obs.append(r)
    for o in obs:
        o.rotation_euler.x += math.radians(-12)
    return obs


def potion_object(color, milk=False):
    # lathe profile for the bottle
    prof = [(0.0, -0.95), (0.62, -0.95), (0.7, -0.82), (0.72, -0.35), (0.62, 0.05), (0.3, 0.3), (0.2, 0.45), (0.2, 0.7), (0.24, 0.74), (0.24, 0.8), (0.0, 0.8)]
    def lathe(points, name, segs=48):
        bm = bmesh.new()
        rings = []
        for (r, z) in points:
            ring = [bm.verts.new((r * math.cos(2 * math.pi * i / segs), r * math.sin(2 * math.pi * i / segs), z)) for i in range(segs)]
            rings.append(ring)
        for a, b in zip(rings[:-1], rings[1:]):
            for i in range(segs):
                try:
                    bm.faces.new((a[i], a[(i + 1) % segs], b[(i + 1) % segs], b[i]))
                except ValueError:
                    pass
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        for p in me.polygons:
            p.use_smooth = True
        o = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(o)
        return o
    bottle = lathe(prof, "Bottle")
    s = bottle.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.035
    bottle.data.materials.append(glass_mat((0.95, 0.98, 1.0), 1.45, 0.02))
    liq_prof = [(0.0, -0.9), (0.6, -0.9), (0.67, -0.8), (0.68, -0.35), (0.58, 0.0), (0.0, 0.0)]
    liquid = lathe(liq_prof, "Liquid")
    if milk:
        liquid.data.materials.append(pbr(lin(color), 0, 0.15, "Milk", coat=1.0))
    else:
        lm = glass_mat(lin(color), 1.33, 0.0, "Liquid")
        lb = lm.node_tree.nodes["Principled BSDF"]
        lb.inputs["Emission Color"].default_value = (*lin(color), 1)
        lb.inputs["Emission Strength"].default_value = 0.6
        liquid.data.materials.append(lm)
    cork = lathe([(0.0, 0.7), (0.17, 0.7), (0.19, 1.0), (0.0, 1.0)], "Cork")
    cork.data.materials.append(pbr(lin((0.62, 0.45, 0.3)), 0, 0.85, "Cork"))
    obs = [bottle, liquid, cork]
    for o in obs:
        o.rotation_euler = (math.radians(8), 0, math.radians(-8))
    return obs


def rocky(radius, subdiv, seed, jitter=0.28, name="Rock"):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=radius)
    o = bpy.context.active_object
    r = np.random.default_rng(seed)
    for v in o.data.vertices:
        v.co *= 1 + (r.random() - 0.5) * jitter
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(14), verts=bm.verts, edges=bm.edges)
    bm.to_mesh(o.data); bm.free()
    bev = o.modifiers.new("b", "BEVEL"); bev.width = radius * 0.04; bev.segments = 2
    return o


def ore_object(vein_color, rock=(0.36, 0.34, 0.33), metal=True):
    o = rocky(0.8, 2, 3)
    o.scale = (1.15, 0.9, 0.82)
    m = pbr(lin(rock), 0, 0.82, "Stone")
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bump = nt.nodes.new("ShaderNodeBump")
    n2 = nt.nodes.new("ShaderNodeTexNoise"); n2.inputs["Scale"].default_value = 14; n2.inputs["Detail"].default_value = 8
    nt.links.new(n2.outputs["Fac"], bump.inputs["Height"])
    bump.inputs["Strength"].default_value = 0.5
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    # tint variation
    mixc = nt.nodes.new("ShaderNodeMix"); mixc.data_type = "RGBA"
    mixc.inputs["A"].default_value = (*lin(rock), 1)
    mixc.inputs["B"].default_value = (*lin(tuple(c * 0.6 for c in rock)), 1)
    nt.links.new(n2.outputs["Fac"], mixc.inputs["Factor"])
    nt.links.new(mixc.outputs["Result"], bsdf.inputs["Base Color"])
    o.data.materials.append(m)
    obs = [o]
    vm = pbr(lin(vein_color), 1.0 if metal else 0.0, 0.18 if metal else 0.35, "Vein", coat=0 if metal else 0.6)
    r = np.random.default_rng(11)
    pts = [(-0.45, -0.5, 0.25, 0.26), (0.3, -0.55, 0.05, 0.3), (-0.05, -0.45, -0.35, 0.22), (0.55, -0.3, 0.4, 0.18), (-0.6, -0.25, -0.2, 0.16), (0.05, -0.35, 0.55, 0.17)]
    for i, (x, y, z, rad) in enumerate(pts):
        n = rocky(rad, 1, 20 + i, 0.5)
        n.location = (x, y, z)
        n.rotation_euler = tuple(r.random(3) * 6)
        n.data.materials.append(vm)
        obs.append(n)
    for x in obs:
        x.rotation_euler.x += math.radians(-10)
    return obs


def gel_object(color, eyes=True):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=0.8)
    o = bpy.context.active_object
    for v in o.data.vertices:
        z = v.co.z
        v.co.z = z * 0.72 if z > 0 else z * 0.45
        if z < -0.2:
            v.co.x *= 1.08; v.co.y *= 1.08
    for p in o.data.polygons:
        p.use_smooth = True
    m = bpy.data.materials.new("Gel")
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*lin(color), 1)
    b.inputs["Subsurface Weight"].default_value = 1.0
    b.inputs["Subsurface Radius"].default_value = (0.6, 0.8, 0.6)
    b.inputs["Roughness"].default_value = 0.08
    b.inputs["Coat Weight"].default_value = 1.0
    b.inputs["Transmission Weight"].default_value = 0.35
    o.data.materials.append(m)
    obs = [o]
    if eyes:
        for sx in (-0.25, 0.25):
            bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.09, location=(sx, -0.72, 0.12))
            e = bpy.context.active_object
            e.scale = (0.8, 0.5, 1.3)
            e.data.materials.append(pbr((0.01, 0.01, 0.01), 0, 0.1, "Eye", coat=1))
            obs.append(e)
    for x in obs:
        x.rotation_euler.x += math.radians(-8)
    return obs


def pearl_object():
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=0.62)
    o = bpy.context.active_object
    for p in o.data.polygons:
        p.use_smooth = True
    m = pbr(lin((0.95, 0.93, 0.9)), 0, 0.12, "Pearl", coat=1.0)
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Sheen Weight"].default_value = 1.0
    b.inputs["Sheen Tint"].default_value = (1.0, 0.85, 0.95, 1)
    b.inputs["Subsurface Weight"].default_value = 0.3
    o.data.materials.append(m)
    return [o]


ORES = {"iron_ore": ((0.78, 0.6, 0.5), True), "copper_ore": ((0.95, 0.5, 0.25), True), "silver_ore": ((0.9, 0.92, 0.95), True),
        "gold_ore": ((1.0, 0.78, 0.25), True), "mithril_ore": ((0.55, 0.95, 1.0), True), "coal": ((0.12, 0.12, 0.13), False)}
GEMS = {"ruby_gem": (0.9, 0.08, 0.15), "sapphire_gem": (0.1, 0.25, 0.95), "emerald_gem": (0.05, 0.75, 0.3)}
CRYSTALS = {"ice_crystal": (0.55, 0.85, 1.0), "spirit_ember": (1.0, 0.5, 0.12), "shadow_shard": (0.55, 0.3, 0.95),
            "golem_crystal": (0.25, 0.95, 0.7), "warp_short": (0.4, 0.9, 1.0), "warp_long": (0.75, 0.45, 1.0), "guarantee_stone": (1.0, 0.8, 0.2), "frost_core": (0.6, 0.9, 1.0), "obsidian_shard": (0.25, 0.15, 0.4), "lava_core": (1.0, 0.35, 0.08)}
POTIONS = {"potion_red": ((0.9, 0.06, 0.08), False), "potion_blue": ((0.08, 0.3, 1.0), False), "milk": ((0.97, 0.96, 0.92), True)}
GELS = {"slime_gel": (0.35, 0.85, 0.3), "blue_gel": (0.3, 0.55, 1.0), "royal_gel": (0.7, 0.35, 0.95), "magma_gel": (1.0, 0.4, 0.1)}


def build(item_id):
    if item_id in GEMS:
        return gem_object(GEMS[item_id])
    if item_id in CRYSTALS:
        return crystal_object(CRYSTALS[item_id])
    if item_id in POTIONS:
        c, milk = POTIONS[item_id]
        return potion_object(c, milk)
    if item_id in ORES:
        c, met = ORES[item_id]
        return ore_object(c, metal=met, rock=(0.1, 0.1, 0.11) if item_id == "coal" else (0.36, 0.34, 0.33))
    if item_id in GELS:
        return gel_object(GELS[item_id])
    if item_id == "pearl":
        return pearl_object()
    import hero_models, wear_models
    w = wear_models.build_wear(item_id, os.path.join(SRC, item_id + ".png"))
    if w:
        return w
    hero = hero_models.build_hero(item_id, os.path.join(SRC, item_id + ".png"))
    if hero:
        return hero
    maps = load_maps(os.path.join(SRC, item_id + ".png"))
    if maps is None:
        return []
    ob = relief_object(maps)
    # tilt a touch toward the light so the bevels catch highlights
    ob.rotation_euler = (math.radians(-6), math.radians(8), math.radians(-22))
    return [ob]


def frame(objs):
    # fit the camera to the objects' bounding box
    bpy.context.view_layer.update()
    pts = []
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        oe = o.evaluated_get(dg)
        for c in oe.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    if not pts:
        return
    xs = [p.x for p in pts]; zs = [p.z for p in pts]
    cx, cz = (max(xs) + min(xs)) / 2, (max(zs) + min(zs)) / 2
    span = max(max(xs) - min(xs), max(zs) - min(zs))
    cam = bpy.context.scene.camera
    cam.location = (cx, -10, cz)
    cam.data.ortho_scale = span * 1.12


def render(item_id):
    reset_scene()
    objs = build(item_id)
    if not objs:
        return False
    frame(objs)
    sc = bpy.context.scene
    sc.render.filepath = os.path.join(OUT, item_id + ".png")
    bpy.ops.render.render(write_still=True)
    return True


if __name__ == "__main__":
    ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    import traceback
    for i in ids:
        try:
            ok = render(i)
        except Exception:
            traceback.print_exc(); ok = False
        print("rendered", i, ok, flush=True)
