// Exact D closure state from the original JS. No new player or HTML UI.
import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import vm from 'node:vm';
const base=new URL('../',import.meta.url);
const source=readFileSync(new URL('motion_prototype_01/prototype.js',base),'utf8');
const vehicle=readFileSync(new URL('motion_prototype_01/vehicle.js',base),'utf8');
const manifest=JSON.parse(readFileSync(new URL('composition_v3/manifest.json',base)));
for(const [name,code] of [['prototype.js',source],['vehicle.js',vehicle]]) {
  if(createHash('sha256').update(code).digest('hex')!==manifest.source_hashes[name]) throw Error(`Changed source: ${name}`);
}
const nodes={};
const context=vm.createContext({mode:'beacon',time:0,critical:false,durations:{beacon:4440},$:id=>nodes[id]??={style:{},setAttribute(name,value){this[name]=value;}}});
vm.runInContext(vehicle,context);
vm.runInContext(source.slice(source.indexOf('  const phase='),source.indexOf('  function reveal(')),context);
const tLine=source.split('\n').find(l=>l.includes('const t=final?'));
const sceneLine=source.split('\n').find(l=>l.includes("$('scene-wrap').setAttribute('transform'"));
const samples=[];
for(const ms of [0,1560,2400,2540,2680,2800,3100,3360,3450,3540,3700,3800,4090,4200,4440]) {
  context.time=ms;
  vm.runInContext(`{const final=false;${tLine}const delivery=smooth(phase(t,3100,3650));${sceneLine}drawVariant(false,delivery);}`,context);
  const attrs=id=>Object.fromEntries(Object.entries(nodes[id]).filter(([key])=>key!=='setAttribute'));
  samples.push(JSON.parse(JSON.stringify({ms,symbol:attrs('brand-symbol'),lockup:attrs('brand-lockup'),word:attrs('brand-name'),scene:attrs('scene-wrap'),shadow:attrs('target-shadow')})));
}
writeFileSync(new URL('flutter_increment_1/closure_reference.json',base),JSON.stringify({source_sha256:manifest.source_hashes['prototype.js'],samples},null,2));
console.log(`Prepared ${samples.length} closure states from original D, including nested delivery easing.`);
