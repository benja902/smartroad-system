"""Original review-only vector art. Standard library; no application imports.

Common world, orthographic projections, individually named illustration layers.
Source previews are not inputs to this renderer: no tracing or imported stock art.
"""
from pathlib import Path
import math
import html

ROOT = Path(__file__).resolve().parent
N = '#1B2B48'
PAPER = '#F8F9FA'
WHITE = '#FFFFFF'
TEAL = '#347E84'
TEAL_LIGHT = '#79AAA6'
TEAL_DARK = '#255963'
CLAY = '#D38B70'
CLAY_LIGHT = '#E7B59C'
CLAY_DARK = '#B57059'
ROAD = 'M-18 205H135C198 205 235 171 235 113V10'
SHIELD = 'M80 23C109 23 126 39 126 77C126 111 105 130 80 137C55 130 34 111 34 77C34 39 51 23 80 23Z'
WORD = 'M29 174V188Q29 194 36 194Q43 194 43 188V174M51 194V174H59Q65 174 65 180Q65 186 59 186H51M59 186L65 194M73 194V174H80Q87 174 87 179Q87 184 80 184H73M80 184Q88 184 88 189Q88 194 80 194H73M109 174H95V194H109M95 184H106M131 175Q117 170 117 180Q117 184 124 184Q132 184 132 189Q132 198 117 193'

def txt(x,y,s,size=16,weight=500,fill=N,anchor='start'):
    return f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{html.escape(s)}</text>'

def path(d,fill='none',stroke=None,width=1,extra=''):
    return f'<path d="{d}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"' if stroke else '')+f' {extra}/>'

def poly(points,fill,stroke=None,width=.7,extra=''):
    pts=' '.join(f'{x:.2f},{y:.2f}' for x,y in points)
    return f'<polygon points="{pts}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"' if stroke else '')+f' {extra}/>'

class World:
    def __init__(self,view='iso'):
        self.view=view
    def p(self,x,y,z=0):
        return (300+.8660254*(x-y),48+.5*(x+y)-z) if self.view=='iso' else (65+x,50+y)
    @property
    def matrix(self):
        return 'matrix(.8660254 .5 -.8660254 .5 300 48)' if self.view=='iso' else 'translate(65 50)'
    def ground(self,content):
        return f'<g transform="{self.matrix}">{content}</g>'
    def pg(self,vertices,fill,stroke=None,width=.6,extra=''):
        return poly([self.p(*v) for v in vertices],fill,stroke,width,extra)
    def line(self,points,color,width=1,extra=''):
        pts=[self.p(*p) for p in points]
        return path('M'+'L'.join(f'{x:.2f} {y:.2f}' for x,y in pts),'none',color,width,extra)
    def box(self,x,y,w,d,h,top,left,right,z=0):
        out=''
        if self.view=='iso':
            out+=self.pg([(x,y+d,z),(x+w,y+d,z),(x+w,y+d,z+h),(x,y+d,z+h)],left)
            out+=self.pg([(x+w,y,z),(x+w,y+d,z),(x+w,y+d,z+h),(x+w,y,z+h)],right)
        out+=self.pg([(x,y,z+h),(x+w,y,z+h),(x+w,y+d,z+h),(x,y+d,z+h)],top)
        return out
    def shadow(self,x,y,w,d,opacity=.12):
        return self.ground(f'<rect x="{x+9}" y="{y+9}" width="{w}" height="{d}" rx="5" fill="{N}" opacity="{opacity}"/>')

