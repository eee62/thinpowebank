#!/usr/bin/env python3
"""Plan B: grow the WHOLE body as a clean rectangle to hold a stick-on antenna inside (no tab, no bump).

For each antenna it tries both orientations and both switch / button layouts (in the band above the cell, or in the corner beside it),
with every antenna rule enforced (5 mm from metal, 10 mm from the cell foil, 3 mm from plastic), and prints the outer size of each.
The smallest area is the answer. The limits are lifted for this study only (they are the thing being exceeded).

Usage:  python3 tools/run_planb.py [--style rounded|sharp]
Edit ANTENNAS to add a real part: (name, length, width, thickness)."""
import argparse, os, re, subprocess, tempfile

SCAD = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'powerbank70.scad')
ANTENNAS = [
    ('ceramic 13x5 (default, for reference)', 13, 5, 1.0),
    ('Molex-206994-class 15.4x6.4', 15.4, 6.4, 0.15),
    ('stick-on 25x6', 25, 6, 0.2),
]


def tol(x):
    return 0.2 if x < 100 else 0.003 * x


def size(ant, rot, smalls, style):
    n, l, w, t = ant
    out = tempfile.NamedTemporaryFile(suffix='.echo', delete=False).name
    cmd = ['openscad', '-o', out, '-D', 'enforce_limits=false', '-D', 'style="%s"' % style, '-D', 'ant_type="stick"', '-D', 'ant_l=%s' % l,
           '-D', 'ant_w=%s' % w, '-D', 'ant_t=%s' % t, '-D', 'ant_cable_len=150', '-D', 'ant_rot=%d' % rot, '-D', 'smalls_place="%s"' % smalls, SCAD]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    txt = open(out).read()
    os.unlink(out)
    m = re.search(r'OUTER SIZE .*?L x W x T = ([\d.]+) x ([\d.]+) x ([\d.]+)', txt)
    # any assert other than the (lifted) size limits is a real failure of an antenna rule
    errs = [e for e in re.findall(r'failed: "?([^"\n]*?)"? in file', txt)]
    return (float(m.group(1)), float(m.group(2))) if m and not errs else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--style', default='rounded')
    a = ap.parse_args()
    print('Plan B study, 603450 cell, %s style. Outer L x W in mm (T = 11.78); worst case printed = nominal + JLC tolerance.' % a.style)
    print('%-38s %-6s %-7s %-17s %-10s %-20s' % ('antenna', 'rot', 'smalls', 'outer L x W', 'area mm2', 'worst case printed'))
    for ant in ANTENNAS:
        rows = []
        for rot in (0, 90):
            for sm in ('band', 'corner'):
                s = size(ant, rot, sm, a.style)
                if s:
                    rows.append((s[0] * s[1], rot, sm, s))
        rows.sort()
        for i, (area, rot, sm, s) in enumerate(rows):
            print('%-38s %-6d %-7s %-17s %-10.0f %-20s %s' % (ant[0], rot, sm, '%.3f x %.3f' % s, area,
                  '%.2f x %.2f' % (s[0] + tol(s[0]), s[1] + tol(s[1])), '<- smallest' if i == 0 else ''))
        print()


if __name__ == '__main__':
    main()
