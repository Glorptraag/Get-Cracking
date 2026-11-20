/* Get Cracking — recorded sounds.
 *
 * Real animal calls, two sound effects and a voice saying "It's a Fox!" for every
 * friend, generated once with ElevenLabs (tools/gen-sounds.js, tools/gen-voice.js,
 * tools/pick-sounds.js) and shipped as small MP3s in sounds/. Nothing is fetched
 * from anywhere but this app's own folder, and the service worker caches them.
 *
 * Every recorded sound has a synthesised stand-in (band.js, audio.js) that plays
 * until the recording has loaded, or forever when files can't be fetched (the app
 * opened straight from disk). So recordings only ever make it sound better.
 *
 *   GC.Samples.load(ctx)       start loading the animal calls (after the first tap)
 *   GC.Samples.want(ctx, key)  load one more, e.g. 'voice/fox' just before it's needed
 *   GC.Samples.get(key)        decoded AudioBuffer, or null
 */
(function () {
  'use strict';
  const GC = window.GC;
  const BASE = 'sounds/';
  const buffers = {};
  const pending = {};
  let index = null, loading = null;

  /** decode with the callback form too: older Safari has no promise version */
  const decode = (ctx, data) => new Promise((resolve, reject) => {
    const p = ctx.decodeAudioData(data, resolve, reject);
    if (p && p.catch) p.catch(reject);
  });

  function want(ctx, key) {
    if (buffers[key]) return Promise.resolve(buffers[key]);
    if (pending[key]) return pending[key];
    if (!ctx || location.protocol === 'file:') return Promise.resolve(null);
    pending[key] = fetch(BASE + key + '.mp3')
      .then((r) => (r.ok ? r.arrayBuffer() : Promise.reject(new Error(r.status))))
      .then((data) => decode(ctx, data))
      .then((buf) => (buffers[key] = buf))
      .catch(() => null);
    return pending[key];
  }

  function load(ctx) {
    if (loading) return loading;
    if (!ctx || location.protocol === 'file:' || !window.fetch) return (loading = Promise.resolve(null));
    loading = fetch(BASE + 'index.json')
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(r.status))))
      .then((idx) => {
        index = idx;
        // one at a time, so decoding never competes with the hatch animation for long:
        // the animal calls, then Egg karaoke's band and every friend's singing voice
        // (each friend's extra sound is fetched when it hatches)
        const k = idx.karaoke || {};
        const keys = Object.keys(idx.calls)
          .concat(Object.keys(k.inst || {}).map((id) => 'karaoke/inst/' + id))
          .concat(Object.keys(k.sing || {}).map((id) => 'karaoke/sing/' + id));
        return keys.reduce((p, id) => p.then(() => want(ctx, id)), Promise.resolve());
      })
      .catch(() => null);
    return loading;
  }

  GC.Samples = {
    load, want,
    get: (key) => buffers[key] || null,
    has: (key) => !!buffers[key],
    get index() { return index; },
  };
})();
