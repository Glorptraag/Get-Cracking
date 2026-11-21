import SwiftUI

/// Paints the winter village behind the doors: dusk sky, the star, moon,
/// snowy hills, the church and houses, gift shadows and a lit path. The sky
/// and the snow run edge to edge of the screen; the village sits on the board.
struct VillagePainter {
    let fit: SceneFit

    func draw(in context: GraphicsContext, size: CGSize) {
        sky(context, size)

        var c = context
        c.translateBy(x: fit.origin.x, y: fit.origin.y)
        c.scaleBy(x: fit.scale, y: fit.scale)

        // the board's units, extended to the screen edges
        let left = -fit.origin.x / fit.scale
        let right = (size.width - fit.origin.x) / fit.scale
        let bottom = (size.height - fit.origin.y) / fit.scale

        moon(c)
        bethlehemStar(c)
        hills(c, left: left, right: right)
        c.fill(Draw.rect(left, SceneBoard.horizon, right - left, bottom - SceneBoard.horizon + 10),
               with: .color(Color(hex: 0xeef3f8)))
        sidePines(c, left: left, right: right)

        // back row
        house(c, x: 40, y: 430, w: 300, h: 270, peak: 330, wall: Color(hex: 0xc4674a), roof: Color(hex: 0x5a4660), chimney: true)
        house(c, x: 660, y: 430, w: 300, h: 270, peak: 330, wall: Color(hex: 0x6f8fa6), roof: Color(hex: 0x4a3a4a), chimney: false)
        church(c)
        // snowy path down from the middle house
        let path = Draw.poly([CGPoint(x: 450, y: 1260), CGPoint(x: 550, y: 1260), CGPoint(x: 660, y: bottom + 10),
                              CGPoint(x: 340, y: bottom + 10)])
        c.fill(path, with: .color(Color(hex: 0xd9e3ee)))
        // front row
        house(c, x: 20, y: 860, w: 300, h: 400, peak: 760, wall: Color(hex: 0xe0b15a), roof: Color(hex: 0x7a3f45), chimney: true)
        house(c, x: 350, y: 860, w: 300, h: 400, peak: 740, wall: Color(hex: 0x86a874), roof: Color(hex: 0x3f4a6a), chimney: false)
        house(c, x: 680, y: 860, w: 300, h: 400, peak: 760, wall: Color(hex: 0xc0656a), roof: Color(hex: 0x4a5a3f), chimney: true)
        fairyLights(c)

        for slot in DoorSlot.all { surround(c, slot) }
    }

    // MARK: sky

