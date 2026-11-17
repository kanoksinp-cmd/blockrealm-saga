"""Export the realistic icon models (same Blender builders as the HD inventory
icons) as light-weight GLB meshes for the weapons characters hold in game.

Material parameters are baked into vertex data so one shared shader can draw
every weapon:  COLOR_0 = linear base colour,
               TEXCOORD_0 = (emission, glass),  TEXCOORD_1 = (metallic, roughness).
Every model is posed upright (+Y in glTF), with the grip at the origin."""
import sys, os, math, json
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import bpy
import bmesh
from mathutils import Vector, Matrix

import blender_icons as BI
import hero_models as HM

SRC = "/home/claude/wpn/src_icons"
OUT = "/home/claude/wpn/glb"
BI.SRC = SRC
os.makedirs(OUT, exist_ok=True)

# overall length along the weapon (glTF +Y) in game metres, and the grip
# position as a fraction of the height measured from the bottom
LEN = {"sword": 1.1, "greatsword": 1.45, "scimitar": 1.1, "dagger": 0.72, "katar": 0.66,
       "axe": 1.25, "hammer": 1.25, "mace": 1.15, "staff": 1.5, "bow": 1.15,
       "shield_round": 0.52, "shield_kite": 0.74, "shield_tower": 0.8,
       "spear": 1.62, "whip": 0.9, "book": 0.44, "knuckle": 0.3, "lute": 0.66, "relief_staff": 1.3}
GRIP = {"spear": 0.38, "whip": 0.1, "book": 0.5, "knuckle": 0.5, "lute": 0.5, "relief_staff": 0.3}
TRI_BUDGET = 1800
THICK = {"spear": 0.07, "whip": 0.06, "book": 0.09, "lute": 0.14, "relief_staff": 0.13}


def relief_kind(wtype):
    return {"spear": "spear", "whip": "whip", "book": "book", "knuckle": "knuckle",
            "instrument": "lute", "staff": "relief_staff"}.get(wtype, "relief_staff")


# ------------------------------------------------------------------ material -> params
def _principled(m):
    if m is None or not m.use_nodes:
        return None
    for n in m.node_tree.nodes:
        if n.type == "BSDF_PRINCIPLED":
            return n
    return None


def _src_node(inp):
    return inp.links[0].from_node if inp.is_linked else None


def mat_params(m):
    """-> dict(base=(r,g,b) linear, metal, rough, emit, glass) or dict(tex=...) for image driven."""
    b = _principled(m)
    if b is None:
        return dict(base=(0.6, 0.6, 0.6), metal=0.0, rough=0.6, emit=0.0, glass=0.0)
    bc = b.inputs["Base Color"]
    src = _src_node(bc)
    tex = None
    if src is not None and src.type == "TEX_IMAGE":
        tex = src.image
        base = (0.6, 0.6, 0.6)
    elif src is not None and src.type == "MIX":          # wood rings: mix of col and 0.55*col
        a = next(i for i in src.inputs if i.identifier == "A_Color").default_value
        base = tuple(a[i] * 0.82 for i in range(3))
    else:
        base = tuple(bc.default_value[:3])
    metal = b.inputs["Metallic"].default_value
    rough = b.inputs["Roughness"].default_value
    glass = b.inputs["Transmission Weight"].default_value
    coat = b.inputs["Coat Weight"].default_value
    emit = 0.0
    ec = b.inputs["Emission Color"]
    if not ec.is_linked and max(ec.default_value[:3]) > 0.001:
        emit = b.inputs["Emission Strength"].default_value
    d = dict(base=base, metal=float(metal), rough=float(rough), emit=float(emit), glass=float(glass), coat=float(coat))
    if tex is not None:
        imgs = {}
        for name in ("col", "met", "rou", "em"):
            for im in bpy.data.images:
                if im.name.split(".")[0] == name:
                    imgs[name] = im
        d["tex"] = imgs
    return d


def _img_array(im):
    w, h = im.size
    a = np.empty(w * h * 4, np.float32)
    im.pixels.foreach_get(a)
    return a.reshape(h, w, 4)