def tree(world,x,y,r=16):
    px,py=world.p(x,y,44 if world.view=='iso' else 0)
    gx,gy=world.p(x+10,y+9)
    out=f'<ellipse cx="{gx}" cy="{gy}" rx="{r*1.25}" ry="{r*.65}" fill="{N}" opacity=".09"/>'
    if world.view=='iso':
        out+=world.line([(x,y,0),(x,y,43)],'#826C5C',4)
        out+=world.line([(x,y,23),(x-7,y,34)],'#826C5C',2)
    # Irregular leaf silhouette and individually placed light planes.
    out+=f'<g transform="translate({px} {py}) scale({r/20})">'
    out+=path('M-19 3C-26-3-23-14-15-16C-14-27 1-29 7-22C18-25 27-16 23-8C31 1 22 17 12 17C6 26-8 23-12 16C-23 18-29 8-19 3Z',TEAL_DARK)
    out+=path('M-18-5C-25-13-14-25-6-21C1-29 15-22 14-14C27-13 23 3 16 5C11 16-3 12-6 8C-17 12-24 3-18-5Z',TEAL)
    out+=path('M-14-10C-19-17-9-22-4-18C3-24 12-17 8-10C12-3 1 1-2-4C-10 1-17-4-14-10Z',TEAL_LIGHT)
    out+=path('M-2 5L-3-12M-3-4L-10-9M-3 0L5-5','none',TEAL_DARK,.7,extra='opacity=".45"')
    return out+'</g>'

def townhouse(world):
    x,y,w,d,h=38,56,82,67,65
    out=world.shadow(x,y,w,d)
    out+=world.box(x-3,y-3,w+6,d+6,3,'#D7E1E1','#B6C8CC','#A5BAC1')
    out+=world.box(x,y,w,d,h,'#F2E4D7','#E3D5C8','#C4B7AC')
    if world.view=='iso':
        # Recessed windows and lintels on both visible facades.
        for xx in [x+12,x+35,x+58]:
            for zz in [14,39]:
                out+=world.pg([(xx,y+d+.1,zz),(xx+12,y+d+.1,zz),(xx+12,y+d+.1,zz+16),(xx,y+d+.1,zz+16)],N)
                out+=world.pg([(xx+2,y+d+.2,zz+2),(xx+10,y+d+.2,zz+2),(xx+10,y+d+.2,zz+14),(xx+2,y+d+.2,zz+14)],'#87A7B4')
                out+=world.line([(xx+6,y+d+.3,zz+2),(xx+6,y+d+.3,zz+14)],'#D8E6E8',.8)
                out+=world.line([(xx-1,y+d+.5,zz),(xx+13,y+d+.5,zz)],'#F8EFE7',2)
        for yy in [y+13,y+40]:
            out+=world.pg([(x+w+.2,yy,25),(x+w+.2,yy+14,25),(x+w+.2,yy+14,46),(x+w+.2,yy,46)],N)
            out+=world.pg([(x+w+.3,yy+2,27),(x+w+.3,yy+12,27),(x+w+.3,yy+12,44),(x+w+.3,yy+2,44)],'#76929F')
    # Pitched tiled roof, ridge, parallel courses, skylight.
    mid=y+d/2
    out+=world.pg([(x-5,y-5,h),(x+w+5,y-5,h),(x+w+5,mid,h+20),(x-5,mid,h+20)],CLAY_LIGHT)
    out+=world.pg([(x-5,mid,h+20),(x+w+5,mid,h+20),(x+w+5,y+d+5,h),(x-5,y+d+5,h)],CLAY)
    out+=world.pg([(x+w+5,y-5,h),(x+w+5,mid,h+20),(x+w+5,y+d+5,h)],CLAY_DARK)
    for xx in range(x,x+w+1,8):
        out+=world.line([(xx,mid,h+20),(xx,y+d+5,h)],CLAY_DARK,.65)
        out+=world.line([(xx,y-5,h),(xx,mid,h+20)],CLAY,.65)
    for step in [1,2,3]:
        yy=mid+(d/2+5)*step/4
        zz=h+20*(1-step/4)
        out+=world.line([(x-5,yy,zz),(x+w+5,yy,zz)],CLAY_DARK,.6)
    out+=world.line([(x-5,mid,h+21),(x+w+5,mid,h+21)],'#F0C5AD',2)
    out+=world.pg([(x+16,mid+8,h+17),(x+36,mid+8,h+17),(x+36,mid+22,h+9),(x+16,mid+22,h+9)],'#DDE9EA',N,1)
    out+=world.line([(x+26,mid+8,h+17),(x+26,mid+22,h+9)],'#75939F',.8)
    out+=world.box(x+60,y+13,9,9,14,'#EEDCD0','#D0B7A5','#B29989',h+6)
    return out

