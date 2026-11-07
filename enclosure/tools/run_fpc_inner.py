#!/usr/bin/env python3
"""Can a flat flexible (FPC) antenna lie on the INNER surface of the lid, the front wall or a side wall, instead of beside the boards?

Checks in 3D, with the real extents of every metal part (cell foil 10 mm; every other metal part, board and wire lane 5 mm).
Shapes tried: (a) flat rectangle on the lid or on the front-wall inner surface, both orientations;
              (b) one gentle bend: a strip along a wall (length along the wall), part of its width on the wall, a quarter-circle bend of radius R,
                  the rest of the width flat on the lid or the front wall.
It then grows the body (+X wall and +Y wall move out, nothing else moves) and reports the smallest body that works.

Usage: python3 tools/run_fpc_inner.py [--l 50 --w 14 --t 0.3 --r 3]
The layout used is the build with the antenna taken out of the board layer (as with ant_place="tab_y": switch above the camera)."""
import argparse, math, os, re, subprocess, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(os.path.dirname(HERE), 'powerbank70.scad')
DEFS = ['-D', 'part="none"', '-D', 'enforce_limits=false', '-D', 'ant_place="tab_y"', '-D', 'ant_type="stick"', '-D', 'ant_l=50', '-D', 'ant_w=14',
        '-D', 'ant_t=0.3', '-D', 'ant_cable_len=150', '-D', 'tab_budget=100']
DUMMIES = ['cell_dummy', 'ntc_dummy', 'xiao_dummy', 'bq_dummy', 'mx_dummy', 'camera_dummy', 'switch_dummy', 'tact_dummy']


def bbox(stl):
    xs, ys, zs = [], [], []
    for line in open(stl):
        t = line.split()
        if t and t[0] == 'vertex':
            xs.append(float(t[1])); ys.append(float(t[2])); zs.append(float(t[3]))
    return [min(xs), min(ys), min(zs), max(xs), max(ys), max(zs)]


