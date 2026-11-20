/* Get Cracking — Egg karaoke, the default hatching song.
 *
 * The friend who just hatched is the singer. It sings an original tune with its
 * own recorded voice (sounds/karaoke/sing/<id>.mp3, pitched note by note), puts
 * its second sound (sounds/karaoke/extra/<id>.mp3: a purr, a snort, a splash)
 * into the gaps, duets with itself in the chorus and ends on its full call.
 * The band behind it suits the friend's world, and its chirps and tones are
 * always in the song's key:
 *
 *   meadow    ukulele, upright bass, claps, egg shaker, glockenspiel, slide whistle, cheeps
 *   woodland  harp, upright bass, wood block, shaker, flute, birdsong trills
 *   jungle    marimba, tuba, bongos, shaker, steel pan, parrot whistles
 *   water     kalimba, upright bass, soft snare, hi-hat, glockenspiel, bubble bloops
 *   magic     piano, tuba, snare, hi-hat, glockenspiel, harp, sparkles
 *
 * Every instrument is a single ElevenLabs-recorded note (sounds/karaoke/inst/),
 * pitched to each note here, so the band is always in time and in tune. Anything
 * not loaded yet (or the app opened from disk) is played by the synthesised kit
 * in band.js instead, so the song always works.
 *
 *   intro (count-in, a hello chirp) → verse: two sung lines, each answered
 *   (its own extra sound, then the band's chirp) → chorus: sung with a harmony
 *   → stop! the friend's big call → ta-da, sung.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const P = GC.Sound.constructor.prototype;
  const { FRIEND_CALL, playCall, lenOf, below } = GC.Band;
  const midi = (n) => 440 * Math.pow(2, (n - 69) / 12);
  const DIR = 'karaoke/';

  /* -------------------------------------------------------------- friends
   * world, then the synthesised stand-in voice: [kind in band.js k.say, Hz]. */
  const FRIENDS = {
    chick: ['meadow', 'cheep', 2400], duckling: ['meadow', 'quack', 380], penguin: ['water', 'quack', 450],
    owl: ['woodland', 'hoot', 400], hamster: ['meadow', 'squeak', 2000], bunny: ['meadow', 'squeak', 1500],
    fox: ['woodland', 'woof', 600], kitten: ['meadow', 'meow', 650], bearcub: ['woodland', 'roar', 160],
    panda: ['jungle', 'baa', 420], frog: ['water', 'croak', 170], turtle: ['water', 'bloop', 700],
    dino: ['magic', 'roar', 140], dragon: ['magic', 'roar', 150], mouse: ['meadow', 'squeak', 2800],
    piglet: ['meadow', 'oink', 210], koala: ['jungle', 'oink', 140], raccoon: ['woodland', 'squeak', 2200],
    tiger: ['jungle', 'roar', 180], lion: ['jungle', 'roar', 170], calf: ['meadow', 'moo', 180],
    lamb: ['meadow', 'baa', 420], fawn: ['woodland', 'meow', 750], hedgehog: ['woodland', 'squeak', 2300],
    otter: ['water', 'squeak', 1800], seal: ['water', 'ork', 300], axolotl: ['water', 'bloop', 900],
    bat: ['woodland', 'squeak', 3000], mole: ['woodland', 'squeak', 2000], monkey: ['jungle', 'ooh', 450],
    elephant: ['jungle', 'trumpet', 520], squirrel: ['woodland', 'squeak', 2500], puppy: ['meadow', 'woof', 300],
    unicorn: ['magic', 'neigh', 800], capybara: ['jungle', 'squeak', 1500], redpanda: ['woodland', 'squeak', 2000],
    sloth: ['jungle', 'squeak', 1700], ladybug: ['woodland', 'buzz', 240], snail: ['woodland', 'bloop', 800],
    goat: ['meadow', 'baa', 440],
  };

  /* -------------------------------------------------------------- worlds */
  const WORLDS = {
    meadow: { bpm: 124, kick: 'kick', back: 'clap', tick: 'shaker', bass: 'bass', bassStyle: 'walk', comp: 'uke', compStyle: 'strum', sparkle: 'glock', fill: 'uke', chirp: 'cheeps' },
    woodland: { bpm: 116, kick: 'kick', back: 'woodblock', tick: 'shaker', bass: 'bass', bassStyle: 'root5', comp: 'harp', compStyle: 'arp', sparkle: 'flute', fill: 'flute', chirp: 'birds' },
    jungle: { bpm: 128, kick: 'kick', back: 'bongo', tick: 'shaker', bass: 'tuba', bassStyle: 'oompah', comp: 'marimba', compStyle: 'offbeat', sparkle: 'steelpan', fill: 'steelpan', chirp: 'parrot' },
    water: { bpm: 112, kick: 'kick', back: 'snare', backGain: 0.55, tick: 'hat', bass: 'bass', bassStyle: 'root5', comp: 'kalimba', compStyle: 'arp', sparkle: 'glock', fill: 'kalimba', chirp: 'bubbles' },
    magic: { bpm: 120, kick: 'kick', back: 'snare', tick: 'hat', bass: 'tuba', bassStyle: 'root5', comp: 'piano', compStyle: 'block', sparkle: 'glock', fill: 'harp', chirp: 'sparkle' },
  };

  /* ---------------------------------------------------------------- song
   * An original tune in C. ch: [beat, chord, bass root]; mel: [beat, note, beats]. */
  const C = [60, 64, 67], F = [60, 65, 69], G = [59, 62, 67], Am = [57, 60, 64];
  const VERSE = [
    { ch: [[0, C, 36]], mel: [[0, 64, 0.5], [0.5, 64, 0.5], [1, 67, 1], [2, 72, 0.5], [2.5, 69, 0.5], [3, 67, 1]] },
    { ch: [[0, F, 41], [2, G, 43]], mel: [[0, 65, 0.5], [0.5, 65, 0.5], [1, 64, 0.5], [1.5, 62, 0.5], [2, 67, 1]], answer: 'extra' },
    { ch: [[0, C, 36], [2, Am, 45]], mel: [[0, 64, 0.5], [0.5, 64, 0.5], [1, 67, 1], [2, 72, 0.5], [2.5, 74, 0.5], [3, 76, 1]] },
    { ch: [[0, F, 41], [1, G, 43], [2, C, 36]], mel: [[0, 69, 0.5], [0.5, 72, 0.5], [1, 71, 0.5], [1.5, 74, 0.5], [2, 72, 1]], answer: 'chirp' },
  ];
  const CHORUS = [
    { ch: [[0, F, 41], [2, C, 36]], mel: [[0, 72, 1], [1, 72, 0.5], [1.5, 74, 0.5], [2, 76, 1], [3, 72, 1]] },
    { ch: [[0, G, 43], [2, C, 36]], mel: [[0, 74, 0.5], [0.5, 74, 0.5], [1, 71, 0.5], [1.5, 74, 0.5], [2, 72, 2]] },
  ];
  const MEL_MID = 69; // the middle of the tune: an unpitched voice sounds natural here

  /* --------------------------------------------------------- instruments
   * Recorded note when loaded, else the synth kit. Pitched recordings are
   * moved by whole octaves to sit near their natural pitch (a glockenspiel
   * plays where a glockenspiel lives), then tuned by playbackRate. */
  const GAIN = {
    kick: 0.95, snare: 0.5, hat: 0.28, shaker: 0.32, clap: 0.5, bongo: 0.55, woodblock: 0.45,
    bass: 0.8, tuba: 0.68, uke: 0.24, piano: 0.23, marimba: 0.32, glock: 0.26, flute: 0.34,
    harp: 0.28, kalimba: 0.32, steelpan: 0.32, whistle: 0.35, sparkle: 0.4,
  };
  const SING = 1.6; // the singer sits on top of the band: it's karaoke
  const HOME = { bass: 40, tuba: 40, uke: 64, piano: 64, marimba: 64, harp: 64, kalimba: 72, glock: 84, flute: 76, steelpan: 72 };
  const SYN = {
    kick: (k, n, t, d, g) => k.kick(t, 0.5 * g),
    snare: (k, n, t, d, g) => k.snare(t, 0.2 * g),
    hat: (k, n, t, d, g) => k.hat(t, 0.05 * g),
    shaker: (k, n, t, d, g) => k.shaker(t, 0.045 * g),
    clap: (k, n, t, d, g) => k.clap(t, 0.13 * g),
    bongo: (k, n, t, d, g) => k.bongo(t, true, 0.13 * g),
    woodblock: (k, n, t, d, g) => k.woodblock(t, true, 0.08 * g),
    bass: (k, n, t, d, g) => k.bass(n, t, d, 0.22 * g),
    tuba: (k, n, t, d, g) => k.tuba(n, t, d, 0.19 * g),
    uke: (k, n, t, d, g) => k.uke([n], t, 0.05 * g),
    piano: (k, n, t, d, g, o) => k.piano(n, t, d, 0.06 * g, o),
    marimba: (k, n, t, d, g, o) => k.marimba(n, t, 0.08 * g, o),
    glock: (k, n, t, d, g) => k.glock(n, t, 1.1, 0.04 * g),
    flute: (k, n, t, d, g, o) => k.flute(n, t, d, 0.06 * g, o),
    harp: (k, n, t, d, g) => k.harp([n], t, 0, 0.045 * g),
    kalimba: (k, n, t, d, g) => k.xylo(n, t, 0.07 * g),
    steelpan: (k, n, t, d, g) => k.steel(n, t, 0.9, 0.08 * g),
    whistle: (k, n, t, d, g) => k.slideWhistle(t, n, n + 12, 0.4, 0.06 * g),
    sparkle: (k, n, t, d, g) => [0, 4, 7, 12, 16].forEach((x, i) => k.glock(n + x, t + i * 0.055, 0.8, 0.03 * g)),
  };

  function makePlayer(s, k, friendId) {
    const idx = (GC.Samples && GC.Samples.index && GC.Samples.index.karaoke) || { inst: {}, sing: {}, extra: {} };
    const has = (key) => !!(GC.Samples && GC.Samples.has(DIR + key));
    // decide once, at the start, so a song never switches voice halfway through
    const use = {};
    for (const id of Object.keys(SYN)) {
      const info = idx.inst[id];
      if (!info || !has('inst/' + id)) continue;
      const off = info.m == null || HOME[id] == null ? 0 : 12 * Math.round((info.m - HOME[id]) / 12);
      use[id] = { base: info.m, off };
    }
    const [world, synKind, synHz] = FRIENDS[friendId];
    const singInfo = idx.sing[friendId];
    const voice = singInfo && has('sing/' + friendId)
      ? { base: singInfo.m ?? MEL_MID, off: singInfo.m == null ? 0 : 12 * Math.round((singInfo.m - MEL_MID) / 12) }
      : null;
    // synth voice: whole octaves too, so the tune keeps its shape
    const synOff = 12 * Math.round((69 + 12 * Math.log2(synHz / 440) - MEL_MID) / 12);
    const hasExtra = !!idx.extra[friendId] && has('extra/' + friendId);

    const p = {
      world: WORLDS[world], voice: !!voice,
      /** d = how long the note may ring (0 = let a drum ring out) */
      inst(id, n, t, d, g = 1, out) {
        const u = use[id];
        if (!u) { SYN[id](k, n, t, d, g, out || k.ch.comp); return; }
        const rate = u.base == null ? 1 : Math.pow(2, (n + u.off - u.base) / 12);
        s.sample(DIR + 'inst/' + id, t, out || k.ch.comp, { rate, gain: GAIN[id] * g, max: d ? Math.max(d, 0.25) : undefined });
      },
      sing(n, t, d, out, g = 1) {
        const len = Math.max(0.14, d * 0.95);
        if (voice) {
          const rate = Math.pow(2, (n + voice.off - voice.base) / 12);
          s.sample(DIR + 'sing/' + friendId, t, out, { rate, gain: SING * g, max: len });
        } else k.say[synKind](t, midi(n + synOff), synKind === 'cheep' ? Math.min(len, 0.14) : len, out, g);
        if (s.onSing && g >= 1) s.onSing(t - s.ctx.currentTime, len);
      },
      /** its second sound; if that has not loaded, the world's chirp answers instead */
      extra(t, out, chord) {
        if (hasExtra) return s.sample(DIR + 'extra/' + friendId, t, out, { gain: 0.85, max: 1.4 });
        p.chirp(t, chord);
        return 0.5;
      },
      /** tones and chirps that suit the world, always on the chord's notes */
      chirp(t, chord) {
        const hi = chord.map((n) => n + 24), o = k.ch.sparkle;
        switch (p.world.chirp) {
          case 'cheeps':
            k.say.cheep(t, midi(hi[2]), 0.08, o, 0.8); k.say.cheep(t + 0.12, midi(hi[2] + 5), 0.08, o, 0.8);
            p.inst('whistle', 72, t + 0.24, 0, 0.8, o);
            break;
          case 'birds':
            for (let i = 0; i < 6; i++) k.say.cheep(t + i * 0.065, midi(hi[i % 2 ? 2 : 1] + 12 * (i > 3)), 0.05, o, 0.7);
            break;
          case 'parrot':
            k.say.squeak(t, midi(hi[0]), 0.16, o, 0.9); k.say.squeak(t + 0.2, midi(hi[2]), 0.2, o, 0.9);
            p.inst('bongo', 0, t + 0.1, 0, 0.6, k.ch.drums); p.inst('bongo', 0, t + 0.22, 0, 0.5, k.ch.drums);
            break;
          case 'bubbles':
            [0, 1, 2, 0].forEach((j, i) => k.say.bloop(t + i * 0.09, midi(chord[j] + 12 * (1 + (i === 3))), 0.1, o, 0.9));
            break;
          default: // sparkle
            p.inst('sparkle', 0, t, 0, 0.8, o);
            chord.concat(chord[0] + 12).forEach((n, i) => p.inst('glock', n + 12, t + i * 0.07, 0.6, 0.6, o));
        }
      },
    };
    return p;
  }

  /* ------------------------------------------------------------- arrange */
  function arrange(k, s, friendId, spb) {
    const ev = [];
    const at = (beat, fn) => ev.push({ beat, fn });
    const p = makePlayer(s, k, friendId);
    const w = p.world;
    const D = k.ch.drums;

    const groove = (b, full) => {
      for (let x = 0; x < 4; x += 0.5) {
        if (x % 2 === 0) at(b + x, (t) => p.inst(w.kick, 0, t, 0, 1, D));
        if (x === 1 || x === 3) at(b + x, (t) => { p.inst(w.back, 0, t, 0, w.backGain || 1, D); if (full && w.back !== 'clap') p.inst('clap', 0, t, 0, 0.7, D); });
        at(b + x, (t) => p.inst(w.tick, 0, t, 0, x % 1 ? 0.6 : 1, D));
      }
    };
    const bass = (b, root, beats) => {
      const r = root;
      const steps = w.bassStyle === 'walk' ? (beats >= 4 ? [[0, r], [1, r + 4], [2, r + 7], [3, r + 9]] : beats >= 2 ? [[0, r], [1, r + 7]] : [[0, r]])
        : w.bassStyle === 'oompah' ? (beats >= 4 ? [[0, r], [2, r + 7]] : [[0, r]])
          : (beats >= 4 ? [[0, r], [2, r + 7], [3.5, r + 7]] : [[0, r]]);
      for (const [x, n] of steps) at(b + x, (t) => p.inst(w.bass, n, t, spb * 0.9, 1, k.ch.bass));
    };
    const comp = (b, chord, beats) => {
      const st = w.compStyle;
      if (st === 'strum') {
        for (const [x, g] of [[0, 1], [1, 0.7], [1.5, 0.8], [2.5, 0.7], [3, 0.8]]) {
          if (x >= beats) continue;
          at(b + x, (t) => chord.forEach((n, i) => p.inst(w.comp, n, t + i * 0.015, spb * 1.5, g)));
        }
      } else if (st === 'arp') {
        const notes = [chord[0], chord[1], chord[2], chord[0] + 12, chord[2], chord[1], chord[2], chord[0] + 12];
        for (let i = 0; i < beats * 2; i++) at(b + i * 0.5, (t) => p.inst(w.comp, notes[i % 8], t, spb, i % 2 ? 0.7 : 1));
      } else if (st === 'offbeat') {
        for (let x = 0.5; x < beats; x += 1) at(b + x, (t) => [chord[1], chord[2]].forEach((n) => p.inst(w.comp, n, t, spb * 0.5, 0.9)));
      } else { // block chords on the beat, a lighter one on the "and" before the next
        for (let x = 0; x < beats; x += 2) {
          at(b + x, (t) => chord.forEach((n) => p.inst(w.comp, n, t, spb * 1.6, 1)));
          if (x + 1.5 < beats) at(b + x + 1.5, (t) => chord.forEach((n) => p.inst(w.comp, n + 12, t, spb * 0.5, 0.5)));
        }
      }
    };
    const bars = (list, b0, full, sung) => list.forEach((bar, i) => {
      const b = b0 + i * 4;
      groove(b, full);
      bar.ch.forEach(([x, chord, root], j) => {
        const beats = (j + 1 < bar.ch.length ? bar.ch[j + 1][0] : 4) - x;
        bass(b + x, root, beats);
        comp(b + x, chord, beats);
      });
      const chordAt = (x) => bar.ch.filter((c) => c[0] <= x).pop()[1];
      for (const [x, n, d] of bar.mel) sung(b + x, n, d, chordAt(x));
      if (bar.answer === 'extra') at(b + 3, (t) => p.extra(t, k.ch.aR, chordAt(3)));
      if (bar.answer === 'chirp') {
        at(b + 3, (t) => p.chirp(t, chordAt(3)));
        // the band echoes the end of the line, an octave up
        bar.mel.slice(-3).forEach(([, n], j) => at(b + 3 + j * 0.25, (t) => p.inst(w.fill, n + 12, t, spb * 0.4, 0.7, k.ch.lead)));
      }
    });

    // intro: a count-in on the sticks, a hello chirp, the band walks up to the singer
    for (let x = 0; x < 4; x++) at(x, (t) => p.inst('woodblock', 0, t, 0, x === 0 ? 1 : 0.7, D));
    at(1.5, (t) => p.chirp(t, C));
    [60, 64, 67, 72].forEach((n, i) => at(2 + i * 0.5, (t) => p.inst(w.fill, n + 12, t, spb * 0.5, 0.6, k.ch.lead)));
    at(3, (t) => p.inst(w.bass, 43, t, spb * 0.9, 1, k.ch.bass));
    let b = 4;

    // verse: the friend sings, then answers itself and the band chirps back
    bars(VERSE, b, false, (beat, n, d) => at(beat, (t) => p.sing(n, t, d * spb, k.ch.solo)));
    b += VERSE.length * 4;

    // chorus: fuller band, the tune doubled up high, the friend sings a harmony with itself
    at(b, (t) => k.crash(t, 0.1));
    bars(CHORUS, b, true, (beat, n, d, chord) => {
      at(beat, (t) => {
        p.sing(n, t, d * spb, k.ch.solo);
        p.sing(below(n, chord), t + 0.012, d * spb, k.ch.aL, 0.5);
        p.inst(w.sparkle, n + 12, t, d * spb, 0.7, k.ch.sparkle);
      });
    });
    b += CHORUS.length * 4;
    // a chirp in the chorus's last held note
    at(b - 1, (t) => p.chirp(t, C));

    // stop! one band hit, then the friend's own big call on its own
    at(b, (t) => { k.crash(t, 0.12); p.inst(w.kick, 0, t, 0, 1, D); p.inst(w.bass, 36, t, spb, 1, k.ch.bass); C.forEach((n) => p.inst(w.comp, n, t, spb, 1)); });
    const call = FRIEND_CALL[friendId];
    const callLen = lenOf(call);
    const soloAt = b + 1;
    at(soloAt, (t) => { playCall(k, call, t, k.ch.solo); k.strings([60, 64, 67], t, callLen + spb, 0.01); });
    // ta-da: sung, with the whole band, then one last ad-lib
    const end = Math.ceil((soloAt + (callLen + 0.15) / spb) * 2) / 2;
    at(end, (t) => {
      p.sing(67, t, spb * 0.5, k.ch.solo);
      p.inst(w.kick, 0, t, 0, 1, D);
    });
    at(end + 0.5, (t) => {
      p.sing(72, t, spb * 2, k.ch.solo);
      p.sing(64, t + 0.012, spb * 2, k.ch.aL, 0.5);
      k.crash(t, 0.13);
      p.inst(w.kick, 0, t, 0, 1, D);
      p.inst(w.bass, 36, t, spb * 3, 1, k.ch.bass);
      [48, 55, 60, 64, 67, 72].forEach((n, i) => p.inst(w.comp, n, t + i * 0.03, spb * 3, 0.8));
      p.chirp(t + 0.1, C);
    });
    at(end + 2, (t) => p.extra(t, k.ch.aR, C));
    return { ev, beats: end + 2, tail: 2.6, voice: p.voice, world: FRIENDS[friendId][0] };
  }

  /**
   * Egg karaoke for this friend (or a random one: the settings preview). Prefers
   * a friend whose voice has loaded when it has to choose.
   */
  P.karaokeTune = function (friendId) {
    if (!FRIENDS[friendId]) {
      const ids = Object.keys(FRIENDS);
      const ready = ids.filter((id) => GC.Samples && GC.Samples.has(DIR + 'sing/' + id));
      friendId = GC.pick(ready.length ? ready : ids);
    }
    if (this.ctx && GC.Samples) GC.Samples.want(this.ctx, DIR + 'extra/' + friendId);
    const wld = WORLDS[FRIENDS[friendId][0]];
    let meta = null;
    const len = this._celebrate(wld.bpm, (k, spb) => (meta = arrange(k, this, friendId, spb)), { friendCall: FRIEND_CALL[friendId], singer: friendId });
    if (this._celeb && meta) Object.assign(this._celeb, { recorded: meta.voice, world: meta.world });
    return len;
  };

  GC.Karaoke = { FRIENDS, WORLDS, VERSE, CHORUS, DIR };
})();
