import SwiftUI

/// A tiny retained vector scene graph — the native stand-in for the SVG DOM
/// the web version drew into. Nodes are drawn by `Renderer` into a SwiftUI
/// `Canvas` every frame; idle loops and one-shot animations are evaluated
/// against the shared clock (`GC.now`).
final class VNode {
    enum Content {
        case group
        case shape(Path)
        case text(String, size: CGFloat, at: CGPoint)
        case image(UIImage, CGRect)
    }

    var content: Content
    private(set) var children: [VNode] = []
    private(set) weak var parent: VNode?
    var tag: String?

    // static presentation
    var transform: CGAffineTransform = .identity
    var clip: Path?
    var opacity: Double = 1
    var hidden = false
    var fill: Color?
    var stroke: Color?
    var strokeWidth: CGFloat = 1
    var cap: CGLineCap = .butt
    var join: CGLineJoin = .miter
    var dash: [CGFloat] = []
    var dashPhase: CGFloat = 0
    var trimFrom: CGFloat = 0
    var trimTo: CGFloat = 1
    /// soft radial fill (used for glows instead of a blur filter)
    var radialGlow: (color: Color, center: CGPoint, radius: CGFloat)?
    /// draw the stroke as a soft glow (a few widening translucent strokes)
    var softGlow = false

    // motion
    var loop: Loop? { didSet { loopStart = GC.now; pausedAt = nil } }
    /// idle-only loops (critter hop, wave …) stay off until the friend is out
    var loopEnabled = true
    var idleGated = false
    private var loopStart: Double = GC.now
    private var pausedAt: Double?
    private(set) var anims: [Anim] = []

    init(_ content: Content = .group) { self.content = content }

    // MARK: tree

    @discardableResult
    func add(_ child: VNode) -> VNode {
        child.removeFromParent()
        child.parent = self
        children.append(child)
        return child
    }

    func add(_ kids: [VNode]) { for k in kids { add(k) } }

    func insert(_ child: VNode, at index: Int) {
        child.removeFromParent()
        child.parent = self
        children.insert(child, at: min(max(0, index), children.count))
    }

    func removeFromParent() {
        guard let p = parent else { return }
        p.children.removeAll { $0 === self }
        parent = nil
    }

    func removeAllChildren() {
        for c in children { c.parent = nil }
        children.removeAll()
    }

    func first(tag: String) -> VNode? {
        if self.tag == tag { return self }
        for c in children { if let f = c.first(tag: tag) { return f } }
        return nil
    }

    func walk(_ fn: (VNode) -> Void) {
        fn(self)
        for c in children { c.walk(fn) }
    }

    /// Turn on the friend's idle loops (hop, wave, wag …).
    func enableIdle() { walk { if $0.idleGated { $0.loopEnabled = true } } }

    // MARK: loops

    func pauseLoop(_ on: Bool) {
        let now = GC.now
        if on {
            if pausedAt == nil { pausedAt = now }
        } else if let p = pausedAt {
            loopStart += now - p
            pausedAt = nil
        }
    }

    /// Set a loop without restarting it when it's already the same kind.
    func setLoop(_ l: Loop?, key: String?) {
        if key != nil, key == loopKey { return }
        loopKey = key
        loop = l
    }
    private var loopKey: String?

    // MARK: one-shot animations

    @discardableResult
    func play(_ kfs: [KF], duration: Double, delay: Double = 0, easing: Ease = .linear, fill: Bool = false) -> Anim {
        let a = Anim(start: GC.now + delay, duration: duration, fill: fill,
                     sample: Anim.keyframes(kfs, duration: duration, easing: easing, base: self))
        anims.append(a)
        return a
    }

    @discardableResult
    func drive(duration: Double, delay: Double = 0, fill: Bool = true, _ fn: @escaping (Double) -> AnimPose) -> Anim {
        let a = Anim(start: GC.now + delay, duration: duration, fill: fill, sample: fn)
        anims.append(a)
        return a
    }

    func cancelAnims() { anims.removeAll() }

    // MARK: evaluation

    struct Pose {
        var transform: CGAffineTransform
        var opacity: Double
        var trimFrom: CGFloat
        var trimTo: CGFloat
        var dashPhase: CGFloat
    }

    func pose(at now: Double) -> Pose {
        var p = Pose(transform: transform, opacity: opacity, trimFrom: trimFrom, trimTo: trimTo, dashPhase: dashPhase)
        var loopOpacity = 1.0
        if let l = loop, loopEnabled {
            let t = (pausedAt ?? now) - loopStart
            let r = l.evaluate(time: t, bounds: bounds)
            if let m = r.transform { p.transform = m }
            loopOpacity = r.opacity
            if let d = r.dash { p.dashPhase = CGFloat(d) }
        }
        if !anims.isEmpty {
            var finished: [Anim] = []
            for a in anims {
                if let ap = a.pose(at: now) {
                    if let m = ap.transform { p.transform = m }
                    if let o = ap.opacity { p.opacity = o }
                    if let v = ap.trimFrom { p.trimFrom = CGFloat(v) }
                    if let v = ap.trimTo { p.trimTo = CGFloat(v) }
                }
                if now >= a.end { finished.append(a) }
            }
            // a finished, filling animation becomes the node's new base value
            for a in finished {
                if a.fill, let ap = a.pose(at: now) {
                    if let m = ap.transform { transform = m }
                    if let o = ap.opacity { opacity = o }
                    if let v = ap.trimFrom { trimFrom = CGFloat(v) }
                    if let v = ap.trimTo { trimTo = CGFloat(v) }
                }
                anims.removeAll { $0 === a }
            }
        }
        p.opacity *= loopOpacity
        return p
    }

