import SwiftUI

/// Shell effect "Crumble".
///
/// The "teeth fall out" gag: the egg lands from its stretch and freezes; a
/// web of cracks races across it; then the shell drops out tile by tile, top
/// row first, each one wobbling, falling straight down under gravity and
/// tinkling onto a little heap at the egg's base. The heap gives a last
/// slump, one tile slides off the top, and the rubble stays behind the
/// friend. See ShellFX.swift for the contract.

private func sgn(_ v: Double) -> Double { v > 0 ? 1 : v < 0 ? -1 : 0 }

/// half-width of the egg at height y, from the egg's right-hand Béziers
private let halfWidthTable: [Pt] = {
    let curves: [[Pt]] = [
        [(0, -170), (40, -170), (64, -96), (64, -58)],
        [(64, -58), (64, -20), (36, 0), (0, 0)],
    ]
    var pts: [Pt] = []
    for c in curves {
        for i in 0...48 {
            let t = Double(i) / 48, u = 1 - t
            let k0 = u * u * u, k1 = 3 * u * u * t, k2 = 3 * u * t * t, k3 = t * t * t
            pts.append((k0 * c[0].0 + k1 * c[1].0 + k2 * c[2].0 + k3 * c[3].0, k0 * c[0].1 + k1 * c[1].1 + k2 * c[2].1 + k3 * c[3].1))
        }
    }
    return pts.sorted { $0.1 < $1.1 }
}()

private func HW(_ y: Double) -> Double {
    if y <= -170 || y >= 0 { return 0 }
    let pts = halfWidthTable
    for i in 1..<pts.count where pts[i].1 >= y {
        let (x0, y0) = pts[i - 1], (x1, y1) = pts[i]
        return y1 == y0 ? max(x0, x1) : x0 + (x1 - x0) * (y - y0) / (y1 - y0)
    }
    return 0
}

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

/// points of the tile polygon that are actually visible (inside the egg)
private func visibleSamples(_ poly: [Pt]) -> [Pt] {
    var x0 = Double.infinity, x1 = -Double.infinity, y0 = Double.infinity, y1 = -Double.infinity
    for (x, y) in poly { x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y) }
    var out: [Pt] = []
    var y = max(y0, -170) + 1
    while y < min(y1, 0) {
        let hw = HW(y)
        var x = max(x0, -hw) + 1
        while x < min(x1, hw) {
            if inPoly(x, y, poly) { out.append((x, y)) }
            x += 3
        }
        y += 3
    }
    return out
}

// row boundaries (top → bottom) and where each row is split into tiles
private let ROW_Y: [Double] = [-196, -134, -100, -66, -32, 14]
private let SPLITS: [[Double]] = [[2], [-17, 18], [-32, 0, 32], [-40, -14, 12, 38], [-26, 0, 26]]
private let XS: [Double] = [-100, -80, -60, -40, -20, 0, 20, 40, 60, 80, 100]

