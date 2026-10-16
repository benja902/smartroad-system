// Local static browser rendering; native Node modules only. No user profile/device.
import {createServer} from 'node:http';
import {readFile,writeFile,mkdir,mkdtemp,rm} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {dirname,resolve,sep,extname,join} from 'node:path';
import {tmpdir} from 'node:os';
const root = dirname(fileURLToPath(import.meta.url));
const browser = process.env.URBES_BROWSER || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const profile = await mkdtemp(join(tmpdir(),'urbes-design-review-'));
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.ttf':'font/ttf','.png':'image/png'};
const server = createServer(async(req,res) => {
  try {
    const name = decodeURIComponent(new URL(req.url,'http://localhost').pathname);
    const target = resolve(root,`.${name === '/' ? '/index.html' : name}`);
    if (!target.startsWith(root+sep)) { res.writeHead(403); res.end(); return; }
    const data = await readFile(target); res.writeHead(200,{'Content-Type':types[extname(target)] || 'application/octet-stream'}); res.end(data);
  } catch { res.writeHead(404); res.end(); }
});
await new Promise(resolveReady => server.listen(0,'127.0.0.1',resolveReady));
const base = `http://127.0.0.1:${server.address().port}`;
function run(args) {
  return new Promise((done,reject) => {
    const child = spawn(browser,['--headless','--no-first-run','--no-default-browser-check','--disable-extensions','--disable-background-networking','--disable-component-update','--disable-sync','--force-device-scale-factor=1',`--user-data-dir=${profile}`,'--hide-scrollbars','--virtual-time-budget=2000',...args],{windowsHide:true});
    let out = '', err = '';
    child.stdout.on('data',data => {out += data;}); child.stderr.on('data',data => {err += data;});
    const deadline = setTimeout(() => {child.kill(); reject(Error('Browser exceeded 45 seconds without completion'));},45000);
    child.on('error',error => {clearTimeout(deadline); reject(error);});
    child.on('exit',code => {clearTimeout(deadline); code === 0 ? done(out) : reject(Error(`Browser exit ${code}: ${err.slice(-500)}`));});
  });
}
try {
  await mkdir(join(root,'previews'),{recursive:true});
  console.log('Validando escenarios, navegación, movimiento reducido y texto ampliado…');
  const dom = await run(['--dump-dom',`${base}/tests/browser.html`]);
  const match = dom.match(/<pre id="report" data-result="([^"]+)">([\s\S]*?)<\/pre>/);
  if (!match) throw Error('Browser did not produce the verification report');
  const report = JSON.parse(match[2].replaceAll('&amp;','&').replaceAll('&lt;','<').replaceAll('&gt;','>'));
  await writeFile(join(root,'previews','validation.json'),JSON.stringify(report,null,2)+'\n');
  if (!report.passed) throw Error(JSON.stringify(report.results.filter(item => !item.passed)));
  console.log(`${report.total}/${report.total} comprobaciones de navegador aprobadas.`);
  console.log('Comprobando apertura directa del HTML sin servidor…');
  const offline = await run(['--dump-dom',`${pathToFileURL(join(root,'index.html'))}?capture=1&screen=emergency`]);
  if (!offline.includes('data-critical="true"')) throw Error('Direct file opening failed');
  const captures = [
    ['studio.png','?gallery=1',1440,1000],
    ['overview.png','?board=1',1600,1000],
    ['login.png','?capture=1&screen=login',390,844],
    ['home.png','?capture=1&screen=home',390,844],
    ['alerts.png','?capture=1&screen=alerts',390,844],
    ['emergency.png','?capture=1&screen=emergency',390,844],
    ['emergency-no-location.png','?capture=1&screen=emergency&state=noLocation&type=sos',390,844],
    ['home-light.png','?capture=1&screen=home&variant=light',390,844],
    ['home-no-data.png','?capture=1&screen=home&state=noData',390,844],
    ['alerts-deferred.png','?capture=1&screen=alerts&state=deferred',390,844],
    ['emergency-text-200.png','?capture=1&screen=emergency&scale=2&reduced=1',320,640],
    ['emergency-text-200-location.png','?capture=1&screen=emergency&scale=2&reduced=1&section=location',320,640],
  ];
  for (const [name,query,width,height] of captures) {
    console.log(`Renderizando ${name} (${width}×${height})…`);
    await run([`--window-size=${width},${height}`,`--screenshot=${join(root,'previews',name)}`,`${base}/index.html${query}&width=${width}&height=${height}`]);
  }
  console.log('Capturas listas en previews/. No se ha medido rendimiento Flutter.');
} finally {
  await new Promise(done => server.close(done));
  // Only the temporary browser profile created by this script, outside the repo.
  if (profile.startsWith(join(tmpdir(),'urbes-design-review-'))) await rm(profile,{recursive:true,force:true,maxRetries:3,retryDelay:200});
}
