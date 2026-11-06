#!/usr/bin/env python3
"""Antenna tab study for powerbank70.scad.

For every antenna it evaluates the antenna inside the body (the body grows) and in a tab on the +X end or the +Y side, in both
orientations, with the tab position chosen automatically (smallest tab). It prints, per case, the total outer size, the extra length / width
over the 100 x 70 mm limits, the metal that decides the position, and PASS or the first failing assert.

PASS means: every assert passes with the limits enforced (main body <= 100 x 70 x 12 at worst-case print size, tab adds <= tab_budget).

Usage:  python3 tools/run_tab_study.py [--cell 603450] [--budget 10] [--all]
        --all prints every orientation; the default prints the best tab per side.
Edit ANTENNAS to add real parts: (name, type, length, width, thickness, cable_len)."""
import argparse, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(os.path.dirname(HERE), 'powerbank70.scad')

CELLS = {  # code: (thickness, width, length), standard-code nominal sizes, NOT verified listings
    '603450': (6.0, 34.0, 50.0), '603450max': (6.0, 34.5, 52.0), '503450': (5.0, 34.0, 50.0),
}
# name, type, length, width, thickness, cable. The five sizes are the ones you asked for (none matched a datasheet part).
# The last two are real datasheet parts for reference: Linx ANT-2.4-FPC-SH 25.4 x 20.1 x 0.1 (85 % efficiency, 4.0 dBi peak),
# Molex 206994 15.4 x 6.4 x 0.15 (about 3.6 dBi; dual-band flexible antenna).
ANTENNAS = [
    ('ceramic 13x5 (baseline)', 'ceramic', 13, 5, 1.0, 150),
    ('stick 25x6', 'stick', 25, 6, 0.2, 150),
    ('stick 40x8', 'stick', 40, 8, 0.2, 150),
    ('stick 42x12', 'stick', 42, 12, 0.2, 150),
    ('stick 45x7', 'stick', 45, 7, 0.2, 150),
    ('stick 39x19', 'stick', 39, 19, 0.2, 150),
    ('Linx SH 25.4x20.1 (datasheet)', 'stick', 25.4, 20.1, 0.1, 150),
    ('Molex 206994 15.4x6.4 (datasheet)', 'stick', 15.4, 6.4, 0.15, 150),
]
MODES = [('inside', 0), ('tab_x', 90), ('tab_x', 0), ('tab_y', 0), ('tab_y', 90)]
# the body can grow in two layouts (switch + button in the band above the cell, or in the corner beside it): both are tried


def run(defs, enforce):
    out = tempfile.NamedTemporaryFile(suffix='.echo', delete=False).name
    cmd = ['openscad', '-o', out, '-D', 'enforce_limits=%s' % ('true' if enforce else 'false')]
    for k, v in defs.items():
        cmd += ['-D', '%s=%s' % (k, v)]
    subprocess.run(cmd + [SCAD], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    txt = open(out).read()
    os.unlink(out)
    return txt


def evaluate(cell, ant, place, rot, budget):
    if place == 'inside':
        rs = [evaluate1(cell, ant, place, rot, budget, sp) for sp in ('band', 'corner')]
        rs = [r for r in rs if r['total']] or rs
        return min(rs, key=lambda r: (not r['ok'], r['total'][0] * r['total'][1] if r['total'] else 1e9))
    return evaluate1(cell, ant, place, rot, budget, 'auto')


def evaluate1(cell, ant, place, rot, budget, smalls):
    n, t, l, w, th, cab = ant
    t_, w_, l_ = CELLS[cell]
    d = {'cell_code': '"%s"' % cell, 'cell_t': t_, 'cell_w': w_, 'cell_l': l_, 'ant_type': '"%s"' % t, 'ant_l': l, 'ant_w': w,
         'ant_t': th, 'ant_cable_len': cab, 'ant_place': '"%s"' % place, 'ant_rot': rot, 'tab_budget': budget,
         'smalls_place': '"%s"' % smalls}
    if place == 'inside':      # growing the body is an extension on one end: judge it against the same budget as a tab.
        d['max_L'], d['max_W'] = 100 + budget, 70 + budget      # (the layout itself depends on max_L: a free corner beside the cell takes the switch)
    free = run(d, False)
    m = re.search(r'TOTAL OUTER SIZE incl\. tab: ([\d.]+) x ([\d.]+) x ([\d.]+) mm +main body ([\d.]+) x ([\d.]+)', free)
    if not m:
        # an assert that does not depend on the limits failed (e.g. the antenna does not fit its edge)
        e = re.search(r'failed: "?([^"\n]*)', free)
        return dict(ok=False, msg=(e.group(1)[:80] if e else 'no output'), total=None)
    pos = re.search(r'box x ([\d.]+)\.\.([\d.]+) y ([\d.]+)\.\.([\d.]+)(?:, binding metal: ([^"]*))?', free)
    cable = re.search(r'antenna box = ([\d.]+) mm', free)
    lim = run(d, True)
    e = re.search(r'ERROR: Assertion[^\n]*?failed: "?([^"\n]*?)"? in file', lim)
    return dict(ok=e is None, msg=(e.group(1)[:70] if e else ''), total=(float(m.group(1)), float(m.group(2))),
                main=(float(m.group(4)), float(m.group(5))), extra=(max(0.0, float(m.group(1)) - 100), max(0.0, float(m.group(2)) - 70)),
                box=tuple(float(x) for x in pos.groups()[:4]), who=(pos.group(5) or '').strip(), cable=float(cable.group(1)) if cable else 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--cell', default='603450')
    ap.add_argument('--budget', type=float, default=10.0)
    ap.add_argument('--all', action='store_true')
    a = ap.parse_args()
    print('cell %s %s (thickness, width, length), tab budget %.1f mm, limits 100 x 70 x 12 at worst-case printed size' % (a.cell, CELLS[a.cell], a.budget))
    print('%-34s %-14s %-17s %-13s %-9s %-9s %-14s %s' % ('antenna', 'placement', 'total L x W', 'extra L', 'extra W', 'cable>=', 'decided by', 'result'))
    for ant in ANTENNAS:
        res = []
        for place, rot in MODES:
            r = evaluate(a.cell, ant, place, rot, a.budget)
            r['place'], r['rot'] = place, rot
            res.append(r)
        good = [r for r in res if r['total'] and r['place'] != 'inside']
        best = {}
        for side in ('tab_x', 'tab_y'):
            c = [r for r in good if r['place'] == side]
            if c:
                best[side] = min(c, key=lambda r: (not r['ok'], max(r['extra']), r['total'][0] * r['total'][1]))
        show = res if a.all else [r for r in res if r['place'] == 'inside'] + [best[s] for s in ('tab_x', 'tab_y') if s in best]
        for r in show:
            if not r['total']:
                print('%-34s %-14s %s' % (ant[0], '%s r%d' % (r['place'], r['rot']), 'cannot be placed: ' + r['msg']))
                continue
            print('%-34s %-14s %-17s %-13s %-9s %-9s %-14s %s' % (ant[0], '%s r%d' % (r['place'], r['rot']), '%.2f x %.2f' % r['total'],
                  '%.2f' % r['extra'][0], '%.2f' % r['extra'][1], '%.0f' % r['cable'], r['who'][:14], 'PASS' if r['ok'] else 'fail: ' + r['msg']))
        print()


if __name__ == '__main__':
    main()