def pavilion(world):
    x,y,w,d,h=277,130,50,77,31
    out=world.shadow(x,y,w,d)
    out+=world.box(x-3,y-3,w+6,d+6,3,'#E0E6E7','#B9C8CE','#91A5AF')
    out+=world.box(x,y,w,d,h,'#EFF2F2','#C6D8DA','#9EBCC1')
    if world.view=='iso':
        for xx in [x+7,x+22,x+37]:
            out+=world.pg([(xx,y+d+.2,6),(xx+9,y+d+.2,6),(xx+9,y+d+.2,24),(xx,y+d+.2,24)],'#456778')
            out+=world.line([(xx+2,y+d+.3,8),(xx+2,y+d+.3,22)],'#8FB7C1',1.4)
        for yy in [y+12,y+35,y+58]:
            out+=world.pg([(x+w+.2,yy,7),(x+w+.2,yy+14,7),(x+w+.2,yy+14,24),(x+w+.2,yy,24)],'#456778')
    out+=world.box(x-4,y-4,w+8,d+8,4,TEAL_LIGHT,TEAL,TEAL_DARK,h)
    # Solar panes, roof vent and canopy: recognizable architectural detail.
    for yy in [y+7,y+30]:
        out+=world.pg([(x+7,yy,h+4.1),(x+40,yy,h+4.1),(x+40,yy+17,h+4.1),(x+7,yy+17,h+4.1)],'#456778')
        for xx in [x+15,x+23,x+31]:
            out+=world.line([(xx,yy,h+4.2),(xx,yy+17,h+4.2)],'#91B6BD',.7)
        out+=world.line([(x+7,yy+8,h+4.2),(x+40,yy+8,h+4.2)],'#91B6BD',.7)
    out+=world.box(x+12,y+59,17,9,6,'#DAE4E5','#AFC4C8','#8AA9B1',h+4)
    return out

def bench(world,x,y):
    out=world.shadow(x,y,37,12,.1)
    for xx in [x+5,x+30]:
        out+=world.box(xx,y+2,3,9,8,N,N,N)
    for yy in [y,y+4,y+8]:
        out+=world.box(x,yy,37,3,2,CLAY_LIGHT,CLAY,CLAY_DARK,8)
    for zz in [15,20]:
        out+=world.box(x,y+11,37,2,3,CLAY_LIGHT,CLAY,CLAY_DARK,zz)
    return out

def lamp(world,x,y):
    out=world.ground(path(f'M{x} {y}l20 20','none',N,2,extra='opacity=".10"'))
    out+=world.line([(x,y,0),(x,y,49),(x+9,y,53)],'#66818D',1.8)
    out+=world.box(x+5,y-2,11,5,2,'#E7EDEF','#7E969F','#66818D',51)
    return out

