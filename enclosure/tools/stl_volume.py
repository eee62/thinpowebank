#!/usr/bin/env python3
"""Print the enclosed volume (mm^3) and triangle count of an ASCII or binary STL.
Used by run_checks.sh: an intersection that is empty or only a touching face has ~0 volume."""
import struct, sys

def triangles(path):
    data = open(path, 'rb').read()
    if data[:5] == b'solid' and b'facet' in data[:1000]:
        tri = []
        for line in data.decode('ascii', 'replace').splitlines():
            t = line.split()
            if t and t[0] == 'vertex':
                tri.append(tuple(map(float, t[1:4])))
                if len(tri) == 3:
                    yield tri; tri = []
    else:
        n = struct.unpack('<I', data[80:84])[0]
        for i in range(n):
            v = struct.unpack('<12f', data[84 + 50*i: 84 + 50*i + 48])
            yield [v[3:6], v[6:9], v[9:12]]

vol, n = 0.0, 0
for a, b, c in triangles(sys.argv[1]):
    vol += (a[0]*(b[1]*c[2]-b[2]*c[1]) - a[1]*(b[0]*c[2]-b[2]*c[0]) + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6.0
    n += 1
print(f"{abs(vol):.6f} {n}")
