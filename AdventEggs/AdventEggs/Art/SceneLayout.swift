import SwiftUI

/// The calendar scene is painted on a 1000 x 1500 board (scene units):
/// a winter village at dusk under the star, a church in the middle, two
/// houses behind, three in front and gift boxes in the snow. Every window,
/// door and gift is one of the 25 advent doors, numbered out of order the
/// way a real advent calendar is. Christmas Day is the church door.
enum SceneBoard {
    static let width: CGFloat = 1000
    static let height: CGFloat = 1500
    /// Where the snowy ground starts, in scene units.
    static let horizon: CGFloat = 760
}

/// How the board is scaled and placed on the screen.
struct SceneFit {
    let scale: CGFloat
    let origin: CGPoint

    init(size: CGSize, topPadding: CGFloat) {
        let s = min(size.width / SceneBoard.width, (size.height - topPadding) / SceneBoard.height)
        scale = max(s, 0.01)
        let x = (size.width - SceneBoard.width * scale) / 2
        let y = topPadding + (size.height - topPadding - SceneBoard.height * scale) / 2
        origin = CGPoint(x: x, y: y)
    }

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }
}

enum DoorStyle {
    case window, door, round, arch, gift

    var shape: AnyShape {
        switch self {
        case .window: return AnyShape(RoundedRectangle(cornerRadius: 6))
        case .door: return AnyShape(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 2,
                                                             bottomTrailingRadius: 2, topTrailingRadius: 18))
        case .round: return AnyShape(Circle())
        case .arch: return AnyShape(ArchShape())
        case .gift: return AnyShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ArchShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        let radius = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + radius), radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct DoorSlot: Identifiable {
    let day: Int
    let rect: CGRect
    let style: DoorStyle
    let paint: Color
    /// The trim painted around the opening (window frames, door surrounds).
    let trim: Color

    var id: Int { day }

    private static let paints: [Color] = [
        Color(hex: 0xb8434a), Color(hex: 0x3f7a5a), Color(hex: 0x3f6496),
        Color(hex: 0xd39a3a), Color(hex: 0x7b4f7a), Color(hex: 0x3f8a8a),
    ]

    private static func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    /// Positions in painting order, then the day behind each one.
    private static let places: [(CGRect, DoorStyle)] = [
        // church: rose window in the tower, and the big door (Christmas Day)
        (r(452, 252, 96, 96), .round), (r(450, 560, 100, 140), .arch),
        // back left house
        (r(70, 462, 110, 100), .window), (r(200, 462, 110, 100), .window), (r(135, 592, 110, 108), .door),
        // back right house
        (r(690, 462, 110, 100), .window), (r(820, 462, 110, 100), .window), (r(755, 592, 110, 108), .door),
        // front left house
        (r(45, 895, 110, 105), .window), (r(185, 895, 110, 105), .window), (r(45, 1035, 110, 105), .window),
        (r(190, 1062, 100, 198), .door),
        // front middle house, with a round attic window
        (r(455, 778, 90, 90), .round), (r(375, 895, 110, 105), .window), (r(515, 895, 110, 105), .window),
        (r(450, 1062, 100, 198), .door),
        // front right house
        (r(705, 895, 110, 105), .window), (r(845, 895, 110, 105), .window), (r(845, 1035, 110, 105), .window),
        (r(710, 1062, 100, 198), .door),
        // gifts in the snow
        (r(40, 1305, 140, 125), .gift), (r(228, 1328, 118, 108), .gift), (r(405, 1300, 150, 135), .gift),
        (r(600, 1326, 120, 110), .gift), (r(778, 1304, 150, 128), .gift),
    ]

    private static let days = [24, 25, 7, 15, 3, 19, 11, 21, 1, 13, 9, 17, 6, 22, 4, 12, 16, 2, 20, 10, 8, 18, 5, 23, 14]

    static let all: [DoorSlot] = zip(places, days).enumerated().map { i, pair in
        let (place, day) = pair
        let trim: Color = place.1 == .gift ? .clear : Color(hex: 0xf4ead8)
        return DoorSlot(day: day, rect: place.0, style: place.1, paint: paints[i % paints.count], trim: trim)
    }
}