# ------------------------------------------------------------------ bake + merge
def bake_object(o, dg):
    """Evaluated copy of `o` as a mesh object in world space with params in vertex data."""
    oe = o.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(oe, preserve_all_data_layers=True, depsgraph=dg)
    me.transform(o.matrix_world)
    if o.matrix_world.determinant() < 0:
        me.flip_normals()
    mats = [s.material for s in o.material_slots] or [None]
    params = [mat_params(m) for m in mats]
    nl = len(me.loops)
    col = np.zeros((nl, 4), np.float32); col[:, 3] = 1
    uv0 = np.zeros((nl, 2), np.float32)
    uv1 = np.zeros((nl, 2), np.float32)
    src_uv = None
    if me.uv_layers:
        src_uv = np.zeros(nl * 2, np.float32)
        me.uv_layers[0].data.foreach_get("uv", src_uv)
        src_uv = src_uv.reshape(nl, 2)
    poly_mat = np.zeros(len(me.polygons), int)
    me.polygons.foreach_get("material_index", poly_mat)
    loop_start = np.zeros(len(me.polygons), int); me.polygons.foreach_get("loop_start", loop_start)
    loop_tot = np.zeros(len(me.polygons), int); me.polygons.foreach_get("loop_total", loop_tot)
    loop_mat = np.repeat(np.clip(poly_mat, 0, len(params) - 1), loop_tot)
    for mi, p in enumerate(params):
        sel = loop_mat == mi
        if not sel.any():
            continue
        if "tex" in p and src_uv is not None and "col" in p["tex"]:
            t = p["tex"]
            c = _img_array(t["col"])
            H, W = c.shape[:2]
            u = np.clip((src_uv[sel, 0] * W).astype(int), 0, W - 1)
            v = np.clip((src_uv[sel, 1] * H).astype(int), 0, H - 1)
            col[sel, :3] = c[v, u, :3]
            met = _img_array(t["met"])[v, u, 0] if "met" in t else np.zeros(sel.sum())
            rou = _img_array(t["rou"])[v, u, 0] if "rou" in t else np.full(sel.sum(), 0.5)
            em = _img_array(t["em"])[v, u, :3].max(1) if "em" in t else np.zeros(sel.sum())
            uv1[sel, 0] = met; uv1[sel, 1] = rou
            uv0[sel, 0] = np.clip(em * 1.6, 0, 1)
        else:
            col[sel, :3] = p["base"]
            uv1[sel, 0] = p["metal"]; uv1[sel, 1] = p["rough"]
            uv0[sel, 0] = min(1.0, p["emit"] / 3.0)
            # 0 = plain, 0..0.5 = clear-coat amount, 1 = glass / gem
            uv0[sel, 1] = 1.0 if p["glass"] > 0.5 else min(0.5, p.get("coat", 0.0) * 0.5)
    for l in list(me.uv_layers):
        me.uv_layers.remove(l)
    for a in list(me.color_attributes):
        me.color_attributes.remove(a)
    col[:, :3] = np.clip(col[:, :3], 0, 1) ** (1 / 2.2)     # stored as sRGB
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    ca.data.foreach_set("color", col.ravel())
    me.color_attributes.active_color = ca
    uv0[:, 1] = 1 - uv0[:, 1]          # glTF export flips V
    uv1[:, 1] = 1 - uv1[:, 1]
    l0 = me.uv_layers.new(name="Fx"); l0.data.foreach_set("uv", uv0.ravel())
    l1 = me.uv_layers.new(name="Pbr"); l1.data.foreach_set("uv", uv1.ravel())
    me.materials.clear()
    ob = bpy.data.objects.new(o.name + "_baked", me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def tri_count(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def decimate(ob, budget):
    t = tri_count(ob)
    if t <= budget:
        return
    mod = ob.modifiers.new("dec", "DECIMATE")
    mod.ratio = budget / t
    mod.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.select_set(False)


def knuckle_parts(pal):
    """Spiked knuckle-duster like the inventory icon: four rings, spiked bar, leather grip."""
    obs = []
    metal = HM.mat_metal(pal["metal"] if pal["metal_frac"] > 0.1 else (0.8, 0.82, 0.86), 0.16)
    for i in range(4):
        x = -0.33 + i * 0.22
        bpy.ops.mesh.primitive_torus_add(major_radius=0.1, minor_radius=0.032, major_segments=24, minor_segments=10,
                                         location=(x, 0, 0), rotation=(math.radians(90), 0, 0))
        t = bpy.context.active_object
        for p in t.data.polygons:
            p.use_smooth = True
        HM.apply(t, metal); obs.append(t)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.038, depth=0.92, location=(0, 0, 0.13), rotation=(0, math.radians(90), 0))
    bar = bpy.context.active_object
    for p in bar.data.polygons:
        p.use_smooth = True
    HM.apply(bar, metal); obs.append(bar)
    for i in range(4):
        x = -0.33 + i * 0.22
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.045, radius2=0.0, depth=0.2, location=(x, 0, 0.25))
        c = bpy.context.active_object
        HM.apply(c, metal); obs.append(c)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.02, 0, -0.17))
    g = bpy.context.active_object
    g.scale = (0.86, 0.1, 0.09)
    g.rotation_euler = (0, math.radians(-4), 0)
    bev = g.modifiers.new("b", "BEVEL"); bev.width = 0.035; bev.segments = 3
    HM.apply(g, HM.mat_leather(pal["wood"] if pal["wood"] else (0.45, 0.28, 0.16)))
    obs.append(g)
    return obs


