import CoreGraphics

/// The spacing scale. Convention, not enforcement: a layout that genuinely needs 6 can
/// have it, but reach here first.
enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

/// Corner radii by the thing they round. Chips and pill buttons take a capsule instead.
enum Radius {
    static let control: CGFloat = 16
    static let card: CGFloat = 18
    static let promo: CGFloat = 26
}
