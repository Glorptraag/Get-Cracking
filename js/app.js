/* Get Cracking — app controller.
 *
 * Phases of one run:
 *   running → (paused ↔ running) → ready (time's up, waiting for a tap)
 *           → hatching → hatched
 *
 * Design rules carried through the code:
 *   - progress is physical and wordless (egg cracks + ground ring)
 *   - friction for the child, convenience for the adult (hold-to-act)
 *   - the payoff can't be missed (hatch waits for a tap by default)
 */
(function () {
  'use strict';
  const GC = window.GC;
  const $ = (id) => document.getElementById(id);
  const Sound = GC.Sound;
  const Store = GC.Store;
  const O = GC.OUT;

  let S = Store.load();
  const save = () => Store.save(S);
  document.documentElement.style.setProperty('--hold', `${S.holdSeconds}s`);

  const ANIMAL_IDS = GC.Animals.list.map((a) => a.id);
  const bag = new GC.ShuffleBag('gc.bag.v1', ANIMAL_IDS);
  const sceneBag = new GC.ShuffleBag('gc.scenebag.v1', GC.Scenes.list.map((s) => s.id));

  /* ============================================================ setup */
  let pendingScene = null;
  function chooseScene() {
    pendingScene = S.scene === 'random' ? sceneBag.next() : S.scene;
    const sc = GC.Scenes.list.find((s) => s.id === pendingScene);
    document.body.style.setProperty('--scene-bg', sc.bg);
    document.querySelector('meta[name=theme-color]').setAttribute('content', sc.bg);
    GC.Scenes.build(document.querySelector('.setup-bg'), pendingScene, { particles: true });
    document.querySelector('.setup-bg').setAttribute('preserveAspectRatio', 'xMidYMid slice');
  }

  let perchEgg = null;
  function buildPerch() {
    const svg = document.querySelector('.perch-egg');
    svg.innerHTML = `<g class="nest">` +
      `<ellipse cx="0" cy="-2" rx="86" ry="20" fill="#b98652" stroke="${O}" stroke-width="6"/>` +
      `<path d="M-74,-6 Q-30,8 10,-4 T76,-6 M-60,6 Q-10,-8 40,6 T80,0" stroke="#8a5a3b" stroke-width="4" fill="none" stroke-linecap="round"/></g>` +
      `<g class="perch-egg-layer"></g>` +
      `<path d="M-84,-2 Q-40,22 0,18 Q40,22 84,-2 Q60,20 0,22 Q-60,20 -84,-2 Z" fill="#b98652" stroke="${O}" stroke-width="5" stroke-linejoin="round"/>` +
      `<path d="M-70,6 L-50,0 M-30,12 L-8,6 M20,12 L44,6 M56,6 L74,0" stroke="#8a5a3b" stroke-width="4" stroke-linecap="round"/>`;
    perchEgg = new GC.Egg(svg.querySelector('.perch-egg-layer'), { x: 0, y: 4, scale: 0.92 });
    perchEgg.onBoop = () => Sound.boop();
  }

  function renderDials() {
    $('dial-min').firstElementChild.textContent = String(S.minutes).padStart(2, '0');
    $('dial-sec').firstElementChild.textContent = String(S.seconds).padStart(2, '0');
    const sl = $('min-slider');
    sl.value = S.minutes;
    sl.style.setProperty('--p', `${(S.minutes / 60) * 100}%`);
    $('min-label').textContent = S.minutes === 1 ? 'minute' : 'minutes';
    document.querySelectorAll('.presets button').forEach((b) => b.classList.toggle('on', +b.dataset.min === S.minutes && S.seconds === 0));
    $('quick-tap').checked = S.hatchMode === 'tap';
  }

  function bump(el) {
    el.animate([{ transform: 'scale(1)' }, { transform: 'scale(1.08)' }, { transform: 'scale(1)' }], { duration: 220 });
  }

  function wireSetup() {
    $('min-slider').addEventListener('input', (e) => { S.minutes = +e.target.value; if (!S.minutes && !S.seconds) S.seconds = 30; renderDials(); save(); });
    $('dial-min').addEventListener('click', () => { S.minutes = (S.minutes + 1) % 61; if (!S.minutes && !S.seconds) S.seconds = 30; renderDials(); bump($('dial-min')); save(); });
    $('dial-sec').addEventListener('click', () => { S.seconds = (S.seconds + 15) % 60; if (!S.minutes && !S.seconds) S.seconds = 15; renderDials(); bump($('dial-sec')); save(); });
    document.querySelectorAll('.presets button').forEach((b) => b.addEventListener('click', () => { S.minutes = +b.dataset.min; S.seconds = 0; renderDials(); save(); }));
    $('quick-tap').addEventListener('change', (e) => { S.hatchMode = e.target.checked ? 'tap' : 'auto'; save(); });
    $('start-btn').addEventListener('click', startRun);
    $('btn-world').addEventListener('click', () => openSheet('world'));
    $('btn-sound').addEventListener('click', () => openSheet('sound'));
    $('btn-book').addEventListener('click', () => openSheet('book'));
    $('btn-settings').addEventListener('click', () => openSheet('settings'));
    window.addEventListener('resize', fitSetup);
  }

  function fitSetup() {
    const inner = document.querySelector('.setup-inner');
    inner.style.setProperty('--fit', 1);
    inner.style.top = '0px';
    const h = inner.scrollHeight;
    const s = Math.min(1, window.innerHeight / h);
    inner.style.setProperty('--fit', s.toFixed(3));
    inner.style.top = `${Math.max(0, (window.innerHeight - h * s) / 2)}px`;
  }

  function showScreen(id) {
    document.querySelectorAll('.screen').forEach((s) => s.classList.toggle('active', s.id === id));
  }

  /* ============================================================ hold */
  /** press-and-hold gesture: a quick tap never triggers it */
  function holdable(el, onHold, onTap) {
    let t = null, start = 0, fired = false;
    const cancel = (e) => {
      if (!start) return;
      clearTimeout(t);
      el.classList.remove('holding');
      if (!fired && onTap && Date.now() - start < 350 && e && e.type === 'pointerup') onTap();
      start = 0;
    };
    el.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      fired = false; start = Date.now();
      el.classList.add('holding');
      try { el.setPointerCapture(e.pointerId); } catch (err) {}
      t = setTimeout(() => { fired = true; el.classList.remove('holding'); start = 0; onHold(); }, S.holdSeconds * 1000);
    });
    el.addEventListener('pointerup', cancel);
    el.addEventListener('pointercancel', cancel);
    el.addEventListener('lostpointercapture', cancel);
    el.addEventListener('contextmenu', (e) => e.preventDefault());
    el.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onHold(); } });
  }

  /* ============================================================ run */
  let run = null;
  let wakeLock = null;

  async function keepAwake(on) {
    try {
      if (on && 'wakeLock' in navigator && document.visibilityState === 'visible') wakeLock = await navigator.wakeLock.request('screen');
      else if (!on && wakeLock) { await wakeLock.release(); wakeLock = null; }
    } catch (e) { /* not supported or denied — fine */ }
  }

  function buildRing(layer, color) {
    const { cx, cy, rx, ry } = GC.Scenes.RING;
    const d = `M${cx},${cy + ry} A${rx},${ry} 0 0 1 ${cx},${cy - ry} A${rx},${ry} 0 0 1 ${cx},${cy + ry}`;
    layer.innerHTML =
      `<path class="ring-ref" d="${d}" fill="none" stroke="${O}" stroke-width="30"/>` +
      `<path d="${d}" fill="none" stroke="#fdf3e4" stroke-width="18"/>` +
      `<path class="ring-prog" d="${d}" pathLength="1" fill="none" stroke="${color}" stroke-width="18" stroke-linecap="round"/>` +
      `<g class="ring-pebbles"></g>` +
      `<g class="ring-hand"><circle r="13" fill="#fdf3e4" stroke="${O}" stroke-width="5"/>` +
      `<path d="M0,-4 C-2,-16 -14,-18 -16,-12 C-12,-6 -4,-4 0,-4 Z M0,-4 C2,-16 14,-18 16,-12 C12,-6 4,-4 0,-4 Z" fill="#a9d36b" stroke="${O}" stroke-width="3" stroke-linejoin="round"/></g>`;
    const ref = layer.querySelector('.ring-ref');
    const total = ref.getTotalLength();
    const pebbles = layer.querySelector('.ring-pebbles');
    const pts = GC.Egg.STEP_AT.map((f) => {
      const p = ref.getPointAtLength(f * total);
      return GC.el('circle', { cx: p.x, cy: p.y, r: 5.5, fill: '#cbbfae', stroke: O, 'stroke-width': 3, class: 'pebble' }, pebbles);
    });
    return {
      prog: layer.querySelector('.ring-prog'), hand: layer.querySelector('.ring-hand'), ref, total, pebbles: pts, color,
      set(elapsed) {
        const r = Math.max(0, 1 - elapsed);
        this.prog.style.strokeDasharray = `${r} 2`;
        this.prog.style.strokeDashoffset = `${-elapsed}`;
        this.prog.style.opacity = r <= 0.0005 ? 0 : 1;
        const p = this.ref.getPointAtLength(Math.min(elapsed, 0.9999) * this.total);
        this.hand.setAttribute('transform', `translate(${p.x.toFixed(1)} ${p.y.toFixed(1)})`);
      },
      light(step) { this.pebbles.forEach((c, i) => c.setAttribute('fill', i < step ? this.color : '#cbbfae')); },
    };
  }

  async function startRun() {
    Sound.ensure();
    Sound.setVolume(S.volume);
    const total = Math.max(10, S.minutes * 60 + S.seconds) * 1000;
    if (S.fullscreen && document.documentElement.requestFullscreen && !document.fullscreenElement) {
      document.documentElement.requestFullscreen({ navigationUI: 'hide' }).catch(() => {});
    }
    const sceneId = pendingScene || sceneBag.next();
    const stage = $('stage');
    const h = GC.Scenes.build(stage, sceneId);
    frameStage();
    document.body.style.setProperty('--scene-bg', h.scene.bg);
    const egg = new GC.Egg(h.eggLayer, { x: GC.Scenes.EGG.x, y: GC.Scenes.EGG.y });
    egg.onBoop = () => Sound.boop();
    const ring = buildRing(h.ringLayer, h.scene.ring);
    run = {
      phase: 'running', total, endAt: Date.now() + total, remaining: total,
      egg, ring, scene: h.scene, photos: [], knockT: null, raf: 0,
    };
    Store.listPhotos().then((p) => { if (run) run.photos = p; });
    ring.set(0);
    ring.light(0);

    // UI state
    $('hatch-pill').classList.remove('show');
    $('tap-hint').classList.remove('show');
    $('next-card').classList.remove('show');
    $('again-btn').classList.remove('show');
    $('time-pill').classList.toggle('hide', !S.showNumbers);
    $('kc-pause').classList.toggle('hidden', !S.showPause);
    $('kc-minus').classList.toggle('hidden', !S.showAdjust);
    $('kc-plus').classList.toggle('hidden', !S.showAdjust);
    $('kid-controls').style.display = '';
    $('kc-pause').textContent = '❚❚';
    closeTray();
    showScreen('timer');

    Sound.setTension(0);
    Sound.startMusic(S.music);
    keepAwake(true);
    if (!S.seenHint) {
      setTimeout(() => showLockTip(4000), 1200);
      S.seenHint = true; save();
    }
    loop();
  }

  /** crop the stage tighter on tall phones so the egg is as big as possible */
  function frameStage() {
    const stage = $('stage');
    const tall = window.innerHeight / window.innerWidth > 1.25;
    stage.setAttribute('viewBox', tall ? '45 110 510 580' : '0 0 600 720');
  }
  window.addEventListener('resize', () => { if (run) frameStage(); });

  function remaining() {
    if (!run) return 0;
    return run.phase === 'paused' ? run.remaining : Math.max(0, run.endAt - Date.now());
  }

  function loop() {
    cancelAnimationFrame(run && run.raf);
    const step = () => {
      if (!run) return;
      tick();
      run.raf = requestAnimationFrame(step);
    };
    if (run) run.raf = requestAnimationFrame(step);
  }
  // backup ticker for when animation frames are throttled (screen hidden)
  setInterval(() => { if (run) tick(); }, 1000);

  function tick() {
    if (!run || (run.phase !== 'running' && run.phase !== 'paused')) return;
    const rem = remaining();
    const elapsed = GC.clamp(1 - rem / run.total, 0, 1);
    run.ring.set(elapsed);
    const step = GC.Egg.stepFor(elapsed);
    if (step > run.egg.step) {
      run.egg.setStep(step);
      run.ring.light(step);
      Sound.crack();
    }
    if (elapsed >= 0.9) Sound.setTension(1);
    $('time-pill').textContent = GC.fmtTime(rem);
    if (rem <= 0 && run.phase === 'running') timeUp();
  }

  function timeUp() {
    run.phase = 'ready';
    run.ring.set(1);
    run.ring.light(8);
    run.egg.setStep(8);
    $('time-pill').classList.add('hide');
    Sound.stopMusic(1.5);
    $('kid-controls').style.display = 'none';
    if (S.hatchMode === 'auto') { hatch(); return; }
    // hatch waits for you: a gentle, wordless "come see!"
    run.egg.setReady(true);
    Sound.ready();
    $('hatch-pill').textContent = 'Tap the egg!';
    $('hatch-pill').classList.add('show');
    $('tap-hint').classList.add('show');
    let knocks = 0;
    run.knockT = setInterval(() => {
      if (!run || run.phase !== 'ready') return;
      if (knocks++ < 60) Sound.knock();
    }, 5000);
  }

  function pickFriend() {
    const photos = run.photos || [];
    const usePhoto = photos.length && (S.hatchWho === 'photos' || (S.hatchWho === 'both' && Math.random() < 0.4));
    if (usePhoto) {
      const p = GC.pick(photos);
      return { kind: 'photo', id: p.id, name: 'Peekaboo!', markup: GC.Animals.renderPhoto(p.url) };
    }
    const a = GC.Animals.byId[bag.next()];
    return { kind: 'animal', id: a.id, name: a.name, markup: GC.Animals.render(a) };
  }

  async function hatch() {
    if (!run || run.phase === 'hatching' || run.phase === 'hatched') return;
    run.phase = 'hatching';
    clearInterval(run.knockT);
    Sound.stopMusic(0.4);
    $('tap-hint').classList.remove('show');
    $('hatch-pill').classList.remove('show');
    $('kid-controls').style.display = 'none';
    closeTray();
    const r = run;
    r.ring.prog.closest('.ring-layer').animate([{ opacity: 1 }, { opacity: 0.25 }], { duration: 800, fill: 'forwards' });
    const friend = pickFriend();
    r.friend = friend;
    r.egg.onCheer = () => Sound.cheer();
    await r.egg.hatch(friend.markup, {
      style: S.hatchStyle,
      onPop: () => {
        Sound.pop();
        setTimeout(() => Sound.endTune(S.endSound), 120);
      },
    });
    if (run !== r) return;
    r.phase = 'hatched';
    $('hatch-pill').textContent = friend.kind === 'animal' ? `It's a ${friend.name}!` : friend.name;
    $('hatch-pill').classList.add('show');
    if (friend.kind === 'animal') {
      Store.addToBook(friend.id);
      if (S.sayName) setTimeout(() => Sound.say(`It's a ${friend.name}!`), 500);
    }
    if (S.nextUp.on && (S.nextUp.text || S.nextUp.photo)) {
      setTimeout(() => {
        if (run !== r) return;
        $('next-text').textContent = S.nextUp.text || '';
        $('next-icon').innerHTML = S.nextUp.photo ? `<img src="${S.nextUp.photo}" alt="">` : (S.nextUp.icon || '⭐');
        $('next-card').classList.add('show');
      }, 2200);
    }
    setTimeout(() => { if (run === r) $('again-btn').classList.add('show'); }, 3000);
    keepAwake(false);
  }

  function setPaused(on) {
    if (!run) return;
    if (on && run.phase === 'running') {
      run.remaining = Math.max(0, run.endAt - Date.now());
      run.phase = 'paused';
      run.egg.setPaused(true);
      Sound.pauseMusic();
      const fx = run.egg.fx;
      fx.innerHTML = `<text class="zz" x="52" y="-150" font-size="34">z</text><text class="zz" x="70" y="-176" font-size="26" style="animation-delay:-1.2s">z</text>`;
      run.ring.prog.closest('.ring-layer').style.opacity = 0.55;
    } else if (!on && run.phase === 'paused') {
      run.endAt = Date.now() + run.remaining;
      run.phase = 'running';
      run.egg.setPaused(false);
      run.egg.fx.querySelectorAll('.zz').forEach((z) => z.remove());
      run.ring.prog.closest('.ring-layer').style.opacity = 1;
      Sound.resumeMusic();
    }
    $('kc-pause').textContent = run.phase === 'paused' ? '▶' : '❚❚';
    syncTray();
  }

  function adjust(ms) {
    if (!run || (run.phase !== 'running' && run.phase !== 'paused')) return;
    const rem = remaining();
    const next = Math.max(5000, rem + ms);
    const delta = next - rem;
    run.total = Math.max(next, run.total + delta);
    if (run.phase === 'paused') run.remaining = next; else run.endAt = Date.now() + next;
    if (next > 30000) Sound.setTension(0);
    const pill = $('time-pill');
    pill.animate([{ transform: 'scale(1)' }, { transform: 'scale(1.25)' }, { transform: 'scale(1)' }], { duration: 300 });
    tick();
  }

  function endRun() {
    if (!run) return;
    cancelAnimationFrame(run.raf);
    clearInterval(run.knockT);
    run = null;
    Sound.stopMusic(0.3);
    keepAwake(false);
    if (document.fullscreenElement && document.exitFullscreen) document.exitFullscreen().catch(() => {});
  }

  function stopToSetup() {
    endRun();
    closeTray();
    chooseScene();
    buildPerch();
    showScreen('setup');
    fitSetup();
  }

  function restartSame() {
    endRun();
    pendingScene = S.scene === 'random' ? sceneBag.next() : S.scene;
    startRun();
  }

  /* ============================================================ tray */
  let trayT = null;
  function openTray() { syncTray(); $('tray').classList.add('show'); armTray(); }
  function closeTray() { $('tray').classList.remove('show'); clearTimeout(trayT); }
  function armTray() { clearTimeout(trayT); trayT = setTimeout(closeTray, 9000); }
  function syncTray() {
    const ph = run ? run.phase : 'none';
    const live = ph === 'running' || ph === 'paused';
    const q = (a) => document.querySelector(`.tray [data-act="${a}"]`);
    q('pause').hidden = !live;
    q('pause').innerHTML = ph === 'paused' ? '<span>▶</span>Resume' : '<span>❚❚</span>Pause';
    q('minus').hidden = !live;
    q('plus').hidden = !live;
    q('hatch').hidden = !(live || ph === 'ready');
  }
  function showLockTip(ms = 2000) {
    const tip = $('lock-tip');
    tip.classList.add('show');
    clearTimeout(showLockTip.t);
    showLockTip.t = setTimeout(() => tip.classList.remove('show'), ms);
  }

  function wireTimer() {
    holdable($('lock-btn'),
      () => openTray(),
      () => { if (S.longPressStop) showLockTip(); else openTray(); });
    holdable($('again-btn'), () => stopToSetup());

    $('tray').addEventListener('click', (e) => {
      const b = e.target.closest('[data-act]');
      if (!b) return;
      armTray();
      switch (b.dataset.act) {
        case 'pause': setPaused(run && run.phase !== 'paused'); break;
        case 'minus': adjust(-60000); break;
        case 'plus': adjust(60000); break;
        case 'hatch': if (run) { if (run.phase === 'paused') setPaused(false); run.endAt = Date.now(); run.phase = 'running'; tick(); if (run.phase === 'ready') hatch(); } break;
        case 'again': restartSame(); break;
        case 'stop': stopToSetup(); break;
        case 'close': closeTray(); break;
      }
    });

    $('kc-pause').addEventListener('click', () => setPaused(run && run.phase !== 'paused'));
    $('kc-minus').addEventListener('click', () => adjust(-60000));
    $('kc-plus').addEventListener('click', () => adjust(60000));

    // during "ready", a tap anywhere hatches — easiest possible target
    $('stage').addEventListener('pointerdown', () => { if (run && run.phase === 'ready') hatch(); });

    document.addEventListener('keydown', (e) => {
      if (!$('timer').classList.contains('active')) return;
      if (e.key === 'Escape') { $('tray').classList.contains('show') ? closeTray() : openTray(); }
    });
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible' && run && run.phase !== 'hatched') keepAwake(true);
      if (run) tick();
    });
  }

  /* ============================================================ sheets */
  function openSheet(kind) {
    const body = $('sheet-body');
    body.innerHTML = '';
    const titles = { world: 'Choose a world', sound: 'Music & sounds', book: 'Friend book', settings: 'Grown-up settings' };
    $('sheet-title').textContent = titles[kind];
    if (kind === 'world' || kind === 'settings') body.appendChild(secWorld());
    if (kind === 'sound' || kind === 'settings') body.appendChild(secSound());
    if (kind === 'settings') {
      body.appendChild(secStyle());
      body.appendChild(secHatch());
      body.appendChild(secScreen());
      body.appendChild(secNext());
      body.appendChild(secAbout());
    }
    if (kind === 'book') body.appendChild(secBook());
    $('sheet').classList.add('show');
    $('sheet-backdrop').classList.add('show');
    body.scrollTop = 0;
  }
  function closeSheet() {
    $('sheet').classList.remove('show');
    $('sheet-backdrop').classList.remove('show');
    Sound.stopMusic(0.3);
    renderDials();
  }

  function h(tag, attrs = {}, ...kids) {
    const e = document.createElement(tag);
    for (const k in attrs) {
      if (k === 'class') e.className = attrs[k];
      else if (k.startsWith('on')) e.addEventListener(k.slice(2), attrs[k]);
      else if (k === 'html') e.innerHTML = attrs[k];
      else e.setAttribute(k, attrs[k]);
    }
    for (const c of kids) if (c != null) e.append(c);
    return e;
  }
  function sec(title, hint, ...kids) {
    return h('div', { class: 'sec' }, h('h3', {}, title), hint ? h('p', { class: 'hint' }, hint) : null, ...kids);
  }
  function optGroup(options, get, set, extra) {
    const wrap = h('div', { class: 'opts' });
    const paint = () => wrap.querySelectorAll('.opt').forEach((b) => b.classList.toggle('on', b.dataset.v === String(get())));
    for (const o of options) {
      const b = h('button', { class: 'opt', 'data-v': o.v, onclick: () => { set(o.v); paint(); save(); if (extra) extra(o.v); } }, o.label);
      wrap.append(b);
    }
    paint();
    return wrap;
  }
  function toggleRow(label, sub, get, set) {
    const input = h('input', { type: 'checkbox' });
    input.checked = !!get();
    input.addEventListener('change', () => { set(input.checked); save(); });
    return h('div', { class: 'row' },
      h('label', {}, label, sub ? h('span', { class: 'sub' }, sub) : null),
      h('label', { class: 'toggle-row' }, input, h('span', { class: 'switch' })));
  }

  function secWorld() {
    const grid = h('div', { class: 'scene-grid' });
    const paint = () => grid.querySelectorAll('.scene-card').forEach((c) => c.classList.toggle('on', c.dataset.v === S.scene));
    const pickScene = (v) => { S.scene = v; save(); paint(); chooseScene(); fitSetup(); };
    grid.append(h('button', { class: 'scene-card', 'data-v': 'random', onclick: () => pickScene('random') }, h('div', { class: 'rand' }, '🎲'), h('span', {}, 'Surprise me')));
    for (const sc of GC.Scenes.list) {
      const svg = document.createElementNS(GC.SVGNS, 'svg');
      GC.Scenes.build(svg, sc.id, { particles: false });
      svg.setAttribute('viewBox', '40 90 520 540');
      svg.style.background = sc.bg;
      svg.querySelectorAll('*').forEach((n) => { if (n.style) n.style.animation = 'none'; });
      const egg = new GC.Egg(svg.querySelector('.egg-layer'), { x: 300, y: 392 });
      egg.wobbleEl.style.animation = 'none';
      grid.append(h('button', { class: 'scene-card', 'data-v': sc.id, onclick: () => pickScene(sc.id) }, svg, h('span', {}, sc.name)));
    }
    paint();
    return sec('World', 'Where the egg sits. Surprise me picks a different one each time.', grid);
  }

  function secSound() {
    const vol = h('input', { type: 'range', min: 0, max: 1, step: 0.05, value: S.volume });
    vol.style.setProperty('--p', `${S.volume * 100}%`);
    vol.addEventListener('input', () => { S.volume = +vol.value; vol.style.setProperty('--p', `${S.volume * 100}%`); Sound.setVolume(S.volume); save(); });
    vol.addEventListener('change', () => Sound.boop());
    return sec('Countdown music', 'A soft sound while the egg cracks, so little ones can hear time passing even when they look away. Tap to hear a sample.',
      optGroup(GC.MUSIC.map((m) => ({ v: m.id, label: `${m.icon} ${m.name}` })), () => S.music, (v) => (S.music = v),
        (v) => { Sound.setVolume(S.volume); if (v === 'off') Sound.stopMusic(); else Sound.preview('music', v); }),
      h('h3', { style: 'margin-top:18px' }, 'Hatching tune'),
      h('p', { class: 'hint' }, 'A happy tune instead of an alarm. Time is up = a win!'),
      optGroup(GC.END_SOUNDS.map((m) => ({ v: m.id, label: `${m.icon} ${m.name}` })), () => S.endSound, (v) => (S.endSound = v),
        (v) => { Sound.setVolume(S.volume); Sound.preview('end', v); }),
      h('div', { class: 'row', style: 'margin-top:12px' }, h('label', {}, 'Volume'), vol),
      toggleRow('Say the friend\'s name', '“It\'s a Fox!” (uses the device voice)', () => S.sayName, (v) => (S.sayName = v)));
  }

  function secStyle() {
    const svg = document.createElementNS(GC.SVGNS, 'svg');
    svg.setAttribute('viewBox', '-200 -260 400 330');
    svg.setAttribute('class', 'style-preview');
    let busy = false;
    const play = async (id) => {
      if (busy) return;
      busy = true;
      Sound.ensure(); Sound.setVolume(S.volume);
      svg.innerHTML = `<ellipse cx="0" cy="40" rx="190" ry="40" fill="#cfe3a8" stroke="${O}" stroke-width="5"/><g></g>`;
      const egg = new GC.Egg(svg.lastChild, { x: 0, y: 10, scale: 0.9 });
      egg.setStep(8, true);
      const pool = GC.Animals.list;
      try {
        await egg.hatch(GC.Animals.render(GC.pick(pool)), { style: id === 'random' ? undefined : id, onPop: () => Sound.pop() });
      } finally { busy = false; }
    };
    const opts = [{ v: 'random', label: '🎲 Surprise me' }, ...GC.ShellFX.list().map((f) => ({ v: f.id, label: `${f.icon} ${f.name}` }))];
    const group = optGroup(opts, () => S.hatchStyle, (v) => (S.hatchStyle = v), (v) => play(v));
    svg.addEventListener('click', () => play(S.hatchStyle));
    svg.innerHTML = `<ellipse cx="0" cy="40" rx="190" ry="40" fill="#cfe3a8" stroke="${O}" stroke-width="5"/><g></g>`;
    const e = new GC.Egg(svg.lastChild, { x: 0, y: 10, scale: 0.9 });
    e.setStep(8, true);
    return sec('Hatch style', 'What the shell does when the egg hatches. Tap a style to watch it, or tap the egg to replay.', group, svg);
  }

  function secHatch() {
    const photoGrid = h('div', { class: 'photo-grid' });
    const file = h('input', { type: 'file', accept: 'image/*', multiple: '', style: 'display:none' });
    const refresh = async () => {
      const photos = await Store.listPhotos();
      photoGrid.innerHTML = '';
      for (const p of photos) {
        photoGrid.append(h('div', { class: 'photo' }, h('img', { src: p.url, alt: '' }),
          h('button', { 'aria-label': 'Remove photo', onclick: async () => { await Store.removePhoto(p.id); refresh(); } }, '✕')));
      }
      photoGrid.append(h('button', { class: 'photo-add', 'aria-label': 'Add photos', onclick: () => file.click() }, '＋'));
    };
    file.addEventListener('change', async () => {
      for (const f of file.files) {
        try { await Store.addPhoto(await Store.fileToSquareDataUrl(f)); } catch (e) {}
      }
      file.value = '';
      if (S.hatchWho === 'animals') { S.hatchWho = 'both'; save(); whoGroup.replaceWith((whoGroup = mkWho())); }
      refresh();
    });
    const mkWho = () => optGroup([
      { v: 'animals', label: '🐾 Animals' }, { v: 'photos', label: '📷 My photos' }, { v: 'both', label: '🎁 Both' },
    ], () => S.hatchWho, (v) => (S.hatchWho = v));
    let whoGroup = mkWho();
    refresh();
    return sec('Who hatches?', '40 animal friends arrive in a shuffled order — every one shows up before any repeats. Add photos of family, pets or toys and they can hatch too. Photos stay on this device.',
      whoGroup, h('div', { style: 'height:12px' }), photoGrid, file,
      h('h3', { style: 'margin-top:18px' }, 'When time is up'),
      h('p', { class: 'hint' }, 'If a child wanders off, “Wait for a tap” keeps the egg wiggling until they come back, so they never miss the hatch.'),
      optGroup([{ v: 'tap', label: '👆 Wait for a tap' }, { v: 'auto', label: '🐣 Hatch by itself' }], () => S.hatchMode, (v) => (S.hatchMode = v)));
  }

  function secScreen() {
    const holdOpts = optGroup([1, 1.5, 2, 3].map((v) => ({ v, label: `${v}s` })), () => S.holdSeconds, (v) => {
      S.holdSeconds = v; document.documentElement.style.setProperty('--hold', `${v}s`);
    });
    return sec('Timer screen', 'Fewer buttons = fewer tempting things to tap. Grown-up controls live behind the 🔒 in the corner.',
      toggleRow('Long-press 🔒 for grown-up controls', 'A quick tap does nothing, so little fingers can\'t stop the timer', () => S.longPressStop, (v) => (S.longPressStop = v)),
      h('div', { class: 'row' }, h('label', {}, 'Hold for'), holdOpts),
      toggleRow('Show pause button', 'Always on screen (one tap)', () => S.showPause, (v) => (S.showPause = v)),
      toggleRow('Show −1 / +1 minute buttons', 'Always on screen (one tap)', () => S.showAdjust, (v) => (S.showAdjust = v)),
      toggleRow('Show numbers', 'Small clock in the corner for grown-ups', () => S.showNumbers, (v) => (S.showNumbers = v)),
      toggleRow('Go full screen', 'Hides browser bars while the timer runs', () => S.fullscreen, (v) => (S.fullscreen = v)));
  }

  function secNext() {
    const icons = ['🧸', '🛁', '🥣', '🧦', '🦷', '📚', '🛏️', '🚗', '🧩', '🎨', '🍎', '🧥', '🖍️', '🚽', '🏃', '⭐'];
    const text = h('input', { type: 'text', value: S.nextUp.text, maxlength: 40, placeholder: 'e.g. Bath time' });
    text.addEventListener('input', () => { S.nextUp.text = text.value; save(); });
    const row = h('div', { class: 'emoji-row' });
    const paint = () => row.querySelectorAll('button').forEach((b) => b.classList.toggle('on', !S.nextUp.photo && b.textContent === S.nextUp.icon));
    for (const ic of icons) row.append(h('button', { onclick: () => { S.nextUp.icon = ic; S.nextUp.photo = null; save(); paint(); photoBtn.textContent = '📷'; } }, ic));
    const file = h('input', { type: 'file', accept: 'image/*', style: 'display:none' });
    const photoBtn = h('button', { 'aria-label': 'Use a photo', onclick: () => file.click() }, S.nextUp.photo ? '🖼️' : '📷');
    row.append(photoBtn);
    file.addEventListener('change', async () => {
      if (!file.files[0]) return;
      try { S.nextUp.photo = await Store.fileToSquareDataUrl(file.files[0], 240); save(); photoBtn.textContent = '🖼️'; paint(); } catch (e) {}
    });
    paint();
    return sec('Next up card', 'After the hatch, show what happens next — a photo of the reading corner, the bath, shoes by the door. It turns the reward into a gentle transition cue.',
      toggleRow('Show a “Next up” card', null, () => S.nextUp.on, (v) => (S.nextUp.on = v)), text, row, file);
  }

  function secAbout() {
    return sec('About', 'Get Cracking works fully offline. No login, no account, no ads — settings, photos and the friend book stay on this device.',
      h('div', { class: 'opts' },
        h('button', { class: 'opt', onclick: () => { if (confirm('Clear the friend book?')) { localStorage.removeItem('gc.book.v1'); } } }, '🧹 Reset friend book'),
        h('button', { class: 'opt', onclick: () => { if (confirm('Reset all settings?')) { S = JSON.parse(JSON.stringify(Store.DEFAULTS)); save(); closeSheet(); chooseScene(); } } }, '↺ Reset settings')));
  }

  function secBook() {
    const book = Store.book();
    const found = GC.Animals.list.filter((a) => book[a.id]).length;
    const grid = h('div', { class: 'book-grid' });
    for (const a of GC.Animals.list) {
      const seen = !!book[a.id];
      const card = h('div', { class: `book-card ${seen ? '' : 'unseen'}` });
      card.innerHTML = `<svg viewBox="-112 -218 224 232">${GC.Animals.render(a)}</svg><span>${seen ? a.name : '?'}</span>${book[a.id] > 1 ? `<b>×${book[a.id]}</b>` : ''}`;
      grid.append(card);
    }
    return sec(`${found} of ${GC.Animals.list.length} friends found`, 'Every hatch adds a friend to the book.', grid);
  }

  /* ============================================================ boot */
  function boot() {
    chooseScene();
    buildPerch();
    renderDials();
    wireSetup();
    wireTimer();
    $('sheet-close').addEventListener('click', closeSheet);
    $('sheet-backdrop').addEventListener('click', closeSheet);
    requestAnimationFrame(fitSetup);
    if (document.fonts) document.fonts.ready.then(fitSetup);
    if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
      navigator.serviceWorker.register('sw.js').catch(() => {});
    }
    // debug/test hook
    GC.app = { get run() { return run; }, startRun, hatch, setPaused, adjust, stopToSetup, openSheet, closeSheet, settings: () => S };
  }
  boot();
})();
