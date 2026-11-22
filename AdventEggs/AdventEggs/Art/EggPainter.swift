import SwiftUI

/// The egg, ported from Get Cracking's egg.js. It cracks in 8 stepped
/// landmarks so a child who can't read a clock still sees the day passing:
/// step 1 is a hairline near the top, steps 2-5 run the main zig-zag across
/// the shell, steps 6-8 branch new cracks and deepen them all.
///
/// Egg units: base at (0, 0), the egg grows up to y = -170.
struct EggPainter {
    enum Part { case whole, top, bottom }

    var day: Int
    var step: Int
    var part: Part = .whole
    var glow = false

    /// Fraction of the 24 hours at which each crack step lands (same as the app).
    static let stepAt: [Double] = [0.1, 0.22, 0.34, 0.46, 0.58, 0.7, 0.8, 0.9]
    static let mainLenByStep: [CGFloat] = [0, 0, 0.22, 0.46, 0.72, 1, 1, 1, 1]
    static let crackWidthByStep: [CGFloat] = [3, 3, 3.6, 4.2, 4.8, 5.4, 6.2, 7, 8]

    static func step(for progress: Double) -> Int {
        stepAt.filter { progress >= $0 }.count
    }

    /// Flat [x0, y0, x1, y1, ...] to points.
    static func pts(_ xy: [CGFloat]) -> [CGPoint] {
        stride(from: 0, to: xy.count - 1, by: 2).map { CGPoint(x: xy[$0], y: xy[$0 + 1]) }
    }

    static let zig: [CGPoint] = pts([-68, -74, -50, -88, -36, -72, -20, -92, -4, -74,
                                     12, -94, 28, -74, 44, -90, 68, -76])

    struct Branch {
        let step: Int
        let pts: [CGPoint]
    }

    static let branches: [Branch] = [
        Branch(step: 1, pts: pts([-30, -140, -22, -128, -27, -117, -17, -108])),
        Branch(step: 3, pts: pts([14, -150, 20, -138, 12, -128, 18, -118])),
        Branch(step: 5, pts: pts([34, -62, 40, -50, 31, -40])),
        Branch(step: 6, pts: pts([12, -94, 22, -106, 16, -116, 28, -128, 38, -122])),
        Branch(step: 6, pts: pts([-36, -72, -30, -58, -38, -48])),
        Branch(step: 7, pts: pts([-4, -74, -12, -60, -3, -50, -10, -36])),
        Branch(step: 7, pts: pts([-20, -92, -26, -104, -17, -108])),
        Branch(step: 8, pts: pts([-44, -66, -50, -52, -42, -42, -47, -30])),
        Branch(step: 8, pts: pts([44, -90, 50, -104, 42, -114, 46, -126])),
        Branch(step: 8, pts: pts([-6, -152, -12, -160])),
    ]

