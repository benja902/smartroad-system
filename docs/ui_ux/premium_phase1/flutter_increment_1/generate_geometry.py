"""Prepare this approved illustration as Dart paths; not a runtime SVG engine.

Source: the actual D state at 2160 ms, exported by composition_v3.
No animation is implemented by this generator. Unsupported SVG fails explicitly.
"""
from pathlib import Path
import hashlib
import json
import math
import re
import sys
import xml.etree.ElementTree as ET

BASE = Path(__file__).resolve().parents[1]
REPO = BASE.parents[2]
DEST = REPO / 'lib/screens/dev/premium_scene/premium_scene_geometry.g.dart'
IDENTITY = (1., 0., 0., 1., 0., 0.)
NS = 'http://www.w3.org/2000/svg'
PREFIX = 'beacon-2160-'


def mul(p, q):
    a,b,c,d,e,f=p; A,B,C,D,E,F=q
    return (a*A+c*B,b*A+d*B,a*C+c*D,b*C+d*D,a*E+c*F+e,b*E+d*F+f)


def numbers(s):
    return [float(x) for x in re.findall(r'[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?', s)]


def matrix(s):
    result=IDENTITY
    for kind,args in re.findall(r'(\w+)\(([^)]*)\)',s or ''):
        v=numbers(args)
        if kind=='matrix': m=tuple(v)
        elif kind=='translate': m=(1,0,0,1,v[0],v[1] if len(v)>1 else 0)
        elif kind=='scale': m=(v[0],0,0,v[1] if len(v)>1 else v[0],0,0)
        elif kind=='rotate':
            a=math.radians(v[0]);m=(math.cos(a),math.sin(a),-math.sin(a),math.cos(a),0,0)
            if len(v)==3:m=mul(mul((1,0,0,1,v[1],v[2]),m),(1,0,0,1,-v[1],-v[2]))
        else: raise ValueError('Unsupported transform '+kind)
        result=mul(result,m)
    return result


def num(v):
    return '0.0' if abs(v)<1e-12 else repr(float(v))


def path_commands(d):
    tokens=re.findall(r'[a-df-zA-DF-Z]|[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?',d)
    out=[];i=0;cmd=None;x=y=sx=sy=0.;last='';control=None
    sizes={'M':2,'L':2,'H':1,'V':1,'C':6,'S':4,'Q':4,'T':2,'A':7}
    def emit(name,*args):out.append('..'+name+'('+', '.join(num(v) for v in args)+')')
    while i<len(tokens):
        if tokens[i].isalpha():cmd=tokens[i];i+=1
        assert cmd is not None
        upper=cmd.upper();relative=cmd.islower()
        if upper=='Z':
            out.append('..close()');x,y=sx,sy;last='Z';control=None;cmd=None;continue
        assert upper in sizes,cmd
        n=sizes[upper];v=list(map(float,tokens[i:i+n]));assert len(v)==n;i+=n
        def pt(a,b):return (a+x,b+y) if relative else (a,b)
        next_control=None
        if upper in ['M','L']:
            nx,ny=pt(*v);emit('moveTo' if upper=='M' else 'lineTo',nx,ny)
            if upper=='M':sx,sy=nx,ny;cmd='l' if relative else 'L'
        elif upper=='H':nx,ny=(x+v[0] if relative else v[0]),y;emit('lineTo',nx,ny)
        elif upper=='V':nx,ny=x,(y+v[0] if relative else v[0]);emit('lineTo',nx,ny)
        elif upper in ['C','S']:
            if upper=='C':a,b=pt(v[0],v[1]);c,e=pt(v[2],v[3]);nx,ny=pt(v[4],v[5])
            else:
                a,b=(2*x-control[0],2*y-control[1]) if last in ['C','S'] else (x,y)
                c,e=pt(v[0],v[1]);nx,ny=pt(v[2],v[3])
            emit('cubicTo',a,b,c,e,nx,ny);next_control=(c,e)
        elif upper in ['Q','T']:
            if upper=='Q':a,b=pt(v[0],v[1]);nx,ny=pt(v[2],v[3])
            else:
                a,b=(2*x-control[0],2*y-control[1]) if last in ['Q','T'] else (x,y)
                nx,ny=pt(*v)
            emit('quadraticBezierTo',a,b,nx,ny);next_control=(a,b)
        elif upper=='A':
            rx,ry,rotation,large,sweep,ex,ey=v;nx,ny=pt(ex,ey)
            assert large in [0,1] and sweep in [0,1]
            out.append(f'..arcToPoint(Offset({num(nx)}, {num(ny)}), radius: Radius.elliptical({num(rx)}, {num(ry)}), rotation: {num(rotation)}, largeArc: {str(bool(large)).lower()}, clockwise: {str(bool(sweep)).lower()})')
        x,y=nx,ny;control=next_control;last=upper
    return out


