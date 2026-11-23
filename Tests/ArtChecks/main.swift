// Art checks for the content packs, with no simulator and no test target.
// CI compiles the app's own drawing code (Core/, Art/, Art/Packs/, Packs.swift)
// with a tiny UIKit shim into a macOS tool:
//
//   swiftc GetCracking/Core/{VNode,SVGPath,Motion,Util}.swift GetCracking/Art/{Animals,Loops,Props,Scenes}.swift \
//          GetCracking/Art/Packs/*.swift GetCracking/Monetization/Packs.swift Tests/ArtChecks/*.swift -o artcheck
//   ./artcheck [png-folder]
//
// Like the web's tests/packs.test.js, every pack friend and world must build a
// non-empty drawing of a sensible size. With a folder, it also draws contact
// sheets of the pack friends and worlds there (CI uploads them).
// It lives outside GetCracking/ so it never ships in the app.

import Foundation
import SwiftUI

var failures = 0
func check(_ ok: Bool, _ what: String) {
    print((ok ? "PASS  " : "FAIL  ") + what)
    if !ok { failures += 1 }
}

/// The built-in part names in Animals.swift, so a pack friend that names one
/// is not flagged as a typo.
enum BuiltIn {
    static let ears: Set = ["none", "round", "pointy", "tall", "bat", "tufts", "long", "tiny", "bigRound", "fluffy", "side", "elephant", "floppy", "goat"]
    static let back: Set = ["tailFluffy", "tailStriped", "tailSquirrel", "tailThin", "tailCurl", "tailDino", "batWings", "dragonWings", "mane", "quills",
                            "fleece", "turtleShell", "snailShell", "gills", "spikes", "horns", "nubs", "antennae", "eyeStalks", "frogBumps"]
    static let marks: Set = ["stripes", "spots", "patches", "mask", "eyePatches", "eyePatch", "faceMask", "faceHeart", "lowerFace", "faceOval",
                             "muzzlePatch", "redPanda", "slothEyes", "cap", "fawnSpots", "owlBelly", "plastron"]
    static let front: Set = ["tuft", "horn", "pastelMane", "fleeceTuft", "curl", "leaf", "claws"]
    static let eyes: Set = ["none", "dot", "stalk", "big", "ringed", "happy", "tiny"]
    static let muzzle: Set = ["none", "snout", "pig", "beak", "bill", "trunk", "capy"]
    static let nose: Set = ["none", "small", "big"]
    static let mouth: Set = ["none", "w", "u", "wide", "open", "fang"]
    static let arms: Set = ["none", "paw", "wing", "flipper"]
    static let feet: Set = ["none", "paw", "bird"]
}

func shapes(_ n: VNode) -> Int {
    var k = 0
    n.walk { if case .shape(let p) = $0.content, !p.isEmpty { k += 1 } }
    return k
}

func finite(_ r: CGRect) -> Bool { !r.isNull && r.minX.isFinite && r.minY.isFinite && r.width.isFinite && r.height.isFinite }

func size(_ r: CGRect) -> String { "\(Int(r.width.rounded()))×\(Int(r.height.rounded())), top \(Int(r.minY.rounded()))" }

