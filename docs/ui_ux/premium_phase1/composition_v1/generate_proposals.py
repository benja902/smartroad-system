"""Generate review-only SVG compositions and an offline storyboard. No app imports."""
from pathlib import Path
import html

ROOT = Path(__file__).resolve().parent
NAVY = '#1B2B48'
BG = '#F8F9FA'
INK = '#1B1B1E'
SECONDARY = '#44474D'
ROAD = 'M48 278V221C48 190 76 170 110 170H198C234 170 254 149 254 113V75'
SHIELD = 'M80 23C109 23 126 39 126 77C126 111 105 130 80 137C55 130 34 111 34 77C34 39 51 23 80 23Z'
WORD = 'M29 174V188Q29 194 36 194Q43 194 43 188V174M51 194V174H59Q65 174 65 180Q65 186 59 186H51M59 186L65 194M73 194V174H80Q87 174 87 179Q87 184 80 184H73M80 184Q88 184 88 189Q88 194 80 194H73M109 174H95V194H109M95 184H106M131 175Q117 170 117 180Q117 184 124 184Q132 184 132 189Q132 198 117 193'

def text(x, y, value, size=16, weight=500, fill=INK, anchor='start'):
    return f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{html.escape(value)}</text>'

def mark(x, y, scale=.5):
    return f'''<g transform="translate({x} {y}) scale({scale}) translate(-80 -80)" fill="none" stroke="{NAVY}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="{SHIELD}"/><path d="M80 69L63 87M80 69L97 87M80 69V108" stroke-width="2"/><g fill="{NAVY}" stroke="none"><circle cx="80" cy="69" r="3.5"/><circle cx="63" cy="87" r="3.5"/><circle cx="97" cy="87" r="3.5"/><circle cx="80" cy="108" r="3.5"/></g></g>'''

def car(x, y, angle=0):
    return f'''<g transform="translate({x} {y}) rotate({angle})"><rect x="-12" y="-19" width="26" height="42" rx="9" fill="{NAVY}" opacity=".08" transform="translate(2 3)"/><path d="M-5-18Q0-21 5-18L9-9 10 13Q9 19 5 19H-5Q-9 19-10 13L-9-9Z" fill="{NAVY}"/><path d="M-6-7L-4-14Q0-16 4-14L6-7Z" fill="#FFFFFF"/><path d="M-6 9H6L5 13H-5Z" fill="#FFFFFF" opacity=".65"/><path d="M-9-2V7M9-2V7" stroke="#FFFFFF" stroke-width="1.2" opacity=".45"/><path d="M-6-18H-3M3-18H6" stroke="#FFFFFF" stroke-width="1.5"/></g>'''

def environment():
    # Stylised roadside parcels, never a real map or live location.
    return f'''<g fill="{NAVY}" opacity=".045"><path d="M79 224Q79 205 98 205H157V274H98Q79 274 79 255Z"/><rect x="165" y="210" width="56" height="43" rx="12"/><rect x="26" y="103" width="70" height="34" rx="12"/><rect x="111" y="85" width="88" height="51" rx="14"/><rect x="288" y="94" width="41" height="95" rx="15"/></g><g fill="none" stroke="{NAVY}" stroke-opacity=".12" stroke-width="1"><path d="M90 221H143V259H90ZM176 221H210V242H176ZM122 96H188V124H122"/><path d="M35 112H86M35 119H86M35 126H86"/></g><g fill="{NAVY}" fill-opacity=".09"><circle cx="108" cy="293" r="9"/><circle cx="131" cy="293" r="9"/><circle cx="154" cy="293" r="9"/><circle cx="216" cy="69" r="9"/><circle cx="216" cy="46" r="9"/><circle cx="305" cy="221" r="13"/></g><g fill="none" stroke="{NAVY}" stroke-opacity=".2" stroke-width="1"><path d="M108 288V298M103 293H113M131 288V298M126 293H136M154 288V298M149 293H159M216 64V74M211 69H221M216 41V51M211 46H221"/></g>'''