def car(world,x,y,heading=0):
    angle=math.radians(heading)
    def q(a,b,z=0):
        return (x+a*math.cos(angle)-b*math.sin(angle),y+a*math.sin(angle)+b*math.cos(angle),z)
    def pg(points,color,stroke=None,width=.6):
        return world.pg([q(*p) for p in points],color,stroke,width)
    def ln(points,color,width=1,extra=''):
        return world.line([q(*p) for p in points],color,width,extra)
    out='<g data-object="vehicle" data-pivot="center" data-heading="'+str(heading)+'">'
    out+=world.ground(f'<g transform="translate({x+7} {y+9}) rotate({heading})"><rect x="-44" y="-22" width="88" height="44" rx="18" fill="{N}" opacity=".13"/></g>')
    # Four tyres: projected circles in longitudinal-height planes.
    wheels=[]
    for a in [-25,25]:
        for b in [-19,19]:
            rings=[(a+9*math.cos(t*math.pi/12),b,10+9*math.sin(t*math.pi/12)) for t in range(24)]
            hub=[(a+4.3*math.cos(t*math.pi/12),b+(.2 if b>0 else -.2),10+4.3*math.sin(t*math.pi/12)) for t in range(24)]
            depth=sum(q(a,b)[:2])
            wheels.append((depth,pg(rings,N)+pg(hub,'#B4C9CD')+ln([(a-2,b,10),(a+2,b,10)],WHITE,.8)))
    wheels.sort()
    out+=''.join(w[1] for w in wheels[:2])
    outline=[(-40,-12),(-32,-19),(25,-19),(40,-12),(43,-5),(43,7),(35,17),(-31,19),(-42,10)]
    faces=[]
    for i,(a,b) in enumerate(outline):
        c,d=outline[(i+1)%len(outline)]
        vertices=[(a,b,11),(c,d,11),(c,d,27),(a,b,27)]
        depth=sum(q((a+c)/2,(b+d)/2)[:2])
        faces.append((depth,pg(vertices,TEAL_DARK if b+d>0 else TEAL)))
    faces.sort()
    out+=''.join(f[1] for f in faces)
    out+=pg([(a,b,27) for a,b in outline],TEAL)
    out+=pg([(24,-15,28),(37,-10,28),(39,7,28),(32,14,28),(24,15,28)],TEAL_LIGHT)
    # Cabin: front/rear glass, roof and side glazing.
    surfaces=[([(-28,-15,28),(-17,-12,42),(14,-12,42),(24,-15,28)],N),([(-28,15,28),(-17,12,42),(14,12,42),(24,15,28)],TEAL_DARK),([(-28,-15,28),(-28,15,28),(-17,12,42),(-17,-12,42)],'#496D7C'),([(14,-12,42),(14,12,42),(24,15,28),(24,-15,28)],'#254A61')]
    surfaces.sort(key=lambda item:sum(sum(q(*v)[:2]) for v in item[0])/4)
    out+=''.join(pg(points,col) for points,col in surfaces)
    out+=pg([(-17,-12,42),(14,-12,42),(14,12,42),(-17,12,42)],'#8AB7B2')
    out+=pg([(-14,-9,42.2),(10,-9,42.2),(10,9,42.2),(-14,9,42.2)],TEAL_LIGHT)
    # Pillars, reflected light, body seams, mirrors, lamps and bumper.
    out+=ln([(-5,-13,41),(-5,-15,29)],TEAL,2)
    out+=ln([(-5,13,41),(-5,15,29)],TEAL,2)
    out+=ln([(18,-10,38),(22,-12,31)],'#A8CCD0',2)
    out+=ln([(-12,-8,42.5),(8,-8,42.5)],'#BCD7D2',1.5)
    out+=ln([(-28,18,26),(30,17,26)],'#79AAA6',1.2)
    out+=ln([(-5,18.5,13),(-5,18.5,27)],TEAL_DARK,.7)
    out+=ln([(-2,19,24),(5,19,24)],'#A8C8C5',1.5)
    out+=pg([(37,-11,22),(42,-6,22),(42,-6,26),(38,-11,26)],'#FFF2D6')
    out+=pg([(37,11,22),(42,6,22),(42,6,26),(38,11,26)],'#FFF2D6')
    out+=ln([(43,-4,17),(43,5,17)],N,2)
    out+=ln([(-40,-8,22),(-40,5,22)],CLAY_LIGHT,2)
    for side in [-1,1]:
        out+=pg([(12,side*17,29),(17,side*24,29),(12,side*25,31),(9,side*18,31)],TEAL_DARK)
    out+=''.join(w[1] for w in wheels[2:])
    return out+'</g>'