def build(item_id, wtype):
    BI.reset_scene()
    for o in list(bpy.context.scene.objects):        # drop camera/lights/softboxes
        bpy.data.objects.remove(o, do_unlink=True)
    HM.CUR_ID = item_id
    kind = HM.kind_of(item_id)
    if item_id.endswith("_lute"):
        kind = None                                   # "silverstring" is not a ring
    path = os.path.join(SRC, item_id + ".png")
    if wtype == "knuckle":
        return "knuckle", knuckle_parts(HM.palette(path))
    if kind is not None:
        objs = HM.build_hero(item_id, path)
        for o in bpy.context.scene.objects:
            if o.type == "EMPTY":
                o.rotation_euler = (0, 0, 0)            # keep the model upright, not the icon pose
        return kind, [o for o in objs if o.type in ("MESH", "CURVE")]
    maps = BI.load_maps(path, W=288)
    ob = BI.relief_object(maps)
    return relief_kind(wtype), [ob]


def grip_point(kind, objs_bb):
    (x0, y0, z0), (x1, y1, z1) = objs_bb
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    if kind in ("sword", "greatsword", "scimitar", "dagger", "katar"):
        gl = {"sword": 0.38, "greatsword": 0.55, "dagger": 0.28, "katar": 0.26, "scimitar": 0.36}[kind]
        return Vector((0, 0, -0.07 - gl * 0.45))
    if kind in ("axe", "hammer", "mace"):
        return Vector((0, 0, -0.62))
    if kind == "staff":
        return Vector((0, 0, -0.2))
    if kind == "bow":
        return Vector((0.34, 0, 0))
    if kind.startswith("shield"):
        return Vector((cx, cy, (z0 + z1) / 2))
    f = GRIP.get(kind, 0.5)
    return Vector((cx, cy, z0 + (z1 - z0) * f))


def export(item_id, wtype):
    kind, objs = build(item_id, wtype)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    baked = [bake_object(o, dg) for o in objs]
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)
    for o in list(bpy.context.scene.objects):
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    total = sum(tri_count(o) for o in baked)
    for o in baked:
        decimate(o, max(60, int(TRI_BUDGET * tri_count(o) / max(1, total))))
    bpy.ops.object.select_all(action="DESELECT")
    for o in baked:
        o.select_set(True)
    bpy.context.view_layer.objects.active = baked[0]
    if len(baked) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    me = ob.data
    co = np.zeros(len(me.vertices) * 3, np.float32); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    bb = (co.min(0), co.max(0))
    g = grip_point(kind, bb)
    ext = bb[1] - bb[0]
    if kind == "knuckle":
        span = max(ext[0], ext[2])
    elif kind == "bow":
        span = ext[2]
    else:
        span = ext[2]
    s = LEN[kind] / max(span, 1e-4)
    me.transform(Matrix.Scale(s, 4) @ Matrix.Translation(-g))
    # relief slabs keep the thickness of the whole icon; thin them to the object's own size
    if kind in THICK and ext[1] * s > THICK[kind]:
        me.transform(Matrix.Diagonal((1.0, THICK[kind] / (ext[1] * s), 1.0, 1.0)))
        ext = ext.copy(); ext[1] = THICK[kind] / s
    me.update()
    ob.name = item_id
    me.name = item_id
    path = os.path.join(OUT, item_id + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
                              export_apply=True, export_materials="NONE",
                              export_vertex_color="ACTIVE", export_all_vertex_colors=False,
                              export_texcoords=True, export_normals=True, export_yup=True)
    return kind, tri_count(ob), [float(x) for x in ext * s]


if __name__ == "__main__":
    items = [l.split("|") for l in open("/home/claude/wpn/items.txt").read().split("\n") if l]
    only = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    report = {}
    for row in items:
        iid, wtype = row[0], row[1]
        if only and iid not in only:
            continue
        try:
            kind, tris, size = export(iid, wtype)
            report[iid] = {"kind": kind, "tris": tris, "size": size}
            print("OK", iid, kind, tris, [round(x, 2) for x in size], flush=True)
        except Exception as e:
            import traceback; traceback.print_exc()
            print("FAIL", iid, e, flush=True)
    old = {}
    rp = os.path.join(OUT, "report.json")
    if os.path.exists(rp):
        old = json.load(open(rp))
    old.update(report)
    json.dump(old, open(rp, "w"), indent=1)
