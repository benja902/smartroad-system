(function() {
  'use strict';
  const F = window.UrbesFixtures;
  const names = { login: 'Login', home: 'Inicio', alerts: 'Alertas', emergency: 'Emergencia crítica' };
  const captions = { login: 'Marca y acceso', home: 'Vehículo y últimos datos', alerts: 'Atención moderada', emergency: 'Incidente grave activo' };
  const scenarios = {
    login: [['ready','Formulario'],['loading','Envío en curso'],['error','Error de autenticación']],
    home: [['reported','Datos disponibles'],['attention','Con alerta moderada'],['noData','Sin datos del SDA'],['previous','Último dato anterior'],['loading','Consulta inicial'],['error','Error de lectura']],
    alerts: [['attention','Atención + registros'],['empty','Consulta sin incidentes'],['loading','Consulta inicial'],['error','Error de lectura'],['deferred','Grave recibido con retraso'],['cancelled','Cancelado desde el SDA'],['acknowledged','Aviso ya visto'],['unknown','Tipo desconocido · técnico']],
    emergency: [['active','Emergencia activa'],['noLocation','Sin ubicación'],['lastLocation','Última posición · sin fix'],['noTime','Hora del evento desconocida'],['deferred','Diferido · ver en Alertas'],['cancelled','Cancelado · ver en Alertas'],['acknowledged','Ya visto · ver en Alertas']],
  };
  const query = new URLSearchParams(location.search);
  // Headless desktop Chrome can impose a minimum viewport wider than a phone.
  // Explicit artboard dimensions keep exported phone captures faithful.
  for (const axis of ['width','height']) {
    const size = Number(query.get(axis));
    if (size >= 240 && size <= 2000) document.documentElement.style.setProperty(`--capture-${axis}`,`${size}px`);
  }
  const initialScreen = names[query.get('screen')] ? query.get('screen') : 'home';
  const state = {
    screen: initialScreen, mode: query.has('capture') ? 'capture' : query.has('board') ? 'board' : query.has('screen') ? 'focus' : 'gallery',
    login: 'ready', home: 'reported', alerts: 'attention', emergency: 'active',
    type: ['crash','rollover','sos'].includes(query.get('type')) ? query.get('type') : 'crash',
    variant: query.get('variant') === 'light' ? 'light' : 'navy',
    scale: ['1','1.5','2'].includes(query.get('scale')) ? query.get('scale') : '1',
    reduced: query.get('reduced') === '1', ackFailure: false, moderateAck: false, criticalAck: false,
    moderateError: false, criticalError: false, visited: new Set(), scroll: {},
  };
  if (scenarios[initialScreen].some(([value]) => value === query.get('state'))) state[initialScreen] = query.get('state');
  const $ = (selector, parent = document) => parent.querySelector(selector);
  const icon = (name, extra = '') => `<svg class="icon ${extra}" aria-hidden="true" focusable="false"><use href="#i-${name}"/></svg>`;
  const mark = () => '<svg class="brand-mark" aria-hidden="true"><use href="#i-mark"/></svg>';
  const brand = () => `<div class="app-brand">${mark()}<span>URBES</span></div>`;
  const header = (avatar = true) => `<header class="app-header">${brand()}${avatar ? '<span class="avatar" aria-label="Cuenta ficticia de Andrea">A</span>' : ''}</header>`;
  const systemBar = () => `<div class="system-bar" aria-hidden="true"><span>9:41</span><span class="system-indicators">${icon('signal')}${icon('wifi')}${icon('battery')}</span></div>`;
  const badge = (label, tone = '', symbol = '') => `<span class="badge ${tone}">${symbol ? icon(symbol) : ''}${label}</span>`;
  const nav = (screen) => `<nav class="nav-bar" aria-label="Navegación principal del prototipo">${[
    ['home','Inicio','home'],['alerts','Alertas','bell'],['vehicle','Vehículo','car'],['history','Historial','history'],['profile','Perfil','user'],
  ].map(([id,label,symbol]) => `<button class="nav-item" ${id === screen ? 'aria-current="page"' : ''} ${names[id] ? `data-app-screen="${id}"` : 'aria-disabled="true" title="Pantalla fuera del alcance de este prototipo"'}><span class="nav-icon">${icon(symbol)}</span><span>${label}</span></button>`).join('')}</nav>`;
  function statePanel(kind, heading, copy) {
    return `<section class="state-panel" ${kind === 'loading' ? 'aria-busy="true"' : ''}>${kind === 'loading' ? '<span class="spinner" aria-hidden="true"></span>' : icon(kind === 'error' ? 'info' : 'bell')}<h3>${heading}</h3><p class="body-copy">${copy}</p>${kind === 'loading' ? '<div class="skeleton"></div><div class="skeleton short"></div>' : ''}</section>`;
  }
  function login(context) {
    const prefix = `login-${context}`;
    const loading = state.login === 'loading';
    return `<section class="screen login-screen" aria-label="Login">${header(false)}<div class="app-scroll"><div class="login-content">
      <div class="login-identity" aria-hidden="true"><svg class="login-road" viewBox="0 0 310 135"><path class="road-soft" d="M0 114h88c54 0 45-94 109-94h14M0 130h88c65 0 56-94 109-94h14"/><path class="route-dash" d="M0 122h88c60 0 50-94 109-94h20"/><use class="brand-mark" href="#i-mark" x="199" y="1" width="109" height="130"/></svg></div>
      <div class="entrance-target"><h2 class="screen-title">Bienvenido<br>a URBES.</h2><p class="body-copy">Consulta el estado de tu vehículo<br>y sus alertas.</p></div>
      <form class="login-form" data-login-form novalidate autocomplete="off">
        <div class="field"><label for="${prefix}-email">Correo</label><div class="input-wrap"><input id="${prefix}-email" name="email" type="email" inputmode="email" placeholder="tu-correo@example.invalid" aria-describedby="${prefix}-email-error" ${loading ? 'disabled' : ''}></div><p class="field-error" id="${prefix}-email-error" data-field-error="email" hidden></p></div>
        <div class="field"><label for="${prefix}-password">Contraseña</label><div class="input-wrap"><input id="${prefix}-password" name="password" type="password" placeholder="Ingresa tu contraseña" aria-describedby="${prefix}-password-error" ${loading ? 'disabled' : ''}><button class="eye-button" type="button" data-action="toggle-password" aria-label="Mostrar contraseña" aria-pressed="false" ${loading ? 'disabled' : ''}>${icon('eye')}</button></div><p class="field-error" id="${prefix}-password-error" data-field-error="password" hidden></p></div>
        ${state.login === 'error' ? '<p class="inline-message" role="status">Correo o contraseña incorrectos.</p>' : ''}
        <button class="button" type="submit" ${loading ? 'disabled aria-busy="true"' : ''}>${loading ? '<span class="spinner" aria-hidden="true"></span>Ingresando…' : 'Iniciar sesión'}</button>
      </form><p class="login-footnote">Usa tu cuenta registrada.</p>
    </div></div></section>`;
  }
  function vehicleCard() {
    return `<section class="vehicle-card entrance-target" aria-label="Vehículo vinculado"><div class="vehicle-top"><p class="vehicle-label">Tu vehículo</p><span class="vehicle-plate">${F.vehicle.plate}</span></div><h3 class="vehicle-name">${F.vehicle.name}</h3><svg class="vehicle-illustration" aria-hidden="true"><use href="#vehicle-profile"/></svg><div class="vehicle-footer">${icon('mark')}<span>Un vehículo vinculado a tu cuenta</span></div></section>`;
  }
  function home() {
    const missing = state.home === 'noData';
    const previous = state.home === 'previous';
    const usable = !missing && !['loading','error'].includes(state.home);
    return `<section class="screen home-screen ${state.variant === 'light' ? 'light-vehicle' : ''}" aria-label="Inicio">${header()}<div class="app-scroll"><div class="page-pad">
      <div class="welcome entrance-target"><h2 class="screen-title">Hola, Andrea.</h2><p class="body-copy">Tu vehículo y sus últimos datos.</p></div>
      ${state.criticalAck ? '<p class="inline-message neutral" role="status">Marcaste el aviso como visto. Esto no cancela el incidente.</p><div style="height:16px"></div>' : ''}
      ${state.home === 'attention' && !state.moderateAck ? `<button class="home-attention" data-app-screen="alerts">${icon('warning')}<span class="grow"><strong>Una alerta requiere tu atención</strong><span>Posible accidente · recibido 09:38</span></span>${icon('chevron')}</button>` : ''}
      ${vehicleCard()}
      ${state.home === 'loading' ? statePanel('loading','Consultando el SDA','Los datos aparecerán cuando termine la consulta.') : state.home === 'error' ? statePanel('error','No pudimos consultar el SDA','La lectura falló. Esto no permite confirmar su disponibilidad.') : `
        <section class="availability ${missing || previous ? 'unknown' : ''}" aria-label="Disponibilidad del SDA"><span class="icon-box">${icon(missing ? 'info' : previous ? 'clock' : 'link')}</span><div><h3>${missing ? 'Sin datos del SDA' : previous ? 'Último estado conocido' : 'SDA conectado'}</h3><p class="small-copy">${missing ? 'Disponibilidad no confirmada.' : previous ? 'Última comunicación: ayer, 18:20.<br>No confirma la disponibilidad actual.' : 'Dato de disponibilidad del SDA.<br>Última comunicación: 09:41.'}</p></div></section>
        <section aria-label="Información del último estado"><h3 class="section-heading">${previous ? 'En el último dato conocido' : 'Información del SDA'}</h3><div class="metrics"><div class="metric">${icon('battery')}<p class="metric-label">Batería</p><p class="metric-value">${usable ? '4,08 <span>V</span>' : '<span>No disponible</span>'}</p></div><div class="metric">${icon('signal')}<p class="metric-label">Señal celular</p><p class="metric-value">${usable ? '−83 <span>dBm</span>' : '<span>No disponible</span>'}</p></div></div></section>
        <section class="location-row">${icon('pin')}<div class="grow"><h3>${missing ? 'Ubicación no disponible' : previous ? 'Última posición conocida' : 'Posición GNSS con fix'}</h3><p class="small-copy">${missing ? 'No hay datos de posición en esta consulta.' : previous ? 'Dato anterior; no es ubicación actual.' : 'Incluida en el último estado del SDA.'}</p><div class="map-pending"><button class="button compact secondary" disabled>${icon('pin')}Ver mapa</button><p class="pending-note">Mapa no disponible en esta versión.</p></div></div></section>`}
      <button class="recent-link" data-app-screen="alerts"><span class="icon-box">${icon('bell')}</span><span class="grow"><strong>Alertas del vehículo</strong><span>Consultar registros recibidos</span></span>${icon('chevron')}</button>
    </div></div>${nav('home')}</section>`;
  }
  function eventRow(symbol, heading, copy, label = '', tone = '') {
    return `<article class="event-row"><span class="icon-box ${tone}">${icon(symbol)}</span><div class="grow"><h4>${heading}</h4><p>${copy}</p>${label ? badge(label,tone) : ''}</div></article>`;
  }
  function historyRows(mode) {
    if (mode === 'deferred') return eventRow('history','Choque · grave','Hora del evento no disponible.<br>Recibido hoy, 09:18.','Recepción diferida');
    if (mode === 'cancelled') return eventRow('check','Choque · moderado','Recibido ayer, 17:03.','Cancelado desde el SDA');
    if (mode === 'acknowledged') return eventRow('eye',state.type === 'sos' ? 'Auxilio solicitado · SOS' : 'Choque · grave','Recibido hoy, 09:41.','Ya lo viste');
    return `${state.moderateAck ? eventRow('eye','Posible accidente · moderado','Recibido hoy, 09:38.','Ya lo viste') : ''}${eventRow('history','Choque · grave','Hora del evento no disponible.<br>Recibido hoy, 09:18.','Recepción diferida')}${eventRow('check','Choque · moderado','Recibido ayer, 17:03.','Cancelado desde el SDA')}`;
  }
  function alerts() {
    const mode = state.alerts;
    let content;
    if (mode === 'loading') content = statePanel('loading','Consultando alertas','Todavía no hay un resultado de esta consulta.');
    else if (mode === 'error') content = statePanel('error','No pudimos cargar las alertas','Un error de lectura no confirma ausencia de incidentes.');
    else if (mode === 'empty') content = statePanel('empty','Sin incidentes en esta consulta','Cuando haya registros disponibles, podrás revisarlos aquí.');
    else {
      const attention = mode === 'attention' && !state.moderateAck;
      content = `<section aria-label="Alertas que requieren atención"><div class="section-top"><h3 class="section-heading">Requieren atención</h3>${attention ? '<span class="count">1</span>' : ''}</div>${attention ? `
        <article class="attention-card">${badge('Moderado','attention','warning')}<h4>Posible accidente<br>detectado</h4><p class="body-copy">Impacto inusual registrado en el vehículo ${F.vehicle.plate}.</p><p class="event-meta">Recibido hoy, 09:38.<br>Hora del evento: 09:37.</p><button class="button compact secondary" data-action="ack-moderate">${icon('check')}Ya lo vi</button><p class="pending-note">Solo registra que viste el aviso.</p>${state.moderateError ? '<p class="inline-message" role="status">No se pudo guardar el acuse. El aviso sigue pendiente.</p>' : ''}</article>` : '<p class="empty-inline">Sin avisos por revisar en esta consulta.</p>'}</section>
        ${state.moderateAck && mode === 'attention' ? '<p class="inline-message neutral" role="status">Aviso marcado como visto. No se canceló el incidente.</p>' : ''}
        ${mode === 'attention' ? `<section class="section-gap"><h3 class="section-heading">Informativos</h3>${eventRow('car','Choque · leve','Recibido hoy, 08:24.','Informativo')}</section>` : ''}
        <section class="section-gap"><div class="section-top"><h3 class="section-heading">Estado técnico</h3></div><div class="technical-summary">${icon('info')}<div><strong>${mode === 'unknown' ? 'Tipo de evento desconocido' : 'Reinicio del SDA registrado'}</strong><p>${mode === 'unknown' ? 'Registro técnico. No se presenta como emergencia.' : 'Recibido hoy, 08:12.'}</p></div></div></section>
        <section class="section-gap"><h3 class="section-heading">Historial reciente</h3>${mode === 'unknown' ? '<p class="empty-inline" style="margin-top:16px">Sin incidentes históricos en esta consulta.</p>' : historyRows(mode)}</section>
        ${mode === 'deferred' ? '<p class="pending-note">El equipo transmitió este incidente con retraso. No se presenta como recién ocurrido.</p>' : ''}`;
    }
    return `<section class="screen alerts-screen" aria-label="Alertas">${header()}<div class="app-scroll"><div class="page-pad"><div class="alert-intro"><h2 class="screen-title">Alertas</h2><p class="body-copy">Lo importante primero.<br>Los registros, con su contexto.</p></div>${content}</div></div>${nav('alerts')}</section>`;
  }
  function emergency(context) {
    const event = F.criticalExample(state.type, state.emergency);
    // Even direct capture links cannot turn queued/cancelled/seen into a takeover.
    if (F.classify(event) !== 'activeEmergency') {
      return alerts();
    }
    const loc = F.locationCopy(event.position);
    const sos = event.type === 'sos';
    const explanation = 'Registra que viste el aviso. No cancela el incidente ni solicita ayuda.';
    const explanationId = `ack-scope-${context}`;
    const largeText = Number(state.scale) > 1.4;
    const title = sos ? 'Auxilio<br>solicitado' : event.type === 'rollover' ? 'Volcadura<br>detectada' : 'Choque severo<br>detectado';
    return `<section class="screen emergency-screen" aria-label="Emergencia activa" data-critical="true"><div class="app-scroll">
      <header class="emergency-head"><div class="emergency-label">${icon(sos ? 'sos' : 'warning')}<span>Emergencia activa${sos ? ' · SOS' : ''}</span></div><h2 class="screen-title">${title}</h2><p class="emergency-vehicle">${F.vehicle.plate} · ${F.vehicle.name}</p><p class="body-copy">${sos ? 'Solicitud manual desde el SDA.' : 'Detección automática del SDA.'}</p></header>
      <div class="emergency-content"><section class="location-emergency"><div class="row">${icon('pin')}<div class="grow"><h3>${loc.title}</h3>${loc.coordinates ? `<p class="coordinates">${loc.coordinates}</p>` : ''}<p class="small-copy">${loc.quality}</p></div></div>${loc.tone === 'attention' ? badge('No es ubicación actual','attention','clock') : ''}<button class="button compact secondary" disabled style="margin-top:14px">${icon('pin')}Ver mapa</button><p class="pending-note">Mapa no disponible en esta versión.</p></section>
      <dl class="data-list"><div><dt>Hora del evento</dt><dd>${F.clock(event.ts)}</dd></div><div><dt>Recepción del aviso</dt><dd>${F.clock(event.receivedAt)}</dd></div></dl>
      ${largeText ? `<p class="small-copy ack-scope" id="${explanationId}">${explanation}</p>` : ''}
      <details class="diagnostics"><summary>Diagnóstico del equipo${icon('chevron')}</summary><p class="small-copy">Datos incluidos en este evento. No representan el estado actual.</p><dl class="data-list"><div><dt>Batería</dt><dd>4,08 V</dd></div><div><dt>Señal celular</dt><dd>−83 dBm</dd></div><div><dt>microSD</dt><dd>Presente</dd></div></dl></details></div>
      </div><footer class="emergency-actions"><button class="button" data-action="ack-critical" aria-describedby="${explanationId}">${icon('check')}Ya lo vi</button>${!largeText ? `<p id="${explanationId}">${explanation}</p>` : ''}${state.criticalError ? '<p class="inline-message" role="status">No se pudo guardar el acuse. La emergencia sigue visible.</p>' : ''}</footer></section>`;
  }
  const renderers = { login, home, alerts, emergency };
  function phone(screen, context) {
    return `<div class="phone" data-phone="${screen}" data-context="${context}">${systemBar()}${renderers[screen](context)}</div>`;
  }
  const notes = {
    login: ['La marca abre. El formulario responde.', 'Un gesto vectorial recoge la identidad del piloto. Los campos mantienen etiquetas visibles y el acceso conserva protagonismo, sin enlaces a funciones pendientes.', 'Prueba campos vacíos, visibilidad de contraseña y acceso con valores ficticios. El envío no incorpora una espera decorativa.', '240 ms · 6 px · una sola entrada', 'Foco visible · controles de 48 px'],
    home: ['Un vehículo. Una lectura más clara.', 'La superficie del vehículo es el punto de reconocimiento. Disponibilidad, comunicación y datos se leen por separado: una conexión no equivale a protección garantizada.', 'Compara la superficie navy con la variante clara. Revisa ausencia de datos, dato anterior y aviso moderado. Los valores del SDA nunca se inventan en la variante vacía.', 'Primera entrada finita · scroll retenido', 'Ubicación y mapa separados'],
    alerts: ['Prioridad sin ruido.', 'La atención ocupa una superficie. Los demás registros son filas con contexto temporal y etiquetas. Diferido, cancelado y ya visto permanecen distintos.', 'Pulsa «Ya lo vi» y repite simulando fallo del acuse. El fallo mantiene el registro; el éxito simulado lo lleva al historial. Los detalles pendientes no son una acción.', 'Acuse personal · sin cancelación', 'Sin pulso · sin contador'],
    emergency: ['Lo esencial, inmediatamente.', 'Tipo de incidente, vehículo y calidad de ubicación encabezan la pantalla. El diagnóstico del propietario se despliega cuando se necesita. La navegación inferior desaparece.', 'Cambia entre choque, volcadura y SOS; revisa ubicación ausente, última posición y hora desconocida. Un grave diferido se presenta en Alertas, no como emergencia activa.', 'Entrada inmediata · sin transición', 'Sin llamada ni ayuda ficticias'],
  };
  function saveScroll() {
    document.querySelectorAll('.phone[data-context="focus"] .app-scroll').forEach(el => { state.scroll[state.screen] = el.scrollTop; });
  }
  function renderFocus(animate = false) {
    $('#focused-phone').innerHTML = phone(state.screen,'focus');
    const scroller = $('#focused-phone .app-scroll');
    if (scroller) scroller.scrollTop = state.scroll[state.screen] || 0;
    if (animate && state.screen !== 'emergency') {
      $('#focused-phone').querySelectorAll('.entrance-target').forEach(el => el.classList.add('first-entrance'));
    }
    const note = notes[state.screen];
    $('#screen-notes').innerHTML = `<h3>${note[0]}</h3><p>${note[1]}</p><div class="note-block"><h4>Para evaluar</h4><p>${note[2]}</p></div><div class="note-tags"><span>${note[3]}</span><span>${note[4]}</span></div><div class="note-block"><h4>Fuera de estas maquetas</h4><p>Vehículo, Historial y Perfil conservan su lugar en la barra. Sus pantallas y funcionalidades no se amplían en esta fase.</p></div>`;
  }
  function renderGallery() {
    $('#gallery').innerHTML = Object.keys(names).map(screen => `<article class="device-card"><div class="device-caption"><h3>${names[screen]}</h3><span>${captions[screen]}</span></div>${phone(screen,'gallery')}</article>`).join('');
  }
  function renderControls() {
    $('#scenario-label').textContent = `Escenario de ${names[state.screen]}`;
    $('#scenario').innerHTML = scenarios[state.screen].map(([value,label]) => `<option value="${value}">${label}</option>`).join('');
    $('#scenario').value = state[state.screen];
    $('#critical-type').value = state.type;
    $('#type-control').hidden = state.screen !== 'emergency';
    $('#variant-control').hidden = state.screen !== 'home';
    $('#home-variant').value = state.variant;
    $('#text-scale').value = state.scale;
    $('#reduce-motion').checked = state.reduced;
    $('#ack-failure').checked = state.ackFailure;
    document.querySelectorAll('.screen-picker [data-screen]').forEach(button => button.setAttribute('aria-current',String(button.dataset.screen === state.screen && !['gallery','board'].includes(state.mode))));
    $('#review-title').textContent = ['gallery','board'].includes(state.mode) ? 'Una identidad. Cuatro momentos.' : `${names[state.screen]} · propuesta visual`;
  }
  function render(animate = false) {
    document.body.classList.toggle('capture',state.mode === 'capture');
    document.body.classList.toggle('board',state.mode === 'board');
    document.body.classList.toggle('reduced-motion',state.reduced);
    document.body.classList.toggle('large-type',Number(state.scale) > 1.4);
    document.documentElement.style.setProperty('--text-scale',state.scale);
    $('#gallery').hidden = !['gallery','board'].includes(state.mode);
    $('#focus').hidden = ['gallery','board'].includes(state.mode);
    renderGallery();
    renderFocus(animate);
    renderControls();
  }
  function announce(message) { $('#review-status').textContent = message; }
  function openScreen(screen, urgent = false) {
    if (!names[screen]) return;
    saveScroll();
    state.screen = screen;
    if (state.mode !== 'capture') state.mode = 'focus';
    const animate = !urgent && !state.visited.has(screen);
    state.visited.add(screen);
    render(animate);
    if (!urgent && ['home','alerts'].includes(screen)) $('#focused-phone .phone').classList.add('navigation-feedback');
    const heading = $('#focused-phone h2');
    if (heading) { heading.tabIndex = -1; heading.focus({preventScroll:true}); }
  }
  function setScenario(value) {
    if (!scenarios[state.screen].some(([id]) => id === value)) return;
    saveScroll();
    state[state.screen] = value;
    state.moderateError = false;
    state.criticalError = false;
    if (state.screen === 'alerts') state.moderateAck = false;
    if (state.screen === 'emergency' && ['deferred','cancelled','acknowledged'].includes(value)) {
      state.alerts = value;
      announce('Este ejemplo se presenta en Alertas según su clasificación. No abre una emergencia activa.');
      openScreen('alerts',true);
      return;
    }
    announce('');
    render();
  }
  document.addEventListener('click',event => {
    const button = event.target.closest('button');
    if (!button || button.disabled || button.getAttribute('aria-disabled') === 'true') return;
    if (button.dataset.screen) { announce(''); openScreen(button.dataset.screen); return; }
    if (button.dataset.appScreen) { announce(''); openScreen(button.dataset.appScreen); return; }
    switch (button.dataset.action) {
      case 'gallery': saveScroll(); state.mode = 'gallery'; announce(''); render(); break;
      case 'toggle-password': {
        const field = button.parentElement.querySelector('input');
        const show = field.type === 'password'; field.type = show ? 'text' : 'password';
        button.setAttribute('aria-label',show ? 'Ocultar contraseña' : 'Mostrar contraseña');
        button.setAttribute('aria-pressed',String(show)); button.innerHTML = icon(show ? 'eye-off' : 'eye'); break;
      }
      case 'ack-moderate':
        saveScroll();
        if (state.ackFailure) state.moderateError = true;
        else { state.moderateAck = true; state.moderateError = false; }
        render(); break;
      case 'ack-critical':
        if (state.ackFailure) { saveScroll(); state.criticalError = true; render(); }
        else { state.criticalAck = true; state.criticalError = false; state.alerts = 'acknowledged'; openScreen('home',true); }
        break;
      case 'simulate-critical':
        if (state.screen === 'login' && state.mode === 'focus') { announce('Inicia la sesión ficticia para probar la interrupción. La vista de Emergencia del estudio puede revisarse por separado.'); break; }
        state.emergency = 'active'; state.criticalAck = false; state.criticalError = false;
        announce('Llegada crítica simulada. La pantalla aparece inmediatamente.'); openScreen('emergency',true); break;
      case 'reset':
        Object.assign(state,{login:'ready',home:'reported',alerts:'attention',emergency:'active',type:'crash',variant:'navy',moderateAck:false,criticalAck:false,moderateError:false,criticalError:false,ackFailure:false,scroll:{},visited:new Set()});
        announce('Ejemplos restablecidos. No se guardan datos entre aperturas.'); render(); break;
    }
  });
  document.addEventListener('submit',event => {
    if (!event.target.matches('[data-login-form]')) return;
    event.preventDefault();
    const form = event.target;
    let firstInvalid = null;
    ['email','password'].forEach(name => {
      const input = form.elements[name];
      // Match the existing Flutter validation: nonempty fields. No extra auth policy.
      const invalid = name === 'email' ? !input.value.trim() : !input.value;
      input.setAttribute('aria-invalid',String(invalid));
      const error = $(`[data-field-error="${name}"]`,form);
      error.hidden = !invalid; error.textContent = invalid ? (name === 'email' ? 'Ingresa tu correo' : 'Ingresa tu contraseña') : '';
      if (invalid && !firstInvalid) firstInvalid = input;
    });
    if (firstInvalid) { firstInvalid.focus(); return; }
    announce('Acceso ficticio. No se envió ni guardó el correo o la contraseña.'); openScreen('home');
  });
  $('#scenario').addEventListener('change',event => setScenario(event.target.value));
  $('#critical-type').addEventListener('change',event => { saveScroll(); state.type = event.target.value; render(); });
  $('#home-variant').addEventListener('change',event => { saveScroll(); state.variant = event.target.value; render(); });
  $('#text-scale').addEventListener('change',event => { saveScroll(); state.scale = event.target.value; render(); });
  $('#reduce-motion').addEventListener('change',event => { saveScroll(); state.reduced = event.target.checked; render(); });
  $('#ack-failure').addEventListener('change',event => { state.ackFailure = event.target.checked; });
  // Read-only inspection + review actions for the local browser validation harness.
  window.UrbesPrototype = Object.freeze({openScreen,setScenario,getState:() => ({screen:state.screen,mode:state.mode,scenario:state[state.screen],moderateAck:state.moderateAck,criticalAck:state.criticalAck})});
  if (state.screen === 'emergency' && ['deferred','cancelled','acknowledged'].includes(state.emergency)) {
    state.alerts = state.emergency; state.screen = 'alerts';
  }
  state.visited.add(state.screen);
  render(state.mode === 'focus');
  const captureSection = {location:'.location-emergency',diagnostics:'.diagnostics'}[query.get('section')];
  if (state.mode === 'capture' && captureSection) document.fonts.ready.then(() => {
    const target = $('#focused-phone').querySelector(captureSection);
    const scroll = $('#focused-phone .app-scroll');
    if (target && scroll) scroll.scrollTop = target.offsetTop - scroll.offsetTop;
  });
})();
