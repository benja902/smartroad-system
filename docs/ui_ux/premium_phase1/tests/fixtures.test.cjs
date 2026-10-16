const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const F = require('../fixtures.js');

test('Design examples preserve incident precedence and never promote unknown types', () => {
  const e = F.event;
  for (const type of ['test','power_loss','low_battery','booted','unknown','unrecognized']) {
    assert.equal(F.classify({...e,type}), 'technical');
  }
  assert.equal(F.classify({...e,type:'cancel',cancelledBySeq:3}), 'cancellation');
  assert.equal(F.classify({...e,cancelledBySeq:3,acknowledged:true,queued:true}), 'cancelled');
  assert.equal(F.classify({...e,acknowledged:true,queued:true}), 'attended');
  assert.equal(F.classify({...e,queued:true}), 'deferred');
  assert.equal(F.classify({...e,type:'sos',queued:true}), 'deferred');
  assert.equal(F.classify({...e,type:'sos',severity:'none'}), 'activeEmergency');
  assert.equal(F.classify({...e,severity:'moderado'}), 'attention');
  assert.equal(F.classify({...e,severity:'leve'}), 'informative');
});

test('Missing position/time and last-known position remain explicit', () => {
  assert.equal(F.locationCopy(null).coordinates, null);
  assert.match(F.locationCopy(null).quality, /no incluye/);
  assert.doesNotMatch(F.locationCopy(null).quality, /nunca/);
  const old = F.locationCopy({...F.position,fix:false,fixAgeS:420});
  assert.equal(old.title, 'Última posición conocida');
  assert.match(old.quality, /420 s/);
  assert.equal(F.clock(null), 'No disponible');
  assert.equal(F.clock('invalid'), 'No disponible');
  assert.equal(F.clock(F.event.ts), '09:39');
  assert.equal(F.clock(F.event.receivedAt), '09:41');
});

function luminance(hex) {
  const rgb = hex.replace('#','').match(/../g).map(value => parseInt(value,16)/255);
  return rgb.map(value => value <= .04045 ? value/12.92 : ((value+.055)/1.055)**2.4)
    .reduce((sum,value,index) => sum + value*[.2126,.7152,.0722][index],0);
}
function contrast(a,b) {
  const values = [luminance(a),luminance(b)].sort((x,y) => y-x);
  return (values[0]+.05)/(values[1]+.05);
}
test('Proposed body, semantic, button, and disabled-label pairs exceed 4.5:1', () => {
  const pairs = [
    ['Navy / blanco','#1B2B48','#FFFFFF'],['Secundario / fondo','#526078','#F4F6FA'],
    ['Verde / tonal','#176B50','#EAF5EF'],['Ámbar / tonal','#80520A','#FFF4DE'],
    ['Crítico / tonal','#B52F34','#FFF0EE'],['Deshabilitado / tonal','#526078','#E9EDF3'],
    ['Texto vehículo / navy','#C5D2E5','#1B2B48'],['Origen crítico / tonal','#6A4148','#FFF0EE'],
  ];
  for (const [label,a,b] of pairs) {
    const ratio = contrast(a,b);
    assert.ok(ratio >= 4.5, `${label}: ${ratio.toFixed(2)}:1`);
    console.log(`${label}: ${ratio.toFixed(2)}:1`);
  }
  for (const accent of ['#2ECC71','#F39C12','#E74C3C']) {
    assert.ok(contrast('#FFFFFF',accent) < 4.5);
  }
});

test('The prototype uses local assets, prevents form submission and has no data/network APIs', () => {
  const root = path.resolve(__dirname,'..');
  const html = fs.readFileSync(path.join(root,'index.html'),'utf8');
  const js = fs.readFileSync(path.join(root,'prototype.js'),'utf8');
  assert.match(html, /connect-src 'none'/);
  assert.match(html, /form-action 'none'/);
  assert.doesNotMatch(html, /(?:src|href)="https?:/);
  assert.doesNotMatch(js, /\b(fetch|XMLHttpRequest|WebSocket|localStorage|sessionStorage)\b/);
  assert.match(js, /event\.preventDefault\(\)/);
  assert.ok(fs.statSync(path.join(root,'assets','Manrope-variable.ttf')).size > 10000);
  assert.ok(fs.existsSync(path.join(root,'assets','OFL.txt')));
  assert.ok(fs.existsSync(path.join(root,'assets','FONTLOG.txt')));
});
