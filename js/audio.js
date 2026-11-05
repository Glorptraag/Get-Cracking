/* Get Cracking — sound.
 *
 * Everything is synthesised live with Web Audio: no audio files, works
 * offline, and all melodies are original. Three jobs:
 *   1. countdown music — an ambient "something is happening" cue that keeps
 *      working when the child looks away from the screen
 *   2. small sound effects — crack, pop, boop, knock
 *   3. the end tune — a cheerful celebration instead of an alarm
 */
(function () {
  'use strict';
  const GC = window.GC;
  const midi = (n) => 440 * Math.pow(2, (n - 69) / 12);

  const MUSIC = [
    { id: 'musicbox', name: 'Music box', icon: '🎶' },
    { id: 'marimba', name: 'Marimba walk', icon: '🪘' },
    { id: 'forest', name: 'Forest birds', icon: '🐦' },
    { id: 'rain', name: 'Soft rain', icon: '🌧️' },
    { id: 'ticktock', name: 'Gentle tick-tock', icon: '🕰️' },
    { id: 'off', name: 'Quiet', icon: '🔇' },
  ];
  const ENDS = [
    { id: 'tada', name: 'Ta-da parade', icon: '🎉' },
    { id: 'chimes', name: 'Happy chimes', icon: '🔔' },
    { id: 'birds', name: 'Birdsong hello', icon: '🐤' },
    { id: 'bubbles', name: 'Bubble pops', icon: '🫧' },
  ];

  // original melodies (MIDI note numbers, null = rest)
  const MUSICBOX = {
    bpm: 76, steps: 2, // 8th notes
    mel: [76, 79, 84, 79, 77, 81, 84, 81, 76, 79, 83, 79, 74, 77, 79, 77,
      72, 76, 79, 76, 74, 77, 81, 77, 79, 76, 74, 72, 71, 74, 79, null],
    bass: [48, null, null, null, 53, null, null, null, 52, null, null, null, 50, null, 55, null,
      48, null, null, null, 50, null, null, null, 55, null, null, null, 43, null, 55, null],
  };
  const MARIMBA = {
    bpm: 112, steps: 2,
    mel: [67, 71, 74, 71, 69, 74, 76, 74, 67, 71, 74, 79, 76, 74, 71, 69,
      64, 67, 71, 67, 66, 69, 74, 69, 67, 71, 76, 74, 71, null, 67, null],
    bass: [43, null, 50, null, 45, null, 50, null, 43, null, 50, null, 47, null, 45, null,
      40, null, 47, null, 42, null, 50, null, 43, null, 47, null, 43, null, null, null],
  };

  class Sound {
    constructor() {
      this.ctx = null;
      this.volume = 0.7;
      this.music = 'off';
      this.tension = 0;
      this._timer = null;
    }

    ensure() {
      if (!this.ctx) {
        const AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return null;
        const ctx = (this.ctx = new AC());
        this.master = ctx.createGain();
        this.master.gain.value = this.volume;
        const comp = ctx.createDynamicsCompressor();
        comp.threshold.value = -18; comp.ratio.value = 3;
        this.master.connect(comp); comp.connect(ctx.destination);
        // music bus with a soft echo for a dreamy music-box feel
        this.musicBus = ctx.createGain();
        this.musicBus.gain.value = 0.55;
        this.musicBus.connect(this.master);
        const delay = ctx.createDelay(1); delay.delayTime.value = 0.32;
        const fb = ctx.createGain(); fb.gain.value = 0.28;
        const wet = ctx.createGain(); wet.gain.value = 0.35;
        const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 2600;
        this.musicBus.connect(delay); delay.connect(lp); lp.connect(fb); fb.connect(delay); lp.connect(wet); wet.connect(this.master);
        this.sfxBus = ctx.createGain(); this.sfxBus.gain.value = 0.9; this.sfxBus.connect(this.master);
        this.sfxBus.connect(delay);
        this._noise = this._makeNoise();
      }
      if (this.ctx.state === 'suspended') this.ctx.resume();
      return this.ctx;
    }

    setVolume(v) {
      this.volume = v;
      if (this.master) this.master.gain.setTargetAtTime(v, this.ctx.currentTime, 0.05);
    }

    _makeNoise() {
      const len = this.ctx.sampleRate * 2;
      const buf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
      const d = buf.getChannelData(0);
      for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      return buf;
    }

    /** one plucked / struck note */
    tone(freq, t, dur, o = {}) {
      const ctx = this.ctx;
      const g = ctx.createGain();
      const peak = o.gain ?? 0.2;
      const a = o.attack ?? 0.005;
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(peak, t + a);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      g.connect(o.bus || this.musicBus);
      const partials = o.partials || [[1, 1]];
      for (const [ratio, amp] of partials) {
        const osc = ctx.createOscillator();
        osc.type = o.type || 'sine';
        osc.frequency.setValueAtTime(freq * ratio, t);
        if (o.slide) osc.frequency.exponentialRampToValueAtTime(freq * ratio * o.slide, t + dur * 0.8);
        let node = osc;
        if (amp !== 1) { const pg = ctx.createGain(); pg.gain.value = amp; osc.connect(pg); node = pg; }
        node.connect(g);
        osc.start(t); osc.stop(t + dur + 0.05);
      }
    }

    noiseBurst(t, dur, o = {}) {
      const ctx = this.ctx;
      const src = ctx.createBufferSource(); src.buffer = this._noise;
      const f = ctx.createBiquadFilter(); f.type = o.filter || 'bandpass'; f.frequency.value = o.freq || 2000; f.Q.value = o.q || 1;
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(o.gain || 0.2, t + (o.attack || 0.003));
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      src.connect(f); f.connect(g); g.connect(o.bus || this.sfxBus);
      src.start(t, Math.random()); src.stop(t + dur + 0.05);
    }

    /* ------------------------------------------------------- music */
    startMusic(id) {
      this.stopMusic();
      this.music = id;
      if (!this.ensure() || id === 'off') return;
      this.musicBus.gain.cancelScheduledValues(this.ctx.currentTime);
      this.musicBus.gain.setValueAtTime(0.0001, this.ctx.currentTime);
      this.musicBus.gain.exponentialRampToValueAtTime(0.55, this.ctx.currentTime + 1.5);
      this._step = 0;
      this._next = this.ctx.currentTime + 0.1;
      this._ambientAt = this.ctx.currentTime + 0.5;
      if (id === 'forest' || id === 'rain') this._startBed(id);
      this._timer = setInterval(() => this._schedule(), 60);
    }

    stopMusic(fade = 0.6) {
      if (this._timer) clearInterval(this._timer);
      this._timer = null;
      if (this._bed) {
        const b = this._bed; this._bed = null;
        try {
          b.g.gain.setTargetAtTime(0.0001, this.ctx.currentTime, fade / 3);
          setTimeout(() => { try { b.src.stop(); } catch (e) {} }, fade * 1000 + 200);
        } catch (e) {}
      }
    }

    pauseMusic() { this._pausedMusic = this.music; this.stopMusic(0.3); }
    resumeMusic() { if (this._pausedMusic) this.startMusic(this._pausedMusic); }

    setTension(v) { this.tension = v; }

    _startBed(id) {
      const ctx = this.ctx;
      const src = ctx.createBufferSource(); src.buffer = this._noise; src.loop = true;
      const f = ctx.createBiquadFilter();
      const g = ctx.createGain(); g.gain.value = 0.0001;
      if (id === 'forest') {
        f.type = 'bandpass'; f.frequency.value = 500; f.Q.value = 0.6;
        const lfo = ctx.createOscillator(); lfo.frequency.value = 0.08;
        const lg = ctx.createGain(); lg.gain.value = 260; lfo.connect(lg); lg.connect(f.frequency); lfo.start();
        g.gain.setTargetAtTime(0.07, ctx.currentTime, 1);
      } else {
        f.type = 'lowpass'; f.frequency.value = 1800;
        const hp = ctx.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = 400;
        src.connect(hp); hp.connect(f); f.connect(g); g.connect(this.musicBus);
        src.start(); g.gain.setTargetAtTime(0.12, ctx.currentTime, 1);
        this._bed = { src, g };
        return;
      }
      src.connect(f); f.connect(g); g.connect(this.musicBus); src.start();
      this._bed = { src, g };
    }

    _schedule() {
      const ctx = this.ctx;
      const now = ctx.currentTime;
      // look further ahead when the tab is hidden (timers are throttled to ~1/s)
      const ahead = now + (document.hidden ? 1.6 : 0.25);
      // after a stall, skip the missed notes instead of firing them all at once
      if (this._next < now - 0.02) {
        const song = this.music === 'marimba' ? MARIMBA : MUSICBOX;
        const stepDur = this.music === 'ticktock' ? (this.tension > 0 ? 0.5 : 1) : 60 / song.bpm / song.steps;
        const missed = Math.ceil((now - this._next) / stepDur);
        this._next += missed * stepDur;
        this._step += missed;
        this.dropped = (this.dropped || 0) + missed;
      }
      if (this._ambientAt < now - 0.02) this._ambientAt = now + 0.05;
      const id = this.music;
      if (id === 'musicbox' || id === 'marimba') {
        const song = id === 'musicbox' ? MUSICBOX : MARIMBA;
        const stepDur = 60 / song.bpm / song.steps;
        while (this._next < ahead) {
          const i = this._step % song.mel.length;
          const n = song.mel[i], b = song.bass[i];
          if (id === 'musicbox') {
            if (n) this.tone(midi(n), this._next, 1.4, { gain: 0.11, partials: [[1, 1], [2, 0.25], [3.01, 0.08]] });
            if (b) this.tone(midi(b), this._next, 2.2, { gain: 0.08, type: 'triangle' });
            if (this.tension > 0 && n && i % 2 === 0) this.tone(midi(n + 12), this._next + stepDur * 0.5, 0.6, { gain: 0.05 });
          } else {
            if (n) this.tone(midi(n), this._next, 0.45, { gain: 0.14, partials: [[1, 1], [4, 0.12], [9.8, 0.03]] });
            if (b) this.tone(midi(b), this._next, 0.6, { gain: 0.12, partials: [[1, 1], [3.9, 0.08]] });
            if (this.tension > 0 && i % 4 === 2) this.tone(midi(91), this._next, 0.25, { gain: 0.04 });
          }
          this._next += stepDur;
          this._step++;
        }
      } else if (id === 'ticktock') {
        while (this._next < ahead) {
          const hi = this._step % 2 === 0;
          this.noiseBurst(this._next, 0.05, { freq: hi ? 2400 : 1700, q: 8, gain: 0.12, bus: this.musicBus });
          this.tone(hi ? 1180 : 880, this._next, 0.07, { gain: 0.05 });
          if (this._step % 8 === 0) this.tone(midi(84), this._next, 1.6, { gain: 0.03, partials: [[1, 1], [2.76, 0.2]] });
          this._next += this.tension > 0 ? 0.5 : 1;
          this._step++;
        }
      } else if (id === 'forest') {
        if (this._ambientAt < ahead) {
          const t = this._ambientAt;
          const base = GC.rand(2200, 3600);
          const n = Math.floor(GC.rand(2, 5));
          for (let k = 0; k < n; k++) this.tone(base * GC.rand(0.9, 1.15), t + k * 0.11, 0.09, { gain: 0.05, slide: GC.rand(1.15, 1.4) });
          this._ambientAt = t + GC.rand(1.2, this.tension > 0 ? 2.5 : 4.5);
        }
      } else if (id === 'rain') {
        while (this._ambientAt < ahead) {
          const t = this._ambientAt;
          this.tone(GC.rand(900, 2200), t, 0.18, { gain: 0.035, slide: 0.7 });
          this._ambientAt = t + GC.rand(0.15, 0.9);
        }
      }
    }

    /* --------------------------------------------------------- sfx */
    crack() {
      if (!this.ensure()) return;
      const t = this.ctx.currentTime + 0.01;
      for (let i = 0; i < 3; i++) this.noiseBurst(t + i * 0.045 + Math.random() * 0.02, 0.06, { freq: GC.rand(2500, 4200), q: 2, gain: 0.25, filter: 'bandpass' });
      this.tone(220, t, 0.08, { gain: 0.1, bus: this.sfxBus, slide: 0.6 });
    }
    boop() {
      if (!this.ensure()) return;
      this.tone(GC.rand(520, 640), this.ctx.currentTime, 0.18, { gain: 0.08, bus: this.sfxBus, slide: 1.5 });
    }
    knock() {
      if (!this.ensure()) return;
      const t = this.ctx.currentTime + 0.01;
      for (const dt of [0, 0.2]) {
        this.tone(190, t + dt, 0.12, { gain: 0.25, bus: this.sfxBus, slide: 0.7 });
        this.noiseBurst(t + dt, 0.05, { freq: 900, q: 1.5, gain: 0.12 });
      }
    }
    ready() { // gentle "time's up" — a soft rising sparkle, never an alarm
      if (!this.ensure()) return;
      const t = this.ctx.currentTime + 0.02;
      [72, 76, 79, 84].forEach((n, i) => this.tone(midi(n), t + i * 0.12, 1.2, { gain: 0.1, bus: this.sfxBus, partials: [[1, 1], [2.76, 0.15]] }));
    }
    pop() {
      if (!this.ensure()) return;
      const t = this.ctx.currentTime;
      this.tone(320, t, 0.25, { gain: 0.3, bus: this.sfxBus, slide: 3.2 });
      this.noiseBurst(t, 0.25, { freq: 1500, q: 0.7, gain: 0.2 });
    }
    cheer() {
      if (!this.ensure()) return;
      const t = this.ctx.currentTime;
      [79, 84].forEach((n, i) => this.tone(midi(n), t + i * 0.09, 0.3, { gain: 0.1, bus: this.sfxBus, partials: [[1, 1], [2, 0.2]] }));
    }

    /** shell piece hitting something hard; p = 0..1 pitch */
    clink(p = 0.5) {
      if (!this.ensure()) return;
      const t = this.ctx.currentTime;
      const f = 1800 + p * 2600;
      this.tone(f, t, 0.12, { gain: 0.07, bus: this.sfxBus, partials: [[1, 1], [2.7, 0.3]] });
      this.noiseBurst(t, 0.03, { freq: f * 1.5, q: 4, gain: 0.08 });
    }
    /** soft landing on the ground; p = 0..1 pitch */
    thud(p = 0.5) {
      if (!this.ensure()) return;
      const t = this.ctx.currentTime;
      this.tone(90 + p * 120, t, 0.16, { gain: 0.22, bus: this.sfxBus, slide: 0.6 });
      this.noiseBurst(t, 0.08, { freq: 500, q: 0.8, gain: 0.08 });
    }
    whoosh() {
      if (!this.ensure()) return;
      const ctx = this.ctx, t = ctx.currentTime;
      const src = ctx.createBufferSource(); src.buffer = this._noise;
      const f = ctx.createBiquadFilter(); f.type = 'bandpass'; f.Q.value = 1.2;
      f.frequency.setValueAtTime(400, t); f.frequency.exponentialRampToValueAtTime(2400, t + 0.35);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(0.18, t + 0.12); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.45);
      src.connect(f); f.connect(g); g.connect(this.sfxBus); src.start(t, Math.random()); src.stop(t + 0.5);
    }

    /** the celebration tune; returns its length in seconds */
    endTune(id) {
      if (!this.ensure()) return 0;
      const t0 = this.ctx.currentTime + 0.05;
      const bus = this.sfxBus;
      const bell = (n, t, d = 1.6, g = 0.14) => this.tone(midi(n), t, d, { gain: g, bus, partials: [[1, 1], [2.76, 0.18], [5.4, 0.06]] });
      const pluck = (n, t, d = 0.5, g = 0.16) => this.tone(midi(n), t, d, { gain: g, bus, type: 'triangle', partials: [[1, 1], [2, 0.3]] });
      switch (id) {
        case 'chimes': {
          const seq = [84, 81, 79, 76, 79, 81, 84, 88];
          seq.forEach((n, i) => bell(n, t0 + i * 0.16, 1.8, 0.12));
          [72, 76, 79, 84].forEach((n) => bell(n, t0 + 1.5, 2.6, 0.07));
          return 4;
        }
        case 'birds': {
          const tw = (n, t) => this.tone(midi(n), t, 0.12, { gain: 0.1, bus, slide: 1.25 });
          const mel = [[86, 0], [91, 0.14], [86, 0.28], [93, 0.5], [91, 0.64], [88, 0.78], [86, 1.0], [91, 1.14], [98, 1.4]];
          mel.forEach(([n, dt]) => tw(n, t0 + dt));
          [72, 76, 79].forEach((n, i) => pluck(n, t0 + 1.7 + i * 0.1, 1.4, 0.12));
          return 3.4;
        }
        case 'bubbles': {
          for (let i = 0; i < 10; i++) this.tone(midi(64 + i * 2.4), t0 + i * 0.12, 0.16, { gain: 0.16, bus, slide: 2.2 });
          [76, 79, 84].forEach((n) => bell(n, t0 + 1.35, 2, 0.09));
          return 3.4;
        }
        default: { // tada parade
          const mel = [[67, 0, 0.2], [72, 0.15, 0.2], [76, 0.3, 0.2], [79, 0.45, 0.45], [76, 0.75, 0.2], [79, 0.9, 0.2], [84, 1.05, 1.2]];
          mel.forEach(([n, dt, d]) => pluck(n, t0 + dt, d + 0.3, 0.17));
          [60, 64, 67, 72].forEach((n) => this.tone(midi(n), t0 + 1.05, 1.8, { gain: 0.06, bus, type: 'triangle' }));
          for (let i = 0; i < 6; i++) bell(96 + (i % 3) * 3, t0 + 1.1 + i * 0.09, 0.6, 0.04);
          this.noiseBurst(t0 + 1.05, 0.5, { freq: 6000, q: 0.5, gain: 0.05 });
          return 3;
        }
      }
    }

    preview(kind, id) {
      this.ensure();
      if (kind === 'end') { this.stopMusic(0.2); return this.endTune(id); }
      this.startMusic(id);
      clearTimeout(this._previewT);
      this._previewT = setTimeout(() => this.stopMusic(), 5000);
    }

    say(text) {
      try {
        if (!('speechSynthesis' in window)) return;
        speechSynthesis.cancel();
        const u = new SpeechSynthesisUtterance(text);
        u.rate = 0.9; u.pitch = 1.25; u.volume = Math.min(1, this.volume + 0.2);
        speechSynthesis.speak(u);
      } catch (e) { /* speech is optional */ }
    }
  }

  GC.Sound = new Sound();
  GC.MUSIC = MUSIC;
  GC.END_SOUNDS = ENDS;
})();
