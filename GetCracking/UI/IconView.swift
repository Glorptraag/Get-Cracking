import SwiftUI

/// One drawn icon (Art/Icons.swift), drawn by the app's vector renderer.
/// It is decorative: the button or row that shows it carries the label.
struct IconView: View {
    let name: String
    var size: CGFloat = 32

    var body: some View {
        // a little bleed round the 48×48 box: some icons poke past it, as on the web (overflow: visible)
        IconCanvas(node: IconCache.node(name), bleed: 6)
            .frame(width: size * 60 / 48, height: size * 60 / 48)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct IconCanvas: View {
    let node: VNode
    let bleed: CGFloat

    var body: some View {
        Canvas { ctx, size in
            ctx.concatenate(fitTransform(Icons.box.insetBy(dx: -bleed, dy: -bleed), in: size))
            Renderer.draw(node, in: ctx, now: GC.now)
        }
    }
}

@MainActor
enum IconCache {
    private static var nodes: [String: VNode] = [:]
    private static var images: [String: CGImage] = [:]

    /// one shared drawing per icon (icons never animate)
    static func node(_ name: String) -> VNode {
        if let n = nodes[name] { return n }
        let n = Icons.node(name)
        nodes[name] = n
        return n
    }

    /// the icon as a picture, for drawing inside a line of text
    static func image(_ name: String, _ size: CGFloat) -> CGImage? {
        let key = "\(name)@\(size)"
        if let i = images[key] { return i }
        let r = ImageRenderer(content: IconCanvas(node: node(name), bleed: 0).frame(width: size, height: size))
        r.scale = 3
        let img = r.cgImage
        if let img { images[key] = img }
        return img
    }
}

/// Text with {icon} tokens drawn inline, like the web's `rich()`:
/// "Long-press {lock} for grown-up controls" shows the drawn lock.
@MainActor
func iconText(_ s: String, size: CGFloat) -> Text {
    var out = Text("")
    for (i, part) in s.components(separatedBy: CharacterSet(charactersIn: "{}")).enumerated() {
        if i % 2 == 1, Icons.has(part), let img = IconCache.image(part, size * 1.35) {
            out = out + Text(Image(img, scale: 3, label: Text(part))).baselineOffset(-size * 0.3)
        } else if !part.isEmpty {
            out = out + Text(part)
        }
    }
    return out
}