def scene(mode='a', stage=3):
    result = '<g>'
    if stage >= 1:
        if mode == 'a' or stage >= 4:
            result += f'<path d="M7 255Q-3 184 30 152Q49 140 60 97Q71 42 149 35Q203 19 242 29Q330 38 341 111Q368 198 309 251Q275 290 205 300Q95 330 31 298Z" fill="{NAVY}" opacity=".025"/>'
            result += environment()
        result += f'<path d="{ROAD}" fill="none" stroke="#FFFFFF" stroke-width="43" stroke-linecap="round"/><path d="{ROAD}" fill="none" stroke="{NAVY}" stroke-opacity=".16" stroke-width="39" stroke-linecap="round"/><path d="{ROAD}" fill="none" stroke="{BG}" stroke-width="36" stroke-linecap="round"/><path d="{ROAD}" fill="none" stroke="{NAVY}" stroke-opacity=".28" stroke-width="1.5" stroke-dasharray="6 8"/>'
        # Roadside bollards and route nodes: illustrative, no operational state.
        result += f'<g fill="#FFFFFF" stroke="{NAVY}" stroke-opacity=".22"><circle cx="48" cy="278" r="5"/><circle cx="254" cy="75" r="5"/></g>'
        if mode == 'b' and stage >= 2 and stage < 4:
            trace = 'M48 278V245' if stage == 2 else 'M48 278V221C48 190 76 170 110 170H160'
            result += f'<path d="{trace}" fill="none" stroke="{NAVY}" stroke-width="2.5" stroke-linecap="round"/>'
    if stage >= 2:
        pos = (48, 245, 0) if stage == 2 else (160,170,90) if stage == 3 else (254,105,0)
        result += car(*pos)
    if stage >= 3:
        result += f'<circle cx="254" cy="44" r="32" fill="{BG}"/>' + mark(254,44,.48)
    return result + '</g>'

def native():
    return f'<g transform="translate(115 342)" fill="none" stroke="{NAVY}" stroke-linecap="round"><path d="M70 40C70 54 70 68 70 80C70 95 70 107 70 120M90 40C90 54 90 68 90 80C90 95 90 107 90 120" stroke-width="3"/><path d="M80 58V66M80 77V85M80 96V104" stroke-width="2"/></g>'

def login_content(state='ready'):
    small = state == 'keyboard'
    header_y = -25 if small else 0
    scene_y, scale = (48,.42) if small else (66,.85)
    out = f'<g transform="translate(0 {header_y})">' + text(24,51,'URBES',20,800,NAVY)
    out += f'<g transform="translate({(390-360*scale)/2} {scene_y}) scale({scale})">{scene("a",4)}</g>'
    out += '</g>'
    title_y = 225 if small else 378
    out += text(24,title_y,'Bienvenido.',32,750,NAVY)
    out += text(24,title_y+32,'Consulta el estado de tu vehículo',15,400,SECONDARY)
    out += text(24,title_y+55,'y sus alertas.',15,400,SECONDARY)
    field_y=title_y+95
    for label, value, y in [('Correo','tu-correo@example.invalid',field_y),('Contraseña','Ingresa tu contraseña',field_y+100)]:
        out += text(24,y,label,14,650,NAVY)
        out += f'<rect x="24" y="{y+12}" width="342" height="56" rx="16" fill="#FFFFFF" stroke="#C5C6CE"/>'
        out += text(40,y+47,value,15,400,SECONDARY)
        if label == 'Contraseña':
            out += f'<g transform="translate(336 {y+40})" stroke="{NAVY}" fill="none" stroke-width="1.5"><path d="M-10 0Q0-12 10 0Q0 12-10 0Z"/><circle r="3"/></g>'
    button_y=field_y+196
    if state == 'error':
        out += text(24,button_y-9,'Correo o contraseña incorrectos.',14,500,'#B52F34')
        button_y+=20
    out += f'<rect x="24" y="{button_y}" width="342" height="56" rx="16" fill="{NAVY}"/>'
    out += text(195,button_y+35,'Ingresando…' if state=='loading' else 'Iniciar sesión',16,700,'#FFFFFF','middle')
    if state == 'loading':
        out += text(195,button_y+86,'Envío en curso · sin espera decorativa',12,400,SECONDARY,'middle')
    if small:
        out += f'<rect y="652" width="390" height="192" fill="#DBD9DC"/>' + text(195,740,'Teclado del sistema',16,500,SECONDARY,'middle')
    return out

