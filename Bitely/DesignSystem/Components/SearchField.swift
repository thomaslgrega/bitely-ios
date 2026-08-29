import SwiftUI

/// The app's own search field, on `.fieldSurface()` like every other input here.
///
/// `.searchable` was the alternative and draws iOS's own capsule at its own type size and
/// inset, which is a control from another design system in an app whose visual language is
/// ADR-0001. It also pins itself above whatever it is placed over, and position is what
/// states scope — the Cookbook's filter has to sit inside the segment it filters.
struct SearchField: View {
    @Binding var text: String
    let prompt: String
    /// Discover's field is the whole screen, so it takes the keyboard on arrival; a filter
    /// over a list the user came to look at does not.
    var autofocus = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: SymbolSize.control, weight: .medium))
                .foregroundStyle(Color.contentSecondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .textStyle(.body)
                .foregroundStyle(Color.contentPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: SymbolSize.control, weight: .medium))
                        .foregroundStyle(Color.contentSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear the search")
            }
        }
        .fieldSurface()
        .onAppear { if autofocus { isFocused = true } }
    }
}

#Preview {
    @Previewable @State var text = ""

    SearchField(text: $text, prompt: "Search your recipes")
        .padding(Spacing.xl)
        .background(Color.surface)
}
