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
                        GlyphBubble(emoji: group.emoji, diameter: 32)
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
                        .overlay { Capsule().stroke(Color.gray2, lineWidth: 1.5) }
                    Button("Add", action: addCustom)
                        .font(.display(13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 46)
                        .background(Color.rose, in: .capsule)
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
        grid.sensoryFeedback(.selection, trigger: selection)
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(cuisineOptions.sorted { $0.name < $1.name }.enumerated()), id: \.element.id) { index, cuisine in
                CuisineTile(
                    cuisine: cuisine,
                    isSelected: selection.contains(cuisine.name),
                    accent: .white
                ) {
                    selection.formSymmetricDifference([cuisine.name])
                }
            }
        }
    }
}

private struct CuisineTile: View {
    let cuisine: OnboardingOption
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                GlyphBubble(emoji: cuisine.emoji, diameter: 82, fill: cuisineBubbleColors[cuisine.name])
                    .frame(maxWidth: .infinity, minHeight: 92)
                Text(cuisine.name)
                    .font(.display(14))
                    .foregroundStyle(Color.ink)
                Text([signatureDish(forCuisine: cuisine.name), "\(cuisineRecipeCounts[cuisine.name, default: 0]) recipes"]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.text(12))
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
            .padding(8)
            .padding(.vertical, 8)
            .background(accent.opacity(isSelected ? 1 : 0.55), in: Leaf.swatch())
            .overlay {
                Leaf.swatch().strokeBorder(Color.ink, lineWidth: isSelected ? 2.5 : 0)
            }
            .scaleEffect(isSelected ? 1.03 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.5), value: isSelected)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Sparkle()
                        .fill(Color.ink)
                        .frame(width: 22, height: 22)
                        .padding(14)
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
