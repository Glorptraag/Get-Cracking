import SwiftUI

/// Shell effect "Roll away".
///
/// Cartoon physics: the lid pops straight up with a spin, lands dome-down,
/// rocks like a bowl and then trundles off to the left. The bottom cup splits
/// down a jagged crack; the halves flop open like petals, bounce, and roll
/// away like wheels (rotation = distance / radius). The left half rolls off
/// screen, the right half teeters to a stop face-down near the edge. A few
/// chips rattle to rest on the ground.
///
/// Rolling height comes from each piece's real outline: for every rotation we
/// find the lowest point of the piece, so the non-round halves bob and bump
/// naturally as their corners come round.

private let D2R = Double.pi / 180

// the egg outline (matches EggArt.pathD) as cubic segments
private let eggSegs: [[Pt]] = [
    [(0, -170), (40, -170), (64, -96), (64, -58)],
    [(64, -58), (64, -20), (36, 0), (0, 0)],
    [(0, 0), (-36, 0), (-64, -20), (-64, -58)],
    [(-64, -58), (-64, -96), (-40, -170), (0, -170)],
]

private let rollOutline: [Pt] = {
    var out: [Pt] = []
    for s in eggSegs {
        let a = s[0], b = s[1], c = s[2], d = s[3]
        for i in 0..<20 {
            let u = Double(i) / 20, v = 1 - u
            let k0 = v * v * v, k1 = 3 * v * v * u, k2 = 3 * v * u * u, k3 = u * u * u
            out.append((k0 * a.0 + k1 * b.0 + k2 * c.0 + k3 * d.0, k0 * a.1 + k1 * b.1 + k2 * c.1 + k3 * d.1))
        }
    }
    return out
}()

private func inside(_ poly: [Pt], _ x: Double, _ y: Double) -> Bool {
    var c = false
    var j = poly.count - 1
    for i in 0..<poly.count {
        let (xi, yi) = poly[i], (xj, yj) = poly[j]
        if (yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi { c.toggle() }
        j = i
    }
    return c
}

private struct Region {
    var pts: [Pt]
    var cx: Double, cy: Double, w: Double, h: Double
}

/// the visible region of a piece (egg ∩ polygon): boundary points + area centroid
private func region(_ poly: [Pt]) -> Region {
    let egg = rollOutline
    var pts = egg.filter { inside(poly, $0.0, $0.1) }
    for i in 0..<poly.count {
        let a = poly[i], b = poly[(i + 1) % poly.count]
        let n = max(1, Int(ceil(hypot(b.0 - a.0, b.1 - a.1) / 5)))
        for k in 0...n {
            let x = a.0 + (b.0 - a.0) * Double(k) / Double(n), y = a.1 + (b.1 - a.1) * Double(k) / Double(n)
            if inside(egg, x, y) { pts.append((x, y)) }
        }
    }
    var x0 = Double.infinity, x1 = -Double.infinity, y0 = Double.infinity, y1 = -Double.infinity
    for (x, y) in pts { x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y) }
    var sx = 0.0, sy = 0.0, n = 0.0
    // a 6 px grid is plenty for a centroid and keeps the break frame cheap
    if !pts.isEmpty {
        var y = y0
        while y <= y1 {
            var x = x0
            while x <= x1 {
                if inside(egg, x, y) && inside(poly, x, y) { sx += x; sy += y; n += 1 }
                x += 6
            }
            y += 6
        }
    }
    return Region(pts: pts, cx: n > 0 ? sx / n : (x0 + x1) / 2, cy: n > 0 ? sy / n : (y0 + y1) / 2, w: x1 - x0, h: y1 - y0)
}

/// lowest point of region R (relative to its centroid) when rotated by deg
private func low(_ R: Region, _ deg: Double) -> Double {
    let s = sin(deg * D2R), c = cos(deg * D2R)
    var m = -Double.infinity
    for (px, py) in R.pts {
        let dx = px - R.cx, dy = py - R.cy
        let y = dx * s + dy * c
        if y > m { m = y }
    }
    return m
}

// motion helpers
private func lerp(_ a: Double, _ b: Double, _ u: Double) -> Double { a + (b - a) * u }
/// 0 → 1 as v goes from a to b
private func ramp(_ v: Double, _ a: Double, _ b: Double) -> Double { GC.clamp((v - a) / (b - a), 0, 1) }
private func sgn(_ v: Double) -> Double { v > 0 ? 1 : v < 0 ? -1 : 0 }

private struct Hop { let t: Double, d: Double, h: Double }
private struct Impact { let t: Double, a: Double }

