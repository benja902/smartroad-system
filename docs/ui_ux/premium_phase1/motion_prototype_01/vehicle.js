/* Review-only orthographic renderer. No WebGL, external library or pose atlas. */
(function(global) {
  'use strict';
  const NS='http://www.w3.org/2000/svg';
  const project=([x,y,z=0])=>[300+Math.sqrt(3)/2*(x-y),48+.5*(x+y)-z];
  const clamp=x=>Math.max(0,Math.min(1,x));
  const ease=x=>{x=clamp(x);return x*x*x*(10+x*(-15+6*x));};
  function curve(t) {
    const u=1-t;
    return {x:u*u*u*135+3*u*u*t*198+3*u*t*t*235+t*t*t*235,
      y:u*u*u*205+3*u*u*t*205+3*u*t*t*171+t*t*t*113,
      dx:3*u*u*63+6*u*t*37,dy:-6*u*t*34-3*t*t*58};
  }
  // LUT parameterizes projected ground distance; the heading remains in world space.
  const route=[];
  for(let i=0;i<=120;i++)route.push({x:64+71*i/120,y:205,angle:0});
  for(let i=1;i<=600;i++) {
    const c=curve(i/600);route.push({x:c.x,y:c.y,angle:Math.atan2(c.dy,c.dx)});
  }
  for(let i=1;i<=120;i++)route.push({x:235,y:113-43*i/120,angle:-Math.PI/2});
  let total=0;
  route.forEach((p,i)=>{if(i){const a=project([p.x,p.y]),b=project([route[i-1].x,route[i-1].y]);total+=Math.hypot(a[0]-b[0],a[1]-b[1]);}p.distance=total;});
  function at(progress) {
    const d=clamp(progress)*total;
    let lo=0,hi=route.length-1;
    while(lo+1<hi){const mid=(lo+hi)>>1;if(route[mid].distance<d)lo=mid;else hi=mid;}
    const a=route[lo],b=route[hi],f=(d-a.distance)/(b.distance-a.distance||1);
    return {x:a.x+(b.x-a.x)*f,y:a.y+(b.y-a.y)*f,angle:a.angle+(b.angle-a.angle)*f};
  }
  function transform([x,y,z=0],pose) {
    const c=Math.cos(pose.angle),s=Math.sin(pose.angle);
    return [pose.x+x*c-y*s,pose.y+x*s+y*c,z];
  }
  function createRenderer(host,parts) {
    const shadow=document.createElementNS(NS,'polygon');
    shadow.setAttribute('fill','#1B2B48');shadow.setAttribute('opacity','.13');host.append(shadow);
    const surfaces=document.createElementNS(NS,'g');host.append(surfaces);
    const nodes=parts.map((part,i)=>{
      const node=document.createElementNS(NS,part.kind);node.dataset.part=String(i);
      node.setAttribute('fill',part.fill);
      if(part.stroke){node.setAttribute('stroke',part.stroke);node.setAttribute('stroke-width',part.width);node.setAttribute('stroke-linecap','round');node.setAttribute('stroke-linejoin','round');}
      surfaces.append(node);return {node,part,i};
    });
    let order='';
    return function render(progress) {
      const pose=at(progress),c=Math.cos(pose.angle),s=Math.sin(pose.angle);
      const shadowPoints=Array.from({length:48},(_,i)=>{const a=2*Math.PI*i/48;const p=transform([44*Math.cos(a),23*Math.sin(a),0],pose);p[0]+=7;p[1]+=9;return project(p).join(',');});
      shadow.setAttribute('points',shadowPoints.join(' '));
      const sorted=[];
      for(const item of nodes) {
        const {part,node}=item;
        const n=part.normal,nx=n[0]*c-n[1]*s,ny=n[0]*s+n[1]*c;
        const facing=nx+ny+n[2];
        // A hidden face reaches zero projected area before changing visibility.
        node.style.display=facing>1e-7?'':'none';
        const points=part.points.map(p=>transform(p,pose));
        node.setAttribute('points',points.map(p=>project(p).map(v=>v.toFixed(3)).join(',')).join(' '));
        const depth=points.reduce((sum,p)=>sum+p[0]+p[1]+p[2],0)/points.length;
        sorted.push({...item,depth});
      }
      sorted.sort((a,b)=>a.depth-b.depth||a.i-b.i);
      const next=sorted.map(item=>item.i).join(',');
      if(next!==order){for(const {node} of sorted)surfaces.append(node);order=next;}
      host.dataset.x=pose.x.toFixed(3);host.dataset.y=pose.y.toFixed(3);
      host.dataset.heading=(pose.angle*180/Math.PI).toFixed(3);
      return pose;
    };
  }
  global.VehicleMotion={project,at,ease,clamp,curve,createRenderer,routeLength:total};
})(typeof window==='undefined'?globalThis:window);
