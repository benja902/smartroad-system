(function(){
  'use strict';
  const $=id=>document.getElementById(id),NS='http://www.w3.org/2000/svg';
  const stage=$('stage'),artboard=stage.parentElement;
  stage.innerHTML=`<defs><symbol id="urbes-logo" viewBox="0 0 512 512">${URBES_ASSETS.logo}</symbol></defs><g id="scene-wrap">${URBES_ASSETS.scene}</g><ellipse id="target-shadow" fill="#031B3B" aria-hidden="true"/><g id="encounter-signal" fill="none" stroke="#14E0D3" stroke-linecap="round" aria-hidden="true"><ellipse id="impulse-ring"/><path id="activation-link"/></g><g id="brand-lockup"><g id="brand-symbol"><use href="#urbes-logo" x="-48" y="-48" width="96" height="96"/></g><text id="brand-name" text-anchor="middle" font-family="Manrope,Arial,sans-serif" font-weight="800" fill="#031B3B">URBES</text></g>`;
  const renderer=VehicleMotion.createRenderer($('layer-vehicle'),URBES_ASSETS.parts);
  const preference=matchMedia('(prefers-reduced-motion: reduce)');
  const durations={vehicle:2000,full:3800,delivery:900,impulse:4440,activation:4440,refined:4440,beacon:4440};
  let mode='vehicle',time=0,running=false,last=null,raf=null,speed=1,critical=false,target=false,ticks=0,stopReason='ready';
  const duration=()=>durations[mode],reduced=()=>$('reduce').checked||preference.matches;
  const phase=(t,start,end)=>VehicleMotion.clamp((t-start)/(end-start));
  const easeOut=x=>1-Math.pow(1-x,3),smooth=x=>x*x*(3-2*x);
  const variant=()=>mode==='impulse'||mode==='activation'||mode==='refined'||mode==='beacon';
  const withoutT4=()=>mode==='refined'||mode==='beacon';
  // Same world anchor as v2's former sign. Logo is a camera-facing graphic,
  // not a road obstacle or a real connectivity/status indicator.
  const encounter=VehicleMotion.project([236,13,26]);
  const encounterFoot=VehicleMotion.project([236,13,0]);
  const toPhone=([x,y])=>[14+.6*x,270+.6*y];
  function vehicleNose(progress){
    const p=VehicleMotion.at(progress);
    return VehicleMotion.project([p.x+44*Math.cos(p.angle),p.y+44*Math.sin(p.angle),0]);
  }
  // Derive the cue from the existing eased route, once. Seeking is pure and
  // repeatable: no timers, collision events or second animation clock.
  let encounterTime=2600;
  for(let ms=0;ms<=2000;ms++){
    const nose=vehicleNose(VehicleMotion.ease(ms/2000));
    if(Math.hypot(nose[0]-encounterFoot[0],nose[1]-encounterFoot[1])<=16){encounterTime=600+ms;break;}
  }
  const interaction={cue:encounterTime,departure:2680,join:3360,delivery:3540,reveal:4090};
  const contactPose=VehicleMotion.at(VehicleMotion.ease((encounterTime-600)/2000));
  const contactBase=VehicleMotion.project([contactPose.x,contactPose.y]);
  const contactAhead=VehicleMotion.project([contactPose.x+Math.cos(contactPose.angle),contactPose.y+Math.sin(contactPose.angle)]);
  const direction=contactAhead.map((v,i)=>v-contactBase[i]);
  const directionLength=Math.hypot(...direction);direction.forEach((v,i)=>direction[i]=v/directionLength);
  function cubic(a,b,c,d,p){const u=1-p;return a.map((v,i)=>u*u*u*v+3*u*u*p*b[i]+3*u*p*p*c[i]+p*p*p*d[i]);}
  function drawVariant(final,delivery){
    const now=final?durations[mode]:time,origin=toPhone(encounter),join=[131,633];
    const impulse=mode!=='activation';
    const flight=VehicleMotion.ease(phase(now,interaction.departure,interaction.join));
    const point=impulse?cubic(origin,[365,440],[131,510],join,flight):cubic(origin,[310,490],[131,520],join,flight);
    const reaction=phase(now,interaction.cue,interaction.cue+(impulse?280:220));
    const amplitude=Math.pow(Math.sin(Math.PI*reaction),2);
    // D only: one slow lift-and-return, at rest before contact. Same review clock.
    const hover=phase(now,960,2160);
    const lift=mode==='beacon'?(hover<.5?VehicleMotion.ease(hover*2):1-VehicleMotion.ease(hover*2-1)):0;
    const push=mode==='beacon'?3*amplitude:0;
    point[0]+=push*direction[0];point[1]+=-2*lift+push*direction[1];
    const size=28.8+(57.6-28.8)*flight;
    $('brand-lockup').style.opacity=1;
    $('brand-lockup').setAttribute('transform',`translate(${42+89*(1-delivery)**3} ${633-586*smooth(delivery)}) scale(${1-.375*delivery})`);
    // Before docking, children compensate for the stationary lockup origin.
    $('brand-symbol').setAttribute('transform',`translate(${point[0]-131} ${point[1]-633}) scale(${size/96*(1+(impulse?.035*amplitude:0))})`);
    $('brand-symbol').style.opacity=withoutT4()?easeOut(phase(now,720,960)):easeOut(phase(now,1550,1850));
    $('brand-name').setAttribute('text-anchor','start');
    $('brand-name').setAttribute('x',43);$('brand-name').setAttribute('y',11);$('brand-name').setAttribute('font-size',32);
    $('brand-name').style.opacity=easeOut(phase(now,1900,2200));
    const signal=$('encounter-signal'),ring=$('impulse-ring'),link=$('activation-link');
    signal.style.opacity=final?0:amplitude*(mode==='beacon'?.65:.8);
    ring.style.display=impulse?'':'none';link.style.display=impulse?'none':'';
    ring.setAttribute('cx',origin[0]);ring.setAttribute('cy',origin[1]+15);
    ring.setAttribute('rx',12+14*reaction);ring.setAttribute('ry',6+7*reaction);ring.setAttribute('stroke-width',1.4);
    const nose=toPhone(vehicleNose(VehicleMotion.ease(phase(now,600,2600))));
    const foot=toPhone(encounterFoot);
    if(mode==='beacon'){
      ring.setAttribute('cx',foot[0]);ring.setAttribute('cy',foot[1]);
      ring.setAttribute('rx',10+12*reaction);ring.setAttribute('ry',4+5*reaction);
      ring.setAttribute('transform',`rotate(-30 ${foot[0]} ${foot[1]})`);
      const shadow=$('target-shadow');
      shadow.setAttribute('cx',foot[0]);shadow.setAttribute('cy',foot[1]);
      shadow.setAttribute('rx',10-.8*lift);shadow.setAttribute('ry',4-.3*lift);
      shadow.setAttribute('transform',`rotate(-30 ${foot[0]} ${foot[1]})`);
      shadow.style.opacity=final||critical?0:(.11-.02*lift)*easeOut(phase(now,720,960))*(1-smooth(phase(now,2680,2800)));
    }
    link.setAttribute('d',`M${nose[0]} ${nose[1]} L${foot[0]} ${foot[1]} L${origin[0]} ${origin[1]+8}`);
    link.setAttribute('stroke-width',1.5);
  }
  function reveal(id,t,start,length,dy=0,scale=1,pivot=[300,220]){
    const node=$(id),p=easeOut(phase(t,start,start+length)),s=scale+(1-scale)*p;
    node.style.opacity=p;
    node.setAttribute('transform',`translate(0 ${dy*(1-p)}) translate(${pivot[0]} ${pivot[1]}) scale(${s}) translate(${-pivot[0]} ${-pivot[1]})`);
  }
  function htmlReveal(node,p){node.style.opacity=p;node.style.transform=`translateY(${6*(1-p)}px)`;}
  function draw(){
    const final=target||reduced(),phone=mode!=='vehicle'||final||critical;
    // Preserve the original six-tree scene in all other review routes.
    $('object-tree-3').style.display=withoutT4()?'none':'';
    $('target-shadow').style.opacity=0;$('impulse-ring').removeAttribute('transform');
    artboard.classList.toggle('phone',phone);
    stage.setAttribute('viewBox',phone?'0 0 390 844':'0 0 620 430');
    stage.style.display=critical?'none':'';
    $('critical-view').hidden=!critical;$('clear-critical').hidden=!critical;
    for(const id of ['play','pause','restart','mode','seek'])$(id).disabled=critical;
    $('system-motion').textContent=preference.matches?'Movimiento reducido activo en el sistema.':'';
    const t=final?4000:variant()?(time<interaction.delivery?Math.min(3100,200+time):3100+time-interaction.delivery):mode==='delivery'?3100+time:mode==='full'?200+time:time;
    renderer(final?1:mode==='vehicle'?VehicleMotion.ease(time/2000):VehicleMotion.ease(phase(t,800,2800)));
    const visibleLogin=!critical&&phone&&(final||t>=3650);
    $('login').hidden=!visibleLogin;$('login').inert=!visibleLogin;
    $('brand-lockup').style.display=phone?'':'none';
    $('brand-lockup').style.opacity=easeOut(phase(t,2500,2800));
    $('brand-lockup').removeAttribute('transform');$('brand-symbol').style.opacity=1;
    $('brand-name').setAttribute('text-anchor','middle');$('encounter-signal').style.opacity=0;
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
      if(variant())drawVariant(final,delivery);
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
  window.MotionPrototype={seek,play,pause,setMode,skip:finish,critical:simulateCritical,clearCritical,setReduced,background:()=>finish('background'),renderer,state:()=>({time,running,speed,duration:duration(),mode,critical,reduced:reduced(),target,ticks,stopReason,heading:$('layer-vehicle').dataset.heading,interaction:variant()?interaction:null})};
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
