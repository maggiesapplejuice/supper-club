import SwiftUI

/// Lays chips out left to right and wraps them onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews, width: bounds.width)
        for (subview, origin) in zip(subviews, rows.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (origins: [CGPoint], width: CGFloat, height: CGFloat) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return (origins, maxX, y + rowHeight)
    }
}

/// Every dietary option, grouped, plus a field for anything the list doesn't cover.
struct RestrictionPicker: View {
    @Binding var selection: Set<String>
    @State private var custom = ""

    private var listed: Set<String> { Set(restrictionGroups.flatMap(\.options)) }
    private var customSelections: [String] { selection.subtracting(listed).sorted() }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(restrictionGroups) { group in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        InkGlyphView(emoji: group.emoji, size: 28)
                        Text(group.title)
                            .font(.display(15))
                            .foregroundStyle(Color.ink)
                    }
                    .accessibilityAddTraits(.isHeader)
                    FlowLayout {
                        ForEach(group.options, id: \.self) { option in
                            InkChip(title: option, isSelected: selection.contains(option)) {
                                selection.formSymmetricDifference([option])
                            }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Something else?")
                    .font(.display(15))
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 8) {
                    TextField("e.g. no cilantro", text: $custom)
                        .font(.text(14))
                        .foregroundStyle(Color.ink)
                        .submitLabel(.done)
                        .onSubmit(addCustom)
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(.white, in: .capsule)
                        .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
                    Button("Add", action: addCustom)
                        .font(.display(13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 46)
                        .background(Color.ink, in: .capsule)
                        .opacity(trimmedCustom.isEmpty ? 0.3 : 1)
                        .disabled(trimmedCustom.isEmpty)
                }
                Text("Sourcing picks like organic, non-GMO or local, and anything you add here, are saved to your profile but don't hide recipes yet.")
                    .font(.text(12))
                    .foregroundStyle(Color.gray4)
                if !customSelections.isEmpty {
                    FlowLayout {
                        ForEach(customSelections, id: \.self) { option in
                            InkChip(title: "\(option)  ✕", isSelected: true) {
                                selection.remove(option)
                            }
                            .accessibilityLabel("Remove \(option)")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var trimmedCustom: String { custom.trimmingCharacters(in: .whitespaces) }

    private func addCustom() {
        guard !trimmedCustom.isEmpty else { return }
        selection.insert(trimmedCustom)
        custom = ""
    }
}

struct CuisinePicker: View {
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            ForEach(cuisineOptions) { cuisine in
                CuisineTile(cuisine: cuisine, isSelected: selection.contains(cuisine.name)) {
                    selection.formSymmetricDifference([cuisine.name])
                }
            }
        }
    }
}

private struct CuisineTile: View {
    let cuisine: OnboardingOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                InkGlyphView(emoji: cuisine.emoji, size: 84)
                    .frame(maxWidth: .infinity, minHeight: 104)
                Text(cuisine.name)
                    .font(.display(13))
                    .foregroundStyle(Color.brandText)
            }
            .padding(8)
            .background(isSelected ? Color.gray1 : .white, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.ink : Color.gray2, lineWidth: isSelected ? 2.5 : 2)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Sparkle()
                        .fill(Color.ink)
                        .frame(width: 24, height: 24)
                        .padding(10)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Kosher", "Non-GMO"]
    ScrollView { RestrictionPicker(selection: $selection).padding(20) }
}
