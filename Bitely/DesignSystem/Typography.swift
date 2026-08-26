import SwiftUI

/// The bundled faces, registered in Info.plist under `UIAppFonts` from `Resources/Fonts`.
enum Fraunces: String, CaseIterable {
    case regular = "Fraunces-Regular"
    case semiBold = "Fraunces-SemiBold"
}

enum TypeFace: Equatable {
    case fraunces(Fraunces)
    case system(Font.Weight)
}

/// One row of the type scale: the face, the size it is drawn at, and the text style it
/// scales against under Dynamic Type.
struct TypeSpec: Equatable {
    let face: TypeFace
    let size: CGFloat
    let textStyle: Font.TextStyle
}

/// The whole type scale. A size chosen at a call site is how a design system dies, so
/// every font in the app comes from a case here.
enum TypeToken: CaseIterable {
    case display
    case sectionTitle
    case greeting
    case cardTitle
    case body
    case meta
    case label

    var spec: TypeSpec {
        switch self {
        case .display: TypeSpec(face: .fraunces(.semiBold), size: 30, textStyle: .title)
        case .sectionTitle: TypeSpec(face: .fraunces(.semiBold), size: 24, textStyle: .title2)
        case .greeting: TypeSpec(face: .fraunces(.semiBold), size: 19, textStyle: .title3)
        case .cardTitle: TypeSpec(face: .fraunces(.semiBold), size: 16, textStyle: .headline)
        case .body: TypeSpec(face: .system(.regular), size: 15, textStyle: .body)
        case .meta: TypeSpec(face: .system(.regular), size: 13, textStyle: .footnote)
        case .label: TypeSpec(face: .system(.semibold), size: 14, textStyle: .subheadline)
        }
    }

}

private struct TypeStyle: ViewModifier {
    private let spec: TypeSpec

    /// `Font.system` has no `relativeTo:`, so the sans sizes are scaled here instead and
    /// land on the same Dynamic Type curve the Fraunces sizes get for free.
    @ScaledMetric private var scaledSize: CGFloat

    init(_ token: TypeToken) {
        let spec = token.spec
        self.spec = spec
        _scaledSize = ScaledMetric(wrappedValue: spec.size, relativeTo: spec.textStyle)
    }

    func body(content: Content) -> some View {
        content.font(font)
    }

    private var font: Font {
        switch spec.face {
        case .fraunces(let face):
            .custom(face.rawValue, size: spec.size, relativeTo: spec.textStyle)
        case .system(let weight):
            .system(size: scaledSize, weight: weight)
        }
    }
}

extension View {
    func textStyle(_ token: TypeToken) -> some View {
        modifier(TypeStyle(token))
    }
}