    // MARK: geometry

    private var cachedBounds: CGRect?
    /// Local bounding box (SVG "fill-box").
    var bounds: CGRect {
        if let b = cachedBounds { return b }
        var r = CGRect.null
        switch content {
        case .shape(let p): r = p.boundingRect
        case let .text(_, size, at): r = CGRect(x: at.x, y: at.y - size, width: size * 0.6, height: size)
        case let .image(_, rect): r = rect
        case .group:
            for c in children where !c.hidden {
                let b = c.bounds
                if !b.isNull { r = r.union(b.applying(c.transform)) }
            }
        }
        if r.isNull { r = .zero }
        cachedBounds = r
        return r
    }

    /// Apply `m` to this subtree's geometry (paths, clips, child transforms)
    /// instead of drawing it through a transform, so strokes stay unskewed —
    /// the native version of SVG's `vector-effect: non-scaling-stroke`.
    func bake(_ m: CGAffineTransform) {
        let t = transform.concatenating(m)
        switch content {
        case .shape(let p):
            content = .shape(p.applying(t))
            if let c = clip { clip = c.applying(t) }
            if let g = radialGlow { radialGlow = (g.color, g.center.applying(t), g.radius) }
            transform = .identity
        case .group:
            if let c = clip { clip = c.applying(t) }
            for c in children { c.bake(t) }
            transform = .identity
        default:
            transform = t
        }
        cachedBounds = nil
    }
}

// MARK: - Builders (the counterpart of the web version's SVG markup)

/// Paint for a shape. `St.o(w)` is the chunky dark outline.
struct St {
    var fill: String? = nil
    var fillOpacity: Double = 1
    var stroke: String? = nil
    var width: Double = 1
    var strokeOpacity: Double = 1
    var cap: CGLineCap = .butt
    var join: CGLineJoin = .miter
    var dash: [Double] = []
    var opacity: Double = 1

    /// dark outline, round joins and caps
    static func o(_ w: Double = 6) -> St { St(stroke: GC.outHex, width: w, cap: .round, join: .round) }
    static func f(_ c: String) -> St { St(fill: c) }
    static func line(_ c: String, _ w: Double, cap: CGLineCap = .round, join: CGLineJoin = .round) -> St {
        St(stroke: c, width: w, cap: cap, join: join)
    }
    func filled(_ c: String) -> St { var s = self; s.fill = c; return s }
    func fo(_ o: Double) -> St { var s = self; s.fillOpacity = o; return s }
    func so(_ o: Double) -> St { var s = self; s.strokeOpacity = o; return s }
    func op(_ o: Double) -> St { var s = self; s.opacity = o; return s }
    func dashed(_ d: [Double]) -> St { var s = self; s.dash = d; return s }
    func capped(_ c: CGLineCap) -> St { var s = self; s.cap = c; return s }
}

extension VNode {
    func paint(_ st: St) -> VNode {
        if let f = st.fill { fill = Color(hex: f, opacity: st.fillOpacity) }
        if let s = st.stroke { stroke = Color(hex: s, opacity: st.strokeOpacity) }
        strokeWidth = st.width
        cap = st.cap
        join = st.join
        dash = st.dash.map { CGFloat($0) }
        opacity = st.opacity
        return self
    }
    func moved(_ m: CGAffineTransform) -> VNode { transform = m; return self }
    func looping(_ l: Loop, idle: Bool = false) -> VNode {
        loop = l
        if idle { idleGated = true; loopEnabled = false }
        return self
    }
    func tagged(_ t: String) -> VNode { tag = t; return self }
}

func nPath(_ d: String, _ st: St) -> VNode { VNode(.shape(SVGPath.parse(d))).paint(st) }
func nShape(_ p: Path, _ st: St) -> VNode { VNode(.shape(p)).paint(st) }

func nCircle(_ cx: Double, _ cy: Double, _ r: Double, _ st: St) -> VNode {
    VNode(.shape(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)))).paint(st)
}

func nEllipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ st: St) -> VNode {
    VNode(.shape(Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry)))).paint(st)
}

func nRect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, rx: Double = 0, _ st: St) -> VNode {
    let r = CGRect(x: x, y: y, width: w, height: h)
    let p = rx > 0 ? Path(roundedRect: r, cornerRadius: min(rx, w / 2, h / 2)) : Path(r)
    return VNode(.shape(p)).paint(st)
}

func polyPath(_ pts: [Pt], closed: Bool) -> Path {
    var p = Path()
    guard let first = pts.first else { return p }
    p.move(to: CGPoint(x: first.0, y: first.1))
    for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
    if closed { p.closeSubpath() }
    return p
}

func nPolygon(_ pts: [Pt], _ st: St) -> VNode { VNode(.shape(polyPath(pts, closed: true))).paint(st) }
func nPolyline(_ pts: [Pt], _ st: St) -> VNode { VNode(.shape(polyPath(pts, closed: false))).paint(st) }

func nGroup(_ kids: [VNode] = [], _ m: CGAffineTransform = .identity, clip: Path? = nil, opacity: Double = 1) -> VNode {
    let g = VNode(.group)
    g.transform = m
    g.clip = clip
    g.opacity = opacity
    g.add(kids)
    return g
}

/// `both { s in … }` — draw something once mirrored on each side (s = -1, 1).
func both(_ fn: (Double) -> [VNode]) -> [VNode] { fn(-1) + fn(1) }

func tr(_ x: Double, _ y: Double) -> CGAffineTransform { CGAffineTransform(translationX: x, y: y) }
func rotAbout(_ deg: Double, _ x: Double, _ y: Double) -> CGAffineTransform { Transform.rotate(deg, about: x, y) }
