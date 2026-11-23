import SwiftUI

/// Aussie Bush pack: twelve Australian friends in the house style (one chunky
/// bean, 6 px outlines, soft flat colours). Ported from the web's
/// js/packs/aussie.js (parts and friends); the worlds are in AussieWorlds.swift.
/// Native animals and generic bush landscape only: no sacred sites, no
/// Aboriginal instruments or art motifs.
enum AussieArt {
    private typealias A = Animals
    private static let O = GC.outHex
    private static func sh(_ c: String, _ a: Double) -> String { GC.shade(c, a) }

    // MARK: helpers

    /// a parrot's hooked beak, seen from the front
    static func parrotBeak(_ d: AnimalDef, _ k: PartKit) -> [VNode] {
        let fy = k.fy, c = d.muzzleColor ?? "#f1e6d2"
        return [
            nPath("M-11,\(fy + 5) Q0,\(fy - 1) 11,\(fy + 5) Q12,\(fy + 15) 2,\(fy + 24) Q0,\(fy + 26) -2,\(fy + 24) Q-12,\(fy + 15) -11,\(fy + 5) Z", A.S4(c)),
            nPath("M-6,\(fy + 13) Q0,\(fy + 17) 6,\(fy + 13)", rcap(sh(c, -0.35), 3)),
            nEllipse(-4, fy + 6, 3.5, 1.8, St.f("#ffffff").op(0.55)),
        ]
    }

    /// a feather or leaf: a pointed oval from base (bx, by) to its tip at angle a (deg), length L, width W
    static func leaf(_ bx: Double, _ by: Double, _ a: Double, _ L: Double, _ W: Double, _ st: St) -> VNode {
        let r = a * .pi / 180, ux = cos(r), uy = sin(r), px = -uy, py = ux
        let tx = bx + ux * L, ty = by + uy * L
        let m1x = bx + ux * L * 0.45 + px * W, m1y = by + uy * L * 0.45 + py * W
        let m2x = bx + ux * L * 0.45 - px * W, m2y = by + uy * L * 0.45 - py * W
        return nPath("M\(bx + px * W * 0.45),\(by + py * W * 0.45) Q\(m1x),\(m1y) \(tx),\(ty) Q\(m2x),\(m2y) \(bx - px * W * 0.45),\(by - py * W * 0.45) Z", st)
    }

    /// a spike: a narrow triangle from base (bx, by) at angle a (deg), with a dark tip
    static func spine(_ bx: Double, _ by: Double, _ a: Double, _ L: Double, _ W: Double, _ fill: String, _ tip: String) -> [VNode] {
        let r = a * .pi / 180, ux = cos(r), uy = sin(r), px = -uy * W, py = ux * W
        let tx = bx + ux * L, ty = by + uy * L
        let k = 0.62, mx = bx + ux * L * k, my = by + uy * L * k
        return [
            nPath("M\(bx + px),\(by + py) L\(tx),\(ty) L\(bx - px),\(by - py) Z", A.S4(fill)),
            nPath("M\(mx + px * (1 - k)),\(my + py * (1 - k)) L\(tx),\(ty) L\(mx - px * (1 - k)),\(my - py * (1 - k)) Z",
                  St(fill: tip, stroke: tip, width: 2, join: .round)),
        ]
    }

    private static func tail(_ kids: [VNode]) -> VNode { nGroup(kids).looping(Loops.wag, idle: true) }

    // MARK: parts

