// Installed headless Chrome + native Node APIs. Isolated local page/profile only.
import {spawn} from 'node:child_process';
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve,dirname,basename} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import assert from 'node:assert/strict';
const root=dirname(fileURLToPath(import.meta.url));
const profile=await mkdtemp(join(tmpdir(),'urbes-motion-browser-'));
const browser=spawn('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',['--headless','--no-sandbox','--disable-gpu','--disable-background-networking','--disable-component-update','--disable-sync','--disable-extensions','--no-first-run','--no-default-browser-check',`--user-data-dir=${profile}`,'--remote-debugging-address=127.0.0.1','--remote-debugging-port=0','--window-size=1200,1200',pathToFileURL(join(root,'index.html')).href],{windowsHide:true,stdio:'ignore'});
let ws;const results=[],errors=[];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function waitFor(fn){const end=Date.now()+15000;while(Date.now()<end){try{const v=await fn();if(v)return v;}catch{}await sleep(100);}throw Error('Local browser initialization timed out');}
try{
  console.log('Opening isolated local browser…');
  const port=await waitFor(async()=>Number((await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]));
  const target=await waitFor(async()=>{const list=await(await fetch(`http://127.0.0.1:${port}/json/list`)).json();return list.find(x=>x.type==='page'&&x.url.startsWith('file:'));});
  ws=new WebSocket(target.webSocketDebuggerUrl);await new Promise((yes,no)=>{ws.onopen=yes;ws.onerror=no;});
  let seq=0;const pending=new Map();
  ws.onmessage=event=>{const m=JSON.parse(event.data);if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.text);if(m.id){const p=pending.get(m.id);if(!p)return;clearTimeout(p.timer);pending.delete(m.id);m.error?p.no(Error(m.error.message)):p.yes(m.result);}};
  const call=(method,params={})=>new Promise((yes,no)=>{const id=++seq,timer=setTimeout(()=>{pending.delete(id);no(Error(`CDP timeout: ${method}`));},12000);pending.set(id,{yes,no,timer});ws.send(JSON.stringify({id,method,params}));});
  const ev=async expression=>{const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.text);return r.result.value;};
  await call('Runtime.enable');await call('Page.enable');
  await waitFor(()=>ev('typeof MotionPrototype!=="undefined"'));
  await ev('document.fonts.ready.then(()=>true)');
  const check=async(name,expression)=>{assert.equal(await ev(expression),true,name);results.push({name,passed:true});console.log(`OK: ${name}`);};
  await check('Direct file opening; no autoplay','MotionPrototype.state().running===false && MotionPrototype.state().mode==="vehicle"');
  await check('Live rAF playback advances',`(async()=>{MotionPrototype.play();const end=performance.now()+3000;while(MotionPrototype.state().ticks<3&&performance.now()<end)await new Promise(r=>setTimeout(r,50));const s=MotionPrototype.state();MotionPrototype.pause();return s.ticks>2&&s.time>0;})()`);
  await check('Pause retains time',`(async()=>{const t=MotionPrototype.state().time;await new Promise(r=>setTimeout(r,90));return MotionPrototype.state().time===t;})()`);
  await check('Reduced speed selected without restarting','document.getElementById("speed").value=".25";document.getElementById("speed").dispatchEvent(new Event("change"));MotionPrototype.state().speed===.25');
  await check('Restart resets progress','document.getElementById("restart").click();MotionPrototype.state().time===0&&!MotionPrototype.state().running');
  await check('Direct isometric opening without former road/emblem','MotionPrototype.setMode("full");MotionPrototype.seek(0);Number(document.getElementById("layer-ground").style.opacity)>0 && !document.getElementById("native-road") && !document.getElementById("layer-brand-sign") && !document.getElementById("large-wordmark")');
  await check('Supplied logo preserves its three paths and original fills','(()=>{const logo=document.getElementById("urbes-logo"),paths=Array.from(logo.querySelectorAll("path"));return logo.getAttribute("viewBox")==="0 0 512 512" && paths.length===3 && paths.filter(p=>p.getAttribute("fill")==="#031B3B").length===1 && paths.filter(p=>p.getAttribute("fill")==="#14E0D3").length===2;})()');
  await check('One logo moves continuously to the header','MotionPrototype.seek(2900);const before=document.getElementById("brand-symbol");MotionPrototype.seek(3250);before===document.getElementById("brand-symbol") && document.querySelectorAll("#brand-symbol use").length===1');
  await check('Full sequence hides form until delivery','MotionPrototype.seek(3400);document.getElementById("login").hidden && document.getElementById("login").inert');
  await check('Fields stay unfocusable before their entry','MotionPrototype.seek(3460);!document.getElementById("login").hidden && document.querySelector(".login-fields").inert && document.querySelector(".login-action").inert');
  await check('Login entry after reveal','MotionPrototype.seek(3800);!document.getElementById("login").hidden && !document.querySelector(".login-action").inert && document.querySelector(".login-title").style.opacity==="1"');
  await check('One persistent scene instance','document.querySelectorAll("#illustration-world").length===1');
  await check('Replay starts a fresh finite sequence','MotionPrototype.play();MotionPrototype.state().running && MotionPrototype.state().time===0');
  await check('Skip immediately cancels playback','MotionPrototype.skip();!MotionPrototype.state().running && MotionPrototype.state().target && !document.getElementById("login").hidden');
  await check('Critical overrides active playback','MotionPrototype.setMode("full");MotionPrototype.seek(1200);MotionPrototype.play();MotionPrototype.critical();!MotionPrototype.state().running && document.getElementById("stage").style.display==="none" && document.getElementById("login").hidden && !document.getElementById("critical-view").hidden');
  await check('Critical resists skip/replay/reduced motion','MotionPrototype.skip();MotionPrototype.play();MotionPrototype.setReduced(true);MotionPrototype.state().critical && !MotionPrototype.state().running && !document.getElementById("critical-view").hidden');
  await check('Clear critical delivers static target','MotionPrototype.clearCritical();!MotionPrototype.state().critical && !document.getElementById("login").hidden');
  await check('Reduced motion blocks decorative playback','MotionPrototype.play();!MotionPrototype.state().running && !document.getElementById("login").hidden');
  await check('Disabling reduced motion never autoplays','MotionPrototype.setReduced(false);!MotionPrototype.state().running');
  await check('Background interruption never resumes','MotionPrototype.setMode("full");MotionPrototype.play();MotionPrototype.background();!MotionPrototype.state().running && MotionPrototype.state().stopReason==="background"');
  await check('Delivery-only mode ends in login','MotionPrototype.setMode("delivery");MotionPrototype.seek(900);!document.getElementById("login").hidden && document.querySelector(".login-action").style.opacity==="1"');
  await check('Readonly fictional login never authenticates','document.getElementById("demo-submit").click();document.querySelectorAll("form").length===0 && document.getElementById("demo-email").readOnly && document.getElementById("status").textContent.includes("no se envían")');
  await check('Repeated seeks do not accumulate geometry','MotionPrototype.setMode("vehicle");(()=>{const n=document.querySelectorAll("#layer-vehicle *").length;for(let i=0;i<100;i++)MotionPrototype.seek(i*20);return document.querySelectorAll("#layer-vehicle *").length===n;})()');
  await call('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]});
  await check('System reduced-motion preference is honored','MotionPrototype.play();MotionPrototype.state().reduced && !MotionPrototype.state().running && !document.getElementById("login").hidden');
  await call('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'no-preference'}]});
  await call('Emulation.setDeviceMetricsOverride',{width:320,height:920,deviceScaleFactor:1,mobile:false});
  await check('320px review has no horizontal overflow','MotionPrototype.skip();document.documentElement.scrollWidth<=320');
  await call('Emulation.setDeviceMetricsOverride',{width:1200,height:1200,deviceScaleFactor:1,mobile:false});
  console.log('Playing complete finite sequence at 1×…');
  await check('Full real-time playback completes without seeking',`(async()=>{document.getElementById('speed').value='1';document.getElementById('speed').dispatchEvent(new Event('change'));MotionPrototype.setMode('full');MotionPrototype.play();const end=performance.now()+10000;while(MotionPrototype.state().running&&performance.now()<end)await new Promise(r=>setTimeout(r,100));const s=MotionPrototype.state();return !s.running&&s.time===3800&&s.stopReason==='completed'&&!document.getElementById('login').hidden;})()`);
  for(const [name,mode,t] of [['full-build','full',700],['brand-close','full',2700],['handoff','full',3200],['login','full',3800]]){
    await ev(`MotionPrototype.setMode(${JSON.stringify(mode)});MotionPrototype.seek(${t});`);
    const {data}=await call('Page.captureScreenshot',{format:'png'});await writeFile(join(root,`${name}.png`),Buffer.from(data,'base64'));
    console.log(`Captured ${name}`);
  }
  assert.equal(errors.length,0,'No runtime exceptions');
  await writeFile(join(root,'browser-validation.json'),JSON.stringify({passed:true,total:results.length,results,errors,live_raf_verified:true,android_performance_measured:false},null,2));
  console.log(`${results.length}/${results.length} local browser checks passed.`);
  await call('Browser.close').catch(()=>{});
}finally{
  if(ws)ws.close();
  if(browser.exitCode===null){await Promise.race([new Promise(r=>browser.once('exit',r)),sleep(1500)]);if(browser.exitCode===null)browser.kill();}
  const checked=resolve(profile),base=resolve(tmpdir());
  if(dirname(checked)!==base||!basename(checked).startsWith('urbes-motion-browser-'))throw Error('Unexpected cleanup target');
  await rm(checked,{recursive:true,force:true,maxRetries:3,retryDelay:200});
}
