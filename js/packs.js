/* Get Cracking — content packs.
 *
 * The 40 friends and 10 worlds are the Classic pack. More packs (js/packs/*.js)
 * add friends, worlds and sounds without editing the core files:
 *
 *   GC.Packs.register({
 *     id: 'aussie', name: 'Aussie Bush', blurb: 'Galahs, wombats and a mole cricket',
 *     icon: 'paw',                       // a drawing in js/icons.js
 *     friends: [{ id: 'galah', name: 'Galah', body: '#f2a3b6', ...parts,
 *                 call: 'galah',          // its solo in the animal bands (GC.Band.CALLS)
 *                 karaoke: ['outback', 'squeak', 2200] }],  // Egg karaoke world + synth stand-in voice
 *     parts:  { back: { galahWings(d, k) { return '<path …/>'; } } },   // GC.Animals.parts
 *     calls:  { galah: { len: 0.5, play: (k, t, o) => k.say.squeak(t, 2200, 0.2, o) } },
 *     scenes: [{ id: 'outback', name: 'Red Centre', … }],              // same shape as js/scenes.js
 *     particles: { gumleaves: (i, x, y, st, r) => '…' },               // GC.Scenes.PARTICLES
 *     worlds: { outback: { bpm: 118, lead: 'marimba', … } },           // GC.Karaoke.WORLDS
 *     chirps: { kooka: (p, k, t, chord, hi, o) => … },                 // GC.Karaoke.CHIRPS
 *   });
 *
 * The web app is free in full: every pack plays here. The App Store app sells
 * one unlock that opens every pack (now and future); `starter` marks what it
 * gives away free (see MONETIZATION.md). Grown-ups can switch packs off in
 * settings (S.packsOff), e.g. Christmas only in December.
 */
(function () {
  'use strict';
  const GC = window.GC;

  const list = [{
    id: 'classic', name: 'Classic friends', blurb: 'The first 40 friends and 10 worlds', icon: 'paw', builtIn: true,
  }];

  function register(pack) {
    if (!pack || !pack.id) throw new Error('a pack needs an id');
    if (list.some((p) => p.id === pack.id)) throw new Error(`pack "${pack.id}" is registered twice`);
    // the contact sheets in tools/ load only some of the app; skip what isn't there
    const { Animals } = GC;
    const Scenes = GC.Scenes || { PARTICLES: {}, add() {} };
    const Band = GC.Band || { CALLS: {}, FRIEND_CALL: {}, missing: true };
    const Karaoke = GC.Karaoke || { WORLDS: {}, CHIRPS: {}, SYN: {}, GAIN: {}, HOME: {}, FRIENDS: {}, missing: true };

    for (const [layer, parts] of Object.entries(pack.parts || {})) {
      if (!Animals.parts[layer]) throw new Error(`${pack.id}: no part layer "${layer}"`);
      Object.assign(Animals.parts[layer], parts);
    }
    Object.assign(Band.CALLS, pack.calls || {});
    Object.assign(Scenes.PARTICLES, pack.particles || {});
    Object.assign(Karaoke.WORLDS, pack.worlds || {});
    Object.assign(Karaoke.CHIRPS, pack.chirps || {});
    for (const [id, inst] of Object.entries(pack.instruments || {})) {
      Karaoke.SYN[id] = inst.syn;
      Karaoke.GAIN[id] = inst.gain == null ? 0.35 : inst.gain;
      if (inst.home != null) Karaoke.HOME[id] = inst.home;
    }

    const friends = pack.friends || [];
    for (const a of friends) {
      if (!Band.missing && (!a.call || !Band.CALLS[a.call])) throw new Error(`${pack.id}/${a.id}: call "${a.call}" is not in GC.Band.CALLS`);
      if (!Karaoke.missing && (!a.karaoke || !Karaoke.WORLDS[a.karaoke[0]])) throw new Error(`${pack.id}/${a.id}: karaoke world "${a.karaoke && a.karaoke[0]}" is unknown`);
      Band.FRIEND_CALL[a.id] = a.call;
      Karaoke.FRIENDS[a.id] = a.karaoke;
    }
    Animals.add(friends, pack.id);
    Scenes.add(pack.scenes || [], pack.id);

    list.push({
      id: pack.id, name: pack.name || pack.id, blurb: pack.blurb || '', icon: pack.icon || 'gift',
      friends: friends.map((a) => a.id), scenes: (pack.scenes || []).map((s) => s.id),
    });
  }

  /** which pack ids are switched on (never none: with everything off, Classic plays) */
  function enabled(off) {
    const on = list.filter((p) => !(off || []).includes(p.id)).map((p) => p.id);
    return on.length ? on : ['classic'];
  }

  GC.Packs = {
    list, register, enabled,
    byId: (id) => list.find((p) => p.id === id),
    friendsIn: (packId) => GC.Animals.list.filter((a) => a.pack === packId),
    scenesIn: (packId) => (GC.Scenes ? GC.Scenes.list : []).filter((s) => s.pack === packId),
  };
})();
