// A still CoreGraphics drawing of a VNode tree (the static pose: no idle
// loops or animations), for the PNG contact sheets the CI job uploads.
// It walks the same scene graph the app's Renderer draws into a SwiftUI Canvas.

#if os(macOS)
import AppKit
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

enum CGDraw {
    static func cg(_ c: Color) -> CGColor {
        NSColor(c).usingColorSpace(.sRGB)?.cgColor ?? CGColor(gray: 0, alpha: 1)
    }

    static func draw(_ n: VNode, _ ctx: CGContext) {
        if n.hidden || n.opacity <= 0.002 { return }
        ctx.saveGState()
        ctx.concatenate(n.transform)
        if let clip = n.clip {
            ctx.addPath(clip.cgPath)
            ctx.clip()
        }
        let layer = n.opacity < 0.999
        if layer {
            ctx.setAlpha(n.opacity)
            ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        }
        switch n.content {
        case .group:
            for c in n.children { draw(c, ctx) }
        case .shape(let p):
            if let f = n.fill {
                ctx.addPath(p.cgPath)
                ctx.setFillColor(cg(f))
                ctx.fillPath()
            }
            if let s = n.stroke, n.strokeWidth > 0 {
                ctx.addPath(p.cgPath)
                ctx.setStrokeColor(cg(s))
                ctx.setLineWidth(n.strokeWidth)
                ctx.setLineCap(n.cap)
                ctx.setLineJoin(n.join)
                ctx.setMiterLimit(4)
                ctx.setLineDash(phase: n.dashPhase, lengths: n.dash)
                ctx.strokePath()
            }
        default:
            break
        }
        if layer { ctx.endTransparencyLayer() }
        ctx.restoreGState()
    }

    /// Draw `items` (each a node and the view box to fit it into) in a grid of cells.
    static func sheet(_ items: [(VNode, CGRect)], cols: Int, cell: CGSize, gap: CGFloat = 10,
                      background: String, cellFill: String?) -> CGImage? {
        let rows = (items.count + cols - 1) / cols
        let W = Int(CGFloat(cols) * (cell.width + gap) + gap), H = Int(CGFloat(rows) * (cell.height + gap) + gap)
        guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // SVG coordinates: y grows downwards
        ctx.translateBy(x: 0, y: CGFloat(H))
        ctx.scaleBy(x: 1, y: -1)
        ctx.setFillColor(cg(Color(hex: background)))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        for (i, (node, vb)) in items.enumerated() {
            let r = CGRect(x: gap + CGFloat(i % cols) * (cell.width + gap), y: gap + CGFloat(i / cols) * (cell.height + gap),
                           width: cell.width, height: cell.height)
            ctx.saveGState()
            if let cf = cellFill {
                ctx.setFillColor(cg(Color(hex: cf)))
                ctx.addPath(CGPath(roundedRect: r, cornerWidth: 8, cornerHeight: 8, transform: nil))
                ctx.fillPath()
            }
            ctx.clip(to: r)
            ctx.translateBy(x: r.minX, y: r.minY)
            ctx.concatenate(fitTransform(vb, in: r.size))
            draw(node, ctx)
            ctx.restoreGState()
        }
        return ctx.makeImage()
    }

    static func writePNG(_ img: CGImage, _ url: URL) -> Bool {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return false }
        CGImageDestinationAddImage(dest, img, nil)
        return CGImageDestinationFinalize(dest)
    }
}

/// Map a viewBox onto a size, like SVG preserveAspectRatio xMidYMid meet
/// (the same maths as the app's Renderer.swift).
func fitTransform(_ vb: CGRect, in size: CGSize) -> CGAffineTransform {
    let s = min(size.width / vb.width, size.height / vb.height)
    let tx = (size.width - vb.width * s) / 2 - vb.minX * s
    let ty = (size.height - vb.height * s) / 2 - vb.minY * s
    return CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: tx, ty: ty)
}
#endif