def primitive(n):
    tag=n.tag.rsplit('}',1)[-1]
    val=lambda k,default=0:float(n.get(k,default))
    if tag=='path':return path_commands(n.get('d',''))
    if tag in ['polygon','polyline']:
        v=numbers(n.get('points'));assert len(v)%2==0
        result=[f'..{"moveTo" if i==0 else "lineTo"}({num(v[i])}, {num(v[i+1])})' for i in range(0,len(v),2)]
        return result+(['..close()'] if tag=='polygon' else [])
    if tag in ['ellipse','circle']:
        rx=val('rx') if tag=='ellipse' else val('r');ry=val('ry') if tag=='ellipse' else rx
        return [f'..addOval(Rect.fromLTRB({num(val("cx")-rx)}, {num(val("cy")-ry)}, {num(val("cx")+rx)}, {num(val("cy")+ry)}))']
    if tag=='rect':
        x,y,w,h=val('x'),val('y'),val('width'),val('height');rx=val('rx',n.get('ry',0));ry=val('ry',rx)
        rect=f'Rect.fromLTWH({num(x)}, {num(y)}, {num(w)}, {num(h)})'
        return [f'..addRRect(RRect.fromRectAndRadius({rect}, Radius.elliptical({num(min(rx,w/2))}, {num(min(ry,h/2))})))'] if rx or ry else [f'..addRect({rect})']
    raise ValueError('Unsupported primitive '+tag)


def color(s,opacity):
    if s=='none':return 'null'
    assert s.startswith('#'),s
    rgb=s[1:]
    if len(rgb)==3:rgb=''.join(c*2 for c in rgb)
    assert len(rgb)==6
    return 'const Color(0x'+f'{round(255*opacity):02X}'+rgb.upper()+')'


