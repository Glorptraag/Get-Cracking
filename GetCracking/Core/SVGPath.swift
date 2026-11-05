import SwiftUI

/// Parses SVG path data (M L H V C S Q T A Z, absolute and relative) into a
/// CGPath. The art in this app is authored the same way as the web version,
/// as path strings, so the drawings port over unchanged.
enum SVGPath {
    private static var cache: [String: Path] = [:]

    static func parse(_ d: String) -> Path {
        if let p = cache[d] { return p }
        let p = Path(cgPath(d))
        if cache.count > 4000 { cache.removeAll() }
        cache[d] = p
        return p
    }

    static func cgPath(_ d: String) -> CGMutablePath {
        let path = CGMutablePath()
        var tok = Tokenizer(Array(d.utf8))
        var cur = CGPoint.zero, start = CGPoint.zero
        var lastCtrl: CGPoint? = nil      // for S/s
        var lastQuad: CGPoint? = nil      // for T/t
        var cmd: UInt8 = 0
        var open = false

        func ensureOpen() {
            if !open { path.move(to: cur); start = cur; open = true }
        }

        while true {
            if let c = tok.command() {
                cmd = c
            } else if cmd == 0 || !tok.hasNumber() {
                if tok.atEnd { break }
                tok.skipJunk()
                continue
            }
            let rel = cmd >= 97 // lowercase
            let base = rel ? cur : .zero
            switch cmd {
            case UInt8(ascii: "M"), UInt8(ascii: "m"):
                guard let x = tok.number(), let y = tok.number() else { break }
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.move(to: cur); start = cur; open = true
                cmd = rel ? UInt8(ascii: "l") : UInt8(ascii: "L")
                lastCtrl = nil; lastQuad = nil
            case UInt8(ascii: "L"), UInt8(ascii: "l"):
                guard let x = tok.number(), let y = tok.number() else { break }
                ensureOpen()
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addLine(to: cur)
                lastCtrl = nil; lastQuad = nil
            case UInt8(ascii: "H"), UInt8(ascii: "h"):
                guard let x = tok.number() else { break }
                ensureOpen()
                cur = CGPoint(x: (rel ? cur.x : 0) + x, y: cur.y)
                path.addLine(to: cur)
                lastCtrl = nil; lastQuad = nil
            case UInt8(ascii: "V"), UInt8(ascii: "v"):
                guard let y = tok.number() else { break }
                ensureOpen()
                cur = CGPoint(x: cur.x, y: (rel ? cur.y : 0) + y)
                path.addLine(to: cur)
                lastCtrl = nil; lastQuad = nil
            case UInt8(ascii: "C"), UInt8(ascii: "c"):
                guard let x1 = tok.number(), let y1 = tok.number(), let x2 = tok.number(),
                      let y2 = tok.number(), let x = tok.number(), let y = tok.number() else { break }
                ensureOpen()
                let c1 = CGPoint(x: base.x + x1, y: base.y + y1)
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addCurve(to: cur, control1: c1, control2: c2)
                lastCtrl = c2; lastQuad = nil
            case UInt8(ascii: "S"), UInt8(ascii: "s"):
                guard let x2 = tok.number(), let y2 = tok.number(), let x = tok.number(), let y = tok.number() else { break }
                ensureOpen()
                let c1 = lastCtrl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addCurve(to: cur, control1: c1, control2: c2)
                lastCtrl = c2; lastQuad = nil
            case UInt8(ascii: "Q"), UInt8(ascii: "q"):
                guard let x1 = tok.number(), let y1 = tok.number(), let x = tok.number(), let y = tok.number() else { break }
                ensureOpen()
                let c = CGPoint(x: base.x + x1, y: base.y + y1)
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addQuadCurve(to: cur, control: c)
                lastQuad = c; lastCtrl = nil
            case UInt8(ascii: "T"), UInt8(ascii: "t"):
                guard let x = tok.number(), let y = tok.number() else { break }
                ensureOpen()
                let c = lastQuad.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addQuadCurve(to: cur, control: c)
                lastQuad = c; lastCtrl = nil
            case UInt8(ascii: "A"), UInt8(ascii: "a"):
                guard let rx = tok.number(), let ry = tok.number(), let rot = tok.number(),
                      let large = tok.number(), let sweep = tok.number(),
                      let x = tok.number(), let y = tok.number() else { break }
                ensureOpen()
                let to = CGPoint(x: base.x + x, y: base.y + y)
                addArc(path, from: cur, rx: rx, ry: ry, rotation: rot, large: large != 0, sweep: sweep != 0, to: to)
                cur = to
                lastCtrl = nil; lastQuad = nil
            case UInt8(ascii: "Z"), UInt8(ascii: "z"):
                if open { path.closeSubpath() }
                cur = start
                open = false
                lastCtrl = nil; lastQuad = nil
                cmd = 0
            default:
                tok.skipJunk()
            }
            if tok.atEnd { break }
        }
        return path
    }

