import sys, math, xml.etree.ElementTree as ET
path = sys.argv[1]
root = ET.parse(path).getroot()
board = root.find('drawing/board')
# outline: layer 20
xs=[];ys=[]
for w in board.findall('plain/wire'):
    if w.get('layer')=='20':
        for k in ('x1','x2'): xs.append(float(w.get(k)))
        for k in ('y1','y2'): ys.append(float(w.get(k)))
for c in board.findall('plain/circle'):
    if c.get('layer')=='20': print('outline circle', c.attrib)
print('OUTLINE x %.3f..%.3f (%.3f)  y %.3f..%.3f (%.3f)'%(min(xs),max(xs),max(xs)-min(xs),min(ys),max(ys),max(ys)-min(ys)))
x0,y0=min(xs),min(ys)
# arcs/curves in outline
for w in board.findall('plain/wire'):
    if w.get('layer')=='20' and w.get('curve'): print('  outline curve', w.attrib); break
for h in board.findall('plain/hole'):
    print('PLAIN HOLE x=%.3f y=%.3f d=%s (rel %.3f,%.3f)'%(float(h.get('x')),float(h.get('y')),h.get('drill'),float(h.get('x'))-x0,float(h.get('y'))-y0))
# packages
pk={}
for lib in board.findall('libraries/library'):
    for p in lib.findall('packages/package'):
        pk[(lib.get('name'),p.get('name'))]=p
for e in board.findall('elements/element'):
    key=(e.get('library'),e.get('package'))
    p=pk.get(key)
    x=float(e.get('x'));y=float(e.get('y'));rot=e.get('rot','R0')
    mir = rot.startswith('M'); ang=float(rot.lstrip('MSR'))
    # bbox of pads/smds + holes in package, transformed
    pts=[]
    if p is not None:
        for s in p.findall('smd'):
            sx,sy,dx,dy=[float(s.get(k)) for k in ('x','y','dx','dy')]
            pts += [(sx-dx/2,sy-dy/2),(sx+dx/2,sy+dy/2),(sx-dx/2,sy+dy/2),(sx+dx/2,sy-dy/2)]
        for s in p.findall('pad'):
            sx,sy=float(s.get('x')),float(s.get('y')); d=float(s.get('drill'))
            pts += [(sx-d,sy-d),(sx+d,sy+d)]
        for s in p.findall('hole'):
            sx,sy=float(s.get('x')),float(s.get('y')); d=float(s.get('drill'))
            pts += [(sx-d/2,sy-d/2),(sx+d/2,sy+d/2)]
        for wv in p.findall('wire'):
            if wv.get('layer') in ('21','51','39','22','52'):
                pts += [(float(wv.get('x1')),float(wv.get('y1'))),(float(wv.get('x2')),float(wv.get('y2')))]
    tp=[]
    for (px,py) in pts:
        if mir: px=-px
        a=math.radians(ang); qx=px*math.cos(a)-py*math.sin(a); qy=px*math.sin(a)+py*math.cos(a)
        tp.append((qx+x-x0,qy+y-y0))
    bb = '' if not tp else 'bbox x %.2f..%.2f y %.2f..%.2f'%(min(t[0] for t in tp),max(t[0] for t in tp),min(t[1] for t in tp),max(t[1] for t in tp))
    attrs={a.get('name'):a.get('value') for a in e.findall('attribute')}
    print('%-10s %-30s %-28s at (%.3f, %.3f) %s %s'%(e.get('name'),e.get('package'),e.get('value'),x-x0,y-y0,rot,bb))
