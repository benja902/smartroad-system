/* Review-only refinement of existing compositions. No application logic. */
(function () {
  'use strict';
  const rows = [...document.querySelectorAll('.comparison-row')];
  const historical = rows.map(row => row.innerHTML);
  const originals = rows.map(row => row.querySelector('.candidate .phone').cloneNode(true));
  const tools = document.querySelector('.review-tools');
  tools.insertAdjacentHTML('afterbegin', '<label for="review-mode">Comparación</label><select id="review-mode"><option value="refined">Actual / propuesta refinada</option><option value="palette">Paletas históricas</option></select>');
  tools.insertAdjacentHTML('beforeend', '<label for="review-state">Estado propuesto</label><select id="review-state"><option value="ready">Contenido</option><option value="loading">Carga / envío</option><option value="error">Error</option><option value="empty">Vacío / sin ubicación</option></select><label class="ds-motion"><input type="checkbox" id="review-motion"> Reducir movimiento</label>');
  document.querySelector('.lab-head h1').innerHTML = 'URBES, con una misma voz.<br>Design System v1.0';
  document.querySelector('.lab-head > p').textContent = 'Smart Road System URBES · Propuesta consolidada para revisión';
  document.querySelector('.lab-head h1 + p').textContent = 'Propuesta pendiente de aprobación. La escena y el cierre D se conservan; refinamos el formulario, las superficies y la lectura de estados sobre los componentes existentes.';
  document.querySelector('.lab-notice').innerHTML = 'La izquierda muestra el Login Flutter DEV aprobado y reconstrucciones HTML del código actual para Inicio, Alertas y Emergencia. No son capturas Android de esas tres pantallas. La derecha es una propuesta visual. Todos los datos son ficticios y las acciones de producto están desactivadas. <a href="DESIGN_SYSTEM_V1_PROPOSAL.md">Leer propuesta consolidada</a> · <a href="ACCESSIBILITY.md">Accesibilidad</a>';
  const svg = (name) => `<svg class="icon" aria-hidden="true"><use href="#i-${name}"/></svg>`;
  const library = document.querySelector('.svg-library defs');
  library.insertAdjacentHTML('beforeend', '<symbol id="i-mail" viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 6 9 7 9-7"/></symbol><symbol id="i-lock" viewBox="0 0 24 24"><rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V6a4 4 0 0 1 8 0v4m-4 4v3"/></symbol><symbol id="i-search" viewBox="0 0 24 24"><circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/></symbol>');
  const button = (label, extra = '') => `<button type="button" class="button ${extra}" disabled>${label}</button>`;
  const brand = '<div class="ds-brand"><img src="../motion_prototype_01/logo.svg" alt=""><strong>URBES</strong></div>';
  const dataNote = '<p class="ds-fixture">Ejemplo ficticio · un vehículo y un SDA</p>';
  function baseline(index) {
    if (index === 0) return '<div class="phone ds-baseline-image"><div class="ds-image-scroll"><img src="../flutter_increment_1/login_flutter_4440.png" alt="Captura propia del Login real Flutter DEV aprobado, con escena D y formulario existente"></div></div>';
    const phone = originals[index].cloneNode(true);
    phone.className = 'phone current-code';
    const header = phone.querySelector('.app-header');
    if (header) header.innerHTML = `${svg('mark')}<strong>URBES</strong>${svg('signal')}`;
    let content;
    if (index === 1) content = `<h2>Hola, Andrea</h2><p>Tu vehículo está funcionando correctamente</p><section class="current-card"><h3>${svg('check')} URBES operativo</h3><p>Monitoreo activo</p></section><section class="current-card"><h3>Indicadores del dispositivo</h3><div class="current-grid"><div>Batería<strong>4,08 V</strong></div><div>Señal<strong>−83 dBm</strong></div><div>GNSS<strong>Con fix</strong></div><div>microSD<strong>Presente</strong></div></div></section><section class="current-card"><h3>Vehículo principal</h3><p>Vehículo de demostración · Placa: DEMO-01</p><span class="current-success">Dispositivo URBES conectado</span></section><section class="current-card"><h3>Ubicación del vehículo</h3><p>Posición GNSS del ejemplo</p>${button('Ver mapa')}</section><section class="current-card"><h3>Contactos de emergencia</h3><p>Gestionar · Historial · Vehículo</p></section>`;
    if (index === 2) content = `<h2>Alertas</h2><p>Última actualización: 09:41</p><h3>Alertas activas</h3><section class="current-card"><span class="current-warning">Moderado</span><h3>Posible accidente detectado</h3><p>Impacto inusual registrado en el vehículo.</p><p>09:37 · DEMO-01</p>${button('Ya lo vi')}${button('Ver Detalles','secondary')}</section><h3>Eventos informativos</h3><section class="current-card"><h3>Choque leve</h3><p>08:24 · Informativo</p></section><h3>Estado técnico</h3><section class="current-card"><p>Reinicio del SDA registrado</p></section><h3>Historial reciente</h3><section class="current-card"><p>Choque grave · Recepción diferida</p></section>`;
    if (index === 3) {
      phone.querySelector('.screen').innerHTML = `<div class="app-scroll"><div class="current-body current-emergency"><div class="current-critical-symbol">${svg('warning')}</div><h2>CHOQUE SEVERO DETECTADO</h2><span class="current-critical">ALERTA DE EMERGENCIA · GRAVE</span><p>El equipo activó automáticamente el protocolo de emergencia.</p><section class="current-card"><h3>EMERGENCIA ACTIVA</h3><p>Esta pantalla se cerrará automáticamente si la alerta se anula desde el equipo, o si la marcas como atendida abajo.</p></section><section class="current-card"><h3>Ubicación del incidente</h3><p>Posición GNSS con fix</p></section><section class="current-card"><h3>VEHÍCULO</h3><p>DEMO-01</p></section><section class="current-card"><h3>HORA · ORIGEN</h3><p>09:37 · Detección automática</p></section><section class="current-card"><h3>Diagnóstico del equipo al momento del evento</h3><p>Batería: 4,08 V · Señal: −83 dBm</p></section></div></div><div class="emergency-actions">${button('VER INCIDENTE')}${button('LLAMAR A EMERGENCIAS','current-critical-button')}${button('Ya lo vi — marcar como atendido','secondary')}</div>`;
      return phone.outerHTML;
    }
    phone.querySelector('.app-scroll').innerHTML = `<div class="current-body">${content}</div>`;
    return phone.outerHTML;
  }
  function statePanel(kind) {
    const copy = {
      loading: ['Consultando datos', 'La consulta todavía no terminó.'],
      error: ['No pudimos cargar los datos', 'Esto no confirma ausencia de incidentes.'],
      empty: ['Sin registros en esta consulta', 'Los registros aparecerán cuando estén disponibles.'],
    }[kind];
    return `<section class="state-panel" ${kind === 'loading' ? 'aria-busy="true"' : ''}>${svg(kind === 'error' ? 'info' : 'bell')}<h3>${copy[0]}</h3><p class="body-copy">${copy[1]}</p>${kind === 'loading' ? '<div class="skeleton"></div><div class="skeleton short"></div>' : ''}</section>`;
  }
  function login(state) {
    return `<div class="phone ds-refined ds-login"><section class="screen"><div class="app-scroll"><div class="ds-approved-header"><img src="../flutter_increment_1/closure_flutter_4440.png" alt="Marca e ilustración final D aprobadas"></div><div class="ds-login-body"><h2 class="screen-title">Bienvenido.</h2><p class="body-copy">Consulta el estado de tu vehículo<br>y sus alertas.</p><div class="ds-form">
      <div class="field"><label for="ds-email">Correo electrónico</label><div class="input-wrap">${svg('mail')}<input id="ds-email" readonly type="email" autocomplete="off" value="demo@example.invalid" aria-describedby="ds-email-help"></div><p class="ds-help" id="ds-email-help">Usa tu cuenta registrada.</p></div>
      <div class="field"><label for="ds-password">Contraseña</label><div class="input-wrap ${state === 'error' ? 'ds-field-error' : ''}">${svg('lock')}<input id="ds-password" readonly type="password" value="demo-only" autocomplete="off" ${state === 'error' ? 'aria-invalid="true" aria-describedby="ds-auth-error"' : ''}><button type="button" class="eye-button" data-demo-eye aria-label="Mostrar contraseña del ejemplo" aria-pressed="false">${svg('eye')}</button></div></div>
      ${state === 'error' ? '<p id="ds-auth-error" class="ds-auth-error" role="status">Correo o contraseña incorrectos.</p>' : ''}
      <button type="button" class="button" disabled ${state === 'loading' ? 'aria-busy="true"' : ''}>${state === 'loading' ? 'Ingresando…' : 'Iniciar sesión'}</button></div></div></div></section></div>`;
  }
  const notes = [
    ['Campos con iconos de correo y candado, etiquetas persistentes y ayudas legibles. Botón a 56 px y foco de alto contraste.', 'La escena y la marca son las aprobadas. El ojo es una interacción local de maqueta propuesta para Flutter. Google sigue como decisión funcional pendiente; no hay botón de acceso Google.'],
    ['Un vehículo protagonista; estado del SDA separado de las métricas y de la posición. Filas de datos con menos superficies repetidas.', 'Cambiar «operativo» por disponibilidad limitada al dato necesita revisión de contenido/contrato. No se decide frescura ni se implementa un mapa.'],
    ['Grupos existentes conservados; atención con énfasis ámbar y registros con divisores. Tiempo del evento separado de recepción.', 'El acuse conserva su operación. Detalles usa la ruta existente; completar su contenido sigue en el plan funcional.'],
    ['Urgencia estable, ubicación y vehículo antes del diagnóstico. Acuse visible, sin navegación inferior ni espera decorativa.', '«Ya lo vi» no cancela ni solicita ayuda. Llamada/mapa no se simulan como acciones operativas; su resolución sigue pendiente.'],
  ];
  function refined(index, state) {
    if (index === 0) return login(state === 'empty' ? 'ready' : state);
    const phone = originals[index].cloneNode(true);
    phone.classList.add('ds-refined');
    phone.querySelector('.app-header')?.replaceChildren();
    if (phone.querySelector('.app-header')) phone.querySelector('.app-header').innerHTML = brand;
    phone.querySelectorAll('.avatar').forEach(el => el.remove());
    phone.querySelectorAll('button').forEach(el => el.disabled = true);
    // Keep the pre-existing compositions; local emphasis and content refinements only.
    if (index === 1) {
      phone.querySelector('.vehicle-footer').textContent = 'Un vehículo vinculado a tu cuenta';
      phone.querySelector('.vehicle-plate').textContent = 'DEMO-01';
      phone.querySelector('.vehicle-name').textContent = 'Vehículo de demostración';
      phone.querySelector('.map-pending').innerHTML = '<p class="pending-note">Mapa pendiente de implementación.</p>';
      phone.querySelector('.recent-link').insertAdjacentHTML('beforebegin', `<div class="ds-quick-links">${button('Contactos de emergencia','secondary')}${button('Historial','secondary')}</div>`);
    }
    if (index === 2) phone.querySelector('.attention-card .body-copy').textContent = 'Impacto inusual registrado en el vehículo DEMO-01.';
    if (index === 3) {
      phone.querySelector('.emergency-vehicle').textContent = 'Vehículo DEMO-01';
      phone.querySelector('.coordinates').textContent = 'Posición GNSS del ejemplo';
      phone.querySelectorAll('.location-emergency button').forEach(el => el.remove());
      phone.querySelectorAll('.map-pending').forEach(el => el.innerHTML = '<p class="pending-note">Mapa pendiente de implementación.</p>');
    }
    if (state !== 'ready') {
      if (index !== 3) phone.querySelector('.app-scroll').innerHTML = `<div class="page-pad"><h2 class="screen-title">${index === 1 ? 'Inicio' : 'Alertas'}</h2>${statePanel(state)}${dataNote}</div>`;
      else if (state === 'empty') phone.querySelector('.location-emergency').innerHTML = `<h3>Ubicación no disponible</h3><p class="body-copy">El incidente permanece activo. No hay posición GNSS para este ejemplo.</p>`;
      else phone.querySelector('.location-emergency').insertAdjacentHTML('beforeend', `<p class="inline-message neutral">${state === 'error' ? 'No se pudo leer información adicional.' : 'Consultando información adicional.'} El incidente permanece visible.</p>`);
    }
    return phone.outerHTML;
  }
  function render() {
    const historicalMode = document.querySelector('#review-mode').value === 'palette';
    const state = document.querySelector('#review-state').value;
    document.querySelector('#review-state').disabled = historicalMode;
    rows.forEach((row, index) => {
      if (historicalMode) row.innerHTML = historical[index];
      else row.innerHTML = `<h2>${['Login','Inicio','Alertas','Emergencia'][index]}</h2><div class="palette-pair"><article class="palette previous"><h3>Actual · ${index ? 'reconstrucción del código Flutter' : 'captura Flutter DEV aprobada'}</h3>${baseline(index)}<p class="ds-caption">${index ? 'Referencia HTML de estructura y estilos; no captura ni réplica píxel a píxel. Caso de datos disponibles.' : 'Captura propia de QA; el selector de texto no modifica texto rasterizado.'}</p></article><article class="palette candidate"><h3>Propuesta refinada · pendiente de aprobación</h3>${refined(index,state)}<p class="ds-caption">${notes[index][0]}</p></article></div><aside class="ds-screen-note"><strong>Decisión y límites.</strong> ${notes[index][1]}</aside>`;
      const candidate = row.querySelector('.candidate');
      // Tokens use the same palette mapping already established by lab.js.
      const c = URBES_PROPOSAL.tokens.color;
      const aliases = {'--navy':'action.primary','--canvas':'surface.canvas','--surface':'surface.base','--ink':'text.primary','--secondary':'text.secondary','--line':'border.decorative','--soft':'surface.subtle','--green':'status.success.text','--green-bg':'status.success.surface','--amber':'status.warning.text','--amber-bg':'status.warning.surface','--red':'status.critical.text','--red-bg':'status.critical.surface','--interaction':'action.secondary','--accent-container':'action.secondaryContainer','--control-border':'border.control','--heading':'text.heading'};
      for (const [key,role] of Object.entries(aliases)) candidate.style.setProperty(key,c[role]);
    });
    applyScale();
  }
  function applyScale() {
    const scale = document.querySelector('#review-scale').value;
    document.querySelectorAll('.phone,.bench').forEach(node => {node.style.setProperty('--text-scale',scale);node.classList.toggle('large-type',Number(scale)>1);});
  }
  document.querySelector('#review-mode').addEventListener('change',render);
  document.querySelector('#review-state').addEventListener('change',render);
  document.querySelector('#review-scale').addEventListener('change',applyScale);
  document.querySelector('#review-motion').addEventListener('change',event => document.body.classList.toggle('reduced-motion',event.target.checked));
  document.addEventListener('click',event => {
    const eye = event.target.closest('[data-demo-eye]');
    if (!eye) return;
    const field = eye.parentElement.querySelector('input'), shown = field.type === 'password';
    field.type = shown ? 'text' : 'password';eye.setAttribute('aria-pressed',String(shown));
    eye.setAttribute('aria-label',(shown ? 'Ocultar' : 'Mostrar')+' contraseña del ejemplo');
    eye.innerHTML = svg(shown ? 'eye-off' : 'eye');
  });
  document.querySelector('.bench').insertAdjacentHTML('beforeend', `<div class="ds-component-grid"><section><h3>Campo de búsqueda · muestra</h3><label for="ds-search">Buscar registros</label><div class="input-wrap">${svg('search')}<input id="ds-search" readonly placeholder="Buscar por tipo o vehículo"></div><p class="ds-help">Solo catálogo; no añade búsqueda a Alertas.</p></section><section><h3>Error asociado al campo</h3><label for="ds-error">Correo electrónico</label><div class="input-wrap ds-field-error">${svg('mail')}<input id="ds-error" readonly aria-invalid="true" aria-describedby="ds-error-help" value=""></div><p id="ds-error-help" class="ds-auth-error">Ingresa tu correo.</p></section><section><h3>Banner de atención</h3><div class="ds-warning">${svg('warning')}<div><strong>Posible accidente</strong><p>Revisa el aviso recibido. Sin pulso continuo.</p></div></div></section><section><h3>Confirmación · muestra de catálogo</h3><div class="ds-dialog"><h4>Confirmar acción</h4><p>El texto explicará la operación y su alcance.</p><button class="sample-tonal" disabled>Volver</button> <button class="sample-primary" disabled>Confirmar</button></div><p class="ds-help">No introduce un diálogo en el acuse ni retrasa emergencias.</p></section></div><p><a href="TOKENS.md">Catálogo completo de tokens</a> · <a href="DESIGN_SYSTEM_V1_PROPOSAL.md#decisiones-para-aprobación">Decisiones para aprobación</a></p>`);
  document.querySelector('.bench-controls').insertAdjacentHTML('beforeend', '<button class="sample-critical" type="button">Acción urgente · ejemplo</button>');
  document.querySelector('.sample-critical').addEventListener('click', () => document.querySelector('#sample-status').textContent = 'Muestra visual de acción urgente; no llama ni envía comunicaciones.');
  window.BrandReview.refinement = true;
  render();
  if (!new URLSearchParams(location.search).has('screen')) {
    document.querySelector('#review-screen').value = '0';
    document.querySelector('#review-screen').dispatchEvent(new Event('change'));
  }
})();
