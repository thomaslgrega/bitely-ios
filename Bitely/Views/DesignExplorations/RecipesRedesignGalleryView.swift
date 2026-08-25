//
//  The comparison harness for the five RecipesTabView explorations.
//
//  Point ContentView's Recipes tab at this while choosing a direction; nothing
//  under DesignExplorations is wired into the shipping app.
//

import SwiftUI

enum RecipesRedesign: String, CaseIterable, Identifiable {
    case editorialFeed = "Editorial Feed"
    case crimsonHeader = "Crimson Header"
    case midnightKitchen = "Midnight Kitchen"
    case magazineIndex = "Magazine Index"
    case pantryFirst = "Pantry First"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .editorialFeed: "The inspiration board head-on: greeting bar, dark promo card, chips, two-column grid."
        case .crimsonHeader: "Red masthead with search, cream sheet riding over it, category tiles and compact rows."
        case .midnightKitchen: "Ink background, cream type, one full-bleed recipe per card, filtering pill rail."
        case .magazineIndex: "Type-led contents page — oversized serif, hairline rules, numbered entries."
        case .pantryFirst: "Pantry entry at the top filters a mosaic in place; the category ring narrows it."
        }
    }

    var accent: Color {
        switch self {
        case .editorialFeed: Redesign.tint(for: .pasta)
        case .crimsonHeader: Redesign.red
        case .midnightKitchen: Redesign.ink
        case .magazineIndex: Redesign.tint(for: .seafood)
        case .pantryFirst: Redesign.tint(for: .vegetarian)
        }
    }

    @ViewBuilder
    var screen: some View {
        switch self {
        case .editorialFeed: EditorialFeedRecipesView()
        case .crimsonHeader: CrimsonHeaderRecipesView()
        case .midnightKitchen: MidnightKitchenRecipesView()
        case .magazineIndex: MagazineIndexRecipesView()
        case .pantryFirst: PantryFirstRecipesView()
        }
    }
}

struct RecipesRedesignGalleryView: View {
    @State private var presented: RecipesRedesign?
    /// Side-by-side puts every exploration on one pannable row; the list opens them full screen.
    @State private var sideBySide = false
    @State private var type = RedesignType.shared

    var body: some View {
        NavigationStack {
            Group {
                if sideBySide {
                    comparisonStrip
                } else {
                    pickerList
                }
            }
            .background(Redesign.cream)
            .navigationTitle("Recipes redesign")
            .safeAreaInset(edge: .bottom) { typefaceBar }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) { sideBySide.toggle() }
                    } label: {
                        Image(systemName: sideBySide ? "list.bullet" : "rectangle.split.3x1")
                    }
                }
            }
            .fullScreenCover(item: $presented) { design in
                ZStack(alignment: .topTrailing) {
                    design.screen

                    HStack(spacing: 8) {
                        TypefacePicker(style: design == .midnightKitchen ? .dark : .light)

                        Button { presented = nil } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Redesign.cream)
                                .padding(10)
                                .background(Circle().fill(Redesign.ink.opacity(0.75)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 58)
                    .padding(.trailing, 14)
                }
            }
        }
        .tint(Redesign.red)
    }

    /// Faces sit on a bar of their own rather than in the toolbar, so the sample
    /// word for each is set in the face it names.
    private var typefaceBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RedesignTypeface.allCases) { face in
                    let isSelected = type.typeface == face
                    Button {
                        withAnimation(.snappy) { type.typeface = face }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Recipes")
                                .font(face.font(19, .semibold))
                                .foregroundStyle(isSelected ? Redesign.cream : Redesign.ink)
                            Text(face.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isSelected ? Redesign.cream.opacity(0.7) : Redesign.inkSoft)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isSelected ? Redesign.ink : .white))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Redesign.hairline, lineWidth: isSelected ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Redesign.cream.opacity(0.98))
        .overlay(alignment: .top) { Rectangle().fill(Redesign.hairline).frame(height: 1) }
    }

    private var pickerList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Array(RecipesRedesign.allCases.enumerated()), id: \.element) { index, design in
                    Button { presented = design } label: {
                        HStack(spacing: 16) {
                            Text(String(format: "%02d", index + 1))
                                .font(Redesign.serif(20, .semibold))
                                .foregroundStyle(Redesign.cream)
                                .frame(width: 54, height: 54)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Redesign.ink))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(design.rawValue)
                                    .font(Redesign.serif(20, .semibold))
                                    .foregroundStyle(Redesign.ink)
                                Text(design.blurb)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Redesign.inkSoft)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Redesign.inkSoft)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(design.accent, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    /// Each exploration rendered at phone width and scaled down, so two fit on screen at once.
    private var comparisonStrip: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 20) {
                ForEach(RecipesRedesign.allCases) { design in
                    VStack(spacing: 10) {
                        design.screen
                            .frame(width: 393, height: 760)
                            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 34, style: .continuous)
                                    .stroke(Redesign.ink.opacity(0.15), lineWidth: 1)
                            )
                            .scaleEffect(0.46, anchor: .top)
                            .frame(width: 393 * 0.46, height: 760 * 0.46)
                            .allowsHitTesting(false)

                        Button { presented = design } label: {
                            Text(design.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Redesign.cream)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Redesign.ink))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    RecipesRedesignGalleryView()
}
