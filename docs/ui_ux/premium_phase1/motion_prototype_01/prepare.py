"""Extract the approved vector scene and vehicle coordinates; never writes v2."""
from pathlib import Path
import importlib.util
import sys
import json
import math
import xml.etree.ElementTree as ET

sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/'composition_v2'
spec=importlib.util.spec_from_file_location('urbes_art',SOURCE/'illustrate.py')
art=importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)

def normal(points):
    # Newell's method supports wheel rings and non-triangular body contours.
    n=[0.,0.,0.]
    for a,b in zip(points,points[1:]+points[:1]):
        n[0]+=(a[1]-b[1])*(a[2]+b[2])
        n[1]+=(a[2]-b[2])*(a[0]+b[0])
        n[2]+=(a[0]-b[0])*(a[1]+b[1])
    center=[sum(p[i] for p in points)/len(points) for i in range(3)]
    # Orient original inconsistent face winding outwards, without changing vertices.
    if sum(n[i]*(center[i]-[0,0,22][i]) for i in range(3))<0:n=[-v for v in n]
    length=math.sqrt(sum(v*v for v in n)) or 1
    return [v/length for v in n]

class Capture:
    view='iso'
    def __init__(self):self.parts=[]
    def ground(self,content):return '' # Replaced with one consistently lit shadow.
    def pg(self,vertices,fill,stroke=None,width=.6,extra=''):
        self.parts.append({'kind':'polygon','points':vertices,'fill':fill,'stroke':stroke,'width':width,'normal':normal(vertices)})
        return ''
    def line(self,points,color,width=1,extra=''):
        mid=[sum(p[i] for p in points)/len(points) for i in range(3)]
        if abs(mid[1])>=13:n=[0,1 if mid[1]>0 else -1,0]
        elif mid[0]>=17 and mid[2]<40:n=[1,0,.65]
        elif mid[0]<-35:n=[-1,0,0]
        else:n=[0,0,1]
        self.parts.append({'kind':'polyline','points':points,'fill':'none','stroke':color,'width':width,'normal':n})
        return ''

def main():
    capture=Capture();art.car(capture,0,0,0)
    ns={'s':'http://www.w3.org/2000/svg'}
    scene=ET.parse(SOURCE/'scene-isometric.svg').find('.//s:g[@id="illustration-world"]',ns)
    vehicle=scene.find('s:g[@id="layer-vehicle"]',ns)
    assert vehicle is not None
    vehicle.clear()
    vehicle.set('id','layer-vehicle')
    scene.remove(scene.find('s:g[@id="layer-brand-sign"]',ns))
    ET.register_namespace('',ns['s'])
    # The v2 still placed the entire vehicle above all scenery. On this route,
    # the pavilion and foreground park must occlude it where their silhouettes meet.
    foreground=ET.SubElement(scene,'{'+ns['s']+'}g',{'id':'layer-foreground'})
    for object_id in ['object-pavilion','object-bench','object-tree-0','object-tree-1','object-tree-2']:
        for parent in list(scene.iter()):
            for child in list(parent):
                if child.get('id')==object_id:
                    parent.remove(child);foreground.append(child)
                    break
            else:continue
            break
    source=ET.tostring(scene,encoding='unicode')
    logo=ET.parse(ROOT/'logo.svg').getroot()
    assert logo.get('viewBox')=='0 0 512 512'
    assert all(child.tag=='{'+ns['s']+'}path' for child in logo)
    logo_paths=''.join(ET.tostring(child,encoding='unicode') for child in logo)
    assets={'scene':source,'parts':capture.parts,'logo':logo_paths}
    (ROOT/'assets.js').write_text('/* Derived locally from composition_v2; no stock assets. */\nwindow.URBES_ASSETS='+json.dumps(assets,separators=(',',':'))+';\n',encoding='utf-8')
    print(f'Prepared scene without old emblem, supplied logo and {len(capture.parts)} vehicle surfaces/details; v2 preserved.')

if __name__=='__main__':main()