    private func sky(_ c: GraphicsContext, _ size: CGSize) {
        let full = Path(CGRect(origin: .zero, size: size))
        let horizonY = fit.origin.y + SceneBoard.horizon * fit.scale
        c.fill(full, with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(hex: 0x15203f), location: 0),
                .init(color: Color(hex: 0x2c3d6e), location: 0.45),
                .init(color: Color(hex: 0x8c7fae), location: 0.85),
                .init(color: Color(hex: 0xe8b9a8), location: 1),
            ]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: max(horizonY, 1))))
        for i in 0..<90 {
            let x = hash01(Double(i) * 1.7) * size.width
            let y = hash01(Double(i) * 3.3) * horizonY * 0.8
            let r = 0.6 + hash01(Double(i) * 9.1) * 1.6
            c.fill(Draw.circle(x, y, r), with: .color(.white.opacity(0.35 + hash01(Double(i) * 4.4) * 0.5)))
        }
    }

    private func moon(_ c: GraphicsContext) {
        c.fill(Draw.circle(850, 150, 110), with: .radialGradient(
            Gradient(colors: [Color(hex: 0xfdf3d6).opacity(0.45), .clear]),
            center: CGPoint(x: 850, y: 150), startRadius: 40, endRadius: 110))
        c.fill(Draw.circle(850, 150, 44), with: .color(Color(hex: 0xfdf3d6)))
        c.fill(Draw.circle(838, 140, 9), with: .color(Color(hex: 0xeadfc0)))
        c.fill(Draw.circle(862, 166, 6), with: .color(Color(hex: 0xeadfc0)))
    }

    private func bethlehemStar(_ c: GraphicsContext) {
        c.fill(Draw.circle(500, 48, 120), with: .radialGradient(
            Gradient(colors: [Color(hex: 0xfff1b0).opacity(0.7), .clear]),
            center: CGPoint(x: 500, y: 48), startRadius: 10, endRadius: 120))
        Draw.fillOut(c, Draw.star(500, 48, outer: 50, inner: 9, points: 4), Color(hex: 0xffe27a), 3)
        Draw.fillOut(c, Draw.star(500, 48, outer: 26, inner: 7, points: 4).applying(
            CGAffineTransform(translationX: -500, y: -48).concatenating(CGAffineTransform(rotationAngle: .pi / 4))
                .concatenating(CGAffineTransform(translationX: 500, y: 48))), Color(hex: 0xfff6cf), 2.5)
    }

    private func hills(_ c: GraphicsContext, left: CGFloat, right: CGFloat) {
        for (layer, base, amp, color) in [(0, CGFloat(650), CGFloat(40), Color(hex: 0xb9c6dd)),
                                          (1, 715, 30, Color(hex: 0xd6e0ee))] {
            var p = Path()
            p.move(to: CGPoint(x: left - 10, y: SceneBoard.horizon + 20))
            var x = left - 10
            while x <= right + 20 {
                let y = base - amp * CGFloat(sin(Double(x) / 140 + Double(layer) * 2.1)) - amp * 0.4 * CGFloat(sin(Double(x) / 53))
                p.addLine(to: CGPoint(x: x, y: y))
                x += 20
            }
            p.addLine(to: CGPoint(x: right + 20, y: SceneBoard.horizon + 20))
            p.closeSubpath()
            c.fill(p, with: .color(color))
        }
        // little pines along the far hill
        var x = left + 30
        var i = 0
        while x < right {
            let y = 640 - 30 * CGFloat(sin(Double(x) / 140 + 2.1))
            pine(c, x: x, base: y + 30, h: 46 + CGFloat(hash01(Double(i)) * 24), color: Color(hex: 0x3f5a6a), outline: false)
            x += 70 + CGFloat(hash01(Double(i) * 2.3) * 90)
            i += 1
        }
    }

    private func sidePines(_ c: GraphicsContext, left: CGFloat, right: CGFloat) {
        // only visible when the screen is wider than the board (iPad)
        var x = left + 40
        var i = 0
        while x < -40 {
            pine(c, x: x, base: 1240 + CGFloat(hash01(Double(i)) * 120), h: 260, color: Color(hex: 0x2f6a4f), outline: true)
            x += 130
            i += 1
        }
        x = right - 40
        while x > 1040 {
            pine(c, x: x, base: 1240 + CGFloat(hash01(Double(i)) * 120), h: 260, color: Color(hex: 0x2f6a4f), outline: true)
            x -= 130
            i += 1
        }
    }

    private func pine(_ c: GraphicsContext, x: CGFloat, base: CGFloat, h: CGFloat, color: Color, outline: Bool) {
        let w = h * 0.42
        for tier in 0..<3 {
            let t = CGFloat(tier)
            let top = base - h + t * h * 0.22
            let bot = base - h * 0.45 + t * h * 0.22
            let half = w * (0.55 + t * 0.25)
            let tri = Draw.poly([CGPoint(x: x - half, y: bot), CGPoint(x: x + half, y: bot), CGPoint(x: x, y: top)])
            if outline { Draw.fillOut(c, tri, color, 5) } else { c.fill(tri, with: .color(color)) }
            var snow = Path()
            snow.move(to: CGPoint(x: x - half * 0.5, y: (top + bot) / 2))
            snow.addLine(to: CGPoint(x: x, y: top + 2))
            snow.addLine(to: CGPoint(x: x + half * 0.5, y: (top + bot) / 2))
            c.stroke(snow, with: .color(.white.opacity(0.9)), style: Draw.style(outline ? 9 : 4))
        }
    }

    // MARK: buildings

    private func house(_ c: GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, peak: CGFloat,
                       wall: Color, roof: Color, chimney: Bool) {
        let cx = x + w / 2
        if chimney {
            let chX = x + w * 0.7
            Draw.fillOut(c, Draw.rect(chX, peak + 18, 38, 80), Color(hex: 0x9a5a48), 5)
            Draw.fillOut(c, Draw.rect(chX - 6, peak + 8, 50, 18, r: 9), .white, 5)
            for n in 0..<3 {
                let k = CGFloat(n)
                c.fill(Draw.circle(chX + 22 + k * 14, peak - 12 - k * 26, 12 + k * 4), with: .color(.white.opacity(0.35 - Double(k) * 0.08)))
            }
        }
        Draw.fillOut(c, Draw.rect(x, y, w, h), wall, 5)
        // a few painted bricks
        for i in 0..<7 {
            let bx = x + 20 + CGFloat(hash01(Double(i) * 5.1 + Double(x))) * (w - 60)
            let by = y + 20 + CGFloat(hash01(Double(i) * 7.9 + Double(y))) * (h - 40)
            c.stroke(Draw.rect(bx, by, 26, 11, r: 2), with: .color(.ink.opacity(0.12)), style: Draw.style(2.5))
        }
        let roofPath = Draw.poly([CGPoint(x: x - 22, y: y + 4), CGPoint(x: cx, y: peak), CGPoint(x: x + w + 22, y: y + 4)])
        Draw.fillOut(c, roofPath, roof, 5)
        var snow = Path()
        snow.move(to: CGPoint(x: x - 18, y: y))
        snow.addLine(to: CGPoint(x: cx, y: peak + 4))
        snow.addLine(to: CGPoint(x: x + w + 18, y: y))
        Draw.tube(c, snow, .white, 16)
        // icicles under the eaves
        var ix = x + 6
        var i = 0
        while ix < x + w - 6 {
            let len = 10 + CGFloat(hash01(Double(i) + Double(x)) * 16)
            Draw.fillOut(c, Draw.poly([CGPoint(x: ix, y: y + 6), CGPoint(x: ix + 10, y: y + 6), CGPoint(x: ix + 5, y: y + 6 + len)]),
                         Color(hex: 0xe6f2fb), 2.5)
            ix += 26
            i += 1
        }
    }

    private func church(_ c: GraphicsContext) {
        let stone = Color(hex: 0xe3d6c0)
        // nave
        Draw.fillOut(c, Draw.poly([CGPoint(x: 360, y: 384), CGPoint(x: 500, y: 316), CGPoint(x: 640, y: 384)]),
                     Color(hex: 0x5a5070), 5)
        Draw.fillOut(c, Draw.rect(380, 380, 240, 320), stone, 5)
        // tower and spire
        Draw.fillOut(c, Draw.poly([CGPoint(x: 428, y: 206), CGPoint(x: 500, y: 92), CGPoint(x: 572, y: 206)]),
                     Color(hex: 0x4a5a7a), 5)
        var spireSnow = Path()
        spireSnow.move(to: CGPoint(x: 452, y: 168))
        spireSnow.addLine(to: CGPoint(x: 500, y: 96))
        spireSnow.addLine(to: CGPoint(x: 548, y: 168))
        Draw.tube(c, spireSnow, .white, 9)
        Draw.fillOut(c, Draw.rect(440, 200, 120, 190), stone, 5)
        Draw.fillOut(c, Draw.rect(432, 196, 136, 16, r: 6), .white, 4)
        // stone courses
        for y in stride(from: CGFloat(420), to: 690, by: 46) {
            c.stroke(Draw.line(CGPoint(x: 386, y: y), CGPoint(x: 614, y: y)), with: .color(.ink.opacity(0.1)), style: Draw.style(2.5))
        }
        // steps
        Draw.fillOut(c, Draw.rect(430, 700, 140, 16, r: 4), Color(hex: 0xd0c3ad), 4)
        Draw.fillOut(c, Draw.rect(416, 714, 168, 16, r: 4), Color(hex: 0xc4b6a0), 4)
        // two lanterns by the door
        for lx in [CGFloat(418), 582] {
            c.fill(Draw.circle(lx, 600, 26), with: .radialGradient(
                Gradient(colors: [Color(hex: 0xffd77a).opacity(0.8), .clear]),
                center: CGPoint(x: lx, y: 600), startRadius: 2, endRadius: 26))
            Draw.fillOut(c, Draw.rect(lx - 8, 588, 16, 22, r: 4), Color(hex: 0xffe9a8), 3.5)
        }
    }

    private func fairyLights(_ c: GraphicsContext) {
        let colors: [Color] = [Color(hex: 0xff6b6b), Color(hex: 0xffd86b), Color(hex: 0x7fd8ff), Color(hex: 0x9fe07a)]
        let roofs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(20, 860, 170, 760), (350, 860, 500, 740), (680, 860, 830, 760)]
        var k = 0
        for (x, y, cx, peak) in roofs {
            let w: CGFloat = 300
            for side in 0..<2 {
                let a = side == 0 ? CGPoint(x: x - 4, y: y + 10) : CGPoint(x: cx, y: peak + 22)
                let b = side == 0 ? CGPoint(x: cx, y: peak + 22) : CGPoint(x: x + w + 4, y: y + 10)
                var wire = Path()
                wire.move(to: a)
                wire.addLine(to: b)
                c.stroke(wire, with: .color(.ink.opacity(0.6)), style: Draw.style(2))
                for i in 0..<7 {
                    let t = (CGFloat(i) + 0.5) / 7
                    let p = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t + 6)
                    let col = colors[k % colors.count]
                    c.fill(Draw.circle(p.x, p.y, 11), with: .color(col.opacity(0.35)))
                    Draw.fillOut(c, Draw.oval(p.x, p.y, 5, 6.5), col, 2.5)
                    k += 1
                }
            }
        }
    }

    /// The painted frame around each door, the snow on window sills, and the
    /// shadows under the gift boxes.
    private func surround(_ c: GraphicsContext, _ slot: DoorSlot) {
        let r = slot.rect
        switch slot.style {
        case .gift:
            c.fill(Draw.oval(r.midX + 8, r.maxY + 2, r.width * 0.62, 14), with: .color(Color(hex: 0x8fa3bd).opacity(0.5)))
        case .round:
            Draw.fillOut(c, Draw.circle(r.midX, r.midY, r.width / 2 + 11), slot.trim, 5)
        case .arch:
            let frame = ArchShape().path(in: r.insetBy(dx: -12, dy: -12))
            Draw.fillOut(c, frame, slot.trim, 5)
        case .door:
            Draw.fillOut(c, Draw.rect(r.minX - 11, r.minY - 11, r.width + 22, r.height + 11, r: 20), slot.trim, 5)
            // a doorstep in the snow
            Draw.fillOut(c, Draw.rect(r.minX - 16, r.maxY - 2, r.width + 32, 12, r: 5), Color(hex: 0xd0c3ad), 4)
        case .window:
            Draw.fillOut(c, Draw.rect(r.minX - 10, r.minY - 10, r.width + 20, r.height + 20, r: 8), slot.trim, 5)
            Draw.fillOut(c, Draw.rect(r.minX - 18, r.maxY + 6, r.width + 36, 16, r: 8), .white, 4)
        }
    }
}
