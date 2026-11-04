# Usage: python stepbb.py file.step [maxdepth]
# Prints, for every node of the STEP assembly tree, its name and its axis-aligned
# bounding box in the file's GLOBAL coordinates (mm), using exact (non-mesh) OCC bounds.
import sys
from OCP.STEPCAFControl import STEPCAFControl_Reader
from OCP.TDocStd import TDocStd_Document
from OCP.TCollection import TCollection_ExtendedString
from OCP.XCAFDoc import XCAFDoc_DocumentTool
from OCP.TDF import TDF_Label
from OCP.collections import Sequence_TDF_Label as TDF_LabelSequence
from OCP.TDataStd import TDataStd_Name
from OCP.Bnd import Bnd_Box
from OCP.BRepBndLib import BRepBndLib
from OCP.TopLoc import TopLoc_Location
from OCP.IFSelect import IFSelect_RetDone

path=sys.argv[1]; maxd=int(sys.argv[2]) if len(sys.argv)>2 else 99
doc=TDocStd_Document(TCollection_ExtendedString("doc"))
r=STEPCAFControl_Reader(); r.SetNameMode(True)
assert r.ReadFile(path)==IFSelect_RetDone
r.Transfer(doc)
st=XCAFDoc_DocumentTool.ShapeTool_s(doc.Main())
def name(l):
    a=TDataStd_Name()
    if l.FindAttribute(TDataStd_Name.GetID_s(),a): return a.Get().ToExtString()
    return '?'
def bb(shape):
    b=Bnd_Box(); BRepBndLib.AddOptimal_s(shape,b,False,False)
    if b.IsVoid(): return None
    a=b.CornerMin(); c=b.CornerMax()
    return (a.X(),a.Y(),a.Z(),c.X(),c.Y(),c.Z())
def walk(label,loc,depth):
    if depth>maxd: return
    shape=st.GetShape_s(label)
    s=shape.Moved(loc)
    box=bb(s)
    if box:
        x0,y0,z0,x1,y1,z1=box
        print('%s%-40s x[%8.3f,%8.3f] y[%8.3f,%8.3f] z[%8.3f,%8.3f]  size %.3f x %.3f x %.3f'%('  '*depth,name(label)[:40],x0,x1,y0,y1,z0,z1,x1-x0,y1-y0,z1-z0))
    if st.IsAssembly_s(label):
        comps=TDF_LabelSequence(); st.GetComponents_s(label,comps)
        for i in range(1,comps.Length()+1):
            c=comps.Value(i)
            cl=st.GetLocation_s(c)
            ref=TDF_Label(); st.GetReferredShape_s(c,ref)
            walk(ref, loc.Multiplied(cl), depth+1)
roots=TDF_LabelSequence(); st.GetFreeShapes(roots)
for i in range(1,roots.Length()+1):
    walk(roots.Value(i),TopLoc_Location(),0)