def brand_mark(x,y,scale=.45):
    return f'<g transform="translate({x} {y}) scale({scale}) translate(-80 -80)" fill="none" stroke="{N}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">'+path(SHIELD,'none',N,3)+path('M80 69L63 87M80 69L97 87M80 69V108','none',N,2)+''.join(f'<circle cx="{a}" cy="{b}" r="3.5" fill="{N}" stroke="none"/>' for a,b in [(80,69),(63,87),(97,87),(80,108)])+'</g>'

def scene(view='iso',phase=4,vehicle_pose=0):
    world=World(view)
    out='<g id="illustration-world" data-projection="'+view+'">'
    out+='<g id="layer-ground">'
    out+=world.ground('<rect x="-12" y="-12" width="364" height="324" rx="38" fill="#E8EEEC"/>')
    out+=world.ground('<path d="M-3 237H176Q181 283 130 298H18Q-4 297-3 275Z" fill="#D5E5DB"/><path d="M269 7H315Q338 7 338 36V102H269Z" fill="#D5E5DB"/>')
    out+='</g>'
    if phase>=1:
        out+='<g id="layer-road">'
        out+=world.ground(path(ROAD,'none','#C2CFD1',80)+path(ROAD,'none','#FAFBF9',76)+path(ROAD,'none','#91A5B0',63)+path(ROAD,'none','#F8FAF7',1.4,extra='stroke-dasharray="9 10"'))
        # Curb joints, crosswalk and drainage grates.
        out+=world.ground(''.join(f'<path d="M{xx} 168v6M{xx} 237v6" stroke="#B8C7CC" stroke-width="1"/>' for xx in range(12,133,12)))
        out+=world.ground(''.join(f'<rect x="{xx}" y="179" width="4" height="19" rx=".5" fill="#F8FAF7"/>' for xx in range(21,49,6)))
        out+=world.ground('<g stroke="#637E8C" stroke-width="1"><path d="M191 110h8m-8 3h8m-8 3h8M65 247h8m-8 3h8m-8 3h8"/></g>')
        out+='</g>'
    if phase>=2:
        out+='<g id="layer-architecture"><g id="object-townhouse">'+townhouse(world)+'</g><g id="object-pavilion">'+pavilion(world)+'</g></g>'
        out+='<g id="layer-landscape">'
        # Small park walk, bench, natural canopies and street furniture.
        out+=world.ground('<path d="M87 244Q97 263 111 276H171" stroke="#F4F4E9" stroke-width="10" stroke-linecap="round" fill="none"/>')
        out+='<g id="object-bench">'+bench(world,131,278)+'</g>'
        for i,(x,y,r) in enumerate([(34,263,18),(66,277,17),(112,246,16),(304,50,19),(315,88,16),(160,80,14)]):
            out+=f'<g id="object-tree-{i}">'+tree(world,x,y,r)+'</g>'
        out+='<g id="object-lamps">'+lamp(world,159,244)+lamp(world,190,89)+'</g>'
        out+='</g>'
    if phase>=3:
        poses=[(125,205,0),(202,178,-45),(235,112,-90)]
        out+='<g id="layer-vehicle">'+car(world,*poses[vehicle_pose])+'</g>'
    if phase>=4:
        # Brand sign is a graphic overlay, not an operational location indicator.
        px,py=world.p(236,13,26)
        out+='<g id="layer-brand-sign">'
        out+=f'<path d="M{px} {py+24}v21" stroke="{N}" stroke-width="1.6"/>'
        out+=f'<circle cx="{px}" cy="{py}" r="27" fill="{WHITE}" stroke="#D7E1E2"/>'
        out+=brand_mark(px,py,.37)+'</g>'
    return out+'</g>'

def svg(content,label,w=390,h=844):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-label="{html.escape(label)}"><title>{html.escape(label)}</title><rect width="{w}" height="{h}" fill="{PAPER}"/><g font-family="Manrope,Arial,sans-serif">{content}</g></svg>'

def scene_group(view='iso',phase=4,pose=0,header=False):
    if view=='iso':
        x,y,s=(14,270,.60) if not header else (14,71,.60)
    else:
        x,y,s=(-14,249,.88) if not header else (-14,44,.88)
    return f'<g transform="translate({x} {y}) scale({s})">{scene(view,phase,pose)}</g>'

