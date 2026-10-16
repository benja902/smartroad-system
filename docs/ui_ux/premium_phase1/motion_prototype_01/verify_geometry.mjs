import {readFileSync,writeFileSync} from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const root=new URL('./',import.meta.url);
const context=vm.createContext({});
vm.runInContext(readFileSync(new URL('vehicle.js',root),'utf8'),context);
const V=context.VehicleMotion;
let maxStep=0,maxAngle=0,previous=null;
for(let i=0;i<=1200;i++){
  const p=V.at(V.ease(i/1200));assert(Number.isFinite(p.x+p.y+p.angle));
  assert(p.angle<=.000001 && p.angle>=-Math.PI/2-.000001);
  if(previous){assert(p.angle<=previous.angle+.000001);const a=V.project([p.x,p.y]),b=V.project([previous.x,previous.y]);maxStep=Math.max(maxStep,Math.hypot(a[0]-b[0],a[1]-b[1]));maxAngle=Math.max(maxAngle,(previous.angle-p.angle)*180/Math.PI);}
  previous=p;
}
assert(maxStep<1);assert(maxAngle<1);
assert.equal(V.at(0).x,64);assert.equal(V.at(1).x,235);assert.equal(V.at(1).y,70);
const result={passed:true,samples:1201,monotonic_heading:true,max_projected_step_world:maxStep,max_heading_step_degrees:maxAngle,projection:'fixed orthographic',turn_duration_ms:2000,notes:'Mathematical continuity, not a browser or Android FPS measurement.'};
writeFileSync(new URL('geometry-validation.json',root),JSON.stringify(result,null,2));
console.log(JSON.stringify(result));