private func buildGrid() -> (tiles: [(row: Int, poly: [Pt])], cracks: [[Pt]]) {
    // horizontal boundaries: jittered polylines (outer ones straight)
    var H: [[Pt]] = []
    for (k, y) in ROW_Y.enumerated() {
        let straight = k == 0 || k == ROW_Y.count - 1
        H.append(XS.map { x in (x, straight ? y : y + GC.rand(-4, 4)) })
    }
    func yAt(_ line: [Pt], _ x: Double) -> Double {
        for i in 1..<line.count where line[i].0 >= x {
            let (xa, ya) = line[i - 1], (xb, yb) = line[i]
            return ya + (yb - ya) * (x - xa) / (xb - xa)
        }
        return line[line.count - 1].1
    }
    func between(_ line: [Pt], _ a: Double, _ b: Double) -> [Pt] { line.filter { $0.0 > a && $0.0 < b } }

    var tiles: [(row: Int, poly: [Pt])] = []
    var cracks: [[Pt]] = []
    for r in 0..<SPLITS.count {
        let top = H[r], bot = H[r + 1]
        // each split is a little kinked line from the top boundary to the bottom one
        let cuts: [[Pt]] = SPLITS[r].map { s in
            let xt = s + GC.rand(-3, 3), xb = s + GC.rand(-3, 3)
            let yt = yAt(top, xt), yb = yAt(bot, xb)
            let mid: Pt = ((xt + xb) / 2 + GC.rand(-3.5, 3.5), (yt + yb) / 2 + GC.rand(-3, 3))
            return [(xt, yt), mid, (xb, yb)]
        }
        var edges: [[Pt]] = [[(-100, top[0].1), (-100, bot[0].1)]]
        edges += cuts
        edges.append([(100, top[top.count - 1].1), (100, bot[bot.count - 1].1)])
        for c in 0..<(edges.count - 1) {
            let L = edges[c], R = edges[c + 1]
            let lFirst = L[0], lLast = L[L.count - 1], rFirst = R[0], rLast = R[R.count - 1]
            var pts: [Pt] = [lFirst]
            pts += between(top, lFirst.0, rFirst.0)
            pts.append(rFirst)
            if R.count > 2 { pts += Array(R[1..<(R.count - 1)]) }
            pts.append(rLast)
            pts += Array(between(bot, lLast.0, rLast.0).reversed())
            pts.append(lLast)
            if L.count > 2 { pts += Array(L[1..<(L.count - 1)].reversed()) }
            tiles.append((r, pts))
        }
        cracks += cuts
    }
    for k in 1..<(H.count - 1) { cracks.append(H[k]) }
    return (tiles, cracks)
}

private func tf(_ x: Double, _ y: Double, _ r: Double, _ sx: Double = 1, _ sy: Double = 1) -> [TOp] {
    var ops: [TOp] = [.translate(x, y), .rotate(r)]
    if sx != 1 || sy != 1 { ops.append(.scale(sx, sy)) }
    return ops
}

/// extents of a tile's visible samples (centroid-relative) after rotating by deg
private func extents(_ rel: [Pt], _ deg: Double) -> (minX: Double, maxX: Double, minY: Double, maxY: Double) {
    let a = deg * Double.pi / 180, c = cos(a), s = sin(a)
    var minX = Double.infinity, maxX = -Double.infinity, minY = Double.infinity, maxY = -Double.infinity
    for (x, y) in rel {
        let X = x * c - y * s, Y = x * s + y * c
        minX = min(minX, X); maxX = max(maxX, X); minY = min(minY, Y); maxY = max(maxY, Y)
    }
    if rel.isEmpty { return (0, 0, 0, 0) }
    return (minX, maxX, minY, maxY)
}

/// a ground heightmap for the rubble heap
private final class Heap {
    let ground: Double
    private let col = 8.0, x0 = -180.0
    private var h: [Double]
    init(_ ground: Double) {
        self.ground = ground
        h = [Double](repeating: 0, count: Int(ceil(360 / 8.0)))
    }
    private func idx(_ x: Double) -> Int { Int(GC.clamp(((x - x0) / col).rounded(), 0, Double(h.count - 1))) }
    func surface(_ a: Double, _ b: Double) -> Double {
        var s = 0.0, m = 0.0
        let i0 = idx(a), i1 = idx(b)
        if i0 <= i1 { for i in i0...i1 { s += h[i]; m += 1 } }
        return m > 0 ? s / m : 0
    }
    func at(_ x: Double) -> Double { h[idx(x)] }
    func raise(_ a: Double, _ b: Double, _ v: Double) {
        let i0 = idx(a), i1 = idx(b)
        if i0 <= i1 { for i in i0...i1 { h[i] = max(h[i], v) } }
    }
}

