/* Get Cracking — Egg karaoke, the default hatching song.
 *
 * A little band plays an original tune, and the friend who just hatched is one
 * of the players. The tune is carried by instruments and passed around: the
 * lead instrument plays the first verse line, a second instrument takes the
 * next, and in the chorus everyone plays, with a counter-melody and sparkle
 * on top. The friend's own recorded sound (sounds/karaoke/sing/<id>.mp3) is one
 * more part in the band, and what it does with it depends on the sound:
 *   sings   a call that holds a clear note (a meow, a moo, a hoot) sings in tune.
 *           Like real karaoke, the whole song moves to that friend's key, so its
 *           voice is only ever nudged a few notes and still sounds like itself.
 *   plays   a sound that is not a note (a quack, a grunt, a sniff, a turtle's
 *           shell knock, a snail's squelch, a bunny's thump) is never re-pitched:
 *           the friend plays it as it is, in time, like a percussion instrument.
 * Which one is decided from the recording by tools/pick-karaoke.js (a pitch in
 * sounds/index.json = sings). Either way the friend plays:
 *   - off-beat stabs through the verse, with its second sound (a purr, a
 *     snort, a splash: sounds/karaoke/extra/<id>.mp3) and the world's chirps
 *     answering in the gaps
 *   - in the chorus it sings the hook together with the lead instrument
 *   - one short solo break (its full call), then it joins the "ta-da"
 * Each world has its own band, and its chirps and tones are always in key:
 *
 *   meadow    piano lead, flute, ukulele, upright bass, claps, egg shaker, wood block, glockenspiel, cheeps + slide whistle
 *   woodland  flute lead, kalimba, harp, upright bass, wood block, shaker, glockenspiel, birdsong trills
 *   jungle    steel pan lead, marimba, tuba, bongos, shaker, wood block, glockenspiel, parrot whistles
 *   water     kalimba lead, glockenspiel, piano, upright bass, soft snare, hi-hat, flute, bubble bloops
 *   magic     harp lead, flute, piano, tuba, snare, hi-hat, glockenspiel, sparkles
 *
 * Every instrument is a single ElevenLabs-recorded note (sounds/karaoke/inst/),
 * pitched to each note here, so the band is always in time and in tune. Anything
 * not loaded yet (or the app opened from disk) is played by the synthesised kit
 * in band.js instead, so the song always works.
 *
 *   intro (count-in, hello) → verse (lead, then the second instrument, with the
 *   friend's stabs and answers) → chorus (everyone, the friend on the hook)
 *   → stop! the friend's solo break → ta-da.
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
    owl: ['woodland', 'hoot', 400], hamster: ['meadow', 'squeak', 2000], bunny: ['meadow', 'bloop', 260],
    fox: ['woodland', 'woof', 600], kitten: ['meadow', 'meow', 650], bearcub: ['woodland', 'roar', 160],
    panda: ['jungle', 'baa', 420], frog: ['water', 'croak', 170], turtle: ['water', 'bloop', 500],
    dino: ['magic', 'roar', 140], dragon: ['magic', 'roar', 150], mouse: ['meadow', 'squeak', 2800],
    piglet: ['meadow', 'oink', 210], koala: ['jungle', 'oink', 140], raccoon: ['woodland', 'squeak', 2200],
    tiger: ['jungle', 'roar', 180], lion: ['jungle', 'roar', 170], calf: ['meadow', 'moo', 180],
    lamb: ['meadow', 'baa', 420], fawn: ['woodland', 'meow', 750], hedgehog: ['woodland', 'squeak', 2300],
    otter: ['water', 'squeak', 1800], seal: ['water', 'ork', 300], axolotl: ['water', 'bloop', 800],
    bat: ['woodland', 'squeak', 3000], mole: ['woodland', 'sniff', 2600], monkey: ['jungle', 'ooh', 450],
    elephant: ['jungle', 'trumpet', 520], squirrel: ['woodland', 'squeak', 2500], puppy: ['meadow', 'woof', 300],
    unicorn: ['magic', 'neigh', 800], capybara: ['jungle', 'squeak', 1500], redpanda: ['woodland', 'squeak', 2000],
    sloth: ['jungle', 'squeak', 1700], ladybug: ['woodland', 'buzz', 240], snail: ['woodland', 'bloop', 700],
    goat: ['meadow', 'baa', 440],
  };

  /* -------------------------------------------------------------- worlds */
  /* lead and second carry the tune; comp, bass, sparkle and the drums fill out the band */
  const WORLDS = {
    meadow: { bpm: 124, lead: 'piano', second: 'flute', comp: 'uke', compStyle: 'strum', bass: 'bass', bassStyle: 'walk', sparkle: 'glock', kick: 'kick', back: 'clap', tick: 'shaker', perc: 'woodblock', chirp: 'cheeps' },
    woodland: { bpm: 116, lead: 'flute', second: 'kalimba', comp: 'harp', compStyle: 'arp', bass: 'bass', bassStyle: 'root5', sparkle: 'glock', kick: 'kick', back: 'woodblock', tick: 'shaker', chirp: 'birds' },
    jungle: { bpm: 128, lead: 'steelpan', second: 'marimba', comp: 'marimba', compStyle: 'offbeat', bass: 'tuba', bassStyle: 'oompah', sparkle: 'glock', kick: 'kick', back: 'bongo', tick: 'shaker', perc: 'woodblock', chirp: 'parrot' },
    water: { bpm: 112, lead: 'kalimba', second: 'glock', comp: 'piano', compStyle: 'arp', bass: 'bass', bassStyle: 'root5', sparkle: 'flute', kick: 'kick', back: 'snare', backGain: 0.55, tick: 'hat', chirp: 'bubbles' },
    magic: { bpm: 120, lead: 'harp', second: 'flute', comp: 'piano', compStyle: 'block', bass: 'tuba', bassStyle: 'root5', sparkle: 'glock', kick: 'kick', back: 'snare', tick: 'hat', chirp: 'sparkle' },
  };

  /* ---------------------------------------------------------------- song
   * An original tune in C. ch: [beat, chord, bass root]; mel: [beat, note, beats]
   * is the tune, which the band plays softly as a guide. voice is what the friend
   * sings: the same tune with one syllable per beat, because an animal's call is
   * about half a second long and cutting it shorter makes it stutter. */
  const C = [60, 64, 67], F = [60, 65, 69], G = [59, 62, 67], Am = [57, 60, 64];
  const VERSE = [
    { ch: [[0, C, 36]], mel: [[0, 64, 0.5], [0.5, 64, 0.5], [1, 67, 1], [2, 72, 0.5], [2.5, 69, 0.5], [3, 67, 1]],
      voice: [[0, 64, 1], [1, 67, 1], [2, 72, 1], [3, 67, 1]] },
    { ch: [[0, F, 41], [2, G, 43]], mel: [[0, 65, 0.5], [0.5, 65, 0.5], [1, 64, 0.5], [1.5, 62, 0.5], [2, 67, 1]],
      voice: [[0, 65, 1], [1, 62, 1], [2, 67, 1]], answer: 'extra' },
    { ch: [[0, C, 36], [2, Am, 45]], mel: [[0, 64, 0.5], [0.5, 64, 0.5], [1, 67, 1], [2, 72, 0.5], [2.5, 74, 0.5], [3, 76, 1]],
      voice: [[0, 64, 1], [1, 67, 1], [2, 72, 1], [3, 76, 1]] },
    { ch: [[0, F, 41], [1, G, 43], [2, C, 36]], mel: [[0, 69, 0.5], [0.5, 72, 0.5], [1, 71, 0.5], [1.5, 74, 0.5], [2, 72, 1]],
      voice: [[0, 69, 1], [1, 71, 1], [2, 72, 1]], answer: 'chirp' },
  ];
  const CHORUS = [
    { ch: [[0, F, 41], [2, C, 36]], mel: [[0, 72, 1], [1, 72, 0.5], [1.5, 74, 0.5], [2, 76, 1], [3, 72, 1]],
      voice: [[0, 72, 1], [1, 74, 1], [2, 76, 1], [3, 72, 1]] },
    { ch: [[0, G, 43], [2, C, 36]], mel: [[0, 74, 0.5], [0.5, 74, 0.5], [1, 71, 0.5], [1.5, 74, 0.5], [2, 72, 2]],
      voice: [[0, 74, 1], [1, 71, 1], [2, 72, 2]] },
  ];
  const MEL_MID = 69; // the middle of the tune, where the synthesised stand-in voices sit
  /* The friend's own notes run from the G of its verse stabs to the E at the top
   * of the hook. The song is moved (KEY_LO..KEY_HI semitones) so the middle of
   * that range lands on the pitch of the friend's own call. */
  const PART_MID = 71.5, KEY_LO = -7, KEY_HI = 4;
  const keyFor = (pitch) => {
    let k = (((pitch - PART_MID) % 12) + 12) % 12; // 0..12
    if (k > KEY_HI + 0.5) k -= 12;
    return Math.max(KEY_LO, Math.min(KEY_HI, Math.round(k)));
  };
  const FLOOR = { bass: 31, tuba: 31 }; // a low key must not push the bass below what a small speaker can play

  /* --------------------------------------------------------- instruments
   * Recorded note when loaded, else the synth kit. Pitched recordings are
   * moved by whole octaves to sit near their natural pitch (a glockenspiel
   * plays where a glockenspiel lives), then tuned by playbackRate. */
  const GAIN = {
    kick: 0.95, snare: 0.5, hat: 0.28, shaker: 0.32, clap: 0.5, bongo: 0.55, woodblock: 0.45,
    bass: 0.85, tuba: 0.72, uke: 0.27, piano: 0.27, marimba: 0.36, glock: 0.28, flute: 0.38,
    harp: 0.32, kalimba: 0.36, steelpan: 0.36, whistle: 0.35, sparkle: 0.4,
  };
  const SING = 1.3;  // the friend's voice is one part in the band, level with the instruments
  const LEAD = 1.35; // whichever instrument has the tune sits a little forward
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

  /** chirp kinds a pack adds for its world: CHIRPS[name] = (p, k, t, chord, hi, out).
   * Play only chord notes (+ p.key) so it stays in key, e.g. p.inst('glock', hi[0], t, 0.6, 0.6, out). */
  const CHIRPS = {};

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
    // a recorded call with a pitch sings (and sets the key); one without is played as it is
    const rec = singInfo && has('sing/' + friendId);
    const sings = rec && singInfo.m != null;
    const key = sings ? keyFor(singInfo.m) : 0;
    const voice = sings ? { base: singInfo.m, off: 12 * Math.round((singInfo.m - (PART_MID + key)) / 12) } : null;
    const role = sings ? 'sings' : rec ? 'plays' : 'synth';
    // synth voice: whole octaves too, so the tune keeps its shape
    const synOff = 12 * Math.round((69 + 12 * Math.log2(synHz / 440) - MEL_MID) / 12);
    const hasExtra = !!idx.extra[friendId] && has('extra/' + friendId);

    const p = {
      world: WORLDS[world], voice: !!rec, role, key,
      /** d = how long the note may ring (0 = let a drum ring out) */
      inst(id, n, t, d, g = 1, out) {
        const u = use[id];
        n += key;
        if (n < FLOOR[id]) n += 12;
        if (!u) { SYN[id](k, n, t, d, g, out || k.ch.comp); return; }
        const rate = u.base == null ? 1 : Math.pow(2, (n + u.off - u.base) / 12);
        s.sample(DIR + 'inst/' + id, t, out || k.ch.comp, { rate, gain: GAIN[id] * g, max: d ? Math.max(d, 0.25) : undefined });
      },
      /** one sung syllable: it rings for as long as it naturally lasts, overlapping
       *  the next by a touch (legato), and is only faded (gently, never chopped)
       *  if the call is longer than that */
      sing(n, t, d, out, g = 1) {
        const len = d + 0.1;
        if (voice) {
          const rate = Math.pow(2, (n + key + voice.off - voice.base) / 12);
          s.sample(DIR + 'sing/' + friendId, t, out, { rate, gain: SING * g, max: len, fade: 0.12 });
        } else if (rec) {
          // not a note: its own sound, as it is. It only leans a touch up or down
          // with the tune (two semitones at most), the way a drummer moves between toms
          const lean = Math.max(-2, Math.min(2, (n - PART_MID) * 0.35));
          s.sample(DIR + 'sing/' + friendId, t, out, { rate: Math.pow(2, lean / 12), gain: SING * g, max: len, fade: 0.12 });
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
        const hi = chord.map((n) => n + 24 + key), o = k.ch.sparkle;
        if (CHIRPS[p.world.chirp]) { CHIRPS[p.world.chirp](p, k, t, chord, hi, o); return; }
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
            [0, 1, 2, 0].forEach((j, i) => k.say.bloop(t + i * 0.09, midi(chord[j] + key + 12 * (1 + (i === 3))), 0.1, o, 0.9));
            break;
          default: // sparkle
            p.inst('sparkle', 84, t, 0, 0.8, o);
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
      if (w.perc) [1.5, 3.5].forEach((x) => at(b + x, (t) => p.inst(w.perc, 0, t, 0, 0.6, D)));
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
    const L = k.ch.lead, SP = k.ch.sparkle, A = k.ch.aR;
    const melody = (id, b, mel, g, up = 12, out = L) => {
      for (const [x, n, d] of mel) at(b + x, (t) => p.inst(id, n + up, t, d * spb * 1.05, g, out));
    };
    const bars = (list, b0, chorus) => list.forEach((bar, i) => {
      const b = b0 + i * 4;
      groove(b, chorus);
      bar.ch.forEach(([x, chord, root], j) => {
        const beats = (j + 1 < bar.ch.length ? bar.ch[j + 1][0] : 4) - x;
        bass(b + x, root, beats);
        comp(b + x, chord, beats);
      });
      const chordAt = (x) => bar.ch.filter((c) => c[0] <= x).pop()[1];
      const harmony = bar.mel.filter(([, , d]) => d >= 1).map(([x, n, d]) => [x, below(n, chordAt(x)), d]);
      if (!chorus) {
        // the tune passes around the band: the lead's line, then the second instrument's
        const [tune, other] = i < 2 ? [w.lead, w.second] : [w.second, w.lead];
        melody(tune, b, bar.mel, LEAD);
        melody(other, b, harmony, 0.45, 12, SP);
        // the friend: off-beat stabs on the chord, and its answers in the gaps
        at(b + 1, (t) => p.sing(chordAt(1)[2], t, spb * 0.75, A));
        if (!bar.answer) at(b + 3, (t) => p.sing(chordAt(3)[0] + 12, t, spb * 0.75, A));
      } else {
        // everyone: the tune on the lead, a counter-melody, sparkle up high, the friend on the hook
        melody(w.lead, b, bar.mel, LEAD);
        melody(w.second, b, harmony, 0.6, 12, SP);
        melody(w.sparkle, b, bar.mel, 0.4, 24, SP);
        for (const [x, n, d] of bar.voice) at(b + x, (t) => p.sing(n, t, d * spb, k.ch.solo));
      }
      if (bar.answer === 'extra') at(b + 3, (t) => p.extra(t, A, chordAt(3)));
      if (bar.answer === 'chirp') {
        at(b + 3, (t) => p.chirp(t, chordAt(3)));
        // the band echoes the end of the line, an octave up
        bar.mel.slice(-3).forEach(([, n], j) => at(b + 3 + j * 0.25, (t) => p.inst(w.lead, n + 24, t, spb * 0.4, 0.7, SP)));
      }
    });

    // intro: a count-in on the sticks, the band walks up, the friend says hello
    for (let x = 0; x < 4; x++) at(x, (t) => p.inst('woodblock', 0, t, 0, x === 0 ? 1 : 0.7, D));
    at(0, (t) => C.forEach((n) => p.inst(w.comp, n, t, spb * 2, 0.7)));
    at(2, (t) => p.sing(67, t, spb, A));
    [60, 64, 67, 72].forEach((n, i) => at(2 + i * 0.5, (t) => p.inst(w.lead, n + 12, t, spb * 0.5, 0.8, L)));
    at(3, (t) => p.inst(w.bass, 43, t, spb * 0.9, 1, k.ch.bass));
    at(3.5, (t) => p.chirp(t, C));
    let b = 4;

    // verse: the instruments take turns with the tune; the friend plays along
    bars(VERSE, b, false);
    b += VERSE.length * 4;

    // chorus: the whole band, the friend singing the hook with the lead
    at(b, (t) => k.crash(t, 0.1));
    bars(CHORUS, b, true);
    b += CHORUS.length * 4;
    // a chirp in the chorus's last held note
    at(b - 1, (t) => p.chirp(t, C));

    // stop! one band hit, then the friend's solo break: its own full call
    at(b, (t) => { k.crash(t, 0.12); p.inst(w.kick, 0, t, 0, 1, D); p.inst(w.bass, 36, t, spb, 1, k.ch.bass); C.forEach((n) => p.inst(w.comp, n, t, spb, 1)); });
    const call = FRIEND_CALL[friendId];
    const callLen = lenOf(call);
    const soloAt = b + 1;
    at(soloAt, (t) => { playCall(k, call, t, k.ch.solo); k.strings([60, 64, 67].map((n) => n + p.key), t, callLen + spb, 0.01); });
    // ta-da: the whole band, the friend with them, then one last ad-lib
    const end = Math.ceil((soloAt + (callLen + 0.15) / spb) * 2) / 2;
    at(end, (t) => {
      p.sing(67, t, spb, k.ch.solo);
      p.inst(w.lead, 79, t, spb, LEAD, L);
      p.inst(w.kick, 0, t, 0, 1, D);
    });
    at(end + 1, (t) => {
      p.sing(72, t, spb * 2, k.ch.solo);
      p.inst(w.lead, 84, t, spb * 3, LEAD, L);
      p.inst(w.second, 76, t, spb * 3, 0.7, SP);
      k.crash(t, 0.13);
      p.inst(w.kick, 0, t, 0, 1, D);
      p.inst(w.bass, 36, t, spb * 3, 1, k.ch.bass);
      [48, 55, 60, 64, 67, 72].forEach((n, i) => p.inst(w.comp, n, t + i * 0.03, spb * 3, 0.8));
      p.chirp(t + 0.1, C);
    });
    at(end + 2.5, (t) => p.extra(t, A, C));
    return { ev, beats: end + 2.5, tail: 2.6, voice: p.voice, role: p.role, key: p.key, world: FRIENDS[friendId][0] };
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
    if (this._celeb && meta) Object.assign(this._celeb, { recorded: meta.voice, role: meta.role, key: meta.key, world: meta.world });
    return len;
  };

  /* A pack can add an instrument too: SYN[id] (the synth stand-in), GAIN[id], and
   * HOME[id] (the MIDI note it naturally sits around, for pitched ones), plus its
   * recording in sounds/karaoke/inst/<id>.mp3 listed in sounds/index.json. */
  GC.Karaoke = { FRIENDS, WORLDS, VERSE, CHORUS, DIR, keyFor, PART_MID, SYN, GAIN, HOME, CHIRPS };
})();
