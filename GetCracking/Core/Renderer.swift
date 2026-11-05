import SwiftUI

/// Draws a `VNode` tree into a SwiftUI `GraphicsContext`.
enum Renderer {
    static let fredokaBold = "Fredoka-Bold"

    static func draw(_ n: VNode, in ctx: GraphicsContext, now: Double) {
        if n.hidden { return }
        let pose = n.pose(at: now)
        if pose.opacity <= 0.002 { return }
        var c = ctx
        c.concatenate(pose.transform)
        if let clip = n.clip { c.clip(to: clip) }

        let needsLayer: Bool = {
            guard pose.opacity < 0.999 else { return false }
            switch n.content {
            case .group: return n.children.count > 1
            case .shape: return n.fill != nil && n.stroke != nil
            default: return false
            }
        }()

        if needsLayer {
            c.opacity *= pose.opacity
            c.drawLayer { layer in
                var l = layer
                l.opacity = 1
                drawContent(n, pose, in: l, now: now)
            }
        } else {
            c.opacity *= pose.opacity
            drawContent(n, pose, in: c, now: now)
        }
    }

    private static func drawContent(_ n: VNode, _ pose: VNode.Pose, in c: GraphicsContext, now: Double) {
        switch n.content {
        case .group:
            for child in n.children { draw(child, in: c, now: now) }

        case .shape(let base):
            var path = base
            if pose.trimFrom > 0.0001 || pose.trimTo < 0.9999 {
                let a = min(max(pose.trimFrom, 0), 1), b = min(max(pose.trimTo, 0), 1)
                if b <= a { return }
                path = base.trimmedPath(from: a, to: b)
            }
            if let g = n.radialGlow {
                c.fill(path, with: .radialGradient(Gradient(colors: [g.color, g.color.opacity(0.55), g.color.opacity(0)]),
                                                   center: g.center, startRadius: 0, endRadius: g.radius))
            }
            if let f = n.fill { c.fill(path, with: .color(f)) }
            if let s = n.stroke, n.strokeWidth > 0 {
                if n.softGlow {
                    for (k, a) in [(1.9, 0.18), (1.45, 0.28), (1.0, 0.5)] {
                        c.stroke(path, with: .color(s.opacity(a)),
                                 style: StrokeStyle(lineWidth: n.strokeWidth * k, lineCap: .round, lineJoin: .round))
                    }
                } else {
                    c.stroke(path, with: .color(s),
                             style: StrokeStyle(lineWidth: n.strokeWidth, lineCap: n.cap, lineJoin: n.join,
                                                miterLimit: 4, dash: n.dash, dashPhase: pose.dashPhase))
                }
            }

        case let .text(str, size, at):
            // cream letters with a dark outline (paint-order: stroke)
            let font = Font.custom(fredokaBold, size: size)
            let outline = c.resolve(Text(str).font(font).foregroundColor(GC.out))
            let face = c.resolve(Text(str).font(font).foregroundColor(Color(hex: "#fdf3e4")))
            let r: CGFloat = max(1.5, size * 0.07)
            for k in 0..<8 {
                let a = Double(k) / 8 * 2 * .pi
                c.draw(outline, at: CGPoint(x: at.x + r * cos(a), y: at.y + r * sin(a)), anchor: .bottomLeading)
            }
            c.draw(face, at: at, anchor: .bottomLeading)

        case let .image(img, rect):
            c.draw(Image(uiImage: img), in: rect)
        }
    }
}

/// Map a viewBox onto a view, like SVG preserveAspectRatio xMidYMid meet/slice.
func fitTransform(_ vb: CGRect, in size: CGSize, slice: Bool = false) -> CGAffineTransform {
    guard vb.width > 0, vb.height > 0, size.width > 0, size.height > 0 else { return .identity }
    let sx = size.width / vb.width, sy = size.height / vb.height
    let s = slice ? max(sx, sy) : min(sx, sy)
    let tx = (size.width - vb.width * s) / 2 - vb.minX * s
    let ty = (size.height - vb.height * s) / 2 - vb.minY * s
    return CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: tx, ty: ty)
}

/// A live, animated drawing of a node tree.
struct StageView: View {
    let root: VNode
    var viewBox: CGRect
    var slice = false
    var animated = true

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !animated)) { _ in
            Canvas { ctx, size in
                ctx.concatenate(fitTransform(viewBox, in: size, slice: slice))
                Renderer.draw(root, in: ctx, now: GC.now)
            }
        }
    }
}