    static let parts: AnimalParts = {
        var p = AnimalParts()

        // ears
        /// joey: tall pointed kangaroo ears, set wide
        p.ears["roo"] = { d, k in
            let w = k.w, h = k.h
            return both { s in
                let cx = s * w * 0.5
                return [nGroup([
                    nPath("M\(cx - 15),\(-h * 0.86) C\(cx - 19),\(-h * 1.08) \(cx - 5),\(-h * 1.26) \(cx),\(-h * 1.31) C\(cx + 5),\(-h * 1.26) \(cx + 19),\(-h * 1.08) \(cx + 15),\(-h * 0.86) Z", A.S(d.body)),
                    nPath("M\(cx - 7),\(-h * 0.9) C\(cx - 9),\(-h * 1.06) \(cx - 3),\(-h * 1.17) \(cx),\(-h * 1.21) C\(cx + 3),\(-h * 1.17) \(cx + 9),\(-h * 1.06) \(cx + 7),\(-h * 0.9) Z", .f(d.earInner ?? d.body)),
                ], rotAbout(s * 16, cx, -h * 0.88))]
            }
        }
        /// wombat: small, rounded, a little pointed
        p.ears["wombat"] = { d, k in
            let w = k.w, h = k.h
            return both { s in
                let x = s * w * 0.6, y = -h * 0.9
                return [
                    nPath("M\(x - s * 16),\(y + 8) Q\(x - s * 8),\(y - 24) \(x + s * 8),\(y - 22) Q\(x + s * 20),\(y - 8) \(x + s * 18),\(y + 12) Z", A.S(d.body)),
                    nPath("M\(x - s * 7),\(y + 4) Q\(x - s * 2),\(y - 14) \(x + s * 7),\(y - 12) Q\(x + s * 12),\(y - 4) \(x + s * 10),\(y + 6) Z", .f(d.earInner ?? d.body)),
                ]
            }
        }
        /// sugar glider: big, thin, upright ovals
        p.ears["glider"] = { d, k in
            let w = k.w, h = k.h
            return both { s in
                [nGroup([
                    nEllipse(s * w * 0.66, -h * 0.98, 17, 25, A.S(d.body)),
                    nEllipse(s * w * 0.66, -h * 0.97, 9, 16, .f(d.earInner ?? d.body)),
                ], rotAbout(s * 24, s * w * 0.66, -h * 0.98))]
            }
        }
        /// bilby: very long rabbit-like ears splayed in a V, pointed at the tips
        p.ears["bilby"] = { d, k in
            let w = k.w, h = k.h
            return both { s in
                let cx = s * w * 0.3
                return [nGroup([
                    nPath("M\(cx - 17),\(-h * 0.84) C\(cx - 24),\(-h * 1.12) \(cx - 8),\(-h * 1.44) \(cx),\(-h * 1.5) C\(cx + 8),\(-h * 1.44) \(cx + 24),\(-h * 1.12) \(cx + 17),\(-h * 0.84) Z", A.S(d.body)),
                    nPath("M\(cx - 8),\(-h * 0.9) C\(cx - 12),\(-h * 1.12) \(cx - 4),\(-h * 1.34) \(cx),\(-h * 1.39) C\(cx + 4),\(-h * 1.34) \(cx + 12),\(-h * 1.12) \(cx + 8),\(-h * 0.9) Z", .f(d.earInner ?? d.body)),
                ], rotAbout(s * 24, cx, -h * 0.86))]
            }
        }

        // back
        /// galah: a short, rounded pale crest
        p.back["galahCrest"] = { d, k in
            let h = k.h, st = A.S4(d.crestColor ?? "#fde1e8")
            return [leaf(-4, -h * 0.9, -112, 34, 13, st), leaf(4, -h * 0.92, -82, 36, 13, st), leaf(10, -h * 0.9, -58, 28, 11, st)]
        }
        /// cockatoo: a tall fan of sulphur-yellow feathers
        p.back["cockyCrest"] = { d, k in
            let st = A.S4(d.crestColor ?? "#ffd84a")
            return [(-14.0, -122.0, 46.0), (-6, -102, 62), (4, -82, 66), (12, -62, 56), (18, -44, 40)].map { x, a, L in
                leaf(x, -k.h * 0.9, a, L, 12, st)
            }
        }
        /// kookaburra: a rufous barred tail cocked up behind
        p.back["kookaTail"] = { d, k in
            let w = k.w, h = k.h, tc = d.tailColor ?? "#c46f3c"
            let pd = "M\(w * 0.3),\(-h * 0.16) Q\(w + 4),\(-h * 0.5) \(w + 18),\(-h * 0.76) Q\(w + 34),\(-h * 0.8) \(w + 36),\(-h * 0.6) Q\(w + 22),\(-h * 0.3) \(w * 0.5),\(-h * 0.02) Z"
            let bars = [0.45, 0.65, 0.85].map { q in
                nPath("M\(w * 0.3 + 30 * q + 6),\(-h * (0.1 + 0.64 * q) - 16) l28,18", plain(sh(tc, -0.35), 5.5))
            }
            return [tail([nPath(pd, .f(tc)), nGroup(bars, clip: SVGPath.parse(pd)), nPath(pd, St.o(6))])]
        }
        /// echidna: cream spines with dark tips, all over the back
        p.back["echidnaSpines"] = { d, k in
            let w = k.w, h = k.h, n = 13
            var out: [VNode] = []
            for i in 0..<n {
                let a = -196 + Double(i) * 212 / Double(n - 1)
                let r = a * .pi / 180
                let bx = cos(r) * w * 0.8, by = -h * 0.52 + sin(r) * h * 0.42
                out += spine(bx, by, a, i % 2 == 1 ? 38 : 44, 10, d.spineColor ?? "#f4e2b2", d.spineTip ?? "#4f3a2c")
            }
            return out
        }
        /// sugar glider: the furry gliding membrane, stretched from wrist to ankle
        p.back["patagium"] = { d, k in
            let w = k.w, h = k.h, c = d.wingColor ?? d.body
            return both { s in
                [nPath("M\(s * w * 0.7),\(-h * 0.62) L\(s * (w + 30)),\(-h * 0.5) " +
                    "Q\(s * (w + 22)),\(-h * 0.36) \(s * (w + 30)),\(-h * 0.22) Q\(s * (w + 20)),\(-h * 0.12) \(s * (w + 22)),\(-h * 0.02) " +
                    "L\(s * w * 0.5),-6 Z", A.S(c))]
            }
        }
        /// frill-neck lizard: the big umbrella frill around its head
        p.back["frill"] = { d, k in
            let w = k.w, h = k.h
            let cx = 0.0, cy = -h * 0.6, n = 11
            func angle(_ i: Int) -> Double { (-205 + Double(i) * 230 / Double(n * 2)) * .pi / 180 }
            func ring(_ R: Double, _ inner: Double) -> [Pt] {
                (0...(n * 2)).map { i in
                    let a = angle(i), rr = i % 2 == 1 ? R * inner : R
                    return (cx + cos(a) * rr, cy + sin(a) * rr * 0.92)
                }
            }
            let outer = ring(w + 36, 0.88), mid = ring(w + 14, 0.94)
            var out = [nPolygon(outer + [(cx, cy)], A.S(d.frillColor ?? "#f07d4e")), nPolygon(mid + [(cx, cy)], .f(d.frillInner ?? "#ffcf66"))]
            for i in stride(from: 0, through: n * 2, by: 2) {
                let a = angle(i)
                out.append(nPath("M\(cx + cos(a) * (w - 4)),\(cy + sin(a) * (w - 4) * 0.92) L\(cx + cos(a) * (w + 30)),\(cy + sin(a) * (w + 30) * 0.92)",
                                 rcap(d.frillRib ?? "#cf5a35", 4)))
            }
            return out
        }
        /// frill-neck lizard: a long tail curling along the ground
        p.back["lizardTail"] = { d, k in
            let w = k.w, h = k.h
            return [tail(A.tube("M\(w * 0.5),-12 C\(w + 20),-4 \(w + 40),-10 \(w + 46),\(-h * 0.2) C\(w + 50),\(-h * 0.3) \(w + 40),\(-h * 0.36) \(w + 34),\(-h * 0.3)", d.body, 12))]
        }
        /// bilby: a thin black tail with a white crested tip
        p.back["bilbyTail"] = { _, k in
            let w = k.w, h = k.h
            return [tail(A.tube("M\(w * 0.5),-14 C\(w + 18),-10 \(w + 26),-24 \(w + 30),\(-h * 0.34)", "#4a4352", 7) +
                A.tube("M\(w + 28),\(-h * 0.28) C\(w + 31),\(-h * 0.38) \(w + 32),\(-h * 0.46) \(w + 30),\(-h * 0.54)", "#fdfaf3", 11))]
        }
        /// mole cricket: short, soft antennae with a little curl
        p.back["cricketAntennae"] = { d, k in
            let w = k.w, h = k.h
            return both { s in
                let pd = "M\(s * w * 0.16),\(-h * 0.92) Q\(s * w * 0.2),\(-h * 1.14) \(s * w * 0.48),\(-h * 1.16) Q\(s * w * 0.62),\(-h * 1.16) \(s * w * 0.6),\(-h * 1.08)"
                return [nPath(pd, rcap(O, 11)), nPath(pd, rcap(d.antennaColor ?? O, 4))]
            }
        }

        // marks (clipped inside the body)
        /// galah: pale pink cap, grey wings wrapped round the flanks
        p.marks["galah"] = { d, k in
            let w = k.w, h = k.h, g = d.greyColor ?? "#b7bcc6"
            return [nEllipse(0, -h * 1.04, w * 0.78, h * 0.24, .f(d.capColor ?? d.body))] +
                both { s in [nEllipse(s * w * 1.02, -h * 0.3, w * 0.42, h * 0.44, .f(g))] } +
                [nEllipse(0, 6, w * 0.7, h * 0.1, .f(g))]
        }
        /// kookaburra: brown wings on the flanks, a streaky crown and the dark eye stripe
        p.marks["kooka"] = { d, k in
            let w = k.w, h = k.h, fy = k.fy, ex = k.ex
            let br = d.wingColor ?? "#9a6a47", crown = d.crownColor ?? "#d9bf9c"
            var out = both { s in [nEllipse(s * w * 1.0, -h * 0.36, w * 0.4, h * 0.5, .f(br))] }
            out.append(nEllipse(0, -h * 1.02, w * 0.62, h * 0.2, .f(crown)))
            out += [-14.0, 0, 14].map { x in nPath("M\(x),\(-h * 0.98) L\(x * 1.2),\(-h * 0.86)", rcap(sh(crown, -0.3), 4)) }
            out += both { s in
                [nPath("M\(s * (w * ex + 2)),\(fy - 1) Q\(s * (w * 0.72)),\(fy - 5) \(s * (w + 6)),\(fy + 4) L\(s * (w + 6)),\(fy + 15) Q\(s * w * 0.72),\(fy + 7) \(s * (w * ex + 2)),\(fy + 8) Z",
                       .f(d.stripeColor ?? "#6e4a33"))]
            }
            return out
        }
        /// emu chick: long cream and brown stripes, a spotty head
        p.marks["emu"] = { d, k in
            let w = k.w, h = k.h, fy = k.fy, c = d.markColor ?? "#7a5640"
            func stripe(_ x: Double, _ top: Double, _ wd: Double) -> VNode {
                nPath("M\(x),\(top) C\(x + 6),\(top * 0.66) \(x - 6),\(top * 0.33) \(x),4", rcap(c, wd))
            }
            return both { s in [stripe(s * w * 0.5, -h * 0.9, 10), stripe(s * w * 0.94, -h * 0.74, 16)] } +
                [nPath("M0,\(-h * 1.02) L0,\(fy - 20)", rcap(c, 8))] +
                [(-0.3, 0.86), (0.3, 0.86), (-0.42, 0.74), (0.42, 0.74)].map { x, y in nCircle(x * w, -y * h, 4, .f(c)) }
        }
        /// sugar glider: the dark stripe down the forehead and dark rings round the eyes
        p.marks["glider"] = { d, k in
            let w = k.w, h = k.h, fy = k.fy, ex = k.ex, c = d.markColor ?? "#4f4c5c"
            return [nPath("M-7,\(-h * 1.02) L7,\(-h * 1.02) L3,\(fy + 2) Q0,\(fy + 5) -3,\(fy + 2) Z", .f(c))] +
                both { s in [
                    nEllipse(s * w * ex, fy, 14, 15, .f(c)),
                    nPath("M\(s * w * ex),\(fy - 10) Q\(s * w * 0.6),\(fy - 26) \(s * w * 0.72),\(-h * 0.86)", rcap(c, 9)),
                ] }
        }
        /// mole cricket: the velvety helmet (pronotum) and soft tummy bands
        p.marks["cricket"] = { d, k in
            let w = k.w, h = k.h, c = d.markColor ?? "#8c5d3c", belly = d.belly ?? d.body
            return [
                nPath("M\(-w - 6),\(-h * 0.74) Q0,\(-h * 0.84) \(w + 6),\(-h * 0.74) L\(w + 6),\(-h * 1.2) L\(-w - 6),\(-h * 1.2) Z", .f(c)),
                nPath("M\(-w * 0.46),\(-h * 0.9) Q0,\(-h * 0.98) \(w * 0.46),\(-h * 0.9)", rcap(sh(c, 0.22), 6)),
                nPath("M0,\(-h * 0.98) L0,\(-h * 0.8)", rcap(sh(c, -0.25), 3.5)),
            ] + [0.2, 0.09].enumerated().map { i, y in
                let xx = w * (0.36 - Double(i) * 0.06)
                return nPath("M\(-xx),\(-h * y) Q0,\(-h * y + 6) \(xx),\(-h * y)", rcap(sh(belly, -0.12), 3.5))
            }
        }

        // front
        /// joey: mum's pouch, with the joey peeking out of it
        p.front["pouch"] = { d, k in
            let w = k.w, h = k.h, c = d.pouchColor ?? "#cf9764"
            // a soft fur pocket: its opening is a smile, high at the sides
            let pd = "M\(-w - 6),\(-h * 0.46) C\(-w - 14),\(-h * 0.12) \(-w * 0.62),4 0,4 C\(w * 0.62),4 \(w + 14),\(-h * 0.12) \(w + 6),\(-h * 0.46) " +
                "C\(w * 0.5),\(-h * 0.3) \(-w * 0.5),\(-h * 0.3) \(-w - 6),\(-h * 0.46) Z"
            let shade = "M\(-w + 2),\(-h * 0.5) C\(-w * 0.4),\(-h * 0.36) \(w * 0.4),\(-h * 0.36) \(w - 2),\(-h * 0.5) L\(w + 6),\(-h * 0.46) C\(w * 0.5),\(-h * 0.3) \(-w * 0.5),\(-h * 0.3) \(-w - 6),\(-h * 0.46) Z"
            return [
                nPath(shade, .f(sh(d.body, -0.18))),
                nPath(pd, A.S(c)),
                nPath("M\(-w + 2),\(-h * 0.39) C\(-w * 0.4),\(-h * 0.27) \(w * 0.4),\(-h * 0.27) \(w - 2),\(-h * 0.39)", rcap(sh(c, 0.35), 5)),
            ]
        }
        /// echidna: a few short spines on top of the head
        p.front["headSpines"] = { d, k in
            let h = k.h, c = d.spineColor ?? "#f4e2b2", t = d.spineTip ?? "#4f3a2c"
            return spine(-14, -h * 0.9, -108, 22, 6, c, t) + spine(0, -h * 0.93, -90, 25, 6, c, t) + spine(14, -h * 0.9, -72, 22, 6, c, t)
        }
        /// emu chick: a little fuzz on top
        p.front["fuzz"] = { d, k in
            let h = k.h, st = A.S4(d.markColor ?? "#7a5640")
            return [leaf(-3, -h * 0.94, -118, 18, 6, st), leaf(0, -h * 0.95, -88, 22, 6, st), leaf(3, -h * 0.94, -60, 18, 6, st)]
        }

        // eyes
        /// a parrot's eye: the friendly dot eye with a bare pale ring round it
        p.eyes["ringDot"] = { d, k in
            both { s in
                let x = s * k.w * k.ex, fy = k.fy
                return [nCircle(x, fy, 11, .f(d.eyeRing ?? "#fde1e8")), nEllipse(x, fy, 6.5, 8, .f(O)), nCircle(x - 2, fy - 3, 2.5, .f("#ffffff"))]
            }
        }

        // muzzle
        p.muzzle["parrotBeak"] = parrotBeak
        /// kookaburra: the big kingfisher beak, dark on top, pale below
        p.muzzle["kookaBeak"] = { d, k in
            let fy = k.fy
            return [
                nPath("M12,\(fy + 13) C-4,\(fy + 17) -26,\(fy + 22) -42,\(fy + 28) C-26,\(fy + 34) -4,\(fy + 32) 12,\(fy + 25) Z", A.S4(d.beakLow ?? "#efe3cc")),
                nPath("M14,\(fy + 1) C0,\(fy - 3) -30,\(fy + 6) -48,\(fy + 24) C-28,\(fy + 20) -4,\(fy + 20) 14,\(fy + 17) Q19,\(fy + 9) 14,\(fy + 1) Z", A.S4(d.beakTop ?? "#4f4540")),
                nPath("M4,\(fy + 5) Q-12,\(fy + 5) -24,\(fy + 12)", rcap("#ffffff", 3.5).so(0.35)),
            ]
        }
        /// platypus: the wide, soft duck bill
        p.muzzle["platyBill"] = { d, k in
            let fy = k.fy, c = d.muzzleColor ?? "#6d7383"
            return [
                nPath("M-31,\(fy + 14) C-33,\(fy + 2) 33,\(fy + 2) 31,\(fy + 14) C33,\(fy + 30) -33,\(fy + 30) -31,\(fy + 14) Z", A.S4(c)),
                nPath("M-20,\(fy + 19) Q0,\(fy + 24) 20,\(fy + 19)", rcap(sh(c, -0.35), 3)),
                nEllipse(-6, fy + 10, 2.4, 3, .f(O)), nEllipse(6, fy + 10, 2.4, 3, .f(O)),
                nEllipse(-16, fy + 9, 6, 2.4, St.f("#ffffff").op(0.3)),
            ]
        }
        /// echidna: a long thin snout
        p.muzzle["echidnaSnout"] = { d, k in
            let fy = k.fy
            return A.tube("M0,\(fy + 6) C0,\(fy + 20) 0,\(fy + 30) -3,\(fy + 38)", d.muzzleColor ?? "#4f3f36", 13) +
                [nEllipse(-3, fy + 39, 4.5, 3, .f(O))]
        }
        /// bilby: a long pointy snout with a pink nose
        p.muzzle["bilbySnout"] = { d, k in
            let fy = k.fy
            return [
                nPath("M-15,\(fy + 6) Q0,\(fy - 2) 15,\(fy + 6) Q8,\(fy + 24) 2,\(fy + 32) Q0,\(fy + 34) -2,\(fy + 32) Q-8,\(fy + 24) -15,\(fy + 6) Z", A.S4(d.muzzleColor ?? "#ece4ee")),
                nEllipse(0, fy + 30, 7, 5.5, A.S4(d.noseColor ?? "#f28fab")),
            ]
        }

        // nose
        /// wombat: the big, square, leathery nose
        p.nose["wombat"] = { d, k in
            let fy = k.fy, c = d.noseColor ?? "#4f403c"
            return [
                nRect(-18, fy + 3, 36, 24, rx: 11, A.S4(c)),
                nPath("M-9,\(fy + 17) q3,-5 6,0 M3,\(fy + 17) q3,-5 6,0", rcap(sh(c, -0.5), 3)),
                nEllipse(-7, fy + 8, 6, 2.5, St.f("#ffffff").op(0.35)),
            ]
        }
        /// lizard: two little nostrils
        p.nose["nostrils"] = { _, k in [nCircle(-5, k.fy + 9, 2.2, .f(O)), nCircle(5, k.fy + 9, 2.2, .f(O))] }

        // mouth
        /// under the wombat's big nose
        p.mouth["under"] = { _, k in
            let my = k.fy + 33
            return [nPath("M-7,\(my) Q-3.5,\(my + 5) 0,\(my) Q3.5,\(my + 5) 7,\(my)", St.line(O, 4))]
        }
        /// a lizard's wide grin
        p.mouth["grin"] = { _, k in
            let my = k.fy + 18
            return [nPath("M-20,\(my - 3) Q0,\(my + 11) 20,\(my - 3)", rcap(O, 4))]
        }

        // arms
        /// joey: little paws resting on the rim of the pouch
        p.arms["rimPaws"] = { d, k in
            let w = k.w, h = k.h, c = d.armColor ?? sh(d.body, -0.06)
            return both { s in
                [A.arm(s, [
                    nEllipse(s * w * 0.5, -h * 0.36, 12, 9, A.S(c)),
                    nPath("M\(s * w * 0.5 - 4),\(-h * 0.36 + 2) l0,5 M\(s * w * 0.5 + 4),\(-h * 0.36 + 2) l0,5", rcap(O, 2.5)),
                ])]
            }
        }
        /// kookaburra: brown wings with the blue shoulder patch
        p.arms["kookaWing"] = { d, k in
            let w = k.w, h = k.h, c = d.armColor ?? sh(d.body, -0.06)
            return both { s in
                [A.arm(s, [nPath("M\(s * (w - 12)),\(-h * 0.62) Q\(s * (w + 18)),\(-h * 0.48) \(s * (w - 2)),\(-h * 0.16) Q\(s * (w - 18)),\(-h * 0.34) \(s * (w - 12)),\(-h * 0.62) Z", A.S(c))] +
                    [(-0.52, 3.5), (-0.45, 3), (-0.4, 3.2)].enumerated().map { i, yr in
                        nCircle(s * (w - 6 + Double(i) * 3), h * yr.0, yr.1, .f(d.blueColor ?? "#7fb6e0"))
                    })]
            }
        }
        /// sugar glider: paws out at the corners of its gliding membrane
        p.arms["gliderPaws"] = { d, k in
            let c = d.armColor ?? sh(d.body, -0.06)
            return both { s in [A.arm(s, [nEllipse(s * (k.w + 28), -k.h * 0.5, 9, 8, A.S(c))])] }
        }
        /// mole cricket: big, soft, shovel-shaped digging hands
        p.arms["shovels"] = { d, k in
            let w = k.w, h = k.h, c = d.armColor ?? sh(d.body, -0.06)
            // a broad digging hand: a wide palm and three fat, rounded fingers fanned outwards
            return both { s in
                let fingers = [-42.0, 0, 42].map { a -> VNode in
                    let r = a * .pi / 180, cx = s * (8 + cos(r) * 17), cy = sin(r) * 17
                    return nEllipse(cx, cy, 11, 7.5, A.S(c)).moved(rotAbout(s * a, cx, cy))
                }
                return [A.arm(s, [nGroup(fingers + [
                    nEllipse(s * 4, 0, 17, 15, A.S(c)),
                    nPath("M\(s * -6),-7 Q\(s * 3),-11 \(s * 12),-6", rcap(sh(c, 0.3), 3.5)),
                ], svgMove(s * (w - 4), -h * 0.34, rot: s * 38))])]
            }
        }

        // feet
        /// emu chick: big three-toed feet
        p.feet["bigBird"] = { d, k in
            let c = d.feetColor ?? "#8f8994"
            return both { s in
                let x = s * k.w * 0.34
                let pd = "M\(x - 15),4 L\(x),-12 L\(x + 15),4 M\(x),-12 L\(x),6"
                return [nPath(pd, St.line(O, 14)), nPath(pd, St.line(c, 6))]
            }
        }
        /// platypus: webbed feet
        p.feet["webbed"] = { d, k in
            let c = d.feetColor ?? "#6d7383"
            return both { s in
                let x = s * k.w * 0.42
                return [nPath("M\(x - 18),-2 Q\(x - 20),-14 \(x),-14 Q\(x + 20),-14 \(x + 18),-2 Q\(x + 12),4 \(x + 6),0 Q\(x),5 \(x - 6),0 Q\(x - 12),4 \(x - 18),-2 Z", A.S(c))]
            }
        }
        return p
    }()

