(function(){
  'use strict';
  const $=id=>document.getElementById(id),NS='http://www.w3.org/2000/svg';
  const stage=$('stage'),artboard=stage.parentElement;
  stage.innerHTML=`<defs><symbol id="urbes-logo" viewBox="0 0 512 512">${URBES_ASSETS.logo}</symbol></defs><g id="scene-wrap">${URBES_ASSETS.scene}</g><g id="brand-lockup"><g id="brand-symbol"><use href="#urbes-logo" x="-48" y="-48" width="96" height="96"/></g><text id="brand-name" text-anchor="middle" font-family="Manrope,Arial,sans-serif" font-weight="800" fill="#031B3B">URBES</text></g>`;
  const renderer=VehicleMotion.createRenderer($('layer-vehicle'),URBES_ASSETS.parts);
  const preference=matchMedia('(prefers-reduced-motion: reduce)');
  const durations={vehicle:2000,full:3800,delivery:900};
  let mode='vehicle',time=0,running=false,last=null,raf=null,speed=1,critical=false,target=false,ticks=0,stopReason='ready';
  const duration=()=>durations[mode],reduced=()=>$('reduce').checked||preference.matches;
  const phase=(t,start,end)=>VehicleMotion.clamp((t-start)/(end-start));
  const easeOut=x=>1-Math.pow(1-x,3),smooth=x=>x*x*(3-2*x);
  function reveal(id,t,start,length,dy=0,scale=1,pivot=[300,220]){
    const node=$(id),p=easeOut(phase(t,start,start+length)),s=scale+(1-scale)*p;
    node.style.opacity=p;
    node.setAttribute('transform',`translate(0 ${dy*(1-p)}) translate(${pivot[0]} ${pivot[1]}) scale(${s}) translate(${-pivot[0]} ${-pivot[1]})`);
  }
  function htmlReveal(node,p){node.style.opacity=p;node.style.transform=`translateY(${6*(1-p)}px)`;}
  function draw(){
    const final=target||reduced(),phone=mode!=='vehicle'||final||critical;
    artboard.classList.toggle('phone',phone);
    stage.setAttribute('viewBox',phone?'0 0 390 844':'0 0 620 430');
    stage.style.display=critical?'none':'';
    $('critical-view').hidden=!critical;$('clear-critical').hidden=!critical;
    for(const id of ['play','pause','restart','mode','seek'])$(id).disabled=critical;
    $('system-motion').textContent=preference.matches?'Movimiento reducido activo en el sistema.':'';
    const t=final?4000:mode==='delivery'?3100+time:mode==='full'?200+time:time;
    renderer(final?1:mode==='vehicle'?VehicleMotion.ease(time/2000):VehicleMotion.ease(phase(t,800,2800)));
    const visibleLogin=!critical&&phone&&(final||t>=3650);
    $('login').hidden=!visibleLogin;$('login').inert=!visibleLogin;
    $('brand-lockup').style.display=phone?'':'none';
    $('brand-lockup').style.opacity=easeOut(phase(t,2500,2800));
    if(phone){
      const delivery=smooth(phase(t,3100,3650));
      $('scene-wrap').setAttribute('transform',`translate(14 ${270-199*delivery}) scale(.6)`);
      // Follow the empty left margin instead of crossing the illustrated road.
      const u=1-delivery,logoX=195*u*u*u+42*delivery*delivery*delivery;
      $('brand-symbol').setAttribute('transform',`translate(${logoX} ${608-561*smooth(delivery)}) scale(${1-.625*easeOut(VehicleMotion.clamp(delivery/.35))})`);
      const closing=delivery<.3;
      $('brand-name').setAttribute('x',closing?195:109);
      $('brand-name').setAttribute('y',closing?690:54);
      $('brand-name').setAttribute('font-size',closing?32:20);
      $('brand-name').style.opacity=closing?1-smooth(delivery/.3):smooth(VehicleMotion.clamp((delivery-.85)/.15));
      reveal('layer-ground',t,180,340,0,.985);reveal('layer-road',t,270,380,0,.992);
      reveal('layer-architecture',t,0,1);reveal('layer-landscape',t,500,280);
      reveal('object-townhouse',t,430,400,8,.985,[300,120]);
      reveal('object-pavilion',t,550,360,6,.985,[400,250]);
      ['object-tree-5','object-tree-3','object-tree-4','object-tree-0','object-tree-1','object-tree-2'].forEach((id,i)=>reveal(id,t,580+i*55,300,4,.98));
      reveal('object-bench',t,780,260,3);reveal('object-lamps',t,840,260,3);
      $('layer-vehicle').style.opacity=phase(t,800,980);
    }else{
      $('scene-wrap').removeAttribute('transform');
      for(const id of ['layer-ground','layer-road','layer-architecture','layer-landscape','object-townhouse','object-pavilion','object-bench','object-lamps','object-tree-0','object-tree-1','object-tree-2','object-tree-3','object-tree-4','object-tree-5']){const node=$(id);node.style.opacity=1;node.removeAttribute('transform');}
      $('layer-vehicle').style.opacity=1;
    }
    htmlReveal(document.querySelector('.login-title'),final?1:easeOut(phase(t,3650,3890)));
    htmlReveal(document.querySelector('.login-fields'),final?1:easeOut(phase(t,3690,3930)));
    htmlReveal(document.querySelector('.login-action'),final?1:easeOut(phase(t,3730,3970)));
    for(const [selector,start] of [['.login-fields',3690],['.login-action',3730]]){
      const node=document.querySelector(selector),visible=visibleLogin&&(final||t>start);
      node.style.visibility=visible?'visible':'hidden';node.inert=!visible;
    }
    $('seek').max=duration();$('seek').value=time;
    $('readout').textContent=`${Math.round(time)} / ${duration()} ms · ${speed}×`;
  }
  function pause(reason='paused'){running=false;last=null;if(raf!==null)cancelAnimationFrame(raf);raf=null;stopReason=reason;}
  function finish(reason='skipped'){
    pause(reason);time=duration();target=true;draw();
    $('status').textContent=critical?'Prioridad crítica: escena retirada.':reason==='background'?'La intro terminó al ocultar la página.':'Login estático; animaciones decorativas omitidas.';
  }
  function tick(now){
    if(!running)return;
    if(last!==null)time=Math.min(duration(),time+Math.min(40,Math.max(0,now-last))*speed);
    last=now;ticks++;draw();
    if(time>=duration()){pause('completed');$('status').textContent='Secuencia terminada. Puedes repetirla.';}else raf=requestAnimationFrame(tick);
  }
  function play(){
    if(critical)return;
    if(reduced()){finish('reduced');return;}
    pause();if(time>=duration()||target)time=0;target=false;running=true;stopReason='playing';
    $('status').textContent='Reproduciendo';draw();raf=requestAnimationFrame(tick);
  }
  function seek(t){
    if(critical)return;if(reduced()){finish('reduced');return;}
    pause('seek');target=false;time=Math.max(0,Math.min(duration(),Number.isFinite(t)?t:0));draw();$('status').textContent='En revisión; reproducción detenida.';
  }
  function setMode(value){if(critical||!Object.hasOwn(durations,value))return;mode=value;$('mode').value=mode;seek(0);}
  function simulateCritical(){pause('critical');critical=true;draw();$('status').textContent='Prioridad crítica: escena retirada sin esperar la animación.';}
  function clearCritical(){critical=false;finish('critical-cleared');}
  function setReduced(value){$('reduce').checked=value;if(reduced())finish('reduced');else{pause('reduced-disabled');draw();}}
  $('play').addEventListener('click',play);
  $('pause').addEventListener('click',()=>{pause();$('status').textContent='En pausa';});
  $('restart').addEventListener('click',()=>{seek(0);$('status').textContent=reduced()?'Movimiento reducido: Login estático.':'Lista para repetir.';});
  $('mode').addEventListener('change',e=>setMode(e.target.value));
  $('speed').addEventListener('change',e=>{speed=Number(e.target.value);draw();});
  $('seek').addEventListener('input',e=>seek(Number(e.target.value)));
  $('skip').addEventListener('click',()=>finish('skipped'));
  $('reduce').addEventListener('change',()=>setReduced($('reduce').checked));
  $('critical').addEventListener('click',simulateCritical);$('clear-critical').addEventListener('click',clearCritical);
  $('demo-submit').addEventListener('click',()=>{$('status').textContent='Formulario ficticio: no se envían datos ni se autentica.';});
  preference.addEventListener('change',()=>{if(reduced())finish('system-reduced');else draw();});
  document.addEventListener('visibilitychange',()=>{if(document.hidden&&running)finish('background');});
  window.MotionPrototype={seek,play,pause,setMode,skip:finish,critical:simulateCritical,clearCritical,setReduced,background:()=>finish('background'),renderer,state:()=>({time,running,speed,duration:duration(),mode,critical,reduced:reduced(),target,ticks,stopReason,heading:$('layer-vehicle').dataset.heading})};
  const query=new URLSearchParams(location.search);
  if(query.has('mode'))setMode(query.get('mode'));if(query.has('t'))seek(Number(query.get('t')));if(query.has('reduced'))setReduced(true);
  draw();
  if(query.has('film')){
    const board=document.createElement('div');board.className='film';
    for(const t of [350,650,800,900,1000,1100,1200,1300,1450,1650,1850,2000]){
      const figure=document.createElement('figure'),svg=document.createElementNS(NS,'svg');svg.setAttribute('viewBox','0 0 620 430');svg.innerHTML=URBES_ASSETS.scene;
      const host=svg.querySelector('#layer-vehicle');VehicleMotion.createRenderer(host,URBES_ASSETS.parts)(VehicleMotion.ease(t/2000));
      svg.querySelectorAll('[id]').forEach(el=>el.removeAttribute('id'));
      const label=document.createElement('figcaption');label.textContent=`${t} ms · ${host.dataset.heading}°`;figure.append(svg,label);board.append(figure);
    }
    document.querySelector('.studio').hidden=true;document.querySelector('main').append(board);
  }
})();