    static var shell: Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -170))
        p.addCurve(to: CGPoint(x: 64, y: -58), control1: CGPoint(x: 40, y: -170), control2: CGPoint(x: 64, y: -96))
        p.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 64, y: -20), control2: CGPoint(x: 36, y: 0))
        p.addCurve(to: CGPoint(x: -64, y: -58), control1: CGPoint(x: -36, y: 0), control2: CGPoint(x: -64, y: -20))
        p.addCurve(to: CGPoint(x: 0, y: -170), control1: CGPoint(x: -64, y: -96), control2: CGPoint(x: -40, y: -170))
        p.closeSubpath()
        return p
    }

    /// Festive shells: (shell, pattern) colours, picked by day.
    static let palettes: [(Color, Color)] = [
        (Color(hex: 0xfbf1dc), Color(hex: 0xd0504a)),
        (Color(hex: 0xe2f1e4), Color(hex: 0x4f9a5c)),
        (Color(hex: 0xfff1c2), Color(hex: 0xe0a43c)),
        (Color(hex: 0xdcecf6), Color(hex: 0x4f7fc0)),
        (Color(hex: 0xf3e4f2), Color(hex: 0xb46aa8)),
        (Color(hex: 0xfde3d3), Color(hex: 0xd0504a)),
    ]

    private var palette: (Color, Color) { Self.palettes[day % Self.palettes.count] }

    func draw(in context: GraphicsContext, size: CGSize) {
        var c = context
        let s = min(size.width / 160, size.height / 190)
        c.translateBy(x: size.width / 2, y: size.height - 8 * s)
        c.scaleBy(x: s, y: s)

        if part == .whole {
            if glow {
                c.fill(Draw.circle(0, -86, 120), with: .radialGradient(
                    Gradient(colors: [Color(hex: 0xfff3b0).opacity(0.9), Color(hex: 0xfff3b0).opacity(0)]),
                    center: CGPoint(x: 0, y: -86), startRadius: 40, endRadius: 120))
            }
            c.fill(Draw.oval(0, 2, 70, 13), with: .color(.ink.opacity(0.2)))
        }

        var piece = c
        if part != .whole { piece.clip(to: halfClip(top: part == .top)) }

        let shell = Self.shell
        piece.fill(shell, with: .color(palette.0))
        var inside = piece
        inside.clip(to: shell)
        pattern(inside)
        var shine = Path()
        shine.move(to: CGPoint(x: -40, y: -60))
        shine.addCurve(to: CGPoint(x: -6, y: -160), control1: CGPoint(x: -44, y: -110), control2: CGPoint(x: -26, y: -150))
        inside.stroke(shine, with: .color(.white.opacity(0.7)), style: Draw.style(9))
        inside.stroke(shell, with: .color(.ink.opacity(0.12)), style: StrokeStyle(lineWidth: 16))
        cracks(inside)
        piece.stroke(shell, with: .color(.ink), style: Draw.round)
        if part != .whole {
            piece.stroke(Self.zigPath, with: .color(.ink), style: Draw.style(5))
        }
    }

    private static var zigPath: Path {
        var p = Path()
        p.addLines(zig)
        return p
    }

    private func halfClip(top: Bool) -> Path {
        var pts = Self.zig
        if top {
            pts.append(CGPoint(x: 90, y: -76))
            pts.append(CGPoint(x: 90, y: -220))
            pts.append(CGPoint(x: -90, y: -220))
            pts.append(CGPoint(x: -90, y: -74))
        } else {
            pts.append(CGPoint(x: 90, y: -76))
            pts.append(CGPoint(x: 90, y: 30))
            pts.append(CGPoint(x: -90, y: 30))
            pts.append(CGPoint(x: -90, y: -74))
        }
        return Draw.poly(pts)
    }

    private func pattern(_ c: GraphicsContext) {
        let spot = palette.1
        switch day % 4 {
        case 0: // zig-zag band
            let band = Draw.poly(Self.pts([-70, -112, -52, -124, -36, -110, -20, -124, -4, -110, 12, -124, 28, -110,
                                           44, -124, 60, -110, 72, -118, 72, -100, -70, -96]))
            c.fill(band, with: .color(spot))
            for (x, y, r) in [(CGFloat(-30), CGFloat(-40), CGFloat(7)), (20, -30, 9), (-6, -150, 6)] {
                c.fill(Draw.circle(x, y, r), with: .color(spot))
            }
        case 1: // stripes
            for (i, y) in [CGFloat(-140), -104, -46].enumerated() {
                var p = Path()
                p.move(to: CGPoint(x: -70, y: y))
                p.addQuadCurve(to: CGPoint(x: 70, y: y), control: CGPoint(x: 0, y: y + 14))
                c.stroke(p, with: .color(spot), style: StrokeStyle(lineWidth: i == 1 ? 12 : 9))
            }
        case 2: // stars
            for (x, y, r) in [(CGFloat(-28), CGFloat(-128), CGFloat(11)), (26, -144, 8), (30, -100, 13), (-34, -78, 10),
                              (8, -60, 12), (-24, -34, 9), (40, -40, 8)] {
                c.fill(Draw.star(x, y, outer: r, inner: r * 0.45), with: .color(spot))
            }
        default: // spots
            for (x, y, r) in [(CGFloat(-30), CGFloat(-132), CGFloat(10)), (24, -146, 7), (32, -108, 12), (-40, -86, 8),
                              (-8, -104, 6), (10, -60, 11), (-30, -36, 9), (40, -40, 7), (-48, -58, 5)] {
                c.fill(Draw.circle(x, y, r), with: .color(spot))
            }
        }
    }

    private func cracks(_ c: GraphicsContext) {
        let n = min(max(step, 0), 8)
        guard n > 0 else { return }
        let width = Self.crackWidthByStep[n]
        let style = Draw.style(width)
        let len = Self.mainLenByStep[n]
        if len > 0 {
            c.stroke(Self.zigPath.trimmedPath(from: 0, to: len), with: .color(.ink), style: style)
        }
        for b in Self.branches where b.step <= n {
            var p = Path()
            p.addLines(b.pts)
            c.stroke(p, with: .color(.ink), style: Draw.style(width * 0.78))
        }
    }
}
