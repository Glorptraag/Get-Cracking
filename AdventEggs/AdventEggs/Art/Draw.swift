import SwiftUI

/// Small drawing helpers shared by every painter. Friend, egg and scene art
/// all use the same chunky outline so they read as one hand.
enum Draw {
    static let round = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)

    static func style(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    /// An ellipse centred on (cx, cy), optionally turned by `deg` degrees.
    static func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, deg: CGFloat = 0) -> Path {
        let base = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
        let turn = CGAffineTransform(rotationAngle: deg * .pi / 180)
        let move = CGAffineTransform(translationX: cx, y: cy)
        return base.applying(turn.concatenating(move))
    }

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        oval(cx, cy, r, r)
    }

    static func poly(_ pts: [CGPoint]) -> Path {
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        return p
    }

    static func line(_ a: CGPoint, _ b: CGPoint) -> Path {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        return p
    }

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat = 0) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
    }

    /// A star with `points` points around (cx, cy), top point straight up.
    static func star(_ cx: CGFloat, _ cy: CGFloat, outer: CGFloat, inner: CGFloat, points: Int = 5) -> Path {
        var pts: [CGPoint] = []
        let n = points * 2
        for i in 0..<n {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            pts.append(CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r))
        }
        return poly(pts)
    }

    /// A four-point twinkle.
    static func twinkle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        star(cx, cy, outer: r, inner: r * 0.32, points: 4)
    }

    /// Fill, then the chunky outline.
    static func fillOut(_ c: GraphicsContext, _ p: Path, _ color: Color, _ width: CGFloat = 6) {
        c.fill(p, with: .color(color))
        c.stroke(p, with: .color(.ink), style: style(width))
    }

    static func stroke(_ c: GraphicsContext, _ p: Path, _ color: Color, _ width: CGFloat) {
        c.stroke(p, with: .color(color), style: style(width))
    }

    /// A thick stroked line with an outline (a tail, a staff).
    static func tube(_ c: GraphicsContext, _ p: Path, _ color: Color, _ width: CGFloat) {
        c.stroke(p, with: .color(.ink), style: style(width + 9))
        c.stroke(p, with: .color(color), style: style(width))
    }
}

/// Deterministic noise in 0..<1, so snowflakes and stars stay put between frames.
func hash01(_ x: Double) -> Double {
    let s = sin(x * 12.9898 + 78.233) * 43758.5453
    return s - floor(s)
}
