"""Review-only palette lab, composed from the existing HTML prototype."""
from pathlib import Path
import json,hashlib

ROOT=Path(__file__).resolve().parent
BASE=ROOT.parent

def luminance(color):
    rgb=[int(color[i:i+2],16)/255 for i in (1,3,5)]
    rgb=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    return sum(v*w for v,w in zip(rgb,[.2126,.7152,.0722]))

def contrast(a,b):
    x,y=sorted([luminance(a),luminance(b)])
    return (y+.05)/(x+.05)

def main():
    tokens=json.loads((ROOT/'tokens.json').read_text(encoding='utf-8'))
    c=tokens['color']
    pairs=[
        ('Navy anterior / blanco','#1B2B48','#FFFFFF',4.5),
        ('Navy marca / blanco',c['brand.navy'],c['surface.base'],4.5),
        ('Aqua original / blanco',c['brand.aqua'],c['surface.base'],3),
        ('Aqua original / navy',c['brand.aqua'],c['brand.navy'],4.5),
        ('Texto primario / canvas',c['text.primary'],c['surface.canvas'],4.5),
        ('Texto secundario / canvas',c['text.secondary'],c['surface.canvas'],4.5),
        ('Interacción oscura / blanco',c['action.secondary'],c['surface.base'],4.5),
        ('Navy / contenedor aqua',c['action.onSecondaryContainer'],c['action.secondaryContainer'],4.5),
        ('Foco / canvas',c['focus.ring'],c['surface.canvas'],3),
        ('Borde de control / blanco',c['border.control'],c['surface.base'],3),
        ('Verde de texto / tonal',c['status.success.text'],c['status.success.surface'],4.5),
        ('Ámbar de texto / tonal',c['status.warning.text'],c['status.warning.surface'],4.5),
        ('Crítico de texto / tonal',c['status.critical.text'],c['status.critical.surface'],4.5),
        ('Desconocido / tonal',c['status.unknown.text'],c['status.unknown.surface'],4.5),
        ('Texto deshabilitado / superficie',c['disabled.text'],c['disabled.surface'],4.5)
    ]
    results=[{'pair':name,'foreground':a,'background':b,'ratio':round(contrast(a,b),2),'target':target,'meets':contrast(a,b)>=target} for name,a,b,target in pairs]
    assert all(row['meets'] for row in results if not row['pair'].startswith('Aqua original / blanco'))
    assert not results[2]['meets']
    (ROOT/'contrast.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
    (ROOT/'tokens.js').write_text('window.URBES_PROPOSAL='+json.dumps({'tokens':tokens,'contrast':results},ensure_ascii=False)+';\n',encoding='utf-8')
    original=(BASE/'index.html').read_text(encoding='utf-8')
    page=original.replace('href="styles.css"','href="../styles.css"').replace('src="fixtures.js"','src="../fixtures.js"').replace('src="prototype.js"','src="../prototype.js"')
    page=page.replace('</head>','<link rel="stylesheet" href="lab.css"><script defer src="tokens.js"></script><script defer src="../motion_prototype_01/assets.js"></script><script defer src="../motion_prototype_01/vehicle.js"></script><script defer src="lab.js"></script></head>')
    page=page.replace('<title>URBES — Premium Redesign / Propuesta 01</title>','<title>URBES · Marca y componentes · propuesta provisional</title>')
    (ROOT/'index.html').write_text(page,encoding='utf-8')
    protected=[BASE/'motion_prototype_01'/name for name in ['logo.svg','assets.js','prototype.js','vehicle.js','index.html','styles.css']]
    (ROOT/'preserved-files.json').write_text(json.dumps({str(p.relative_to(BASE)):hashlib.sha256(p.read_bytes()).hexdigest() for p in protected},indent=2),encoding='utf-8')
    print(f'Built palette review; {len(results)} contrast pairs calculated. Brand animation only read, never edited.')

if __name__=='__main__':main()
