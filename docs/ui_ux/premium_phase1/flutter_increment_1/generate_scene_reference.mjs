// Evaluate the actual HTML reveal calls as the test oracle, without a browser.
import {readFileSync, writeFileSync} from 'node:fs';
import vm from 'node:vm';
import {createHash} from 'node:crypto';
const base=new URL('../',import.meta.url);
const source=readFileSync(new URL('motion_prototype_01/prototype.js',base),'utf8');
const manifest=JSON.parse(readFileSync(new URL('composition_v3/manifest.json',base)));
if(createHash('sha256').update(source).digest('hex')!==manifest.source_hashes['prototype.js']) throw Error('Motion source changed');
const reveal=source.slice(source.indexOf('  function reveal('),source.indexOf('  function htmlReveal('));
const start=source.indexOf("      reveal('layer-ground'");
const end=source.indexOf("      $('layer-vehicle').style.opacity=phase(t,800,980);")+"      $('layer-vehicle').style.opacity=phase(t,800,980);".length;
const calls=source.slice(start,end);
const samples=[];
for(const ms of [0,70,230,380,490,600,720,780,900,955,2160,2600]) {
  const nodes={};
  const context=vm.createContext({t:ms+200,$:id=>nodes[id]??=( {style:{},setAttribute(name,value){this[name]=value;}} )});
  vm.runInContext("const VehicleMotion={clamp:x=>Math.max(0,Math.min(1,x))}; const phase=(t,a,b)=>VehicleMotion.clamp((t-a)/(b-a)); const easeOut=x=>1-Math.pow(1-x,3);"+reveal+calls,context);
  samples.push({ms,layers:Object.fromEntries(Object.entries(nodes).map(([id,n])=>[id,{opacity:n.style.opacity,transform:n.transform??null}]))});
}
writeFileSync(new URL('flutter_increment_1/scene_reference.json',base),JSON.stringify({source_sha256:manifest.source_hashes['prototype.js'],clock_offset_ms:200,samples},null,2));
console.log(`Prepared ${samples.length} samples by evaluating the original reveal calls; no source edits.`);