@MainActor
private final class Tile {
    let piece: Piece
    let row: Int
    let rel: [Pt]
    let cx: Double, cy: Double
    var start = 0.0, total = 0.0, impact = 0.0
    var rest = (x: 0.0, y: 0.0, r: 0.0)
    var frames: [KF] = []
    init(piece: Piece, row: Int, rel: [Pt], cx: Double, cy: Double) {
        self.piece = piece; self.row = row; self.rel = rel; self.cx = cx; self.cy = cy
    }
    var el: VNode { piece.el }
}

struct CrumbleFX: ShellEffect {
    let id = "crumble", name = "Crumble", icon = "🧱"

    func run(_ ctx: ShellCtx) async {
        let R = ctx.rand
        let (grid, cracks) = buildGrid()

        // ---------- reduced motion: tiles just sink and fade together ----------
        if ctx.reduce {
            let ps = grid.map { ctx.piece($0.poly, layer: ctx.back, edge: 4) }
            ctx.crack()
            ctx.release()
            for p in ps {
                ctx.start(p.el, [KF([.translate(0, 0)], opacity: 1), KF([.translate(0, R(5, 9))], opacity: 0)],
                          duration: 360, easing: .easeIn, fill: true)
            }
            await ctx.wait(360)
            return
        }

        // ---------- beat 1: land from the stretch, freeze, crack web ----------
        let shadow = ctx.shadow(0, 24, 112, layer: ctx.back)
        shadow.opacity = 0
        let whole = ctx.piece([(-100, -200), (100, -200), (100, 20), (-100, 20)], cx: 0, cy: 0)
        await ctx.animate(whole.el, [KF([.scale(0.9, 1.12)]), KF([.scale(1.07, 0.93)], offset: 0.55), KF([.scale(1, 1)])],
                          duration: 180, easing: .easeOut, fill: true)
        await ctx.wait(70)

        let ox = 6.0, oy = -124.0 // where the first crack starts
        let lines = nGroup([], clip: EggArt.path)
        let web = nGroup([lines])
        ctx.front.add(web)
        let SPEED = 0.95          // px per ms the crack travels
        func len(_ pts: [Pt]) -> Double {
            var s = 0.0
            for i in 1..<pts.count { s += hypot(pts[i].0 - pts[i - 1].0, pts[i].1 - pts[i - 1].1) }
            return s
        }
        var segs: [[Pt]] = []
        for c in cracks {
            if c.count > 3 {
                // a horizontal boundary: crack from the point nearest the origin outwards both ways
                var k = 0
                for (i, p) in c.enumerated() where abs(p.0 - ox) < abs(c[k].0 - ox) { k = i }
                segs.append(Array(c[0...k].reversed()))
                segs.append(Array(c[k...]))
            } else {
                let d0 = hypot(c[0].0 - ox, c[0].1 - oy), d1 = hypot(c[2].0 - ox, c[2].1 - oy)
                segs.append(d0 <= d1 ? c : Array(c.reversed()))
            }
        }
        ctx.crack()
        var webEnd = 0.0
        for s in segs where s.count > 1 {
            let pl = nPolyline(s, St.line(GC.outHex, 4.5))
            pl.trimTo = 0
            lines.add(pl)
            let d = hypot(s[0].0 - ox, s[0].1 - oy) * 0.75
            let dur = max(40, len(s) / SPEED), delay = d / SPEED
            ctx.start(pl, [KF(trimTo: 0), KF(trimTo: 1)], duration: dur, delay: delay, fill: true)
            webEnd = max(webEnd, dur + delay)
        }
        // a tiny "tink" sparkle where it starts
        let sp = nPath("M0,-13 L3,-3 L13,0 L3,3 L0,13 L-3,3 L-13,0 L-3,-3 Z", St.o(2.5).filled("#ffffff"))
        web.add(nGroup([sp], tr(ox, oy)))
        ctx.start(sp, [KF([.s(0.1), .rotate(0)]), KF([.s(1.2), .rotate(30)], offset: 0.35), KF([.s(0.001), .rotate(60)])],
                  duration: 260, easing: .easeOut, fill: true)
        await ctx.wait(webEnd)
        await ctx.wait(190) // …uh-oh.

        // ---------- beat 2: swap to the tiles (identical picture) ----------
        // bottom rows first so falling upper tiles pass in front of them
        let tiles: [Tile] = grid.reversed().map { g in
            let vis = visibleSamples(g.poly)
            var cx = 0.0, cy = 0.0
            for (x, y) in vis { cx += x; cy += y }
            let n = Double(max(1, vis.count))
            cx /= n; cy /= n
            let p = ctx.piece(g.poly, cx: cx, cy: cy)
            return Tile(piece: p, row: g.row, rel: vis.map { ($0.0 - cx, $0.1 - cy) }, cx: cx, cy: cy)
        }
        web.removeFromParent()
        whole.wrap.removeFromParent()

        // ---------- beat 3: the cascade ----------
        // fall order: top row first, shuffled inside each row
        var order: [Tile] = []
        for r in 0..<SPLITS.count { order += tiles.filter { $0.row == r }.shuffled() }
        let frontHeap = Heap(28), backHeap = Heap(9) // upper rows land nearer the viewer
        let G = 0.0030                               // gravity, px/ms²
        let WOB = 95.0
        var t0 = 0.0
        for (i, t) in order.enumerated() {
            t.start = t0
            t0 += t.row < 3 ? R(52, 66) : R(38, 50)
            let hp = t.row < 3 ? frontHeap : backHeap
            let side: Double = abs(t.cx) < 4 ? (i % 2 == 1 ? 1 : -1) : sgn(t.cx)
            // where it comes to rest: pushed out to the sides so the friend stands in front
            let ax = abs(t.cx)
            let spread = [ax * 0.7, 16 + ax * 1.1, 30 + ax * 1.3, 48 + ax * 1.3, 52 + ax * 1.4][t.row]
            let xr = side * spread + R(-7, 7)
            let rr = side * R(14, 48) * (Double.random(in: 0..<1) < 0.2 ? -1 : 1)
            let eR = extents(t.rel, rr)
            let fw = (eR.maxX - eR.minX) / 2
            let surf = hp.surface(xr - fw * 0.6, xr + fw * 0.6) * 0.8
            let restBottom = hp.ground + R(-4, 6) - surf
            let yr = restBottom - eR.maxY
            hp.raise(xr - fw * 0.75, xr + fw * 0.75, min(46, surf + (eR.maxY - eR.minY) * 0.55))
            // the drop: straight down at first, edging outward as it nears the heap,
            // then it skitters down the slope
            let rx = xr - t.cx, ry = yr - t.cy
            let xi = side * R(2, 8) + rx * (t.row < 3 ? 0.5 : 0.3)
            let ri = side * R(6, 18)
            let eI = extents(t.rel, ri)
            let impactBottom = hp.ground - 4 - hp.at(t.cx + xi) * 0.6
            let yi = max(6, impactBottom - eI.maxY - t.cy) // drop distance
            let d = yi - 2
            let T = (2 * d / G).squareRoot()
            let S = 150 + abs(rx - xi) * 1.5
            t.rest = (rx, ry, rr)
            // keyframes in absolute ms, converted to offsets below
            var k: [(Double, [TOp])] = []
            let sw = R(3, 6) * (Double.random(in: 0..<1) < 0.5 ? -1 : 1)
            k.append((0, tf(0, 0, 0)))
            k.append((WOB * 0.3, tf(0, 1, sw)))
            k.append((WOB * 0.65, tf(0, 1, -sw * 0.8)))
            k.append((WOB, tf(0, 2, 0)))
            for s in 1...8 {
                let u = Double(s) / 8
                k.append((WOB + T * u, tf(xi * u * u * u, 2 + (yi - 2) * u * u, ri * u)))
            }
            let tI = WOB + T
            let hop = R(7, 13)
            k.append((tI + 25, tf(xi + (rx - xi) * 0.08, yi - 2, ri + (rr - ri) * 0.1, 1.08, 0.9)))
            k.append((tI + S * 0.45, tf(xi + (rx - xi) * 0.5, min(yi, ry) - hop, ri + (rr - ri) * 0.7)))
            k.append((tI + S, tf(rx, ry, rr + side * 5)))
            k.append((tI + S + 90, tf(rx, ry, rr)))
            let total = k[k.count - 1].0
            var frames: [KF] = []
            for (j, e) in k.enumerated() {
                let ease: Ease = j >= k.count - 4 ? (j == k.count - 3 ? .easeOut : .easeIn) : .linear
                frames.append(KF(e.1, offset: e.0 / total, easing: ease))
            }
            t.frames = frames
            t.total = total
            t.impact = tI
        }

        // release the friend once the top two rows are on their way down
        let releaseAt = order[min(5, order.count - 1)].start + WOB + 40
        let releaseFlow = Task { @MainActor in
            await ctx.wait(releaseAt)
            ctx.release()
            await ctx.wait(320)
            // everything goes behind the friend now (keeps the original stacking order)
            ctx.back.add(shadow)
            for t in tiles { ctx.back.add(t.piece.wrap) }
        }

        ctx.start(shadow, [KF(opacity: 0), KF(opacity: 0.18)], duration: t0 + 300, fill: true)

        let N = Double(order.count)
        var landed = 0.0
        var cascadeEnd = 0.0
        for t in order {
            ctx.start(t.el, t.frames, duration: t.total, delay: t.start, fill: true)
            ctx.later(t.start + t.impact) {
                ctx.clink(GC.clamp(0.95 - (landed / N) * 0.85, 0, 1))
                landed += 1
            }
            cascadeEnd = max(cascadeEnd, t.start + t.total)
        }
        await ctx.wait(cascadeEnd)
        await releaseFlow.value

        // ---------- beat 4: the heap slumps, one tile slides off ----------
        ctx.thud(0.25)
        // pick the highest tile on the front heap that sits off to one side
        var topTile: Tile?
        for t in order where t.row < 3 {
            let y = t.cy + t.rest.y
            if abs(t.cx + t.rest.x) > 60, topTile == nil || y < topTile!.cy + topTile!.rest.y { topTile = t }
        }
        for t in order {
            let r = t.rest
            let v = r.x + t.cx
            let dx = sgn(v != 0 ? v : 1) * R(1, 4), dy = R(2, 5), dr = R(-5, 5)
            t.rest = (r.x + dx, r.y + dy, r.r + dr)
            ctx.start(t.el, [KF(tf(r.x, r.y, r.r)), KF(tf(r.x + dx * 0.5, r.y - 2, r.r + dr * 0.3), offset: 0.3), KF(tf(t.rest.x, t.rest.y, t.rest.r))],
                      duration: 260, delay: R(0, 50), easing: Ease(0.5, 0, 0.6, 1.4), fill: true)
        }
        ctx.puff(-104, 22, 22, layer: ctx.back)
        ctx.puff(106, 24, 20, layer: ctx.back)
        await ctx.wait(110)
        if let top = topTile {
            let r = top.rest
            let side = sgn(top.cx + r.x)
            let rr = r.r + side * R(50, 80)
            let e = extents(top.rel, rr)
            let xr = r.x + side * R(44, 56)
            let yr = 40 - e.maxY - top.cy
            await ctx.animate(top.el, [
                KF(tf(r.x, r.y, r.r)),
                KF(tf(r.x + side * 4, r.y + 1, r.r + side * 8), offset: 0.25, easing: .easeIn),
                KF(tf(xr, yr, rr), offset: 0.8, easing: .easeOut),
                KF(tf(xr + side * 3, yr - 5, rr + side * 6), offset: 0.9, easing: .easeIn),
                KF(tf(xr + side * 5, yr, rr + side * 4)),
            ], duration: 420, fill: true)
            ctx.clink(0.05)
        } else {
            await ctx.wait(200)
        }
    }
}
