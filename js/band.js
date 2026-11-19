/* Get Cracking — the animal bands.
 *
 * Three celebration songs that play when the egg hatches, each a full little
 * band plus a farmyard (or jungle) of animal voices, every sound synthesised
 * live with Web Audio. No samples, no files, works offline. The melodies are
 * original.
 *
 *   Animal band       marching parade: drums, tuba, trumpets, piano, strings,
 *                     glockenspiel, flute, kazoo, timpani, slide whistle
 *   Jungle jam        calypso: steel drum, marimba, ukulele, bongos, shaker,
 *                     claves, bass, pan flute
 *   Farmyard hoedown  two-step: fiddle, banjo, harmonica, jug, washboard,
 *                     cowbell, hand claps, slide whistle
 *
 * Every song has the same shape, so a child learns it:
 *   intro → 4 bars of call-and-response (band plays a line, an animal answers)
 *   → 2 bars where the animals sing the tune → everyone cheers → the friend
 *   who just hatched gets a solo → big "ta-da" chord.
 *
 * Notes are scheduled a little ahead of time by a lookahead pump (like the
 * countdown music), so a 15-second song never creates thousands of audio
 * nodes in one frame during the hatch animation, and it can stop instantly.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const P = GC.Sound.constructor.prototype;
  const midi = (n) => 440 * Math.pow(2, (n - 69) / 12);

  /* ------------------------------------------------------------------ voice
   * One synthesised voice: oscillators → (filter) → (formant bank) →
   * (tremolo) → envelope → out. Used for brass, strings, fiddle, kazoo and
   * every animal.
   *   f        Hz, or a glide [[dt, Hz], …] (exponential between points)
   *   partials [[ratio, amp]] stacked oscillators (default [[1, 1]])
   *   detune   cents per extra copy, for a chorus/section sound
   *   vib      [rateHz, cents, delayS]     trem [rateHz, depth 0..1]
   *   filter   { type, f (Hz or glide), q }
   *   formants [[f (Hz or glide), q, amp]] parallel band-passes (vowels)
   *   noise    amount of breath/growl mixed in before the filters (noiseF Hz)
   *   pluck    true = percussive exponential decay instead of a held note
   */
  function glide(param, t, p, k = 1) {
    if (typeof p === 'number') { param.setValueAtTime(p * k, t); return; }
    param.setValueAtTime(p[0][1] * k, t + p[0][0]);
    for (let i = 1; i < p.length; i++) param.exponentialRampToValueAtTime(p[i][1] * k, t + p[i][0]);
  }

  P._voice = function (t, v, out) {
    const ctx = this.ctx;
    const dur = v.dur, end = t + dur + 0.06;
    const peak = v.gain ?? 0.2;
    const env = ctx.createGain();
    if (v.pluck) {
      env.gain.setValueAtTime(0.0001, t);
      env.gain.exponentialRampToValueAtTime(peak, t + (v.attack ?? 0.004));
      env.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    } else {
      const a = Math.min(v.attack ?? 0.02, dur * 0.4), r = Math.min(v.release ?? 0.08, dur * 0.5);
      env.gain.setValueAtTime(0, t);
      env.gain.linearRampToValueAtTime(peak, t + a);
      env.gain.linearRampToValueAtTime(peak * (v.sus ?? 1), t + dur - r);
      env.gain.linearRampToValueAtTime(0, t + dur);
    }
    env.connect(out);
    const srcs = [];
    const mix = ctx.createGain();
    let vibG = null;
    if (v.vib) {
      const [rate, cents, delay = 0] = v.vib;
      const lfo = ctx.createOscillator(); lfo.frequency.value = rate;
      vibG = ctx.createGain();
      vibG.gain.setValueAtTime(0, t);
      vibG.gain.linearRampToValueAtTime(0, t + delay);
      vibG.gain.linearRampToValueAtTime(cents, t + delay + 0.12);
      lfo.connect(vibG); srcs.push(lfo);
    }
    const parts = v.partials || [[1, 1]];
    const copies = v.detune || [0];
    const share = 1 / Math.sqrt(copies.length);
    for (const [ratio, amp] of parts) {
      for (const cents of copies) {
        const o = ctx.createOscillator();
        o.type = v.type || 'sawtooth';
        glide(o.frequency, t, v.f, ratio);
        o.detune.value = cents;
        if (vibG) vibG.connect(o.detune);
        const pg = ctx.createGain(); pg.gain.value = amp * share;
        o.connect(pg); pg.connect(mix); srcs.push(o);
      }
    }
    if (v.noise) {
      const n = ctx.createBufferSource(); n.buffer = this._noise;
      const nf = ctx.createBiquadFilter(); nf.type = 'bandpass'; nf.frequency.value = v.noiseF || 1500; nf.Q.value = 0.8;
      const ng = ctx.createGain(); ng.gain.value = v.noise;
      n.connect(nf); nf.connect(ng); ng.connect(mix);
      srcs.push(n);
    }
    let head = mix;
    if (v.filter) {
      const f = ctx.createBiquadFilter(); f.type = v.filter.type || 'lowpass'; f.Q.value = v.filter.q ?? 1;
      glide(f.frequency, t, v.filter.f);
      head.connect(f); head = f;
    }
    if (v.formants) {
      const sum = ctx.createGain();
      for (const [fp, q, amp] of v.formants) {
        const bp = ctx.createBiquadFilter(); bp.type = 'bandpass'; bp.Q.value = q;
        glide(bp.frequency, t, fp);
        const g = ctx.createGain(); g.gain.value = amp * Math.sqrt(q); // narrow bands lose level; give it back
        head.connect(bp); bp.connect(g); g.connect(sum);
      }
      head = sum;
    }
    if (v.trem) {
      const [rate, depth] = v.trem;
      const tg = ctx.createGain(); tg.gain.value = 1 - depth / 2;
      const lfo = ctx.createOscillator(); lfo.frequency.value = rate;
      const lg = ctx.createGain(); lg.gain.value = depth / 2;
      lfo.connect(lg); lg.connect(tg.gain); srcs.push(lfo);
      head.connect(tg); head = tg;
    }
    head.connect(env);
    for (const s of srcs) {
      if (s.buffer) s.start(t, Math.random()); else s.start(t);
      s.stop(end);
    }
  };

  /* ------------------------------------------------------------------ kit
   * Every instrument and animal syllable, bound to the song's mixer channels.
   */
  function makeKit(s, ch) {
    const V = (t, v, out) => s._voice(t, v, out);
    const tone = (f, t, d, o) => s.tone(f, t, d, o);
    const noise = (t, d, o) => s.noiseBurst(t, d, o);
    const D = ch.drums;
    const k = {
      s,
      /* ---- drums & percussion */
      kick(t, g = 0.5) {
        tone(150, t, 0.3, { gain: g, bus: D, slide: 0.32 });
        tone(80, t, 0.22, { gain: g * 0.5, bus: D, type: 'triangle', slide: 0.7 });
        noise(t, 0.02, { freq: 3500, q: 0.8, gain: g * 0.18, bus: D });
      },
      snare(t, g = 0.22) { // a crisp marching snare: wires + a tight drum head
        noise(t, 0.13, { freq: 3800, q: 0.7, gain: g * 0.8, bus: D });
        noise(t, 0.17, { filter: 'highpass', freq: 1400, q: 0.5, gain: g * 0.6, bus: D });
        tone(225, t, 0.07, { gain: g * 0.6, type: 'triangle', slide: 0.8, bus: D });
      },
      flam(t, g = 0.22) { k.snare(t - 0.028, g * 0.35); k.snare(t, g); },
      bassDrum(t, g = 0.5) { // big felt-beater marching bass drum
        tone(72, t, 0.55, { gain: g, slide: 0.72, bus: D });
        tone(118, t, 0.2, { gain: g * 0.45, type: 'triangle', slide: 0.7, bus: D });
        noise(t, 0.07, { filter: 'lowpass', freq: 600, q: 0.7, gain: g * 0.35, bus: D });
      },
      clash(t, g = 0.08) { // hand cymbals
        noise(t, 0.75, { filter: 'highpass', freq: 3200, q: 0.5, gain: g, bus: D });
        noise(t, 0.4, { freq: 6200, q: 1.2, gain: g * 0.7, bus: D });
      },
      peaWhistle(t, d, g = 0.1) { // the drum major's whistle: the pea makes it trill
        V(t, { type: 'sine', f: [[0, 2650], [0.04, 2900], [d, 2850]], dur: d, attack: 0.01, release: 0.03, gain: g, trem: [46, 0.75], vib: [46, 45, 0], noise: 0.08, noiseF: 2900 }, ch.sparkle);
      },
      roll(t0, t1, g0, g1) {
        const n = Math.max(2, Math.round((t1 - t0) / 0.05));
        for (let i = 0; i < n; i++) noise(t0 + (i * (t1 - t0)) / n, 0.06, { filter: 'highpass', freq: 1700, q: 0.5, gain: g0 + ((g1 - g0) * i) / n, bus: D });
      },
      hat(t, g = 0.06, open = false) { noise(t, open ? 0.24 : 0.035, { filter: 'highpass', freq: 7600, q: 0.7, gain: g, bus: D }); },
      crash(t, g = 0.13) {
        noise(t, 2.0, { filter: 'highpass', freq: 4800, q: 0.4, gain: g, bus: D });
        noise(t, 1.3, { freq: 9500, q: 1.5, gain: g * 0.6, bus: D });
      },
      clap(t, g = 0.16) {
        for (let i = 0; i < 3; i++) noise(t + i * 0.011, 0.025, { freq: 1300, q: 1.1, gain: g, bus: D });
        noise(t + 0.033, 0.14, { freq: 1150, q: 0.9, gain: g * 0.6, bus: D });
      },
      tamb(t, g = 0.06) {
        noise(t, 0.13, { freq: 8200, q: 2.2, gain: g, bus: D });
        tone(5300, t, 0.1, { gain: g * 0.18, bus: D }); tone(7150, t + 0.004, 0.08, { gain: g * 0.14, bus: D });
      },
      shaker(t, g = 0.045) { noise(t, 0.075, { filter: 'highpass', freq: 5500, q: 0.7, gain: g, attack: 0.02, bus: D }); },
      claves(t, g = 0.1) { tone(2450, t, 0.06, { gain: g, partials: [[1, 1], [2.2, 0.15]], bus: D }); },
      woodblock(t, hi = true, g = 0.1) { tone(hi ? 1250 : 880, t, 0.07, { gain: g, partials: [[1, 1], [2.4, 0.3]], bus: D }); },
      bongo(t, hi = true, g = 0.16) {
        tone(hi ? 410 : 290, t, hi ? 0.13 : 0.18, { gain: g, slide: 0.9, partials: [[1, 1], [1.52, 0.25]], bus: D });
        noise(t, 0.018, { freq: hi ? 3200 : 2100, q: 1, gain: g * 0.35, bus: D });
      },
      cowbell(t, g = 0.07) { V(t, { type: 'square', f: 562, partials: [[1, 1], [1.505, 0.8]], dur: 0.32, pluck: true, gain: g, filter: { type: 'bandpass', f: 820, q: 2.2 } }, D); },
      washboard(t, g = 0.07) {
        noise(t, 0.07, { freq: 3600, q: 2.5, gain: g, attack: 0.018, bus: D });
        for (let i = 0; i < 3; i++) tone(4100 + i * 300, t + i * 0.012, 0.02, { gain: g * 0.12, bus: D });
      },
      timp(t, n, g = 0.25) { tone(midi(n), t, 1.4, { gain: g, slide: 0.985, partials: [[1, 1], [1.5, 0.35], [2, 0.25], [2.74, 0.08]], bus: ch.bass }); },
      timpRoll(t0, t1, n, g0, g1) {
        const c = Math.max(2, Math.round((t1 - t0) / 0.065));
        for (let i = 0; i < c; i++) tone(midi(n), t0 + (i * (t1 - t0)) / c, 0.3, { gain: g0 + ((g1 - g0) * i) / c, partials: [[1, 1], [1.5, 0.3], [2, 0.2]], bus: ch.bass });
      },

      /* ---- bass */
      tuba(n, t, d, g = 0.2) {
        V(t, { f: [[0, midi(n) * 0.97], [0.04, midi(n)]], dur: d, attack: 0.035, release: 0.09, sus: 0.7, gain: g, filter: { type: 'lowpass', f: [[0, 260], [0.05, 950], [d, 480]], q: 1.1 } }, ch.bass);
      },
      bass(n, t, d, g = 0.24) { tone(midi(n), t, d, { gain: g, partials: [[1, 1], [2, 0.55], [3, 0.22], [4, 0.08]], bus: ch.bass }); },
      jug(n, t, d, g = 0.22) {
        V(t, { f: [[0, midi(n) * 0.93], [0.07, midi(n)]], dur: d, attack: 0.03, release: 0.08, sus: 0.55, gain: g, formants: [[[[0, 260], [0.08, 420], [d, 300]], 2.5, 1], [800, 4, 0.35]] }, ch.bass);
      },

      /* ---- chords & keys */
      piano(n, t, d = 0.9, g = 0.07, out = ch.comp) {
        tone(midi(n), t, d, { gain: g, partials: [[1, 1], [2, 0.45], [3, 0.18], [4, 0.1], [5.02, 0.04]], bus: out });
      },
      chord(notes, t, d, g, fn) { notes.forEach((n) => fn(n, t, d, g)); },
      strings(notes, t, d, g = 0.022) {
        for (const n of notes) V(t, { f: midi(n), detune: [-9, 0, 8], dur: d, attack: Math.min(0.35, d * 0.3), release: 0.35, sus: 0.9, gain: g, vib: [5, 7, 0.2], filter: { type: 'lowpass', f: 2300, q: 0.7 } }, ch.comp);
      },
      uke(notes, t, g = 0.06) {
        notes.forEach((n, i) => tone(midi(n), t + i * 0.016, 0.38, { gain: g, type: 'triangle', partials: [[1, 1], [2, 0.4], [3, 0.12]], bus: ch.comp }));
      },
      banjo(n, t, g = 0.08, out = ch.comp) {
        V(t, { f: midi(n), dur: 0.42, pluck: true, gain: g, filter: { type: 'lowpass', f: [[0, 5200], [0.12, 1400], [0.42, 900]], q: 2.5 } }, out);
      },
      strum(notes, t, g, fn) { notes.forEach((n, i) => fn(n, t + i * 0.014, g)); },
      harmonica(notes, t, d, g = 0.035) {
        for (const n of notes) V(t, { type: 'square', f: midi(n), dur: d, attack: 0.03, release: 0.06, sus: 0.85, gain: g, trem: [6.5, 0.25], filter: { type: 'lowpass', f: 2400, q: 1.2 } }, ch.comp);
      },

      /* ---- melody */
      brass(n, t, d, g = 0.075, out = ch.lead) { // trumpets: a little scoop up into each note
        V(t, { f: [[0, midi(n) * 0.975], [0.035, midi(n)]], detune: [-7, 0, 6], dur: d, attack: 0.035, release: 0.09, sus: 0.8, gain: g, vib: [5.5, 10, 0.18], filter: { type: 'lowpass', f: [[0, 450], [0.045, 3400], [0.25, 2100]], q: 1.3 } }, out);
      },
      horns(notes, t, d, g = 0.022) { // French horns: round, mellow sustained chords
        for (const n of notes) V(t, { f: midi(n), detune: [-5, 5], dur: d, attack: Math.min(0.09, d * 0.3), release: 0.12, sus: 0.85, gain: g, vib: [4.8, 6, 0.25], filter: { type: 'lowpass', f: 1050, q: 0.6 } }, ch.comp);
      },
      bones(notes, t, d, g = 0.04) { // trombones: the "pah" in oom-pah
        for (const n of notes) V(t, { f: [[0, midi(n) * 0.98], [0.03, midi(n)]], detune: [-6, 6], dur: d, attack: 0.02, release: 0.06, sus: 0.6, gain: g, filter: { type: 'lowpass', f: [[0, 400], [0.04, 2200], [d, 900]], q: 1.2 } }, ch.comp);
      },
      glock(n, t, d = 1.1, g = 0.045) { tone(midi(n), t, d, { gain: g, partials: [[1, 1], [2.76, 0.2], [5.4, 0.06]], bus: ch.sparkle }); },
      xylo(n, t, g = 0.08) { tone(midi(n), t, 0.35, { gain: g, partials: [[1, 1], [3.93, 0.25], [9.4, 0.05]], bus: ch.sparkle }); },
      flute(n, t, d, g = 0.07, out = ch.lead) {
        V(t, { type: 'sine', f: midi(n), partials: [[1, 1], [2, 0.14], [3, 0.04]], dur: d, attack: 0.06, release: 0.08, sus: 0.9, gain: g, vib: [5, 14, 0.15], noise: 0.05, noiseF: midi(n) * 2 }, out);
      },
      panflute(n, t, d, g = 0.07) {
        V(t, { type: 'sine', f: [[0, midi(n) * 0.985], [0.05, midi(n)]], partials: [[1, 1], [2, 0.08]], dur: d, attack: 0.05, release: 0.1, sus: 0.8, gain: g, vib: [4.5, 12, 0.2], noise: 0.14, noiseF: midi(n) * 1.5 }, ch.lead);
      },
      steel(n, t, d = 0.9, g = 0.1) {
        tone(midi(n), t, d, { gain: g, partials: [[1, 1], [2, 0.55], [3.01, 0.18], [4.02, 0.26], [5.05, 0.05]], bus: ch.lead });
      },
      marimba(n, t, g = 0.09, out = ch.comp) { tone(midi(n), t, 0.6, { gain: g, partials: [[1, 1], [4, 0.15], [9.8, 0.03]], bus: out }); },
      fiddle(n, t, d, g = 0.065) {
        V(t, { f: [[0, midi(n) * 0.985], [0.05, midi(n)]], dur: d, attack: 0.04, release: 0.08, sus: 0.85, gain: g, vib: [6, 18, 0.1], formants: [[700, 3, 1], [1700, 4, 0.7], [3000, 5, 0.4]] }, ch.lead);
      },
      kazoo(n, t, d, g = 0.05, out = ch.lead) {
        V(t, { f: [[0, midi(n) * 0.97], [0.04, midi(n)]], dur: d, attack: 0.02, release: 0.06, sus: 0.9, gain: g, vib: [6, 25, 0.08], noise: 0.12, noiseF: 2500, formants: [[600, 4, 1], [1500, 8, 0.9], [2800, 8, 0.5]] }, out);
      },
      slideWhistle(t, n0, n1, d, g = 0.08) {
        V(t, { type: 'sine', f: [[0, midi(n0)], [d, midi(n1)]], partials: [[1, 1], [2, 0.06]], dur: d, attack: 0.04, release: 0.06, gain: g, vib: [6.5, 30, 0], noise: 0.05, noiseF: 3000 }, ch.sparkle);
      },
      harp(notes, t, gap, g = 0.05) {
        notes.forEach((n, i) => tone(midi(n), t + i * gap, 1.3, { gain: g, type: 'triangle', partials: [[1, 1], [2, 0.25]], bus: ch.sparkle }));
      },
    };

    /* ---- animal syllables: (t, f Hz, d s, out). Paths are written as
     * fractions of d (time) and f (pitch), so the same moo can be a calf or
     * a cow, short or long, and the animals can sing the tune. */
    const rel = (p, f, d) => p.map(([x, y]) => [x * d, y * f]);
    const A = (k.say = {
      moo: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.9], [0.14, 1.06], [0.6, 1.0], [1, 0.78]], f, d), dur: d, attack: d * 0.12, release: d * 0.28, gain: 0.25 * g, vib: [4, 12, d * 0.2], noise: 0.03, noiseF: 400, filter: { type: 'lowpass', f: rel([[0, 2], [0.26, 8.8], [0.75, 5.6], [1, 2.4]], f, d), q: 2.5 } }, o),
      quack: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 1.1], [0.6, 1], [1, 0.82]], f, d), dur: d, attack: 0.008, release: d * 0.3, gain: 0.46 * g, noise: 0.08, noiseF: 1500, formants: [[[[0, 900], [d * 0.5, 1300]], 5, 1], [2600, 7, 0.6]] }, o),
      baa: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.9], [0.1, 1.01], [1, 0.9]], f, d), dur: d, attack: 0.03, release: d * 0.2, gain: 0.39 * g, vib: [7.5, 55, 0], trem: [7.5, 0.55], filter: { type: 'lowpass', f: [[0, 500], [0.06, 4000]], q: 0.7 }, formants: [[800, 5, 1], [1200, 6, 0.7], [2500, 8, 0.3]] }, o),
      woof: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.82], [0.2, 1.14], [1, 0.72]], f, d), dur: d, attack: 0.006, release: d * 0.3, gain: 0.4 * g, noise: 0.25, noiseF: 900, formants: [[550, 3, 1], [1100, 4, 0.6], [2300, 6, 0.2]] }, o),
      meow: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.84], [0.22, 1.13], [0.6, 1.06], [1, 0.77]], f, d), dur: d, attack: 0.04, release: d * 0.2, gain: 0.19 * g, vib: [5.5, 18, d * 0.15], formants: [[rel([[0, 0.7], [0.3, 1.45], [0.85, 0.9]], 620, d), 5, 1], [rel([[0, 3.7], [0.3, 2.4], [0.85, 1.4]], 620, d), 7, 0.7], [3000, 8, 0.15]] }, o),
      oink: (t, f, d, o, g = 1) => V(t, { type: 'square', f: rel([[0, 0.9], [0.28, 1.13], [1, 0.8]], f, d), dur: d, attack: 0.01, release: d * 0.3, gain: 0.45 * g, trem: [38, 0.7], noise: 0.35, noiseF: 700, formants: [[650, 3, 1], [1500, 5, 0.4]] }, o),
      hoot: (t, f, d, o, g = 1) => V(t, { type: 'sine', f: rel([[0, 0.97], [0.22, 1.04], [1, 0.92]], f, d), partials: [[1, 1], [2, 0.12]], dur: d, attack: Math.min(0.07, d * 0.2), release: d * 0.4, gain: 0.21 * g, noise: 0.03, noiseF: 400 }, o),
      cheep: (t, f, d, o, g = 1) => V(t, { type: 'sine', f: rel([[0, 1.15], [1, 0.92]], f, d), dur: d, attack: 0.006, release: d * 0.3, gain: 0.17 * g }, o),
      trumpet: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.72], [0.13, 1.14], [0.6, 1.06], [1, 0.9]], f, d), detune: [-15, 15], dur: d, attack: 0.05, release: d * 0.22, gain: 0.23 * g, vib: [9, 45, 0.08], noise: 0.2, noiseF: 1800, formants: [[800, 3, 1], [1600, 4, 0.9], [3200, 5, 0.5]] }, o),
      roar: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.82], [0.23, 1.18], [1, 0.7]], f, d), detune: [-20, 20], dur: d, attack: d * 0.1, release: d * 0.3, gain: 0.5 * g, trem: [32, 0.45], noise: 0.4, noiseF: 600, filter: { type: 'lowpass', f: rel([[0, 3], [0.23, 14], [1, 4]], f, d), q: 1 }, formants: [[700, 2, 1], [1300, 3, 0.6]] }, o),
      neigh: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.72], [0.12, 1.57], [0.5, 1.14], [1, 0.6]], f, d), dur: d, attack: 0.04, release: d * 0.25, gain: 0.17 * g, vib: [11, 140, 0.1], noise: 0.12, noiseF: 2000, formants: [[900, 4, 1], [1800, 5, 0.6], [2800, 6, 0.3]] }, o),
      squeak: (t, f, d, o, g = 1) => V(t, { type: 'sine', f: rel([[0, 0.87], [0.45, 1.16], [1, 1]], f, d), dur: d, attack: 0.008, release: d * 0.3, gain: 0.125 * g, vib: [30, 40, 0] }, o),
      ork: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 1.1], [1, 0.83]], f, d), dur: d, attack: 0.012, release: d * 0.3, gain: 0.42 * g, trem: [25, 0.3], noise: 0.25, noiseF: 800, formants: [[600, 3, 1], [1100, 4, 0.6]] }, o),
      croak: (t, f, d, o, g = 1) => V(t, { type: 'square', f: rel([[0, 0.95], [1, 1.12]], f, d), dur: d, attack: 0.01, release: 0.03, gain: 0.55 * g, trem: [30, 1], formants: [[450, 3, 1], [1300, 5, 0.5]] }, o),
      ooh: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.85], [1, 1.15]], f, d), dur: d, attack: 0.02, release: d * 0.3, gain: 0.28 * g, formants: [[400, 4, 1], [850, 6, 0.3]] }, o),
      ah: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.88], [1, 1.12]], f, d), dur: d, attack: 0.02, release: d * 0.3, gain: 0.28 * g, formants: [[900, 4, 1], [1400, 5, 0.6]] }, o),
      crow: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.9], [0.2, 1.05], [0.75, 1], [1, 0.75]], f, d), dur: d, attack: 0.02, release: d * 0.25, gain: 0.16 * g, vib: [7, 40, d * 0.25], noise: 0.1, noiseF: 2500, formants: [[900, 5, 1], [1900, 6, 0.6], [3200, 8, 0.3]] }, o),
      buzz: (t, f, d, o, g = 1) => V(t, { f: rel([[0, 0.92], [0.4, 1.08], [0.75, 0.96], [1, 1.04]], f, d), dur: d, attack: 0.08, release: 0.1, gain: 0.18 * g, vib: [14, 60, 0], filter: { type: 'lowpass', f: 1800, q: 1 } }, o),
      bloop: (t, f, d, o, g = 1) => V(t, { type: 'sine', f: rel([[0, 0.35], [1, 1]], f, d), dur: d, attack: 0.005, release: d * 0.3, gain: 0.23 * g }, o),
      sniff: (t, f, d, o, g = 1) => s.noiseBurst(t, d, { freq: f, q: 2, gain: 0.5 * g, attack: d * 0.4, bus: o }),
    });
    k.A = A;
    return k;
  }

  /* ------------------------------------------------------------- calls
   * What each animal "says" when it answers or takes its solo.
   * len = how long it lasts (s), so the song can leave room for it.
   */
  const rep = (fn, f, d, gaps) => (k, t, o) => gaps.forEach((g, i) => fn(k, t + g, f * (1 + i * 0.04), d, o));
  const CALLS = {
    moo: { len: 1.15, play: (k, t, o) => k.say.moo(t, 125, 1.15, o) },
    calf: { len: 0.8, play: (k, t, o) => k.say.moo(t, 175, 0.8, o) },
    quack: { len: 0.42, play: (k, t, o) => { k.say.quack(t, 300, 0.17, o); k.say.quack(t + 0.24, 290, 0.18, o); } },
    peep: { len: 0.4, play: (k, t, o) => { k.say.quack(t, 420, 0.13, o); k.say.quack(t + 0.2, 440, 0.14, o); } },
    baa: { len: 0.8, play: (k, t, o) => k.say.baa(t, 330, 0.8, o) },
    goat: { len: 0.6, play: (k, t, o) => V2(k, 'goat', t, o) },
    woof: { len: 0.4, play: (k, t, o) => { k.say.woof(t, 280, 0.15, o); k.say.woof(t + 0.23, 270, 0.16, o); } },
    yip: { len: 0.36, play: (k, t, o) => { k.say.woof(t, 560, 0.1, o, 0.7); k.say.woof(t + 0.15, 600, 0.1, o, 0.7); k.say.woof(t + 0.28, 640, 0.09, o, 0.7); } },
    meow: { len: 0.72, play: (k, t, o) => k.say.meow(t, 620, 0.72, o) },
    mew: { len: 0.45, play: (k, t, o) => k.say.meow(t, 760, 0.45, o) },
    oink: { len: 0.45, play: (k, t, o) => { k.say.oink(t, 190, 0.18, o); k.say.oink(t + 0.25, 205, 0.18, o); } },
    grunt: { len: 0.5, play: (k, t, o) => { k.say.oink(t, 120, 0.22, o); k.say.ork(t + 0.26, 170, 0.22, o); } },
    hoot: { len: 0.95, play: (k, t, o) => { k.say.hoot(t, 380, 0.38, o); k.say.hoot(t + 0.5, 345, 0.45, o); } },
    cheep: { len: 0.4, play: (k, t, o) => [0, 0.13, 0.26].forEach((g, i) => k.say.cheep(t + g, 3100 - i * 120, 0.08, o)) },
    tweet: {
      len: 0.75,
      play: (k, t, o) => {
        for (let i = 0; i < 5; i++) k.say.cheep(t + i * 0.07, 3600 + (i % 2) * 400, 0.05, o);
        k.say.squeak(t + 0.42, 2600, 0.3, o);
      },
    },
    trumpet: { len: 0.9, play: (k, t, o) => k.say.trumpet(t, 520, 0.9, o) },
    roar: { len: 0.65, play: (k, t, o) => k.say.roar(t, 170, 0.65, o) },
    rawr: { len: 0.6, play: (k, t, o) => k.say.roar(t, 140, 0.6, o) },
    dino: { len: 0.95, play: (k, t, o) => k.say.roar(t, 115, 0.95, o) },
    dragon: {
      len: 1.2,
      play: (k, t, o) => { k.say.roar(t, 125, 0.8, o); [84, 88, 91, 96].forEach((n, i) => k.glock(n, t + 0.75 + i * 0.07, 0.6, 0.05)); },
    },
    neigh: { len: 1.0, play: (k, t, o) => k.say.neigh(t, 700, 1.0, o) },
    unicorn: {
      len: 1.25,
      play: (k, t, o) => { k.say.neigh(t, 820, 0.85, o); [79, 84, 88, 91, 96].forEach((n, i) => k.glock(n, t + 0.8 + i * 0.07, 0.7, 0.05)); },
    },
    squeak: { len: 0.32, play: (k, t, o) => { k.say.squeak(t, 3000, 0.12, o); k.say.squeak(t + 0.17, 3200, 0.12, o); } },
    eep: { len: 0.45, play: (k, t, o) => [0, 0.15, 0.3].forEach((g, i) => k.say.squeak(t + g, 1900 + i * 150, 0.11, o)) },
    chitter: { len: 0.5, play: (k, t, o) => { for (let i = 0; i < 7; i++) k.say.squeak(t + i * 0.065, 2500 + ((i * 7) % 5) * 160, 0.045, o); } },
    ork: { len: 0.7, play: (k, t, o) => [0, 0.25, 0.5].forEach((g) => k.say.ork(t + g, 300, 0.19, o)) },
    ribbit: { len: 0.4, play: (k, t, o) => { k.say.croak(t, 150, 0.13, o); k.say.croak(t + 0.18, 170, 0.18, o); } },
    monkey: {
      len: 0.85,
      play: (k, t, o) => {
        k.say.ooh(t, 420, 0.14, o); k.say.ooh(t + 0.17, 460, 0.14, o);
        k.say.ah(t + 0.36, 600, 0.15, o); k.say.ah(t + 0.54, 650, 0.15, o); k.say.squeak(t + 0.72, 1400, 0.12, o);
      },
    },
    rooster: {
      len: 1.35,
      play: (k, t, o) => {
        k.say.crow(t, 600, 0.12, o); k.say.crow(t + 0.15, 730, 0.1, o); k.say.crow(t + 0.29, 850, 0.15, o);
        k.say.crow(t + 0.48, 960, 0.85, o);
      },
    },
    buzz: { len: 0.8, play: (k, t, o) => k.say.buzz(t, 230, 0.8, o) },
    bloop: { len: 0.4, play: (k, t, o) => [0, 0.14, 0.26].forEach((g, i) => k.say.bloop(t + g, 900 * (1 + i * 0.22), 0.1, o)) },
    boing: { len: 0.5, play: (k, t, o) => { k.say.bloop(t, 700, 0.18, o); k.say.bloop(t + 0.24, 900, 0.2, o); } },
    sniff: { len: 0.6, play: (k, t, o) => { [0, 0.11, 0.22, 0.33].forEach((g) => k.say.sniff(t + g, 2600, 0.07, o)); k.say.squeak(t + 0.45, 2400, 0.12, o); } },
    wheek: { len: 0.55, play: (k, t, o) => { k.say.squeak(t, 1500, 0.2, o); k.say.squeak(t + 0.28, 1700, 0.22, o); } },
    sloth: { len: 0.9, play: (k, t, o) => k.say.squeak(t, 1800, 0.9, o, 0.8) },
    honk: { len: 0.6, play: (k, t, o) => [0, 0.18, 0.36].forEach((g, i) => k.say.quack(t + g, 430 + i * 40, 0.16, o)) },
    lamb: { len: 0.6, play: (k, t, o) => k.say.baa(t, 420, 0.6, o, 0.8) },
  };
  function V2(k, kind, t, o) {
    if (kind === 'goat') {
      k.say.baa(t, 440, 0.55, o, 0.55);
      k.say.baa(t, 446, 0.55, o, 0.55); // two slightly apart voices = that wobbly goat "meh-eh-eh"
    }
  }

  /** which call each friend makes when it takes its solo */
  const FRIEND_CALL = {
    chick: 'cheep', duckling: 'peep', penguin: 'honk', owl: 'hoot', hamster: 'squeak', bunny: 'boing', fox: 'yip',
    kitten: 'meow', bearcub: 'rawr', panda: 'lamb', frog: 'ribbit', turtle: 'bloop', dino: 'dino', dragon: 'dragon',
    mouse: 'squeak', piglet: 'oink', koala: 'grunt', raccoon: 'chitter', tiger: 'roar', lion: 'roar', calf: 'calf',
    lamb: 'lamb', fawn: 'mew', hedgehog: 'sniff', otter: 'eep', seal: 'ork', axolotl: 'bloop', bat: 'squeak',
    mole: 'sniff', monkey: 'monkey', elephant: 'trumpet', squirrel: 'chitter', puppy: 'woof', unicorn: 'unicorn',
    capybara: 'wheek', redpanda: 'squeak', sloth: 'sloth', ladybug: 'buzz', snail: 'bloop', goat: 'goat',
  };

  /**
   * An animal's call: the real recording (js/samples.js) when it has loaded,
   * otherwise the synthesised one above. A few get a little magic on top.
   */
  const AFTER = {
    dragon: (k, t) => [84, 88, 91, 96].forEach((n, i) => k.glock(n, t + i * 0.07, 0.6, 0.05)),
  };
  function playCall(k, name, t, out, gain = 1) {
    const d = k.s.sample(name, t, out, { gain });
    if (d) { if (AFTER[name]) AFTER[name](k, t + d * 0.8); return d; }
    CALLS[name].play(k, t, out);
    return CALLS[name].len;
  }
  const lenOf = (name) => { const b = GC.Samples && GC.Samples.get(name); return b ? b.duration : CALLS[name].len; };

  /** singers: each animal's comfortable range (Hz); notes are folded into it by octaves */
  const RANGE = { meow: [440, 820], baa: [250, 460], quack: [260, 440], woof: [220, 400], oink: [150, 270], hoot: [300, 540], trumpet: [380, 720], cheep: [1800, 3600], kazoo: [300, 700] };
  function sing(k, who, t, n, d, o) {
    if (who === 'kazoo') { k.kazoo(n, t, d * 0.92, 0.06, o); return; }
    let f = midi(n);
    const [lo, hi] = RANGE[who];
    while (f < lo) f *= 2;
    while (f > hi) f /= 2;
    const len = who === 'cheep' ? Math.min(d, 0.12) : who === 'woof' || who === 'oink' || who === 'quack' ? Math.min(d * 0.8, 0.3) : d * 0.92;
    k.say[who](t, f, len, o);
  }

  /* --------------------------------------------------------------- songs
   * mel: [beat, note, beats]. Chords are MIDI note lists.
   */
  const C = [60, 64, 67], F = [60, 65, 69], G = [59, 62, 67], Am = [57, 60, 64];
  const A7 = [57, 61, 64, 67], D = [62, 66, 69];
  /** the nearest chord tone a bit below a melody note: a simple harmony line */
  const below = (n, chord) => {
    let best = n - 12;
    for (const c of chord) for (let o = -24; o <= 12; o += 12) { const h = c + o; if (h <= n - 3 && h > best) best = h; }
    return best;
  };
  const Fj = [60, 65, 69], Bb = [62, 65, 70], Cj = [60, 64, 67], Dm = [62, 65, 69];
  const Gf = [59, 62, 67], Cf = [60, 64, 67], Df = [62, 66, 69], Em = [59, 64, 67];

  const SONGS = {
    band: {
      bpm: 136, introBeats: 4,
      pool: ['moo', 'quack', 'baa', 'woof', 'meow', 'oink', 'trumpet', 'roar', 'hoot', 'neigh'],
      singers: ['meow', 'baa', 'kazoo', 'quack', 'hoot', 'woof'],
      // a dotted march line, then a gap for the animal; bars 1-2 share a rhythm so it is easy to follow
      A: [
        { chord: C, root: 36, fifth: 43, mel: [[0, 67, 0.75], [0.75, 72, 0.25], [1, 76, 0.5], [1.5, 79, 0.5]] },
        { chord: F, root: 41, fifth: 36, mel: [[0, 69, 0.75], [0.75, 72, 0.25], [1, 77, 0.5], [1.5, 81, 0.5]] },
        { chord: G, root: 43, fifth: 38, mel: [[0, 79, 0.75], [0.75, 77, 0.25], [1, 76, 0.5], [1.5, 74, 0.5]] },
        { chord: C, root: 36, fifth: 43, mel: [[0, 76, 0.75], [0.75, 74, 0.25], [1, 72, 1]] },
      ],
      // the animals sing; the last two beats pivot on A7 so the finale can step up a key
      B: [
        { chords: [[0, Am, 33], [2, F, 41]], notes: [[0, 69, 1], [1, 72, 1], [2, 77, 1], [3, 76, 1]] },
        { chords: [[0, G, 43], [2, A7, 45]], notes: [[0, 74, 1], [1, 71, 1], [2, 73, 1], [3, 76, 1]] },
      ],
      // finale in D: one step higher than the rest of the song, for a lift
      end: { chord: D, root: 38, top: [62, 66, 69, 74], fan: [[0, 69, 1 / 3], [1 / 3, 74, 1 / 3], [2 / 3, 78, 1 / 3], [1, 81, 1]] },
      tail: 4.2,
      intro(k, at) {
        // drum major's whistle ("tweet, tweeeet!"), then a snare roll with a slide whistle into the downbeat
        at(0, (t) => k.peaWhistle(t, 0.16));
        at(0.5, (t, B) => k.peaWhistle(t, B(1.6) - t));
        at(2, (t, B) => { k.roll(t, B(4) - 0.03, 0.03, 0.2); k.slideWhistle(t, 64, 88, B(3.9) - t, 0.06); });
      },
      groove(k, at, b, kind, i) {
        const hum = (g) => g * (0.88 + Math.random() * 0.24); // nobody in a real band hits exactly the same every time
        if (i === 0) at(b, (t) => { k.crash(t, kind === 'A' ? 0.12 : 0.08); });
        // oom-pah: bass drum on 1 and 3, snare + cymbals on 2 and 4
        for (const x of [0, 2]) at(b + x, (t) => k.bassDrum(t, hum(x ? 0.4 : 0.5)));
        for (const x of [1, 3]) at(b + x, (t) => { if (kind === 'A') k.flam(t, hum(0.2)); else k.clap(t, hum(0.15)); k.clash(t, hum(0.045)); });
        if (kind === 'A') {
          for (const x of [0.5, 1.75, 2.5, 3.25]) at(b + x, (t) => k.snare(t, hum(0.06))); // ghost notes keep it marching
          if (i === 3) [3.5, 3.625, 3.75, 3.875].forEach((x, j) => at(b + x, (t) => k.snare(t, 0.08 + j * 0.035))); // fill into the choir
          else at(b + 3.5, (t) => k.snare(t, hum(0.1)));
        } else {
          for (let x = 0; x < 8; x++) at(b + x / 2, (t) => k.hat(t, hum(x % 2 ? 0.03 : 0.05)));
          if (i === 1) at(b + 2, (t, B) => k.roll(t, B(b + 4) - 0.03, 0.02, 0.22)); // roll into the key change
        }
      },
      bass(k, at, b, root, fifth, beats = 4) {
        at(b, (t, B) => k.tuba(root, t, B(b + 0.9) - t));
        if (beats > 2) at(b + 2, (t, B) => k.tuba(fifth, t, B(b + 2.9) - t));
      },
      comp(k, at, b, chord, kind, beats = 4) {
        // trombones on the "pah", horns hold the harmony underneath
        for (let x = 1; x < beats; x += 2) at(b + x, (t, B) => k.bones(chord, t, B(b + x + 0.45) - t, kind === 'A' ? 0.045 : 0.032));
        at(b, (t, B) => k.horns(chord.map((n) => n + 12).slice(0, 3), t, B(b + beats) - t - 0.03, kind === 'A' ? 0.012 : 0.02));
      },
      lead(k, t, n, d, i, spb, chord) {
        const h = below(n, chord);
        k.brass(n, t, d * 0.9);
        k.brass(h, t, d * 0.9, 0.045); // second trumpets play the harmony
        k.glock(n + 12, t, 0.8, 0.03);
        if (i >= 2) k.flute(n + 12, t, d * 0.88, 0.035); // piccolo joins for the second half
      },
      pad(k, notes, t, d, g) { k.horns(notes, t, d, g * 1.6); },
      finish(k, t, e, spb) {
        const top = e.top, hit = (tt, d, g) => {
          k.chord(top, tt, d, g, (n, t2, d2, g2) => k.brass(n, t2, d2, g2));
          k.bones(top.slice(0, 3).map((n) => n - 12), tt, d, g * 0.6);
          k.tuba(e.root, tt, d, 0.22); k.bassDrum(tt, 0.55); k.timp(tt, e.root + 12, 0.28);
        };
        // ta-daaa … bum-BUM!
        hit(t, 1.25, 0.065);
        k.horns(top, t, 1.3, 0.02); k.crash(t, 0.16); k.clash(t, 0.08);
        k.harp(top.map((n) => n + 12).concat(top.slice(1).map((n) => n + 24)), t + 0.05, 0.045, 0.045);
        k.roll(t + 1.3, t + 1.3 + spb * 1.5, 0.03, 0.14);
        k.flam(t + 1.3 + spb * 1.5, 0.2); hit(t + 1.3 + spb * 1.5, 0.18, 0.06);
        hit(t + 1.3 + spb * 2, 1.4, 0.075); k.crash(t + 1.3 + spb * 2, 0.16); k.clash(t + 1.3 + spb * 2, 0.09);
        k.glock(top[3] + 24, t + 1.3 + spb * 2, 1.4, 0.05);
      },
    },

    jungle: {
      bpm: 124, introBeats: 3,
      pool: ['monkey', 'trumpet', 'roar', 'tweet', 'ribbit', 'hoot', 'buzz', 'chitter'],
      singers: ['hoot', 'trumpet', 'meow', 'cheep', 'hoot', 'trumpet', 'meow'],
      A: [
        { chord: Fj, root: 41, fifth: 48, mel: [[0, 72, 0.75], [0.75, 77, 0.75], [1.5, 81, 0.5]] },
        { chord: Bb, root: 46, fifth: 41, mel: [[0, 74, 0.75], [0.75, 77, 0.75], [1.5, 82, 0.5]] },
        { chord: Cj, root: 48, fifth: 43, mel: [[0, 76, 0.5], [0.5, 79, 0.5], [1, 84, 0.5], [1.5, 82, 0.5]] },
        { chord: Fj, root: 41, fifth: 48, mel: [[0, 81, 0.75], [0.75, 79, 0.75], [1.5, 77, 0.5]] },
      ],
      B: [
        { chords: [[0, Dm, 38], [2, Bb, 46]], notes: [[0, 69, 1], [1, 74, 1], [2, 74, 1], [3, 77, 1]] },
        { chords: [[0, Cj, 48], [2, Fj, 41]], notes: [[0, 79, 1], [1, 76, 1], [2, 77, 2]] },
      ],
      end: { chord: Fj, root: 41, top: [65, 69, 72, 77], fan: [[0, 72, 1 / 3], [1 / 3, 77, 1 / 3], [2 / 3, 81, 1 / 3], [1, 84, 1]] },
      intro(k, at) {
        at(0, (t) => playCall(k, 'monkey', t, k.ch.aL));
        [[1.5, 1], [2, 0], [2.25, 1], [2.5, 0], [2.75, 0]].forEach(([b, hi]) => at(b, (t) => k.bongo(t, !!hi, 0.1 + b * 0.025)));
        for (let x = 0; x < 6; x++) at(1.5 + x / 4, (t) => k.shaker(t, 0.02 + x * 0.006));
      },
      groove(k, at, b, kind, i) {
        if (i === 0 && kind === 'A') at(b, (t) => k.crash(t, 0.08));
        [0, 1.5, 2, 3.5].forEach((x) => at(b + x, (t) => k.kick(t, 0.4)));
        [[0, 0], [0.5, 1], [1, 1], [1.5, 0], [2, 0], [2.5, 1], [3, 1], [3.5, 1], [3.75, 1]].forEach(([x, hi]) => at(b + x, (t) => k.bongo(t, !!hi, x % 1 ? 0.09 : 0.13)));
        for (let x = 0; x < 16; x++) at(b + x / 4, (t) => k.shaker(t, x % 2 ? 0.025 : 0.04));
        [0, 0.75, 1.5, 2.5, 3].forEach((x) => at(b + x, (t) => k.claves(t, 0.06)));
      },
      bass(k, at, b, root, fifth, beats = 4) {
        at(b, (t) => k.bass(root, t, 0.5));
        at(b + 1.5, (t) => k.bass(root, t, 0.3, 0.18));
        if (beats > 2) { at(b + 2, (t) => k.bass(fifth, t, 0.5)); at(b + 3.5, (t) => k.bass(fifth + 2, t, 0.3, 0.18)); }
      },
      comp(k, at, b, chord, kind, beats = 4) {
        if (kind === 'A') for (let x = 0.5; x < beats; x += 1) at(b + x, (t) => k.uke(chord.map((n) => n + 12), t, 0.04));
        else for (let x = 0; x < beats * 2; x++) at(b + x / 2, (t) => k.marimba(chord[x % 3] + (x % 6 < 3 ? 0 : 12), t, 0.06));
      },
      lead(k, t, n, d, i, spb) {
        k.steel(n, t, Math.max(0.6, d), 0.1);
        if (d > spb * 0.7) k.steel(n, t + spb / 2, 0.5, 0.05); // steel pans repeat long notes
        k.marimba(n - 12, t, 0.06, k.ch.lead);
        if (i >= 2) k.panflute(n + 12, t, d * 0.9, 0.035);
      },
      finish(k, t, e) {
        k.chord(e.top, t, 1.6, 0.07, k.steel);
        k.chord(e.top.map((n) => n + 12), t + 0.18, 1.2, 0.04, k.steel);
        k.uke(e.top.map((n) => n + 12), t, 0.06); k.bass(e.root, t, 1.4, 0.26);
        k.kick(t, 0.5); k.crash(t, 0.14); k.bongo(t, true, 0.16); k.bongo(t + 0.09, false, 0.16);
        k.harp([77, 81, 84, 89, 93, 96], t + 0.05, 0.05, 0.045);
        playCall(k, 'tweet', t + 0.4, k.ch.aR);
      },
    },

    farm: {
      bpm: 144, introBeats: 4,
      pool: ['moo', 'baa', 'oink', 'quack', 'woof', 'neigh', 'goat', 'cheep', 'meow'],
      singers: ['baa', 'quack', 'oink', 'meow', 'woof', 'baa', 'kazoo'],
      A: [
        { chord: Gf, root: 43, fifth: 38, mel: [[0, 67, 0.5], [0.5, 71, 0.5], [1, 74, 1]] },
        { chord: Cf, root: 48, fifth: 43, mel: [[0, 72, 0.5], [0.5, 76, 0.5], [1, 79, 1]] },
        { chord: Df, root: 50, fifth: 45, mel: [[0, 74, 0.5], [0.5, 78, 0.5], [1, 81, 0.5], [1.5, 78, 0.5]] },
        { chord: Gf, root: 43, fifth: 38, mel: [[0, 79, 0.5], [0.5, 74, 0.5], [1, 71, 1]] },
      ],
      B: [
        { chords: [[0, Em, 40], [2, Cf, 48]], notes: [[0, 71, 1], [1, 67, 1], [2, 72, 1], [3, 76, 1]] },
        { chords: [[0, Df, 50], [2, Gf, 43]], notes: [[0, 74, 1], [1, 78, 1], [2, 79, 2]] },
      ],
      end: { chord: Gf, root: 43, top: [67, 71, 74, 79], fan: [[0, 67, 1 / 3], [1 / 3, 71, 1 / 3], [2 / 3, 74, 1 / 3], [1, 79, 1]] },
      intro(k, at) {
        at(0, (t) => playCall(k, 'rooster', t, k.ch.aL));
        at(3, (t) => k.washboard(t, 0.08)); at(3.5, (t) => k.washboard(t, 0.1));
        at(3, (t, B) => k.fiddle(62, t, B(3.45) - t, 0.05)); at(3.5, (t, B) => k.fiddle(64, t, B(3.95) - t, 0.05));
      },
      groove(k, at, b, kind, i) {
        if (i === 0 && kind === 'A') at(b, (t) => k.crash(t, 0.08));
        [0, 2].forEach((x) => at(b + x, (t) => k.kick(t, 0.42)));
        [1, 3].forEach((x) => at(b + x, (t) => k.clap(t, 0.12)));
        for (let x = 0; x < 8; x++) at(b + x / 2, (t) => k.washboard(t, x % 2 ? 0.035 : 0.06));
        at(b, (t) => k.cowbell(t, 0.05));
        if (kind === 'B') at(b + 2, (t) => k.cowbell(t, 0.04));
      },
      bass(k, at, b, root, fifth, beats = 4) {
        at(b, (t, B) => k.jug(root, t, B(b + 0.85) - t));
        if (beats > 2) at(b + 2, (t, B) => k.jug(fifth, t, B(b + 2.85) - t));
      },
      comp(k, at, b, chord, kind, beats = 4) {
        for (let x = 1; x < beats; x += 2) at(b + x, (t) => k.strum(chord.map((n) => n + 12), t, 0.055, k.banjo));
        if (kind === 'A') for (let x = 0; x < beats * 2; x += 2) at(b + x / 2 + 0.5, (t) => k.banjo(chord[(x / 2) % 3] + 24, t, 0.03));
        else at(b, (t, B) => k.harmonica(chord.map((n) => n + 12), t, B(b + beats) - t - 0.05, 0.022));
      },
      lead(k, t, n, d, i) {
        k.fiddle(n, t, d * 0.92);
        if (i >= 2) k.harmonica([n], t, d * 0.9, 0.04);
        else k.banjo(n + 12, t, 0.04, k.ch.sparkle);
      },
      finish(k, t, e) {
        k.fiddle(e.top[3], t, 1.6, 0.07); k.fiddle(e.top[1] + 12, t, 1.6, 0.04);
        k.harmonica(e.top, t, 1.5, 0.03); k.strum(e.top.map((n) => n + 12), t, 0.07, k.banjo);
        k.jug(e.root, t, 1.0, 0.24); k.kick(t, 0.5); k.crash(t, 0.14); k.cowbell(t, 0.07); k.cowbell(t + 0.28, 0.06);
        k.slideWhistle(t + 0.05, 74, 98, 0.45, 0.06);
      },
    },
  };

  /* ---------------------------------------------------------- performance */
  function arrange(song, k, friendCall, spb) {
    const ev = [];
    const at = (beat, fn) => ev.push({ beat, fn });
    const others = GC.shuffle(song.pool.filter((c) => c !== friendCall));
    const pans = [k.ch.aL, k.ch.aR, k.ch.aL, k.ch.aR];

    song.intro(k, at);
    let b = song.introBeats;

    // A: the band plays a line, an animal answers
    song.A.forEach((bar, i) => {
      song.groove(k, at, b, 'A', i);
      song.bass(k, at, b, bar.root, bar.fifth);
      song.comp(k, at, b, bar.chord, 'A');
      for (const [x, n, d] of bar.mel) at(b + x, (t) => song.lead(k, t, n, d * spb, i, spb, bar.chord));
      const who = others[i % others.length];
      at(b + 2, (t) => playCall(k, who, t, pans[i]));
      b += 4;
    });

    // B: the animals sing the tune
    let singer = Math.floor(Math.random() * song.singers.length);
    song.B.forEach((bar, i) => {
      song.groove(k, at, b, 'B', i);
      bar.chords.forEach(([x, chord, root], j) => {
        const beats = j + 1 < bar.chords.length ? bar.chords[j + 1][0] - x : 4 - x;
        song.bass(k, at, b + x, root, root + 7, beats);
        song.comp(k, at, b + x, chord, 'B', beats);
      });
      for (const [x, n, d] of bar.notes) {
        const who = song.singers[singer++ % song.singers.length];
        const out = singer % 2 ? k.ch.aL : k.ch.aR;
        at(b + x, (t) => sing(k, who, t, n, d * spb, out));
      }
      b += 4;
    });

    // finale: fanfare + everyone cheers, then the friend's solo, then ta-da
    const e = song.end;
    at(b, (t) => { k.crash(t, 0.12); k.kick(t, 0.5); });
    for (const [x, n, d] of e.fan) at(b + x, (t) => song.lead(k, t, n, d * spb, 3, spb, e.chord));
    song.bass(k, at, b, e.root, e.root + 7, 2);
    others.slice(4, 7).concat(others.slice(0, 1)).forEach((who, i) => at(b + 1 + i * 0.25, (t) => playCall(k, who, t, i % 2 ? k.ch.aL : k.ch.aR, 0.8)));
    const soloAt = b + 3;
    const callLen = lenOf(friendCall);
    at(soloAt - 0.5, (t) => k.timpRoll(t, t + 0.5, e.root + 12, 0.02, 0.12));
    at(soloAt, (t) => { playCall(k, friendCall, t, k.ch.solo); (song.pad || ((kk, ...a) => kk.strings(...a)))(k, e.top, t, callLen + spb, 0.012); });
    const endBeat = Math.ceil((soloAt + (callLen + 0.15) / spb) * 2) / 2;
    at(endBeat, (t) => song.finish(k, t, e, spb));
    return { ev, beats: endBeat, tail: song.tail || 2.6 };
  }

  /** the room every band plays in: a short, soft reverb */
  P._room = function () {
    if (this._roomIR) return this._roomIR;
    const ctx = this.ctx, sr = ctx.sampleRate, len = Math.floor(sr * 1.3);
    const ir = ctx.createBuffer(2, len, sr);
    for (let c = 0; c < 2; c++) {
      const d = ir.getChannelData(c);
      for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 3.2);
    }
    return (this._roomIR = ir);
  };

  P.bandTune = function (id, friendId) {
    if (!this.ensure()) return 0;
    this.stopCelebration(0.05);
    const ctx = this.ctx;
    const song = SONGS[id];
    const friendCall = FRIEND_CALL[friendId] || GC.pick(Object.values(FRIEND_CALL));
    const spb = 60 / song.bpm;

    // mixer: one bus per song so it can stop cleanly, gentle glue compression, room
    const bus = ctx.createGain(); bus.gain.value = 1;
    const glue = ctx.createDynamicsCompressor();
    glue.threshold.value = -16; glue.knee.value = 10; glue.ratio.value = 4; glue.attack.value = 0.004; glue.release.value = 0.2;
    const trim = ctx.createGain(); trim.gain.value = 0.9;
    bus.connect(glue); glue.connect(trim); trim.connect(this.master);
    const room = ctx.createConvolver(); room.buffer = this._room();
    const wet = ctx.createGain(); wet.gain.value = 0.22;
    bus.connect(room); room.connect(wet); wet.connect(this.master);
    const chan = (pan, gain) => {
      const g = ctx.createGain(); g.gain.value = gain;
      if (ctx.createStereoPanner) { const p = ctx.createStereoPanner(); p.pan.value = pan; g.connect(p); p.connect(bus); } else g.connect(bus);
      return g;
    };
    const ch = {
      drums: chan(0, 0.85), bass: chan(0, 1), comp: chan(-0.3, 0.9), lead: chan(0.12, 1), sparkle: chan(0.35, 0.9),
      aL: chan(-0.4, 1), aR: chan(0.4, 1), solo: chan(0, 1.15),
    };
    const k = makeKit(this, ch);
    k.ch = ch;
    const { ev, beats, tail } = arrange(song, k, friendCall, spb);

    const t0 = ctx.currentTime + 0.08;
    const B = (beat) => t0 + beat * spb;
    for (const e of ev) e.t = B(e.beat);
    ev.sort((a, b) => a.t - b.t);
    const len = B(beats) - t0 + tail;
    const c = { ev, i: 0, bus, nodes: [bus, glue, trim, room, wet, ...Object.values(ch)], B, end: t0 + len, friendCall };
    this._celeb = c;
    this._celebPump();
    c.timer = setInterval(() => this._celebPump(), 50);
    c.doneT = setTimeout(() => { if (this._celeb === c) this.stopCelebration(0.1); }, (len + 0.5) * 1000);
    return len;
  };

  /** schedule the next stretch of the song; skip anything a stall made us miss */
  P._celebPump = function () {
    const c = this._celeb;
    if (!c) return;
    const now = this.ctx.currentTime;
    const ahead = now + (document.hidden ? 1.6 : 0.3);
    while (c.i < c.ev.length && c.ev[c.i].t < ahead) {
      const e = c.ev[c.i++];
      if (e.t < now - 0.05) { this.dropped = (this.dropped || 0) + 1; continue; }
      e.fn(e.t, c.B);
    }
    if (c.i >= c.ev.length && c.timer) { clearInterval(c.timer); c.timer = null; }
  };

  P.stopCelebration = function (fade = 0.3) {
    const c = this._celeb;
    if (!c) return;
    this._celeb = null;
    clearInterval(c.timer); clearTimeout(c.doneT);
    c.timer = null;
    try {
      c.bus.gain.cancelScheduledValues(this.ctx.currentTime);
      c.bus.gain.setTargetAtTime(0, this.ctx.currentTime, Math.max(0.01, fade / 3));
    } catch (e) {}
    setTimeout(() => c.nodes.forEach((n) => { try { n.disconnect(); } catch (e) {} }), fade * 1000 + 400);
  };

  /** dip the band while the device voice says the friend's name */
  P.duckCelebration = function (secs = 1.8) {
    const c = this._celeb;
    if (!c) return;
    const g = c.bus.gain, now = this.ctx.currentTime;
    g.cancelScheduledValues(now);
    g.setTargetAtTime(0.3, now, 0.08);
    g.setTargetAtTime(1, now + secs, 0.3);
  };

  /** one animal's call on its own (tap the friend to hear it again) */
  P.animalCall = function (name) {
    const call = CALLS[name];
    if (!call || !this.ensure()) return 0;
    const b = this.sfxBus;
    const ch = { drums: b, bass: b, comp: b, lead: b, sparkle: b, aL: b, aR: b, solo: b };
    const k = makeKit(this, ch);
    k.ch = ch;
    return playCall(k, name, this.ctx.currentTime + 0.02, b);
  };
  P.friendCall = function (friendId) { return this.animalCall(FRIEND_CALL[friendId]); };

  GC.Band = { SONGS, CALLS, FRIEND_CALL, ids: Object.keys(SONGS) };
})();