    // MARK: the 12 friends (web order)

    private static let WHITE = "#fdfaf3", PINK = "#f6b3bf"

    static let friends: [AnimalDef] = [
        AnimalDef("galah", "Galah", "#f39cb4") {
            $0.back = ["galahCrest"]; $0.crestColor = "#fde1e8"; $0.marks = ["galah"]; $0.capColor = "#fbd0dc"; $0.greyColor = "#b7bcc6"
            $0.arms = "wing"; $0.armColor = "#a3a9b4"; $0.feet = "bird"; $0.feetColor = "#a3a9b4"; $0.muzzle = "parrotBeak"; $0.muzzleColor = "#f1e6d2"; $0.nose = "none"; $0.mouth = "none"
            $0.eyes = "ringDot"; $0.eyeRing = "#fde1e8"; $0.cheekColor = "#e8668a"
        },
        AnimalDef("cockatoo", "Cockatoo", WHITE) {
            $0.shape = "tall"; $0.back = ["cockyCrest"]; $0.crestColor = "#ffd84a"
            $0.arms = "wing"; $0.armColor = "#efebe0"; $0.feet = "bird"; $0.feetColor = "#9a949c"; $0.muzzle = "parrotBeak"; $0.muzzleColor = "#56505a"; $0.nose = "none"; $0.mouth = "none"
            $0.eyes = "ringDot"; $0.eyeRing = "#dcecf5"; $0.cheekColor = "#ffd36b"
        },
        AnimalDef("kookaburra", "Kookaburra", "#f6efe2") {
            $0.marks = ["kooka"]; $0.wingColor = "#9a6a47"; $0.crownColor = "#d9bf9c"; $0.stripeColor = "#6e4a33"
            $0.back = ["kookaTail"]; $0.tailColor = "#c46f3c"; $0.arms = "kookaWing"; $0.armColor = "#8a5d3e"; $0.blueColor = "#7fb6e0"; $0.feet = "bird"; $0.feetColor = "#c9a27a"
            $0.muzzle = "kookaBeak"; $0.beakTop = "#4f4540"; $0.beakLow = "#efe3cc"; $0.nose = "none"; $0.mouth = "none"; $0.eyeX = 0.4
        },
        AnimalDef("emu", "Emu Chick", "#f0dfbb") {
            $0.shape = "tall"; $0.belly = "#f8ecd2"; $0.marks = ["emu"]; $0.markColor = "#7a5640"; $0.front = ["fuzz"]
            $0.arms = "wing"; $0.armColor = "#e4cda2"; $0.feet = "bigBird"; $0.feetColor = "#8f8994"; $0.muzzle = "beak"; $0.muzzleColor = "#6f6873"; $0.nose = "none"; $0.mouth = "none"
        },
        AnimalDef("joey", "Joey", "#e2ad7c") {
            $0.shape = "tall"; $0.ears = "roo"; $0.earInner = "#f4c3b4"; $0.muzzle = "snout"; $0.muzzleColor = "#f6e2c8"
            $0.front = ["pouch"]; $0.pouchColor = "#cf9764"; $0.arms = "rimPaws"; $0.armColor = "#d79c6a"; $0.feet = "none"; $0.faceY = 0.62
        },
        AnimalDef("wombat", "Wombat", "#a48d7b") {
            $0.shape = "wide"; $0.ears = "wombat"; $0.earInner = "#dcc3b4"; $0.marks = ["muzzlePatch"]; $0.faceColor = "#c9b4a2"
            $0.nose = "wombat"; $0.noseColor = "#4f403c"; $0.mouth = "under"; $0.front = ["claws"]; $0.armColor = "#8f7868"; $0.feetColor = "#8f7868"; $0.faceY = 0.6
        },
        AnimalDef("platypus", "Platypus", "#94694a") {
            // the web names a "paddleTail" no pack defines, so it draws no tail; kept the same here
            $0.shape = "wide"; $0.belly = "#d9b48c"; $0.back = ["paddleTail"]; $0.tailColor = "#7a5538"
            $0.muzzle = "platyBill"; $0.muzzleColor = "#6d7383"; $0.nose = "none"; $0.mouth = "none"; $0.feet = "webbed"; $0.feetColor = "#6d7383"; $0.armColor = "#7f5a3f"; $0.faceY = 0.62
        },
        AnimalDef("echidna", "Echidna", "#80604a") {
            $0.shape = "small"; $0.back = ["echidnaSpines"]; $0.front = ["headSpines", "claws"]; $0.spineColor = "#f4e2b2"; $0.spineTip = "#4f3a2c"
            $0.muzzle = "echidnaSnout"; $0.muzzleColor = "#4f3f36"; $0.nose = "none"; $0.mouth = "none"; $0.armColor = "#6b4f3c"; $0.feetColor = "#6b4f3c"
        },
        AnimalDef("sugarglider", "Sugar Glider", "#a9adbd") {
            $0.shape = "small"; $0.belly = "#f6f0e4"; $0.ears = "glider"; $0.earInner = PINK
            $0.marks = ["glider"]; $0.markColor = "#4f4c5c"; $0.back = ["patagium"]; $0.wingColor = "#9da1b2"; $0.arms = "gliderPaws"; $0.armColor = "#f3c6c9"
            $0.eyes = "big"; $0.noseColor = "#f18ea0"; $0.feetColor = "#f3c6c9"
        },
        AnimalDef("frillneck", "Frill-neck Lizard", "#e3bf7f") {
            $0.belly = "#f6e2b4"; $0.back = ["frill", "lizardTail"]; $0.frillColor = "#f07d4e"; $0.frillInner = "#ffcf66"; $0.frillRib = "#cf5a35"
            $0.marks = ["spots"]; $0.markColor = "#cfa264"; $0.spotPts = [(-0.72, 0.7, 7), (0.74, 0.66, 8), (-0.8, 0.44, 6), (0.82, 0.4, 6), (0.3, 0.95, 5), (-0.32, 0.93, 5)]
            $0.nose = "nostrils"; $0.mouth = "grin"; $0.feetColor = "#cfa264"; $0.armColor = "#d6ad6c"; $0.cheekColor = "#f39a7b"
        },
        AnimalDef("bilby", "Bilby", "#bdb3c8") {
            $0.shape = "small"; $0.belly = WHITE; $0.ears = "bilby"; $0.earInner = "#f6b8c8"; $0.back = ["bilbyTail"]
            $0.muzzle = "bilbySnout"; $0.muzzleColor = "#ece4ee"; $0.noseColor = "#f28fab"; $0.nose = "none"; $0.mouth = "none"; $0.whiskers = true; $0.feetColor = "#e9c7d2"; $0.armColor = "#b0a6bd"
        },
        AnimalDef("molecricket", "Mole Cricket", "#b9875c") {
            $0.shape = "wide"; $0.belly = "#e2bd90"; $0.marks = ["cricket"]; $0.markColor = "#8c5d3c"; $0.back = ["cricketAntennae"]; $0.antennaColor = "#8c5d3c"
            $0.arms = "shovels"; $0.armColor = "#8c5d3c"; $0.eyes = "big"; $0.mouth = "u"; $0.nose = "none"; $0.feetColor = "#8c5d3c"; $0.faceY = 0.5
        },
    ]
}
