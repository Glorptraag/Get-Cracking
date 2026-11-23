import SwiftUI

/// Egg karaoke: the hatched friend bops on each note it sings, and now and
/// then a little music note floats up (web js/egg.js `sing`, driven by
/// Sound.onSing). Kept out of Art/Egg.swift so the art stays in one place.
private enum Bop {
    @MainActor static var sung = 0
    static let noteColors = ["#f7a8c8", "#ffd86b", "#9fd8e8", "#a9d36b", "#c5a8f0"]
}

extension Egg {
    /// a little squash-and-stretch on a sung note (dur = how long it rings)
    func sing(_ dur: Double = 0.3) {
        guard hatched, !GC.reduceMotion, let f = friend, let inner = f.first(tag: "critter") else { return }
        // never cut into the happy jump from a tap
        let now = GC.now
        if inner.anims.contains(where: { $0.duration > 0.5 && now < $0.end }) { return }
        let d = max(0.16, min(0.42, dur))
        inner.play([
            KF([.scale(1, 1)]),
            KF([.scale(1.07, 0.93)], offset: 0.3),
            KF([.scale(0.97, 1.05)], offset: 0.65),
            KF([.scale(1, 1)]),
        ], duration: d, easing: .easeOut)

        Bop.sung += 1
        if Bop.sung % 2 == 1 { return }
        let side: Double = Bop.sung % 4 == 0 ? -1 : 1
        let g = nGroup([], tr(side * GC.rand(40, 70), -150))
        let note = nGroup([
            nPath("M6,-22 V2 M6,-22 L16,-17", St.line(GC.outHex, 3.5)),
            nEllipse(0, 3, 7.5, 6, St.o(3).filled(GC.pick(Bop.noteColors))),
        ])
        g.add(note)
        fx.add(g)
        note.play([
            KF([.translate(0, 0), .s(0.3), .rotate(0)], opacity: 0),
            KF([.translate(side * 8, -30), .s(1), .rotate(side * 8)], offset: 0.25, opacity: 1),
            KF([.translate(side * 22, -110), .s(0.9), .rotate(side * -10)], opacity: 0),
        ], duration: 1.5, easing: .easeOut, fill: true)
        GC.after(1.55) { g.removeFromParent() }
    }
}
