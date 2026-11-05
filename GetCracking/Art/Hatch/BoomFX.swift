import SwiftUI

/// Shell effect "Kaboom".
///
/// A cartoon party-pop: the egg puffs up and jitters, a pale "POW" star
/// flashes behind it, then the shell bursts into ~15 jagged shards that tile
/// the egg exactly. Shards fly out on gravity arcs, spin, bounce once or
/// twice with a squash, skid to a stop; a few stay as rubble, the rest sail
/// off-screen or fade. See ShellFX.swift for the contract.

private let CENTER_Y = -85.0     // egg-local pivot for the whole-egg puff-up
private let PUFF_MS = 200.0      // inflate + jitter before the burst
private let BURST_S = 1.2        // inflation at the moment of bursting
private let GRAV = 2500.0        // px/s²
private let DT = 1.0 / 60
private let MAX_T = 2.15         // s — every shard is done by then
private let BOX = (l: -75.0, r: 75.0, t: -200.0, b: 60.0) // keep-clear box (front layer)

// MARK: geometry

/// The egg outline sampled into a polygon.
private let boomEgg: [Pt] = {
    let segs: [[Pt]] = [
        [(0, -170), (40, -170), (64, -96), (64, -58)],
        [(64, -58), (64, -20), (36, 0), (0, 0)],
        [(0, 0), (-36, 0), (-64, -20), (-64, -58)],
        [(-64, -58), (-64, -96), (-40, -170), (0, -170)],
    ]
    var out: [Pt] = []
    for s in segs {
        for k in 0..<16 {
            let t = Double(k) / 16, u = 1 - t
            let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
            out.append((a * s[0].0 + b * s[1].0 + c * s[2].0 + d * s[3].0, a * s[0].1 + b * s[1].1 + c * s[2].1 + d * s[3].1))
        }
    }
    return out
}()

