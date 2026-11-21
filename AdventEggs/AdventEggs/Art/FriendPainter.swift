import SwiftUI

/// Paints one friend into a Canvas.
///
/// Friend units: feet on y = 0, the friend grows upward (negative y), centred
/// on x = 0. Everything fits a 250 x 250 box, which `draw` scales to the canvas.
struct FriendPainter {
    let look: Look
    var blink = false
    var mouthOpen = false

    func draw(in context: GraphicsContext, size: CGSize) {
        var c = context
        let s = min(size.width, size.height) / 250
        c.translateBy(x: size.width / 2, y: size.height * 0.95)
        c.scaleBy(x: s, y: s)

        // soft ground shadow
        c.fill(Draw.oval(0, 0, 78, 11), with: .color(.ink.opacity(0.16)))

        switch look.kind {
        case .blob: blob(c)
        case .gingerbread: gingerbread(c)
        case .tree: tree(c)
        case .star: starCookie(c)
        case .pudding: pudding(c)
        }
    }

    private func has(_ test: (Look.Extra) -> Bool) -> Bool { look.extras.contains(where: test) }

    private var isPerson: Bool { look.skin != nil }

    // MARK: - The bean-shaped friends

    static func bean(_ w: CGFloat, _ h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: -w, y: -h * 0.45))
        p.addCurve(to: CGPoint(x: w, y: -h * 0.45),
                   control1: CGPoint(x: -w, y: -h * 1.15), control2: CGPoint(x: w, y: -h * 1.15))
        p.addCurve(to: CGPoint(x: 0, y: 0),
                   control1: CGPoint(x: w, y: -h * 0.05), control2: CGPoint(x: w * 0.75, y: 0))
        p.addCurve(to: CGPoint(x: -w, y: -h * 0.45),
                   control1: CGPoint(x: -w * 0.75, y: 0), control2: CGPoint(x: -w, y: -h * 0.05))
        p.closeSubpath()
        return p
    }

    private func blob(_ c: GraphicsContext) {
        let (w, h) = look.size.dims
        let body = Self.bean(w, h)

        // behind the body
        for x in look.extras { backExtra(x, c, w, h) }
        if case .halo = look.head { halo(c, w, h) }
        earsBack(c, w, h)
        feet(c, w, h)

        // body, with belly, hair / veil and bands clipped inside it
        c.fill(body, with: .color(look.body))
        var inside = c
        inside.clip(to: body)
        if let belly = look.belly {
            inside.fill(Draw.oval(0, -h * 0.26, w * 0.64, h * 0.32), with: .color(belly))
        }
        if let cap = look.cap {
            let bottom = -h * look.capDepth
            inside.fill(Draw.rect(-w * 1.3, -h * 1.3, w * 2.6, h * 1.3 + bottom, r: 30), with: .color(cap))
        }
        for x in look.extras { clippedExtra(x, inside, w, h) }
        // a soft shine on the upper left
        var shine = Path()
        shine.move(to: CGPoint(x: -w * 0.72, y: -h * 0.42))
        shine.addQuadCurve(to: CGPoint(x: -w * 0.3, y: -h * 0.9), control: CGPoint(x: -w * 0.78, y: -h * 0.82))
        inside.stroke(shine, with: .color(.white.opacity(0.35)), style: Draw.style(8))
        c.stroke(body, with: .color(.ink), style: Draw.round)

        // a person's face patch, with a fringe if the cap is hair
        if let skin = look.skin {
            let face = Draw.oval(0, -h * 0.6, w * 0.66, h * 0.27)
            c.fill(face, with: .color(skin))
            if let cap = look.cap, look.capDepth >= 0.45, look.capDepth < 0.6 {
                var fringe = c
                fringe.clip(to: face)
                fringe.fill(Draw.oval(0, -h * 0.88, w * 0.8, h * 0.13), with: .color(cap))
            }
            c.stroke(face, with: .color(.ink), style: Draw.style(4.5))
        }

        earsFront(c, w, h)
        face(c, w, h)
        for x in look.extras { frontExtra(x, c, w, h) }
        if !has({ if case .swaddle = $0 { return true }; if case .manger = $0 { return true }; return false }) {
            arms(c, w, h)
        }
        for x in look.extras { handExtra(x, c, w, h) }
        headwear(c, w, h)
    }

    // MARK: ears and feet

    private var earInner: Color { look.belly ?? Color.blush.opacity(0.7) }
    private var earFill: Color { look.earColor ?? look.body }

    private func earsBack(_ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        for s in [CGFloat(-1), 1] {
            switch look.ears {
            case .round:
                Draw.fillOut(c, Draw.circle(s * w * 0.62, -h * 0.86, 19), earFill)
                c.fill(Draw.circle(s * w * 0.62, -h * 0.86, 9), with: .color(earInner))
            case .fluffy:
                Draw.fillOut(c, Draw.circle(s * w * 0.9, -h * 0.82, 29), earFill)
                c.fill(Draw.circle(s * w * 0.94, -h * 0.8, 16), with: .color(look.belly ?? .white))
            case .long:
                Draw.fillOut(c, Draw.oval(s * w * 0.44, -h * 1.06, 14, 38, deg: s * 16), earFill)
                c.fill(Draw.oval(s * w * 0.46, -h * 1.06, 6, 26, deg: s * 16), with: .color(earInner))
            case .pointy:
                Draw.fillOut(c, Draw.oval(s * w * 0.42, -h * 1.04, 12, 32, deg: s * 12), earFill)
                c.fill(Draw.oval(s * w * 0.43, -h * 1.03, 5, 21, deg: s * 12), with: .color(earInner))
            case .mouse:
                Draw.fillOut(c, Draw.circle(s * w * 0.76, -h * 0.92, 31), earFill)
                c.fill(Draw.circle(s * w * 0.78, -h * 0.91, 19), with: .color(Color(hex: 0xf2b6c4)))
            case .tiny:
                Draw.fillOut(c, Draw.circle(s * w * 0.52, -h * 0.94, 11), earFill)
            case .none, .lamb:
                break
            }
        }
    }

    private func earsFront(_ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        guard case .lamb = look.ears else { return }
        for s in [CGFloat(-1), 1] {
            Draw.fillOut(c, Draw.oval(s * (w + 2), -h * 0.66, 23, 11, deg: s * 22), earFill)
        }
    }

    private func feet(_ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        if has({ if case .manger = $0 { return true }; return false }) { return }
        var color = look.body
        for x in look.extras { if case .webbedFeet(let col) = x { color = col } }
        for s in [CGFloat(-1), 1] {
            Draw.fillOut(c, Draw.oval(s * w * 0.42, -5, 19, 10), color)
        }
    }

    private func arms(_ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        let holding = has {
            switch $0 {
            case .gift, .jar, .holdNutcracker: return true
            default: return false
            }
        }
        for s in [CGFloat(-1), 1] {
            if holding {
                Draw.fillOut(c, Draw.oval(s * w * 0.48, -h * 0.28, 13, 16, deg: s * -40), look.body)
            } else {
                Draw.fillOut(c, Draw.oval(s * (w - 4), -h * 0.36, 12, 18, deg: s * -22), look.body)
            }
        }
    }

    // MARK: face

    private func face(_ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        let eyeY = isPerson ? -h * 0.62 : -h * 0.62
        let eyeX = isPerson ? w * 0.28 : w * 0.34

        for s in [CGFloat(-1), 1] {
            let x = s * eyeX
            if blink {
                var p = Path()
                p.move(to: CGPoint(x: x - 7, y: eyeY))
                p.addQuadCurve(to: CGPoint(x: x + 7, y: eyeY), control: CGPoint(x: x, y: eyeY + 6))
                Draw.stroke(c, p, .ink, 4)
            } else {
                c.fill(Draw.oval(x, eyeY, 6.5, 8.5), with: .color(.ink))
                c.fill(Draw.circle(x + 2, eyeY - 3, 2.4), with: .color(.white))
            }
            let cheekX = isPerson ? s * w * 0.44 : s * w * 0.54
            c.fill(Draw.oval(cheekX, -h * 0.5, 9, 6), with: .color(Color.blush.opacity(0.85)))
        }

        // beards sit under the mouth
        for x in look.extras {
            if case .beard(let col) = x {
                var p = Path()
                p.move(to: CGPoint(x: -w * 0.5, y: -h * 0.52))
                p.addQuadCurve(to: CGPoint(x: 0, y: -h * 0.2), control: CGPoint(x: -w * 0.5, y: -h * 0.24))
                p.addQuadCurve(to: CGPoint(x: w * 0.5, y: -h * 0.52), control: CGPoint(x: w * 0.5, y: -h * 0.24))
                p.addQuadCurve(to: CGPoint(x: -w * 0.5, y: -h * 0.52), control: CGPoint(x: 0, y: -h * 0.4))
                p.closeSubpath()
                Draw.fillOut(c, p, col, 4.5)
            }
        }

        let mouthY = -h * 0.49
        switch look.snout {
        case .none:
            mouth(c, y: mouthY)
        case .nose(let col):
            Draw.fillOut(c, Draw.oval(0, -h * 0.54, 7, 5.5), col, 3)
            mouth(c, y: mouthY + 2)
        case .muzzle(let col):
            Draw.fillOut(c, Draw.oval(0, -h * 0.47, w * 0.4, h * 0.15), col, 4.5)
            c.fill(Draw.oval(0, -h * 0.53, 7.5, 5.5), with: .color(.ink))
            mouth(c, y: -h * 0.45)
        case .beak(let col):
            let top = -h * 0.55
            let beak = Draw.poly([CGPoint(x: -15, y: top), CGPoint(x: 15, y: top), CGPoint(x: 0, y: top + 24)])
            Draw.fillOut(c, beak, col, 4.5)
            Draw.stroke(c, Draw.line(CGPoint(x: -9, y: top + 8), CGPoint(x: 9, y: top + 8)), Color(hex: 0xe9e1d2), 3)
        case .bill(let col):
            Draw.fillOut(c, Draw.oval(0, -h * 0.44, w * 0.52, h * 0.12), col, 4.5)
            c.fill(Draw.oval(-8, -h * 0.48, 2.5, 3.5), with: .color(.white.opacity(0.6)))
            c.fill(Draw.oval(8, -h * 0.48, 2.5, 3.5), with: .color(.white.opacity(0.6)))
        case .bigNose(let col):
            Draw.fillOut(c, Draw.oval(0, -h * 0.51, w * 0.2, h * 0.11), col, 3)
            c.fill(Draw.oval(-w * 0.06, -h * 0.55, 4, 3), with: .color(.white.opacity(0.5)))
            mouth(c, y: -h * 0.4)
        case .longSnout(let col):
            Draw.tube(c, Draw.line(CGPoint(x: 0, y: -h * 0.54), CGPoint(x: 0, y: -h * 0.3)), col, 11)
            mouth(c, y: -h * 0.47 + 0.01)
        }

        for x in look.extras {
            if case .whiskers = x {
                for s in [CGFloat(-1), 1] {
                    for dy in [CGFloat(-4), 4] {
                        Draw.stroke(c, Draw.line(CGPoint(x: s * 14, y: -h * 0.52 + dy),
                                                 CGPoint(x: s * 40, y: -h * 0.52 + dy * 2.2)), .ink, 2.5)
                    }
                }
            }
        }
    }

    private func mouth(_ c: GraphicsContext, y: CGFloat) {
        if mouthOpen {
            Draw.fillOut(c, Draw.oval(0, y + 2, 6.5, 7.5), Color(hex: 0xb8434a), 3.5)
            return
        }
        var p = Path()
        p.move(to: CGPoint(x: -7, y: y))
        p.addQuadCurve(to: CGPoint(x: 0, y: y), control: CGPoint(x: -3.5, y: y + 5))
        p.addQuadCurve(to: CGPoint(x: 7, y: y), control: CGPoint(x: 3.5, y: y + 5))
        Draw.stroke(c, p, .ink, 3.5)
    }

    // MARK: extras

    private func halo(_ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        let ring = Draw.oval(0, -h * 1.08, w * 0.6, 11)
        c.stroke(ring, with: .color(Color(hex: 0xfff1b0).opacity(0.7)), style: Draw.style(22))
        Draw.stroke(c, ring, .ink, 13)
        Draw.stroke(c, ring, .goldLeaf, 6)
    }

    private func backExtra(_ x: Look.Extra, _ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        switch x {
        case .wings(let col):
            for s in [CGFloat(-1), 1] {
                Draw.fillOut(c, Draw.oval(s * (w + 8), -h * 0.64, 27, 46, deg: s * 28), col)
                Draw.stroke(c, Draw.line(CGPoint(x: s * (w - 2), y: -h * 0.56), CGPoint(x: s * (w + 20), y: -h * 0.86)),
                            .ink.opacity(0.25), 3)
            }
        case .cape(let col):
            var p = Path()
            p.move(to: CGPoint(x: -w * 0.85, y: -h * 0.6))
            p.addLine(to: CGPoint(x: w * 0.85, y: -h * 0.6))
            p.addLine(to: CGPoint(x: w * 1.28, y: -2))
            p.addQuadCurve(to: CGPoint(x: -w * 1.28, y: -2), control: CGPoint(x: 0, y: 10))
            p.closeSubpath()
            Draw.fillOut(c, p, col)
        case .tailThin(let col):
            var p = Path()
            p.move(to: CGPoint(x: w * 0.6, y: -h * 0.14))
            p.addCurve(to: CGPoint(x: w + 40, y: -h * 0.6),
                       control1: CGPoint(x: w + 34, y: -h * 0.06), control2: CGPoint(x: w + 54, y: -h * 0.34))
            p.addQuadCurve(to: CGPoint(x: w + 24, y: -h * 0.66), control: CGPoint(x: w + 30, y: -h * 0.76))
            Draw.tube(c, p, col, 8)
        case .tailWide(let col):
            Draw.fillOut(c, Draw.oval(w + 14, -h * 0.1, 40, 15, deg: -14), col)
        case .spines(let col):
            let cy = -h * 0.55
            for i in 0..<15 {
                let a = (192 + CGFloat(i) * 11.2) * .pi / 180
                let da: CGFloat = 0.11
                let r0 = w * 0.86
                let r1 = w * 1.36
                let p = Draw.poly([
                    CGPoint(x: cos(a - da) * r0, y: cy + sin(a - da) * r0 * 0.95),
                    CGPoint(x: cos(a) * r1, y: cy + sin(a) * r1 * 0.95),
                    CGPoint(x: cos(a + da) * r0, y: cy + sin(a + da) * r0 * 0.95),
                ])
                Draw.fillOut(c, p, col, 4)
            }
        case .staff:
            var p = Path()
            p.move(to: CGPoint(x: w + 12, y: -2))
            p.addLine(to: CGPoint(x: w + 12, y: -h * 1.04))
            p.addCurve(to: CGPoint(x: w - 12, y: -h * 0.98),
                       control1: CGPoint(x: w + 12, y: -h * 1.24), control2: CGPoint(x: w - 14, y: -h * 1.22))
            Draw.tube(c, p, Color(hex: 0x9a6a3e), 7)
        default:
            break
        }
    }

    /// Drawn inside the body outline (bands, sashes, markings).
    private func clippedExtra(_ x: Look.Extra, _ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        switch x {
        case .belt(let col):
            c.fill(Draw.rect(-w * 1.2, -h * 0.33, w * 2.4, 13), with: .color(col))
            c.stroke(Draw.rect(-w * 1.2, -h * 0.33, w * 2.4, 13), with: .color(.ink.opacity(0.5)), style: Draw.style(3))
        case .sash(let col):
            let band = Draw.line(CGPoint(x: -w, y: -h * 0.56), CGPoint(x: w, y: -h * 0.06))
            c.stroke(band, with: .color(.ink.opacity(0.5)), style: StrokeStyle(lineWidth: 20))
            c.stroke(band, with: .color(col), style: StrokeStyle(lineWidth: 15))
        case .eyeStripe(let col):
            c.stroke(Draw.line(CGPoint(x: -w * 1.1, y: -h * 0.6), CGPoint(x: w * 1.1, y: -h * 0.6)),
                     with: .color(col), style: StrokeStyle(lineWidth: 16))
            c.fill(Draw.oval(0, -h * 0.98, w * 0.7, h * 0.16), with: .color(col.opacity(0.85)))
        case .swaddle:
            for i in 0..<3 {
                let y = -h * (0.12 + CGFloat(i) * 0.12)
                var p = Path()
                p.move(to: CGPoint(x: -w * 1.1, y: y + 20))
                p.addQuadCurve(to: CGPoint(x: w * 1.1, y: y - 14), control: CGPoint(x: 0, y: y + 12))
                c.stroke(p, with: .color(Color(hex: 0xd9c9a8)), style: Draw.style(5))
            }
        default:
            break
        }
    }

    /// Drawn on the front of the body, under the arms.
    private func frontExtra(_ x: Look.Extra, _ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        switch x {
        case .buttons(let col):
            for i in 0..<3 {
                Draw.fillOut(c, Draw.circle(0, -h * (0.4 - CGFloat(i) * 0.13), 5.5), col, 3)
            }
        case .bell(let col):
            Draw.fillOut(c, Draw.circle(0, -h * 0.34, 10), col, 4)
            Draw.stroke(c, Draw.line(CGPoint(x: -4, y: -h * 0.34 + 3), CGPoint(x: 4, y: -h * 0.34 + 3)), .ink, 3)
        case .pouch:
            var p = Path()
            p.move(to: CGPoint(x: -w * 0.44, y: -h * 0.27))
            p.addQuadCurve(to: CGPoint(x: w * 0.44, y: -h * 0.27), control: CGPoint(x: 0, y: -h * 0.12))
            Draw.stroke(c, p, .ink, 4)
        case .fringe(let col):
            for (dx, r) in [(CGFloat(-9), CGFloat(10)), (5, 12), (15, 8)] {
                Draw.fillOut(c, Draw.circle(dx, -h * 0.97, r), col, 4)
            }
        case .sparkles(let col):
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(-w - 22, -h * 0.92, 10), (w + 26, -h * 1.02, 12),
                                                         (-w - 32, -h * 0.38, 8), (w + 34, -h * 0.34, 9)]
            for (x, y, r) in spots {
                Draw.fillOut(c, Draw.twinkle(x, y, r), col, 3)
            }
        case .snowflake:
            let cy = -h * 0.28
            for i in 0..<3 {
                let a = CGFloat(i) * .pi / 3
                let d = CGPoint(x: cos(a) * 13, y: sin(a) * 13)
                let seg = Draw.line(CGPoint(x: -d.x, y: cy - d.y), CGPoint(x: d.x, y: cy + d.y))
                Draw.tube(c, seg, .white, 3.5)
            }
        case .manger:
            let top = -h * 0.4
            for i in 0..<9 {
                let x = -w * 1.2 + CGFloat(i) * w * 0.3
                let tilt = CGFloat(i % 3 - 1) * 8
                Draw.tube(c, Draw.line(CGPoint(x: x, y: top + 6), CGPoint(x: x + tilt, y: top - 14)), Color(hex: 0xf0cd6a), 4)
            }
            let trough = Draw.poly([CGPoint(x: -w * 1.55, y: top), CGPoint(x: w * 1.55, y: top),
                                    CGPoint(x: w * 1.2, y: -2), CGPoint(x: -w * 1.2, y: -2)])
            Draw.fillOut(c, trough, Color(hex: 0xa8743f))
            for f in [CGFloat(0.36), 0.68] {
                let y = top * (1 - f)
                c.stroke(Draw.line(CGPoint(x: -w * 1.35, y: y), CGPoint(x: w * 1.35, y: y)),
                         with: .color(.ink.opacity(0.35)), style: Draw.style(3))
            }
        default:
            break
        }
    }

    /// Things held in the hands, drawn over the arms.
    private func handExtra(_ x: Look.Extra, _ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        switch x {
        case .gift(let box, let ribbon):
            let y = -h * 0.44
            Draw.fillOut(c, Draw.rect(-24, y, 48, 40, r: 5), box, 4.5)
            c.fill(Draw.rect(-5, y, 10, 40), with: .color(ribbon))
            c.fill(Draw.rect(-24, y + 15, 48, 9), with: .color(ribbon))
            Draw.fillOut(c, Draw.oval(-9, y - 4, 9, 6, deg: -20), ribbon, 3)
            Draw.fillOut(c, Draw.oval(9, y - 4, 9, 6, deg: 20), ribbon, 3)
        case .jar(let col):
            let y = -h * 0.26
            Draw.fillOut(c, Draw.rect(-10, y - 34, 20, 14, r: 3), col, 4)
            Draw.fillOut(c, Draw.oval(0, y, 23, 20), col, 4.5)
            Draw.fillOut(c, Draw.oval(0, y - 36, 15, 6), .goldLeaf, 3.5)
            c.fill(Draw.oval(-8, y - 6, 5, 8), with: .color(.white.opacity(0.45)))
        case .wand:
            let tip = CGPoint(x: w + 22, y: -h * 0.86)
            Draw.tube(c, Draw.line(CGPoint(x: w * 0.82, y: -h * 0.34), tip), Color(hex: 0xf6e7c2), 4)
            Draw.fillOut(c, Draw.star(tip.x, tip.y, outer: 15, inner: 7), .goldLeaf, 4)
        case .holdNutcracker:
            let x = w * 0.08
            let y = -h * 0.42
            Draw.fillOut(c, Draw.rect(x - 11, y, 22, 32, r: 5), Color(hex: 0xc23b3f), 3.5)
            Draw.fillOut(c, Draw.circle(x, y - 6, 9), Color(hex: 0xf6d2b4), 3.5)
            Draw.fillOut(c, Draw.rect(x - 8, y - 30, 16, 18, r: 2), Color(hex: 0x2d2a3a), 3.5)
            c.fill(Draw.rect(x - 8, y - 15, 16, 3), with: .color(.goldLeaf))
        default:
            break
        }
    }

    // MARK: headwear

    private func headwear(_ c: GraphicsContext, _ w: CGFloat, _ h: CGFloat) {
        switch look.head {
        case .none, .halo:
            break
        case .crown(let col):
            let yb = -h * 0.88
            let crown = Draw.poly([
                CGPoint(x: -w * 0.46, y: yb), CGPoint(x: -w * 0.5, y: yb - 32), CGPoint(x: -w * 0.24, y: yb - 16),
                CGPoint(x: 0, y: yb - 38), CGPoint(x: w * 0.24, y: yb - 16), CGPoint(x: w * 0.5, y: yb - 32),
                CGPoint(x: w * 0.46, y: yb),
            ])
            Draw.fillOut(c, crown, col, 5)
            Draw.fillOut(c, Draw.circle(0, yb - 10, 5), Color(hex: 0xc23b3f), 3)
            Draw.fillOut(c, Draw.circle(-w * 0.28, yb - 7, 3.5), Color(hex: 0x4f7fc0), 2.5)
            Draw.fillOut(c, Draw.circle(w * 0.28, yb - 7, 3.5), Color(hex: 0x3f8a6a), 2.5)
        case .tiara(let col):
            let yb = -h * 0.9
            let tiara = Draw.poly([
                CGPoint(x: -w * 0.36, y: yb), CGPoint(x: -w * 0.24, y: yb - 12), CGPoint(x: -w * 0.1, y: yb - 6),
                CGPoint(x: 0, y: yb - 24), CGPoint(x: w * 0.1, y: yb - 6), CGPoint(x: w * 0.24, y: yb - 12),
                CGPoint(x: w * 0.36, y: yb),
            ])
            Draw.fillOut(c, tiara, col, 4)
            Draw.fillOut(c, Draw.circle(0, yb - 9, 4), Color(hex: 0xf28ab8), 2.5)
        case .shako:
            let base = -h * 0.84
            Draw.fillOut(c, Draw.rect(-w * 0.58, base - 70, w * 1.16, 70, r: 6), Color(hex: 0x2d2a3a))
            c.fill(Draw.rect(-w * 0.58 + 3, base - 16, w * 1.16 - 6, 12), with: .color(.goldLeaf))
            Draw.fillOut(c, Draw.oval(0, base, w * 0.66, 9), Color(hex: 0x2d2a3a), 5)
            Draw.fillOut(c, Draw.star(0, base - 42, outer: 12, inner: 6), .goldLeaf, 3.5)
            Draw.fillOut(c, Draw.oval(0, base - 84, 11, 19), .white, 5)
            c.fill(Draw.oval(0, base - 76, 7, 7), with: .color(Color(hex: 0xc23b3f)))
        case .bow(let col):
            let bx = w * 0.42
            let by = -h * 0.92
            Draw.fillOut(c, Draw.oval(bx - 14, by, 15, 10, deg: -25), col, 4)
            Draw.fillOut(c, Draw.oval(bx + 14, by, 15, 10, deg: 25), col, 4)
            Draw.fillOut(c, Draw.circle(bx, by, 6.5), col, 4)
        case .wool:
            let puffs: [(CGFloat, CGFloat, CGFloat)] = [(-w * 0.42, -h * 0.9, 18), (-w * 0.18, -h * 0.98, 19),
                                                       (w * 0.12, -h * 1.0, 20), (w * 0.4, -h * 0.91, 17)]
            for (x, y, r) in puffs { Draw.stroke(c, Draw.circle(x, y, r), .ink, 12) }
            for (x, y, r) in puffs { c.fill(Draw.circle(x, y, r), with: .color(look.body)) }
        case .band(let col):
            var p = Path()
            p.move(to: CGPoint(x: -w * 0.68, y: -h * 0.7))
            p.addQuadCurve(to: CGPoint(x: w * 0.68, y: -h * 0.7), control: CGPoint(x: 0, y: -h * 0.98))
            Draw.tube(c, p, col, 7)
        case .turban(let col):
            Draw.fillOut(c, Draw.oval(0, -h * 0.92, w * 0.76, h * 0.19), col)
            var wrap = Path()
            wrap.move(to: CGPoint(x: -w * 0.6, y: -h * 0.86))
            wrap.addQuadCurve(to: CGPoint(x: w * 0.6, y: -h * 1.0), control: CGPoint(x: 0, y: -h * 0.86))
            Draw.stroke(c, wrap, .ink.opacity(0.35), 3.5)
            Draw.fillOut(c, Draw.oval(0, -h * 0.84, 7, 9), Color(hex: 0x3f8a6a), 3)
        }
    }

    // MARK: - Baking friends (cookie shapes)

    private func cookieFace(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, spread: CGFloat = 15) {
        for s in [CGFloat(-1), 1] {
            if blink {
                Draw.stroke(c, Draw.line(CGPoint(x: x + s * spread - 5, y: y), CGPoint(x: x + s * spread + 5, y: y)), .ink, 4)
            } else {
                c.fill(Draw.oval(x + s * spread, y, 5.5, 7), with: .color(.ink))
                c.fill(Draw.circle(x + s * spread + 1.5, y - 2.5, 2), with: .color(.white))
            }
            c.fill(Draw.oval(x + s * (spread + 9), y + 10, 7.5, 5), with: .color(Color.blush.opacity(0.9)))
        }
        if mouthOpen {
            Draw.fillOut(c, Draw.oval(x, y + 15, 6, 7), Color(hex: 0xb8434a), 3)
        } else {
            var p = Path()
            p.move(to: CGPoint(x: x - 8, y: y + 12))
            p.addQuadCurve(to: CGPoint(x: x + 8, y: y + 12), control: CGPoint(x: x, y: y + 21))
            Draw.stroke(c, p, .ink, 3.5)
        }
    }

    private func icingSquiggle(_ c: GraphicsContext, from a: CGPoint, to b: CGPoint) {
        var p = Path()
        p.move(to: a)
        let steps = 4
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = a.x + (b.x - a.x) * t
            let y = a.y + (b.y - a.y) * t
            let bump: CGFloat = i.isMultiple(of: 2) ? -5 : 5
            p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - (b.x - a.x) / CGFloat(steps * 2), y: y + bump))
        }
        Draw.stroke(c, p, .white, 4)
    }

    private func gingerbread(_ c: GraphicsContext) {
        let col = look.body
        let head = Draw.circle(0, -150, 40)
        let torso = Draw.rect(-36, -118, 72, 78, r: 26)
        let limbs: [(CGPoint, CGPoint)] = [
            (CGPoint(x: -26, y: -100), CGPoint(x: -70, y: -80)),
            (CGPoint(x: 26, y: -100), CGPoint(x: 70, y: -80)),
            (CGPoint(x: -16, y: -54), CGPoint(x: -30, y: -10)),
            (CGPoint(x: 16, y: -54), CGPoint(x: 30, y: -10)),
        ]
        // outline pass, then fill pass: one clean silhouette
        for p in [head, torso] { Draw.stroke(c, p, .ink, 12) }
        for (a, b) in limbs { Draw.stroke(c, Draw.line(a, b), .ink, 42) }
        for p in [head, torso] { c.fill(p, with: .color(col)) }
        for (a, b) in limbs { Draw.stroke(c, Draw.line(a, b), col, 30) }
        c.stroke(Draw.circle(-8, -160, 26).trimmedPath(from: 0.55, to: 0.8),
                 with: .color(.white.opacity(0.3)), style: Draw.style(7))

        icingSquiggle(c, from: CGPoint(x: -62, y: -96), to: CGPoint(x: -56, y: -70))
        icingSquiggle(c, from: CGPoint(x: 56, y: -70), to: CGPoint(x: 62, y: -96))
        icingSquiggle(c, from: CGPoint(x: -40, y: -22), to: CGPoint(x: -16, y: -18))
        icingSquiggle(c, from: CGPoint(x: 16, y: -18), to: CGPoint(x: 40, y: -22))

        let gumdrops = [Color(hex: 0xd63b4f), Color(hex: 0x4f9a5c), Color(hex: 0xf0b63c)]
        for (i, g) in gumdrops.enumerated() {
            Draw.fillOut(c, Draw.circle(0, -100 + CGFloat(i) * 20, 6.5), g, 3)
        }
        cookieFace(c, 0, -156, spread: 14)
    }

    private func tree(_ c: GraphicsContext) {
        let col = look.body
        let trunk = Draw.rect(-16, -46, 32, 44, r: 6)
        let tiers = [
            Draw.poly([CGPoint(x: -80, y: -42), CGPoint(x: 80, y: -42), CGPoint(x: 0, y: -124)]),
            Draw.poly([CGPoint(x: -64, y: -96), CGPoint(x: 64, y: -96), CGPoint(x: 0, y: -164)]),
            Draw.poly([CGPoint(x: -46, y: -144), CGPoint(x: 46, y: -144), CGPoint(x: 0, y: -198)]),
        ]
        Draw.stroke(c, trunk, .ink, 12)
        for t in tiers { Draw.stroke(c, t, .ink, 24) }
        c.fill(trunk, with: .color(Color(hex: 0x9a6a3e)))
        for t in tiers {
            c.fill(t, with: .color(col))
            Draw.stroke(c, t, col, 12)
        }
        // icing garlands
        for (y, half) in [(CGFloat(-60), CGFloat(66)), (-112, 50), (-158, 32)] {
            var p = Path()
            p.move(to: CGPoint(x: -half, y: y))
            p.addQuadCurve(to: CGPoint(x: half, y: y), control: CGPoint(x: 0, y: y + 18))
            Draw.stroke(c, p, .white, 5)
        }
        let sprinkles: [(CGFloat, CGFloat, UInt32)] = [(-44, -50, 0xd63b4f), (42, -52, 0xf0b63c), (-30, -104, 0x6fb3c9),
                                                      (30, -106, 0xd63b4f), (-14, -150, 0xf0b63c), (16, -170, 0xf2a0b8),
                                                      (52, -70, 0xf2a0b8), (-56, -74, 0xf0b63c)]
        for (x, y, hex) in sprinkles {
            Draw.fillOut(c, Draw.circle(x, y, 5), Color(hex: hex), 2.5)
        }
        Draw.fillOut(c, Draw.star(0, -206, outer: 20, inner: 9), .goldLeaf, 5)
        cookieFace(c, 0, -88, spread: 16)
    }

    private func starCookie(_ c: GraphicsContext) {
        let col = look.body
        let shape = Draw.star(0, -104, outer: 96, inner: 48)
        Draw.stroke(c, shape, .ink, 22)
        c.fill(shape, with: .color(col))
        Draw.stroke(c, shape, col, 10)
        let icing = Draw.star(0, -104, outer: 74, inner: 37)
        c.stroke(icing, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [2, 9]))
        for i in 0..<10 {
            let x = (hash01(Double(i) * 3.1) - 0.5) * 80
            let y = -104 + (hash01(Double(i) * 7.7) - 0.5) * 70
            c.fill(Draw.circle(x, y, 2.2), with: .color(.white.opacity(0.8)))
        }
        cookieFace(c, 0, -110, spread: 17)
    }

    private func pudding(_ c: GraphicsContext) {
        Draw.fillOut(c, Draw.oval(0, -10, 94, 15), Color(hex: 0xe9f0f6), 5)
        var dome = Path()
        dome.move(to: CGPoint(x: -76, y: -16))
        dome.addCurve(to: CGPoint(x: 76, y: -16), control1: CGPoint(x: -82, y: -176), control2: CGPoint(x: 82, y: -176))
        dome.addQuadCurve(to: CGPoint(x: -76, y: -16), control: CGPoint(x: 0, y: -4))
        dome.closeSubpath()
        c.fill(dome, with: .color(look.body))
        var inside = c
        inside.clip(to: dome)
        for i in 0..<16 {
            let x = (hash01(Double(i) * 5.3) - 0.5) * 130
            let y = -30 - hash01(Double(i) * 2.9) * 70
            inside.fill(Draw.oval(x, y, 4, 3), with: .color(Color(hex: 0x3a1f18)))
        }
        // custard poured over the top, dripping down
        let custard = Color(hex: 0xfdf3d0)
        inside.fill(Draw.oval(0, -134, 84, 34), with: .color(custard))
        for (x, y, rx, ry) in [(CGFloat(-46), CGFloat(-106), CGFloat(10), CGFloat(15)), (-12, -100, 9, 18), (26, -104, 10, 14), (54, -112, 8, 11)] {
            inside.fill(Draw.oval(x, y, rx, ry), with: .color(custard))
        }
        inside.stroke(Draw.oval(-26, -126, 30, 10).trimmedPath(from: 0.5, to: 0.85), with: .color(.white), style: Draw.style(5))
        c.stroke(dome, with: .color(.ink), style: Draw.round)
        // holly sprig
        Draw.fillOut(c, Draw.oval(-18, -142, 18, 8, deg: -25), Color(hex: 0x3f8a5a), 4)
        Draw.fillOut(c, Draw.oval(18, -142, 18, 8, deg: 25), Color(hex: 0x3f8a5a), 4)
        for (x, y) in [(CGFloat(0), CGFloat(-146)), (-7, -138), (7, -138)] {
            Draw.fillOut(c, Draw.circle(x, y, 6), Color(hex: 0xd63b4f), 3)
        }
        cookieFace(c, 0, -70, spread: 20)
    }
}
