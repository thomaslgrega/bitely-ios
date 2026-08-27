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

/// Symbol point sizes, the axis the type scale does not cover: these glyphs sit inside
/// fixed-size controls, so they hold their size while the text around them grows.
enum SymbolSize {
    static let control: CGFloat = 17
    static let save: CGFloat = 15
    static let emptyState: CGFloat = 34
}

/// Sizes of the controls that float over a thumbnail. They sit on a picture rather than in
/// the text flow, so they hold still while the text around them grows.
enum ControlSize {
    /// The save heart and the selection indicator, which share a corner across screens and
    /// so must share a size.
    static let thumbnailBadge: CGFloat = 34
}
