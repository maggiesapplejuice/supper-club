import SwiftUI

/// Opened by tapping a card: shows the points behind its rarity and where that falls on the scale.
struct RarityDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                LiveCardView(recipe: recipe, width: 230, isDraggable: true)
                    .padding(.top, 8)
                summary
                factors
                scale
            }
            .padding(20)
        }
        .background(Color.paper)
        .overlay(alignment: .topTrailing) {
            Button("Close", systemImage: "xmark") { dismiss() }
                .labelStyle(.iconOnly)
                .font(.display(14))
                .foregroundStyle(Color.brandText)
                .frame(width: 44, height: 44)
                .background(.white, in: .circle)
                .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
                .padding(16)
        }
    }

    private var summary: some View {
        VStack(spacing: 6) {
            Text(recipe.tier.name.uppercased())
                .font(.display(13))
                .tracking(2)
                .foregroundStyle(recipe.tier.color)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(recipe.score)")
                    .font(.display(44))
                Text("/ 100 rarity points")
                    .font(.text(14))
                    .foregroundStyle(Color.gray4)
            }
            .foregroundStyle(Color.brandText)
            .accessibilityElement(children: .combine)
        }
    }

    private var factors: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What makes up this rarity")
                .font(.display(17))
                .foregroundStyle(Color.brandText)
            ForEach(recipe.factors) { factor in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(factor.name)
                            .font(.display(15))
                        Spacer()
                        Text("\(factor.points)/\(RarityFactor.maxPoints)")
                            .font(.text(14))
                            .monospacedDigit()
                    }
                    .foregroundStyle(Color.brandText)
                    InkProgressBar(value: Double(factor.points) / Double(RarityFactor.maxPoints))
                    Text(factor.detail)
                        .font(.text(13))
                        .foregroundStyle(Color.gray4)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scale: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rarity scale")
                .font(.display(17))
                .foregroundStyle(Color.brandText)
            ForEach(RarityTier.allCases.reversed()) { tier in
                HStack(spacing: 10) {
                    HStack(spacing: 1) {
                        ForEach(0..<tier.stars, id: \.self) { _ in
                            Sparkle().fill(Color.ink).frame(width: 11, height: 11)
                        }
                    }
                    .frame(width: 62, alignment: .leading)
                    Text(tier.name)
                        .font(tier == recipe.tier ? .display(14) : .text(14))
                    if tier.isHolographic {
                        Text("Holographic")
                            .font(.display(11))
                            .foregroundStyle(tier.color)
                    }
                    Spacer()
                    Text(tier.scoreRange)
                        .font(.text(13))
                        .foregroundStyle(Color.gray4)
                }
                .foregroundStyle(Color.brandText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.gray1.opacity(tier == recipe.tier ? 1 : 0), in: .rect(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