/// parabolic hops → upward offset (positive = up)
private func hops(_ list: [Hop], _ t: Double) -> Double {
    var up = 0.0
    for hp in list {
        let u = (t - hp.t) / hp.d
        if u > 0 && u < 1 { up += hp.h * 4 * u * (1 - u) }
    }
    return up
}

/// squash on impacts → amount 0…a
private func squash(_ list: [Impact], _ t: Double) -> Double {
    var k = 0.0
    for im in list {
        let tau = t - im.t
        if tau >= 0 && tau < 170 { k = max(k, im.a * sin(Double.pi * tau / 170) * (1 - tau / 340)) }
    }
    return k
}

/// cubic Hermite from (p0, slope m0) to (p1, slope m1) over duration D
private func hermite(_ p0: Double, _ m0: Double, _ p1: Double, _ m1: Double, _ D: Double, _ tau: Double) -> Double {
    let s = GC.clamp(tau / D, 0, 1), s2 = s * s, s3 = s2 * s
    let a = (2 * s3 - 3 * s2 + 1) * p0 + (s3 - 2 * s2 + s) * D * m0
    let b = (-2 * s3 + 3 * s2) * p1 + (s3 - s2) * D * m1
    return a + b
}

/// x, y = centroid position; r = rotation (deg); sq = squash amount, applied
/// in world space and anchored to the piece's lowest point.
private struct Sample {
    var x: Double, y: Double, r: Double
    var sq: Double = 0
    var o: Double = 1
    var so: Double = 1
}

struct RollFX: ShellEffect {
    let id = "roll", name = "Roll away", icon = "🛞"

    /// Animate a piece along fn(t ms); if `shadow` is given it follows on the ground at depth g.
    private func track(_ ctx: ShellCtx, _ pc: Piece, _ R: Region, _ dur: Double, _ fn: @escaping (Double) -> Sample,
                       shadow: VNode? = nil, g: Double = 0) async {
        if let sh = shadow {
            sh.drive(duration: dur / 1000) { sec in
                let s = fn(sec * 1000)
                let lo = low(R, s.r)
                let air = max(0, g - (s.y + lo))
                let k = GC.clamp(1 - air / 260, 0.3, 1)
                return AnimPose(transform: Transform.matrix([.translate(s.x, g), .s(k * (1 + s.sq * 0.5))]),
                                opacity: 0.18 * s.o * k * s.so)
            }
        }
        await ctx.drive(pc.el, duration: dur) { t in
            let s = fn(t)
            let sx = 1 + s.sq * 0.8, sy = 1 - s.sq
            let lo = low(R, s.r)
            let y = s.y + (1 - sy) * lo // keep the bottom planted while squashing
            return AnimPose(transform: Transform.matrix([.translate(s.x - R.cx, y - R.cy), .scale(sx, sy), .rotate(s.r)]),
                            opacity: s.o)
        }
    }