def main():
    page=(BASE/'composition_v3/index.html').read_text(encoding='utf-8')
    snapshot=next(s for s in re.findall(r'<figure>(<svg.*?</svg>)<figcaption>.*?</figcaption></figure>',page,re.S) if f'id="{PREFIX}brand-symbol"' in s)
    root=ET.fromstring(snapshot)
    manifest=json.loads((BASE/'composition_v3/manifest.json').read_text())
    for name,h in manifest['source_hashes'].items():
        assert hashlib.sha256((BASE/'motion_prototype_01'/name).read_bytes()).hexdigest()==h,'Regenerate v3 before native preparation: '+name
    ids={n.get('id'):n for n in root.iter() if n.get('id')}
    scene=ids[PREFIX+'scene-wrap'];shadow=ids[PREFIX+'target-shadow'];symbol=ids[PREFIX+'brand-symbol']
    assert ids[PREFIX+'object-tree-3'].get('style','').find('display: none')>=0
    shapes=[]
    def walk(n,parent,style,opacity,owner):
        tag=n.tag.rsplit('}',1)[-1]
        own=dict(style)
        for k in ['fill','stroke','stroke-width','stroke-linecap','stroke-linejoin','stroke-dasharray','fill-opacity','stroke-opacity','display']:
            if n.get(k) is not None:own[k]=n.get(k)
        inline=dict(re.findall(r'([\w-]+)\s*:\s*([^;]+)',n.get('style','')))
        own.update({k:v.strip() for k,v in inline.items() if k!='opacity'})
        if own.get('display')=='none':return
        opacity*=float(inline.get('opacity',n.get('opacity','1')))
        if opacity==0:return
        current=mul(parent,matrix(n.get('transform')))
        if n.get('id') and n.get('id').startswith(PREFIX):owner=n.get('id')[len(PREFIX):]
        if tag in ['g','svg','symbol']:
            for c in n:walk(c,current,own,opacity,owner)
        elif tag=='use':
            ref=ids[n.get('href')[1:]];box=numbers(ref.get('viewBox'))
            assert box[2]==box[3] and n.get('width')==n.get('height')
            m=mul(current,(float(n.get('width'))/box[2],0,0,float(n.get('height'))/box[3],float(n.get('x','0')),float(n.get('y','0'))))
            for c in ref:walk(c,m,own,opacity,owner)
        else:
            commands=primitive(n)
            shapes.append((owner,commands,current,own,opacity))
    inverse=(1/.6,0,0,1/.6,-14/.6,-270/.6)
    defaults={'fill':'#000000','stroke':'none','stroke-width':'1','stroke-linecap':'butt','stroke-linejoin':'miter'}
    walk(scene,inverse,defaults,1,'scene')
    walk(shadow,inverse,defaults,1,'target-shadow')
    walk(symbol,mul(inverse,matrix(ids[PREFIX+'brand-lockup'].get('transform'))),defaults,1,'brand-symbol')
    layers=[]
    for shape in shapes:
        if not layers or layers[-1][0]!=shape[0]:layers.append((shape[0],[]))
        layers[-1][1].append(shape)
    assert all(name!='object-tree-3' for name,_ in layers)
    lines=["// GENERATED by docs/ui_ux/premium_phase1/flutter_increment_1/generate_geometry.py.","// Static approved D at 2160 ms; original SVG/HTML sources remain unchanged.","part of 'premium_scene.dart';",'', 'List<_SceneLayer> _buildPremiumSceneGeometry() => [']
    for owner,items in layers:
        lines.append(f"  _SceneLayer('{owner}', [")
        for _,commands,m,style,opacity in items:
            path='(Path()\n      '+'\n      '.join(commands)+')'
            if style.get('stroke-dasharray'):
                assert numbers(style['stroke-dasharray'])==[9,10]
                path='_laneMarkings('+path+')'
            a,b,c,d,e,f=m
            if any(abs(x-y)>1e-10 for x,y in zip(m,IDENTITY)):
                values=[a,b,0,0,c,d,0,0,0,0,1,0,e,f,0,1]
                # Transform strokes with their paths at paint time, preserving
                # the nonuniform isometric projection of rounded strokes.
                mat='Float64List.fromList(['+', '.join(map(num,values))+'])'
            else:mat='null'
            fill=color(style['fill'],opacity*float(style.get('fill-opacity','1')))
            stroke=color(style['stroke'],opacity*float(style.get('stroke-opacity','1')))
            cap={'butt':'butt','round':'round','square':'square'}[style['stroke-linecap']]
            join={'miter':'miter','round':'round','bevel':'bevel'}[style['stroke-linejoin']]
            lines.append(f'    _SceneShape({path}, {fill}, {stroke}, {num(float(style["stroke-width"]))}, {mat}, StrokeCap.{cap}, StrokeJoin.{join}),')
        lines.append('  ]),')
    lines.append('];\n')
    DEST.parent.mkdir(parents=True,exist_ok=True);DEST.write_text('\n'.join(lines),encoding='utf-8')
    data={'source_mode':'beacon','time_ms':2160,'source_snapshot_sha256':hashlib.sha256(snapshot.encode()).hexdigest(),'source_hashes':manifest['source_hashes'],'layers':[{'id':name,'shapes':len(items)} for name,items in layers],'shape_count':len(shapes),'viewport':[620,430],'t4_removed':True,'animation_implemented':False}
    (BASE/'flutter_increment_1/geometry_manifest.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
    if '--reference-svg' in sys.argv:
        # QA export only; no new HTML panel or alternate illustration source.
        out=ET.Element('{'+NS+'}svg',{'viewBox':'0 0 620 430','width':'620','height':'430'})
        ET.SubElement(out,'{'+NS+'}rect',{'width':'620','height':'430','fill':'#F8F9FA'})
        out.append(root.find('{'+NS+'}defs'))
        group=ET.SubElement(out,'{'+NS+'}g',{'transform':'matrix(1.6666666666666667 0 0 1.6666666666666667 -23.333333333333333 -450)'})
        group.append(scene);group.append(shadow)
        brand=ET.SubElement(group,'{'+NS+'}g',dict(ids[PREFIX+'brand-lockup'].attrib));brand.append(symbol)
        ET.register_namespace('',NS)
        Path(sys.argv[sys.argv.index('--reference-svg')+1]).write_text(ET.tostring(out,encoding='unicode'),encoding='utf-8')
    print(f'Prepared {len(shapes)} vector shapes / {len(layers)} layers from approved D; no motion or source edits.')


if __name__=='__main__':main()