private func inPoly(_ x: Double, _ y: Double, _ poly: [Pt]) -> Bool {
    var c = false
    var j = poly.count - 1
    for i in 0..<poly.count {
        let (xi, yi) = poly[i], (xj, yj) = poly[j]
        if (yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi { c.toggle() }
        j = i
    }
    return c
}

private func sgn(_ v: Double) -> Double { v > 0 ? 1 : v < 0 ? -1 : 0 }

/// n jaggy points strictly between a and b (zig-zag across the line).
private func jag(_ a: Pt, _ b: Pt, _ n: Int, _ amp: Double) -> [Pt] {
    let dx = b.0 - a.0, dy = b.1 - a.1
    var len = hypot(dx, dy)
    if len == 0 { len = 1 }
    let nx = -dy / len, ny = dx / len
    var pts: [Pt] = []
    var sg: Double = GC.rand(0, 1) < 0.5 ? -1 : 1
    for i in 1...n {
        let t = Double(i) / Double(n + 1) + GC.rand(-0.06, 0.06)
        let o = sg * amp * GC.rand(0.55, 1)
        pts.append((a.0 + dx * t + nx * o, a.1 + dy * t + ny * o))
        sg = -sg
    }
    return pts
}

/// A radial / ring split that tiles the whole egg with no gaps: 5 inner
/// pieces around a burst point P, and 10 outer pieces between jagged rays.
/// Every edge polyline is shared by its two neighbours.
private func buildPolys() -> (P: Pt, polys: [[Pt]]) {
    let P: Pt = (GC.rand(-5, 5), GC.rand(-94, -82))
    let K = 10, R = 140.0
    var Q: [Pt] = [], Ang: [Double] = []
    for k in 0..<K {
        let a = -Double.pi / 2 + Double(k) / Double(K) * Double.pi * 2 + GC.rand(-0.13, 0.13)
        let r = (k % 2 == 1 ? 44.0 : 34.0) + GC.rand(-4, 4)
        Ang.append(a)
        Q.append((P.0 + cos(a) * r, P.1 + sin(a) * r * 1.15))
    }
    var spoke: [[Pt]] = []   // P → Q[2j]
    for j in 0..<(K / 2) { spoke.append(jag(P, Q[2 * j], 1, 6)) }
    var ring: [[Pt]] = []    // Q[k] → Q[k+1]
    for k in 0..<K { ring.append(jag(Q[k], Q[(k + 1) % K], 1, 6)) }
    var ray: [[Pt]] = [], oEnd: [Pt] = []   // Q[k] → far outside the egg
    for k in 0..<K {
        let a = Ang[k] + GC.rand(-0.1, 0.1)
        let o: Pt = (P.0 + cos(a) * R, P.1 + sin(a) * R * 1.2)
        oEnd.append(o)
        ray.append(jag(Q[k], o, 3, 7))
    }
    var polys: [[Pt]] = []
    for j in 0..<(K / 2) {
        let a = 2 * j, b = 2 * j + 1, c = (2 * j + 2) % K
        var poly: [Pt] = [P]
        poly += spoke[j]
        poly.append(Q[a]); poly += ring[a]
        poly.append(Q[b]); poly += ring[b]
        poly.append(Q[c]); poly += Array(spoke[(j + 1) % (K / 2)].reversed())
        polys.append(poly)
    }
    for k in 0..<K {
        let k2 = (k + 1) % K
        let am = (Ang[k] + (k2 != 0 ? Ang[k2] : Ang[k2] + Double.pi * 2)) / 2
        let mid: Pt = (P.0 + cos(am) * R * 1.05, P.1 + sin(am) * R * 1.25)
        var poly: [Pt] = [Q[k]]
        poly += ray[k]
        poly += [oEnd[k], mid, oEnd[k2]]
        poly += Array(ray[k2].reversed())
        poly.append(Q[k2])
        poly += Array(ring[k].reversed())
        polys.append(poly)
    }
    return (P, polys)
}

private struct Stat {
    var cx: Double, cy: Double, area: Double
    var pts: [Pt]
    var r: Double
}

/// Visible (inside-the-egg) centroid, area and sample points per polygon.
private func measure(_ polys: [[Pt]], _ egg: [Pt]) -> [Stat] {
    var sx = [Double](repeating: 0, count: polys.count), sy = sx
    var cnt = [Int](repeating: 0, count: polys.count)
    var raw = [[Pt]](repeating: [], count: polys.count)
    let step = 4.0
    var y = -170 + step / 2
    while y < 0 {
        var x = -64 + step / 2
        while x < 64 {
            if inPoly(x, y, egg) {
                for i in 0..<polys.count where inPoly(x, y, polys[i]) {
                    sx[i] += x; sy[i] += y; cnt[i] += 1; raw[i].append((x, y))
                    break
                }
            }
            x += step
        }
        y += step
    }
    return (0..<polys.count).map { i in
        let n = Double(cnt[i])
        let cx = n > 0 ? sx[i] / n : 0, cy = n > 0 ? sy[i] / n : CENTER_Y
        let pts = raw[i].map { ($0.0 - cx, $0.1 - cy) }
        var r = 4.0
        for p in pts { r = max(r, hypot(p.0, p.1)) }
        // keep the extreme points only (enough to find the lowest point when rotated)
        var hull: [Pt] = []
        for (k, p) in pts.enumerated() where k % 3 == 0 || hypot(p.0, p.1) > r * 0.6 { hull.append(p) }
        return Stat(cx: cx, cy: cy, area: n * step * step, pts: hull.isEmpty ? [(0, 0)] : hull, r: r + 2.5)
    }
}

/// lowest (max y) offset of the shard's points when rotated by deg
private func lowest(_ pts: [Pt], _ deg: Double) -> Double {
    let a = deg * Double.pi / 180, s = sin(a), c = cos(a)
    var m = -1e9
    for (x, y) in pts { let v = x * s + y * c; if v > m { m = v } }
    return m + 2 // half the outline
}

// MARK: physics

private func inflateAt(_ t: Double) -> Double {
    let k = max(0, 1 - t / 0.14)
    return 1 + (BURST_S - 1) * k * k
}

private struct Frame { var t: Double, X: Double, Y: Double, R: Double, sx: Double, sy: Double }
private struct Event { var t: Double, X: Double, impact: Double, n: Int }
private struct Vel { var vx: Double, vy: Double, maxB: Int, w: Double }
private struct Sim {
    var frames: [Frame]
    var events: [Event]
    var resting: Bool, out: Bool
    var X: Double, Y: Double, depth: Double
}

private final class Shard {
    let pts: [Pt], poly: [Pt]
    let cx: Double, cy: Double, area: Double, r: Double, x0: Double, y0: Double
    let inner: Bool
    var keeper = false
    var layer: VNode?
    var sim: Sim?
    var stay = false
    var shadow: VNode?
    var piece: Piece?

    init(pts: [Pt], poly: [Pt], cx: Double, cy: Double, area: Double, r: Double, x0: Double, y0: Double, inner: Bool) {
        self.pts = pts; self.poly = poly; self.cx = cx; self.cy = cy; self.area = area
        self.r = r; self.x0 = x0; self.y0 = y0; self.inner = inner
    }
}

/// Simulate one shard: frames (absolute egg-local centroid), bounces, end state.
private func simulate(_ sh: Shard, _ v: Vel, _ depth: Double) -> Sim {
    var X = sh.x0, Y = sh.y0, vx = v.vx, vy = v.vy, R = 0.0, w = v.w
    var bounces = 0, resting = false, out = false, sqA = 0.0, sqT = 1.0
    var frames: [Frame] = [], events: [Event] = []
    let rest = [0.46, 0.34, 0.25]
    var i = 0
    while Double(i) * DT <= MAX_T {
        let t = Double(i) * DT
        let s = inflateAt(t)
        // squash after an impact: flat → tall → settle
        var qx = 1.0, qy = 1.0
        if sqT < 0.12 {
            let p = sqT / 0.12
            let k: Double = p < 0.35 ? 1 : p < 0.7 ? -0.35 : 0.1
            qx = 1 + sqA * k
            qy = 1 - sqA * k
        }
        let lowNow = lowest(sh.pts, R)
        let planted: Double = (resting || sqT < 0.12) ? 1 : 0
        frames.append(Frame(t: t, X: X, Y: Y + lowNow * (1 - qy * s) * planted, R: R, sx: s * qx, sy: s * qy))
        if out { break }
        sqT += DT
        if !resting { vy += GRAV * DT }
        X += vx * DT; Y += vy * DT; R += w * DT
        let lo = lowest(sh.pts, R)
        if !resting && vy > 0 && Y + lo >= depth {
            Y = depth - lo
            events.append(Event(t: t + DT, X: X, impact: vy, n: bounces))
            bounces += 1
            sqA = min(0.28, vy / 3800)
            sqT = 0
            let e = rest[min(bounces - 1, 2)]
            if bounces >= v.maxB || vy * e < 230 { resting = true; vy = 0 } else { vy = -vy * e }
            vx *= 0.7
            w = w * GC.rand(0.35, 0.6) * (GC.rand(0, 1) < 0.3 ? -1 : 1)
        }
        if resting {
            Y = depth - lo
            let f = 900 * DT
            vx = abs(vx) <= f ? 0 : vx - sgn(vx) * f
            w *= 0.86
            if vx == 0 && abs(w) < 8 && sqT > 0.14 {
                frames.append(Frame(t: t + DT, X: X, Y: Y, R: R, sx: 1, sy: 1))
                break
            }
        }
        if abs(X) - sh.r > 330 || Y + sh.r < -470 { out = true }
        i += 1
    }
    return Sim(frames: frames, events: events, resting: resting, out: out, X: X, Y: Y, depth: depth)
}

/// do any frames after tFrom put the shard inside the keep-clear box?
private func crossesBox(_ frames: [Frame], _ r: Double, _ tFrom: Double) -> Bool {
    for f in frames where f.t >= tFrom {
        if f.X + r > BOX.l && f.X - r < BOX.r && f.Y + r > BOX.t && f.Y - r < BOX.b { return true }
    }
    return false
}

/// the simulated state at time `sec`, linearly interpolated between frames
private func frameAt(_ frames: [Frame], _ sec: Double) -> Frame {
    guard let first = frames.first else { return Frame(t: 0, X: 0, Y: 0, R: 0, sx: 1, sy: 1) }
    if sec <= first.t { return first }
    var i = min(frames.count - 1, Int(sec / DT))
    while i > 0 && frames[i].t > sec { i -= 1 }
    while i < frames.count - 1 && frames[i + 1].t < sec { i += 1 }
    if i >= frames.count - 1 { return frames[frames.count - 1] }
    let a = frames[i], b = frames[i + 1]
    let u = b.t > a.t ? (sec - a.t) / (b.t - a.t) : 1
    func l(_ p: Double, _ q: Double) -> Double { p + (q - p) * u }
    return Frame(t: sec, X: l(a.X, b.X), Y: l(a.Y, b.Y), R: l(a.R, b.R), sx: l(a.sx, b.sx), sy: l(a.sy, b.sy))
}

// MARK: decorations

private func starPath(_ n: Int, _ r1: Double, _ r2: Double) -> String {
    var d = ""
    for i in 0..<(n * 2) {
        let a = Double(i) / Double(n * 2) * Double.pi * 2 + GC.rand(-0.06, 0.06)
        let r = (i % 2 == 1 ? r2 : r1) * GC.rand(0.85, 1.12)
        d += (i == 0 ? "M" : "L") + "\(cos(a) * r),\(sin(a) * r * 1.08)"
    }
    return d + "Z"
}

/// a dust puff that also drifts outward
@MainActor
private func driftPuff(_ ctx: ShellCtx, _ x: Double, _ y: Double, _ r: Double, _ dx: Double, _ dy: Double, _ layer: VNode) {
    let outer = nGroup([], tr(x, y))
    layer.add(outer)
    let inner = nGroup()
    outer.add(inner)
    ctx.puff(0, 0, r, layer: inner)
    ctx.start(inner, [KF([.translate(0, 0)]), KF([.translate(dx, dy)])], duration: 600, easing: Ease(0.2, 0.8, 0.4, 1), fill: true)
    ctx.later(620) { outer.removeFromParent() }
}

// MARK: the effect

struct BoomFX: ShellEffect {
    let id = "boom", name = "Kaboom", icon = "💥"

    func run(_ ctx: ShellCtx) async {
        let (P, polys) = buildPolys()
        let stats = measure(polys, boomEgg)

        if ctx.reduce {
            await reduced(ctx, polys, stats, P)
            return
        }

        // 1. puff up: a whole-egg piece inflates and jitters
        let whole = ctx.piece([(-90, -200), (90, -200), (90, 20), (-90, 20)], cx: 0, cy: CENTER_Y)
        func inflateTo(_ sx: Double, _ sy: Double, _ jx: Double) -> [TOp] {
            [.translate(jx, -(sy - 1) * -CENTER_Y), .scale(sx, sy)]
        }
        ctx.start(whole.el, [
            KF(inflateTo(0.9, 1.12, 0)),
            KF(inflateTo(1.1, 1.0, -3), offset: 0.22),
            KF(inflateTo(1.06, 1.13, 3), offset: 0.4),
            KF(inflateTo(1.17, 1.08, -3), offset: 0.56),
            KF(inflateTo(1.13, 1.2, 3), offset: 0.7),
            KF(inflateTo(1.23, 1.17, -2), offset: 0.85),
            KF(inflateTo(BURST_S, BURST_S, 0)),
        ], duration: PUFF_MS, easing: .easeOut, fill: true)

        // pale "POW" starburst behind (back layer, behind everything else)
        let powG = nGroup([], tr(0, CENTER_Y - 6))
        ctx.back.insert(powG, at: 0)
        let star = nGroup([nPath(starPath(12, 150, 92), St.o(5).filled("#fff6c9")), nPath(starPath(9, 92, 58), .f("#ffffff"))])
        star.opacity = 0
        powG.add(star)
        ctx.start(star, [
            KF([.s(0.25), .rotate(-8)], opacity: 0),
            KF([.s(0.8), .rotate(-2)], offset: 0.2, opacity: 1),
            KF([.s(1.18), .rotate(4)], offset: 0.45, opacity: 1),
            KF([.s(1.06), .rotate(6)], offset: 0.62, opacity: 0.95),
            KF([.s(1.3), .rotate(10)], opacity: 0),
        ], duration: 640, delay: PUFF_MS - 90, easing: .easeOut, fill: true)
        ctx.later(640 + PUFF_MS - 90) { powG.removeFromParent() }

        // 2. pre-build the shards (hidden) while the egg puffs up.
        // Where each shard's centroid sits on the inflated egg (scaled about
        // (0, CENTER_Y), then lifted so the base stays on the ground).
        var shards: [Shard] = []
        for (i, poly) in polys.enumerated() {
            let s = stats[i]
            guard s.area > 40 else { continue }
            let x0 = s.cx * BURST_S
            let y0 = CENTER_Y + (s.cy - CENTER_Y) * BURST_S - (BURST_S - 1) * -CENTER_Y
            shards.append(Shard(pts: s.pts, poly: poly, cx: s.cx, cy: s.cy, area: s.area, r: s.r * BURST_S, x0: x0, y0: y0, inner: i < 5))
        }

        // choose a few keepers: three each side, biggest non-top shards first
        func side(_ s: Shard) -> Double { s.cx - P.0 >= 0 ? 1 : -1 }
        let cand = shards.filter { !$0.inner && $0.cy > -125 }.sorted { $0.area > $1.area }
        for sd in [-1.0, 1.0] {
            for s in cand.filter({ side($0) == sd }).prefix(3) { s.keeper = true }
        }

        var keepSlotL = 0, keepSlotR = 0
        for s in shards {
            var dx = s.cx - P.0, dy = s.cy - P.1
            if hypot(dx, dy) < 6 { dx = ctx.rand(-1, 1); dy = -1 }
            let hl = hypot(dx, dy) == 0 ? 1 : hypot(dx, dy)
            let ux = dx / hl, uy = dy / hl
            let sg = side(s)
            var v: Vel
            if s.keeper {
                // land in staggered slots around the friend, 2–3 bounces
                let slot: Int
                if sg < 0 { slot = keepSlotL; keepSlotL += 1 } else { slot = keepSlotR; keepSlotR += 1 }
                let reach = [215.0, 150, 285][slot % 3] + ctx.rand(-15, 15)
                v = Vel(vx: sg * reach * ctx.rand(0.5, 0.65), vy: -ctx.rand(520, 760), maxB: 3, w: 0)
            } else if s.inner {
                // the middle pieces get out of the friend's way fast
                v = Vel(vx: (ux != 0 ? ux : sg) * ctx.rand(380, 560) + sg * 120, vy: -ctx.rand(650, 950) + uy * 150, maxB: 2, w: 0)
            } else if uy < -0.55 {
                // top of the shell rockets up and away
                v = Vel(vx: ux * 260 + sg * ctx.rand(140, 260), vy: -ctx.rand(900, 1150), maxB: 2, w: 0)
            } else {
                v = Vel(vx: sg * ctx.rand(360, 600), vy: -ctx.rand(380, 760) + uy * 200, maxB: 2, w: 0)
            }
            v.w = sgn(v.vx != 0 ? v.vx : 1) * ctx.rand(s.keeper ? 360 : 500, s.keeper ? 720 : 1100)

            // front layer if the path stays clear of the friend; otherwise back
            let fromBox = 0.38 // s after release
            var sim = simulate(s, v, max(ctx.rand(52, 70), s.y0 + 30))
            s.layer = ctx.front
            if crossesBox(sim.frames, s.r, fromBox) || (sim.resting && abs(sim.X) - s.r < 82) {
                sim = simulate(s, v, max(ctx.rand(-15, 36), s.y0 + lowest(s.pts, 0) + 4))
                s.layer = ctx.back
            }
            s.sim = sim
            s.stay = sim.resting && !sim.out && abs(sim.X) + s.r < 250
        }
        // too much rubble? fade the extras (non-keepers first)
        let stayers = shards.filter { $0.stay }.sorted { ($0.keeper ? 1 : 0) > ($1.keeper ? 1 : 0) }
        for s in stayers.dropFirst(7) { s.stay = false }

        // shadows first (so shards draw on top), then shards; back pieces under front ones
        for s in shards {
            let sh = ctx.shadow(0, 0, max(9, min(28, sqrt(s.area) * 0.55)), layer: ctx.back)
            sh.opacity = 0
            s.shadow = sh
        }
        for s in shards {
            let p = ctx.piece(s.poly, layer: s.layer, edge: 5, cx: s.cx, cy: s.cy)
            p.wrap.hidden = true
            s.piece = p
        }

        await ctx.wait(PUFF_MS)

        // 3. KABOOM
        whole.wrap.removeFromParent()
        ctx.release()
        ctx.crack()
        ctx.whoosh()

        // smoke ring bursting outward + a ground dust ring
        for i in 0..<7 {
            let a = Double(i) / 7 * Double.pi * 2 + ctx.rand(-0.2, 0.2)
            let x = cos(a) * 66, y = CENTER_Y + sin(a) * 82
            let layer = abs(x) > 50 ? ctx.front : ctx.back
            let dx = cos(a) * ctx.rand(55, 85), dy = sin(a) * ctx.rand(55, 85)
            driftPuff(ctx, x, y, ctx.rand(22, 28), dx, dy, layer)
            driftPuff(ctx, x + cos(a + 1.6) * 16, y + sin(a + 1.6) * 16, ctx.rand(13, 17), dx * 1.2, dy * 1.2, layer)
        }
        for sx in [-1.0, 1.0] {
            for i in 0..<3 {
                let x = sx * (30 + Double(i) * 34), y = 6 + Double(i) * 4
                driftPuff(ctx, x, y, 14 + Double(i) * 2, sx * ctx.rand(40, 70), ctx.rand(-6, 4), abs(x) > 95 ? ctx.front : ctx.back)
            }
        }

        typealias Hit = (t: Double, p: Double, big: Bool, first: Bool, x: Double, y: Double, area: Double)
        var sounds: [Hit] = []
        var runEnd = 0.0
        for s in shards {
            guard let sim = s.sim, let piece = s.piece, let shadow = s.shadow else { continue }
            let frames = sim.frames
            let lastT = frames.last?.t ?? DT
            let total = lastT > 0 ? lastT : DT
            let fadeFrom = s.stay ? Double.infinity : sim.out ? total - 0.08 : max(0.35, total - 0.32)
            let groundY = sim.depth
            let cx = s.cx, cy = s.cy
            func opacityAt(_ t: Double) -> Double {
                if t <= fadeFrom { return 1 }
                let span = total - fadeFrom
                return max(0, 1 - (t - fadeFrom) / (span != 0 ? span : 1))
            }
            piece.wrap.hidden = false
            piece.el.drive(duration: total) { sec in
                let f = frameAt(frames, sec)
                return AnimPose(transform: Transform.matrix([.translate(f.X - cx, f.Y - cy), .scale(f.sx, f.sy), .rotate(f.R)]),
                                opacity: opacityAt(sec))
            }
            shadow.opacity = 1
            shadow.drive(duration: total) { sec in
                let f = frameAt(frames, sec)
                let h = max(0, groundY - f.Y)
                let k = max(0.35, 1 - h / 320)
                return AnimPose(transform: Transform.matrix([.translate(f.X, groundY), .s(k)]), opacity: 0.2 * k * opacityAt(sec))
            }
            let stay = s.stay
            ctx.later(total * 1000) {
                if !stay {
                    piece.wrap.removeFromParent()
                    shadow.removeFromParent()
                }
            }
            runEnd = max(runEnd, total * 1000)
            for ev in sim.events {
                if abs(ev.X) > 270 || ev.t > fadeFrom { continue }
                sounds.append((ev.t, min(1, 0.35 + 900 / (s.area + 300)) + ctx.rand(-0.1, 0.1),
                               s.area > 1400 && ev.n == 0, ev.n == 0, ev.X, groundY, s.area))
            }
        }

        // impact sounds + landing dust, thinned so it's a patter, not a din
        sounds.sort { $0.t < $1.t }
        var lastHit = -1.0, thuds = 0
        for e in sounds {
            if e.t - lastHit < 0.05 { continue }
            lastHit = e.t
            let isThud = e.big && thuds < 1
            if isThud { thuds += 1 }
            ctx.later(e.t * 1000) {
                if isThud { ctx.thud(0.4) } else { ctx.clink(max(0, min(1, e.p))) }
                if e.first {
                    let inFront = e.y > 48 && abs(e.x) > 100
                    ctx.puff(e.x, e.y - 4, 9 + min(8, sqrt(e.area) * 0.12), layer: inFront ? ctx.front : ctx.back)
                }
            }
        }

        await ctx.wait(runEnd)
    }

    /// Reduce Motion: a soft pop — shards nudge outward and fade.
    private func reduced(_ ctx: ShellCtx, _ polys: [[Pt]], _ stats: [Stat], _ P: Pt) async {
        var pieces: [(Stat, Piece)] = []
        for (i, poly) in polys.enumerated() {
            pieces.append((stats[i], ctx.piece(poly, cx: stats[i].cx, cy: stats[i].cy)))
        }
        ctx.release()
        ctx.crack()
        for (s, p) in pieces {
            let dx = s.cx - P.0, dy = s.cy - P.1
            let l = hypot(dx, dy) == 0 ? 1 : hypot(dx, dy)
            ctx.start(p.el, [KF([.translate(0, 0), .s(1)], opacity: 1), KF([.translate(dx / l * 8, dy / l * 8), .s(0.92)], opacity: 0)],
                      duration: 300, easing: .easeOut, fill: true)
            ctx.later(300) { p.wrap.removeFromParent() }
        }
        await ctx.wait(320)
    }
}
