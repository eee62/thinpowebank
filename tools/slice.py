# Usage: slice.py file.step name-substring axis(x|y|z) v1 v2 v3 ...
# Cuts the named assembly node with planes normal to the axis and prints the section's bounding box.
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
from OCP.BRepAlgoAPI import BRepAlgoAPI_Section
from OCP.gp import gp_Pln, gp_Pnt, gp_Dir
path,sub,axis=sys.argv[1],sys.argv[2],sys.argv[3]; vals=[float(v) for v in sys.argv[4:]]
doc=TDocStd_Document(TCollection_ExtendedString("doc"))
r=STEPCAFControl_Reader(); r.SetNameMode(True); r.ReadFile(path); r.Transfer(doc)
st=XCAFDoc_DocumentTool.ShapeTool_s(doc.Main())
def name(l):
    a=TDataStd_Name(); return a.Get().ToExtString() if l.FindAttribute(TDataStd_Name.GetID_s(),a) else '?'
found=[]
def walk(label,loc):
    if sub in name(label): found.append(st.GetShape_s(label).Moved(loc)); return
    if st.IsAssembly_s(label):
        comps=Seq(); st.GetComponents_s(label,comps)
        for i in range(1,comps.Length()+1):
            c=comps.Value(i); ref=TDF_Label(); st.GetReferredShape_s(c,ref); walk(ref,loc.Multiplied(st.GetLocation_s(c)))
roots=Seq(); st.GetFreeShapes(roots)
for i in range(1,roots.Length()+1): walk(roots.Value(i),TopLoc_Location())
shape=found[0]
d={'x':gp_Dir(1,0,0),'y':gp_Dir(0,1,0),'z':gp_Dir(0,0,1)}[axis]
for v in vals:
    p=gp_Pnt(v if axis=='x' else 0, v if axis=='y' else 0, v if axis=='z' else 0)
    sec=BRepAlgoAPI_Section(shape,gp_Pln(p,d)); sec.Build()
    b=Bnd_Box(); BRepBndLib.Add_s(sec.Shape(),b)
    if b.IsVoid(): print('%s=%.3f: empty'%(axis,v)); continue
    a=b.CornerMin(); c=b.CornerMax()
    print('%s=%7.3f: x[%7.3f,%7.3f] y[%7.3f,%7.3f] z[%7.3f,%7.3f]  dx=%.3f dy=%.3f dz=%.3f'%(axis,v,a.X(),c.X(),a.Y(),c.Y(),a.Z(),c.Z(),c.X()-a.X(),c.Y()-a.Y(),c.Z()-a.Z()))
