// Test oracle: evaluate D's original drawVariant before its departure.
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
const encounter=vm.runInContext('encounterTime',context);
const samples=[];
for(const ms of [0,719,720,780,840,960,1260,1560,1860,2160,2399,2400,2470,2540,2610,2680]) {
  context.time=ms;
  vm.runInContext('drawVariant(false,0)',context);
  const attrs=id=>Object.fromEntries(Object.entries(nodes[id]).filter(([key])=>key!=='setAttribute'));
  samples.push({ms,symbol:attrs('brand-symbol'),shadow:attrs('target-shadow'),wave:attrs('impulse-ring'),waveOpacity:nodes['encounter-signal'].style.opacity});
  // Copy style objects; next draw mutates the original DOM stand-ins.
  samples[samples.length-1]=JSON.parse(JSON.stringify(samples.at(-1)));
}
writeFileSync(new URL('flutter_increment_1/beacon_reference.json',base),JSON.stringify({source_hashes:{'prototype.js':manifest.source_hashes['prototype.js'],'vehicle.js':manifest.source_hashes['vehicle.js']},encounter_ms:encounter,samples},null,2));
console.log(`Prepared ${samples.length} original D samples; encounter=${encounter}ms, ending at ${encounter+280}ms.`);