def splash(view='iso',phase=4,pose=0):
    content=scene_group(view,phase,pose)
    if phase>=4:
        content+=f'<path d="{WORD}" transform="translate(75 329) scale(1.5)" fill="none" stroke="{N}" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/>'
    return svg(content,f'Splash v2 {view}: ilustración propia provisional, sin animación')

def login(header_only=False):
    out=brand_mark(37,47,.25)+txt(61,54,'URBES',20,800)
    out+=scene_group('iso',4,2,True)
    if not header_only:
        out+=txt(24,365,'Bienvenido.',32,750)
        out+=txt(24,399,'Consulta el estado de tu vehículo',15,400,'#44474D')
        out+=txt(24,422,'y sus alertas.',15,400,'#44474D')
        for label,placeholder,y in [('Correo','tu-correo@example.invalid',465),('Contraseña','Ingresa tu contraseña',565)]:
            out+=txt(24,y,label,14,650)
            out+=f'<rect x="24" y="{y+12}" width="342" height="56" rx="16" fill="white" stroke="#C5C6CE"/>'
            out+=txt(40,y+47,placeholder,15,400,'#526078')
            if label=='Contraseña':
                out+=f'<g transform="translate(336 {y+40})" fill="none" stroke="{N}" stroke-width="1.6"><path d="M-10 0Q0-12 10 0Q0 12-10 0Z"/><circle r="3"/></g>'
        out+='<rect x="24" y="672" width="342" height="56" rx="16" fill="'+N+'"/>'
        out+=txt(195,707,'Iniciar sesión',16,700,'white','middle')
        out+=txt(195,767,'Usa tu cuenta registrada.',13,400,'#526078','middle')
    return svg(out,'Login v2: ilustración isométrica y formulario de referencia estático')

def native():
    return svg('<g transform="translate(115 342)" fill="none" stroke="'+N+'" stroke-linecap="round"><path d="M70 40C70 54 70 68 70 80C70 95 70 107 70 120M90 40C90 54 90 68 90 80C90 95 90 107 90 120" stroke-width="3"/><path d="M80 58V66M80 77V85M80 96V104" stroke-width="2"/></g>','Arranque nativo vigente, conservado')

def figure(art,title,copy):
    return f'<figure>{art}<figcaption>{title}</figcaption><p>{copy}</p></figure>'

