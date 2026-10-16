/* Ephemeral design review: existing compositions, identical fixtures, palette comparison. */
(function(){
  'use strict';
  const sources=Array.from(document.querySelectorAll('.gallery .phone'));
  if(sources.length!==4)throw Error('Expected four existing review compositions');
  const library=document.querySelector('.svg-library');
  const root=document.createElement('main');root.className='brand-review';
  root.innerHTML=`<header class="lab-head"><p>Smart Road System Urbes · Propuesta de marca y componentes · 15 octubre 2026</p><h1>Una marca. Roles claros.<br>Componentes que continúan.</h1><p>Comparación controlada de paletas sobre las composiciones existentes. Mismos datos ficticios y estructura en ambos lados; no representa el frontend Flutter actual ni aprueba Design System v1.0.</p><div class="review-tools"><label for="review-screen">Pantalla</label><select id="review-screen"><option value="0">Login</option><option value="1" selected>Inicio</option><option value="2">Alertas</option><option value="3">Emergencia</option><option value="all">Todas</option></select><label for="review-scale">Texto</label><select id="review-scale"><option value="1">100 %</option><option value="1.5">150 %</option><option value="2">200 %</option></select><a href="COMPONENTS.md">Inventario y mapa</a><a href="REVIEW.md">Roles y decisiones</a></div><p class="lab-notice">Navy anterior: #1B2B48. Candidato: #031B3B. Aqua original se conserva en el logo; para foco y texto interactivo se explora #006D68. Las vistas son muestras estáticas con scroll: sus acciones están deshabilitadas.</p></header><div id="comparisons"></div><section class="bench candidate"><h2>Estados de componentes · candidatos</h2><p>Referencia de controles reutilizables; estos botones no ejecutan acciones del producto. El estado funcional siempre provendrá del contrato real.</p><div class="bench-controls"><button class="sample-primary" type="button">Iniciar sesión</button><button class="sample-tonal" type="button">Acción secundaria</button><button class="sample-primary force-focus" type="button">Foco visible</button><button class="sample-disabled" disabled>Deshabilitado</button><button class="sample-primary" disabled aria-busy="true">Ingresando…</button></div><label for="sample-field">Correo · foco, texto y borde</label><input id="sample-field" class="sample-field" readonly value="demo@example.invalid"><div class="role-samples"><span class="role success">● Estado confirmado</span><span class="role warning">▲ Requiere atención</span><span class="role critical">! Incidente crítico</span><span class="role unknown">? Sin datos</span></div><p class="sample-error">Error de interfaz: mensaje asociado a la operación. No es una severidad de incidente.</p><output id="sample-status" role="status"></output></section><section class="contrast-section"><h2>Contraste medido</h2><p>Validación de pares, no certificación integral. Aqua sobre blanco falla para texto ordinario y límites funcionales; el archivo del logo no se recolorea.</p><div class="contrast-scroll"><table><thead><tr><th>Par</th><th>Ratio</th><th>Objetivo</th><th>Resultado</th></tr></thead><tbody id="contrast-body"></tbody></table></div></section><footer><p>SVG original intacto. Solo se dispone aquí de la versión clara suministrada; variantes oscuras y monocromáticas pendientes de recibir y comprobar. No se sintetizan recoloreando el original.</p><p><a href="../motion_prototype_01/index.html">Motion Prototype 01 intacto</a> · <a href="../../../UI_UX_PHASE1_SPEC.md">Borrador UI/UX actualizado</a></p></footer>`;
  document.body.replaceChildren(library,root);
  const c=URBES_PROPOSAL.tokens.color;
  const aliases={'--navy':'action.primary','--canvas':'surface.canvas','--surface':'surface.base','--ink':'text.primary','--secondary':'text.secondary','--line':'border.decorative','--soft':'surface.subtle','--green':'status.success.text','--green-bg':'status.success.surface','--amber':'status.warning.text','--amber-bg':'status.warning.surface','--red':'status.critical.text','--red-bg':'status.critical.surface','--aqua':'brand.aqua','--interaction':'action.secondary','--accent-container':'action.secondaryContainer','--control-border':'border.control','--heading':'text.heading'};
  function candidateTokens(node){for(const [key,role] of Object.entries(aliases))node.style.setProperty(key,c[role]);}
  const names=['Login','Inicio','Alertas','Emergencia'];
  const rows=[];
  sources.forEach((source,index)=>{
    const row=document.createElement('section');row.className='comparison-row';row.dataset.screen=index;
    const title=document.createElement('h2');title.textContent=names[index];row.append(title);
    const pair=document.createElement('div');pair.className='palette-pair';
    for(const candidate of [false,true]){
      const column=document.createElement('article');column.className=candidate?'palette candidate':'palette previous';
      const heading=document.createElement('h3');heading.textContent=candidate?'Candidata · Navy de marca + Aqua':'Anterior · Navy del prototipo HTML';
      const phone=source.cloneNode(true);phone.querySelectorAll('[id]').forEach(el=>{const old=el.id;el.id=`${candidate?'new':'old'}-${index}-${old}`;phone.querySelectorAll('label').forEach(l=>{if(l.htmlFor===old)l.htmlFor=el.id;});phone.querySelectorAll('[aria-describedby]').forEach(el=>el.removeAttribute('aria-describedby'));});
      phone.querySelectorAll('form').forEach(form=>{const block=document.createElement('div');block.className=form.className;block.append(...form.childNodes);form.replaceWith(block);});
      phone.querySelectorAll('button,select').forEach(el=>{el.disabled=true;el.removeAttribute('data-action');});
      phone.querySelectorAll('input').forEach(el=>{el.readOnly=true;el.tabIndex=-1;el.removeAttribute('name');});
      phone.querySelectorAll('use[href="#i-mark"]').forEach(use=>{const old=use.closest('svg'),logo=document.createElement('img');logo.src='../motion_prototype_01/logo.svg';logo.alt='';logo.className='lab-brand-logo';old.replaceWith(logo);});
      const identity=phone.querySelector('.login-identity');
      if(identity){const scene=document.createElementNS('http://www.w3.org/2000/svg','svg');scene.setAttribute('viewBox','0 0 620 430');scene.setAttribute('aria-hidden','true');scene.innerHTML=URBES_ASSETS.scene;VehicleMotion.createRenderer(scene.querySelector('#layer-vehicle'),URBES_ASSETS.parts)(1);scene.querySelectorAll('[id]').forEach(el=>el.removeAttribute('id'));identity.replaceChildren(scene);}
      if(candidate)candidateTokens(column);
      column.append(heading,phone);pair.append(column);
    }
    row.append(pair);rows.push(row);document.querySelector('#comparisons').append(row);
  });
  candidateTokens(document.querySelector('.bench'));
  function select(){const value=document.querySelector('#review-screen').value;rows.forEach((row,i)=>{row.hidden=value!=='all'&&value!==String(i);});}
  document.querySelector('#review-screen').addEventListener('change',select);
  document.querySelector('#review-scale').addEventListener('change',e=>{document.querySelectorAll('.phone,.bench').forEach(n=>n.style.setProperty('--text-scale',e.target.value));});
  document.querySelectorAll('.bench button:not(:disabled)').forEach(button=>button.addEventListener('click',()=>{document.querySelector('#sample-status').textContent='Muestra de respuesta visual; sin operación funcional.';}));
  for(const pair of URBES_PROPOSAL.contrast){const tr=document.createElement('tr');tr.innerHTML=`<td>${pair.pair}</td><td>${pair.ratio.toFixed(2)}:1</td><td>${pair.target}:1</td><td>${pair.meets?'Cumple el par':'Uso restringido'}</td>`;document.querySelector('#contrast-body').append(tr);}
  select();
  const q=new URLSearchParams(location.search);if(q.has('screen')){document.querySelector('#review-screen').value=q.get('screen');select();}
  window.BrandReview={rows:rows.length,provisional:true,source:'existing HTML compositions',contrast:URBES_PROPOSAL.contrast};
})();
