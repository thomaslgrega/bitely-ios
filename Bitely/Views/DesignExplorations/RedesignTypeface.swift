//
//  The typeface the explorations set their headings in, switchable at runtime
//  so the five layouts can be compared in the same face and one face compared
//  across the five layouts.
//
//  Every family here ships under the SIL Open Font License; the copy in
//  Resources/Fonts/OFL.txt covers all of them.
//

import SwiftUI

enum RedesignTypeface: String, CaseIterable, Identifiable {
    case fraunces = "Fraunces"
    case playfair = "Playfair Display"
    case dmSerif = "DM Serif Display"
    case instrumentSerif = "Instrument Serif"
    case bricolage = "Bricolage Grotesque"
    case systemSerif = "New York"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .fraunces: "The board's own face — soft, wonky, warm."
        case .playfair: "High-contrast Didone; the editorial default."
        case .dmSerif: "Display serif, tight and confident at large sizes."
        case .instrumentSerif: "Narrow and literary; buys a lot of headline width."
        case .bricolage: "The sans option — a modern grotesque with character."
        case .systemSerif: "Apple's New York, no download, scales everywhere."
        }
    }

    /// PostScript names of the bundled files. Display faces ship a single weight,
    /// so a semibold heading in one of those renders in its regular cut.
    fileprivate func fontName(for weight: Font.Weight) -> String? {
        let wantsHeavy = weight != .regular && weight != .light && weight != .thin

        return switch self {
        case .fraunces: wantsHeavy ? "Fraunces-SemiBold" : "Fraunces-Regular"
        case .playfair: wantsHeavy ? "PlayfairDisplay-SemiBold" : "PlayfairDisplay-Regular"
        case .dmSerif: "DMSerifDisplay-Regular"
        case .instrumentSerif: "InstrumentSerif-Regular"
        case .bricolage: wantsHeavy ? "BricolageGrotesque-SemiBold" : "BricolageGrotesque-Regular"
        case .systemSerif: nil
        }
    }

    /// A heading in this face, whether or not it is the selected one.
    func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        guard let name = fontName(for: weight) else {
            return .system(size: size, weight: weight, design: .serif)
        }

        return .custom(name, size: size * sizeAdjustment)
    }

    /// Cap heights differ enough between these families that one point size reads
    /// a full step apart; this evens them out against Fraunces.
    fileprivate var sizeAdjustment: CGFloat {
        switch self {
        case .fraunces, .playfair, .dmSerif, .systemSerif: 1
        case .instrumentSerif: 1.12
        case .bricolage: 0.96
        }
    }
}

/// One selection shared by every exploration, so switching face in the gallery
/// changes all five at once. Observation carries the change into each body that
/// asked `Redesign.serif` for a font.
@Observable
final class RedesignType {
    static let shared = RedesignType()

    var typeface: RedesignTypeface = .fraunces

    private init() {}
}

extension Redesign {
    /// The heading font, in whichever face is selected.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        RedesignType.shared.typeface.font(size, weight)
    }
}

/// The control itself: a face name that renders in its own face, tapped to cycle
/// through the list or long-pressed for the full menu.
struct TypefacePicker: View {
    var style: SaveButton.Style = .light

    @State private var type = RedesignType.shared

    var body: some View {
        Menu {
            Picker("Typeface", selection: $type.typeface) {
                ForEach(RedesignTypeface.allCases) { face in
                    Text(face.rawValue).tag(face)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("Aa")
                    .font(Redesign.serif(16, .semibold))
                Text(type.typeface.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(style == .light ? Redesign.ink : Redesign.cream)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(style == .light ? .white : Color.white.opacity(0.15)))
            .overlay(Capsule().stroke(style == .light ? Redesign.hairline : .clear, lineWidth: 1))
        }
    }
}
