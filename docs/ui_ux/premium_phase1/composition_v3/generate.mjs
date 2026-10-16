// Export the existing Motion renderer. No second playback engine or review controls.
import {spawn} from 'node:child_process';
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import {join,resolve,dirname,basename} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import assert from 'node:assert/strict';
const root=dirname(fileURLToPath(import.meta.url)),motion=join(root,'..','motion_prototype_01');
const names=['index.html','styles.css','assets.js','vehicle.js','prototype.js','logo.svg'];
const hashes=Object.fromEntries(await Promise.all(names.map(async n=>[n,createHash('sha256').update(await readFile(join(motion,n))).digest('hex')])));
hashes['../assets/Manrope-variable.ttf']=createHash('sha256').update(await readFile(join(root,'..','assets','Manrope-variable.ttf'))).digest('hex');
if(process.argv.includes('--check')){
  const manifest=JSON.parse(await readFile(join(root,'manifest.json'),'utf8'));
  const changed=Object.keys(hashes).filter(n=>hashes[n]!==manifest.source_hashes[n]);
  console.log(changed.length?'Regenerate v3; changed sources: '+changed.join(', '):'V3 matches current Motion sources.');
  process.exit(changed.length?1:0);
}
const objects=[
  ['S','Suelo','layer-ground'],['R','Carretera','layer-road'],
  ['T1','Árbol del parque · izquierda','object-tree-0'],['T2','Árbol del parque · abajo','object-tree-1'],['T3','Árbol junto al banco','object-tree-2'],
  ['M','Banco','object-bench'],['P','Pabellón','object-pavilion'],
  ['C','Casa','object-townhouse'],['T6','Árbol junto a la casa','object-tree-5'],['L','Farolas','object-lamps'],
  ['T4','Árbol al final de carretera','object-tree-3'],['T5','Árbol junto al vehículo','object-tree-4'],['V','Vehículo','layer-vehicle'],['U','Isotipo URBES','brand-symbol']
];
const common=[[0,'Arranque directo'],[650,'Entorno en construcción'],[1100,'Entorno construido'],[1800,'Aparece el isotipo']];
const refinedStart=[[600,'Entra el vehículo'],[720,'Comienza la entrada del isotipo'],[840,'Isotipo apareciendo'],[960,'Isotipo visible']];
const beaconStart=[[840,'Isotipo apareciendo'],[1560,'Baliza flotando'],[2160,'Estable antes del encuentro'],[2400,'Comienza el impulso']];
const later=[[2510,'Reacción al vehículo'],[3100,'Isotipo en movimiento'],[3450,'Marca reunida'],[3800,'Entrega a cabecera'],[4200,'Formulario entrando'],[4440,'Login disponible']];
const profile=await mkdtemp(join(tmpdir(),'urbes-v3-export-'));
const browser=spawn('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',['--headless','--no-sandbox','--disable-gpu','--disable-background-networking','--disable-component-update','--disable-sync','--disable-extensions','--no-first-run','--no-default-browser-check',`--user-data-dir=${profile}`,'--remote-debugging-address=127.0.0.1','--remote-debugging-port=0',pathToFileURL(join(motion,'index.html')).href],{windowsHide:true,stdio:'ignore'});
let ws;const errors=[];const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function waitFor(fn){const end=Date.now()+15000;while(Date.now()<end){try{const v=await fn();if(v)return v;}catch{}await sleep(100);}throw Error('Browser initialization timed out');}
const escape=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
function namespace(svg,key){return svg.replace(/\bid="([^"]+)"/g,(_,id)=>`id="${key}-${id}"`).replace(/(href|for)="(#?)([^"#]+)"/g,(whole,attr,hash,id)=>hash||attr==='for'?`${attr}="${hash}${key}-${id}"`:whole);}
try{
  console.log('Exporting current Motion states…');
  const port=await waitFor(async()=>Number((await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]));
  const target=await waitFor(async()=>(await(await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(t=>t.type==='page'&&t.url.startsWith('file:')));
  ws=new WebSocket(target.webSocketDebuggerUrl);await new Promise((yes,no)=>{ws.onopen=yes;ws.onerror=no;});
  let seq=0;const pending=new Map();
  ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.text);if(m.id){const p=pending.get(m.id);if(!p)return;clearTimeout(p.timer);pending.delete(m.id);m.error?p.no(Error(m.error.message)):p.yes(m.result);}};
  const call=(method,params={})=>new Promise((yes,no)=>{const id=++seq,timer=setTimeout(()=>no(Error('CDP timeout: '+method)),15000);pending.set(id,{yes,no,timer});ws.send(JSON.stringify({id,method,params}));});
  const ev=async expression=>{const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
  await call('Runtime.enable');await call('Page.enable');
  await call('Emulation.setDeviceMetricsOverride',{width:1240,height:1200,deviceScaleFactor:1,mobile:false});
  await waitFor(()=>ev('typeof MotionPrototype!=="undefined"'));await ev('document.fonts.ready.then(()=>true)');
  // Export DOM state from the real prototype, including actual HTML reveal styles.
  await ev(`window.exportMotionFrame=function(){
    const ns='http://www.w3.org/2000/svg',clone=document.getElementById('stage').cloneNode(true);
    clone.removeAttribute('id');clone.removeAttribute('style');clone.removeAttribute('aria-hidden');
    clone.setAttribute('xmlns',ns);clone.setAttribute('viewBox','0 0 390 844');clone.setAttribute('role','img');
    const bg=document.createElementNS(ns,'rect');bg.setAttribute('width','390');bg.setAttribute('height','844');bg.setAttribute('fill','#F8F9FA');clone.prepend(bg);
    const source=document.getElementById('login');
    if(!source.hidden){
      const block=source.cloneNode(true),properties=['display','box-sizing','position','left','right','top','bottom','width','height','margin-top','margin-right','margin-bottom','margin-left','padding-top','padding-right','padding-bottom','padding-left','font-family','font-size','font-weight','line-height','letter-spacing','color','background-color','border-top','border-right','border-bottom','border-left','border-radius','opacity','transform','visibility','gap','grid-template-columns','align-items','text-align','fill','stroke','stroke-width'];
      const originals=[source,...source.querySelectorAll('*')],copies=[block,...block.querySelectorAll('*')];
      originals.forEach((n,i)=>{const style=getComputedStyle(n);for(const p of properties)copies[i].style.setProperty(p,style.getPropertyValue(p));if(copies[i].tagName==='BUTTON')copies[i].disabled=true;});
      block.style.position='relative';block.style.left='0';block.style.right='auto';block.style.top='0';block.style.margin='0';block.setAttribute('xmlns','http://www.w3.org/1999/xhtml');
      const foreign=document.createElementNS(ns,'foreignObject');foreign.setAttribute('x','24');foreign.setAttribute('y','340');foreign.setAttribute('width','342');foreign.setAttribute('height','490');foreign.append(block);clone.append(foreign);
    }
    return new XMLSerializer().serializeToString(clone);
  };`);
  const records=[];
  async function frame(mode,time,title,key){
    await ev(`MotionPrototype.setMode('${mode}');MotionPrototype.seek(${time})`);
    assert.equal(await ev(`!MotionPrototype.state().running&&MotionPrototype.state().time===${time}`),true);
    const svg=namespace(await ev('exportMotionFrame()'),key).replace('role="img"',`role="img" aria-label="${escape(title)} · ${time} ms"`);
    records.push({key,mode,time_ms:time,title});
    return `<figure>${svg}<figcaption><strong>${escape(title)}</strong>${({impulse:'A',activation:'B',refined:'C',beacon:'D'})[mode]} · ${time} ms<br><a href="../motion_prototype_01/index.html?mode=${mode}&amp;t=${time}">Ver este instante en Motion</a></figcaption></figure>`;
  }
  const initial=[];for(const [t,title] of common)initial.push(await frame('impulse',t,title,'common-'+t));
  const variants={};for(const mode of ['impulse','activation','refined','beacon']){variants[mode]=[];for(const [t,title] of (mode==='beacon'?[...beaconStart,...later]:mode==='refined'?[...refinedStart,...later]:later))variants[mode].push(await frame(mode,t,title,mode+'-'+t));console.log('Exported '+mode);}
  // Normalize the existing scene to its world frame only for the labelled map.
  await ev("MotionPrototype.setMode('impulse');MotionPrototype.seek(2600)");
  const map=await ev(`(()=>{
    const ns='http://www.w3.org/2000/svg',source=document.getElementById('stage'),scene=document.getElementById('scene-wrap'),inverse=scene.getCTM().inverse();
    const objects=${JSON.stringify(objects)};
    const anchors=objects.map(([code,label,id])=>{const n=document.getElementById(id),b=n.getBBox(),p=new DOMPoint(b.x+b.width/2,b.y+b.height/2).matrixTransform(inverse.multiply(n.getCTM()));return {code,label,id,x:p.x+150,y:p.y+50};});
    const svg=document.createElementNS(ns,'svg');svg.setAttribute('xmlns',ns);svg.setAttribute('viewBox','0 0 920 560');svg.setAttribute('class','object-map');svg.setAttribute('role','img');svg.setAttribute('aria-label','Mapa de objetos de la escena actual');
    svg.append(source.querySelector('defs').cloneNode(true));const g=document.createElementNS(ns,'g');g.setAttribute('transform','translate(150 50)');
    const art=scene.cloneNode(true);art.removeAttribute('transform');g.append(art);
    const mark=document.getElementById('brand-symbol').cloneNode(true),m=inverse.multiply(document.getElementById('brand-symbol').getCTM());mark.setAttribute('transform','matrix('+[m.a,m.b,m.c,m.d,m.e,m.f].join(' ')+')');g.append(mark);svg.append(g);
    return {svg:new XMLSerializer().serializeToString(svg),anchors};
  })()`);
  const shortLabels={T1:'Parque · izquierda',T2:'Parque · abajo',T3:'Junto al banco',T4:'Final de carretera',T5:'Junto al vehículo',T6:'Junto a la casa'};
  let labels='';map.anchors.forEach((o,i)=>{const left=i<7,y=48+(i%7)*73,x=left?14:790,end=left?128:790;
    labels+=`<path d="M${o.x} ${o.y}L${end} ${y+10}" fill="none" stroke="#75777E" stroke-width=".8"/><circle cx="${o.x}" cy="${o.y}" r="3" fill="#006D68"/><rect x="${x}" y="${y-4}" width="116" height="36" rx="6" fill="#FFFFFF" stroke="#C5C6CE"/><text x="${x+8}" y="${y+10}" fill="#031B3B" font-family="Manrope,Arial,sans-serif" font-size="12" font-weight="800">${o.code}</text><text x="${x+8}" y="${y+24}" fill="#44474D" font-family="Manrope,Arial,sans-serif" font-size="10">${escape(shortLabels[o.code]||o.label)}</text>`;
  });
  const mapSvg=namespace(map.svg.replace('</svg>',labels+'</svg>'),'map');
  const legend=objects.map(([code,label,id])=>`<p><strong>${code} — ${escape(label)}</strong><br><code>${id}</code></p>`).join('');
  const page=`<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data:; connect-src 'none'; form-action 'none'"><title>URBES · Composition v3 · referencia Motion</title><link rel="stylesheet" href="styles.css"></head><body><main><header><p>URBES · Composition v3 · 16 octubre 2026</p><h1>Señala el objeto.<br>Localiza el instante.</h1><p>Referencia estática generada desde Motion Prototype 01. El dibujo y los tiempos proceden del prototipo actual; v2 se conserva como antecedente.</p><p class="notice">A, B, C y D pendientes de selección. Esta página no reproduce animaciones: cada enlace abre el reproductor existente detenido en ese instante. Después de editar Motion hay que regenerar esta referencia.</p><nav><a href="#map">Mapa de objetos</a><a href="#common">Inicio compartido</a><a href="#a">A · Impulso</a><a href="#b">B · Activación</a><a href="#c">C · Impulso refinado</a><a href="#d">D · Baliza flotante</a><a href="../motion_prototype_01/index.html">Abrir Motion</a><a href="README.md">Cómo editar y regenerar</a></nav></header><section id="map"><h2>Mapa de objetos</h2><p>Usa estos códigos o señala el objeto en una captura. El mapa normaliza el encuadre para identificar piezas; no representa un fotograma adicional. T4 pertenece a A/B y está retirado en C/D.</p>${mapSvg}<div class="legend">${legend}</div></section><section class="examples"><h2>Cómo indicar una corrección</h2><p>«Quita T3 de toda la escena». «En A, a 650 ms, T2 todavía no debería aparecer». «En B, a 3100 ms, mueve el isotipo más a la derecha».</p><p>El instante identifica el problema. La corrección se aplica al objeto o a su animación, después se regenera esta página.</p></section><section id="common"><h2>Inicio compartido por A y B</h2><p>Estas cuatro instantáneas usan A; B comparte exactamente la construcción inicial. No es una sucesión de archivos que Motion reproduce.</p><div class="frames common">${initial.join('')}</div></section><section id="a"><h2>A · Impulso</h2><p>Reacción más expresiva y arco amplio. Tiempos desde el inicio del recorrido A, duración total 4440 ms.</p><div class="frames">${variants.impulse.join('')}</div></section><section id="b"><h2>B · Activación</h2><p>Señal breve y salida más contenida. Tiempos desde el inicio del recorrido B, duración total 4440 ms.</p><div class="frames">${variants.activation.join('')}</div></section><section id="c"><h2>C · Impulso refinado</h2><p>Sin T4 y con el isotipo en su posición original. Auto desde 600 ms; isotipo desde 720 ms, entrada de 240 ms. Después conserva el impulso y la entrega de A. Total 4440 ms.</p><div class="frames">${variants.refined.join('')}</div></section><section id="d"><h2>D · Baliza flotante</h2><p>Conserva C para comparar. Una elevación suave de 2 px con sombra tenue, reposo antes del encuentro y reacción de 3 px en el sentido del auto. Sin T4; entrada 720–960 ms y duración total 4440 ms.</p><div class="frames">${variants.beacon.join('')}</div></section><footer><p>36 instantáneas de revisión; no todos los fotogramas. Controles, omisión, movimiento reducido y prioridad crítica permanecen en Motion. Sin cambios Flutter, autenticación ni servicios reales.</p><p><a href="manifest.json">Fuentes, tiempos y hashes</a> · <a href="../composition_v2/index.html">Antecedente v2</a></p></footer></main></body></html>`;
  // Refuse a mixed snapshot if the source changed during export.
  for(const n of names)assert.equal(createHash('sha256').update(await readFile(join(motion,n))).digest('hex'),hashes[n],n+' changed during export');
  await writeFile(join(root,'index.html'),page);
  await writeFile(join(root,'manifest.json'),JSON.stringify({review_date:'2026-10-16',provisional:true,source:'../motion_prototype_01/',source_hashes:hashes,frames:records,objects:map.anchors},null,2));
  await call('Page.navigate',{url:pathToFileURL(join(root,'index.html')).href});
  await waitFor(()=>ev('document.readyState==="complete"&&document.title.includes("Composition v3")'));await ev('document.fonts.ready.then(()=>true)');
  assert.equal(await ev('document.querySelectorAll("figure").length'),36);
  assert.equal(await ev('[...document.querySelectorAll("button,select,script")].filter(n=>!n.closest("foreignObject")).length'),0);
  assert.equal(await ev('[...document.querySelectorAll("button")].every(n=>n.disabled)'),true);
  assert.equal(await ev('(()=>{const ids=[...document.querySelectorAll("[id]")].map(n=>n.id);return ids.length===new Set(ids).size;})()'),true);
  assert.equal(await ev('document.querySelectorAll(".legend p").length'),14);
  assert.equal(await ev('[...document.querySelectorAll("figure a")].every(a=>a.getAttribute("href").startsWith("../motion_prototype_01/index.html?mode="))'),true);
  assert.equal(await ev('document.querySelectorAll("#a foreignObject,#b foreignObject,#c foreignObject,#d foreignObject").length'),8);
  assert.equal(await ev('[...document.querySelectorAll("use")].every(n=>document.getElementById(n.getAttribute("href").slice(1)))'),true);
  assert.equal(await ev('(()=>{const trees=[...document.querySelectorAll("#c [id]")].filter(n=>n.id.endsWith("object-tree-3"));return trees.length===10&&trees.every(n=>getComputedStyle(n).display==="none");})()'),true);
  await writeFile(join(root,'review.png'),Buffer.from((await call('Page.captureScreenshot',{format:'png'})).data,'base64'));
  await ev('document.getElementById("d").scrollIntoView()');
  await writeFile(join(root,'storyboard.png'),Buffer.from((await call('Page.captureScreenshot',{format:'png'})).data,'base64'));
  await call('Emulation.setDeviceMetricsOverride',{width:320,height:920,deviceScaleFactor:1,mobile:false});
  assert.equal(await ev('document.documentElement.scrollWidth<=320'),true);
  assert.equal(errors.length,0,'No runtime exceptions');
  await writeFile(join(root,'validation.json'),JSON.stringify({passed:true,frames:36,objects:14,no_new_playback_controls:true,unique_ids:true,login_snapshots:8,no_page_overflow_at_320:true,source_hashes_verified:true,errors,android_performance_measured:false},null,2));
  console.log('Verified 36 frames, 14 objects, unique IDs, eight Login snapshots, no controls and 320px layout.');
  await call('Browser.close').catch(()=>{});
}finally{
  if(ws)ws.close();if(browser.exitCode===null){await Promise.race([new Promise(r=>browser.once('exit',r)),sleep(1500)]);if(browser.exitCode===null)browser.kill();}
  const checked=resolve(profile);if(dirname(checked)!==resolve(tmpdir())||!basename(checked).startsWith('urbes-v3-export-'))throw Error('Unexpected cleanup path');
  await rm(checked,{recursive:true,force:true,maxRetries:3,retryDelay:200});
}
