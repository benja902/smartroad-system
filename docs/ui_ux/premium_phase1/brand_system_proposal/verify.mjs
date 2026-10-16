// Local review only; installed Chrome and Node built-ins, no dependencies.
import {spawn} from 'node:child_process';
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import {join,resolve,dirname,basename} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import assert from 'node:assert/strict';
const root=dirname(fileURLToPath(import.meta.url));
const profile=await mkdtemp(join(tmpdir(),'urbes-brand-review-'));
const browser=spawn('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',['--headless','--no-sandbox','--disable-gpu','--disable-background-networking','--disable-component-update','--disable-sync','--disable-extensions','--no-first-run','--no-default-browser-check',`--user-data-dir=${profile}`,'--remote-debugging-address=127.0.0.1','--remote-debugging-port=0',pathToFileURL(join(root,'index.html')).href],{windowsHide:true,stdio:'ignore'});
let ws;const results=[],errors=[];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function waitFor(fn){const end=Date.now()+15000;while(Date.now()<end){try{const value=await fn();if(value)return value;}catch{}await sleep(100);}throw Error('Local page did not initialize');}
try{
  console.log('Opening local brand comparison…');
  const port=await waitFor(async()=>Number((await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]));
  const target=await waitFor(async()=>(await(await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(x=>x.type==='page'&&x.url.startsWith('file:')));
  ws=new WebSocket(target.webSocketDebuggerUrl);await new Promise((yes,no)=>{ws.onopen=yes;ws.onerror=no;});
  let seq=0;const pending=new Map();
  ws.onmessage=event=>{const m=JSON.parse(event.data);if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.text);if(m.id){const p=pending.get(m.id);if(!p)return;clearTimeout(p.timer);pending.delete(m.id);m.error?p.no(Error(m.error.message)):p.yes(m.result);}};
  const call=(method,params={})=>new Promise((yes,no)=>{const id=++seq,timer=setTimeout(()=>no(Error(method+' timed out')),12000);pending.set(id,{yes,no,timer});ws.send(JSON.stringify({id,method,params}));});
  const ev=async expression=>{const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
  const check=async(name,expression)=>{assert.equal(await ev(expression),true,name);results.push({name,passed:true});console.log('OK: '+name);};
  await call('Runtime.enable');await call('Page.enable');
  await waitFor(()=>ev('typeof BrandReview!=="undefined"'));
  await ev('document.fonts.ready.then(()=>true)');
  await check('Four paired compositions, provisional status','BrandReview.rows===4 && BrandReview.provisional && document.querySelectorAll(".palette .phone").length===8');
  await check('Local supplied logos loaded','Array.from(document.querySelectorAll(".lab-brand-logo")).every(i=>i.complete&&i.naturalWidth>0&&i.src.endsWith("/motion_prototype_01/logo.svg"))');
  await check('No forms or functional preview actions','document.querySelectorAll("form").length===0 && Array.from(document.querySelectorAll(".phone button,.phone select")).every(b=>b.disabled) && Array.from(document.querySelectorAll(".phone input")).every(i=>i.readOnly)');
  await check('New primary and focus roles applied','getComputedStyle(document.querySelector(".bench .sample-primary")).backgroundColor==="rgb(3, 27, 59)" && getComputedStyle(document.querySelector(".force-focus")).outlineColor==="rgb(0, 109, 104)"');
  await check('Functional field border and readable frozen action','getComputedStyle(document.querySelector(".candidate .input-wrap")).borderColor==="rgb(117, 119, 126)" && getComputedStyle(document.querySelector(".candidate .emergency-actions .button")).color==="rgb(255, 255, 255)"');
  await check('Both login compositions reuse static approved scene','document.querySelectorAll(".login-identity svg").length===2 && typeof MotionPrototype==="undefined"');
  await check('No duplicate DOM IDs','(()=>{const ids=Array.from(document.querySelectorAll("[id]")).map(e=>e.id);return new Set(ids).size===ids.length;})()');
  await check('Measured aqua limitation displayed','BrandReview.contrast.length===15 && BrandReview.contrast.filter(p=>!p.meets).length===1 && document.querySelectorAll("#contrast-body tr").length===15');
  await check('Bench response is only a local demonstration','document.querySelector(".bench .sample-primary").click();document.getElementById("sample-status").textContent.includes("sin operación funcional")');
  await call('Emulation.setDeviceMetricsOverride',{width:1200,height:1400,deviceScaleFactor:1,mobile:false});
  for(const [index,name] of ['login','inicio','alertas','emergencia'].entries()){
    await ev(`document.getElementById('review-screen').value='${index}';document.getElementById('review-screen').dispatchEvent(new Event('change'));window.scrollTo(0,0)`);
    await check(name+' selector shows one pair','Array.from(document.querySelectorAll(".comparison-row")).filter(r=>!r.hidden).length===1');
    await sleep(50);
    const {data}=await call('Page.captureScreenshot',{format:'png'});await writeFile(join(root,name+'.png'),Buffer.from(data,'base64'));
  }
  await call('Emulation.setDeviceMetricsOverride',{width:320,height:920,deviceScaleFactor:1,mobile:false});
  await ev('document.getElementById("review-scale").value="2";document.getElementById("review-scale").dispatchEvent(new Event("change"))');
  for(let i=0;i<4;i++){
    await ev(`document.getElementById('review-screen').value='${i}';document.getElementById('review-screen').dispatchEvent(new Event('change'))`);
    await check('320px / 200% screen '+i+' has no page overflow','document.documentElement.scrollWidth<=320');
  }
  await call('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]});
  await check('Reduced motion removes bench transitions','getComputedStyle(document.querySelector(".sample-primary")).transitionDuration==="0s"');
  const preserved=JSON.parse(await readFile(join(root,'preserved-files.json'),'utf8'));
  for(const [file,hash] of Object.entries(preserved))assert.equal(createHash('sha256').update(await readFile(join(root,'..',file))).digest('hex'),hash,file+' preserved');
  assert.equal(errors.length,0,'No runtime exceptions');
  await writeFile(join(root,'browser-validation.json'),JSON.stringify({passed:true,total:results.length,results,errors,protected_motion_files_verified:Object.keys(preserved).length,android_performance_measured:false},null,2));
  console.log(`${results.length} browser checks passed; six original motion files unchanged.`);
  await call('Browser.close').catch(()=>{});
}finally{
  if(ws)ws.close();
  if(browser.exitCode===null){await Promise.race([new Promise(r=>browser.once('exit',r)),sleep(1500)]);if(browser.exitCode===null)browser.kill();}
  const checked=resolve(profile);
  if(dirname(checked)!==resolve(tmpdir())||!basename(checked).startsWith('urbes-brand-review-'))throw Error('Unexpected cleanup target');
  await rm(checked,{recursive:true,force:true,maxRetries:3,retryDelay:200});
}
