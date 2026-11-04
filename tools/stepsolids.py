# Usage: stepsolids.py file.step [name-substring]
# Lists every SOLID (global coords, exact bounds) under assembly nodes whose name contains the substring,
# plus every cylindrical face (axis, radius, extent) so barrels/holes can be identified.
import sys
from OCP.STEPCAFControl import STEPCAFControl_Reader
from OCP.TDocStd import TDocStd_Document
from OCP.TCollection import TCollection_ExtendedString
from OCP.XCAFDoc import XCAFDoc_DocumentTool
from OCP.TDF import TDF_Label
from OCP.collections import Sequence_TDF_Label as Seq
from OCP.TDataStd import TDataStd_Name
from OCP.Bnd import Bnd_Box
from OCP.BRepBndLib import BRepBndLib
from OCP.TopLoc import TopLoc_Location
from OCP.TopExp import TopExp_Explorer
from OCP.TopAbs import TopAbs_SOLID, TopAbs_FACE, TopAbs_SHELL
from OCP.BRepAdaptor import BRepAdaptor_Surface
from OCP.GeomAbs import GeomAbs_Cylinder
from OCP.TopoDS import TopoDS
path=sys.argv[1]; sub=sys.argv[2] if len(sys.argv)>2 else ''
doc=TDocStd_Document(TCollection_ExtendedString("doc"))
r=STEPCAFControl_Reader(); r.SetNameMode(True); r.ReadFile(path); r.Transfer(doc)
st=XCAFDoc_DocumentTool.ShapeTool_s(doc.Main())
def name(l):
    a=TDataStd_Name()
    return a.Get().ToExtString() if l.FindAttribute(TDataStd_Name.GetID_s(),a) else '?'
def bb(s):
    b=Bnd_Box(); BRepBndLib.AddOptimal_s(s,b,False,False)
    if b.IsVoid(): return None
    a=b.CornerMin(); c=b.CornerMax(); return (a.X(),c.X(),a.Y(),c.Y(),a.Z(),c.Z())
def fmt(b): return 'x[%7.3f,%7.3f] y[%7.3f,%7.3f] z[%7.3f,%7.3f] size %.3f x %.3f x %.3f'%(b+(b[1]-b[0],b[3]-b[2],b[5]-b[4]))
def report(shape,label):
    print('###',label, fmt(bb(shape)))
    ex=TopExp_Explorer(shape,TopAbs_SOLID); n=0
    while ex.More():
        n+=1; print('  solid %d: %s'%(n,fmt(bb(ex.Current())))); ex.Next()
    if n==0:
        ex=TopExp_Explorer(shape,TopAbs_SHELL)
        while ex.More(): n+=1; print('  shell %d: %s'%(n,fmt(bb(ex.Current())))); ex.Next()
    cyl={}
    ex=TopExp_Explorer(shape,TopAbs_FACE)
    while ex.More():
        f=TopoDS.Face(ex.Current()); s=BRepAdaptor_Surface(f)
        if s.GetType()==GeomAbs_Cylinder:
            c=s.Cylinder(); ax=c.Axis(); d=ax.Direction(); p=ax.Location()
            key=(round(c.Radius(),3),round(abs(d.X()),2),round(abs(d.Y()),2),round(abs(d.Z()),2))
            b=bb(f)
            cyl.setdefault(key,[]).append(b)
        ex.Next()
    for k,v in sorted(cyl.items(), key=lambda kv:-kv[0][0]):
        if k[0]<0.5: continue
        lo=[min(b[i] for b in v) for i in (0,2,4)]; hi=[max(b[i] for b in v) for i in (1,3,5)]
        print('  cyl r=%.3f (d=%.3f) axis|%s| n=%d extent x[%.3f,%.3f] y[%.3f,%.3f] z[%.3f,%.3f]'%(k[0],2*k[0],k[1:],len(v),lo[0],hi[0],lo[1],hi[1],lo[2],hi[2]))
def walk(label,loc,path):
    nm=name(label); p=path+'/'+nm
    if sub and sub in nm:
        report(st.GetShape_s(label).Moved(loc),p); return
    if st.IsAssembly_s(label):
        comps=Seq(); st.GetComponents_s(label,comps)
        for i in range(1,comps.Length()+1):
            c=comps.Value(i); ref=TDF_Label(); st.GetReferredShape_s(c,ref)
            walk(ref,loc.Multiplied(st.GetLocation_s(c)),p)
    elif not sub:
        report(st.GetShape_s(label).Moved(loc),p)
roots=Seq(); st.GetFreeShapes(roots)
for i in range(1,roots.Length()+1): walk(roots.Value(i),TopLoc_Location(),'')
