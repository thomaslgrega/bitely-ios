import Foundation

/// Whether the Cookbook offers its filter, and what it draws in place of a grid.
///
/// A decision type like `ShareControl` because the order of these branches is the whole
/// behaviour and a view cannot be tested: a segment that holds nothing because `me/recipes`
/// has not answered is not an empty collection, and must not be answered with the creation
/// flow — docs/design/app-flow.md, Cookbook.
struct CookbookScreen: Equatable {
    enum Placeholder: Equatable {
        case grid
        /// The segment genuinely holds nothing, so its own empty state owns the screen.
        case emptyCollection
        case noMatches
        case matchesElsewhere(Int)
        /// My Recipes, filtered to nothing, before authorship has answered for this session.
        case unresolvedAuthorship
    }

    let segment: CookbookSegment
    let query: String
    /// Rows of this segment passing the query.
    let matches: Int
    /// Rows of this segment before it.
    let held: Int
    let matchesElsewhere: Int
    let hasResolvedAuthorship: Bool

    private var isQuerying: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    /// A live query keeps its field even over a segment that has nothing left to filter,
    /// because a field the user cannot see is a query they cannot clear.
    var offersFilter: Bool { held > 0 || isQuerying }

    var placeholder: Placeholder {
        guard matches == 0 else { return .grid }
        guard isQuerying else { return .emptyCollection }

        // Ahead of the softening: a Recipe one tap away answers the question the user
        // asked, where a caveat about authorship only explains why nothing does.
        if matchesElsewhere > 0 { return .matchesElsewhere(matchesElsewhere) }
        if segment == .myRecipes && !hasResolvedAuthorship { return .unresolvedAuthorship }
        return .noMatches
    }
}