def svg(content, label):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844" role="img" aria-label="{html.escape(label)}"><title>{html.escape(label)}</title><rect width="390" height="844" fill="{BG}"/><g font-family="Manrope,Arial,sans-serif">{content}</g></svg>'''

def frame(mode, stage):
    if stage == 0:
        content = native()
    elif stage == 5:
        content = login_content()
    elif stage == 4:
        # Shared world already at its final login anchor; no duplicate scene.
        content = text(24,51,'URBES',20,800,NAVY)
        content += f'<g transform="translate(42 66) scale(.85)">{scene("a",4)}</g>'
    else:
        scale, x, y = (1,15,251) if mode=='a' else (1.16,-14,220)
        content = f'<g transform="translate({x} {y}) scale({scale})">{scene(mode,stage)}</g>'
        if stage>=3:
            content += f'<path d="{WORD}" transform="translate(75 357) scale(1.5)" fill="none" stroke="{NAVY}" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/>'
    return svg(content, f'Alternativa {mode.upper()}, fotograma {stage}: propuesta estática URBES')

NAMES=['Arranque compatible','La ruta aparece','Entra el vehículo','Cierre de marca','Entrega visual','Login disponible']
NOTES_A=['Carretera nativa vigente. No se exige trabajo de escena antes del primer frame.','Suelo, parcelas viales y carretera se revelan como capas, con cámara fija.','Vehículo cenital sobre la ruta; el entorno ya organiza la composición.','Escudo y nodos de Brand Intro. Nombre vectorial provisional legible.','Una sola escena se reduce hacia la cabecera; el nombre pasa a texto en cabecera.','Título y formulario aparecen cuando pueden verse; escena en reposo.']
NOTES_B=['Mismo primer fotograma que A y que Brand Intro 01.','Corredor ampliado; el entorno queda en segundo plano.','Vehículo parte hacia arriba y toma una curva continua; véase hoja de rumbo.','El vehículo gira hacia la derecha; la ruta y el escudo dan contexto de protección.','Termina el segundo giro. Cámara fija reduce la escena hasta el anclaje común.','Mismo Login: no se prolonga el recorrido ni se mueve el fondo mientras se escribe.']

def figure(source, caption, detail='', cls=''):
    return f'<figure class="{cls}">{source}<figcaption>{caption}</figcaption><p>{detail}</p></figure>'

