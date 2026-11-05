#!/usr/bin/env python3
"""Build a patched pack from ~/proj/scripts.

usage: build2.py <base.pck> <out.pck> [extra_patch_dir]
 - scripts that are .gdc in the base pack are recompiled (binary tokens) via ~/gdtest
 - scripts that are plain .gd in the base pack, or new, are stored as plain text
Only files that differ from the base pack are replaced.
"""
import os, sys, shutil, subprocess, filecmp
sys.path.insert(0, '/root/tools')
import pck

base, out = sys.argv[1], sys.argv[2]
extra = sys.argv[3] if len(sys.argv) > 3 else None
A, _, fa = pck.read(base)
entries = {n: A[o:o + s] for n, o, s, f in fa}
proj = '/root/proj/scripts'
patch = '/root/b2patch'
shutil.rmtree(patch, ignore_errors=True)
os.makedirs(patch)
to_compile = []
for dp, dn, fn in os.walk(proj):
    for f in fn:
        if not f.endswith('.gd'):
            continue
        full = os.path.join(dp, f)
        rel = 'scripts/' + os.path.relpath(full, proj)
        data = open(full, 'rb').read()
        if rel + 'c' in entries:
            to_compile.append(rel)
        elif rel in entries and entries[rel] == data:
            continue
        else:
            p = os.path.join(patch, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, 'wb').write(data)
            print('plain', rel)
if to_compile:
    g = '/root/gdtest'
    shutil.rmtree(g + '/scripts', ignore_errors=True)
    shutil.rmtree(g + '/.godot', ignore_errors=True)
    if os.path.exists(g + '/out.pck'):
        os.remove(g + '/out.pck')
    for rel in to_compile:
        p = os.path.join(g, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        shutil.copy(os.path.join('/root/proj', rel), p)
    r = subprocess.run(['timeout', '300', '/root/tools/Godot_v4.7.2-stable_linux.x86_64', '--headless', '--export-pack', 'Linux', 'out.pck'],
                       cwd=g, capture_output=True, text=True, env=dict(os.environ, HOME='/tmp/gh'))
    errs = [l for l in (r.stdout + r.stderr).splitlines() if 'error' in l.lower()]
    if errs:
        print('\n'.join(errs[:10]))
    B, _, fb = pck.read(g + '/out.pck')
    got = {n: B[o:o + s] for n, o, s, f in fb}
    for rel in to_compile:
        c = got.get(rel + 'c')
        if c is None:
            print('MISSING compiled', rel); sys.exit(1)
        if c != entries[rel + 'c']:
            p = os.path.join(patch, rel + 'c')
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, 'wb').write(c)
            print('compiled', rel)
if extra:
    subprocess.run(['cp', '-r', extra + '/.', patch])
r = subprocess.run(['python3', '/root/tools/repack_dir.py', base, patch, out], capture_output=True, text=True)
print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr)
