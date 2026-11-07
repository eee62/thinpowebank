#!/usr/bin/env python3
"""Lumped steady-state thermal estimate for the SEALED shell (no vents or slots). ESTIMATE, not a measurement.

Shell temperature rise = P / (h * A), A = outside area of the box without the face lying on the desk.
Inputs that are ASSUMPTIONS are marked (A). Sources are in the README ("Heat in the sealed shell").
Usage: python3 tools/thermal_estimate.py [L W T]   (defaults: the v3 build 95.73 x 73.0 x 11.78 mm)"""
import sys
L, W, T = [float(x) for x in sys.argv[1:4]] if len(sys.argv) == 4 else (95.73, 73.0, 11.78)
A_all = 2 * (L * W + L * T + W * T) * 1e-6
A_eff = A_all - L * W * 1e-6            # the back face lies on the desk: count it as insulated (pessimistic)
H = {'pessimistic 7': 7.0, 'typical 10': 10.0, 'optimistic 16': 16.0}   # W/m2K convection (2-10) + radiation (~5): see README
V_IN = 5.0
cases = [
    ('A  XIAO + camera running, not charging', 0.6),                       # (A) 0.6 W = ~160 mA at 3.7 V, peak use
    ('B  charging 0.5 A (IS jumper cut), XIAO asleep/idle', (V_IN - 3.7) * 0.5 + 0.1),
    ('C  charging 1 A (default), XIAO asleep/idle', (V_IN - 3.7) * 1.0 + 0.1),
    ('D  charging 1 A + XIAO + camera running (worst)', (V_IN - 3.7) * 1.0 + 0.6),
    ('E  charging 0.5 A + XIAO + camera running', (V_IN - 3.7) * 0.5 + 0.6),
]
LIM_HDT, LIM_CELL, SEEED_BACK, SEEED_AMB = 60.0, 45.0, 63.6, 27.0
print('box %.2f x %.2f x %.2f mm, outside area %.4f m2, %.4f m2 without the face on the desk' % (L, W, T, A_all, A_eff))
print('linear charger loss = (5.0 V - 3.7 V) x I (3.0 V cell: up to (5.0-3.0) x I)')
print('%-52s %6s | %s' % ('case', 'P [W]', ' | '.join('shell rise, h=%s' % k for k in H)))
for name, P in cases:
    print('%-52s %6.2f | %s' % (name, P, ' | '.join('%5.1f K          ' % (P / (h * A_eff)) for h in H.values())))
print()
def verdict(m):
    return 'PASS' if m >= 5 else ('MARGINAL' if m >= 0 else 'FAIL')
for room in (25.0, 35.0):
    print('Margins at %.0f C room (typical h = 10). Verdict: PASS >= 5 K, MARGINAL 0-5 K, FAIL < 0' % room)
    for name, P in cases:
        rise = P / (10.0 * A_eff)
        shell = room + rise
        cell = shell + 3.0      # (A) the cell sits 4 mm from the hot boards: assume +3 K over the mean shell
        cam = 'camera' in name
        back = SEEED_BACK + (room - SEEED_AMB) + rise     # Seeed's open-air figure + room offset + the air trapped in the box
        print('  %-50s wall mean %4.1f C: %-8s | cell %4.1f C: %-8s | XIAO back %s' % (name, shell, verdict(LIM_HDT - shell), cell, verdict(LIM_CELL - cell),
              ('~%4.1f C (above 60 C; the front wall over it is cooler by the 1.4 mm air gap, by an unknown amount: MEASURE)' % back) if cam else 'not hot (camera off)'))
    print()