def main():
    ROOT.mkdir(exist_ok=True)
    for mode in ('a','b'):
        for stage in range(6):
            (ROOT/f'{mode}-{stage}.svg').write_text(frame(mode,stage),encoding='utf-8')
    for state in ('ready','keyboard','error','loading'):
        (ROOT/f'login-{state}.svg').write_text(svg(login_content(state),f'Login propuesto: {state}; maqueta estática sin autenticación'),encoding='utf-8')
    # Direction sheet uses the same scene/path; no dependency on SVG motion support.
    direction = ''.join(figure(svg(f'<g transform="translate(15 251)">{scene("b",1)}{car(*pos)}</g>',label),label,'') for pos,label in [((48,245,0),'1. Rumbo arriba'),((78,180,60),'2. Curva hacia la derecha'),((160,170,90),'3. Rumbo derecha'),((246,142,25),'4. Curva hacia arriba'),((254,105,0),'5. Rumbo arriba')])
    hero = ''.join(figure(frame(mode,3),caption,detail) for mode,caption,detail in [('a','A · La ruta se construye','Escena por capas, más entorno y una lectura de marca equilibrada.'),('b','B · El vehículo guía','Corredor ampliado, recorrido protagonista y contexto más silencioso.')])
    hero += figure(svg(login_content(),'Login compartido propuesto'),'Login · La ruta permanece','La misma geometría pasa a la cabecera. Formulario y botones conservan sus responsabilidades.')
    story=''
    for mode,notes in [('a',NOTES_A),('b',NOTES_B)]:
        cards=''.join(figure(frame(mode,i),f'{i+1}. {NAMES[i]}',notes[i]) for i in range(6))
        story+=f'<section id="story-{mode}"><h2>Storyboard {mode.upper()}</h2><p>Fotogramas clave, sin interpolación ni tiempos exactos certificados. El paso 4→5 cambia la escala y posición de una única escena.</p><div class="story">{cards}</div></section>'
    states=''.join(figure(svg(login_content(s),f'Login {s}'),name,desc) for s,name,desc in [('keyboard','Teclado visible','Cabecera compacta; contenido desplazable en implementación futura.'),('error','Error','Mensaje asociado al formulario; la ilustración no se repite.'),('loading','Envío','Texto de estado inmediato; sin ilustración en bucle ni demora artificial.')])
    page=f'''<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self'; font-src 'self'; connect-src 'none'; form-action 'none'"><title>URBES · Composiciones Splash y Login v1</title><style>
@font-face{{font-family:Manrope;src:url('../assets/Manrope-variable.ttf') format('truetype');font-weight:200 800;font-display:swap}}*{{box-sizing:border-box}}body{{margin:0;background:#edf0f4;color:{NAVY};font-family:Manrope,Arial,sans-serif;line-height:1.6}}main{{max-width:1440px;margin:auto;padding:44px 32px}}header{{max-width:850px}}h1{{font-size:36px;line-height:1.2;letter-spacing:-1px;margin:12px 0 20px}}h2{{font-size:26px;letter-spacing:-.5px;margin:0 0 8px}}p{{color:{SECONDARY};max-width:78ch}}a{{color:{NAVY};text-underline-offset:4px}}a:focus-visible{{outline:3px solid {NAVY};outline-offset:4px}}nav{{display:flex;flex-wrap:wrap;gap:12px 24px;margin:24px 0}}nav a{{min-height:48px;display:flex;align-items:center}}section{{margin:52px 0}}.comparison{{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:40px}}figure{{margin:0;min-width:0}}figure svg{{display:block;width:100%;height:auto;border:1px solid #C5C6CE;border-radius:24px;background:{BG}}}figcaption{{font-size:18px;font-weight:750;margin:16px 0 4px}}figure p{{font-size:14px;margin:0}}.story{{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:20px;margin-top:24px}}.story figcaption{{font-size:14px}}.story p{{font-size:12px}}.directions{{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:20px}}.notice{{padding:16px 20px;border-left:3px solid {NAVY};background:{BG}}}.tag{{font-size:14px;font-weight:650}}footer{{border-top:1px solid #C5C6CE;padding:24px 0}}@media(max-width:900px){{.comparison{{gap:20px}}.story{{grid-template-columns:repeat(3,minmax(0,1fr))}}.directions{{grid-template-columns:repeat(3,minmax(0,1fr))}}}}@media(max-width:600px){{main{{padding:24px 20px}}h1{{font-size:28px}}.comparison,.story,.directions{{grid-template-columns:1fr}}figure{{max-width:390px;width:100%;margin:0 auto 24px}}}}@media print{{body{{background:white}}main{{padding:12px}}nav{{display:none}}section{{break-inside:avoid}}}}
</style><main><header><span class="tag">URBES Premium Redesign · Fase 1 · 14 octubre 2026</span><h1>Una ruta propia.<br>Dos formas de presentarla.</h1><p>Propuestas vectoriales para revisión. A desarrolla la aparición de capas; B da protagonismo al recorrido del vehículo. Un Login común mantiene la continuidad de marca.</p><p class="notice">Maquetas estáticas, sin código Flutter, autenticación, navegación ni conexión a servicios. Las curvas, tiempos y recursos son candidatos; esta página no demuestra fluidez Android.</p><nav><a href="#compositions">Composiciones</a><a href="#story-a">Storyboard A</a><a href="#story-b">Storyboard B</a><a href="#directions">Rumbo del vehículo</a><a href="#states">Estados Login</a><a href="REVIEW.md">Informe de revisión</a></nav></header><section id="compositions"><h2>Composiciones para comparar</h2><p>Perspectiva cenital y lenguaje vectorial plano: navy, superficies frías y trazos del sistema existente. La complejidad se concentra en la escena vial.</p><div class="comparison">{hero}</div></section>{story}<section id="directions"><h2>El vehículo sigue la carretera</h2><p>Hoja de rumbo de B. El pivote es el centro del vehículo; orientación inicial hacia arriba. La cámara no gira. Son poses de referencia, no muestras de una animación implementada.</p><div class="directions">{direction}</div></section><section id="states"><h2>El acceso conserva prioridad</h2><p>Variantes de presentación. No añaden contratos ni acciones a la aplicación. Mostrar contraseña ya existe en el HTML anterior, pero aún no en Login Flutter.</p><div class="comparison">{states}</div></section><section><h2>Interrupciones y movimiento reducido</h2><p>Movimiento reducido: omitir Splash y mostrar Login estático. Omitir o salir a segundo plano: terminar escena sin repetirla al volver. Incidente crítico: retirar toda decoración inmediatamente y dejar actuar al router existente. Sesión abierta: entregar al destino resuelto, sin mostrar Login ni cambiar su estado.</p><p>La continuidad propuesta conserva ruta, vehículo y escudo como una única escena entre cierre y cabecera. El wordmark vectorial se desvanece; el texto de cabecera aparece sin intentar deformar letras. Los controles se presentan cuando quedan visibles, con acciones disponibles desde ese momento.</p></section><footer><p>Referencia interna. No se incorporan imágenes ni videos externos a estas propuestas. Escudo y wordmark provisionales de Brand Intro 01; geometría vial nueva creada para esta revisión. D1–D3 siguen pendientes. Sin aprobación para implementar.</p></footer></main></html>'''
    (ROOT/'index.html').write_text(page,encoding='utf-8')
    # Compact presentation boards for exports and direct review.
    style = page.split('<style>')[1].split('</style>')[0]
    for name,title,body in [('comparison','Splash y Login · dos alternativas',f'<div class="comparison">{hero}</div>'),('storyboard-a','A · La ruta se construye',f'<div class="story">'+''.join(figure(frame('a',i),f'{i+1}. {NAMES[i]}',NOTES_A[i]) for i in range(6))+'</div>'),('storyboard-b','B · El vehículo guía',f'<div class="story">'+''.join(figure(frame('b',i),f'{i+1}. {NAMES[i]}',NOTES_B[i]) for i in range(6))+'</div>')]:
        board=f'<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>URBES · {title}</title><style>{style}main{{padding-top:24px}}h1{{font-size:26px}}</style><main><h1>{title}</h1><p>URBES · Propuesta visual v1 · Fotogramas estáticos, sin aprobación para implementar.</p>{body}<p><a href="index.html">Volver a la revisión completa</a></p></main></html>'
        (ROOT/f'{name}.html').write_text(board,encoding='utf-8')
    print('Generated 16 SVG compositions and offline review page.')

if __name__ == '__main__':
    main()