def load():
    d = tempfile.mkdtemp()
    metals = []
    for n in DUMMIES:
        p = os.path.join(d, n + '.scad')
        open(p, 'w').write('include <%s>\n%s();\n' % (SCAD, n))
        subprocess.run(['openscad', '-o', os.path.join(d, n + '.stl')] + DEFS + [p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        metals.append((n, bbox(os.path.join(d, n + '.stl')), 10.0 if n == 'cell_dummy' else 5.0))
    p = os.path.join(d, 'info.scad')
    open(p, 'w').write('include <%s>\necho(info=[L, W, Zi0, Zw, wall]);\necho(lanes=lane_boxes());\n' % SCAD)
    subprocess.run(['openscad', '-o', os.path.join(d, 'i.echo')] + DEFS + [p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    t = open(os.path.join(d, 'i.echo')).read()
    info = [float(x) for x in re.search(r'info = \[([^\]]*)\]', t).group(1).split(',')]
    lanes = re.search(r'lanes = (\[\[.*\]\])', t).group(1)
    for i, b in enumerate(eval(lanes)):
        metals.append(('lane%d' % i, [b[0], b[1], b[2], b[3], b[4], b[5]], 5.0))
    return metals, info


def gap(a, b):  # 3D distance between two axis-aligned boxes (x0, y0, z0, x1, y1, z1)
    s = 0.0
    for k in range(3):
        g = max(a[k] - b[k + 3], b[k] - a[k + 3], 0.0)
        s += g * g
    return math.sqrt(s)


def worst(shape, metals):
    """smallest margin (distance - required) of the shape over all metal; also names the part that decides"""
    m, who = 1e9, ''
    for n, b, req in metals:
        for box in shape:
            v = gap(box, b) - req
            if v < m:
                m, who = v, n
    return m, who


def shapes(L, W, zi, zw, wall, al, aw, at, r):
    """yield (label, boxes) for every placement tried; coordinates in mm, outer frame"""
    x0, x1, y0, y1 = wall, L - wall, wall, W - wall
    out = []
    for surf, z0 in (('lid', zi), ('front wall', zw - at)):
        for (lx, ly) in ((al, aw), (aw, al)):
            x = x0
            while x + lx <= x1 + 1e-9:
                y = y0
                while y + ly <= y1 + 1e-9:
                    out.append(('flat on the %s %gx%g at x %.1f y %.1f' % (surf, lx, ly, x, y), [[x, y, z0, x + lx, y + ly, z0 + at]]))
                    y += 2.0
                x += 2.0
    H = zw - zi
    for surf in ('lid', 'front wall'):
        for wallname in ('+Y', '-Y', '+X', '-X'):
            along0, along1 = (x0, x1) if wallname in ('+Y', '-Y') else (y0, y1)
            a = 0.0
            while a <= H - r + 1e-9:
                b = aw - a - math.pi * r / 2
                if b >= -1e-9:
                    s = along0
                    while s + al <= along1 + 1e-9:
                        bx = []
                        # wall strip (thin box on the wall), z span depends on the surface
                        if surf == 'lid':
                            zlo, zhi = zi + r, zi + r + a            # wall part runs up from the bend
                            zf0, zf1 = zi, zi + at                    # floor part
                        else:
                            zlo, zhi = zw - r - a, zw - r
                            zf0, zf1 = zw - at, zw
                        d_wall = {'+Y': (None, y1 - at, None, y1), '-Y': (None, y0, None, y0 + at), '+X': (x1 - at, None, x1, None), '-X': (x0, None, x0 + at, None)}[wallname]
                        def box(px0, py0, px1, py1, z0, z1):
                            if wallname in ('+Y', '-Y'):
                                return [s, py0, z0, s + al, py1, z1]
                            return [px0, s, z0, px1, s + al, z1]
                        if wallname == '+Y':
                            wall_b = box(0, y1 - at, 0, y1, zlo, max(zhi, zlo + at)); arc_b = box(0, y1 - r, 0, y1, zf0 if surf == 'lid' else zw - r, zf0 + r if surf == 'lid' else zw); fl_b = box(0, y1 - r - max(b, 0), 0, y1 - r, zf0, zf1)
                        elif wallname == '-Y':
                            wall_b = box(0, y0, 0, y0 + at, zlo, max(zhi, zlo + at)); arc_b = box(0, y0, 0, y0 + r, zf0 if surf == 'lid' else zw - r, zf0 + r if surf == 'lid' else zw); fl_b = box(0, y0 + r, 0, y0 + r + max(b, 0), zf0, zf1)
                        elif wallname == '+X':
                            wall_b = box(x1 - at, 0, x1, 0, zlo, max(zhi, zlo + at)); arc_b = box(x1 - r, 0, x1, 0, zf0 if surf == 'lid' else zw - r, zf0 + r if surf == 'lid' else zw); fl_b = box(x1 - r - max(b, 0), 0, x1 - r, 0, zf0, zf1)
                        else:
                            wall_b = box(x0, 0, x0 + at, 0, zlo, max(zhi, zlo + at)); arc_b = box(x0, 0, x0 + r, 0, zf0 if surf == 'lid' else zw - r, zf0 + r if surf == 'lid' else zw); fl_b = box(x0 + r, 0, x0 + r + max(b, 0), 0, zf0, zf1)
                        out.append(('bent on the %s wall, %g mm on the wall + R%g bend + %.1f mm on the %s, along %.0f..%.0f' % (wallname, a, r, max(b, 0), surf, s, s + al), [wall_b, arc_b, fl_b]))
                        s += 2.0
                a += 0.5
    return out


def best(L, W, metals, info, al, aw, at, r):
    zi, zw, wall = info[2], info[3], info[4]
    res = (-1e9, '', '')
    for label, boxes in shapes(L, W, zi, zw, wall, al, aw, at, r):
        m, who = worst(boxes, metals)
        if m > res[0]:
            res = (m, label, who)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--l', type=float, default=50); ap.add_argument('--w', type=float, default=14)
    ap.add_argument('--t', type=float, default=0.3); ap.add_argument('--r', type=float, default=3.0)
    a = ap.parse_args()
    metals, info = load()
    L0, W0 = info[0], info[1]
    print('FPC %gx%gx%g mm, bend radius %g mm, on the inner surface of the lid / front wall / a side wall' % (a.l, a.w, a.t, a.r))
    print('rules: >= 10 mm (3D) from the cell foil, >= 5 mm from every other metal part, board and wire lane')
    print('body without the antenna in the board layer: %.2f x %.2f x 11.78 (worst-case printed limit 100 x 70: L <= 99.8, W <= 69.8)\n' % (L0, W0))
    m, label, who = best(L0, W0, metals, info, a.l, a.w, a.t, a.r)
    print('A) in the 70 x 100 body: best placement found: %s' % label)
    print('   margin %+.2f mm (>= 0 passes), decided by %s -> %s\n' % (m, who, 'PASS' if m >= 0 else 'FAIL'))
    print('B) smallest body that works (the +X and +Y walls move out; nothing else moves):')
    found = []
    for W in [W0 + 0.5 * i for i in range(0, 60)]:
        for L in [L0 + 1.0 * i for i in range(0, 41)]:
            m, label, who = best(L, W, metals, info, a.l, a.w, a.t, a.r)
            if m >= 0:
                found.append((L * W, L, W, label))
                break
    if found:
        found.sort()
        for area, L, W, label in found[:3]:
            print('   %.1f x %.1f (area %.0f): %s' % (L, W, area, label))
    else:
        print('   none up to W %.1f / L %.1f' % (W0 + 29.5, L0 + 40))


if __name__ == '__main__':
    main()
