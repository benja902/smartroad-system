// QA only: screenshot the original Motion page, without its out-of-scope form.
import {spawn} from 'node:child_process';
import {mkdtemp,readFile,writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
const root=fileURLToPath(new URL('./',import.meta.url));
const source=new URL('../motion_prototype_01/index.html',import.meta.url);
const profile=await mkdtemp(join(tmpdir(),'urbes-closure-qa-'));
const browser=spawn('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',['--headless','--disable-gpu','--disable-background-networking','--disable-component-update','--disable-sync','--disable-extensions','--no-first-run','--no-default-browser-check',`--user-data-dir=${profile}`,'--remote-debugging-address=127.0.0.1','--remote-debugging-port=0',pathToFileURL(fileURLToPath(source)).href],{windowsHide:true,stdio:'ignore'});
let ws;
async function waitFor(fn) {const end=Date.now()+20000;while(Date.now()<end){try{const v=await fn();if(v)return v;}catch{}await new Promise(r=>setTimeout(r,100));}throw Error('QA browser timeout');}
try {
  const port=await waitFor(async()=>Number((await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]));
  const tab=await waitFor(async()=>(await(await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(x=>x.type==='page'));
  ws=new WebSocket(tab.webSocketDebuggerUrl);await new Promise((yes,no)=>{ws.onopen=yes;ws.onerror=no;});
  let seq=0;const pending=new Map();
  ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);if(p){clearTimeout(p.timer);pending.delete(m.id);m.error?p.no(Error(m.error.message)):p.yes(m.result);}}};
  const call=(method,params={})=>new Promise((yes,no)=>{const id=++seq;pending.set(id,{yes,no,timer:setTimeout(()=>no(Error('CDP timeout')),15000)});ws.send(JSON.stringify({id,method,params}));});
  const ev=async expression=>{const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.text);return r.result.value;};
  await call('Runtime.enable');await call('Page.enable');
  await call('Emulation.setDeviceMetricsOverride',{width:1000,height:1600,deviceScaleFactor:1,mobile:false});
  await waitFor(()=>ev('typeof MotionPrototype!=="undefined"'));
  await ev('document.fonts.ready.then(()=>true)');
  await ev("MotionPrototype.setMode('beacon');document.getElementById('login').style.display='none';document.querySelector('.artboard').style.border='none';document.querySelector('.artboard').style.borderRadius='0';true");
  const metrics=[];
  for(const ms of [3100,3450,3800,4440]) {
    await ev(`MotionPrototype.seek(${ms});true`);
    const rect=await ev("(()=>{const r=document.querySelector('.artboard').getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};})()");
    const capture=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false,clip:{...rect,scale:1}});
    await writeFile(join(root,`closure_browser_${ms}.png`),Buffer.from(capture.data,'base64'));
    metrics.push({ms,word_advance:await ev("document.getElementById('brand-name').getComputedTextLength()"),artboard:rect});
    console.log(`Captured original D ${ms}ms (${rect.width}x${rect.height}).`);
  }
  await writeFile(join(root,'closure_browser_metrics.json'),JSON.stringify(metrics,null,2));
} finally {if(ws)ws.close();browser.kill();}