    func run(_ ctx: ShellCtx) async {
        let Z = ctx.zig
        let zi = 4 // the zig point the vertical crack starts from
        let crack: [Pt] = [Z[zi], (7, -62), (-5, -50), (6, -37), (-4, -24), (4, -12), (-2, 0), (0, 24)]

        let lidPoly: [Pt] = [(-100, -240), (100, -240), (100, Z[Z.count - 1].1)] + Array(Z.reversed()) + [(-100, Z[0].1)]
        let leftPoly: [Pt] = [(-100, Z[0].1)] + Array(Z[0..<zi]) + crack + [(-100, 24)]
        let rightPoly: [Pt] = Array(Z[(zi + 1)...]) + [(100, Z[Z.count - 1].1), (100, 24)] + Array(crack.reversed())

        let Rl = region(lidPoly), RL = region(leftPoly), RR = region(rightPoly)

        // reduced motion: the halves just ease apart and fade, ≤ 400 ms
        if ctx.reduce {
            let lid = ctx.piece(lidPoly, layer: ctx.back, cx: Rl.cx, cy: Rl.cy)
            let L = ctx.piece(leftPoly, cx: RL.cx, cy: RL.cy)
            let Rt = ctx.piece(rightPoly, cx: RR.cx, cy: RR.cy)
            ctx.release()
            ctx.start(lid.el, [KF([.translate(0, 0)], opacity: 1), KF([.translate(0, -24)], opacity: 0)], duration: 350, easing: .easeOut, fill: true)
            ctx.start(L.el, [KF([.translate(0, 0), .rotate(0)], opacity: 1), KF([.translate(-40, 0), .rotate(-10)], opacity: 0)], duration: 350, easing: .easeOut, fill: true)
            await ctx.animate(Rt.el, [KF([.translate(0, 0), .rotate(0)], opacity: 1), KF([.translate(40, 0), .rotate(10)], opacity: 0)], duration: 350, easing: .easeOut, fill: true)
            return
        }

        // shadows first so they sit underneath everything in the back layer
        let shLid = ctx.shadow(0, 0, 52, layer: ctx.back)
        let shL = ctx.shadow(0, 0, 34, layer: ctx.back)
        let shR = ctx.shadow(0, 0, 34, layer: ctx.back)
        for s in [shLid, shL, shR] { s.opacity = 0 }

        // the lid lives behind the friend from the start; the halves cover the
        // friend's first peek, then step back once it's out
        let lid = ctx.piece(lidPoly, layer: ctx.back, cx: Rl.cx, cy: Rl.cy)
        let L = ctx.piece(leftPoly, cx: RL.cx, cy: RL.cy)
        let Rt = ctx.piece(rightPoly, cx: RR.cx, cy: RR.cy)

        ctx.whoosh()
        ctx.release()
        ctx.later(260) {
            ctx.back.add(L.wrap)
            ctx.back.add(Rt.wrap)
        }

        var jobs: [Task<Void, Never>] = []

        // ── lid: pop, spin, land dome-down, rock, roll off left ──
        do {
            let R = Rl
            let g = 22.0             // landing depth
            let T1 = 640.0           // touchdown
            let X1 = -128.0          // touchdown x
            let RE = -540.0          // end spin: dome-down
            let yE = g - low(R, RE)
            let T2 = T1 + 760        // rocking done
            let ROCK = 32.0, PER = 260.0, RAD = 38.0
            let rockAt: (Double) -> Double = { tau in -ROCK * exp(-tau / 240) * sin(2 * Double.pi * tau / PER) }
            let ROLL = 860.0
            let dur = T2 + ROLL
            let acc = (2 * 190) / (ROLL * ROLL)
            let imp = [Impact(t: T1, a: 0.24)]
            let fn: (Double) -> Sample = { t in
                if t < T1 {
                    let u = t / T1
                    let x = X1 * pow(u, 1.9)
                    let r = RE * (1 - pow(1 - u, 1.35))
                    let y = lerp(R.cy, yE, u * u) - 150 * sin(Double.pi * pow(u, 0.8)) * (1 - u * 0.25)
                    // stretch on the way up
                    let sq = -0.14 * (1 - ramp(u, 0, 0.35))
                    return Sample(x: x, y: y, r: r, sq: sq, so: ramp(t, 0, 120))
                }
                if t < T2 {
                    let phi = rockAt(t - T1)
                    let r = RE + phi
                    return Sample(x: X1 + RAD * phi * D2R, y: g - low(R, r), r: r, sq: squash(imp, t))
                }
                let tau = t - T2
                // a tiny hesitation, then it trundles off to the left
                let dx = -0.5 * acc * tau * tau - 4 * sin(Double.pi * ramp(tau, 0, 160))
                let x = X1 + RAD * rockAt(T2 - T1) * D2R + dx
                let r = RE + rockAt(T2 - T1) + (dx / RAD) / D2R
                let o = 1 - ramp(x, -205, -262)
                return Sample(x: x, y: g - low(R, r), r: r, o: o)
            }
            jobs.append(Task { await self.track(ctx, lid, R, dur, fn, shadow: shLid, g: g) })
            ctx.later(T1) {
                ctx.thud(0.35)
                ctx.puff(X1 - 40, g, 16, layer: ctx.back)
                ctx.puff(X1 + 44, g, 13, layer: ctx.back)
            }
            for i in 1...3 {
                ctx.later(T1 + Double(i) * PER * 0.5 + 40) { ctx.clink(0.25 + 0.05 * Double(i)) }
            }
        }

        // ── halves: flop open like petals, bounce, roll like wheels ──
        let TT = 250.0 // petal lands on its back
        func half(_ pc: Piece, _ R: Region, _ dir: Double) {
            let g = R.cy + low(R, 0) // resting depth == where it stands now
            let RAD = dir < 0 ? 38.0 : 33.0
            let imp = [Impact(t: TT, a: 0.22)]
            let bump: [Hop] = dir < 0
                ? [Hop(t: TT, d: 190, h: 16), Hop(t: 470, d: 120, h: 9), Hop(t: 640, d: 90, h: 5)]
                : [Hop(t: TT, d: 190, h: 14), Hop(t: 520, d: 120, h: 7)]
            let ang: (Double) -> Double
            let dur: Double
            let fade: (Double) -> Double
            if dir < 0 {
                // keeps rolling until it's gone off the left
                dur = 980
                ang = { t in
                    if t < TT { return -90 * (t / TT) * (t / TT) }
                    return -90 - 0.58 * (t - TT) - 0.00034 * (t - TT) * (t - TT)
                }
                fade = { x in 1 - ramp(x, -215, -270) }
            } else {
                // rolls right, slows, teeters to rest face-down near the edge
                let D = 700.0, SET = 720.0, END = 270.0, OVER = 15.0
                dur = TT + D + SET
                ang = { t in
                    if t < TT { return 90 * (t / TT) * (t / TT) }
                    let tau = t - TT
                    if tau < D { return hermite(90, 0.55, END + OVER, 0, D, tau) }
                    let s = tau - D
                    return END + OVER * exp(-s / 170) * cos(2 * Double.pi * s / 250)
                }
                fade = { _ in 1 }
            }
            let x0 = R.cx
            let fn: (Double) -> Sample = { t in
                let r = ang(t)
                let x = x0 + RAD * r * D2R
                return Sample(x: x, y: g - low(R, r) - hops(bump, t), r: r, sq: squash(imp, t), o: fade(x))
            }
            let sh = dir < 0 ? shL : shR
            jobs.append(Task { await self.track(ctx, pc, R, dur, fn, shadow: sh, g: g) })
            ctx.later(TT) {
                ctx.thud(dir < 0 ? 0.55 : 0.6)
                ctx.puff(x0 + dir * 42, g + 2, 15, layer: ctx.back)
            }
            for b in bump.dropFirst() {
                ctx.later(b.t + b.d) {
                    ctx.clink(dir < 0 ? 0.5 : 0.65)
                    ctx.puff(fn(b.t + b.d).x - dir * 18, g + 2, 9, layer: ctx.back)
                }
            }
            if dir > 0 {
                for s in [TT + 700 + 120, TT + 700 + 250] { ctx.later(s) { ctx.clink(0.8) } }
            }
        }
        half(L, RL, -1)
        half(Rt, RR, 1)

        // ── chips: a few crumbs rattle down beside the friend ──
        struct Chip { let at: Pt; let to: Double; let g: Double; let t: Double; let h: Double; let spin: Double }
        let chips = [
            Chip(at: (-44, -84), to: -98, g: 30, t: 380, h: 70, spin: -420),
            Chip(at: (-18, -84), to: -150, g: 40, t: 460, h: 95, spin: -300),
            Chip(at: (22, -86), to: 104, g: 34, t: 420, h: 85, spin: 380),
            Chip(at: (48, -82), to: 158, g: 18, t: 480, h: 60, spin: 520),
            Chip(at: (2, -40), to: 84, g: 52, t: 360, h: 50, spin: 260),
        ]
        for (i, c) in chips.enumerated() {
            let (ax, ay) = c.at
            let s = 7 + Double(i % 3) * 2
            let poly: [Pt] = [(ax - s, ay - s * 0.6), (ax + s, ay - s * 0.4), (ax + s * 0.3, ay + s * 0.9), (ax - s * 0.7, ay + s * 0.5)]
            let R = region(poly)
            if R.pts.count < 3 { continue }
            let pc = ctx.piece(poly, layer: ctx.back, edge: 3, cx: R.cx, cy: R.cy)
            pc.el.opacity = 0
            let start = 30 + Double(i) * 18
            let yE = c.g - low(R, c.spin)
            let rattle = [Hop(t: c.t, d: 150, h: 12), Hop(t: c.t + 150, d: 90, h: 5), Hop(t: c.t + 240, d: 60, h: 2)]
            let fn: (Double) -> Sample = { t in
                if t < c.t {
                    let u = t / c.t
                    return Sample(x: lerp(R.cx, c.to, u), y: lerp(R.cy, yE, u) - c.h * 4 * u * (1 - u), r: c.spin * u)
                }
                let tau = t - c.t
                let r = c.spin + 18 * exp(-tau / 120) * sin(tau / 22)
                return Sample(x: c.to + sgn(c.to) * 10 * (1 - exp(-tau / 120)), y: c.g - low(R, r) - hops(rattle, t), r: r)
            }
            ctx.later(start) {
                pc.el.opacity = 1
                Task { await self.track(ctx, pc, R, c.t + 420, fn) }
            }
            ctx.later(start + c.t) { ctx.clink(0.7 + 0.06 * Double(i)) }
            ctx.later(start + c.t + 150) { ctx.clink(0.85) }
        }

        for j in jobs { await j.value }
    }
}
