import SwiftUI

/// A labelled control on the writing screens — design-system.md, FormField. The label, the
/// message a required field shows when it is empty, and the surface the control sits on.
struct FormField<Content: View>: View {
    let label: String
    /// Non-nil only once the user has tried to save without filling the field in, so the
    /// screen never scolds someone for not having typed yet.
    var error: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text(label)
                    .textStyle(.label)
                    .foregroundStyle(Color.contentSecondary)

                if let error {
                    Spacer()
                    Label(error, systemImage: "exclamationmark.triangle")
                        .textStyle(.meta)
                        .foregroundStyle(Color.destructive)
                }
            }

            content().fieldSurface(isInvalid: error != nil)
        }
    }
}

extension View {
    /// The ground every text field, picker and ingredient row on the writing screens sits
    /// on. A field in error takes the `destructive` stroke; nothing else changes, so the
    /// value stays readable while it is being corrected.
    func fieldSurface(isInvalid: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.control, style: .continuous)

        return padding(Spacing.m)
            .background(shape.fill(Color.surfaceRaised))
            .overlay(shape.strokeBorder(isInvalid ? Color.destructive : Color.border, lineWidth: 1))
    }
}

private struct FormFieldPreview: View {
    @State private var name = "Brown Butter Gnocchi"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            FormField(label: "Recipe name") {
                TextField("Recipe name", text: $name)
            }

            FormField(label: "Recipe name", error: "This field is required") {
                TextField("Recipe name", text: .constant(""))
            }
        }
        .textStyle(.body)
        .padding()
        .background(Color.surface)
    }
}

#Preview { FormFieldPreview() }