    /// SVG elliptical arc (endpoint parameterisation) as cubic Béziers.
    static func addArc(_ path: CGMutablePath, from p0: CGPoint, rx rxIn: Double, ry ryIn: Double,
                       rotation: Double, large: Bool, sweep: Bool, to p1: CGPoint) {
        if p0 == p1 { return }
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 { path.addLine(to: p1); return }
        let x0 = Double(p0.x), y0 = Double(p0.y), x1 = Double(p1.x), y1 = Double(p1.y)
        let phi = rotation * .pi / 180
        let cp = cos(phi), sp = sin(phi)
        let dx2: Double = (x0 - x1) / 2, dy2: Double = (y0 - y1) / 2
        let x1p = cp * dx2 + sp * dy2
        let y1p = -sp * dx2 + cp * dy2
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var coef = den == 0 ? 0 : sqrt(max(0, num / den))
        if large == sweep { coef = -coef }
        let cxp = coef * rx * y1p / ry
        let cyp = -coef * ry * x1p / rx
        let cx: Double = cp * cxp - sp * cyp + (x0 + x1) / 2
        let cy: Double = sp * cxp + cp * cyp + (y0 + y1) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        }
        let ux = (x1p - cxp) / rx, uy = (y1p - cyp) / ry
        let vx = (-x1p - cxp) / rx, vy = (-y1p - cyp) / ry
        let theta1 = angle(1, 0, ux, uy)
        var dTheta = angle(ux, uy, vx, vy)
        if !sweep && dTheta > 0 { dTheta -= 2 * .pi }
        if sweep && dTheta < 0 { dTheta += 2 * .pi }

        let n = max(1, Int(ceil(abs(dTheta) / (.pi / 2))))
        let delta = dTheta / Double(n)
        let t = 4.0 / 3.0 * tan(delta / 4)
        func pt(_ th: Double) -> CGPoint {
            CGPoint(x: cx + rx * cp * cos(th) - ry * sp * sin(th), y: cy + rx * sp * cos(th) + ry * cp * sin(th))
        }
        func der(_ th: Double) -> CGPoint {
            CGPoint(x: -rx * cp * sin(th) - ry * sp * cos(th), y: -rx * sp * sin(th) + ry * cp * cos(th))
        }
        for i in 0..<n {
            let a = theta1 + Double(i) * delta, b = a + delta
            let pa = pt(a), pb = pt(b), da = der(a), db = der(b)
            path.addCurve(to: pb,
                          control1: CGPoint(x: pa.x + t * da.x, y: pa.y + t * da.y),
                          control2: CGPoint(x: pb.x - t * db.x, y: pb.y - t * db.y))
        }
    }

    private struct Tokenizer {
        let b: [UInt8]
        var i = 0
        init(_ b: [UInt8]) { self.b = b }

        var atEnd: Bool {
            var j = i
            while j < b.count, Tokenizer.isSep(b[j]) { j += 1 }
            return j >= b.count
        }

        static func isSep(_ c: UInt8) -> Bool {
            c == 32 || c == 44 || c == 9 || c == 10 || c == 13
        }
        static func isCmd(_ c: UInt8) -> Bool {
            switch c {
            case UInt8(ascii: "e"), UInt8(ascii: "E"): return false
            case 65...90, 97...122: return true
            default: return false
            }
        }

        mutating func skipSeps() { while i < b.count, Tokenizer.isSep(b[i]) { i += 1 } }

        mutating func command() -> UInt8? {
            skipSeps()
            guard i < b.count, Tokenizer.isCmd(b[i]) else { return nil }
            defer { i += 1 }
            return b[i]
        }

        mutating func hasNumber() -> Bool {
            skipSeps()
            guard i < b.count else { return false }
            let c = b[i]
            return (c >= 48 && c <= 57) || c == 45 || c == 43 || c == 46
        }

        mutating func skipJunk() { if i < b.count { i += 1 } }

        mutating func number() -> Double? {
            skipSeps()
            guard i < b.count else { return nil }
            let s = i
            if b[i] == 45 || b[i] == 43 { i += 1 }
            var sawDot = false, sawDigit = false
            while i < b.count {
                let c = b[i]
                if c >= 48 && c <= 57 { sawDigit = true; i += 1 }
                else if c == 46 && !sawDot { sawDot = true; i += 1 }
                else { break }
            }
            if i < b.count, b[i] == 101 || b[i] == 69 { // exponent
                var j = i + 1
                if j < b.count, b[j] == 45 || b[j] == 43 { j += 1 }
                if j < b.count, b[j] >= 48 && b[j] <= 57 {
                    i = j
                    while i < b.count, b[i] >= 48 && b[i] <= 57 { i += 1 }
                }
            }
            guard sawDigit, let str = String(bytes: b[s..<i], encoding: .ascii), let v = Double(str) else {
                i = max(i, s + 1)
                return nil
            }
            return v
        }
    }
}