MainActor.assumeIsolated {
    // the registry and the art agree (AppModel asserts the same in debug builds)
    check(Packs.allFriends == Animals.list.map(\.id), "Packs.swift friends = Animals.list, same order")
    check(Packs.allScenes == Scenes.list.map(\.id), "Packs.swift worlds = Scenes.list, same order")
    check(Animals.classic.count == 40, "the Classic 40 are unchanged in number")

    let packs = Packs.list.filter { $0.id != "classic" }
    for pk in packs {
        print("\n\(pk.name) (\(pk.id)): \(pk.friends.count) friends, \(pk.scenes.count) worlds")
        for id in pk.friends {
            guard let a = Animals.byId[id] else { check(false, "\(id): in Animals.list"); continue }
            let node = Animals.render(a)
            let squash = node.children.count == 2 ? node.children[1] : node
            let bb = squash.bounds
            let n = shapes(node)
            check(n >= 12, "\(a.name): builds a drawing (\(n) shapes)")
            // the web's sensible-size check on the .c-squash group
            check(finite(bb) && bb.width > 80 && bb.width < 300 && bb.height > 90 && bb.height < 300 && bb.minY > -260,
                  "\(a.name): sensible size (\(size(bb)))")
            check(bb.minX < 0 && bb.maxX > 0 && bb.maxY > -5 && bb.maxY < 30, "\(a.name): stands on y = 0, centred")
            // every part a friend names exists (a typo would silently draw nothing)
            let parts = Animals.parts
            for x in a.back where x != "paddleTail" { check(parts.back[x] != nil || BuiltIn.back.contains(x), "\(a.name): back part \(x)") }
            for x in a.marks { check(parts.marks[x] != nil || BuiltIn.marks.contains(x), "\(a.name): marks part \(x)") }
            for x in a.front { check(parts.front[x] != nil || BuiltIn.front.contains(x), "\(a.name): front part \(x)") }
            for x in a.over { check(parts.over[x] != nil, "\(a.name): over part \(x)") }
            check(parts.ears[a.ears] != nil || BuiltIn.ears.contains(a.ears), "\(a.name): ears \(a.ears)")
            check(parts.eyes[a.eyes] != nil || BuiltIn.eyes.contains(a.eyes), "\(a.name): eyes \(a.eyes)")
            check(parts.muzzle[a.muzzle] != nil || BuiltIn.muzzle.contains(a.muzzle), "\(a.name): muzzle \(a.muzzle)")
            check(parts.nose[a.nose] != nil || BuiltIn.nose.contains(a.nose), "\(a.name): nose \(a.nose)")
            check(parts.mouth[a.mouth] != nil || BuiltIn.mouth.contains(a.mouth), "\(a.name): mouth \(a.mouth)")
            check(parts.arms[a.arms] != nil || BuiltIn.arms.contains(a.arms), "\(a.name): arms \(a.arms)")
            check(parts.feet[a.feet] != nil || BuiltIn.feet.contains(a.feet), "\(a.name): feet \(a.feet)")
        }
        for id in pk.scenes {
            let b = Scenes.build(id)
            check(b.scene.id == id, "world \(id): builds")
            let n = shapes(b.root)
            check(n > 120, "world \(id): a full diorama (\(n) shapes)")
            let sc = b.scene
            let layers: [(String, [VNode])] = [("sky", sc.sky()), ("ground", sc.ground()), ("side critters", sc.sideCritters()),
                                               ("back props", sc.back()), ("front props", sc.front())]
            for (name, kids) in layers {
                let g = nGroup(kids)
                let bb = g.bounds
                check(!kids.isEmpty && finite(bb) && bb.width > 10 && bb.minX > -100 && bb.maxX < 700 && bb.minY > -100 && bb.maxY < 760,
                      "world \(id): \(name) inside the stage (\(size(bb)))")
            }
            if let kind = sc.particles {
                check(PackArt.particles[kind] != nil, "world \(id): particle kind \(kind) is registered")
                let p = Scenes.particles(kind, 16)
                check(p.map { $0.children.count == 16 && shapes($0) >= 16 } ?? false, "world \(id): 16 \(kind) particles")
                var loops = 0
                p?.walk { if $0.loop != nil { loops += 1 } }
                check(loops >= 16, "world \(id): the \(kind) particles move")
            }
        }
    }

    // reduced motion: no particles and no loops, as on the web
    UIAccessibility.isReduceMotionEnabled = true
    for id in packs.flatMap(\.scenes) {
        let b = Scenes.build(id)
        var loops = 0
        b.root.walk { if $0.loop != nil { loops += 1 } }
        let full = shapes(b.root), still = shapes(Scenes.build(id, particles: false).root)
        check(loops == 0 && full == still, "world \(id), reduced motion: no particles, nothing moves")
    }
    UIAccessibility.isReduceMotionEnabled = false

    // contact sheets
    if CommandLine.arguments.count > 1 {
        let dir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let friendBox = CGRect(x: -110, y: -215, width: 220, height: 230)  // the web contact sheet's view box
        for pk in Packs.list {
            let friends = pk.friends.compactMap { Animals.byId[$0] }.map { (Animals.render($0), friendBox) }
            if let img = CGDraw.sheet(friends, cols: 6, cell: CGSize(width: 330, height: 345), background: "#d8d0c4", cellFill: "#ece4d9") {
                check(CGDraw.writePNG(img, dir.appendingPathComponent("packs-\(pk.id).png")), "drew packs-\(pk.id).png")
            }
            if pk.id == "classic" { continue }
            let worlds = pk.scenes.map { (Scenes.build($0, particles: true).root, CGRect(x: 0, y: 0, width: 600, height: 720)) }
            if let img = CGDraw.sheet(worlds, cols: 2, cell: CGSize(width: 600, height: 720), background: "#d8d0c4", cellFill: nil) {
                check(CGDraw.writePNG(img, dir.appendingPathComponent("packs-\(pk.id)-worlds.png")), "drew packs-\(pk.id)-worlds.png")
            }
            // one big picture per friend, for close comparison with the web
            for a in pk.friends.compactMap({ Animals.byId[$0] }) {
                if let img = CGDraw.sheet([(Animals.render(a), CGRect(x: -150, y: -250, width: 300, height: 270))], cols: 1,
                                          cell: CGSize(width: 600, height: 540), gap: 0, background: "#ffffff", cellFill: nil) {
                    _ = CGDraw.writePNG(img, dir.appendingPathComponent("friend-\(a.id).png"))
                }
            }
            for id in pk.scenes {
                if let img = CGDraw.sheet([(Scenes.build(id, particles: false).root, CGRect(x: 0, y: 0, width: 600, height: 720))], cols: 1,
                                          cell: CGSize(width: 600, height: 720), gap: 0, background: "#ffffff", cellFill: nil) {
                    _ = CGDraw.writePNG(img, dir.appendingPathComponent("world-\(id).png"))
                }
            }
        }
    }
}

print(failures == 0 ? "\nAll art checks passed" : "\n\(failures) art check(s) FAILED")
exit(failures == 0 ? 0 : 1)