def main():
    ROOT.mkdir(exist_ok=True)
    artifacts={'splash-v2.svg':splash(),'splash-cenital.svg':splash('top'),'login-v2.svg':login(),'scene-isometric.svg':svg(scene(), 'Escena isométrica original URBES por capas',620,430),'scene-cenital.svg':svg(scene('top'), 'Escena cenital alternativa, mismos objetos y familia',500,430)}
    stages=[native(),splash(phase=1),splash(phase=2),splash(pose=0),login(True),login()]
    titles=['Arranque vigente','Suelo y carretera','Se construye el entorno','Vehículo y protección','Entrega a cabecera','Login disponible']
    captions=['Mismo vector nativo DEV. Enlace a escena nueva por validar.','Primero el plano vial: recorrido claro, bordillos y cruce peatonal.','Fachadas, parque, árboles y mobiliario aparecen por capas.','Auto orientado en la ruta. Escudo y nombre cierran la composición.','La escena pasa de y=270 a y=71, sin cambiar su perspectiva.','El formulario entra cuando es visible. La ilustración permanece quieta.']
    for i,art in enumerate(stages): artifacts[f'frame-{i}.svg']=art
    for name,art in artifacts.items(): (ROOT/name).write_text(art,encoding='utf-8')
    v1=ROOT.parent/'composition_v1'
    old_splash=(v1/'a-3.svg').read_text(encoding='utf-8')
    old_login=(v1/'login-ready.svg').read_text(encoding='utf-8')
    # Namespace IDs for repeated embedded SVGs; art contains no global CSS selectors.
    count=0
    def unique(art):
        nonlocal count
        count+=1
        return art.replace('id="',f'id="art-{count}-')
    comparison=''.join(figure(unique(art),title,copy) for art,title,copy in [(old_splash,'v1 · Splash','Carretera y símbolo: lenguaje lineal monocromático.'),(splash(),'v2 · Splash','Auto con volumen, arquitectura, vegetación y objetos viales.'),(old_login,'v1 · Login','Escena abstracta de parcelas y camino.'),(login(),'v2 · Login','Mismo entorno ilustrado del Splash, detenido y legible.')])
    directions=''.join(figure(unique(art),title,copy) for art,title,copy in [(splash(),'Isométrica 2.5D · recomendada','Más profundidad y reconocimiento de objetos. Requiere vistas del vehículo coherentes para girar.'),(splash('top'),'Cenital ilustrada · alternativa','Mismos colores y objetos, vistos desde arriba. Más sencilla para rumbo continuo; menor lectura de fachadas.')])
    story=''.join(figure(unique(art),f'{i+1}. {titles[i]}',captions[i]) for i,art in enumerate(stages))
    poses=''.join(figure(unique(svg(scene('iso',4,i),'Pose de rumbo isométrico, no animación',620,430)),title,copy) for i,title,copy in [(0,'Tramo de entrada','Auto paralelo al eje de carretera.'),(1,'Curva intermedia','Cambia la vista del auto; no se gira una imagen plana.'),(2,'Tramo de salida','Volumen y profundidad coherentes con el nuevo rumbo.')])
    CSS='''@font-face{font-family:Manrope;src:url('../assets/Manrope-variable.ttf') format('truetype');font-weight:200 800;font-display:swap}*{box-sizing:border-box}body{margin:0;background:#E9EDF2;color:#1B2B48;font-family:Manrope,Arial,sans-serif;line-height:1.6}main{max-width:1560px;margin:auto;padding:32px}h1{font-size:36px;letter-spacing:-1px;line-height:1.25;margin:16px 0}h2{font-size:25px;margin:0 0 8px;letter-spacing:-.4px}p{color:#44474D;max-width:85ch}nav{display:flex;flex-wrap:wrap;gap:8px 24px;margin:24px 0}a{color:#1B2B48;text-underline-offset:4px}nav a{min-height:48px;display:flex;align-items:center}a:focus-visible{outline:3px solid #1B2B48;outline-offset:4px}section{margin:48px 0}figure{margin:0;min-width:0}figure svg{display:block;width:100%;height:auto;border:1px solid #C5C6CE;border-radius:24px;background:#F8F9FA}figcaption{font-size:16px;font-weight:750;margin:14px 0 4px}figure p{font-size:13px;margin:0}.compare{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:24px}.pair{display:grid;grid-template-columns:repeat(2,minmax(0,390px));gap:40px}.story{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:18px}.poses{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}.notice{padding:16px 20px;border-left:3px solid #347E84;background:#F8F9FA}.swatches{display:flex;gap:20px;flex-wrap:wrap}.swatches div{display:flex;align-items:center;gap:8px;font-size:13px}.swatches span{width:28px;height:28px;border-radius:8px;display:block;border:1px solid #C5C6CE}footer{border-top:1px solid #C5C6CE;padding:16px 0}header{max-width:1000px}@media(max-width:1000px){.compare{grid-template-columns:repeat(2,minmax(0,1fr))}.story{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:620px){main{padding:24px 16px}h1{font-size:28px}.compare,.pair,.story,.poses{grid-template-columns:1fr}figure{max-width:390px;margin:auto;width:100%}}@media print{body{background:white}nav{display:none}section{break-inside:avoid}}'''
    def page(title,body):
        return f'<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src \'self\'; style-src \'self\' \'unsafe-inline\'; img-src \'self\'; font-src \'self\'; connect-src \'none\'; form-action \'none\'"><title>URBES · {title}</title><style>{CSS}</style><main>{body}</main></html>'
    palette=''.join(f'<div><span style="background:{c}"></span>{label} {c}</div>' for label,c in [('Marca',N),('Vehículo/vegetación',TEAL),('Luz',TEAL_LIGHT),('Tejados',CLAY),('Fondo',PAPER)])
    index=page('Composición v2',f'''<header><p>URBES Premium Redesign · composición v2 · 14 octubre 2026</p><h1>Una escena vial.<br>Una identidad que continúa.</h1><p>Más reconocimiento y profundidad: vehículo, arquitectura, vegetación y camino diseñados como una única familia. La ilustración tiene que funcionar detenida.</p><p class="notice">Dirección artística para aprobar. Vector original editable por capas, sin animaciones definitivas ni cambios en Flutter. Colores ilustrativos locales; Design System global intacto.</p><nav><a href="#comparison">v1 / v2</a><a href="#directions">Dos perspectivas</a><a href="#storyboard">Storyboard</a><a href="#heading">Giros del vehículo</a><a href="REVIEW.md">Decisiones</a><a href="LICENSES.md">Fuentes y licencias</a></nav></header><section id="comparison"><h2>Comparativa v1 / v2</h2><p>La v2 añade objetos reconocibles y un tratamiento de luz consistente. No es un cambio de color sobre la geometría anterior.</p><div class="compare">{comparison}</div></section><section id="directions"><h2>Dos perspectivas, una familia</h2><p>Recomendada: isométrica 2.5D para mayor riqueza estática. La cenital conserva el mismo mundo y permite comparar el coste visual de simplificar el movimiento.</p><div class="pair">{directions}</div></section><section><h2>Color controlado dentro de la ilustración</h2><div class="swatches">{palette}</div><p>Navy conserva la identidad. Teal y terracota distinguen vehículo, copas y tejados. Neutros, luces y sombras completan los volúmenes; estos colores no comunican conectividad ni estados operativos.</p></section><section id="storyboard"><h2>Storyboard actualizado</h2><p>Fotogramas clave sin interpolación. La entrada de controles se coordina con su visibilidad. No se fijan aún tiempos finales.</p><div class="story">{story}</div></section><section id="heading"><h2>El rumbo cambia la vista del auto</h2><p>Poses proyectadas sobre el mismo plano vial. Demuestran intención de orientación, no suavidad, velocidad ni rendimiento.</p><div class="poses">{poses}</div></section><section><h2>El acceso y las alertas tienen prioridad</h2><p>Movimiento reducido: omitir escena y entregar destino estático. Omitir por toque o salir a segundo plano: terminar sin repetición. Incidente crítico: retirar toda decoración inmediatamente; el router existente decide. Sesión abierta: no forzar Login. Teclado y texto grande: reducir cabecera decorativa y permitir scroll; autofill, validación y submit se conservan.</p></section><footer><p>Escudo y wordmark provisionales heredados de Brand Intro 01. Escena vectorial nueva creada para URBES; sin assets de stock dentro de Splash/Login. Referencias externas evaluadas por separado. Sin autorización para implementar.</p></footer>''')
    (ROOT/'index.html').write_text(index,encoding='utf-8')
    for name,title,body in [('comparison','v1 / v2',f'<div class="compare">{comparison}</div>'),('directions','Isométrica y cenital',f'<div class="pair">{directions}</div>'),('storyboard','Splash → Login',f'<div class="story">{story}</div>'),('heading','Tres poses de rumbo',f'<div class="poses">{poses}</div>')]:
        body='<h1>'+title+'</h1><p>URBES · composición v2 · propuesta estática, pendiente de aprobación</p>'+body+'<p><a href="index.html">Revisión completa</a></p>'
        (ROOT/f'{name}.html').write_text(page(title,body),encoding='utf-8')
    print(f'Generated {len(artifacts)} SVG and 5 HTML review documents.')

if __name__=='__main__':
    main()
