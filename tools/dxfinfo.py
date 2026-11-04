import sys, ezdxf
from ezdxf import bbox
from collections import Counter
doc=ezdxf.readfile(sys.argv[1]); msp=doc.modelspace()
print('units', doc.header.get('$INSUNITS'), 'entities', Counter(e.dxftype() for e in msp))
print('layers', sorted(set(e.dxf.layer for e in msp)))
for lay in sorted(set(e.dxf.layer for e in msp)):
    ents=[e for e in msp if e.dxf.layer==lay and e.dxftype() not in ('TEXT','MTEXT','DIMENSION','INSERT')]
    if not ents: continue
    b=bbox.extents(ents)
    if b.has_data: print('  layer %-20s n=%4d  x[%.3f,%.3f] y[%.3f,%.3f]  size %.3f x %.3f'%(lay,len(ents),b.extmin.x,b.extmax.x,b.extmin.y,b.extmax.y,b.size.x,b.size.y))
txt=[e.dxf.text for e in msp if e.dxftype()=='TEXT'][:60]
print('texts', txt)
for e in msp:
    if e.dxftype()=='DIMENSION':
        try: print('  DIM', e.dxf.text, round(e.get_measurement(),3))
        except Exception as ex: pass
